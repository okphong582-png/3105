import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Animated Radar Scanner HUD Component
struct CyberRadarHUDView: View {
    @State private var rotationAngle: Double = 0
    @State private var blipPulse: Bool = false

    var body: some View {
        ZStack {
            // Radar Background Circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.05, green: 0.18, blue: 0.12), Color(red: 0.02, green: 0.06, blue: 0.04)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 170, height: 170)

            // Concentric Range Rings
            Circle()
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                .frame(width: 50, height: 50)
            Circle()
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                .frame(width: 100, height: 100)
            Circle()
                .stroke(Color.green.opacity(0.4), lineWidth: 1.2)
                .frame(width: 150, height: 150)

            // Crosshair Grids
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 150, height: 1)
            Rectangle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 1, height: 150)

            // Target Blips (Chấm Trắng Định Vị)
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .shadow(color: .white, radius: 4)
                .offset(x: 35, y: -25)
                .scaleEffect(blipPulse ? 1.3 : 0.8)

            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .shadow(color: .white, radius: 4)
                .offset(x: -40, y: 30)
                .scaleEffect(blipPulse ? 1.4 : 0.7)

            Circle()
                .fill(Color.white)
                .frame(width: 7, height: 7)
                .shadow(color: .white, radius: 5)
                .offset(x: -20, y: -45)
                .scaleEffect(blipPulse ? 1.2 : 0.9)

            // Rotating Sweep Beam
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.green.opacity(0.0),
                            Color.green.opacity(0.5)
                        ]),
                        center: .center
                    )
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(rotationAngle))

            // Center Point
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: Color.green, radius: 6)
        }
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.cyan.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.green.opacity(0.35), radius: 14)
        .onAppear {
            withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                blipPulse = true
            }
        }
    }
}

// MARK: - Cyberpunk ESP Xuyên Tường HUD View (Hih.3105 Simulation)
struct CyberESPHUDView: View {
    @ObservedObject private var modManager = ModFeatureManager.shared
    @State private var scanPulse = false
    @State private var targetFlicker = false

    var body: some View {
        ZStack {
            // Tactical Dark Glass Container
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.06, blue: 0.10),
                            Color(red: 0.02, green: 0.03, blue: 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 175)

            // Grid Scan Background
            VStack(spacing: 22) {
                ForEach(0..<6) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.03))
                        .frame(height: 1)
                }
            }
            .frame(height: 155)

            HStack(spacing: 38) {
                ForEach(0..<8) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 1)
                }
            }
            .frame(height: 155)

            // Dynamic Scanning Light Sweep
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            (modManager.isESPEnabled ? Color(red: 1.0, green: 0.2, blue: 0.4) : Color.white).opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 36)
                .offset(y: scanPulse ? 55 : -55)

            // Simulated Enemy ESP Box with Tactical Indicators
            VStack(spacing: 4) {
                // Overhead Enemy Information Tag (Tên & Khoảng cách)
                HStack(spacing: 5) {
                    Circle()
                        .fill(modManager.isESPEnabled ? Color.red : Color.gray)
                        .frame(width: 6, height: 6)
                        .scaleEffect(targetFlicker ? 1.3 : 0.8)

                    Text(modManager.isESPEnabled ? "🔴 [ĐỊCH] 48.2m • SÚNG: M1887" : "○ QUÉT MỤC TIÊU...")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(modManager.isESPEnabled ? Color.red : Color.secondary)

                    // HP Bar
                    if modManager.isESPEnabled {
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2)).frame(width: 34, height: 5)
                            Capsule().fill(Color.green).frame(width: 26, height: 5)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(modManager.isESPEnabled ? Color.red.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 0.8)
                        )
                )

                // 2D Corner Hitbox Frame
                ZStack {
                    // Box interior glow
                    RoundedRectangle(cornerRadius: 8)
                        .fill((modManager.isESPEnabled ? Color.red : Color.cyan).opacity(modManager.isESPEnabled ? 0.08 : 0.03))
                        .frame(width: 88, height: 70)

                    // Corner brackets (ESP Box Corner)
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            modManager.isESPEnabled
                                ? LinearGradient(colors: [Color.red, Color(red: 1.0, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                        .frame(width: 88, height: 70)

                    // Center Crosshair / Bone Head Node
                    Circle()
                        .fill(modManager.isESPEnabled ? Color.yellow : Color.white.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .offset(y: -14)

                    // Skeleton line indicator
                    Rectangle()
                        .fill((modManager.isESPEnabled ? Color.yellow : Color.white.opacity(0.2)).opacity(0.7))
                        .frame(width: 1.5, height: 24)
                        .offset(y: 2)
                }

                // Laser Tracer Line to Bottom (ESP Line Tracer)
                if modManager.isESPEnabled {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.yellow.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5, height: 32)
                }
            }
            .offset(y: -4)

            // Top-left and bottom-right HUD telemetry readouts
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ESP ENGINE: ONIAKUMA VIP")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.red)
                        Text(modManager.isESPEnabled ? "STATUS: ACTIVE • WALLHACK ON" : "STATUS: STANDBY")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(modManager.isESPEnabled ? Color.green : Color.secondary)
                    }
                    Spacer()
                    Text(modManager.selectedBundle == "com.dts.freefiremax" ? "MAX_ENGINE" : "TH_ENGINE")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.12).cornerRadius(4))
                }
                Spacer()
                HStack {
                    Text("FOV: 360° • X-RAY: 100%")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(modManager.isESPEnabled ? "48M • LOCKED" : "IDLE")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(modManager.isESPEnabled ? Color.green : Color.secondary)
                }
            }
            .padding(10)
        }
        .frame(height: 175)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(modManager.isESPEnabled ? Color.red.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.2)
                .shadow(color: modManager.isESPEnabled ? Color.red.opacity(0.3) : Color.clear, radius: 8)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scanPulse = true
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                targetFlicker = true
            }
        }
    }
}

// MARK: - Main Injector View (Thiết Kế Độc Quyền - Không Đạo Bất Kỳ App Nào)
struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: PatchProjectStore
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared

    @ObservedObject private var nextDNSService = NextDNSInstallerService.shared
    @State private var showNextDNSSetup = false

    // Game Selection State (Sau khi nhập key -> Hiện 2 Logo chọn Game)
    @State private var hasSelectedGame = false
    @State private var selectedTab: Int = 0 // 0: AIM ASSIST, 1: ĐỊNH VỊ ESP, 2: RADAR CHẤM, 3: GÓI MOD
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showPatchProjects = false
    @State private var showAppDataBrowser = false
    @State private var showFileImporter = false
    @State private var tabSession = FilesTabSession()
    @State private var lastActivatedAimName: String? = nil

    var body: some View {
        Group {
            if !hasSelectedGame {
                // 1. MÀN HÌNH CHỌN 2 LOGO (FF THƯỜNG & MAX - GIAO DIỆN TACTICAL MỚI)
                GameSelectionView { chosenBundle in
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        hasSelectedGame = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 2. MÀN HÌNH CHÍNH (TACTICAL CYBER ENGINE - CHUẨN 2 TAB ĐỘC LẬP)
                mainDashboardContent
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .onAppear {
            store.reload()
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
                        // Top Header Bar: Back button < | Title | VIP Badge
                        topNavBar

                        // Selected Game Info Card (Icon + Free Fire / com.dts.freefireth)
                        selectedGameHeaderCard

                        // Antiban NextDNS Status & Setup Banner
                        nextDNSAntibanBanner

                        // CUSTOM SEGMENTED TAB SELECTOR: [ 🎯 AIM BOT ] [ 👁️ ĐỊNH VỊ ESP ] [ 📡 RADAR ]
                        tacticalTabSelector

                        // TAB CONTENT:
                        if selectedTab == 0 {
                            // TAB 0: AIM BOT (5 CHỨC NĂNG AIM)
                            aimBotCardSection
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        } else if selectedTab == 1 {
                            // TAB 1: ĐỊNH VỊ ESP XUYÊN TƯỜNG
                            espCardSection
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else if selectedTab == 2 {
                            // TAB 2: ĐỊNH VỊ CHẤM TRẮNG (RADAR)
                            locatorCardSection
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        } else {
                            // TAB 3: GÓI MOD TỰ CHỌN (.3105)
                            customModCardSection
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }

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
                    onCancel: { showFileImporter = false }
                )
                .ignoresSafeArea()
            }
            .sheet(item: $store.passwordRequest, onDismiss: store.cancelUnlock) { _ in
                PatchUnlockView(store: store)
            }
            .overlay(alignment: .bottom) {
                if modManager.showToast, let toastMessage = modManager.toastMessage {
                    toastView(message: toastMessage)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 30)
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

            // Brand Title & Exploit Status
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.exploitStatus.isSuccess ? Color.green : (appState.kernelExploitRunning ? Color.yellow : Color.orange))
                    .frame(width: 7, height: 7)
                    .shadow(color: appState.exploitStatus.isSuccess ? Color.green : Color.orange, radius: 4)

                Text(modManager.gameShortName.uppercased())
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

            // Quick Tool Buttons: [Gói Mod] [Duyệt File Container] [Cài đặt]
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

    // MARK: - Selected Game Header Card (Tactical Cyber Display)
    private var selectedGameHeaderCard: some View {
        let isMax = modManager.selectedBundle == "com.dts.freefiremax"
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
                Text(modManager.gameShortName)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(modManager.selectedBundle)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.green, radius: 3)
                    Text("SẴN SÀNG TIÊM HỆ THỐNG")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.green)
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
            // Tappable Area to open Full Live Dashboard
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                showNextDNSSetup = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(nextDNSService.isProtectionActive ? Color.green.opacity(0.16) : Color.red.opacity(0.16))
                            .frame(width: 42, height: 42)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(nextDNSService.isProtectionActive ? Color.green.opacity(0.4) : Color.red.opacity(0.4), lineWidth: 1)
                            )

                        Image(systemName: nextDNSService.isProtectionActive ? "shield.checkered" : "shield.slash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(nextDNSService.isProtectionActive ? Color.green : Color.red)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("NEXTDNS REALTIME")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.white)

                            Text(nextDNSService.isProtectionActive ? "ACTIVE" : "OFF")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(nextDNSService.isProtectionActive ? Color.black : Color.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    (nextDNSService.isProtectionActive ? Color.green : Color.red)
                                        .cornerRadius(4)
                                )
                        }

                        Text(nextDNSService.isProtectionActive
                             ? "Đã chặn \(nextDNSService.blockedQueries) truy vấn • Chạm xem Live Stream"
                             : "Đã tắt bảo vệ • Bật để chống khóa tài khoản")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Inline Master ON/OFF Switch
            Toggle("", isOn: $nextDNSService.isProtectionActive)
                .labelsHidden()
                .tint(Color.green)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            nextDNSService.isProtectionActive ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Tactical 4-Tab Selector: [ 🎯 AIM BOT ] [ 👁️ ĐỊNH VỊ ESP ] [ 📡 RADAR ] [ 📦 GÓI MOD ]
    private var tacticalTabSelector: some View {
        HStack(spacing: 4) {
            // Tab 0: AIM BOT
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 0
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "scope")
                        .font(.system(size: 13, weight: .black))
                    Text("AIM BOT")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(selectedTab == 0 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selectedTab == 0
                                ? LinearGradient(colors: [Color.green, Color(red: 0.2, green: 0.85, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedTab == 0 ? Color.green.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 0 ? Color.green.opacity(0.35) : Color.clear, radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            // Tab 1: ĐỊNH VỊ ESP (File Hih.3105)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 1
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.system(size: 13, weight: .black))
                    Text("ESP X-RAY")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(selectedTab == 1 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selectedTab == 1
                                ? LinearGradient(colors: [Color.red, Color(red: 1.0, green: 0.3, blue: 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedTab == 1 ? Color.red.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 1 ? Color.red.opacity(0.35) : Color.clear, radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            // Tab 2: RADAR CHẤM (Định vị.3105)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 2
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 13, weight: .black))
                    Text("RADAR")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(selectedTab == 2 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selectedTab == 2
                                ? LinearGradient(colors: [Color.cyan, Color(red: 0.1, green: 0.7, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedTab == 2 ? Color.cyan.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 2 ? Color.cyan.opacity(0.35) : Color.clear, radius: 6, y: 2)
            }
            .buttonStyle(.plain)

            // Tab 3: GÓI MOD (File Mod Tự Chọn)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 3
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 13, weight: .black))
                    Text("GÓI MOD")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(selectedTab == 3 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            selectedTab == 3
                                ? LinearGradient(colors: [Color.purple, Color(red: 0.8, green: 0.4, blue: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selectedTab == 3 ? Color.purple.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 3 ? Color.purple.opacity(0.35) : Color.clear, radius: 6, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color(red: 0.06, green: 0.07, blue: 0.10).cornerRadius(16))
    }

    // MARK: - Tab 0: Aim Bot Card Section
    private var aimBotCardSection: some View {
        let visibleAims = AimModType.allCases.filter { licenseManager.isAimVisible($0) }

        return VStack(spacing: 0) {
            // Card Top Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 3, height: 16)

                    Text("BỘ AIM BOT CHÍNH XÁC CAO")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.green)
                        .tracking(1.0)
                }

                Spacer()

                Text("LIVE VIP")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.16))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.green.opacity(0.4), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Features List (Aim Neck, Aim Drag, Aim Body, Aim Chest, Aim Magic)
            if visibleAims.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("Các chế độ Aim Bot đang được Admin tạm ẩn.")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(visibleAims) { aim in
                        let isAllowed = licenseManager.currentLicense?.canUseAimMod(aim) ?? true
                        let isEnabled = isAllowed && modManager.isAimModEnabled(aim)
                        let isProcessing = modManager.isAimModProcessing(aim)

                        aimFeatureRow(
                            aim: aim,
                            isAllowed: isAllowed,
                            isEnabled: isEnabled,
                            isProcessing: isProcessing
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Bottom Status Text inside Card
            if let lastAim = lastActivatedAimName {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .black))
                    Text("Đã kích hoạt: \(lastAim)")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Color.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.08))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                    Text("Sẵn sàng — Bật toggle để kích hoạt Aim Bot")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.secondary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
                .shadow(color: Color.green.opacity(0.25), radius: 8)
        )
    }

    // MARK: - Aim Feature Row (Square colored icon box + Native iOS Toggle)
    @ViewBuilder
    private func aimFeatureRow(
        aim: AimModType,
        isAllowed: Bool,
        isEnabled: Bool,
        isProcessing: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Square Colored Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isAllowed ? aim.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .shadow(color: (isAllowed ? aim.accentColor : Color.clear).opacity(0.4), radius: 5)

                Image(systemName: isAllowed ? aim.icon : "lock.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(aim.shortTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isAllowed ? Color.white : Color.secondary)

                    if !isAllowed {
                        Text("CẦN PRO")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15).cornerRadius(4))
                    }
                }

                Text(isAllowed ? aim.subtitle : "Gói Lite chỉ có Neck, Drag, Body. Nâng cấp PRO VIP!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // NÚT TOGGLE MẶC ĐỊNH CỦA IOS KÈM HIỆU ỨNG LOADING NHANH
            if !isAllowed {
                Button {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.warning)
                    modManager.triggerToast("Tính năng này yêu cầu Key PRO VIP! Gói Lite chỉ có Aim Neck, Drag, Body.")
                } label: {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.orange.opacity(0.7))
                }
            } else {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(Color.green)
                            .scaleEffect(0.85)
                            .transition(.opacity.combined(with: .scale))
                    }

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { isEnabled },
                            set: { newVal in
                                guard !isProcessing else { return }
                                if newVal {
                                    lastActivatedAimName = aim.shortTitle
                                }
                                modManager.toggleAimMod(aim, store: store)
                            }
                        )
                    )
                    .labelsHidden()
                    .tint(Color.green)
                    .disabled(isProcessing)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tab 1: ESP Card Section (Định Vị ESP Xuyên Tường - Hih.3105)
    private var espCardSection: some View {
        VStack(spacing: 16) {
            // Cyberpunk Animated ESP HUD View
            CyberESPHUDView()
                .padding(.top, 6)

            // ESP Master Toggle Card
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red, Color(red: 1.0, green: 0.3, blue: 0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.red.opacity(0.4), radius: 6)

                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("ESP Xuyên Tường")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.white)

                            Text("VIP PRO")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.18).cornerRadius(4))
                        }

                        Text("ESP Xuyên Tường • Tên, Box, Vạch kẻ, Khoảng cách")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Toggle Button with Loading Progress
                    HStack(spacing: 8) {
                        if modManager.isProcessingESP {
                            ProgressView()
                                .tint(Color.red)
                                .scaleEffect(0.85)
                                .transition(.opacity.combined(with: .scale))
                        }

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { modManager.isESPEnabled },
                                set: { _ in
                                    guard !modManager.isProcessingESP else { return }
                                    modManager.toggleESP(store: store)
                                }
                            )
                        )
                        .labelsHidden()
                        .tint(Color.red)
                        .disabled(modManager.isProcessingESP)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04).cornerRadius(14))

                // 4 Tactical ESP Feature Capabilities Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    espFeaturePill(icon: "tag.fill", title: "ESP TÊN & ID", desc: "Hiện tên qua tường", isActive: modManager.isESPEnabled)
                    espFeaturePill(icon: "viewfinder", title: "ESP BOX 2D/3D", desc: "Khung hitbox chuẩn", isActive: modManager.isESPEnabled)
                    espFeaturePill(icon: "ruler.fill", title: "ESP ĐO MÉT", desc: "Khoảng cách real-time", isActive: modManager.isESPEnabled)
                    espFeaturePill(icon: "bolt.horizontal.fill", title: "ESP LINE TRACER", desc: "Tia dẫn từ súng", isActive: modManager.isESPEnabled)
                }

                // Telemetry Specs
                VStack(spacing: 6) {
                    HStack {
                        Text("TARGET CONTAINER:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text(modManager.selectedBundle)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.red)
                    }

                    HStack {
                        Text("PATCH PAYLOAD:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("Assembly-CSharp (ESP Core)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }

                    HStack {
                        Text("TRẠNG THÁI:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text(modManager.isESPEnabled ? "● HOẠT ĐỘNG" : "○ CHƯA BẬT")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(modManager.isESPEnabled ? Color.green : Color.secondary)
                    }
                }
                .padding(12)
                .background(Color.black.opacity(0.35).cornerRadius(12))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                    .shadow(color: Color.red.opacity(0.25), radius: 8)
            )
        }
    }

    private func espFeaturePill(icon: String, title: String, desc: String, isActive: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isActive ? Color.red : Color.secondary)
                .frame(width: 24, height: 24)
                .background((isActive ? Color.red : Color.white).opacity(0.1).cornerRadius(6))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(isActive ? Color.white : Color.secondary)
                Text(desc)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03).cornerRadius(10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.red.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.8)
        )
    }

    // MARK: - Tab 2: Locator Card Section (Định Vị Chấm Trắng - Định vị.3105)
    private var locatorCardSection: some View {
        VStack(spacing: 16) {
            // Holographic Radar HUD
            CyberRadarHUDView()
                .padding(.top, 12)

            // Radar Status & Details Card
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.cyan)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.cyan.opacity(0.4), radius: 6)

                        Image(systemName: "scope")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Chấm Trắng Định Vị")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.white)

                            Text("RADAR VIP")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.18).cornerRadius(4))
                        }

                        Text("Hiện vị trí đối thủ chuẩn xác qua tường")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Toggle Button Kèm Hiệu Ứng Loading Nhanh
                    HStack(spacing: 8) {
                        if modManager.isProcessingLocator {
                            ProgressView()
                                .tint(Color.cyan)
                                .scaleEffect(0.85)
                                .transition(.opacity.combined(with: .scale))
                        }

                        Toggle(
                            "",
                            isOn: Binding(
                                get: { modManager.isLocatorEnabled },
                                set: { _ in
                                    guard !modManager.isProcessingLocator else { return }
                                    modManager.toggleLocator(store: store)
                                }
                            )
                        )
                        .labelsHidden()
                        .tint(Color.cyan)
                        .disabled(modManager.isProcessingLocator)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04).cornerRadius(14))

                // Telemetry Specs (Tuyệt đối không hiển thị 3105)
                VStack(spacing: 6) {
                    HStack {
                        Text("TARGET BUNDLE:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text(modManager.selectedBundle)
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.cyan)
                    }

                    HStack {
                        Text("CHẾ ĐỘ RADAR:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("Chấm Trắng Toàn Bản Đồ")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }

                    HStack {
                        Text("TRẠNG THÁI:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text(modManager.isLocatorEnabled ? "● HOẠT ĐỘNG" : "○ CHƯA BẬT")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(modManager.isLocatorEnabled ? Color.green : Color.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                .shadow(color: Color.cyan.opacity(0.25), radius: 8)
        )
    }

    // MARK: - Tab 3: Custom Mod Card Section (Quản lý và áp dụng file mod)
    private var customModCardSection: some View {
        VStack(spacing: 14) {
            // Card Top Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.purple)
                        .frame(width: 3, height: 16)

                    Text("DANH SÁCH GÓI MOD TỰ CHỌN")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.purple)
                        .tracking(1.0)
                }

                Spacer()

                Text("\(store.items.count) GÓI")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.purple)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.purple.opacity(0.16))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.purple.opacity(0.4), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Divider()
                .background(Color.white.opacity(0.08))

            // Quick Tool Bar: [ + NHẬP FILE MOD ] [ 📂 DUYỆT DATA ] [ ⚙️ CHI TIẾT ]
            HStack(spacing: 8) {
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    showFileImporter = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("NHẬP FILE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    showAppDataBrowser = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("DUYỆT DATA")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.cyan)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.cyan.opacity(0.14))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    showPatchProjects = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .bold))
                        Text("CHI TIẾT")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)

            // Packages List or Empty State
            if store.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color.secondary)
                    Text("CHƯA CÓ GÓI MOD NÀO ĐƯỢC NẠP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                    Text("Bấm 'NHẬP FILE' để nạp tệp gói mod từ ứng dụng Tệp (Files). App sẽ tự động ghi đè hoặc tạo mới vào game.")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.03).cornerRadius(12))
                .padding(.horizontal, 14)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.items) { item in
                        customModItemRow(item)
                    }
                }
                .padding(.horizontal, 14)
            }

            // Exploit & Container Status Footer
            VStack(spacing: 6) {
                HStack {
                    Text("MỤC TIÊU:")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(modManager.selectedBundle)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.purple)
                }

                HStack {
                    Text("QUYỀN HẠN KERNEL:")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(AppState.shared.exploitStatus.isSuccess ? "● ĐÃ MỞ KHÓA SANDBOX" : "○ CHUẨN BỊ TỰ ĐỘNG")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(AppState.shared.exploitStatus.isSuccess ? Color.green : Color.yellow)
                }

                HStack {
                    Text("CƠ CHẾ GHI TỆP:")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text("Tự Động Tạo Hoặc Ghi Đè (0o777)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.purple.opacity(0.6), lineWidth: 1.5)
                .shadow(color: Color.purple.opacity(0.25), radius: 8)
        )
    }

    private func customModItemRow(_ item: PatchLibraryItem) -> some View {
        let isApplied = DevicePatchService.latestReceipt(projectID: item.id) != nil
        let displayName = cleanPackageName(item)

        return HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(isApplied ? Color.green.opacity(0.2) : Color.purple.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: item.isLocked ? "lock.fill" : (isApplied ? "checkmark.circle.fill" : "shippingbox.fill"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(item.isLocked ? Color.yellow : (isApplied ? Color.green : Color.purple))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let project = item.project {
                        Text("\(project.rules.count) files")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                    }
                    Text(isApplied ? "● ĐÃ ÁP DỤNG" : "○ CHƯA BẬT")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(isApplied ? Color.green : Color.secondary)
                }
            }

            Spacer()

            // Buttons: Áp Dụng / Khôi Phục
            HStack(spacing: 6) {
                if isApplied {
                    Button {
                        restoreCustomMod(item)
                    } label: {
                        Text("KHÔI PHỤC")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.orange)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.16))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        applyCustomMod(item)
                    } label: {
                        Text("ÁP DỤNG")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.16))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                // Delete Button
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    store.delete(item)
                    modManager.triggerToast("Đã xóa gói!")
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.red.opacity(0.7))
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.04).cornerRadius(12))
    }

    private func cleanPackageName(_ item: PatchLibraryItem) -> String {
        var name = item.project?.name ?? item.packageURL.deletingPathExtension().lastPathComponent
        name = name.replacingOccurrences(of: "3105", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { name = "Gói Mod VIP" }
        return name
    }

    private func applyCustomMod(_ item: PatchLibraryItem) {
        guard let baseProject = item.project else {
            if item.isLocked {
                store.requestUnlock(for: item)
            } else {
                modManager.triggerToast("Gói mod không hợp lệ hoặc chưa mở khóa!")
            }
            return
        }

        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        Task {
            await ModFeatureManager.ensureExploitReady()
            do {
                let project = item.summary.schemaVersion >= 2
                    ? try PatchProjectLibrary.synchronizeWorkspace(item: item)
                    : baseProject
                _ = try DevicePatchService.apply(project: project)
                await MainActor.run {
                    store.reload()
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    let cleanName = cleanPackageName(item)
                    modManager.triggerToast("Đã áp dụng thành công: \(cleanName)!")
                }
            } catch {
                await MainActor.run {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    modManager.triggerToast("Lỗi áp dụng: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreCustomMod(_ item: PatchLibraryItem) {
        guard let receipt = DevicePatchService.latestReceipt(projectID: item.id) else {
            modManager.triggerToast("Gói chưa được áp dụng hoặc không có bản lưu!")
            return
        }

        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        Task {
            do {
                try DevicePatchService.restore(receipt: receipt)
                await MainActor.run {
                    store.reload()
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    let cleanName = cleanPackageName(item)
                    modManager.triggerToast("Đã khôi phục thành công: \(cleanName)!")
                }
            } catch {
                await MainActor.run {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    modManager.triggerToast("Lỗi khôi phục: \(error.localizedDescription)")
                }
            }
        }
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

        let isMax = modManager.selectedBundle == "com.dts.freefiremax"
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
