import SwiftUI

/// A neumorphic horizontal slider - soft track with draggable thumb.
struct FrequencyDialView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var sliderPosition: CGFloat = 0.5  // 0 to 1
    @State private var isDragging = false
    @State private var lastDetent: Int = 5

    private let frameWidth: CGFloat = 120
    private let frameHeight: CGFloat = 70
    private let trackWidth: CGFloat = 100
    private let trackHeight: CGFloat = 28
    private let thumbWidth: CGFloat = 32
    private let thumbHeight: CGFloat = 44

    private let detentCount: Int = 10

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

            // Thumb
            sliderThumb
                .offset(x: thumbOffset)
        }
        .frame(width: frameWidth, height: frameHeight)
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }

    private var thumbOffset: CGFloat {
        let range = trackWidth - thumbWidth - 8
        return (sliderPosition - 0.5) * range
    }

    // MARK: - Track Base (Inset Neumorphic)

    private var trackBase: some View {
        ZStack {
            // Outer raised area
            Capsule()
                .fill(surfaceColor)
                .frame(width: trackWidth + 12, height: trackHeight + 12)
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
                        startPoint: .top,
                        endPoint: .bottom
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
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: trackWidth - 2, height: trackHeight - 2)
                .blur(radius: 1)

            // Detent marks
            HStack(spacing: (trackWidth - 20) / CGFloat(detentCount - 1)) {
                ForEach(0..<detentCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25))
                        .frame(width: 2, height: 8)
                }
            }
        }
    }

    // MARK: - Slider Thumb

    private var sliderThumb: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4))
                .frame(width: thumbWidth * 0.8, height: thumbHeight * 0.3)
                .blur(radius: 5)
                .offset(y: thumbHeight / 2 - 4)

            // Thumb body - raised neumorphic pill
            RoundedRectangle(cornerRadius: 10)
                .fill(surfaceColor)
                .frame(width: thumbWidth, height: thumbHeight)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.3 : 0.9),
                    radius: isDarkMode ? 5 : 8,
                    x: isDarkMode ? -3 : -4,
                    y: isDarkMode ? -3 : -4
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.7 : 0.65),
                    radius: isDarkMode ? 5 : 8,
                    x: isDarkMode ? 3 : 4,
                    y: isDarkMode ? 3 : 4
                )

            // Inner gradient
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            surfaceLightColor,
                            surfaceColor,
                            surfaceDarkColor.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: thumbWidth - 4, height: thumbHeight - 4)

            // Grip lines
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.2))
                        .frame(width: thumbWidth - 14, height: 2)
                }
            }

            // Edge highlight
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLightColor.opacity(isDarkMode ? 0.2 : 0.5),
                            Color.clear,
                            shadowDarkColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: thumbWidth - 1, height: thumbHeight - 1)
        }
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isDragging)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                }

                let dragRange = trackWidth - thumbWidth - 8
                let newPosition = 0.5 + (value.location.x - frameWidth / 2) / dragRange
                sliderPosition = min(max(newPosition, 0), 1)

                let currentDetent = Int(round(sliderPosition * Double(detentCount - 1)))
                if currentDetent != lastDetent {
                    hapticEngine.playDetent()
                    soundEngine.play(.sliderTick)
                    lastDetent = currentDetent
                }
            }
            .onEnded { _ in
                isDragging = false
                let nearestDetent = round(sliderPosition * Double(detentCount - 1))
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    sliderPosition = nearestDetent / Double(detentCount - 1)
                }
                soundEngine.play(.sliderSnap)
            }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        FrequencyDialView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
