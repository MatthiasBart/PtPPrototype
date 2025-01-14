//
//  Server.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Network
import Combine

protocol Server {
    func startAdvertising()
    var connection: (any Connection)? { get }
    var transportProtocol: TransportProtocol { get }
    var testResult: CurrentValueSubject<(any CustomStringConvertible)?, Never> { get }
}
