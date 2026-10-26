import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var isShowingSplash = true
    @State private var hasRevealedApp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()
            if isShowingSplash {
                SplashLoadingView {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else {
                Group {
                    if licenseManager.isSystemMaintenance {
                        SystemMaintenanceGateView().saturation(0)
                    } else if !licenseManager.isAuthorized || !hasRevealedApp {
                        KeyAuthView()
                            .transition(.opacity)
                    } else {
                        MainInjectorView()
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .task(id: licenseManager.isAuthorized) {
            guard licenseManager.isAuthorized else {
                hasRevealedApp = false
                return
            }
            if !isShowingSplash {
                do { try await Task.sleep(nanoseconds: 650_000_000) }
                catch { return }
            }
            guard !Task.isCancelled, licenseManager.isAuthorized else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) {
                hasRevealedApp = true
            }
        }
    }
}
