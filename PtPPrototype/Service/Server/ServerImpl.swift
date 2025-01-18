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
    var connection: (any Connection)?
    var testResult: CurrentValueSubject<(any CustomStringConvertible)?, Never> = .init(nil)
    
    struct TestResult: CustomStringConvertible {
        let receivedFirstPacketAt: Date
        let receivedBytes: Int
        let receivedLastPacketAt: Date?
        
        var description: String {
            "Received first packet at \(receivedFirstPacketAt), received \(receivedBytes) bytes, received last packet at \(receivedLastPacketAt?.formatted())"
        }
    }
    
    private var listener: NWListener
    let transportProtocol: TransportProtocol
    
    init(transportProtocol: TransportProtocol) throws {
        self.transportProtocol = transportProtocol
        listener = try NWListener(
            service: .init(
                name: UIDevice.current.name + transportProtocol.rawValue,
                type: transportProtocol.type,
                domain: nil
            ),
            using: transportProtocol.parameters
        )
    }
    
    func startAdvertising() {
        listener.newConnectionHandler = { [weak self] connection in
            if self?.connection == nil {
                self?.connection = C(connection)
                self?.listenToMessages()
            }
        }
        
        listener.stateUpdateHandler = { state in
            log.info("\(state)")
        }
        
        listener.start(queue: .main)
    }
    
    private var byteCount: Int = 0
    private var receivedFirstPackageAt: Date?

    func listenToMessages() {
        guard var connection else { return }
        
        connection.receiveMessage = { [weak self] data in
            if self?.receivedFirstPackageAt == nil {
                self?.receivedFirstPackageAt = .now
            }
            
            if let data {
                self?.byteCount += data.count
            } else if let receivedFirstPackageAt = self?.receivedFirstPackageAt, let byteCount = self?.byteCount {
                self?.testResult.value = TestResult(receivedFirstPacketAt: receivedFirstPackageAt, receivedBytes: byteCount, receivedLastPacketAt: .now)
                self?.byteCount = 0
                self?.receivedFirstPackageAt = nil
            }
        }
    }
}

