import SwiftUI

/// A premium mechanical keyboard keycap with satisfying thock sound.
/// Toggles between two states, swapping icon and text on each press.
struct MechanicalKeycapView: View {
    var motionManager: MotionManager?
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    // Toggle states - customize these for different key functions
    var primaryIcon: String = "moon.fill"
    var primaryText: String = "SLEEP"
    var secondaryIcon: String = "sun.max.fill"
    var secondaryText: String = "WAKE"
    var accentColor: Color = Color(hex: 0x7C5CFF)  // Keycap LED color

    @State private var isPressed = false
    @State private var isToggled = false
    @State private var pressDepth: CGFloat = 0
    @State private var wobbleOffset: CGFloat = 0

    // Keycap dimensions (1u size)
    private let keycapSize: CGFloat = 56
    private let keycapHeight: CGFloat = 12  // Visual height of the keycap
    private let cornerRadius: CGFloat = 6
    private let maxTravel: CGFloat = 4  // Key travel distance

    // Theme colors
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

    // Dynamic tilt properties
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

    // Keycap colors
    private var keycapColor: Color {
        isDarkMode ? Color(hex: 0x3A3A3C) : Color(hex: 0xE8E8E8)
    }

    private var keycapTopColor: Color {
        isDarkMode ? Color(hex: 0x4A4A4C) : Color(hex: 0xF5F5F5)
    }

    private var keycapSideColor: Color {
        isDarkMode ? Color(hex: 0x2A2A2C) : Color(hex: 0xD0D0D0)
    }

    private var legendColor: Color {
        isDarkMode ? Color(hex: 0xB0B0B0) : Color(hex: 0x4A4A4A)
    }

    var body: some View {
        ZStack {
            // LED underglow (beneath everything)
            ledUnderglow

            // Switch housing / plate
            switchHousing

            // The keycap itself
            keycap
        }
        .frame(width: keycapSize + 20, height: keycapSize + 24)  // Room for layers + shadows
        .contentShape(Rectangle())
        .gesture(pressGesture)
    }

    // MARK: - LED Underglow

    private var ledUnderglow: some View {
        RoundedRectangle(cornerRadius: cornerRadius + 4)
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(isPressed ? 0.8 : (isToggled ? 0.5 : 0.15)),
                        accentColor.opacity(isPressed ? 0.4 : (isToggled ? 0.2 : 0.0)),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: keycapSize * 0.8
                )
            )
            .frame(width: keycapSize + 20, height: keycapSize + 20)
            .blur(radius: 12)
            .offset(y: 4)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .animation(.easeOut(duration: 0.3), value: isToggled)
    }

    // MARK: - Switch Housing

    private var switchHousing: some View {
        ZStack {
            // Plate cutout (dark recess)
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .fill(Color.black.opacity(isDarkMode ? 0.6 : 0.4))
                .frame(width: keycapSize + 4, height: keycapSize + 4)
                .offset(y: 6)

            // Switch housing visible inside
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: isDarkMode ? 0x1A1A1C : 0x2A2A2C),
                            Color(hex: isDarkMode ? 0x252527 : 0x3A3A3C)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: keycapSize - 4, height: keycapSize - 4)
                .offset(y: 6 + pressDepth)

            // Stem cross (visible when key is pressed down)
            stemCross
                .opacity(Double(pressDepth / maxTravel) * 0.6)
        }
    }

    private var stemCross: some View {
        ZStack {
            // Vertical bar
            RoundedRectangle(cornerRadius: 0.5)
                .fill(accentColor.opacity(0.8))
                .frame(width: 1.5, height: 8)

            // Horizontal bar
            RoundedRectangle(cornerRadius: 0.5)
                .fill(accentColor.opacity(0.8))
                .frame(width: 5, height: 1.5)
        }
        .offset(y: 6)
    }

    // MARK: - Keycap (Proper 3D Layered Design)

    // 3D keycap depth - how thick the keycap is from bottom to top
    private let keycapDepth: CGFloat = 8
    // How much each layer tapers inward (creates beveled edge)
    private let taperPerLayer: CGFloat = 2
    // Parallax multiplier for tilt response
    private let parallaxStrength: CGFloat = 4

    private var keycap: some View {
        // Calculate parallax offset based on tilt
        // This creates the illusion of physical depth when tilting
        let parallaxX = reduceMotion ? 0 : CGFloat(tiltX) * parallaxStrength * 2.5
        let parallaxY = reduceMotion ? 0 : CGFloat(-tiltY) * parallaxStrength * 2.5

        // Light direction affects which edges appear lit vs shadowed
        let lightAngleX = reduceMotion ? 0.3 : 0.3 - tiltX * 0.5
        let lightAngleY = reduceMotion ? 0.3 : 0.3 + tiltY * 0.5

        return ZStack {
            // === LAYER 1: Bottom/Base layer (largest, creates visible sides) ===
            keycapBaseLayer(
                lightAngleX: lightAngleX,
                lightAngleY: lightAngleY
            )
            .offset(x: parallaxX * 0.8, y: parallaxY * 0.8)

            // === LAYER 2: Middle body layer ===
            keycapMiddleLayer(
                lightAngleX: lightAngleX,
                lightAngleY: lightAngleY
            )
            .offset(
                x: parallaxX * 0.4,
                y: -keycapDepth * 0.4 + parallaxY * 0.4
            )

            // === LAYER 3: Top surface (smallest, the dished top) ===
            keycapTopLayer(
                lightAngleX: lightAngleX,
                lightAngleY: lightAngleY
            )
            .offset(
                x: parallaxX * 0.15,
                y: -keycapDepth * 0.75 + parallaxY * 0.15
            )

            // === LEGEND ===
            keycapLegend
                .offset(
                    x: parallaxX * 0.1,
                    y: -keycapDepth * 0.75 + parallaxY * 0.1
                )
        }
        .offset(y: pressDepth)
        .offset(x: wobbleOffset)
        .animation(.interpolatingSpring(stiffness: 800, damping: 15), value: pressDepth)
        .animation(.interpolatingSpring(stiffness: 1000, damping: 10), value: wobbleOffset)
    }

    // MARK: - Base Layer (Shows the physical sides)

    private func keycapBaseLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        // Base is slightly larger - the visible rim IS the "side" of the keycap
        let baseSize = keycapSize + taperPerLayer * 2

        // Colors for the base layer - darker, showing physical depth
        let baseColor = isDarkMode ? Color(hex: 0x252528) : Color(hex: 0xB8B8BC)
        let baseLitEdge = isDarkMode ? Color(hex: 0x404045) : Color(hex: 0xD0D0D4)
        let baseShadowEdge = isDarkMode ? Color(hex: 0x18181A) : Color(hex: 0x909094)

        return ZStack {
            // Main base shape with directional lighting gradient
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .fill(
                    LinearGradient(
                        colors: [baseLitEdge, baseColor, baseShadowEdge],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    )
                )
                .frame(width: baseSize, height: baseSize)

            // Inner shadow to create depth between base and middle layer
            RoundedRectangle(cornerRadius: cornerRadius + 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isDarkMode ? 0.4 : 0.2),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.3)
                        ],
                        startPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY),
                        endPoint: UnitPoint(x: lightAngleX, y: lightAngleY)
                    ),
                    lineWidth: 2
                )
                .frame(width: baseSize - 2, height: baseSize - 2)
        }
        .shadow(
            color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.4),
            radius: 3,
            x: CGFloat(1 - lightAngleX) * 3,
            y: 3
        )
    }

    // MARK: - Middle Layer (Main body with bevel transition)

    private func keycapMiddleLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        let middleSize = keycapSize + taperPerLayer * 0.5

        // Middle body colors
        let bodyColor = keycapColor
        let bodyLitEdge = isDarkMode ? Color(hex: 0x505055) : Color(hex: 0xE8E8EC)
        let bodyShadowEdge = isDarkMode ? Color(hex: 0x2A2A2E) : Color(hex: 0xC0C0C4)

        return ZStack {
            // Main body with lit/shadow gradient
            RoundedRectangle(cornerRadius: cornerRadius + 1)
                .fill(
                    LinearGradient(
                        colors: [bodyLitEdge, bodyColor, bodyShadowEdge],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    )
                )
                .frame(width: middleSize, height: middleSize)

            // Subtle top edge highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.2 : 0.5),
                            Color.clear,
                            Color.black.opacity(isDarkMode ? 0.2 : 0.1)
                        ],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    ),
                    lineWidth: 1.5
                )
                .frame(width: middleSize - 1, height: middleSize - 1)
        }
    }

    // MARK: - Top Layer (Dished surface)

    private func keycapTopLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        let topSize = keycapSize - taperPerLayer

        return ZStack {
            // Top surface
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .fill(keycapTopColor)
                .frame(width: topSize, height: topSize)

            // Dish effect (concave center)
            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.15 : 0.1),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                        ],
                        center: UnitPoint(
                            x: 0.65 + (reduceMotion ? 0 : tiltX * 0.3),
                            y: 0.65 - (reduceMotion ? 0 : tiltY * 0.3)
                        ),
                        startRadius: 0,
                        endRadius: topSize * 0.5
                    )
                )
                .frame(width: topSize - 4, height: topSize - 4)

            // Top edge ring highlight
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.3 : 0.7),
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.3),
                            shadowDarkColor.opacity(isDarkMode ? 0.3 : 0.2),
                            shadowDarkColor.opacity(isDarkMode ? 0.15 : 0.1)
                        ],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    ),
                    lineWidth: 1
                )
                .frame(width: topSize - 2, height: topSize - 2)
        }
    }

    private var keycapLegend: some View {
        VStack(spacing: 2) {
            // Icon
            Image(systemName: isToggled ? secondaryIcon : primaryIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isToggled ? accentColor : legendColor)
                .shadow(
                    color: isToggled ? accentColor.opacity(0.5) : Color.clear,
                    radius: 4
                )

            // Text
            Text(isToggled ? secondaryText : primaryText)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(isToggled ? accentColor.opacity(0.9) : legendColor.opacity(0.8))
                .tracking(1)
        }
        .animation(.easeInOut(duration: 0.15), value: isToggled)
    }

    // MARK: - Press Gesture

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isPressed {
                    // Initial press
                    isPressed = true
                    pressDepth = maxTravel

                    // Add slight random wobble for realism
                    wobbleOffset = CGFloat.random(in: -0.5...0.5)

                    // Haptic and sound
                    hapticEngine.playDetent()
                    soundEngine.play(.keyThock)
                }
            }
            .onEnded { _ in
                isPressed = false
                pressDepth = 0
                wobbleOffset = 0

                // Toggle state
                isToggled.toggle()

                // Release haptic and sound
                hapticEngine.playDetent()
                soundEngine.play(.keyClack)
            }
    }
}

// MARK: - Preview

#Preview("Mechanical Keycap") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        VStack(spacing: 30) {
            MechanicalKeycapView(
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                primaryIcon: "moon.fill",
                primaryText: "SLEEP",
                secondaryIcon: "sun.max.fill",
                secondaryText: "WAKE",
                accentColor: Color(hex: 0x7C5CFF)
            )

            MechanicalKeycapView(
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                primaryIcon: "speaker.wave.2.fill",
                primaryText: "MUTE",
                secondaryIcon: "speaker.slash.fill",
                secondaryText: "UNMUTE",
                accentColor: Color(hex: 0xFF5C5C)
            )

            MechanicalKeycapView(
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                primaryIcon: "bolt.fill",
                primaryText: "TURBO",
                secondaryIcon: "bolt.slash.fill",
                secondaryText: "NORMAL",
                accentColor: Color(hex: 0x5CFF7C)
            )
        }
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color(hex: 0x1C1C1E).ignoresSafeArea()

        MechanicalKeycapView(
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine(),
            themeManager: {
                let tm = ThemeManager()
                // Simulate dark mode
                return tm
            }(),
            primaryIcon: "moon.fill",
            primaryText: "SLEEP",
            secondaryIcon: "sun.max.fill",
            secondaryText: "WAKE",
            accentColor: Color(hex: 0x7C5CFF)
        )
    }
    .preferredColorScheme(.dark)
}
