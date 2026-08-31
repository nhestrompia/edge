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

    var shortLabel: String {
        switch self {
        case .pnlHighToLow: "PnL high"
        case .pnlLowToHigh: "PnL low"
        case .asset: "Asset"
        case .leverage: "Leverage high"
        }
    }
}

struct ExpandedSidebarView: View {
    @EnvironmentObject private var model: AppModel
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    @FocusState private var isSearchFieldFocused: Bool
    @State private var positionFilter: ExpandedPositionFilter = .all
    @State private var positionSearchText = ""
    @State private var positionSort: ExpandedPositionSort = .pnlHighToLow

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)

            if model.activeSection == .positions {
                positionsContent
                    .transition(.opacity)
            } else {
                ExpandedMarketContent()
                    .transition(.opacity)
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
                Text("edge")
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
                StatusDot(state: model.activeConnectionState, size: 10)
                if model.activeConnectionState != .live {
                    Text(model.activeConnectionState.label)
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
                .onChanged { value in onDragChanged(value.translation) }
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

    private var positionsContent: some View {
        VStack(spacing: 0) {
            summary
                .padding(.horizontal, 16)
                .padding(.top, 14)

            HStack(spacing: 8) {
                searchField
                filterMenu
            }
            .padding(.horizontal, 16)
            .padding(.top, 11)

            HStack {
                Text(positionCountLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                Spacer()
                sortMenu
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 9)

            if model.positions.isEmpty {
                emptyState
            } else if filteredPositions.isEmpty {
                noMatchesState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredPositions) { position in
                            ExpandedPositionCard(position: position)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HPTheme.textSecondary)

            TextField("Search assets", text: $positionSearchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Clear search")
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(HPTheme.surfaceRaised.opacity(0.8))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(
                    isSearchFieldFocused ? HPTheme.positive.opacity(0.82) : HPTheme.line,
                    lineWidth: isSearchFieldFocused ? 1.2 : 0.8
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onTapGesture {
            isSearchFieldFocused = true
        }
        .animation(HPMotion.control, value: isSearchFieldFocused)
    }

    private var filterMenu: some View {
        Menu {
            ForEach(ExpandedPositionFilter.allCases) { filter in
                Button {
                    positionFilter = filter
                } label: {
                    HStack {
                        Text(filter.label)
                        Spacer()
                        if positionFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 12, weight: .semibold))
                Text(positionFilter == .all ? "Filter" : positionFilter.label)
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(positionFilter == .all ? HPTheme.textSecondary : HPTheme.positive)
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(
                        positionFilter == .all
                            ? HPTheme.surfaceRaised.opacity(0.8)
                            : HPTheme.positiveMuted.opacity(0.72)
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(
                        positionFilter == .all ? HPTheme.line : HPTheme.positive.opacity(0.42),
                        lineWidth: 0.8
                    )
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Filter positions")
        .accessibilityLabel("Filter positions")
        .accessibilityValue(positionFilter.label)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(ExpandedPositionSort.allCases) { sort in
                Button {
                    positionSort = sort
                } label: {
                    HStack {
                        Text(sort.label)
                        Spacer()
                        if positionSort == sort {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text("Sort: \(positionSort.shortLabel)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(HPTheme.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sort positions")
        .accessibilityLabel("Sort positions")
        .accessibilityValue(positionSort.label)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            Button {
                model.switchSection(to: .positions)
            } label: {
                footerIcon("briefcase", active: model.activeSection == .positions)
            }
            .help("Positions")
            .accessibilityLabel("Positions")
            .accessibilityAddTraits(model.activeSection == .positions ? .isSelected : [])

            Button {
                model.switchSection(to: .market)
            } label: {
                footerIcon("chart.line.uptrend.xyaxis", active: model.activeSection == .market)
            }
            .help("Markets")
            .accessibilityLabel("Markets")
            .accessibilityAddTraits(model.activeSection == .market ? .isSelected : [])

            SettingsLink {
                footerIcon("gearshape", active: false)
            }
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .buttonStyle(ExpandedFooterButtonStyle())
        .foregroundStyle(HPTheme.textSecondary)
        .frame(height: 57)
        .overlay(alignment: .top) {
            Rectangle().fill(HPTheme.line).frame(height: 1)
        }
    }

    private func footerIcon(_ systemName: String, active: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
            if active {
                StatusDot(state: model.activeConnectionState, size: 6)
                    .offset(x: 7, y: -5)
            }
        }
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

private struct ExpandedPositionCard: View {
    @EnvironmentObject private var model: AppModel
    let position: Position
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                AssetIcon(coin: position.coin, size: 38)
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
        .animation(HPMotion.control, value: hovered)
    }
}
