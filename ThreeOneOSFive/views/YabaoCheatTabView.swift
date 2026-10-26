import SwiftUI
import UIKit

typealias FeatureMenuTabView = YabaoCheatTabView

@MainActor
struct YabaoCheatTabView: View {
    var onResult: (Bool, String, Bool) -> Void = { _, _, _ in }
    @ObservedObject private var yabao = YabaoCheatManager.shared
    @State private var isSubmitting = false
    @State private var isTurningOn = false

    private var isBusy: Bool { isSubmitting || yabao.isInjecting }
    private var busyTitle: String { isTurningOn ? "Đang bật Menu…" : "Đang tắt Menu…" }

    var body: some View {
        VStack(spacing: 26) {
            HStack {
                Text("MIZZE MENU")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.5)
                Spacer()
                Label(yabao.isOnline ? "Đang bật" : "Đang tắt", systemImage: yabao.isOnline ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.black.opacity(0.65))

            ZStack {
                Circle().stroke(Color.black.opacity(0.12), lineWidth: 1).frame(width: 116, height: 116)
                Circle().fill(Color.black.opacity(0.06)).frame(width: 94, height: 94)
                if isBusy {
                    ProgressView().tint(.black).scaleEffect(1.4)
                } else {
                    Image(systemName: yabao.isOnline ? "checkmark" : "power")
                        .font(.system(size: 34, weight: .light))
                }
            }
            .padding(.top, 6)
            .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text(isBusy ? busyTitle : (yabao.needsCleanupRetry ? "Chưa tắt xong Menu." : (yabao.isOnline ? "Menu đã sẵn sàng." : "Bật Menu để bắt đầu.")))
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.8)
                    .multilineTextAlignment(.center)
                Text(isBusy ? (isTurningOn ? "Chờ một chút, Menu đang được chuẩn bị." : "Đang xóa các file Menu của game đã chọn.") : (yabao.needsCleanupRetry ? "Nhấn Tắt Menu để thử xóa lại các file còn lại." : (yabao.isOnline ? "Bạn có thể mở game ngay bây giờ." : "Chọn Bật Menu và chờ 3 giây để hoàn tất.")))
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                guard !isBusy else { return }
                isTurningOn = !yabao.canDisableMenu
                isSubmitting = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task { @MainActor in
                    defer { isSubmitting = false }
                    let (success, message) = await yabao.toggleFeature()
                    onResult(success, message, isTurningOn)
                }
            } label: {
                HStack(spacing: 10) {
                    if isBusy { ProgressView().tint(.white) }
                    Text(isBusy ? busyTitle : (yabao.canDisableMenu ? "Tắt Menu" : "Bật Menu"))
                        .font(.system(size: 16, weight: .semibold))
                    if !isBusy { Image(systemName: yabao.canDisableMenu ? "power" : "arrow.right") }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.black.opacity(isBusy ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 17))
            }
            .buttonStyle(CardScaleButtonStyle())
            .disabled(isBusy)
        }
        .foregroundStyle(.black)
        .padding(26)
        .background(Color(white: 0.96), in: RoundedRectangle(cornerRadius: 28))
        .onAppear { yabao.checkInjectionState() }
    }
}
