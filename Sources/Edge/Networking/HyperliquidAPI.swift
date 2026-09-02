import Foundation

enum WalletAddressValidator {
    static func isValid(_ address: String) -> Bool {
        guard address.count == 42, address.hasPrefix("0x") else { return false }
        return address.dropFirst(2).allSatisfy(\.isHexDigit)
    }
}

enum HyperliquidAPIError: LocalizedError {
    case invalidResponse
    case rejected(Int)
    case malformedAccount

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Hyperliquid returned an unreadable response."
        case let .rejected(statusCode):
            "Hyperliquid returned HTTP \(statusCode)."
        case .malformedAccount:
            "The account response did not contain valid position data."
        }
    }
}

actor HyperliquidAPI {
    static let infoURL = URL(string: "https://api.hyperliquid.xyz/info")!

    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPositions(for address: String) async throws -> [Position] {
        var request = URLRequest(url: Self.infoURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ClearinghouseRequest(user: address))

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HyperliquidAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw HyperliquidAPIError.rejected(httpResponse.statusCode)
        }

        let state = try decoder.decode(ClearinghouseStateDTO.self, from: data)
        return try Self.normalize(state)
    }

    static func normalize(_ state: ClearinghouseStateDTO) throws -> [Position] {
        try state.assetPositions.compactMap { wrapper in
            let raw = wrapper.position
            guard
                let size = Double(raw.szi),
                let entryPrice = Double(raw.entryPx),
                let positionValue = Double(raw.positionValue),
                let unrealizedPnl = Double(raw.unrealizedPnl),
                let marginUsed = Double(raw.marginUsed),
                let returnOnEquity = Double(raw.returnOnEquity)
            else {
                throw HyperliquidAPIError.malformedAccount
            }

            guard abs(size) > .ulpOfOne else { return nil }

            return Position(
                coin: raw.coin,
                side: size > 0 ? .long : .short,
                leverage: raw.leverage.value,
                size: size,
                entryPrice: entryPrice,
                liquidationPrice: raw.liquidationPx.flatMap(Double.init),
                marginUsed: marginUsed,
                markPrice: abs(positionValue / size),
                notionalValue: abs(positionValue),
                unrealizedPnl: unrealizedPnl,
                pnlPercent: returnOnEquity * 100
            )
        }
    }
}

private struct ClearinghouseRequest: Encodable {
    let type = "clearinghouseState"
    let user: String
}

struct ClearinghouseStateDTO: Decodable, Sendable {
    let assetPositions: [AssetPositionDTO]
}

struct AssetPositionDTO: Decodable, Sendable {
    let position: PositionDTO
}

struct PositionDTO: Decodable, Sendable {
    struct LeverageDTO: Decodable, Sendable {
        let value: Int
    }

    let coin: String
    let entryPx: String
    let leverage: LeverageDTO
    let liquidationPx: String?
    let marginUsed: String
    let positionValue: String
    let returnOnEquity: String
    let szi: String
    let unrealizedPnl: String
}
