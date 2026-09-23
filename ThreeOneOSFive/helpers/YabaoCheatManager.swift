import SwiftUI
import Foundation
import UIKit

// MARK: - Aliases for Feature Menu
typealias FeatureMenuManager = YabaoCheatManager
typealias FeatureAimTarget = YabaoAimTarget

// MARK: - Mục Tiêu Ngắm (Aim Target)
enum YabaoAimTarget: String, CaseIterable, Identifiable {
    case head = "head"
    case neck = "neck"
    case chest = "chest"
    case body = "body"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .head: return "ĐẦU"
        case .neck: return "CỔ"
        case .chest: return "NGỰC"
        case .body: return "THÂN"
        }
    }

    var englishTitle: String {
        switch self {
        case .head: return "HEAD"
        case .neck: return "NECK"
        case .chest: return "CHEST"
        case .body: return "BODY"
        }
    }

    var iconName: String {
        switch self {
        case .head: return "target"
        case .neck: return "scope"
        case .chest: return "shield.lefthalf.filled"
        case .body: return "figure.stand"
        }
    }
}

// MARK: - YabaoCheatManager (Quản Lý Bật/Tắt Chức Năng YABAOCHEAT)
@MainActor
final class YabaoCheatManager: ObservableObject {
    static let shared = YabaoCheatManager()

    // Key lưu cài đặt
    private let prefix = "yabao.controls.v1."

    // 1. Game được chọn
    @Published var selectedGame: String {
        didSet { UserDefaults.standard.set(selectedGame, forKey: prefix + "selectedGame") }
    }

    // 2. Mục tiêu ngắm & Tỉ lệ
    @Published var aimTarget: YabaoAimTarget {
        didSet { UserDefaults.standard.set(aimTarget.rawValue, forKey: prefix + "aimTarget") }
    }
    @Published var headshotRate: Double {
        didSet { UserDefaults.standard.set(headshotRate, forKey: prefix + "headshotRate") }
    }
    @Published var fovRadius: Double {
        didSet { UserDefaults.standard.set(fovRadius, forKey: prefix + "fovRadius") }
    }

    // 3. Nhóm AIM & COMBAT (Trợ ngắm)
    @Published var isAutoAimLock: Bool {
        didSet { UserDefaults.standard.set(isAutoAimLock, forKey: prefix + "autoAimLock") }
    }
    @Published var isAimDragSensi: Bool {
        didSet { UserDefaults.standard.set(isAimDragSensi, forKey: prefix + "aimDragSensi") }
    }
    @Published var isAutoHeadshot: Bool {
        didSet { UserDefaults.standard.set(isAutoHeadshot, forKey: prefix + "autoHeadshot") }
    }
    @Published var isNoRecoil: Bool {
        didSet { UserDefaults.standard.set(isNoRecoil, forKey: prefix + "noRecoil") }
    }
    @Published var isAimFovCircle: Bool {
        didSet { UserDefaults.standard.set(isAimFovCircle, forKey: prefix + "aimFovCircle") }
    }

    // 4. Nhóm ESP & X-RAY (Định vị)
    @Published var isEspBox: Bool {
        didSet { UserDefaults.standard.set(isEspBox, forKey: prefix + "espBox") }
    }
    @Published var isEspLine: Bool {
        didSet { UserDefaults.standard.set(isEspLine, forKey: prefix + "espLine") }
    }
    @Published var isEspDistance: Bool {
        didSet { UserDefaults.standard.set(isEspDistance, forKey: prefix + "espDistance") }
    }
    @Published var isEspHealthBar: Bool {
        didSet { UserDefaults.standard.set(isEspHealthBar, forKey: prefix + "espHealthBar") }
    }
    @Published var isEspChamsXray: Bool {
        didSet { UserDefaults.standard.set(isEspChamsXray, forKey: prefix + "espChamsXray") }
    }
    @Published var isMiniRadar2D: Bool {
        didSet { UserDefaults.standard.set(isMiniRadar2D, forKey: prefix + "miniRadar2D") }
    }

    // 5. Nhóm TIỆN ÍCH & AN TOÀN (Safe & Extra)
    @Published var isNoGrassFog: Bool {
        didSet { UserDefaults.standard.set(isNoGrassFog, forKey: prefix + "noGrassFog") }
    }
    @Published var isFastBullet: Bool {
        didSet { UserDefaults.standard.set(isFastBullet, forKey: prefix + "fastBullet") }
    }
    @Published var isAntiBanSafe: Bool {
        didSet { UserDefaults.standard.set(isAntiBanSafe, forKey: prefix + "antiBanSafe") }
    }
    @Published var isSafeRankMode: Bool {
        didSet { UserDefaults.standard.set(isSafeRankMode, forKey: prefix + "safeRankMode") }
    }

    // 6. Trạng thái thực thi
    @Published var isOnline: Bool = false
    @Published var isInjecting: Bool = false
    @Published var statusMessage: String = "TRẠNG THÁI : OFFLINE"
    @Published var lastInjectedTime: Date? = nil

    private init() {
        let defaults = UserDefaults.standard
        let targetRaw = defaults.string(forKey: prefix + "aimTarget") ?? YabaoAimTarget.head.rawValue
        self.aimTarget = YabaoAimTarget(rawValue: targetRaw) ?? .head
        self.selectedGame = defaults.string(forKey: prefix + "selectedGame") ?? "com.dts.freefireth"

        let savedRate = defaults.double(forKey: prefix + "headshotRate")
        self.headshotRate = savedRate > 0 ? savedRate : 100.0

        let savedRadius = defaults.double(forKey: prefix + "fovRadius")
        self.fovRadius = savedRadius > 0 ? savedRadius : 60.0

        // Giá trị mặc định bật các chức năng hữu ích
        self.isAutoAimLock = defaults.object(forKey: prefix + "autoAimLock") as? Bool ?? true
        self.isAimDragSensi = defaults.object(forKey: prefix + "aimDragSensi") as? Bool ?? true
        self.isAutoHeadshot = defaults.object(forKey: prefix + "autoHeadshot") as? Bool ?? true
        self.isNoRecoil = defaults.object(forKey: prefix + "noRecoil") as? Bool ?? true
        self.isAimFovCircle = defaults.object(forKey: prefix + "aimFovCircle") as? Bool ?? true

        self.isEspBox = defaults.object(forKey: prefix + "espBox") as? Bool ?? true
        self.isEspLine = defaults.object(forKey: prefix + "espLine") as? Bool ?? true
        self.isEspDistance = defaults.object(forKey: prefix + "espDistance") as? Bool ?? true
        self.isEspHealthBar = defaults.object(forKey: prefix + "espHealthBar") as? Bool ?? true
        self.isEspChamsXray = defaults.object(forKey: prefix + "espChamsXray") as? Bool ?? true
        self.isMiniRadar2D = defaults.object(forKey: prefix + "miniRadar2D") as? Bool ?? true

        self.isNoGrassFog = defaults.object(forKey: prefix + "noGrassFog") as? Bool ?? false
        self.isFastBullet = defaults.object(forKey: prefix + "fastBullet") as? Bool ?? false
        self.isAntiBanSafe = defaults.object(forKey: prefix + "antiBanSafe") as? Bool ?? true
        self.isSafeRankMode = defaults.object(forKey: prefix + "safeRankMode") as? Bool ?? true

        // Kiểm tra nhanh xem container đã có patch file chưa
        checkInjectionState()
    }

    // MARK: - Kiểm tra trạng thái hiện tại trong container game
    func checkInjectionState() {
        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: selectedGame) else {
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
            return
        }
        let patchURL = URL(fileURLWithPath: containerPath)
            .appendingPathComponent("Documents")
            .appendingPathComponent("Assembly-CSharp-patch.bytes")
        if FileManager.default.fileExists(atPath: patchURL.path) {
            self.isOnline = true
            self.statusMessage = "TRẠNG THÁI : ONLINE"
        } else {
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
        }
    }

    // MARK: - Tiêm Chức Năng YABAO (INJECT)
    func injectFeatures() async -> (Bool, String) {
        self.isInjecting = true
        self.statusMessage = "ĐANG TIÊM..."

        // Tự động kích hoạt quyền traversal & lease container game
        ContainerStore.warmupAndActivateGameContainer(bundleID: selectedGame)

        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: selectedGame) else {
            self.isInjecting = false
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
            return (false, "Không tìm thấy dữ liệu game \(selectedGame == "com.dts.freefiremax" ? "Free Fire MAX" : "Free Fire Thường"). Hãy mở game một lần trước.")
        }

        let containerURL = URL(fileURLWithPath: containerPath)
        let documentsURL = containerURL.appendingPathComponent("Documents")
        let patchURL = documentsURL.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let configBinURL = documentsURL.appendingPathComponent("config.bin")
        let configJsonURL = documentsURL.appendingPathComponent("localConfig.json")

        do {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ])

            // 1. NẠP FILE HOOK CHÍNH (Assembly-CSharp-patch.bytes 53,235 bytes từ In-Memory Vault Chống Trộm)
            var patchData: Data? = FeaturePayloadVault.getPatchBytesData()
            if patchData == nil {
                // Fallback trích xuất nếu có
                if let espProject = StealthPatchVault.loadProject(for: .esp) {
                    for rule in espProject.rules {
                        if rule.relativePath.hasSuffix("Assembly-CSharp-patch.bytes") {
                            patchData = rule.replacementData
                            break
                        }
                    }
                }
            }

            if let data = patchData {
                if FileManager.default.fileExists(atPath: patchURL.path) {
                    try? FileManager.default.removeItem(at: patchURL)
                }
                try data.write(to: patchURL, options: .atomic)
                try? FileManager.default.setAttributes([
                    .posixPermissions: 0o777,
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: patchURL.path)
            }

            // 2. GHI CẤU HÌNH LOCALCONFIG.JSON (Khởi tạo từ In-Memory Vault chuẩn + Bật/Tắt Dynamic)
            var localConfigDict: [String: Any] = [
                "_ffxc_session": "47b93c16f465468fbdf74b04433010c6",
                "testCodePatch": true
            ]
            if let baseConfigData = FeaturePayloadVault.getLocalConfigData(),
               let parsed = try? JSONSerialization.jsonObject(with: baseConfigData, options: []) as? [String: Any] {
                for (k, v) in parsed {
                    localConfigDict[k] = v
                }
            }

            localConfigDict["testCodePatch"] = true
            localConfigDict["resetGuest"] = true
            localConfigDict["aim_target"] = aimTarget.rawValue
            localConfigDict["headshot"] = isAutoHeadshot
            localConfigDict["headshot_rate"] = headshotRate
            localConfigDict["radius"] = fovRadius
            localConfigDict["aim_lock"] = isAutoAimLock
            localConfigDict["aim_drag"] = isAimDragSensi
            localConfigDict["no_recoil"] = isNoRecoil
            localConfigDict["fov_circle"] = isAimFovCircle
            localConfigDict["esp_box"] = isEspBox
            localConfigDict["esp_line"] = isEspLine
            localConfigDict["esp_distance"] = isEspDistance
            localConfigDict["esp_health"] = isEspHealthBar
            localConfigDict["esp_chams"] = isEspChamsXray
            localConfigDict["radar"] = isMiniRadar2D
            localConfigDict["no_grass"] = isNoGrassFog
            localConfigDict["antiban"] = isAntiBanSafe
            localConfigDict["fast_bullet"] = isFastBullet
            localConfigDict["safe_rank"] = isSafeRankMode
            localConfigDict["timestamp"] = Date().timeIntervalSince1970

            if let jsonData = try? JSONSerialization.data(withJSONObject: localConfigDict, options: [.prettyPrinted]) {
                if FileManager.default.fileExists(atPath: configJsonURL.path) {
                    try? FileManager.default.removeItem(at: configJsonURL)
                }
                try jsonData.write(to: configJsonURL, options: .atomic)
                try? FileManager.default.setAttributes([
                    .posixPermissions: 0o777,
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: configJsonURL.path)
            }

            // 3. NẠP FILE NHỊ PHÂN CẤU HÌNH (config.bin 21 bytes)
            let configBinData = Data([
                0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x78, 0x00,
                0x01, 0x01, 0x00, 0x00, 0x05, 0x0a, 0x4b, 0x00,
                0x01, 0x0a, 0x00, 0x00, 0x00
            ])
            if FileManager.default.fileExists(atPath: configBinURL.path) {
                try? FileManager.default.removeItem(at: configBinURL)
            }
            try? configBinData.write(to: configBinURL, options: .atomic)
            try? FileManager.default.setAttributes([
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ], ofItemAtPath: configBinURL.path)

            // 4. TIÊM CACHE_RES DÀNH CHO AIM & HEADSHOT THEO VỊ TRÍ GHIM TÂM
            let aimTag: StealthPatchVault.ResourceTag
            switch aimTarget {
            case .head:
                aimTag = isAimDragSensi ? .aimDrag : .aimNeck
            case .neck:
                aimTag = .aimNeck
            case .chest:
                aimTag = .aimChest
            case .body:
                aimTag = .aimBody
            }
            if let aimProject = StealthPatchVault.loadProject(for: aimTag) {
                applyRulesDirectly(rules: aimProject.rules, toContainer: containerURL)
            }

            // 5. TIÊM SHADERS CHO ĐỊNH VỊ ESP CHAMS & RADAR (NẾU BẬT)
            if isEspChamsXray || isMiniRadar2D {
                if let locatorProject = StealthPatchVault.loadProject(for: .locator) {
                    applyRulesDirectly(rules: locatorProject.rules, toContainer: containerURL)
                }
            }

            // Cập nhật trạng thái
            self.isInjecting = false
            self.isOnline = true
            self.statusMessage = "TRẠNG THÁI : ONLINE"
            self.lastInjectedTime = Date()

            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)

            return (true, "Tiêm Menu Tính Năng VIP Pro Max thành công! Mở game để trải nghiệm.")
        } catch {
            self.isInjecting = false
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"

            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)

            return (false, "Lỗi tiêm: \(error.localizedDescription)")
        }
    }

    // MARK: - Ghi đè trực tiếp các file rules vào container
    private func applyRulesDirectly(rules: [PatchRule], toContainer containerURL: URL) {
        for rule in rules {
            // Chuẩn hóa relative path
            var rel = rule.relativePath
            if rel.hasPrefix("/") { rel.removeFirst() }

            let targetURL = containerURL.appendingPathComponent(rel)
            let parentDir = targetURL.deletingLastPathComponent()

            try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ])

            if FileManager.default.fileExists(atPath: targetURL.path) {
                try? FileManager.default.removeItem(at: targetURL)
            }

            do {
                try rule.replacementData.write(to: targetURL, options: .atomic)
                try? FileManager.default.setAttributes([
                    .posixPermissions: 0o777,
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: targetURL.path)
            } catch {
                log("yabao: không thể ghi rule \(rel): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Đặt Lại / Khôi Phục (RESET)
    func resetFeatures() async -> (Bool, String) {
        ContainerStore.warmupAndActivateGameContainer(bundleID: selectedGame)

        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: selectedGame) else {
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
            return (true, "Đã đặt lại cấu hình sạch.")
        }

        let containerURL = URL(fileURLWithPath: containerPath)
        let documentsURL = containerURL.appendingPathComponent("Documents")
        let patchURL = documentsURL.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let configBinURL = documentsURL.appendingPathComponent("config.bin")
        let configJsonURL = documentsURL.appendingPathComponent("localConfig.json")

        if FileManager.default.fileExists(atPath: patchURL.path) {
            try? FileManager.default.removeItem(at: patchURL)
        }
        if FileManager.default.fileExists(atPath: configBinURL.path) {
            try? FileManager.default.removeItem(at: configBinURL)
        }
        if FileManager.default.fileExists(atPath: configJsonURL.path) {
            try? FileManager.default.removeItem(at: configJsonURL)
        }

        // Xóa cache_res mod nếu có
        let compulsoryURL = documentsURL.appendingPathComponent("contentcache/Compulsory/ios/gameassetbundles")
        let cacheResURL = compulsoryURL.appendingPathComponent("cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D")
        if FileManager.default.fileExists(atPath: cacheResURL.path) {
            try? FileManager.default.removeItem(at: cacheResURL)
        }

        // Xóa shaders mod nếu có
        let optionalURL = documentsURL.appendingPathComponent("contentcache/Optional/ios/gameassetbundles")
        let shadersURL = optionalURL.appendingPathComponent("shaders.RXqs706xmtWYhbN9TqDzP8LDRzk~3D")
        if FileManager.default.fileExists(atPath: shadersURL.path) {
            try? FileManager.default.removeItem(at: shadersURL)
        }

        self.isOnline = false
        self.statusMessage = "TRẠNG THÁI : OFFLINE"

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)

        return (true, "Đã xóa toàn bộ file patch, game đã trở về trạng thái sạch nguyên bản.")
    }
}
