import SwiftUI
import UIKit

typealias FeatureMenuTabView = YabaoCheatTabView

@MainActor
struct YabaoCheatTabView: View {
    @ObservedObject private var yabao = YabaoCheatManager.shared
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isAlertSuccess = true
    @State private var isSubmitting = false

    private var isBusy: Bool { isSubmitting || yabao.isInjecting }

    var body: some View {
        VStack(spacing: 20) {
            powerCard
        }
        .onAppear { yabao.checkInjectionState() }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isAlertSuccess ? "Thành công" : "Thông báo"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đóng"))
            )
        }
    }

    private var powerCard: some View {
        VStack(spacing: 28) {
            HStack {
                Text("CONTROL CENTER")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(2)
                Spacer()
                Label(yabao.isOnline ? "Đang bật" : "Đang tắt", systemImage: yabao.isOnline ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.textSecondary)

            ZStack {
                Circle().stroke(AppTheme.borderSubtle, lineWidth: 1).frame(width: 124, height: 124)
                Circle()
                    .fill(yabao.isOnline ? Color.white : AppTheme.cardBackgroundElevated)
                    .frame(width: 96, height: 96)
                if isBusy {
                    ProgressView().tint(yabao.isOnline ? .black : .white)
                } else {
                    Image(systemName: yabao.isOnline ? "checkmark" : "power")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(yabao.isOnline ? .black : .white)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(isBusy ? "Đang xử lý…" : (yabao.isOnline ? "Mọi thứ sẵn sàng." : "Sẵn sàng khi bạn muốn."))
                    .font(.system(size: 26, weight: .semibold)).tracking(-0.8)
                    .multilineTextAlignment(.center)
                Text(isBusy ? "Vui lòng chờ thao tác hoàn tất." : (yabao.isOnline ? "Tính năng đã bật cho phiên bản bạn chọn." : "Một chạm để bật tính năng cho phiên bản đã chọn."))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                guard !isBusy else { return }
                isSubmitting = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { @MainActor in
                    defer { isSubmitting = false }
                    let (success, message) = await yabao.toggleFeature()
                    alertMessage = message
                    isAlertSuccess = success
                    showAlert = true
                }
            } label: {
                HStack(spacing: 10) {
                    if isBusy { ProgressView().tint(.black) }
                    Text(isBusy ? "Đang xử lý" : (yabao.isOnline ? "Tắt tính năng" : "Kích hoạt tính năng"))
                        .font(.system(size: 15, weight: .semibold))
                    if !isBusy { Image(systemName: yabao.isOnline ? "power" : "arrow.right") }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.white.opacity(isBusy ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(CardScaleButtonStyle())
            .disabled(isBusy)
        }
        .padding(24)
        .background(AppTheme.darkSurfaceGradient, in: RoundedRectangle(cornerRadius: 26))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(AppTheme.borderSubtle))
    }

}
