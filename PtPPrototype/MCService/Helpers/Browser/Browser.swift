//
//  Browser.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity
import Combine

protocol Browser {
    var nearbyPeersToInvite: CurrentValueSubject<[UnconnectedNearbyPeer], Never> { get }
    
    func startBrowsingForPeers()
    func invitePeer(_ peerID: MCPeerID, to session: MCSession, withContext context: Data?, timeout: TimeInterval)
}
