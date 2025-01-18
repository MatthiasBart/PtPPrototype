//
//  Browser.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Network
import Combine

protocol Client {
    var testResult: CurrentValueSubject<(any CustomStringConvertible)?, Never> { get }
    var browserResults: CurrentValueSubject<Set<NWBrowser.Result>, Never> { get }
    var transportProtocol: TransportProtocol { get }
    
    func startTesting()
    func startBrowsing()
    func createConnection(with browserResult: NWBrowser.Result)
}
