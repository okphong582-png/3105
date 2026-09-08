import Foundation
import UIKit
import Combine

// MARK: - Clipboard & Conflict Models

enum ZTransferMode: String {
    case copy = "Sao chép"
    case cut = "Cắt"
}

struct ZClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let mode: ZTransferMode
}

enum ZConflictChoice {
    case overwrite
    case skip
    case autoRename
}

struct ZConflictPrompt: Identifiable {
    let id = UUID()
    let sourceURL: URL
    let destinationURL: URL
    let itemName: String
    let isDirectory: Bool
    let totalConflictsRemaining: Int
}

// MARK: - ZArchiver File Engine

@MainActor
final class ZArchiverFileEngine: ObservableObject {
    static let shared = ZArchiverFileEngine()

    @Published private(set) var clipboardItems: [ZClipboardItem] = []
    @Published var activeConflict: ZConflictPrompt?
    @Published var isOperating: Bool = false
    @Published var operationProgressText: String?
    @Published var operationMessage: String?
    @Published var isShowingMessage: Bool = false

    private var pendingTransfers: [(source: URL, destDir: URL, mode: ZTransferMode)] = []
    private var rememberChoice: ZConflictChoice?

    private init() {}

    var hasClipboard: Bool { !clipboardItems.isEmpty }
    var clipboardCount: Int { clipboardItems.count }
    var clipboardMode: ZTransferMode? { clipboardItems.first?.mode }

    // MARK: - Clipboard Actions

    func copy(urls: [URL]) {
        let items = urls.map { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return ZClipboardItem(url: url, name: url.lastPathComponent, isDirectory: isDir.boolValue, mode: .copy)
        }
        clipboardItems = items
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }

    func cut(urls: [URL]) {
        let items = urls.map { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return ZClipboardItem(url: url, name: url.lastPathComponent, isDirectory: isDir.boolValue, mode: .cut)
        }
        clipboardItems = items
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }

    func clearClipboard() {
        clipboardItems.removeAll()
    }

    // MARK: - Paste & Conflict Handling

    func paste(to destinationDirectory: URL, alwaysOverwrite: Bool = false) {
        guard !clipboardItems.isEmpty else { return }
        rememberChoice = alwaysOverwrite ? .overwrite : nil
        pendingTransfers = clipboardItems.map { ($0.url, destinationDirectory, $0.mode) }
        isOperating = true
        processNextTransfer()
    }

    private func processNextTransfer() {
        guard !pendingTransfers.isEmpty else {
            isOperating = false
            operationProgressText = nil
            // Clear cut items if complete
            if clipboardMode == .cut {
                clearClipboard()
            }
            return
        }

        let current = pendingTransfers.removeFirst()
        let fm = FileManager.default
        let targetURL = current.destDir.appendingPathComponent(current.source.lastPathComponent)

        // Kiểm tra xung đột tệp
        if fm.fileExists(atPath: targetURL.path) {
            if let choice = rememberChoice {
                executeTransfer(source: current.source, dest: targetURL, choice: choice, mode: current.mode)
                processNextTransfer()
            } else {
                var isDir: ObjCBool = false
                fm.fileExists(atPath: targetURL.path, isDirectory: &isDir)
                activeConflict = ZConflictPrompt(
                    sourceURL: current.source,
                    destinationURL: targetURL,
                    itemName: targetURL.lastPathComponent,
                    isDirectory: isDir.boolValue,
                    totalConflictsRemaining: pendingTransfers.count + 1
                )
                // Lưu lại tác vụ đang chờ xử lý
                pendingTransfers.insert(current, at: 0)
            }
            return
        }

        // Không xung đột, thực hiện trực tiếp
        executeTransfer(source: current.source, dest: targetURL, choice: .overwrite, mode: current.mode)
        processNextTransfer()
    }

    func resolveConflict(choice: ZConflictChoice, applyToAll: Bool) {
        if applyToAll {
            rememberChoice = choice
        }
        guard let current = pendingTransfers.first else {
            activeConflict = nil
            return
        }
        _ = pendingTransfers.removeFirst()
        activeConflict = nil

        let targetURL = current.destDir.appendingPathComponent(current.source.lastPathComponent)
        executeTransfer(source: current.source, dest: targetURL, choice: choice, mode: current.mode)
        processNextTransfer()
    }

    func cancelTransfer() {
        pendingTransfers.removeAll()
        activeConflict = nil
        isOperating = false
        operationProgressText = nil
    }

    private func executeTransfer(source: URL, dest: URL, choice: ZConflictChoice, mode: ZTransferMode) {
        let fm = FileManager.default
        var finalDest = dest

        switch choice {
        case .skip:
            return
        case .overwrite:
            if fm.fileExists(atPath: dest.path) {
                try? fm.removeItem(at: dest)
            }
        case .autoRename:
            finalDest = generateUniqueURL(for: dest)
        }

        do {
            if mode == .cut {
                try fm.moveItem(at: source, to: finalDest)
            } else {
                try recursiveCopy(from: source, to: finalDest)
            }
        } catch {
            log("ZArchiverFileEngine: lỗi chuyển tệp: \(error.localizedDescription)")
            showMessage("Lỗi: \(error.localizedDescription)")
        }
    }

    private func recursiveCopy(from src: URL, to dest: URL) throws {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: src.path, isDirectory: &isDir), isDir.boolValue {
            try fm.createDirectory(at: dest, withIntermediateDirectories: true)
            let contents = try fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)
            for child in contents {
                let childDest = dest.appendingPathComponent(child.lastPathComponent)
                try recursiveCopy(from: child, to: childDest)
            }
        } else {
            try fm.copyItem(at: src, to: dest)
        }
    }

    private func generateUniqueURL(for url: URL) -> URL {
        let dir = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let fm = FileManager.default

        var counter = 1
        while true {
            let newName = ext.isEmpty ? "\(name) (\(counter))" : "\(name) (\(counter)).\(ext)"
            let candidate = dir.appendingPathComponent(newName)
            if !fm.fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }

    // MARK: - Archive Operations

    func extractArchive(at archiveURL: URL, into destDir: URL, autoFolder: Bool = false, completion: @escaping (Bool) -> Void) {
        isOperating = true
        operationProgressText = "Đang giải nén \(archiveURL.lastPathComponent)..."

        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let targetDir: URL
            if autoFolder {
                let folderName = archiveURL.deletingPathExtension().lastPathComponent
                targetDir = destDir.appendingPathComponent(folderName)
                try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
            } else {
                targetDir = destDir
            }

            do {
                _ = try ZIPArchiveExtractor.extract(archiveURL: archiveURL, into: targetDir)
                DispatchQueue.main.async {
                    self.isOperating = false
                    self.operationProgressText = nil
                    self.showMessage("Giải nén thành công vào \(targetDir.lastPathComponent)")
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isOperating = false
                    self.operationProgressText = nil
                    self.showMessage("Giải nén thất bại: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }

    func createZIPArchive(sources: [URL], in destDir: URL, archiveName: String, completion: @escaping (Bool) -> Void) {
        isOperating = true
        operationProgressText = "Đang nén thành tệp ZIP..."

        var finalName = archiveName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalName.lowercased().hasSuffix(".zip") {
            finalName += ".zip"
        }
        let destZipURL = destDir.appendingPathComponent(finalName)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                _ = try ZIPArchiveWriter.write(items: sources, to: destZipURL)
                DispatchQueue.main.async {
                    self.isOperating = false
                    self.operationProgressText = nil
                    self.showMessage("Tạo tệp nén thành công: \(finalName)")
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isOperating = false
                    self.operationProgressText = nil
                    self.showMessage("Nén thất bại: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }

    // MARK: - File & Folder Management

    func createFolder(named name: String, in directory: URL) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let target = directory.appendingPathComponent(trimmed)
        do {
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            return true
        } catch {
            showMessage("Không thể tạo thư mục: \(error.localizedDescription)")
            return false
        }
    }

    func createTextFile(named name: String, in directory: URL, content: String = "") -> Bool {
        var trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if !trimmed.contains(".") { trimmed += ".txt" }
        let target = directory.appendingPathComponent(trimmed)
        do {
            try content.write(to: target, atomically: true, encoding: .utf8)
            return true
        } catch {
            showMessage("Không thể tạo tệp: \(error.localizedDescription)")
            return false
        }
    }

    func renameItem(at url: URL, newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != url.lastPathComponent else { return false }
        let dest = url.deletingLastPathComponent().appendingPathComponent(trimmed)
        do {
            try FileManager.default.moveItem(at: url, to: dest)
            return true
        } catch {
            showMessage("Đổi tên thất bại: \(error.localizedDescription)")
            return false
        }
    }

    func deleteItems(at urls: [URL]) {
        let fm = FileManager.default
        for url in urls {
            try? fm.removeItem(at: url)
        }
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
    }

    func showMessage(_ text: String) {
        operationMessage = text
        isShowingMessage = true
    }
}
