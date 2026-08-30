import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var walletAddress = ""
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HyperliquidMark(size: 46)
                Spacer()
                Text("READ-ONLY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(HPTheme.positive)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(HPTheme.positiveMuted))
            }

            Text("Track your Hyperliquid positions")
                .font(.system(size: 27, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(HPTheme.textPrimary)
                .padding(.top, 22)

            Text("Keep every open perpetual position visible at the edge of your Mac.")
                .font(.system(size: 14))
                .foregroundStyle(HPTheme.textSecondary)
                .lineSpacing(3)
                .padding(.top, 8)
                .frame(maxWidth: 350, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text("PUBLIC WALLET ADDRESS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(HPTheme.textSecondary)

                HStack(spacing: 10) {
                    Image(systemName: "wallet.pass")
                        .foregroundStyle(addressFocused ? HPTheme.positive : HPTheme.textSecondary)
                    TextField("0x…", text: $walletAddress)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium).monospaced())
                        .foregroundStyle(HPTheme.textPrimary)
                        .focused($addressFocused)
                        .onSubmit { submit() }

                    if !walletAddress.isEmpty {
                        Button {
                            walletAddress = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(HPTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear wallet address")
                    }
                }
                .padding(.horizontal, 13)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HPTheme.surfaceRaised)
                )
                .hpFocusRing(addressFocused)

                if let error = model.onboardingError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(HPTheme.negative)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 26)

            Button(action: submit) {
                HStack(spacing: 8) {
                    if model.isSubmittingWallet {
                        ProgressView()
                            .controlSize(.small)
                            .tint(HPTheme.canvas)
                    }
                    Text(model.isSubmittingWallet ? "Checking account…" : "Track wallet")
                    if !model.isSubmittingWallet {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(HPTheme.canvas)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(HPTheme.positive)
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isSubmittingWallet || walletAddress.isEmpty)
            .opacity(walletAddress.isEmpty ? 0.48 : 1)
            .padding(.top, 14)

            HStack(spacing: 18) {
                trustPoint("No connection", icon: "link.badge.plus")
                trustPoint("No private keys", icon: "key.slash")
            }
            .padding(.top, 18)
        }
        .padding(28)
        .frame(width: HPLayout.onboardingSize.width, height: HPLayout.onboardingSize.height)
        .hpPanelSurface(cornerRadius: 24)
        .onAppear {
            addressFocused = true
        }
        .animation(.easeOut(duration: 0.2), value: model.onboardingError)
    }

    private func trustPoint(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(HPTheme.textSecondary)
    }

    private func submit() {
        guard !model.isSubmittingWallet else { return }
        Task { await model.trackWallet(walletAddress) }
    }
}
