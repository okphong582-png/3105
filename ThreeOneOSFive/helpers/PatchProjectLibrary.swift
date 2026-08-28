import Foundation

struct PatchLibraryItem: Identifiable {
    let summary: PatchPackageSummary
    var project: PatchProject?
    var contentKey: Data?
    var packageURL: URL

    var id: UUID { summary.packageID }
    var isLocked: Bool { project == nil }
    var workspaceURL: URL? {
        PatchWorkspaceService.workspaceURL(projectID: id)
    }
}

struct PatchPasswordRequest: Identifiable {
    let summary: PatchPackageSummary
    var id: UUID { summary.packageID }
}

enum PatchProjectLibrary {
    static func packageRootURL(fileManager: FileManager = .default) throws -> URL {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = base.appendingPathComponent("PatchProjects", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func backupRootURL(fileManager: FileManager = .default) throws -> URL {
        let root = try packageRootURL(fileManager: fileManager)
            .appendingPathComponent("Backups", isDirectory: true)
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    static func isSupportedExtension(_ ext: String) -> Bool {
        let clean = ext.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased()
        return clean == "3105" || clean == "hoanghatrongkien"
    }

    /// Finds all bundled .3105 and .hoanghatrongkien URLs using multiple discovery strategies
    static func findBundledPackageURLs(fileManager: FileManager = .default) -> [URL] {
        var foundDict: [String: URL] = [:]

        // Strategy 1: Standard Bundle URLs
        if let urls = Bundle.main.urls(forResourcesWithExtension: "3105", subdirectory: nil) {
            for u in urls { foundDict[u.lastPathComponent.lowercased()] = u }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "hoanghatrongkien", subdirectory: nil) {
            for u in urls { foundDict[u.lastPathComponent.lowercased()] = u }
        }

        // Strategy 2: Bundle.main.paths
        let paths3105 = Bundle.main.paths(forResourcesOfType: "3105", inDirectory: nil)
        for p in paths3105 {
            let u = URL(fileURLWithPath: p)
            foundDict[u.lastPathComponent.lowercased()] = u
        }

        // Strategy 3: Enumerate Bundle directories
        let searchDirectories = [Bundle.main.resourceURL, Bundle.main.bundleURL].compactMap { $0 }
        for dir in searchDirectories {
            if let urls = try? fileManager.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) {
                for url in urls where isSupportedExtension(url.pathExtension) {
                    foundDict[url.lastPathComponent.lowercased()] = url
                }
            }
        }

        // Strategy 4: Explicit known names
        let knownFiles = [
            "Aim Body.3105",
            "Aim Drag.3105",
            "Aim Chest.3105",
            "Aim Magic.3105",
            "Aim Neck.3105",
            "Modskin.3105",
            "Mod đồ chỉ sử dụng nhân vật Ignis.3105",
            "DV_đỏ_ff.3105"
        ]
        for filename in knownFiles {
            let base = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            if let u = Bundle.main.url(forResource: base, withExtension: ext) {
                foundDict[filename.lowercased()] = u
            }
            if let u = Bundle.main.url(forResource: filename, withExtension: nil) {
                foundDict[filename.lowercased()] = u
            }
            let directBundle = Bundle.main.bundleURL.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: directBundle.path) {
                foundDict[filename.lowercased()] = directBundle
            }
        }

        return Array(foundDict.values)
    }

    static func load(fileManager: FileManager = .default) -> [PatchLibraryItem] {
        guard let root = try? packageRootURL(fileManager: fileManager) else { return [] }

        // 1. Copy all bundled package URLs to root
        let bundledURLs = findBundledPackageURLs(fileManager: fileManager)
        for bundledURL in bundledURLs {
            let destURL = root.appendingPathComponent(bundledURL.lastPathComponent)
            if !fileManager.fileExists(atPath: destURL.path) {
                try? fileManager.copyItem(at: bundledURL, to: destURL)
            } else if let bundledSize = try? bundledURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                      let destSize = try? destURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                      bundledSize != destSize {
                try? fileManager.removeItem(at: destURL)
                try? fileManager.copyItem(at: bundledURL, to: destURL)
            }
        }

        // 2. Discover all package URLs in root + bundle
        var allCandidateURLs: [URL] = []
        if let localURLs = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) {
            allCandidateURLs.append(contentsOf: localURLs.filter { isSupportedExtension($0.pathExtension) })
        }

        // Also add bundled URLs directly in case copying failed or had permission issues
        for bURL in bundledURLs {
            if !allCandidateURLs.contains(where: { $0.lastPathComponent.lowercased() == bURL.lastPathComponent.lowercased() }) {
                allCandidateURLs.append(bURL)
            }
        }

        var itemsByFilename: [String: PatchLibraryItem] = [:]
        for url in allCandidateURLs {
            if let item = parseItem(from: url, fileManager: fileManager) {
                itemsByFilename[url.lastPathComponent.lowercased()] = item
            }
        }

        return Array(itemsByFilename.values).sorted {
            $0.packageURL.lastPathComponent < $1.packageURL.lastPathComponent
        }
    }

    static func parseItem(from url: URL, fileManager: FileManager = .default) -> PatchLibraryItem? {
        do {
            let data = try readPackage(at: url)
            let summary = try PatchPackageCodec.inspect(data)
            let decoded: DecodedPatchPackage?
            if let contentKey = try PatchKeyStore.load(for: summary) {
                decoded = try PatchPackageCodec.decode(data, contentKey: contentKey)
            } else if summary.isPasswordProtected {
                decoded = nil
            } else {
                decoded = try PatchPackageCodec.decode(data, password: nil)
            }
            let item = PatchLibraryItem(
                summary: summary,
                project: decoded?.project,
                contentKey: decoded?.contentKey,
                packageURL: url
            )
            if summary.schemaVersion >= 2, let project = decoded?.project {
                do {
                    _ = try PatchWorkspaceService.ensureWorkspace(for: project)
                } catch {
                    log("patch: workspace unavailable for \(project.id.uuidString)")
                }
            }
            return item
        } catch {
            log("patch: error parsing package \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    static func loadItem(forFilename filename: String, fileManager: FileManager = .default) -> PatchLibraryItem? {
        let cleanName = filename.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // 1. Check in root
        if let root = try? packageRootURL(fileManager: fileManager) {
            let rootCandidate = root.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: rootCandidate.path),
               let item = parseItem(from: rootCandidate, fileManager: fileManager) {
                return item
            }

            // Check case-insensitive match in root
            if let urls = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
                for u in urls where u.lastPathComponent.lowercased() == cleanName || u.lastPathComponent.lowercased().contains(cleanName) {
                    if let item = parseItem(from: u, fileManager: fileManager) {
                        return item
                    }
                }
            }
        }

        // 2. Check in Bundle
        let bundled = findBundledPackageURLs(fileManager: fileManager)
        for bURL in bundled {
            if bURL.lastPathComponent.lowercased() == cleanName || bURL.lastPathComponent.lowercased().contains(cleanName) {
                if let item = parseItem(from: bURL, fileManager: fileManager) {
                    return item
                }
            }
        }

        return nil
    }

    static func readPackage(at url: URL) throws -> Data {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
        guard values.isDirectory != true,
              values.isSymbolicLink != true,
              values.isRegularFile == true else {
            throw PatchPackageError.invalidProject
        }
        return try Data(contentsOf: url, options: .mappedIfSafe)
    }

    static func save(
        data: Data,
        projectName: String,
        existingURL: URL? = nil,
        preferredExtension: String = "hoanghatrongkien",
        fileManager: FileManager = .default
    ) throws -> URL {
        let destination: URL
        if let existingURL {
            destination = existingURL
        } else {
            let root = try packageRootURL(fileManager: fileManager)
            let baseName = sanitizedFilename(projectName)
            var candidate = root.appendingPathComponent(baseName).appendingPathExtension(preferredExtension)
            var suffix = 2
            while fileManager.fileExists(atPath: candidate.path) {
                candidate = root.appendingPathComponent("\(baseName)-\(suffix)").appendingPathExtension(preferredExtension)
                suffix += 1
            }
            destination = candidate
        }
        try data.write(to: destination, options: [.atomic, .completeFileProtection])
        return destination
    }

    static func installImportedPackage(
        data: Data,
        decoded: DecodedPatchPackage,
        summary: PatchPackageSummary,
        existingURL: URL?,
        fileManager: FileManager = .default
    ) throws {
        let previousData = try existingURL.map { try readPackage(at: $0) }
        var savedURL: URL?
        do {
            savedURL = try save(
                data: data,
                projectName: decoded.project.name,
                existingURL: existingURL,
                fileManager: fileManager
            )
            if summary.schemaVersion >= 2 {
                _ = try PatchWorkspaceService.replaceWorkspace(
                    with: decoded.project,
                    fileManager: fileManager
                )
            } else {
                try? PatchWorkspaceService.deleteWorkspace(
                    projectID: decoded.project.id,
                    fileManager: fileManager
                )
            }
        } catch {
            if let previousData, let existingURL {
                try? previousData.write(
                    to: existingURL,
                    options: [.atomic, .completeFileProtection]
                )
            } else if let savedURL, fileManager.fileExists(atPath: savedURL.path) {
                try? fileManager.removeItem(at: savedURL)
            }
            throw error
        }
    }

    static func delete(_ item: PatchLibraryItem, fileManager: FileManager = .default) throws {
        if fileManager.fileExists(atPath: item.packageURL.path) {
            try fileManager.removeItem(at: item.packageURL)
        }
        try? PatchWorkspaceService.deleteWorkspace(projectID: item.id, fileManager: fileManager)
        try? PatchKeyStore.delete(for: item.summary)
    }

    static func synchronizeWorkspace(
        item: PatchLibraryItem,
        fileManager: FileManager = .default
    ) throws -> PatchProject {
        guard item.summary.schemaVersion >= 2,
              let baseProject = item.project,
              let contentKey = item.contentKey else {
            throw PatchPackageError.invalidProject
        }
        let workspace = try PatchWorkspaceService.ensureWorkspace(
            for: baseProject,
            fileManager: fileManager
        )
        let project = try PatchWorkspaceService.snapshot(
            baseProject: baseProject,
            workspaceURL: workspace,
            fileManager: fileManager
        )
        let original = try readPackage(at: item.packageURL)
        let updated = try PatchPackageCodec.update(
            original,
            project: project,
            contentKey: contentKey,
            schemaVersion: PatchPackageCodec.latestSchemaVersion
        )
        _ = try save(
            data: updated,
            projectName: project.name,
            existingURL: item.packageURL,
            fileManager: fileManager
        )
        return project
    }

    private static func sanitizedFilename(_ rawName: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let scalars = rawName.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
        let result = String(scalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(80)
        return result.isEmpty ? "Patch" : String(result)
    }
}
