import Foundation
import UIKit
import Security

// MARK: - License Models
struct LicenseInfo: Codable {
    var key: String
    var status: String // "active", "banned", "expired"
    var duration: String // "1h", "1d", "1w", "1m", "1y", "lifetime"
    var durationSeconds: Int64
    var maxDevices: Int
    var usedDevices: [String]
    var createdAt: Int64
    var activatedAt: Int64?
    var expiresAt: Int64?
    var note: String?
    var tier: String? // "bypass" or "premium"

    enum CodingKeys: String, CodingKey {
        case key, status, duration, durationSeconds, maxDevices, usedDevices, createdAt, activatedAt, expiresAt, note, tier
    }

    init(
        key: String,
        status: String = "active",
        duration: String = "1d",
        durationSeconds: Int64 = 86400,
        maxDevices: Int = 1,
        usedDevices: [String] = [],
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        activatedAt: Int64? = nil,
        expiresAt: Int64? = nil,
        note: String? = nil,
        tier: String? = nil
    ) {
        self.key = key
        self.status = status
        self.duration = duration
        self.durationSeconds = durationSeconds
        self.maxDevices = maxDevices
        self.usedDevices = usedDevices
        self.createdAt = createdAt
        self.activatedAt = activatedAt
        self.expiresAt = expiresAt
        self.note = note
        self.tier = tier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.key = (try? container.decode(String.self, forKey: .key)) ?? ""
        self.status = (try? container.decode(String.self, forKey: .status)) ?? "active"
        self.duration = (try? container.decode(String.self, forKey: .duration)) ?? "1d"

        if let sec = try? container.decode(Int64.self, forKey: .durationSeconds) {
            self.durationSeconds = sec
        } else if let secInt = try? container.decode(Int.self, forKey: .durationSeconds) {
            self.durationSeconds = Int64(secInt)
        } else if let secStr = try? container.decode(String.self, forKey: .durationSeconds), let secVal = Int64(secStr) {
            self.durationSeconds = secVal
        } else {
            self.durationSeconds = 86400
        }

        if let maxDev = try? container.decode(Int.self, forKey: .maxDevices) {
            self.maxDevices = maxDev
        } else if let maxDevStr = try? container.decode(String.self, forKey: .maxDevices), let maxVal = Int(maxDevStr) {
            self.maxDevices = maxVal
        } else {
            self.maxDevices = 1
        }

        if let devList = try? container.decode([String].self, forKey: .usedDevices) {
            self.usedDevices = devList
        } else if let devDict = try? container.decode([String: String].self, forKey: .usedDevices) {
            self.usedDevices = Array(devDict.values)
        } else {
            self.usedDevices = []
        }

        if let created = try? container.decode(Int64.self, forKey: .createdAt) {
            self.createdAt = created
        } else if let createdInt = try? container.decode(Int.self, forKey: .createdAt) {
            self.createdAt = Int64(createdInt)
        } else {
            self.createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        }

        if let act = try? container.decode(Int64.self, forKey: .activatedAt) {
            self.activatedAt = act
        } else if let actInt = try? container.decode(Int.self, forKey: .activatedAt) {
            self.activatedAt = Int64(actInt)
        } else {
            self.activatedAt = nil
        }

        if let exp = try? container.decode(Int64.self, forKey: .expiresAt) {
            self.expiresAt = exp
        } else if let expInt = try? container.decode(Int.self, forKey: .expiresAt) {
            self.expiresAt = Int64(expInt)
        } else {
            self.expiresAt = nil
        }

        self.note = try? container.decode(String.self, forKey: .note)
        self.tier = try? container.decode(String.self, forKey: .tier)
    }

    init(dict: [String: Any], fallbackKey: String) {
        self.key = (dict["key"] as? String) ?? fallbackKey
        self.status = (dict["status"] as? String) ?? "active"
        self.duration = (dict["duration"] as? String) ?? "1d"
        
        if let sec = dict["durationSeconds"] as? Int64 {
            self.durationSeconds = sec
        } else if let sec = dict["durationSeconds"] as? Int {
            self.durationSeconds = Int64(sec)
        } else if let sec = dict["durationSeconds"] as? NSNumber {
            self.durationSeconds = sec.int64Value
        } else if let secStr = dict["durationSeconds"] as? String, let val = Int64(secStr) {
            self.durationSeconds = val
        } else {
            self.durationSeconds = 86400
        }

        if let maxDev = dict["maxDevices"] as? Int {
            self.maxDevices = maxDev
        } else if let maxDev = dict["maxDevices"] as? NSNumber {
            self.maxDevices = maxDev.intValue
        } else if let maxDevStr = dict["maxDevices"] as? String, let val = Int(maxDevStr) {
            self.maxDevices = val
        } else {
            self.maxDevices = 1
        }

        if let devs = dict["usedDevices"] as? [String] {
            self.usedDevices = devs
        } else if let devsDict = dict["usedDevices"] as? [String: String] {
            self.usedDevices = Array(devsDict.values)
        } else if let devsObj = dict["usedDevices"] as? [Any] {
            self.usedDevices = devsObj.compactMap { "\($0)" }
        } else {
            self.usedDevices = []
        }

        if let created = dict["createdAt"] as? NSNumber {
            self.createdAt = created.int64Value
        } else if let created = dict["createdAt"] as? Int64 {
            self.createdAt = created
        } else {
            self.createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        }

        if let act = dict["activatedAt"] as? NSNumber {
            self.activatedAt = act.int64Value
        } else if let act = dict["activatedAt"] as? Int64 {
            self.activatedAt = act
        } else {
            self.activatedAt = nil
        }

        if let exp = dict["expiresAt"] as? NSNumber {
            self.expiresAt = exp.int64Value
        } else if let exp = dict["expiresAt"] as? Int64 {
            self.expiresAt = exp
        } else {
            self.expiresAt = nil
        }

        self.note = dict["note"] as? String
        self.tier = dict["tier"] as? String
    }

    var isLifetime: Bool {
        duration == "lifetime" || durationSeconds == -1 || expiresAt == -1
    }

    var isExpired: Bool {
        if isLifetime { return false }
        guard let exp = expiresAt, exp > 0 else { return false }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now > exp
    }

    var isBypassTier: Bool {
        if let t = tier?.lowercased(), t == "bypass" { return true }
        if let t = tier?.lowercased(), t == "premium" { return false }
        return key.uppercased().hasPrefix("PASS-") ||
               (note ?? "").lowercased().contains("vượt link") ||
               (note ?? "").lowercased().contains("link4m")
    }

    var isPremiumTier: Bool { !isBypassTier }
    var canUseMods: Bool { isPremiumTier }
    var tierBadgeText: String { isPremiumTier ? "👑 PREMIUM VIP" : "⚡ FREE VƯỢT LINK" }

    var remainingTimeFormatted: String {
        if isLifetime { return "Vĩnh Viễn" }
        guard let exp = expiresAt, exp > 0 else {
            return formatDurationString(durationSeconds)
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let diffMs = exp - now
        if diffMs <= 0 { return "Đã hết hạn" }

        let diffSec = diffMs / 1000
        let days = diffSec / 86400
        let hours = (diffSec % 86400) / 3600
        let minutes = (diffSec % 3600) / 60

        if days > 0 {
            return "\(days) ngày \(hours) giờ"
        } else if hours > 0 {
            return "\(hours) giờ \(minutes) phút"
        } else {
            return "\(max(1, minutes)) phút"
        }
    }

    var deviceUsageFormatted: String {
        let current = usedDevices.count
        return "\(current)/\(maxDevices) thiết bị"
    }

    var durationFormatted: String {
        formatDurationString(durationSeconds)
    }

    private func formatDurationString(_ seconds: Int64) -> String {
        if seconds == -1 { return "Vĩnh Viễn" }
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        if days > 0 { return "\(days) ngày" }
        if hours > 0 { return "\(hours) giờ" }
        return "\(seconds / 60) phút"
    }
}

struct ActivationResult {
    let success: Bool
    let message: String
    let remaining: String
    let devices: String
}

// MARK: - License Manager
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published var isAuthorized: Bool = false
    @Published var currentLicense: LicenseInfo? = nil
    @Published var isVerifying: Bool = false
    @Published var lastErrorMessage: String? = nil
    @Published var isSystemMaintenance: Bool = false
    @Published var maintenanceMessage: String = "Hệ thống đang tạm ngắt kết nối / bảo trì bởi Quản Trị Viên. Vui lòng quay lại sau!"
    @Published var bypassLink: String = "https://link4m.co"
    @Published var bypassKeys: [LicenseInfo] = []
    @Published var isLoadingBypassKeys: Bool = false

    private let storageKey = "oni_akuma_active_license_v2"
    private let savedKeyStringKey = "oni_akuma_saved_raw_key"
    private var heartbeatTimer: Timer?
    
    // Obfuscated Firebase Realtime Database Base URL
    // https://ewrergdf-default-rtdb.firebaseio.com
    private var databaseEndpoint: String {
        let part1 = "https://"
        let part2 = "ewrergdf-default-rtdb"
        let part3 = ".firebaseio.com/keys"
        return "\(part1)\(part2)\(part3)"
    }

    private var configEndpoint: String {
        let part1 = "https://"
        let part2 = "ewrergdf-default-rtdb"
        let part3 = ".firebaseio.com/config.json"
        return "\(part1)\(part2)\(part3)"
    }

    var deviceHWID: String {
        if let vendor = UIDevice.current.identifierForVendor?.uuidString {
            return vendor
        }
        let fallbackKey = "oni_akuma_persistent_hwid"
        if let stored = UserDefaults.standard.string(forKey: fallbackKey) {
            return stored
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: fallbackKey)
        return generated
    }

    init() {
        loadCachedLicense()
        startHeartbeat()
    }

    // MARK: - Check System Maintenance & Bypass Link (Kill Switch)
    @MainActor
    func checkSystemMaintenance() async -> Bool {
        guard let url = URL(string: configEndpoint) else { return false }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 6.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return isSystemMaintenance
            }

            let isMaint = (dict["is_maintenance"] as? Bool) ?? (dict["app_killed"] as? Bool) ?? false
            if let msg = dict["maintenance_message"] as? String, !msg.isEmpty {
                self.maintenanceMessage = msg
            }
            if let link = dict["bypass_link"] as? String, !link.isEmpty {
                self.bypassLink = link
            }
            self.isSystemMaintenance = isMaint
            return isMaint
        } catch {
            return isSystemMaintenance
        }
    }

    // MARK: - Fetch Bypass Keys from Firebase (Kho Key Vượt Link)
    @MainActor
    func fetchBypassKeys() async {
        isLoadingBypassKeys = true
        defer { isLoadingBypassKeys = false }

        guard let url = URL(string: "\(databaseEndpoint).json") else { return }
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 8.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }

            var result: [LicenseInfo] = []
            for (key, val) in dict {
                if let keyDict = val as? [String: Any] {
                    let info = LicenseInfo(dict: keyDict, fallbackKey: key)
                    if info.isBypassTier && !info.isExpired && info.status != "banned" {
                        result.append(info)
                    }
                }
            }
            result.sort { $0.createdAt > $1.createdAt }
            self.bypassKeys = result
        } catch {
            // log error
        }
    }

    func openBypassLink() {
        let target = bypassLink.isEmpty ? "https://link4m.co" : bypassLink
        if let url = URL(string: target) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    // MARK: - Realtime Heartbeat Monitoring (Instant Kickout on Delete/Expire/Maintenance)
    func startHeartbeat() {
        stopHeartbeat()
        DispatchQueue.main.async { [weak self] in
            self?.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    _ = await self.checkSystemMaintenance()
                    // ONLY recheck license if user is currently authorized with an active key!
                    if self.isAuthorized && self.currentLicense != nil {
                        _ = await self.recheckLicense()
                    }
                }
            }
        }
    }

    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    // MARK: - Load Cache
    private func loadCachedLicense() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let info = try? JSONDecoder().decode(LicenseInfo.self, from: data) else {
            isAuthorized = false
            currentLicense = nil
            return
        }

        if info.status == "banned" || info.isExpired {
            clearCachedLicense()
            isAuthorized = false
            currentLicense = nil
        } else {
            currentLicense = info
            isAuthorized = true
        }
    }

    // MARK: - Activate / Login Key
    @MainActor
    func activateKey(_ rawKey: String) async -> ActivationResult {
        let cleaned = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty else {
            let msg = "Vui lòng nhập mã bản quyền (Key)!"
            lastErrorMessage = msg
            return ActivationResult(success: false, message: msg, remaining: "", devices: "")
        }

        // 1. Check Kill Switch / Maintenance
        let isMaint = await checkSystemMaintenance()
        if isMaint {
            let msg = maintenanceMessage
            lastErrorMessage = msg
            return ActivationResult(success: false, message: msg, remaining: "", devices: "")
        }

        isVerifying = true
        defer { isVerifying = false }

        // Sanitize key for Firebase path
        let sanitizedKey = cleaned
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
            .replacingOccurrences(of: "/", with: "_")

        guard let requestURL = URL(string: "\(databaseEndpoint)/\(sanitizedKey).json") else {
            let msg = "Đường dẫn xác thực không hợp lệ!"
            lastErrorMessage = msg
            return ActivationResult(success: false, message: msg, remaining: "", devices: "")
        }

        do {
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 10.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let msg = "Không thể kết nối máy chủ xác thực! (Mã: \((response as? HTTPURLResponse)?.statusCode ?? 0))"
                lastErrorMessage = msg
                return ActivationResult(success: false, message: msg, remaining: "", devices: "")
            }

            let textContent = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if data.isEmpty || textContent == "null" || textContent == "{}" {
                let msg = "Key không tồn tại hoặc đã bị xoá bởi Admin!"
                lastErrorMessage = msg
                return ActivationResult(success: false, message: msg, remaining: "", devices: "")
            }

            // Parse robustly from JSON dictionary
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let dict = jsonObject, !dict.isEmpty else {
                let msg = "Key không tồn tại hoặc đã bị xoá bởi Admin!"
                lastErrorMessage = msg
                return ActivationResult(success: false, message: msg, remaining: "", devices: "")
            }

            var license = LicenseInfo(dict: dict, fallbackKey: cleaned)
            if license.key.isEmpty { license.key = cleaned }

            // Check Banned
            if license.status == "banned" {
                let msg = "Key này đã bị khoá / vô hiệu hoá bởi quản trị viên!"
                lastErrorMessage = msg
                return ActivationResult(success: false, message: msg, remaining: "", devices: "")
            }

            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let currentHWID = deviceHWID

            // Check if First Time Activation
            if license.activatedAt == nil || license.activatedAt == 0 {
                license.activatedAt = now
                if license.isLifetime {
                    license.expiresAt = -1
                } else {
                    license.expiresAt = now + (license.durationSeconds * 1000)
                }
                license.usedDevices = [currentHWID]
                license.status = "active"

                // Push update to Firebase
                try await patchLicenseToFirebase(key: sanitizedKey, license: license)
            } else {
                // Already activated before -> Check Expiration
                if license.isExpired {
                    license.status = "expired"
                    _ = try? await patchLicenseToFirebase(key: sanitizedKey, license: license)
                    let msg = "Key đã hết hạn sử dụng!"
                    lastErrorMessage = msg
                    return ActivationResult(success: false, message: msg, remaining: "", devices: "")
                }

                // Check Device HWID
                if !license.usedDevices.contains(currentHWID) {
                    if license.usedDevices.count < license.maxDevices {
                        license.usedDevices.append(currentHWID)
                        try await patchLicenseToFirebase(key: sanitizedKey, license: license)
                    } else {
                        let msg = "Key đã đạt giới hạn tối đa (\(license.maxDevices) thiết bị)! Vui lòng liên hệ Admin để reset thiết bị."
                        lastErrorMessage = msg
                        return ActivationResult(success: false, message: msg, remaining: "", devices: "")
                    }
                }
            }

            // Save to Local Cache
            saveLicenseLocally(license, rawKey: cleaned)
            self.currentLicense = license
            self.isAuthorized = true
            self.lastErrorMessage = nil

            let remain = license.remainingTimeFormatted
            let devs = license.deviceUsageFormatted
            let tierName = license.tierBadgeText
            return ActivationResult(success: true, message: "Kích hoạt \(tierName) thành công!", remaining: remain, devices: devs)

        } catch {
            let msg = "Lỗi xác thực: \(error.localizedDescription)"
            lastErrorMessage = msg
            return ActivationResult(success: false, message: msg, remaining: "", devices: "")
        }
    }

    // MARK: - Recheck License Silently (Returns true if valid, false if revoked/expired)
    @MainActor
    @discardableResult
    func recheckLicense() async -> Bool {
        // Check maintenance first
        let isMaint = await checkSystemMaintenance()
        if isMaint {
            return false
        }

        guard let savedRawKey = UserDefaults.standard.string(forKey: savedKeyStringKey),
              !savedRawKey.isEmpty else {
            // User hasn't saved or activated a key yet - do NOT call logout() or reset layers!
            return false
        }

        let sanitizedKey = savedRawKey
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
            .replacingOccurrences(of: "/", with: "_")

        guard let requestURL = URL(string: "\(databaseEndpoint)/\(sanitizedKey).json") else {
            logout(reason: "Đường dẫn Key không hợp lệ!")
            return false
        }

        do {
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 8.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                if let cached = currentLicense, cached.isExpired {
                    logout(reason: "Key bản quyền đã hết hạn sử dụng!")
                    return false
                }
                return isAuthorized
            }

            let textContent = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if data.isEmpty || textContent == "null" || textContent == "{}" {
                logout(reason: "Key không tồn tại hoặc đã bị xoá bởi Admin!")
                return false
            }

            guard let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any], !dict.isEmpty else {
                logout(reason: "Key không tồn tại hoặc đã bị xoá bởi Admin!")
                return false
            }

            var license = LicenseInfo(dict: dict, fallbackKey: savedRawKey)
            if license.key.isEmpty { license.key = savedRawKey }

            let currentHWID = deviceHWID

            if license.status == "banned" {
                logout(reason: "Key đã bị khoá / vô hiệu hoá bởi Admin!")
                return false
            }

            if license.isExpired || license.status == "expired" {
                logout(reason: "Key bản quyền đã hết hạn sử dụng!")
                return false
            }

            if !license.usedDevices.contains(currentHWID) {
                logout(reason: "Mã thiết bị không khớp với Key bản quyền!")
                return false
            }

            saveLicenseLocally(license, rawKey: savedRawKey)
            self.currentLicense = license
            self.isAuthorized = true
            return true

        } catch {
            if let cached = currentLicense, cached.isExpired {
                logout(reason: "Key bản quyền đã hết hạn sử dụng!")
                return false
            }
            return isAuthorized
        }
    }

    // MARK: - Logout / Remove Key / Reset Security Layers
    func logout(reason: String? = nil) {
        clearCachedLicense()
        MultiLayerSecurityService.shared.passedLayers.remove(SecurityGateLayer.layer2_licenseKey.rawValue)
        MultiLayerSecurityService.shared.passedLayers.remove(SecurityGateLayer.layer3_securityPin.rawValue)
        MultiLayerSecurityService.shared.passedLayers.remove(SecurityGateLayer.layer4_antiBotChallenge.rawValue)
        MultiLayerSecurityService.shared.passedLayers.remove(SecurityGateLayer.layer5_coreDecryption.rawValue)
        MultiLayerSecurityService.shared.isFullyUnlocked = false
        MultiLayerSecurityService.shared.advanceToNextLayer()

        DispatchQueue.main.async {
            self.isAuthorized = false
            self.currentLicense = nil
            if let reason = reason {
                self.lastErrorMessage = reason
            }
        }
    }

    private func saveLicenseLocally(_ license: LicenseInfo, rawKey: String) {
        UserDefaults.standard.set(rawKey, forKey: savedKeyStringKey)
        if let encoded = try? JSONEncoder().encode(license) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func clearCachedLicense() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: savedKeyStringKey)
    }

    private func patchLicenseToFirebase(key: String, license: LicenseInfo) async throws {
        guard let url = URL(string: "\(databaseEndpoint)/\(key).json") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "status": license.status,
            "activatedAt": license.activatedAt ?? NSNull(),
            "expiresAt": license.expiresAt ?? NSNull(),
            "usedDevices": license.usedDevices,
            "tier": license.tier ?? (license.isBypassTier ? "bypass" : "premium")
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "LicenseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cập nhật dữ liệu lên máy chủ thất bại"])
        }
    }
}
