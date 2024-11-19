//
//  ChatView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 18.11.24.
//

import SwiftUI

struct ChatView: View {
    
    @StateObject
    var vm: ChatViewModel
    
    var body: some View {
        ScrollView {
            ForEach(vm.state.messages) { message in
                MessageView(message: message)
            }
        }
        .task {
            await vm.action(.onAppear)
        }
        .frame(maxWidth: .infinity)
        .background(Color.systemGroupedBackground)
        .safeAreaInset(edge: .bottom, content: {
            textField
                .padding()
                .background(.ultraThinMaterial)
        })
        .navigationTitle("Chat")
        .alert("An Error occured", isPresented: .constant(vm.state.error != nil)) {
            Button("OK") {
                vm.send(.onErrorClickOk)
            }
        }
    }
    
    var textField: some View {
        HStack {
            TextField("Message", text: currentMessageBinding)
            
            Button {
                vm.send(.onSendButtonClicked)
            } label: {
                Image(systemName: "paperplane")
            }
        }
        .padding()
        .background(Color.systemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let messages: [Message] = [
                .local(.text(.init(id: "1", date: .now, peerDisplayName: "iPhone", text: "Hello"))),
                .remote(.text(.init(id: "2", date: .now, peerDisplayName: "iPad", text: "Hello"))),
                .remote(.data(.init(id: "3", date: .now, peerDisplayName: "iPad", data: "Hello world".data(using: .utf8)!)))
            ]
    
    ChatView(vm: .init(
        state: .init(
            messages: messages
        ),
        session: .init(myPeerID: .init(displayName: "hello")))
    )
}

extension ChatView {
    var currentMessageBinding: Binding<String> {
        Binding {
            vm.state.currentMessage
        } set: { newValue in
            vm.send(.onCurrentMessageChanged(newValue))
        }
    }
}
