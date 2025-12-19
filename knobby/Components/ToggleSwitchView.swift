import SwiftUI

/// A neumorphic pill toggle - soft sliding switch with indicator.
struct ToggleSwitchView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var isOn = false

    private let frameWidth: CGFloat = 90
    private let frameHeight: CGFloat = 120
    private let trackWidth: CGFloat = 36
    private let trackHeight: CGFloat = 80
    private let thumbSize: CGFloat = 30

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
            // Neumorphic track (inset)
            trackBase

            // Sliding thumb
            thumb
                .offset(y: isOn ? -trackHeight / 2 + thumbSize / 2 + 6 : trackHeight / 2 - thumbSize / 2 - 6)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        }
        .frame(width: frameWidth, height: frameHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSwitch()
        }
    }

    // MARK: - Track Base (Inset Neumorphic)

    private var trackBase: some View {
        ZStack {
            // Outer raised area
            Capsule()
                .fill(surfaceColor)
                .frame(width: trackWidth + 16, height: trackHeight + 16)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: isDarkMode ? 6 : 10,
                    x: isDarkMode ? -4 : -6,
                    y: isDarkMode ? -4 : -6
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.65),
                    radius: isDarkMode ? 6 : 10,
                    x: isDarkMode ? 4 : 6,
                    y: isDarkMode ? 4 : 6
                )

            // Inset track
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.3),
                            surfaceColor,
                            surfaceLightColor.opacity(isDarkMode ? 0.3 : 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: trackWidth, height: trackHeight)

            // Inner shadow
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: trackWidth - 2, height: trackHeight - 2)
                .blur(radius: 1)

            // ON indicator (top)
            Circle()
                .fill(isOn ? KnobbyColors.accent : shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.2))
                .frame(width: 6, height: 6)
                .offset(y: -trackHeight / 2 + 14)
                .shadow(
                    color: isOn ? KnobbyColors.accent.opacity(0.5) : Color.clear,
                    radius: isOn ? 4 : 0
                )

            // OFF indicator (bottom)
            Circle()
                .fill(!isOn ? KnobbyColors.accent.opacity(0.6) : shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.2))
                .frame(width: 6, height: 6)
                .offset(y: trackHeight / 2 - 14)
        }
    }

    // MARK: - Thumb

    private var thumb: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35))
                .frame(width: thumbSize * 0.8, height: thumbSize * 0.3)
                .blur(radius: 4)
                .offset(y: 6)

            // Thumb body - raised neumorphic
            Circle()
                .fill(surfaceColor)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: isDarkMode ? 4 : 6,
                    x: isDarkMode ? -3 : -4,
                    y: isDarkMode ? -3 : -4
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.65),
                    radius: isDarkMode ? 4 : 6,
                    x: isDarkMode ? 3 : 4,
                    y: isDarkMode ? 3 : 4
                )

            // Inner gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            surfaceLightColor,
                            surfaceColor,
                            surfaceDarkColor.opacity(0.3)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: thumbSize * 0.5
                    )
                )
                .frame(width: thumbSize - 4, height: thumbSize - 4)

            // Edge highlight
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.25 : 0.5),
                            Color.clear,
                            shadowDarkColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: thumbSize - 2, height: thumbSize - 2)

            // Center dot
            Circle()
                .fill(isOn ? KnobbyColors.accent : shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.2))
                .frame(width: 8, height: 8)
                .shadow(
                    color: isOn ? KnobbyColors.accent.opacity(0.4) : Color.clear,
                    radius: isOn ? 3 : 0
                )
        }
    }

    private func toggleSwitch() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isOn.toggle()
        }
        hapticEngine.playDetent()
        soundEngine.play(.switchClick)
    }
}

// MARK: - Helpers

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        ToggleSwitchView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
