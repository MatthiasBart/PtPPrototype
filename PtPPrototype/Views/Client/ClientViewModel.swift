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
        var testResults: [TransportProtocol: TestResultRepresentable?] = [:]
        var numberOfPackages: Int = Int(PackageNumber.number100.rawValue)!
        var sizeOfPackageInBytes: Int = Int(PackageSize.size128.rawValue)!
        var isTesting: Bool = false
        var scenario: String = Scenario.innerCity.rawValue
        var distance: String = Distance.meter1.rawValue
        var alertString: String? = nil
        var testCount = 0
    }
    
    enum Action {
        case onAppear
        case onTapOnAdvertiserName(String)
        case onStartTestingButtonPressedFor(TransportProtocol)
        case onSaveResultButtonPressedFor(TransportProtocol)
        case onReloadButtonPressed
        
        case onNumberOfPackagesChanged(Int)
        case onSizeOfPackageInBytesChanged(Int)
        case onScenarioChanged(String)
        case onDistanceChanged(String)
        case onAlertOkButtonPressed
        case onSaveAllButtonPressed
        case onTestAllButtonPressed
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
        testResultsTasks = []
        browseResultsTasks = []
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case .onSaveAllButtonPressed:
            for (transportProtocol, result) in state.testResults {
                guard let result else {
                    state.alertString = "Error: No results for \(transportProtocol.rawValue)"
                    break
                }
                
                let fileName = "Client-\(transportProtocol.rawValue.uppercased())-\(state.scenario)-\(state.distance)-\(Date.now.formatted(date: .numeric, time: .standard)).csv"
                
                do {
                    try ResultSaver.save(
                        name: fileName,
                        content: result.toCSV(
                            in: state.scenario,
                            with: state.distance,
                            using: transportProtocol.rawValue.uppercased()
                        )
                    )
                } catch {
                    state.alertString = "Error while saving \(transportProtocol.rawValue)"
                    break
                }
            }
            if state.alertString == nil {
                state.alertString = "Results saved!"
            }
            
        case let .onSaveResultButtonPressedFor(transportProtocol):
            if let result = state.testResults.first(where: { $0.key == transportProtocol })?.value {
                let fileName = "Client-\(transportProtocol.rawValue.uppercased())-\(state.scenario)-\(state.distance)-\(Date.now.formatted(date: .numeric, time: .standard)).csv"
                
                do {
                    try ResultSaver.save(
                        name: fileName,
                        content: result.toCSV(
                            in: state.scenario,
                            with: state.distance,
                            using: transportProtocol.rawValue.uppercased()
                        )
                    )
                    state.alertString = "File saved"
                } catch {
                    state.alertString = "Error while saving \(transportProtocol.rawValue)"
                }
            }
            
        case .onReloadButtonPressed:
            cancelRunningTasks()
            state.isShowingBrowserView = true
            state.advertiserNames = []
            state.testResults = [:]
            state.isTesting = false
            self.clients = Config.clients
            await self.action(.onAppear)
            
        case .onAppear:
            cancelRunningTasks()
            listenToBrowserResults()
            listenToTestResults()
            for client in clients {
                client.startBrowsing()
            }

        case let .onTapOnAdvertiserName(advertiserName):
            state.isShowingBrowserView = false
            for client in clients {
                if let browserResult = client.browserResults.value.first(where: { $0.name == advertiserName }) {
                    if client.createConnection(with: browserResult) == nil {
                        state.testResults[client.transportProtocol] = .empty
                    } else {
                        state.alertString = "Connection refused for \(client.transportProtocol)"
                    }
                }
            }
            
        case let .onStartTestingButtonPressedFor(transportProtocol):
            guard state.testResults.contains(where: { $0.key == transportProtocol }) else { return }
            state.isTesting = true
            if let client = clients.first(where: { $0.transportProtocol == transportProtocol }) {
                await client.startTesting(with: state.numberOfPackages, and: state.sizeOfPackageInBytes)
            }
            state.testCount += 1
            state.isTesting = false
            
        case .onNumberOfPackagesChanged(let count):
            state.numberOfPackages = count
            state.testCount = 0
            
        case .onSizeOfPackageInBytesChanged(let size):
            state.sizeOfPackageInBytes = size
            state.testCount = 0

        case .onDistanceChanged(let distance):
            state.distance = distance
            state.testCount = 0

        case .onScenarioChanged(let scenario):
            state.scenario = scenario
            state.testCount = 0
            
        case .onTestAllButtonPressed:
            for client in clients {
                await self.action(.onStartTestingButtonPressedFor(client.transportProtocol))
            }

        case .onAlertOkButtonPressed:
            state.alertString = nil
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
                    for await testResult in client.testResult.values {
                        state.testResults[client.transportProtocol] = testResult
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
