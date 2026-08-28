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

    var filename: String {
        switch self {
        case .body: return "Aim Body.3105"
        case .drag: return "Aim Drag.3105"
        case .chest: return "Aim Chest.3105"
        case .magic: return "Aim Magic.3105"
        case .neck: return "Aim Neck.3105"
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
    private let redLocatorKey = "oni_akuma_redlocator_enabled_v5"
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

    @Published var isRedLocatorEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRedLocatorEnabled, forKey: redLocatorKey)
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
    @Published var isProcessingRedLocator: Bool = false
    @Published var toastMessage: String? = nil
    @Published var showToast: Bool = false

    private init() {
        let savedAimMods = UserDefaults.standard.stringArray(forKey: enabledAimModsKey) ?? []
        self.enabledAimMods = Set(savedAimMods)
        self.isModSkinEnabled = UserDefaults.standard.bool(forKey: modSkinKey)
        self.isModOutfitEnabled = UserDefaults.standard.bool(forKey: modOutfitKey)
        self.isRedLocatorEnabled = UserDefaults.standard.bool(forKey: redLocatorKey)
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

        guard let item = findItem(forFilename: type.filename, altKey: type.rawValue, store: store) else {
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
                    _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.enabledAimMods.insert(typeKey)
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã bật \(type.shortTitle) trên \(targetName)!")
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
        let targetItem = findItem(forFilename: type.filename, altKey: type.rawValue, store: store)
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
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.enabledAimMods.remove(typeKey)
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt \(type.shortTitle)!")
            }
        }
    }

    // MARK: - Toggle Mod Skin (MP40 Mãng Xà từ Phong Xà)
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
        guard let item = findItem(forFilename: "Modskin.3105", altKey: "modskin", store: store) else {
            triggerToast("Không tìm thấy gói Mod Skin!")
            return
        }

        if item.isLocked {
            store.requestUnlock(for: item)
            triggerToast("Gói Mod Skin yêu cầu nhập mật khẩu!")
            return
        }

        guard let proj = item.project else {
            triggerToast("Không tìm thấy cấu hình Mod Skin!")
            return
        }

        isProcessingModSkin = true
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
                    ModFeatureManager.shared.isProcessingModSkin = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isModSkinEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Mod Skin MP40 Mãng Xà trên \(targetName)!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModSkin = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModSkin = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Lỗi khi kích hoạt skin: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreModSkin(store: PatchProjectStore) {
        let targetItem = findItem(forFilename: "Modskin.3105", altKey: "modskin", store: store)
        let receiptToRestore = targetItem?.project.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingModSkin = true

        Task.detached(priority: .userInitiated) {
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
        let outfitFilename = "Mod đồ chỉ sử dụng nhân vật Ignis.3105"
        guard let item = findItem(forFilename: outfitFilename, altKey: "ignis", store: store) else {
            triggerToast("Không tìm thấy gói Trang Phục Ignis!")
            return
        }

        if item.isLocked {
            store.requestUnlock(for: item)
            triggerToast("Gói Trang Phục Ignis yêu cầu nhập mật khẩu!")
            return
        }

        guard let proj = item.project else {
            triggerToast("Không tìm thấy cấu hình Trang Phục Ignis!")
            return
        }

        isProcessingModOutfit = true
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
                    ModFeatureManager.shared.isProcessingModOutfit = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isModOutfitEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Trang Phục Ignis trên \(targetName)!")
                }
            } catch let error as PatchPackageError {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModOutfit = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast(error.localizationKey)
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingModOutfit = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Lỗi khi kích hoạt trang phục: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreModOutfit(store: PatchProjectStore) {
        let outfitFilename = "Mod đồ chỉ sử dụng nhân vật Ignis.3105"
        let targetItem = findItem(forFilename: outfitFilename, altKey: "ignis", store: store)
        let receiptToRestore = targetItem?.project.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingModOutfit = true

        Task.detached(priority: .userInitiated) {
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

    // MARK: - Auto-Unlock Helper (Tự động mở khóa mật khẩu ngầm)
    private func ensureUnlockedItem(_ item: PatchLibraryItem, password: String = "YaBao") -> PatchLibraryItem? {
        if !item.isLocked && item.project != nil {
            return item
        }
        if let data = try? PatchProjectLibrary.readPackage(at: item.packageURL) {
            if let decoded = try? PatchPackageCodec.decode(data, password: password) {
                try? PatchKeyStore.store(decoded.contentKey, for: item.summary)
                try? PatchProjectLibrary.installImportedPackage(
                    data: data,
                    decoded: decoded,
                    summary: item.summary,
                    existingURL: item.packageURL
                )
                return PatchLibraryItem(
                    summary: item.summary,
                    project: decoded.project,
                    contentKey: decoded.contentKey,
                    packageURL: item.packageURL
                )
            }
        }
        return item
    }

    // MARK: - Toggle Định Vị Đỏ (DV_đỏ_ff.3105, tự động giải mã YaBao)
    func toggleRedLocator(store: PatchProjectStore) {
        guard !isProcessingRedLocator else { return }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if isRedLocatorEnabled {
            restoreRedLocator(store: store)
        } else {
            injectRedLocator(store: store)
        }
    }

    private func injectRedLocator(store: PatchProjectStore) {
        guard var item = findItem(forFilename: "DV_đỏ_ff.3105", altKey: "dinhvi", store: store) else {
            triggerToast("Không tìm thấy gói Định Vị Đỏ!")
            return
        }

        if item.isLocked || item.project == nil {
            if let unlocked = ensureUnlockedItem(item, password: "YaBao") {
                item = unlocked
            }
        }

        guard let proj = item.project else {
            // Mở cửa sổ nhập mật khẩu chuẩn của 3105-main để người dùng mở khóa
            store.requestUnlock(for: item)
            return
        }

        isProcessingRedLocator = true
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
                    ModFeatureManager.shared.isProcessingRedLocator = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        ModFeatureManager.shared.isRedLocatorEnabled = true
                    }
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)
                    ModFeatureManager.shared.triggerToast("Đã kích hoạt Định Vị Đỏ trên \(targetName)!")
                }
            } catch {
                await MainActor.run {
                    ModFeatureManager.shared.isProcessingRedLocator = false
                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.error)
                    ModFeatureManager.shared.triggerToast("Lỗi kích hoạt: \(error.localizedDescription)")
                }
            }
        }
    }

    private func restoreRedLocator(store: PatchProjectStore) {
        let targetItem = findItem(forFilename: "DV_đỏ_ff.3105", altKey: "dinhvi", store: store)
        let receiptToRestore = targetItem?.project.flatMap { DevicePatchService.latestReceipt(projectID: $0.id) }

        isProcessingRedLocator = true

        Task.detached(priority: .userInitiated) {
            if let receiptToRestore {
                try? DevicePatchService.restore(receipt: receiptToRestore)
            }

            await MainActor.run {
                ModFeatureManager.shared.isProcessingRedLocator = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    ModFeatureManager.shared.isRedLocatorEnabled = false
                }
                let notif = UINotificationFeedbackGenerator()
                notif.notificationOccurred(.success)
                ModFeatureManager.shared.triggerToast("Đã tắt Định Vị Đỏ!")
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
