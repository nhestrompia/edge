import AppKit
import SwiftUI

struct ExpandedSidebarView: View {
    @EnvironmentObject private var model: AppModel
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)

            summary
                .padding(.horizontal, 16)
                .padding(.top, 14)

            HStack {
                Text(positionCountLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                Spacer()
                Text("Sorted by PnL")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.top, 15)
            .padding(.bottom, 9)

            if model.positions.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(sortedPositions) { position in
                            ExpandedPositionCard(position: position)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }

            footer
        }
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(HPTheme.canvas.opacity(0.985))
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .strokeBorder(HPTheme.lineStrong, lineWidth: 0.8)
                }
                .shadow(color: HPTheme.panelShadow, radius: 24, x: -4, y: 12)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            HyperliquidMark(size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Hyperliquid")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(model.trackedAddress, forType: .string)
                } label: {
                    HStack(spacing: 5) {
                        Text(model.abbreviatedAddress)
                            .font(.system(size: 12, weight: .medium).monospaced())
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(HPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Copy wallet address")
            }

            Spacer()
            if model.isShowingDemoData {
                Text("DEMO DATA")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(HPTheme.warning)
            }
            HStack(spacing: 6) {
                StatusDot(state: model.connectionState, size: 10)
                if model.connectionState != .live {
                    Text(model.connectionState.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HPTheme.textSecondary)
                }
            }
            Menu {
                Button("Change Wallet…") { model.changeWallet() }
                Divider()
                Button("Collapse") { model.showRail() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(HPTheme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(HPTheme.surfaceRaised))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in onDragChanged(value.translation.height) }
                .onEnded { _ in onDragEnded() }
        )
    }

    private var summary: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Unrealized PnL")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                Text(HPFormat.signedCurrency(model.totalUnrealizedPnl))
                .font(.system(size: 24, weight: .bold).monospacedDigit())
                .foregroundStyle(model.totalUnrealizedPnl >= 0 ? HPTheme.positive : HPTheme.negative)
                .contentTransition(.numericText())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Text("Position Return")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                Text(HPFormat.signedPercent(model.combinedPnlPercent))
                    .font(.system(size: 18, weight: .bold).monospacedDigit())
                    .foregroundStyle(model.combinedPnlPercent >= 0 ? HPTheme.positive : HPTheme.negative)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HPTheme.surface.opacity(0.82))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HPTheme.line, lineWidth: 0.8)
                }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(HPTheme.positive)
            Text("No open positions")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HPTheme.textPrimary)
            Text("Open Hyperliquid positions for this wallet will automatically appear here.")
                .font(.system(size: 13))
                .foregroundStyle(HPTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            Button {
                model.showRail()
            } label: {
                Label("Collapse", systemImage: "sidebar.right")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .help("Collapse sidebar")

            VStack(spacing: 4) {
                StatusDot(state: model.connectionState, size: 7)
                Text(model.connectionState.label)
                    .font(.system(size: 9, weight: .semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(HPTheme.textSecondary)

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .help("Settings")
        }
        .buttonStyle(ExpandedFooterButtonStyle())
        .foregroundStyle(HPTheme.textSecondary)
        .frame(height: 57)
        .overlay(alignment: .top) {
            Rectangle().fill(HPTheme.line).frame(height: 1)
        }
    }

    private var sortedPositions: [Position] {
        model.positions.sorted { $0.unrealizedPnl > $1.unrealizedPnl }
    }

    private var positionCountLabel: String {
        "\(model.positions.count) Open Position\(model.positions.count == 1 ? "" : "s")"
    }
}

private struct ExpandedFooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? HPTheme.surfacePressed : Color.clear)
            .contentShape(Rectangle())
    }
}

private struct ExpandedPositionCard: View {
    @EnvironmentObject private var model: AppModel
    let position: Position
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                TokenMark(coin: position.coin, size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(position.coin)-PERP")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(HPTheme.textPrimary)
                    SideBadge(position: position)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(HPFormat.signedCurrency(position.unrealizedPnl))
                    .font(.system(size: 16, weight: .bold).monospacedDigit())
                    .contentTransition(.numericText())
                    Text(HPFormat.signedPercent(position.pnlPercent))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                }
                .foregroundStyle(position.isProfitable ? HPTheme.positive : HPTheme.negative)
            }

            HStack(alignment: .top) {
                MetricView(label: "Size", value: HPFormat.currency(position.notionalValue))
                Spacer()
                MetricView(label: "Entry", value: HPFormat.price(position.entryPrice))
                Spacer()
                MetricView(label: "Mark", value: HPFormat.price(position.markPrice), alignment: .trailing)
            }

            HStack(alignment: .bottom, spacing: 16) {
                MetricView(label: "Liq. Price", value: HPFormat.price(position.liquidationPrice))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Liq. Distance")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HPTheme.textSecondary)
                        Spacer()
                        Text(position.liquidationDistance.map { HPFormat.percent($0) } ?? "—")
                            .font(.system(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(position.isLiquidationRiskElevated ? HPTheme.negative : HPTheme.positive)
                    }
                    LiquidationBar(distance: position.liquidationDistance)
                }
                .frame(maxWidth: .infinity)
            }

            Button {
                model.openHyperliquid(for: position.coin)
            } label: {
                HStack(spacing: 6) {
                    Text("Open on Hyperliquid")
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HPTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(hovered ? HPTheme.surfacePressed : HPTheme.surfaceRaised)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hovered ? HPTheme.surface.opacity(0.86) : HPTheme.surface.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            hovered ? HPTheme.positive.opacity(0.42) : HPTheme.lineStrong,
                            lineWidth: 0.8
                        )
                }
        }
        .onHover { hovered = $0 }
        .animation(.easeOut(duration: 0.18), value: hovered)
    }
}
