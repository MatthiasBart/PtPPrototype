//
//  OutstandingInvitationsView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import SwiftUI

struct InitiationView: View {
    @ObservedObject
    var vm: InitiationViewModel
    
    var body: some View {
        List {
            Section("Invitations") {
                ForEach(vm.state.outstandingInvitations) { invitation in
                    Button {
                        vm.send(.pressedOnInvitation(invitation))
                    } label: {
                        Text(invitation.peerID.displayName)
                    }
                }
            }
            
            Section("Nearby Peers") {
                ForEach(vm.state.nearbyPeersToInvite) { peer in
                    Button {
                        vm.send(.pressedOnNearbyPeer(peer))
                    } label: {
                        Text(peer.peerID.displayName)
                    }
                }
            }
        }
        .onAppear {
            vm.send(.onAppear)
        }
        .alert("Invitation to Session", isPresented: .constant(vm.state.selectedInvitation != nil)) {
            Button("Accept") {
                vm.send(.pressedOnAcceptInvitation)
            }
            
            Button("Decline") {
                vm.send(.pressedOnDeclineInvitation)
            }
        }
    }
}
