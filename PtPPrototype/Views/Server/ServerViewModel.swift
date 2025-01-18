//
//  ServerViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 03.01.25.
//

import Network
import SwiftUI

class ServerViewModel: ObservableObject, AsyncViewModel {
    struct State {
        var selectedTransportProtocol: TransportProtocol = .tcp
        var testResult: String = "No Result for this protocol."
    }
    
    enum Action {
        case onPickerValueChanged(TransportProtocol)
        case onAppear
    }
    
    @Published
    private(set) var state: State
    private var servers: [any Server] = []
    private var testResultObservingTask: Task<Void, Never>? = nil
    
    deinit {
        testResultObservingTask?.cancel()
    }
    
    init(state: State = .init(), servers: [any Server] = Config.servers) {
        self.state = state
        self.servers = servers
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case let .onPickerValueChanged(selectedTransportProtocol):
            state.selectedTransportProtocol = selectedTransportProtocol
            observeTestResultsOfCurrentlySelectedServer()
            
        case .onAppear:
            for server in servers {
                server.startAdvertising()
            }
            observeTestResultsOfCurrentlySelectedServer()
        }
    }
}

extension ServerViewModel {
    func observeTestResultsOfCurrentlySelectedServer() {
        guard let server = servers.first(where: { $0.transportProtocol == state.selectedTransportProtocol }) else {
            return
        }
        testResultObservingTask?.cancel()
        
        testResultObservingTask = Task { @MainActor in
            for await testResult in server.testResult.values {
                self.state.testResult = testResult?.description ?? "No Result for this protocol."
            }
        }
    }
}
