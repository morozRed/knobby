import SwiftUI

struct KnobView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    // Rotation state
    @State private var rotationAngle: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var velocity: Double = 0
    @State private var lastDetent: Int = 0

    private let diameter: CGFloat = 140
    private let frameSize: CGFloat = 170
    private let tickCount: Int = 24

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

    var body: some View {
        ZStack {
            // Neumorphic knob body (raised from surface)
            knobBody

            // Tick marks around edge
            tickMarks
                .rotationEffect(.degrees(rotationAngle))

            // Indicator dot
            indicatorDot
                .rotationEffect(.degrees(rotationAngle))

            // Top highlight
            topHighlight
        }
        .frame(width: frameSize, height: frameSize)
        .contentShape(Circle())
        .gesture(rotationGesture)
        .onAppear {
            hapticEngine.prepare()
        }
    }

    // MARK: - Knob Body (Neumorphic)

    private var knobBody: some View {
        ZStack {
            // Main knob circle with neumorphic shadows
            Circle()
                .fill(surfaceColor)
                .frame(width: diameter, height: diameter)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: isDarkMode ? 10 : 14,
                    x: isDarkMode ? -6 : -10,
                    y: isDarkMode ? -6 : -10
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.7),
                    radius: isDarkMode ? 10 : 14,
                    x: isDarkMode ? 6 : 10,
                    y: isDarkMode ? 6 : 10
                )

            // Inner soft gradient for 3D effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            surfaceLightColor,
                            surfaceColor,
                            surfaceDarkColor.opacity(0.5)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter - 4, height: diameter - 4)

            // Subtle edge highlight
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.3 : 0.6),
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2),
                            shadowDarkColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: diameter - 2, height: diameter - 2)
        }
    }

    // MARK: - Tick Marks

    private var tickMarks: some View {
        ForEach(0..<tickCount, id: \.self) { index in
            let angle = Double(index) * (360.0 / Double(tickCount))

            RoundedRectangle(cornerRadius: 1)
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4))
                .frame(width: 2, height: 8)
                .offset(y: -diameter / 2 + 10)
                .rotationEffect(.degrees(angle))
        }
    }

    // MARK: - Indicator Dot

    private var indicatorDot: some View {
        ZStack {
            // Glow
            Circle()
                .fill(KnobbyColors.accent.opacity(isDarkMode ? 0.5 : 0.3))
                .frame(width: 16, height: 16)
                .blur(radius: 4)

            // Dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            KnobbyColors.accentLight,
                            KnobbyColors.accent,
                            KnobbyColors.accentDark
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 10, height: 10)

            // Dot highlight
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 4, height: 4)
                .offset(x: -1.5, y: -1.5)
        }
        .offset(y: -diameter / 2 + 25)
    }

    // MARK: - Top Highlight

    private var topHighlight: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        shadowLightColor.opacity(isDarkMode ? 0.15 : 0.4),
                        shadowLightColor.opacity(isDarkMode ? 0.05 : 0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 30
                )
            )
            .frame(width: 50, height: 20)
            .offset(x: -diameter * 0.15, y: -diameter * 0.2)
            .blur(radius: 2)
            .allowsHitTesting(false)
    }

    // MARK: - Gesture

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: frameSize / 2, y: frameSize / 2)

                let currentAngle = atan2(
                    value.location.y - center.y,
                    value.location.x - center.x
                ) * 180 / .pi

                if let last = lastAngle {
                    var delta = currentAngle - last

                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    rotationAngle += delta
                    velocity = delta

                    checkDetent()
                }

                lastAngle = currentAngle
            }
            .onEnded { _ in
                lastAngle = nil
                applyMomentum()
            }
    }

    private func checkDetent() {
        let detentDegrees = KnobbyHaptics.rotationDegreePerDetent
        let currentDetent = Int(floor(rotationAngle / detentDegrees))

        if currentDetent != lastDetent {
            hapticEngine.playDetent()
            soundEngine.play(.knobTick)
            lastDetent = currentDetent
        }
    }

    private func applyMomentum() {
        guard abs(velocity) > 2 else { return }

        withAnimation(.easeOut(duration: 0.4)) {
            rotationAngle += velocity * 2.5
        }

        let startDetent = lastDetent
        let endRotation = rotationAngle + velocity * 2.5
        let endDetent = Int(floor(endRotation / KnobbyHaptics.rotationDegreePerDetent))
        let detentsCrossed = abs(endDetent - startDetent)

        for i in 0..<min(detentsCrossed, 3) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                self.hapticEngine.playDetent()
            }
        }

        lastDetent = endDetent
    }
}

#Preview {
    ZStack {
        KnobbyColors.surfaceMid
            .ignoresSafeArea()

        KnobView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
