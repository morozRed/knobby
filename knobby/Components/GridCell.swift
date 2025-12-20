import SwiftUI

/// A neumorphic cell container for tactile objects.
/// Provides raised panel effect with dynamic neumorphic lighting responding to device tilt.
struct NeumorphicCell<Content: View>: View {
    let isLocked: Bool
    var themeManager: ThemeManager?
    var motionManager: MotionManager?
    var hapticEngine: HapticEngine?
    var soundEngine: SoundEngine?

    /// Callback when user taps unlock button
    var onUnlockTapped: (() -> Void)?

    @ViewBuilder let content: () -> Content

    init(
        isLocked: Bool = false,
        themeManager: ThemeManager? = nil,
        motionManager: MotionManager? = nil,
        hapticEngine: HapticEngine? = nil,
        soundEngine: SoundEngine? = nil,
        onUnlockTapped: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLocked = isLocked
        self.themeManager = themeManager
        self.motionManager = motionManager
        self.hapticEngine = hapticEngine
        self.soundEngine = soundEngine
        self.onUnlockTapped = onUnlockTapped
        self.content = content
    }

    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
    }

    private var surfaceDarkColor: Color {
        themeManager?.surfaceDark ?? KnobbyColors.surfaceDark
    }

    private var shadowDarkColor: Color {
        themeManager?.shadowDark ?? KnobbyColors.shadowDark
    }

    private var shadowLightColor: Color {
        themeManager?.shadowLight ?? KnobbyColors.shadowLight
    }

    private var isDarkMode: Bool {
        themeManager?.isDarkMode ?? false
    }

    // Dynamic shadow properties
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

    var body: some View {
        ZStack {
            // Layer 1: Main neumorphic panel with contained shadows
            mainPanel

            // Layer 2: Content
            content()
                .opacity(isLocked ? 0.4 : 1.0)

            // Layer 3: Lock overlay
            if isLocked {
                lockOverlay
            }
        }
    }

    // MARK: - Main Panel

    private var mainPanel: some View {
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

        return RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(surfaceColor)
            .overlay {
                // Inner gradient for 3D convex surface - light shifts with tilt
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.12 : 0.25),
                                Color.clear,
                                shadowDarkColor.opacity(isDarkMode ? 0.12 : 0.08)
                            ],
                            startPoint: edgePoints.start,
                            endPoint: edgePoints.end
                        )
                    )
            }
            .overlay {
                // Border highlight - dynamic edge catching light
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.4 : 0.9),
                                Color.white.opacity(isDarkMode ? 0.15 : 0.4),
                                shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.3)
                            ],
                            startPoint: edgePoints.start,
                            endPoint: edgePoints.end
                        ),
                        lineWidth: 1
                    )
            }
            // Composite content before applying shadows for better scroll performance
            .compositingGroup()
            // Light source shadow (top-left highlight) - dynamic
            .shadow(
                color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.7),
                radius: isDarkMode ? 6 : 8,
                x: shadowOffsets.light.width,
                y: shadowOffsets.light.height
            )
            // Primary depth shadow (bottom-right) - dynamic
            .shadow(
                color: shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.35),
                radius: isDarkMode ? 8 : 10,
                x: shadowOffsets.dark.width,
                y: shadowOffsets.dark.height
            )
            // Soft ambient shadow for extra depth - follows dark shadow
            .shadow(
                color: shadowDarkColor.opacity(isDarkMode ? 0.25 : 0.15),
                radius: 16,
                x: shadowOffsets.dark.width * 1.6,
                y: shadowOffsets.dark.height * 2
            )
    }

    // MARK: - Lock Overlay

    private var lockOverlay: some View {
        LockedCellOverlay(
            themeManager: themeManager,
            motionManager: motionManager,
            hapticEngine: hapticEngine,
            soundEngine: soundEngine,
            onUnlockTapped: onUnlockTapped
        )
    }
}

/// A container that sizes its content to span multiple grid units.
/// Use this to place tactile objects in the sensory wall grid.
struct GridCell<Content: View>: View {
    /// Number of grid units wide (1 = 195pt)
    let width: Int

    /// Number of grid units tall (1 = 195pt)
    let height: Int

    /// The content to display within the cell
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(
                width: CGFloat(width) * KnobbyDimensions.gridUnit,
                height: CGFloat(height) * KnobbyDimensions.gridUnit
            )
    }
}

#Preview("Neumorphic Cells") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        VStack(spacing: 20) {
            HStack(spacing: 20) {
                NeumorphicCell {
                    Circle()
                        .fill(KnobbyColors.accent)
                        .frame(width: 60, height: 60)
                }
                .frame(width: 140, height: 140)

                NeumorphicCell(
                    isLocked: true,
                    hapticEngine: HapticEngine(),
                    soundEngine: SoundEngine(),
                    onUnlockTapped: { print("Unlock!") }
                ) {
                    Circle()
                        .fill(KnobbyColors.accent)
                        .frame(width: 60, height: 60)
                }
                .frame(width: 140, height: 140)
            }

            // Wide locked cell
            NeumorphicCell(
                isLocked: true,
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                onUnlockTapped: { print("Unlock wide!") }
            ) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(KnobbyColors.accent)
                    .frame(width: 200, height: 40)
            }
            .frame(width: 300, height: 120)
        }
    }
}

#Preview("Locked Cell Sizes") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        VStack(spacing: 16) {
            // Compact
            NeumorphicCell(
                isLocked: true,
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine()
            ) {
                EmptyView()
            }
            .frame(width: 160, height: 100)

            // Standard
            NeumorphicCell(
                isLocked: true,
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine()
            ) {
                EmptyView()
            }
            .frame(width: 180, height: 150)

            // Wide
            NeumorphicCell(
                isLocked: true,
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine()
            ) {
                EmptyView()
            }
            .frame(width: 350, height: 130)
        }
    }
}
