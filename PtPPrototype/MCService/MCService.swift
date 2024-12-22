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
    func startTesting(for: SessionImpl, numberOfBytes: Int, split: Int) throws
    func invite(peer: UnconnectedNearbyPeer)
    func accept(_ invitation: Invitation)
    func decline(_ invitation: Invitation)
    func send(_ content: Message.Content, in session: SessionImpl) throws 
}

//MARK: interesting for thesis
extension MCService {
    func startTesting(for session: SessionImpl, numberOfBytes: Int = 1024 * 1024, split: Int = 1) throws {
        try startTesting(for: session, numberOfBytes: numberOfBytes, split: split)
    }
}



