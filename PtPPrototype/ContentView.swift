//
//  ContentView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.10.24.
//

import SwiftUI

struct ContentView: View {
    
    @State
    private var currentSegment: Segment = .initiation
    
    @StateObject
    var sessionsVM: SessionsViewModel = .init()
    
    @StateObject
    var initiationVM: InitiationViewModel = .init()
    
    var body: some View {
        NavigationStack {
            VStack {
                switch currentSegment {
                case .sessions:
                    SessionsView(vm: sessionsVM)
                    
                case .initiation:
                    InitiationView(vm: initiationVM)
                }
            }
            .animation(.default, value: currentSegment)
            .toolbar(content: {
                ToolbarItem(placement: .navigation) {
                    Picker("Tab", selection: $currentSegment) {
                        Text("Initiation")
                            .tag(Segment.initiation)
                        
                        Text("Sessions")
                            .tag(Segment.sessions)
                    }
                    .pickerStyle(.segmented)
                }
            })
            .navigationTitle("PtP Prototype")
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {
    enum Segment {
        case sessions
        case initiation
    }
}
