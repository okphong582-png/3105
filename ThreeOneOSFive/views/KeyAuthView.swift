import SwiftUI
import UIKit

struct KeyAuthView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @State private var inputKey = ""
    @State private var showSuccessToast = false
    @State private var successToastMessage = ""
    @State private var showHWIDCopied = false
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            // Ambient background glow
            VStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.18))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(y: -100)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 20)

                    // Hero Branding
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [AppTheme.accent.opacity(0.4), Color.clear],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 70
                                    )
                                )
                                .frame(width: 130, height: 130)

                            AppLogo(size: 88)
                        }

                        VStack(spacing: 4) {
                            Text("OniAkuma")
                                .font(.system(size: 30, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.8, green: 0.95, blue: 1.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: AppTheme.accent.opacity(0.6), radius: 10, x: 0, y: 2)

                            Text("HoangHaMod & TrongKien")
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(AppTheme.accent)
                        }
                    }

                    // Key Authentication Card
                    VStack(spacing: 18) {
                        VStack(spacing: 6) {
                            Label {
                                Text("XÁC THỰC BẢN QUYỀN")
                                    .font(.subheadline.weight(.black))
                                    .foregroundStyle(.white)
                            } icon: {
                                Image(systemName: "key.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }

                            Text("Vui lòng nhập License Key để kích hoạt ứng dụng")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Key Input Field
                        HStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(isFieldFocused ? AppTheme.accent : .secondary)

                            TextField("Nhập mã key tại đây...", text: $inputKey)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
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
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppTheme.cardBackgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isFieldFocused ? AppTheme.accent : AppTheme.borderSubtle, lineWidth: 1.5)
                                )
                        )

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
                                        .font(.headline.weight(.bold))
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.headline.weight(.bold))
                                    Text("KÍCH HOẠT NGAY")
                                        .font(.headline.weight(.bold))
                                }
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.accentGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, y: 4)
                        }
                        .disabled(licenseManager.isVerifying)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
                            )
                    )

                    // Device HWID Info Card
                    VStack(alignment: .leading, spacing: 10) {
                        Label {
                            Text("MÃ THIẾT BỊ (HWID)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                        } icon: {
                            Image(systemName: "iphone.smartbatterycase.gen2")
                                .foregroundStyle(AppTheme.accent)
                        }

                        HStack {
                            Text(licenseManager.deviceHWID)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
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
                                .foregroundStyle(showHWIDCopied ? .green : AppTheme.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.cardBackgroundElevated.cornerRadius(8))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppTheme.borderSubtle, lineWidth: 1)
                            )
                    )

                    // Contact / Support
                    VStack(spacing: 10) {
                        Text("Chưa có Key bản quyền?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Link(destination: URL(string: "https://zalo.me/0866445455")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "phone.fill")
                                    Text("Mua Key (Zalo: 0866445455)")
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
                                    Text("Nhóm Cộng Đồng")
                                }
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(AppTheme.accent.opacity(0.15).cornerRadius(10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.accent.opacity(0.4), lineWidth: 1))
                            }
                        }
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, AppTheme.pageInset)
            }
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kích Hoạt Thành Công!")
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.white)

                        Text(successToastMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.14, blue: 0.18))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.green.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: Color.green.opacity(0.3), radius: 12, y: 6)
                )
                .padding(.top, 50)
                .padding(.horizontal, 20)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func submitKey() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        isFieldFocused = false

        Task {
            let result = await LicenseManager.shared.activateKey(inputKey)
            await MainActor.run {
                if result.success {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    successToastMessage = "Thời hạn: \(result.remaining) • Đã liên kết: \(result.devices)"
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showSuccessToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showSuccessToast = false
                        }
                    }
                } else {
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                }
            }
        }
    }
}
