import SwiftUI

struct HyperliquidMark: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(HPTheme.positive.opacity(0.09))

            HyperliquidGlyphShape()
                .fill(HPTheme.positive)
                .frame(width: size * 0.62, height: size * 0.42)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct TokenMark: View {
    let coin: String
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)

            glyph
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
        }
        .accessibilityLabel("\(coin) position")
    }

    @ViewBuilder
    private var glyph: some View {
        switch coin.uppercased() {
        case "BTC":
            BitcoinGlyph()
        case "ETH":
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                Path { path in
                    path.move(to: CGPoint(x: width / 2, y: 0))
                    path.addLine(to: CGPoint(x: width * 0.83, y: height * 0.52))
                    path.addLine(to: CGPoint(x: width / 2, y: height * 0.68))
                    path.addLine(to: CGPoint(x: width * 0.17, y: height * 0.52))
                    path.closeSubpath()
                }
                .fill(Color.white)

                Path { path in
                    path.move(to: CGPoint(x: width / 2, y: height * 0.74))
                    path.addLine(to: CGPoint(x: width * 0.81, y: height * 0.58))
                    path.addLine(to: CGPoint(x: width / 2, y: height))
                    path.addLine(to: CGPoint(x: width * 0.19, y: height * 0.58))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.84))
            }
        case "SOL":
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == 1 ? Color.cyan : Color.purple)
                        .frame(height: 4)
                        .offset(x: index == 1 ? -3 : 3)
                }
            }
        case "HYPE":
            HyperliquidGlyphShape()
                .fill(HPTheme.positive)
        default:
            Text(String(coin.prefix(1)))
                .font(.system(size: size * 0.48, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }

    private var backgroundColor: Color {
        switch coin.uppercased() {
        case "BTC": Color(red: 0.97, green: 0.48, blue: 0.08)
        case "ETH": Color(red: 0.39, green: 0.35, blue: 0.91)
        case "HYPE": HPTheme.canvas
        case "SOL": HPTheme.canvas
        default: Color(red: 0.22, green: 0.29, blue: 0.30)
        }
    }
}

enum AssetIconSource {
    static let coinGeckoImageBaseURL = URL(string: "https://coin-images.coingecko.com/coins/images/")!
    static let hyperliquidBaseURL = URL(string: "https://app.hyperliquid.xyz/coins/")!
    static let binanceIconURL = URL(string: "https://bin.bnbstatic.com/static/images/common/favicon.ico")!

    private static let canonicalAssetImageURLs: [String: URL] = [
        "BTC": coinGeckoImageBaseURL.appendingPathComponent("1/large/bitcoin.png"),
        "ETH": coinGeckoImageBaseURL.appendingPathComponent("279/large/ethereum.png"),
        "SOL": coinGeckoImageBaseURL.appendingPathComponent("4128/large/solana.png")
    ]

    /// Exchange responses contain asset symbols, but not image URLs. Use exact
    /// CoinGecko IDs for the core markets so a symbol cannot resolve to the
    /// wrong token. Other Hyperliquid symbols use Hyperliquid's official mark
    /// endpoint; invalid symbols stay on the local fallback mark.
    static func url(for coin: String) -> URL? {
        let asset = coin.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_:@#"))

        guard
            !asset.isEmpty,
            asset.count <= 64,
            asset.unicodeScalars.allSatisfy(allowedCharacters.contains)
        else {
            return nil
        }

        return canonicalAssetImageURLs[asset.uppercased()]
            ?? hyperliquidBaseURL.appendingPathComponent("\(asset).svg")
    }
}

struct AssetIcon: View {
    let coin: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url = AssetIconSource.url(for: coin) {
                AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: size, height: size)
                    case .empty, .failure:
                        TokenMark(coin: coin, size: size)
                    @unknown default:
                        TokenMark(coin: coin, size: size)
                    }
                }
            } else {
                TokenMark(coin: coin, size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(coin) asset")
    }
}

struct SourceMark: View {
    let source: MarketSource
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(source == .binance ? Color(red: 0.96, green: 0.73, blue: 0.18).opacity(0.13) : HPTheme.positive.opacity(0.09))

            switch source {
            case .binance:
                AsyncImage(url: AssetIconSource.binanceIconURL, transaction: Transaction(animation: nil)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.13)
                    case .empty, .failure:
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: size * 0.62, weight: .bold))
                            .foregroundStyle(HPTheme.warning)
                    @unknown default:
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: size * 0.62, weight: .bold))
                            .foregroundStyle(HPTheme.warning)
                    }
                }
            case .hyperliquid:
                HyperliquidMark(size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel(source.label)
    }
}

enum MarketSource: Equatable {
    case binance
    case hyperliquid

    var label: String {
        switch self {
        case .binance: "Binance"
        case .hyperliquid: "Hyperliquid"
        }
    }
}

private struct HyperliquidGlyphShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = { (value: CGFloat) in rect.minX + value * rect.width }
        let y = { (value: CGFloat) in rect.minY + value * rect.height }
        var path = Path()

        path.move(to: CGPoint(x: x(0.03), y: y(0.50)))
        path.addCurve(
            to: CGPoint(x: x(0.23), y: y(0.12)),
            control1: CGPoint(x: x(0.03), y: y(0.27)),
            control2: CGPoint(x: x(0.12), y: y(0.12))
        )
        path.addCurve(
            to: CGPoint(x: x(0.50), y: y(0.43)),
            control1: CGPoint(x: x(0.38), y: y(0.12)),
            control2: CGPoint(x: x(0.39), y: y(0.43))
        )
        path.addCurve(
            to: CGPoint(x: x(0.77), y: y(0.12)),
            control1: CGPoint(x: x(0.61), y: y(0.43)),
            control2: CGPoint(x: x(0.62), y: y(0.12))
        )
        path.addCurve(
            to: CGPoint(x: x(0.97), y: y(0.50)),
            control1: CGPoint(x: x(0.90), y: y(0.12)),
            control2: CGPoint(x: x(0.97), y: y(0.27))
        )
        path.addCurve(
            to: CGPoint(x: x(0.77), y: y(0.88)),
            control1: CGPoint(x: x(0.97), y: y(0.73)),
            control2: CGPoint(x: x(0.88), y: y(0.88))
        )
        path.addCurve(
            to: CGPoint(x: x(0.50), y: y(0.57)),
            control1: CGPoint(x: x(0.62), y: y(0.88)),
            control2: CGPoint(x: x(0.61), y: y(0.57))
        )
        path.addCurve(
            to: CGPoint(x: x(0.23), y: y(0.88)),
            control1: CGPoint(x: x(0.39), y: y(0.57)),
            control2: CGPoint(x: x(0.38), y: y(0.88))
        )
        path.addCurve(
            to: CGPoint(x: x(0.03), y: y(0.50)),
            control1: CGPoint(x: x(0.10), y: y(0.88)),
            control2: CGPoint(x: x(0.03), y: y(0.73))
        )
        path.closeSubpath()
        return path
    }
}

private struct BitcoinGlyph: View {
    var body: some View {
        ZStack {
            HStack(spacing: 3) {
                Capsule().fill(Color.white)
                Capsule().fill(Color.white)
            }
            .frame(width: 7, height: 28)

            BitcoinBShape()
                .fill(Color.white, style: FillStyle(eoFill: true))
        }
    }
}

private struct BitcoinBShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let outer = CGRect(x: rect.width * 0.20, y: rect.height * 0.14, width: rect.width * 0.63, height: rect.height * 0.72)
        path.addRoundedRect(in: outer, cornerSize: CGSize(width: rect.width * 0.22, height: rect.height * 0.22))
        path.addRect(CGRect(x: rect.width * 0.20, y: rect.height * 0.14, width: rect.width * 0.22, height: rect.height * 0.72))
        path.addRoundedRect(
            in: CGRect(x: rect.width * 0.42, y: rect.height * 0.27, width: rect.width * 0.22, height: rect.height * 0.16),
            cornerSize: CGSize(width: rect.width * 0.08, height: rect.height * 0.08)
        )
        path.addRoundedRect(
            in: CGRect(x: rect.width * 0.42, y: rect.height * 0.56, width: rect.width * 0.26, height: rect.height * 0.17),
            cornerSize: CGSize(width: rect.width * 0.08, height: rect.height * 0.08)
        )
        return path
    }
}

struct StatusDot: View {
    let state: ConnectionState
    var size: CGFloat = 9

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                if state == .connecting || state == .stale {
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 4)
                        .scaleEffect(1.25)
                }
            }
            .accessibilityLabel(state.label)
    }

    private var color: Color {
        switch state {
        case .live: HPTheme.positive
        case .connecting: HPTheme.warning
        case .stale: HPTheme.negative
        case .idle: HPTheme.textSecondary
        }
    }
}

struct SideBadge: View {
    let position: Position

    var body: some View {
        Text("\(position.side.label) \(position.leverage)×")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(position.side == .long ? HPTheme.positive : HPTheme.negative)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(position.side == .long ? HPTheme.positiveMuted : HPTheme.negativeMuted)
            )
    }
}

struct MetricView: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(HPTheme.textPrimary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
    }
}

struct LiquidationBar: View {
    let distance: Double?
    var height: CGFloat = 7

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(barColor)
                    .frame(width: max(height, geometry.size.width * progress))
            }
        }
        .frame(height: height)
        .accessibilityLabel("Liquidation distance")
        .accessibilityValue(distance.map { HPFormat.percent($0) } ?? "Unavailable")
    }

    private var progress: Double {
        guard let distance else { return 0 }
        return min(max(distance / 35, 0.04), 1)
    }

    private var barColor: Color {
        guard let distance else { return HPTheme.textSecondary }
        if distance < 12 { return HPTheme.negative }
        if distance < 18 { return HPTheme.warning }
        return HPTheme.positive
    }
}

struct PressableIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(hovered ? HPTheme.textPrimary : HPTheme.textSecondary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(hovered ? HPTheme.surfacePressed : HPTheme.surfaceRaised))
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : HPMotion.control, value: hovered)
        .accessibilityLabel(label)
    }
}
