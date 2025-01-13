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
                Text("Is your device a browser or advertiser?")
                
                NavigationLink("Browser") {
                    BrowserView()
                }
                
                NavigationLink("Advertiser") {
                    ServerView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
