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
                List {
                    ForEach(Array(vm.state.testResult.keys)) { resultProtocol in
                        Section(resultProtocol.rawValue) {
                            Text(vm.state.testResult[resultProtocol] ?? "Protocol not found in test results.")
                        }
                    }
                }
            }
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
