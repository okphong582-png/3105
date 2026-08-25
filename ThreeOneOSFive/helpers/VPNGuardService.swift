import Foundation
import UIKit
import SystemConfiguration
import Network

// MARK: - Anti-VPN & Proxy Shield
final class VPNGuardService: ObservableObject {
    static let shared = VPNGuardService()

    @Published var isVPNActive: Bool = false
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.oniakuma.vpnmonitor")
    private var hasOtherInterfaceActive = false

    init() {
        startNetworkMonitoring()
        _ = checkVPN()
    }

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            // On iOS, .other indicates an active VPN interface
            let usesOther = path.usesInterfaceType(.other)
            self.hasOtherInterfaceActive = usesOther
            _ = self.checkVPN()
        }
        pathMonitor.start(queue: monitorQueue)
    }

    @discardableResult
    func checkVPN() -> Bool {
        let isVPN = isRealVPNConnected()
        let isProxy = isRealProxyActive()
        let active = isVPN || isProxy

        DispatchQueue.main.async {
            self.isVPNActive = active
        }
        return active
    }

    private func isRealVPNConnected() -> Bool {
        // 1. If Network framework detects active .other (VPN) interface
        if hasOtherInterfaceActive {
            return true
        }

        // 2. Check getifaddrs for active external VPN tunnels
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) == IFF_UP
            let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING
            guard isUp && isRunning else { continue }

            let name = String(cString: ptr.pointee.ifa_name).lowercased()

            // System interfaces (utun0, utun1, utun2) are native iOS internal tunnels (AirDrop, AWDL, Private Relay)
            // They MUST be ignored to prevent false positives on normal devices
            if name == "utun0" || name == "utun1" || name == "utun2" {
                continue
            }

            // User-level VPN tunnels (OpenVPN, Wireguard, Shadowsocks, Shadowrocket, etc.)
            if name.hasPrefix("ppp") || name.hasPrefix("ipsec") || name.hasPrefix("tap") {
                return true
            }

            // Third-party VPN tunnels (utun3, utun4, utun5... or tun0, tun1...)
            if name.hasPrefix("tun") && !name.hasPrefix("utun") {
                return true
            }

            if name.hasPrefix("utun") {
                if let numStr = name.components(separatedBy: CharacterSet.decimalDigits.inverted).last,
                   let num = Int(numStr), num >= 3 {
                    return true
                }
            }
        }
        return false
    }

    private func isRealProxyActive() -> Bool {
        guard let proxySettings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [String: Any] else {
            return false
        }

        // Check if HTTP / HTTPS / SOCKS proxy is explicitly enabled with a configured server
        if let httpEnable = proxySettings[kCFNetworkProxiesHTTPEnable as String] as? Int, httpEnable == 1,
           let httpProxy = proxySettings[kCFNetworkProxiesHTTPProxy as String] as? String, !httpProxy.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        if let httpsEnable = proxySettings[kCFNetworkProxiesHTTPSEnable as String] as? Int, httpsEnable == 1,
           let httpsProxy = proxySettings[kCFNetworkProxiesHTTPSProxy as String] as? String, !httpsProxy.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        if let socksEnable = proxySettings[kCFNetworkProxiesSOCKSEnable as String] as? Int, socksEnable == 1,
           let socksProxy = proxySettings[kCFNetworkProxiesSOCKSProxy as String] as? String, !socksProxy.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }

        // Check Scoped interfaces for actual enabled proxies (NOT just interface existence)
        if let scopes = proxySettings["__SCOPED__"] as? [String: [String: Any]] {
            for (_, config) in scopes {
                if let httpEnable = config[kCFNetworkProxiesHTTPEnable as String] as? Int, httpEnable == 1,
                   let httpProxy = config[kCFNetworkProxiesHTTPProxy as String] as? String, !httpProxy.trimmingCharacters(in: .whitespaces).isEmpty {
                    return true
                }
                if let httpsEnable = config[kCFNetworkProxiesHTTPSEnable as String] as? Int, httpsEnable == 1,
                   let httpsProxy = config[kCFNetworkProxiesHTTPSProxy as String] as? String, !httpsProxy.trimmingCharacters(in: .whitespaces).isEmpty {
                    return true
                }
            }
        }

        return false
    }
}
