import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.vietnamese.rawValue
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo(size: 52)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("OniAkuma").font(.headline.weight(.bold))
                            Text("HoangHaMod & TrongKien")
                                .font(.caption.weight(.semibold).monospaced())
                                .foregroundStyle(activeTheme.primaryColor)
                            Text("Exploit Kernel By 3105 • v\(appVersion)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Theme Color Customizer
                Section("GIAO DIỆN MÀU SẮC (THEME)") {
                    ForEach(AppColorTheme.allCases) { theme in
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentThemeRaw = theme.rawValue
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(theme.primaryColor)
                                    .frame(width: 18, height: 18)
                                    .shadow(color: theme.primaryColor.opacity(0.4), radius: 4)

                                Text(theme.displayName)
                                    .font(.subheadline.weight(currentThemeRaw == theme.rawValue ? .bold : .regular))
                                    .foregroundStyle(currentThemeRaw == theme.rawValue ? .white : .secondary)

                                Spacer()

                                if currentThemeRaw == theme.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(theme.primaryColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section(language.text("settings.language")) {
                    Picker(language.text("settings.language"), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section(language.text("common.device")) {
                    LabeledContent(language.text("dashboard.hardware_model"), value: AppInfo.displayMachineName)
                    LabeledContent(language.text("settings.ios_version"), value: "\(AppInfo.osVersion) (\(AppInfo.osBuild))")
                }

                Section("KHAI THÁC LỖ HỔNG HỆ THỐNG") {
                    HStack {
                        Text("Trạng Thái")
                        Spacer()
                        Text(appState.isSupported ? "Đã Kích Hoạt" : "Sẵn Sàng")
                            .foregroundStyle(appState.isSupported ? Color.green : activeTheme.primaryColor)
                    }
                    LabeledContent("Nhân Khai Thác", value: "Exploit Kernel By 3105")
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                }

                // License Management Section
                Section("BẢN QUYỀN & GIẤY PHÉP") {
                    if let license = LicenseManager.shared.currentLicense {
                        LabeledContent("Mã Key") {
                            Text(maskedKey(license.key))
                                .font(.subheadline.weight(.semibold).monospaced())
                                .foregroundStyle(activeTheme.primaryColor)
                        }
                        LabeledContent("Thời Hạn Còn Lại") {
                            Text(license.remainingTimeFormatted)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.green)
                        }
                        LabeledContent("Thiết Bị Đã Liên Kết") {
                            Text(license.deviceUsageFormatted)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LabeledContent("Mã Thiết Bị (HWID)") {
                        Text(LicenseManager.shared.deviceHWID)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Button(role: .destructive) {
                        LicenseManager.shared.logout()
                        MultiLayerSecurityService.shared.lockdown()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng Xuất License Key")
                        }
                        .foregroundStyle(.red)
                    }
                }

                // Admin Server Key Manager Entry
                Section("QUẢN TRỊ VIÊN (ADMIN SERVER)") {
                    NavigationLink {
                        AdminManagerView()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "server.rack")
                                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quản Lý Server Key (.tipa)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("Tạo key, quản lý vượt link & cấu hình")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("HỖ TRỢ & CỘNG ĐỒNG") {
                    creditsRow(
                        name: "Mua Key / Hỗ Trợ Zalo",
                        role: "Zalo: 0866445455",
                        url: "https://zalo.me/0866445455"
                    )
                    creditsRow(
                        name: "Nhóm Cộng Đồng OniAkuma",
                        role: "Telegram: Nhóm Hỗ Trợ & Thảo Luận",
                        url: "https://t.me/+1fstsksh_dMxNjE1"
                    )
                    creditsRow(
                        name: "HoangHaMod & TrongKien",
                        role: "Phát triển & Tùy biến OniAkuma",
                        url: "https://zalo.me/0866445455"
                    )
                }
            }
            .tint(activeTheme.primaryColor)
            .navigationTitle(language.text("settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.text("common.done")) { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppReleaseDisplayVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "1.1.1"
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(activeTheme.primaryColor)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 6 else { return key }
        let prefix = key.prefix(4)
        let suffix = key.suffix(3)
        return "\(prefix)••••\(suffix)"
    }
}
