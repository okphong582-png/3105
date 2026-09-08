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

    /// Tải danh sách tất cả ứng dụng từ hệ thống, MCM và filesystem
    func loadApps(forceRefresh: Bool = false) {
        if !forceRefresh && hasLoadedOnce && !apps.isEmpty {
            return
        }

        isLoading = apps.isEmpty
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. Quét thông tin metadata bundle
            let bundleMetadata = ContainerStore.applicationBundleMetadataCatalog()

            // 2. Quét từ API MobileInstallation / LaunchServices
            let apiApps = ContainerStore.applyingBundleMetadata(
                to: ContainerStore.installedAppsFromAPI(),
                catalog: bundleMetadata
            )

            // 3. Quét từ MCM (MobileContainerManager)
            let dynamicIdentifiers = ContainerStore.dynamicAppIdentifiers()
            let mcmApps = ContainerStore.installedAppsFromMCM(
                identifiers: dynamicIdentifiers,
                bundleMetadata: bundleMetadata
            )

            // 4. Quét trực tiếp thư mục filesystem /var/mobile/Containers/Data/Application
            let filesystemApps = ContainerStore.containersFromFilesystem()

            // 5. Kết hợp toàn bộ nguồn nhận diện cơ bản
            let baseIdentifiedApps = mcmApps + apiApps
            var mergedApps = ContainerDiscoveryMerger.merge(
                enumerated: filesystemApps,
                identified: baseIdentifiedApps,
                path: { $0.containerPath }
            )

            // Lọc ứng dụng hợp lệ và sắp xếp tên
            var preliminary = mergedApps.filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }
            preliminary.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }

            // Cập nhật kết quả nhanh lên giao diện
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
                log("ZArchiverAppService: đã tải nhanh \(preliminary.count) ứng dụng")
            }

            // 6. Quét sâu các ứng dụng qua MHA Candidate Catalog
            let launchServicesIdentifiers = ContainerStore.launchServicesStoreIdentifiers()
            let mhaIdentifiers = MHAIdentifierCatalog.identifiers(
                dynamic: dynamicIdentifiers,
                installed: apiApps.map(\.bundleID),
                research: ContainerStore.researchAppIdentifiers,
                custom: bundleMetadata.keys.sorted(),
                launchServices: launchServicesIdentifiers
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
                }
            }

            // 7. Hoàn thiện kết hợp với các ứng dụng suy luận từ filesystem
            let allKnownApps = mhaApps + baseIdentifiedApps
            let identifiedPaths = Set(allKnownApps.map {
                ContainerDiscoveryMerger.canonicalPath($0.containerPath)
            })
            let unmatchedFilesystemApps = filesystemApps.filter {
                !identifiedPaths.contains(ContainerDiscoveryMerger.canonicalPath($0.containerPath))
            }
            let inferredApps = ContainerStore.inferUnidentifiedApps(
                in: unmatchedFilesystemApps,
                knownApps: allKnownApps,
                launchServicesIdentifiers: Set(launchServicesIdentifiers)
            ).filter {
                ContainerPresentationPolicy.shouldShow(bundleID: $0.bundleID)
            }

            var finalResult = AppDataCatalogMerger.merge(
                identified: allKnownApps,
                fallback: inferredApps,
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
                log("ZArchiverAppService: hoàn tất quét toàn diện \(finalResult.count) ứng dụng")
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
