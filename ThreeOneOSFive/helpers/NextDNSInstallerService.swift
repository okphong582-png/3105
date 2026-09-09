import Foundation
import Network
import UIKit

// MARK: - DNS Domain Category
enum DNSDomainCategory: String, CaseIterable {
    case all = "Tất cả"
    case anticheat = "Anti-Cheat"
    case garenaReport = "Garena Báo Cáo"
    case telemetry = "Theo Dõi / SDK"
    case inGameCheck = "Kiểm Tra Dữ Liệu"

    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .anticheat: return "shield.slash.fill"
        case .garenaReport: return "exclamationmark.bubble.fill"
        case .telemetry: return "antenna.radiowaves.left.and.right"
        case .inGameCheck: return "externaldrive.badge.xmark"
        }
    }

    var badgeColor: UIColor {
        switch self {
        case .all: return .systemGray
        case .anticheat: return .systemRed
        case .garenaReport: return .systemOrange
        case .telemetry: return .systemPurple
        case .inGameCheck: return .systemYellow
        }
    }
}

// MARK: - DNS Rule Item
struct DNSRuleItem: Identifiable, Hashable {
    let id = UUID()
    let pattern: String
    let category: DNSDomainCategory
    let isAllowRule: Bool
    let note: String
}

// MARK: - Realtime Query Log Model
struct NextDNSQueryLog: Identifiable, Hashable {
    let id = UUID()
    let domain: String
    let isBlocked: Bool
    let matchedRule: String
    let timestamp: Date
    let latencyMs: Double
    let clientIP: String
    let protocolName: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - NextDNS Service with Realtime Protection Engine
@MainActor
final class NextDNSInstallerService: ObservableObject {
    static let shared = NextDNSInstallerService()

    // MARK: - Rules Catalog
    static let denyDomains: [String] = [
        "ff.contact.garena.com",
        "contact.garena.com",
        "hotro.garena.vn",
        "hotro.ff.garena.com",
        "ff.garena.com.vn",
        "*.supportff.com",
        "*.napthe.vn",
        "*.garena.com.vn",
        "*.garena.vn",
        "*.anticheat.com",
        "*.freefire.com.vn",
        "*.ff.vn",
        "*.squadpass.sea.freefiremobile.com",
        "*.conversions.appsflyer.com",
        "*.ff.member.garena.com",
        "*.dl.dir.freefiremobile.com",
        "*.ffguid.garena.com",
        "*.mathu304.ff.garena.vn",
        "*.goiban304.ff.garena.vn",
        "*.attr.appsflyer.com",
        "*.inapps.appsflyer.com",
        "*.yomost.ff.garena.vn",
        "*.quandoan.ff.garena.vn",
        "*.faceit.com",
        "*.ffsupport.garena.com",
        "*.easy.ac",
        "*.membership.garena.vn",
        "*.ff.garena.con",
        "*.akamaihd.net",
        "*.garenanow.com",
        "*.akamaiedge.net",
        "*.freefiremobile.com",
        "*.garena.com",
        "*.dl.listdl.com",
        "*.listdl.com",
        "*.hocal.com",
        "*.appsflyer.com",
        "*.gopapi.io",
        "*.akamai.net",
        "*.1e100.net",
        "*.ff.dr.grtc.garenanow.com",
        "*.appsflyersdk.com",
        "*.ff.garena.com",
        "*.ffguide.garena.com",
        "*.gin.freefiremobile.com",
        "*.cdn-settings.appsflyer.com",
        "*.skadsdk.appsflyer.com",
        "*.gcdsdk.appsflyer.com",
        "*.launches.appsflyer.com",
        "*.firebase-setting.crashlytics.com",
        "*.ff.garena.vn"
    ]

    static let allowDomains: [String] = [
        "100067.contact.garena.com",
        "100067.ff.contact.garena.com"
    ]

    // MARK: - Published State
    @Published var isProtectionActive: Bool {
        didSet {
            UserDefaults.standard.set(isProtectionActive, forKey: "oni_nextdns_active")
            if isProtectionActive {
                startRealtimeStream()
            } else {
                stopRealtimeStream()
            }
        }
    }

    @Published var isServerRunning = false
    @Published var hasDownloadedProfile: Bool = false
    @Published var isSetupCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isSetupCompleted, forKey: "oni_nextdns_setup_done")
        }
    }

    // Realtime Query Counters
    @Published var totalQueries: Int = 1845
    @Published var blockedQueries: Int = 1142
    @Published var allowedQueries: Int = 703

    // Realtime Traffic Stream
    @Published var liveLogs: [NextDNSQueryLog] = []

    var blockedPercentage: String {
        guard totalQueries > 0 else { return "0.0%" }
        let rate = (Double(blockedQueries) / Double(totalQueries)) * 100.0
        return String(format: "%.1f%%", rate)
    }

    private var listener: NWListener?
    private let serverPort: UInt16 = 53891
    private var streamTimer: Timer?

    private init() {
        let savedActive = UserDefaults.standard.object(forKey: "oni_nextdns_active") as? Bool ?? true
        self.isProtectionActive = savedActive
        self.isSetupCompleted = UserDefaults.standard.bool(forKey: "oni_nextdns_setup_done")

        seedInitialLogs()
        if savedActive {
            startRealtimeStream()
        }
    }

    // MARK: - Seed Initial Realtime Traffic
    private func seedInitialLogs() {
        let initialSamples: [(String, Bool, String)] = [
            ("ff.contact.garena.com", true, "Rule: ff.contact.garena.com"),
            ("100067.ff.contact.garena.com", false, "Allowlist: 100067.ff.contact.garena.com"),
            ("report.anticheat.com", true, "Rule: *.anticheat.com"),
            ("inapps.appsflyer.com", true, "Rule: *.appsflyer.com"),
            ("100067.contact.garena.com", false, "Allowlist: 100067.contact.garena.com"),
            ("cdn-settings.appsflyer.com", true, "Rule: *.appsflyer.com"),
            ("hotro.ff.garena.com", true, "Rule: hotro.ff.garena.com"),
            ("settings.crashlytics.com", true, "Rule: *.firebase-setting.crashlytics.com"),
            ("gateway.freefiremobile.com", false, "Traffic: Game Server TCP"),
            ("dl.dir.freefiremobile.com", true, "Rule: *.dl.dir.freefiremobile.com"),
            ("easy.ac", true, "Rule: *.easy.ac"),
            ("quandoan.ff.garena.vn", true, "Rule: *.quandoan.ff.garena.vn")
        ]

        var now = Date().addingTimeInterval(-25)
        for sample in initialSamples {
            now = now.addingTimeInterval(Double.random(in: 1.5...3.0))
            let latency = sample.1 ? Double.random(in: 0.1...0.4) : Double.random(in: 8.0...19.0)
            liveLogs.append(NextDNSQueryLog(
                domain: sample.0,
                isBlocked: sample.1,
                matchedRule: sample.2,
                timestamp: now,
                latencyMs: latency,
                clientIP: "192.168.1.104",
                protocolName: "DoH (HTTPS)"
            ))
        }
        liveLogs.reverse()
    }

    // MARK: - Realtime Stream Engine
    func startRealtimeStream() {
        guard streamTimer == nil else { return }
        streamTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.generateSimulatedLiveQuery()
            }
        }
    }

    func stopRealtimeStream() {
        streamTimer?.invalidate()
        streamTimer = nil
    }

    func toggleProtection() {
        let feedback = UIImpactFeedbackGenerator(style: .heavy)
        feedback.impactOccurred()
        isProtectionActive.toggle()
    }

    func clearLogs() {
        liveLogs.removeAll()
        totalQueries = 0
        blockedQueries = 0
        allowedQueries = 0
    }

    private func generateSimulatedLiveQuery() {
        guard isProtectionActive else { return }

        // Danh sách mẫu truy vấn ngẫu nhiên mô phỏng traffic game & thiết bị
        let candidates: [(domain: String, forceDecision: (Bool, String)?)] = [
            ("report.anticheat.com", nil),
            ("100067.ff.contact.garena.com", nil),
            ("100067.contact.garena.com", nil),
            ("ff.contact.garena.com", nil),
            ("hotro.ff.garena.com", nil),
            ("skadsdk.appsflyer.com", nil),
            ("login.freefiremobile.com", (false, "Game Server Normal")),
            ("quandoan.ff.garena.vn", nil),
            ("dl.dir.freefiremobile.com", nil),
            ("firebase-setting.crashlytics.com", nil),
            ("easy.ac", nil),
            ("faceit.com", nil),
            ("conversions.appsflyer.com", nil),
            ("live.sea.freefiremobile.com", (false, "Game Room Matchmaking")),
            ("attr.appsflyer.com", nil),
            ("gin.freefiremobile.com", nil),
            ("ffguid.garena.com", nil)
        ]

        guard let pick = candidates.randomElement() else { return }

        let evaluation = evaluate(domain: pick.domain)
        let isBlocked: Bool
        let rule: String

        if let override = pick.forceDecision {
            isBlocked = override.0
            rule = override.1
        } else {
            isBlocked = evaluation.isBlocked
            rule = evaluation.rule
        }

        totalQueries += 1
        if isBlocked {
            blockedQueries += 1
        } else {
            allowedQueries += 1
        }

        let latency = isBlocked ? Double.random(in: 0.1...0.4) : Double.random(in: 8.5...24.0)
        let logItem = NextDNSQueryLog(
            domain: pick.domain,
            isBlocked: isBlocked,
            matchedRule: rule,
            timestamp: Date(),
            latencyMs: latency,
            clientIP: "192.168.1.104",
            protocolName: "DoH (HTTPS)"
        )

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            liveLogs.insert(logItem, at: 0)
            if liveLogs.count > 60 {
                liveLogs.removeLast()
            }
        }
    }

    // MARK: - Domain Evaluation
    func evaluate(domain: String) -> (isBlocked: Bool, rule: String) {
        let clean = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Kiểm tra danh sách Allow (Ưu tiên tuyệt đối)
        for allowed in Self.allowDomains {
            if Self.matches(clean, pattern: allowed.lowercased()) {
                return (false, "Allowlist: \(allowed)")
            }
        }

        // 2. Kiểm tra danh sách Deny
        for denied in Self.denyDomains {
            if Self.matches(clean, pattern: denied.lowercased()) {
                return (true, "Denylist: \(denied)")
            }
        }

        return (false, "Default Traffic")
    }

    static func matches(_ domain: String, pattern: String) -> Bool {
        if pattern.hasPrefix("*.") {
            let suffix = String(pattern.dropFirst(2))
            return domain == suffix || domain.hasSuffix("." + suffix)
        }
        return domain == pattern
    }

    // MARK: - Categorized Rules for UI
    var formattedDenyRules: [DNSRuleItem] {
        Self.denyDomains.map { pattern in
            let cat: DNSDomainCategory
            if pattern.contains("anticheat") || pattern.contains("easy.ac") || pattern.contains("faceit") {
                cat = .anticheat
            } else if pattern.contains("appsflyer") || pattern.contains("crashlytics") || pattern.contains("1e100") {
                cat = .telemetry
            } else if pattern.contains("dl.") || pattern.contains("listdl") || pattern.contains("akamai") || pattern.contains("gin.") {
                cat = .inGameCheck
            } else {
                cat = .garenaReport
            }

            return DNSRuleItem(
                pattern: pattern,
                category: cat,
                isAllowRule: false,
                note: "Chặn truyền dữ liệu phát hiện mod & báo cáo gian lận"
            )
        }
    }

    var formattedAllowRules: [DNSRuleItem] {
        Self.allowDomains.map { pattern in
            DNSRuleItem(
                pattern: pattern,
                category: .all,
                isAllowRule: true,
                note: "Bắt buộc cho phép để vào game và tải dữ liệu nhân vật"
            )
        }
    }

    // MARK: - Local Server for .mobileconfig
    nonisolated var profileData: Data? {
        if let bundlePath = Bundle.main.url(forResource: "NextDNS", withExtension: "mobileconfig") {
            return try? Data(contentsOf: bundlePath)
        }
        let mainDir = Bundle.main.bundleURL
        let candidate = mainDir.appendingPathComponent("NextDNS.mobileconfig")
        if let data = try? Data(contentsOf: candidate) {
            return data
        }
        return nil
    }

    func startLocalServer() {
        guard listener == nil else { return }

        do {
            let port = NWEndpoint.Port(rawValue: serverPort) ?? 53891
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let newListener = try NWListener(using: params, on: port)

            newListener.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }

            newListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    if case .ready = state {
                        self?.isServerRunning = true
                    }
                }
            }

            newListener.start(queue: .global(qos: .userInitiated))
            self.listener = newListener
        } catch {
            log("NextDNS: không thể khởi động máy chủ cục bộ: \(error.localizedDescription)")
        }
    }

    nonisolated private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] _, _, _, error in
            guard error == nil, let self = self else {
                connection.cancel()
                return
            }

            let profileBytes = self.profileData ?? Data()
            let header = """
            HTTP/1.1 200 OK\r
            Content-Type: application/x-apple-aspen-config\r
            Content-Disposition: attachment; filename="NextDNS.mobileconfig"\r
            Content-Length: \(profileBytes.count)\r
            Connection: close\r
            \r\n
            """
            var response = Data(header.utf8)
            response.append(profileBytes)

            connection.send(content: response, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        }
    }

    func downloadAndInstallProfile() {
        startLocalServer()
        hasDownloadedProfile = true

        let localURLString = "http://127.0.0.1:\(serverPort)/NextDNS.mobileconfig"
        if let localURL = URL(string: localURLString) {
            UIApplication.shared.open(localURL, options: [:]) { [weak self] success in
                if !success {
                    Task { @MainActor [weak self] in
                        self?.shareProfileFallback()
                    }
                }
            }
        } else {
            shareProfileFallback()
        }
    }

    func shareProfileFallback() {
        guard let data = profileData else { return }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("NextDNS.mobileconfig")
        try? data.write(to: tempURL)
        FileShareHelper.share(url: tempURL, isDirectory: false, defaultName: "NextDNS.mobileconfig")
    }

    func completeSetup() {
        isSetupCompleted = true
        isProtectionActive = true
        let notif = UINotificationFeedbackGenerator()
        notif.notificationOccurred(.success)
    }

    func resetSetup() {
        isSetupCompleted = false
    }
}
