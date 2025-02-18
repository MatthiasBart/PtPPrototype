//
//  ServerImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import Network
import Combine
import Foundation
import UIKit

class ServerImpl<C: Connection>: Server {
    private var connection: (any Connection)?
    private var listener: NWListener
    
    var connectionStatus: CurrentValueSubject<String?, Never> = .init(nil)
    let transportProtocol: TransportProtocol
    
    init(transportProtocol: TransportProtocol) throws {
        self.transportProtocol = transportProtocol
        listener = try NWListener(
            service: .init(
                name: UIDevice.current.name,
                type: transportProtocol.type,
                domain: nil
            ),
            using: transportProtocol.parameters
        )
    }
    
    func startAdvertising() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.connection?.cancel()
            self?.connection = nil
            self?.connection = C(connection)
            self?.connectionStatus.value = "Connection established"
        }
        
        listener.stateUpdateHandler = { [weak self] state in
            self?.connectionStatus.value = "\(state)"
        }
        
        listener.start(queue: .global())
    }
    
    func stopAdvertising() {
        listener.cancel()
    }
    
    func getTestResult() async -> String? {
        let metrics = await self.connection?.collectMetrics()
        connection?.resetMetrics()
        return metrics
    }
}

