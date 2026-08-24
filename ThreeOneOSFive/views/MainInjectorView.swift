import SwiftUI
import UIKit

struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()

    @AppStorage("selectedGameBundle") private var selectedBundle = "com.dts.freefireth"
    @AppStorage("oni_akuma_aim_enabled") private var isAimEnabled = false
    @AppStorage("oni_akuma_holo_enabled") private var isHoloEnabled = false

    @State private var isProcessingAim = false
    @State private var isProcessingHolo = false
    @State private var processingMessage = ""
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    @State private var showSettings = false
    @State private var showLogs = false

    // Look for specific projects in the library
    private var aimProject: PatchProject? {
        store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("Aim") })?.project
            ?? store.items.first?.project
    }

    private var holoProject: PatchProject? {
        store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("HOLO") })?.project
            ?? store.items.last?.project
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroHeader

                    gameSelectorCard

                    // Feature Toggles Section
                    VStack(spacing: 14) {
                        featureToggleCard(
                            title: "AIM BODY",
                            subtitle: "Tự động ghim tâm vào thân đối thủ",
                            filename: "Aim Body.3105",
                            icon: "scope",
                            isEnabled: isAimEnabled,
                            isProcessing: isProcessingAim,
                            accentColor: AppTheme.accent
                        ) {
                            handleToggleAim()
                        }

                        featureToggleCard(
                            title: "ĐỊNH VỊ (HOLO)",
                            subtitle: "Định vị vị trí và phát hiện kẻ địch (ESP Holo)",
                            filename: "HOLO.3105",
                            icon: "viewfinder.circle.fill",
                            isEnabled: isHoloEnabled,
                            isProcessing: isProcessingHolo,
                            accentColor: AppTheme.goldAccent
                        ) {
                            handleToggleHolo()
                        }
                    }

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
                            .foregroundStyle(AppTheme.accent)
                    }
                    .accessibilityLabel(language.text("accessibility.open_logs"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                    .accessibilityLabel(language.text("accessibility.open_settings"))
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
            .onAppear {
                store.reload()
            }
            .overlay(alignment: .bottom) {
                if showToast, let toastMessage {
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
                            colors: [AppTheme.accent.opacity(0.35), Color.clear],
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
                            colors: [.white, Color(red: 0.8, green: 0.95, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AppTheme.accent.opacity(0.5), radius: 8, x: 0, y: 2)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("3105 x HoangHaMod,TrongKien")
                        .font(.caption2.weight(.bold).monospaced())
                }
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppTheme.accent.opacity(0.12))
                        .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
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
                    .foregroundStyle(AppTheme.accent)
            } icon: {
                Image(systemName: "gamecontroller.fill")
                    .foregroundStyle(AppTheme.accent)
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
        let isSelected = selectedBundle == bundleID
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedBundle = bundleID
            }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .secondary)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .secondary.opacity(0.4))
                }

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text(bundleID)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(isSelected ? AppTheme.accent.opacity(0.8) : .secondary.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.cardBackgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? AppTheme.accent : AppTheme.borderSubtle,
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isProcessingAim || isProcessingHolo)
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
                        // Animated Custom Toggle Switch
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

    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("THÔNG TIN HỆ THỐNG")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 8) {
                statusRow(
                    label: "Target Bundle",
                    value: selectedBundle,
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
                    label: "Trạng Thái Khai Thác",
                    value: appState.isSupported ? "Đã Kích Hoạt" : "Sẵn Sàng",
                    icon: "shield.lefthalf.filled",
                    color: appState.isSupported ? .green : AppTheme.goldAccent
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
                .foregroundStyle(AppTheme.accent)
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

            Text("OniAkuma v1.1.1 (Build 7)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var gameShortName: String {
        selectedBundle == "com.dts.freefiremax" ? "FF MAX" : "Free Fire"
    }

    // MARK: - Toggle Actions
    private func handleToggleAim() {
        if isAimEnabled {
            restoreFeature(featureName: "Aim Body", isAim: true)
        } else {
            injectFeature(project: aimProject, featureName: "Aim Body", isAim: true)
        }
    }

    private func handleToggleHolo() {
        if isHoloEnabled {
            restoreFeature(featureName: "Định Vị Holo", isAim: false)
        } else {
            injectFeature(project: holoProject, featureName: "Định Vị Holo", isAim: false)
        }
    }

    private func injectFeature(project: PatchProject?, featureName: String, isAim: Bool) {
        guard let proj = project else {
            triggerToast("Không tìm thấy file \(featureName)!")
            return
        }

        if isAim {
            isProcessingAim = true
        } else {
            isProcessingHolo = true
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let bundleID = selectedBundle
        let targetName = gameShortName

        Task.detached(priority: .userInitiated) {
            var adaptedProject = proj
            for i in 0..<adaptedProject.rules.count {
                adaptedProject.rules[i].bundleID = bundleID
            }

            do {
                _ = try DevicePatchService.apply(project: adaptedProject)
                await MainActor.run {
                    if isAim {
                        self.isProcessingAim = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            self.isAimEnabled = true
                        }
                    } else {
                        self.isProcessingHolo = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            self.isHoloEnabled = true
                        }
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    self.triggerToast("Đã bật \(featureName) trên \(targetName)!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    if isAim { self.isProcessingAim = false } else { self.isProcessingHolo = false }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    self.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    if isAim { self.isProcessingAim = false } else { self.isProcessingHolo = false }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    self.triggerToast("Lỗi khi bật \(featureName): \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreFeature(featureName: String, isAim: Bool) {
        if isAim {
            isProcessingAim = true
        } else {
            isProcessingHolo = true
        }

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let targetProj = isAim ? aimProject : holoProject
        let receipt = targetProj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        Task.detached(priority: .userInitiated) {
            if let receipt {
                do {
                    try DevicePatchService.restore(receipt: receipt)
                } catch {
                    log("restore error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                if isAim {
                    self.isProcessingAim = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        self.isAimEnabled = false
                    }
                } else {
                    self.isProcessingHolo = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        self.isHoloEnabled = false
                    }
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                self.triggerToast("Đã tắt \(featureName)!")
            }
        }
    }

    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
    }

    private func toastView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppTheme.accent)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                .overlay(Capsule().stroke(AppTheme.accent.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
        )
    }
}
