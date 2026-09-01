import SwiftUI

struct SettingsPageView: View {
    @EnvironmentObject private var model: AppModel
    let onBack: (() -> Void)?

    private var hasWallet: Bool {
        !model.trackedAddress.isEmpty
    }

    init(onBack: (() -> Void)? = nil) {
        self.onBack = onBack
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                accountSection
                behaviorSection
                displaySection

                trustNote
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HPTheme.canvas)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(HPTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(HPTheme.surfaceRaised.opacity(0.72)))
                        .overlay {
                            Circle()
                                .strokeBorder(HPTheme.line, lineWidth: 0.8)
                        }
                }
                .buttonStyle(.plain)
                .help("Back to overview")
                .accessibilityLabel("Back to overview")
            }

            HyperliquidMark(
                size: 40,
                foreground: HPTheme.positive,
                background: HPTheme.positive.opacity(0.10)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("edge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HPTheme.textSecondary)

                Text("Settings")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(HPTheme.textPrimary)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var accountSection: some View {
        settingsGroup(title: "Account") {
            HStack(spacing: 12) {
                HyperliquidMark(
                    size: 32,
                    foreground: HPTheme.positive,
                    background: HPTheme.positive.opacity(0.08)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(hasWallet ? model.abbreviatedAddress : "No wallet selected")
                        .font(.system(size: 14, weight: .medium).monospaced())
                        .foregroundStyle(HPTheme.textPrimary)
                        .lineLimit(1)

                    Text(hasWallet ? "Public Hyperliquid wallet" : "Add a public wallet to begin")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(HPTheme.textSecondary)
                }

                Spacer(minLength: 12)

                Button(hasWallet ? "Change" : "Add wallet") {
                    model.changeWallet()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(HPTheme.positive)
                .help(hasWallet ? "Change wallet" : "Add wallet")
                .accessibilityLabel(hasWallet ? "Change wallet" : "Add wallet")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider()
                .overlay(HPTheme.line)

            Label("Read-only access · no keys or signatures", systemImage: "lock.shield")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
        }
    }

    private var behaviorSection: some View {
        settingsGroup(title: "Behavior") {
            settingsToggle("Launch at login", isOn: $model.preferences.launchAtLogin)

            Divider()
                .overlay(HPTheme.line)

            settingsToggle("Always on top", isOn: $model.preferences.alwaysOnTop)

            Divider()
                .overlay(HPTheme.line)

            settingsToggle("Hide to notch when inactive", isOn: $model.preferences.autoHide)
        }
    }

    private var displaySection: some View {
        settingsGroup(title: "Display") {
            settingPickerRow(
                title: "PnL shown as",
                accessibilityLabel: "PnL display",
                selection: $model.preferences.pnlDisplayMode,
                options: PnLDisplayMode.allCases,
                titleForOption: { $0.title }
            )

            Divider()
                .overlay(HPTheme.line)

            settingPickerRow(
                title: "Screen edge",
                accessibilityLabel: "Screen edge",
                selection: $model.preferences.sidebarEdge,
                options: SidebarEdge.allCases,
                titleForOption: { $0.title }
            )
        }
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HPTheme.positive)
                .frame(width: 20)

            Text("edge only uses a public wallet address. It never requests private keys, signatures, or trading access.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HPTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 3)
        .padding(.top, 1)
    }

    private func settingsGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HPTheme.surface.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(HPTheme.line, lineWidth: 0.8)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func settingsToggle(
        _ title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HPTheme.textPrimary)

            Spacer(minLength: 12)

            Toggle(title, isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(HPTheme.positive)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func settingPickerRow<Selection: Hashable & Identifiable>(
        title: String,
        accessibilityLabel: String,
        selection: Binding<Selection>,
        options: [Selection],
        titleForOption: @escaping (Selection) -> String
    ) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HPTheme.textPrimary)

            Spacer(minLength: 12)

            Picker(accessibilityLabel, selection: selection) {
                ForEach(options) { option in
                    Text(titleForOption(option)).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 148)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
