//
//  BrowserImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import Network
import Foundation
import Combine

class ClientImpl<C: Connection>: Client {
    struct TestResult: CustomStringConvertible {
        let startedSendingAt: Date
        let sentBytes: Int
        let endedSendingAt: Date
        
        var description: String {
            "Started at: \(startedSendingAt.formatted(date: .omitted, time: .complete))\n Sent: \(sentBytes) bytes\n Ended at: \(endedSendingAt.formatted(date: .omitted, time: .complete))"
        }
    }
    
    var browserResults = CurrentValueSubject<Set<NWBrowser.Result>, Never>([])
    var connection: (any Connection)?
    var testResult: CurrentValueSubject<(any CustomStringConvertible)?, Never> = .init(nil)
    let transportProtocol: TransportProtocol

    private var browser: NWBrowser
    
    init(transportProtocol: TransportProtocol) {
        self.transportProtocol = transportProtocol
        self.browser = NWBrowser(
            for: .bonjour(type: transportProtocol.type, domain: nil),
            using: transportProtocol.parameters
        )
    }
    
    func startBrowsing() {
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .cancelled:
                log.info("browser cancelled")
                
            case .failed(let error):
                log.error("\(error.localizedDescription)")
                log.info("browser failed")
                
            case .ready:
                log.info("browser ready \(self?.transportProtocol.rawValue ?? "no protocol set")")
                
            case .setup:
                log.info("browser setup")
                
            case .waiting(let error):
                log.info("browser \(error.localizedDescription)")
                log.info("browser waiting")
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.browserResults.send(results)
        }

        browser.start(queue: .main)
    }
     
    func createConnection(with browserResult: NWBrowser.Result) {
        let nwConnection = NWConnection(to: browserResult.endpoint, using: browser.parameters)
        self.connection?.cancel()
        self.connection = nil
        self.connection = C(nwConnection)
    }
    
    func startTesting() {
        Task {
            let numberOfBytesSent = 1024*16
            let startingTime = Date()
            await connection?.startTesting(numberOfBytes: numberOfBytesSent, splitSize: 1)
            testResult.send(TestResult(startedSendingAt: startingTime, sentBytes: numberOfBytesSent, endedSendingAt: .now))
        }
    }
}
