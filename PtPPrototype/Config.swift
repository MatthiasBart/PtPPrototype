//
//  Config.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import Network

struct Config {
    static let serviceProcols: [TransportProtocol] = []
    //TODO
    static let client: any Client = ClientImpl<ConnectionImpl>(transportProtocol: .udp)
    static let server: (any Server)? = try? ServerImpl<ConnectionImpl>(transportProtocol: .udp)
}
