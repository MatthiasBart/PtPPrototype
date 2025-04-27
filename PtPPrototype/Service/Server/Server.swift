//
//  Server.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Network
import Combine

protocol Server {
    var transportProtocol: TransportProtocol { get }
    var connectionStatus: CurrentValueSubject<String?, Never> { get }
    func startAdvertising()
    func stopAdvertising()
    func getTestResult() async -> TestResultRepresentable?
}
