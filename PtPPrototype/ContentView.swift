//
//  ContentView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.10.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject
    private var serverViewModel = ServerViewModel()
    
    @StateObject
    private var clientViewModel = ClientViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Is your device a browser/client or advertiser/server?")
                
                NavigationLink("Client") {
                    ClientView(vm: clientViewModel)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                NavigationLink("Server") {
                    ServerView(vm: serverViewModel)
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
