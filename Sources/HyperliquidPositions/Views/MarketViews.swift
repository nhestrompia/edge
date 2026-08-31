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
                Text(model.marketConnectionState.label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(model.marketConnectionState == .live ? HPTheme.positive : HPTheme.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            model.marketConnectionState == .live
                                ? HPTheme.positiveMuted
                                : HPTheme.warning.opacity(0.14)
                        )
                    )
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
            HStack {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Markets")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(HPTheme.textPrimary)
                    Text("Live spot prices from Binance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    StatusDot(state: model.marketConnectionState, size: 8)
                    Text(model.marketConnectionState.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HPTheme.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HPTheme.surface.opacity(0.82))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(HPTheme.line, lineWidth: 0.8)
                    }
            )
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack {
                Text("3 Core Markets")
                Spacer()
                Text("24h Change")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HPTheme.textSecondary)
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 9)

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
                    LazyVStack(spacing: 9) {
                        ForEach(model.marketQuotes) { quote in
                            ExpandedMarketCard(quote: quote)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

private struct ExpandedMarketCard: View {
    let quote: MarketQuote

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 11) {
                AssetIcon(coin: quote.symbol, size: 40)
                VStack(alignment: .leading, spacing: 3) {
                    Text(quote.pair)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(HPTheme.textPrimary)
                    Text("Binance spot")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(HPFormat.marketPrice(quote.price))
                        .font(.system(size: 17, weight: .bold).monospacedDigit())
                        .foregroundStyle(HPTheme.textPrimary)
                        .contentTransition(.numericText())
                    Text(HPFormat.signedPercent(quote.changePercent24h))
                        .font(.system(size: 13, weight: .bold).monospacedDigit())
                        .foregroundStyle(quote.isUp ? HPTheme.positive : HPTheme.negative)
                }
            }

            HStack(alignment: .top) {
                MetricView(label: "Open", value: HPFormat.marketPrice(quote.openPrice24h))
                Spacer()
                MetricView(label: "Low", value: HPFormat.marketPrice(quote.lowPrice24h))
                Spacer()
                MetricView(label: "High", value: HPFormat.marketPrice(quote.highPrice24h), alignment: .trailing)
            }

        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HPTheme.surface.opacity(0.66))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HPTheme.lineStrong, lineWidth: 0.8)
                }
        }
    }
}
