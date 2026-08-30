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
    private var dragOriginY: CGFloat?

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
        panel.title = "Hyperliquid Positions"
        panel.acceptsMouseMovedEvents = true
        panel.contentView?.wantsLayer = true
    }

    private func installContent() {
        let root = SidebarRootView(
            onDragChanged: { [weak self] translation in
                self?.dragChanged(translation)
            },
            onDragEnded: { [weak self] in
                self?.dragEnded()
            }
        )
        .environmentObject(model)

        let hostingView = NSHostingView(rootView: root)
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
    }

    private func observeModel() {
        Publishers.CombineLatest3(
            model.$panelMode,
            model.$hoveredPositionID,
            model.$positions
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _ in
            self?.updateFrame(animated: true)
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
                self?.updateFrame(animated: true)
            }
            .store(in: &cancellables)
    }

    private func updateFrame(animated: Bool) {
        guard let screen = screenForPanel() else { return }
        let visibleFrame = screen.visibleFrame
        let size = targetSize(in: visibleFrame)

        let storedCenterY = model.preferences.panelCenterY
        let currentCenterY = panel.frame.isEmpty ? 0 : panel.frame.midY
        let preferredCenterY: CGFloat
        if model.panelMode == .onboarding {
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
        let x: CGFloat
        if model.panelMode == .onboarding {
            x = visibleFrame.midX - size.width / 2
        } else if model.preferences.sidebarEdge == .right {
            x = visibleFrame.maxX - size.width + edgeOverlap
        } else {
            x = visibleFrame.minX - edgeOverlap
        }

        let targetFrame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        guard panel.frame != targetFrame else { return }

        if animated, panel.isVisible, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.28
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.82, 0.2, 1)
                panel.animator().setFrame(targetFrame, display: true)
            }
        } else {
            panel.setFrame(targetFrame, display: true)
        }

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
                width: model.hoveredPositionID == nil
                    ? HPLayout.railWidth
                    : HPLayout.railWidth + HPLayout.inspectorWidth,
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
        let contentHeight = HPLayout.railTopPadding
            + CGFloat(max(model.positions.count, 1)) * HPLayout.positionRowHeight
            + HPLayout.railFooterHeight
        return min(max(contentHeight, 242), min(630, visibleFrame.height - 20))
    }

    private func dragChanged(_ translation: CGFloat) {
        guard model.panelMode != .onboarding, let screen = screenForPanel() else { return }
        if dragOriginY == nil {
            dragOriginY = panel.frame.origin.y
        }
        guard let dragOriginY else { return }

        let visibleFrame = screen.visibleFrame
        let targetY = dragOriginY - translation
        let clampedY = min(
            max(targetY, visibleFrame.minY + 8),
            visibleFrame.maxY - panel.frame.height - 8
        )
        panel.setFrameOrigin(CGPoint(x: panel.frame.minX, y: clampedY))
    }

    private func dragEnded() {
        dragOriginY = nil
        model.preferences.panelCenterY = panel.frame.midY
    }

    private func screenForPanel() -> NSScreen? {
        panel.screen ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func runDemoCaptureSequence(in directory: URL) {
        panel.ignoresMouseEvents = true

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            model.showRail()
            model.hover(positionID: nil)
            try? await Task.sleep(for: .milliseconds(450))
            capturePanel(to: directory.appending(path: "01-rail.png"))

            if let firstPosition = model.positions.first {
                model.hover(positionID: firstPosition.id)
                try? await Task.sleep(for: .milliseconds(450))
                capturePanel(to: directory.appending(path: "02-inspector.png"))
            }

            model.expand()
            try? await Task.sleep(for: .milliseconds(500))
            capturePanel(to: directory.appending(path: "03-expanded.png"))

            model.hidePositions()
            try? await Task.sleep(for: .milliseconds(450))
            capturePanel(to: directory.appending(path: "04-notch.png"))
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
