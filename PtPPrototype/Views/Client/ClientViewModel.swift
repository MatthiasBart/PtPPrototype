//
//  ClientViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 06.01.25.
//

import SwiftUI
import Network

class ClientViewModel: ObservableObject, AsyncViewModel {
    
    struct State {
        var advertiserNamesOfSelectedClient = [String]()
        var selectedProtocol: TransportProtocol = .tcp
        var isShowingBrowserView: Bool = true
        var testResult: String = "No Result for this protocol."
    }
    
    enum Action {
        case onAppear
        case onTapOnAdvertiserName(String)
        case onStartTestingButtonPressed
        case onPickerValueChanged(TransportProtocol)
    }
    
    @Published
    private(set) var state: State
    private(set) var clients: [any Client] = []
    private var listenToClientOfSelectedProtocolTask: Task<Void, Never>? = nil
    
    init(state: State = .init(), clients: [any Client] = Config.clients) {
        self.state = state
        self.clients = clients
    }
    
    deinit {
        listenToClientOfSelectedProtocolTask?.cancel()
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case let .onPickerValueChanged(selectedProtocol):
            state.selectedProtocol = selectedProtocol
            state.advertiserNamesOfSelectedClient = []
            listenToClientOfSelectedProtocol()
            
        case .onAppear:
            listenToClientOfSelectedProtocol()
            for client in clients {
                client.startBrowsing()
            }
            
        case let .onTapOnAdvertiserName(advertiserName):
            break
            
        case .onStartTestingButtonPressed:
            for client in clients {
                client.startTesting()
            }
        }
    }
}

extension ClientViewModel {
    func listenToClientOfSelectedProtocol() {
        listenToClientOfSelectedProtocolTask?.cancel()
        
        listenToClientOfSelectedProtocolTask = Task { @MainActor in
            if let clientOfSelectedProtocol = clients.first(where: { $0.transportProtocol == state.selectedProtocol }) {
                state.advertiserNamesOfSelectedClient = clientOfSelectedProtocol.browserResults.value.compactMap { $0.name }
                state.testResult = clientOfSelectedProtocol.testResult.value?.description ?? "No Result for this protocol."

                for await testResult in clientOfSelectedProtocol.testResult.values {
                    state.testResult = testResult?.description ?? "No Result for this protocol."
                    if testResult != nil {
                        state.isShowingBrowserView = false
                    }
                }
                
                
                for await browseResults in clientOfSelectedProtocol.browserResults.values {
                    state.advertiserNamesOfSelectedClient = []
                    for browseResult in browseResults {
                        guard let advertiserName = browseResult.name else { continue }
                        state.advertiserNamesOfSelectedClient.append(advertiserName)
                    }
                }
            }
        }
    }
}

