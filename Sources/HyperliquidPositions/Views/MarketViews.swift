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
                .shadow(color: HPTheme.panelShadow, radius: 22, x: -3, y: 11)
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
            .padding(.horizontal, 26)
            .padding(.top, 28)
            .padding(.bottom, 12)

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
                    LazyVStack(spacing: 11) {
                        ForEach(model.marketQuotes) { quote in
                            ExpandedMarketCard(quote: quote)
                        }
                    }
                    .padding(.horizontal, 15.5)
                    .padding(.bottom, 12)
                }
            }
        }
        .padding(.top, 19)
    }

    private var marketHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Markets")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Spot prices from Binance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 27.5)
    }
}

private struct ExpandedMarketCard: View {
    let quote: MarketQuote

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 13) {
                AssetIcon(coin: quote.symbol, size: 44)
                    .offset(x: -2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(quote.pair)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(HPTheme.textPrimary)
                    Text("Binance spot")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .offset(x: -2)
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(HPFormat.marketPrice(quote.price))
                        .font(.system(size: 18, weight: .bold).monospacedDigit())
                        .foregroundStyle(HPTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text(HPFormat.signedPercent(quote.changePercent24h))
                        .font(.system(size: 15, weight: .bold).monospacedDigit())
                        .foregroundStyle(quote.isUp ? HPTheme.positive : HPTheme.negative)
                }
            }
            .frame(minHeight: 44)

            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)
                .padding(.top, 16)

            HStack(alignment: .top) {
                MarketCardMetric(label: "Open", value: HPFormat.marketPrice(quote.openPrice24h))
                Spacer()
                MarketCardMetric(label: "Low", value: HPFormat.marketPrice(quote.lowPrice24h))
                Spacer()
                MarketCardMetric(label: "High", value: HPFormat.marketPrice(quote.highPrice24h), alignment: .trailing)
            }
            .padding(.top, 13)

        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HPTheme.surface.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HPTheme.lineStrong.opacity(0.70), lineWidth: 0.8)
                }
        }
    }
}

private struct MarketCardMetric: View {
    let label: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(HPTheme.textPrimary)
                .lineLimit(1)
                .contentTransition(.numericText())
        }
    }
}
