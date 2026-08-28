import SwiftUI

struct SplashLoadingView: View {
    var onFinish: () -> Void

    @State private var pulseGlow = false
    @State private var progress: CGFloat = 0.0
    @State private var statusIndex = 0
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.92

    private let statusMessages = [
        "Initializing System...",
        "Connecting Container Bridge...",
        "OniAkuma x HoangHaMod,TrongKien",
        "Ready"
    ]

    var body: some View {
        ZStack {
            // Luxury Deep Pitch Black Background with ambient radial glows
            Color(red: 0.03, green: 0.03, blue: 0.05)
                .ignoresSafeArea()

            // Ambient background lighting
            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 0.86, blue: 1.0).opacity(pulseGlow ? 0.18 : 0.07),
                    Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulseGlow)

            VStack(spacing: 28) {
                Spacer()

                // Glowing Emblem / Logo
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.86, blue: 1.0).opacity(0.35),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 75
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseGlow ? 1.15 : 0.95)

                    AppLogo(size: 96)
                }

                // Brand & Collaboration Typography
                VStack(spacing: 8) {
                    Text("OniAkuma")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color(red: 0.82, green: 0.92, blue: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 0.0, green: 0.86, blue: 1.0).opacity(0.4), radius: 8, x: 0, y: 3)

                    // Collaboration Tag
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.0, green: 0.86, blue: 1.0))

                        Text("OniAkuma x HoangHaMod,TrongKien")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.86, blue: 1.0),
                                        Color(red: 0.55, green: 0.75, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.0, green: 0.86, blue: 1.0))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.16))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.86, blue: 1.0).opacity(0.5),
                                                Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.2)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                }

                Spacer()

                // Progress Bar & Dynamic Status
                VStack(spacing: 14) {
                    // Shimmering Cyber Progress Bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 220, height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.86, blue: 1.0),
                                        Color(red: 0.4, green: 0.7, blue: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, 220 * progress), height: 4)
                            .shadow(color: Color(red: 0.0, green: 0.86, blue: 1.0).opacity(0.8), radius: 4, x: 0, y: 0)
                    }

                    Text(statusMessages[min(statusIndex, statusMessages.count - 1)])
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.secondary.opacity(0.85))
                        .frame(height: 16)
                }
                .padding(.bottom, 48)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            Task {
                await LicenseManager.shared.recheckLicense()
            }
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        withAnimation(.easeOut(duration: 0.5)) {
            opacity = 1.0
            scale = 1.0
        }
        pulseGlow = true

        // Progress simulation with status updates
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
                if progress >= 0.35 && statusIndex == 0 {
                    statusIndex = 1
                } else if progress >= 0.70 && statusIndex == 1 {
                    statusIndex = 2
                } else if progress >= 0.95 && statusIndex == 2 {
                    statusIndex = 3
                }
            } else {
                timer.invalidate()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        opacity = 0.0
                        scale = 1.04
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onFinish()
                    }
                }
            }
        }
    }
}
