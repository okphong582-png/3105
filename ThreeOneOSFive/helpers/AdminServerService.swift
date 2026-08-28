import Foundation
import SwiftUI
import Combine

// MARK: - Admin Server Key Service
@MainActor
final class AdminServerService: ObservableObject {
    static let shared = AdminServerService()

    @Published var keys: [LicenseInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var bypassLink: String = "https://link4m.co"
    @Published var announcement: String = ""
    @Published var searchQuery: String = ""
    @Published var selectedFilter: KeyFilter = .all

    // Firebase Endpoints
    private let baseURL = "https://ewrergdf-default-rtdb.firebaseio.com"
    private var keysURL: URL { URL(string: "\(baseURL)/keys.json")! }
    private var configURL: URL { URL(string: "\(baseURL)/config.json")! }

    private var refreshTimer: Timer?

    enum KeyFilter: String, CaseIterable, Identifiable {
        case all = "Tất Cả"
        case active = "Đang Dùng"
        case bypass = "Vượt Link"
        case expired = "Hết Hạn"
        case banned = "Bị Khóa"

        var id: String { rawValue }
    }

    private init() {
        Task {
            await fetchAllData()
        }
    }

    func startRealtimeSync() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchAllData(silent: true)
            }
        }
    }

    func stopRealtimeSync() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Filtered Keys
    var filteredKeys: [LicenseInfo] {
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        return keys.filter { key in
            // Search query match
            let matchesSearch: Bool
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let q = searchQuery.lowercased()
                let matchKey = key.key.lowercased().contains(q)
                let matchNote = (key.note ?? "").lowercased().contains(q)
                let matchDevice = key.usedDevices.contains { $0.lowercased().contains(q) }
                matchesSearch = matchKey || matchNote || matchDevice
            }

            guard matchesSearch else { return false }

            // Filter match
            switch selectedFilter {
            case .all:
                return true
            case .active:
                if key.status == "banned" { return false }
                if let exp = key.expiresAt, exp <= now { return false }
                return true
            case .bypass:
                let note = (key.note ?? "").lowercased()
                let keyStr = key.key.lowercased()
                return note.contains("vượt link") || note.contains("link4m") || keyStr.hasPrefix("pass-") || keyStr.hasPrefix("link-") || keyStr.hasPrefix("free-")
            case .expired:
                if let exp = key.expiresAt, exp <= now { return true }
                return key.status == "expired"
            case .banned:
                return key.status == "banned"
            }
        }.sorted { k1, k2 in
            (k1.createdAt) > (k2.createdAt)
        }
    }

    // MARK: - Stats
    var totalKeysCount: Int { keys.count }
    var activeKeysCount: Int {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return keys.filter { $0.status != "banned" && ($0.expiresAt == nil || $0.expiresAt! > now) }.count
    }
    var bypassKeysCount: Int {
        keys.filter {
            let note = ($0.note ?? "").lowercased()
            let keyStr = $0.key.lowercased()
            return note.contains("vượt link") || note.contains("link4m") || keyStr.hasPrefix("pass-") || keyStr.hasPrefix("link-") || keyStr.hasPrefix("free-")
        }.count
    }
    var bannedKeysCount: Int { keys.filter { $0.status == "banned" }.count }

    // MARK: - Fetch All Data
    func fetchAllData(silent: Bool = false) async {
        if !silent { isLoading = true }
        errorMessage = nil

        async let keysFetch: [LicenseInfo] = fetchKeys()
        async let configFetch: (String, String) = fetchConfig()

        let (fetchedKeys, (fetchedBypass, fetchedAnnounce)) = await (keysFetch, configFetch)

        self.keys = fetchedKeys
        if !fetchedBypass.isEmpty { self.bypassLink = fetchedBypass }
        self.announcement = fetchedAnnounce
        if !silent { self.isLoading = false }
    }

    private func fetchKeys() async -> [LicenseInfo] {
        do {
            let (data, response) = try await URLSession.shared.data(from: keysURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return []
            }
            if let dict = try? JSONDecoder().decode([String: LicenseInfo].self, from: data) {
                return Array(dict.values)
            }
        } catch {
            log("Admin: fetchKeys error: \(error.localizedDescription)")
        }
        return []
    }

    private func fetchConfig() async -> (String, String) {
        do {
            let (data, response) = try await URLSession.shared.data(from: configURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return ("", "")
            }
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let link = dict["bypass_link"] as? String ?? ""
                let ann = dict["announcement"] as? String ?? ""
                return (link, ann)
            }
        } catch {
            log("Admin: fetchConfig error: \(error.localizedDescription)")
        }
        return ("", "")
    }

    // MARK: - Create Key (Standard or Custom Duration with Pass Key)
    func createKey(
        keyText: String? = nil,
        passwordText: String? = nil,
        durationSeconds: Int64,
        maxDevices: Int = 1,
        note: String? = nil,
        isBypass: Bool = false
    ) async -> (success: Bool, createdKey: LicenseInfo?, message: String) {
        isLoading = true
        defer { isLoading = false }

        let cleanKey = (keyText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let finalKey = cleanKey.isEmpty ? generateRandomKey(isBypass: isBypass) : cleanKey.uppercased()

        let cleanPass = (passwordText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
        let finalPassword = cleanPass.isEmpty ? String(format: "%06d", Int.random(in: 100000...999999)) : cleanPass

        var durationDesc = "1d"
        if durationSeconds == -1 {
            durationDesc = "lifetime"
        } else if durationSeconds >= 86400 {
            durationDesc = "\(durationSeconds / 86400)d"
        } else if durationSeconds >= 3600 {
            durationDesc = "\(durationSeconds / 3600)h"
        } else {
            durationDesc = "\(durationSeconds / 60)m"
        }

        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let finalNote = note ?? (isBypass ? "Vượt Link (Link4m)" : "Tạo bởi Admin")

        let license = LicenseInfo(
            key: finalKey,
            status: "active",
            duration: durationDesc,
            durationSeconds: durationSeconds,
            maxDevices: maxDevices,
            usedDevices: [],
            createdAt: now,
            activatedAt: nil,
            expiresAt: nil,
            note: finalNote,
            tier: isBypass ? "bypass" : "premium",
            password: finalPassword
        )

        let targetURL = URL(string: "\(baseURL)/keys/\(finalKey).json")!
        var request = URLRequest(url: targetURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONEncoder().encode(license)
            request.httpBody = data
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                // Update local list
                self.keys.removeAll { $0.key == finalKey }
                self.keys.append(license)
                UIPasteboard.general.string = "Key: \(finalKey) | Pass: \(finalPassword)"
                return (true, license, "Đã tạo thành công Key: \(finalKey) | Pass: \(finalPassword)")
            } else {
                return (false, nil, "Server từ chối (Mã HTTP: \((response as? HTTPURLResponse)?.statusCode ?? 0))")
            }
        } catch {
            return (false, nil, "Lỗi kết nối Firebase: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Key Status (Ban / Unban)
    func setKeyStatus(key: String, status: String) async -> Bool {
        let targetURL = URL(string: "\(baseURL)/keys/\(key)/status.json")!
        var req = URLRequest(url: targetURL)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "\"\(status)\"".data(using: .utf8)

        do {
            let (_, res) = try await URLSession.shared.data(for: req)
            if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                if let idx = self.keys.firstIndex(where: { $0.key == key }) {
                    self.keys[idx].status = status
                }
                return true
            }
        } catch {
            log("Admin: setKeyStatus error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Reset HWID
    func resetHWID(key: String) async -> Bool {
        let targetURL = URL(string: "\(baseURL)/keys/\(key)/usedDevices.json")!
        var req = URLRequest(url: targetURL)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = "[]".data(using: .utf8)

        do {
            let (_, res) = try await URLSession.shared.data(for: req)
            if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                if let idx = self.keys.firstIndex(where: { $0.key == key }) {
                    self.keys[idx].usedDevices = []
                }
                return true
            }
        } catch {
            log("Admin: resetHWID error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Delete Key
    func deleteKey(key: String) async -> Bool {
        let targetURL = URL(string: "\(baseURL)/keys/\(key).json")!
        var req = URLRequest(url: targetURL)
        req.httpMethod = "DELETE"

        do {
            let (_, res) = try await URLSession.shared.data(for: req)
            if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                self.keys.removeAll { $0.key == key }
                return true
            }
        } catch {
            log("Admin: deleteKey error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Update Bypass Link on Firebase
    func updateBypassLink(_ newLink: String) async -> Bool {
        let clean = newLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return false }

        let targetURL = URL(string: "\(baseURL)/config/bypass_link.json")!
        var req = URLRequest(url: targetURL)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(clean)

        do {
            let (_, res) = try await URLSession.shared.data(for: req)
            if let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                self.bypassLink = clean
                return true
            }
        } catch {
            log("Admin: updateBypassLink error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Key Generation Helper
    private func generateRandomKey(isBypass: Bool) -> String {
        let prefix = isBypass ? "PASS" : "ONIAKUMA"
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let part1 = String((0..<4).compactMap { _ in chars.randomElement() })
        let part2 = String((0..<4).compactMap { _ in chars.randomElement() })
        return "\(prefix)-\(part1)-\(part2)"
    }
}
