//
//  InfoSheet.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import SwiftUI

struct InfoSheet: View {
    @ObservedObject
    var vm: HostViewModel
    
    var body: some View {
        List {
            Section("Connecting to") {
                ForEach(vm.state.peersConnecting) { peer in
                    Text(peer.displayName)
                }
            }
            
            Section("Connected to") {
                ForEach(vm.state.peersConnected) { peer in
                    Text(peer.displayName)
                }
            }
            
            Section("Peers to invite") {
                ForEach(vm.state.peersToInvite) { peer in
                    Button(peer.displayName) {
                        vm.invitePeer(peer)
                    }
                }
            }
            
            Section("Invitations from") {
                ForEach(vm.state.invitationsFrom.sorted(by: { $0.key.displayName > $1.key.displayName }), id: \.key) { invitation in
                    Button("Accept invitation from \(invitation.key.displayName)") {
                        vm.joinSession(from: invitation.key)
                    }
                }
            }
        }
    }
}
