import AppKit
import Combine
import SwiftUI

final class UtilityPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class EdgePanelCoordinator: NSObject {
    private let model: AppModel
    private let panel: UtilityPanel
    private var cancellables = Set<AnyCancellable>()
    private var dragOrigin: CGPoint?
    private var pendingFrameUpdate: Task<Void, Never>?
    private var lastRequestedFrame: CGRect?
    private var lastAppliedMode: PanelMode?

    init(model: AppModel) {
        self.model = model
        panel = UtilityPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        configurePanel()
        installContent()
        observeModel()
        updateFrame(animated: false)
    }

    func show() {
        panel.orderFrontRegardless()
        if model.panelMode == .onboarding {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKey()
        }

        if ProcessInfo.processInfo.environment["EDGE_LAYOUT_STRESS"] == "1" {
            model.prepareLayoutStressData()
            runLayoutStressSequence()
            return
        }

        if let captureDirectory = ProcessInfo.processInfo.environment["HYPERLIQUID_CAPTURE_DIR"] {
            runDemoCaptureSequence(in: URL(fileURLWithPath: captureDirectory, isDirectory: true))
        }
    }

    private func configurePanel() {
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.level = model.preferences.alwaysOnTop ? .floating : .normal
        panel.animationBehavior = .none
        panel.title = "edge"
        panel.acceptsMouseMovedEvents = true
        panel.contentView?.wantsLayer = true
    }

    private func installContent() {
        let root = SidebarRootView(
            onCloseOnboarding: { [weak self] in
                self?.closeOnboarding()
            },
            onDragChanged: { [weak self] translation in
                self?.dragChanged(translation)
            },
            onDragEnded: { [weak self] in
                self?.dragEnded()
            }
        )
        .environmentObject(model)

        panel.contentView = Self.makeContentView(rootView: root)
    }

    static func makeContentView<Content: View>(rootView: Content) -> NSView {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.sizingOptions = []
        hostingView.safeAreaRegions = []
        hostingView.sceneBridgingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = .zero
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        // Keep SwiftUI out of NSWindow sizing. A direct NSHostingView contentView can
        // feed its animated content size back into AppKit while the panel is resizing.
        let containerView = NSView(frame: .zero)
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        containerView.addSubview(hostingView)
        return containerView
    }

    private func observeModel() {
        model.$isPanelVisible
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isVisible in
                guard let self else { return }
                if isVisible {
                    self.updateFrame(animated: false)
                } else {
                    self.panel.orderOut(nil)
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            model.$panelMode,
            model.$hoveredPositionID,
            model.$hoveredMarketSymbol,
            model.$activeSection
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.scheduleFrameUpdate(animated: true)
        }
        .store(in: &cancellables)

        Publishers.Merge(
            model.$positions.map(\.count),
            model.$marketQuotes.map(\.count)
        )
        .removeDuplicates()
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.scheduleFrameUpdate(animated: true)
        }
        .store(in: &cancellables)

        model.preferences.$alwaysOnTop
            .removeDuplicates()
            .sink { [weak self] alwaysOnTop in
                self?.panel.level = alwaysOnTop ? .floating : .normal
            }
            .store(in: &cancellables)

        model.preferences.$sidebarEdge
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.scheduleFrameUpdate(animated: true)
            }
            .store(in: &cancellables)
    }

    private func scheduleFrameUpdate(animated: Bool) {
        pendingFrameUpdate?.cancel()
        pendingFrameUpdate = Task { [weak self] in
            await Task.yield()
            guard !Task.isCancelled else { return }
            self?.updateFrame(animated: animated)
        }
    }

    private func updateFrame(animated: Bool) {
        guard model.isPanelVisible else {
            panel.orderOut(nil)
            return
        }

        guard let screen = screenForPanel() else { return }
        let visibleFrame = screen.visibleFrame
        let size = targetSize(in: visibleFrame)

        let storedCenterY = model.preferences.panelCenterY
        let currentCenterY = panel.frame.isEmpty ? 0 : panel.frame.midY
        let isEnteringOnboarding = model.panelMode == .onboarding && lastAppliedMode != .onboarding
        let preferredCenterY: CGFloat
        if isEnteringOnboarding || panel.frame.isEmpty {
            preferredCenterY = visibleFrame.midY
        } else if currentCenterY > 0 {
            preferredCenterY = currentCenterY
        } else if storedCenterY > 0 {
            preferredCenterY = storedCenterY
        } else {
            preferredCenterY = visibleFrame.midY
        }

        let y = min(
            max(preferredCenterY - size.height / 2, visibleFrame.minY + 8),
            visibleFrame.maxY - size.height - 8
        )

        let edgeOverlap: CGFloat = 7
        let preferredX: CGFloat
        if model.panelMode == .onboarding {
            preferredX = isEnteringOnboarding || panel.frame.isEmpty
                ? visibleFrame.midX - size.width / 2
                : panel.frame.minX
        } else if model.preferences.sidebarEdge == .right {
            preferredX = visibleFrame.maxX - size.width + edgeOverlap
        } else {
            preferredX = visibleFrame.minX - edgeOverlap
        }

        let x = model.panelMode == .onboarding
            ? min(max(preferredX, visibleFrame.minX + 8), visibleFrame.maxX - size.width - 8)
            : preferredX
        let targetFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)

        if lastRequestedFrame != targetFrame {
            lastRequestedFrame = targetFrame

            let isCapturing = ProcessInfo.processInfo.environment["HYPERLIQUID_CAPTURE_DIR"] != nil
            if animated, panel.isVisible, !isCapturing, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                let isInspectorResize = lastAppliedMode == .rail
                    && model.panelMode == .rail
                    && abs(panel.frame.width - targetFrame.width) > 0.5
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = isInspectorResize ? 0.24 : 0.34
                    context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1, 0.3, 1)
                    panel.animator().setFrame(targetFrame, display: true)
                }
            } else {
                panel.setFrame(targetFrame, display: true)
            }
        }

        lastAppliedMode = model.panelMode
        panel.orderFrontRegardless()
        if model.panelMode == .onboarding {
            panel.makeKey()
        }
    }

    private func targetSize(in visibleFrame: CGRect) -> CGSize {
        switch model.panelMode {
        case .onboarding:
            HPLayout.onboardingSize
        case .notch:
            HPLayout.notchSize
        case .rail:
            CGSize(
                width: model.hasActiveInspector
                    ? HPLayout.railWidth + HPLayout.inspectorWidth
                    : HPLayout.railWidth,
                height: railHeight(in: visibleFrame)
            )
        case .expanded:
            CGSize(
                width: HPLayout.expandedWidth,
                height: min(710, visibleFrame.height - 20)
            )
        }
    }

    private func railHeight(in visibleFrame: CGRect) -> CGFloat {
        let itemCount = model.activeSection == .positions ? model.positions.count : model.marketQuotes.count
        let contentHeight = HPLayout.railTopPadding
            + CGFloat(max(itemCount, 1)) * HPLayout.positionRowHeight
            + HPLayout.railFooterHeight
        return min(max(contentHeight, 242), min(630, visibleFrame.height - 20))
    }

    private func dragChanged(_ translation: CGSize) {
        guard let screen = screenForPanel() else { return }
        if dragOrigin == nil {
            dragOrigin = panel.frame.origin
        }
        guard let dragOrigin else { return }

        let visibleFrame = screen.visibleFrame
        let targetX = model.panelMode == .onboarding
            ? dragOrigin.x + translation.width
            : panel.frame.minX
        let targetY = dragOrigin.y - translation.height
        let clampedX = model.panelMode == .onboarding
            ? min(max(targetX, visibleFrame.minX + 8), visibleFrame.maxX - panel.frame.width - 8)
            : panel.frame.minX
        let clampedY = min(
            max(targetY, visibleFrame.minY + 8),
            visibleFrame.maxY - panel.frame.height - 8
        )
        panel.setFrameOrigin(CGPoint(x: clampedX, y: clampedY))
        lastRequestedFrame = panel.frame
    }

    private func dragEnded() {
        dragOrigin = nil
        model.preferences.panelCenterY = panel.frame.midY
    }

    private func closeOnboarding() {
        guard model.panelMode == .onboarding else { return }
        panel.resignKey()
        model.dismissOnboarding()
    }

    private func screenForPanel() -> NSScreen? {
        panel.screen ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func runDemoCaptureSequence(in directory: URL) {
        panel.ignoresMouseEvents = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            model.panelMode = .onboarding
            try? await Task.sleep(for: .milliseconds(650))
            capturePanel(to: directory.appending(path: "00-onboarding.png"))

            model.switchSection(to: .positions)
            model.showRail()
            model.hover(positionID: nil)
            try? await Task.sleep(for: .milliseconds(650))
            capturePanel(to: directory.appending(path: "01-rail.png"))

            if let firstPosition = model.positions.first {
                model.hover(positionID: firstPosition.id)
                try? await Task.sleep(for: .milliseconds(650))
                capturePanel(to: directory.appending(path: "02-inspector.png"))
            }

            model.expand()
            try? await Task.sleep(for: .milliseconds(650))
            capturePanel(to: directory.appending(path: "03-expanded.png"))

            model.switchSection(to: .market)
            try? await Task.sleep(for: .milliseconds(600))
            capturePanel(to: directory.appending(path: "04-market-expanded.png"))

            model.showRail()
            try? await Task.sleep(for: .milliseconds(600))
            capturePanel(to: directory.appending(path: "05-market-rail.png"))

            if let firstMarket = model.marketQuotes.first {
                model.hover(marketSymbol: firstMarket.symbol)
                try? await Task.sleep(for: .milliseconds(650))
                capturePanel(to: directory.appending(path: "06-market-inspector.png"))

                model.preferences.sidebarEdge = .left
                try? await Task.sleep(for: .milliseconds(650))
                capturePanel(to: directory.appending(path: "07-left-edge-inspector.png"))
                model.preferences.sidebarEdge = .right
            }

            model.hidePositions()
            try? await Task.sleep(for: .milliseconds(650))
            capturePanel(to: directory.appending(path: "08-notch.png"))
            NSApp.terminate(nil)
        }
    }

    private func runLayoutStressSequence() {
        panel.ignoresMouseEvents = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            for index in 0..<24 {
                model.switchSection(to: index.isMultiple(of: 2) ? .positions : .market)
                model.showRail()
                try? await Task.sleep(for: .milliseconds(140))

                if model.activeSection == .positions {
                    model.hover(positionID: model.positions[index % model.positions.count].id)
                } else {
                    model.hover(marketSymbol: model.marketQuotes[index % model.marketQuotes.count].symbol)
                }
                try? await Task.sleep(for: .milliseconds(140))

                if model.activeSection == .positions {
                    model.hover(positionID: model.positions[(index + 1) % model.positions.count].id)
                    try? await Task.sleep(for: .milliseconds(70))
                }

                model.expand()
                try? await Task.sleep(for: .milliseconds(140))
                model.showRail()
                try? await Task.sleep(for: .milliseconds(140))
                model.hidePositions()
                try? await Task.sleep(for: .milliseconds(140))
            }

            print("[EDGE_LAYOUT_STRESS] PASS")
            NSApp.terminate(nil)
        }
    }

    private func capturePanel(to url: URL) {
        guard let view = panel.contentView,
              let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
