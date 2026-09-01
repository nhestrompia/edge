import AppKit
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var walletAddress: String
    @State private var closeHovered = false
    @State private var pasteHovered = false
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

            Spacer(minLength: 8)

            Text("Track your\nHyperliquid positions")
                .font(.system(size: 40, weight: .bold))
                .tracking(-1.1)
                .lineSpacing(4)
                .foregroundStyle(HPTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Keep every open perpetual position\nvisible at the edge of your Mac.")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(HPTheme.textSecondary)
                .lineSpacing(6)
                .padding(.top, 16)

            walletForm
                .padding(.top, 38)

            Spacer(minLength: 0)

            trustSection
        }
        .padding(.horizontal, 36)
        .padding(.top, 28)
        .padding(.bottom, 40)
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
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(HPTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(closeHovered ? HPTheme.surfacePressed.opacity(0.84) : .clear))
                    .overlay {
                        Circle()
                            .strokeBorder(HPTheme.lineStrong.opacity(0.82), lineWidth: 0.9)
                    }
                    .contentShape(Circle())
            }
            .offset(y: -5)
            .buttonStyle(.plain)
            .onHover { closeHovered = $0 }
            .help("Close setup")
            .accessibilityLabel("Close setup")
        }
        .frame(height: 48)
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
            Text("Wallet address")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(HPTheme.textSecondary)

            HStack(spacing: 0) {
                TextField("0x...", text: $walletAddress)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .medium).monospaced())
                    .foregroundStyle(HPTheme.textPrimary)
                    .focused($addressFocused)
                    .onSubmit { submit() }

                Spacer(minLength: 12)

                pasteButton
            }
            .padding(.leading, 17)
            .padding(.trailing, 12)
            .frame(height: 62)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HPTheme.onboardingField)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                addressFocused ? HPTheme.textSecondary.opacity(0.88) : HPTheme.lineStrong,
                                lineWidth: addressFocused ? 1.1 : 0.8
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
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(HPTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HPTheme.onboardingControl)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(HPTheme.line, lineWidth: 0.8)
                        }
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isSubmittingWallet)
            .padding(.top, 16)
        }
    }

    private var pasteButton: some View {
        Button(action: pasteWalletAddress) {
            HStack(spacing: 10) {
                Image(systemName: "clipboard")
                    .font(.system(size: 19, weight: .regular))

                Text("Paste")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(HPTheme.textPrimary)
            .frame(width: 92, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(pasteHovered ? HPTheme.surfacePressed.opacity(0.72) : HPTheme.onboardingControl.opacity(0.48))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(pasteHovered ? HPTheme.lineStrong : HPTheme.line, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
        .onHover { pasteHovered = $0 }
        .help("Paste wallet address")
        .accessibilityLabel("Paste wallet address")
    }

    private var trustSection: some View {
        let columnWidth = (HPLayout.onboardingSize.width - 72 - 1) / 2

        return VStack(spacing: 0) {
            Rectangle()
                .fill(HPTheme.line)
                .frame(height: 1)

            HStack(spacing: 0) {
                trustPoint(icon: "lock") {
                    Text("We ")
                        .foregroundStyle(HPTheme.textSecondary)
                    + Text("never")
                        .foregroundStyle(HPTheme.onboardingAccent)
                    + Text(" store your data.")
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .frame(width: columnWidth, alignment: .leading)

                Rectangle()
                    .fill(HPTheme.line)
                    .frame(width: 1, height: 21)

                trustPoint(icon: "shield") {
                    Text("Read-only.")
                        .foregroundStyle(HPTheme.onboardingAccent)
                    + Text(" Nothing gets signed.")
                        .foregroundStyle(HPTheme.textSecondary)
                }
                .padding(.leading, 8)
                .frame(width: columnWidth, alignment: .leading)
            }
            .padding(.top, 24)
            .frame(height: 49, alignment: .bottom)
        }
    }

    private var onboardingSurface: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(HPTheme.onboardingCanvas)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
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
        guard !model.isSubmittingWallet,
              !walletAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task { await model.trackWallet(walletAddress) }
    }

    private func pasteWalletAddress() {
        guard let pastedAddress = NSPasteboard.general.string(forType: .string) else { return }
        walletAddress = pastedAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        addressFocused = true
    }
}
