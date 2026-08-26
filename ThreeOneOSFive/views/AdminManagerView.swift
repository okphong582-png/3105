import SwiftUI
import UIKit

// MARK: - Admin Server Key Manager View
struct AdminManagerView: View {
    @StateObject private var adminService = AdminServerService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentTab: Int = 0 // 0: Keys List, 1: Create Standard, 2: Create Bypass, 3: Server Config
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var keyToDelete: LicenseInfo? = nil
    @State private var showDeleteConfirm: Bool = false

    // Form State: Create Standard
    @State private var stdKeyName: String = ""
    @State private var stdDurationHours: String = "24"
    @State private var stdSelectedPreset: Int64 = 86400 // 1d
    @State private var stdMaxDevices: Int = 1
    @State private var stdNote: String = ""

    // Form State: Create Bypass Link Key (3 Fields as requested)
    @State private var bypassRealKey: String = "PASS-" + String((0..<4).compactMap { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() }) + "-" + String((0..<4).compactMap { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement() })
    @State private var bypassShortLink: String = "https://link4m.co/"
    @State private var bypassDestinationKeyText: String = ""
    @State private var bypassDurationHours: String = "2"
    @State private var bypassSelectedPreset: Int64 = 7200 // 2h
    @State private var syncAsDefaultBypassLink: Bool = true

    // Server Config
    @State private var customServerBypassLink: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08).ignoresSafeArea()

                // Ambient glow
                VStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.12))
                        .frame(width: 320, height: 320)
                        .blur(radius: 90)
                        .offset(y: -120)
                    Spacer()
                }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    adminHeader

                    // Stats bar
                    statsBanner
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    // Tab Selector
                    adminTabSwitcher
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)

                    // Tab Content
                    ScrollView {
                        VStack(spacing: 16) {
                            if currentTab == 0 {
                                keysListTab
                            } else if currentTab == 1 {
                                createStandardKeyTab
                            } else if currentTab == 2 {
                                createBypassKeyTab
                            } else {
                                serverConfigTab
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 36)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Đóng")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await adminService.fetchAllData()
                            triggerToast("Đã làm mới dữ liệu Server!")
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                    }
                }
            }
            .onAppear {
                adminService.startRealtimeSync()
                customServerBypassLink = adminService.bypassLink
                bypassDestinationKeyText = bypassRealKey
            }
            .onDisappear {
                adminService.stopRealtimeSync()
            }
            .confirmationDialog(
                "Xác nhận xóa key vĩnh viễn khỏi Server?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                if let key = keyToDelete {
                    Button("Xóa Key \(key.key)", role: .destructive) {
                        Task {
                            let ok = await adminService.deleteKey(key: key.key)
                            if ok {
                                triggerToast("Đã xóa key \(key.key)!")
                            } else {
                                triggerToast("Lỗi khi xóa key!")
                            }
                        }
                    }
                }
                Button("Hủy", role: .cancel) {}
            }
            .overlay(alignment: .bottom) {
                if showToast, let msg = toastMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text(msg)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Admin Header
    private var adminHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: "server.rack")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("OniAkuma Server Key Manager")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Circle()
                        .fill(adminService.isLoading ? Color.orange : Color.green)
                        .frame(width: 7, height: 7)
                    Text(adminService.isLoading ? "Đang đồng bộ Firebase..." : "Firebase Realtime: Kết nối tốt")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(adminService.isLoading ? Color.orange : Color.green)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Stats Banner
    private var statsBanner: some View {
        HStack(spacing: 8) {
            statCard(title: "TỔNG KEY", count: adminService.totalKeysCount, color: Color(red: 0.0, green: 0.85, blue: 1.0))
            statCard(title: "HOẠT ĐỘNG", count: adminService.activeKeysCount, color: Color.green)
            statCard(title: "VƯỢT LINK", count: adminService.bypassKeysCount, color: Color.orange)
            statCard(title: "BỊ KHÓA", count: adminService.bannedKeysCount, color: Color.red)
        }
    }

    @ViewBuilder
    private func statCard(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("\(count)")
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.15))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    // MARK: - Admin Tab Switcher
    private var adminTabSwitcher: some View {
        HStack(spacing: 6) {
            tabBtn(index: 0, title: "Danh Sách", icon: "list.bullet.rectangle.portrait")
            tabBtn(index: 1, title: "Tạo Thường", icon: "plus.circle.fill")
            tabBtn(index: 2, title: "Vượt Link", icon: "link.badge.plus")
            tabBtn(index: 3, title: "Cấu Hình", icon: "gearshape.fill")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func tabBtn(index: Int, title: String, icon: String) -> some View {
        let isSelected = currentTab == index
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                currentTab = index
            }
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundStyle(isSelected ? .black : .secondary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color(red: 0.0, green: 0.85, blue: 1.0) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 1: Keys List
    private var keysListTab: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Tìm theo mã key, ghi chú, HWID...", text: $adminService.searchQuery)
                    .font(.system(size: 13, weight: .semibold))
                    .autocapitalization(.none)

                if !adminService.searchQuery.isEmpty {
                    Button { adminService.searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.09, green: 0.11, blue: 0.15))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AdminServerService.KeyFilter.allCases) { filter in
                        let isSelected = adminService.selectedFilter == filter
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                adminService.selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color(red: 0.0, green: 0.85, blue: 1.0) : Color(red: 0.12, green: 0.14, blue: 0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Keys Count
            HStack {
                Text("Hiển thị: \(adminService.filteredKeys.count) key")
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if adminService.filteredKeys.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "key.slash.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Không tìm thấy key nào")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(adminService.filteredKeys, id: \.key) { key in
                        keyRowCard(key: key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyRowCard(key: LicenseInfo) -> some View {
        let isBanned = key.status == "banned"
        let isExpired = key.expiresAt != nil && key.expiresAt! <= Int64(Date().timeIntervalSince1970 * 1000)
        let isBypass = (key.note ?? "").lowercased().contains("vượt link") || key.key.hasPrefix("PASS-")

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Key String
                Button {
                    UIPasteboard.general.string = key.key
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)
                    triggerToast("Đã copy key: \(key.key)")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(isBanned ? Color.red : (isBypass ? Color.orange : Color(red: 0.0, green: 0.85, blue: 1.0)))

                        Text(key.key)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)

                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Status Pill
                if isBanned {
                    Text("BANNED")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red.opacity(0.15).cornerRadius(4))
                } else if isExpired {
                    Text("HẾT HẠN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08).cornerRadius(4))
                } else {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15).cornerRadius(4))
                }
            }

            // Info rows
            HStack(spacing: 12) {
                Label(key.durationFormatted, systemImage: "clock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Label(key.deviceUsageFormatted, systemImage: "iphone")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(key.usedDevices.isEmpty ? .secondary : Color(red: 0.0, green: 0.85, blue: 1.0))

                if let note = key.note, !note.isEmpty {
                    Label(note, systemImage: "note.text")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Divider().background(Color.white.opacity(0.06))

            // Action Buttons Bar
            HStack(spacing: 8) {
                // Ban / Unban
                Button {
                    Task {
                        let newStatus = isBanned ? "active" : "banned"
                        let ok = await adminService.setKeyStatus(key: key.key, status: newStatus)
                        if ok { triggerToast(isBanned ? "Đã mở khóa key!" : "Đã khóa key!") }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isBanned ? "lock.open.fill" : "lock.fill")
                        Text(isBanned ? "Mở Khóa" : "Khóa")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isBanned ? Color.green : Color.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((isBanned ? Color.green : Color.orange).opacity(0.12).cornerRadius(8))
                }

                // Reset HWID
                Button {
                    Task {
                        let ok = await adminService.resetHWID(key: key.key)
                        if ok { triggerToast("Đã Reset HWID thiết bị cho key!") }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset HWID")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.12).cornerRadius(8))
                }

                Spacer()

                // Delete Button
                Button {
                    keyToDelete = key
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.red)
                        .padding(7)
                        .background(Color.red.opacity(0.12).cornerRadius(8))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isBanned ? Color.red.opacity(0.3) : (isBypass ? Color.orange.opacity(0.3) : Color.white.opacity(0.08)), lineWidth: 1)
                )
        )
    }

    // MARK: - Tab 2: Create Standard Key
    private var createStandardKeyTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TẠO KEY THƯỜNG / VIP")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))

            // Key Name (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Mã Key (Để trống nếu muốn tự sinh ngẫu nhiên)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("VD: ONIAKUMA-VIP-2026", text: $stdKeyName)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .autocapitalization(.allCharacters)

                    Button("Sinh Ngẫu Nhiên") {
                        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                        let p1 = String((0..<4).compactMap { _ in chars.randomElement() })
                        let p2 = String((0..<4).compactMap { _ in chars.randomElement() })
                        stdKeyName = "ONIAKUMA-\(p1)-\(p2)"
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                }
                .padding(12)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Duration Presets
            VStack(alignment: .leading, spacing: 6) {
                Text("Thời Hạn Key")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                let presets: [(name: String, sec: Int64)] = [
                    ("1 Giờ", 3600), ("2 Giờ", 7200), ("6 Giờ", 21600),
                    ("12 Giờ", 43200), ("1 Ngày", 86400), ("3 Ngày", 259200),
                    ("7 Ngày", 604800), ("30 Ngày", 2592000), ("Vĩnh Viễn", -1)
                ]

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(presets, id: \.sec) { p in
                        let isSel = stdSelectedPreset == p.sec
                        Button {
                            stdSelectedPreset = p.sec
                            if p.sec > 0 {
                                stdDurationHours = "\(p.sec / 3600)"
                            }
                        } label: {
                            Text(p.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(isSel ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSel ? Color(red: 0.0, green: 0.85, blue: 1.0) : Color(red: 0.12, green: 0.14, blue: 0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom Hours Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Hoặc Nhập Số Giờ Tùy Chỉnh")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Nhập số giờ (VD: 5, 8, 48, 720)...", text: $stdDurationHours)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .onChange(of: stdDurationHours) { val in
                            if let h = Int64(val), h > 0 {
                                stdSelectedPreset = h * 3600
                            }
                        }

                    Text("Giờ")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Note
            VStack(alignment: .leading, spacing: 6) {
                Text("Ghi Chú Key")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                TextField("VD: Bán cho khách VIP Facebook...", text: $stdNote)
                    .font(.system(size: 13))
                    .padding(12)
                    .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Submit Button
            Button {
                Task {
                    let sec = stdSelectedPreset
                    let (ok, created, msg) = await adminService.createKey(
                        keyText: stdKeyName.isEmpty ? nil : stdKeyName,
                        durationSeconds: sec,
                        maxDevices: stdMaxDevices,
                        note: stdNote.isEmpty ? nil : stdNote,
                        isBypass: false
                    )
                    if ok, let created {
                        triggerToast("Đã tạo & Copy key: \(created.key)")
                        stdKeyName = ""
                    } else {
                        triggerToast(msg)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if adminService.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "key.fill")
                    }
                    Text("TẠO & LƯU KEY LÊN FIREBASE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.0, green: 0.85, blue: 1.0))
                )
            }
            .buttonStyle(.plain)
            .disabled(adminService.isLoading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Tab 3: Create Bypass Link Key (3 Fields as requested)
    private var createBypassKeyTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TẠO KEY CHO NGƯỜI VƯỢT LINK (LINK4M)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.orange)

                Spacer()

                Text("FREE BYPASS")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.cornerRadius(4))
            }

            // Ô 1: Key Thật
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Ô 1: KEY THẬT (Lưu trên Database)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))

                    Spacer()

                    Button("Đổi Mã") {
                        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                        let p1 = String((0..<4).compactMap { _ in chars.randomElement() })
                        let p2 = String((0..<4).compactMap { _ in chars.randomElement() })
                        bypassRealKey = "PASS-\(p1)-\(p2)"
                        bypassDestinationKeyText = bypassRealKey
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                }

                TextField("Mã key lưu server (VD: PASS-9872-XKLA)", text: $bypassRealKey)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .autocapitalization(.allCharacters)
                    .padding(12)
                    .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
                    .onChange(of: bypassRealKey) { val in
                        bypassDestinationKeyText = val
                    }
            }

            // Ô 2: Link Vượt Link4m
            VStack(alignment: .leading, spacing: 6) {
                Text("Ô 2: LINK VƯỢT LINK4M (Để user nhấn vào)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.orange)

                TextField("VD: https://link4m.co/xY7zQw1", text: $bypassShortLink)
                    .font(.system(size: 13, design: .monospaced))
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Ô 3: Link Đích / Key Để Dán
            VStack(alignment: .leading, spacing: 6) {
                Text("Ô 3: LINK ĐÍCH / KEY ĐỂ DÁN (Cung cấp sau khi vượt link)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.green)

                HStack {
                    TextField("Nội dung key dán cho user", text: $bypassDestinationKeyText)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))

                    Button {
                        UIPasteboard.general.string = bypassDestinationKeyText
                        triggerToast("Đã copy key đích vào Clipboard!")
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .foregroundStyle(Color.green)
                    }
                }
                .padding(12)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Thời Hạn Sống Của Key Vượt Link
            VStack(alignment: .leading, spacing: 6) {
                Text("Thời Hạn Sống Key Vượt Link")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                let bypassPresets: [(name: String, sec: Int64)] = [
                    ("1 Giờ", 3600), ("2 Giờ", 7200), ("4 Giờ", 14400),
                    ("6 Giờ", 21600), ("12 Giờ", 43200), ("24 Giờ", 86400)
                ]

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(bypassPresets, id: \.sec) { p in
                        let isSel = bypassSelectedPreset == p.sec
                        Button {
                            bypassSelectedPreset = p.sec
                            bypassDurationHours = "\(p.sec / 3600)"
                        } label: {
                            Text(p.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(isSel ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSel ? Color.orange : Color(red: 0.12, green: 0.14, blue: 0.18))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Custom Hours Input for Bypass
            VStack(alignment: .leading, spacing: 6) {
                Text("Hoặc Nhập Số Giờ Tùy Chỉnh Cho Key Vượt Link")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("Nhập số giờ...", text: $bypassDurationHours)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .onChange(of: bypassDurationHours) { val in
                            if let h = Int64(val), h > 0 {
                                bypassSelectedPreset = h * 3600
                            }
                        }

                    Text("Giờ")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))
            }

            // Sync as default bypass link toggle
            Toggle(isOn: $syncAsDefaultBypassLink) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đồng bộ Link Vượt lên hệ thống")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    Text("App Client sẽ tự động mở link này khi user bấm Vượt Link")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Color.orange)
            .padding(.vertical, 4)

            // Submit Button
            Button {
                Task {
                    let sec = bypassSelectedPreset
                    let (ok, created, msg) = await adminService.createKey(
                        keyText: bypassRealKey,
                        durationSeconds: sec,
                        maxDevices: 1,
                        note: "Vượt Link (Link4m) - Hạn: \(sec / 3600)h",
                        isBypass: true
                    )

                    if syncAsDefaultBypassLink && !bypassShortLink.isEmpty {
                        _ = await adminService.updateBypassLink(bypassShortLink)
                    }

                    if ok, let created {
                        UIPasteboard.general.string = bypassShortLink.isEmpty ? created.key : bypassShortLink
                        triggerToast("Đã tạo key vượt link: \(created.key) và copy link!")
                    } else {
                        triggerToast(msg)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if adminService.isLoading {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "bolt.fill")
                    }
                    Text("TẠO & ĐỒNG BỘ KEY VƯỢT LINK")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(adminService.isLoading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Tab 4: Server Config
    private var serverConfigTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CẤU HÌNH HỆ THỐNG & LINK VƯỢT")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))

            // Current Bypass Link
            VStack(alignment: .leading, spacing: 6) {
                Text("Link Vượt Mặc Định Cho Toàn Bộ App Client")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                TextField("https://link4m.co/...", text: $customServerBypassLink)
                    .font(.system(size: 13, design: .monospaced))
                    .autocapitalization(.none)
                    .padding(12)
                    .background(Color(red: 0.09, green: 0.11, blue: 0.15).cornerRadius(10))

                Button {
                    Task {
                        let ok = await adminService.updateBypassLink(customServerBypassLink)
                        if ok {
                            triggerToast("Đã lưu Link Vượt mới lên Server!")
                        } else {
                            triggerToast("Lỗi khi lưu link!")
                        }
                    }
                } label: {
                    Text("LƯU LINK VƯỢT HỆ THỐNG")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.0, green: 0.85, blue: 1.0).cornerRadius(10))
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.08))

            // Database Endpoints Info
            VStack(alignment: .leading, spacing: 6) {
                Text("THÔNG TIN MÁY CHỦ")
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(.secondary)

                infoRow(title: "Firebase Endpoint", value: "https://ewrergdf-default-rtdb.firebaseio.com")
                infoRow(title: "Bản Quyền Ứng Dụng", value: "OniAkuma v1.1.1 (Build 7)")
                infoRow(title: "Tác Giả & Quản Trị", value: "HoangHaMod & TrongKien")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.13))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    @ViewBuilder
    private func infoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 2)
    }

    private func triggerToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.showToast = false
            }
        }
    }
}
