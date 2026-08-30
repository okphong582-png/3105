import SwiftUI

struct NoInternetGateView: View {
    @ObservedObject private var networkService = NetworkReachabilityService.shared
    @State private var isPulsing = false
    @State private var isChecking = false

    var body: some View {
        ZStack {
            // Obsidian Black High-Tech Background
            Color(red: 0.04, green: 0.05, blue: 0.08)
                .ignoresSafeArea()

            // Ambient Warning Glows
            VStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Animated Radar Pulse Icon
                ZStack {
                    // Outer pulsing rings
                    Circle()
                        .stroke(Color.orange.opacity(isPulsing ? 0.0 : 0.4), lineWidth: 1.5)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isPulsing ? 1.4 : 0.8)

                    Circle()
                        .stroke(Color.red.opacity(isPulsing ? 0.1 : 0.5), lineWidth: 1.5)
                        .frame(width: 110, height: 110)
                        .scaleEffect(isPulsing ? 1.2 : 0.9)

                    // Center Glass Hexagon Badge
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.12, blue: 0.16), Color(red: 0.08, green: 0.07, blue: 0.11)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.8), Color.red.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.4), radius: 20)

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(red: 1.0, green: 0.6, blue: 0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.6)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }

                // Title & Subtitle
                VStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.red, radius: 4)

                        Text("YÊU CẦU KẾT NỐI MẠNG")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.red)
                            .tracking(2.0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.12).cornerRadius(12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))

                    Text("Không Có Kết Nối Internet")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Ứng dụng cần kết nối Wi-Fi hoặc 4G/5G để xác thực mã bản quyền và bảo vệ hệ thống. Vui lòng bật mạng để tiếp tục sử dụng.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Recheck Action Button
                VStack(spacing: 12) {
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        isChecking = true
                        networkService.recheckNow()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isChecking = false
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isChecking {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .bold))
                            }

                            Text(isChecking ? "ĐANG KIỂM TRA..." : "THỬ LẠI KẾT NỐI")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .tracking(1.0)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.orange.opacity(0.4), radius: 12, y: 4)
                    }
                    .disabled(isChecking)

                    Text("Hệ thống sẽ tự động mở khoá ngay khi có mạng")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
