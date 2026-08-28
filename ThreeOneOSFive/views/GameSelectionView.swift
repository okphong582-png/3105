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
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
            } else {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(Color.black.opacity(0.3))
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
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Game Selection View (Chuẩn 100% Giao Diện Ảnh 2)
struct GameSelectionView: View {
    var onSelectGame: (String) -> Void

    @ObservedObject private var modManager = ModFeatureManager.shared
    @ObservedObject private var licenseManager = LicenseManager.shared

    @State private var showKeyDetails = false
    @State private var showChangeKeyConfirm = false

    private var maskedKeyText: String {
        guard let raw = licenseManager.currentLicense?.key, !raw.isEmpty else {
            return "KEY DEMO••••VIP"
        }
        let clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.count <= 8 {
            return "KEY \(clean)"
        }
        let start = String(clean.prefix(4))
        let end = String(clean.suffix(4))
        return "KEY \(start)••••\(end)"
    }

    private var remainingTimeText: String {
        guard let lic = licenseManager.currentLicense else {
            return "Chưa kích hoạt"
        }
        if lic.duration == "lifetime" || lic.durationSeconds == -1 || lic.expiresAt == -1 {
            return "Còn Vĩnh Viễn"
        }
        guard let exp = lic.expiresAt else {
            let h = lic.durationSeconds / 3600
            if h >= 24 {
                return "Còn \(h / 24) ngày (Chưa kích hoạt)"
            }
            return "Còn \(h) giờ (Chưa kích hoạt)"
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
            // Dark Obsidian Ambient Background
            Color(red: 0.04, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. TOP CARD: THÔNG TIN THIẾT BỊ (Y HỆT ẢNH 2)
                topDeviceInfoCard

                Spacer()

                // 2. HAI CARD GAME GIỮA MÀN HÌNH (MAX Ở TRÊN, THƯỜNG Ở DƯỚI)
                VStack(spacing: 20) {
                    // Card 1: Free Fire Max (Nửa trên Xanh Dương, nửa dưới Đen)
                    gameCard(
                        isMax: true,
                        title: "Free Fire Max",
                        subtitle: "com.dts.freefiremax",
                        topColor: Color(red: 0.05, green: 0.52, blue: 0.98),
                        borderColor: Color.blue,
                        action: {
                            selectGame(bundleID: "com.dts.freefiremax")
                        }
                    )

                    // Card 2: Free Fire Thường (Nửa trên Cam, nửa dưới Đen)
                    gameCard(
                        isMax: false,
                        title: "Free Fire Thường",
                        subtitle: "com.dts.freefireth",
                        topColor: Color(red: 1.0, green: 0.46, blue: 0.05),
                        borderColor: Color.orange,
                        action: {
                            selectGame(bundleID: "com.dts.freefireth")
                        }
                    )
                }

                Spacer()

                // 3. BOTTOM BAR: THÔNG TIN KEY + NÚT ĐỔI KEY (Y HỆT ẢNH 2)
                bottomKeyInfoBar
            }
        }
        .alert("Chi Tiết Bản Quyền", isPresented: $showKeyDetails) {
            Button("Đóng", role: .cancel) {}
        } message: {
            if let lic = licenseManager.currentLicense {
                Text("Mã Key: \(lic.key)\nThời hạn: \(lic.duration)\nTrạng thái: \(lic.status.uppercased())\nSố thiết bị: \(lic.usedDevices.count)/\(lic.maxDevices)\n\(remainingTimeText)")
            } else {
                Text("Chưa có thông tin bản quyền.")
            }
        }
        .confirmationDialog("Bạn có chắc chắn muốn đổi Key khác?", isPresented: $showChangeKeyConfirm, titleVisibility: .visible) {
            Button("Đổi Key (Đăng Xuất)", role: .destructive) {
                licenseManager.clearCachedLicense()
            }
            Button("Hủy", role: .cancel) {}
        }
    }

    // MARK: - 1. Top Device Info Card (Y hệt ảnh 2)
    private var topDeviceInfoCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.72, green: 0.45, blue: 0.98))
                    Text("iOS \(UIDevice.current.systemVersion)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                HStack(spacing: 8) {
                    Image(systemName: "iphone")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                    Text("Device \(UIDevice.current.model)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.09, green: 0.10, blue: 0.14).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - 2. Game Selection Card (Nửa trên Màu + Nửa dưới Đen)
    @ViewBuilder
    private func gameCard(
        isMax: Bool,
        title: String,
        subtitle: String,
        topColor: Color,
        borderColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Top Half: Màu khối nổi bật chứa Logo Game
                ZStack {
                    topColor
                    GameAppIconBadge(isMax: isMax, size: 66)
                }
                .frame(width: 250, height: 105)

                // Bottom Half: Nền đen sang trọng chứa Tên Game & Bundle ID
                VStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                .frame(width: 250, height: 85)
                .background(Color(red: 0.08, green: 0.09, blue: 0.12))
            }
            .frame(width: 250, height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(borderColor.opacity(0.45), lineWidth: 1.5)
            )
            .shadow(color: borderColor.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(CardScaleButtonStyle())
    }

    // MARK: - 3. Bottom Key Info Bar (Y hệt ảnh 2)
    private var bottomKeyInfoBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.4), Color.cyan.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 12) {
                // Chấm xanh phát sáng
                Circle()
                    .fill(Color(red: 0.15, green: 0.9, blue: 0.35))
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.green.opacity(0.8), radius: 6)

                // Thông tin Key & Thời Hạn
                VStack(alignment: .leading, spacing: 2) {
                    Text(maskedKeyText)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text(remainingTimeText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.4))
                }

                Spacer()

                // Nút Info (i)
                Button {
                    showKeyDetails = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white.opacity(0.65))
                }

                // Nút "Đổi Key" Xanh Cyan
                Button {
                    showChangeKeyConfirm = true
                } label: {
                    Text("Đổi Key")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.04, green: 0.10, blue: 0.22))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Color(red: 0.45, green: 0.72, blue: 1.0)
                                .cornerRadius(10)
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.95))
        }
    }

    private func selectGame(bundleID: String) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        modManager.selectedBundle = bundleID
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            onSelectGame(bundleID)
        }
    }
}
