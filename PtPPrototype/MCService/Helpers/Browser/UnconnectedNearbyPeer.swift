//
//  UnconnectedNearbyPeer.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity

struct UnconnectedNearbyPeer: Identifiable {
    let id: UUID = .init()
    let peerID: MCPeerID
    let discoveryInfo: [String: String]?
}
