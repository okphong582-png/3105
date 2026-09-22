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
    private static var cachedAllApps: [InstalledApp] = []

    private init() {
        iconCache.countLimit = 500
        // Nạp tức thì các app game Free Fire ngay khi service khởi tạo trong RAM (0ms)
        let instantGames = Self.fastResolveFreeFireApps()
        if !instantGames.isEmpty {
            self.apps = instantGames
            for app in instantGames {
                if let icon = app.icon {
                    self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                }
            }
        }
    }

    /// Tìm siêu tốc container của Free Fire Thường & MAX trực tiếp trong < 1ms
    static func fastResolveFreeFireApps() -> [InstalledApp] {
        var results: [InstalledApp] = []
        let targets = [
            ("com.dts.freefireth", "Free Fire", "FFTHLogo"),
            ("com.dts.freefiremax", "Free Fire MAX", "FFMAXLogo")
        ]
        for (bid, name, iconKey) in targets {
            if let path = ContainerStore.resolveAppContainerPath(bundleID: bid),
               FileManager.default.fileExists(atPath: path) {
                let icon = UIImage(named: iconKey)
                    ?? (bid == "com.dts.freefiremax" ? UIImage(named: "ffmax") : UIImage(named: "ffth"))
                results.append(InstalledApp(
                    bundleID: bid,
                    name: name,
                    containerPath: path,
                    version: "OB",
                    icon: icon
                ))
            }
        }
        return results
    }

    /// Tải danh sách tất cả ứng dụng từ hệ thống, MCM và filesystem siêu tốc 0-delay
    func loadApps(forceRefresh: Bool = false) {
        if !forceRefresh && !Self.cachedAllApps.isEmpty {
            self.apps = Self.cachedAllApps
            self.isLoading = false
            return
        }

        if !forceRefresh && hasLoadedOnce && !apps.isEmpty {
            return
        }

        // 1. Nạp ngay lập tức Free Fire TH & MAX để hiển thị tức thì không chờ đợi
        let instantGames = Self.fastResolveFreeFireApps()
        if !instantGames.isEmpty && self.apps.isEmpty {
            self.apps = instantGames
            for app in instantGames {
                if let icon = app.icon {
                    self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                }
            }
        }

        isLoading = apps.isEmpty
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. Quét thông tin metadata bundle
            let bundleMetadata = ContainerStore.applicationBundleMetadataCatalog()

            // 2. Quét nhanh từ API MobileInstallation / LaunchServices
            let apiApps = ContainerStore.installedAppsFromAPI()

            // 3. Quét từ MCM (MobileContainerManager) dynamic identifiers
            let dynamicIdentifiers = ContainerStore.dynamicAppIdentifiers()
            let mcmApps = ContainerStore.installedAppsFromMCM(
                identifiers: dynamicIdentifiers,
                bundleMetadata: bundleMetadata
            )

            // 4. Quét từ filesystem nếu có quyền truy cập
            let filesystemApps = ContainerStore.containersFromFilesystem()

            // 5. Kết hợp các nguồn nhận diện cơ bản + Instant Games
            let baseIdentifiedApps = instantGames + mcmApps + apiApps
            let mergedApps = ContainerDiscoveryMerger.merge(
                enumerated: filesystemApps,
                identified: baseIdentifiedApps,
                path: { $0.containerPath }
            )

            var preliminary = mergedApps.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            preliminary.sort {
                // Ưu tiên hiển thị Free Fire lên đầu danh sách để dán tệp nhanh nhất
                let isGame0 = $0.bundleID.contains("freefire")
                let isGame1 = $1.bundleID.contains("freefire")
                if isGame0 && !isGame1 { return true }
                if !isGame0 && isGame1 { return false }
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            // Cập nhật kết quả nhanh lên giao diện
            if !preliminary.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for app in preliminary {
                        if let icon = app.icon {
                            self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                        }
                    }
                    self.apps = preliminary
                    self.isLoading = false
                    self.hasLoadedOnce = true
                    self.lastLoadedTime = Date()
                    Self.cachedAllApps = preliminary
                }
            }

            // 6. Quét sâu toàn bộ game và ứng dụng qua LaunchServices cache và catalog
            let launchServicesIdentifiers = ContainerStore.launchServicesStoreIdentifiers()
            let mhaIdentifiers = MHAIdentifierCatalog.identifiers(
                dynamic: dynamicIdentifiers,
                installed: apiApps.map(\.bundleID),
                research: ContainerStore.researchAppIdentifiers,
                custom: bundleMetadata.keys.sorted(),
                launchServices: launchServicesIdentifiers,
                limit: 1500
            )

            let mhaApps = ContainerStore.installedAppsFromMHACandidates(
                identifiers: mhaIdentifiers,
                bundleMetadata: bundleMetadata
            ) { [weak self] discoveredApps in
                var progressive = AppDataCatalogMerger.merge(
                    identified: instantGames + discoveredApps + baseIdentifiedApps,
                    fallback: [],
                    identifier: { $0.bundleID },
                    path: { $0.containerPath }
                )
                progressive = progressive.filter {
                    ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
                }
                progressive.sort {
                    let isGame0 = $0.bundleID.contains("freefire")
                    let isGame1 = $1.bundleID.contains("freefire")
                    if isGame0 && !isGame1 { return true }
                    if !isGame0 && isGame1 { return false }
                    return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    for app in progressive {
                        if let icon = app.icon {
                            self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                        }
                    }
                    self.apps = progressive
                    self.isLoading = false
                    self.hasLoadedOnce = true
                    Self.cachedAllApps = progressive
                }
            }

            // 7. Hoàn thiện kết quả cuối cùng
            let allKnownApps = instantGames + mhaApps + baseIdentifiedApps
            var finalResult = AppDataCatalogMerger.merge(
                identified: allKnownApps,
                fallback: filesystemApps,
                identifier: { $0.bundleID },
                path: { $0.containerPath }
            )
            finalResult = finalResult.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            finalResult.sort {
                let isGame0 = $0.bundleID.contains("freefire")
                let isGame1 = $1.bundleID.contains("freefire")
                if isGame0 && !isGame1 { return true }
                if !isGame0 && isGame1 { return false }
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            DispatchQueue.main.async { [weak self] in
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
                Self.cachedAllApps = finalResult
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
