//
//  MCService.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 16.11.24.
//

import MultipeerConnectivity
import Combine

protocol MCService: Advertiser {
    var nearbyPeersToInvite: CurrentValueSubject<[UnconnectedNearbyPeer], Never> { get }
    var sessions: CurrentValueSubject<[SessionImpl], Never> { get }
    var myPeerID: MCPeerID { get }
    
    func startBrowsingForPeers()
    func invite(peer: UnconnectedNearbyPeer)
    func accept(_ invitation: Invitation)
    func decline(_ invitation: Invitation)
    func send(_ content: Message.Content, in session: SessionImpl) throws 
}



