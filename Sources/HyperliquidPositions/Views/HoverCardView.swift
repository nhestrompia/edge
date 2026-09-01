import SwiftUI

struct HoverCardView: View {
    @EnvironmentObject private var model: AppModel
    let position: Position

    private var pointsRight: Bool { model.preferences.sidebarEdge == .right }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                AssetIcon(coin: position.coin, size: 41)
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
        .padding(.leading, pointsRight ? 22 : 42)
        .padding(.trailing, pointsRight ? 42 : 22)
        .padding(.vertical, 21)
        .frame(width: HPLayout.inspectorWidth, height: HPLayout.inspectorHeight, alignment: .topLeading)
        .background {
            InspectorBubbleShape(pointsRight: pointsRight)
                .fill(HPTheme.canvas.opacity(0.985))
                .overlay {
                    InspectorBubbleShape(pointsRight: pointsRight)
                        .stroke(HPTheme.lineStrong, lineWidth: 0.7)
                }
                .shadow(color: HPTheme.panelShadow, radius: 22, x: pointsRight ? -3 : 3, y: 11)
        }
        .accessibilityElement(children: .contain)
        // The inspector moves as one anchored surface. Its figures should swap in
        // place instead of running a second, slower numeric animation on hover.
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

struct InspectorBubbleShape: Shape {
    var pointsRight = true

    func path(in rect: CGRect) -> Path {
        let pointerWidth: CGFloat = 27
        let radius: CGFloat = 18
        let bodyMaxX = rect.maxX - pointerWidth
        let centerY = rect.midY
        let shoulder: CGFloat = 23
        var path = Path()

        path.move(to: CGPoint(x: radius, y: rect.minY))
        path.addLine(to: CGPoint(x: bodyMaxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: bodyMaxX, y: rect.minY + radius),
            control: CGPoint(x: bodyMaxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: bodyMaxX, y: centerY - shoulder))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: centerY),
            control1: CGPoint(x: bodyMaxX + 8, y: centerY - shoulder + 3),
            control2: CGPoint(x: rect.maxX - 7, y: centerY - 7)
        )
        path.addCurve(
            to: CGPoint(x: bodyMaxX, y: centerY + shoulder),
            control1: CGPoint(x: rect.maxX - 7, y: centerY + 7),
            control2: CGPoint(x: bodyMaxX + 8, y: centerY + shoulder - 3)
        )
        path.addLine(to: CGPoint(x: bodyMaxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: bodyMaxX - radius, y: rect.maxY),
            control: CGPoint(x: bodyMaxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        guard !pointsRight else { return path }
        return path.applying(
            CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.width, ty: 0)
        )
    }
}
