import Foundation

enum MenuFileCleanup {
    static let filenames = [
        "Assembly-CSharp-patch.bytes",
        "localConfig.json",
        "config.bin",
        "beetalk_session.db",
        "game_sound_config",
        "ShaderStripSettings"
    ]

    static func removeFiles(in documentsURL: URL, fileManager: FileManager = .default) throws {
        let attributes = try fileManager.attributesOfItem(atPath: documentsURL.path)
        guard documentsURL.lastPathComponent == "Documents",
              attributes[.type] as? FileAttributeType == .typeDirectory else {
            throw failure("Thư mục Documents không hợp lệ.")
        }
        let root = documentsURL.standardizedFileURL.resolvingSymlinksInPath()
        var targets: [URL] = []
        // Validate every target first. Never recursively remove a directory or follow a symlink.
        for name in filenames {
            let target = root.appendingPathComponent(name)
            let info: [FileAttributeKey: Any]
            do {
                info = try fileManager.attributesOfItem(atPath: target.path)
            } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
                [CocoaError.fileNoSuchFile.rawValue, CocoaError.fileReadNoSuchFile.rawValue].contains(error.code) {
                continue
            }
            guard info[.type] as? FileAttributeType == .typeRegular,
                  target.resolvingSymlinksInPath().deletingLastPathComponent().path == root.path else {
                throw failure("Không thể xóa \(name): đường dẫn không phải file thông thường.")
            }
            targets.append(target)
        }
        for target in targets {
            do {
                try fileManager.removeItem(at: target)
            } catch {
                throw failure("Không xóa được \(target.lastPathComponent): \(error.localizedDescription)")
            }
        }
        guard !targets.contains(where: { fileManager.fileExists(atPath: $0.path) }) else {
            throw failure("Một số file vẫn còn tồn tại. Hãy đóng game và thử tắt Menu lại.")
        }
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "Mizze.MenuCleanup", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
