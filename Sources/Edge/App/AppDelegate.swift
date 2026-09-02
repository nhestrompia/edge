import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelCoordinator: EdgePanelCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panelCoordinator = EdgePanelCoordinator(model: AppModel.shared)
        panelCoordinator?.show()
        AppModel.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
