import Foundation
import SwiftUI
import Combine

// MARK: - Aim Mod Types
enum AimModType: String, CaseIterable, Identifiable {
    case drag = "drag"
    case chest = "chest"
    case magic = "magic"
    case neck = "neck"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .drag: return "AIM DRAG (CÂN TÂM)"
        case .chest: return "AIM CHEST (KHÓA NGỰC)"
        case .magic: return "AIM MAGIC (MA THUẬT)"
        case .neck: return "AIM NECK (KHÓA CỔ)"
        }
    }

    var subtitle: String {
        switch self {
        case .drag: return "Kéo tâm mượt mà, check tâm chuẩn xác"
        case .chest: return "Tự động ghim tâm vào thân và ngực đối thủ"
        case .magic: return "Bắn trên cao hoặc chệch góc vẫn trúng đích"
        case .neck: return "Ghim tâm vùng cổ cận đầu, tỷ lệ headshot cực cao"
        }
    }

    var filename: String {
        switch self {
        case .drag: return "Aim Drag.3105"
        case .chest: return "Aim Chest.3105"
        case .magic: return "Aim Magic.3105"
        case .neck: return "Aim Neck.3105"
        }
    }

    var icon: String {
        switch self {
        case .drag: return "scope"
        case .chest: return "shield.lefthalf.filled"
        case .magic: return "wand.and.stars"
        case .neck: return "flame.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .drag: return Color(red: 0.0, green: 0.85, blue: 1.0) // Cyan Neon
        case .chest: return Color(red: 1.0, green: 0.6, blue: 0.1) // Warm Orange
        case .magic: return Color(red: 0.75, green: 0.35, blue: 1.0) // Magic Purple
        case .neck: return Color(red: 1.0, green: 0.25, blue: 0.35) // Crimson Red
        }
    }
}

// MARK: - Mod Feature State Manager
@MainActor
final class ModFeatureManager: ObservableObject {
    static let shared = ModFeatureManager()

    private let enabledAimModsKey = "oni_akuma_enabled_aim_mods_v4"
    private let targetBundleKey = "oni_akuma_target_game_bundle_v4"

    @Published var enabledAimMods: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(enabledAimMods), forKey: enabledAimModsKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var selectedBundle: String {
        didSet {
            UserDefaults.standard.set(selectedBundle, forKey: targetBundleKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var processingAimMods: Set<String> = []
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false

    private init() {
        let savedAimMods = UserDefaults.standard.stringArray(forKey: enabledAimModsKey) ?? []
        self.enabledAimMods = Set(savedAimMods)
        self.selectedBundle = UserDefaults.standard.string(forKey: targetBundleKey) ?? "com.dts.freefireth"
    }

    var gameShortName: String {
        selectedBundle == "com.dts.freefiremax" ? "FF MAX" : "Free Fire"
    }

    func isAimModEnabled(_ type: AimModType) -> Bool {
        enabledAimMods.contains(type.rawValue)
    }

    func isAimModProcessing(_ type: AimModType) -> Bool {
        processingAimMods.contains(type.rawValue)
    }

    // MARK: - Toggle Aim Mod
    func toggleAimMod(_ type: AimModType, store: PatchProjectStore) {
        guard !processingAimMods.contains(type.rawValue) else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isAimModEnabled(type) {
            restoreAimMod(type, store: store)
        } else {
            injectAimMod(type, store: store)
        }
    }

    private func injectAimMod(_ type: AimModType, store: PatchProjectStore) {
        let featureName = type.title
        let typeKey = type.rawValue

        let targetItem = store.items.first(where: {
            $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains(type.rawValue) ||
            $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains(type.filename)
        })

        guard let item = targetItem else {
            triggerToast("Không tìm thấy file \(type.filename)!")
            return
        }

        if item.isLocked {
            store.requestUnlock(for: item)
            triggerToast("Gói \(type.filename) yêu cầu nhập mật khẩu!")
            return
        }

        guard let proj = item.project else {
            triggerToast("Không tìm thấy dữ liệu cấu hình \(type.filename)!")
            return
        }

        processingAimMods.insert(typeKey)
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.processingAimMods.remove(typeKey)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.enabledAimMods.insert(typeKey)
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã bật \(type.filename) trên \(targetName)!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    ModFeatureManager.shared.processingAimMods.remove(typeKey)
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.processingAimMods.remove(typeKey)
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Lỗi khi bật: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreAimMod(_ type: AimModType, store: PatchProjectStore) {
        let typeKey = type.rawValue
        let targetItem = store.items.first(where: {
            $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains(type.rawValue) ||
            $0.packageURL.lastPathComponent.localizedCaseInsensitiveContains(type.filename)
        })

        let receiptToRestore = targetItem?.project.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        processingAimMods.insert(typeKey)

        Task.detached(priority: .userInitiated) {
            if let receiptToRestore {
                do {
                    try DevicePatchService.restore(receipt: receiptToRestore)
                } catch {
                    log("restore aim mod error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                ModFeatureManager.shared.processingAimMods.remove(typeKey)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.enabledAimMods.remove(typeKey)
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt \(type.filename)!")
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
