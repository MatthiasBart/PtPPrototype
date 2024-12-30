//
//  MCServiceImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class MCServiceImpl<S: Session>: MCService {
    private let browser: Browser
    private let advertiser: Advertiser
    let myPeerID: MCPeerID
    
    init(
        browser: Browser,
        advertiser: Advertiser,
        myPeerID: MCPeerID
    ) {
        self.browser = browser
        self.advertiser = advertiser
        self.myPeerID = myPeerID
    }
    
    var sessions = CurrentValueSubject<[any Session], Never>([])
    
    var outstandingInvitations: CurrentValueSubject<[Invitation], Never> {
        advertiser.outstandingInvitations
    }
    
    var nearbyPeersToInvite: CurrentValueSubject<[UnconnectedNearbyPeer], Never> {
        browser.nearbyPeersToInvite
    }
    
    func startAdvertisingPeer() {
        advertiser.startAdvertisingPeer()
    }
    
    func startBrowsingForPeers() {
        browser.startBrowsingForPeers()
    }
    
    func invite(peer: UnconnectedNearbyPeer) {
        let session = S(myPeerID: myPeerID)
        
        browser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: 5)
        
        sessions.value.append(session)
    }
    
    func accept(_ invitation: Invitation) {
        let session = S(myPeerID: myPeerID)
        
        invitation.handler(true, session)
        
        sessions.value.append(session)
    }
    
    func decline(_ invitation: Invitation) {
        invitation.handler(false, nil)
    }
}

