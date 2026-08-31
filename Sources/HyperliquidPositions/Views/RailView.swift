import SwiftUI

struct RailView: View {
    @EnvironmentObject private var model: AppModel

    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
                .frame(height: HPLayout.railTopPadding)

            ZStack {
                if model.activeSection == .positions {
                    positionsContent
                        .transition(.opacity)
                } else {
                    marketContent
                        .transition(.opacity)
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
                .overlay(HPTheme.line)
                .padding(.horizontal, 19)

            HStack(spacing: 0) {
                railFooterButton(
                    icon: "briefcase",
                    label: "Positions",
                    isActive: model.activeSection == .positions
                ) {
                    model.switchSection(to: .positions)
                }

                railFooterButton(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Markets",
                    isActive: model.activeSection == .market
                ) {
                    model.switchSection(to: .market)
                }

                railFooterButton(
                    icon: "rectangle.leftthird.inset.filled",
                    label: "Expand",
                    isActive: false
                ) {
                    model.expand()
                }
            }
            .frame(height: HPLayout.railFooterHeight)
        }
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 32,
                bottomTrailingRadius: 3,
                topTrailingRadius: 3,
                style: .continuous
            )
            .fill(HPTheme.canvas.opacity(0.98))
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 32,
                    bottomLeadingRadius: 32,
                    bottomTrailingRadius: 3,
                    topTrailingRadius: 3,
                    style: .continuous
                )
                .strokeBorder(HPTheme.line, lineWidth: 0.8)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var positionsContent: some View {
        if model.positions.isEmpty {
            emptyState
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(model.positions) { position in
                        Button {
                            model.openHyperliquid(for: position.coin)
                        } label: {
                            RailPositionView(position: position)
                                .frame(height: HPLayout.positionRowHeight)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering { model.hover(positionID: position.id) }
                        }
                        .help("Open \(position.coin) on Hyperliquid")
                        .accessibilityHint("Opens this position on Hyperliquid")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var marketContent: some View {
        if model.marketQuotes.isEmpty {
            VStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(HPTheme.positive)
                Text("Loading\nmarkets")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HPTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            MarketRailList()
        }
    }

    private func railFooterButton(
        icon: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isActive ? HPTheme.positive : HPTheme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var dragHandle: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 22, height: 3)
            if model.isShowingDemoData {
                Text("DEMO")
                    .font(.system(size: 7, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(HPTheme.warning)
                    .offset(x: 34)
            }
        }
            .contentShape(Rectangle().inset(by: -8))
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in onDragChanged(value.translation) }
                    .onEnded { _ in onDragEnded() }
            )
            .accessibilityLabel("Drag sidebar vertically")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 20))
                .foregroundStyle(HPTheme.textSecondary)
            Text("No open\npositions")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HPTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 26)
    }
}

private struct RailPositionView: View {
    @EnvironmentObject private var model: AppModel
    let position: Position

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                AssetIcon(coin: position.coin, size: 47)
                    .overlay {
                        if model.hoveredPositionID == position.id {
                            Circle()
                                .stroke(HPTheme.positive.opacity(0.68), lineWidth: 2)
                                .padding(-4)
                                .transition(.opacity)
                        }
                    }

                Circle()
                    .fill(position.isProfitable ? HPTheme.positive : HPTheme.negative)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(HPTheme.canvas, lineWidth: 2))
                    .offset(x: 7, y: -3)
            }

            VStack(spacing: 1) {
                Text(
                    model.preferences.pnlDisplayMode == .usd
                        ? HPFormat.signedCurrency(position.unrealizedPnl, compact: true)
                        : HPFormat.signedPercent(position.pnlPercent)
                )
                .font(.system(size: 15, weight: .bold).monospacedDigit())
                .foregroundStyle(position.isProfitable ? HPTheme.positive : HPTheme.negative)
                .contentTransition(.numericText())

                Text(HPFormat.signedPercent(position.pnlPercent))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(position.isProfitable ? HPTheme.positive : HPTheme.negative)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(position.coin), \(position.side.label), \(HPFormat.signedCurrency(position.unrealizedPnl))")
    }
}
