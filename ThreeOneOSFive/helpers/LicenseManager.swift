import Foundation
import UIKit
import Security

// MARK: - License Models
struct LicenseInfo: Codable {
    let key: String
    var status: String // "active", "banned", "expired"
    var duration: String // "1h", "1d", "1w", "1m", "1y", "lifetime"
    var durationSeconds: Int64
    var maxDevices: Int
    var usedDevices: [String]
    var createdAt: Int64
    var activatedAt: Int64?
    var expiresAt: Int64?
    var note: String?

    var isLifetime: Bool {
        duration == "lifetime" || durationSeconds == -1 || expiresAt == -1
    }

    var isExpired: Bool {
        if isLifetime { return false }
        guard let exp = expiresAt, exp > 0 else { return false }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return now > exp
    }

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

    private func formatDurationString(_ seconds: Int64) -> String {
        if seconds == -1 { return "Vĩnh Viễn" }
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        if days > 0 { return "\(days) ngày" }
        if hours > 0 { return "\(hours) giờ" }
        return "\(seconds / 60) phút"
    }
}

// MARK: - License Manager
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published var isAuthorized: Bool = false
    @Published var currentLicense: LicenseInfo? = nil
    @Published var isVerifying: Bool = false
    @Published var lastErrorMessage: String? = nil

    private let storageKey = "oni_akuma_active_license_v2"
    private let savedKeyStringKey = "oni_akuma_saved_raw_key"
    
    // Obfuscated Firebase Realtime Database Base URL
    // https://ewrergdf-default-rtdb.firebaseio.com
    private var databaseEndpoint: String {
        let part1 = "https://"
        let part2 = "ewrergdf-default-rtdb"
        let part3 = ".firebaseio.com/keys"
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
    func activateKey(_ rawKey: String) async -> Result<(String, String), String> {
        let cleaned = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty else {
            let msg = "Vui lòng nhập mã bản quyền (Key)!"
            lastErrorMessage = msg
            return .failure(msg)
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
            return .failure(msg)
        }

        do {
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 12.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let msg = "Không thể kết nối máy chủ xác thực! (Mã: \((response as? HTTPURLResponse)?.statusCode ?? 0))"
                lastErrorMessage = msg
                return .failure(msg)
            }

            if data.isEmpty || String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) == "null" {
                let msg = "Key không tồn tại hoặc đã bị xoá!"
                lastErrorMessage = msg
                return .failure(msg)
            }

            var license = try JSONDecoder().decode(LicenseInfo.self, from: data)

            // Check Banned
            if license.status == "banned" {
                let msg = "Key này đã bị khoá / vô hiệu hoá bởi quản trị viên!"
                lastErrorMessage = msg
                return .failure(msg)
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
                    return .failure(msg)
                }

                // Check Device HWID
                if !license.usedDevices.contains(currentHWID) {
                    if license.usedDevices.count < license.maxDevices {
                        license.usedDevices.append(currentHWID)
                        try await patchLicenseToFirebase(key: sanitizedKey, license: license)
                    } else {
                        let msg = "Key đã đạt giới hạn tối đa (\(license.maxDevices) thiết bị)! Vui lòng liên hệ Admin để reset thiết bị."
                        lastErrorMessage = msg
                        return .failure(msg)
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
            return .success((remain, devs))

        } catch {
            let msg = "Lỗi xác thực: \(error.localizedDescription)"
            lastErrorMessage = msg
            return .failure(msg)
        }
    }

    // MARK: - Recheck License Silently
    @MainActor
    func recheckLicense() async {
        guard let savedRawKey = UserDefaults.standard.string(forKey: savedKeyStringKey),
              !savedRawKey.isEmpty else {
            isAuthorized = false
            currentLicense = nil
            return
        }

        let sanitizedKey = savedRawKey
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: "$", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
            .replacingOccurrences(of: "/", with: "_")

        guard let requestURL = URL(string: "\(databaseEndpoint)/\(sanitizedKey).json") else { return }

        do {
            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 10.0

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  !data.isEmpty,
                  String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) != "null" else {
                // Key removed on server
                logout()
                return
            }

            let license = try JSONDecoder().decode(LicenseInfo.self, from: data)
            let currentHWID = deviceHWID

            if license.status == "banned" || license.isExpired || !license.usedDevices.contains(currentHWID) {
                logout()
            } else {
                saveLicenseLocally(license, rawKey: savedRawKey)
                self.currentLicense = license
                self.isAuthorized = true
            }
        } catch {
            // Keep local state if offline, but check local expiry
            if let cached = currentLicense, cached.isExpired {
                logout()
            }
        }
    }

    // MARK: - Logout / Remove Key
    func logout() {
        clearCachedLicense()
        DispatchQueue.main.async {
            self.isAuthorized = false
            self.currentLicense = nil
        }
    }

    // MARK: - Helpers
    private func saveLicenseLocally(_ license: LicenseInfo, rawKey: String) {
        if let encoded = try? JSONEncoder().encode(license) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            UserDefaults.standard.set(rawKey, forKey: savedKeyStringKey)
        }
    }

    private func clearCachedLicense() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: savedKeyStringKey)
    }

    private func patchLicenseToFirebase(key: String, license: LicenseInfo) async throws {
        guard let url = URL(string: "\(databaseEndpoint)/\(key).json") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0

        let payload: [String: Any?] = [
            "status": license.status,
            "activatedAt": license.activatedAt,
            "expiresAt": license.expiresAt,
            "usedDevices": license.usedDevices
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 })

        _ = try await URLSession.shared.data(for: request)
    }
}
