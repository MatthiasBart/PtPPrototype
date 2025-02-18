//
//  ServerView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 03.01.25.
//

import SwiftUI

struct ServerView: View {

    @ObservedObject
    var vm: ServerViewModel
    
    var body: some View {
        VStack {
            List(Config.serviceProtocols) { resultProtocol in
                Section(resultProtocol.rawValue) {
                    Text(vm.state.testResults[resultProtocol] ?? "Protocol not found in test results.")
                    Text(vm.state.connectionStatus[resultProtocol] ?? "No connection established.")
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
                Button("Get Test Results") {
                    vm.send(.onGetTestResultsButtonPressed)
                }
            }
        }
    }
}
