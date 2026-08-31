import Foundation

struct Position: Identifiable, Hashable, Sendable {
    enum Side: String, Hashable, Sendable {
        case long
        case short

        var label: String { rawValue.uppercased() }
    }

    let coin: String
    let side: Side
    let leverage: Int
    let size: Double
    let entryPrice: Double
    let liquidationPrice: Double?
    let marginUsed: Double
    var markPrice: Double
    var notionalValue: Double
    var unrealizedPnl: Double
    var pnlPercent: Double

    var id: String { coin }

    var liquidationDistance: Double? {
        guard let liquidationPrice, markPrice > 0 else { return nil }

        let distance: Double
        switch side {
        case .long:
            distance = (markPrice - liquidationPrice) / markPrice
        case .short:
            distance = (liquidationPrice - markPrice) / markPrice
        }
        return max(0, distance * 100)
    }

    var isProfitable: Bool { unrealizedPnl >= 0 }

    var isLiquidationRiskElevated: Bool {
        guard let liquidationDistance else { return false }
        return liquidationDistance < 12
    }

    func updating(markPrice newMarkPrice: Double) -> Position {
        guard newMarkPrice > 0 else { return self }

        var copy = self
        copy.markPrice = newMarkPrice
        copy.notionalValue = abs(size * newMarkPrice)
        copy.unrealizedPnl = size * (newMarkPrice - entryPrice)
        copy.pnlPercent = marginUsed > 0 ? (copy.unrealizedPnl / marginUsed) * 100 : 0
        return copy
    }
}

extension Position {
    static let demo: [Position] = [
        Position(
            coin: "BTC",
            side: .long,
            leverage: 5,
            size: 0.1686,
            entryPrice: 108_240,
            liquidationPrice: 91_830,
            marginUsed: 3_684.10,
            markPrice: 109_333,
            notionalValue: 18_433.54,
            unrealizedPnl: 184.32,
            pnlPercent: 4.72
        ),
        Position(
            coin: "ETH",
            side: .long,
            leverage: 3,
            size: 5.505,
            entryPrice: 2_589.10,
            liquidationPrice: 1_932.80,
            marginUsed: 4_853.33,
            markPrice: 2_646.76,
            notionalValue: 14_571.42,
            unrealizedPnl: 317.45,
            pnlPercent: 2.18
        ),
        Position(
            coin: "HYPE",
            side: .short,
            leverage: 2,
            size: -106.13,
            entryPrice: 23.48,
            liquidationPrice: 31.24,
            marginUsed: 2_042.60,
            markPrice: 23.88,
            notionalValue: 2_534.38,
            unrealizedPnl: -42.45,
            pnlPercent: -1.03
        )
    ]

    static let layoutStressDemo: [Position] = demo + [
        Position(
            coin: "SOL",
            side: .long,
            leverage: 4,
            size: 24.2,
            entryPrice: 181.20,
            liquidationPrice: 144.80,
            marginUsed: 1_100,
            markPrice: 186.42,
            notionalValue: 4_511.36,
            unrealizedPnl: 126.32,
            pnlPercent: 11.48
        ),
        Position(
            coin: "ATOM",
            side: .long,
            leverage: 20,
            size: 1_434.65,
            entryPrice: 1.4601,
            liquidationPrice: nil,
            marginUsed: 103.81,
            markPrice: 1.4478,
            notionalValue: 2_076.17,
            unrealizedPnl: -17.77,
            pnlPercent: -16.97
        )
    ]
}
