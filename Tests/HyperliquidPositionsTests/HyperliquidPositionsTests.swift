import XCTest
@testable import HyperliquidPositions

final class HyperliquidPositionsTests: XCTestCase {
    func testWalletAddressValidation() {
        XCTAssertTrue(WalletAddressValidator.isValid("0x71f41234567890abcdef1234567890abcdef1234"))
        XCTAssertTrue(WalletAddressValidator.isValid("0x0000000000000000000000000000000000000000"))
        XCTAssertFalse(WalletAddressValidator.isValid("71f4a1234567890abcdef1234567890abcdef1234"))
        XCTAssertFalse(WalletAddressValidator.isValid("0x71f4"))
        XCTAssertFalse(WalletAddressValidator.isValid("0x71f4z1234567890abcdef1234567890abcdef1234"))
    }

    func testPositionUpdatesFromMarkPrice() {
        let position = Position(
            coin: "ETH",
            side: .long,
            leverage: 5,
            size: 2,
            entryPrice: 2_000,
            liquidationPrice: 1_500,
            marginUsed: 800,
            markPrice: 2_100,
            notionalValue: 4_200,
            unrealizedPnl: 200,
            pnlPercent: 25
        )

        let updated = position.updating(markPrice: 2_200)

        XCTAssertEqual(updated.markPrice, 2_200)
        XCTAssertEqual(updated.notionalValue, 4_400)
        XCTAssertEqual(updated.unrealizedPnl, 400)
        XCTAssertEqual(updated.pnlPercent, 50)
        XCTAssertEqual(updated.liquidationDistance ?? 0, 31.8181818, accuracy: 0.0001)
    }

    func testClearinghouseStateNormalization() throws {
        let payload = Data(
            """
            {
              "assetPositions": [
                {
                  "position": {
                    "coin": "ETH",
                    "entryPx": "2986.3",
                    "leverage": { "type": "isolated", "value": 20 },
                    "liquidationPx": "2866.26936529",
                    "marginUsed": "4.967826",
                    "positionValue": "100.02765",
                    "returnOnEquity": "-0.0026789",
                    "szi": "0.0335",
                    "unrealizedPnl": "-0.0134"
                  },
                  "type": "oneWay"
                }
              ]
            }
            """.utf8
        )

        let dto = try JSONDecoder().decode(ClearinghouseStateDTO.self, from: payload)
        let positions = try HyperliquidAPI.normalize(dto)

        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].coin, "ETH")
        XCTAssertEqual(positions[0].side, .long)
        XCTAssertEqual(positions[0].leverage, 20)
        XCTAssertEqual(positions[0].pnlPercent, -0.26789, accuracy: 0.000001)
        XCTAssertEqual(positions[0].markPrice, 2_985.9, accuracy: 0.01)
    }

    func testShortLiquidationDistance() {
        let position = Position(
            coin: "HYPE",
            side: .short,
            leverage: 2,
            size: -10,
            entryPrice: 24,
            liquidationPrice: 30,
            marginUsed: 120,
            markPrice: 25,
            notionalValue: 250,
            unrealizedPnl: -10,
            pnlPercent: -8.33
        )

        XCTAssertEqual(position.liquidationDistance, 20)
    }
}
