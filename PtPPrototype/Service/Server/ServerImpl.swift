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
    
    private var messageObservingTask: Task<Void, Never>?
    
    private var receivedFirstPackageAt: Date?
    
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
    
    deinit {
        messageObservingTask?.cancel()
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
    
    func listenToMessages() {
        guard let connection else { return }
        messageObservingTask?.cancel()
        
        messageObservingTask = Task {
            for await message in connection.message.values {
                if let receivedFirstPackageAt {
                    testResult.send(TestResult(receivedFirstPacketAt: receivedFirstPackageAt, receivedBytes: message.count, receivedLastPacketAt: nil))
                } else {
                    print(message.count)
                    testResult.send(TestResult(receivedFirstPacketAt: .now, receivedBytes: message.count, receivedLastPacketAt: nil))
                    receivedFirstPackageAt = .now
                }
            }
        }
    }
}

