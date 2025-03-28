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
    private var connection: (any Connection)?
    private var browser: NWBrowser?
    
    var browserResults = CurrentValueSubject<Set<NWBrowser.Result>, Never>([])
    var testResult: CurrentValueSubject<String?, Never> = .init(nil)
    let transportProtocol: TransportProtocol
    
    init(transportProtocol: TransportProtocol) {
        self.transportProtocol = transportProtocol
        
        self.browser = NWBrowser(
            for: .bonjour(type: transportProtocol.type, domain: nil),
            using: transportProtocol.parameters
        )
    }
    
    func createConnection(with browserResult: NWBrowser.Result?) -> Error? {
        var nwConnection: NWConnection
        if let browserResult {
            nwConnection = NWConnection(to: browserResult.endpoint, using: transportProtocol.parameters)
        } else {
            return URLError(.badURL)
        }
        self.connection?.cancel()
        self.connection = nil
        self.connection = C(nwConnection)
        
        if case let .failed(error) = self.connection?.state {
            return error
        }
        return nil
    }
    
    func startTesting(with packageCount: Int, and packageSize: Int?) async {
        await connection?.startTesting(numberOfPackages: packageCount, packageSizeInByte: packageSize ?? C.payloadSize)
        self.testResult.value = await connection?.collectMetrics()
        connection?.resetMetrics()
    }
    
    func startBrowsing() {
        guard let browser, browser.queue == nil else { return } // assuming this indicates that the browser hasnt been started
        
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
        
        browser.start(queue: .global())
    }
}
