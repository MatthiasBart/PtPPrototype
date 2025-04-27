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
    
    @FocusState
    var focusState: FocusedTextField?
    
    @State
    var isShowingModificationSheet: Bool = false
    
    enum FocusedTextField: Hashable {
        case numberOfPackages
        case sizePerPackage
        case scenario
        case distance
    }
    
    var body: some View {
        VStack {
            if vm.state.isShowingBrowserView {
                BrowserView(advertiserNames: vm.state.advertiserNames) { advertiserName in
                    vm.send(.onTapOnAdvertiserName(advertiserName))
                }
            } else {
                List(Array(vm.state.testResults.keys).sorted(by: { $0.rawValue < $1.rawValue })) { resultProtocol in
                    Section {
                        Text(vm.state.testResults[resultProtocol]??.description ?? "Protocol not found in test results.")
                    } header: {
                        HStack {
                            Text(resultProtocol.rawValue)
                            
                            Spacer()
                            
                            Button("Save Result") {
                                vm.send(.onSaveResultButtonPressedFor(resultProtocol))
                            }
                            
                            if vm.state.isTesting {
                                ProgressView()
                            } else {
                                Button("Start Test") {
                                    vm.send(.onStartTestingButtonPressedFor(resultProtocol))
                                }
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
        }
        .onAppear {
            vm.send(.onAppear)
        }
        .alert("", isPresented: .constant(vm.state.alertString != nil), actions: {
            Button("OK") {
                vm.send(.onAlertOkButtonPressed)
            }
        }, message: {
            Text(vm.state.alertString ?? "")
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    modificatonSheet
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button("Done") {
                                    focusState = nil
                                }
                            }
                        }
                } label: {
                    Image(systemName: "gear")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Reload") {
                    vm.send(.onReloadButtonPressed)
                }
            }
        }
    }
}

extension ClientView {
    var numberOfPackagesBinding: Binding<String> {
        Binding {
            String(vm.state.numberOfPackages)
        } set: { newValue in
            vm.send(.onNumberOfPackagesChanged(Int(newValue) ?? 0))
        }
    }
    
    var sizePerPackageBinding: Binding<String> {
        Binding {
            String(vm.state.sizeOfPackageInBytes)
        } set: { newValue in
            vm.send(.onSizeOfPackageInBytesChanged(Int(newValue) ?? 0))
        }
    }
    
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

extension ClientView {
    private var modificatonSheet: some View {
        ScrollView {
            Text("Scenario")
            TextField("Underground", text: scenarioBinding)
                .textField(for: $focusState, equals: .scenario)
            
            Divider()
            
            Text("Distance")
            TextField("10", text: distanceBinding)
                .textField(for: $focusState, equals: .distance)
            
            Divider()

            Text("Number of packages to send:")
            TextField("1000", text: numberOfPackagesBinding)
                .textField(for: $focusState, equals: .sizePerPackage)
                .keyboardType(.numberPad)

            Divider()
            
            Text("Bytes per package:")
            TextField("128", text: sizePerPackageBinding)
                .textField(for: $focusState, equals: .sizePerPackage)
                .keyboardType(.numberPad)
        }
    }
}

fileprivate extension View {
    func textField(for focusState: FocusState<ClientView.FocusedTextField?>.Binding, equals: ClientView.FocusedTextField) -> some View {
        focused(focusState, equals: equals)
        .padding()
        .background(Color.systemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
}
