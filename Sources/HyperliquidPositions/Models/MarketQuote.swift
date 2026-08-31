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
            price: 109_333,
            openPrice24h: 106_820,
            highPrice24h: 110_180,
            lowPrice24h: 105_940,
            updatedAt: .now
        ),
        MarketQuote(
            symbol: "ETH",
            price: 2_646.76,
            openPrice24h: 2_589.10,
            highPrice24h: 2_681.40,
            lowPrice24h: 2_552.30,
            updatedAt: .now
        ),
        MarketQuote(
            symbol: "SOL",
            price: 186.42,
            openPrice24h: 187.81,
            highPrice24h: 191.20,
            lowPrice24h: 183.04,
            updatedAt: .now
        )
    ]
}
