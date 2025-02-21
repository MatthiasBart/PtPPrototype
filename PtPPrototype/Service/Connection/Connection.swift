//
//  Connection.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Network
import Combine
import Foundation

struct ConnectionMetricsClient: CustomStringConvertible {
    let startedSendingAt: Date?
    let numberOfSentPackages: Int
    let sizePerSentPackageInBytes: Int
    let endedSendingAt: Date?
    let errors: [any Error]
    
    let latencies: [TimeInterval]
    
    let dataTransferReport: NWConnection.DataTransferReport.PathReport
    
    private var latencyCount: String {
        latencies.count.description
    }
    
    private var averageLatency: String {
        (latencies.reduce(0, +) / Double(latencies.count)).formatted()
    }
    
    private var jitter: String {
        latencies.std().formatted()
    }
    
    private var duration: TimeInterval? {
        guard let startedSendingAt, let endedSendingAt else { return nil }
        return endedSendingAt.timeIntervalSince(startedSendingAt)
    }
    
    private var mbitsPerSecond: Float? {
        guard let duration else { return nil }
        return Float(numberOfSentPackages * sizePerSentPackageInBytes * 8) / Float(duration) / 1_000_000
    }
    
    var description: String {
        """
        Started \(startedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: startedSendingAt!))
        Ended \(endedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: endedSendingAt!))
        Took \(duration == nil ? "N/A" : duration!.formatted()) seconds
        
        \(numberOfSentPackages.formatted()) packages each \(sizePerSentPackageInBytes.formatted()) bytes
        \((numberOfSentPackages * sizePerSentPackageInBytes).formatted()) bytes
        \(latencyCount) latencies counted
        Average Latency: \(averageLatency)
        Jitter: \(jitter)
        
        \(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted()) mbit/sec
        
        Data transfer report from Network Framework:
        
        Interface: \(dataTransferReport.interface.debugDescription)
        IP Sent: \(dataTransferReport.sentIPPacketCount.formatted())
        IP Received: \(dataTransferReport.receivedIPPacketCount.formatted())
        
        Application Bytes R: \(dataTransferReport.receivedApplicationByteCount.formatted())
        Application Bytes S: \(dataTransferReport.sentApplicationByteCount.formatted())
        
        Transport Bytes R: \(dataTransferReport.receivedTransportByteCount.formatted())
        Transport Dup Bytes R: \(dataTransferReport.receivedTransportDuplicateByteCount.formatted())
        Transport OoO Bytes R: \(dataTransferReport.receivedTransportOutOfOrderByteCount.formatted())
        Transport retrans Bytes R: \(dataTransferReport.retransmittedTransportByteCount.formatted())
        Transport Bytes S: \(dataTransferReport.sentTransportByteCount.formatted())
        Transport RTT Min: \(dataTransferReport.transportMinimumRTT.formatted())
        Transport RTT Variance: \(dataTransferReport.transportRTTVariance.formatted())
        Transport RTT smoothed: \(dataTransferReport.transportSmoothedRTT.formatted())
        RadioType: \(dataTransferReport.radioType.debugDescription)
        
        \(errors.count) errors
        \(errors.count == 0 ? "" : errors.first!.localizedDescription)
        """
    }
}

struct ConnectionMetricsServer: CustomStringConvertible {
    let receivedBytes: Int
    let receivedPackages: Int
    let numberOfTotalPackages: Int
    
    let receivedFirstPacketAt: Date?
    let receivedLastPacketAt: Date?
    
    let remoteFirstPackageWasSentAt: Date?
    let remotePackageWasSentAt: Date?
    
    let errors: [any Error]
    
    let dataTransferReport: NWConnection.DataTransferReport.PathReport
    
    private var duration: TimeInterval? {
        guard let receivedLastPacketAt, let receivedFirstPacketAt else { return nil }
        return receivedLastPacketAt.timeIntervalSince(receivedFirstPacketAt)
    }
    
    private var mbitsPerSecond: Float? {
        guard let duration else { return nil }
        return Float(receivedBytes * 8) / Float(duration) / 1_000_000
    }
    
    private var packageLoss: Float {
        100 - Float(receivedPackages) / Float(numberOfTotalPackages) * 100
    }
    
    var description: String {
                """
        Started \(receivedFirstPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedFirstPacketAt!))
        Ended \(receivedLastPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedLastPacketAt!))
        Took \(duration == nil ? "N/A" : duration!.formatted()) seconds

        Remote started \(remoteFirstPackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remoteFirstPackageWasSentAt!))
        Remote ended \(remotePackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remotePackageWasSentAt!))

        \(receivedBytes.formatted()) bytes
        \(receivedPackages.formatted()) of \(numberOfTotalPackages.formatted()) packages
        \(packageLoss.formatted()) % package loss 
        \(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted()) mbit/sec
        
        Data transfer report from Network Framework:
        
        Interface: \(dataTransferReport.interface.debugDescription)
        IP Sent: \(dataTransferReport.sentIPPacketCount.formatted())
        IP Received: \(dataTransferReport.receivedIPPacketCount.formatted())
        
        Application Bytes R: \(dataTransferReport.receivedApplicationByteCount.formatted())
        Application Bytes S: \(dataTransferReport.sentApplicationByteCount.formatted())
        
        Transport Bytes R: \(dataTransferReport.receivedTransportByteCount.formatted())
        Transport Dup Bytes R: \(dataTransferReport.receivedTransportDuplicateByteCount.formatted())
        Transport OoO Bytes R: \(dataTransferReport.receivedTransportOutOfOrderByteCount.formatted())
        Transport retrans Bytes R: \(dataTransferReport.retransmittedTransportByteCount.formatted())
        Transport Bytes S: \(dataTransferReport.sentTransportByteCount.formatted())
        Transport RTT Min: \(dataTransferReport.transportMinimumRTT.formatted())
        Transport RTT Variance: \(dataTransferReport.transportRTTVariance.formatted())
        Transport RTT smoothed: \(dataTransferReport.transportSmoothedRTT.formatted())
        RadioType: \(dataTransferReport.radioType.debugDescription)
        
        \(errors.count) errors
        \(errors.count == 0 ? "" : errors.first!.localizedDescription)
        """
    }
}

protocol Connection: Identifiable {
    init(_ connection: NWConnection)
    var state: NWConnection.State { get }
    
    static var payloadSize: Int { get }
    
    func collectMetrics() async -> String
    func resetMetrics()
    func startTesting(numberOfPackages: Int, packageSizeInByte: Int) async
    func cancel()
}

//https://stackoverflow.com/questions/38422150/swift-array-extension-for-standard-deviation
extension Array where Element: FloatingPoint {
    func sum() -> Element {
        return self.reduce(0, +)
    }

    func avg() -> Element {
        return self.sum() / Element(self.count)
    }

    func std() -> Element {
        let mean = self.avg()
        let v = self.reduce(0, { $0 + ($1-mean)*($1-mean) })
        return sqrt(v / (Element(self.count) - 1))
    }
}
