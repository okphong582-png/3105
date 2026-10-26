import SwiftUI
import UIKit

struct MainInjectorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var yabao = YabaoCheatManager.shared
    @ObservedObject private var modManager = ModFeatureManager.shared
    @State private var hasSelectedGame = false

    var body: some View {
        Group {
            if hasSelectedGame {
                dashboard.transition(.opacity)
            } else {
                GameSelectionView { bundleID in
                    yabao.selectedGame = bundleID
                    modManager.selectedBundle = bundleID
                    yabao.checkInjectionState()
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                        hasSelectedGame = true
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private var dashboard: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Button(action: changeGame) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 44, height: 44)
                            .background(AppTheme.cardBackground, in: Circle())
                    }
                    .accessibilityLabel("Đổi game")
                    .disabled(yabao.isInjecting)
                    Text("Bảng điều khiển")
                        .font(.system(size: 22, weight: .semibold))
                        .tracking(-0.6)
                    Spacer(minLength: 0)
                }

                selectedGameCard
                YabaoCheatTabView()

                Button(action: openGame) {
                    HStack(spacing: 10) {
                        Text("Mở game").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(AppTheme.cardBackgroundElevated, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.borderSubtle))
                }
                .buttonStyle(CardScaleButtonStyle())
                .disabled(yabao.isInjecting)

                Text("MIZZE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(5)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(AppTheme.pageBackground.ignoresSafeArea())
        .foregroundStyle(.white)
        .overlay(alignment: .top) {
            if let message = modManager.toastMessage {
                Text(message)
                    .font(.subheadline)
                    .padding(16)
                    .background(AppTheme.cardBackgroundElevated, in: RoundedRectangle(cornerRadius: 16))
                    .padding(24)
            }
        }
    }

    private var selectedGameCard: some View {
        HStack(spacing: 16) {
            GameAppIconBadge(isMax: yabao.selectedGame == "com.dts.freefiremax", size: 58)
            VStack(alignment: .leading, spacing: 7) {
                Text(yabao.selectedGame == "com.dts.freefiremax" ? "Free Fire MAX" : "Free Fire")
                    .font(.system(size: 20, weight: .semibold))
                Label(yabao.isOnline ? "Menu đang bật" : "Menu đang tắt", systemImage: yabao.isOnline ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Button(action: changeGame) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
            }
            .accessibilityLabel("Đổi phiên bản game")
            .disabled(yabao.isInjecting)
        }
        .padding(18)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.borderSubtle))
    }

    private func changeGame() {
        guard !yabao.isInjecting else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            hasSelectedGame = false
        }
    }

    private func openGame() {
        guard !yabao.isInjecting else { return }
        let isMax = yabao.selectedGame == "com.dts.freefiremax"
        let scheme = isMax ? "freefiremax://" : "freefire://"
        guard let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) else {
            modManager.triggerToast("Hãy mở \(isMax ? "Free Fire MAX" : "Free Fire") từ màn hình chính.")
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
