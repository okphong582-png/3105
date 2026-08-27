import SwiftUI
import UIKit

struct MultiLayerSecurityGateView: View {
    @ObservedObject var securityService = MultiLayerSecurityService.shared
    @ObservedObject var licenseManager = LicenseManager.shared
    @AppStorage("oni_akuma_theme_color") private var currentThemeRaw = "cyan"

    @State private var inputKey = ""
    @State private var showHWIDCopied = false
    @State private var showLinkCopiedToast = false
    @FocusState private var isKeyFieldFocused: Bool

    private var activeTheme: AppColorTheme {
        AppColorTheme(rawValue: currentThemeRaw) ?? .cyan
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            // Ambient background glow
            VStack {
                Circle()
                    .fill(activeTheme.primaryColor.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(y: -80)
                Spacer()
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Status
                    VStack(spacing: 8) {
                        AppLogo(size: 68)

                        Text("ONIAKUMA SECURITY GATE")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(activeTheme.primaryColor)
                            .tracking(2.0)

                        Text("Hệ thống bảo vệ phân vùng độc quyền • HoangHaMod & TrongKien")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

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
                    .padding(.top, 10)

                    // 5-Layer Progress Bar
                    layerProgressHeader
                        .padding(.horizontal, 8)

                    // Active Layer View
                    activeLayerCard
                        .padding(.horizontal, 4)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, AppTheme.pageInset)
            }
        }
        .onAppear {
            if !securityService.passedLayers.contains(1) {
                securityService.runLayer1IntegrityScan { _ in }
            }
            Task {
                _ = await licenseManager.checkSystemMaintenance()
                await licenseManager.fetchBypassKeys()
            }
        }
    }

    // MARK: - 5-Layer Progress Indicator
    private var layerProgressHeader: some View {
        HStack(spacing: 4) {
            ForEach(SecurityGateLayer.allCases) { layer in
                let isPassed = securityService.passedLayers.contains(layer.rawValue)
                let isCurrent = securityService.currentLayer == layer

                HStack(spacing: 4) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(
                                    isPassed ? Color.green :
                                    (isCurrent ? activeTheme.primaryColor : Color.white.opacity(0.1))
                                )
                                .frame(width: 32, height: 32)
                                .shadow(
                                    color: (isPassed ? Color.green : (isCurrent ? activeTheme.primaryColor : Color.clear)).opacity(0.6),
                                    radius: 6
                                )

                            if isPassed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.black)
                            } else {
                                Image(systemName: layer.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(isCurrent ? .black : .white)
                            }
                        }

                        Text("Lớp \(layer.rawValue)")
                            .font(.system(size: 9, weight: isCurrent ? .black : .medium))
                            .foregroundStyle(isCurrent ? activeTheme.primaryColor : (isPassed ? .green : .secondary))
                    }

                    if layer.rawValue < 5 {
                        Rectangle()
                            .fill(isPassed ? Color.green.opacity(0.7) : Color.white.opacity(0.15))
                            .frame(height: 2)
                            .padding(.bottom, 14)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
    }

    // MARK: - Dynamic Active Layer Card
    @ViewBuilder
    private var activeLayerCard: some View {
        VStack(spacing: 16) {
            // Layer Title
            HStack(spacing: 8) {
                Image(systemName: securityService.currentLayer.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(activeTheme.primaryColor)

                Text(securityService.currentLayer.title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)

                Spacer()

                Text("0\(securityService.currentLayer.rawValue) / 05")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(activeTheme.primaryColor)
            }
            .padding(.bottom, 4)

            Divider().background(Color.white.opacity(0.1))

            // Switch to appropriate card
            switch securityService.currentLayer {
            case .layer1_environment:
                layer1View
            case .layer2_licenseKey:
                layer2View
            case .layer3_securityPin:
                layer3View
            case .layer4_antiBotChallenge:
                layer4View
            case .layer5_coreDecryption:
                layer5View
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(activeTheme.primaryColor.opacity(0.3), lineWidth: 1.2)
                )
                .shadow(color: activeTheme.primaryColor.opacity(0.1), radius: 12)
        )
    }

    // MARK: - LAYER 1: Hardware & Integrity
    private var layer1View: some View {
        VStack(spacing: 14) {
            Text("Hệ thống đang kiểm tra chữ ký phần cứng và các tầng phòng thủ chống gỡ lỗi (Anti-Debug) trước khi mở cổng.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            VStack(spacing: 8) {
                integrityRow(label: "Mã Thiết Bị (HWID)", val: securityService.l1_hwidStatus, isGood: true)
                integrityRow(label: "Trạng Thái Debugger", val: securityService.l1_debuggerStatus, isGood: securityService.l1_debuggerStatus.contains("AN TOÀN"))
                integrityRow(label: "Môi Trường & Proxy", val: securityService.l1_environmentStatus, isGood: securityService.l1_environmentStatus.contains("SẠCH SẼ"))
            }
            .padding(12)
            .background(Color.black.opacity(0.35).cornerRadius(12))

            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                securityService.runLayer1IntegrityScan { _ in }
            } label: {
                HStack(spacing: 8) {
                    if securityService.l1_isScanning {
                        ProgressView().tint(.black)
                        Text("ĐANG QUÉT BẢO MẬT...")
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                        Text(securityService.l1_integrityOk ? "ĐÃ VƯỢT QUA LỚP 1" : "QUÉT TOÀN VẸN HỆ THỐNG")
                    }
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(securityService.l1_integrityOk ? Color.green : activeTheme.primaryColor)
                )
            }
            .disabled(securityService.l1_isScanning)
        }
    }

    private func integrityRow(label: String, val: String, isGood: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(val)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isGood ? Color.green : Color.orange)
        }
    }

    // MARK: - LAYER 2: License Key
    private var layer2View: some View {
        VStack(spacing: 14) {
            Text("Nhập mã License Key (VIP, Lite hoặc Vượt Link) để xác thực quyền truy cập:")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // VƯỢT LINK LINK4M LẤY KEY
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Button 1: Mở Safari vượt link trực tiếp
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

                    // Button 2: CHỈ SAO CHÉP LINK ĐỂ VƯỢT (Tuyệt đối không điền vào ô key!)
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
                    Text("✅ Đã sao chép link vượt! Hãy dán vào Safari/Chrome để vượt link lấy key.")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.green)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Vượt link nhanh nhận ngay Key miễn phí 100% (Mở khóa Aim Bot)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.orange.opacity(0.85))
                }
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.35), lineWidth: 1))

            // Key Input
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(activeTheme.primaryColor)

                TextField("Nhập hoặc dán mã key tại đây...", text: $inputKey)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .focused($isKeyFieldFocused)

                if !inputKey.isEmpty {
                    Button { inputKey = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.35).cornerRadius(12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))

            if let err = licenseManager.lastErrorMessage {
                Text(err)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Verify Key Button
            Button {
                isKeyFieldFocused = false
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                Task {
                    let result = await licenseManager.activateKey(inputKey)
                    if result.success {
                        securityService.confirmLayer2Success()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if licenseManager.isVerifying {
                        ProgressView().tint(.black)
                        Text("ĐANG XÁC THỰC ONLINE...")
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                        Text("XÁC NHẬN LICENSE KEY")
                    }
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(activeTheme.primaryColor))
            }
            .disabled(licenseManager.isVerifying || inputKey.trimmingCharacters(in: .whitespaces).isEmpty)

            // KHO KEY VƯỢT LINK HỆ THỐNG
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
                    VStack(spacing: 4) {
                        Text("Kho key tạm thời chưa có key công khai sẵn.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("👉 Hãy nhấn nút 'Vượt Link' ở trên để nhận key riêng cho máy bạn!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                } else {
                    VStack(spacing: 8) {
                        ForEach(licenseManager.bypassKeys.prefix(4), id: \.key) { bKey in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bKey.key)
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Text("Thời hạn: \(bKey.remainingTimeFormatted)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.green)
                                }

                                Spacer()

                                Button {
                                    inputKey = bKey.key
                                    UIPasteboard.general.string = bKey.key
                                    let gen = UIImpactFeedbackGenerator(style: .medium)
                                    gen.impactOccurred()
                                    Task {
                                        let result = await licenseManager.activateKey(bKey.key)
                                        if result.success {
                                            securityService.confirmLayer2Success()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard.fill")
                                        Text("Dán & Dùng")
                                    }
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.cornerRadius(8))
                                }
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.04).cornerRadius(10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.35), lineWidth: 1))

            // HWID Copy helper
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

    // MARK: - LAYER 3: Security PIN Code
    private var layer3View: some View {
        VStack(spacing: 16) {
            Text("Nhập mã PIN bảo mật cấp 2 (Bàn phím chống ghi âm và theo dõi vị trí nhấn):")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // PIN Dots
            HStack(spacing: 14) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(
                            index < securityService.l3_pinInput.count
                                ? activeTheme.primaryColor
                                : Color.white.opacity(0.15)
                        )
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(activeTheme.primaryColor, lineWidth: index < securityService.l3_pinInput.count ? 0 : 1)
                        )
                        .shadow(
                            color: index < securityService.l3_pinInput.count ? activeTheme.primaryColor.opacity(0.6) : .clear,
                            radius: 6
                        )
                }
            }
            .padding(.vertical, 6)

            if let err = securityService.l3_pinErrorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
            } else {
                Text("Mã PIN bảo mật mặc định: 8888")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Scrambled Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(securityService.l3_scrambledDigits, id: \.self) { digit in
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                        securityService.appendPinDigit(digit)
                    } label: {
                        Text("\(digit)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white.opacity(0.08).cornerRadius(10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                }

                // Clear & Delete button
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    securityService.deletePinDigit()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.red.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.red.opacity(0.12).cornerRadius(10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - LAYER 4: Anti-Bot Challenge
    private var layer4View: some View {
        VStack(spacing: 16) {
            Text("Xác thực chống công cụ giả lập & Bot Crack tự động. Hãy chọn kết quả chính xác của biểu thức bên dưới:")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Question Box
            Text(securityService.l4_challenge.question)
                .font(.system(size: 28, weight: .black, design: .monospaced))
                .foregroundStyle(activeTheme.primaryColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(Color.black.opacity(0.4).cornerRadius(12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))

            if let err = securityService.l4_errorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
            }

            // Options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<securityService.l4_challenge.options.count, id: \.self) { idx in
                    let val = securityService.l4_challenge.options[idx]
                    Button {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        securityService.answerLayer4Challenge(selectedIndex: idx)
                    } label: {
                        Text("\(val)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(activeTheme.primaryColor.opacity(0.15).cornerRadius(10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(activeTheme.primaryColor.opacity(0.4), lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: - LAYER 5: Core Decryption
    private var layer5View: some View {
        VStack(spacing: 16) {
            Text("Bạn đã vượt qua 4 lớp phòng thủ! Tiến hành giải mã và mở khóa vùng lõi ứng dụng OniAkuma.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if securityService.l5_isDecrypting {
                VStack(spacing: 10) {
                    ProgressView(value: securityService.l5_progress, total: 1.0)
                        .tint(activeTheme.primaryColor)
                        .scaleEffect(x: 1, y: 2, anchor: .center)

                    Text("ĐANG GIẢI MÃ VÙNG NHỚ LÕI: \(Int(securityService.l5_progress * 100))%")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(activeTheme.primaryColor)
                }
                .padding(.vertical, 8)
            }

            Button {
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
                securityService.startLayer5CoreDecryption {
                    // Completed!
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                    Text("KÍCH HOẠT VÙNG LÕI ONIAKUMA")
                }
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(activeTheme.primaryColor)
                        .shadow(color: activeTheme.primaryColor.opacity(0.5), radius: 8)
                )
            }
            .disabled(securityService.l5_isDecrypting)
        }
    }
}
