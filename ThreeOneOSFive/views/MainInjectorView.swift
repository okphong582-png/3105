import SwiftUI
import UIKit

// MARK: - Main Injector View (Giao diện chuẩn theo yêu cầu)
struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared

    // Game Selection State (Sau khi nhập key -> Hiện 2 Logo chọn Game)
    @State private var hasSelectedGame = false
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var lastActivatedAimName: String? = nil

    var body: some View {
        Group {
            if !hasSelectedGame {
                // 1. MÀN HÌNH CHỌN 2 LOGO GIỮA MÀN HÌNH (FREE FIRE THƯỜNG & MAX)
                GameSelectionView { chosenBundle in
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        hasSelectedGame = true
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // 2. MÀN HÌNH CHÍNH (GIAO DIỆN CHUẨN Y HỆT ẢNH)
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
                Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()

                // Ambient Radial Lights
                VStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.14), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 340, height: 340)
                        .blur(radius: 90)
                        .offset(x: -80, y: -100)

                    Spacer()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.14), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 320, height: 320)
                        .blur(radius: 90)
                        .offset(x: 80, y: 100)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Top Header Bar: Back button < | Title | VIP Badge
                        topNavBar

                        // Selected Game Info Card (Icon + Free Fire / com.dts.freefireth)
                        selectedGameHeaderCard

                        // Main Content Card: Aim Bot
                        aimBotCardSection

                        // Bottom Big Action Button: ▶ OPEN GAME
                        openGameButton

                        Spacer(minLength: 20)
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
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                    Text("ĐỔI GAME")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            }

            Spacer()

            // Title: Game Name
            Text(modManager.gameShortName.uppercased())
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.0, green: 0.85, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .tracking(1.5)

            Spacer()

            // Tier Badge
            if let lic = licenseManager.currentLicense {
                Text(lic.tierBadgeText)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(lic.isPremiumTier ? Color.yellow : (lic.isLiteTier ? Color.green : Color.orange))
                    .padding(.horizontal, 8)
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

    // MARK: - Selected Game Header Card (Giống trong ảnh)
    private var selectedGameHeaderCard: some View {
        let isMax = modManager.selectedBundle == "com.dts.freefiremax"
        let accentColor = isMax ? Color(red: 0.65, green: 0.35, blue: 1.0) : Color.orange

        return HStack(spacing: 14) {
            // Square App Logo Icon
            GameAppIconBadge(isMax: isMax, size: 58)

            // Game Details
            VStack(alignment: .leading, spacing: 4) {
                Text(modManager.gameShortName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(modManager.selectedBundle)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.secondary)

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    Text("Ready • Sẵn Sàng")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.green)
                }
                .padding(.top, 1)
            }

            Spacer()

            // Switch game shortcut icon
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    hasSelectedGame = false
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accentColor)
                    .padding(10)
                    .background(accentColor.opacity(0.12).cornerRadius(10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Tab 1: Aim Bot Card (Giao diện viền xanh neon y hệt ảnh)
    private var aimBotCardSection: some View {
        let visibleAims = AimModType.allCases.filter { licenseManager.isAimVisible($0) }

        return VStack(spacing: 0) {
            // Card Top Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 3, height: 16)

                    Text("AIM BOT")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.green)
                        .tracking(1.0)
                }

                Spacer()

                Text("LIVE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
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
                VStack(spacing: 14) {
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
                .padding(.bottom, 10)
            }

            // Bottom Status Text inside Card (y hệt ảnh: "✓ Activated ...")
            if let lastAim = lastActivatedAimName {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                    Text("✓ Activated \(lastAim)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.06))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                    Text("Ready — Activate Aim Bot Now")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.secondary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.green.opacity(0.7), lineWidth: 1.5)
                .shadow(color: Color.green.opacity(0.35), radius: 10)
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
            // Square Colored Icon Container (giống hệt ảnh)
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isAllowed ? aim.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 42, height: 42)
                    .shadow(color: (isAllowed ? aim.accentColor : Color.clear).opacity(0.4), radius: 6)

                Image(systemName: isAllowed ? aim.icon : "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Title and Subtitle
            VStack(alignment: .leading, spacing: 3) {
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
                    .scaleEffect(0.9)
            } else if !isAllowed {
                Button {
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.warning)
                    modManager.triggerToast("Tính năng này yêu cầu Key PRO VIP! Gói Lite chỉ có Aim Neck, Drag, Body.")
                } label: {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 26))
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
        .padding(.vertical, 3)
    }

    // MARK: - Tab 2: Mod Skin Card (Viền Cyan Neon)
    private var modSkinCardSection: some View {
        let canUseMods = licenseManager.currentLicense?.canUseMods ?? false

        return VStack(spacing: 0) {
            // Card Header
            HStack {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cyan)
                        .frame(width: 3, height: 16)

                    Text("MOD SKIN & TRANG PHỤC VIP")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                        .tracking(1.0)
                }

                Spacer()

                Text("PRO")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.16))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Mod Skin Rows
            VStack(spacing: 14) {
                // ROW 1: AK Rồng Xanh (MP40 Draco)
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(canUseMods ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 42, height: 42)
                            .shadow(color: (canUseMods ? Color.orange : Color.clear).opacity(0.4), radius: 6)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MP40 Mãng Xà Draco VIP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(canUseMods ? Color.white : Color.secondary)

                        Text("Thay thế ngoại hình & tia lửa đạn MP40")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if modManager.isProcessingModSkin {
                        ProgressView().tint(Color.cyan)
                    } else if !canUseMods {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.orange)
                    } else {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { modManager.isModSkinEnabled },
                                set: { _ in modManager.toggleModSkin(store: store) }
                            )
                        )
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.cyan))
                    }
                }

                // ROW 2: Mod Trang Phục Ignis VIP
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(canUseMods ? Color(red: 0.65, green: 0.35, blue: 1.0) : Color.gray.opacity(0.3))
                            .frame(width: 42, height: 42)
                            .shadow(color: (canUseMods ? Color.purple : Color.clear).opacity(0.4), radius: 6)

                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Trang Phục Ignis VIP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(canUseMods ? Color.white : Color.secondary)

                        Text("Độc quyền nhân vật Ignis")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if modManager.isProcessingModOutfit {
                        ProgressView().tint(Color.cyan)
                    } else if !canUseMods {
                        Image(systemName: "lock.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.orange)
                    } else {
                        Toggle(
                            "",
                            isOn: Binding(
                                get: { modManager.isModOutfitEnabled },
                                set: { _ in modManager.toggleModOutfit(store: store) }
                            )
                        )
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.cyan))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            // Status message
            if !canUseMods {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                    Text("Gói Key Lite & Vượt Link không mở khóa Mod Skin. Cần Key PRO VIP!")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.07, green: 0.08, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
                .shadow(color: Color.cyan.opacity(0.35), radius: 10)
        )
    }

    // MARK: - Tab 3: Cài Đặt Section
    private var settingsCardSection: some View {
        VStack(spacing: 12) {
            // License Details
            if let lic = licenseManager.currentLicense {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BẢN QUYỀN HIỆN TẠI")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                        Text(lic.key)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    Text(lic.remainingTimeFormatted)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color.yellow)
                }
                .padding(14)
                .background(Color.white.opacity(0.04).cornerRadius(14))
            }

            // Contact Admins
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://zalo.me/0866445455")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Zalo Admin Hoàng Hà: 0866445455")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.blue.opacity(0.8).cornerRadius(12))
                }

                Link(destination: URL(string: "https://zalo.me/0826794943")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Zalo Admin Trọng Kiên: 0826794943")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.blue.opacity(0.8).cornerRadius(12))
                }

                Link(destination: URL(string: "https://t.me/+1fstsksh_dMxNjE1")!) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Telegram Hỗ Trợ Chính Thức")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(Color.cyan)
                    .padding(12)
                    .background(Color.cyan.opacity(0.15).cornerRadius(12))
                }
            }

            // Switch Game Shortcut
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    hasSelectedGame = false
                }
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                    Text("Đổi Phiên Bản Game (Thường / MAX)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08).cornerRadius(12))
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Open Game Button (Y HỆT ẢNH: GRADIENT CYAN SANG TÍM)
    private var openGameButton: some View {
        Button {
            openGame()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 17, weight: .black))

                Text("OPEN GAME")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .tracking(2.0)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.82, blue: 1.0),
                        Color(red: 0.6, green: 0.3, blue: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(red: 0.0, green: 0.82, blue: 1.0).opacity(0.4), radius: 14, y: 5)
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
            modManager.triggerToast("Đã kích hoạt tính năng xong! Hãy mở game \(targetName) để bắt đầu.")
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
