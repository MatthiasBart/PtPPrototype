//
//  ConnectionImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import Network
import Combine
import Foundation

class ConnectionImpl: Connection {
    private var connection: NWConnection
    //Client
    private var startedSendingAt: Date?
    private var endedSendingAt: Date?
    private var sizePerPackage: Int = 0
    private var latencies: [TimeInterval] = []
    
    
    //Server
    private var byteCount: Int = 0
    private var packagesCount: Int = 0
    private var receivedFirstPackageAt: Date?
    private var receivedLastPackageAt: Date?
    private var remoteFirstPackageWasSentAt: Date?
    private var remotePackageWasSentAt: Date?
    private var errors: [Error] = []
    
    //Shared
    private var currentReport: NWConnection.PendingDataTransferReport?
    private var numberOfTotalPackages: Int = 0

    private var isClient = false
    static let payloadSize = 128

    var state: NWConnection.State {
        connection.state
    }

    required init(_ connection: NWConnection) {
        self.connection = connection
        setupConnection()
    }
    
    func startTesting(numberOfPackages: Int, packageSizeInByte: Int = payloadSize) async {
        await self._startTesting(numberOfPackages: numberOfPackages, packageSizeInByte: packageSizeInByte)
    }
    
    func cancel() {
        self.connection.cancel()
    }
    
    func setupConnection() {
        self.connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                log.info("connection ready")
                DispatchQueue.global().async {
                    self?.currentReport = self?.connection.startDataTransferReport()
                    self?.receive()
                }
                
            default:
                break
            }
        }
        
        self.connection.start(queue: .main)
    }
    
    func collectMetrics() async -> String {
        if isClient {
            ConnectionMetricsClient(startedSendingAt: startedSendingAt ?? .now, numberOfSentPackages: numberOfTotalPackages, sizePerSentPackageInBytes: sizePerPackage, endedSendingAt: endedSendingAt, latencies: latencies).description
        } else {
            await withCheckedContinuation { continuation in
                currentReport?.collect(queue: .global(), completion: { report in
                    continuation.resume(returning: ConnectionMetricsServer(
                        receivedFirstPacketAt: self.receivedFirstPackageAt ?? .now,
                        receivedBytes: self.byteCount,
                        receivedPackages: self.packagesCount,
                        numberOfTotalPackages: self.numberOfTotalPackages,
                        receivedLastPacketAt: self.receivedLastPackageAt ?? .now,
                        remoteFirstPackageWasSentAt: self.remoteFirstPackageWasSentAt ?? .now,
                        remotePackageWasSentAt: self.remotePackageWasSentAt ?? .now,
                        interface: report.aggregatePathReport.interface.debugDescription,
                        ipPackagesSent: report.aggregatePathReport.sentIPPacketCount.formatted(),
                        ipPacketsReceived: report.aggregatePathReport.receivedIPPacketCount.formatted()
                    ))
                })
            }.description
        }
    }
    
    func resetMetrics() {
        self.latencies = []
        self.currentReport = self.connection.startDataTransferReport()
    }
}

//MARK: Client
extension ConnectionImpl {
    //private start testing to wrap the sync methods in an async callback
    private func _startTesting(numberOfPackages: Int, packageSizeInByte: Int) async {
        isClient = true
        numberOfTotalPackages = numberOfPackages
        sizePerPackage = packageSizeInByte
        
        await withCheckedContinuation { continuation in
            for _ in 1...100 {
                sendLatencyJitterPackage()
            }
            continuation.resume()
        }
        
        try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
        
        startedSendingAt = .now
        
        await withCheckedContinuation { continuation in
            for _ in 1...numberOfPackages  {
                sendPackage(bytes: packageSizeInByte, numberOfPackages: numberOfPackages)
            }
            continuation.resume()
        }
        
        endedSendingAt = .now
    }
    
    private func sendLatencyJitterPackage(dateData: Data? = nil) {
        let dateDataSize: Int = MemoryLayout<UInt64>.size
        var date = Date.now.timeIntervalSince1970.bitPattern.bigEndian
        var dateDataCurrent = Data(bytes: &date, count: dateDataSize)
        
        var length = UInt32(dateDataSize).bigEndian
        let lengthData = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        
        connection.send(content: lengthData + (dateData ?? dateDataCurrent), completion: .contentProcessed({ error in
            if let error {
                log.error("\(error.localizedDescription)")
            }
        }))
    }
    
    //sends one individual package with the payload size `bytes` and info about the length of the package and overall number of packages
    private func sendPackage(bytes: Int, content: UInt8 = 61, numberOfPackages: Int) {
        let totalNumberPackageHeaderSize: Int = MemoryLayout<UInt32>.size
        let dateDataSize: Int = MemoryLayout<UInt64>.size
        
        let junkData: [UInt8] = Array(repeating: content, count: bytes)
        
        var date = Date.now.timeIntervalSince1970.bitPattern.bigEndian
        let dateData = Data(bytes: &date, count: dateDataSize)
        
        var totalNumberOfPackages = UInt32(numberOfPackages).bigEndian
        let totalNumberOfPackagesData = Data(bytes: &totalNumberOfPackages, count: totalNumberPackageHeaderSize)
        
        //length of the payload plus length of total number of packages header information
        var length = UInt32(bytes + totalNumberPackageHeaderSize + dateDataSize).bigEndian
        let lenghtData = Data(bytes: &length, count: MemoryLayout<UInt32>.size)
        
        connection.send(content:  lenghtData + totalNumberOfPackagesData + dateData + junkData, isComplete: true, completion: .contentProcessed( { error in
            if let error {
                log.error("\(error.localizedDescription)")
            }
        }))
    }
}

//MARK: Server
extension ConnectionImpl {
    private func receive() {
        //receive the header so the receiver knows how big the package is and can read the declared length of the rest of the message
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { lengthData, contentContext, isComplete, error in
            if let lengthData, lengthData.count == 4 {
                
                let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                
                //read the rest of the package using the size declared in the header before
                
                if length == 8 {
                    self.receive_latency_jitter_test()
                } else {
                    self.receive_message(length: length)
                }
            }
        }
    }
    
    private func receive_latency_jitter_test() {
        self.connection.receive(minimumIncompleteLength: 8, maximumLength: 8) { data, contentContext, isComplete, error in
            if let data {
                if self.isClient {
                    let date = data.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }.bigEndian
                    let latency = Date().timeIntervalSince(Date(timeIntervalSince1970: TimeInterval(bitPattern: date)))
                    self.latencies.append(latency)
                } else {
                    self.sendLatencyJitterPackage(dateData: data)
                }
            }
            
            if let error {
                self.errors.append(error)
            } else {
                self.receive()
            }
        }
    }
    
    private func receive_message(length: UInt32) {
        self.connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { data, contentContext, isComplete, error in
            if let data {
                //information about the total packages that will be sent, important for upd packages that can/will get lost
                let numberOfTotalPackages = data.subdata(in: 0..<4).withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                let datePackageWasSent = data.subdata(in: 4..<12).withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }.bigEndian
                //callback for total number of packages and the bytes received
                self.byteCount += Int(data.count) + 4 // 4 because of length data
                if self.receivedFirstPackageAt == nil {
                    self.receivedFirstPackageAt = .now
                    self.remoteFirstPackageWasSentAt = Date(timeIntervalSince1970: TimeInterval(bitPattern: datePackageWasSent))
                }
                self.numberOfTotalPackages = Int(numberOfTotalPackages)
                self.packagesCount += 1
                self.receivedLastPackageAt = .now
                self.remotePackageWasSentAt = Date(timeIntervalSince1970: TimeInterval(bitPattern: datePackageWasSent))
            }
            
            if let error {
                self.errors.append(error)
            } else {
                self.receive()
            }
        }
    }
}
