import Foundation
import UIKit

/// Helper for presenting native iOS Share Sheet (UIActivityViewController)
/// to allow sharing and "Lưu vào Tệp" (Save to Files) for files and directories.
enum FileShareHelper {
    /// Share a FileEntry directly to iOS Share Sheet
    static func share(entry: FileEntry, from sourceView: UIView? = nil) {
        let url = URL(fileURLWithPath: entry.path)
        share(url: url, isDirectory: entry.isDirectory, defaultName: entry.name, from: sourceView)
    }

    /// Share any file or directory URL to iOS Share Sheet
    static func share(url: URL, isDirectory: Bool, defaultName: String, from sourceView: UIView? = nil) {
        // Dispatch after context menu dismiss completes to prevent presentation collisions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
                  let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                return
            }

            var topController = rootVC
            while let presented = topController.presentedViewController {
                topController = presented
            }

            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

            if isDirectory {
                // For directories, package into a temporary ZIP archive so iOS Share Sheet / Save to Files can handle it
                let cleanName = defaultName.replacingOccurrences(of: "/", with: "_")
                let zipName = cleanName.hasSuffix(".zip") ? cleanName : "\(cleanName).zip"
                let targetZipURL = tempDir.appendingPathComponent(zipName)

                try? FileManager.default.removeItem(at: targetZipURL)
                FileManager.default.createFile(atPath: targetZipURL.path, contents: nil)

                do {
                    _ = try ZIPArchiveWriter.write(items: [url], to: targetZipURL)
                    presentActivityController(items: [targetZipURL], from: topController, sourceView: sourceView)
                } catch {
                    // Fallback to sharing the folder URL directly
                    presentActivityController(items: [url], from: topController, sourceView: sourceView)
                }
            } else {
                // For single files, copy to temp directory to guarantee sandbox access
                let cleanName = defaultName.replacingOccurrences(of: "/", with: "_")
                let targetFileURL = tempDir.appendingPathComponent(cleanName)

                try? FileManager.default.removeItem(at: targetFileURL)

                do {
                    try FileManager.default.copyItem(at: url, to: targetFileURL)
                    presentActivityController(items: [targetFileURL], from: topController, sourceView: sourceView)
                } catch {
                    // Fallback to sharing original file URL
                    presentActivityController(items: [url], from: topController, sourceView: sourceView)
                }
            }
        }
    }

    private static func presentActivityController(items: [Any], from controller: UIViewController, sourceView: UIView?) {
        let avc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = avc.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                popover.sourceView = controller.view
                popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        controller.present(avc, animated: true)
    }
}
