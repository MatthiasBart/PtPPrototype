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
            List(Array(vm.state.status.keys)) { resultProtocol in
                Section(resultProtocol.rawValue) {
                    Text(vm.state.status[resultProtocol] ?? "Protocol not found in test results.")
                }
            }
        }
        .onAppear {
            vm.send(.onAppear)
        }
    }
}
