import SwiftUI

struct NotchView: View {
    let connectionState: ConnectionState
    let edge: SidebarEdge

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    private var isRightEdge: Bool {
        edge == .right
    }

    var body: some View {
        ZStack(alignment: isRightEdge ? .leading : .trailing) {
            notchShape
                .fill(HPTheme.canvas.opacity(0.97))
                .overlay(alignment: isRightEdge ? .leading : .trailing) {
                    Capsule()
                        .fill(connectionState == .stale ? HPTheme.negative : HPTheme.positive)
                        .frame(width: hovered ? 5 : 3, height: hovered ? 42 : 31)
                        .padding(.leading, isRightEdge ? 8 : 0)
                        .padding(.trailing, isRightEdge ? 0 : 8)
                        .shadow(
                            color: HPTheme.positive.opacity(0.30),
                            radius: 6,
                            x: isRightEdge ? -1 : 1,
                            y: 2
                        )
                }
                .overlay {
                    notchShape.strokeBorder(HPTheme.line, lineWidth: 0.7)
                }
        }
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : HPMotion.control, value: hovered)
        .accessibilityLabel("Open \(edge.title.lowercased()) edge sidebar")
    }

    private var notchShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isRightEdge ? 24 : 4,
            bottomLeadingRadius: isRightEdge ? 24 : 4,
            bottomTrailingRadius: isRightEdge ? 4 : 24,
            topTrailingRadius: isRightEdge ? 4 : 24,
            style: .continuous
        )
    }
}
