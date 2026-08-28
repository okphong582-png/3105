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
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: isMax
                                        ? [Color.cyan, Color.purple]
                                        : [Color.orange, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: (isMax ? Color.purple : Color.orange).opacity(0.5),
                        radius: 10,
                        y: 3
                    )
            } else {
                // Vector fallback if image cannot be loaded
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isMax
                                ? [Color(red: 0.15, green: 0.08, blue: 0.25), Color(red: 0.08, green: 0.05, blue: 0.15)]
                                : [Color(red: 0.25, green: 0.12, blue: 0.04), Color(red: 0.12, green: 0.05, blue: 0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: isMax ? "bolt.shield.fill" : "flame.fill")
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundStyle(isMax ? Color.cyan : Color.orange)
                    )
            }
        }
    }
}

// MARK: - Game Selection View (2 Logo Giữa Màn Hình)
struct GameSelectionView: View {
    var onSelectGame: (String) -> Void

    @ObservedObject private var modManager = ModFeatureManager.shared

    var body: some View {
        ZStack {
            // Dark Obsidian Ambient Background
            Color(red: 0.04, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            // Glowing Ambient Lights
            VStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: -80, y: -60)

                Spacer()

                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: 80, y: 60)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Brand
                    VStack(spacing: 8) {
                        AppLogo(size: 68)
                            .shadow(color: Color.cyan.opacity(0.5), radius: 14)

                        Text("ONIAKUMA INJECTOR")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(red: 0.0, green: 0.85, blue: 1.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .tracking(2.0)

                        Text("Hệ Thống Hỗ Trợ Độc Quyền • HoangHaMod & TrongKien")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // Title Instruction
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("CHỌN PHIÊN BẢN GAME")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                                .tracking(1.0)
                        }

                        Text("Chọn đúng game bạn đang cài trên máy để kích hoạt chính xác")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // 2 LOGO GIỮA MÀN HÌNH (FREE FIRE THƯỜNG & MAX)
                    VStack(spacing: 16) {
                        // LOGO 1: FREE FIRE THƯỜNG
                        gameSelectCard(
                            isMax: false,
                            title: "Free Fire",
                            subtitle: "com.dts.freefireth",
                            badgeText: "BẢN GARENA THƯỜNG",
                            accentColor: Color.orange,
                            action: {
                                selectGame(bundleID: "com.dts.freefireth")
                            }
                        )

                        // LOGO 2: FREE FIRE MAX
                        gameSelectCard(
                            isMax: true,
                            title: "Free Fire MAX",
                            subtitle: "com.dts.freefiremax",
                            badgeText: "BẢN ĐỒ HỌA CAO CẤP",
                            accentColor: Color(red: 0.65, green: 0.35, blue: 1.0),
                            action: {
                                selectGame(bundleID: "com.dts.freefiremax")
                            }
                        )
                    }
                    .padding(.horizontal, 4)

                    // Support Contacts
                    HStack(spacing: 10) {
                        Link(destination: URL(string: "https://zalo.me/0866445455")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                Text("Zalo: 0866445455")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.85).cornerRadius(8))
                        }

                        Link(destination: URL(string: "https://zalo.me/0826794943")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                Text("Zalo: 0826794943")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.85).cornerRadius(8))
                        }

                        Link(destination: URL(string: "https://t.me/+1fstsksh_dMxNjE1")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                Text("Telegram")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.15).cornerRadius(8))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
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

    @ViewBuilder
    private func gameSelectCard(
        isMax: Bool,
        title: String,
        subtitle: String,
        badgeText: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Real Game App Logo Badge
                GameAppIconBadge(isMax: isMax, size: 84)

                // Game Info Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(badgeText)
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.16))
                            .cornerRadius(5)

                        Spacer()

                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(accentColor)
                    }

                    Text(title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Bấm để kích hoạt bản này")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                    .padding(.top, 2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor.opacity(0.8), accentColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8
                    )
                    .shadow(color: accentColor.opacity(0.35), radius: 10)
            )
        }
        .buttonStyle(.plain)
    }
}
