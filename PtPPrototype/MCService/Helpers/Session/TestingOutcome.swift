//
//  TestingOutcome.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 30.12.24.
//

import Foundation

enum TestingDataClient: Codable {
    case none
    case started(StartedData)
    case finished(FinishedData)
    
    struct StartedData: Codable {
        let streamOpenedAt: Date
        var firstPackageReceivedAt: Date?
        
        init(streamOpenedAt: Date, firstPackageReceivedAt: Date? = nil) {
            self.streamOpenedAt = streamOpenedAt
            self.firstPackageReceivedAt = firstPackageReceivedAt
        }
    }
    
    struct FinishedData: Codable {
        let streamOpenedAt: Date
        let firstPackageReceivedAt: Date?
        
        let numberOfBytesReceived: Int
        let lastByteReadAt: Date
    }
}

enum TestingDataServer {
    case none
    case started(StartedData)
    case finished(FinishedData)
    
    struct StartedData: Codable {
        let numberOfBytesToSend: Int
        let streamOpenedAt: Date
        var firstPackageSentAt: Date?
        
        init(numberOfBytesToSend: Int, streamOpenedAt: Date, firstPackageSentAt: Date? = nil) {
            self.numberOfBytesToSend = numberOfBytesToSend
            self.streamOpenedAt = streamOpenedAt
            self.firstPackageSentAt = firstPackageSentAt
        }
    }
    
    struct FinishedData: Codable {
        let numberOfBytesToSend: Int
        let streamOpenedAt: Date
        let firstPackageSentAt: Date?
        
        let numberOfBytesSent: Int
        let lastByteSentAt: Date
    }
}
