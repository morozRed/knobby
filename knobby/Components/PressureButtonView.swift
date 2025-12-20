import SwiftUI

/// A neumorphic pressure button - button with deepening haptics.
struct PressureButtonView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var isPressed = false
    @State private var pressDepth: CGFloat = 0  // 0 to 1
    @State private var pressTimer: Timer?
    @State private var glowOpacity: Double = 0

    private let frameSize: CGFloat = 100
    private let buttonSize: CGFloat = 65
    private let maxDepth: CGFloat = 4

    // Theme-aware colors
    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
    }

    private var surfaceLightColor: Color {
        themeManager?.surfaceLight ?? KnobbyColors.surfaceLight
    }

    private var surfaceDarkColor: Color {
        themeManager?.surfaceDark ?? KnobbyColors.surfaceDark
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

    // Dynamic tilt properties
    private var tiltX: Double { motionManager.tiltX }
    private var tiltY: Double { motionManager.tiltY }
    private var reduceMotion: Bool { motionManager.reduceMotion }

    // Rim properties for 3D depth effect
    private let rimThickness: CGFloat = 4
    private let rimReveal: CGFloat = 2

    var body: some View {
        ZStack {
            // Neumorphic recessed socket
            socketBase

            // Glow (behind button)
            glowLayer

            // The button
            buttonBody
                .offset(y: pressDepth * maxDepth)
        }
        .frame(width: frameSize, height: frameSize)
        .gesture(pressGesture)
    }

    // MARK: - Socket Base (Inset Neumorphic)

    private var socketBase: some View {
        let shadowOffsets = DynamicShadow.shadowOffsets(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let concaveCenter = DynamicShadow.concaveGradientCenter(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let edgePoints = DynamicShadow.edgeGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        return ZStack {
            // Outer raised ring with dynamic shadows
            Circle()
                .fill(surfaceColor)
                .frame(width: buttonSize + 24, height: buttonSize + 24)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: isDarkMode ? 6 : 10,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.65),
                    radius: isDarkMode ? 6 : 10,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
                )

            // Inset socket (concave) - dynamic gradient center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                            surfaceColor,
                            surfaceLightColor.opacity(isDarkMode ? 0.25 : 0.4)
                        ],
                        center: concaveCenter,
                        startRadius: 0,
                        endRadius: buttonSize * 0.55
                    )
                )
                .frame(width: buttonSize + 8, height: buttonSize + 8)

            // Inner shadow - dynamic edge
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.12 : 0.25)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
                    ),
                    lineWidth: 2
                )
                .frame(width: buttonSize + 4, height: buttonSize + 4)
                .blur(radius: 1)
        }
    }

    // MARK: - Glow

    private var glowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        KnobbyColors.accent.opacity(glowOpacity * 0.5),
                        KnobbyColors.accent.opacity(glowOpacity * 0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: buttonSize * 0.6
                )
            )
            .frame(width: buttonSize + 30, height: buttonSize + 30)
            .blur(radius: 8)
    }

    // MARK: - Button Body

    private var buttonBody: some View {
        let gradientCenter = DynamicShadow.convexGradientCenter(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let rimOffset = DynamicShadow.rimOffset(
            tiltX: tiltX,
            tiltY: tiltY,
            maxReveal: rimReveal,
            reduceMotion: reduceMotion
        )
        let rimGradient = DynamicShadow.rimGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let edgePoints = DynamicShadow.edgeGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let baseHighlightOffset = CGSize(width: -buttonSize * 0.12, height: -buttonSize * 0.18)
        let dynamicHighlight = DynamicShadow.highlightOffset(
            tiltX: tiltX,
            tiltY: tiltY,
            baseOffset: baseHighlightOffset,
            maxShift: 4,
            reduceMotion: reduceMotion
        )

        return ZStack {
            // Button rim (behind button body) - reveals 3D depth
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            KnobbyColors.accentLight.opacity(0.8),
                            KnobbyColors.accent,
                            KnobbyColors.accentDark
                        ],
                        startPoint: rimGradient.start,
                        endPoint: rimGradient.end
                    )
                )
                .frame(width: buttonSize + rimThickness, height: buttonSize + rimThickness)
                .offset(x: rimOffset.width, y: rimOffset.height)

            // Button body - graphite/accent color with dynamic gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            KnobbyColors.accentLight,
                            KnobbyColors.accent,
                            KnobbyColors.accentDark
                        ],
                        center: gradientCenter,
                        startRadius: 0,
                        endRadius: buttonSize * 0.55
                    )
                )
                .frame(width: buttonSize, height: buttonSize)
                .shadow(
                    color: KnobbyColors.accent.opacity(isDarkMode ? 0.3 : 0.5 - Double(pressDepth) * 0.3),
                    radius: 8 - pressDepth * 4,
                    x: 0,
                    y: 4 - pressDepth * 2
                )

            // Top specular highlight - dynamic position
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.65 - Double(pressDepth) * 0.4),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 14
                    )
                )
                .frame(width: 22, height: 12)
                .offset(x: dynamicHighlight.width, y: dynamicHighlight.height)

            // Secondary reflection
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 6, height: 6)
                .offset(x: buttonSize * 0.1, y: buttonSize * 0.15)
                .blur(radius: 1)

            // Edge highlight - dynamic
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear,
                            KnobbyColors.accentDark.opacity(0.3)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
                    ),
                    lineWidth: 1.5
                )
                .frame(width: buttonSize - 2, height: buttonSize - 2)
        }
        .scaleEffect(1 - pressDepth * 0.03)
    }

    // MARK: - Gesture

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    startPress()
                }
            }
            .onEnded { _ in
                endPress()
            }
    }

    private func startPress() {
        isPressed = true
        hapticEngine.playDetent()
        soundEngine.play(.buttonPress)

        withAnimation(.easeOut(duration: 0.08)) {
            pressDepth = 0.4
        }

        pressTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            if pressDepth < 1 {
                withAnimation(.easeOut(duration: 0.08)) {
                    pressDepth = min(pressDepth + 0.12, 1)
                    glowOpacity = Double(pressDepth)
                }
                hapticEngine.playDetent()
            }
        }
    }

    private func endPress() {
        isPressed = false
        pressTimer?.invalidate()
        pressTimer = nil
        soundEngine.play(.buttonRelease)

        withAnimation(.easeOut(duration: 0.3)) {
            pressDepth = 0
            glowOpacity = 0
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        PressureButtonView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
