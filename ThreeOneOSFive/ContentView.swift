import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject private var licenseManager = LicenseManager.shared

    var body: some View {
        Group {
            if licenseManager.isSystemMaintenance {
                SystemMaintenanceGateView()
            } else if !licenseManager.isAuthorized {
                KeyAuthView()
            } else {
                MainInjectorView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
