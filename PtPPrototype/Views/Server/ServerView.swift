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
    
    enum FocusedTextField {
        case scenario
        case distance
    }
    
    @FocusState
    private var focusState: FocusedTextField?
    
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
        .alert("", isPresented: .constant(vm.state.alertString != nil), actions: {
            Button("OK") {
                vm.send(.onAlertOKButtonPressed)
            }
        }, message: {
            Text(vm.state.alertString ?? "")
        })
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
                NavigationLink {
                    modificatonSheet
                } label: {
                    Image(systemName: "gear")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                VStack {
                    Text("\(vm.state.scenario)-\(vm.state.distance)")
                    
                    HStack {
                        Button("Get All") {
                            vm.send(.onGetAllButtonPressed)
                        }
                        
                        Divider()
                        
                        Button("Save All") {
                            vm.send(.onSaveAllButtonPressed)
                        }
                    }
                }
            }
        }
    }
}

extension ServerView {
var scenarioBinding: Binding<String> {
    Binding {
        vm.state.scenario
    } set: { newValue in
        vm.send(.onScenarioChanged(newValue))
    }
}

var distanceBinding: Binding<String> {
    Binding {
        vm.state.distance
    } set: { newValue in
        vm.send(.onDistanceChanged(newValue))
    }
}
}

extension ServerView {
    private var modificatonSheet: some View {
        ScrollView {
            Picker("Scenario", selection: scenarioBinding) {
                ForEach(Scenario.allCases) { scenario in
                    Text(scenario.rawValue)
                        .tag(scenario.rawValue)
                }
            }
            
            Divider()
            
            Picker("Distance", selection: distanceBinding) {
                ForEach(Distance.allCases) { distance in
                    Text(distance.rawValue)
                        .tag(distance.rawValue)
                }
            }
        }
    }
}
