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
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Text("\(vm.state.scenario)-\(vm.state.distance)m-\(vm.state.numberOfPackages)-\(vm.state.sizeOfPackageInBytes)B")
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
            
            Divider()

            Picker("Number of Packages", selection: numberOfPackagesBinding) {
                ForEach(PackageNumber.allCases) { packageNumber in
                    Text(packageNumber.rawValue)
                        .tag(packageNumber.rawValue)
                }
            }

            Divider()
            
            Picker("Package Size", selection: sizePerPackageBinding) {
                ForEach(PackageSize.allCases) { packageSize in
                    Text(packageSize.rawValue)
                        .tag(packageSize.rawValue)
                }
            }
        }
    }
}

extension View {
    func textField<V>(for focusState: FocusState<V>.Binding, equals: V) -> some View where V: Hashable {
        focused(focusState, equals: equals)
        .padding()
        .background(Color.systemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
    }
}
