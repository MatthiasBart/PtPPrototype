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
    
    func send(_ content: Message.Content, in session: any Session) throws {
        let data = try JSONEncoder().encode(content)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        session.messages.value.append(.local(content))
    }
    
    func startTesting(for session: any Session, numberOfBytes: Int, splitSize: Int) async throws -> [Error?] {
        try await withCheckedThrowingContinuation { continuation in
            do {
                continuation.resume(returning: try startTesting(
                    for: session,
                    numberOfBytes: numberOfBytes,
                    splitSize: splitSize
                ))
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func startTesting(for session: any Session, numberOfBytes: Int, splitSize: Int) throws -> [Error?] {
        addTestingMessage(in: session)
        
        var errors: [Error?] = []
        guard let otherPeer = session.connectedPeers.first else { return errors }
        let stream = try session.startStream(withName: "test", toPeer: otherPeer)
        stream.schedule(in: .main, forMode: .default)
        stream.open()
        
        let data: [UInt8] = Array(repeating: 61, count: numberOfBytes)
        let dataSliced = data.split(into: splitSize)
        
        for slice in dataSliced {
            if stream.write(slice, maxLength: slice.count) < 0 {
                if let streamError = stream.streamError {
                    errors.append(streamError)
                } else {
                    errors.append(MCServiceError.streamWriteError)
                }
            } else {
                errors.append(nil)
            }
        }
        
        stream.close()
        stream.remove(from: .main, forMode: .default)
        
        //nil indicates a success
        return errors
    }
    
    private func addTestingMessage(in session: any Session) {
        let content = Message.Content.text(.init(text: "Started testing"))
        
        session.messages.value.append(.local(content))
    }
}

