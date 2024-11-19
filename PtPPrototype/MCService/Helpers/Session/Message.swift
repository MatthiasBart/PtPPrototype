//
//  Message.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 17.11.24.
//

import Foundation
import MultipeerConnectivity

enum Message: Codable, Identifiable {
    case local(Content)
    case remote(Content)
    
    var id: String {
        switch self {
        case .local(let content):
            return content.id
        case .remote(let content):
            return content.id
        }
    }
    
    var date: Date {
        switch self {
        case .local(let content):
            return content.date
        case .remote(let content):
            return content.date
        }
    }
    
    var peerDisplayName: String {
        switch self {
        case .local(let content):
            return content.peerDisplayName
        case .remote(let content):
            return content.peerDisplayName
        }
    }
    
    var content: Content {
        switch self {
        case .local(let content):
            return content
        case .remote(let content):
            return content
        }
    }
}

extension Message {
    enum Content: Codable {
        case text(TextMessage)
        case data(DataMessage)
        
        var id: String {
            switch self {
            case .text(let textMessage):
                textMessage.id
            case .data(let dataMessage):
                dataMessage.id
            }
        }
        
        var date: Date {
            switch self {
            case .text(let textMessage):
                textMessage.date
            case .data(let dataMessage):
                dataMessage.date
            }
        }
        
        var peerDisplayName: String {
            switch self {
            case .text(let textMessage):
                textMessage.peerDisplayName
            case .data(let dataMessage):
                dataMessage.peerDisplayName
            }
        }
    }
}

extension Message.Content {
    struct TextMessage: Codable {
        let id: String
        let date: Date
        let peerDisplayName: String
        let text: String
        
        init(id: String, date: Date, peerDisplayName: String, text: String) {
            self.id = id
            self.date = date
            self.peerDisplayName = peerDisplayName
            self.text = text
        }
        
        init(text: String, service: MCService = Config.service) {
            self.id = UUID().uuidString
            self.date = .now
            self.peerDisplayName = service.myPeerID.displayName
            self.text = text
        }
    }
    
    struct DataMessage: Codable {
        let id: String
        let date: Date
        let peerDisplayName: String
        let data: Data
        
        init(id: String, date: Date, peerDisplayName: String, data: Data) {
            self.id = id
            self.date = date
            self.peerDisplayName = peerDisplayName
            self.data = data
        }
        
        init(data: Data, service: MCService = Config.service) {
            self.id = UUID().uuidString
            self.date = .now
            self.peerDisplayName = service.myPeerID.displayName
            self.data = data
        }
    }
}
