//
//  TransportProtocol.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 30.12.24.
//

import Foundation
import Network

enum TransportProtocol: String, CaseIterable, Identifiable {
    case udp
    case tcp
    case quic
    
    var id: String {
        self.rawValue
    }
    
    var parameters: NWParameters {
        switch self {
        case .udp:
            let udpOptions = NWProtocolUDP.Options()
            udpOptions.preferNoChecksum = true
            let parameters = NWParameters(dtls: nil, udp: udpOptions)
            parameters.includePeerToPeer = true
            return parameters
            
        case .tcp:
            let tcpOptions = NWProtocolTCP.Options()
            tcpOptions.enableKeepalive = true
            tcpOptions.keepaliveIdle = 2
            let parameters = NWParameters(tls: nil, tcp: tcpOptions)
            parameters.includePeerToPeer = true
            return parameters
            
        case .quic:
            let quicOptions = NWProtocolQUIC.Options()
            quicOptions.maxDatagramFrameSize = 1024
            let parameters = NWParameters(quic: quicOptions)
            parameters.includePeerToPeer = true
            return parameters
        }
    }
    
    var type: String {
        switch self {
        case .udp:
            "_txtchat._udp"
        case .tcp:
            "_txtchat._tcp"
        case .quic:
            "_txtchat._quic"
        }
    }
}
