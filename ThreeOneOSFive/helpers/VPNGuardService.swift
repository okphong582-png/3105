import Foundation
import UIKit

// MARK: - Anti-VPN & Proxy Shield (Bypassed)
final class VPNGuardService: ObservableObject {
    static let shared = VPNGuardService()

    @Published var isVPNActive: Bool = false

    init() {}

    @discardableResult
    func checkVPN() -> Bool {
        DispatchQueue.main.async {
            self.isVPNActive = false
        }
        return false
    }
}
