import SwiftUI

/// Three-lobed fidget spinner with momentum physics.
/// Flick to spin with realistic deceleration and subtle haptic pulses.
struct SpinnerView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var rotation: Double = 0
    @State private var angularVelocity: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var isSpinning = false
    @State private var displayLink: CADisplayLink?
    @State private var lastPulseRotation: Double = 0

    private let diameter: CGFloat = 130
    private let lobeRadius: CGFloat = 28
    private let lobeDistance: CGFloat = 38
    private let friction: Double = 0.985
    private let pulseInterval: Double = 60 // Degrees between haptic pulses

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

    var body: some View {
        ZStack {
            // Base plate (neumorphic)
            basePlate

            // Spinner body
            spinnerBody
                .rotationEffect(.degrees(rotation))

            // Center bearing
            centerBearing
        }
        .frame(width: diameter + 20, height: diameter + 20)
        .contentShape(Circle())
        .gesture(spinGesture)
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Base Plate

    private var basePlate: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        shadowDarkColor.opacity(isDarkMode ? 0.25 : 0.15),
                        surfaceColor,
                        shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                    ],
                    center: UnitPoint(x: 0.6, y: 0.6),
                    startRadius: 20,
                    endRadius: diameter * 0.5
                )
            )
            .frame(width: diameter - 20, height: diameter - 20)
    }

    // MARK: - Spinner Body

    private var spinnerBody: some View {
        ZStack {
            // Three lobes
            ForEach(0..<3, id: \.self) { index in
                spinnerLobe
                    .offset(y: -lobeDistance)
                    .rotationEffect(.degrees(Double(index) * 120))
            }

            // Center connector
            centerConnector
        }
    }

    private var spinnerLobe: some View {
        ZStack {
            // Lobe body (neumorphic raised)
            Circle()
                .fill(surfaceColor)
                .frame(width: lobeRadius * 2, height: lobeRadius * 2)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: 8,
                    x: -4,
                    y: -4
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.55),
                    radius: 8,
                    x: 4,
                    y: 4
                )

            // Inner gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.35),
                            surfaceColor,
                            shadowDarkColor.opacity(0.15)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: lobeRadius
                    )
                )
                .frame(width: lobeRadius * 2 - 4, height: lobeRadius * 2 - 4)

            // Weight indicator (metallic insert)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x888890),
                            Color(hex: 0x606068),
                            Color(hex: 0x707078)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: 14
                    )
                )
                .frame(width: 20, height: 20)

            // Weight highlight
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 6, height: 6)
                .offset(x: -3, y: -3)
                .blur(radius: 1)
        }
    }

    private var centerConnector: some View {
        ZStack {
            // Triangular connector arms
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(surfaceColor)
                    .frame(width: 18, height: lobeDistance + lobeRadius - 10)
                    .offset(y: -(lobeDistance + lobeRadius - 10) / 2 + 12)
                    .rotationEffect(.degrees(Double(index) * 120))
                    .shadow(
                        color: shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.3),
                        radius: 3,
                        x: 2,
                        y: 2
                    )
            }
        }
    }

    // MARK: - Center Bearing

    private var centerBearing: some View {
        ZStack {
            // Outer bearing ring
            Circle()
                .fill(surfaceColor)
                .frame(width: 42, height: 42)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.35 : 0.95),
                    radius: 10,
                    x: -5,
                    y: -5
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.6),
                    radius: 10,
                    x: 5,
                    y: 5
                )

            // Bearing surface
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x909098),
                            Color(hex: 0x686870),
                            Color(hex: 0x787880)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 34, height: 34)

            // Inner race
            Circle()
                .stroke(Color(hex: 0x505058), lineWidth: 2)
                .frame(width: 22, height: 22)

            // Center cap
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xA0A0A8),
                            Color(hex: 0x606068)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)

            // Cap highlight
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 5, height: 5)
                .offset(x: -2, y: -2)
                .blur(radius: 0.5)
        }
    }

    // MARK: - Gesture

    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: (diameter + 20) / 2, y: (diameter + 20) / 2)
                let currentAngle = atan2(
                    value.location.y - center.y,
                    value.location.x - center.x
                ) * 180 / .pi

                if let last = lastAngle {
                    var delta = currentAngle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    rotation += delta
                    angularVelocity = delta
                }

                lastAngle = currentAngle
                stopAnimation()
            }
            .onEnded { _ in
                lastAngle = nil

                // Apply momentum if velocity is significant
                if abs(angularVelocity) > 2 {
                    startMomentum()
                }
            }
    }

    // MARK: - Physics

    private func startMomentum() {
        isSpinning = true
        lastPulseRotation = rotation

        // Use Timer for animation loop
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            // Apply friction
            angularVelocity *= friction

            // Update rotation
            rotation += angularVelocity

            // Haptic pulses during spin
            let rotationDelta = abs(rotation - lastPulseRotation)
            if rotationDelta >= pulseInterval {
                // Pulse intensity based on speed
                let speed = abs(angularVelocity)
                if speed > 5 {
                    hapticEngine.playDetent()
                }
                lastPulseRotation = rotation
            }

            // Stop when velocity is negligible
            if abs(angularVelocity) < 0.1 {
                timer.invalidate()
                isSpinning = false
            }
        }
    }

    private func stopAnimation() {
        isSpinning = false
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        SpinnerView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
