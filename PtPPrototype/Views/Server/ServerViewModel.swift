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
        var testResults: [TransportProtocol: String] = [:]
        var connectionStatus: [TransportProtocol: String] = [:]
    }
    
    enum Action {
        case onAppear
        case onReloadButtonPressed
        case onGetTestResultsButtonPressed
    }
    
    @Published
    private(set) var state: State
    private var servers: [any Server] = []
    private var tasks: Set<Task<Void, Never>> = []
    
    deinit {
        cancelRunningTasks()
    }
    
    init(state: State = .init(), servers: [any Server] = Config.servers) {
        self.state = state
        self.servers = servers
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case .onReloadButtonPressed:
            cancelRunningTasks()
            for server in servers {
                server.stopAdvertising()
            }
            self.servers = Config.servers
            await self.action(.onAppear)
            
        case .onAppear:
            cancelRunningTasks()
            observeTestResultsOfServers()
            for server in servers {
                server.startAdvertising()
            }
            
        case .onGetTestResultsButtonPressed:
            for server in servers {
                self.state.testResults[server.transportProtocol] = await server.getTestResult() ?? "N/A"
            }
        }
    }
}

extension ServerViewModel {
    func cancelRunningTasks() {
        tasks.forEach { $0.cancel() }
    }
    
    func observeTestResultsOfServers() {
        for server in servers {
            tasks.insert(
                Task { @MainActor in
                    for await status in server.connectionStatus.values {
                        self.state.connectionStatus[server.transportProtocol] = status?.description ?? "N/A"
                    }
                }
            )
        }
    }
}
