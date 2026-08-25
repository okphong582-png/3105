import Foundation
import SwiftUI
import Combine

// MARK: - Mod Feature State Manager
@MainActor
final class ModFeatureManager: ObservableObject {
    static let shared = ModFeatureManager()

    private let aimStorageKey = "oni_akuma_aim_enabled_v3"
    private let holoStorageKey = "oni_akuma_holo_enabled_v3"
    private let targetBundleKey = "oni_akuma_target_game_bundle_v3"

    @Published var isAimEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isAimEnabled, forKey: aimStorageKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isHoloEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHoloEnabled, forKey: holoStorageKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var selectedBundle: String {
        didSet {
            UserDefaults.standard.set(selectedBundle, forKey: targetBundleKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isProcessingAim: Bool = false
    @Published var isProcessingHolo: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false

    private init() {
        self.isAimEnabled = UserDefaults.standard.bool(forKey: aimStorageKey)
        self.isHoloEnabled = UserDefaults.standard.bool(forKey: holoStorageKey)
        self.selectedBundle = UserDefaults.standard.string(forKey: targetBundleKey) ?? "com.dts.freefireth"
    }

    var gameShortName: String {
        selectedBundle == "com.dts.freefiremax" ? "FF MAX" : "Free Fire"
    }

    func toggleAim(store: PatchProjectStore) {
        guard !isProcessingAim else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isAimEnabled {
            restoreFeature(isAim: true, store: store)
        } else {
            injectFeature(isAim: true, store: store)
        }
    }

    func toggleHolo(store: PatchProjectStore) {
        guard !isProcessingHolo else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isHoloEnabled {
            restoreFeature(isAim: false, store: store)
        } else {
            injectFeature(isAim: false, store: store)
        }
    }

    private func injectFeature(isAim: Bool, store: PatchProjectStore) {
        let featureName = isAim ? "Aim Body" : "Định Vị Holo"
        let project = isAim
            ? (store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("Aim") })?.project ?? store.items.first?.project)
            : (store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("HOLO") })?.project ?? store.items.last?.project)

        guard let proj = project else {
            triggerToast("Không tìm thấy file gói mod \(featureName)!")
            return
        }

        if isAim { isProcessingAim = true } else { isProcessingHolo = true }
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }

        Task.detached(priority: .userInitiated) {
            do {
                _ = try DevicePatchService.apply(project: adapted)
                await MainActor.run {
                    if isAim {
                        ModFeatureManager.shared.isProcessingAim = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            ModFeatureManager.shared.isAimEnabled = true
                        }
                    } else {
                        ModFeatureManager.shared.isProcessingHolo = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            ModFeatureManager.shared.isHoloEnabled = true
                        }
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã bật \(featureName) trên \(targetName)!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    if isAim {
                        ModFeatureManager.shared.isProcessingAim = false
                    } else {
                        ModFeatureManager.shared.isProcessingHolo = false
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    if isAim {
                        ModFeatureManager.shared.isProcessingAim = false
                    } else {
                        ModFeatureManager.shared.isProcessingHolo = false
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Lỗi khi bật: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreFeature(isAim: Bool, store: PatchProjectStore) {
        let featureName = isAim ? "Aim Body" : "Định Vị Holo"
        let project = isAim
            ? (store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("Aim") })?.project ?? store.items.first?.project)
            : (store.items.first(where: { $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains("HOLO") })?.project ?? store.items.last?.project)

        let receipt = project.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        if isAim { isProcessingAim = true } else { isProcessingHolo = true }

        Task.detached(priority: .userInitiated) {
            if let receipt {
                do {
                    try DevicePatchService.restore(receipt: receipt)
                } catch {
                    log("restore error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                if isAim {
                    ModFeatureManager.shared.isProcessingAim = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isAimEnabled = false
                    }
                } else {
                    ModFeatureManager.shared.isProcessingHolo = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isHoloEnabled = false
                    }
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt \(featureName)!")
            }
        }
    }

    func triggerToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.showToast = false
            }
        }
    }
}
