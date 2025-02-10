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
        var advertiserNames = [String]()
        var isShowingBrowserView: Bool = true
        var testResults: [TransportProtocol: String] = [:]
    }
    
    enum Action {
        case onAppear
        case onTapOnAdvertiserName(String)
        case onStartTestingButtonPressed
    }
    
    @Published
    private(set) var state: State
    private(set) var clients: [any Client] = []
    private var testResultsTasks = Set<Task<Void, Never>>()
    private var browseResultsTasks = Set<Task<Void, Never>>()

    init(state: State = .init(), clients: [any Client] = Config.clients) {
        self.state = state
        self.clients = clients
    }
    
    deinit {
        cancelRunningTasks()
    }
    
    private func cancelRunningTasks() {
        testResultsTasks.forEach { $0.cancel() }
        browseResultsTasks.forEach { $0.cancel() }
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case .onAppear:
            cancelRunningTasks()
            listenToBrowserResults()
            listenToTestResults()
            for client in clients {
                client.startBrowsing()
            }

        case let .onTapOnAdvertiserName(advertiserName):
            for client in clients {
                if let browserResult = client.browserResults.value.first(where: { $0.name == advertiserName }) {
                    client.createConnection(with: browserResult)
                }
            }
            
        case .onStartTestingButtonPressed:
            for client in clients {
                client.startTesting()
            }
        }
    }
}

extension ClientViewModel {
    func listenToBrowserResults() {
        for client in clients {
            browseResultsTasks.insert(
                Task { @MainActor in
                    for await browseResults in client.browserResults.values {
                        state.advertiserNames.append(contentsOf: browseResults.compactMap { $0.name })
                        state.advertiserNames = state.advertiserNames.removingDuplicates()
                    }
                }
            )
        }
    }
    
    func listenToTestResults() {
        for client in clients {
            testResultsTasks.insert(
                Task { @MainActor in
                    for await testResult in client.status.values {
                        state.testResults[client.transportProtocol] = testResult?.description ?? "No Result for this protocol."
                        if testResult != nil {
                            state.isShowingBrowserView = false
                        }
                    }
                }
            )
        }
    }
}

extension [String] {
    func removingDuplicates() -> Self {
        var buffer = Set<String>()
        
        return self.filter { buffer.insert($0).inserted }
    }
}
