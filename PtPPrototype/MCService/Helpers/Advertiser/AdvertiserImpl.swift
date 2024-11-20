//
//  AdvertiserImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class AdvertiserImpl: MCNearbyServiceAdvertiser, MCNearbyServiceAdvertiserDelegate, Advertiser {
    
    let outstandingInvitations = CurrentValueSubject<[Invitation], Never>([])
    
    override init(peer myPeerID: MCPeerID, discoveryInfo info: [String : String]?, serviceType: String) {
        super.init(peer: myPeerID, discoveryInfo: info, serviceType: serviceType)
        self.delegate = self
    }
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        let invitation = Invitation(
            from: peerID,
            with: context,
            handler: invitationHandler
        )
        
        outstandingInvitations.value.append(invitation)
    }
}

