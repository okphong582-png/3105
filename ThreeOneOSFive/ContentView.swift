import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashLoadingView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else {
                Group {
                    if licenseManager.isSystemMaintenance {
                        SystemMaintenanceGateView()
                    } else if !licenseManager.isAuthorized {
                        KeyAuthView()
                    } else {
                        MainInjectorView()
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}
