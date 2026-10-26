import SwiftUI

struct SplashLoadingView: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                AppLogo(size: 148)
                Text("MIZZE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(5)
                ProgressView().tint(.white).padding(.top, 20)
                Text("Đang chuẩn bị phiên truy cập…")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .foregroundStyle(.white)
        }
        .task {
            // Follow the actual license check rather than a simulated percentage.
            await LicenseManager.shared.recheckLicense()
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }
}
