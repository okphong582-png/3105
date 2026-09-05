import SwiftUI
import UIKit

struct NextDNSSetupSheet: View {
    @ObservedObject var nextDNSService = NextDNSInstallerService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var pulseAnimation: Bool = false
    @State private var downloaded: Bool = false

    var onFinish: (() -> Void)?

    var body: some View {
        ZStack {
            // Dark Futuristic Canvas
            Color(red: 0.04, green: 0.05, blue: 0.08).ignoresSafeArea()

            // Ambient Glows
            VStack {
                Circle()
                    .fill(RadialGradient(colors: [Color.green.opacity(0.16), Color.clear], center: .center, startRadius: 20, endRadius: 160))
                    .frame(width: 320, height: 320)
                    .blur(radius: 50)
                    .offset(y: -80)
                Spacer()
            }

            VStack(spacing: 22) {
                // Header Indicator Bar
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 44, height: 5)
                    .padding(.top, 12)

                Spacer(minLength: 8)

                // Shield Icon with Radar Rings
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 104, height: 104)
                        .scaleEffect(pulseAnimation ? 1.18 : 0.95)
                        .opacity(pulseAnimation ? 0.4 : 0.8)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.08, green: 0.28, blue: 0.16), Color(red: 0.03, green: 0.12, blue: 0.07)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 84, height: 84)
                        .overlay(Circle().stroke(Color.green.opacity(0.6), lineWidth: 2))
                        .shadow(color: Color.green.opacity(0.4), radius: 14)

                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.green],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Title & Badge
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Text("NEXTDNS ANTIBAN")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)

                        Text("VIP")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.cornerRadius(4))
                    }

                    Text("Hồ sơ bảo vệ chống khóa tài khoản, chặn máy chủ phát hiện của game.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Step Instructions Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.2)).frame(width: 26, height: 26)
                            Text("1").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Color.green)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tải về NextDNS.mobileconfig")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("Nhấn nút tải và chọn Cho phép tải về hồ sơ cấu hình.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(Color.cyan.opacity(0.2)).frame(width: 26, height: 26)
                            Text("2").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Color.cyan)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kích hoạt trong Cài đặt iPhone")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.white)
                            Text("Mở Cài đặt > Đã tải về hồ sơ > Nhấn Cài đặt để kích hoạt.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
                .padding(.horizontal, 20)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // Button 1: Tải về NextDNS.mobileconfig
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            downloaded = true
                        }
                        nextDNSService.downloadAndInstallProfile()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: downloaded ? "checkmark.circle.fill" : "arrow.down.doc.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(downloaded ? "TẢI LẠI NEXTDNS.MOBILECONFIG" : "TẢI VỀ NEXTDNS.MOBILECONFIG")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(downloaded ? Color.white : Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            downloaded
                                ? LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.green, Color(red: 0.2, green: 0.9, blue: 0.5)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(downloaded ? Color.white.opacity(0.2) : Color.green.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: downloaded ? Color.clear : Color.green.opacity(0.35), radius: 10, y: 3)
                    }

                    // Button 2: BẠN ĐÃ SETUP XONG ? VÔ CHƠI
                    if downloaded || nextDNSService.hasDownloadedProfile {
                        Button {
                            nextDNSService.completeSetup()
                            onFinish?()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 16, weight: .black))
                                Text("BẠN ĐÃ SETUP XONG ? VÔ CHƠI")
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                            }
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.cyan, Color(red: 0.1, green: 0.8, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.cyan.opacity(0.9), lineWidth: 1.2)
                            )
                            .shadow(color: Color.cyan.opacity(0.4), radius: 12, y: 3)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Skip / Already installed button
                        Button {
                            nextDNSService.completeSetup()
                            onFinish?()
                            dismiss()
                        } label: {
                            Text("Tôi đã cài đặt NextDNS từ trước (Bỏ qua)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            if nextDNSService.hasDownloadedProfile {
                downloaded = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}
