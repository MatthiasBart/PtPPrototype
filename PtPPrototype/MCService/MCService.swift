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
    func startTesting(for: SessionImpl, numberOfBytes: Int, splitSize: Int) throws -> [Error?]
    func invite(peer: UnconnectedNearbyPeer)
    func accept(_ invitation: Invitation)
    func decline(_ invitation: Invitation)
    func send(_ content: Message.Content, in session: SessionImpl) throws 
}

//MARK: interesting for thesis
// can lead to indifinete calling loop when not implemented -> BAD, and when interface changes, the adaptee doesnt notice
// https://medium.com/@georgetsifrikas/swift-protocols-with-default-values-b7278d3eef22
extension MCService {
    func startTesting(for session: SessionImpl, numberOfBytes: Int = 1024 * 1024, splitSize: Int = 1) throws -> [Error?] {
        try startTesting(for: session, numberOfBytes: numberOfBytes, splitSize: splitSize)
    }
}



