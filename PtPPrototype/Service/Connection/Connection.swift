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
    func cancel()
    var receiveMessageHandler: ((Int?) -> Void)? { get set }
    func startTesting(numberOfBytes: Int, splitSize: Int) async
}
