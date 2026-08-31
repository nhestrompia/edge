import SwiftUI

struct NotchView: View {
    let connectionState: ConnectionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered = false

    var body: some View {
        ZStack(alignment: .leading) {
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 4,
                topTrailingRadius: 4,
                style: .continuous
            )
            .fill(HPTheme.canvas.opacity(0.97))
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(connectionState == .stale ? HPTheme.negative : HPTheme.positive)
                    .frame(width: hovered ? 5 : 3, height: hovered ? 42 : 31)
                    .padding(.leading, 8)
                    .shadow(color: HPTheme.positive.opacity(0.30), radius: 6, x: -1, y: 2)
            }
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 4,
                    topTrailingRadius: 4,
                    style: .continuous
                )
                .strokeBorder(HPTheme.line, lineWidth: 0.7)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(reduceMotion ? nil : HPMotion.control, value: hovered)
        .accessibilityLabel("Open edge sidebar")
    }
}
