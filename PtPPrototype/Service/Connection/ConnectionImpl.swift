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
    var receiveMessageHandler: ((Int?) -> Void)?
    private var delimiter: UInt8 = 1
    static let payloadSize = 128

    required init(_ connection: NWConnection) {
        self.connection = connection
        setupConnection()
    }
    
    func startTesting(numberOfBytes: Int, splitSize: Int = payloadSize) async {
        await self._startTesting(numberOfBytes: numberOfBytes, splitSize: splitSize)
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
                    self?.receive()
                }
                
            default:
                break
            }
        }
        
        self.connection.start(queue: .main)
    }
}

//MARK: Client
extension ConnectionImpl {
    private func _startTesting(numberOfBytes: Int, splitSize: Int) async {
        await withCheckedContinuation { continuation in
            for _ in stride(from: 0, to: numberOfBytes, by: splitSize) {
                sendPackage(bytes: splitSize)
            }
            continuation.resume()
        }
        
        sendPackage(bytes: 1, content: delimiter)
    }
    
    private func sendPackage(bytes: Int, content: UInt8 = 61) {
        var data: [UInt8] = Array(repeating: content, count: bytes)
        var length = UInt32(bytes).bigEndian
        let lenghtData = Data(bytes: &length, count: 4)
        
        connection.send(content: lenghtData + data, isComplete: true, completion: .contentProcessed( { error in
            if let error {
                log.error("\(error.localizedDescription)")
            }
        }))
    }
}

//MARK: Server
extension ConnectionImpl {
    private func receive() {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { lengthData, contentContext, isComplete, error in
            if let lengthData, lengthData.count == 4 {
                
                let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
                guard length == Self.payloadSize || length == 1 else { return }
                
                self.connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { data, contentContext, isComplete, error in
                    if let data {
                        self.receiveMessageHandler?((data + lengthData).count)
                        
                        if data.last == self.delimiter {
                            self.receiveMessageHandler?(nil)
                        }
                    }
                    
                    if let error {
                        log.info("Error: \(error), testing stopped")
                        self.receiveMessageHandler?(nil)
                    } else {
                        self.receive()
                    }
                }
            }
        }
    }
}
