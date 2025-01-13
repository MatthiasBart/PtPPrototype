//
//  ClientView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 03.01.25.
//

import SwiftUI

struct ClientView: View {
    
    @ObservedObject
    var vm: ClientViewModel
    
    @State var selectedProtocol: TransportProtocol = .udp
    
    var body: some View {
        VStack {
            Picker("Protocol", selection: $selectedProtocol) {
                ForEach(TransportProtocol.allCases) { tprotocol in
                    Text(tprotocol.rawValue)
                        .tag(tprotocol)
                }
            }
            .pickerStyle(.segmented)
            
            if let client = vm.clients.first(where: { $0.transportProtocol == selectedProtocol }) {
                Text(client.connection.debugDescription)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Testing") {
                    vm.send(.onStartTestingButtonPressed)
                }
            }
        }
    }
}
