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
    
    let latencies: [TimeInterval]
    
    var latencyCount: String {
        latencies.count.description
    }
    
    var averageLatency: String {
        (latencies.reduce(0, +) / Double(latencies.count)).description
    }
    
    var jitter: String {
        ""
    }
    
    var description: String {
        """
        Started \(startedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: startedSendingAt!))
        Ended \(endedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: endedSendingAt!))
        Took \(startedSendingAt != nil && endedSendingAt != nil ? endedSendingAt!.timeIntervalSince(startedSendingAt!).formatted() : "N/A") seconds
        
        \(numberOfSentPackages) packages each \(sizePerSentPackageInBytes) bytes
        \(latencyCount) latencies counted
        Average Latency: \(averageLatency)
        Latency Variance: 
        Jitter: \(jitter)
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
    
    let errors: [any Error] = []
    
    let interface: String
    let ipPackagesSent: String
    let ipPacketsReceived: String
    
    private var duration: TimeInterval? {
        guard let receivedLastPacketAt, let receivedFirstPacketAt else { return nil }
        return receivedLastPacketAt.timeIntervalSince(receivedFirstPacketAt)
    }
    
    private var mbitsPerSecond: Float? {
        guard let duration else { return nil }
        return Float(receivedBytes * 8) / Float(duration)
    }
    
    var description: String {
                """
        Started \(receivedFirstPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedFirstPacketAt!))
        Ended \(receivedLastPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedLastPacketAt!))
        Took \(receivedFirstPacketAt != nil && receivedLastPacketAt != nil ? receivedLastPacketAt!.timeIntervalSince(receivedFirstPacketAt!).description : "N/A") seconds

        Remote started \(remoteFirstPackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remoteFirstPackageWasSentAt!))
        Remote ended \(remotePackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remotePackageWasSentAt!))

        \(receivedBytes.formatted()) bytes
        \(receivedPackages) of \(numberOfTotalPackages) packages

        \(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted()) mbit/sec
        Interface: \(interface)
        IP Sent: \(ipPackagesSent)
        IP Received: \(ipPacketsReceived)
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
