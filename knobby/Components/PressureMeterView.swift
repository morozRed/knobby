import SwiftUI

/// A compact click counter with 7-segment LCD display and mechanical keycap button.
/// Each press increments the counter. Resets at 999.
struct PressureMeterView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var isPressed = false
    @State private var clickCount: Int = 0

    private let maxClickCount = 999

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
        VStack(spacing: 12) {
            // 7-Segment LCD Counter
            lcdCounter

            // Mechanical Keycap Button
            mechanicalKeycap
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    // MARK: - LCD Counter Display

    private var lcdCounter: some View {
        ZStack {
            // LCD panel background
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: 0x1A1A1C))
                .frame(width: 88, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.7),
                                    Color(hex: 0x3A3A3C).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            // 3-digit display
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { digitIndex in
                    let digit = getDigit(at: digitIndex)
                    SevenSegmentDigit(digit: digit)
                }
            }
        }
    }

    private func getDigit(at index: Int) -> Int {
        let paddedString = String(format: "%03d", clickCount)
        let digitChar = paddedString[paddedString.index(paddedString.startIndex, offsetBy: index)]
        return Int(String(digitChar)) ?? 0
    }

    // MARK: - Mechanical Keycap

    private var mechanicalKeycap: some View {
        let keycapSize: CGFloat = 56
        let pressDepth: CGFloat = isPressed ? 4 : 0
        let housingHeight: CGFloat = 12

        return ZStack {
            // Switch housing/plate (visible base)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: isDarkMode ? 0x2A2A2E : 0xC0C0C4),
                            Color(hex: isDarkMode ? 0x1E1E22 : 0xA8A8AC)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: keycapSize + 8, height: keycapSize + 8)
                .overlay(
                    // Housing inner shadow
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(isDarkMode ? 0.5 : 0.3),
                                    Color.white.opacity(isDarkMode ? 0.1 : 0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )

            // Stem well (dark recessed area)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: isDarkMode ? 0x0C0C0E : 0x606064))
                .frame(width: keycapSize + 2, height: keycapSize + 2)

            // Keycap group (moves when pressed)
            VStack(spacing: 0) {
                // Keycap top surface
                ZStack {
                    // Main keycap body with 3D sides
                    keycapBody(size: keycapSize)

                    // Top legend/texture (subtle dish)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(isDarkMode ? 0.08 : 0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: keycapSize * 0.4
                            )
                        )
                        .frame(width: keycapSize - 12, height: keycapSize - 12)
                        .offset(y: -2)
                }
            }
            .offset(y: -housingHeight / 2 + pressDepth)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: keycapSize + 12, height: keycapSize + housingHeight + 8)
        .gesture(pressGesture)
    }

    private func keycapBody(size: CGFloat) -> some View {
        let baseColor = isDarkMode ? Color(hex: 0x4A4A52) : Color(hex: 0xE8E8EC)
        let sideColor = isDarkMode ? Color(hex: 0x38383C) : Color(hex: 0xD0D0D4)
        let darkSide = isDarkMode ? Color(hex: 0x28282C) : Color(hex: 0xB8B8BC)

        return ZStack {
            // Bottom edge (creates depth)
            RoundedRectangle(cornerRadius: 6)
                .fill(darkSide)
                .frame(width: size, height: size)
                .offset(y: 4)

            // Right edge
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [sideColor, darkSide],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size, height: size)
                .offset(x: 2, y: 2)

            // Main top surface
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor,
                            sideColor
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size - 2, height: size - 2)
                .overlay(
                    // Top edge highlight
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDarkMode ? 0.2 : 0.6),
                                    Color.clear,
                                    Color.black.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Subtle concave dish effect
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(isDarkMode ? 0.15 : 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.35
                    )
                )
                .frame(width: size - 16, height: size - 20)
                .offset(y: 2)
        }
        .shadow(
            color: shadowDarkColor.opacity(isPressed ? 0.2 : 0.5),
            radius: isPressed ? 2 : 6,
            x: 0,
            y: isPressed ? 1 : 4
        )
    }

    // MARK: - Gesture

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    pressDown()
                }
            }
            .onEnded { _ in
                releaseKey()
            }
    }

    private func pressDown() {
        isPressed = true
        hapticEngine.playDetent()
        soundEngine.play(.buttonPress)

        // Increment click counter
        clickCount = (clickCount + 1) % (maxClickCount + 1)
    }

    private func releaseKey() {
        isPressed = false
        soundEngine.play(.buttonRelease)
    }
}

// MARK: - Seven Segment Digit (Compact)

struct SevenSegmentDigit: View {
    let digit: Int

    // Compact segment dimensions
    private let digitWidth: CGFloat = 18
    private let digitHeight: CGFloat = 26
    private let segmentThickness: CGFloat = 3
    private let skewAngle: CGFloat = -0.08

    // LCD colors
    private let litColor = Color(hex: 0xE8E4D9)
    private let ghostColor = Color(hex: 0x252527)

    // Segment mapping for digits 0-9
    private let segmentMap: [[Bool]] = [
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    var body: some View {
        let segments = segmentMap[digit]

        return ZStack {
            // Ghost segments
            segmentPaths(activeSegments: Array(repeating: false, count: 7))
            // Lit segments
            segmentPaths(activeSegments: segments)
        }
        .frame(width: digitWidth, height: digitHeight)
        .transformEffect(CGAffineTransform(a: 1, b: 0, c: skewAngle, d: 1, tx: 0, ty: 0))
    }

    @ViewBuilder
    private func segmentPaths(activeSegments: [Bool]) -> some View {
        let halfThickness = segmentThickness / 2
        let hSegmentWidth: CGFloat = 8
        let vSegmentHeight = (digitHeight - segmentThickness * 3) / 2

        let topY: CGFloat = 0
        let middleY: CGFloat = digitHeight / 2 - halfThickness
        let bottomY: CGFloat = digitHeight - segmentThickness
        let rightX: CGFloat = digitWidth - segmentThickness

        ZStack {
            // Top (0)
            HSegment(isLit: activeSegments[0], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: topY + halfThickness)

            // Top-right (1)
            VSegment(isLit: activeSegments[1], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: rightX + halfThickness, y: topY + segmentThickness + vSegmentHeight / 2)

            // Bottom-right (2)
            VSegment(isLit: activeSegments[2], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: rightX + halfThickness, y: middleY + segmentThickness + vSegmentHeight / 2)

            // Bottom (3)
            HSegment(isLit: activeSegments[3], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: bottomY + halfThickness)

            // Bottom-left (4)
            VSegment(isLit: activeSegments[4], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: halfThickness, y: middleY + segmentThickness + vSegmentHeight / 2)

            // Top-left (5)
            VSegment(isLit: activeSegments[5], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: halfThickness, y: topY + segmentThickness + vSegmentHeight / 2)

            // Middle (6)
            HSegment(isLit: activeSegments[6], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: middleY + halfThickness)
        }
    }
}

// MARK: - Segment Views

struct HSegment: View {
    let isLit: Bool
    let litColor: Color
    let ghostColor: Color

    var body: some View {
        HorizontalSegment()
            .fill(isLit ? litColor : ghostColor)
            .shadow(color: isLit ? litColor.opacity(0.7) : .clear, radius: isLit ? 2 : 0)
    }
}

struct VSegment: View {
    let isLit: Bool
    let litColor: Color
    let ghostColor: Color

    var body: some View {
        VerticalSegment()
            .fill(isLit ? litColor : ghostColor)
            .shadow(color: isLit ? litColor.opacity(0.7) : .clear, radius: isLit ? 2 : 0)
    }
}

// MARK: - Segment Shapes

struct HorizontalSegment: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        let inset = h * 0.35

        path.move(to: CGPoint(x: inset, y: 0))
        path.addLine(to: CGPoint(x: w - inset, y: 0))
        path.addLine(to: CGPoint(x: w, y: h / 2))
        path.addLine(to: CGPoint(x: w - inset, y: h))
        path.addLine(to: CGPoint(x: inset, y: h))
        path.addLine(to: CGPoint(x: 0, y: h / 2))
        path.closeSubpath()

        return path
    }
}

struct VerticalSegment: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        let inset = w * 0.35

        path.move(to: CGPoint(x: w / 2, y: 0))
        path.addLine(to: CGPoint(x: w, y: inset))
        path.addLine(to: CGPoint(x: w, y: h - inset))
        path.addLine(to: CGPoint(x: w / 2, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - inset))
        path.addLine(to: CGPoint(x: 0, y: inset))
        path.closeSubpath()

        return path
    }
}

// MARK: - Color Extension

extension Color {
    func interpolate(to other: Color, progress: CGFloat) -> Color {
        let clampedProgress = max(0, min(1, progress))
        return Color(
            red: lerp(from: self.components.red, to: other.components.red, progress: clampedProgress),
            green: lerp(from: self.components.green, to: other.components.green, progress: clampedProgress),
            blue: lerp(from: self.components.blue, to: other.components.blue, progress: clampedProgress)
        )
    }

    private func lerp(from: Double, to: Double, progress: CGFloat) -> Double {
        from + (to - from) * Double(progress)
    }

    var components: (red: Double, green: Double, blue: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue))
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        PressureMeterView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
