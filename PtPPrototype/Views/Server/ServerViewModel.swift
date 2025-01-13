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
    
    init(state: State = .init(), server: (any Server)? = Config.server) {
        self.state = state
        guard let server else { return }
        self.servers.append(server)
    }
    
    func action(_ action: Action) {
        switch action {
        case let .onPickerValueChanged(selectedTransportProtocol):
            state.selectedTransportProtocol = selectedTransportProtocol
            if let server = servers.first(where: { $0.transportProtocol == selectedTransportProtocol }) {
                state.testResult = server.testResult.value?.description ?? "No Result for this protocol."
            }
            
        case .onAppear:
            for server in servers {
                server.startAdvertising()
            }
        }
    }
}
