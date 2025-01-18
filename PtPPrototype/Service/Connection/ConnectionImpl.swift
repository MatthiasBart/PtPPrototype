//
//  ConnectionImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import Network
import Combine
import Foundation

class ConnectionImpl: Connection {
    private var connection: NWConnection
    var state: CurrentValueSubject<NWConnection.State, Never>
    var receiveMessageHandler: ((Data?) -> Void)?

    required init(_ connection: NWConnection) {
        self.connection = connection
        self.state = .init(connection.state)
        setupConnection()
    }
    
    func startTesting(numberOfBytes: Int, splitSize: Int) async {
        await withCheckedContinuation { continuation in
            self._startTesting(numberOfBytes: numberOfBytes, splitSize: splitSize)
            continuation.resume()
        }
    }
    
    func cancel() {
        self.connection.cancel()
    }
    
    func setupConnection() {
        self.connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                log.info("connection ready")
                self?.receiveMessage()
                
            default:
                break
            }
            
            self?.state.send(state)
        }
        self.connection.start(queue: .main)
    }
}

//MARK: Client
extension ConnectionImpl {
    private func _startTesting(numberOfBytes: Int, splitSize: Int) {
        for _ in stride(from: 0, to: numberOfBytes, by: splitSize) {
            sendPackage(bytes: splitSize)
        }
    }
    
    private func sendPackage(bytes: Int) {
        let data: [UInt8] = Array(repeating: 61, count: bytes)
        
        connection.send(content: data, completion: .contentProcessed( { error in
            if let error {
                print(error)
            }
        }))
    }
}

//MARK: Server
extension ConnectionImpl {
    private func receiveMessage() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content {
                self.receiveMessageHandler?(content)
            }
            
            if let error {
                log.info("Error: \(error), testing stopped")
                self.receiveMessageHandler?(nil)
            } else {
                self.receiveMessage()
            }
        }
    }
}
