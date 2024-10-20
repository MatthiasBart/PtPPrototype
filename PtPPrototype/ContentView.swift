//
//  ContentView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.10.24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HostView()
                .navigationTitle("PtP Prototype")
        }
    }
}

#Preview {
    ContentView()
}
