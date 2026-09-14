import SwiftUI
import UIKit
import UniformTypeIdentifiers
import QuickLook

// MARK: - Navigation Target
enum ZStoragePartition: String, CaseIterable {
    case apps = "Ứng Dụng"
    case device = "Bộ Nhớ Máy"
    case local = "Tài Liệu"

    var icon: String {
        switch self {
        case .apps: return "app.badge.fill"
        case .device: return "iphone"
        case .local: return "folder.fill"
        }
    }
}

// MARK: - Sort Order
enum ZSortField: String, CaseIterable {
    case name = "Tên"
    case date = "Ngày"
    case size = "Kích thước"
    case type = "Loại tệp"
}

// MARK: - File Entry Model
struct ZFileEntry: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modifiedDate: Date
    let fileType: ZArchiverFileType

    var id: String { url.path }

    var formattedSize: String {
        if isDirectory { return "Thư mục" }
        return ZArchiverFormatters.fileSizeString(size)
    }

    var formattedDate: String {
        ZArchiverFormatters.dateString(modifiedDate)
    }
}

// MARK: - Breadcrumb Model
struct ZBreadcrumbItem: Identifiable, Hashable {
    var id: String { url.path }
    let name: String
    let url: URL
}

// MARK: - ZArchiver Main View
struct ZArchiverMainView: View {
    @StateObject private var fileEngine = ZArchiverFileEngine.shared
    @StateObject private var appService = ZArchiverAppService.shared

    @State private var currentPartition: ZStoragePartition = .apps
    @State private var currentDirectoryURL: URL
    @State private var selectedApp: InstalledApp? = nil
    @State private var activeAppBundleID: String? = nil

    @State private var entries: [ZFileEntry] = []
    @State private var isLoadingEntries: Bool = false
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var isMultiSelecting: Bool = false
    @State private var selectedEntries: Set<URL> = []

    @State private var sortField: ZSortField = .name
    @State private var sortAscending: Bool = true

    // Dialogs & Sheets
    @State private var showCreateFolderAlert: Bool = false
    @State private var newFolderName: String = ""
    @State private var showCreateFileAlert: Bool = false
    @State private var newFileName: String = ""
    @State private var showRenameAlert: Bool = false
    @State private var renameTargetURL: URL?
    @State private var renameNewName: String = ""
    @State private var showDeleteConfirmAlert: Bool = false
    @State private var deleteTargets: [URL] = []
    @State private var showArchiveNameAlert: Bool = false
    @State private var archiveNameInput: String = "Archive"

    @State private var activeTextEditURL: URL?
    @State private var activeImagePreviewURL: URL?
    @State private var showDocumentPicker: Bool = false

    // Conflict apply to all toggle
    @State private var conflictApplyToAll: Bool = false

    init() {
        let appDataRoot = URL(fileURLWithPath: ContainerStore.appDataRoot)
        _currentDirectoryURL = State(initialValue: appDataRoot)
    }

    // MARK: - Filtered & Sorted Entries
    private var displayedEntries: [ZFileEntry] {
        var list = entries
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }

        list.sort { a, b in
            // Folders always first
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }
            switch sortField {
            case .name:
                let cmp = a.name.localizedCaseInsensitiveCompare(b.name)
                return sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
            case .date:
                return sortAscending ? (a.modifiedDate < b.modifiedDate) : (a.modifiedDate > b.modifiedDate)
            case .size:
                return sortAscending ? (a.size < b.size) : (a.size > b.size)
            case .type:
                let extA = a.url.pathExtension.lowercased()
                let extB = b.url.pathExtension.lowercased()
                return sortAscending ? (extA < extB) : (extA > extB)
            }
        }
        return list
    }

    // MARK: - Path Components for Breadcrumb
    private var pathBreadcrumbs: [ZBreadcrumbItem] {
        if currentPartition == .apps {
            var crumbs: [ZBreadcrumbItem] = [
                ZBreadcrumbItem(name: "Ứng Dụng", url: partitionRootURL(for: .apps))
            ]
            if let app = selectedApp {
                let appRootURL = URL(fileURLWithPath: app.containerPath)
                crumbs.append(ZBreadcrumbItem(name: app.displayName, url: appRootURL))

                let curPath = currentDirectoryURL.path
                let rootPath = appRootURL.path
                if curPath != rootPath && curPath.hasPrefix(rootPath) {
                    let relative = String(curPath.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    var builtPath = rootPath
                    for segment in relative.split(separator: "/") {
                        builtPath += "/" + segment
                        crumbs.append(ZBreadcrumbItem(name: String(segment), url: URL(fileURLWithPath: builtPath)))
                    }
                }
            }
            return crumbs
        } else {
            var crumbs: [ZBreadcrumbItem] = []
            var cur = currentDirectoryURL
            var loopGuard = 0
            while cur.path != "/" && cur.path != "." && !cur.path.isEmpty && loopGuard < 20 {
                loopGuard += 1
                crumbs.insert(ZBreadcrumbItem(name: cur.lastPathComponent, url: cur), at: 0)
                let parent = cur.deletingLastPathComponent()
                if parent.path == cur.path { break }
                cur = parent
            }
            crumbs.insert(
                ZBreadcrumbItem(
                    name: currentPartition == .device ? "Gốc (/)" : "Tài Liệu",
                    url: partitionRootURL(for: currentPartition)
                ),
                at: 0
            )
            return crumbs
        }
    }

    var body: some View {
        ZStack {
            ZArchiverColor.darkBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topHeaderBar
                partitionTabBar
                breadcrumbBar

                if isSearching {
                    searchBar
                }

                if isMultiSelecting {
                    multiSelectActionBar
                }

                // Main Content
                if currentPartition == .apps && selectedApp == nil {
                    installedAppsListView
                } else {
                    fileListView
                }
            }

            // Floating Green Action Button (+)
            floatingActionButton

            // Floating Green Paste Bar
            if fileEngine.hasClipboard {
                floatingPasteBar
            }

            // Progress HUD
            if fileEngine.isOperating {
                operationHUD
            }

            // Conflict Dialog Modal ("Dán Ghi Đè Các Kiểu")
            if let conflict = fileEngine.activeConflict {
                conflictModal(conflict: conflict)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            appService.loadApps()
            if currentPartition != .apps || selectedApp != nil {
                reloadEntries()
            }
        }
        // Sheets & Pickers
        .sheet(item: Binding(
            get: { activeTextEditURL.map { IdentifiableURL(url: $0) } },
            set: { activeTextEditURL = $0?.url }
        )) { item in
            ZArchiverTextEditorView(fileURL: item.url) {
                reloadEntries()
            }
        }
        .sheet(item: Binding(
            get: { activeImagePreviewURL.map { IdentifiableURL(url: $0) } },
            set: { activeImagePreviewURL = $0?.url }
        )) { item in
            ZArchiverImageViewer(fileURL: item.url)
        }
        .sheet(isPresented: $showDocumentPicker) {
            ZArchiverDocumentPicker(destinationDir: currentDirectoryURL) {
                reloadEntries()
            }
        }
        // Alerts
        .alert("Tạo Thư Mục Mới", isPresented: $showCreateFolderAlert) {
            TextField("Tên thư mục", text: $newFolderName)
            Button("Tạo") {
                if fileEngine.createFolder(named: newFolderName, in: currentDirectoryURL) {
                    newFolderName = ""
                    reloadEntries()
                }
            }
            Button("Hủy", role: .cancel) { newFolderName = "" }
        }
        .alert("Tạo Tệp Văn Bản", isPresented: $showCreateFileAlert) {
            TextField("Tên tệp (vd: script.txt)", text: $newFileName)
            Button("Tạo") {
                if fileEngine.createTextFile(named: newFileName, in: currentDirectoryURL) {
                    let newURL = currentDirectoryURL.appendingPathComponent(newFileName.contains(".") ? newFileName : "\(newFileName).txt")
                    newFileName = ""
                    reloadEntries()
                    activeTextEditURL = newURL
                }
            }
            Button("Hủy", role: .cancel) { newFileName = "" }
        }
        .alert("Đổi Tên", isPresented: $showRenameAlert) {
            TextField("Tên mới", text: $renameNewName)
            Button("Đổi Tên") {
                if let target = renameTargetURL {
                    if fileEngine.renameItem(at: target, newName: renameNewName) {
                        renameTargetURL = nil
                        renameNewName = ""
                        reloadEntries()
                    }
                }
            }
            Button("Hủy", role: .cancel) { renameTargetURL = nil; renameNewName = "" }
        }
        .alert("Tạo Tệp Nén ZIP", isPresented: $showArchiveNameAlert) {
            TextField("Tên tệp ZIP", text: $archiveNameInput)
            Button("Nén") {
                let targets = isMultiSelecting ? Array(selectedEntries) : (renameTargetURL.map { [$0] } ?? [])
                fileEngine.createZIPArchive(sources: targets, in: currentDirectoryURL, archiveName: archiveNameInput) { success in
                    if success {
                        isMultiSelecting = false
                        selectedEntries.removeAll()
                        reloadEntries()
                    }
                }
            }
            Button("Hủy", role: .cancel) {}
        }
        .alert("Xác Nhận Xóa", isPresented: $showDeleteConfirmAlert) {
            Button("Xóa Vĩnh Viễn", role: .destructive) {
                fileEngine.deleteItems(at: deleteTargets)
                deleteTargets.removeAll()
                isMultiSelecting = false
                selectedEntries.removeAll()
                reloadEntries()
            }
            Button("Hủy", role: .cancel) { deleteTargets.removeAll() }
        } message: {
            Text("Bạn có chắc chắn muốn xóa \(deleteTargets.count) mục đã chọn không? Thao tác này không thể hoàn tác.")
        }
        .alert("Thông Báo", isPresented: $fileEngine.isShowingMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(fileEngine.operationMessage ?? "")
        }
    }

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            // ZArchiver Logo Icon
            HStack(spacing: 8) {
                if let logoImg = UIImage(named: "zarchiver_logo") {
                    Image(uiImage: logoImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [ZArchiverColor.lightGreen, ZArchiverColor.headerGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.3), radius: 2)

                        Text("Z")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }

                Text("ZArchiver")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Header Action Buttons
            HStack(spacing: 14) {
                // Search toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching.toggle()
                        if !isSearching { searchText = "" }
                    }
                } label: {
                    Image(systemName: isSearching ? "magnifyingglass.circle.fill" : "magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isSearching ? ZArchiverColor.vibrantGreen : .white)
                }

                // Multi-select toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMultiSelecting.toggle()
                        if !isMultiSelecting { selectedEntries.removeAll() }
                    }
                } label: {
                    Image(systemName: isMultiSelecting ? "checkmark.circle.fill" : "checklist")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isMultiSelecting ? ZArchiverColor.vibrantGreen : .white)
                }

                // Sort Menu
                Menu {
                    ForEach(ZSortField.allCases, id: \.self) { field in
                        Button {
                            if sortField == field {
                                sortAscending.toggle()
                            } else {
                                sortField = field
                                sortAscending = true
                            }
                        } label: {
                            HStack {
                                Text(field.rawValue)
                                if sortField == field {
                                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Refresh Button
                Button {
                    if currentPartition == .apps && selectedApp == nil {
                        appService.loadApps(forceRefresh: true)
                    } else {
                        reloadEntries()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(ZArchiverColor.headerGreen)
    }

    // MARK: - Partition Tab Bar (Ứng Dụng | Bộ Nhớ Máy | Tài Liệu)
    private var partitionTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ZStoragePartition.allCases, id: \.self) { partition in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        currentPartition = partition
                        selectedApp = nil
                        activeAppBundleID = nil
                        currentDirectoryURL = partitionRootURL(for: partition)
                        if partition != .apps {
                            reloadEntries()
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: partition.icon)
                            .font(.system(size: 12, weight: .bold))
                        Text(partition.rawValue)
                            .font(.system(size: 13, weight: currentPartition == partition ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(currentPartition == partition ? .white : Color.white.opacity(0.6))
                    .background(
                        currentPartition == partition
                            ? ZArchiverColor.primaryGreen
                            : Color.clear
                    )
                }
            }
        }
        .background(Color.black.opacity(0.35))
    }

    // MARK: - Breadcrumb Navigation Bar
    private var breadcrumbBar: some View {
        HStack(spacing: 6) {
            // Back button
            Button {
                navigateUp()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(ZArchiverColor.surfaceSecondary)
                    .clipShape(Circle())
            }
            .disabled(isAtPartitionRoot)

            // Horizontal Scroll of Breadcrumbs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    let crumbs = pathBreadcrumbs
                    ForEach(crumbs) { crumb in
                        let isLast = crumb.id == crumbs.last?.id
                        Button {
                            handleBreadcrumbTap(crumb)
                        } label: {
                            Text(crumb.name)
                                .font(.system(size: 12, weight: isLast ? .bold : .regular))
                                .foregroundStyle(isLast ? ZArchiverColor.vibrantGreen : Color.white.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(ZArchiverColor.surfaceSecondary.opacity(0.6))
                                .cornerRadius(4)
                        }

                        if !isLast {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ZArchiverColor.surface)
    }

    private var isAtPartitionRoot: Bool {
        if currentPartition == .apps {
            return selectedApp == nil
        }
        return currentDirectoryURL.path == "/" || currentDirectoryURL.path == partitionRootURL(for: currentPartition).path
    }

    private func handleBreadcrumbTap(_ crumb: ZBreadcrumbItem) {
        if currentPartition == .apps {
            if crumb.url.path == partitionRootURL(for: .apps).path {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedApp = nil
                    activeAppBundleID = nil
                    currentDirectoryURL = crumb.url
                }
                return
            }
            if let app = selectedApp, crumb.url.path == URL(fileURLWithPath: app.containerPath).path {
                navigateTo(crumb.url)
                return
            }
        }
        navigateTo(crumb.url)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ZArchiverColor.vibrantGreen)
            TextField("Tìm kiếm tệp/thư mục...", text: $searchText)
                .font(.system(size: 13))
                .foregroundStyle(.white)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(ZArchiverColor.surfaceSecondary)
    }

    // MARK: - Multi-Select Action Bar
    private var multiSelectActionBar: some View {
        HStack(spacing: 16) {
            Text("Đã chọn: \(selectedEntries.count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            // Select All / Deselect
            Button {
                if selectedEntries.count == displayedEntries.count {
                    selectedEntries.removeAll()
                } else {
                    selectedEntries = Set(displayedEntries.map(\.url))
                }
            } label: {
                Text(selectedEntries.count == displayedEntries.count ? "Bỏ chọn" : "Chọn tất cả")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ZArchiverColor.vibrantGreen)
            }

            // Copy
            Button {
                fileEngine.copy(urls: Array(selectedEntries))
                isMultiSelecting = false
                selectedEntries.removeAll()
            } label: {
                Image(systemName: "doc.on.doc").foregroundStyle(.white)
            }
            .disabled(selectedEntries.isEmpty)

            // Cut
            Button {
                fileEngine.cut(urls: Array(selectedEntries))
                isMultiSelecting = false
                selectedEntries.removeAll()
            } label: {
                Image(systemName: "scissors").foregroundStyle(.white)
            }
            .disabled(selectedEntries.isEmpty)

            // Compress
            Button {
                archiveNameInput = "Archive"
                showArchiveNameAlert = true
            } label: {
                Image(systemName: "doc.zipper").foregroundStyle(.white)
            }
            .disabled(selectedEntries.isEmpty)

            // Delete
            Button {
                deleteTargets = Array(selectedEntries)
                showDeleteConfirmAlert = true
            } label: {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .disabled(selectedEntries.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.18, green: 0.22, blue: 0.18))
    }

    // MARK: - Installed Apps List View (Ultra-fast App Containers)
    private var workspaceRow: some View {
        Button {
            currentPartition = .local
            currentDirectoryURL = partitionRootURL(for: .local)
            reloadEntries()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ZArchiverColor.primaryGreen.opacity(0.2))
                        .frame(width: 46, height: 46)
                    Image(systemName: "folder.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ZArchiverColor.vibrantGreen)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Thư Mục Tệp Cục Bộ (Tài Liệu / OniAkuma)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Quản lý tệp zip, mod, và tài liệu trong máy")
                        .font(.system(size: 11))
                        .foregroundStyle(ZArchiverColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ZArchiverColor.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var installedAppsListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                // Thư mục tệp cục bộ (tương tự 3105-main)
                workspaceRow

                if appService.isLoading && appService.apps.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(ZArchiverColor.vibrantGreen).scaleEffect(1.2)
                        Text("Đang quét toàn bộ ứng dụng trên thiết bị...")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                } else if appService.apps.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)
                        Text("Chưa tìm thấy container ứng dụng.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Chạm vào nút bên dưới để quét lại ứng dụng.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Button {
                            appService.loadApps(forceRefresh: true)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Quét Lại Ứng Dụng")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ZArchiverColor.primaryGreen)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(filteredApps) { app in
                        appRow(app)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty { return appService.apps }
        let q = searchText.lowercased()
        return appService.apps.filter {
            $0.displayName.lowercased().contains(q) || $0.bundleID.lowercased().contains(q)
        }
    }

    private func appRow(_ app: InstalledApp) -> some View {
        Button {
            selectApp(app)
        } label: {
            HStack(spacing: 12) {
                // App Logo Icon
                if let icon = appService.getCachedIcon(for: app.bundleID) {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.35), radius: 3, y: 1.5)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(ZArchiverColor.surfaceSecondary)
                            .frame(width: 46, height: 46)
                        Image(systemName: "app.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(ZArchiverColor.vibrantGreen)
                    }
                }

                // App Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(app.bundleID)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(ZArchiverColor.textSecondary)
                        .lineLimit(1)

                    if !app.version.isEmpty {
                        Text("v\(app.version)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ZArchiverColor.vibrantGreen)
                    }
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ZArchiverColor.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private func selectApp(_ app: InstalledApp) {
        var containerPath = app.containerPath
        if containerPath.isEmpty {
            containerPath = ContainerStore.resolveAppContainerPath(bundleID: app.bundleID) ?? ""
        }
        if containerPath.isEmpty {
            var err: NSString?
            containerPath = MCMContainerPathForIdentifier(2, app.bundleID, false, &err) ?? ""
        }
        if containerPath.isEmpty {
            let dirs = (try? FileManager.default.contentsOfDirectory(atPath: ContainerStore.appDataRoot)) ?? []
            for d in dirs {
                let full = (ContainerStore.appDataRoot as NSString).appendingPathComponent(d)
                if let meta = ContainerStore.readContainerMetadata(containerPath: full), meta.bundleID == app.bundleID {
                    containerPath = full
                    break
                }
            }
        }
        guard !containerPath.isEmpty else {
            log("selectApp: không tìm thấy đường dẫn container cho \(app.bundleID)")
            return
        }
        let resolvedApp = InstalledApp(
            bundleID: app.bundleID,
            name: app.displayName,
            containerPath: containerPath,
            version: app.version,
            icon: app.icon
        )
        selectedApp = resolvedApp
        activeAppBundleID = resolvedApp.bundleID
        let targetURL = URL(fileURLWithPath: containerPath)
        currentDirectoryURL = targetURL
        reloadEntries()
    }

    // MARK: - File List View
    private var fileListView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                if isLoadingEntries && entries.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(ZArchiverColor.vibrantGreen).scaleEffect(1.2)
                        Text("Đang nạp dữ liệu thư mục...")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else if displayedEntries.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "folder.badge.minus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Thư mục trống")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(displayedEntries) { entry in
                        fileRow(entry)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func fileRow(_ entry: ZFileEntry) -> some View {
        HStack(spacing: 12) {
            // Selection checkbox
            if isMultiSelecting {
                Button {
                    if selectedEntries.contains(entry.url) {
                        selectedEntries.remove(entry.url)
                    } else {
                        selectedEntries.insert(entry.url)
                    }
                } label: {
                    Image(systemName: selectedEntries.contains(entry.url) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundStyle(selectedEntries.contains(entry.url) ? ZArchiverColor.vibrantGreen : .secondary)
                }
                .buttonStyle(.plain)
            }

            // File Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(entry.fileType.accentColor.opacity(0.18))
                    .frame(width: 36, height: 36)

                Image(systemName: entry.fileType.systemIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(entry.fileType.accentColor)
            }

            // Name & Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(size: 13, weight: entry.isDirectory ? .bold : .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text(entry.formattedSize)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(ZArchiverColor.textSecondary)

                    Text(entry.formattedDate)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }

            Spacer()

            if entry.isDirectory {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            selectedEntries.contains(entry.url)
                ? ZArchiverColor.primaryGreen.opacity(0.25)
                : ZArchiverColor.surface
        )
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            if isMultiSelecting {
                if selectedEntries.contains(entry.url) {
                    selectedEntries.remove(entry.url)
                } else {
                    selectedEntries.insert(entry.url)
                }
            } else {
                handleEntryTap(entry)
            }
        }
        .contextMenu {
            fileContextMenu(entry)
        }
    }

    // MARK: - Context Menu for File/Folder
    @ViewBuilder
    private func fileContextMenu(_ entry: ZFileEntry) -> some View {
        // Open/View
        if !entry.isDirectory {
            Button {
                openFile(entry.url)
            } label: {
                Label("Xem", systemImage: "eye")
            }

            Button {
                activeTextEditURL = entry.url
            } label: {
                Label("Sửa Văn Bản", systemImage: "pencil.line")
            }
        }

        // Archive options
        if entry.fileType == .archive {
            Button {
                fileEngine.extractArchive(at: entry.url, into: currentDirectoryURL, autoFolder: false) { _ in
                    reloadEntries()
                }
            } label: {
                Label("Giải Nén Tại Đây", systemImage: "doc.zipper")
            }

            Button {
                fileEngine.extractArchive(at: entry.url, into: currentDirectoryURL, autoFolder: true) { _ in
                    reloadEntries()
                }
            } label: {
                Label("Giải Nén Vào Thư Mục", systemImage: "folder.badge.gearshape")
            }
        }

        // Compress
        Button {
            renameTargetURL = entry.url
            archiveNameInput = entry.name.replacingOccurrences(of: ".\(entry.url.pathExtension)", with: "")
            showArchiveNameAlert = true
        } label: {
            Label("Nén Thành ZIP", systemImage: "doc.zipper")
        }

        Divider()

        // Copy
        Button {
            fileEngine.copy(urls: [entry.url])
        } label: {
            Label("Sao Chép", systemImage: "doc.on.doc")
        }

        // Cut
        Button {
            fileEngine.cut(urls: [entry.url])
        } label: {
            Label("Cắt (Di Chuyển)", systemImage: "scissors")
        }

        // Rename
        Button {
            renameTargetURL = entry.url
            renameNewName = entry.name
            showRenameAlert = true
        } label: {
            Label("Đổi Tên", systemImage: "pencil")
        }

        // Share
        Button {
            FileShareHelper.share(url: entry.url, isDirectory: entry.isDirectory, defaultName: entry.name)
        } label: {
            Label("Chia Sẻ / Lưu Vào Tệp", systemImage: "square.and.arrow.up")
        }

        Divider()

        // Delete
        Button(role: .destructive) {
            deleteTargets = [entry.url]
            showDeleteConfirmAlert = true
        } label: {
            Label("Xóa", systemImage: "trash")
        }
    }

    // MARK: - Floating Green Action Button (+)
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Menu {
                    Button {
                        newFolderName = ""
                        showCreateFolderAlert = true
                    } label: {
                        Label("Tạo Thư Mục Mới", systemImage: "folder.badge.plus")
                    }

                    Button {
                        archiveNameInput = "Archive"
                        showArchiveNameAlert = true
                    } label: {
                        Label("Tạo Tệp Nén ZIP", systemImage: "doc.zipper")
                    }

                    Button {
                        showDocumentPicker = true
                    } label: {
                        Label("Tải Lên / Thêm Tệp Từ Máy", systemImage: "arrow.up.doc.fill")
                    }

                    Button {
                        newFileName = ""
                        showCreateFileAlert = true
                    } label: {
                        Label("Tạo Tệp Văn Bản Mới", systemImage: "doc.badge.plus")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ZArchiverColor.lightGreen, ZArchiverColor.primaryGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: ZArchiverColor.vibrantGreen.opacity(0.4), radius: 8, y: 4)

                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, fileEngine.hasClipboard ? 80 : 24)
            }
        }
    }

    // MARK: - Floating Green Paste Bar
    private var floatingPasteBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                // Clipboard Info
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ZArchiverColor.vibrantGreen)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(fileEngine.clipboardMode?.rawValue ?? "Dán"): \(fileEngine.clipboardCount) mục")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Dán vào: \(currentDirectoryURL.lastPathComponent)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Quick Overwrite-All Paste
                Button {
                    fileEngine.paste(to: currentDirectoryURL, alwaysOverwrite: true)
                    reloadEntries()
                } label: {
                    Text("Ghi đè tất cả")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(6)
                }

                // Normal Paste Button
                Button {
                    fileEngine.paste(to: currentDirectoryURL, alwaysOverwrite: false)
                    reloadEntries()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Dán")
                            .fontWeight(.black)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ZArchiverColor.primaryGreen)
                    .cornerRadius(8)
                }

                // Dismiss
                Button {
                    fileEngine.clearClipboard()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ZArchiverColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ZArchiverColor.vibrantGreen.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 6)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Conflict Resolution Modal ("Dán Ghi Đè Các Kiểu")
    private func conflictModal(conflict: ZConflictPrompt) -> some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.orange)
                    Text("Trùng Tên Tệp / Thư Mục")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Đã tồn tại mục có tên tương tự ở thư mục đích:")
                        .font(.system(size: 13))
                        .foregroundStyle(ZArchiverColor.textSecondary)

                    Text(conflict.itemName)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ZArchiverColor.surfaceSecondary)
                        .cornerRadius(6)
                }

                // Toggle Apply to All
                Toggle(isOn: $conflictApplyToAll) {
                    Text("Áp dụng cho tất cả các xung đột tiếp theo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .tint(ZArchiverColor.vibrantGreen)

                Divider()

                // Actions: Overwrite, Skip, Rename
                VStack(spacing: 8) {
                    // Overwrite
                    Button {
                        fileEngine.resolveConflict(choice: .overwrite, applyToAll: conflictApplyToAll)
                        reloadEntries()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Ghi Đè (Thay thế mục cũ)")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(ZArchiverColor.primaryGreen)
                        .cornerRadius(8)
                    }

                    // Auto Rename
                    Button {
                        fileEngine.resolveConflict(choice: .autoRename, applyToAll: conflictApplyToAll)
                        reloadEntries()
                    } label: {
                        HStack {
                            Image(systemName: "plus.square.on.square")
                            Text("Đổi Tên Tự Động (Giữ cả hai)")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.35))
                        .cornerRadius(8)
                    }

                    // Skip
                    Button {
                        fileEngine.resolveConflict(choice: .skip, applyToAll: conflictApplyToAll)
                        reloadEntries()
                    } label: {
                        Text("Bỏ Qua")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ZArchiverColor.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
            )
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Operation Progress HUD
    private var operationHUD: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView().tint(ZArchiverColor.vibrantGreen).scaleEffect(1.3)
                Text(fileEngine.operationProgressText ?? "Đang xử lý...")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 14).fill(ZArchiverColor.surfaceSecondary))
        }
    }

    // MARK: - Navigation & Loading Helpers

    private func partitionRootURL(for partition: ZStoragePartition) -> URL {
        switch partition {
        case .apps:
            return URL(fileURLWithPath: ContainerStore.appDataRoot)
        case .device:
            return URL(fileURLWithPath: "/")
        case .local:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory())
        }
    }

    private func navigateTo(_ url: URL) {
        currentDirectoryURL = url
        reloadEntries()
    }

    private func navigateUp() {
        if currentPartition == .apps {
            if let app = selectedApp {
                let curPath = currentDirectoryURL.path
                let rootPath = URL(fileURLWithPath: app.containerPath).path
                if curPath == rootPath || !curPath.hasPrefix(rootPath) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedApp = nil
                        activeAppBundleID = nil
                        currentDirectoryURL = partitionRootURL(for: .apps)
                    }
                    return
                } else {
                    let parent = currentDirectoryURL.deletingLastPathComponent()
                    navigateTo(parent)
                    return
                }
            }
        }
        let parent = currentDirectoryURL.deletingLastPathComponent()
        if parent != currentDirectoryURL {
            navigateTo(parent)
        }
    }

    private func handleEntryTap(_ entry: ZFileEntry) {
        if entry.isDirectory {
            navigateTo(entry.url)
        } else {
            openFile(entry.url)
        }
    }

    private func openFile(_ url: URL) {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "txt", "json", "plist", "xml", "log", "cfg", "ini", "strings", "sh", "py", "c", "h", "md", "html", "css", "js", "dat":
            activeTextEditURL = url
        case "png", "jpg", "jpeg", "webp", "gif", "bmp", "heic":
            activeImagePreviewURL = url
        case "zip", "7z", "rar", "tar", "gz":
            fileEngine.extractArchive(at: url, into: currentDirectoryURL, autoFolder: true) { _ in
                reloadEntries()
            }
        default:
            FileShareHelper.share(url: url, isDirectory: false, defaultName: url.lastPathComponent)
        }
    }

    private func reloadEntries() {
        let path = currentDirectoryURL.path
        let bundleID = activeAppBundleID
        isLoadingEntries = true

        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Kích hoạt quyền truy cập container ứng dụng qua MCM & MobileHouseArrest
            if let bundleID, ContainerAccessPolicy.shouldAttemptMCM(bundleID: bundleID) {
                var activationError: NSString?
                let handle = MCMActivateContainer(2, bundleID, false, &activationError)
                log("ZArchiver: MCM activate \(bundleID) -> \(handle)")
            }
            if path.contains("Containers/Data/Application") || path.hasPrefix("/var") || path.hasPrefix("/private/var") {
                let handle = ContainerStore.grantContainerAccess(path)
                log("ZArchiver: grantContainerAccess \(path) -> \(handle)")
            }

            // 2. Liệt kê danh sách tệp an toàn không gây crash
            let rawItems = ContainerStore.listFiles(at: path)
            let fm = FileManager.default
            let mapped: [ZFileEntry] = rawItems.map { item in
                let itemURL = URL(fileURLWithPath: item.path)
                let date = (try? fm.attributesOfItem(atPath: item.path)[.modificationDate] as? Date) ?? Date()
                let fileType = ZArchiverFileType.resolve(name: item.name, isDirectory: item.isDirectory)
                return ZFileEntry(
                    url: itemURL,
                    name: item.name,
                    isDirectory: item.isDirectory,
                    size: item.size,
                    modifiedDate: date,
                    fileType: fileType
                )
            }

            DispatchQueue.main.async {
                guard currentDirectoryURL.path == path else { return }
                self.entries = mapped
                self.isLoadingEntries = false
            }
        }
    }
}

// MARK: - Document Picker Representable
struct ZArchiverDocumentPicker: UIViewControllerRepresentable {
    let destinationDir: URL
    let onCompleted: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .folder, .archive, .data], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(destinationDir: destinationDir, onCompleted: onCompleted)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let destinationDir: URL
        let onCompleted: () -> Void

        init(destinationDir: URL, onCompleted: @escaping () -> Void) {
            self.destinationDir = destinationDir
            self.onCompleted = onCompleted
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let fm = FileManager.default
            for url in urls {
                let dest = destinationDir.appendingPathComponent(url.lastPathComponent)
                if fm.fileExists(atPath: dest.path) {
                    try? fm.removeItem(at: dest)
                }
                try? fm.copyItem(at: url, to: dest)
            }
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
            onCompleted()
        }
    }
}

// MARK: - URL Wrapper for Sheet Identifiable
private struct IdentifiableURL: Identifiable {
    var id: String { url.absoluteString }
    let url: URL
}
