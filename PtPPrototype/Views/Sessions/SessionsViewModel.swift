//
//  SessionsViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import SwiftUI

class SessionsViewModel: ObservableObject, AsyncViewModel {
    struct State {
        var sessions: [SessionImpl] = []
    }
    
    @Published
    private(set) var state: State
    
    private let service: MCService
    
    private var tasks: Set<Task<Void, Never>> = []
    
    init(state: State = .init(), service: MCService = Config.service) {
        self.state = state
        self.service = service
        listenToService()
    }
    
    deinit {
        tasks.forEach {
            $0.cancel()
        }
    }
    
    private func listenToService() {
        let task = Task { @MainActor in
            for await sessions in service.sessions.values {
                state.sessions = sessions
            }
        }
        
        tasks.insert(task)
    }
}