import SwiftUI
import UIKit

@main
struct ThreeOneOSFiveApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @ObservedObject private var licenseManager = LicenseManager.shared
    @ObservedObject private var vpnGuard = VPNGuardService.shared
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.vietnamese.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        setupLogCapture()
        log("app: OniAkuma launching — iOS \(AppInfo.osVersion) (\(AppInfo.osBuild)) \(AppInfo.machineName)")
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .vietnamese
    }

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if vpnGuard.isVPNActive {
                    VPNBlockedView()
                        .transition(.opacity)
                        .zIndex(10)
                } else if !licenseManager.isAuthorized && !showSplash {
                    KeyAuthView()
                        .environment(\.appLanguage, language)
                        .environment(\.locale, language.locale)
                        .transition(.opacity)
                        .zIndex(0)
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(patchDraftCoordinator)
                        .environmentObject(fileOperationCoordinator)
                        .environment(\.appLanguage, language)
                        .environment(\.locale, language.locale)
                        .opacity(showSplash ? 0 : 1)
                        .allowsHitTesting(!showSplash)
                        .zIndex(0)
                }

                if showSplash && !vpnGuard.isVPNActive {
                    SplashLoadingView {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            showSplash = false
                        }
                        if licenseManager.isAuthorized {
                            appState.detectSupport()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(2)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                vpnGuard.checkVPN()
                if !showSplash && licenseManager.isAuthorized {
                    appState.detectSupport()
                }
                Task {
                    await licenseManager.recheckLicense()
                }
            }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                vpnGuard.checkVPN()
                Task {
                    await licenseManager.recheckLicense()
                }
                guard !showSplash, licenseManager.isAuthorized else { return }
                appState.detectSupport()
            }
            .onOpenURL { url in
                patchDraftCoordinator.presentImport(url)
            }
        }
    }
}

class AppState: ObservableObject {
    @Published var exploitStatus: ExploitStatus = .notStarted
    @Published var unsupportedMessage: String?
    @Published var kernelExploitRunning = false

    private var autoRunAttempted = false

    var kernelExploitApplicable: Bool {
        KernelExploit.isApplicable(
            osVersion: AppInfo.osVersion,
            osBuild: AppInfo.osBuild,
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch
        )
    }

    var isSupported: Bool {
        switch exploitStatus {
        case .notStarted, .ineligible:
            return ExploitSupportPolicy.isEligible(
                major: AppInfo.versionTuple.major,
                minor: AppInfo.versionTuple.minor,
                patch: AppInfo.versionTuple.patch,
                build: AppInfo.osBuild
            )
        case .ready, .succeeded:
            return true
        case .unsupported:
            return false
        }
    }

    func detectSupport() {
        if kernelExploitRunning { return }
        if kernelExploitApplicable && !autoRunAttempted {
            autoRunAttempted = true
            triggerKernelExploit(isRetry: false)
            return
        }
        guard exploitStatus == .notStarted else { return }
        if ExploitSupportPolicy.isEligible(
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            build: AppInfo.osBuild
        ) {
            exploitStatus = .ready
        } else {
            exploitStatus = .unsupported
            unsupportedMessage = ExploitSupportPolicy.unsupportedReason(
                osVersion: AppInfo.osVersion,
                osBuild: AppInfo.osBuild,
                major: AppInfo.versionTuple.major,
                minor: AppInfo.versionTuple.minor,
                patch: AppInfo.versionTuple.patch
            )
        }
    }

    func triggerKernelExploit(isRetry: Bool) {
        guard kernelExploitApplicable else { return }
        kernelExploitRunning = true
        exploitStatus = .notStarted

        KernelExploit.run(
            osVersion: AppInfo.osVersion,
            osBuild: AppInfo.osBuild,
            major: AppInfo.versionTuple.major,
            minor: AppInfo.versionTuple.minor,
            patch: AppInfo.versionTuple.patch,
            isRetry: isRetry
        ) { [weak self] status, msg in
            self?.kernelExploitRunning = false
            self?.exploitStatus = status
            self?.unsupportedMessage = msg
        }
    }
}
