import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Main dashboard
struct MainInjectorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: PatchProjectStore
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared
    @ObservedObject private var yabao = YabaoCheatManager.shared

    @ObservedObject private var nextDNSService = NextDNSInstallerService.shared
    @State private var showNextDNSSetup = false

    // Trạng thái chọn Game (Sau khi qua màn hình chọn 2 logo -> Vào thẳng bảng điều khiển)
    @State private var hasSelectedGame = false
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showPatchProjects = false
    @State private var showAppDataBrowser = false
    @State private var showFileImporter = false
    @State private var tabSession = FilesTabSession()

    var body: some View {
        Group {
            if !hasSelectedGame {
                // 1. MÀN HÌNH CHỌN 2 LOGO OB MỚI (FF THƯỜNG & FF MAX)
                GameSelectionView { chosenBundle in
                    yabao.selectedGame = chosenBundle
                    modManager.selectedBundle = chosenBundle
                    yabao.checkInjectionState()
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        hasSelectedGame = true
                    }
                }
                .transition(.opacity)
            } else {
                // 2. MÀN HÌNH ĐIỀU KHIỂN CHÍNH (DUY NHẤT TAB YABAO CHEAT)
                mainDashboardContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            store.reload()
            // Kích hoạt nạp container và danh sách ứng dụng nền tức thì
            ZArchiverAppService.shared.loadApps()
            DispatchQueue.global(qos: .userInitiated).async {
                ContainerStore.warmupAndActivateGameContainer(bundleID: yabao.selectedGame)
            }

        }
        .sheet(isPresented: $showNextDNSSetup) {
            NextDNSSetupSheet()
        }
    }

    // MARK: - Main Dashboard Content
    private var mainDashboardContent: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header Bar: Back button < | Title | Quick Tool Buttons
                        topNavBar

                        // Selected Game Info Card (Icon OB Mới + Free Fire / com.dts.freefireth)
                        selectedGameHeaderCard

                        // Antiban NextDNS Status & Setup Banner
                        nextDNSAntibanBanner

                        // BẢNG ĐIỀU KHIỂN YABAO CHEAT DUY NHẤT
                        YabaoCheatTabView()

                        // Bottom Big Action Button: ▶ OPEN GAME
                        openGameButton

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) { SettingsView().saturation(0) }
            .sheet(isPresented: $showLogs) { LogView().saturation(0) }
            .sheet(isPresented: $showPatchProjects) {
                PatchProjectsView().saturation(0)
            }
            .sheet(isPresented: $showAppDataBrowser) {
                AppDataBrowserView(tabSession: $tabSession).saturation(0)
            }
            .sheet(isPresented: $showFileImporter) {
                FileDocumentPicker(
                    allowedContentTypes: [UTType(filenameExtension: "3105") ?? .data, .data],
                    copiesSelectedDocument: true,
                    allowsMultipleSelection: false,
                    onSelection: { result in
                        showFileImporter = false
                        if case .success(let urls) = result, let url = urls.first {
                            store.importPackage(at: url)
                            modManager.triggerToast("Đã nạp gói mod: \(url.lastPathComponent)!")
                        }
                    },
                    onCancel: {
                        showFileImporter = false
                    }
                )
            }
            .overlay(alignment: .top) {
                if let toast = modManager.toastMessage {
                    toastView(message: toast)
                        .padding(.top, 50)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Top Navigation Bar
    private var topNavBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { hasSelectedGame = false }
            } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Đổi game")
            Text("Bảng điều khiển")
                .font(.system(size: 18, weight: .semibold)).tracking(-0.5)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Menu {
                Button { showPatchProjects = true } label: { Label("Gói mod", systemImage: "folder") }
                Button {
                    ZArchiverAppService.shared.loadApps()
                    showAppDataBrowser = true
                } label: { Label("Duyệt tệp", systemImage: "internaldrive") }
                Button { showSettings = true } label: { Label("Cài đặt", systemImage: "gearshape") }
            } label: {
                Image(systemName: "ellipsis").frame(width: 44, height: 44)
                    .background(AppTheme.cardBackground, in: Circle())
            }
            .accessibilityLabel("Công cụ và cài đặt")
        }
        .foregroundStyle(.white)
    }
    // MARK: - Selected Game Header Card (Tactical Cyber Display với Logo OB Mới)
    private var selectedGameHeaderCard: some View {
        let isMax = yabao.selectedGame == "com.dts.freefiremax"
        let accentColor = Color.white

        return HStack(spacing: 14) {
            // Square App Logo Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 58, height: 58)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentColor.opacity(0.4), lineWidth: 1))

                GameAppIconBadge(isMax: isMax, size: 52)
            }

            // Game Details
            VStack(alignment: .leading, spacing: 3) {
                Text(isMax ? "Free Fire MAX" : "Free Fire")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(.white)

                Text(isMax ? "MAX EDITION" : "ORIGINAL EDITION")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(yabao.isOnline ? Color.white : AppTheme.textSecondary)
                        .frame(width: 6, height: 6)
                        .shadow(color: yabao.isOnline ? Color.white : AppTheme.textSecondary, radius: 3)
                    Text(yabao.isOnline ? "Đã bật tính năng" : "Chưa bật tính năng")
                        .font(.system(size: 9, weight: .medium, design: .default))
                        .foregroundStyle(yabao.isOnline ? Color.white : AppTheme.textSecondary)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Switch game shortcut icon
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    hasSelectedGame = false
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                    .padding(9)
                    .background(accentColor.opacity(0.15).cornerRadius(10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.35), lineWidth: 1))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.4), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - NextDNS Antiban VIP Quick Banner (Realtime Status & Toggle)
    private var nextDNSAntibanBanner: some View {
        HStack(spacing: 12) {
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                showNextDNSSetup = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: nextDNSService.isSetupCompleted
                                        ? [Color.white.opacity(0.3), Color.white.opacity(0.15)]
                                        : [Color.white.opacity(0.3), Color.white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: nextDNSService.isSetupCompleted ? "checkmark.shield.fill" : "shield.slash.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(nextDNSService.isSetupCompleted ? Color.white : AppTheme.textSecondary)
                            .shadow(color: (nextDNSService.isSetupCompleted ? Color.white : AppTheme.textSecondary).opacity(0.6), radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("CẤU HÌNH DNS")
                                .font(.system(size: 11.5, weight: .medium, design: .default))
                                .foregroundStyle(.white)

                            Text(nextDNSService.isSetupCompleted ? "HOẠT ĐỘNG" : "CHƯA CÀI")
                                .font(.system(size: 8, weight: .medium, design: .default))
                                .foregroundStyle(nextDNSService.isSetupCompleted ? Color.white : AppTheme.textSecondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill((nextDNSService.isSetupCompleted ? Color.white : AppTheme.textSecondary).opacity(0.15)))
                                .overlay(Capsule().stroke((nextDNSService.isSetupCompleted ? Color.white : AppTheme.textSecondary).opacity(0.4), lineWidth: 0.8))
                        }

                        Text(nextDNSService.isSetupCompleted ? "Đã cài cấu hình DNS" : "Nhấn để xem hướng dẫn cài đặt")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    nextDNSService.isSetupCompleted ? Color.white.opacity(0.3) : Color.white.opacity(0.3),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Open Game Button (Tactical Cyber Launch Station)
    private var openGameButton: some View {
        Button { openGame() } label: {
            HStack(spacing: 10) {
                Text("Mở game").font(.system(size: 15, weight: .semibold))
                Image(systemName: "arrow.up.right")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.25)))
        }
        .buttonStyle(CardScaleButtonStyle())
        .padding(.top, 4)
    }
    // MARK: - Open Game Action
    private func openGame() {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.impactOccurred()

        let isMax = yabao.selectedGame == "com.dts.freefiremax"
        let scheme = isMax ? "freefiremax://" : "freefire://"

        if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let targetName = isMax ? "Free Fire MAX" : "Free Fire"
            modManager.triggerToast("Đã kích hoạt tính năng thành công! Hãy mở game \(targetName) để trải nghiệm.")
        }
    }

    // MARK: - Toast Message
    @ViewBuilder
    private func toastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.white)
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(AppTheme.cardBackground)
                .shadow(color: .black.opacity(0.6), radius: 10, y: 4)
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 1.2))
    }
}
