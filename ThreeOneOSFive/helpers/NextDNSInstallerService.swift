import Foundation
import Network
import UIKit

@MainActor
final class NextDNSInstallerService: ObservableObject {
    static let shared = NextDNSInstallerService()

    @Published var isServerRunning = false
    @Published var hasDownloadedProfile: Bool = false
    @Published var isSetupCompleted: Bool {
        didSet {
            UserDefaults.standard.set(isSetupCompleted, forKey: "oni_nextdns_setup_done")
        }
    }

    private var listener: NWListener?
    private let serverPort: UInt16 = 53891

    init() {
        self.isSetupCompleted = UserDefaults.standard.bool(forKey: "oni_nextdns_setup_done")
    }

    /// Đọc dữ liệu tệp NextDNS.mobileconfig từ bundle
    var profileData: Data? {
        if let bundlePath = Bundle.main.url(forResource: "NextDNS", withExtension: "mobileconfig") {
            return try? Data(contentsOf: bundlePath)
        }
        // Fallback: tìm trong thư mục ứng dụng
        let mainDir = Bundle.main.bundleURL
        let candidate = mainDir.appendingPathComponent("NextDNS.mobileconfig")
        if let data = try? Data(contentsOf: candidate) {
            return data
        }
        return nil
    }

    /// Khởi động máy chủ HTTP nội bộ trên localhost để Safari tải hồ sơ cấu hình chuẩn Apple
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
                    switch state {
                    case .ready:
                        self?.isServerRunning = true
                    default:
                        break
                    }
                }
            }

            newListener.start(queue: .global(qos: .userInitiated))
            self.listener = newListener
        } catch {
            log("NextDNS: không thể khởi động máy chủ cục bộ: \(error.localizedDescription)")
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, error in
            guard error == nil, let self = self else {
                connection.cancel()
                return
            }

            let profileBytes = Task { @MainActor in
                self.profileData ?? Data()
            }

            Task {
                let data = await profileBytes.value
                let header = """
                HTTP/1.1 200 OK\r
                Content-Type: application/x-apple-aspen-config\r
                Content-Disposition: attachment; filename="NextDNS.mobileconfig"\r
                Content-Length: \(data.count)\r
                Connection: close\r
                \r\n
                """
                var response = Data(header.utf8)
                response.append(data)

                connection.send(content: response, completion: .contentProcessed({ _ in
                    connection.cancel()
                }))
            }
        }
    }

    /// Tải về NextDNS.mobileconfig vào thiết bị
    func downloadAndInstallProfile() {
        startLocalServer()
        hasDownloadedProfile = true

        let localURLString = "http://127.0.0.1:\(serverPort)/NextDNS.mobileconfig"
        if let localURL = URL(string: localURLString) {
            // Mở Safari để iOS tự kích hoạt hộp thoại: "Đã tải về hồ sơ cấu hình"
            UIApplication.shared.open(localURL, options: [:]) { success in
                if !success {
                    // Fallback: Mở share sheet trực tiếp
                    self.shareProfileFallback()
                }
            }
        } else {
            shareProfileFallback()
        }
    }

    /// Dự phòng: Mở bảng chia sẻ để Lưu vào Tệp
    func shareProfileFallback() {
        guard let data = profileData else { return }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("NextDNS.mobileconfig")
        try? data.write(to: tempURL)
        FileShareHelper.share(url: tempURL, isDirectory: false, defaultName: "NextDNS.mobileconfig")
    }

    /// Hoàn tất thiết lập
    func completeSetup() {
        isSetupCompleted = true
        let notif = UINotificationFeedbackGenerator()
        notif.notificationOccurred(.success)
    }

    func resetSetup() {
        isSetupCompleted = false
    }
}
