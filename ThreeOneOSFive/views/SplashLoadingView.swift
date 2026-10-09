import SwiftUI
import UIKit

// MARK: - Màn Hình Loading App Siêu VIP Pro Max (Splash Screen)
struct SplashLoadingView: View {
    var onFinish: () -> Void

    @State private var pulseGlow: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var statusIndex: Int = 0
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.90
    @State private var rotationAngle: Double = 0.0

    // Bảng màu Tím Neon Cyber VIP PRO MAX
    private let purplePrimary = Color(red: 0.72, green: 0.35, blue: 1.0)
    private let magentaAccent = Color(red: 0.92, green: 0.28, blue: 0.95)
    private let deepBackground = Color(red: 0.03, green: 0.02, blue: 0.06)

    private let statusMessages = [
        "Khởi tạo hệ thống bảo mật Mach-O...",
        "Đồng bộ In-Memory Vault chống dịch ngược...",
        "Tối ưu hóa môi trường Sandbox Free Fire...",
        "Hệ thống VIP Pro Max đã sẵn sàng!"
    ]

    var body: some View {
        ZStack {
            // Nền Đen Tím Deep Space Sang Trọng
            deepBackground
                .ignoresSafeArea()

            // Hiệu ứng ánh sáng nền đa tầng (Radial Ambient Glow)
            ZStack {
                RadialGradient(
                    colors: [
                        purplePrimary.opacity(pulseGlow ? 0.30 : 0.14),
                        magentaAccent.opacity(pulseGlow ? 0.15 : 0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 320
                )
                .ignoresSafeArea()

                // Tia sáng xoay nhẹ tinh tế
                AngularGradient(
                    gradient: Gradient(colors: [
                        purplePrimary.opacity(0.08),
                        Color.clear,
                        magentaAccent.opacity(0.08),
                        Color.clear,
                        purplePrimary.opacity(0.08)
                    ]),
                    center: .center
                )
                .rotationEffect(.degrees(rotationAngle))
                .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseGlow)

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo Ở Giữa Siêu VIP (Ảnh 6212775768715106594)
                VStack(spacing: 24) {
                    ZStack {
                        // Vòng hào quang phát sáng ngoài
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        purplePrimary.opacity(pulseGlow ? 0.45 : 0.20),
                                        magentaAccent.opacity(pulseGlow ? 0.25 : 0.08),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseGlow ? 1.15 : 0.95)

                        // Vòng viền xoay năng lượng neon
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [purplePrimary, magentaAccent, Color.clear, purplePrimary]),
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 142, height: 142)
                            .rotationEffect(.degrees(rotationAngle))

                        // Logo Chính Bo Góc Siêu Đẹp
                        AppLogo(size: 116)
                            .shadow(color: purplePrimary.opacity(0.8), radius: 20, x: 0, y: 0)
                            .shadow(color: magentaAccent.opacity(0.5), radius: 30, x: 0, y: 0)
                    }

                    // Tên Thương Hiệu & Thông Tin Developer
                    VStack(spacing: 10) {
                        Text("VIP PRO MAX")
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(red: 0.90, green: 0.80, blue: 1.0), purplePrimary],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: purplePrimary.opacity(0.7), radius: 10, x: 0, y: 2)

                        // Badge Developer VIP (Zalo 0865979853 • Tele @zwicka1)
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.yellow)

                            Text("DEV: @zwicka1 • ZALO: 0865979853")
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white)

                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(purplePrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.08, green: 0.06, blue: 0.14).opacity(0.95))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [purplePrimary.opacity(0.8), magentaAccent.opacity(0.5)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1.2
                                        )
                                )
                        )
                        .shadow(color: purplePrimary.opacity(0.3), radius: 8, y: 2)
                    }
                }

                Spacer()

                // MARK: - Thanh Loading Công Nghệ Cao (Progress Bar)
                VStack(spacing: 12) {
                    // Dòng trạng thái hệ thống
                    Text(statusMessages[min(statusIndex, statusMessages.count - 1)])
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(height: 18)
                        .transition(.opacity)

                    // Cyber Neon Progress Bar
                    ZStack(alignment: .leading) {
                        // Nền thanh tiến trình
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 250, height: 6)

                        // Vạch tiến trình tím neon
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [purplePrimary, magentaAccent, Color.white],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, 250 * progress), height: 6)
                            .shadow(color: purplePrimary.opacity(0.9), radius: 8, x: 0, y: 0)
                            .shadow(color: magentaAccent.opacity(0.7), radius: 12, x: 0, y: 0)
                    }

                    // Số phần trăm hiển thị
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(purplePrimary)
                        .padding(.top, 2)
                }
                .padding(.bottom, 50)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            Task {
                await LicenseManager.shared.recheckLicense()
            }
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        // Fade in mượt mà
        withAnimation(.easeOut(duration: 0.45)) {
            opacity = 1.0
            scale = 1.0
        }
        pulseGlow = true

        // Xoay tia sáng nhẹ
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Chạy thanh tiến trình từ 0% -> 100% trong khoảng 1.8 giây
        Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.018
                if progress >= 0.28 && statusIndex == 0 {
                    withAnimation { statusIndex = 1 }
                } else if progress >= 0.60 && statusIndex == 1 {
                    withAnimation { statusIndex = 2 }
                } else if progress >= 0.92 && statusIndex == 2 {
                    withAnimation { statusIndex = 3 }
                }
            } else {
                progress = 1.0
                timer.invalidate()

                // Kết thúc và chuyển tiếp vào app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        opacity = 0.0
                        scale = 1.05
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onFinish()
                    }
                }
            }
        }
    }
}
