import SwiftUI

/// Gentle pulsing orb for calming focus.
/// Touch to sync with the rhythm or let it breathe on its own.
struct BreathingOrbView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var breathPhase: Double = 0 // 0 to 1
    @State private var isExpanding = true
    @State private var isTouching = false
    @State private var glowIntensity: Double = 0.3
    @State private var breathTimer: Timer?

    private let baseSize: CGFloat = 70
    private let breathCycleDuration: Double = 4.0 // Full inhale-exhale

    // Theme-aware colors
    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
    }

    private var shadowLightColor: Color {
        themeManager?.shadowLight ?? KnobbyColors.shadowLight
    }

    private var shadowDarkColor: Color {
        themeManager?.shadowDark ?? KnobbyColors.shadowDark
    }

    private var isDarkMode: Bool {
        themeManager?.isDarkMode ?? false
    }

    // Orb color - calming teal/cyan
    private var orbColor: Color {
        Color(hex: isDarkMode ? 0x4A9BA8 : 0x5AB8C8)
    }

    private var orbColorDark: Color {
        Color(hex: isDarkMode ? 0x2A6B78 : 0x3A8898)
    }

    private var orbColorLight: Color {
        Color(hex: isDarkMode ? 0x6ACBD8 : 0x8AE8F8)
    }

    // Current size based on breath phase
    private var currentSize: CGFloat {
        let minScale: CGFloat = 0.85
        let maxScale: CGFloat = 1.15
        let scale = minScale + (maxScale - minScale) * breathPhase
        return baseSize * scale
    }

    var body: some View {
        ZStack {
            // Outer glow rings
            outerGlow

            // Main orb
            orb

            // Inner light
            innerLight

            // Touch indicator
            if isTouching {
                touchRing
            }
        }
        .frame(width: baseSize + 50, height: baseSize + 50)
        .contentShape(Circle())
        .gesture(touchGesture)
        .onAppear {
            startBreathing()
        }
        .onDisappear {
            breathTimer?.invalidate()
        }
    }

    // MARK: - Outer Glow

    private var outerGlow: some View {
        ZStack {
            // Distant glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            orbColor.opacity(glowIntensity * 0.3),
                            orbColor.opacity(glowIntensity * 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: baseSize * 0.4,
                        endRadius: baseSize * 0.9
                    )
                )
                .frame(width: currentSize + 40, height: currentSize + 40)
                .blur(radius: 10)

            // Close glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            orbColor.opacity(glowIntensity * 0.5),
                            orbColor.opacity(glowIntensity * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: baseSize * 0.3,
                        endRadius: baseSize * 0.6
                    )
                )
                .frame(width: currentSize + 20, height: currentSize + 20)
                .blur(radius: 6)
        }
    }

    // MARK: - Orb

    private var orb: some View {
        ZStack {
            // Base orb with 3D gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            orbColorLight,
                            orbColor,
                            orbColorDark
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: currentSize * 0.55
                    )
                )
                .frame(width: currentSize, height: currentSize)

            // Subsurface scattering effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15 + glowIntensity * 0.1),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: currentSize * 0.4
                    )
                )
                .frame(width: currentSize, height: currentSize)

            // Edge definition
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            orbColorLight.opacity(0.6),
                            Color.clear,
                            orbColorDark.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: currentSize - 2, height: currentSize - 2)

            // Primary specular highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 10
                    )
                )
                .frame(width: 16, height: 10)
                .offset(x: -currentSize * 0.18, y: -currentSize * 0.22)

            // Secondary highlight
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 6, height: 6)
                .offset(x: currentSize * 0.12, y: currentSize * 0.18)
                .blur(radius: 1)
        }
        .shadow(
            color: orbColor.opacity(glowIntensity * 0.6),
            radius: 15 + CGFloat(glowIntensity) * 10,
            x: 0,
            y: 5
        )
    }

    // MARK: - Inner Light

    private var innerLight: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(glowIntensity * 0.4),
                        orbColorLight.opacity(glowIntensity * 0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: currentSize * 0.3
                )
            )
            .frame(width: currentSize * 0.5, height: currentSize * 0.5)
            .blur(radius: 3)
    }

    // MARK: - Touch Ring

    private var touchRing: some View {
        Circle()
            .stroke(
                orbColorLight.opacity(0.6),
                style: StrokeStyle(lineWidth: 2, dash: [4, 4])
            )
            .frame(width: currentSize + 16, height: currentSize + 16)
            .rotationEffect(.degrees(breathPhase * 360))
    }

    // MARK: - Gesture

    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isTouching {
                    isTouching = true
                    // Sync to user's rhythm
                    hapticEngine.playDetent()
                }
            }
            .onEnded { _ in
                isTouching = false
            }
    }

    // MARK: - Breathing Animation

    private func startBreathing() {
        breathTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            let phaseSpeed = 1.0 / (breathCycleDuration * 60.0) // Phase change per frame

            if isExpanding {
                breathPhase += phaseSpeed
                if breathPhase >= 1.0 {
                    breathPhase = 1.0
                    isExpanding = false

                    // Gentle haptic at peak
                    if !isTouching {
                        hapticEngine.playDetent()
                    }
                }
            } else {
                breathPhase -= phaseSpeed
                if breathPhase <= 0.0 {
                    breathPhase = 0.0
                    isExpanding = true

                    // Gentle haptic at trough
                    if !isTouching {
                        hapticEngine.playDetent()
                    }
                }
            }

            // Glow follows breath with slight lag
            withAnimation(.easeInOut(duration: 0.3)) {
                glowIntensity = 0.3 + breathPhase * 0.5
            }
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        BreathingOrbView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
