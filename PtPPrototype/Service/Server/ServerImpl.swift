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
    var status: CurrentValueSubject<(any CustomStringConvertible)?, Never> = .init(nil)
    
    struct TestResult: CustomStringConvertible {
        let receivedFirstPacketAt: Date
        let receivedBytes: Int
        let receivedLastPacketAt: Date?
        
        var description: String {
            "Received first at: \(receivedFirstPacketAt.formatted(date: .omitted, time: .complete))\n Received: \(receivedBytes) bytes\n Received last at: \(receivedLastPacketAt?.formatted(date: .omitted, time: .complete) ?? "no time info")"
        }
    }
    
    private var listener: NWListener
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
            self?.listenToMessages()
            self?.status.value = "Connection established"
        }
        
        listener.stateUpdateHandler = { state in
            log.info("\(state)")
        }
        
        listener.start(queue: .global())
    }
    
    private var byteCount: Int = 0
    private var receivedFirstPackageAt: Date?
    
    func listenToMessages() {
        guard var connection else { return }
        
        connection.receiveMessageHandler = { [weak self] dataCount in
            if self?.receivedFirstPackageAt == nil {
                self?.receivedFirstPackageAt = .now
            }
            
            if let dataCount {
                self?.byteCount += dataCount
            } else if let receivedFirstPackageAt = self?.receivedFirstPackageAt, let byteCount = self?.byteCount {
                self?.status.value = TestResult(receivedFirstPacketAt: receivedFirstPackageAt, receivedBytes: byteCount, receivedLastPacketAt: .now) 
                self?.byteCount = 0
                self?.receivedFirstPackageAt = nil
            }
        }
    }
}

