//
//  BrowserView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 06.01.25.
//

import SwiftUI
import Network

struct BrowserView: View {
    
    @StateObject
    private var vm = ClientViewModel()
    
    var body: some View {
        if vm.state.isShowingClientView {
            ClientView(vm: vm)
        } else {
            if vm.state.advertiserNames.isEmpty {
                ProgressView()
                    .onAppear {
                        vm.send(.onAppear)
                    }
            }
            
            List(vm.state.advertiserNames) { advertiserName in
                Button(advertiserName) {
                    vm.send(.onTapOnAdvertiserName(advertiserName))
                }
            }
            .navigationTitle("Browsing Results")
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: Self { self }
}
