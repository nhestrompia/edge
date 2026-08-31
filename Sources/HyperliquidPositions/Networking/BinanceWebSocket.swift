import Foundation

actor BinanceWebSocket {
    enum StreamError: Error {
        case malformedMessage
    }

    private var task: URLSessionWebSocketTask?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func quotes() -> AsyncThrowingStream<MarketQuote, Error> {
        disconnect()

        let streams = BinanceAPI.tradingPairs
            .map { "\($0.lowercased())@miniTicker" }
            .joined(separator: "/")
        let url = URL(string: "wss://data-stream.binance.vision/stream?streams=\(streams)")!
        let socket = session.webSocketTask(with: url)
        task = socket
        socket.resume()

        return AsyncThrowingStream { continuation in
            let receiveTask = Task {
                do {
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        continuation.yield(try Self.decode(message))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            let heartbeatTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(30))
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

    static func decode(_ message: URLSessionWebSocketTask.Message) throws -> MarketQuote {
        let data: Data
        switch message {
        case let .data(rawData):
            data = rawData
        case let .string(text):
            data = Data(text.utf8)
        @unknown default:
            throw StreamError.malformedMessage
        }

        let envelope = try JSONDecoder().decode(BinanceStreamEnvelope.self, from: data)
        guard
            let price = Double(envelope.data.closePrice),
            let open = Double(envelope.data.openPrice),
            let high = Double(envelope.data.highPrice),
            let low = Double(envelope.data.lowPrice)
        else {
            throw StreamError.malformedMessage
        }

        return MarketQuote(
            symbol: envelope.data.symbol.replacingOccurrences(of: "USDT", with: ""),
            price: price,
            openPrice24h: open,
            highPrice24h: high,
            lowPrice24h: low,
            updatedAt: Date(timeIntervalSince1970: TimeInterval(envelope.data.eventTime) / 1_000)
        )
    }
}

private struct BinanceStreamEnvelope: Decodable {
    let data: BinanceMiniTickerDTO
}

private struct BinanceMiniTickerDTO: Decodable {
    let eventTime: Int64
    let symbol: String
    let closePrice: String
    let openPrice: String
    let highPrice: String
    let lowPrice: String

    enum CodingKeys: String, CodingKey {
        case eventTime = "E"
        case symbol = "s"
        case closePrice = "c"
        case openPrice = "o"
        case highPrice = "h"
        case lowPrice = "l"
    }
}
