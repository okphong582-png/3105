import SwiftUI

enum AppColorTheme: String, CaseIterable, Identifiable {
    case cyan = "cyan"
    case crimson = "crimson"
    case purple = "purple"
    case gold = "gold"
    case emerald = "emerald"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cyan: return "Neon Cyan (Mặc định)"
        case .crimson: return "Blood Crimson (Đỏ Ác Quỷ)"
        case .purple: return "Phantom Purple (Tím Ma Quái)"
        case .gold: return "Cyber Gold (Vàng Hoàng Gia)"
        case .emerald: return "Emerald Green (Xanh Lục Bảo)"
        }
    }

    var primaryColor: Color {
        switch self {
        case .cyan: return Color(red: 0.0, green: 0.86, blue: 1.0)
        case .crimson: return Color(red: 1.0, green: 0.22, blue: 0.35)
        case .purple: return Color(red: 0.72, green: 0.35, blue: 1.0)
        case .gold: return Color(red: 1.0, green: 0.78, blue: 0.20)
        case .emerald: return Color(red: 0.18, green: 0.88, blue: 0.48)
        }
    }

    static var current: AppColorTheme {
        let saved = UserDefaults.standard.string(forKey: "oni_akuma_theme_color") ?? "cyan"
        return AppColorTheme(rawValue: saved) ?? .cyan
    }
}

enum AppTheme {
    static var accent: Color {
        AppColorTheme.current.primaryColor
    }

    static let secondaryAccent = Color(red: 0.38, green: 0.55, blue: 1.0)
    static let goldAccent = Color(red: 0.95, green: 0.77, blue: 0.25)

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let darkSurfaceGradient = LinearGradient(
        colors: [Color(red: 0.09, green: 0.10, blue: 0.14), Color(red: 0.05, green: 0.05, blue: 0.08)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Deep Obsidian / Jet Black Surfaces
    static let pageBackground = Color(red: 0.04, green: 0.04, blue: 0.06) // #0A0A0F
    static let cardBackground = Color(red: 0.08, green: 0.09, blue: 0.12) // #14161F
    static let cardBackgroundElevated = Color(red: 0.12, green: 0.13, blue: 0.17)
    static let consoleBackground = Color(red: 0.03, green: 0.03, blue: 0.05)
    static let borderSubtle = Color.white.opacity(0.08)
    static var borderGlow: Color { accent.opacity(0.3) }

    static let pageInset: CGFloat = 16
    static let rowIconSize: CGFloat = 17
    static let rowIconFrame: CGFloat = 28
    static let fileRowIconSize: CGFloat = 17
    static let fileRowIconFrame: CGFloat = 30
    static let fileRowHeight: CGFloat = 60
    static let appIconSize: CGFloat = 32
    static let emptyIconSize: CGFloat = 30
    static let selectionIconSize: CGFloat = 18
}

struct AppRowIcon: View {
    let systemName: String
    var tint: Color = AppTheme.accent
    var symbolSize: CGFloat = AppTheme.rowIconSize
    var frameSize: CGFloat = AppTheme.rowIconFrame

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.20), tint.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(tint.opacity(0.25), lineWidth: 0.75)
                )
            Image(systemName: systemName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: frameSize, height: frameSize)
        .accessibilityHidden(true)
    }
}

struct AppSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearLabel: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent.opacity(0.8))
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(.body)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clearLabel)
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 38)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(AppTheme.cardBackgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(AppTheme.borderSubtle, lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.pageInset)
        .padding(.vertical, 8)
    }
}

struct AppLogo: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            if let icon = UIImage(named: "AppLogo")
                ?? UIImage(named: "AppIcon")
                ?? UIImage(named: "AppIcon-1024")
                ?? UIImage(named: "AppIcon60x60") {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.2)
        )
        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }
}
