//
//  ResultSaver.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 27.04.25.
//


import Foundation

class ResultSaver {
    static func save(name: String, content: String) {
            do {
                var fileUrl =  try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                fileUrl = fileUrl.appendingPathComponent(name)
                
                try content.data(using: .utf8)?.write(to: fileUrl)
                print("File saved at: \(fileUrl)")
            } catch {
                print("Failed to save file:", error)
            }
    }
}

enum CSVHeaders {
    //General
    static let transportProtocol = "Transport Protocol"
    static let scenario = "Scenario"
    static let packageSize = "Package Size (Bytes)"
    static let numberOfPackages = "Number of Packages"
    static let distance = "Distance (m)"
    
    //Client
    static let avgRTT = "Average RTT (ms)"
    static let jitter = "Jitter (ms)"
    
    //Server
    static let transferSpeed = "Transfer Speed (Mbps)"
    static let duration = "Duration (s)"
    static let packageLoss = "Package Loss (%)"
    
    enum Scenarios: String {
        case field = "Field"
        case city = "Inner City"
        case underground = "Underground"
        case forest = "Forest"
    }
}
