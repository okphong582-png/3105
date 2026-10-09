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

    // MARK: - Bật / Tắt 1 Nút Duy Nhất (Single Master Toggle)
    func toggleFeature() async -> (Bool, String) {
        if isOnline {
            return await resetFeatures()
        } else {
            return await injectFeatures()
        }
    }

    // MARK: - Kích Hoạt 2 File Duy Nhất Vào Documents (Assembly-CSharp-patch.bytes & localConfig.json)
    func injectFeatures() async -> (Bool, String) {
        self.isInjecting = true
        self.statusMessage = "ĐANG BẬT..."

        // Kích hoạt container quyền truy cập
        ContainerStore.warmupAndActivateGameContainer(bundleID: selectedGame)

        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: selectedGame) else {
            self.isInjecting = false
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
            let targetName = selectedGame == "com.dts.freefiremax" ? "Free Fire MAX" : "Free Fire Thường"
            return (false, "Không tìm thấy dữ liệu game \(targetName). Hãy mở game một lần trước.")
        }

        let containerURL = URL(fileURLWithPath: containerPath)
        let documentsURL = containerURL.appendingPathComponent("Documents")
        let patchURL = documentsURL.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let configJsonURL = documentsURL.appendingPathComponent("localConfig.json")

        do {
            try FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ])

            // 1. Kích hoạt FILE 1: Assembly-CSharp-patch.bytes (53,235 bytes từ Vault Chống Trộm)
            guard let patchData = FeaturePayloadVault.getPatchBytesData() else {
                self.isInjecting = false
                return (false, "Không thể giải mã dữ liệu patch từ Vault.")
            }
            if FileManager.default.fileExists(atPath: patchURL.path) {
                try? FileManager.default.removeItem(at: patchURL)
            }
            try patchData.write(to: patchURL, options: .atomic)
            try? FileManager.default.setAttributes([
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ], ofItemAtPath: patchURL.path)

            // 2. Kích hoạt FILE 2: localConfig.json (84 bytes từ Vault Chống Trộm)
            guard let configData = FeaturePayloadVault.getLocalConfigData() else {
                self.isInjecting = false
                return (false, "Không thể giải mã cấu hình từ Vault.")
            }
            if FileManager.default.fileExists(atPath: configJsonURL.path) {
                try? FileManager.default.removeItem(at: configJsonURL)
            }
            try configData.write(to: configJsonURL, options: .atomic)
            try? FileManager.default.setAttributes([
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ], ofItemAtPath: configJsonURL.path)

            // Cập nhật trạng thái
            self.isInjecting = false
            self.isOnline = true
            self.statusMessage = "TRẠNG THÁI : ONLINE"
            self.lastInjectedTime = Date()

            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)

            return (true, "Đã KÍCH HOẠT tính năng thành công! Dữ liệu tối ưu đã sẵn sàng trong Documents.")
        } catch {
            self.isInjecting = false
            self.isOnline = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"

            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)

            return (false, "Lỗi bật tính năng: \(error.localizedDescription)")
        }
    }

    // MARK: - Tắt Tính Năng (Xóa 2 File Khỏi Documents)
    func resetFeatures() async -> (Bool, String) {
        self.isInjecting = true
        self.statusMessage = "ĐANG TẮT..."

        ContainerStore.warmupAndActivateGameContainer(bundleID: selectedGame)

        guard let containerPath = ContainerStore.resolveAppContainerPath(bundleID: selectedGame) else {
            self.isOnline = false
            self.isInjecting = false
            self.statusMessage = "TRẠNG THÁI : OFFLINE"
            return (true, "Đã tắt tính năng.")
        }

        let containerURL = URL(fileURLWithPath: containerPath)
        let documentsURL = containerURL.appendingPathComponent("Documents")
        let patchURL = documentsURL.appendingPathComponent("Assembly-CSharp-patch.bytes")
        let configJsonURL = documentsURL.appendingPathComponent("localConfig.json")
        let configBinURL = documentsURL.appendingPathComponent("config.bin")

        if FileManager.default.fileExists(atPath: patchURL.path) {
            try? FileManager.default.removeItem(at: patchURL)
        }
        if FileManager.default.fileExists(atPath: configJsonURL.path) {
            try? FileManager.default.removeItem(at: configJsonURL)
        }
        if FileManager.default.fileExists(atPath: configBinURL.path) {
            try? FileManager.default.removeItem(at: configBinURL)
        }

        // Xóa sạch cache nếu có
        let compulsoryURL = documentsURL.appendingPathComponent("contentcache/Compulsory/ios/gameassetbundles")
        let cacheResURL = compulsoryURL.appendingPathComponent("cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D")
        if FileManager.default.fileExists(atPath: cacheResURL.path) {
            try? FileManager.default.removeItem(at: cacheResURL)
        }

        self.isInjecting = false
        self.isOnline = false
        self.statusMessage = "TRẠNG THÁI : OFFLINE"

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.warning)

        return (true, "Đã HỦY KÍCH HOẠT tính năng! File game đã trở về trạng thái gốc sạch sẽ.")
    }
}
