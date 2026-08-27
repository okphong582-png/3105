import SwiftUI
import UIKit

struct MainInjectorView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @StateObject private var store = PatchProjectStore()
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared

    @AppStorage("oni_akuma_has_shown_welcome_v2") private var hasShownWelcome = false
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"

    @State private var selectedTab: Int = 0 // 0: Aim Bot, 1: Mod Skin, 2: Mod Đồ
    @State private var showSettings = false
    @State private var showLogs = false
    @State private var showWelcomeDialog = false

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cyberpunk Obsidian Gradient Background
                Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()

                // Ambient Radial Glows
                VStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [activeTheme.primaryColor.opacity(0.18), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 350, height: 350)
                        .blur(radius: 90)
                        .offset(y: -90)

                    Spacer()

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 160
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(y: 90)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        heroHeader

                        gameSelectorCard

                        // Segmented Tab Switcher (Aim Bot vs Mod Skin vs Mod Đồ)
                        tabSwitcherSection

                        if selectedTab == 0 {
                            aimBotSection
                        } else if selectedTab == 1 {
                            modSkinSection
                        } else {
                            modOutfitSection
                        }

                        // Open Game Button
                        openGameButton

                        systemStatusCard

                        creditsBadge
                    }
                    .padding(.horizontal, AppTheme.pageInset)
                    .padding(.top, 6)
                    .padding(.bottom, 36)
                }
            }
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
                    HStack(spacing: 12) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(activeTheme.primaryColor)
                        }
                        .accessibilityLabel(language.text("accessibility.open_settings"))
                    }
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
        VStack(spacing: 8) {
            ZStack {
                // Outer glowing pulse ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [activeTheme.primaryColor.opacity(0.6), activeTheme.primaryColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 86, height: 86)
                    .shadow(color: activeTheme.primaryColor.opacity(0.5), radius: 10)

                AppLogo(size: 72)
            }

            VStack(spacing: 4) {
                Text("OniAkuma")
                    .font(.system(size: 28, weight: .black, design: .rounded))
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
                        .font(.caption2.weight(.black).monospaced())
                }
                .foregroundStyle(activeTheme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(activeTheme.primaryColor.opacity(0.12))
                        .overlay(Capsule().stroke(activeTheme.primaryColor.opacity(0.35), lineWidth: 1))
                )

                // License duration & Tier badge
                if let lic = licenseManager.currentLicense {
                    HStack(spacing: 6) {
                        // Tier badge
                        Text(lic.tierBadgeText)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(lic.isPremiumTier ? Color.yellow : Color.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((lic.isPremiumTier ? Color.yellow : Color.orange).opacity(0.15).cornerRadius(4))

                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.green)
                            Text(lic.remainingTimeFormatted)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.green)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06).cornerRadius(6))
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Game Selector Card
    private var gameSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("BẢN GAME ĐÍCH")
                    .font(.caption.weight(.black))
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
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text(bundleID)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? activeTheme.primaryColor.opacity(0.85) : .secondary.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? activeTheme.primaryColor.opacity(0.14) : Color(red: 0.11, green: 0.13, blue: 0.17))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? activeTheme.primaryColor : Color.white.opacity(0.06),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(color: isSelected ? activeTheme.primaryColor.opacity(0.2) : .clear, radius: 8)
            )
        }
        .buttonStyle(.plain)
        .disabled(!modManager.processingAimMods.isEmpty || modManager.isProcessingModSkin || modManager.isProcessingModOutfit)
    }

    // MARK: - Tab Switcher Section (3 Tabs)
    @ViewBuilder
    private var tabSwitcherSection: some View {
        let canUseMods = licenseManager.currentLicense?.canUseMods ?? false
        HStack(spacing: 6) {
            tabButton(index: 0, title: "AIM BOT", icon: "scope", isLocked: false)
            tabButton(index: 1, title: "MOD SKIN", icon: "flame.fill", isLocked: !canUseMods)
            tabButton(index: 2, title: "MOD ĐỒ", icon: "tshirt.fill", isLocked: !canUseMods)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func tabButton(index: Int, title: String, icon: String, isLocked: Bool) -> some View {
        let isSelected = selectedTab == index
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = index
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isLocked ? "lock.fill" : icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? .black : (isLocked ? Color.orange : .secondary))

                Text(title)
                    .font(.system(size: 10, weight: .black, design: .rounded))
            }
            .foregroundStyle(isSelected ? .black : .secondary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? (isLocked ? Color.orange : activeTheme.primaryColor) : Color.clear)
                    .shadow(color: isSelected ? (isLocked ? Color.orange.opacity(0.4) : activeTheme.primaryColor.opacity(0.4)) : .clear, radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 1: Aim Bot Section (Tự động lọc theo Admin & Gói Key)
    private var aimBotSection: some View {
        let visibleAims = AimModType.allCases.filter { licenseManager.isAimVisible($0) }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TÍNH NĂNG AIM BOT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1.0)

                Spacer()

                Text("\(visibleAims.count) CHẾ ĐỘ SẴN SÀNG")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(activeTheme.primaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(activeTheme.primaryColor.opacity(0.12).cornerRadius(6))
            }
            .padding(.horizontal, 4)

            if visibleAims.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("Các chế độ Aim Bot đang được Quản Trị Viên tạm ẩn.")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Vui lòng quay lại sau khi Admin mở lại trên máy chủ.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white.opacity(0.04).cornerRadius(16))
            } else {
                VStack(spacing: 12) {
                    ForEach(visibleAims) { aimType in
                        let isAllowed = licenseManager.currentLicense?.canUseAimMod(aimType) ?? true
                        featureToggleCard(
                            title: aimType.title,
                            subtitle: isAllowed ? aimType.subtitle : "🔒 Gói Key Lite chỉ có Neck, Drag, Body. Hãy nâng cấp PRO VIP!",
                            filename: aimType.filename,
                            icon: isAllowed ? aimType.icon : "lock.fill",
                            isEnabled: isAllowed && modManager.isAimModEnabled(aimType),
                            isProcessing: modManager.isAimModProcessing(aimType),
                            accentColor: isAllowed ? aimType.accentColor : Color.gray,
                            isLocked: !isAllowed
                        ) {
                            if !isAllowed {
                                let gen = UINotificationFeedbackGenerator()
                                gen.notificationOccurred(.warning)
                                modManager.triggerToast("Tính năng này yêu cầu Key PRO VIP! Gói Lite chỉ có Aim Neck, Drag, Body.")
                            } else {
                                modManager.toggleAimMod(aimType, store: store)
                            }
                        }
                    }
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .leading)))
    }

    // MARK: - Tab 2: Mod Skin Section (MP40 Mãng Xà từ Phong Xà)
    private var modSkinSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("VŨ KHÍ TIẾN HÓA CẤP TỐI THƯỢNG")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1.0)

                Spacer()

                Text("LV.7 MAX")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.15).cornerRadius(6))
            }
            .padding(.horizontal, 4)

            // Mod Skin Feature Card
            VStack(spacing: 14) {
                // Header of skin
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                modManager.isModSkinEnabled
                                    ? Color.yellow.opacity(0.2)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(width: 54, height: 54)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                modManager.isModSkinEnabled
                                    ? LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.secondary, .secondary.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("MP40 MÃNG XÀ (DRACO)")
                                .font(.system(size: 16, weight: .black))
                                .foregroundStyle(modManager.isModSkinEnabled ? Color.yellow : .white)

                            Circle()
                                .fill(modManager.isModSkinEnabled ? Color.green : Color.red.opacity(0.8))
                                .frame(width: 7, height: 7)

                            Text(modManager.isModSkinEnabled ? "ĐÃ BẬT" : "TẮT")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(modManager.isModSkinEnabled ? Color.green : .secondary)
                        }

                        Text("Thay thế hiệu ứng tia lửa & ngoại hình MP40")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("File: Modskin.3105 (5.03 MB)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(modManager.isModSkinEnabled ? Color.yellow.opacity(0.9) : .secondary.opacity(0.6))
                    }

                    Spacer()
                }

                // Weapon Attribute Badges
                HStack(spacing: 8) {
                    attributeBadge(label: "SÁT THƯƠNG", value: "+2", color: .red)
                    attributeBadge(label: "TỐC BẮN", value: "+1", color: .orange)
                    attributeBadge(label: "THAY ĐẠN", value: "-1", color: .gray)
                }

                // Important Note Box
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.yellow)

                        Text("GHI CHÚ QUAN TRỌNG")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.yellow)
                    }

                    Text("Chỉ khi tài khoản của bạn sở hữu skin Phong Xà mới đổi thành công sang MP40 Mãng Xà!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.yellow.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
                        )
                )

                // Activation Button (or Premium Lock)
                if !(licenseManager.currentLicense?.canUseMods ?? false) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.orange)
                            Text("TÍNH NĂNG DÀNH CHO KEY PREMIUM VIP")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.orange)
                        }
                        Text("Bạn đang dùng Key Vượt Link (chỉ mở khóa Aim Bot). Vui lòng nâng cấp Key Premium VIP để sử dụng Mod Skin MP40!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1).cornerRadius(12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                    )
                } else {
                    Button {
                        modManager.toggleModSkin(store: store)
                    } label: {
                        HStack(spacing: 10) {
                            if modManager.isProcessingModSkin {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: modManager.isModSkinEnabled ? "checkmark.circle.fill" : "power")
                                    .font(.system(size: 16, weight: .bold))
                            }

                            Text(modManager.isModSkinEnabled ? "ĐANG BẬT MOD SKIN (BẤM ĐỂ TẮT)" : "KÍCH HOẠT MOD SKIN MP40")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    modManager.isModSkinEnabled
                                        ? LinearGradient(colors: [Color.green, Color(red: 0.1, green: 0.6, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(
                                    color: (modManager.isModSkinEnabled ? Color.green : Color.orange).opacity(0.4),
                                    radius: 8,
                                    y: 3
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(modManager.isProcessingModSkin)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                modManager.isModSkinEnabled ? Color.yellow.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: modManager.isModSkinEnabled ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: modManager.isModSkinEnabled ? Color.yellow.opacity(0.15) : Color.clear,
                        radius: 10,
                        y: 3
                    )
            )
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    // MARK: - Tab 3: Mod Đồ Section (Chỉ sử dụng nhân vật Ignis)
    private var modOutfitSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("BỘ TRANG PHỤC ĐẶC BIỆT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1.0)

                Spacer()

                Text("IGNIS ONLY")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15).cornerRadius(6))
            }
            .padding(.horizontal, 4)

            // Mod Outfit Feature Card
            VStack(spacing: 14) {
                // Header of outfit
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                modManager.isModOutfitEnabled
                                    ? Color.cyan.opacity(0.2)
                                    : Color.white.opacity(0.06)
                            )
                            .frame(width: 54, height: 54)

                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(
                                modManager.isModOutfitEnabled
                                    ? LinearGradient(colors: [.cyan, .blue, .teal], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.secondary, .secondary.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("MOD ĐỒ NHÂN VẬT IGNIS")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(modManager.isModOutfitEnabled ? Color.cyan : .white)

                            Circle()
                                .fill(modManager.isModOutfitEnabled ? Color.green : Color.red.opacity(0.8))
                                .frame(width: 7, height: 7)

                            Text(modManager.isModOutfitEnabled ? "ĐÃ BẬT" : "TẮT")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(modManager.isModOutfitEnabled ? Color.green : .secondary)
                        }

                        Text("Thay đổi ngoại hình & bộ trang phục đặc biệt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("File: Mod đồ chỉ sử dụng nhân vật Ignis.3105 (2.62 MB)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(modManager.isModOutfitEnabled ? Color.cyan.opacity(0.9) : .secondary.opacity(0.6))
                    }

                    Spacer()
                }

                // Outfit Attribute Badges
                HStack(spacing: 8) {
                    attributeBadge(label: "NHÂN VẬT", value: "IGNIS", color: .cyan)
                    attributeBadge(label: "HIỆU ỨNG", value: "FULL SET", color: .teal)
                    attributeBadge(label: "TỐC ĐỘ", value: "MƯỢT 100%", color: .green)
                }

                // Important Note Box
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.yellow)

                        Text("GHI CHÚ QUAN TRỌNG")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.yellow)
                    }

                    Text("Mod đồ CHỈ hoạt động khi bạn chọn và sử dụng nhân vật IGNIS trong game Free Fire!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .lineSpacing(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.yellow.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
                        )
                )

                // Activation Button (or Premium Lock)
                if !(licenseManager.currentLicense?.canUseMods ?? false) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.orange)
                            Text("TÍNH NĂNG DÀNH CHO KEY PREMIUM VIP")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.orange)
                        }
                        Text("Bạn đang dùng Key Vượt Link (chỉ mở khóa Aim Bot). Vui lòng nâng cấp Key Premium VIP để sử dụng Mod Đồ Ignis!")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1).cornerRadius(12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.35), lineWidth: 1)
                    )
                } else {
                    Button {
                        modManager.toggleModOutfit(store: store)
                    } label: {
                        HStack(spacing: 10) {
                            if modManager.isProcessingModOutfit {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: modManager.isModOutfitEnabled ? "checkmark.circle.fill" : "power")
                                    .font(.system(size: 16, weight: .bold))
                            }

                            Text(modManager.isModOutfitEnabled ? "ĐANG BẬT MOD ĐỒ IGNIS (BẤM ĐỂ TẮT)" : "KÍCH HOẠT MOD ĐỒ IGNIS")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    modManager.isModOutfitEnabled
                                        ? LinearGradient(colors: [Color.green, Color(red: 0.1, green: 0.6, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .shadow(
                                    color: (modManager.isModOutfitEnabled ? Color.green : Color.cyan).opacity(0.4),
                                    radius: 8,
                                    y: 3
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(modManager.isProcessingModOutfit)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                modManager.isModOutfitEnabled ? Color.cyan.opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: modManager.isModOutfitEnabled ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: modManager.isModOutfitEnabled ? Color.cyan.opacity(0.15) : Color.clear,
                        radius: 10,
                        y: 3
                    )
            )
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    @ViewBuilder
    private func attributeBadge(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
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
        isLocked: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                isLocked
                                    ? Color.orange.opacity(0.12)
                                    : (isEnabled ? accentColor.opacity(0.2) : Color.white.opacity(0.06))
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: isLocked ? "lock.fill" : icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                isLocked
                                    ? LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .top, endPoint: .bottom)
                                    : (isEnabled
                                        ? LinearGradient(colors: [accentColor, .white], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [.secondary, .secondary.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                            )
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(title)
                                .font(.headline.weight(.black))
                                .foregroundStyle(isLocked ? Color.secondary : (isEnabled ? accentColor : .white))

                            if isLocked {
                                Text("CẦN PRO VIP")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15).cornerRadius(4))
                            } else {
                                Circle()
                                    .fill(isEnabled ? Color.green : Color.red.opacity(0.8))
                                    .frame(width: 7, height: 7)

                                Text(isEnabled ? "BẬT" : "TẮT")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(isEnabled ? Color.green : .secondary)
                            }
                        }

                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("File: \(filename)")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(isEnabled ? accentColor.opacity(0.85) : .secondary.opacity(0.6))
                    }

                    Spacer()

                    if isProcessing {
                        ProgressView()
                            .tint(accentColor)
                            .scaleEffect(1.1)
                    } else if isLocked {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.orange.opacity(0.8))
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
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isEnabled ? accentColor.opacity(0.55) : Color.white.opacity(0.08),
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

                VStack(alignment: .leading, spacing: 2) {
                    Text("MỞ \(modManager.gameShortName.uppercased()) NGAY")
                        .font(.headline.weight(.black))

                    Text("Khởi chạy game để tận hưởng cấu hình")
                        .font(.caption2)
                        .opacity(0.85)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [activeTheme.primaryColor, activeTheme.primaryColor.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: activeTheme.primaryColor.opacity(0.45), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - System Status Card
    private var systemStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label {
                    Text("TRẠNG THÁI HỆ THỐNG")
                        .font(.caption.weight(.black))
                        .foregroundStyle(activeTheme.primaryColor)
                } icon: {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(activeTheme.primaryColor)
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("SẴN SÀNG")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(Color.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12).cornerRadius(6))
            }

            Divider().background(Color.white.opacity(0.08))

            VStack(spacing: 8) {
                statusRow(title: "Bảo Vệ Đa Tầng", value: "Hoạt động", isOk: true)
                statusRow(title: "Chống Anti-Cheat", value: "Bảo vệ tối đa", isOk: true)
                statusRow(title: "Khai Thác Nhân (Kernel)", value: "Kexploit Opa334", isOk: true)
                statusRow(title: "Target Bundle", value: modManager.selectedBundle, isOk: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func statusRow(title: String, value: String, isOk: Bool) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(isOk ? .white : .secondary)
        }
    }

    // MARK: - Credits Badge
    private var creditsBadge: some View {
        VStack(spacing: 6) {
            Text("Phiên bản OniAkuma 1.1.1 (Build 7)")
                .font(.caption2)
                .foregroundStyle(.secondary.opacity(0.7))

            Text("Phát triển bởi HoangHaMod & TrongKien")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Toast View
    @ViewBuilder
    private func toastView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.green)

            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.95))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
        )
    }

    // MARK: - Welcome Dialog Overlay
    private var welcomeDialogOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWelcomeDialog()
                }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [activeTheme.primaryColor.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)

                    AppLogo(size: 64)
                }

                VStack(spacing: 8) {
                    Text("Chào mừng đến OniAkuma")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)

                    Text("Công cụ hỗ trợ Free Fire tối thượng phát triển bởi HoangHaMod & TrongKien.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(alignment: .leading, spacing: 10) {
                    welcomeFeatureRow(icon: "scope", title: "5 Chế Độ Aim Bot", desc: "Khóa thân, cân tâm, khóa ngực, ma thuật & khóa cổ.")
                    welcomeFeatureRow(icon: "flame.fill", title: "Mod Skin MP40 Mãng Xà", desc: "Tự động đổi từ skin Phong Xà sang MP40 Mãng Xà.")
                    welcomeFeatureRow(icon: "tshirt.fill", title: "Mod Đồ Nhân Vật Ignis", desc: "Full bộ trang phục đặc biệt cho nhân vật Ignis.")
                    welcomeFeatureRow(icon: "shield.checkered", title: "Bảo Mật Cực Cao", desc: "Bảo vệ đa lớp chống ban, an toàn tuyệt đối.")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.11, green: 0.13, blue: 0.17))
                )

                Button {
                    dismissWelcomeDialog()
                } label: {
                    Text("BẮT ĐẦU NGAY")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(activeTheme.primaryColor)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.1, blue: 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: activeTheme.primaryColor.opacity(0.3), radius: 25)
            )
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func welcomeFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(activeTheme.primaryColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)

                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dismissWelcomeDialog() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showWelcomeDialog = false
            hasShownWelcome = true
        }
    }

    // MARK: - Open Game
    private func openTargetGame() {
        let bundleID = modManager.selectedBundle
        let schemes = bundleID == "com.dts.freefiremax"
            ? ["freefiremax://", "ffmax://"]
            : ["freefireth://", "freefire://"]

        for schemeStr in schemes {
            if let url = URL(string: schemeStr), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                modManager.triggerToast("Đang mở \(modManager.gameShortName)...")
                return
            }
        }

        if let fallbackURL = URL(string: "\(schemes[0])") {
            UIApplication.shared.open(fallbackURL, options: [:]) { success in
                if success {
                    modManager.triggerToast("Đang mở \(modManager.gameShortName)...")
                } else {
                    modManager.triggerToast("Không thể tự mở game. Vui lòng mở game từ màn hình chính!")
                }
            }
        }
    }
}
