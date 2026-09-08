import SwiftUI
import UIKit

// MARK: - ZArchiver Color Tokens
enum ZArchiverColor {
    static let primaryGreen = Color(red: 0.18, green: 0.49, blue: 0.20)      // #2E7D32
    static let headerGreen = Color(red: 0.11, green: 0.37, blue: 0.13)       // #1B5E20
    static let vibrantGreen = Color(red: 0.30, green: 0.69, blue: 0.31)      // #4CAF50
    static let lightGreen = Color(red: 0.40, green: 0.78, blue: 0.41)        // #66BB6A
    static let accentMint = Color(red: 0.00, green: 0.78, blue: 0.55)        // #00C853
    static let darkBackground = Color(red: 0.08, green: 0.08, blue: 0.09)    // #141417
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.14)           // #1F1F24
    static let surfaceSecondary = Color(red: 0.16, green: 0.16, blue: 0.19)  // #292930
    static let border = Color(red: 0.22, green: 0.22, blue: 0.25)            // #383840
    static let folderAmber = Color(red: 1.00, green: 0.65, blue: 0.00)       // #FFA000
    static let archiveGreen = Color(red: 0.26, green: 0.63, blue: 0.28)      // #43A047
    static let imagePurple = Color(red: 0.67, green: 0.28, blue: 0.74)       // #AB47BC
    static let codeBlue = Color(red: 0.26, green: 0.65, blue: 0.96)          // #42A5F5
    static let audioOrange = Color(red: 1.00, green: 0.44, blue: 0.26)       // #FF7043
    static let videoRed = Color(red: 0.94, green: 0.33, blue: 0.31)          // #EF5350
    static let configYellow = Color(red: 0.95, green: 0.77, blue: 0.06)      // #FBC02D
    static let textSecondary = Color(white: 0.65)
}

// MARK: - File Category & Icon Resolver
enum ZArchiverFileType {
    case folder
    case archive
    case image
    case audio
    case video
    case text
    case code
    case config
    case binary
    case appContainer

    var systemIcon: String {
        switch self {
        case .folder: return "folder.fill"
        case .archive: return "doc.zipper"
        case .image: return "photo.fill"
        case .audio: return "music.note"
        case .video: return "film.fill"
        case .text: return "doc.text.fill"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .config: return "gearshape.fill"
        case .binary: return "doc.fill"
        case .appContainer: return "app.badge.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .folder: return ZArchiverColor.folderAmber
        case .archive: return ZArchiverColor.archiveGreen
        case .image: return ZArchiverColor.imagePurple
        case .audio: return ZArchiverColor.audioOrange
        case .video: return ZArchiverColor.videoRed
        case .text: return ZArchiverColor.codeBlue
        case .code: return ZArchiverColor.accentMint
        case .config: return ZArchiverColor.configYellow
        case .binary: return Color.gray
        case .appContainer: return ZArchiverColor.vibrantGreen
        }
    }

    static func resolve(name: String, isDirectory: Bool) -> ZArchiverFileType {
        if isDirectory {
            if name.hasSuffix(".app") { return .appContainer }
            return .folder
        }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "zip", "7z", "rar", "tar", "gz", "bz2", "xz", "iso", "ipa", "apk", "z", "lzma":
            return .archive
        case "png", "jpg", "jpeg", "webp", "gif", "bmp", "heic", "tiff", "svg", "ico":
            return .image
        case "mp3", "wav", "m4a", "flac", "aac", "ogg", "wma":
            return .audio
        case "mp4", "mov", "m4v", "avi", "mkv", "webm", "flv":
            return .video
        case "txt", "md", "rtf", "strings", "log", "readme", "csv":
            return .text
        case "json", "plist", "xml", "html", "htm", "css", "js", "ts", "py", "sh", "swift", "c", "h", "cpp", "m", "mm":
            return .code
        case "cfg", "ini", "conf", "yaml", "yml", "properties", "dat", "bin", "dylib":
            return .config
        default:
            return .binary
        }
    }
}

// MARK: - Formatters
enum ZArchiverFormatters {
    static func fileSizeString(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}
