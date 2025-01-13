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
    var state: CurrentValueSubject<NWConnection.State, Never> { get }
    var message: CurrentValueSubject<Data, Never> { get }
    func cancel()
    func startTesting(numberOfBytes: Int, splitSize: Int) async throws
}
