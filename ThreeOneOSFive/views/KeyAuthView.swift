import SwiftUI
import UIKit

struct KeyAuthView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var inputKey = ""
    @State private var inputPassword = ""
    @State private var needsPassword = false
    @State private var isSubmitting = false
    @State private var showSupport = false
    @State private var copiedMessage = ""
    @State private var activationTask: Task<Void, Never>?
    @FocusState private var isFieldFocused: Bool

    private var isBusy: Bool { isSubmitting || licenseManager.isVerifying }
    private var isComplete: Bool { licenseManager.isAuthorized }
    private var canSubmit: Bool {
        !inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (!needsPassword || !inputPassword.isEmpty) && !isBusy && !isComplete
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("MIZZE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(4)
                        Spacer()
                        Button { showSupport = true } label: {
                            Image(systemName: "ellipsis").frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Tùy chọn truy cập và thiết bị")
                    }
                    Spacer(minLength: 64)
                    VStack(alignment: .leading, spacing: 24) {
                        Group {
                            if isComplete {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 28, weight: .light))
                                    .frame(width: 64, height: 64)
                                    .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
                            } else {
                                AppLogo(size: 64)
                            }
                        }
                        .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 12) {
                            Text(isComplete ? "Đã kích hoạt." : "Không gian\ncủa bạn.")
                                .font(.system(size: 46, weight: .semibold))
                                .tracking(-2)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(isComplete ? "Đang mở ứng dụng…" : "Một key. Mọi thứ sẵn sàng.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            inputRow
                            if let error = licenseManager.lastErrorMessage, !isBusy, !isComplete {
                                Label(error, systemImage: "exclamationmark.circle")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityLabel("Lỗi: \(error)")
                            } else {
                                Text(isBusy ? "Đang xác thực key…" : (needsPassword ? "Nhập mật khẩu của key để tiếp tục." : "Nhập key rồi chạm mũi tên để kích hoạt."))
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: 460, alignment: .leading)
                    .frame(maxWidth: .infinity)
                    Spacer(minLength: 64)
                    HStack {
                        Text("PRIVATE ACCESS").tracking(3)
                        Spacer()
                        Text("01 / ENTRY").monospaced()
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 28)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .foregroundStyle(.white)
        .tint(.white)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: needsPassword)
        .sheet(isPresented: $showSupport) { supportSheet }
        .onDisappear { activationTask?.cancel() }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            if needsPassword {
                Button {
                    needsPassword = false
                    inputPassword = ""
                    licenseManager.lastErrorMessage = nil
                    isFieldFocused = true
                } label: {
                    Image(systemName: "chevron.left").frame(width: 32, height: 44)
                }
                .accessibilityLabel("Sửa key")
            }
            Group {
                if needsPassword {
                    SecureField("Mật khẩu key", text: $inputPassword)
                        .textContentType(.password)
                } else {
                    TextField("Nhập key của bạn", text: $inputKey)
                        .textInputAutocapitalization(.characters)
                }
            }
            .font(.system(size: 15, weight: .medium, design: .monospaced))
            .autocorrectionDisabled()
            .focused($isFieldFocused)
            .submitLabel(.go)
            .onSubmit(submitKey)
            .accessibilityLabel(needsPassword ? "Mật khẩu key" : "License key")
            Button(action: submitKey) {
                ZStack {
                    if isComplete {
                        Image(systemName: "checkmark")
                    } else if isBusy {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(canSubmit || isBusy || isComplete ? 1 : 0.35), in: RoundedRectangle(cornerRadius: 13))
            }
            .disabled(!canSubmit)
            .accessibilityLabel(isBusy ? "Đang xác thực" : "Kích hoạt")
        }
        .padding(8)
        .padding(.leading, needsPassword ? 0 : 12)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 21))
        .overlay(RoundedRectangle(cornerRadius: 21).stroke(isFieldFocused ? Color.white.opacity(0.65) : AppTheme.borderSubtle))
        .disabled(isBusy || isComplete)
    }

    private var supportSheet: some View {
        NavigationStack {
            List {
                Section("Key của bạn") {
                    Button("Key có mật khẩu") {
                        needsPassword = true
                        showSupport = false
                        isFieldFocused = true
                    }
                    Button("Dán key từ bộ nhớ tạm") {
                        if let key = UIPasteboard.general.string {
                            inputKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
                            needsPassword = false
                            inputPassword = ""
                            licenseManager.lastErrorMessage = nil
                        }
                        showSupport = false
                    }
                    Button("Mở link lấy key") { Task { await openBypassLink() } }
                    Button("Sao chép link lấy key") {
                        UIPasteboard.general.string = licenseManager.bypassLink.isEmpty ? "https://link4m.co" : licenseManager.bypassLink
                        copiedMessage = "Đã sao chép link"
                    }
                }
                .disabled(isBusy || isComplete)
                Section("Thiết bị") {
                    Text(licenseManager.deviceHWID).font(.caption.monospaced()).textSelection(.enabled)
                    Button("Sao chép mã thiết bị") {
                        UIPasteboard.general.string = licenseManager.deviceHWID
                        copiedMessage = "Đã sao chép mã thiết bị"
                    }
                    if !copiedMessage.isEmpty { Text(copiedMessage).font(.footnote) }
                }
            }
            .navigationTitle("Truy cập và thiết bị")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Xong") { showSupport = false } } }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }

    private func submitKey() {
        guard canSubmit else { return }
        isFieldFocused = false
        isSubmitting = true
        licenseManager.lastErrorMessage = nil
        let key = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = inputPassword
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        activationTask = Task { @MainActor in
            defer { isSubmitting = false }
            let result = await licenseManager.activateKey(key, enteredPassword: password)
            guard !Task.isCancelled else { return }
            if result.success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                // Preserve existing password validation, showing the next step only when required.
                if result.message == "Mật khẩu Key không chính xác! Vui lòng kiểm tra lại Pass Key." {
                    needsPassword = true
                }
                isFieldFocused = true
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    @MainActor
    private func openBypassLink() async {
        var destination = licenseManager.bypassLink.isEmpty ? "https://link4m.co" : licenseManager.bypassLink
        if let endpoint = URL(string: "https://ewrergdf-default-rtdb.firebaseio.com/config/bypass_link.json") {
            var request = URLRequest(url: endpoint)
            request.timeoutInterval = 10
            if let (data, response) = try? await URLSession.shared.data(for: request),
               (response as? HTTPURLResponse)?.statusCode == 200,
               let link = try? JSONDecoder().decode(String.self, from: data), !link.isEmpty {
                destination = link
            }
        }
        guard let url = URL(string: destination), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return }
        UIApplication.shared.open(url)
    }
}
