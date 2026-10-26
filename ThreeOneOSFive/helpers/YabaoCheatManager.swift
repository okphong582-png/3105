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

    @Published private var pendingCleanupBundles: Set<String> = []
    var needsCleanupRetry: Bool { pendingCleanupBundles.contains(selectedGame) }
    var canDisableMenu: Bool { isOnline || needsCleanupRetry }

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

    // MARK: - Menu state
    func checkInjectionState() {
        guard !isInjecting else { return }
        guard let documents = try? gameDocumentsURL(bundleID: selectedGame) else {
            isOnline = false
            statusMessage = "Menu đang tắt"
            return
        }
        let hasPatch = FileManager.default.fileExists(atPath: documents.appendingPathComponent("Assembly-CSharp-patch.bytes").path)
        let hasConfig = FileManager.default.fileExists(atPath: documents.appendingPathComponent("localConfig.json").path)
        isOnline = hasPatch && hasConfig
        if hasPatch && !hasConfig { pendingCleanupBundles.insert(selectedGame) }
        statusMessage = isOnline ? "Menu đang bật" : "Menu đang tắt"
    }

    func toggleFeature() async -> (Bool, String) {
        guard !isInjecting else { return (false, "Menu đang được xử lý. Vui lòng chờ.") }
        if canDisableMenu { return await resetFeatures() }
        return await injectFeatures()
    }

    func injectFeatures() async -> (Bool, String) {
        guard !isInjecting else { return (false, "Menu đang được xử lý. Vui lòng chờ.") }
        let bundleID = selectedGame
        isInjecting = true
        statusMessage = "Đang bật Menu…"
        defer { isInjecting = false }

        do {
            // Yield to the loader and keep activation pending for at least three seconds.
            try await Task.sleep(nanoseconds: 3_000_000_000)
            let documents = try gameDocumentsURL(bundleID: bundleID)
            guard let patchData = FeaturePayloadVault.getPatchBytesData(),
                  let configData = FeaturePayloadVault.getLocalConfigData() else {
                throw menuError("Không đọc được dữ liệu Menu.")
            }
            try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ])
            for (name, data) in [("Assembly-CSharp-patch.bytes", patchData), ("localConfig.json", configData)] {
                let target = documents.appendingPathComponent(name)
                try data.write(to: target, options: .atomic)
                try? FileManager.default.setAttributes([
                    .posixPermissions: 0o777,
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: target.path)
            }
            pendingCleanupBundles.remove(bundleID)
            isOnline = true
            statusMessage = "Menu đang bật"
            lastInjectedTime = Date()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return (true, "Đã bật Menu cho \(bundleID == "com.dts.freefiremax" ? "Free Fire MAX" : "Free Fire").")
        } catch {
            isOnline = false
            statusMessage = "Chưa bật được Menu"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return (false, "Không bật được Menu: \(error.localizedDescription)")
        }
    }

    func resetFeatures() async -> (Bool, String) {
        guard !isInjecting else { return (false, "Menu đang được xử lý. Vui lòng chờ.") }
        let bundleID = selectedGame
        isInjecting = true
        statusMessage = "Đang tắt Menu…"
        defer { isInjecting = false }
        await Task.yield()
        do {
            let documents = try gameDocumentsURL(bundleID: bundleID)
            try MenuFileCleanup.removeFiles(in: documents)
            pendingCleanupBundles.remove(bundleID)
            isOnline = false
            statusMessage = "Menu đang tắt"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return (true, "Đã tắt Menu và xóa các file Menu cùng beetalk_session.db, game_sound_config, ShaderStripSettings của \(bundleID == "com.dts.freefiremax" ? "Free Fire MAX" : "Free Fire").")
        } catch {
            pendingCleanupBundles.insert(bundleID)
            statusMessage = "Chưa tắt xong Menu"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return (false, "Chưa xóa hết file. \(error.localizedDescription)")
        }
    }

    private func gameDocumentsURL(bundleID: String) throws -> URL {
        guard ["com.dts.freefireth", "com.dts.freefiremax"].contains(bundleID),
              let path = ContainerStore.warmupAndActivateGameContainer(bundleID: bundleID),
              ContainerStore.isApplicationContainerPath(path) else {
            throw menuError("Không tìm thấy dữ liệu game đã chọn. Hãy mở game một lần trước.")
        }
        let container = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
        // Older cached lookups may point at the other FF edition. Verify identity before any writes or deletion.
        if let metadata = ContainerStore.readContainerMetadata(containerPath: container.path), !metadata.bundleID.isEmpty {
            guard metadata.bundleID == bundleID else {
                throw menuError("Thư mục dữ liệu không khớp phiên bản game đã chọn.")
            }
        } else {
            let identityPaths = [
                "Library/Preferences/\(bundleID).plist",
                "Library/Saved Application State/\(bundleID).savedState",
                "Library/Caches/\(bundleID)"
            ]
            guard identityPaths.contains(where: { FileManager.default.fileExists(atPath: container.appendingPathComponent($0).path) }) else {
                throw menuError("Chưa xác minh được thư mục của phiên bản game này. Hãy mở game rồi thử lại.")
            }
        }
        let documents = container.appendingPathComponent("Documents")
        guard documents.resolvingSymlinksInPath().deletingLastPathComponent().path == container.path else {
            throw menuError("Đường dẫn Documents không nằm trong dữ liệu game đã chọn.")
        }
        return documents
    }

    private func menuError(_ message: String) -> NSError {
        NSError(domain: "Mizze.Menu", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
