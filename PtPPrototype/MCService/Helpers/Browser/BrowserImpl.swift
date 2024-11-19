//
//  BrowserImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class BrowserImpl: MCNearbyServiceBrowser, MCNearbyServiceBrowserDelegate, Browser {
    
    let nearbyPeersToInvite = CurrentValueSubject<[UnconnectedNearbyPeer], Never>([])
    
    override init(
        peer myPeerID: MCPeerID,
        serviceType: String
    ) {
        super.init(peer: myPeerID, serviceType: serviceType)
        self.delegate = self
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        nearbyPeersToInvite.value.append(
            .init(
                peerID: peerID,
                discoveryInfo: info
            )
        )
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        nearbyPeersToInvite.value.removeAll(where: {
            $0.peerID == peerID
        })
    }
}
