import SwiftUI
import UIKit

struct ZArchiverTextEditorView: View {
    let fileURL: URL
    let onSaveCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var textContent: String = ""
    @State private var originalContent: String = ""
    @State private var isSaving: Bool = false
    @State private var showSavedNotice: Bool = false
    @State private var encodingUsed: String = "UTF-8"
    @State private var searchText: String = ""
    @State private var isSearchVisible: Bool = false

    init(fileURL: URL, onSaveCompleted: (() -> Void)? = nil) {
        self.fileURL = fileURL
        self.onSaveCompleted = onSaveCompleted
    }

    private var hasChanges: Bool {
        textContent != originalContent
    }

    private var lineCount: Int {
        textContent.components(separatedBy: .newlines).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZArchiverColor.darkBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Info Bar
                    HStack(spacing: 12) {
                        Label(fileURL.lastPathComponent, systemImage: "doc.text.fill")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer()

                        Text("\(lineCount) dòng")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ZArchiverColor.textSecondary)

                        Text(encodingUsed)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ZArchiverColor.surface)

                    // Quick in-text search bar
                    if isSearchVisible {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            TextField("Tìm trong tệp...", text: $searchText)
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ZArchiverColor.surfaceSecondary)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Text Editor Canvas
                    TextEditor(text: $textContent)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .background(ZArchiverColor.darkBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)

                    // Bottom status bar
                    HStack {
                        if hasChanges {
                            HStack(spacing: 4) {
                                Circle().fill(Color.orange).frame(width: 8, height: 8)
                                Text("Chưa lưu thay đổi")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.orange)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Circle().fill(ZArchiverColor.vibrantGreen).frame(width: 8, height: 8)
                                Text("Đã đồng bộ với đĩa")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text("\(textContent.count) ký tự")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(ZArchiverColor.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ZArchiverColor.surface)
                }

                // Saved Toast
                if showSavedNotice {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ZArchiverColor.vibrantGreen)
                            Text("Đã lưu thay đổi vào tệp thành công!")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(ZArchiverColor.surfaceSecondary)
                                .overlay(Capsule().stroke(ZArchiverColor.vibrantGreen, lineWidth: 1.5))
                                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                        )
                        .padding(.bottom, 60)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Trình Sửa Tệp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearchVisible.toggle()
                            }
                        } label: {
                            Image(systemName: isSearchVisible ? "magnifyingglass.circle.fill" : "magnifyingglass")
                                .foregroundStyle(.white)
                        }

                        Button {
                            saveFile()
                        } label: {
                            HStack(spacing: 4) {
                                if isSaving {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Lưu")
                                        .fontWeight(.bold)
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(hasChanges ? ZArchiverColor.primaryGreen : Color.white.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .disabled(isSaving || !hasChanges)
                    }
                }
            }
            .onAppear {
                loadFile()
            }
        }
    }

    private func loadFile() {
        guard let data = try? Data(contentsOf: fileURL) else {
            textContent = "Không thể đọc dữ liệu tệp."
            return
        }

        if let str = String(data: data, encoding: .utf8) {
            textContent = str
            originalContent = str
            encodingUsed = "UTF-8"
        } else if let str = String(data: data, encoding: .ascii) {
            textContent = str
            originalContent = str
            encodingUsed = "ASCII"
        } else if let str = String(data: data, encoding: .isoLatin1) {
            textContent = str
            originalContent = str
            encodingUsed = "ISO-Latin"
        } else {
            textContent = "Tệp nhị phân (\(data.count) bytes). Không thể hiển thị dưới dạng văn bản."
            originalContent = textContent
            encodingUsed = "Binary"
        }
    }

    private func saveFile() {
        guard hasChanges else { return }
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try textContent.write(to: fileURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.originalContent = self.textContent
                    self.onSaveCompleted?()

                    let notif = UINotificationFeedbackGenerator()
                    notif.notificationOccurred(.success)

                    withAnimation(.spring()) {
                        self.showSavedNotice = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.showSavedNotice = false
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isSaving = false
                    log("ZArchiverTextEditor: không thể ghi tệp: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Image Viewer

struct ZArchiverImageViewer: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var uiImage: UIImage?
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in scale = max(0.8, min(value, 5.0)) }
                                .onEnded { _ in withAnimation { scale = max(1.0, min(scale, 4.0)) } }
                        )
                } else {
                    ProgressView().tint(.white)
                }
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đóng") { dismiss() }.foregroundStyle(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let img = uiImage {
                        Text("\(Int(img.size.width))x\(Int(img.size.height))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                if let data = try? Data(contentsOf: fileURL) {
                    uiImage = UIImage(data: data)
                }
            }
        }
    }
}
