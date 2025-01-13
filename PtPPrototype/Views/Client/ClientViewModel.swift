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
        var isShowingClientView: Bool = false
    }
    
    enum Action {
        case onAppear
        case onTapOnAdvertiserName(String)
        case onStartTestingButtonPressed
    }
    
    @Published
    private(set) var state: State
    
    private(set) var clients: [any Client] = []
    
    private var tasks: Set<Task<Void, Never>> = []
    
    init(state: State = .init(), client: any Client = Config.client) {
        self.state = state
        self.clients.append(client)
        listenToClient()
    }
    
    deinit {
        tasks.forEach { $0.cancel() }
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case .onAppear:
            for client in clients {
                client.startBrowsing()
            }
            
        case let .onTapOnAdvertiserName(advertiserName):
            for client in clients {
                guard let browserResult = client.browserResults.value.first(where: {
                    if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = $0.endpoint {
                        return  name.hasPrefix(advertiserName)
                    }
                    
                    return false
                }) else { return }
                
                client.createConnection(with: browserResult)
            }
            
            state.isShowingClientView =  true
            
        case .onStartTestingButtonPressed:
            for client in clients {
                client.startTesting()
            }
        }
    }
    
    func listenToClient() {
        let task1 = Task { @MainActor in
            for client in clients {
                for await results in client.browserResults.values {
                    state.advertiserNames = results.map {
                        if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = $0.endpoint {
                            return name
                        }
                        
                        return "no info"
                    }
                }
            }
        }
        
        tasks.insert(task1)
    }
}

extension ClientViewModel {
    struct BrowseResult: Hashable {
        let advertiserName: String
        let networkBrowseResult: NWBrowser.Result
    }
}
