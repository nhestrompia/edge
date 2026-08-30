import SwiftUI

struct HoverCardView: View {
    @EnvironmentObject private var model: AppModel
    let position: Position

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                TokenMark(coin: position.coin, size: 41)
                Text("\(position.coin)-PERP")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)
                Spacer()
                if model.isShowingDemoData {
                    Text("DEMO")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(HPTheme.warning)
                }
                SideBadge(position: position)
            }

            Text("Unrealized PnL")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.top, 22)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(HPFormat.signedCurrency(position.unrealizedPnl))
                .font(.system(size: 27, weight: .bold).monospacedDigit())
                .contentTransition(.numericText())
                Text("(\(HPFormat.signedPercent(position.pnlPercent)))")
                    .font(.system(size: 15, weight: .bold).monospacedDigit())
            }
            .foregroundStyle(position.isProfitable ? HPTheme.positive : HPTheme.negative)

            HStack(alignment: .top, spacing: 11) {
                MetricView(label: "Size", value: HPFormat.currency(position.notionalValue))
                MetricView(label: "Entry", value: HPFormat.price(position.entryPrice))
                MetricView(label: "Mark", value: HPFormat.price(position.markPrice))
                MetricView(label: "Liq.", value: HPFormat.price(position.liquidationPrice))
            }
            .padding(.top, 24)

            LiquidationBar(distance: position.liquidationDistance)
                .padding(.top, 24)

            HStack {
                Text("Liq. Distance")
                    .foregroundStyle(HPTheme.textSecondary)
                Spacer()
                Text(position.liquidationDistance.map { HPFormat.percent($0) } ?? "—")
                    .fontWeight(.bold)
                    .foregroundStyle(position.isLiquidationRiskElevated ? HPTheme.negative : HPTheme.positive)
            }
            .font(.system(size: 13).monospacedDigit())
            .padding(.top, 9)
        }
        .padding(.leading, 22)
        .padding(.trailing, 42)
        .padding(.vertical, 21)
        .frame(width: HPLayout.inspectorWidth, height: HPLayout.inspectorHeight, alignment: .topLeading)
        .background {
            InspectorBubbleShape()
                .fill(HPTheme.canvas.opacity(0.985))
                .overlay {
                    InspectorBubbleShape()
                        .stroke(HPTheme.lineStrong, lineWidth: 0.7)
                }
                .shadow(color: HPTheme.panelShadow, radius: 22, x: -3, y: 11)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct InspectorBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pointerWidth: CGFloat = 25
        let bodyRect = CGRect(x: 0, y: 0, width: rect.width - pointerWidth, height: rect.height)
        var path = Path(roundedRect: bodyRect, cornerRadius: 18)

        let centerY = rect.midY
        var pointer = Path()
        pointer.move(to: CGPoint(x: bodyRect.maxX - 1, y: centerY - 22))
        pointer.addLine(to: CGPoint(x: rect.maxX, y: centerY))
        pointer.addLine(to: CGPoint(x: bodyRect.maxX - 1, y: centerY + 22))
        pointer.closeSubpath()
        path.addPath(pointer)
        return path
    }
}
