//
//  BrowserImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import Network
import Foundation
import Combine

enum CustomDateFormatter {
    static let precise = {
        $0.dateFormat = "dd.MM HH:mm:ss.SSS"
        return $0
    }(DateFormatter())
}

class ClientImpl<C: Connection>: Client {
    struct TestResult: CustomStringConvertible {
        let startedSendingAt: Date
        let sentBytes: Int
        let endedSendingAt: Date
        
        var description: String {
            "Started at: \(CustomDateFormatter.precise.string(from: startedSendingAt))\nSent: \(sentBytes) bytes\nEnded at: \(CustomDateFormatter.precise.string(from: endedSendingAt))"
        }
    }
    
    var browserResults = CurrentValueSubject<Set<NWBrowser.Result>, Never>([])
    var connection: (any Connection)?
    var status: CurrentValueSubject<(any CustomStringConvertible)?, Never> = .init(nil)
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
        guard browser.queue == nil else { return } // assuming this indicates that the browser hasnt been started
        
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
    
    func startTesting() async {
        let numberOfBytesSent = 1024*32
        let startingTime = Date()
        await connection?.startTesting(numberOfBytes: numberOfBytesSent, splitSize: C.payloadSize)
        status.send(TestResult(startedSendingAt: startingTime, sentBytes: numberOfBytesSent, endedSendingAt: .now))
    }
}
