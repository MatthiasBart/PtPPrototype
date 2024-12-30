//
//  Invitation.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity

struct Invitation: Identifiable {
    let id: UUID = .init()
    let peerID: MCPeerID
    let context: Data?
    let handler: (Bool, MCSession?) -> Void
    
    init(from peerID: MCPeerID, with context: Data?, handler: @escaping (Bool, MCSession?) -> Void) {
        self.peerID = peerID
        self.context = context
        self.handler = handler
    }
}

extension Invitation: Equatable {
    static func == (lhs: Invitation, rhs: Invitation) -> Bool {
        lhs.id == rhs.id
    }
}
