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
    var receiveMessageHandler: ((Data?) -> Void)?
    private var delimiter: UInt8 = 0

    required init(_ connection: NWConnection) {
        self.connection = connection
        setupConnection()
    }
    
    func startTesting(numberOfBytes: Int, splitSize: Int) async {
        await self._startTesting(numberOfBytes: numberOfBytes, splitSize: splitSize)
    }
    
    func cancel() {
        self.connection.cancel()
    }
    
    func setupConnection() {
        self.connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                log.info("connection ready")
                self?.receive()
                
            default:
                break
            }
        }
        
        self.connection.start(queue: .main)
    }
}

//MARK: Client
extension ConnectionImpl {
    private func _startTesting(numberOfBytes: Int, splitSize: Int) async {
        await withCheckedContinuation { continuation in
            for _ in stride(from: 0, to: numberOfBytes, by: splitSize) {
                sendPackage(bytes: splitSize)
            }
            continuation.resume()
        }
        
        try? await Task.sleep(for: .seconds(1)) //make sure delimiter doesnt reach before other udp packages
        
        connection.send(content: [delimiter], completion: .contentProcessed({ error in
            if let error {
                log.error("\(error.localizedDescription)")
            }
        }))
    }
    
    private func sendPackage(bytes: Int) {
        var data: [UInt8]? = Array(repeating: 61, count: bytes)
        
        connection.send(content: data, isComplete: true, completion: .contentProcessed( { error in
            if let error {
                log.error("\(error.localizedDescription)")
            }
        }))
        
        data = nil
    }
}

//MARK: Server
extension ConnectionImpl {
    private func receive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { content, contentContext, isComplete, error in
            if let content {
                self.receiveMessageHandler?(content)
                
                if content.last == self.delimiter {
                    self.receiveMessageHandler?(nil)
                }
            }
            
            if let error {
                log.info("Error: \(error), testing stopped")
                self.receiveMessageHandler?(nil)
            } else {
                self.receive()
            }
        }
    }
}
