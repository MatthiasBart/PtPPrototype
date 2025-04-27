//
//  ConnectionMetricsServer.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 27.04.25.
//

import SwiftUI
import Network

struct ConnectionMetricsServer: TestResultRepresentable {
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
    
    private var sizePerPackage: Int {
        if receivedPackages != 0 {
            return receivedBytes / receivedPackages
        }
        return 0
    }
    
    private var packageLoss: Float {
        100 - (Float(receivedPackages) / Float(numberOfTotalPackages)) * 100
    }
    
    func toCSV(in scenario: String, with distance: String, using transportProtocol: String) -> String {
        CSVHeaders.transportProtocol + ", " + CSVHeaders.scenario + ", " + CSVHeaders.distance + ", " + CSVHeaders.transferSpeed + ", " + CSVHeaders.packageLoss + ", " + CSVHeaders.packageSize + ", " + CSVHeaders.numberOfPackages + "\n" +
        "\(transportProtocol), \(scenario), \(distance), \(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted().replacingOccurrences(of: ",", with: ".")), \(packageLoss.formatted().replacingOccurrences(of: ",", with: ".")), \(sizePerPackage), \(numberOfTotalPackages)"
    }
    
    var description: String {
                """
        \(mbitsPerSecond == nil ? "N/A" : mbitsPerSecond!.formatted()) Mbps
        \(duration == nil ? "N/A" : duration!.formatted()) seconds
        \(packageLoss.formatted()) % package loss 
        
        \(receivedPackages.formatted()) of \(numberOfTotalPackages.formatted()) packages
        \(sizePerPackage) Bytes per package
        \(errors.count) errors
        \(errors.count == 0 ? "" : errors.first!.localizedDescription)
        """
//                Started \(receivedFirstPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedFirstPacketAt!))
//        Ended \(receivedLastPacketAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: receivedLastPacketAt!))
//        Remote started \(remoteFirstPackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remoteFirstPackageWasSentAt!))
//        Remote ended \(remotePackageWasSentAt == nil ? "N/A" : CustomDateFormatter.precise.string(from: remotePackageWasSentAt!))

//        \(receivedBytes.formatted()) bytes received

//        Data transfer report from Network Framework:
//        
//        Interface: \(dataTransferReport.interface.debugDescription)
//        IP Sent: \(dataTransferReport.sentIPPacketCount.formatted())
//        IP Received: \(dataTransferReport.receivedIPPacketCount.formatted())
//        
//        Application Bytes R: \(dataTransferReport.receivedApplicationByteCount.formatted())
//        Application Bytes S: \(dataTransferReport.sentApplicationByteCount.formatted())
//        
//        Transport Bytes R: \(dataTransferReport.receivedTransportByteCount.formatted())
//        Transport Dup Bytes R: \(dataTransferReport.receivedTransportDuplicateByteCount.formatted())
//        Transport OoO Bytes R: \(dataTransferReport.receivedTransportOutOfOrderByteCount.formatted())
//        Transport retrans Bytes R: \(dataTransferReport.retransmittedTransportByteCount.formatted())
//        Transport Bytes S: \(dataTransferReport.sentTransportByteCount.formatted())
//        Transport RTT Min: \(dataTransferReport.transportMinimumRTT.formatted())
//        Transport RTT Variance: \(dataTransferReport.transportRTTVariance.formatted())
//        Transport RTT smoothed: \(dataTransferReport.transportSmoothedRTT.formatted())
//        RadioType: \(dataTransferReport.radioType.debugDescription)
//        
    }
}
