//
//  SessionImpl.swift
//  PtPPrototype
//
//  Created by Matthias Bartholomaeus on 19.11.24.
//

import MultipeerConnectivity
import Combine

class SessionImpl: MCSession, MCSessionDelegate, Session, StreamDelegate {
    var messages = CurrentValueSubject<[Message], Never>([])
    
    private var testingDataClient: TestingDataClient = .none
    private var receivedBytes: Int = 0
    var testingDataServer: TestingDataServer = .none
    
    init(myPeerID: MCPeerID, messages: [Message]) {
        self.messages.value = messages
        
        super.init(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        self.delegate = self
    }
    
    convenience required init(myPeerID: MCPeerID) {
        self.init(myPeerID: myPeerID, messages: [])
    }
    
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        switch state {
        case .notConnected:
            log.info("Peer \(peerID.displayName) not connected.")
            
        case .connecting:
            log.info("Peer \(peerID.displayName) connecting.")
            
        case .connected:
            log.info("Peer \(peerID.displayName) connected.")
            
        @unknown default:
            log.error("unknown state")
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        if let content = try? JSONDecoder().decode(Message.Content.self, from: data) {
            self.messages.value.append(.remote(content))
        } else if let testingDataClient = try? JSONDecoder().decode(TestingDataClient.self, from: data) {
            guard case let .finished(finishedDataServer) = testingDataServer, case let .finished(finishedDataClient) = testingDataClient else {
                return
            }
            let textContent = formatTestingSummary(finishedDataClient, finishedDataServer)
            let messageContent = Message.Content.TextMessage(text: textContent)
            
            try? send(.text(messageContent))
        }
    }
    
    private func formatTestingSummary(_ finishedDataClient: TestingDataClient.FinishedData, _ finishedDataServer: TestingDataServer.FinishedData) -> String {
        let timeFormat = Date.FormatStyle()
            .hour()
            .minute()
            .second(.twoDigits)
            .secondFraction(.fractional(3))
            .timeZone(.iso8601(.short))
        
        return """
        Server: 
            started Stream: \(finishedDataServer.streamOpenedAt.formatted(timeFormat))
            first Package sent: \(finishedDataServer.firstPackageSentAt?.formatted(timeFormat) ?? "not set")
            bytes Sent: \(finishedDataServer.numberOfBytesSent.formatted())
            last Package sent: \(finishedDataServer.lastByteSentAt.formatted(timeFormat))
        Client: 
            started Stream: \(finishedDataClient.streamOpenedAt.formatted(timeFormat))
            first Package received: \(finishedDataClient.firstPackageReceivedAt?.formatted(timeFormat) ?? "not set")
            bytes received: \(finishedDataClient.numberOfBytesReceived.formatted())
            last Package received: \(finishedDataClient.lastByteReadAt.formatted(timeFormat))
        """
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        let content = Message.Content.text(.init(text: "Peer began testing: \(streamName)"))
        
        self.messages.value.append(.remote(content))
        
        testingDataClient = .started(.init(streamOpenedAt: .now))
        receivedBytes = 0
        stream.open()
        stream.schedule(in: .main, forMode: .default)
        stream.delegate = self
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .endEncountered:
            addMessage("Testing ended")
            aStream.close()
            aStream.remove(from: .main, forMode: .default)
            if case let .started(startedData) = testingDataClient {
                testingDataClient = .finished(.init(
                    streamOpenedAt: startedData.streamOpenedAt,
                    firstPackageReceivedAt: startedData.firstPackageReceivedAt,
                    numberOfBytesReceived: receivedBytes,
                    lastByteReadAt: .now
                ))
                
                try? send(codable: testingDataClient)
            }
        case .errorOccurred:
            addMessage("Error occured")
        case .openCompleted:
            addMessage("Testing stream opened")
        case .hasBytesAvailable:
            guard let stream = aStream as? InputStream else { return }
            if case var .started(startedData) = testingDataClient, startedData.firstPackageReceivedAt == nil {
                startedData.firstPackageReceivedAt = .now
                testingDataClient = .started(startedData)
            }
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                addMessage("Error while reading stream")
            } else if read > 0 {
                receivedBytes += read
            }
            
        default:
            break
        }
    }
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        log.warning("didStartReceivingResourceWithName not implemented")
    }
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: (any Error)?
    ) {
        log.warning("didFinishReceivingResourceWithName not implemented")
    }
    
    func startTesting(numberOfBytes: Int, splitSize: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try startTesting(numberOfBytes: numberOfBytes, splitSize: splitSize)
                continuation.resume(returning: ())
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func send(codable content: Codable) throws {
        let data = try JSONEncoder().encode(content)
        try send(data, toPeers: connectedPeers, with: .reliable)
    }
    
    func send(_ content: Message.Content) throws {
        try send(codable: content)
        messages.value.append(.local(content))
    }
    
    private func startTesting(numberOfBytes: Int, splitSize: Int) throws {
        guard let otherPeer = connectedPeers.first else { return }
        
        testingDataServer = .started(.init(numberOfBytesToSend: numberOfBytes, streamOpenedAt: .now))
        let stream = try startStream(withName: "test", toPeer: otherPeer)
        stream.schedule(in: .main, forMode: .default)
        stream.open()
        
        let data: [UInt8] = Array(repeating: 61, count: numberOfBytes)
        let dataSliced = data.split(into: splitSize)
        
        if case var .started(startedData) = testingDataServer {
            startedData.firstPackageSentAt = .now
            testingDataServer = .started(startedData)
        }
        
        var errors: [Error] = []
        for slice in dataSliced {
            if stream.write(slice, maxLength: slice.count) < 0 {
                if let streamError = stream.streamError {
                    errors.append(streamError)
                } else {
                    errors.append(TestError.streamWriteError)
                }
            }
        }
        
        stream.close()
        stream.remove(from: .main, forMode: .default)
        
        if case let .started(startedData) = testingDataServer {
            testingDataServer = .finished(
                .init(
                    numberOfBytesToSend: startedData.numberOfBytesToSend,
                    streamOpenedAt: startedData.streamOpenedAt,
                    firstPackageSentAt: startedData.firstPackageSentAt,
                    numberOfBytesSent: startedData.numberOfBytesToSend - errors.count,
                    lastByteSentAt: .now
                )
            )
        }
    }
}

extension SessionImpl {
    func addMessage(_ text: String) {
        let content = Message.Content.text(.init(text: text))
        self.messages.value.append(.remote(content))
    }
}
