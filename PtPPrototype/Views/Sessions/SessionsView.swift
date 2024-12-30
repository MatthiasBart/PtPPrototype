//
//  SessionsView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import SwiftUI

struct SessionsView: View {
    
    @ObservedObject
    var vm: SessionsViewModel
    
    var body: some View {
        List {
            Section("Sessions") {
                ForEach(vm.state.sessions, id: \.id) { session in
                    NavigationLink {
                        ChatView(vm: .init(session: session))
                    } label: {
                        Text(session.connectedPeers.count.description)
                    }
                }
                .onDelete { indexSet in
                    vm.send(.removeSession(indexSet))
                }
            }
        }
    }
}
