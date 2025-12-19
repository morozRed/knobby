import SwiftUI

/// iPod-style click wheel with circular scroll gesture and tactile detents.
/// Provides continuous scrolling feedback with satisfying clicks.
struct ClickWheelView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var scrollAngle: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var lastDetent: Int = 0
    @State private var isScrolling = false
    @State private var activeZone: Int? = nil

    private let outerDiameter: CGFloat = 130
    private let innerDiameter: CGFloat = 50
    private let detentCount: Int = 32

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
            // Outer wheel ring (neumorphic inset)
            wheelRing

            // Touch zones (N, E, S, W)
            touchZones

            // Center button
            centerButton

            // Scroll indicator arc
            scrollIndicator
        }
        .frame(width: outerDiameter + 20, height: outerDiameter + 20)
        .contentShape(Circle())
        .gesture(scrollGesture)
    }

    // MARK: - Wheel Ring

    private var wheelRing: some View {
        ZStack {
            // Outer raised edge
            Circle()
                .fill(surfaceColor)
                .frame(width: outerDiameter + 10, height: outerDiameter + 10)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: isDarkMode ? 8 : 12,
                    x: isDarkMode ? -5 : -8,
                    y: isDarkMode ? -5 : -8
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.75 : 0.6),
                    radius: isDarkMode ? 8 : 12,
                    x: isDarkMode ? 5 : 8,
                    y: isDarkMode ? 5 : 8
                )

            // Inset track
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.35 : 0.2),
                            surfaceColor,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        center: UnitPoint(x: 0.65, y: 0.65),
                        startRadius: 30,
                        endRadius: outerDiameter * 0.5
                    )
                )
                .frame(width: outerDiameter, height: outerDiameter)

            // Inner edge shadow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: outerDiameter - 4, height: outerDiameter - 4)
                .blur(radius: 1)

            // Subtle detent marks
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * 30
                Circle()
                    .fill(shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25))
                    .frame(width: 3, height: 3)
                    .offset(y: -(outerDiameter / 2 - 12))
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    // MARK: - Touch Zones

    private var touchZones: some View {
        ZStack {
            // Forward zone (top)
            zoneIndicator(index: 0, symbol: "chevron.up", offset: CGSize(width: 0, height: -38))

            // Skip forward (right)
            zoneIndicator(index: 1, symbol: "forward.end.fill", offset: CGSize(width: 38, height: 0))

            // Back zone (bottom)
            zoneIndicator(index: 2, symbol: "chevron.down", offset: CGSize(width: 0, height: 38))

            // Skip back (left)
            zoneIndicator(index: 3, symbol: "backward.end.fill", offset: CGSize(width: -38, height: 0))
        }
    }

    private func zoneIndicator(index: Int, symbol: String, offset: CGSize) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(
                activeZone == index
                    ? KnobbyColors.accent
                    : shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4)
            )
            .offset(offset)
            .scaleEffect(activeZone == index ? 1.2 : 1.0)
            .animation(.easeOut(duration: 0.1), value: activeZone)
    }

    // MARK: - Center Button

    private var centerButton: some View {
        ZStack {
            // Raised center button
            Circle()
                .fill(surfaceColor)
                .frame(width: innerDiameter, height: innerDiameter)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: 6,
                    x: -4,
                    y: -4
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.5),
                    radius: 6,
                    x: 4,
                    y: 4
                )

            // 3D gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.4),
                            surfaceColor,
                            shadowDarkColor.opacity(0.15)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: innerDiameter * 0.5
                    )
                )
                .frame(width: innerDiameter - 2, height: innerDiameter - 2)

            // Edge highlight
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.3 : 0.6),
                            Color.clear,
                            shadowDarkColor.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: innerDiameter - 2, height: innerDiameter - 2)
        }
        .onTapGesture {
            hapticEngine.playDetent()
            soundEngine.play(.buttonPress)
        }
    }

    // MARK: - Scroll Indicator

    private var scrollIndicator: some View {
        Circle()
            .trim(from: 0, to: 0.08)
            .stroke(
                KnobbyColors.accent.opacity(isScrolling ? 0.8 : 0.3),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: outerDiameter - 16, height: outerDiameter - 16)
            .rotationEffect(.degrees(scrollAngle - 90))
    }

    // MARK: - Gesture

    private var scrollGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: (outerDiameter + 20) / 2, y: (outerDiameter + 20) / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let distance = sqrt(dx * dx + dy * dy)

                // Check if in wheel area (between inner and outer)
                let innerRadius = innerDiameter / 2 + 5
                let outerRadius = outerDiameter / 2

                if distance > innerRadius && distance < outerRadius {
                    isScrolling = true
                    let currentAngle = atan2(dy, dx) * 180 / .pi

                    if let last = lastAngle {
                        var delta = currentAngle - last
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }

                        scrollAngle += delta
                        checkDetent()
                    }

                    lastAngle = currentAngle

                    // Determine active zone
                    let normalizedAngle = (currentAngle + 360).truncatingRemainder(dividingBy: 360)
                    if normalizedAngle > 315 || normalizedAngle <= 45 {
                        activeZone = 1 // Right
                    } else if normalizedAngle > 45 && normalizedAngle <= 135 {
                        activeZone = 2 // Bottom
                    } else if normalizedAngle > 135 && normalizedAngle <= 225 {
                        activeZone = 3 // Left
                    } else {
                        activeZone = 0 // Top
                    }
                } else if distance <= innerRadius {
                    // In center button area
                    activeZone = nil
                }
            }
            .onEnded { _ in
                isScrolling = false
                lastAngle = nil
                activeZone = nil
            }
    }

    private func checkDetent() {
        let detentDegrees = 360.0 / Double(detentCount)
        let currentDetent = Int(floor(scrollAngle / detentDegrees))

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
        ClickWheelView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
