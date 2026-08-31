import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var walletAddress = ""
    @FocusState private var addressFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HyperliquidMark(size: 58)

            Spacer(minLength: 40)

            Text("Track your\nHyperliquid positions")
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.9)
                .foregroundStyle(HPTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Keep every open perpetual position\nvisible at the edge of your Mac.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(HPTheme.textSecondary)
                .lineSpacing(6)
                .padding(.top, 22)

            walletForm
                .padding(.top, 42)

            Spacer(minLength: 28)

            trustRow
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 30)
        .frame(width: HPLayout.onboardingSize.width, height: HPLayout.onboardingSize.height)
        .background(onboardingSurface)
        .onAppear { addressFocused = true }
        .animation(.easeOut(duration: 0.22), value: model.onboardingError)
    }

    private var walletForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PUBLIC WALLET ADDRESS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(HPTheme.textSecondary)

            HStack(spacing: 13) {
                Image(systemName: "wallet.pass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(addressFocused ? HPTheme.positive : HPTheme.textSecondary)

                TextField("0x…", text: $walletAddress)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .medium).monospaced())
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
            .padding(.horizontal, 17)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(HPTheme.surface.opacity(0.84))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(
                                addressFocused ? HPTheme.positive : HPTheme.lineStrong,
                                lineWidth: addressFocused ? 1.35 : 0.8
                            )
                    }
            )
            .padding(.top, 12)

            if let error = model.onboardingError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(HPTheme.negative)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
                    .transition(.opacity)
            }

            Button(action: submit) {
                HStack(spacing: 13) {
                    if model.isSubmittingWallet {
                        ProgressView()
                            .controlSize(.small)
                            .tint(HPTheme.positive)
                    }
                    Text(model.isSubmittingWallet ? "Checking account…" : "Track wallet")
                    if !model.isSubmittingWallet {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HPTheme.positive)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    HPTheme.positive.opacity(0.26),
                                    HPTheme.positiveMuted.opacity(0.78)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(HPTheme.positive.opacity(0.14), lineWidth: 0.8)
                        }
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isSubmittingWallet || walletAddress.isEmpty)
            .opacity(walletAddress.isEmpty ? 0.58 : 1)
            .padding(.top, 16)
        }
    }

    private var trustRow: some View {
        HStack(spacing: 0) {
            trustPoint("No connection", icon: "link.badge.plus")
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(HPTheme.line)
                .frame(width: 1, height: 24)

            trustPoint("No private keys", icon: "key.slash")
                .frame(maxWidth: .infinity)
        }
    }

    private var onboardingSurface: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(HPTheme.canvas.opacity(0.985))
            .overlay {
                ZStack {
                    RadialGradient(
                        colors: [HPTheme.positive.opacity(0.13), .clear],
                        center: .bottomLeading,
                        startRadius: 0,
                        endRadius: 270
                    )
                    RadialGradient(
                        colors: [Color.purple.opacity(0.11), .clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 260
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(HPTheme.lineStrong, lineWidth: 0.8)
            }
    }

    private func trustPoint(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(HPTheme.textSecondary)
            .labelStyle(TrustLabelStyle())
    }

    private func submit() {
        guard !model.isSubmittingWallet else { return }
        Task { await model.trackWallet(walletAddress) }
    }
}

private struct TrustLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(HPTheme.positive)
            configuration.title
        }
    }
}
