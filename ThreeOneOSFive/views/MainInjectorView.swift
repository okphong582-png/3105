import SwiftUI
import UIKit

struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()
    @ObservedObject private var modManager = ModFeatureManager.shared

    @AppStorage("oni_akuma_has_shown_welcome_v2") private var hasShownWelcome = false
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"

    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showWelcomeDialog = false

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroHeader

                    gameSelectorCard

                    // 4 Aim Mod Features Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("TÍNH NĂNG AIM BOT (4 CHẾ ĐỘ)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .tracking(1.0)

                            Spacer()

                            Text("4 GÓI MOD")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(activeTheme.primaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(activeTheme.primaryColor.opacity(0.12).cornerRadius(6))
                        }
                        .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            ForEach(AimModType.allCases) { aimType in
                                featureToggleCard(
                                    title: aimType.title,
                                    subtitle: aimType.subtitle,
                                    filename: aimType.filename,
                                    icon: aimType.icon,
                                    isEnabled: modManager.isAimModEnabled(aimType),
                                    isProcessing: modManager.isAimModProcessing(aimType),
                                    accentColor: aimType.accentColor
                                ) {
                                    modManager.toggleAimMod(aimType, store: store)
                                }
                            }
                        }
                    }

                    // Open Game Button
                    openGameButton

                    systemStatusCard

                    creditsBadge
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showLogs = true } label: {
                        Image(systemName: "apple.terminal")
                            .foregroundStyle(activeTheme.primaryColor)
                    }
                    .accessibilityLabel(language.text("accessibility.open_logs"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(activeTheme.primaryColor)
                    }
                    .accessibilityLabel(language.text("accessibility.open_settings"))
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
            .sheet(item: $store.passwordRequest, onDismiss: store.cancelUnlock) { _ in
                PatchUnlockView(store: store)
            }
            .onAppear {
                store.reload()
                if !hasShownWelcome {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showWelcomeDialog = true
                        }
                    }
                }
            }
            .overlay {
                if showWelcomeDialog {
                    welcomeDialogOverlay
                }
            }
            .overlay(alignment: .bottom) {
                if modManager.showToast, let toastMessage = modManager.toastMessage {
                    toastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Hero Header
    private var heroHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [activeTheme.primaryColor.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 55
                        )
                    )
                    .frame(width: 100, height: 100)

                AppLogo(size: 72)
            }

            VStack(spacing: 4) {
                Text("OniAkuma")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.85, green: 0.95, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: activeTheme.primaryColor.opacity(0.5), radius: 8, x: 0, y: 2)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("HoangHaMod & TrongKien")
                        .font(.caption2.weight(.bold).monospaced())
                }
                .foregroundStyle(activeTheme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(activeTheme.primaryColor.opacity(0.12))
                        .overlay(Capsule().stroke(activeTheme.primaryColor.opacity(0.3), lineWidth: 1))
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Game Selector Card
    private var gameSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("BẢN GAME ĐÍCH")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(activeTheme.primaryColor)
            } icon: {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(activeTheme.primaryColor)
            }

            HStack(spacing: 12) {
                gameOptionButton(
                    title: "Free Fire Thường",
                    bundleID: "com.dts.freefireth",
                    icon: "flame.fill"
                )

                gameOptionButton(
                    title: "Free Fire MAX",
                    bundleID: "com.dts.freefiremax",
                    icon: "bolt.fill"
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func gameOptionButton(title: String, bundleID: String, icon: String) -> some View {
        let isSelected = modManager.selectedBundle == bundleID
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                modManager.selectedBundle = bundleID
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? activeTheme.primaryColor : .secondary)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? activeTheme.primaryColor : .secondary.opacity(0.4))
                }

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text(bundleID)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? activeTheme.primaryColor.opacity(0.8) : .secondary.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? activeTheme.primaryColor.opacity(0.12) : AppTheme.cardBackgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? activeTheme.primaryColor : AppTheme.borderSubtle,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!modManager.processingAimMods.isEmpty)
    }

    // MARK: - Individual Feature Toggle Card
    @ViewBuilder
    private func featureToggleCard(
        title: String,
        subtitle: String,
        filename: String,
        icon: String,
        isEnabled: Bool,
        isProcessing: Bool,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                isEnabled
                                    ? accentColor.opacity(0.2)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                isEnabled
                                    ? LinearGradient(colors: [accentColor, .white], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.secondary, .secondary.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(isEnabled ? accentColor : .white)

                            Circle()
                                .fill(isEnabled ? Color.green : Color.red.opacity(0.8))
                                .frame(width: 7, height: 7)

                            Text(isEnabled ? "BẬT" : "TẮT")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(isEnabled ? Color.green : .secondary)
                        }

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("File: \(filename)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(isEnabled ? accentColor.opacity(0.8) : .secondary.opacity(0.6))
                    }

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .tint(accentColor)
                            .scaleEffect(1.1)
                    } else {
                        ZStack(alignment: isEnabled ? .trailing : .leading) {
                            Capsule()
                                .fill(isEnabled ? accentColor : Color.white.opacity(0.16))
                                .frame(width: 50, height: 28)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 22, height: 22)
                                .padding(3)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isEnabled)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isEnabled ? accentColor.opacity(0.5) : AppTheme.borderSubtle,
                            lineWidth: isEnabled ? 1.5 : 1
                        )
                )
                .shadow(
                    color: isEnabled ? accentColor.opacity(0.15) : Color.clear,
                    radius: 10,
                    y: 3
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    // MARK: - Open Game Button
    private var openGameButton: some View {
        Button {
            openTargetGame()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrowtriangle.right.circle.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("MỞ GAME NGAY (\(modManager.gameShortName))")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)

                    Text("Khởi chạy nhanh \(modManager.selectedBundle)")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [
                        activeTheme.primaryColor,
                        activeTheme.primaryColor.opacity(0.75)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: activeTheme.primaryColor.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("THÔNG TIN HỆ THỐNG")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(activeTheme.primaryColor)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(activeTheme.primaryColor)
            }

            VStack(spacing: 8) {
                statusRow(
                    label: "Target Bundle",
                    value: modManager.selectedBundle,
                    icon: "app.badge.checkmark",
                    color: .white
                )

                statusRow(
                    label: "Thiết Bị / iOS",
                    value: "\(AppInfo.displayMachineName) (iOS \(AppInfo.osVersion))",
                    icon: "iphone",
                    color: .secondary
                )

                statusRow(
                    label: "Khai Thác Lỗ Hổng",
                    value: "Exploit Kernel By 3105",
                    icon: "shield.lefthalf.filled",
                    color: appState.isSupported ? .green : activeTheme.primaryColor
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func statusRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(activeTheme.primaryColor)
                .frame(width: 18)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold).monospaced())
                .foregroundStyle(color)
                .lineLimit(1)
        }
    }

    // MARK: - Credits Badge
    private var creditsBadge: some View {
        VStack(spacing: 4) {
            Text("Phát triển & Tùy biến bởi HoangHaMod & TrongKien")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Exploit Kernel By 3105 • OniAkuma v1.1.1")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Open Target Game via URL Scheme
    private func openTargetGame() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        var candidateURLs: [URL] = []
        if modManager.selectedBundle == "com.dts.freefiremax" {
            if let u = URL(string: "freefiremax://") { candidateURLs.append(u) }
        } else {
            if let u1 = URL(string: "freefireth://") { candidateURLs.append(u1) }
            if let u2 = URL(string: "freefire://") { candidateURLs.append(u2) }
        }

        var didOpen = false
        for candidate in candidateURLs {
            if UIApplication.shared.canOpenURL(candidate) {
                UIApplication.shared.open(candidate, options: [:]) { success in
                    if !success {
                        modManager.triggerToast("Chưa cài đặt \(modManager.gameShortName) trên thiết bị!")
                    }
                }
                didOpen = true
                break
            }
        }

        if !didOpen {
            if let first = candidateURLs.first {
                UIApplication.shared.open(first, options: [:]) { success in
                    if !success {
                        modManager.triggerToast("Chưa cài đặt \(modManager.gameShortName) trên máy! Vui lòng tải game trước.")
                    }
                }
            } else {
                modManager.triggerToast("Chưa cài đặt \(modManager.gameShortName) trên thiết bị!")
            }
        }
    }

    // MARK: - Welcome Dialog
    private var welcomeDialogOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 20) {
                AppLogo(size: 76)

                VStack(spacing: 8) {
                    Text("OniAkuma Mod")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, activeTheme.primaryColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Chúc mọi người chơi game vui vẻ!")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Bản mod Free Fire cao cấp được phát triển và tối ưu bởi HoangHaMod & TrongKien.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    hasShownWelcome = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showWelcomeDialog = false
                    }
                } label: {
                    Text("Bắt Đầu Ngay")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [activeTheme.primaryColor, activeTheme.primaryColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: activeTheme.primaryColor.opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 24, y: 12)
            )
            .padding(.horizontal, 32)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
    }

    private func toastView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(activeTheme.primaryColor)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                .overlay(Capsule().stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
        )
    }
}
