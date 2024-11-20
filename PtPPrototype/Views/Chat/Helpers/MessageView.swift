//
//  MessageView.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 18.11.24.
//

import SwiftUI

struct MessageView: View {
    let message: Message
    
    var isLocal: Bool {
        if case .local = message { return true }
        return false
    }
    
    var alignment: Alignment {
        isLocal ? .trailing : .leading
    }
    
    var foregroundStyle: Color {
        isLocal ? Color.white : Color.primary
    }
    
    var background: Color {
        isLocal ? Color.green : Color.secondarySystemGroupedBackground
    }
    
    var body: some View {
        VStack(alignment: alignment.horizontal) {
            messageView(message.content)
                .padding()
                .foregroundStyle(foregroundStyle)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            Text(message.peerDisplayName.appending(" ") + message.date.formatted(date: .omitted, time: .shortened))
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding([.horizontal, .bottom])
    }
    
    func messageView(_ content: Message.Content) -> some View {
        Group {
            switch content {
            case .text(let textMessage):
                Text(textMessage.text)
                
            case .data(let dataMessage):
                VStack(alignment: alignment.horizontal) {
                    Text("Data: \(dataMessage.data.count) bytes")
                    Text(String(decoding: dataMessage.data, as: Unicode.UTF8.self))
                }
            }
        }
    }
}
