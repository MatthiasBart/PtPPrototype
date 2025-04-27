//
//  ConnectionMetricsClient.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 27.04.25.
//

import SwiftUI
import Network

struct ConnectionMetricsClient: TestResultRepresentable {
    let startedSendingAt: Date?
    let numberOfSentPackages: Int
    let sizePerSentPackageInBytes: Int
    let endedSendingAt: Date?
    let errors: [any Error]
    
    let latencies: [UInt64]
    
    let dataTransferReport: NWConnection.DataTransferReport.PathReport
    
    private var latencyCount: String {
        latencies.count.description
    }
    
    private var averageLatency: String {
        (latencies.avg() / Double(NSEC_PER_MSEC)).formatted().replacingOccurrences(of: ",", with: ".")
    }
    
    private var jitter: String {
        (latencies.std() / Double(NSEC_PER_MSEC)).formatted().replacingOccurrences(of: ",", with: ".")
    }
    
    private var duration: TimeInterval? {
        guard let startedSendingAt, let endedSendingAt else { return nil }
        return endedSendingAt.timeIntervalSince(startedSendingAt)
    }
    
    private var mbitsPerSecond: Float? {
        guard let duration else { return nil }
        return Float(numberOfSentPackages * sizePerSentPackageInBytes * 8) / Float(duration) / 1_000_000
    }
    
    func toCSV(in scenario: String, with distance: String, using transportProtocol: String) -> String {
        CSVHeaders.transportProtocol + ", " + CSVHeaders.scenario + ", " + CSVHeaders.distance + ", " + CSVHeaders.avgRTT + ", " + CSVHeaders.jitter  + "\n" +
        "\(transportProtocol), \(scenario), \(distance), \(averageLatency), \(jitter)"
    }
    
    var description: String {
        """
        \(latencyCount) RTTs counted
        \(CSVHeaders.avgRTT): \(averageLatency)
        \(CSVHeaders.jitter): \(jitter)
        
        \(errors.count) errors
        \(errors.count == 0 ? "" : errors.first!.localizedDescription)
        """
    }
}
//Started \(startedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: startedSendingAt!))
//Ended \(endedSendingAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: endedSendingAt!))
//Took \(duration == nil ? "N/A" : duration!.formatted()) seconds
//\(numberOfSentPackages.formatted()) packages each \(sizePerSentPackageInBytes.formatted()) bytes
//\((numberOfSentPackages * sizePerSentPackageInBytes).formatted()) bytes
//\(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted()) mbit/sec
//
//Data transfer report from Network Framework:
//
//Interface: \(dataTransferReport.interface.debugDescription)
//IP Sent: \(dataTransferReport.sentIPPacketCount.formatted())
//IP Received: \(dataTransferReport.receivedIPPacketCount.formatted())
//
//Application Bytes R: \(dataTransferReport.receivedApplicationByteCount.formatted())
//Application Bytes S: \(dataTransferReport.sentApplicationByteCount.formatted())
//
//Transport Bytes R: \(dataTransferReport.receivedTransportByteCount.formatted())
//Transport Dup Bytes R: \(dataTransferReport.receivedTransportDuplicateByteCount.formatted())
//Transport OoO Bytes R: \(dataTransferReport.receivedTransportOutOfOrderByteCount.formatted())
//Transport retrans Bytes R: \(dataTransferReport.retransmittedTransportByteCount.formatted())
//Transport Bytes S: \(dataTransferReport.sentTransportByteCount.formatted())
//Transport RTT Min: \(dataTransferReport.transportMinimumRTT.formatted())
//Transport RTT Variance: \(dataTransferReport.transportRTTVariance.formatted())
//Transport RTT smoothed: \(dataTransferReport.transportSmoothedRTT.formatted())
//RadioType: \(dataTransferReport.radioType.debugDescription)
//
