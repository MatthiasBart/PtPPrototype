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
    
    var body: some View {
        VStack {
            if vm.state.isShowingBrowserView {
                BrowserView(advertiserNames: vm.state.advertiserNames) { advertiserName in
                    vm.send(.onTapOnAdvertiserName(advertiserName))
                }
            } else {
                List(Array(vm.state.testResults.keys)) { resultProtocol in
                    Section(resultProtocol.rawValue) {
                        Text(vm.state.testResults[resultProtocol] ?? "Protocol not found in test results.")
                    }
                }
            }
        }
        .onAppear {
            vm.send(.onAppear)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reload") {
                    vm.send(.onReloadButtonPressed)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Testing") {
                    vm.send(.onStartTestingButtonPressed)
                }
            }
        }
    }
}
