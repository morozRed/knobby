import SwiftUI

/// Weighted trackball with elastic resistance and realistic 3D lighting.
/// Roll in any direction with satisfying physical resistance. Lighting responds to device tilt.
struct RollerBallView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var ballOffset: CGSize = .zero
    @State private var velocity: CGSize = .zero
    @State private var isDragging = false
    @State private var lastHapticDistance: CGFloat = 0

    private let socketDiameter: CGFloat = 100
    private let ballDiameter: CGFloat = 70
    private let maxOffset: CGFloat = 12
    private let elasticity: CGFloat = 0.15
    private let hapticThreshold: CGFloat = 8

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

    // Dynamic light position based on device tilt
    private var lightX: CGFloat {
        0.35 - CGFloat(motionManager.tiltX) * 0.2
    }

    private var lightY: CGFloat {
        0.35 + CGFloat(motionManager.tiltY) * 0.2
    }

    var body: some View {
        ZStack {
            // Socket (recessed)
            socket

            // Ball with tilt-responsive lighting
            ball
                .offset(ballOffset)
        }
        .frame(width: socketDiameter + 20, height: socketDiameter + 20)
        .contentShape(Circle())
        .gesture(dragGesture)
    }

    // MARK: - Socket

    private var socket: some View {
        let shadowOffsets = DynamicShadow.shadowOffsets(
            tiltX: motionManager.tiltX,
            tiltY: motionManager.tiltY,
            reduceMotion: motionManager.reduceMotion
        )

        return ZStack {
            // Outer raised rim with dynamic shadows
            Circle()
                .fill(surfaceColor)
                .frame(width: socketDiameter + 12, height: socketDiameter + 12)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: 10,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.75 : 0.6),
                    radius: 10,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
                )

            // Recessed bowl with tilt-responsive shading
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35),
                            shadowDarkColor.opacity(isDarkMode ? 0.3 : 0.2),
                            surfaceColor
                        ],
                        center: UnitPoint(
                            x: 0.5 + CGFloat(motionManager.tiltX) * 0.15,
                            y: 0.5 - CGFloat(motionManager.tiltY) * 0.15
                        ),
                        startRadius: 0,
                        endRadius: socketDiameter * 0.5
                    )
                )
                .frame(width: socketDiameter, height: socketDiameter)

            // Inner shadow ring with tilt response
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.25)
                        ],
                        startPoint: UnitPoint(
                            x: 0.2 - CGFloat(motionManager.tiltX) * 0.2,
                            y: 0.2 + CGFloat(motionManager.tiltY) * 0.2
                        ),
                        endPoint: UnitPoint(
                            x: 0.8 - CGFloat(motionManager.tiltX) * 0.2,
                            y: 0.8 + CGFloat(motionManager.tiltY) * 0.2
                        )
                    ),
                    lineWidth: 4
                )
                .frame(width: socketDiameter - 6, height: socketDiameter - 6)
                .blur(radius: 2)

            // Socket depth indicator
            Circle()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.25 : 0.15))
                .frame(width: ballDiameter + 4, height: ballDiameter + 4)
                .blur(radius: 3)
        }
    }

    // MARK: - Ball

    private var ball: some View {
        ZStack {
            // Ball shadow (on socket floor) - moves with ball and tilt
            Ellipse()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35))
                .frame(width: ballDiameter - 4, height: ballDiameter * 0.3)
                .offset(
                    x: ballOffset.width * 0.3 + CGFloat(motionManager.tiltX) * 8,
                    y: ballDiameter * 0.35 + ballOffset.height * 0.2 - CGFloat(motionManager.tiltY) * 4
                )
                .blur(radius: 6)

            // Main ball body with dynamic lighting
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xEE5555), // Bright red
                            Color(hex: 0xCC3333), // Mid red
                            Color(hex: 0x991111)  // Dark red
                        ],
                        center: UnitPoint(x: lightX, y: lightY),
                        startRadius: 0,
                        endRadius: ballDiameter * 0.55
                    )
                )
                .frame(width: ballDiameter, height: ballDiameter)

            // Subsurface glow (responds to light)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color(hex: 0xFF8888).opacity(0.08),
                            Color.clear
                        ],
                        center: UnitPoint(x: lightX - 0.05, y: lightY - 0.05),
                        startRadius: 0,
                        endRadius: ballDiameter * 0.4
                    )
                )
                .frame(width: ballDiameter, height: ballDiameter)

            // Primary specular highlight (moves with tilt)
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
                .frame(width: 16, height: 9)
                .offset(
                    x: -ballDiameter * (0.18 + CGFloat(motionManager.tiltX) * 0.08),
                    y: -ballDiameter * (0.22 - CGFloat(motionManager.tiltY) * 0.08)
                )

            // Secondary reflection (opposite side)
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 5, height: 5)
                .offset(
                    x: ballDiameter * (0.15 - CGFloat(motionManager.tiltX) * 0.05),
                    y: ballDiameter * (0.18 + CGFloat(motionManager.tiltY) * 0.05)
                )
                .blur(radius: 1)

            // Edge rim light (dynamic)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.45),
                            Color.clear,
                            Color.black.opacity(0.25)
                        ],
                        startPoint: UnitPoint(x: lightX - 0.15, y: lightY - 0.15),
                        endPoint: UnitPoint(x: 1.0 - lightX + 0.15, y: 1.0 - lightY + 0.15)
                    ),
                    lineWidth: 2
                )
                .frame(width: ballDiameter - 2, height: ballDiameter - 2)

            // Ambient occlusion at bottom
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: ballDiameter, height: ballDiameter)
                .mask(
                    LinearGradient(
                        colors: [Color.clear, Color.black],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
        }
        .scaleEffect(isDragging ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isDragging)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true

                // Calculate offset with elastic constraint
                let rawOffset = value.translation
                let distance = sqrt(rawOffset.width * rawOffset.width + rawOffset.height * rawOffset.height)

                if distance > maxOffset {
                    // Apply elastic resistance beyond max
                    let scale = maxOffset + (distance - maxOffset) * elasticity
                    let normalizedX = rawOffset.width / distance
                    let normalizedY = rawOffset.height / distance
                    ballOffset = CGSize(
                        width: normalizedX * scale,
                        height: normalizedY * scale
                    )
                } else {
                    ballOffset = rawOffset
                }

                // Haptic feedback based on distance traveled
                let totalDistance = sqrt(
                    pow(ballOffset.width, 2) + pow(ballOffset.height, 2)
                )
                if totalDistance - lastHapticDistance > hapticThreshold {
                    hapticEngine.playDetent()
                    soundEngine.play(.joystickMove)
                    lastHapticDistance = totalDistance
                } else if lastHapticDistance - totalDistance > hapticThreshold {
                    lastHapticDistance = totalDistance
                }
            }
            .onEnded { value in
                isDragging = false
                velocity = CGSize(
                    width: value.velocity.width * 0.01,
                    height: value.velocity.height * 0.01
                )
                lastHapticDistance = 0

                // Spring back to center with inertia
                applySpringBack()
            }
    }

    private func applySpringBack() {
        // Animate back to center with spring physics
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            ballOffset = .zero
        }

        // Play subtle haptic on return
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            hapticEngine.playDetent()
            soundEngine.play(.joystickSnap)
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        RollerBallView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
