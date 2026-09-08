import Foundation
import UIKit

@MainActor
final class ZArchiverAppService: ObservableObject {
    static let shared = ZArchiverAppService()

    @Published private(set) var apps: [InstalledApp] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastLoadedTime: Date?

    private let iconCache = NSCache<NSString, UIImage>()
    private var hasLoadedOnce = false

    private init() {
        iconCache.countLimit = 300
    }

    /// Tải danh sách ứng dụng siêu nhanh từ bộ đệm hoặc quét nền
    func loadApps(forceRefresh: Bool = false) {
        if !forceRefresh && hasLoadedOnce && !apps.isEmpty {
            return
        }

        isLoading = apps.isEmpty
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. Quét nhanh từ MobileInstallation / LaunchServices API
            var discovered = ContainerStore.installedAppsFromAPI()

            // 2. Nếu không đủ, quét bổ sung qua MCM / filesystem scan
            if discovered.isEmpty {
                let metadataCatalog = ContainerStore.applicationBundleMetadataCatalog()
                let mcmApps = ContainerStore.installedAppsFromMCM(bundleMetadata: metadataCatalog)
                discovered = ContainerStore.applyingBundleMetadata(to: mcmApps, catalog: metadataCatalog)
            }

            // Lọc các ứng dụng hợp lệ và sắp xếp theo tên hiển thị
            var result = discovered.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            result.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            DispatchQueue.main.async {
                guard let self = self else { return }
                for app in result {
                    if let icon = app.icon {
                        self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                    }
                }
                self.apps = result
                self.isLoading = false
                self.hasLoadedOnce = true
                self.lastLoadedTime = Date()
                log("ZArchiverAppService: đã nạp \(result.count) ứng dụng thành công")
            }
        }
    }

    /// Lấy icon cho bundleID từ cache hoặc hệ thống
    func getCachedIcon(for bundleID: String) -> UIImage? {
        if let cached = iconCache.object(forKey: bundleID as NSString) {
            return cached
        }
        let icon = iconForBundleID(bundleID)
        iconCache.setObject(icon, forKey: bundleID as NSString)
        return icon
    }
}
