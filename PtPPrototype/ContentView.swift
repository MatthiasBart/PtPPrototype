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
            VStack {
                Text("Is your device a browser/client or advertiser/server?")
                
                NavigationLink("Client") {
                    ClientView()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                NavigationLink("Server") {
                    ServerView()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
