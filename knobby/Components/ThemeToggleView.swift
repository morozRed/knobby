import SwiftUI

/// A neumorphic rocker switch for toggling between light and dark themes.
/// Designed as a tactile element that belongs on the sensory wall.
struct ThemeToggleView: View {
    var themeManager: ThemeManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine

    private let frameWidth: CGFloat = 90
    private let frameHeight: CGFloat = 50
    private let trackWidth: CGFloat = 70
    private let trackHeight: CGFloat = 36
    private let thumbSize: CGFloat = 28

    var body: some View {
        ZStack {
            // Neumorphic track (inset)
            trackBase

            // Icons on either side
            iconsLayer

            // Sliding thumb
            thumb
                .offset(x: themeManager.isDarkMode ? trackWidth / 2 - thumbSize / 2 - 6 : -trackWidth / 2 + thumbSize / 2 + 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: themeManager.isDarkMode)
        }
        .frame(width: frameWidth, height: frameHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleTheme()
        }
    }

    // MARK: - Track Base (Inset Neumorphic)

    private var trackBase: some View {
        ZStack {
            // Outer raised area
            Capsule()
                .fill(themeManager.surface)
                .frame(width: trackWidth + 12, height: trackHeight + 10)
                .shadow(
                    color: themeManager.shadowLight.opacity(0.85),
                    radius: 8,
                    x: -5,
                    y: -5
                )
                .shadow(
                    color: themeManager.shadowDark.opacity(0.6),
                    radius: 8,
                    x: 5,
                    y: 5
                )

            // Inset track
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.shadowDark.opacity(0.35),
                            themeManager.surface,
                            themeManager.surfaceLight.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: trackWidth, height: trackHeight)

            // Inner shadow for depth
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            themeManager.shadowDark.opacity(0.4),
                            Color.clear,
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: trackWidth - 2, height: trackHeight - 2)
                .blur(radius: 1)
        }
    }

    // MARK: - Icons Layer

    private var iconsLayer: some View {
        HStack(spacing: trackWidth - 36) {
            // Sun icon (light mode)
            Image(systemName: "sun.max.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(
                    themeManager.isDarkMode
                        ? themeManager.shadowDark.opacity(0.4)
                        : Color(hex: 0xF5A623).opacity(0.8)
                )

            // Moon icon (dark mode)
            Image(systemName: "moon.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(
                    themeManager.isDarkMode
                        ? Color(hex: 0x7B8CDE).opacity(0.9)
                        : themeManager.shadowDark.opacity(0.4)
                )
        }
    }

    // MARK: - Thumb

    private var thumb: some View {
        ZStack {
            // Shadow under thumb
            Ellipse()
                .fill(themeManager.shadowDark.opacity(0.4))
                .frame(width: thumbSize * 0.8, height: thumbSize * 0.25)
                .blur(radius: 4)
                .offset(y: 5)

            // Thumb body - raised neumorphic
            Circle()
                .fill(themeManager.surface)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(
                    color: themeManager.shadowLight.opacity(0.9),
                    radius: 5,
                    x: -3,
                    y: -3
                )
                .shadow(
                    color: themeManager.shadowDark.opacity(0.6),
                    radius: 5,
                    x: 3,
                    y: 3
                )

            // Inner gradient for 3D effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.surfaceLight,
                            themeManager.surface,
                            themeManager.surfaceDark.opacity(0.4)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: thumbSize * 0.5
                    )
                )
                .frame(width: thumbSize - 3, height: thumbSize - 3)

            // Edge highlight
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.clear,
                            themeManager.shadowDark.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: thumbSize - 2, height: thumbSize - 2)

            // Active indicator glow
            Circle()
                .fill(
                    themeManager.isDarkMode
                        ? Color(hex: 0x7B8CDE).opacity(0.15)
                        : Color(hex: 0xF5A623).opacity(0.1)
                )
                .frame(width: thumbSize - 6, height: thumbSize - 6)
        }
    }

    // MARK: - Actions

    private func toggleTheme() {
        hapticEngine.playDetent()
        soundEngine.play(.switchClick)
        themeManager.toggle()
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        ThemeToggleView(
            themeManager: ThemeManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
