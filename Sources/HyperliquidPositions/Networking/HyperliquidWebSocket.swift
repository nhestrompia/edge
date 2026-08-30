import Foundation

actor HyperliquidWebSocket {
    enum Event: Sendable {
        case mids([String: Double])
        case account(ClearinghouseStateDTO)
    }

    enum StreamError: Error {
        case disconnected
        case malformedMessage
    }

    private var task: URLSessionWebSocketTask?
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func events(for address: String) async throws -> AsyncThrowingStream<Event, Error> {
        disconnect()

        let socket = session.webSocketTask(with: URL(string: "wss://api.hyperliquid.xyz/ws")!)
        task = socket
        socket.resume()

        try await subscribe(socket, payload: ["type": "allMids"])
        try await subscribe(socket, payload: ["type": "clearinghouseState", "user": address])

        return AsyncThrowingStream { continuation in
            let receiveTask = Task {
                do {
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        if let event = try self.decode(message) {
                            continuation.yield(event)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            let heartbeatTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(25))
                    guard !Task.isCancelled else { break }
                    socket.sendPing { _ in }
                }
            }

            continuation.onTermination = { _ in
                receiveTask.cancel()
                heartbeatTask.cancel()
                socket.cancel(with: .goingAway, reason: nil)
            }
        }
    }

    func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func subscribe(_ socket: URLSessionWebSocketTask, payload: [String: String]) async throws {
        let envelope: [String: Any] = [
            "method": "subscribe",
            "subscription": payload
        ]
        let data = try JSONSerialization.data(withJSONObject: envelope)
        guard let text = String(data: data, encoding: .utf8) else {
            throw StreamError.malformedMessage
        }
        try await socket.send(.string(text))
    }

    private func decode(_ message: URLSessionWebSocketTask.Message) throws -> Event? {
        let data: Data
        switch message {
        case let .data(rawData):
            data = rawData
        case let .string(text):
            data = Data(text.utf8)
        @unknown default:
            return nil
        }

        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let channel = root["channel"] as? String,
            channel != "subscriptionResponse"
        else { return nil }

        if channel == "allMids",
           let payload = root["data"] as? [String: Any],
           let rawMids = payload["mids"] as? [String: String] {
            return .mids(rawMids.compactMapValues(Double.init))
        }

        if channel == "clearinghouseState" {
            let payload = root["data"]
            let stateObject: Any
            if let dictionary = payload as? [String: Any],
               let nested = dictionary["clearinghouseState"] {
                stateObject = nested
            } else if let payload {
                stateObject = payload
            } else {
                throw StreamError.malformedMessage
            }

            let stateData = try JSONSerialization.data(withJSONObject: stateObject)
            return .account(try decoder.decode(ClearinghouseStateDTO.self, from: stateData))
        }

        return nil
    }
}
