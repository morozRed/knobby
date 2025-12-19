import SwiftUI

/// Vintage aviation-style flip switch with protective cover.
/// Provides a dramatic flip gesture with satisfying mechanical snap.
struct FlipSwitchView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var isOn = false
    @State private var coverOpen = false
    @State private var switchAngle: Double = 0
    @State private var coverAngle: Double = 0

    private let baseWidth: CGFloat = 60
    private let baseHeight: CGFloat = 100
    private let switchHeight: CGFloat = 45

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
            // Base plate (neumorphic recessed)
            basePlate

            // Switch mechanism
            switchMechanism
                .rotation3DEffect(
                    .degrees(switchAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.5
                )

            // Safety cover
            safetyCover
                .rotation3DEffect(
                    .degrees(coverAngle),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .bottom,
                    perspective: 0.5
                )

            // Status indicator
            statusIndicator
        }
        .frame(width: baseWidth + 30, height: baseHeight + 20)
        .gesture(flipGesture)
    }

    // MARK: - Base Plate

    private var basePlate: some View {
        ZStack {
            // Outer raised border
            RoundedRectangle(cornerRadius: 12)
                .fill(surfaceColor)
                .frame(width: baseWidth + 16, height: baseHeight)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: 10,
                    x: -6,
                    y: -6
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.75 : 0.6),
                    radius: 10,
                    x: 6,
                    y: 6
                )

            // Recessed channel for switch
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                            surfaceColor,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: baseWidth - 8, height: baseHeight - 20)
                .offset(y: -5)

            // Inner shadow
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.3),
                            Color.clear,
                            shadowLightColor.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: baseWidth - 10, height: baseHeight - 22)
                .offset(y: -5)
                .blur(radius: 1)
        }
    }

    // MARK: - Switch Mechanism

    private var switchMechanism: some View {
        ZStack {
            // Switch lever
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xC0C0C8),
                            Color(hex: 0x888890),
                            Color(hex: 0xA0A0A8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 18, height: switchHeight)
                .overlay(
                    // Metallic highlights
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.clear,
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )

            // Grip ridges
            VStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 12, height: 1)
                }
            }
            .offset(y: -switchHeight * 0.15)

            // Top cap
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xD0D0D8),
                            Color(hex: 0x909098)
                        ],
                        center: UnitPoint(x: 0.3, y: 0.3),
                        startRadius: 0,
                        endRadius: 12
                    )
                )
                .frame(width: 22, height: 14)
                .offset(y: -switchHeight / 2 + 5)
        }
        .offset(y: -10)
    }

    // MARK: - Safety Cover

    private var safetyCover: some View {
        ZStack {
            // Cover body (red warning style)
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xCC3333),
                            Color(hex: 0x991111),
                            Color(hex: 0xAA2222)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: baseWidth - 16, height: switchHeight + 20)

            // Cover stripes (warning pattern)
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: baseWidth - 28, height: 2)
                }
            }

            // Cover hinge
            Rectangle()
                .fill(Color(hex: 0x666666))
                .frame(width: baseWidth - 16, height: 6)
                .offset(y: (switchHeight + 20) / 2 - 3)

            // Edge highlights
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear,
                            Color.black.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: baseWidth - 17, height: switchHeight + 19)
        }
        .offset(y: -20)
        .opacity(coverOpen ? 0.3 : 1)
        .allowsHitTesting(!coverOpen)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        isOn ? Color.green : Color.red.opacity(0.3),
                        isOn ? Color.green.opacity(0.6) : Color.red.opacity(0.15)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 6
                )
            )
            .frame(width: 10, height: 10)
            .shadow(
                color: isOn ? Color.green.opacity(0.6) : Color.clear,
                radius: 4
            )
            .offset(y: baseHeight / 2 - 12)
    }

    // MARK: - Gesture

    private var flipGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let dragY = value.translation.height

                if !coverOpen {
                    // Opening cover
                    let coverProgress = min(max(-dragY / 60, 0), 1)
                    coverAngle = -coverProgress * 120
                } else {
                    // Flipping switch
                    let switchProgress = Double(-dragY / 40)
                    if isOn {
                        switchAngle = min(max(30.0 + switchProgress * 30.0, 0), 30)
                    } else {
                        switchAngle = min(max(switchProgress * 30.0, -30), 30)
                    }
                }
            }
            .onEnded { value in
                let dragY = value.translation.height

                if !coverOpen {
                    // Determine if cover should open
                    if -dragY > 30 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            coverOpen = true
                            coverAngle = -120
                        }
                        hapticEngine.playDetent()
                        soundEngine.play(.switchClick)
                    } else {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            coverAngle = 0
                        }
                    }
                } else {
                    // Determine if switch should toggle
                    if abs(dragY) > 20 {
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                            isOn.toggle()
                            switchAngle = isOn ? 30 : -30
                        }
                        hapticEngine.playDetent()
                        soundEngine.play(.switchClick)

                        // Snap to final position
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                                switchAngle = isOn ? 25 : -25
                            }
                        }
                    } else {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                            switchAngle = isOn ? 25 : -25
                        }
                    }

                    // Auto-close cover after a delay if switch is off
                    if !isOn {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if !isOn {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                    coverOpen = false
                                    coverAngle = 0
                                }
                                hapticEngine.playDetent()
                            }
                        }
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        FlipSwitchView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
