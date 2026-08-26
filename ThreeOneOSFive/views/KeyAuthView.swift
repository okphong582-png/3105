import SwiftUI
import UIKit

struct KeyAuthView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @State private var inputKey = ""
    @State private var showSuccessToast = false
    @State private var successToastMessage = ""
    @State private var showHWIDCopied = false
    @State private var showBypassToast = false
    @State private var showAdminSheet = false
    @State private var logoTapCount = 0
    @FocusState private var isFieldFocused: Bool

    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"
    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.07).ignoresSafeArea()

            // Ambient background multi-color glows
            VStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [activeTheme.primaryColor.opacity(0.22), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(y: -80)

                Spacer()

                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 70)
                    .offset(y: 80)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 16)

                    // Hero Branding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [activeTheme.primaryColor.opacity(0.4), Color.clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 75
                                    )
                                )
                                .frame(width: 140, height: 140)

                            AppLogo(size: 88)
                                .onTapGesture {
                                    logoTapCount += 1
                                    if logoTapCount >= 5 {
                                        logoTapCount = 0
                                        showAdminSheet = true
                                        let gen = UINotificationFeedbackGenerator()
                                        gen.notificationOccurred(.success)
                                    }
                                }
                        }

                        VStack(spacing: 4) {
                            Text("OniAkuma")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.85, green: 0.95, blue: 1.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: activeTheme.primaryColor.opacity(0.6), radius: 12, x: 0, y: 3)

                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                Text("HoangHaMod & TrongKien")
                                    .font(.caption.weight(.black).monospaced())
                            }
                            .foregroundStyle(activeTheme.primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(activeTheme.primaryColor.opacity(0.12))
                                    .overlay(Capsule().stroke(activeTheme.primaryColor.opacity(0.35), lineWidth: 1))
                            )
                        }
                    }

                    // Key Authentication Card
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Label {
                                Text("XÁC THỰC BẢN QUYỀN")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(activeTheme.primaryColor)
                            }

                            Text("Nhập License Key hoặc bấm Vượt Link bên dưới để kích hoạt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Key Input Field & Paste Button
                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(isFieldFocused ? activeTheme.primaryColor : .secondary)

                                TextField("Nhập mã key tại đây...", text: $inputKey)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .focused($isFieldFocused)
                                    .submitLabel(.done)

                                if !inputKey.isEmpty {
                                    Button {
                                        inputKey = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                // Quick Paste Button
                                Button {
                                    if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                        inputKey = clip.uppercased()
                                        let gen = UIImpactFeedbackGenerator(style: .light)
                                        gen.impactOccurred()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard.fill")
                                        Text("Dán")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(activeTheme.primaryColor)
                                    )
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(red: 0.10, green: 0.12, blue: 0.16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isFieldFocused ? activeTheme.primaryColor : Color.white.opacity(0.1), lineWidth: 1.5)
                                    )
                            )
                        }

                        // Error Banner if any
                        if let error = licenseManager.lastErrorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.12).cornerRadius(10))
                        }

                        // Submit Button
                        Button {
                            submitKey()
                        } label: {
                            HStack(spacing: 8) {
                                if licenseManager.isVerifying {
                                    ProgressView()
                                        .tint(.black)
                                        .controlSize(.small)
                                    Text("Đang kiểm tra...")
                                        .font(.headline.weight(.black))
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.headline.weight(.bold))
                                    Text("KÍCH HOẠT ỨNG DỤNG")
                                        .font(.headline.weight(.black))
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [activeTheme.primaryColor, activeTheme.primaryColor.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: activeTheme.primaryColor.opacity(0.4), radius: 10, y: 4)
                        }
                        .disabled(licenseManager.isVerifying)

                        Divider().background(Color.white.opacity(0.08))

                        // FREE BYPASS LINK BUTTON (VƯỢT LINK LẤY KEY)
                        Button {
                            openBypassLink()
                        } label: {
                            VStack(spacing: 6) {
                                HStack(spacing: 8) {
                                    Image(systemName: "link.badge.plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.orange)

                                    Text("Bạn không có key? Nhấn vô đây để vượt link")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)

                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color.orange)
                                }

                                Text("Vượt link nhanh nhận ngay Key miễn phí 100%")
                                    .font(.caption2)
                                    .foregroundStyle(Color.orange.opacity(0.9))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.orange.opacity(0.18), Color.yellow.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.orange.opacity(0.6), Color.yellow.opacity(0.3)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: Color.orange.opacity(0.2), radius: 8, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )

                    // Device HWID Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        Label {
                            Text("MÃ THIẾT BỊ (HWID)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(activeTheme.primaryColor)
                        } icon: {
                            Image(systemName: "iphone.smartbatterycase.gen2")
                                .foregroundStyle(activeTheme.primaryColor)
                        }

                        HStack {
                            Text(licenseManager.deviceHWID)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Button {
                                UIPasteboard.general.string = licenseManager.deviceHWID
                                let gen = UIImpactFeedbackGenerator(style: .light)
                                gen.impactOccurred()
                                withAnimation { showHWIDCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation { showHWIDCopied = false }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showHWIDCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption2.weight(.bold))
                                    Text(showHWIDCopied ? "Đã chép" : "Sao chép")
                                        .font(.caption2.weight(.bold))
                                }
                                .foregroundStyle(showHWIDCopied ? .green : activeTheme.primaryColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.06).cornerRadius(8))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )

                    // Contact / Support Links
                    VStack(spacing: 10) {
                        Text("Cần Mua Key VIP Hoặc Hỗ Trợ Kỹ Thuật?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://zalo.me/0866445455")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                    Text("Zalo: 0866445455")
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.85).cornerRadius(10))
                            }

                            Link(destination: URL(string: "https://t.me/+1fstsksh_dMxNjE1")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Nhóm Telegram")
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(activeTheme.primaryColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(activeTheme.primaryColor.opacity(0.15).cornerRadius(10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .sheet(isPresented: $showAdminSheet) {
                AdminManagerView()
            }
            .overlay(alignment: .bottom) {
                if showSuccessToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(successToastMessage)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.95))
                            .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 1))
                            .shadow(color: .black.opacity(0.5), radius: 10)
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func submitKey() {
        let cleanKey = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            licenseManager.lastErrorMessage = "Vui lòng nhập License Key hợp lệ!"
            return
        }

        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        Task {
            let result = await licenseManager.verifyKey(cleanKey)
            await MainActor.run {
                if result.success {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    successToastMessage = result.message
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showSuccessToast = true
                    }
                } else {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                }
            }
        }
    }

    private func openBypassLink() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()

        Task {
            // Check Firebase config for dynamic bypass link
            let bypassURLStr = await fetchServerBypassLink()
            guard let url = URL(string: bypassURLStr), UIApplication.shared.canOpenURL(url) else {
                if let fallback = URL(string: "https://link4m.co") {
                    UIApplication.shared.open(fallback)
                }
                return
            }
            UIApplication.shared.open(url)
        }
    }

    private func fetchServerBypassLink() async -> String {
        let urlStr = "https://ewrergdf-default-rtdb.firebaseio.com/config/bypass_link.json"
        guard let url = URL(string: urlStr) else { return "https://link4m.co" }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode == 200,
               let link = try? JSONDecoder().decode(String.self, from: data), !link.isEmpty {
                return link
            }
        } catch {}
        return "https://link4m.co"
    }
}
