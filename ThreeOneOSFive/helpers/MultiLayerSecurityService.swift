import Foundation
import SwiftUI
import Combine

// MARK: - Security Layer Enum
enum SecurityGateLayer: Int, CaseIterable, Identifiable {
    case layer1_environment = 1
    case layer2_licenseKey = 2
    case layer3_securityPin = 3
    case layer4_antiBotChallenge = 4
    case layer5_coreDecryption = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .layer1_environment: return "LỚP 1: KIỂM SOÁT PHẦN CỨNG"
        case .layer2_licenseKey: return "LỚP 2: MASTER LICENSE KEY"
        case .layer3_securityPin: return "LỚP 3: MÃ PIN BẢO VỆ CẤP 2"
        case .layer4_antiBotChallenge: return "LỚP 4: THUẬT TOÁN CHỐNG BOT"
        case .layer5_coreDecryption: return "LỚP 5: GIẢI MÃ VÙNG LÕI"
        }
    }

    var icon: String {
        switch self {
        case .layer1_environment: return "cpu.fill"
        case .layer2_licenseKey: return "key.horizontal.fill"
        case .layer3_securityPin: return "lock.rectangle.on.rectangle.fill"
        case .layer4_antiBotChallenge: return "puzzlepiece.fill"
        case .layer5_coreDecryption: return "atom"
        }
    }
}

// MARK: - Challenge Model for Layer 4
struct SecurityChallenge {
    let question: String
    let options: [Int]
    let correctIndex: Int
}

// MARK: - MultiLayer Security Service
final class MultiLayerSecurityService: ObservableObject {
    static let shared = MultiLayerSecurityService()

    @Published var currentLayer: SecurityGateLayer = .layer1_environment
    @Published var passedLayers: Set<Int> = []
    
    // Layer 1 state
    @Published var l1_isScanning = false
    @Published var l1_integrityOk = false
    @Published var l1_hwidStatus = "Chưa quét"
    @Published var l1_debuggerStatus = "Chưa quét"
    @Published var l1_environmentStatus = "Chưa quét"

    // Layer 2 state
    @Published var l2_keyVerified = false

    // Layer 3 state (PIN)
    @Published var l3_pinInput = ""
    @Published var l3_pinErrorMessage: String? = nil
    @Published var l3_scrambledDigits: [Int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]

    // Layer 4 state (Challenge)
    @Published var l4_challenge: SecurityChallenge = SecurityChallenge(question: "2 + 3 = ?", options: [4, 5, 6, 7], correctIndex: 1)
    @Published var l4_errorMessage: String? = nil

    // Layer 5 state (Decryption & Core Activation)
    @Published var l5_isDecrypting = false
    @Published var l5_progress: Double = 0.0
    @Published var isFullyUnlocked: Bool = false

    // Dynamic session security tokens
    private var tokenL1: String? = nil
    private var tokenL2: String? = nil
    private var tokenL3: String? = nil
    private var tokenL4: String? = nil
    private var compositeMasterToken: String? = nil

    private let pinStorageKey = "oni_akuma_master_security_pin_v2"
    private let defaultMasterPin = "8888"

    init() {
        isFullyUnlocked = true
    }

    private func checkPreviousAuthorization() {
        let licManager = LicenseManager.shared
        if licManager.isAuthorized,
           let lic = licManager.currentLicense,
           !lic.isExpired,
           lic.status == "active" {
            passedLayers.insert(SecurityGateLayer.layer2_licenseKey.rawValue)
            l2_keyVerified = true
            tokenL2 = "L2_\(UUID().uuidString)"
        } else {
            passedLayers.remove(SecurityGateLayer.layer2_licenseKey.rawValue)
            l2_keyVerified = false
            tokenL2 = nil
        }
    }

    // MARK: - Layer 1: Hardware & Integrity Check
    func runLayer1IntegrityScan(completion: @escaping (Bool) -> Void) {
        l1_isScanning = true
        l1_integrityOk = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Check Anti-Debug & Anti-Dump
            enforce_binary_security()
            let debuggerAttached = is_debugger_attached()
            let suspiciousEnv = is_suspicious_environment()

            self.l1_hwidStatus = "HWID Đã Khóa: \(LicenseManager.shared.deviceHWID.prefix(8))•••"
            self.l1_debuggerStatus = debuggerAttached ? "BỊ PHÁT HIỆN" : "AN TOÀN (0x0)"
            self.l1_environmentStatus = suspiciousEnv ? "PHÁT HIỆN CAN THIỆP" : "SẠCH SẼ (100%)"

            if !debuggerAttached && !suspiciousEnv {
                self.l1_integrityOk = true
                self.passedLayers.insert(SecurityGateLayer.layer1_environment.rawValue)
                self.tokenL1 = "L1_\(UUID().uuidString)"
                self.l1_isScanning = false
                
                // Auto advance to Layer 2 if not passed, or next available
                self.advanceToNextLayer()
                completion(true)
            } else {
                self.l1_integrityOk = false
                self.l1_isScanning = false
                completion(false)
            }
        }
    }

    // MARK: - Layer 2: License Key Passed
    func confirmLayer2Success() {
        l2_keyVerified = true
        passedLayers.insert(SecurityGateLayer.layer2_licenseKey.rawValue)
        tokenL2 = "L2_\(UUID().uuidString)"
        advanceToNextLayer()
    }

    // MARK: - Layer 3: Security PIN Check
    func refreshScrambledPinPad() {
        l3_scrambledDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0].shuffled()
    }

    var configuredPin: String {
        UserDefaults.standard.string(forKey: pinStorageKey) ?? defaultMasterPin
    }

    func appendPinDigit(_ digit: Int) {
        guard l3_pinInput.count < 6 else { return }
        l3_pinInput.append("\(digit)")
        l3_pinErrorMessage = nil

        if l3_pinInput.count >= 4 {
            verifyLayer3Pin()
        }
    }

    func deletePinDigit() {
        guard !l3_pinInput.isEmpty else { return }
        l3_pinInput.removeLast()
        l3_pinErrorMessage = nil
    }

    func clearPin() {
        l3_pinInput = ""
        l3_pinErrorMessage = nil
    }

    private func verifyLayer3Pin() {
        if l3_pinInput == configuredPin {
            l3_pinErrorMessage = nil
            passedLayers.insert(SecurityGateLayer.layer3_securityPin.rawValue)
            tokenL3 = "L3_\(UUID().uuidString)"
            advanceToNextLayer()
        } else if l3_pinInput.count >= configuredPin.count {
            l3_pinErrorMessage = "Mã PIN không chính xác!"
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.error)
            l3_pinInput = ""
            refreshScrambledPinPad()
        }
    }

    // MARK: - Layer 4: Anti-Bot Math Challenge
    func generateLayer4Challenge() {
        let a = Int.random(in: 12...88)
        let b = Int.random(in: 11...55)
        let sum = a + b
        
        var options = [sum]
        while options.count < 4 {
            let fake = sum + Int.random(in: -10...10)
            if !options.contains(fake) && fake > 0 {
                options.append(fake)
            }
        }
        options.shuffle()
        let correctIdx = options.firstIndex(of: sum) ?? 0

        l4_challenge = SecurityChallenge(
            question: "\(a) + \(b) = ?",
            options: options,
            correctIndex: correctIdx
        )
        l4_errorMessage = nil
    }

    func answerLayer4Challenge(selectedIndex: Int) {
        if selectedIndex == l4_challenge.correctIndex {
            l4_errorMessage = nil
            passedLayers.insert(SecurityGateLayer.layer4_antiBotChallenge.rawValue)
            tokenL4 = "L4_\(UUID().uuidString)"
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            advanceToNextLayer()
        } else {
            l4_errorMessage = "Câu trả lời không chính xác! Đang tạo câu hỏi mới..."
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.generateLayer4Challenge()
            }
        }
    }

    // MARK: - Layer 5: Dynamic Core Decryption
    func startLayer5CoreDecryption(completion: @escaping () -> Void) {
        guard !l5_isDecrypting else { return }
        l5_isDecrypting = true
        l5_progress = 0.0

        Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
            if self.l5_progress < 1.0 {
                self.l5_progress += 0.05
            } else {
                timer.invalidate()
                self.passedLayers.insert(SecurityGateLayer.layer5_coreDecryption.rawValue)
                
                // Form composite master token
                let composite = "\(self.tokenL1 ?? ""):\(self.tokenL2 ?? ""):\(self.tokenL3 ?? ""):\(self.tokenL4 ?? ""):\(Date().timeIntervalSince1970)"
                self.compositeMasterToken = composite
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    self.isFullyUnlocked = true
                    self.l5_isDecrypting = false
                }
                completion()
            }
        }
    }

    // MARK: - State Progression
    func advanceToNextLayer() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if !passedLayers.contains(SecurityGateLayer.layer1_environment.rawValue) {
                currentLayer = .layer1_environment
            } else if !passedLayers.contains(SecurityGateLayer.layer2_licenseKey.rawValue) {
                currentLayer = .layer2_licenseKey
            } else if !passedLayers.contains(SecurityGateLayer.layer3_securityPin.rawValue) {
                currentLayer = .layer3_securityPin
            } else if !passedLayers.contains(SecurityGateLayer.layer4_antiBotChallenge.rawValue) {
                currentLayer = .layer4_antiBotChallenge
            } else {
                currentLayer = .layer5_coreDecryption
            }
        }
    }

    // MARK: - Tamper Lockdown
    func lockdown() {
        DispatchQueue.main.async {
            self.tokenL1 = nil
            self.tokenL2 = nil
            self.tokenL3 = nil
            self.tokenL4 = nil
            self.compositeMasterToken = nil
            self.passedLayers.removeAll()
            self.isFullyUnlocked = false
            self.currentLayer = .layer1_environment
            self.l1_integrityOk = false
            self.l2_keyVerified = false
            self.l3_pinInput = ""
            self.generateLayer4Challenge()
        }
    }

    // MARK: - Validate Decoupled Core Access
    func isCoreAccessPermitted() -> Bool {
        guard LicenseManager.shared.isAuthorized,
              let lic = LicenseManager.shared.currentLicense,
              !lic.isExpired,
              lic.status == "active" else {
            return false
        }
        return !is_debugger_attached() && !is_suspicious_environment()
    }
}
