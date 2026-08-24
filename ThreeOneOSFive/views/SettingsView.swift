import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var appState: AppState
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        AppLogo(size: 52)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("OniAkuma").font(.headline.weight(.bold))
                            Text("3105 x HoangHaMod,TrongKien")
                                .font(.caption.weight(.semibold).monospaced())
                                .foregroundStyle(AppTheme.accent)
                            Text(language.text("common.version", appVersion))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
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

                Section {
                    HStack {
                        Text(language.text("settings.current_version"))
                        Spacer()
                        Text(language.text(appState.isSupported ? "settings.supported" : "settings.unsupported"))
                        .foregroundStyle(appState.isSupported ? Color.green : Color.red)
                    }
                    LabeledContent("iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range)
                    LabeledContent("iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range)
                    LabeledContent("iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iOS 27.0")
                            .font(.body)
                        ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { version in
                            Text(versionLabel(version))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } header: {
                    Text(language.text("settings.verified_versions"))
                } footer: {
                    Text(language.text("settings.supported_versions_footer"))
                }

                // License Management Section
                Section("BẢN QUYỀN & GIẤY PHÉP") {
                    if let license = LicenseManager.shared.currentLicense {
                        LabeledContent("Mã Key") {
                            Text(maskedKey(license.key))
                                .font(.subheadline.weight(.semibold).monospaced())
                                .foregroundStyle(AppTheme.accent)
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
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng Xuất License Key")
                        }
                        .foregroundStyle(.red)
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
            .tint(AppTheme.accent)
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
            ?? "1.0"
    }

    private func versionLabel(
        _ version: (beta: Int, publicBeta: Int?, build: String)
    ) -> String {
        if let publicBeta = version.publicBeta {
            return language.text(
                "settings.developer_public_beta_build",
                Int64(version.beta),
                Int64(publicBeta),
                version.build
            )
        }
        return language.text(
            "settings.developer_beta_build",
            Int64(version.beta),
            version.build
        )
    }

    @ViewBuilder
    private func creditsRow(name: String, role: String, url: String) -> some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 28, height: 28)
                }
                .contentShape(Rectangle())
            }
            .accessibilityLabel(language.text("accessibility.open_profile", name))
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 6 else { return key }
        let prefix = key.prefix(4)
        let suffix = key.suffix(3)
        return "\(prefix)••••\(suffix)"
    }
}
