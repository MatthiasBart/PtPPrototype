//
//  BrowserView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 06.01.25.
//

import SwiftUI
import Network

struct BrowserView: View {
    
    let advertiserNames: [String]
    let onClickOnAdvertiserName: (String) -> Void
    
    var body: some View {
        if advertiserNames.isEmpty {
            ProgressView()
        }
        
        List(advertiserNames) { advertiserName in
            Button(advertiserName) {
                onClickOnAdvertiserName(advertiserName)
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: Self { self }
}
