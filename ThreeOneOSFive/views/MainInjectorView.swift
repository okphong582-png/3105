import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Main Injector View (Thiết Kế Cyber Tactical Độc Quyền - Tập Trung 100% Tab Yabao)
struct MainInjectorView: View {
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
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        hasSelectedGame = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 2. MÀN HÌNH ĐIỀU KHIỂN CHÍNH (DUY NHẤT TAB YABAO CHEAT)
                mainDashboardContent
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear {
            store.reload()
            // Kích hoạt nạp container và danh sách ứng dụng nền tức thì
            ZArchiverAppService.shared.loadApps()
            DispatchQueue.global(qos: .userInitiated).async {
                ContainerStore.warmupAndActivateGameContainer(bundleID: yabao.selectedGame)
            }
            if !nextDNSService.isSetupCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showNextDNSSetup = true
                }
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
                // Dark Obsidian Background with Ambient Glows
                Color(red: 0.03, green: 0.04, blue: 0.07).ignoresSafeArea()

                // Ambient Radial Lights
                VStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(x: -80, y: -100)

                    Spacer()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(x: 80, y: 100)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showLogs) { LogView() }
            .sheet(isPresented: $showPatchProjects) {
                PatchProjectsView()
            }
            .sheet(isPresented: $showAppDataBrowser) {
                AppDataBrowserView(tabSession: $tabSession)
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
        HStack {
            // Nút Back < để quay về màn hình chọn 2 Logo bất kỳ lúc nào
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    hasSelectedGame = false
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .black))
                    Text("ĐỔI GAME")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            Spacer()

            // Brand Title & Status
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.exploitStatus.isSuccess ? Color.green : (appState.kernelExploitRunning ? Color.yellow : Color.orange))
                    .frame(width: 7, height: 7)
                    .shadow(color: appState.exploitStatus.isSuccess ? Color.green : Color.orange, radius: 4)

                Text(yabao.selectedGame == "com.dts.freefiremax" ? "FREE FIRE MAX" : "FREE FIRE")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(1.5)
            }

            Spacer()

            // Quick Tool Buttons: [Gói Mod] [Duyệt File Container / Dán Tệp] [Cài đặt]
            HStack(spacing: 7) {
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    showPatchProjects = true
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.cyan)
                        .frame(width: 32, height: 32)
                        .background(Color.cyan.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                }

                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    // Tải trước ngay lập tức danh sách ứng dụng để mở ra là có sẵn không delay
                    ZArchiverAppService.shared.loadApps()
                    showAppDataBrowser = true
                } label: {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.green)
                        .frame(width: 32, height: 32)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1))
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Selected Game Header Card (Tactical Cyber Display với Logo OB Mới)
    private var selectedGameHeaderCard: some View {
        let isMax = yabao.selectedGame == "com.dts.freefiremax"
        let accentColor = isMax ? Color.cyan : Color.orange

        return HStack(spacing: 14) {
            // Square App Logo Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 58, height: 58)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(accentColor.opacity(0.35), lineWidth: 1))

                GameAppIconBadge(isMax: isMax, size: 52)
            }

            // Game Details
            VStack(alignment: .leading, spacing: 3) {
                Text(isMax ? "Free Fire MAX" : "Free Fire")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(yabao.selectedGame)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(yabao.isOnline ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: yabao.isOnline ? Color.green : Color.orange, radius: 3)
                    Text(yabao.isOnline ? "HỆ THỐNG ONLINE • ĐÃ TIÊM" : "SẴN SÀNG TIÊM HỆ THỐNG")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(yabao.isOnline ? Color.green : Color.orange)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Switch game shortcut icon
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    hasSelectedGame = false
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                    .padding(9)
                    .background(accentColor.opacity(0.12).cornerRadius(10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                                        ? [Color.green.opacity(0.3), Color.cyan.opacity(0.15)]
                                        : [Color.orange.opacity(0.3), Color.red.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)

                        Image(systemName: nextDNSService.isSetupCompleted ? "checkmark.shield.fill" : "shield.slash.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(nextDNSService.isSetupCompleted ? Color.green : Color.orange)
                            .shadow(color: (nextDNSService.isSetupCompleted ? Color.green : Color.orange).opacity(0.6), radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("ANTIBAN NEXTDNS VIP")
                                .font(.system(size: 11.5, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)

                            Text(nextDNSService.isSetupCompleted ? "HOẠT ĐỘNG" : "CHƯA CÀI")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(nextDNSService.isSetupCompleted ? Color.green : Color.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill((nextDNSService.isSetupCompleted ? Color.green : Color.orange).opacity(0.15)))
                                .overlay(Capsule().stroke((nextDNSService.isSetupCompleted ? Color.green : Color.orange).opacity(0.4), lineWidth: 0.8))
                        }

                        Text(nextDNSService.isSetupCompleted ? "Bảo vệ rank 100% • Chặn máy chủ quét Blackbox" : "Nhấn để cài cấu hình DNS chống khoá tài khoản")
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
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    nextDNSService.isSetupCompleted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Open Game Button (Tactical Cyber Launch Station)
    private var openGameButton: some View {
        Button {
            openGame()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .black))

                Text("KHỞI ĐỘNG VÀO GAME")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .tracking(1.5)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [
                        Color.cyan,
                        Color.blue,
                        Color.purple
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.cyan.opacity(0.4), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
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
            modManager.triggerToast("Đã tiêm tính năng xong! Hãy mở game \(targetName) để trải nghiệm.")
        }
    }

    // MARK: - Toast Message
    @ViewBuilder
    private func toastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(red: 0.1, green: 0.12, blue: 0.16))
                .shadow(color: .black.opacity(0.6), radius: 10, y: 4)
        )
        .overlay(Capsule().stroke(Color.green.opacity(0.5), lineWidth: 1.2))
    }
}
