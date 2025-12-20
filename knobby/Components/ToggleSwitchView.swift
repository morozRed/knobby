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

    // Dynamic tilt properties
    private var tiltX: Double { motionManager.tiltX }
    private var tiltY: Double { motionManager.tiltY }
    private var reduceMotion: Bool { motionManager.reduceMotion }

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
                .fill(surfaceColor)
                .frame(width: trackWidth + 16, height: trackHeight + 16)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: isDarkMode ? 6 : 10,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.8 : 0.65),
                    radius: isDarkMode ? 6 : 10,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
                )

            // Inset track with dynamic gradient
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.3),
                            surfaceColor,
                            surfaceLightColor.opacity(isDarkMode ? 0.3 : 0.5)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
                    )
                )
                .frame(width: trackWidth, height: trackHeight)

            // Inner shadow with dynamic gradient
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.15 : 0.3)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
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
        let rimColor = surfaceDarkColor
        let rimHighlight = surfaceLightColor.opacity(0.6)
        let rimShadow = shadowDarkColor.opacity(0.5)

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

            // Shadow - dynamic position
            Ellipse()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35))
                .frame(width: thumbSize * 0.8, height: thumbSize * 0.3)
                .blur(radius: 4)
                .offset(
                    x: CGFloat(tiltX) * 3,
                    y: 6 - CGFloat(tiltY) * 2
                )

            // Thumb body - raised neumorphic with dynamic shadows
            Circle()
                .fill(surfaceColor)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: isDarkMode ? 4 : 6,
                    x: shadowOffsets.light.width,
                    y: shadowOffsets.light.height
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.65),
                    radius: isDarkMode ? 4 : 6,
                    x: shadowOffsets.dark.width,
                    y: shadowOffsets.dark.height
                )

            // Inner gradient with dynamic center
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            surfaceLightColor,
                            surfaceColor,
                            surfaceDarkColor.opacity(0.3)
                        ],
                        center: gradientCenter,
                        startRadius: 0,
                        endRadius: thumbSize * 0.5
                    )
                )
                .frame(width: thumbSize - 4, height: thumbSize - 4)

            // Edge highlight with dynamic gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.25 : 0.5),
                            Color.clear,
                            shadowDarkColor.opacity(0.2)
                        ],
                        startPoint: edgePoints.start,
                        endPoint: edgePoints.end
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
