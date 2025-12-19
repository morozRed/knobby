import SwiftUI

/// A premium mechanical keyboard keycap with satisfying thock sound.
/// Toggles between two states, swapping icon and text on each press.
struct MechanicalKeycapView: View {
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
        .frame(width: keycapSize + 16, height: keycapSize + 24)
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

    // MARK: - Keycap

    private var keycap: some View {
        ZStack {
            // Keycap base (bottom edge - creates 3D depth)
            keycapBase

            // Keycap body (the main visible part)
            keycapBody

            // Top surface with dish
            keycapTop

            // Legend (icon + text)
            keycapLegend
        }
        .offset(y: -keycapHeight / 2 + pressDepth)
        .offset(x: wobbleOffset)
        .animation(.interpolatingSpring(stiffness: 800, damping: 15), value: pressDepth)
        .animation(.interpolatingSpring(stiffness: 1000, damping: 10), value: wobbleOffset)
    }

    private var keycapBase: some View {
        RoundedRectangle(cornerRadius: cornerRadius + 1)
            .fill(keycapSideColor)
            .frame(width: keycapSize, height: keycapSize)
            .shadow(
                color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.5),
                radius: 4,
                x: 0,
                y: 4
            )
    }

    private var keycapBody: some View {
        ZStack {
            // Main body with side gradient (shows depth)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            keycapColor,
                            keycapSideColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: keycapSize - 2, height: keycapSize - 2)

            // Side highlight (left edge catch light)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.4),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: keycapSize - 2, height: keycapSize - 2)
        }
        .offset(y: -keycapHeight / 3)
    }

    private var keycapTop: some View {
        ZStack {
            // Top surface base
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .fill(keycapTopColor)
                .frame(width: keycapSize - 6, height: keycapSize - 6)

            // Dish effect (subtle concave scoop)
            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.12 : 0.08),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.08 : 0.15)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.6),
                        startRadius: 0,
                        endRadius: keycapSize * 0.45
                    )
                )
                .frame(width: keycapSize - 8, height: keycapSize - 8)

            // Top edge highlight
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.25 : 0.6),
                            Color.clear,
                            shadowDarkColor.opacity(isDarkMode ? 0.2 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: keycapSize - 6, height: keycapSize - 6)
        }
        .offset(y: -keycapHeight * 0.7)
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
        .offset(y: -keycapHeight * 0.7)
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
