import Foundation

struct MarketQuote: Identifiable, Hashable, Sendable {
    let symbol: String
    var price: Double
    var openPrice24h: Double
    var highPrice24h: Double
    var lowPrice24h: Double
    var updatedAt: Date

    var id: String { symbol }
    var pair: String { "\(symbol)/USDT" }

    var changePercent24h: Double {
        guard openPrice24h > 0 else { return 0 }
        return ((price - openPrice24h) / openPrice24h) * 100
    }

    var isUp: Bool { changePercent24h >= 0 }
}

extension MarketQuote {
    static let trackedSymbols = ["BTC", "ETH", "SOL"]

    static let demo: [MarketQuote] = [
        MarketQuote(
            symbol: "BTC",
            price: 78_797,
            openPrice24h: 77_999,
            highPrice24h: 79_250,
            lowPrice24h: 77_675,
            updatedAt: .now
        ),
        MarketQuote(
            symbol: "ETH",
            price: 2_471.6,
            openPrice24h: 2_432,
            highPrice24h: 2_490,
            lowPrice24h: 2_429,
            updatedAt: .now
        ),
        MarketQuote(
            symbol: "SOL",
            price: 103.80,
            openPrice24h: 102.49,
            highPrice24h: 105.00,
            lowPrice24h: 102.18,
            updatedAt: .now
        )
    ]
}
