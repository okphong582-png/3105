import SwiftUI
import UIKit

struct VPNBlockedView: View {
    @ObservedObject private var vpnGuard = VPNGuardService.shared

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                        .frame(width: 120, height: 120)

                    Image(systemName: "shield.slash.fill")
                        .font(.system(size: 54, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(spacing: 12) {
                    Text("PHÁT HIỆN VPN / PROXY")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Để đảm bảo tính bảo mật và chống crack, hệ thống không cho phép truy cập khi thiết bị đang bật VPN hoặc Proxy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Text("Vui lòng TẮT VPN / Proxy trong phần Cài Đặt của iPhone/iPad và bấm thử lại.")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        _ = vpnGuard.checkVPN()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.headline)
                            Text("Kiểm Tra Lại")
                                .font(.headline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.red.opacity(0.4), radius: 10, y: 4)
                    }

                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Mở Cài Đặt Hệ Thống")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 10)

                Spacer()

                VStack(spacing: 4) {
                    Text("Hệ Thống Bảo Mật OniAkuma Anti-Tamper")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("Exploit Kernel By OniAkuma")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary.opacity(0.4))
                }
                .padding(.bottom, 20)
            }
        }
    }
}
