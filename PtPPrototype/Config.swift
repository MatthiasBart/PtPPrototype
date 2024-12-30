//
//  Config.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import MultipeerConnectivity

struct Config {
    private static let serviceType = "txtchat"
    static let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    static let service: MCService = MCServiceImpl<SessionImpl>(
        browser: BrowserImpl(peer: myPeerID, serviceType: serviceType),
        advertiser: AdvertiserImpl(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType),
        myPeerID: myPeerID
    )
}
