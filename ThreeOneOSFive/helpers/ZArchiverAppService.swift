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

            // 5. Kết hợp các nguồn nhận diện cơ bản
            let baseIdentifiedApps = mcmApps + apiApps
            var mergedApps = ContainerDiscoveryMerger.merge(
                enumerated: filesystemApps,
                identified: baseIdentifiedApps,
                path: { $0.containerPath }
            )

            var preliminary = mergedApps.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            preliminary.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            // Cập nhật kết quả nhanh lên giao diện nếu tìm thấy app
            if !preliminary.isEmpty {
                DispatchQueue.main.async {
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
                    log("ZArchiverAppService: đã nạp nhanh \(preliminary.count) ứng dụng")
                }
            }

            // 6. Quét sâu toàn bộ game và ứng dụng (Free Fire, Roblox, PUBG, v.v.) qua LaunchServices cache và catalog
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
                    identified: discoveredApps + baseIdentifiedApps,
                    fallback: [],
                    identifier: { $0.bundleID },
                    path: { $0.containerPath }
                )
                progressive = progressive.filter {
                    ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
                }
                progressive.sort {
                    $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    for app in progressive {
                        if let icon = app.icon {
                            self.iconCache.setObject(icon, forKey: app.bundleID as NSString)
                        }
                    }
                    self.apps = progressive
                    self.isLoading = false
                    self.hasLoadedOnce = true
                }
            }

            // 7. Hoàn thiện kết quả cuối cùng
            let allKnownApps = mhaApps + baseIdentifiedApps
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
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

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
                log("ZArchiverAppService: hoàn tất nạp đầy đủ \(finalResult.count) ứng dụng")
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
