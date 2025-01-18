//
//  ClientView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 03.01.25.
//

import SwiftUI

struct ClientView: View {
    
    @StateObject
    var vm: ClientViewModel = .init()
    
    var selectedProtocolBinding: Binding<TransportProtocol> {
        Binding {
            vm.state.selectedProtocol
        } set: { selectedProtocol in
            vm.send(.onPickerValueChanged(selectedProtocol))
        }
    }
    
    var body: some View {
        VStack {
            Picker("Protocol", selection: selectedProtocolBinding) {
                ForEach(Config.serviceProtocols) { tprotocol in
                    Text(tprotocol.rawValue)
                        .tag(tprotocol)
                }
            }
            .pickerStyle(.segmented)
            
            Spacer()
            
            if vm.state.isShowingBrowserView {
                BrowserView(advertiserNames: vm.state.advertiserNamesOfSelectedClient) { advertiserName in
                    vm.send(.onTapOnAdvertiserName(advertiserName))
                }
            } else {
                Text(vm.state.testResult)
            }
            
            Spacer()
        }
        .onAppear {
            vm.send(.onAppear)
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
