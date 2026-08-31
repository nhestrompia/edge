import SwiftUI

struct SidebarRootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                switch model.panelMode {
                case .onboarding:
                    OnboardingView()
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.985).combined(with: .opacity))

                case .notch:
                    NotchView(connectionState: model.activeConnectionState)
                        .frame(width: HPLayout.notchSize.width, height: HPLayout.notchSize.height)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(
                                    scale: 0.94,
                                    anchor: model.preferences.sidebarEdge == .right ? .trailing : .leading
                                ).combined(with: .opacity)
                        )

                case .rail:
                    railLayer(in: geometry.size)
                        .transition(.opacity)

                case .expanded:
                    ExpandedSidebarView(
                        onDragChanged: onDragChanged,
                        onDragEnded: onDragEnded
                    )
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .scale(
                                scale: 0.985,
                                anchor: model.preferences.sidebarEdge == .right ? .trailing : .leading
                            ).combined(with: .opacity)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: model.preferences.sidebarEdge == .right ? .topTrailing : .topLeading)
        }
        .onHover { hovering in
            if hovering {
                model.pointerEntered()
            } else {
                model.pointerExited()
            }
        }
        .onExitCommand {
            if model.panelMode == .onboarding {
                return
            } else if model.panelMode == .expanded {
                model.showRail()
            } else {
                model.hidePositions()
            }
        }
        .onMoveCommand { direction in
            guard model.panelMode == .rail else { return }
            let offset: Int
            switch direction {
            case .down: offset = 1
            case .up: offset = -1
            default: return
            }
            if model.activeSection == .positions {
                model.selectAdjacentPosition(offset: offset)
            } else {
                model.selectAdjacentMarket(offset: offset)
            }
        }
        .preferredColorScheme(.dark)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .smooth(duration: 0.5, extraBounce: 0),
            value: model.panelMode
        )
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .smooth(duration: 0.46, extraBounce: 0),
            value: model.activeSection
        )
    }

    @ViewBuilder
    private func railLayer(in size: CGSize) -> some View {
        let railAlignment: Alignment = model.preferences.sidebarEdge == .right ? .topTrailing : .topLeading

        ZStack(alignment: railAlignment) {
            RailView(
                onDragChanged: onDragChanged,
                onDragEnded: onDragEnded
            )
            .frame(width: HPLayout.railWidth, height: size.height)

            if model.activeSection == .positions, let position = model.hoveredPosition {
                HoverCardView(position: position)
                    .offset(
                        x: inspectorHorizontalOffset,
                        y: inspectorOffset(for: position, panelHeight: size.height)
                    )
                    .transition(inspectorTransition)
            } else if model.activeSection == .market, let quote = model.hoveredMarketQuote {
                MarketHoverCardView(quote: quote)
                    .offset(
                        x: inspectorHorizontalOffset,
                        y: inspectorOffset(for: quote, panelHeight: size.height)
                    )
                    .transition(inspectorTransition)
            }
        }
    }

    private var inspectorHorizontalOffset: CGFloat {
        model.preferences.sidebarEdge == .right ? -HPLayout.railWidth + 1 : HPLayout.railWidth - 1
    }

    private var inspectorTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .scale(
            scale: 0.985,
            anchor: model.preferences.sidebarEdge == .right ? .trailing : .leading
        ).combined(with: .opacity)
    }

    private func inspectorOffset(for position: Position, panelHeight: CGFloat) -> CGFloat {
        guard let index = model.positions.firstIndex(where: { $0.id == position.id }) else { return 0 }
        let rowCenter = HPLayout.railTopPadding + CGFloat(index) * HPLayout.positionRowHeight + HPLayout.positionRowHeight / 2
        let ideal = rowCenter - HPLayout.inspectorHeight / 2
        return min(max(ideal, 8), max(8, panelHeight - HPLayout.inspectorHeight - 8))
    }

    private func inspectorOffset(for quote: MarketQuote, panelHeight: CGFloat) -> CGFloat {
        guard let index = model.marketQuotes.firstIndex(where: { $0.id == quote.id }) else { return 0 }
        let rowCenter = HPLayout.railTopPadding + CGFloat(index) * HPLayout.positionRowHeight + HPLayout.positionRowHeight / 2
        let ideal = rowCenter - HPLayout.inspectorHeight / 2
        return min(max(ideal, 8), max(8, panelHeight - HPLayout.inspectorHeight - 8))
    }
}
