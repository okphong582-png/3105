import CryptoKit
import Darwin
import Foundation

struct PatchTransactionReceipt: Equatable, Identifiable {
    let id: UUID
    let projectID: UUID
    let journalURL: URL
}

enum PatchTransaction {
    private enum Status: String, Codable {
        case prepared
        case applied
        case rolledBack
        case restored
    }

    private struct Record: Codable {
        let ruleID: UUID
        let bundleID: String
        let relativePath: String
        let containerFingerprint: Data
        let originalExisted: Bool
        let backupFilename: String?
        let originalDigest: Data?
        let replacementDigest: Data
    }

    private struct DirectoryRecord: Codable {
        let bundleID: String
        let relativePath: String
        let containerFingerprint: Data
    }

    private struct Journal: Codable {
        let schemaVersion: Int
        let transactionID: UUID
        let projectID: UUID
        let createdAt: Date
        var status: Status
        let records: [Record]
        let createdDirectories: [DirectoryRecord]?
    }

    private struct ResolvedRule {
        let rule: PatchRule
        let containerRoot: URL
        let target: URL
    }

    private struct ResolvedDirectory {
        let bundleID: String
        let relativePath: String
        let containerRoot: URL
        let target: URL
    }

    private static let schemaVersion = 1
    private static let journalFilename = "journal.plist"

    static func apply(
        project: PatchProject,
        backupRoot: URL,
        containerResolver: (String) throws -> URL,
        beforeWrite: ((Int) throws -> Void)? = nil,
        fileManager: FileManager = .default
    ) throws -> PatchTransactionReceipt {
        guard !project.rules.isEmpty || !project.directories.isEmpty else {
            throw PatchPackageError.invalidProject
        }

        var roots: [String: URL] = [:]
        var resolvedRules: [ResolvedRule] = []
        var resolvedDirectories: [ResolvedDirectory] = []
        var targetKeys = Set<String>()

        func resolvedRoot(for bundleID: String) throws -> URL {
            if let cached = roots[bundleID] { return cached }
            let root = PatchPathValidator.canonicalFileURL(try containerResolver(bundleID))
            roots[bundleID] = root
            return root
        }

        var requestedDirectories = Set<String>()
        for directory in project.directories {
            let bundleID = try PatchPathValidator.canonicalBundleIdentifier(directory.bundleID)
            guard bundleID == directory.bundleID else { throw PatchPackageError.invalidProject }
            requestedDirectories.insert(bundleID + "\0" + directory.relativePath)
        }
        for rule in project.rules {
            let components = try PatchPathValidator.canonicalRelativePath(rule.relativePath)
                .split(separator: "/").map(String.init)
            guard components.count > 1 else { continue }
            for count in 1..<components.count {
                requestedDirectories.insert(
                    rule.bundleID + "\0" + components.prefix(count).joined(separator: "/")
                )
            }
        }

        for key in requestedDirectories.sorted(by: directoryKeySort) {
            let parts = key.split(separator: "\0", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { throw PatchPackageError.invalidProject }
            let bundleID = try PatchPathValidator.canonicalBundleIdentifier(String(parts[0]))
            let relativePath = try PatchPathValidator.canonicalRelativePath(String(parts[1]))
            let root = try resolvedRoot(for: bundleID)
            let target = try PatchPathValidator.resolveContainedTargetURL(
                relativePath: relativePath,
                containerRoot: root
            )
            try validateDirectoryTarget(
                target,
                relativePath: relativePath,
                containerRoot: root,
                fileManager: fileManager
            )
            resolvedDirectories.append(ResolvedDirectory(
                bundleID: bundleID,
                relativePath: relativePath,
                containerRoot: root,
                target: target
            ))
        }

        for rule in project.rules {
            let bundleID = try PatchPathValidator.canonicalBundleIdentifier(rule.bundleID)
            guard bundleID == rule.bundleID else { throw PatchPackageError.invalidProject }
            let root = try resolvedRoot(for: bundleID)
            let target = try PatchPathValidator.resolveContainedTargetURL(
                relativePath: rule.relativePath,
                containerRoot: root
            )
            let targetKey = target.path
            guard targetKeys.insert(targetKey).inserted else {
                throw PatchPackageError.duplicateTarget
            }
            try validateFileTarget(
                target,
                relativePath: rule.relativePath,
                containerRoot: root,
                allowMissingParents: true,
                fileManager: fileManager
            )
            resolvedRules.append(ResolvedRule(rule: rule, containerRoot: root, target: target))
        }

        let transactionID = UUID()
        let transactionDirectory = backupRoot
            .appendingPathComponent(project.id.uuidString, isDirectory: true)
            .appendingPathComponent(transactionID.uuidString, isDirectory: true)
        try? fileManager.createDirectory(at: transactionDirectory, withIntermediateDirectories: true)

        var records: [Record] = []
        let createdDirectories = resolvedDirectories.compactMap { resolved -> DirectoryRecord? in
            guard !fileManager.fileExists(atPath: resolved.target.path) else { return nil }
            return DirectoryRecord(
                bundleID: resolved.bundleID,
                relativePath: resolved.relativePath,
                containerFingerprint: containerFingerprint(resolved.containerRoot)
            )
        }
        for resolved in resolvedRules {
            let existed = fileManager.fileExists(atPath: resolved.target.path)
            let backupFilename = existed ? "\(resolved.rule.id.uuidString).original" : nil
            var originalDigest: Data?
            if let backupFilename {
                let backupURL = transactionDirectory.appendingPathComponent(backupFilename)
                if (try? fileManager.copyItem(at: resolved.target, to: backupURL)) != nil {
                    originalDigest = try? digestFile(backupURL)
                } else if let origData = try? Data(contentsOf: resolved.target) {
                    try? origData.write(to: backupURL)
                    originalDigest = digest(origData)
                }
            }
            records.append(Record(
                ruleID: resolved.rule.id,
                bundleID: resolved.rule.bundleID,
                relativePath: resolved.rule.relativePath,
                containerFingerprint: containerFingerprint(resolved.containerRoot),
                originalExisted: existed,
                backupFilename: backupFilename,
                originalDigest: originalDigest,
                replacementDigest: digest(resolved.rule.replacementData)
            ))
        }

        let journalURL = transactionDirectory.appendingPathComponent(journalFilename)
        var journal = Journal(
            schemaVersion: schemaVersion,
            transactionID: transactionID,
            projectID: project.id,
            createdAt: Date(),
            status: .prepared,
            records: records,
            createdDirectories: createdDirectories
        )
        try? writeJournal(journal, to: journalURL)

        do {
            for resolved in resolvedDirectories {
                if !fileManager.fileExists(atPath: resolved.target.path) {
                    try? fileManager.createDirectory(
                        at: resolved.target,
                        withIntermediateDirectories: true,
                        attributes: [.posixPermissions: 0o777]
                    )
                }
            }
            for (index, resolved) in resolvedRules.enumerated() {
                try beforeWrite?(index)
                try writeOrReplaceFile(
                    resolved.rule.replacementData,
                    to: resolved.target,
                    fileManager: fileManager
                )
            }
            journal.status = .applied
            try? writeJournal(journal, to: journalURL)
            return PatchTransactionReceipt(
                id: transactionID,
                projectID: project.id,
                journalURL: journalURL
            )
        } catch {
            do {
                try restoreRecords(
                    records,
                    transactionDirectory: transactionDirectory,
                    roots: roots,
                    requirePatchedDigest: false,
                    createdDirectories: createdDirectories,
                    fileManager: fileManager
                )
                journal.status = .rolledBack
                try? writeJournal(journal, to: journalURL)
            } catch {
                // Preserve the prepared journal and backups for explicit recovery.
            }
            throw PatchPackageError.applyFailed
        }
    }

    static func restore(
        receipt: PatchTransactionReceipt,
        containerResolver: (String) throws -> URL,
        fileManager: FileManager = .default
    ) throws {
        var journal: Journal
        do {
            journal = try readJournal(receipt.journalURL)
        } catch {
            throw PatchPackageError.restoreFailed
        }
        guard journal.schemaVersion == schemaVersion,
              journal.transactionID == receipt.id,
              journal.projectID == receipt.projectID,
              journal.status == .applied || journal.status == .prepared
        else {
            throw PatchPackageError.restoreFailed
        }

        var roots: [String: URL] = [:]
        do {
            for record in journal.records where roots[record.bundleID] == nil {
                let root = PatchPathValidator.canonicalFileURL(try containerResolver(record.bundleID))
                guard containerFingerprint(root) == record.containerFingerprint else {
                    throw PatchPackageError.restoreFailed
                }
                roots[record.bundleID] = root
            }
            try restoreRecords(
                journal.records,
                transactionDirectory: receipt.journalURL.deletingLastPathComponent(),
                roots: roots,
                requirePatchedDigest: journal.status == .applied,
                createdDirectories: journal.createdDirectories ?? [],
                fileManager: fileManager
            )
            journal.status = .restored
            try writeJournal(journal, to: receipt.journalURL)
        } catch {
            throw PatchPackageError.restoreFailed
        }
    }

    static func latestReceipt(
        projectID: UUID,
        backupRoot: URL,
        fileManager: FileManager = .default
    ) -> PatchTransactionReceipt? {
        let projectDirectory = backupRoot.appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard let directories = try? fileManager.contentsOfDirectory(
            at: projectDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        return directories.compactMap { directory -> (Journal, URL)? in
            let url = directory.appendingPathComponent(journalFilename)
            guard let journal = try? readJournal(url),
                  journal.status == .applied || journal.status == .prepared else { return nil }
            return (journal, url)
        }
        .sorted { $0.0.createdAt > $1.0.createdAt }
        .first
        .map {
            PatchTransactionReceipt(
                id: $0.0.transactionID,
                projectID: $0.0.projectID,
                journalURL: $0.1
            )
        }
    }

    static func requiredBundleIdentifiers(for receipt: PatchTransactionReceipt) throws -> [String] {
        let journal = try readJournal(receipt.journalURL)
        guard journal.schemaVersion == schemaVersion,
              journal.transactionID == receipt.id,
              journal.projectID == receipt.projectID else {
            throw PatchPackageError.restoreFailed
        }
        var seen = Set<String>()
        return (journal.records.map(\.bundleID)
            + (journal.createdDirectories ?? []).map(\.bundleID)).compactMap { bundleID in
                seen.insert(bundleID).inserted ? bundleID : nil
            }
    }

    private static func restoreRecords(
        _ records: [Record],
        transactionDirectory: URL,
        roots: [String: URL],
        requirePatchedDigest: Bool,
        createdDirectories: [DirectoryRecord],
        fileManager: FileManager
    ) throws {
        var resolvedTargets: [(Record, URL)] = []
        for record in records {
            guard let root = roots[record.bundleID],
                  containerFingerprint(root) == record.containerFingerprint else {
                continue
            }
            if let target = try? PatchPathValidator.resolveContainedTargetURL(
                relativePath: record.relativePath,
                containerRoot: root
            ) {
                resolvedTargets.append((record, target))
            }
        }

        for (record, target) in resolvedTargets.reversed() {
            if record.originalExisted, let backupFilename = record.backupFilename {
                let backup = transactionDirectory.appendingPathComponent(backupFilename)
                if fileManager.fileExists(atPath: backup.path) {
                    try? atomicCopy(backup, to: target, fileManager: fileManager)
                }
            } else if fileManager.fileExists(atPath: target.path) {
                try? fileManager.removeItem(at: target)
            }
        }

        for directory in createdDirectories.reversed() {
            guard let root = roots[directory.bundleID] else { continue }
            guard let target = try? PatchPathValidator.resolveContainedTargetURL(
                relativePath: directory.relativePath,
                containerRoot: root
            ) else { continue }
            guard fileManager.fileExists(atPath: target.path) else { continue }
            if let contents = try? fileManager.contentsOfDirectory(atPath: target.path), contents.isEmpty {
                try? fileManager.removeItem(at: target)
            }
        }
    }

    private static func validateFileTarget(
        _ target: URL,
        relativePath: String,
        containerRoot: URL,
        allowMissingParents: Bool,
        fileManager: FileManager
    ) throws {
        let components = try PatchPathValidator.canonicalRelativePath(relativePath)
            .split(separator: "/")
            .map(String.init)
        var cursor = PatchPathValidator.canonicalFileURL(containerRoot)
        for component in components.dropLast() {
            cursor.appendPathComponent(component, isDirectory: true)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: cursor.path, isDirectory: &isDir) {
                if !isDir.boolValue {
                    // Nếu đang là một tệp, tự động xóa đi để tạo thư mục chứa
                    try? fileManager.removeItem(at: cursor)
                    break
                }
            } else {
                if allowMissingParents { break }
            }
        }
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: target.path, isDirectory: &isDir) {
            if isDir.boolValue {
                // Nếu đích đang là thư mục, tự động xóa đi để ghi đè tệp
                try? fileManager.removeItem(at: target)
            }
        }
    }

    private static func validateDirectoryTarget(
        _ target: URL,
        relativePath: String,
        containerRoot: URL,
        fileManager: FileManager
    ) throws {
        let components = try PatchPathValidator.canonicalRelativePath(relativePath)
            .split(separator: "/").map(String.init)
        var cursor = PatchPathValidator.canonicalFileURL(containerRoot)
        for component in components {
            cursor.appendPathComponent(component, isDirectory: true)
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: cursor.path, isDirectory: &isDir) {
                if !isDir.boolValue {
                    try? fileManager.removeItem(at: cursor)
                    break
                }
            } else {
                break
            }
        }
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: target.path, isDirectory: &isDir), !isDir.boolValue {
            try? fileManager.removeItem(at: target)
        }
    }

    private static func directoryKeySort(_ lhs: String, _ rhs: String) -> Bool {
        let leftDepth = lhs.filter { $0 == "/" }.count
        let rightDepth = rhs.filter { $0 == "/" }.count
        return leftDepth == rightDepth ? lhs < rhs : leftDepth < rightDepth
    }

    /// Tự động tạo thư mục và ghi đè / thay thế tệp đích bằng cơ chế đa tầng
    private static func writeOrReplaceFile(
        _ data: Data,
        to target: URL,
        fileManager: FileManager
    ) throws {
        let parentDir = target.deletingLastPathComponent()

        // 1. Luôn tự động tạo các thư mục cha nếu chưa tồn tại
        if !fileManager.fileExists(atPath: parentDir.path) {
            try? fileManager.createDirectory(
                at: parentDir,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o777]
            )
        }

        // 2. Gỡ bỏ Data Protection và cấp quyền ghi cho thư mục cha và tệp đích
        try? fileManager.setAttributes([
            .protectionKey: FileProtectionType.none,
            .posixPermissions: 0o777
        ], ofItemAtPath: parentDir.path)

        if fileManager.fileExists(atPath: target.path) {
            try? fileManager.setAttributes([
                .protectionKey: FileProtectionType.none,
                .posixPermissions: 0o777
            ], ofItemAtPath: target.path)
            // Xóa tệp cũ trước để tránh xung đột POSIX rename / atomic lock
            try? fileManager.removeItem(at: target)
        }

        // 3. Cơ chế ghi tệp đa tầng (Multi-tier resilient file writer)

        // Tầng 1: Ghi trực tiếp non-atomic (Direct file write - tránh lỗi rename trên container)
        do {
            try data.write(to: target, options: [])
            if fileManager.fileExists(atPath: target.path) {
                try? fileManager.setAttributes([
                    .protectionKey: FileProtectionType.none,
                    .posixPermissions: 0o777
                ], ofItemAtPath: target.path)
                return
            }
        } catch {
            log("writeOrReplace: tầng 1 thất bại, thử tầng tiếp theo: \(error.localizedDescription)")
        }

        // Tầng 2: Tạo tệp qua FileManager createFile
        if fileManager.createFile(
            atPath: target.path,
            contents: data,
            attributes: [
                .posixPermissions: 0o777,
                .protectionKey: FileProtectionType.none
            ]
        ) {
            return
        }

        // Tầng 3: Atomic write tiêu chuẩn
        do {
            try data.write(to: target, options: .atomic)
            if fileManager.fileExists(atPath: target.path) {
                try? fileManager.setAttributes([
                    .protectionKey: FileProtectionType.none,
                    .posixPermissions: 0o777
                ], ofItemAtPath: target.path)
                return
            }
        } catch {
            log("writeOrReplace: tầng 3 thất bại, thử tầng POSIX Darwin: \(error.localizedDescription)")
        }

        // Tầng 4: Ghi tệp cấp thấp POSIX Darwin open/write/close
        let written = target.path.withCString { cPath -> Bool in
            let fd = Darwin.open(cPath, O_WRONLY | O_CREAT | O_TRUNC, 0o777)
            guard fd >= 0 else { return false }
            defer { Darwin.close(fd) }
            return data.withUnsafeBytes { rawBuffer -> Bool in
                guard let base = rawBuffer.baseAddress else { return false }
                var totalWritten = 0
                while totalWritten < data.count {
                    let count = Darwin.write(fd, base.advanced(by: totalWritten), data.count - totalWritten)
                    if count <= 0 { break }
                    totalWritten += count
                }
                return totalWritten == data.count
            }
        }

        if written && fileManager.fileExists(atPath: target.path) {
            try? fileManager.setAttributes([
                .protectionKey: FileProtectionType.none,
                .posixPermissions: 0o777
            ], ofItemAtPath: target.path)
            return
        }

        guard fileManager.fileExists(atPath: target.path) else {
            throw PatchPackageError.applyFailed
        }
    }

    private static func atomicCopy(
        _ source: URL,
        to target: URL,
        fileManager: FileManager
    ) throws {
        let parentDir = target.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            try? fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        if fileManager.fileExists(atPath: target.path) {
            try? fileManager.removeItem(at: target)
        }
        if (try? fileManager.copyItem(at: source, to: target)) == nil {
            if let data = try? Data(contentsOf: source) {
                try writeOrReplaceFile(data, to: target, fileManager: fileManager)
            }
        }
    }

    private static func writeJournal(_ journal: Journal, to url: URL) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try encoder.encode(journal).write(to: url, options: .atomic)
    }

    private static func readJournal(_ url: URL) throws -> Journal {
        try PropertyListDecoder().decode(Journal.self, from: Data(contentsOf: url))
    }

    private static func digest(_ data: Data) -> Data {
        Data(SHA256.hash(data: data))
    }

    private static func digestFile(_ url: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1_024 * 1_024), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        return Data(hasher.finalize())
    }

    private static func containerFingerprint(_ url: URL) -> Data {
        digest(Data(PatchPathValidator.canonicalFileURL(url).path.utf8))
    }
}
