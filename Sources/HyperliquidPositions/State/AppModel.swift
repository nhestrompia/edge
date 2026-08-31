import AppKit
import Combine
import Foundation
import SwiftUI

enum PanelMode: Equatable {
    case onboarding
    case notch
    case rail
    case expanded
}

enum ConnectionState: Equatable {
    case idle
    case connecting
    case live
    case stale

    var label: String {
        switch self {
        case .idle: "Waiting"
        case .connecting: "Connecting"
        case .live: "Live"
        case .stale: "Reconnecting"
        }
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case positions
    case market

    var id: Self { self }
    var label: String { rawValue.capitalized }
}

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var positions: [Position] = []
    @Published private(set) var marketQuotes: [MarketQuote] = []
    @Published var panelMode: PanelMode
    @Published var activeSection: SidebarSection = .positions
    @Published var hoveredPositionID: Position.ID?
    @Published var hoveredMarketSymbol: String?
    @Published private(set) var connectionState: ConnectionState = .idle
    @Published private(set) var marketConnectionState: ConnectionState = .idle
    private(set) var lastUpdated: Date?
    private(set) var marketLastUpdated: Date?
    @Published private(set) var onboardingError: String?
    @Published private(set) var isSubmittingWallet = false

    var preferences: AppPreferences

    private let api = HyperliquidAPI()
    private let socket = HyperliquidWebSocket()
    private let binanceAPI = BinanceAPI()
    private let binanceSocket = BinanceWebSocket()
    private var reconciliationTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?
    private var marketRefreshTask: Task<Void, Never>?
    private var marketStreamTask: Task<Void, Never>?
    private var collapseTask: Task<Void, Never>?
    private var preferencesCancellable: AnyCancellable?
    private let isDemoMode: Bool
    private let isCaptureMode: Bool

    var hoveredPosition: Position? {
        positions.first { $0.id == hoveredPositionID }
    }

    var hoveredMarketQuote: MarketQuote? {
        marketQuotes.first { $0.symbol == hoveredMarketSymbol }
    }

    var hasActiveInspector: Bool {
        switch activeSection {
        case .positions: hoveredPosition != nil
        case .market: hoveredMarketQuote != nil
        }
    }

    var activeConnectionState: ConnectionState {
        activeSection == .positions ? connectionState : marketConnectionState
    }

    var totalUnrealizedPnl: Double {
        positions.reduce(0) { $0 + $1.unrealizedPnl }
    }

    var combinedPnlPercent: Double {
        let margin = positions.reduce(0) { $0 + $1.marginUsed }
        return margin > 0 ? totalUnrealizedPnl / margin * 100 : 0
    }

    var abbreviatedAddress: String {
        Self.abbreviate(trackedAddress)
    }

    var trackedAddress: String {
        isDemoMode ? "0x8f3a77b2588e4869945ea50cbe8b9e36c43a9c45" : preferences.walletAddress
    }

    var isShowingDemoData: Bool { isDemoMode }

    func prepareLayoutStressData() {
        guard ProcessInfo.processInfo.environment["EDGE_LAYOUT_STRESS"] == "1" else { return }
        positions = Position.layoutStressDemo
        activeSection = .positions
        hoveredPositionID = nil
        panelMode = .notch
    }

    private init() {
        isDemoMode = ProcessInfo.processInfo.environment["HYPERLIQUID_DEMO"] == "1"
        isCaptureMode = ProcessInfo.processInfo.environment["HYPERLIQUID_CAPTURE_DIR"] != nil
        if isDemoMode {
            preferences = AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        } else {
            preferences = AppPreferences()
        }
        if isDemoMode {
            positions = Position.demo
            marketQuotes = MarketQuote.demo
            panelMode = .rail
            connectionState = .live
            marketConnectionState = .live
            lastUpdated = .now
            marketLastUpdated = .now
        } else {
            panelMode = preferences.walletAddress.isEmpty ? .onboarding : .notch
        }

        preferencesCancellable = preferences.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func start() {
        guard !isDemoMode, WalletAddressValidator.isValid(preferences.walletAddress) else { return }
        beginMonitoring()
    }

    func trackWallet(_ rawAddress: String) async {
        let address = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        onboardingError = nil

        guard WalletAddressValidator.isValid(address) else {
            onboardingError = "We couldn't find a valid Ethereum address. Check the address and try again."
            return
        }

        isSubmittingWallet = true
        connectionState = .connecting
        defer { isSubmittingWallet = false }

        do {
            let fetchedPositions = try await api.fetchPositions(for: address)
            preferences.walletAddress = address
            positions = fetchedPositions
            lastUpdated = .now
            connectionState = .live
            animate(.smooth(duration: 0.5, extraBounce: 0)) {
                panelMode = preferences.autoHide ? .notch : .rail
            }
            beginMonitoring()
        } catch {
            connectionState = .idle
            onboardingError = "We couldn't load this Hyperliquid account. Check your connection and try again."
        }
    }

    func changeWallet() {
        stopMonitoring()
        preferences.walletAddress = ""
        positions = []
        marketQuotes = []
        hoveredPositionID = nil
        hoveredMarketSymbol = nil
        activeSection = .positions
        onboardingError = nil
        panelMode = .onboarding
    }

    func pointerEntered() {
        collapseTask?.cancel()
        if panelMode == .notch {
            animate(.smooth(duration: 0.5, extraBounce: 0)) {
                panelMode = .rail
            }
        }
    }

    func pointerExited() {
        guard panelMode != .onboarding else { return }
        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(820))
            guard !Task.isCancelled, let self else { return }
            if self.preferences.autoHide {
                self.collapseToNotch()
            } else {
                self.animate(.smooth(duration: 0.46, extraBounce: 0)) {
                    self.hoveredPositionID = nil
                    self.hoveredMarketSymbol = nil
                }
            }
        }
    }

    func hover(positionID: Position.ID?) {
        collapseTask?.cancel()
        guard hoveredPositionID != positionID else { return }
        animate(.smooth(duration: 0.46, extraBounce: 0)) {
            hoveredPositionID = positionID
        }
    }

    func hover(marketSymbol: String?) {
        collapseTask?.cancel()
        guard hoveredMarketSymbol != marketSymbol else { return }
        animate(.smooth(duration: 0.46, extraBounce: 0)) {
            hoveredMarketSymbol = marketSymbol
        }
    }

    func switchSection(to section: SidebarSection) {
        guard activeSection != section else { return }
        collapseTask?.cancel()
        animate(.smooth(duration: 0.48, extraBounce: 0)) {
            hoveredPositionID = nil
            hoveredMarketSymbol = nil
            activeSection = section
        }
    }

    func selectAdjacentPosition(offset: Int) {
        guard !positions.isEmpty else { return }
        let currentIndex = hoveredPositionID.flatMap { id in positions.firstIndex { $0.id == id } }
            ?? (offset > 0 ? -1 : 0)
        let nextIndex = (currentIndex + offset + positions.count) % positions.count
        hover(positionID: positions[nextIndex].id)
    }

    func selectAdjacentMarket(offset: Int) {
        guard !marketQuotes.isEmpty else { return }
        let currentIndex = hoveredMarketSymbol.flatMap { symbol in
            marketQuotes.firstIndex { $0.symbol == symbol }
        } ?? (offset > 0 ? -1 : 0)
        let nextIndex = (currentIndex + offset + marketQuotes.count) % marketQuotes.count
        hover(marketSymbol: marketQuotes[nextIndex].symbol)
    }

    func expand() {
        collapseTask?.cancel()
        animate(.smooth(duration: 0.5, extraBounce: 0)) {
            hoveredPositionID = nil
            hoveredMarketSymbol = nil
            panelMode = .expanded
        }
    }

    func showRail() {
        collapseTask?.cancel()
        animate(.smooth(duration: 0.48, extraBounce: 0)) {
            hoveredPositionID = nil
            hoveredMarketSymbol = nil
            panelMode = .rail
        }
    }

    func hidePositions() {
        guard panelMode != .onboarding else { return }
        animate(.smooth(duration: 0.48, extraBounce: 0)) {
            hoveredPositionID = nil
            hoveredMarketSymbol = nil
            panelMode = .notch
        }
    }

    func showPositions() {
        guard WalletAddressValidator.isValid(trackedAddress) else {
            panelMode = .onboarding
            return
        }
        animate(.smooth(duration: 0.48, extraBounce: 0)) {
            panelMode = .rail
        }
    }

    func openHyperliquid(for coin: String) {
        let encodedCoin = coin.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? coin
        guard let url = URL(string: "https://app.hyperliquid.xyz/trade/\(encodedCoin)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func collapseToNotch() {
        animate(.smooth(duration: 0.5, extraBounce: 0)) {
            hoveredPositionID = nil
            hoveredMarketSymbol = nil
            panelMode = .notch
        }
    }

    private func animate(_ animation: Animation, changes: () -> Void) {
        let shouldReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion || isCaptureMode
        withAnimation(shouldReduceMotion ? nil : animation, changes)
    }

    private func beginMonitoring() {
        stopMonitoring()
        let address = preferences.walletAddress

        reconciliationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled, let self else { return }
                await self.refresh(address: address)
            }
        }

        streamTask = Task { [weak self] in
            var retryDelay = 1.0
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    self.connectionState = .connecting
                    let events = try await self.socket.events(for: address)
                    if self.connectionState != .live {
                        self.connectionState = .live
                    }
                    retryDelay = 1

                    for try await event in events {
                        guard !Task.isCancelled else { return }
                        self.consume(event)
                    }
                    throw HyperliquidWebSocket.StreamError.disconnected
                } catch {
                    guard !Task.isCancelled else { return }
                    self.connectionState = self.positions.isEmpty ? .connecting : .stale
                    try? await Task.sleep(for: .seconds(retryDelay))
                    retryDelay = min(retryDelay * 2, 30)
                }
            }
        }

        marketRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshMarkets()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled else { return }
                await self.refreshMarkets()
            }
        }

        marketStreamTask = Task { [weak self] in
            var retryDelay = 1.0
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    self.marketConnectionState = .connecting
                    let quotes = await self.binanceSocket.quotes()
                    retryDelay = 1

                    for try await quote in quotes {
                        guard !Task.isCancelled else { return }
                        self.consume(quote)
                    }
                    throw BinanceWebSocket.StreamError.malformedMessage
                } catch {
                    guard !Task.isCancelled else { return }
                    self.marketConnectionState = self.marketQuotes.isEmpty ? .connecting : .stale
                    try? await Task.sleep(for: .seconds(retryDelay))
                    retryDelay = min(retryDelay * 2, 30)
                }
            }
        }
    }

    private func stopMonitoring() {
        reconciliationTask?.cancel()
        streamTask?.cancel()
        marketRefreshTask?.cancel()
        marketStreamTask?.cancel()
        reconciliationTask = nil
        streamTask = nil
        marketRefreshTask = nil
        marketStreamTask = nil
        Task { await socket.disconnect() }
        Task { await binanceSocket.disconnect() }
    }

    private func refresh(address: String) async {
        do {
            positions = try await api.fetchPositions(for: address)
            if connectionState != .live {
                connectionState = .live
            }
            lastUpdated = .now
        } catch {
            if !positions.isEmpty {
                connectionState = .stale
            }
        }
    }

    private func refreshMarkets() async {
        do {
            marketQuotes = try await binanceAPI.fetchQuotes()
            marketLastUpdated = .now
            if marketConnectionState == .idle {
                marketConnectionState = .connecting
            }
        } catch {
            marketConnectionState = marketQuotes.isEmpty ? .connecting : .stale
        }
    }

    private func consume(_ quote: MarketQuote) {
        if let index = marketQuotes.firstIndex(where: { $0.symbol == quote.symbol }) {
            marketQuotes[index] = quote
        } else {
            marketQuotes.append(quote)
            marketQuotes.sort(by: BinanceAPI.sortQuotes)
        }
        if marketConnectionState != .live {
            marketConnectionState = .live
        }
        marketLastUpdated = quote.updatedAt
    }

    private func consume(_ event: HyperliquidWebSocket.Event) {
        switch event {
        case let .mids(mids):
            positions = positions.map { position in
                guard let mark = mids[position.coin] else { return position }
                return position.updating(markPrice: mark)
            }
        case let .account(state):
            if let normalized = try? HyperliquidAPI.normalize(state) {
                positions = normalized
            }
        }
        if connectionState != .live {
            connectionState = .live
        }
        lastUpdated = .now
    }

    static func abbreviate(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))…\(address.suffix(4))"
    }
}
