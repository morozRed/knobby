import SwiftUI

/// A locked cell overlay with a mechanical keycap unlock button.
/// Tapping the button presents a purchase sheet.
struct LockedCellOverlay: View {
    var themeManager: ThemeManager?
    var hapticEngine: HapticEngine?
    var soundEngine: SoundEngine?

    /// Callback when user taps unlock - should present purchase sheet
    var onUnlockTapped: (() -> Void)?

    @State private var isKeyPressed = false
    @State private var keyPressDepth: CGFloat = 0

    // MARK: - Theme Colors

    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
    }

    private var shadowLight: Color {
        themeManager?.shadowLight ?? KnobbyColors.shadowLight
    }

    private var shadowDark: Color {
        themeManager?.shadowDark ?? KnobbyColors.shadowDark
    }

    private var isDarkMode: Bool {
        themeManager?.isDarkMode ?? false
    }

    // Keycap colors (matching MechanicalKeycapView exactly)
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

    // Accent for the LED underglow
    private var accentColor: Color {
        Color(hex: 0x6B8E7B) // Sage green - premium unlock feel
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Frosted backdrop
                frostedBackdrop

                // Mechanical unlock keycap
                unlockKeycap(in: geometry)
            }
        }
    }

    // MARK: - Frosted Backdrop

    private var frostedBackdrop: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(surfaceColor.opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                shadowLight.opacity(isDarkMode ? 0.05 : 0.12),
                                Color.clear,
                                shadowDark.opacity(0.06)
                            ],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
            )
    }

    // MARK: - Unlock Keycap (Spacebar Style - Matching MechanicalKeycapView)

    private func unlockKeycap(in geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 130
        let isWide = geometry.size.width > 280

        // Spacebar dimensions - wider than tall
        let keyWidth: CGFloat = isWide ? 140 : (isCompact ? 100 : 120)
        let keyHeight: CGFloat = isCompact ? 40 : 48
        let cornerRadius: CGFloat = isCompact ? 6 : 8
        let keycapHeight: CGFloat = isCompact ? 10 : 12
        let maxTravel: CGFloat = 4

        return ZStack {
            // LED underglow (beneath everything)
            ledUnderglow(width: keyWidth, height: keyHeight)

            // Switch housing / plate
            switchHousing(width: keyWidth, height: keyHeight, cornerRadius: cornerRadius)

            // The keycap itself
            keycap(
                width: keyWidth,
                height: keyHeight,
                cornerRadius: cornerRadius,
                keycapHeight: keycapHeight,
                compact: isCompact
            )
            .offset(y: -keycapHeight / 2 + keyPressDepth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(pressGesture(maxTravel: maxTravel))
    }

    // MARK: - LED Underglow

    private func ledUnderglow(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                RadialGradient(
                    colors: [
                        accentColor.opacity(isKeyPressed ? 0.7 : 0.25),
                        accentColor.opacity(isKeyPressed ? 0.3 : 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.7
                )
            )
            .frame(width: width + 24, height: height + 24)
            .blur(radius: 14)
            .offset(y: 6)
            .animation(.easeOut(duration: 0.12), value: isKeyPressed)
    }

    // MARK: - Switch Housing

    private func switchHousing(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> some View {
        ZStack {
            // Plate cutout (dark recess)
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .fill(Color.black.opacity(isDarkMode ? 0.55 : 0.35))
                .frame(width: width + 6, height: height + 6)
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
                .frame(width: width - 4, height: height - 4)
                .offset(y: 6 + keyPressDepth)

            // Stem cross (visible when key is pressed)
            stemCross
                .opacity(Double(keyPressDepth / 4) * 0.5)
        }
    }

    private var stemCross: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0.5)
                .fill(accentColor.opacity(0.7))
                .frame(width: 1.5, height: 8)

            RoundedRectangle(cornerRadius: 0.5)
                .fill(accentColor.opacity(0.7))
                .frame(width: 5, height: 1.5)
        }
        .offset(y: 6)
    }

    // MARK: - Keycap

    private func keycap(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        keycapHeight: CGFloat,
        compact: Bool
    ) -> some View {
        ZStack {
            // Keycap base (bottom edge - creates 3D depth)
            keycapBase(width: width, height: height, cornerRadius: cornerRadius)

            // Keycap body (the main visible part)
            keycapBody(width: width, height: height, cornerRadius: cornerRadius, keycapHeight: keycapHeight)

            // Top surface with dish
            keycapTop(width: width, height: height, cornerRadius: cornerRadius, keycapHeight: keycapHeight)

            // Legend (icon + text)
            keycapLegend(keycapHeight: keycapHeight, compact: compact)
        }
        .animation(.interpolatingSpring(stiffness: 800, damping: 15), value: keyPressDepth)
    }

    private func keycapBase(width: CGFloat, height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius + 1)
            .fill(keycapSideColor)
            .frame(width: width, height: height)
            .shadow(
                color: shadowDark.opacity(isDarkMode ? 0.7 : 0.45),
                radius: 4,
                x: 0,
                y: 4
            )
    }

    private func keycapBody(width: CGFloat, height: CGFloat, cornerRadius: CGFloat, keycapHeight: CGFloat) -> some View {
        ZStack {
            // Main body with side gradient
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [keycapColor, keycapSideColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width - 2, height: height - 2)

            // Side highlight (left edge catch light)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            shadowLight.opacity(isDarkMode ? 0.12 : 0.35),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width - 2, height: height - 2)
        }
        .offset(y: -keycapHeight / 3)
    }

    private func keycapTop(width: CGFloat, height: CGFloat, cornerRadius: CGFloat, keycapHeight: CGFloat) -> some View {
        ZStack {
            // Top surface base
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .fill(keycapTopColor)
                .frame(width: width - 6, height: height - 6)

            // Dish effect (subtle concave scoop)
            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDark.opacity(isDarkMode ? 0.1 : 0.06),
                            Color.clear,
                            shadowLight.opacity(isDarkMode ? 0.06 : 0.12)
                        ],
                        center: UnitPoint(x: 0.5, y: 0.6),
                        startRadius: 0,
                        endRadius: width * 0.4
                    )
                )
                .frame(width: width - 8, height: height - 8)

            // Top edge highlight
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLight.opacity(isDarkMode ? 0.2 : 0.5),
                            Color.clear,
                            shadowDark.opacity(isDarkMode ? 0.15 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: width - 6, height: height - 6)
        }
        .offset(y: -keycapHeight * 0.7)
    }

    private func keycapLegend(keycapHeight: CGFloat, compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 7) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: compact ? 13 : 16, weight: .semibold))

            Text("UNLOCK")
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .tracking(1.2)
        }
        .foregroundColor(legendColor)
        .offset(y: -keycapHeight * 0.7)
    }

    // MARK: - Press Gesture

    private func pressGesture(maxTravel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isKeyPressed {
                    isKeyPressed = true
                    withAnimation(.interpolatingSpring(stiffness: 800, damping: 15)) {
                        keyPressDepth = maxTravel
                    }

                    // Haptic and sound
                    hapticEngine?.playDetent()
                    soundEngine?.play(.keyThock)
                }
            }
            .onEnded { _ in
                isKeyPressed = false
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 18)) {
                    keyPressDepth = 0
                }

                // Release haptic and sound
                hapticEngine?.playDetent()
                soundEngine?.play(.keyClack)

                // Trigger unlock action
                onUnlockTapped?()
            }
    }
}

// MARK: - Preview

#Preview("Locked Cell - Standard") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        NeumorphicCell(
            isLocked: true,
            hapticEngine: HapticEngine()
        ) {
            Circle()
                .fill(KnobbyColors.accent)
                .frame(width: 60, height: 60)
        }
        .frame(width: 180, height: 160)
    }
}

#Preview("Locked Cell - Compact") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        NeumorphicCell(
            isLocked: true,
            hapticEngine: HapticEngine()
        ) {
            EmptyView()
        }
        .frame(width: 160, height: 110)
    }
}

#Preview("Locked Cell - Wide") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        NeumorphicCell(
            isLocked: true,
            hapticEngine: HapticEngine()
        ) {
            EmptyView()
        }
        .frame(width: 350, height: 130)
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color(hex: 0x2A2A30).ignoresSafeArea()

        LockedCellOverlay(
            themeManager: ThemeManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
        .frame(width: 180, height: 160)
    }
    .preferredColorScheme(.dark)
}
