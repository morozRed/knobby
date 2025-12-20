import SwiftUI

/// A neumorphic joystick - soft socket with ball that springs back.
struct JoystickView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var offset: CGSize = .zero
    @State private var isDragging = false

    private let frameSize: CGFloat = 120
    private let socketSize: CGFloat = 80
    private let ballSize: CGFloat = 48
    private let maxOffset: CGFloat = 20

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

    var body: some View {
        ZStack {
            // Neumorphic recessed socket
            socketBase

            // Ball with shadow
            ball
                .offset(offset)
        }
        .frame(width: frameSize, height: frameSize)
        .gesture(dragGesture)
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
                .frame(width: socketSize + 20, height: socketSize + 20)
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
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.3),
                            surfaceColor,
                            surfaceLightColor.opacity(isDarkMode ? 0.3 : 0.5)
                        ],
                        center: concaveCenter,
                        startRadius: 0,
                        endRadius: socketSize * 0.55
                    )
                )
                .frame(width: socketSize, height: socketSize)

            // Inner shadow for depth - dynamic edge
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
                    ),
                    lineWidth: 3
                )
                .frame(width: socketSize - 4, height: socketSize - 4)
                .blur(radius: 2)
        }
    }

    // MARK: - Ball

    private var ball: some View {
        let gradientCenter = DynamicShadow.convexGradientCenter(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let baseHighlightOffset = CGSize(width: -ballSize * 0.12, height: -ballSize * 0.18)
        let dynamicHighlight = DynamicShadow.highlightOffset(
            tiltX: tiltX,
            tiltY: tiltY,
            baseOffset: baseHighlightOffset,
            maxShift: 4,
            reduceMotion: reduceMotion
        )
        let edgePoints = DynamicShadow.edgeGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        return ZStack {
            // Shadow under ball - shifts with tilt
            Ellipse()
                .fill(shadowDarkColor.opacity(isDragging ? 0.5 : 0.4))
                .frame(width: ballSize * 0.7, height: ballSize * 0.3)
                .blur(radius: 6)
                .offset(
                    x: CGFloat(tiltX) * 4,
                    y: 8 - CGFloat(tiltY) * 2
                )

            // Ball body - graphite/dark color with dynamic gradient
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
                        endRadius: ballSize * 0.55
                    )
                )
                .frame(width: ballSize, height: ballSize)
                .shadow(
                    color: KnobbyColors.accent.opacity(isDarkMode ? 0.3 : 0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )

            // Top specular highlight - dynamic position
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 18, height: 10)
                .offset(x: dynamicHighlight.width, y: dynamicHighlight.height)

            // Secondary reflection
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 6, height: 6)
                .offset(x: ballSize * 0.1, y: ballSize * 0.15)
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
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: ballSize - 2, height: ballSize - 2)
        }
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isDragging)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    hapticEngine.playDetent()
                    soundEngine.play(.joystickMove)
                }

                let proposed = CGSize(
                    width: value.translation.width,
                    height: value.translation.height
                )
                let distance = sqrt(pow(proposed.width, 2) + pow(proposed.height, 2))

                if distance <= maxOffset {
                    offset = proposed
                } else {
                    let scale = maxOffset / distance
                    offset = CGSize(
                        width: proposed.width * scale,
                        height: proposed.height * scale
                    )
                }
            }
            .onEnded { _ in
                isDragging = false
                withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                    offset = .zero
                }
                hapticEngine.playDetent()
                soundEngine.play(.joystickSnap)
            }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        JoystickView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
