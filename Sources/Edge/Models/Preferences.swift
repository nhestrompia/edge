import AppKit
import Combine
import Foundation
import ServiceManagement

enum PnLDisplayMode: String, CaseIterable, Identifiable {
    case usd
    case percentage

    var id: String { rawValue }
    var title: String { self == .usd ? "USD" : "Percentage" }
}

enum SidebarEdge: String, CaseIterable, Identifiable {
    case left
    case right

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

@MainActor
final class AppPreferences: ObservableObject {
    private enum Key {
        static let launchAtLogin = "launchAtLogin"
        static let alwaysOnTop = "alwaysOnTop"
        static let autoHide = "autoHide"
        static let pnlDisplayMode = "pnlDisplayMode"
        static let sidebarEdge = "sidebarEdge"
        static let walletAddress = "walletAddress"
        static let panelCenterY = "panelCenterY"
    }

    private let defaults: UserDefaults

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: Key.alwaysOnTop) }
    }

    @Published var autoHide: Bool {
        didSet { defaults.set(autoHide, forKey: Key.autoHide) }
    }

    @Published var pnlDisplayMode: PnLDisplayMode {
        didSet { defaults.set(pnlDisplayMode.rawValue, forKey: Key.pnlDisplayMode) }
    }

    @Published var sidebarEdge: SidebarEdge {
        didSet { defaults.set(sidebarEdge.rawValue, forKey: Key.sidebarEdge) }
    }

    @Published var walletAddress: String {
        didSet { defaults.set(walletAddress, forKey: Key.walletAddress) }
    }

    @Published var panelCenterY: Double {
        didSet { defaults.set(panelCenterY, forKey: Key.panelCenterY) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        launchAtLogin = defaults.object(forKey: Key.launchAtLogin) as? Bool ?? false
        alwaysOnTop = defaults.object(forKey: Key.alwaysOnTop) as? Bool ?? true
        autoHide = defaults.object(forKey: Key.autoHide) as? Bool ?? true
        pnlDisplayMode = PnLDisplayMode(rawValue: defaults.string(forKey: Key.pnlDisplayMode) ?? "") ?? .usd
        sidebarEdge = SidebarEdge(rawValue: defaults.string(forKey: Key.sidebarEdge) ?? "") ?? .right
        walletAddress = defaults.string(forKey: Key.walletAddress) ?? ""
        panelCenterY = defaults.double(forKey: Key.panelCenterY)
    }

    private func updateLaunchAtLogin() {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }

        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
