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
        var status: [TransportProtocol: String] = [:]
    }
    
    enum Action {
        case onAppear
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
        case .onAppear:
            cancelRunningTasks()
            observeTestResultsOfServers()
            for server in servers {
                server.startAdvertising()
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
                    for await status in server.status.values {
                        self.state.status[server.transportProtocol] = status?.description ?? "N/A"
                    }
                }
            )
        }
    }
}
