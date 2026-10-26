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
                    .saturation(0)
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

struct CardScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct GameSelectionView: View {
    var onSelectGame: (String) -> Void
    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var showNextDNSSetup = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Text("MIZZE").font(.system(size: 12, weight: .semibold)).tracking(4)
                    Spacer()
                    Button { showNextDNSSetup = true } label: {
                        Image(systemName: "shield.lefthalf.filled")
                            .frame(width: 44, height: 44)
                            .background(AppTheme.cardBackground, in: Circle())
                    }
                    .accessibilityLabel("Cài đặt DNS")
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Chọn trải nghiệm.")
                        .font(.system(size: 34, weight: .semibold)).tracking(-1.3)
                    Text("Chọn phiên bản để mở bảng điều khiển.")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
                VStack(spacing: 16) {
                    gameCard(isMax: true, number: "01", subtitle: "MAX EDITION")
                    gameCard(isMax: false, number: "02", subtitle: "ORIGINAL EDITION")
                }
                VStack(alignment: .leading, spacing: 16) {
                    Rectangle().fill(AppTheme.borderSubtle).frame(height: 1)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.seal")
                        VStack(alignment: .leading, spacing: 6) {
                            Text(maskedKeyText).font(.caption.monospaced())
                            Text(remainingTimeText).font(.footnote).foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer(minLength: 0)
                        Button("Đổi key") { licenseManager.logout(reason: "Vui lòng nhập Key mới") }
                            .font(.footnote).frame(minHeight: 44)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .foregroundStyle(.white)
        .sheet(isPresented: $showNextDNSSetup) { NextDNSSetupSheet() }
    }

    private func gameCard(isMax: Bool, number: String, subtitle: String) -> some View {
        Button { selectGame(bundleID: isMax ? "com.dts.freefiremax" : "com.dts.freefireth") } label: {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Text(number + " / " + subtitle)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .tracking(2).foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.system(size: 18, weight: .light))
                }
                HStack(spacing: 18) {
                    GameAppIconBadge(isMax: isMax, size: 68)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isMax ? "Free Fire MAX" : "Free Fire")
                            .font(.system(size: 24, weight: .semibold)).tracking(-0.7)
                        Text("Mở bảng điều khiển")
                            .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.darkSurfaceGradient, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(AppTheme.borderSubtle))
        }
        .buttonStyle(CardScaleButtonStyle())
        .accessibilityLabel("Chọn " + (isMax ? "Free Fire MAX" : "Free Fire"))
    }
    private func selectGame(bundleID: String) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        modManager.selectedBundle = bundleID
        YabaoCheatManager.shared.selectedGame = bundleID
        YabaoCheatManager.shared.checkInjectionState()
        DispatchQueue.global(qos: .userInitiated).async {
            ContainerStore.warmupAndActivateGameContainer(bundleID: bundleID)
        }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            onSelectGame(bundleID)
        }
    }
}
