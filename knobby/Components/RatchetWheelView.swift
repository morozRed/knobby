import SwiftUI

/// One-way ratcheting wheel mechanism.
/// Rotates freely one direction with satisfying clicks, resists the other.
struct RatchetWheelView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var rotation: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var lastDetent: Int = 0
    @State private var isResisting = false
    @State private var resistanceOffset: Double = 0

    private let diameter: CGFloat = 100
    private let teethCount: Int = 16
    private let detentDegrees: Double = 22.5 // 360 / 16

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
            // Base housing
            housing

            // Ratchet wheel (clipped to housing)
            ratchetWheel
                .rotationEffect(.degrees(rotation + resistanceOffset))
                .clipShape(Circle().scale(0.92))

            // Pawl indicator (inside bounds)
            pawlIndicator

            // Direction arrows (subtle, inside)
            directionArrows
        }
        .frame(width: diameter + 20, height: diameter + 20)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Circle())
        .gesture(rotationGesture)
    }

    // MARK: - Housing

    private var housing: some View {
        ZStack {
            // Outer rim
            Circle()
                .fill(surfaceColor)
                .frame(width: diameter + 16, height: diameter + 16)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: 8,
                    x: -5,
                    y: -5
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.75 : 0.6),
                    radius: 8,
                    x: 5,
                    y: 5
                )

            // Recessed track
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.35 : 0.2),
                            surfaceColor,
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                        ],
                        center: UnitPoint(x: 0.6, y: 0.6),
                        startRadius: 20,
                        endRadius: diameter * 0.52
                    )
                )
                .frame(width: diameter + 6, height: diameter + 6)

            // Inner shadow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                            Color.clear,
                            shadowLightColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: diameter, height: diameter)
                .blur(radius: 1)
        }
    }

    // MARK: - Ratchet Wheel

    private var ratchetWheel: some View {
        ZStack {
            // Main wheel body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x707078),
                            Color(hex: 0x505058),
                            Color(hex: 0x606068)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: diameter * 0.42
                    )
                )
                .frame(width: diameter - 10, height: diameter - 10)

            // Teeth around edge (scaled down to fit)
            ForEach(0..<teethCount, id: \.self) { index in
                tooth(at: index)
            }

            // Center hub
            centerHub

            // Surface texture
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: diameter * 0.35
                    )
                )
                .frame(width: diameter - 14, height: diameter - 14)
        }
    }

    private func tooth(at index: Int) -> some View {
        let angle = Double(index) * detentDegrees
        let toothRadius = diameter / 2 - 8

        return Path { path in
            // Smaller asymmetric tooth
            path.move(to: CGPoint(x: 0, y: -toothRadius))
            path.addLine(to: CGPoint(x: 4, y: -toothRadius + 7))
            path.addLine(to: CGPoint(x: -2, y: -toothRadius + 7))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(hex: 0x808088),
                    Color(hex: 0x404048)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .rotationEffect(.degrees(angle))
    }

    private var centerHub: some View {
        ZStack {
            // Hub body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x808088),
                            Color(hex: 0x505058)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 28, height: 28)

            // Hub highlight
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 7, height: 7)
                .offset(x: -3, y: -3)
                .blur(radius: 1)

            // Center indent
            Circle()
                .fill(Color(hex: 0x303038))
                .frame(width: 8, height: 8)
        }
    }

    // MARK: - Pawl Indicator

    private var pawlIndicator: some View {
        // Small indicator dot on the right edge
        Circle()
            .fill(isResisting ? Color.red.opacity(0.8) : Color.green.opacity(0.7))
            .frame(width: 8, height: 8)
            .shadow(
                color: isResisting ? Color.red.opacity(0.5) : Color.green.opacity(0.5),
                radius: 3
            )
            .offset(x: diameter / 2 - 2)
    }

    // MARK: - Direction Arrows

    private var directionArrows: some View {
        ZStack {
            // Clockwise arrow (green when free)
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(!isResisting ? Color.green.opacity(0.6) : shadowDarkColor.opacity(0.25))
                .offset(x: 0, y: diameter / 2 - 12)

            // Counter-clockwise indicator (red when resisting)
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isResisting ? Color.red.opacity(0.6) : shadowDarkColor.opacity(0.25))
                .offset(x: 0, y: -diameter / 2 + 12)
        }
    }

    // MARK: - Gesture

    private var rotationGesture: some Gesture {
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

                    // Clockwise is positive (free direction)
                    if delta > 0 {
                        // Free rotation clockwise
                        isResisting = false
                        rotation += delta
                        resistanceOffset = 0
                        checkDetent()
                    } else {
                        // Resist counter-clockwise
                        isResisting = true
                        // Small visual feedback of resistance
                        resistanceOffset = delta * 0.15
                        // Haptic resistance feedback
                        if abs(delta) > 1 {
                            hapticEngine.playDetent()
                        }
                    }
                }

                lastAngle = currentAngle
            }
            .onEnded { _ in
                lastAngle = nil
                isResisting = false

                // Snap resistance back
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    resistanceOffset = 0
                }
            }
    }

    private func checkDetent() {
        let currentDetent = Int(floor(rotation / detentDegrees))

        if currentDetent != lastDetent {
            hapticEngine.playDetent()
            soundEngine.play(.knobTick)
            lastDetent = currentDetent
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        RatchetWheelView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
