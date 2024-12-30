//
//  Session.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity
import Combine

protocol Session: Identifiable, MCSession {
    init(myPeerID: MCPeerID)
    var messages: CurrentValueSubject<[Message], Never> { get }
    var connectedPeers: [MCPeerID] { get }
    
    func startTesting(numberOfBytes: Int, splitSize: Int) async throws
    func send(_ content: Message.Content) throws
}
