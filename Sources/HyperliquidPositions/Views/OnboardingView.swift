import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var walletAddress: String
    @State private var closeHovered = false
    @FocusState private var addressFocused: Bool
    private let initialWalletAddress: String
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void
    let onClose: () -> Void

    init(
        initialWalletAddress: String = "",
        onDragChanged: @escaping (CGSize) -> Void,
        onDragEnded: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.initialWalletAddress = initialWalletAddress
        _walletAddress = State(initialValue: initialWalletAddress)
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar

            Spacer(minLength: 10)

            Text("Track your\nHyperliquid positions")
                .font(.system(size: 36, weight: .bold))
                .tracking(-1.0)
                .foregroundStyle(HPTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Keep every open perpetual position\nvisible at the edge of your Mac.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(HPTheme.textSecondary)
                .lineSpacing(6)
                .padding(.top, 14)

            walletForm
                .padding(.top, 34)

            Spacer(minLength: 0)

            trustSection
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(width: HPLayout.onboardingSize.width, height: HPLayout.onboardingSize.height)
        .background(onboardingSurface)
        .onAppear {
            walletAddress = initialWalletAddress
            addressFocused = false
        }
        .animation(reduceMotion ? nil : HPMotion.control, value: model.onboardingError)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 0) {
            HyperliquidMark(size: 52)

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(closeHovered ? HPTheme.surfacePressed.opacity(0.84) : .clear))
                    .overlay {
                        Circle()
                            .strokeBorder(HPTheme.lineStrong.opacity(0.82), lineWidth: 0.9)
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .onHover { closeHovered = $0 }
            .help("Close setup")
            .accessibilityLabel("Close setup")
        }
        .frame(height: 52)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in onDragChanged(value.translation) }
                .onEnded { _ in onDragEnded() }
        )
        .help("Drag the top area to move setup")
    }

    private var walletForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PUBLIC WALLET ADDRESS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(HPTheme.textSecondary)

            HStack(spacing: 13) {
                Image(systemName: "clipboard")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(HPTheme.positive)

                TextField("0x...", text: $walletAddress)
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
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HPTheme.surface.opacity(0.55))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                addressFocused ? HPTheme.positive.opacity(0.86) : HPTheme.lineStrong,
                                lineWidth: addressFocused ? 1.25 : 0.8
                            )
                    }
            )
            .padding(.top, 11)

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
                .foregroundStyle(HPTheme.positive.opacity(walletAddress.isEmpty ? 0.88 : 1))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    HPTheme.positive.opacity(walletAddress.isEmpty ? 0.08 : 0.12),
                                    HPTheme.positiveMuted.opacity(walletAddress.isEmpty ? 0.40 : 0.52)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(HPTheme.positive.opacity(0.14), lineWidth: 0.8)
                        }
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isSubmittingWallet || walletAddress.isEmpty)
            .padding(.top, 12)
        }
    }

    private var trustSection: some View {
        let columnWidth = (HPLayout.onboardingSize.width - 64 - 1) / 2

        return VStack(spacing: 0) {
            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)

            HStack(spacing: 0) {
                trustPoint(icon: "lock") {
                    Text("We ")
                        .foregroundStyle(HPTheme.textSecondary)
                    + Text("never")
                        .foregroundStyle(HPTheme.positive)
                    + Text(" store your data.")
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .frame(width: columnWidth, alignment: .leading)

                Rectangle()
                    .fill(HPTheme.line)
                    .frame(width: 1, height: 21)

                trustPoint(icon: "shield") {
                    Text("Read-only.")
                        .foregroundStyle(HPTheme.positive)
                    + Text(" Nothing gets signed.")
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .padding(.leading, 8)
                .frame(width: columnWidth, alignment: .leading)
            }
            .padding(.top, 14)
            .frame(height: 39, alignment: .bottom)
        }
    }

    private var onboardingSurface: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(HPTheme.canvas.opacity(0.985))
            .overlay {
                ZStack {
                    RadialGradient(
                        colors: [HPTheme.positive.opacity(0.055), .clear],
                        center: .bottomLeading,
                        startRadius: 0,
                        endRadius: 320
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(HPTheme.lineStrong.opacity(0.9), lineWidth: 0.8)
            }
            .shadow(color: HPTheme.panelShadow.opacity(0.48), radius: 18, x: -2, y: 8)
    }

    private func trustPoint<Content: View>(
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(HPTheme.textSecondary)
                .frame(width: 24)

            content()
                .font(.system(size: 13.5, weight: .medium))
                .lineLimit(1)
        }
    }

    private func submit() {
        guard !model.isSubmittingWallet else { return }
        Task { await model.trackWallet(walletAddress) }
    }
}
