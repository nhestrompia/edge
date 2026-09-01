import SwiftUI

struct MarketRailList: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(model.marketQuotes) { quote in
                    Button {
                        model.hover(marketSymbol: quote.symbol)
                    } label: {
                        MarketRailRow(quote: quote)
                            .frame(height: HPLayout.positionRowHeight)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { model.hover(marketSymbol: quote.symbol) }
                    }
                    .accessibilityHint("Shows the market inspector")
                }
            }
        }
    }
}

private struct MarketRailRow: View {
    @EnvironmentObject private var model: AppModel
    let quote: MarketQuote

    var body: some View {
        VStack(spacing: 7) {
            AssetIcon(coin: quote.symbol, size: 47)
                .overlay {
                        if model.hoveredMarketSymbol == quote.symbol {
                            Circle()
                                .stroke(HPTheme.positive.opacity(0.68), lineWidth: 2)
                                .padding(-4)
                                .transition(.opacity)
                        }
                }

            VStack(spacing: 1) {
                Text(HPFormat.marketPrice(quote.price, compact: true))
                    .font(.system(size: 14, weight: .bold).monospacedDigit())
                    .foregroundStyle(HPTheme.textPrimary)
                    .contentTransition(.numericText())

                Text(HPFormat.signedPercent(quote.changePercent24h))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(quote.isUp ? HPTheme.positive : HPTheme.negative)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(quote.symbol), \(HPFormat.marketPrice(quote.price)), 24 hour change \(HPFormat.signedPercent(quote.changePercent24h))")
    }
}

struct MarketHoverCardView: View {
    @EnvironmentObject private var model: AppModel
    let quote: MarketQuote

    private var pointsRight: Bool { model.preferences.sidebarEdge == .right }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                AssetIcon(coin: quote.symbol, size: 41)
                VStack(alignment: .leading, spacing: 3) {
                    Text(quote.pair)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HPTheme.textPrimary)
                    HStack(spacing: 4) {
                        SourceMark(source: .binance, size: 13)
                        Text("BINANCE SPOT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.7)
                            .foregroundStyle(HPTheme.textSecondary)
                    }
                }
                Spacer()
            }

            Text("Market Price")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.top, 22)

            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(HPFormat.marketPrice(quote.price))
                    .font(.system(size: 27, weight: .bold).monospacedDigit())
                    .foregroundStyle(HPTheme.textPrimary)
                    .contentTransition(.numericText())
                Text(HPFormat.signedPercent(quote.changePercent24h))
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                    .foregroundStyle(quote.isUp ? HPTheme.positive : HPTheme.negative)
            }

            HStack(alignment: .top, spacing: 18) {
                MetricView(label: "24h Open", value: HPFormat.marketPrice(quote.openPrice24h))
                MetricView(label: "24h Low", value: HPFormat.marketPrice(quote.lowPrice24h))
                MetricView(label: "24h High", value: HPFormat.marketPrice(quote.highPrice24h))
            }
            .padding(.top, 24)

        }
        .padding(.leading, pointsRight ? 22 : 42)
        .padding(.trailing, pointsRight ? 42 : 22)
        .padding(.vertical, 21)
        .frame(width: HPLayout.inspectorWidth, height: HPLayout.marketInspectorHeight, alignment: .topLeading)
        .background {
            InspectorBubbleShape(pointsRight: pointsRight)
                .fill(HPTheme.canvas.opacity(0.985))
                .overlay {
                    InspectorBubbleShape(pointsRight: pointsRight)
                        .stroke(HPTheme.lineStrong, lineWidth: 0.7)
                }
                .shadow(color: HPTheme.panelShadow, radius: 22, x: pointsRight ? -3 : 3, y: 11)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

struct ExpandedMarketContent: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            marketHeader

            HStack {
                Text("3 Core Markets")
                Spacer()
                Text("24h Change")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(HPTheme.textSecondary)
            .padding(.leading, 37)
            .padding(.trailing, 24)
            .padding(.top, 27)
            .padding(.bottom, 11)

            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)
                .padding(.horizontal, 34)

            if model.marketQuotes.isEmpty {
                VStack(spacing: 10) {
                    ProgressView().controlSize(.small).tint(HPTheme.positive)
                    Text("Loading Binance prices…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(model.marketQuotes) { quote in
                            ExpandedMarketCard(quote: quote)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.leading, 34)
                    .padding(.trailing, 20)
                    .padding(.top, 15)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 16)
    }

    private var marketHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Markets")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Spot prices from Binance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 37)
    }
}

private struct ExpandedMarketCard: View {
    let quote: MarketQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AssetIcon(coin: quote.symbol, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(quote.pair)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)
                    .lineLimit(1)
                Text("Binance spot")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
            }
            .padding(.top, 17)

            VStack(alignment: .leading, spacing: 4) {
                Text(HPFormat.marketPrice(quote.price))
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .foregroundStyle(HPTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .contentTransition(.numericText())
                Text(HPFormat.signedPercent(quote.changePercent24h))
                    .font(.system(size: 15, weight: .semibold).monospacedDigit())
                    .foregroundStyle(quote.isUp ? HPTheme.positive : HPTheme.negative)
                    .lineLimit(1)
            }
            .padding(.top, 18)

            VStack(alignment: .leading, spacing: 0) {
                MarketRangeBar(quote: quote)
                    .frame(height: 10)

                HStack {
                    Text(HPFormat.marketPrice(quote.lowPrice24h))
                    Spacer(minLength: 4)
                    Text(HPFormat.marketPrice(quote.highPrice24h))
                }
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.top, 6)
            }
            .padding(.top, 25)

            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)
                .padding(.top, 23)

            VStack(spacing: 8) {
                MarketCardMetric(label: "Open", value: HPFormat.marketPrice(quote.openPrice24h))
                MarketCardMetric(label: "Low", value: HPFormat.marketPrice(quote.lowPrice24h))
                MarketCardMetric(label: "High", value: HPFormat.marketPrice(quote.highPrice24h))
            }
            .padding(.top, 13)

        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(height: 382, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HPTheme.surface.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HPTheme.line.opacity(0.9), lineWidth: 0.8)
                }
        }
    }
}

private struct MarketCardMetric: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(HPTheme.textSecondary)
            Spacer(minLength: 4)
            Text(value)
                .foregroundStyle(HPTheme.textPrimary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
        .font(.system(size: 12, weight: .medium).monospacedDigit())
    }
}

private struct MarketRangeBar: View {
    let quote: MarketQuote

    private var progress: CGFloat {
        let span = quote.highPrice24h - quote.lowPrice24h
        guard span > 0 else { return 0.6 }
        return CGFloat(min(max((quote.price - quote.lowPrice24h) / span, 0), 1))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(HPTheme.lineStrong)
                    .frame(height: 2)

                Circle()
                    .fill(HPTheme.textPrimary)
                    .frame(width: 10, height: 10)
                    .offset(x: progress * max(0, geometry.size.width - 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily range")
        .accessibilityValue(
            HPFormat.marketPrice(quote.lowPrice24h)
                + " to "
                + HPFormat.marketPrice(quote.highPrice24h)
                + "; current "
                + HPFormat.marketPrice(quote.price)
        )
    }
}
