//
//  ChatViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 18.11.24.
//

import SwiftUI

class ChatViewModel: ObservableObject, AsyncViewModel {
    struct State {
        var messages: [Message] = []
        var currentMessage: String = ""
        var error: Error?
        var isKeyBoardVisible: Bool = false
    }
    
    enum Action {
        case onAppear
        case onCurrentMessageChanged(String)
        case onSendButtonClicked
        case onErrorClickOk
    }
    
    @Published
    private(set) var state: State
    
    let session: SessionImpl
    
    private let service: MCService

    init(state: State = .init(), session: SessionImpl, service: MCService = Config.service) {
        self.state = state
        self.session = session
        self.service = service
    }
    
    @MainActor
    func action(_ action: Action) async {
        switch action {
        case .onAppear:
            for await messages in session.messages.values {
                state.messages = messages
            }
            
        case let .onCurrentMessageChanged(messageString):
            state.currentMessage = messageString
            
        case .onSendButtonClicked:
            guard !state.currentMessage.isEmpty else { return }
            
            do {
                try service.send(
                    .text(.init(text: state.currentMessage)),
                    in: session
                )
                
                state.isKeyBoardVisible = false
                state.currentMessage = ""
            } catch {
                state.error = error
            }
            
        case .onErrorClickOk:
            state.error = nil
        }
    }
}
