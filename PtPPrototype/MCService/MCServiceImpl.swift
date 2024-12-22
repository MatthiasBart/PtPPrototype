//
//  MCServiceImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class MCServiceImpl: NSObject, MCService {
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
    
    var sessions = CurrentValueSubject<[SessionImpl], Never>([])
    
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
        let session = SessionImpl(myPeerID: myPeerID)
        
        browser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: 5)
        
        sessions.value.append(session)
    }
    
    func accept(_ invitation: Invitation) {
        let session = SessionImpl(myPeerID: myPeerID)
        
        invitation.handler(true, session)
        
        sessions.value.append(session)
    }
    
    func decline(_ invitation: Invitation) {
        invitation.handler(false, nil)
    }
    
    func send(_ content: Message.Content, in session: SessionImpl) throws {
        let data = try JSONEncoder().encode(content)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        session.messages.value.append(.local(content))
    }
    
    func startTesting(for session: SessionImpl, numberOfBytes: Int = 1024 * 1024, split: Int = 1) throws {
        guard let otherPeer = session.connectedPeers.first else { return }
        let stream = try session.startStream(withName: "test", toPeer: otherPeer)
        stream.open()
        
        let data: [UInt8] = Array(repeating: 61, count: numberOfBytes)
        
        //data.count is number of bytes, since UInt8 has the size of a byte
        for byte in data {
            if stream.write(data, maxLength: data.count) < 0 {
                if let streamError = stream.streamError {
                    throw streamError
                } else {
                    throw MCServiceError.streamWriteError
                }
            }
        }
    }
}
