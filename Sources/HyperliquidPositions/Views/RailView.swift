import SwiftUI

struct RailView: View {
    @EnvironmentObject private var model: AppModel

    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dragHandle
                .frame(height: HPLayout.railTopPadding)

            if model.positions.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(model.positions) { position in
                            Button {
                                model.hover(positionID: position.id)
                            } label: {
                                RailPositionView(position: position)
                                    .frame(height: HPLayout.positionRowHeight)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    model.hover(positionID: position.id)
                                }
                            }
                            .accessibilityHint("Shows the position inspector")
                        }
                    }
                }
            }

            Divider()
                .overlay(HPTheme.line)
                .padding(.horizontal, 19)

            Button {
                model.expand()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.leftthird.inset.filled")
                        .font(.system(size: 17, weight: .medium))
                    if model.connectionState == .connecting || model.connectionState == .stale {
                        HStack(spacing: 4) {
                            StatusDot(state: model.connectionState, size: 6)
                            Text(model.connectionState.label)
                                .font(.system(size: 8, weight: .semibold))
                        }
                    }
                }
                .foregroundStyle(HPTheme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(height: HPLayout.railFooterHeight)
            .accessibilityLabel("Expand all positions")
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
            .shadow(color: HPTheme.panelShadow, radius: 20, x: -3, y: 10)
        }
        .contentShape(Rectangle())
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
                    .onChanged { value in onDragChanged(value.translation.height) }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let position: Position

    var body: some View {
        VStack(spacing: 7) {
            ZStack(alignment: .topTrailing) {
                TokenMark(coin: position.coin, size: 47)
                    .overlay {
                        if model.hoveredPositionID == position.id {
                            Circle()
                                .stroke(HPTheme.positive.opacity(0.68), lineWidth: 2)
                                .padding(-4)
                                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
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
