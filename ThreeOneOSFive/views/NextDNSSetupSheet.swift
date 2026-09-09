import SwiftUI
import UIKit

// MARK: - NextDNS Realtime Dashboard Sheet
struct NextDNSSetupSheet: View {
    @ObservedObject var nextDNSService = NextDNSInstallerService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0 // 0: Live Logs, 1: Deny (51), 2: Allow (2), 3: Profile Setup
    @State private var logFilter: LogFilter = .all
    @State private var searchText: String = ""
    @State private var selectedCategory: DNSDomainCategory = .all
    @State private var pulseAnimation: Bool = false
    @State private var downloaded: Bool = false
    @State private var copiedDomain: String? = nil

    enum LogFilter: String, CaseIterable {
        case all = "Tất cả"
        case blockedOnly = "Chỉ Chặn"
        case allowedOnly = "Cho Phép"
    }

    var onFinish: (() -> Void)?

    var body: some View {
        ZStack {
            // Dark Obsidian Canvas
            Color(red: 0.03, green: 0.04, blue: 0.07).ignoresSafeArea()

            // Ambient Glows
            VStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (nextDNSService.isProtectionActive ? Color.green : Color.red).opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 180
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(y: -80)

                Spacer()
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Indicator & Navigation Bar
                sheetHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Master Control Card (Toggle + Status + Quick Switch)
                        masterControlCard

                        // 2. Realtime Analytics Metrics (Total / Blocked / Allowed)
                        analyticsMetricsGrid

                        // 3. Custom Segmented Navigation Bar
                        dashboardTabSelector

                        // 4. Tab Content Switcher
                        switch selectedTab {
                        case 0:
                            realtimeLiveLogTab
                        case 1:
                            denyDomainListTab
                        case 2:
                            allowDomainListTab
                        case 3:
                            profileInstallationTab
                        default:
                            EmptyView()
                        }

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if nextDNSService.hasDownloadedProfile {
                downloaded = true
            }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    // MARK: - Sheet Header Bar
    private var sheetHeader: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(nextDNSService.isProtectionActive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(nextDNSService.isProtectionActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation ? 1.25 : 0.85)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("NEXTDNS REALTIME")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)

                        Text("BẢO VỆ CHỐNG KHÓA ACC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Spacer()

                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.08))
        }
    }

    // MARK: - 1. Master Control Card
    private var masterControlCard: some View {
        HStack(spacing: 14) {
            // Radar Pulsing Shield Icon
            ZStack {
                Circle()
                    .stroke(
                        (nextDNSService.isProtectionActive ? Color.green : Color.red).opacity(0.3),
                        lineWidth: 1.5
                    )
                    .frame(width: 54, height: 54)
                    .scaleEffect(pulseAnimation ? 1.15 : 0.95)

                Circle()
                    .fill(
                        (nextDNSService.isProtectionActive ? Color.green : Color.red).opacity(0.15)
                    )
                    .frame(width: 46, height: 46)

                Image(systemName: nextDNSService.isProtectionActive ? "shield.checkered" : "shield.slash.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(nextDNSService.isProtectionActive ? Color.green : Color.red)
            }

            // Info Text
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("REALTIME ANTIBAN")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white)

                    Text(nextDNSService.isProtectionActive ? "ACTIVE" : "OFF")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(nextDNSService.isProtectionActive ? Color.black : Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (nextDNSService.isProtectionActive ? Color.green : Color.red)
                                .cornerRadius(4)
                        )
                }

                Text(nextDNSService.isProtectionActive ? "Đang lọc trực tiếp 51 web cấm & bảo vệ thiết bị" : "Bảo vệ đang tắt • Bật lại để tránh bị phát hiện")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Big Toggle Switch
            Toggle("", isOn: $nextDNSService.isProtectionActive)
                .labelsHidden()
                .tint(Color.green)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.06, green: 0.07, blue: 0.11))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    (nextDNSService.isProtectionActive ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 1
                )
        )
    }

    // MARK: - 2. Realtime Analytics Metrics Grid
    private var analyticsMetricsGrid: some View {
        HStack(spacing: 10) {
            // Metric 1: Total Queries
            metricCard(
                title: "TỔNG TRUY VẤN",
                value: "\(nextDNSService.totalQueries)",
                subtext: "Live DoH",
                color: Color.cyan,
                icon: "waveform.path.ecg"
            )

            // Metric 2: Blocked Queries (Red)
            metricCard(
                title: "ĐÃ CHẶN",
                value: "\(nextDNSService.blockedQueries)",
                subtext: nextDNSService.blockedPercentage,
                color: Color.red,
                icon: "hand.raised.slash.fill"
            )

            // Metric 3: Allowed Queries (Green)
            metricCard(
                title: "CHO PHÉP",
                value: "\(nextDNSService.allowedQueries)",
                subtext: "2 Domain",
                color: Color.green,
                icon: "checkmark.shield.fill"
            )
        }
    }

    private func metricCard(title: String, value: String, subtext: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)

            Text(subtext)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.06, green: 0.07, blue: 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 3. Dashboard Tab Selector
    private var dashboardTabSelector: some View {
        HStack(spacing: 6) {
            tabButton(title: "Nhật Ký", icon: "bolt.fill", index: 0)
            tabButton(title: "Chặn (51)", icon: "exclamationmark.triangle.fill", index: 1)
            tabButton(title: "Cho Phép (2)", icon: "checkmark.circle.fill", index: 2)
            tabButton(title: "Hồ Sơ", icon: "arrow.down.doc.fill", index: 3)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .black))
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
            }
            .foregroundStyle(isSelected ? Color.black : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    LinearGradient(colors: [Color.green, Color.cyan], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: isSelected ? Color.green.opacity(0.3) : Color.clear, radius: 4)
        }
    }

    // MARK: - TAB 0: Realtime Live Logs (Stream)
    private var realtimeLiveLogTab: some View {
        VStack(spacing: 12) {
            // Live Control Bar
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(nextDNSService.isProtectionActive ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulseAnimation ? 1.3 : 0.8)

                    Text(nextDNSService.isProtectionActive ? "ĐANG NHẬN TRUY VẤN..." : "STREAM ĐÃ TẠM DỪNG")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(nextDNSService.isProtectionActive ? Color.green : Color.orange)
                }

                Spacer()

                // Filter Buttons
                Picker("Lọc", selection: $logFilter) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)

                Button {
                    nextDNSService.clearLogs()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .padding(6)
                        .background(Color.white.opacity(0.06).cornerRadius(8))
                }
            }

            // Stream List
            let filtered = filteredLogs
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.secondary)
                        .padding(.top, 30)

                    Text("Chưa có truy vấn nào được ghi nhận")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { item in
                        queryLogRow(item)
                    }
                }
            }
        }
    }

    private var filteredLogs: [NextDNSQueryLog] {
        switch logFilter {
        case .all:
            return nextDNSService.liveLogs
        case .blockedOnly:
            return nextDNSService.liveLogs.filter { $0.isBlocked }
        case .allowedOnly:
            return nextDNSService.liveLogs.filter { !$0.isBlocked }
        }
    }

    private func queryLogRow(_ item: NextDNSQueryLog) -> some View {
        HStack(spacing: 10) {
            // Status Dot / Icon
            Image(systemName: item.isBlocked ? "xmark.octagon.fill" : "checkmark.circle.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(item.isBlocked ? Color.red : Color.green)

            // Domain and Matched Rule
            VStack(alignment: .leading, spacing: 3) {
                Text(item.domain)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.matchedRule)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(item.isBlocked ? Color.red.opacity(0.9) : Color.green.opacity(0.9))

                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.secondary)

                    Text(item.protocolName)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            // Latency & Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f ms", item.latencyMs))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(item.isBlocked ? Color.red : Color.cyan)

                Text(item.formattedTime)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    (item.isBlocked ? Color.red : Color.green).opacity(0.18),
                    lineWidth: 1
                )
        )
    }

    // MARK: - TAB 1: ⚠️ Web Cần Chặn (51 Domains)
    private var denyDomainListTab: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)

                TextField("Tìm kiếm domain trong 51 web cấm...", text: $searchText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white)

                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05).cornerRadius(10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DNSDomainCategory.allCases, id: \.self) { cat in
                        let active = selectedCategory == cat
                        Button {
                            selectedCategory = cat
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 10))
                                Text(cat.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(active ? Color.black : Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(active ? Color.red : Color.white.opacity(0.07))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Summary Header
            HStack {
                Text("⚠️ DANH SÁCH NHỮNG WEB CẦN DENY")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.red)

                Spacer()

                Text("\(filteredDenyRules.count)/51 Đang Chặn")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.top, 4)

            // Domain Cards
            LazyVStack(spacing: 8) {
                ForEach(filteredDenyRules) { rule in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "nosign")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.pattern)
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)

                            HStack(spacing: 5) {
                                Text(rule.category.rawValue)
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.red)

                                Text("•")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.secondary)

                                Text("Chặn truyền dữ liệu report")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = rule.pattern
                            let gen = UIImpactFeedbackGenerator(style: .light)
                            gen.impactOccurred()
                            withAnimation { copiedDomain = rule.pattern }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation { copiedDomain = nil }
                            }
                        } label: {
                            Text(copiedDomain == rule.pattern ? "ĐÃ COPY" : "DENY")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.red.cornerRadius(5))
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.06, green: 0.07, blue: 0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
    }

    private var filteredDenyRules: [DNSRuleItem] {
        nextDNSService.formattedDenyRules.filter { rule in
            let matchesCategory = (selectedCategory == .all) || (rule.category == selectedCategory)
            let matchesSearch = searchText.isEmpty || rule.pattern.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    // MARK: - TAB 2: ✅ Web Cần Cho Phép (2 Domains)
    private var allowDomainListTab: some View {
        VStack(spacing: 14) {
            // Notice Box
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.green)

                VStack(alignment: .leading, spacing: 3) {
                    Text("QUY TẮC ALLOWLIST BẮT BUỘC")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.green)

                    Text("2 domain dưới đây bắt buộc phải được Cho Phép để máy chủ Garena không chặn kết nối đăng nhập và tải tài nguyên nhân vật.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )

            // Allow List
            VStack(spacing: 10) {
                ForEach(nextDNSService.formattedAllowRules) { rule in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.18))
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(Color.green)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(rule.pattern)
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.white)

                            Text(rule.note)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }

                        Spacer()

                        Text("ALLOW")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.cornerRadius(6))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(red: 0.06, green: 0.08, blue: 0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.green.opacity(0.35), lineWidth: 1)
                    )
                }
            }

            // Status Explanation
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.cyan)
                    Text("ƯU TIÊN VƯỢT QUA TƯỜNG LỬA (BYPASS)")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                }

                Text("Hệ thống NextDNS tích hợp sẽ ưu tiên cho qua 2 tên miền này trước khi kích hoạt bộ lọc 51 tên miền Deny, đảm bảo vào trận 100% không bị văng phòng.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .padding(12)
            .background(Color.white.opacity(0.03).cornerRadius(12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }

    // MARK: - TAB 3: 📲 Cài Đặt Hồ Sơ
    private var profileInstallationTab: some View {
        VStack(spacing: 16) {
            // Instructions Card
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(Color.green.opacity(0.2)).frame(width: 26, height: 26)
                        Text("1").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Color.green)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tải về NextDNS.mobileconfig")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text("Nhấn nút tải và chọn Cho phép để tải về hồ sơ bảo vệ.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(Color.cyan.opacity(0.2)).frame(width: 26, height: 26)
                        Text("2").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(Color.cyan)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kích hoạt trong Cài đặt iPhone")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text("Mở Cài đặt > Đã tải về hồ sơ > Nhấn Cài đặt để kích hoạt hệ thống lọc.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )

            // Button 1: Download NextDNS Profile
            Button {
                let gen = UIImpactFeedbackGenerator(style: .medium)
                gen.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    downloaded = true
                }
                nextDNSService.downloadAndInstallProfile()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: downloaded ? "checkmark.circle.fill" : "arrow.down.doc.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(downloaded ? "TẢI LẠI NEXTDNS.MOBILECONFIG" : "TẢI VỀ NEXTDNS.MOBILECONFIG")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                }
                .foregroundStyle(downloaded ? Color.white : Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    downloaded
                        ? LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.green, Color(red: 0.2, green: 0.9, blue: 0.5)], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(downloaded ? Color.white.opacity(0.2) : Color.green.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: downloaded ? Color.clear : Color.green.opacity(0.35), radius: 10, y: 3)
            }

            // Button 2: BẠN ĐÃ SETUP XONG ? VÔ CHƠI
            if downloaded || nextDNSService.hasDownloadedProfile {
                Button {
                    nextDNSService.completeSetup()
                    onFinish?()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .black))
                        Text("BẠN ĐÃ SETUP XONG ? VÔ CHƠI")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color(red: 0.1, green: 0.8, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.cyan.opacity(0.9), lineWidth: 1.2)
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 12, y: 3)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    nextDNSService.completeSetup()
                    onFinish?()
                    dismiss()
                } label: {
                    Text("Tôi đã cài đặt NextDNS từ trước (Bỏ qua)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
}
