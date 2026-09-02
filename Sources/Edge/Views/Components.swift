import AppKit
import SwiftUI

private enum EdgeLogoResource {
    @MainActor
    static let image: NSImage = {
        if let url = Bundle.main.url(forResource: "edge-logo-extracted", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let url = Bundle.module.url(forResource: "edge-logo-extracted", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        return NSImage(size: NSSize(width: 1, height: 1))
    }()
}

struct EdgeLogo: View {
    var size: CGFloat = 44
    var foreground: Color = HPTheme.textPrimary

    var body: some View {
        Image(nsImage: EdgeLogoResource.image)
            .resizable()
            .interpolation(.high)
            .renderingMode(.template)
            .foregroundStyle(
                LinearGradient(
                    stops: [
                        .init(color: foreground, location: 0),
                        .init(color: foreground.opacity(0.76), location: 0.5),
                        .init(color: foreground.opacity(0.28), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct HyperliquidIcon: View {
    var size: CGFloat = 32
    var foreground: Color = HPTheme.positive
    var background: Color = HPTheme.positive.opacity(0.09)

    var body: some View {
        ZStack {
            Circle()
                .fill(background)

            HyperliquidGlyphShape()
                .fill(foreground)
                .frame(width: size * 0.62, height: size * 0.42)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
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
    /// endpoint; invalid symbols do not produce an icon URL.
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
                        AssetInitialMark(coin: coin, size: size)
                    @unknown default:
                        AssetInitialMark(coin: coin, size: size)
                    }
                }
            } else {
                AssetInitialMark(coin: coin, size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("\(coin) asset")
    }
}

private struct AssetInitialMark: View {
    let coin: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(HPTheme.surfaceRaised)

            Text(initial)
                .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                .foregroundStyle(HPTheme.textPrimary)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .strokeBorder(HPTheme.line, lineWidth: 0.8)
        }
        .accessibilityHidden(true)
    }

    private var initial: String {
        let trimmedCoin = coin.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedCoin.first.map(String.init) ?? "?"
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
                        Color.clear
                            .frame(width: size, height: size)
                    @unknown default:
                        Color.clear
                            .frame(width: size, height: size)
                    }
                }
            case .hyperliquid:
                HyperliquidIcon(
                    size: size,
                    foreground: HPTheme.positive,
                    background: .clear
                )
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

                if distance != nil {
                    Circle()
                        .fill(barColor)
                        .frame(width: markerDiameter, height: markerDiameter)
                        .offset(x: markerOffset(in: geometry.size.width))
                }
            }
        }
        .frame(height: height)
        .accessibilityLabel("Liquidation distance")
        .accessibilityValue(distance.map { HPFormat.percent($0) } ?? "Unavailable")
    }

    private var progress: Double {
        guard let distance else { return 0 }
        return min(max(distance / 75, 0.04), 1)
    }

    private var markerDiameter: CGFloat {
        max(height * 1.8, 8)
    }

    private func markerOffset(in width: CGFloat) -> CGFloat {
        let availableWidth = max(0, width - markerDiameter)
        return min(max(availableWidth * progress - markerDiameter / 2, 0), availableWidth)
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
