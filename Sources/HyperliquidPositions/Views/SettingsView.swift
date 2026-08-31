import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $model.preferences.launchAtLogin)
                Toggle("Always on top", isOn: $model.preferences.alwaysOnTop)
                Toggle("Collapse to notch when inactive", isOn: $model.preferences.autoHide)
            }

            Section("Display") {
                Picker("PnL display", selection: $model.preferences.pnlDisplayMode) {
                    ForEach(PnLDisplayMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("Screen side", selection: $model.preferences.sidebarEdge) {
                    ForEach(SidebarEdge.allCases) { edge in
                        Text(edge.title).tag(edge)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Account") {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Hyperliquid wallet")
                        Text(model.abbreviatedAddress)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Change Wallet…") {
                        model.changeWallet()
                    }
                }
            }

            Section {
                Label("This app only reads public Hyperliquid account data.", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 500)
        .navigationTitle("edge")
    }
}
