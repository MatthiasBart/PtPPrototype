//
//  Session.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity
import Combine
//TODO: currently not in use
protocol Session: Identifiable {
    var messages: CurrentValueSubject<[Message], Never> { get }
    var connectedPeers: [MCPeerID] { get }
}
