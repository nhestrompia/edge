import SwiftUI

struct SettingsPageView: View {
    @EnvironmentObject private var model: AppModel

    private var hasWallet: Bool {
        !model.trackedAddress.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 18)

                accountSection
                sectionDivider
                behaviorSection
                sectionDivider
                displaySection

                trustNote
                    .padding(.top, 20)
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
            EdgeLogo(size: HPLayout.edgeLogoSize, foreground: HPTheme.textPrimary)

            Text("Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(HPTheme.textPrimary)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var accountSection: some View {
        settingsSection(title: "Account") {
            HStack(spacing: 12) {
                HyperliquidIcon(
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

         
        }
    }

    private var behaviorSection: some View {
        settingsSection(title: "Behavior") {
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
        settingsSection(title: "Display") {
            // settingPickerRow(
            //     title: "PnL shown as",
            //     accessibilityLabel: "PnL display",
            //     selection: $model.preferences.pnlDisplayMode,
            //     options: PnLDisplayMode.allCases,
            //     titleForOption: { $0.title }
            // )

            // Divider()
            //     .overlay(HPTheme.line)

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
          
        }
       
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(HPTheme.line)
            .padding(.vertical, 14)
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HPTheme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 10)

            content()
        }
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
            .frame(width: 148, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
