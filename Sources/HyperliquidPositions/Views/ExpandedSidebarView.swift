import AppKit
import SwiftUI

enum ExpandedPositionFilter: String, CaseIterable, Identifiable {
    case all
    case long
    case short
    case profitable
    case losing
    case nearLiquidation

    var id: Self { self }

    var label: String {
        switch self {
        case .all: "All positions"
        case .long: "Long"
        case .short: "Short"
        case .profitable: "Profitable"
        case .losing: "Losing"
        case .nearLiquidation: "Near liquidation"
        }
    }

    func matches(_ position: Position) -> Bool {
        switch self {
        case .all: true
        case .long: position.side == .long
        case .short: position.side == .short
        case .profitable: position.isProfitable
        case .losing: !position.isProfitable
        case .nearLiquidation: position.isLiquidationRiskElevated
        }
    }
}

enum ExpandedPositionSort: String, CaseIterable, Identifiable {
    case pnlHighToLow
    case pnlLowToHigh
    case asset
    case leverage

    var id: Self { self }

    var label: String {
        switch self {
        case .pnlHighToLow: "PnL · High to low"
        case .pnlLowToHigh: "PnL · Low to high"
        case .asset: "Asset · A to Z"
        case .leverage: "Leverage · High to low"
        }
    }

}

struct ExpandedSidebarView: View {
    @EnvironmentObject private var model: AppModel
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    @FocusState private var isSearchFieldFocused: Bool
    @State private var positionFilter: ExpandedPositionFilter = .all
    @State private var isFilterMenuPresented = false
    @State private var positionSearchText = ""
    @State private var positionSort: ExpandedPositionSort = .pnlHighToLow
    @State private var isSortMenuPresented = false

    var body: some View {
        VStack(spacing: 0) {
            if model.panelMode == .settings {
                SettingsPageView(onBack: model.closeSettings)
            } else {
                header
                    .padding(.leading, 22.5)
                    .padding(.trailing, 18)
                    .padding(.top, 22)
                    .padding(.bottom, 14)

                if model.activeSection == .positions {
                    positionsContent
                        .transition(.opacity)
                } else {
                    ExpandedMarketContent()
                        .transition(.opacity)
                }
            }

            footer
        }
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(HPTheme.canvas.opacity(0.985))
                .overlay {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .strokeBorder(HPTheme.lineStrong, lineWidth: 0.8)
                }
                .shadow(
                    color: HPTheme.panelShadow,
                    radius: 24,
                    x: model.preferences.sidebarEdge == .right ? -4 : 4,
                    y: 12
                )
        }
    }

    private var header: some View {
        HStack(spacing: 17) {
            HyperliquidMark(
                size: 49,
                foreground: HPTheme.textPrimary,
                background: HPTheme.surfaceRaised.opacity(0.76)
            )

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(model.trackedAddress, forType: .string)
            } label: {
                HStack(spacing: 5) {
                    Text(model.abbreviatedAddress)
                        .font(.system(size: 14, weight: .medium).monospaced())
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(HPTheme.textPrimary)
            }
            .buttonStyle(.plain)
            .help("Copy wallet address")
            .accessibilityLabel("Copy wallet address")

            if model.isShowingDemoData {
                Text("DEMO")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(HPTheme.warning)
            }

            Spacer()

            HStack(spacing: 8) {
                ExpandedHeaderIconButton(
                    systemName: "wallet.pass",
                    label: "Change wallet"
                ) {
                    model.changeWallet()
                }

                ExpandedHeaderIconButton(
                    systemName: "rectangle.leftthird.inset.filled",
                    label: "Collapse"
                ) {
                    model.showRail()
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in onDragChanged(value.translation) }
                .onEnded { _ in onDragEnded() }
        )
    }

    private var summary: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL UNREALIZED PNL")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                    Text(HPFormat.signedCurrency(model.totalUnrealizedPnl))
                        .font(.system(size: 24, weight: .bold).monospacedDigit())
                        .foregroundStyle(model.totalUnrealizedPnl >= 0 ? HPTheme.positive : HPTheme.negative)
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("POSITION RETURN")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                    Text(HPFormat.signedPercent(model.combinedPnlPercent))
                        .font(.system(size: 24, weight: .bold).monospacedDigit())
                        .foregroundStyle(model.combinedPnlPercent >= 0 ? HPTheme.positive : HPTheme.negative)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 13)

            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)
                .padding(.horizontal, 26)
        }
    }

    private var positionsContent: some View {
        VStack(spacing: 0) {
            summary

            HStack(spacing: 17) {
                searchField
                filterMenu
            }
            .padding(.leading, 30)
            .padding(.trailing, 27)
            .padding(.top, 14)

            HStack {
                Text(positionCountLabel)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(HPTheme.textPrimary)
                Spacer()
                sortMenu
            }
            .padding(.horizontal, 26)
            .padding(.top, 19)
            .padding(.bottom, 8)

            if model.positions.isEmpty {
                emptyState
            } else if filteredPositions.isEmpty {
                noMatchesState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 5) {
                        ForEach(filteredPositions) { position in
                            ExpandedPositionCard(position: position)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }
            }
        }
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

    private var noMatchesState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
            Text("No matching positions")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(HPTheme.textPrimary)
            Text("Try another asset or clear the active filter.")
                .font(.system(size: 13))
                .foregroundStyle(HPTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)

            Button(clearFilteringLabel) {
                clearPositionFiltering()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(HPTheme.positive)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(HPTheme.positiveMuted.opacity(0.72))
            )
            .accessibilityLabel(clearFilteringLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)

            TextField("Search assets", text: $positionSearchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(HPTheme.textPrimary)
                .focused($isSearchFieldFocused)
                .accessibilityLabel("Search positions")
                .accessibilityHint("Search by asset symbol")

            if !positionSearchText.isEmpty {
                Button {
                    positionSearchText = ""
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(
            Capsule(style: .continuous)
                .fill(HPTheme.surface.opacity(0.58))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    isSearchFieldFocused ? HPTheme.positive : HPTheme.positive.opacity(0.72),
                    lineWidth: isSearchFieldFocused ? 1.3 : 0.8
                )
        }
        .contentShape(Capsule(style: .continuous))
        .onTapGesture {
            isSearchFieldFocused = true
        }
        .animation(HPMotion.control, value: isSearchFieldFocused)
    }

    private var filterMenu: some View {
        Button {
            isFilterMenuPresented.toggle()
        } label: {
            ZStack {
                Color.clear

                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                    Text(positionFilter == .all ? "Filter" : positionFilter.label)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(positionFilter == .all ? HPTheme.textPrimary : HPTheme.positive)
            }
            .frame(width: 100, height: 36)
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(width: 100, height: 36)
        .contentShape(Capsule(style: .continuous))
        .background {
            Capsule(style: .continuous)
                .fill(
                    positionFilter == .all
                        ? HPTheme.surface.opacity(0.58)
                        : HPTheme.positiveMuted.opacity(0.72)
                )
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    positionFilter == .all ? HPTheme.line : HPTheme.positive.opacity(0.42),
                    lineWidth: 0.8
                )
        }
        .help("Filter positions")
        .accessibilityLabel("Filter positions")
        .accessibilityValue(positionFilter.label)
        .popover(isPresented: $isFilterMenuPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(ExpandedPositionFilter.allCases) { filter in
                    Button {
                        positionFilter = filter
                        isFilterMenuPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Text(filter.label)
                            Spacer(minLength: 12)
                            if positionFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HPTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .frame(width: 180)
            .background(HPTheme.canvas)
        }
    }

    private var sortMenu: some View {
        Button {
            isSortMenuPresented.toggle()
        } label: {
            HStack(spacing: 7) {
                Text("Sort:")
                    .foregroundStyle(HPTheme.textSecondary)
                Text(positionSort.label)
                    .foregroundStyle(HPTheme.positive)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HPTheme.textSecondary)
            }
            .font(.system(size: 14, weight: .medium))
            .frame(width: 230, height: 30, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 230, height: 30, alignment: .trailing)
        .help("Sort positions")
        .accessibilityLabel("Sort positions")
        .accessibilityValue(positionSort.label)
        .popover(isPresented: $isSortMenuPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(ExpandedPositionSort.allCases) { sort in
                    Button {
                        positionSort = sort
                        isSortMenuPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Text(sort.label)
                            Spacer(minLength: 12)
                            if positionSort == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(HPTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 30)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .frame(width: 210)
            .background(HPTheme.canvas)
        }
    }

    private var footer: some View {
        HStack(spacing: 0) {
            Button {
                selectSection(.positions)
            } label: {
                footerIcon("briefcase", active: model.panelMode != .settings && model.activeSection == .positions)
            }
            .help("Positions")
            .accessibilityLabel("Positions")
            .accessibilityAddTraits(
                model.panelMode != .settings && model.activeSection == .positions ? .isSelected : []
            )

            Button {
                selectSection(.market)
            } label: {
                footerIcon("chart.line.uptrend.xyaxis", active: model.panelMode != .settings && model.activeSection == .market)
            }
            .help("Markets")
            .accessibilityLabel("Markets")
            .accessibilityAddTraits(
                model.panelMode != .settings && model.activeSection == .market ? .isSelected : []
            )

            Button {
                if model.panelMode == .settings {
                    model.closeSettings()
                } else {
                    model.showSettings()
                }
            } label: {
                footerIcon("gearshape", active: model.panelMode == .settings)
            }
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .buttonStyle(ExpandedFooterButtonStyle())
        .foregroundStyle(HPTheme.textSecondary)
        .padding(.horizontal, model.activeSection == .market ? 10 : 0)
        .frame(height: HPLayout.expandedFooterHeight)
        .background(HPTheme.canvas.opacity(0.98))
        .overlay(alignment: .top) {
            Rectangle().fill(HPTheme.line).frame(height: 1)
        }
    }

    private func selectSection(_ section: SidebarSection) {
        if model.panelMode == .settings {
            model.closeSettings()
        }
        model.switchSection(to: section)
    }

    private func footerIcon(_ systemName: String, active: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(active ? HPTheme.positive : HPTheme.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredPositions: [Position] {
        let query = normalizedSearch.lowercased()
        let matchingPositions = model.positions.filter { position in
            guard positionFilter.matches(position) else { return false }
            guard !query.isEmpty else { return true }
            return position.coin.localizedCaseInsensitiveContains(query)
                || "\(position.coin)-PERP".localizedCaseInsensitiveContains(query)
        }

        return matchingPositions.sorted { lhs, rhs in
            switch positionSort {
            case .pnlHighToLow:
                if lhs.unrealizedPnl == rhs.unrealizedPnl { return lhs.coin < rhs.coin }
                return lhs.unrealizedPnl > rhs.unrealizedPnl
            case .pnlLowToHigh:
                if lhs.unrealizedPnl == rhs.unrealizedPnl { return lhs.coin < rhs.coin }
                return lhs.unrealizedPnl < rhs.unrealizedPnl
            case .asset:
                return lhs.coin.localizedCaseInsensitiveCompare(rhs.coin) == .orderedAscending
            case .leverage:
                if lhs.leverage == rhs.leverage { return lhs.coin < rhs.coin }
                return lhs.leverage > rhs.leverage
            }
        }
    }

    private var normalizedSearch: String {
        positionSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasPositionFiltering: Bool {
        !normalizedSearch.isEmpty || positionFilter != .all
    }

    private var positionCountLabel: String {
        if hasPositionFiltering {
            return "\(filteredPositions.count) of \(model.positions.count) Positions"
        }
        return "\(model.positions.count) Open Position\(model.positions.count == 1 ? "" : "s")"
    }

    private var clearFilteringLabel: String {
        if normalizedSearch.isEmpty {
            return "Clear filter"
        }
        if positionFilter == .all {
            return "Clear search"
        }
        return "Clear search and filter"
    }

    private func clearPositionFiltering() {
        positionSearchText = ""
        positionFilter = .all
    }
}

private struct ExpandedFooterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? HPTheme.surfacePressed : Color.clear)
            .contentShape(Rectangle())
    }
}

private struct ExpandedHeaderIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(hovered ? HPTheme.textPrimary : HPTheme.textSecondary)
                .frame(width: 38, height: 38)
                .background {
                    Circle()
                        .fill(hovered ? HPTheme.surfaceRaised.opacity(0.72) : Color.clear)
                        .overlay {
                            Circle()
                                .strokeBorder(hovered ? HPTheme.lineStrong : HPTheme.line, lineWidth: 0.8)
                        }
                }
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(HPMotion.control, value: hovered)
        .help(label)
        .accessibilityLabel(label)
    }
}

private struct ExpandedPositionCard: View {
    @EnvironmentObject private var model: AppModel
    let position: Position
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                AssetIcon(coin: position.coin, size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(position.coin)-PERP")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HPTheme.textPrimary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(HPTheme.textSecondary)
                    }
                    SideBadge(position: position)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(HPFormat.signedCurrency(position.unrealizedPnl))
                        .font(.system(size: 17, weight: .bold).monospacedDigit())
                        .contentTransition(.numericText())
                    Text(HPFormat.signedPercent(position.pnlPercent))
                        .font(.system(size: 14, weight: .semibold).monospacedDigit())
                }
                .foregroundStyle(position.isProfitable ? HPTheme.positive : HPTheme.negative)

                Button {
                    model.openHyperliquid(for: position.coin)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                        .frame(width: 24, height: 44)
                }
                .buttonStyle(.plain)
                .help("Open \(position.coin) on Hyperliquid")
                .accessibilityLabel("Open \(position.coin) on Hyperliquid")
            }
            .frame(height: 44)

            HStack(spacing: 0) {
                MetricView(label: "Size", value: HPFormat.currency(position.notionalValue))
                    .frame(width: 154, alignment: .leading)
                MetricView(label: "Entry", value: HPFormat.price(position.entryPrice))
                    .frame(width: 139, alignment: .leading)
                MetricView(label: "Mark", value: HPFormat.price(position.markPrice))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 13)

            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)
                .padding(.top, 13)

            HStack(alignment: .bottom, spacing: 0) {
                MetricView(label: "Liq. Price", value: HPFormat.price(position.liquidationPrice))
                    .frame(width: 84, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(HPTheme.textSecondary)
                    Text(HPFormat.liquidationDistance(position.liquidationDistance))
                        .font(.system(size: 14, weight: .medium).monospacedDigit())
                        .foregroundStyle(liquidationColor)
                        .lineLimit(1)
                }
                .frame(width: 102, alignment: .leading)

                VStack(alignment: .trailing, spacing: 5) {
                    LiquidationBar(distance: position.liquidationDistance, height: 4)
                    Text(liquidationLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(liquidationColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 15)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hovered ? HPTheme.surface.opacity(0.86) : HPTheme.surface.opacity(0.62))
                .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                            hovered ? HPTheme.positive.opacity(0.42) : HPTheme.line,
                            lineWidth: 0.8
                        )
                }
        }
        .onHover { hovered = $0 }
        .animation(HPMotion.control, value: hovered)
    }

    private var liquidationLabel: String {
        guard let distance = position.liquidationDistance else { return "UNAVAILABLE" }
        if distance < 12 { return "HIGH RISK" }
        if distance < 18 { return "MEDIUM RISK" }
        return "SAFE"
    }

    private var liquidationColor: Color {
        guard let distance = position.liquidationDistance else { return HPTheme.textSecondary }
        if distance < 12 { return HPTheme.negative }
        if distance < 18 { return HPTheme.warning }
        return HPTheme.positive
    }
}
