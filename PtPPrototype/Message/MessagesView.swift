//
//  MessagesView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import SwiftUI

struct MessagesView: View {
    
    @ObservedObject
    var vm: HostViewModel
    
    @State
    private var currentMessage: String = ""
    
    @FocusState
    var textFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            ForEach(vm.state.messages) { message in
                MessageView(message: message)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("Message", text: $currentMessage)
                    .focused($textFieldFocused)
                    .frame(maxWidth: .infinity)
                
                Button {
                    vm.sendMessage(with: currentMessage)
                    currentMessage = ""
                    textFieldFocused = false
                } label: {
                    Image(systemName: "paperplane")
                }
            }
            .padding()
            .overlay(content: {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: .init(lineWidth: 1))
                    .foregroundStyle(.tertiary)
            })
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

#Preview {
    MessagesView(
        vm: .init(state: .init(messages: [
            .sentText(.init(id: 1, content: "Hello, World!", date: .now)),
            .receivedText(.init(id: 2, content: "Hello, World!", date: .now)),
            .sentText(.init(id: 3, content: "Hello, World!", date: .now)),
            .receivedText(.init(id: 4, content: "Hello, World!", date: .now))
        ])),
        textFieldFocused: .init()
    )
}

struct MessageView: View {
    let message: Message
    
    var body: some View {
        switch message {
        case let .receivedText(text):
            receivedText(text.content, date: text.date)
            
        case let .sentText(text):
            sentText(text.content, date: text.date)
        }
    }
    
    func receivedText(_ text: String, date: Date) -> some View {
        VStack(alignment: .leading) {
            Text(text)
            
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
        .padding()
            .background()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    func sentText(_ text: String, date: Date) -> some View {
        VStack(alignment: .leading) {
            Text(text)
            
            Text(date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
        }
            .padding()
            .foregroundStyle(Color(uiColor: .systemGroupedBackground))
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
