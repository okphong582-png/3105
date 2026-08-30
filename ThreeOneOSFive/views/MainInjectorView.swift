import SwiftUI
import UIKit

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

// MARK: - Main Injector View (Thiết Kế Độc Quyền - Không Đạo Bất Kỳ App Nào)
struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared

    // Game Selection State (Sau khi nhập key -> Hiện 2 Logo chọn Game)
    @State private var hasSelectedGame = false
    @State private var selectedTab: Int = 0 // 0: AIM ASSIST (5 Aim), 1: ĐỊNH VỊ (Định vị.3105)
    @State private var showSettings = false
    @State private var showLogs = false
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

                        // CUSTOM SEGMENTED TAB SELECTOR: [ 🎯 AIM ASSIST ] [ 📡 ĐỊNH VỊ RADAR ]
                        tacticalTabSelector

                        // TAB CONTENT:
                        if selectedTab == 0 {
                            // TAB 1: AIM BOT (5 CHỨC NĂNG AIM)
                            aimBotCardSection
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        } else {
                            // TAB 2: ĐỊNH VỊ CHẤM TRẮNG (Định vị.3105)
                            locatorCardSection
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

            // Brand Title
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: Color.green, radius: 4)

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

            // Tier Badge
            if let lic = licenseManager.currentLicense {
                Text(lic.tierBadgeText)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(lic.isPremiumTier ? Color.yellow : (lic.isLiteTier ? Color.green : Color.orange))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(
                                lic.isPremiumTier ? Color.yellow.opacity(0.5) : (lic.isLiteTier ? Color.green.opacity(0.5) : Color.orange.opacity(0.5)),
                                lineWidth: 1
                            )
                    )
            } else {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
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

    // MARK: - Tactical Dual Tab Selector (MỚI: [ 🎯 AIM ASSIST ] [ 📡 ĐỊNH VỊ RADAR ])
    private var tacticalTabSelector: some View {
        HStack(spacing: 8) {
            // Tab 0: AIM BOT
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 0
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 14, weight: .black))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("AIM ASSIST")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        Text("5 CHỨC NĂNG")
                            .font(.system(size: 8, weight: .bold))
                            .opacity(0.7)
                    }
                }
                .foregroundStyle(selectedTab == 0 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            selectedTab == 0
                                ? LinearGradient(colors: [Color.green, Color(red: 0.2, green: 0.85, blue: 0.4)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selectedTab == 0 ? Color.green.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 0 ? Color.green.opacity(0.35) : Color.clear, radius: 8, y: 2)
            }
            .buttonStyle(.plain)

            // Tab 1: ĐỊNH VỊ RADAR (Định vị.3105)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                    selectedTab = 1
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 14, weight: .black))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ĐỊNH VỊ RADAR")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                        Text("CHẤM TRẮNG")
                            .font(.system(size: 8, weight: .bold))
                            .opacity(0.7)
                    }
                }
                .foregroundStyle(selectedTab == 1 ? Color.black : Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            selectedTab == 1
                                ? LinearGradient(colors: [Color.cyan, Color(red: 0.1, green: 0.7, blue: 1.0)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(selectedTab == 1 ? Color.cyan.opacity(0.8) : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: selectedTab == 1 ? Color.cyan.opacity(0.35) : Color.clear, radius: 8, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color(red: 0.06, green: 0.07, blue: 0.10).cornerRadius(18))
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

            // NÚT TOGGLE MẶC ĐỊNH CỦA IOS (THEO YÊU CẦU CỦA BẠN)
            if isProcessing {
                ProgressView()
                    .tint(Color.green)
                    .scaleEffect(0.85)
            } else if !isAllowed {
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
                Toggle(
                    "",
                    isOn: Binding(
                        get: { isEnabled },
                        set: { newVal in
                            if newVal {
                                lastActivatedAimName = aim.shortTitle
                            }
                            modManager.toggleAimMod(aim, store: store)
                        }
                    )
                )
                .labelsHidden()
                .tint(Color.green)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Tab 1: Locator Card Section (Định Vị Chấm Trắng - Định vị.3105)
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

                            Text("ĐỊNH VỊ 3105")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.18).cornerRadius(4))
                        }

                        Text("Hiện vị trí đối thủ chuẩn xác qua tường (File: Định vị.3105)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }

                    Spacer()

                    // Toggle Button
                    if modManager.isProcessingLocator {
                        ProgressView()
                            .tint(Color.cyan)
                            .scaleEffect(0.9)
                    } else {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { modManager.isLocatorEnabled },
                                set: { _ in modManager.toggleLocator(store: store) }
                            )
                        )
                        .labelsHidden()
                        .tint(Color.cyan)
                    }
                }
                .padding(14)
                .background(Color.white.opacity(0.04).cornerRadius(14))

                // Telemetry Specs
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
                        Text("PACKAGE NAME:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("Định vị.3105 (Cham Trắng)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }

                    HStack {
                        Text("STATUS:")
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
