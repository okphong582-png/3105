import SwiftUI
import UIKit

// MARK: - Alias cho Menu Tính Năng VIP Pro Max
typealias FeatureMenuTabView = YabaoCheatTabView

// MARK: - Giao Diện Menu Tính Năng VIP Pro Max: 1 NÚT BẬT / TẮT DUY NHẤT
@MainActor
struct YabaoCheatTabView: View {
    @ObservedObject private var yabao = YabaoCheatManager.shared
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isAlertSuccess: Bool = true
    @State private var pulseAnimation: Bool = false

    // Bảng màu Tím VIP PRO MAX
    private let purplePrimary = Color(red: 0.72, green: 0.35, blue: 1.0)
    private let magentaAccent = Color(red: 0.90, green: 0.28, blue: 0.92)
    private let deepPurpleCard = Color(red: 0.08, green: 0.06, blue: 0.14).opacity(0.92)

    var body: some View {
        VStack(spacing: 16) {
            // 1. BRAND HEADER & TRẠNG THÁI
            brandHeaderCard

            // 2. CHỌN BẢN GAME (Free Fire Thường vs Free Fire MAX)
            gameSelectorCard

            // 3. MASTER POWER CARD: 1 NÚT BẬT / TẮT MENU DUY NHẤT (TIÊM 2 FILE)
            singleMasterToggleCard

            // 4. CARD THÔNG TIN 2 FILE PATCH ĐÃ MÃ HÓA CHỐNG TRỘM
            patchFileInfoCard

            Spacer(minLength: 16)
        }
        .onAppear {
            yabao.checkInjectionState()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isAlertSuccess ? "THÀNH CÔNG" : "THÔNG BÁO"),
                message: Text(alertMessage),
                dismissButton: .default(Text("ĐỒNG Ý"))
            )
        }
    }

    // MARK: - 1. Brand Header
    private var brandHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [purplePrimary.opacity(0.35), magentaAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, purplePrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: purplePrimary.opacity(0.9), radius: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("MENU TÍNH NĂNG")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Text("VIP PRO MAX")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            LinearGradient(
                                colors: [purplePrimary, magentaAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: purplePrimary.opacity(0.5), radius: 4)
                }

                Text("BẬT / TẮT 1 CHẠM DUY NHẤT • 2 FILE PATCH")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))
            }

            Spacer()

            // Status Indicator Badge (ONLINE / OFFLINE)
            HStack(spacing: 5) {
                Circle()
                    .fill(yabao.isOnline ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(yabao.isOnline && pulseAnimation ? 1.3 : 1.0)
                    .shadow(color: yabao.isOnline ? Color.green.opacity(0.8) : Color.clear, radius: 4)

                Text(yabao.isOnline ? "ONLINE" : "OFFLINE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(yabao.isOnline ? Color.green : Color.gray)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(yabao.isOnline ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(yabao.isOnline ? Color.green.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(deepPurpleCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [purplePrimary.opacity(0.5), magentaAccent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: purplePrimary.opacity(0.15), radius: 10, y: 3)
    }

    // MARK: - 2. Game Selector Card (FF Thường vs FF MAX)
    private var gameSelectorCard: some View {
        HStack(spacing: 8) {
            // Free Fire Thường
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    yabao.selectedGame = "com.dts.freefireth"
                    ModFeatureManager.shared.selectedBundle = "com.dts.freefireth"
                    yabao.checkInjectionState()
                }
            } label: {
                HStack(spacing: 8) {
                    GameAppIconBadge(isMax: false, size: 24)

                    Text("Free Fire Thường")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            yabao.selectedGame == "com.dts.freefireth"
                                ? LinearGradient(colors: [purplePrimary, magentaAccent], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(yabao.selectedGame == "com.dts.freefireth" ? purplePrimary : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: yabao.selectedGame == "com.dts.freefireth" ? purplePrimary.opacity(0.4) : Color.clear, radius: 8)
            }
            .buttonStyle(.plain)

            // Free Fire MAX
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    yabao.selectedGame = "com.dts.freefiremax"
                    ModFeatureManager.shared.selectedBundle = "com.dts.freefiremax"
                    yabao.checkInjectionState()
                }
            } label: {
                HStack(spacing: 8) {
                    GameAppIconBadge(isMax: true, size: 24)

                    Text("Free Fire MAX")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            yabao.selectedGame == "com.dts.freefiremax"
                                ? LinearGradient(colors: [purplePrimary, magentaAccent], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(yabao.selectedGame == "com.dts.freefiremax" ? purplePrimary : Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: yabao.selectedGame == "com.dts.freefiremax" ? purplePrimary.opacity(0.4) : Color.clear, radius: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(red: 0.05, green: 0.04, blue: 0.09).opacity(0.85))
        )
    }

    // MARK: - 3. Master Power Card: 1 NÚT BẬT / TẮT DUY NHẤT
    private var singleMasterToggleCard: some View {
        VStack(spacing: 18) {
            // Icon lớn trung tâm với hiệu ứng phát sáng đa tầng
            ZStack {
                // Aura phát sáng phía sau
                Circle()
                    .fill(
                        RadialGradient(
                            colors: yabao.isOnline
                                ? [purplePrimary.opacity(0.4), magentaAccent.opacity(0.1), Color.clear]
                                : [Color.white.opacity(0.05), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(yabao.isOnline && pulseAnimation ? 1.08 : 0.98)

                // Vòng tròn nút chính
                Circle()
                    .fill(
                        yabao.isOnline
                            ? LinearGradient(colors: [purplePrimary, magentaAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 86, height: 86)
                    .overlay(
                        Circle()
                            .stroke(
                                yabao.isOnline
                                    ? Color.white.opacity(0.8)
                                    : purplePrimary.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: yabao.isOnline ? purplePrimary.opacity(0.7) : Color.clear, radius: 16)

                // Biểu tượng bên trong
                if yabao.isInjecting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                } else {
                    Image(systemName: yabao.isOnline ? "checkmark.shield.fill" : "power")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 4)
                }
            }
            .padding(.top, 4)

            // Tiêu đề trạng thái
            VStack(spacing: 4) {
                Text(yabao.isOnline ? "TÍNH NĂNG ĐANG BẬT" : "TÍNH NĂNG ĐANG TẮT")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        yabao.isOnline
                            ? LinearGradient(colors: [Color.white, purplePrimary], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                    )

                Text(yabao.isOnline ? "2 tệp patch đã được tiêm vào game • Sẵn sàng chiến đấu" : "Chạm nút bên dưới để tiêm 2 file patch vào Documents")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // NÚT BẬT / TẮT DUY NHẤT (Single Big Action Button)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
                Task {
                    let (success, msg) = await yabao.toggleFeature()
                    alertMessage = msg
                    isAlertSuccess = success
                    showAlert = true
                }
            } label: {
                HStack(spacing: 10) {
                    if yabao.isInjecting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: yabao.isOnline ? "power.circle.fill" : "bolt.fill")
                            .font(.system(size: 17, weight: .black))
                    }

                    Text(
                        yabao.isInjecting
                            ? "ĐANG XỬ LÝ..."
                            : (yabao.isOnline ? "TẮT TÍNH NĂNG (GỠ PATCH)" : "BẬT TÍNH NĂNG (TIÊM PATCH)")
                    )
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .tracking(1.0)
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(
                            yabao.isOnline
                                ? LinearGradient(colors: [Color(red: 0.60, green: 0.15, blue: 0.45), Color(red: 0.40, green: 0.10, blue: 0.35)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [purplePrimary, magentaAccent], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(
                            yabao.isOnline
                                ? Color.white.opacity(0.2)
                                : Color.white.opacity(0.5),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: yabao.isOnline ? Color.clear : purplePrimary.opacity(0.6), radius: 14, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(yabao.isInjecting)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(deepPurpleCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [purplePrimary.opacity(yabao.isOnline ? 0.6 : 0.25), magentaAccent.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: yabao.isOnline ? 1.5 : 1
                )
        )
        .shadow(color: yabao.isOnline ? purplePrimary.opacity(0.25) : Color.clear, radius: 16)
    }

    // MARK: - 4. Thông Tin 2 File Patch Đã Mã Hóa Chống Trộm
    private var patchFileInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(purplePrimary)

                Text("THÔNG TIN 2 TỆP PATCH TIÊM VÀO DOCUMENTS")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)

                Spacer()

                Text("IN-MEMORY VAULT")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(purplePrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(purplePrimary.opacity(0.15)))
            }

            VStack(spacing: 7) {
                fileRow(
                    name: "Assembly-CSharp-patch.bytes",
                    size: "53,235 Bytes",
                    detail: "File Hook Engine Chuẩn",
                    isActive: yabao.isOnline
                )

                fileRow(
                    name: "localConfig.json",
                    size: "84 Bytes",
                    detail: "_ffxc_session & testCodePatch",
                    isActive: yabao.isOnline
                )
            }

            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.green)
                Text("Dữ liệu mã hóa nhúng trong mã máy Mach-O, chống trộm 100% khi giải nén IPA")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.06, green: 0.04, blue: 0.11).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(purplePrimary.opacity(0.18), lineWidth: 1)
        )
    }

    private func fileRow(name: String, size: String, detail: String, isActive: Bool) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isActive ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)

                Text(detail)
                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            Text(size)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(purplePrimary)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
    }
}
