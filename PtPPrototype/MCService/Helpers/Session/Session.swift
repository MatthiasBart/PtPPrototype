//
//  Session.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity
import Combine

protocol Session: Identifiable, MCSession {
    var messages: CurrentValueSubject<[Message], Never> { get }
    var connectedPeers: [MCPeerID] { get }
    init(myPeerID: MCPeerID)
}
