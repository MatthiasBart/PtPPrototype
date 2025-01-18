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
    var receiveMessage: ((Data?) -> Void)?

    required init(_ connection: NWConnection) {
        self.connection = connection
        self.state = .init(connection.state)
        setupConnection()
    }
    
    private func startTesting(numberOfBytes: Int, splitSize: Int) {
        var allData: [UInt8] = Array(repeating: 61, count: numberOfBytes)
        var dataSliced = allData.split(into: splitSize)
        allData = []
//        connection.startDataTransferReport() TODO

        for slice in dataSliced {
            connection.send(content: slice, completion: .contentProcessed({ error in
                if let error {
                    print(error)
                }
            }))
        }
        
        dataSliced = []
    }

    func startTesting(numberOfBytes: Int, splitSize: Int) async {
        await withCheckedContinuation { continuation in
            self.startTesting(numberOfBytes: numberOfBytes, splitSize: splitSize)
            continuation.resume()
        }
    }
    
    func _receiveMessage() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content {
                self.receiveMessage?(content)
            }
            
            if error == nil {
                self._receiveMessage()
            } else {
                self.receiveMessage?(nil)
            }
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
                self?._receiveMessage()
                
            default:
                break
            }
            
            self?.state.send(state)
        }
        self.connection.start(queue: .main)
    }
}
