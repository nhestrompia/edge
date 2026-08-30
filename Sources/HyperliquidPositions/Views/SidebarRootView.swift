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
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.96).combined(with: .opacity))

                case .notch:
                    NotchView(connectionState: model.connectionState)
                        .frame(width: HPLayout.notchSize.width, height: HPLayout.notchSize.height)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: model.preferences.sidebarEdge == .right ? .trailing : .leading)
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
                                scale: 0.96,
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
            if model.panelMode == .expanded {
                model.showRail()
            } else {
                model.hidePositions()
            }
        }
        .onMoveCommand { direction in
            guard model.panelMode == .rail else { return }
            switch direction {
            case .down:
                model.selectAdjacentPosition(offset: 1)
            case .up:
                model.selectAdjacentPosition(offset: -1)
            default:
                break
            }
        }
        .preferredColorScheme(.dark)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .snappy(duration: 0.34, extraBounce: 0.04),
            value: model.panelMode
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

            if let position = model.hoveredPosition {
                HoverCardView(position: position)
                    .id(position.id)
                    .offset(
                        x: model.preferences.sidebarEdge == .right ? -HPLayout.railWidth + 1 : HPLayout.railWidth - 1,
                        y: inspectorOffset(for: position, panelHeight: size.height)
                    )
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            )
                    )
            }
        }
    }

    private func inspectorOffset(for position: Position, panelHeight: CGFloat) -> CGFloat {
        guard let index = model.positions.firstIndex(where: { $0.id == position.id }) else { return 0 }
        let rowCenter = HPLayout.railTopPadding + CGFloat(index) * HPLayout.positionRowHeight + HPLayout.positionRowHeight / 2
        let ideal = rowCenter - HPLayout.inspectorHeight / 2
        return min(max(ideal, 8), max(8, panelHeight - HPLayout.inspectorHeight - 8))
    }
}
