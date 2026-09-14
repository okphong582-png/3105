import Foundation
import SwiftUI
import Combine

// MARK: - Aim Mod Types (5 Chế Độ Aim)
enum AimModType: String, CaseIterable, Identifiable {
    case body = "body"
    case drag = "drag"
    case chest = "chest"
    case magic = "magic"
    case neck = "neck"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .body: return "AIM BODY (KHÓA THÂN)"
        case .drag: return "AIM DRAG (CÂN TÂM)"
        case .chest: return "AIM CHEST (KHÓA NGỰC)"
        case .magic: return "AIM MAGIC (MA THUẬT)"
        case .neck: return "AIM NECK (KHÓA CỔ)"
        }
    }

    var subtitle: String {
        switch self {
        case .body: return "Tự động ghim tâm chính xác vào thân đối thủ"
        case .drag: return "Kéo tâm mượt mà, check tâm chuẩn xác"
        case .chest: return "Tự động ghim tâm vào ngực và thân trên đối thủ"
        case .magic: return "Bắn trên cao hoặc chệch góc vẫn trúng đích"
        case .neck: return "Ghim tâm vùng cổ cận đầu, tỷ lệ headshot cực cao"
        }
    }

    var shortTitle: String {
        switch self {
        case .body: return "Aim Body"
        case .drag: return "Aim Drag"
        case .chest: return "Aim Chest"
        case .magic: return "Aim Magic"
        case .neck: return "Aim Neck"
        }
    }

    var vaultTag: StealthPatchVault.ResourceTag {
        switch self {
        case .body: return .aimBody
        case .drag: return .aimDrag
        case .chest: return .aimChest
        case .magic: return .aimMagic
        case .neck: return .aimNeck
        }
    }

    var icon: String {
        switch self {
        case .body: return "figure.stand"
        case .drag: return "scope"
        case .chest: return "shield.lefthalf.filled"
        case .magic: return "wand.and.stars"
        case .neck: return "flame.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .body: return Color(red: 0.2, green: 0.85, blue: 0.55) // Emerald Neon
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

    private let enabledAimModsKey = "oni_akuma_enabled_aim_mods_v5"
    private let modSkinKey = "oni_akuma_modskin_enabled_v5"
    private let modOutfitKey = "oni_akuma_modoutfit_enabled_v5"
    private let locatorKey = "oni_akuma_locator_enabled_v6"
    private let espKey = "oni_akuma_esp_hih_enabled_v6"
    private let targetBundleKey = "oni_akuma_target_game_bundle_v5"

    @Published var enabledAimMods: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(enabledAimMods), forKey: enabledAimModsKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isModSkinEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isModSkinEnabled, forKey: modSkinKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isModOutfitEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isModOutfitEnabled, forKey: modOutfitKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isLocatorEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLocatorEnabled, forKey: locatorKey)
            UserDefaults.standard.synchronize()
        }
    }

    @Published var isESPEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isESPEnabled, forKey: espKey)
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
    @Published var isProcessingModSkin: Bool = false
    @Published var isProcessingModOutfit: Bool = false
    @Published var isProcessingLocator: Bool = false
    @Published var isProcessingESP: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false

    private init() {
        let savedAimMods = UserDefaults.standard.stringArray(forKey: enabledAimModsKey) ?? []
        self.enabledAimMods = Set(savedAimMods)
        self.isModSkinEnabled = UserDefaults.standard.bool(forKey: modSkinKey)
        self.isModOutfitEnabled = UserDefaults.standard.bool(forKey: modOutfitKey)
        self.isLocatorEnabled = UserDefaults.standard.bool(forKey: locatorKey)
        self.isESPEnabled = UserDefaults.standard.bool(forKey: espKey)
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

    // MARK: - Package Resolver Helper
    private func findItem(forFilename filename: String, altKey: String? = nil, store: PatchProjectStore) -> PatchLibraryItem? {
        let cleanName = filename.lowercased()
        let cleanAlt = altKey?.lowercased()

        // 1. Search in store items
        if let found = store.items.first(where: {
            let itemFilename = $0.packageURL.lastPathComponent.lowercased()
            let projName = ($0.project?.name ?? "").lowercased()
            if itemFilename == cleanName || itemFilename.contains(cleanName) { return true }
            if let alt = cleanAlt, !alt.isEmpty {
                if itemFilename.contains(alt) || projName.contains(alt) { return true }
            }
            return false
        }) {
            return found
        }

        // 2. Direct lookup from PatchProjectLibrary (checks Root and Bundle directly)
        if let direct = PatchProjectLibrary.loadItem(forFilename: filename) {
            return direct
        }
        if let alt = altKey, let directAlt = PatchProjectLibrary.loadItem(forFilename: alt) {
            return directAlt
        }

        // 3. Trigger reload and check one last time
        store.reload()
        return store.items.first(where: {
            let itemFilename = $0.packageURL.lastPathComponent.lowercased()
            return itemFilename.contains(cleanName) || (cleanAlt != nil && itemFilename.contains(cleanAlt!))
        })
    }

    // MARK: - Toggle Aim Mod (5 Chế Độ)
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
        let typeKey = type.rawValue

        guard let proj = StealthPatchVault.loadProject(for: type.vaultTag) else {
            triggerToast("Không thể tải cấu hình \(type.shortTitle)!")
            return
        }

        processingAimMods.insert(typeKey)
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        adapted.bundleIdentifiers = [currentBundle]
        for i in 0..<adapted.directories.count {
            adapted.directories[i].bundleID = currentBundle
        }
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            // Loading nhanh siêu mượt (0.35s) mang lại cảm giác phản hồi công nghệ cao
            try? await Task.sleep(nanoseconds: 350_000_000)
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.processingAimMods.remove(typeKey)
                    _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.enabledAimMods.insert(typeKey)
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã bật \(type.shortTitle) trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.processingAimMods.remove(typeKey)
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Không thể bật \(type.shortTitle). Vui lòng mở game Free Fire ít nhất một lần!")
                }
            }
        }
    }

    private func restoreAimMod(_ type: AimModType, store: PatchProjectStore) {
        let typeKey = type.rawValue
        let proj = StealthPatchVault.loadProject(for: type.vaultTag)
        let receiptToRestore = proj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        processingAimMods.insert(typeKey)

        Task.detached(priority: .userInitiated) {
            // Loading nhanh siêu mượt (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let receiptToRestore {
                do {
                    try DevicePatchService.restore(receipt: receiptToRestore)
                } catch {
                    log("restore aim mod error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                ModFeatureManager.shared.processingAimMods.remove(typeKey)
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.enabledAimMods.remove(typeKey)
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt \(type.shortTitle)!")
            }
        }
    }

    // MARK: - Toggle Mod Skin (MP40 Mãng Xà)
    func toggleModSkin(store: PatchProjectStore) {
        guard !isProcessingModSkin else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isModSkinEnabled {
            restoreModSkin(store: store)
        } else {
            injectModSkin(store: store)
        }
    }

    private func injectModSkin(store: PatchProjectStore) {
        guard let proj = StealthPatchVault.loadProject(for: .modSkin) else {
            triggerToast("Không tìm thấy cấu hình Mod Skin!")
            return
        }

        isProcessingModSkin = true
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        adapted.bundleIdentifiers = [currentBundle]
        for i in 0..<adapted.directories.count {
            adapted.directories[i].bundleID = currentBundle
        }
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            // Loading nhanh mượt mà (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModSkin = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isModSkinEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Mod Skin MP40 Mãng Xà trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModSkin = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Không thể kích hoạt Mod Skin MP40. Vui lòng mở game Free Fire ít nhất một lần!")
                }
            }
        }
    }

    private func restoreModSkin(store: PatchProjectStore) {
        let proj = StealthPatchVault.loadProject(for: .modSkin)
        let receiptToRestore = proj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingModSkin = true

        Task.detached(priority: .userInitiated) {
            // Loading nhanh mượt mà (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let receiptToRestore {
                do {
                    try DevicePatchService.restore(receipt: receiptToRestore)
                } catch {
                    log("restore mod skin error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                ModFeatureManager.shared.isProcessingModSkin = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.isModSkinEnabled = false
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt Mod Skin!")
            }
        }
    }

    // MARK: - Toggle Mod Đồ (Chỉ sử dụng nhân vật Ignis)
    func toggleModOutfit(store: PatchProjectStore) {
        guard !isProcessingModOutfit else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isModOutfitEnabled {
            restoreModOutfit(store: store)
        } else {
            injectModOutfit(store: store)
        }
    }

    private func injectModOutfit(store: PatchProjectStore) {
        guard let proj = StealthPatchVault.loadProject(for: .modOutfit) else {
            triggerToast("Không tìm thấy cấu hình Trang Phục Ignis!")
            return
        }

        isProcessingModOutfit = true
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        adapted.bundleIdentifiers = [currentBundle]
        for i in 0..<adapted.directories.count {
            adapted.directories[i].bundleID = currentBundle
        }
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            // Loading nhanh mượt mà (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModOutfit = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isModOutfitEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Trang Phục Ignis trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModOutfit = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Không thể kích hoạt Trang Phục Ignis. Vui lòng mở game Free Fire ít nhất một lần!")
                }
            }
        }
    }

    private func restoreModOutfit(store: PatchProjectStore) {
        let proj = StealthPatchVault.loadProject(for: .modOutfit)
        let receiptToRestore = proj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingModOutfit = true

        Task.detached(priority: .userInitiated) {
            // Loading nhanh mượt mà (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let receiptToRestore {
                do {
                    try DevicePatchService.restore(receipt: receiptToRestore)
                } catch {
                    log("restore mod outfit error: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                ModFeatureManager.shared.isProcessingModOutfit = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.isModOutfitEnabled = false
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt Trang Phục Ignis!")
            }
        }
    }

    // MARK: - Toggle Định Vị (Radar Định Vị Chấm Trắng)
    func toggleLocator(store: PatchProjectStore) {
        guard !isProcessingLocator else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isLocatorEnabled {
            restoreLocator(store: store)
        } else {
            injectLocator(store: store)
        }
    }

    private func injectLocator(store: PatchProjectStore) {
        guard let proj = StealthPatchVault.loadProject(for: .locator) else {
            triggerToast("Gói Định Vị chưa sẵn sàng!")
            return
        }

        isProcessingLocator = true
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        adapted.bundleIdentifiers = [currentBundle]
        for i in 0..<adapted.directories.count {
            adapted.directories[i].bundleID = currentBundle
        }
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            // Loading nhanh siêu mượt (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingLocator = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isLocatorEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Định Vị Chấm Trắng trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingLocator = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Không thể bật Định Vị Chấm Trắng. Vui lòng mở game Free Fire ít nhất một lần!")
                }
            }
        }
    }

    private func restoreLocator(store: PatchProjectStore) {
        let proj = StealthPatchVault.loadProject(for: .locator)
        let receiptToRestore = proj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingLocator = true

        Task.detached(priority: .userInitiated) {
            // Loading nhanh siêu mượt (0.35s)
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let receiptToRestore {
                try? DevicePatchService.restore(receipt: receiptToRestore)
            }

            await MainActor.run {
                ModFeatureManager.shared.isProcessingLocator = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.isLocatorEnabled = false
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt Định Vị!")
            }
        }
    }

    // MARK: - Toggle ESP Xuyên Tường (File Hih.3105)
    func toggleESP(store: PatchProjectStore) {
        guard !isProcessingESP else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isESPEnabled {
            restoreESP(store: store)
        } else {
            injectESP(store: store)
        }
    }

    private func injectESP(store: PatchProjectStore) {
        guard let proj = StealthPatchVault.loadProject(for: .esp) ?? loadDirectHihProject(store: store) else {
            triggerToast("Gói Định Vị ESP chưa sẵn sàng!")
            return
        }

        isProcessingESP = true
        let currentBundle = selectedBundle
        let targetName = gameShortName

        var adapted = proj
        adapted.bundleIdentifiers = [currentBundle]
        for i in 0..<adapted.directories.count {
            adapted.directories[i].bundleID = currentBundle
        }
        for i in 0..<adapted.rules.count {
            adapted.rules[i].bundleID = currentBundle
            if currentBundle == "com.dts.freefiremax" {
                if adapted.rules[i].relativePath.contains("com.dts.freefireth.plist") {
                    adapted.rules[i].relativePath = adapted.rules[i].relativePath.replacingOccurrences(of: "com.dts.freefireth", with: "com.dts.freefiremax")
                    adapted.rules[i].replacementFilename = "com.dts.freefiremax.plist"
                }
            }
        }
        let projectToApply = adapted

        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 350_000_000)
            do {
                _ = try DevicePatchService.apply(project: projectToApply)
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingESP = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isESPEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Định Vị ESP trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingESP = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Không thể bật Định Vị ESP. Vui lòng mở game Free Fire ít nhất một lần!")
                }
            }
        }
    }

    private func restoreESP(store: PatchProjectStore) {
        let proj = StealthPatchVault.loadProject(for: .esp) ?? loadDirectHihProject(store: store)
        let receiptToRestore = proj.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingESP = true

        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if let receiptToRestore {
                try? DevicePatchService.restore(receipt: receiptToRestore)
            }

            await MainActor.run {
                ModFeatureManager.shared.isProcessingESP = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.isESPEnabled = false
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt Định Vị ESP!")
            }
        }
    }

    private func loadDirectHihProject(store: PatchProjectStore) -> PatchProject? {
        if let item = findItem(forFilename: "Hih.3105", altKey: "hih", store: store), let p = item.project {
            return p
        }
        if let item = findItem(forFilename: "Hih", altKey: "hih.3105", store: store), let p = item.project {
            return p
        }
        if let url = Bundle.main.url(forResource: "Hih", withExtension: "3105") ??
                     Bundle.main.url(forResource: "hih", withExtension: "3105"),
           let data = try? Data(contentsOf: url),
           let decoded = try? PatchPackageCodec.decode(data, password: nil) {
            return decoded.project
        }
        return nil
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
