import SwiftUI
import UIKit

// MARK: - Giao Diện Tab YABAO CHEAT (Chức Năng Y Hệt YABAOCHEAT.app)
struct YabaoCheatTabView: View {
    @StateObject private var yabao = YabaoCheatManager.shared
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isAlertSuccess: Bool = true
    @State private var radarPulse: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // 1. BRAND HEADER & TRẠNG THÁI (FFXC / YABAO PRIVATE EDITION)
            yabaoBrandHeaderCard

            // 2. CHỌN GAME (Free Fire Thường vs Free Fire MAX)
            gameSelectorCard

            // 3. CARD MỤC TIÊU NGẮM (AIM TARGET: HEAD / NECK / CHEST / BODY)
            aimTargetSelectionCard

            // 4. CARD TỈ LỆ GHIM ĐẦU & BÁN KÍNH FOV
            precisionAimSettingsCard

            // 5. NHÓM 1: AIMBOT & CHIẾN ĐẤU (AIM & COMBAT)
            aimbotFeaturesCard

            // 6. NHÓM 2: ĐỊNH VỊ & ESP XUYÊN TƯỜNG (ESP & X-RAY)
            espFeaturesCard

            // 7. NHÓM 3: TIỆN ÍCH & AN TOÀN RANK (EXTRA & SAFE)
            extraUtilitiesCard

            // 8. THANH THAO TÁC TIÊM & ĐẶT LẠI (BOTTOM INJECT BAR)
            bottomActionBar

            Spacer(minLength: 16)
        }
        .onAppear {
            yabao.checkInjectionState()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                radarPulse = true
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

    // MARK: - 1. Brand Header & Status
    private var yabaoBrandHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.cyan.opacity(0.8), radius: 6)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("YABAO CHEAT")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Text("PRIVATE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.cyan.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.5), lineWidth: 0.8))
                }

                Text("HỆ THỐNG ĐIỀU KHIỂN & BẬT TẮT CHỨC NĂNG")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            Spacer()

            // Status Indicator Badge (ONLINE / OFFLINE)
            HStack(spacing: 5) {
                Circle()
                    .fill(yabao.isOnline ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(yabao.isOnline && radarPulse ? 1.3 : 1.0)
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.5), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
                    yabao.checkInjectionState()
                }
            } label: {
                HStack(spacing: 8) {
                    Image("ffth")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("Free Fire Thường")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(yabao.selectedGame == "com.dts.freefireth" ? Color.black : Color.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            yabao.selectedGame == "com.dts.freefireth"
                                ? LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(yabao.selectedGame == "com.dts.freefireth" ? Color.orange : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Free Fire MAX
            Button {
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    yabao.selectedGame = "com.dts.freefiremax"
                    yabao.checkInjectionState()
                }
            } label: {
                HStack(spacing: 8) {
                    Image("ffmax")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text("Free Fire MAX")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(yabao.selectedGame == "com.dts.freefiremax" ? Color.black : Color.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            yabao.selectedGame == "com.dts.freefiremax"
                                ? LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.02)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(yabao.selectedGame == "com.dts.freefiremax" ? Color.cyan : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.8))
        )
    }

    // MARK: - 3. Aim Target Selection Card (AimTargetRow)
    private var aimTargetSelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.red)

                Text("VỊ TRÍ GHIM TÂM (AIM TARGET)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white)

                Spacer()

                Text(yabao.aimTarget.englishTitle)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.red.opacity(0.15)))
            }

            // Grid 4 nút: ĐẦU, CỔ, NGỰC, THÂN
            HStack(spacing: 8) {
                ForEach(YabaoAimTarget.allCases) { target in
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            yabao.aimTarget = target
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: target.iconName)
                                .font(.system(size: 14, weight: .bold))

                            Text(target.title)
                                .font(.system(size: 10.5, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(yabao.aimTarget == target ? Color.white : Color.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    yabao.aimTarget == target
                                        ? LinearGradient(colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(yabao.aimTarget == target ? Color.red.opacity(0.9) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: yabao.aimTarget == target ? Color.red.opacity(0.4) : Color.clear, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 4. Precision Aim Settings (HeadshotRateRow & FOVRadiusRow)
    private var precisionAimSettingsCard: some View {
        VStack(spacing: 12) {
            // Tỉ lệ Headshot
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.orange)

                    Text("TỈ LỆ GHIM ĐẦU (HEADSHOT RATE)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Text("\(Int(yabao.headshotRate))%")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.orange)
                }

                Slider(value: $yabao.headshotRate, in: 50...100, step: 5)
                    .tint(Color.orange)

                HStack(spacing: 8) {
                    ForEach([50, 80, 100], id: \.self) { val in
                        Button {
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                            withAnimation {
                                yabao.headshotRate = Double(val)
                            }
                        } label: {
                            Text("\(val)%")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Int(yabao.headshotRate) == val ? Color.black : Color.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                                .background(
                                    Capsule().fill(Int(yabao.headshotRate) == val ? Color.orange : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.08))

            // Bán kính FOV
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.cyan)

                    Text("BÁN KÍNH QUÉT FOV (RADIUS)")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Text("\(Int(yabao.fovRadius))m")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                }

                Slider(value: $yabao.fovRadius, in: 30...120, step: 5)
                    .tint(Color.cyan)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 5. Aimbot Features Card (Nhóm 1)
    private var aimbotFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(title: "AIMBOT & TRỢ CHIẾN", icon: "scope", color: Color.red)

            VStack(spacing: 6) {
                featureToggleRow(title: "Tự Động Khóa Tâm", subtitle: "Tự bắt mục tiêu khi lia tâm gần đối thủ", icon: "lock.shield", isOn: $yabao.isAutoAimLock, color: Color.red)
                featureToggleRow(title: "Kéo Tâm Nhạy Siêu Tốc", subtitle: "Trợ lực vuốt tâm mượt mà, gạt nhẹ là trúng", icon: "arrow.up.forward.circle", isOn: $yabao.isAimDragSensi, color: Color.red)
                featureToggleRow(title: "Ghim Đầu Chuẩn (Auto Head)", subtitle: "Điều hướng đạn thẳng vào vùng đầu", icon: "target", isOn: $yabao.isAutoHeadshot, color: Color.red)
                featureToggleRow(title: "Bắn Không Rung (No Recoil)", subtitle: "Triệt tiêu độ giật và độ rung của súng", icon: "bolt.shield", isOn: $yabao.isNoRecoil, color: Color.red)
                featureToggleRow(title: "Hiển Thị Vòng FOV", subtitle: "Vòng tròn giới hạn vùng quét mục tiêu", icon: "circle", isOn: $yabao.isAimFovCircle, color: Color.red)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 6. ESP Features Card (Nhóm 2)
    private var espFeaturesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(title: "ĐỊNH VỊ & ESP XUYÊN TƯỜNG", icon: "eye.trianglebadge.exclamationmark", color: Color.cyan)

            VStack(spacing: 6) {
                featureToggleRow(title: "ESP Khung Địch (Box 2D/3D)", subtitle: "Đóng khung chữ nhật hiển thị quanh người địch", icon: "viewfinder", isOn: $yabao.isEspBox, color: Color.cyan)
                featureToggleRow(title: "ESP Đường Kẻ (Line)", subtitle: "Đường thẳng nối từ tâm hoặc đỉnh đầu tới địch", icon: "line.diagonal", isOn: $yabao.isEspLine, color: Color.cyan)
                featureToggleRow(title: "ESP Khoảng Cách (Distance)", subtitle: "Hiển thị cự ly (mét) chính xác từng mili-giây", icon: "ruler", isOn: $yabao.isEspDistance, color: Color.cyan)
                featureToggleRow(title: "ESP Thanh Máu & Giáp", subtitle: "Theo dõi lượng máu và trang bị của đối phương", icon: "cross.fill", isOn: $yabao.isEspHealthBar, color: Color.cyan)
                featureToggleRow(title: "ESP X-Ray Chams Xuyên Tường", subtitle: "Tô màu nhân vật nổi bật xuyên qua vật cản", icon: "person.fill.viewfinder", isOn: $yabao.isEspChamsXray, color: Color.cyan)
                featureToggleRow(title: "Mini Radar 2D 360°", subtitle: "Quét chấm định vị kẻ địch xung quanh bản đồ", icon: "dot.radiowaves.left.and.right", isOn: $yabao.isMiniRadar2D, color: Color.cyan)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 7. Extra Utilities Card (Nhóm 3)
    private var extraUtilitiesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(title: "TIỆN ÍCH & AN TOÀN RANK", icon: "shield.checkerboard", color: Color.green)

            VStack(spacing: 6) {
                featureToggleRow(title: "Xóa Cỏ & Sương Mù", subtitle: "Tối ưu hóa tầm nhìn thông thoáng khắp bản đồ", icon: "leaf.arrow.triangle.circlepath", isOn: $yabao.isNoGrassFog, color: Color.green)
                featureToggleRow(title: "Tăng Tốc Đạn (Fast Bullet)", subtitle: "Rút ngắn thời gian đạn bay chạm đích", icon: "bolt.fill", isOn: $yabao.isFastBullet, color: Color.green)
                featureToggleRow(title: "Anti-Ban Safe Guard", subtitle: "Che giấu chữ ký bộ nhớ và tránh bị quét hệ thống", icon: "shield.lefthalf.filled", isOn: $yabao.isAntiBanSafe, color: Color.green)
                featureToggleRow(title: "Chế Độ An Toàn Leo Rank", subtitle: "Cân bằng thông số tự nhiên, hạn chế bị report", icon: "star.shield", isOn: $yabao.isSafeRankMode, color: Color.green)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 8. Bottom Action Bar (INJECT & RESET)
    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            // Nút TIÊM CHỨC NĂNG (INJECT)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
                Task {
                    let (success, msg) = await yabao.injectFeatures()
                    alertMessage = msg
                    isAlertSuccess = success
                    showAlert = true
                }
            } label: {
                HStack(spacing: 10) {
                    if yabao.isInjecting {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "syringe.fill")
                            .font(.system(size: 16, weight: .black))
                    }

                    Text(yabao.isInjecting ? "ĐANG TIÊM CẤU HÌNH..." : "TIÊM CHỨC NĂNG (INJECT)")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.95, blue: 0.6), Color(red: 0.0, green: 0.7, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.0, green: 0.95, blue: 0.6).opacity(0.4), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(yabao.isInjecting)

            // Nút ĐẶT LẠI (RESET)
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                Task {
                    let (success, msg) = await yabao.resetFeatures()
                    alertMessage = msg
                    isAlertSuccess = success
                    showAlert = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))

                    Text("ĐẶT LẠI CÀI ĐẶT GỐC (RESET)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.white.opacity(0.75))
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper Components
    private func cardHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 11.5, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)

            Spacer()
        }
    }

    private func featureToggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isOn.wrappedValue ? color : Color.white.opacity(0.4))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)

                Text(subtitle)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}
