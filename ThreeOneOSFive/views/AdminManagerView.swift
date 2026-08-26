import SwiftUI
import WebKit

// MARK: - Admin Server Web View Wrapper (Running admin_panel.html)
struct AdminManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var webView = WKWebView()
    @State private var isLoading = true
    @State private var loadError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.03, blue: 0.05).ignoresSafeArea()

                AdminHTMLWebView(isLoading: $isLoading, loadError: $loadError)
                    .ignoresSafeArea(.container, edges: .bottom)

                if isLoading {
                    ZStack {
                        Color(red: 0.03, green: 0.04, blue: 0.06).opacity(0.95)
                            .ignoresSafeArea()

                        VStack(spacing: 14) {
                            ProgressView()
                                .tint(Color(red: 0.0, green: 0.85, blue: 1.0))
                                .scaleEffect(1.3)

                            Text("Đang nạp Server Key Portal...")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }

                if let error = loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)

                        Text("Không thể tải giao diện Admin")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)

                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Button("Thử lại") {
                            loadError = nil
                            isLoading = true
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.0, green: 0.85, blue: 1.0).cornerRadius(8))
                    }
                    .padding(24)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.13).cornerRadius(18))
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Đóng")
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        NotificationCenter.default.post(name: .reloadAdminWebView, object: nil)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color(red: 0.0, green: 0.85, blue: 1.0))
                    }
                }
            }
        }
    }
}

extension Notification.Name {
    static let reloadAdminWebView = Notification.Name("reloadAdminWebView")
}

// MARK: - WKWebView UIViewRepresentable
struct AdminHTMLWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = preferences
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true

        NotificationCenter.default.addObserver(
            forName: .reloadAdminWebView,
            object: nil,
            queue: .main
        ) { _ in
            webView.reload()
        }

        loadAdminHTML(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func loadAdminHTML(into webView: WKWebView) {
        // Try Bundle URL first
        if let url = Bundle.main.url(forResource: "admin_panel", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: Bundle.main.bundleURL)
            return
        }

        // Try direct file path in bundle or documents
        let candidatePaths = [
            Bundle.main.bundlePath + "/admin_panel.html",
            Bundle.main.bundlePath + "/ThreeOneOSFive/admin_panel.html"
        ]

        for path in candidatePaths {
            if FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
                return
            }
        }

        // Fallback: Read embedded string directly
        if let htmlContent = loadEmbeddedAdminHTML() {
            webView.loadHTMLString(htmlContent, baseURL: Bundle.main.bundleURL)
            return
        }

        loadError = "Không tìm thấy file admin_panel.html trong ứng dụng!"
        isLoading = false
    }

    private func loadEmbeddedAdminHTML() -> String? {
        if let url = Bundle.main.url(forResource: "admin_panel", withExtension: "html"),
           let str = try? String(contentsOf: url, encoding: .utf8) {
            return str
        }
        return nil
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AdminHTMLWebView

        init(_ parent: AdminHTMLWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadError = error.localizedDescription
        }
    }
}
