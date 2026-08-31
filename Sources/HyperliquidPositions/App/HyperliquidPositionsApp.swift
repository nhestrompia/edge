import AppKit
import SwiftUI

/*
 THESIS: A market-aware edge instrument that removes tab switching; it refuses the miniature-dashboard default by resting as a notch and revealing depth only in place.
 OWN-WORLD: Near-black graphite panels, mint live/profit states, explicit red risk states, fine instrument rules, rounded native controls, and tabular financial figures.
 STORY: The trader supplies one public address, sees live positions at the screen edge, inspects one by hovering, and expands only when the whole account matters.
 FIRST VIEWPORT: A 30-point right-edge notch opens into a 112-point vertical rail; the active asset grows a left-facing inspector, while click reveals a 438-point all-position board.
 FORM: User-pinned edge cockpit, seed f1eedd09. FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md
 */
@main
struct HyperliquidPositionsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra("edge", systemImage: "waveform.path.ecg") {
            Button("Show Positions") {
                model.switchSection(to: .positions)
                model.showPositions()
            }

            Button("Show Markets") {
                model.switchSection(to: .market)
                model.showPositions()
            }

            Button("Hide Positions") {
                model.hidePositions()
            }

            SettingsLink {
                Text("Settings…")
            }

            Divider()

            Button("Quit edge") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            AppSettingsView()
                .environmentObject(model)
        }
    }
}
