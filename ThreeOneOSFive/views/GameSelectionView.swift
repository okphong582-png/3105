import SwiftUI
import UIKit

// MARK: - Game Logo Component (Hiển thị đúng logo thật của Free Fire Thường & MAX)
struct GameAppIconBadge: View {
    let isMax: Bool
    let size: CGFloat

    private var loadedLogo: UIImage? {
        if let assetImg = UIImage(named: isMax ? "FFMAXLogo" : "FFTHLogo") {
            return assetImg
        }
        let imageName = isMax ? "ffmax" : "ffth"
        if let p = Bundle.main.path(forResource: imageName, ofType: "png"), let img = UIImage(contentsOfFile: p) {
            return img
        }
        if let p = Bundle.main.path(forResource: imageName, ofType: "webp"), let img = UIImage(contentsOfFile: p) {
            return img
        }
        return nil
    }

    var body: some View {
        ZStack {
            if let img = loadedLogo {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.5), radius: 8, y: 4)
            } else {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: isMax ? "bolt.shield.fill" : "flame.fill")
                            .font(.system(size: size * 0.45, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
            }
        }
    }
}

// MARK: - Card Scale Button Style
struct CardScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Game Selection View (Giao Diện Cyber Tactical Độc Quyền - Không Đạo Bất Kỳ App Nào)
struct GameSelectionView: View {
    var onSelectGame: (String) -> Void

    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared
    @ObservedObject private var nextDNSService = NextDNSInstallerService.shared
    @State private var showNextDNSSetup = false

    private var maskedKeyText: String {
        let raw = licenseManager.currentLicense?.key ?? UserDefaults.standard.string(forKey: "oni_saved_key") ?? ""
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return "KEY CHƯA KÍCH HOẠT"
        }
        if clean.count <= 8 {
            return "KEY \(clean)"
        }
        let start = String(clean.prefix(4))
        let end = String(clean.suffix(4))
        return "KEY \(start)••••\(end)"
    }

    private var remainingTimeText: String {
        guard let lic = licenseManager.currentLicense else {
            return "Còn Vĩnh Viễn"
        }
        if lic.duration == "lifetime" || lic.durationSeconds == -1 || lic.expiresAt == -1 {
            return "Còn Vĩnh Viễn"
        }
        guard let exp = lic.expiresAt, exp > 0 else {
            let h = lic.durationSeconds / 3600
            if h >= 24 {
                return "Còn \(h / 24) ngày"
            }
            return "Còn \(h) giờ"
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diffSec = max(0, (exp - now) / 1000)
        if diffSec <= 0 { return "Đã hết hạn" }
        let days = diffSec / 86400
        let hours = (diffSec % 86400) / 3600
        let minutes = (diffSec % 3600) / 60
        if days > 0 {
            return "Còn \(days) ngày \(hours) giờ"
        }
        if hours > 0 {
            return "Còn \(hours) giờ \(minutes) phút"
        }
        return "Còn \(max(1, minutes)) phút"
    }

    var body: some View {
        ZStack {
            // Obsidian Cyber Ambient Background
            Color(red: 0.03, green: 0.04, blue: 0.07)
                .ignoresSafeArea()

            // Futuristic Radial Glows
            VStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -80, y: -60)
                Spacer()
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: 80, y: 60)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. TOP TACTICAL HUD
                topTacticalHUD

                Spacer(minLength: 12)

                // 2. DUAL HOLOGRAPHIC GAME MODULES (FF MAX & FF THƯỜNG)
                VStack(spacing: 16) {
                    // Module 1: Free Fire MAX (Electric Cyan & Neon Sapphire)
                    cyberGamePod(
                        isMax: true,
                        title: "FREE FIRE MAX",
                        bundleID: "com.dts.freefiremax",
                        badge: "ULTRA HD",
                        accentColor: Color.cyan,
                        secondaryColor: Color.blue,
                        specs: ["FULL AIM ASSIST (5 AIM)", "ĐỊNH VỊ CHẤM TRẮNG VIP"],
                        action: { selectGame(bundleID: "com.dts.freefiremax") }
                    )

                    // Module 2: Free Fire Thường (Sunset Flame & Cyber Amber)
                    cyberGamePod(
                        isMax: false,
                        title: "FREE FIRE THƯỜNG",
                        bundleID: "com.dts.freefireth",
                        badge: "STANDARD FPS",
                        accentColor: Color.orange,
                        secondaryColor: Color.red,
                        specs: ["FULL AIM ASSIST (5 AIM)", "ĐỊNH VỊ CHẤM TRẮNG VIP"],
                        action: { selectGame(bundleID: "com.dts.freefireth") }
                    )
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // 3. BOTTOM KEY TERMINAL BAR (CHUẨN 100% YÊU CẦU: CHẤM XANH + DÒNG 1 + DÒNG 2)
                bottomKeyTerminalBar
            }
        }
        .onAppear {
            if !nextDNSService.isSetupCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showNextDNSSetup = true
                }
            }
        }
        .sheet(isPresented: $showNextDNSSetup) {
            NextDNSSetupSheet()
        }
    }

    // MARK: - 1. Top Tactical HUD
    private var topTacticalHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.green, radius: 4)

                    Text("HỆ THỐNG ONI AKUMA")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                        .tracking(1.5)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.purple)
                        Text("iOS \(UIDevice.current.systemVersion)")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }

                    Text("•")
                        .foregroundStyle(Color.white.opacity(0.3))

                    HStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.cyan)
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.green)
                    }
                }
            }

            Spacer()

            // Antiban NextDNS Quick Button
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                showNextDNSSetup = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: nextDNSService.isSetupCompleted ? "shield.checkmark.fill" : "shield.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(nextDNSService.isSetupCompleted ? Color.green : Color.orange)
                    Text("ANTIBAN")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06).cornerRadius(10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((nextDNSService.isSetupCompleted ? Color.green : Color.orange).opacity(0.4), lineWidth: 1)
                )
            }

            // Tactical Target Switcher Hint
            VStack(alignment: .trailing, spacing: 2) {
                Text("CHỌN MỤC TIÊU")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.secondary)
                Text("2 BẢN GAME")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05).cornerRadius(10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    // MARK: - 2. Cyber Game Pod (Thiết Kế Mới Toàn Diện - Phong Cách Tactical Cyberpunk)
    @ViewBuilder
    private func cyberGamePod(
        isMax: Bool,
        title: String,
        bundleID: String,
        badge: String,
        accentColor: Color,
        secondaryColor: Color,
        specs: [String],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                // Carbon Texture Background
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.05, green: 0.06, blue: 0.09)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Cyber Grid Border & Accent Glow
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.6), secondaryColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )

                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        // Game App Logo Badge
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                                )

                            GameAppIconBadge(isMax: isMax, size: 64)
                        }

                        // Info Column
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(badge)
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(accentColor.opacity(0.16).cornerRadius(5))

                                Spacer()

                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(accentColor.opacity(0.8))
                            }

                            Text(title)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundStyle(Color.white)

                            Text(bundleID)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)

                    // Specs & Action
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(specs, id: \.self) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 4, height: 4)
                                    Text(item)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                            }
                        }

                        Spacer()

                        // Action Pill
                        HStack(spacing: 5) {
                            Image(systemName: isMax ? "bolt.fill" : "flame.fill")
                                .font(.system(size: 11, weight: .black))
                            Text("CHỌN")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [accentColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: accentColor.opacity(0.4), radius: 8)
                    }
                }
                .padding(16)
            }
            .shadow(color: accentColor.opacity(0.15), radius: 14, y: 6)
        }
        .buttonStyle(CardScaleButtonStyle())
    }

    // MARK: - 3. Bottom Key Terminal Bar (Chuẩn 100% Theo Yêu Cầu Người Dùng)
    private var bottomKeyTerminalBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.cyan.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.2)

            HStack(spacing: 14) {
                // Chấm xanh lá phát sáng 🟢
                Circle()
                    .fill(Color(red: 0.15, green: 0.95, blue: 0.4))
                    .frame(width: 11, height: 11)
                    .shadow(color: Color.green.opacity(0.9), radius: 6)

                // Dòng 1: KEY xxxx••••yyyy & Dòng 2: Còn ...
                VStack(alignment: .leading, spacing: 3) {
                    Text(maskedKeyText)
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .tracking(0.5)

                    Text(remainingTimeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.2, green: 0.95, blue: 0.45))
                }

                Spacer()

                // Verified Security Seal & Change Key
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12).cornerRadius(6))

                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        licenseManager.logout(reason: "Vui lòng nhập Key mới")
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("ĐỔI KEY")
                        }
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12).cornerRadius(6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.96))
        }
    }

    private func selectGame(bundleID: String) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        modManager.selectedBundle = bundleID
        DispatchQueue.global(qos: .userInitiated).async {
            ContainerStore.warmupAndActivateGameContainer(bundleID: bundleID)
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            onSelectGame(bundleID)
        }
    }
}
