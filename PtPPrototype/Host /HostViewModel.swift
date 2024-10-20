//
//  HostViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import Foundation
import MultipeerConnectivity

class HostViewModel: NSObject, ObservableObject {
    let browser: MCNearbyServiceBrowser
    let advertiser: MCNearbyServiceAdvertiser
    let session: MCSession
    let peerID: MCPeerID
    
    struct State {
        var peersToInvite: [MCPeerID] = []
        var peersConnecting: [MCPeerID] = []
        var peersConnected: [MCPeerID] = []
        var peersLost: [MCPeerID] = []
        var invitationsFrom: [MCPeerID: (Bool, MCSession?) -> Void] = [:]
        
        var isInfoSheetPresenting: Bool = false
        
        var messages: [Message] = []
    }
    
    @Published
    private(set) var state: State
    
    init(state: State = .init()) {
        self.peerID = .init(displayName: UIDevice.current.name)
        self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: Config.serviceType)
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: Config.serviceType)
        self.session = MCSession(peer: self.peerID)
        self.state = state
    }
    
    func startBrowsing() {
        self.browser.delegate = self
        self.session.delegate = self
        self.browser.startBrowsingForPeers()
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        self.browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 5)
    }
    
     func startAdvertising() {
         self.advertiser.delegate = self
         self.session.delegate = self
         self.advertiser.startAdvertisingPeer()
     }
     
     func joinSession(from peerID: MCPeerID) {
         if let invitationHandler = state.invitationsFrom[peerID] {
             invitationHandler(true, self.session)
         }
     }
     
     func declineSession(from peerID: MCPeerID) {
         if let invitationHandler = state.invitationsFrom[peerID] {
             invitationHandler(false, nil)
         }
     }
    
    func setIsInfoSheetPresenting(_ isPresenting: Bool) {
        state.isInfoSheetPresenting = isPresenting
    }
    
    func sendMessage(with text: String) {
        let txtMessage = TextMessage(id: self.state.messages.count, content: text, date: .now)
        
        if let data = try? JSONEncoder().encode(txtMessage) {
            try? self.session.send(
                data,
                toPeers: self.session.connectedPeers,
                with: .reliable
            )
            
            self.state.messages.append(.sentText(txtMessage))
        }
    }
}

extension HostViewModel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        state.invitationsFrom[peerID] = invitationHandler
    }
}

extension HostViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        state.peersToInvite.append(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        state.peersConnected.removeAll { $0 == peerID }
        state.peersLost.append(peerID)
    }
}

extension HostViewModel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .notConnected:
                print("Peer: \(peerID.displayName) notConnected")
            case .connecting:
                print("connecting to \(peerID.displayName)")
                self.state.peersConnecting.append(peerID)
            case .connected:
                print("connected to \(peerID.displayName)")
                self.state.peersConnecting.removeAll { $0 == peerID }
                self.state.peersConnected = session.connectedPeers
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        
        if let textMessage = try? decoder.decode(TextMessage.self, from: data) {
            self.state.messages.append(.receivedText(textMessage))
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream from \(peerID.displayName): \(streamName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("started to receive resource: \(resourceName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        print("ended to receive resource: \(resourceName)")
    }
}

