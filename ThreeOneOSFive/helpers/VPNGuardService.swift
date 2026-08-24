import Foundation
import UIKit
import SystemConfiguration

// MARK: - Anti-VPN & Proxy Shield
final class VPNGuardService: ObservableObject {
    static let shared = VPNGuardService()

    @Published var isVPNActive: Bool = false

    init() {
        _ = checkVPN()
    }

    @discardableResult
    func checkVPN() -> Bool {
        let active = isVPNConnected() || isProxyActive()
        DispatchQueue.main.async {
            self.isVPNActive = active
        }
        return active
    }

    private func isVPNConnected() -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            guard isUp && isRunning else { continue }

            let name = String(cString: ptr.pointee.ifa_name).lowercased()
            if name.hasPrefix("utun") || name.hasPrefix("tun") || name.hasPrefix("tap") || name.hasPrefix("ppp") || name.hasPrefix("ipsec") {
                return true
            }
        }
        return false
    }

    private func isProxyActive() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }
        if let httpProxy = proxySettings["HTTPProxy"] as? String, !httpProxy.isEmpty { return true }
        if let httpsProxy = proxySettings["HTTPSProxy"] as? String, !httpsProxy.isEmpty { return true }
        if let httpEnable = proxySettings["HTTPEnable"] as? Int, httpEnable == 1 { return true }
        if let httpsEnable = proxySettings["HTTPSEnable"] as? Int, httpsEnable == 1 { return true }

        if let scopes = proxySettings["__SCOPED__"] as? [String: Any] {
            for (key, _) in scopes {
                let lowerKey = key.lowercased()
                if lowerKey.contains("tap") || lowerKey.contains("tun") || lowerKey.contains("ppp") || lowerKey.contains("ipsec") || lowerKey.contains("utun") {
                    return true
                }
            }
        }
        return false
    }
}
