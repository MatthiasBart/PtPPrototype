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
    var connection: NWConnection
    
    var state: CurrentValueSubject<NWConnection.State, Never>
    var message: CurrentValueSubject<Data, Never>
    
    required init(_ connection: NWConnection) {
        self.connection = connection
        self.state = .init(connection.state)
        self.message = .init(Data())
        setupConnection()
    }

    func startTesting(numberOfBytes: Int, splitSize: Int) async throws {
        let allData: [UInt8] = Array(repeating: 61, count: numberOfBytes)
        let dataSliced = allData.split(into: splitSize)
//        connection.startDataTransferReport() TODO

        for slice in dataSliced {
            var data = Data()
            data.append(contentsOf: slice)
            connection.send(content: data, completion: .contentProcessed({ print($0) }))
        }
    }
    
    func receiveMessage() {
        connection.receiveMessage { content, contentContext, isComplete, error in
            if let content {
                self.message.value.append(content)
            }
            
            if error == nil {
                self.receiveMessage()
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
                self?.receiveMessage()
                
            default:
                break
            }
            
            self?.state.send(state)
        }
        self.connection.start(queue: .main)
    }
}
