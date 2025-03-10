//
//  TransportProtocol.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 30.12.24.
//

import Foundation
import Network
import Security

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
            quicOptions.alpn = ["test"]
            
            if let identityPath = Bundle.main.path(forResource: "QUICConnect2", ofType: "p12"),
               let identityData = try? Data(contentsOf: URL(fileURLWithPath: identityPath)) {
                
                if let identity = loadIdentityFromPKCS12(p12Path: identityPath, password: "quic") {
                    sec_protocol_options_set_local_identity(quicOptions.securityProtocolOptions, sec_identity_create(identity)!)
                    log.info("local identity set")
                    
                    sec_protocol_options_set_verify_block(quicOptions.securityProtocolOptions, { _, sec_trust, completion in
                        log.info("verify block called")
                        var trust: SecTrust = sec_trust_copy_ref(sec_trust).takeRetainedValue()
                        
                        guard let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
                              let serverCertificate = certificateChain.first else {
                            completion(false)
                            return
                        }
                        
                        var certRef: SecCertificate?
                        let statusCert = SecIdentityCopyCertificate(identity, &certRef)
                        
                        guard statusCert == errSecSuccess, let certificate = certRef else {
                            completion(false)
                            return
                        }
                        
                        let isTrusting = CFEqual(serverCertificate, certificate)
                        if isTrusting {
                            log.info("verify block succeeded")
                        }
                        
                        completion(isTrusting)
                    }, .global())
                }
            }
            
            
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

func loadIdentityFromPKCS12(p12Path: String, password: String) -> SecIdentity? {
    guard let p12Data = try? Data(contentsOf: URL(fileURLWithPath: p12Path)) else {
        print("didnt find p12 file at path")
        return nil
    }
    
    let options: NSDictionary = [kSecImportExportPassphrase as String: password, kSecImportToMemoryOnly as String: kCFBooleanTrue!]
    
    var items: CFArray?
    let status = SecPKCS12Import(p12Data as CFData, options, &items)
    
    if status == 0, let dict = (items as? [[String: Any]])?.first {
        if let identity = dict[kSecImportItemIdentity as String] {
            return identity as! SecIdentity
        } else {
            return nil
        }
    } else {
        return nil
    }
}

func getAddress(for network: Network) -> String? {
    var address: String?

    // Get list of all interfaces on the local machine:
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return nil }
    guard let firstAddr = ifaddr else { return nil }

    // For each interface ...
    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee

        // Check for IPv4 or IPv6 interface:
        let addrFamily = interface.ifa_addr.pointee.sa_family
        if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

            // Check interface name:
            let name = String(cString: interface.ifa_name)
            if name == network.rawValue {

                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
            }
        }
    }
    freeifaddrs(ifaddr)

    return address
}

enum Network: String {
    case wifi = "en0"
    case cellular = "pdp_ip0"
    case awdl = "awdl0"
    //... case ipv4 = "ipv4"
    //... case ipv6 = "ipv6"
}
