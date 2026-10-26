import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.vietnamese.rawValue
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "monochrome"

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .monochrome
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo(size: 52)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mizze").font(.headline.weight(.bold))
                            Text("VIP Core System • v\(appVersion)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Giao diện") {
                    Label("Đen trắng", systemImage: "circle.lefthalf.filled")
                        .foregroundStyle(.white)
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
                    LabeledContent("Nhân Khai Thác", value: "Exploit Kernel By Mizze")
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

    private func maskedKey(_ key: String) -> String {
        guard key.count > 6 else { return key }
        let prefix = key.prefix(4)
        let suffix = key.suffix(3)
        return "\(prefix)••••\(suffix)"
    }
}
