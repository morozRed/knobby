import SwiftUI

/// Combination lock dial with numbered positions.
/// Rotate to feel satisfying number-to-number clicks.
struct ComboLockView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var rotation: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var currentNumber: Int = 0
    @State private var lastNumber: Int = 0
    @State private var dialDirection: Int = 0 // 1 = CW, -1 = CCW

    private let diameter: CGFloat = 130
    private let numberCount: Int = 40
    private let degreesPerNumber: Double = 9 // 360 / 40

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
            // Lock body
            lockBody

            // Dial
            dial
                .rotationEffect(.degrees(rotation))

            // Indicator arrow
            indicator

            // Current number display
            numberDisplay
        }
        .frame(width: diameter + 30, height: diameter + 50)
        .contentShape(Circle())
        .gesture(rotationGesture)
    }

    // MARK: - Lock Body

    private var lockBody: some View {
        ZStack {
            // Outer case
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x404048),
                            Color(hex: 0x282830),
                            Color(hex: 0x383840)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter + 24, height: diameter + 24)
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.6),
                    radius: 12,
                    x: 6,
                    y: 6
                )

            // Inner bezel
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x505058),
                            Color(hex: 0x202028)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: diameter + 12, height: diameter + 12)

            // Dial recess
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x181820),
                            Color(hex: 0x101018)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter + 4, height: diameter + 4)
        }
        .offset(y: -10)
    }

    // MARK: - Dial

    private var dial: some View {
        ZStack {
            // Dial body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xE8E8EC),
                            Color(hex: 0xD0D0D4),
                            Color(hex: 0xC0C0C4)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: diameter * 0.5
                    )
                )
                .frame(width: diameter - 4, height: diameter - 4)

            // Number ring
            numberRing

            // Center hub
            centerHub

            // Knurled edge
            knurledEdge
        }
        .offset(y: -10)
    }

    private var numberRing: some View {
        ForEach(0..<numberCount, id: \.self) { num in
            let angle = Double(num) * degreesPerNumber
            let displayNum = num == 0 ? 0 : numberCount - num

            VStack {
                if num % 5 == 0 {
                    // Major tick with number
                    Text("\(displayNum)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x404048))
                        .rotationEffect(.degrees(-angle))
                } else {
                    // Minor tick
                    Rectangle()
                        .fill(Color(hex: 0x808088))
                        .frame(width: 1, height: 4)
                }
            }
            .offset(y: -diameter / 2 + 18)
            .rotationEffect(.degrees(angle))
        }
    }

    private var centerHub: some View {
        ZStack {
            // Hub body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x909098),
                            Color(hex: 0x606068),
                            Color(hex: 0x707078)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 36, height: 36)

            // Hub ring
            Circle()
                .stroke(Color(hex: 0x404048), lineWidth: 2)
                .frame(width: 30, height: 30)

            // Hub highlight
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
                .offset(x: -5, y: -5)
                .blur(radius: 1)
        }
    }

    private var knurledEdge: some View {
        ForEach(0..<60, id: \.self) { i in
            Rectangle()
                .fill(Color(hex: 0xA0A0A8))
                .frame(width: 1.5, height: 6)
                .offset(y: -diameter / 2 + 3)
                .rotationEffect(.degrees(Double(i) * 6))
        }
    }

    // MARK: - Indicator

    private var indicator: some View {
        VStack {
            // Arrow pointing down at dial
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: -8, y: -14))
                path.addLine(to: CGPoint(x: 8, y: -14))
                path.closeSubpath()
            }
            .fill(Color.red)
            .shadow(color: Color.red.opacity(0.5), radius: 3, y: 1)

            Spacer()
        }
        .frame(height: diameter / 2 + 25)
        .offset(y: -diameter / 2 - 5)
    }

    // MARK: - Number Display

    private var numberDisplay: some View {
        VStack {
            Spacer()

            // Display current number
            Text("\(currentNumber)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isDarkMode ? .white : Color(hex: 0x404048))
                .frame(width: 30, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(surfaceColor)
                        .shadow(
                            color: shadowDarkColor.opacity(0.3),
                            radius: 2,
                            x: 1,
                            y: 1
                        )
                )

            // Direction indicator
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(dialDirection < 0 ? KnobbyColors.accent : shadowDarkColor.opacity(0.3))
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(dialDirection > 0 ? KnobbyColors.accent : shadowDarkColor.opacity(0.3))
            }
            .font(.system(size: 10))
        }
        .frame(height: diameter + 40)
    }

    // MARK: - Gesture

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let center = CGPoint(x: (diameter + 30) / 2, y: (diameter + 50) / 2 - 10)
                let currentAngle = atan2(
                    value.location.y - center.y,
                    value.location.x - center.x
                ) * 180 / .pi

                if let last = lastAngle {
                    var delta = currentAngle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    rotation += delta

                    // Track direction
                    if delta > 0.5 {
                        dialDirection = 1
                    } else if delta < -0.5 {
                        dialDirection = -1
                    }

                    // Calculate current number (inverted for correct feel)
                    let normalizedRotation = (-rotation).truncatingRemainder(dividingBy: 360)
                    let adjustedRotation = normalizedRotation < 0 ? normalizedRotation + 360 : normalizedRotation
                    currentNumber = Int(adjustedRotation / degreesPerNumber) % numberCount

                    // Haptic on number change
                    if currentNumber != lastNumber {
                        hapticEngine.playDetent()
                        soundEngine.play(.knobTick)
                        lastNumber = currentNumber
                    }
                }

                lastAngle = currentAngle
            }
            .onEnded { _ in
                lastAngle = nil
                dialDirection = 0
            }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        ComboLockView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
