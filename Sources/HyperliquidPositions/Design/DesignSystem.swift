import SwiftUI

enum HPTheme {
    static let canvas = Color(red: 0.025, green: 0.040, blue: 0.038)
    static let surface = Color(red: 0.042, green: 0.062, blue: 0.058)
    static let surfaceRaised = Color(red: 0.072, green: 0.090, blue: 0.087)
    static let surfacePressed = Color(red: 0.105, green: 0.122, blue: 0.118)
    static let line = Color.white.opacity(0.13)
    static let lineStrong = Color.white.opacity(0.25)
    static let textPrimary = Color(red: 0.955, green: 0.975, blue: 0.965)
    static let textSecondary = Color(red: 0.66, green: 0.72, blue: 0.70)
    static let positive = Color(red: 0.12, green: 0.88, blue: 0.62)
    static let positiveMuted = Color(red: 0.05, green: 0.30, blue: 0.22)
    static let negative = Color(red: 1.0, green: 0.28, blue: 0.31)
    static let negativeMuted = Color(red: 0.34, green: 0.08, blue: 0.09)
    static let warning = Color(red: 1.0, green: 0.68, blue: 0.20)
    static let onboardingCanvas = Color(red: 0.028, green: 0.034, blue: 0.042)
    static let onboardingField = Color(red: 0.025, green: 0.030, blue: 0.038)
    static let onboardingControl = Color(red: 0.075, green: 0.082, blue: 0.095)
    static let onboardingAccent = Color(red: 0.48, green: 0.60, blue: 0.90)

    static let panelShadow = Color.black.opacity(0.44)
}

enum HPLayout {
    static let notchSize = CGSize(width: 30, height: 118)
    static let railWidth: CGFloat = 112
    static let inspectorWidth: CGFloat = 386
    static let inspectorHeight: CGFloat = 302
    static let marketInspectorHeight: CGFloat = 230
    static let expandedWidth: CGFloat = 480
    static let expandedMaxHeight: CGFloat = 820
    static let expandedMarketWidth: CGFloat = 548
    static let expandedMarketContentHeight: CGFloat = 584
    static let expandedMarketHeight: CGFloat = 733
    static let expandedMarketMaxHeight: CGFloat = 790.5
    // Keep the regular expanded panel frame stable for positions and settings.
    // The compact market board has a dedicated reference-sized frame.
    static let expandedPanelWidth: CGFloat = max(expandedWidth, expandedMarketWidth)
    static let expandedPanelMaxHeight: CGFloat = max(expandedMaxHeight, expandedMarketMaxHeight)
    static let expandedFooterHeight: CGFloat = 64
    static let onboardingSize = CGSize(width: 654, height: 578)
    static let positionRowHeight: CGFloat = 106
    static let railTopPadding: CGFloat = 18
    static let railFooterHeight: CGFloat = 62

    static func railItemCount(positions: Int, markets: Int) -> Int {
        max(max(positions, markets), 1)
    }
}

enum HPMotion {
    static let panelDuration: TimeInterval = 0.36
    static let expandDuration: TimeInterval = 0.50
    static let inspectorDuration: TimeInterval = 0.24
    static let autoHideDelay: Duration = .milliseconds(280)
    static let frameUpdateDebounce: Duration = .milliseconds(8)
    static let panel = Animation.timingCurve(0.22, 0.82, 0.28, 1, duration: panelDuration)
    static let expand = Animation.timingCurve(0.4, 0, 0.2, 1, duration: expandDuration)
    static let inspector = Animation.timingCurve(0.22, 0.82, 0.28, 1, duration: inspectorDuration)
    static let control = Animation.easeOut(duration: 0.16)
}

enum HPFormat {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private static let compactCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func signedCurrency(_ value: Double, compact: Bool = false) -> String {
        let formatter = compact ? compactCurrencyFormatter : currencyFormatter
        let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "$0"
        return "\(value >= 0 ? "+" : "−")\(formatted)"
    }

    static func currency(_ value: Double, compact: Bool = false) -> String {
        let formatter = compact ? compactCurrencyFormatter : currencyFormatter
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func signedPercent(_ value: Double, fractionDigits: Int = 2) -> String {
        "\(value >= 0 ? "+" : "−")\(String(format: "%.*f", fractionDigits, abs(value)))%"
    }

    static func percent(_ value: Double, fractionDigits: Int = 1) -> String {
        "\(String(format: "%.*f", fractionDigits, value))%"
    }

    static func liquidationDistance(_ value: Double?) -> String {
        guard let value else { return "—" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = value.rounded() == value ? 0 : 1
        formatter.maximumFractionDigits = 1
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formatted)% away"
    }

    static func price(_ value: Double?) -> String {
        guard let value else { return "—" }
        let digits = value < 10 ? 4 : value < 1_000 ? 2 : 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    static func marketPrice(_ value: Double, compact: Bool = false) -> String {
        if compact, value >= 10_000 {
            return "$\(String(format: "%.1fK", value / 1_000))"
        }
        let digits = value < 10 ? 4 : value < 1_000 ? 2 : 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = digits
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

extension View {
    func hpPanelSurface(cornerRadius: CGFloat = 24) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(HPTheme.canvas.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(HPTheme.lineStrong, lineWidth: 0.7)
                }
                .shadow(color: HPTheme.panelShadow, radius: 22, x: -2, y: 10)
        }
    }

    func hpFocusRing(_ focused: Bool) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(focused ? HPTheme.positive : .clear, lineWidth: 1.5)
        }
    }
}
