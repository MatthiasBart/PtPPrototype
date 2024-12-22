//
//  SessionImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class SessionImpl: MCSession, MCSessionDelegate, Session {
    var messages = CurrentValueSubject<[Message], Never>([])
    
    init(myPeerID: MCPeerID, messages: [Message] = []) {
        self.messages.value = messages
        
        super.init(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        self.delegate = self
    }
    
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        switch state {
        case .notConnected:
            log.info("Peer \(peerID.displayName) not connected.")
            
        case .connecting:
            log.info("Peer \(peerID.displayName) connecting.")
            
        case .connected:
            log.info("Peer \(peerID.displayName) connected.")
            
        @unknown default:
            log.error("unknown state")
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        guard let content = try? JSONDecoder().decode(Message.Content.self, from: data) else {
            return
        }
        
        self.messages.value.append(.remote(content))
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        let content = Message.Content.text(.init(text: "Peer began testing: \(streamName)"))
        
        self.messages.value.append(.remote(content))
    }
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        log.warning("didStartReceivingResourceWithName not implemented")
    }
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        log.warning("didFinishReceivingResourceWithName not implemented")
    }
}
