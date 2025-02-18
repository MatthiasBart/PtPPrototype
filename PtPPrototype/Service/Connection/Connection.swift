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
    let startedSendingAt: Date
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
        "Started sending at: \(CustomDateFormatter.precise.string(from: startedSendingAt))\nSent: \(numberOfSentPackages) packages each \(sizePerSentPackageInBytes) bytes\nEnded sending at: \(CustomDateFormatter.precise.string(from: endedSendingAt ?? .distantPast))\nTook \(endedSendingAt?.timeIntervalSince(startedSendingAt) ?? .zero) seconds\n\(latencyCount) latencies counted\nAverage Latency: \(averageLatency)\nLatency Variance: \nJitter: \(jitter)\n"
    }
}

struct ConnectionMetricsServer: CustomStringConvertible {
    let receivedFirstPacketAt: Date
    let receivedBytes: Int
    let receivedPackages: Int
    let numberOfTotalPackages: Int
    let receivedLastPacketAt: Date
    
    let remoteFirstPackageWasSentAt: Date
    let remotePackageWasSentAt: Date
    
    let errors: [any Error] = []
    
    let interface: String
    let ipPackagesSent: String
    let ipPacketsReceived: String
    
    private var duration: TimeInterval {
        receivedLastPacketAt.timeIntervalSince(receivedFirstPacketAt)
    }
    
    private var mbitsPerSecond: Float {
        Float(receivedBytes * 8) / Float(duration)
    }
    
    var description: String {
                """
        Received first at: \(CustomDateFormatter.precise.string(from: receivedFirstPacketAt))
        Received last at: \(CustomDateFormatter.precise.string(from: receivedLastPacketAt))

        Remote sent first at: \(CustomDateFormatter.precise.string(from: remoteFirstPackageWasSentAt))
        Remote sent last at: \(CustomDateFormatter.precise.string(from: remotePackageWasSentAt))

        Received: \(receivedBytes.formatted()) bytes
        Received: \(receivedPackages) of \(numberOfTotalPackages) packages
        Took \(receivedLastPacketAt.timeIntervalSince(receivedFirstPacketAt)) seconds

        \(mbitsPerSecond.formatted()) mbit/sec
        Interface: \(interface)\nIP Packages Sent: \(ipPackagesSent)\nIP Packets Received: \(ipPacketsReceived)\n"
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
