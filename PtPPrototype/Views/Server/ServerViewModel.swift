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
        var testResults: [TransportProtocol: TestResultRepresentable] = [:]
        var connectionStatus: [TransportProtocol: String] = [:]
        
        var scenario: String = ""
        var distance: String = ""
        
        var alertString: String? = nil
    }
    
    enum Action {
        case onAppear
        case onReloadButtonPressed
        case onGetTestResultsButtonPressedFor(TransportProtocol)
        case onSaveResultButtonPressedFor(TransportProtocol)
        case onAlertOKButtonPressed
        case onScenarioChanged(String)
        case onDistanceChanged(String)
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
        case .onScenarioChanged(let scenario):
            state.scenario = scenario
            
        case .onDistanceChanged(let distance):
            state.distance = distance
            
        case .onAlertOKButtonPressed:
            state.alertString = nil
            
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
            
        case let .onSaveResultButtonPressedFor(transportProtocol):
            if let result = state.testResults.first(where: { $0.key == transportProtocol })?.value {
                let fileName = "Server-\(transportProtocol.rawValue.uppercased())-\(state.scenario)-\(state.distance)-\(Date.now.formatted(date: .numeric, time: .standard)).csv"
                
                ResultSaver.save(
                    name: fileName,
                    content: result.toCSV(
                        in: state.scenario,
                        with: state.distance,
                        using: transportProtocol.rawValue.uppercased()
                    )
                )
                
                state.alertString = "File saved"
            }

        case let .onGetTestResultsButtonPressedFor(transportProtocol):
            if let server = servers.first(where: { $0.transportProtocol == transportProtocol }) {
                self.state.testResults[server.transportProtocol] = await server.getTestResult()
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
