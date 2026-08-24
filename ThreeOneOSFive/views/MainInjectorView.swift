import SwiftUI
import UIKit

struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()

    @AppStorage("selectedGameBundle") private var selectedBundle = "com.dts.freefireth"
    @State private var isInjected = false
    @State private var isProcessing = false
    @State private var processingMessage = ""
    @State private var toastMessage: String? = nil
    @State private var showToast = false
    @State private var showSettings = false
    @State private var showLogs = false

    private var activeProject: PatchProject? {
        store.items.first(where: { !$0.isLocked })?.project ?? store.items.first?.project
    }

    private var activeItem: PatchLibraryItem? {
        store.items.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroHeader

                    gameSelectorCard

                    mainToggleCard

                    systemStatusCard

                    creditsBadge
                }
                .padding(.horizontal, AppTheme.pageInset)
                .padding(.top, 10)
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
            .onAppear(perform: checkCurrentState)
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
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accent.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 110, height: 110)

                AppLogo(size: 76)
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
        .padding(.vertical, 8)
    }

    // MARK: - Game Selector Card
    private var gameSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .padding(16)
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .secondary)

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .bold))
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
        .disabled(isProcessing)
    }

    // MARK: - Main Toggle Card
    private var mainToggleCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isInjected
                                ? Color.green.opacity(0.2)
                                : Color.white.opacity(0.06)
                        )
                        .frame(width: 54, height: 54)

                    Image(systemName: isInjected ? "bolt.shield.fill" : "shield.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(
                            isInjected
                                ? LinearGradient(colors: [Color.green, AppTheme.accent], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.secondary, .secondary.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isInjected ? "ĐÃ TIÊM FILE" : "FILE GỐC")
                        .font(.title3.weight(.black))
                        .foregroundStyle(isInjected ? Color.green : Color.white)

                    Text(isInjected ? "Đang áp dụng Aim Body cho \(gameShortName)" : "Chưa kích hoạt bản vá")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isProcessing {
                    ProgressView()
                        .tint(AppTheme.accent)
                        .scaleEffect(1.2)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isInjected },
                        set: { _ in handleToggleAction() }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
                    .scaleEffect(1.15)
                }
            }

            Divider()
                .background(AppTheme.borderSubtle)

            Button(action: handleToggleAction) {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                            .tint(.black)
                            .controlSize(.small)
                        Text(processingMessage)
                            .font(.headline.weight(.bold))
                    } else {
                        Image(systemName: isInjected ? "arrow.uturn.backward.circle.fill" : "syringe.fill")
                            .font(.headline.weight(.bold))
                        Text(isInjected ? "Khôi Phục Game Gốc" : "Bật Tiêm File Ngay")
                            .font(.headline.weight(.bold))
                    }
                }
                .foregroundStyle(isProcessing ? .white : (isInjected ? .white : .black))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isInjected
                                ? LinearGradient(colors: [Color.red.opacity(0.85), Color.red], startPoint: .top, endPoint: .bottom)
                                : AppTheme.accentGradient
                        )
                )
                .shadow(
                    color: (isInjected ? Color.red : AppTheme.accent).opacity(0.35),
                    radius: 10,
                    x: 0,
                    y: 4
                )
            }
            .disabled(isProcessing)
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            isInjected ? Color.green.opacity(0.4) : AppTheme.borderSubtle,
                            lineWidth: 1.2
                        )
                )
        )
    }

    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("THÔNG TIN HỆ THỐNG")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 10) {
                statusRow(
                    label: "Bản Vá Mặc Định",
                    value: "Aim Body.3105",
                    icon: "doc.zipper",
                    color: AppTheme.accent
                )

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
        .padding(16)
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
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 20)

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
        VStack(spacing: 6) {
            Text("Phát triển & Tùy biến bởi HoangHaMod & TrongKien")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text("OniAkuma v1.1.1 (Build 7)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var gameShortName: String {
        selectedBundle == "com.dts.freefiremax" ? "FF MAX" : "Free Fire"
    }

    // MARK: - Actions
    private func checkCurrentState() {
        store.reload()
        if let project = activeProject {
            isInjected = DevicePatchService.latestReceipt(projectID: project.id) != nil
        }
    }

    private func handleToggleAction() {
        if isInjected {
            restoreOriginals()
        } else {
            injectPatch()
        }
    }

    private func injectPatch() {
        guard let project = activeProject else {
            triggerToast("Không tìm thấy file Aim Body.3105!")
            return
        }

        isProcessing = true
        processingMessage = "Đang tiêm file..."
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task.detached(priority: .userInitiated) {
            var adaptedProject = project
            for i in 0..<adaptedProject.rules.count {
                adaptedProject.rules[i].bundleID = selectedBundle
            }

            do {
                _ = try DevicePatchService.apply(project: adaptedProject)
                await MainActor.run {
                    self.isProcessing = false
                    self.isInjected = true
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    self.triggerToast("Đã tiêm Aim Body vào \(gameShortName) thành công!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    self.isProcessing = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    self.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    self.triggerToast("Lỗi khi tiêm file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreOriginals() {
        guard let project = activeProject,
              let receipt = DevicePatchService.latestReceipt(projectID: project.id) else {
            isInjected = false
            triggerToast("Đã ở trạng thái file gốc!")
            return
        }

        isProcessing = true
        processingMessage = "Đang khôi phục..."
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        Task.detached(priority: .userInitiated) {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    self.isProcessing = false
                    self.isInjected = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    self.triggerToast("Đã khôi phục game gốc thành công!")
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    self.triggerToast("Lỗi khi khôi phục: \(error.localizedDescription)")
                }
            }
        }
    }

    private func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
