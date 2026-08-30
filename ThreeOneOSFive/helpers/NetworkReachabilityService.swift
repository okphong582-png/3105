import Foundation
import Network
import SwiftUI

@MainActor
final class NetworkReachabilityService: ObservableObject {
    static let shared = NetworkReachabilityService()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.threeoneosfive.networkreachability", qos: .userInitiated)

    @Published var isConnected: Bool = true
    @Published var isCellular: Bool = false
    @Published var connectionType: String = "Wi-Fi"

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                let connected = (path.status == .satisfied)
                self?.isConnected = connected
                if path.usesInterfaceType(.cellular) {
                    self?.isCellular = true
                    self?.connectionType = "4G/5G"
                } else if path.usesInterfaceType(.wifi) {
                    self?.isCellular = false
                    self?.connectionType = "Wi-Fi"
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.isCellular = false
                    self?.connectionType = "Ethernet"
                } else {
                    self?.isCellular = false
                    self?.connectionType = "Offline"
                }
            }
        }
        monitor.start(queue: queue)
    }

    func recheckNow() {
        let current = monitor.currentPath
        let connected = (current.status == .satisfied)
        self.isConnected = connected
        if current.usesInterfaceType(.cellular) {
            self.isCellular = true
            self.connectionType = "4G/5G"
        } else if current.usesInterfaceType(.wifi) {
            self.isCellular = false
            self.connectionType = "Wi-Fi"
        } else {
            self.connectionType = connected ? "Online" : "Offline"
        }
    }
}
