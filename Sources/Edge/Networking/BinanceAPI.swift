import Foundation

enum BinanceAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rejected(Int)
    case malformedTicker

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The Binance market-data URL could not be created."
        case .invalidResponse:
            "Binance returned an unreadable response."
        case let .rejected(statusCode):
            "Binance returned HTTP \(statusCode)."
        case .malformedTicker:
            "Binance returned malformed ticker data."
        }
    }
}

actor BinanceAPI {
    static let baseURL = URL(string: "https://data-api.binance.vision")!
    static let tradingPairs = ["BTCUSDT", "ETHUSDT", "SOLUSDT"]

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchQuotes() async throws -> [MarketQuote] {
        var components = URLComponents(
            url: Self.baseURL.appending(path: "/api/v3/ticker/24hr"),
            resolvingAgainstBaseURL: false
        )
        let symbolsData = try JSONEncoder().encode(Self.tradingPairs)
        guard let symbols = String(data: symbolsData, encoding: .utf8) else {
            throw BinanceAPIError.invalidURL
        }
        components?.queryItems = [URLQueryItem(name: "symbols", value: symbols)]
        guard let url = components?.url else { throw BinanceAPIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinanceAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BinanceAPIError.rejected(httpResponse.statusCode)
        }

        let tickers = try JSONDecoder().decode([BinanceTickerDTO].self, from: data)
        return try tickers.map(Self.normalize).sorted(by: Self.sortQuotes)
    }

    static func normalize(_ ticker: BinanceTickerDTO) throws -> MarketQuote {
        guard
            let price = Double(ticker.lastPrice),
            let open = Double(ticker.openPrice),
            let high = Double(ticker.highPrice),
            let low = Double(ticker.lowPrice)
        else {
            throw BinanceAPIError.malformedTicker
        }

        return MarketQuote(
            symbol: ticker.symbol.replacingOccurrences(of: "USDT", with: ""),
            price: price,
            openPrice24h: open,
            highPrice24h: high,
            lowPrice24h: low,
            updatedAt: Date(timeIntervalSince1970: TimeInterval(ticker.closeTime) / 1_000)
        )
    }

    static func sortQuotes(_ lhs: MarketQuote, _ rhs: MarketQuote) -> Bool {
        let lhsIndex = MarketQuote.trackedSymbols.firstIndex(of: lhs.symbol) ?? .max
        let rhsIndex = MarketQuote.trackedSymbols.firstIndex(of: rhs.symbol) ?? .max
        return lhsIndex < rhsIndex
    }
}

struct BinanceTickerDTO: Decodable, Sendable {
    let symbol: String
    let lastPrice: String
    let openPrice: String
    let highPrice: String
    let lowPrice: String
    let closeTime: Int64
}
