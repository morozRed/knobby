import SwiftUI
import Combine

/// Custom status bar with industrial instrument panel aesthetic.
/// Positioned in the "ears" beside the Dynamic Island like iOS system indicators.
/// Features: 7-segment LCD time, LED dot battery, embossed rivet signal.
struct CustomStatusBarView: View {
    var themeManager: ThemeManager
    var motionManager: MotionManager

    // Real device data
    @State private var currentTime = Date()
    @State private var batteryLevel: Float = UIDevice.current.batteryLevel
    @State private var batteryState: UIDevice.BatteryState = UIDevice.current.batteryState

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Theme-aware colors
    private var surfaceColor: Color { themeManager.surface }
    private var surfaceLightColor: Color { themeManager.surfaceLight }
    private var surfaceDarkColor: Color { themeManager.surfaceDark }
    private var shadowLightColor: Color { themeManager.shadowLight }
    private var shadowDarkColor: Color { themeManager.shadowDark }
    private var isDarkMode: Bool { themeManager.isDarkMode }

    var body: some View {
        // Indicators positioned in the "ears" beside Dynamic Island
        // On Dynamic Island devices: indicators sit at ~17pt from top, centered with the island
        // The parent view handles safe area, we just position horizontally
        HStack(alignment: .center) {
            // Left side: Time (LCD display)
            lcdTimeDisplay

            Spacer()

            // Right side: Signal + Battery
            HStack(spacing: 8) {
                batteryDots
            }
        }
        .padding(.horizontal, 40)
        .frame(height: 34) // Height of the indicator row
        .onAppear {
            UIDevice.current.isBatteryMonitoringEnabled = true
            updateBatteryStatus()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            updateBatteryStatus()
        }
    }

    private func updateBatteryStatus() {
        batteryLevel = UIDevice.current.batteryLevel
        batteryState = UIDevice.current.batteryState
    }

    // MARK: - LCD Time Display (7-Segment Style)

    private var lcdTimeDisplay: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let timeString = formatter.string(from: currentTime)

        // Parse time into digits
        let digits = parseTimeDigits(timeString)

        return ZStack {
            // LCD panel housing - recessed into surface
            lcdPanelHousing

            // 7-segment digits
            HStack(spacing: 1) {
                // Hour digit(s)
                if let hourTens = digits.hourTens {
                    StatusBarSevenSegmentDigit(digit: hourTens)
                }
                StatusBarSevenSegmentDigit(digit: digits.hourOnes)

                // Colon separator
                colonSeparator

                // Minute digits
                StatusBarSevenSegmentDigit(digit: digits.minuteTens)
                StatusBarSevenSegmentDigit(digit: digits.minuteOnes)
            }
            .padding(.horizontal, 4)
        }
    }

    private var lcdPanelHousing: some View {
        ZStack {
            // Outer bezel - raised neumorphic
            RoundedRectangle(cornerRadius: 5)
                .fill(surfaceColor)
                .frame(width: 58, height: 24)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.15 : 0.7),
                    radius: 2,
                    x: -1,
                    y: -1
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4),
                    radius: 2,
                    x: 1,
                    y: 1
                )

            // Inner LCD panel - dark recessed
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: 0x1A1A1C))
                .frame(width: 52, height: 20)
                .overlay(
                    // Inner shadow for depth
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.6),
                                    Color(hex: 0x3A3A3C).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    private var colonSeparator: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(Color(hex: 0xE8E4D9))
                .frame(width: 2, height: 2)
                .shadow(color: Color(hex: 0xE8E4D9).opacity(0.5), radius: 1)
            Circle()
                .fill(Color(hex: 0xE8E4D9))
                .frame(width: 2, height: 2)
                .shadow(color: Color(hex: 0xE8E4D9).opacity(0.5), radius: 1)
        }
        .padding(.horizontal, 1)
    }

    private func parseTimeDigits(_ timeString: String) -> (hourTens: Int?, hourOnes: Int, minuteTens: Int, minuteOnes: Int) {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return (nil, 0, 0, 0)
        }

        let hourTens = hour >= 10 ? hour / 10 : nil
        let hourOnes = hour % 10
        let minuteTens = minute / 10
        let minuteOnes = minute % 10

        return (hourTens, hourOnes, minuteTens, minuteOnes)
    }

    // MARK: - Signal Rivets (Embossed Metal Studs)

    private var signalRivets: some View {
        // Simulate signal strength (4 = full)
        let signalStrength = 4

        return HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                rivetIndicator(isActive: index < signalStrength)
            }
        }
    }

    private func rivetIndicator(isActive: Bool) -> some View {
        let rivetSize: CGFloat = 6

        return ZStack {
            // Recessed socket
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: isDarkMode ? 0x1A1A1C : 0x606064),
                            surfaceColor.opacity(0.9)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: rivetSize
                    )
                )
                .frame(width: rivetSize + 3, height: rivetSize + 3)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.25),
                                    shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )

            // Raised rivet head - graphite when active, muted when inactive
            if isActive {
                // Active: dark graphite with sheen
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0x5A5A64),
                                Color(hex: 0x4A4A52),
                                Color(hex: 0x3A3A42)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: rivetSize * 0.6
                        )
                    )
                    .frame(width: rivetSize, height: rivetSize)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 1,
                        x: 0.5,
                        y: 0.5
                    )

                // Top specular highlight
                Circle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 2, height: 2)
                    .offset(x: -1, y: -1)
            } else {
                // Inactive: very muted, almost invisible
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0x2A2A2C),
                                Color(hex: 0x1E1E20)
                            ],
                            center: UnitPoint(x: 0.4, y: 0.4),
                            startRadius: 0,
                            endRadius: rivetSize * 0.6
                        )
                    )
                    .frame(width: rivetSize, height: rivetSize)
            }
        }
    }

    // MARK: - Battery Dots (LED Indicator Lights)

    private var batteryDots: some View {
        let level = batteryLevel < 0 ? 1.0 : CGFloat(batteryLevel)
        let isCharging = batteryState == .charging || batteryState == .full
        let activeDots = Int(ceil(level * 5)) // 1-5 dots based on level

        return HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { index in
                recessedLedWell(
                    index: index,
                    isActive: index < activeDots,
                    level: level,
                    isCharging: isCharging
                )
            }
        }
    }

    private func recessedLedWell(index: Int, isActive: Bool, level: CGFloat, isCharging: Bool) -> some View {
        let wellSize: CGFloat = 10
        let ledSize: CGFloat = 5

        // Determine LED color based on battery level
        let ledColor: Color = {
            if isCharging {
                return Color(hex: 0x4CAF50) // Green when charging
            } else if level <= 0.2 {
                return Color(hex: 0xE53935) // Red - critical
            } else if level <= 0.6 {
                return Color(hex: 0xFFB300) // Amber - medium
            } else {
                return Color(hex: 0x43A047) // Green - good
            }
        }()

        return ZStack {
            // LAYER 1: Outer raised rim (neumorphic - light top-left, dark bottom-right)
            Circle()
                .fill(surfaceColor)
                .frame(width: wellSize, height: wellSize)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.12 : 0.6),
                    radius: 1.5,
                    x: -1,
                    y: -1
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35),
                    radius: 1.5,
                    x: 1,
                    y: 1
                )

            // LAYER 2: Inner well - carved into surface (inverted shadows for concave)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: isDarkMode ? 0x0E0E10 : 0x505054), // Deep center
                            Color(hex: isDarkMode ? 0x18181A : 0x606064), // Mid
                            Color(hex: isDarkMode ? 0x202024 : 0x707074)  // Edge
                        ],
                        center: UnitPoint(x: 0.6, y: 0.6), // Light comes from top-left, so shadow center is bottom-right
                        startRadius: 0,
                        endRadius: wellSize * 0.45
                    )
                )
                .frame(width: wellSize - 2, height: wellSize - 2)

            // LAYER 3: Inner shadow ring (dark at top-left for inset look)
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isDarkMode ? 0.5 : 0.3), // Dark at top-left (inner shadow)
                            Color.black.opacity(isDarkMode ? 0.3 : 0.15),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.05 : 0.1) // Subtle light at bottom-right
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: wellSize - 3, height: wellSize - 3)

            // LAYER 4: The LED itself
            if isActive {
                // Outer glow halo - wide and soft
                Circle()
                    .fill(ledColor.opacity(0.25))
                    .frame(width: ledSize + 10, height: ledSize + 10)
                    .blur(radius: 4)

                // Mid glow - fills the well
                Circle()
                    .fill(ledColor.opacity(0.5))
                    .frame(width: ledSize + 5, height: ledSize + 5)
                    .blur(radius: 2.5)

                // Inner glow - bright ring around LED
                Circle()
                    .fill(ledColor.opacity(0.7))
                    .frame(width: ledSize + 2, height: ledSize + 2)
                    .blur(radius: 1)

                // LED - solid color with subtle depth gradient (no white)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ledColor,
                                ledColor.opacity(0.92),
                                ledColor.opacity(0.8)
                            ],
                            center: UnitPoint(x: 0.45, y: 0.45),
                            startRadius: 0,
                            endRadius: ledSize * 0.55
                        )
                    )
                    .frame(width: ledSize, height: ledSize)
            } else {
                // Unlit LED - dark at bottom of well
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0x1A1A1C),
                                Color(hex: 0x121214)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: ledSize * 0.5
                        )
                    )
                    .frame(width: ledSize, height: ledSize)
            }
        }
        .frame(width: wellSize, height: wellSize)
    }
}

// MARK: - Compact 7-Segment Digit for Status Bar

struct StatusBarSevenSegmentDigit: View {
    let digit: Int

    // Compact dimensions for status bar
    private let digitWidth: CGFloat = 10
    private let digitHeight: CGFloat = 14
    private let segmentThickness: CGFloat = 1.8
    private let skewAngle: CGFloat = -0.06

    // LCD colors - matching PressureMeterView
    private let litColor = Color(hex: 0xE8E4D9)
    private let ghostColor = Color(hex: 0x252527)

    // Segment mapping for 0-9
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
        let segments = digit >= 0 && digit <= 9 ? segmentMap[digit] : segmentMap[0]

        return ZStack {
            // Ghost segments (always visible, dim)
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
        let hSegmentWidth: CGFloat = 5
        let vSegmentHeight = (digitHeight - segmentThickness * 3) / 2

        let topY: CGFloat = 0
        let middleY: CGFloat = digitHeight / 2 - halfThickness
        let bottomY: CGFloat = digitHeight - segmentThickness
        let rightX: CGFloat = digitWidth - segmentThickness

        ZStack {
            // Top (0)
            StatusBarHSegment(isLit: activeSegments[0], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: topY + halfThickness)

            // Top-right (1)
            StatusBarVSegment(isLit: activeSegments[1], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: rightX + halfThickness, y: topY + segmentThickness + vSegmentHeight / 2)

            // Bottom-right (2)
            StatusBarVSegment(isLit: activeSegments[2], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: rightX + halfThickness, y: middleY + segmentThickness + vSegmentHeight / 2)

            // Bottom (3)
            StatusBarHSegment(isLit: activeSegments[3], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: bottomY + halfThickness)

            // Bottom-left (4)
            StatusBarVSegment(isLit: activeSegments[4], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: halfThickness, y: middleY + segmentThickness + vSegmentHeight / 2)

            // Top-left (5)
            StatusBarVSegment(isLit: activeSegments[5], litColor: litColor, ghostColor: ghostColor)
                .frame(width: segmentThickness, height: vSegmentHeight)
                .position(x: halfThickness, y: topY + segmentThickness + vSegmentHeight / 2)

            // Middle (6)
            StatusBarHSegment(isLit: activeSegments[6], litColor: litColor, ghostColor: ghostColor)
                .frame(width: hSegmentWidth, height: segmentThickness)
                .position(x: digitWidth / 2, y: middleY + halfThickness)
        }
    }
}

// MARK: - Status Bar Segment Shapes

struct StatusBarHSegment: View {
    let isLit: Bool
    let litColor: Color
    let ghostColor: Color

    var body: some View {
        StatusBarHorizontalSegmentShape()
            .fill(isLit ? litColor : ghostColor)
            .shadow(color: isLit ? litColor.opacity(0.6) : .clear, radius: isLit ? 1 : 0)
    }
}

struct StatusBarVSegment: View {
    let isLit: Bool
    let litColor: Color
    let ghostColor: Color

    var body: some View {
        StatusBarVerticalSegmentShape()
            .fill(isLit ? litColor : ghostColor)
            .shadow(color: isLit ? litColor.opacity(0.6) : .clear, radius: isLit ? 1 : 0)
    }
}

struct StatusBarHorizontalSegmentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        let inset = h * 0.3

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

struct StatusBarVerticalSegmentShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let h = rect.height
        let w = rect.width
        let inset = w * 0.3

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

// MARK: - Preview

#Preview {
    ZStack {
        KnobbyColors.surface
            .ignoresSafeArea()

        VStack(spacing: 0) {
            CustomStatusBarView(
                themeManager: ThemeManager(),
                motionManager: MotionManager()
            )
            .padding(.top, 17) // Simulate Dynamic Island ear position
            Spacer()
        }
    }
    .statusBarHidden()
}
