import SwiftUI

/// A neumorphic rocker switch for toggling between light and dark themes.
/// Designed as a tactile element that belongs on the sensory wall.
struct ThemeToggleView: View {
    var themeManager: ThemeManager
    var motionManager: MotionManager?
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine

    // Dynamic tilt properties
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

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
        let shadowOffsets = DynamicShadow.shadowOffsets(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let edgePoints = DynamicShadow.edgeGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        return ZStack {
            // Outer raised area with dynamic shadows
            Capsule()
                .fill(themeManager.surface)
                .frame(width: trackWidth + 12, height: trackHeight + 10)
                .shadow(
                    color: themeManager.shadowLight.opacity(0.85),
                    radius: 8,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: themeManager.shadowDark.opacity(0.6),
                    radius: 8,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
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
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
                    )
                )
                .frame(width: trackWidth, height: trackHeight)

            // Inner shadow for depth - dynamic edge
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            themeManager.shadowDark.opacity(0.4),
                            Color.clear,
                            Color.white.opacity(0.25)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
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
        let shadowOffsets = DynamicShadow.shadowOffsets(
            tiltX: tiltX,
            tiltY: tiltY,
            maxOffset: 8,
            reduceMotion: reduceMotion
        )
        let gradientCenter = DynamicShadow.convexGradientCenter(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let rimOffset = DynamicShadow.rimOffset(
            tiltX: tiltX,
            tiltY: tiltY,
            maxReveal: 2,
            reduceMotion: reduceMotion
        )
        let rimGradient = DynamicShadow.rimGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )
        let edgePoints = DynamicShadow.edgeGradientPoints(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        // Rim colors
        let rimColor = themeManager.surfaceDark
        let rimHighlight = themeManager.surfaceLight.opacity(0.6)
        let rimShadow = themeManager.shadowDark.opacity(0.5)

        return ZStack {
            // 3D rim layer (behind thumb) - reveals depth when tilted
            Circle()
                .fill(
                    LinearGradient(
                        colors: [rimHighlight, rimColor, rimShadow],
                        startPoint: rimGradient.start,
                        endPoint: rimGradient.end
                    )
                )
                .frame(width: thumbSize + 4, height: thumbSize + 4)
                .offset(x: rimOffset.width, y: rimOffset.height)

            // Shadow under thumb - dynamic position
            Ellipse()
                .fill(themeManager.shadowDark.opacity(0.4))
                .frame(width: thumbSize * 0.8, height: thumbSize * 0.25)
                .blur(radius: 4)
                .offset(
                    x: CGFloat(tiltX) * 3,
                    y: 5 - CGFloat(tiltY) * 2
                )

            // Thumb body - raised neumorphic with dynamic shadows
            Circle()
                .fill(themeManager.surface)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(
                    color: themeManager.shadowLight.opacity(0.9),
                    radius: 5,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: themeManager.shadowDark.opacity(0.6),
                    radius: 5,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
                )

            // Inner gradient for 3D effect - dynamic center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.surfaceLight,
                            themeManager.surface,
                            themeManager.surfaceDark.opacity(0.4)
                        ],
                        center: gradientCenter,
                        startRadius: 0,
                        endRadius: thumbSize * 0.5
                    )
                )
                .frame(width: thumbSize - 3, height: thumbSize - 3)

            // Edge highlight - dynamic
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.clear,
                            themeManager.shadowDark.opacity(0.25)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
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
