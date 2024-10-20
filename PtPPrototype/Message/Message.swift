//
//  Message.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 20.10.24.
//

import Foundation

enum Message: Identifiable {
    case sentText(TextMessage)
    case receivedText(TextMessage)
    
    var id: Int {
        switch self {
        case .sentText(let text): return text.id
        case .receivedText(let text): return text.id
        }
    }
}

struct TextMessage: Identifiable, Codable {
    let id: Int
    let content: String
    let date: Date
}
