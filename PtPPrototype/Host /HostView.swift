//
//  HostView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import SwiftUI

struct HostView: View {
    
    @StateObject
    var vm: HostViewModel = .init()
    
    var body: some View {
        List(vm.state.peersConnected) { connectedPeer in
            NavigationLink(connectedPeer.displayName) {
                MessagesView(vm: vm)
            }
        }
        .sheet(isPresented: isPresentingSheetBinding) {
            InfoSheet(vm: vm)
                .presentationDetents(
                    [ .medium, .large]
                )
        }
        .toolbar {
            Menu {
                Button("Set Visible for others") {
                    vm.startAdvertising()
                }
                Button("Look for others") {
                    vm.startBrowsing()
                }
                
            } label: {
                Image(systemName: "gear")
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    vm.setIsInfoSheetPresenting(true)
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}

extension HostView {
    var isPresentingSheetBinding: Binding<Bool> {
        Binding(
            get: { vm.state.isInfoSheetPresenting },
            set: { vm.setIsInfoSheetPresenting($0) }
        )
    }
}

