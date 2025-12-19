import SwiftUI

/// A neumorphic cell container for tactile objects.
/// Provides raised panel effect with static neumorphic lighting.
struct NeumorphicCell<Content: View>: View {
    let isLocked: Bool
    var themeManager: ThemeManager?
    var hapticEngine: HapticEngine?
    var soundEngine: SoundEngine?

    /// Callback when user taps unlock button
    var onUnlockTapped: (() -> Void)?

    @ViewBuilder let content: () -> Content

    init(
        isLocked: Bool = false,
        themeManager: ThemeManager? = nil,
        hapticEngine: HapticEngine? = nil,
        soundEngine: SoundEngine? = nil,
        onUnlockTapped: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isLocked = isLocked
        self.themeManager = themeManager
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
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(surfaceColor)
            .overlay {
                // Inner gradient for 3D convex surface - light from top-left
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.clear,
                                shadowDarkColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                // Border highlight - bright top-left edge, subtle bottom-right
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.4),
                                shadowDarkColor.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            // Light source shadow (top-left highlight)
            .shadow(
                color: shadowLightColor.opacity(0.7),
                radius: 8,
                x: -4,
                y: -4
            )
            // Primary depth shadow (bottom-right)
            .shadow(
                color: shadowDarkColor.opacity(0.35),
                radius: 10,
                x: 5,
                y: 5
            )
            // Soft ambient shadow for extra depth
            .shadow(
                color: shadowDarkColor.opacity(0.15),
                radius: 16,
                x: 8,
                y: 12
            )
            .drawingGroup()
    }

    // MARK: - Lock Overlay

    private var lockOverlay: some View {
        LockedCellOverlay(
            themeManager: themeManager,
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
