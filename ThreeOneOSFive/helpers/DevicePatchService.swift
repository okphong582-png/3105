import Foundation

enum DevicePatchService {
    static func apply(project: PatchProject) throws -> PatchTransactionReceipt {
        let adapted = adaptProjectForEnvironment(project)
        let bundleIDs = orderedBundleIdentifiers(in: adapted)
        return try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.apply(
                project: adapted,
                backupRoot: try PatchProjectLibrary.backupRootURL(),
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func restore(receipt: PatchTransactionReceipt) throws {
        let bundleIDs = try PatchTransaction.requiredBundleIdentifiers(for: receipt)
        try withResolvedContainers(bundleIDs: bundleIDs) { roots in
            try PatchTransaction.restore(
                receipt: receipt,
                containerResolver: { bundleID in
                    guard let root = roots[bundleID] else {
                        throw PatchPackageError.targetAppUnavailable(bundleID)
                    }
                    return root
                }
            )
        }
    }

    static func latestReceipt(projectID: UUID) -> PatchTransactionReceipt? {
        guard let backupRoot = try? PatchProjectLibrary.backupRootURL() else { return nil }
        return PatchTransaction.latestReceipt(projectID: projectID, backupRoot: backupRoot)
    }

    private static func orderedBundleIdentifiers(in project: PatchProject) -> [String] {
        project.allBundleIdentifiers
    }

    /// Tự động đồng bộ bundle Free Fire Thường <-> Free Fire MAX nếu người dùng chơi bản game tương ứng
    static func adaptProjectForEnvironment(_ project: PatchProject) -> PatchProject {
        var adapted = project
        let selectedGame = UserDefaults.standard.string(forKey: "oni_akuma_target_game_bundle_v5") ?? "com.dts.freefireth"

        for i in 0..<adapted.rules.count {
            let ruleBundle = adapted.rules[i].bundleID
            if ruleBundle == "com.dts.freefireth" || ruleBundle == "com.dts.freefiremax" {
                // Xác định bundle đích tối ưu
                var targetBundle = ruleBundle
                if let selectedContainer = ContainerStore.resolveAppContainerPath(bundleID: selectedGame),
                   ContainerStore.isApplicationContainerPath(selectedContainer) {
                    targetBundle = selectedGame
                } else if let exactContainer = ContainerStore.resolveAppContainerPath(bundleID: ruleBundle),
                          ContainerStore.isApplicationContainerPath(exactContainer) {
                    targetBundle = ruleBundle
                } else {
                    let alt = (ruleBundle == "com.dts.freefireth") ? "com.dts.freefiremax" : "com.dts.freefireth"
                    if let altContainer = ContainerStore.resolveAppContainerPath(bundleID: alt),
                       ContainerStore.isApplicationContainerPath(altContainer) {
                        targetBundle = alt
                    }
                }

                if targetBundle != ruleBundle {
                    adapted.rules[i].bundleID = targetBundle
                    if adapted.rules[i].relativePath.contains("Library/Preferences/com.dts.") {
                        adapted.rules[i].relativePath = "Library/Preferences/\(targetBundle).plist"
                        adapted.rules[i].replacementFilename = "\(targetBundle).plist"
                    }
                }
            }
        }

        // Đồng bộ bundleIdentifiers và directories
        let activeBundles = Set(adapted.rules.map(\.bundleID))
        if !activeBundles.isEmpty {
            adapted.bundleIdentifiers = Array(activeBundles)
        }
        for i in 0..<adapted.directories.count {
            let dirBundle = adapted.directories[i].bundleID
            if (dirBundle == "com.dts.freefireth" || dirBundle == "com.dts.freefiremax"),
               let primary = activeBundles.first(where: { $0 == "com.dts.freefireth" || $0 == "com.dts.freefiremax" }) {
                adapted.directories[i].bundleID = primary
            }
        }

        return adapted
    }

    private static func withResolvedContainers<T>(
        bundleIDs: [String],
        operation: ([String: URL]) throws -> T
    ) throws -> T {
        var roots: [String: URL] = [:]

        for bundleID in bundleIDs {
            var resolvedPath = ContainerStore.resolveAppContainerPath(bundleID: bundleID)
            
            // Fallback: nếu bundleID là Free Fire mà chưa tìm thấy, thử bundle anh em của nó
            if resolvedPath == nil && (bundleID == "com.dts.freefireth" || bundleID == "com.dts.freefiremax") {
                let alt = (bundleID == "com.dts.freefireth") ? "com.dts.freefiremax" : "com.dts.freefireth"
                if let altPath = ContainerStore.resolveAppContainerPath(bundleID: alt),
                   ContainerStore.isApplicationContainerPath(altPath) {
                    resolvedPath = altPath
                }
            }

            guard let path = resolvedPath, ContainerStore.isApplicationContainerPath(path) else {
                throw PatchPackageError.targetAppUnavailable(bundleID)
            }
            roots[bundleID] = PatchPathValidator.canonicalFileURL(URL(fileURLWithPath: path, isDirectory: true))
        }
        return try operation(roots)
    }
}
