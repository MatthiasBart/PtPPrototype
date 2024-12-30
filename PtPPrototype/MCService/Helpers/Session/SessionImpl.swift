//
//  SessionImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class SessionImpl: MCSession, MCSessionDelegate, Session, StreamDelegate {
    var messages = CurrentValueSubject<[Message], Never>([])
    
    init(myPeerID: MCPeerID, messages: [Message]) {
        self.messages.value = messages
        
        super.init(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        self.delegate = self
    }
    
    convenience required init(myPeerID: MCPeerID) {
        self.init(myPeerID: myPeerID, messages: [])
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
        
        stream.open()
        stream.schedule(in: .main, forMode: .default)
        stream.delegate = self
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard let stream = aStream as? InputStream else { return }
        
        switch eventCode {
        case .endEncountered:
            addMessage("Testing ended")
            stream.close()
            stream.remove(from: .main, forMode: .default)
            
        case .errorOccurred:
            addMessage("Error occured")
        case .openCompleted:
            addMessage("Testing stream opened")
        case .hasBytesAvailable:
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read < 0 {
                    addMessage("Error while reading stream")
                } else if read > 0 {
                    for offset in 0..<read {
                        print(buffer[offset])
                    }
                }
            }
            
        default:
            break
        }
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

extension SessionImpl {
    func addMessage(_ text: String) {
        let content = Message.Content.text(.init(text: text))
        self.messages.value.append(.remote(content))
    }
}
