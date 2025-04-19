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
    }
    
    var body: some View {
        VStack {
            if vm.state.isShowingBrowserView {
                BrowserView(advertiserNames: vm.state.advertiserNames) { advertiserName in
                    vm.send(.onTapOnAdvertiserName(advertiserName))
                }
            } else {
                List(Array(vm.state.testResults.keys)) { resultProtocol in
                    Section {
                        Text(vm.state.testResults[resultProtocol] ?? "Protocol not found in test results.")
                    } header: {
                        HStack {
                            Text(resultProtocol.rawValue)
                            
                            Spacer()
                            
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
        .sheet(isPresented: $isShowingModificationSheet, content: {
            modificatonSheet
                .presentationDetents([.medium, .large])
        })
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingModificationSheet = true
                } label: {
                    Image(systemName: "gear")
                }
            }
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    focusState = nil
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Reload") {
                    vm.send(.onReloadButtonPressed)
                }
                .disabled(vm.state.isTesting)
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
}

extension ClientView {
    private var modificatonSheet: some View {
        VStack {
            Text("Number of packages to send:")
            TextField("1000", text: numberOfPackagesBinding)
                .focused($focusState, equals: .numberOfPackages)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.systemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
            
            Text("Bytes per package:")
            TextField("128", text: sizePerPackageBinding)
                .focused($focusState, equals: .sizePerPackage)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.systemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
    }
}
