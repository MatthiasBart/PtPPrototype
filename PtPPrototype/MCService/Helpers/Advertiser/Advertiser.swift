//
//  Advertiser.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import MultipeerConnectivity
import Combine


protocol Advertiser {
    var outstandingInvitations: CurrentValueSubject<[Invitation], Never> { get }
    
    func startAdvertisingPeer()
}
