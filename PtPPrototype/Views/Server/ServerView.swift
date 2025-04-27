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
    
    @State
    private var isShowingModificationSheet = false
    
    var body: some View {
        VStack {
            List(Config.serviceProtocols.sorted(by: { $0.rawValue < $1.rawValue })) { resultProtocol in
                Section {
                    Text(vm.state.testResults[resultProtocol]?.description ?? "Protocol not found in test results.")
                    Text(vm.state.connectionStatus[resultProtocol] ?? "No connection established.")
                } header: {
                    HStack {
                        Text(resultProtocol.rawValue)
                        
                        Spacer()
                        
                        Button("Save Result") {
                            vm.send(.onSaveResultButtonPressedFor(resultProtocol))
                        }
                        
                        Divider()
                        
                        Button("Get Result") {
                            vm.send(.onGetTestResultsButtonPressedFor(resultProtocol))
                        }
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
                Button {
                    isShowingModificationSheet = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}
