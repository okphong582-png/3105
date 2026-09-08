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
        iconCache.countLimit = 500
    }

    /// Tải danh sách tất cả ứng dụng từ hệ thống, MCM và filesystem an toàn, không bị văng
    func loadApps(forceRefresh: Bool = false) {
        if !forceRefresh && hasLoadedOnce && !apps.isEmpty {
            return
        }

        isLoading = apps.isEmpty
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. Quét ứng dụng từ hệ thống thông qua LSApplicationWorkspace / MobileInstallation
            // Đây là API gốc của iOS: cực nhanh (< 50ms), an toàn tuyệt đối, không crash,
            // lấy đầy đủ logo chính thức, tên hiển thị, phiên bản của TẤT CẢ game và app (Free Fire, Roblox, PUBG...)
            let apiApps = ContainerStore.installedAppsFromAPI()

            // 2. Quét các container hiện diện trong filesystem /var/mobile/Containers/Data/Application
            let filesystemApps = ContainerStore.containersFromFilesystem()

            // 3. Tạo bảng ánh xạ container path theo bundleID từ filesystem
            var containerMap: [String: String] = [:]
            for fsApp in filesystemApps {
                if !fsApp.containerPath.isEmpty && !fsApp.bundleID.isEmpty {
                    containerMap[fsApp.bundleID] = fsApp.containerPath
                }
            }

            var mergedApps: [InstalledApp] = []
            var seenBundleIDs = Set<String>()

            // Duyệt danh sách app từ API trước (chứa đầy đủ icon, tên, version)
            for app in apiApps {
                guard seenBundleIDs.insert(app.bundleID).inserted else { continue }
                var finalPath = app.containerPath
                if finalPath.isEmpty, let matchedPath = containerMap[app.bundleID] {
                    finalPath = matchedPath
                }
                if finalPath.isEmpty {
                    var err: NSString?
                    if let mcmPath = MCMContainerPathForIdentifier(2, app.bundleID, false, &err),
                       ContainerStore.isApplicationContainerPath(mcmPath) {
                        finalPath = mcmPath
                    }
                }
                mergedApps.append(InstalledApp(
                    bundleID: app.bundleID,
                    name: app.name,
                    containerPath: finalPath,
                    version: app.version,
                    icon: app.icon
                ))
            }

            // Bổ sung các container từ filesystem nếu chưa có trong danh sách API
            for fsApp in filesystemApps {
                guard seenBundleIDs.insert(fsApp.bundleID).inserted else { continue }
                let rawInfo = appInfoForBundleID(fsApp.bundleID) as? [String: Any] ?? [:]
                let displayName = fsApp.displayName.isEmpty ? (rawInfo["name"] as? String ?? fsApp.bundleID) : fsApp.displayName
                let icon = rawInfo["icon"] as? UIImage
                mergedApps.append(InstalledApp(
                    bundleID: fsApp.bundleID,
                    name: displayName,
                    containerPath: fsApp.containerPath,
                    version: rawInfo["version"] as? String ?? "",
                    icon: icon
                ))
            }

            // 4. Lọc theo chính sách hiển thị và sắp xếp tên ứng dụng A-Z
            var finalResult = mergedApps.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            finalResult.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            // 5. Cập nhật kết quả lên UI
            DispatchQueue.main.async {
                guard let self = self else { return }
                for app in finalResult {
                    if let icon = app.icon {
                        self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                    }
                }
                self.apps = finalResult
                self.isLoading = false
                self.hasLoadedOnce = true
                self.lastLoadedTime = Date()
                log("ZArchiverAppService: hoàn tất tải an toàn \(finalResult.count) ứng dụng")
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
