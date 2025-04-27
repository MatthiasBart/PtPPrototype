//
//  Connection.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Network
import Combine
import Foundation

protocol Connection: Identifiable {
    init(_ connection: NWConnection)
    var state: NWConnection.State { get }
    
    static var payloadSize: Int { get }
    
    func collectMetrics() async throws -> TestResultRepresentable
    func resetMetrics()
    func startTesting(numberOfPackages: Int, packageSizeInByte: Int) async
    func cancel()
}

//https://stackoverflow.com/questions/38422150/swift-array-extension-for-standard-deviation
extension Array where Element ==  UInt64 {
    func sum() -> Double {
        return Double(self.reduce(0, +))
    }

    func avg() -> Double {
        return self.sum() / Double(self.count)
    }

    func std() -> Double {
        let mean = self.avg()
        let v = self.reduce(0, { Double($0) + (Double($1)-mean)*(Double($1)-mean) })
        return sqrt(Double(v) / Double(self.count - 1))
    }
}
