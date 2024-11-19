//
//  OutstandingInvitationsViewModel.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import SwiftUI
import MultipeerConnectivity

class InitiationViewModel: ObservableObject, AsyncViewModel {
    struct State {
        var selectedInvitation: Invitation?
        var nearbyPeersToInvite: [UnconnectedNearbyPeer] = []
        var outstandingInvitations: [Invitation] = []
    }
    
    enum Action {
        case pressedOnAcceptInvitation
        case pressedOnDeclineInvitation
        
        case pressedOnInvitation(Invitation)
        case pressedOnNearbyPeer(UnconnectedNearbyPeer)
        case onAppear
    }
    
    @Published
    private(set) var state: State
    
    private let service: MCService
    
    private var tasks: Set<Task<Void, Never>> = []
    
    init(
        state: State = .init(),
        service: MCService = Config.service
    ) {
        self.state = state
        self.service = service
        listenToService()
    }
    
    deinit {
        tasks.forEach {
            $0.cancel()
        }
    }
    
    @MainActor
    func action(_ action: Action) {
        switch action {
        case .pressedOnAcceptInvitation:
            guard let invitation = state.selectedInvitation else { return }
            
            service.accept(invitation)
            
            state.selectedInvitation = nil
            
        case .pressedOnDeclineInvitation:
            guard let invitation = state.selectedInvitation else { return }
            
            service.decline(invitation)
            
            state.selectedInvitation = nil

        case .pressedOnInvitation(let invitation):
            state.selectedInvitation = invitation
            
        case .pressedOnNearbyPeer(let nearbyPeer):
            service.invite(peer: nearbyPeer)
            
        case .onAppear:
            service.startAdvertisingPeer()
            service.startBrowsingForPeers()
        }
    }
    
    private func listenToService() {
        let task = Task { @MainActor in
            for await invitations in service.outstandingInvitations.values {
                state.outstandingInvitations = invitations
            }
        }
        
        tasks.insert(task)
        
        let task0 = Task { @MainActor in
            for await nearbyPeers in service.nearbyPeersToInvite.values {
                state.nearbyPeersToInvite = nearbyPeers
            }
        }
        
        tasks.insert(task0)
    }
}
