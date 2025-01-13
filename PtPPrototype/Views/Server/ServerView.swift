//
//  ServerView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 03.01.25.
//

import SwiftUI

struct ServerView: View {
    @StateObject
    private var vm = ServerViewModel()
    
    var selectedProtocolBinding: Binding<TransportProtocol> {
        Binding {
            vm.state.selectedTransportProtocol
        } set: { selectedTransportProtcol in
            vm.send(.onPickerValueChanged(selectedTransportProtcol))
        }
    }
    
    var body: some View {
        VStack {
            Picker("Protocol", selection: selectedProtocolBinding) {
                ForEach(TransportProtocol.allCases) { tprotocol in
                    Text(tprotocol.rawValue)
                        .tag(tprotocol)
                }
            }
             .pickerStyle(.segmented)
            
            Text(vm.state.testResult)
        }
        .onAppear {
            vm.send(.onAppear)
        }
    }
    
    func testResults() -> some View {
        Text("Test results")
    }
}
