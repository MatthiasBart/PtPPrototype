//
//  AsyncViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Foundation

protocol AsyncViewModel {
    associatedtype State
    associatedtype Action = Never
    
    var state: State { get }
    
    func action(_ action: Action) async
}

extension AsyncViewModel {
    func send(_ action: Action) {
        Task { @MainActor in
            await self.action(action)
        }
    }
    
    func action(_ action: Action) async {
        //Default implementation for Viewmodels that dont need Action
    }
}
