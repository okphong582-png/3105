import SwiftUI
import UIKit

// MARK: - MultiLayer Security Gate View (Login Key & Pass Key)
struct MultiLayerSecurityGateView: View {
    @ObservedObject var securityService = MultiLayerSecurityService.shared
    @ObservedObject var licenseManager = LicenseManager.shared
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"

    @State private var inputKey = ""
    @State private var inputPassword = ""
    @State private var isPasswordVisible = false
    @State private var showHWIDCopied = false
    @State private var showLinkCopiedToast = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case key, password
    }

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()

            // Ambient background glows
            VStack {
                Circle()
                    .fill(activeTheme.primaryColor.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(y: -80)
                Spacer()
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(y: 80)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Brand
                    VStack(spacing: 8) {
                        AppLogo(size: 68)

                        Text("ONIAKUMA VIP SECURITY")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(activeTheme.primaryColor)
                            .tracking(2.0)

                        Text("Hệ thống bảo vệ bản quyền độc quyền • HoangHaMod & TrongKien")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        // Admin Contact Buttons
                        HStack(spacing: 8) {
                            Link(destination: URL(string: "https://zalo.me/0866445455")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "phone.fill")
                                    Text("Zalo: 0866445455")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.85).cornerRadius(8))
                            }

                            Link(destination: URL(string: "https://zalo.me/0826794943")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "phone.fill")
                                    Text("Zalo: 0826794943")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.blue.opacity(0.85).cornerRadius(8))
                            }

                            Link(destination: URL(string: "https://t.me/+1fstsksh_dMxNjE1")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Telegram")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(activeTheme.primaryColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(activeTheme.primaryColor.opacity(0.15).cornerRadius(8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.top, 12)

                    // Card Vượt Link Lấy Key Miễn Phí
                    bypassLinkCard

                    // Card Đăng Nhập: Key & Pass Key
                    loginCredentialsCard

                    // Kho Key Vượt Link Hệ Thống
                    bypassKeyWarehouseCard

                    // HWID Copy helper
                    hwidFooter

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            Task {
                _ = await licenseManager.checkSystemMaintenance()
                await licenseManager.fetchBypassKeys()
            }
        }
    }

    // MARK: - Bypass Link Card
    private var bypassLinkCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Button 1: Mở link vượt trên Safari
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .medium)
                    gen.impactOccurred()
                    licenseManager.openBypassLink()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("MỞ LINK VƯỢT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(12)
                    )
                    .shadow(color: Color.orange.opacity(0.35), radius: 6, y: 2)
                }

                // Button 2: Sao chép link để vượt
                Button {
                    let linkToCopy = licenseManager.bypassLink.isEmpty ? "https://link4m.co" : licenseManager.bypassLink
                    UIPasteboard.general.string = linkToCopy
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                    showLinkCopiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showLinkCopiedToast = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showLinkCopiedToast ? "checkmark.circle.fill" : "doc.on.doc.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(showLinkCopiedToast ? "ĐÃ SAO CHÉP!" : "CHÉP LINK VƯỢT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(showLinkCopiedToast ? Color.green : Color.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.orange.opacity(0.14).cornerRadius(12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showLinkCopiedToast ? Color.green : Color.orange.opacity(0.5), lineWidth: 1.2)
                    )
                }
            }

            if showLinkCopiedToast {
                Text("✅ Đã sao chép link vượt! Dán vào Safari/Chrome để vượt link lấy key.")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.green)
                    .multilineTextAlignment(.center)
            } else {
                Text("Vượt link nhanh nhận ngay Key miễn phí 100% (Mở khóa Aim Bot & Định Vị)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.orange.opacity(0.85))
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Login Credentials Card (2 Ô: Key & Pass Key)
    private var loginCredentialsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(activeTheme.primaryColor)
                Text("XÁC THỰC BẢN QUYỀN (KEY & PASS KEY)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Ô 1: Nhập License Key
            VStack(alignment: .leading, spacing: 4) {
                Text("MÃ LICENSE KEY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(focusedField == .key ? activeTheme.primaryColor : .secondary)

                    TextField("Nhập mã key (PRO, LITE, PASS)...", text: $inputKey)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: .key)

                    if !inputKey.isEmpty {
                        Button { inputKey = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }

                    // Nút dán nhanh
                    Button {
                        if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                            inputKey = clip.uppercased()
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                        }
                    } label: {
                        Text("Dán")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(activeTheme.primaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(activeTheme.primaryColor.opacity(0.12).cornerRadius(6))
                    }
                }
                .padding(11)
                .background(Color.black.opacity(0.4).cornerRadius(12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .key ? activeTheme.primaryColor : Color.white.opacity(0.1), lineWidth: 1)
                )
            }

            // Ô 2: Nhập Pass Key (Mật khẩu Key)
            VStack(alignment: .leading, spacing: 4) {
                Text("MẬT KHẨU CỦA KEY (PASS KEY)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(focusedField == .password ? activeTheme.primaryColor : .secondary)

                    if isPasswordVisible {
                        TextField("Nhập mật khẩu của key...", text: $inputPassword)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .password)
                    } else {
                        SecureField("Nhập mật khẩu của key...", text: $inputPassword)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .focused($focusedField, equals: .password)
                    }

                    // Toggle Ẩn / Hiện Pass
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }

                    // Nút dán pass
                    Button {
                        if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                            inputPassword = clip
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                        }
                    } label: {
                        Text("Dán")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(activeTheme.primaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(activeTheme.primaryColor.opacity(0.12).cornerRadius(6))
                    }
                }
                .padding(11)
                .background(Color.black.opacity(0.4).cornerRadius(12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? activeTheme.primaryColor : Color.white.opacity(0.1), lineWidth: 1)
                )
            }

            // Error message
            if let err = licenseManager.lastErrorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(err)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
            }

            // Nút Xác Thực Đăng Nhập
            Button {
                focusedField = nil
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()

                Task {
                    let res = await licenseManager.activateKey(inputKey, enteredPassword: inputPassword)
                    if res.success {
                        await MainActor.run {
                            securityService.isFullyUnlocked = true
                            let notif = UINotificationFeedbackGenerator()
                            notif.notificationOccurred(.success)
                        }
                    } else {
                        let notif = UINotificationFeedbackGenerator()
                        notif.notificationOccurred(.error)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if licenseManager.isVerifying {
                        ProgressView().tint(.black)
                        Text("ĐANG XÁC THỰC...")
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                        Text("KÍCH HOẠT VÀO APP")
                    }
                }
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [activeTheme.primaryColor, Color(red: 0.2, green: 0.9, blue: 0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: activeTheme.primaryColor.opacity(0.4), radius: 8, y: 3)
            }
            .disabled(licenseManager.isVerifying || inputKey.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1.2)
        )
    }

    // MARK: - Bypass Key Warehouse Card (Kho Key Vượt Link)
    private var bypassKeyWarehouseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(Color.orange)
                    Text("KHO KEY VƯỢT LINK HỆ THỐNG")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.orange)
                }

                Spacer()

                Button {
                    Task { await licenseManager.fetchBypassKeys() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Làm mới")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(activeTheme.primaryColor)
                }
            }

            if licenseManager.isLoadingBypassKeys {
                HStack {
                    Spacer()
                    ProgressView().tint(Color.orange)
                    Text("Đang kiểm tra kho key...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 6)
            } else if licenseManager.bypassKeys.isEmpty {
                Text("Chưa có key vượt link có sẵn. Hãy bấm Vượt Link để nhận key mới nhất!")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(licenseManager.bypassKeys.prefix(4)), id: \.key) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.key)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                if let pass = item.password, !pass.isEmpty {
                                    Text("Pass: \(pass)")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Color.yellow)
                                }
                            }

                            Spacer()

                            Button {
                                inputKey = item.key
                                if let pass = item.password {
                                    inputPassword = pass
                                }
                                let gen = UIImpactFeedbackGenerator(style: .light)
                                gen.impactOccurred()
                            } label: {
                                Text("Dùng Key")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.cornerRadius(6))
                            }
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.04).cornerRadius(8))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - HWID Footer
    private var hwidFooter: some View {
        HStack {
            Text("HWID: \(licenseManager.deviceHWID.prefix(16))•••")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                UIPasteboard.general.string = licenseManager.deviceHWID
                let gen = UIImpactFeedbackGenerator(style: .light)
                gen.impactOccurred()
                showHWIDCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showHWIDCopied = false }
            } label: {
                Text(showHWIDCopied ? "Đã chép" : "Sao chép HWID")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(showHWIDCopied ? .green : activeTheme.primaryColor)
            }
        }
    }
}
