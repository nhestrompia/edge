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

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var positions: [Position] = []
    @Published var panelMode: PanelMode
    @Published var hoveredPositionID: Position.ID?
    @Published private(set) var connectionState: ConnectionState = .idle
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var onboardingError: String?
    @Published private(set) var isSubmittingWallet = false

    var preferences: AppPreferences

    private let api = HyperliquidAPI()
    private let socket = HyperliquidWebSocket()
    private var reconciliationTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?
    private var collapseTask: Task<Void, Never>?
    private var preferencesCancellable: AnyCancellable?
    private let isDemoMode: Bool

    var hoveredPosition: Position? {
        positions.first { $0.id == hoveredPositionID }
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

    private init() {
        isDemoMode = ProcessInfo.processInfo.environment["HYPERLIQUID_DEMO"] == "1"
        if isDemoMode {
            preferences = AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        } else {
            preferences = AppPreferences()
        }
        if isDemoMode {
            positions = Position.demo
            panelMode = .rail
            connectionState = .live
            lastUpdated = .now
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
            animate(.snappy(duration: 0.36)) {
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
        hoveredPositionID = nil
        onboardingError = nil
        panelMode = .onboarding
    }

    func pointerEntered() {
        collapseTask?.cancel()
        if panelMode == .notch {
            animate(.snappy(duration: 0.32, extraBounce: 0.08)) {
                panelMode = .rail
            }
        }
    }

    func pointerExited() {
        guard preferences.autoHide, panelMode != .onboarding else { return }
        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled, let self else { return }
            self.collapseToNotch()
        }
    }

    func hover(positionID: Position.ID?) {
        collapseTask?.cancel()
        guard hoveredPositionID != positionID else { return }
        animate(.snappy(duration: 0.28, extraBounce: 0.04)) {
            hoveredPositionID = positionID
        }
    }

    func selectAdjacentPosition(offset: Int) {
        guard !positions.isEmpty else { return }
        let currentIndex = hoveredPositionID.flatMap { id in positions.firstIndex { $0.id == id } }
            ?? (offset > 0 ? -1 : 0)
        let nextIndex = (currentIndex + offset + positions.count) % positions.count
        hover(positionID: positions[nextIndex].id)
    }

    func expand() {
        collapseTask?.cancel()
        animate(.snappy(duration: 0.38, extraBounce: 0.04)) {
            hoveredPositionID = nil
            panelMode = .expanded
        }
    }

    func showRail() {
        collapseTask?.cancel()
        animate(.snappy(duration: 0.3)) {
            hoveredPositionID = nil
            panelMode = .rail
        }
    }

    func hidePositions() {
        animate(.snappy(duration: 0.3)) {
            hoveredPositionID = nil
            panelMode = .notch
        }
    }

    func showPositions() {
        animate(.snappy(duration: 0.3)) {
            panelMode = .rail
        }
    }

    func openHyperliquid(for coin: String) {
        let encodedCoin = coin.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? coin
        guard let url = URL(string: "https://app.hyperliquid.xyz/trade/\(encodedCoin)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func collapseToNotch() {
        animate(.snappy(duration: 0.34, extraBounce: 0.04)) {
            hoveredPositionID = nil
            panelMode = .notch
        }
    }

    private func animate(_ animation: Animation, changes: () -> Void) {
        withAnimation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : animation, changes)
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
                    self.connectionState = .live
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
    }

    private func stopMonitoring() {
        reconciliationTask?.cancel()
        streamTask?.cancel()
        reconciliationTask = nil
        streamTask = nil
        Task { await socket.disconnect() }
    }

    private func refresh(address: String) async {
        do {
            positions = try await api.fetchPositions(for: address)
            connectionState = .live
            lastUpdated = .now
        } catch {
            if !positions.isEmpty {
                connectionState = .stale
            }
        }
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
        connectionState = .live
        lastUpdated = .now
    }

    static func abbreviate(_ address: String) -> String {
        guard address.count > 12 else { return address }
        return "\(address.prefix(6))…\(address.suffix(4))"
    }
}
