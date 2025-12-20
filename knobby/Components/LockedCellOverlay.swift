import SwiftUI

/// A locked cell overlay with a mechanical keycap unlock button.
/// Tapping the button presents a purchase sheet.
struct LockedCellOverlay: View {
    var themeManager: ThemeManager?
    var motionManager: MotionManager?
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

    // Dynamic tilt properties
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

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

    // 3D keycap depth constants (matching MechanicalKeycapView)
    private let keycapDepth: CGFloat = 8
    private let taperPerLayer: CGFloat = 2
    private let parallaxStrength: CGFloat = 4

    private func unlockKeycap(in geometry: GeometryProxy) -> some View {
        let isCompact = geometry.size.height < 130
        let isWide = geometry.size.width > 280

        // Spacebar dimensions - wider than tall
        let keyWidth: CGFloat = isWide ? 140 : (isCompact ? 100 : 120)
        let keyHeight: CGFloat = isCompact ? 40 : 48
        let cornerRadius: CGFloat = isCompact ? 6 : 8
        let maxTravel: CGFloat = 4

        // Calculate parallax offset based on tilt (matching MechanicalKeycapView)
        let parallaxX = reduceMotion ? 0 : CGFloat(tiltX) * parallaxStrength * 2.5
        let parallaxY = reduceMotion ? 0 : CGFloat(-tiltY) * parallaxStrength * 2.5

        // Light direction affects which edges appear lit vs shadowed
        let lightAngleX = reduceMotion ? 0.3 : 0.3 - tiltX * 0.5
        let lightAngleY = reduceMotion ? 0.3 : 0.3 + tiltY * 0.5

        return ZStack {
            // LED underglow (beneath everything)
            ledUnderglow(width: keyWidth, height: keyHeight)

            // Switch housing / plate
            switchHousing(width: keyWidth, height: keyHeight, cornerRadius: cornerRadius)

            // Interactive keycap group - only this responds to taps
            ZStack {
                // === LAYER 1: Bottom/Base layer (largest, creates visible sides) ===
                keycapBaseLayer(
                    width: keyWidth,
                    height: keyHeight,
                    cornerRadius: cornerRadius,
                    lightAngleX: lightAngleX,
                    lightAngleY: lightAngleY
                )
                .offset(
                    x: parallaxX * 0.8,
                    y: parallaxY * 0.8 + keyPressDepth
                )

                // === LAYER 2: Middle body layer ===
                keycapMiddleLayer(
                    width: keyWidth,
                    height: keyHeight,
                    cornerRadius: cornerRadius,
                    lightAngleX: lightAngleX,
                    lightAngleY: lightAngleY
                )
                .offset(
                    x: parallaxX * 0.4,
                    y: -keycapDepth * 0.4 + parallaxY * 0.4 + keyPressDepth
                )

                // === LAYER 3: Top surface (smallest, the dished top) ===
                keycapTopLayer(
                    width: keyWidth,
                    height: keyHeight,
                    cornerRadius: cornerRadius,
                    lightAngleX: lightAngleX,
                    lightAngleY: lightAngleY
                )
                .offset(
                    x: parallaxX * 0.15,
                    y: -keycapDepth * 0.75 + parallaxY * 0.15 + keyPressDepth
                )

                // === LEGEND ===
                keycapLegend(compact: isCompact)
                    .offset(
                        x: parallaxX * 0.1,
                        y: -keycapDepth * 0.75 + parallaxY * 0.1 + keyPressDepth
                    )
            }
            .frame(width: keyWidth + taperPerLayer * 2 + 8, height: keyHeight + taperPerLayer * 2 + 16)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius + 2))
            .gesture(pressGesture(maxTravel: maxTravel))
            .animation(.interpolatingSpring(stiffness: 800, damping: 15), value: keyPressDepth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Base Layer (Shows the physical sides)

    private func keycapBaseLayer(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        lightAngleX: Double,
        lightAngleY: Double
    ) -> some View {
        // Base is slightly larger - the visible rim IS the "side" of the keycap
        let baseWidth = width + taperPerLayer * 2
        let baseHeight = height + taperPerLayer * 2

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
                .frame(width: baseWidth, height: baseHeight)

            // Inner shadow to create depth between base and middle layer
            RoundedRectangle(cornerRadius: cornerRadius + 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isDarkMode ? 0.4 : 0.2),
                            Color.clear,
                            shadowLight.opacity(isDarkMode ? 0.1 : 0.3)
                        ],
                        startPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY),
                        endPoint: UnitPoint(x: lightAngleX, y: lightAngleY)
                    ),
                    lineWidth: 2
                )
                .frame(width: baseWidth - 2, height: baseHeight - 2)
        }
        .shadow(
            color: shadowDark.opacity(isDarkMode ? 0.7 : 0.4),
            radius: 3,
            x: CGFloat(1 - lightAngleX) * 3,
            y: 3
        )
    }

    // MARK: - Middle Layer (Main body with bevel transition)

    private func keycapMiddleLayer(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        lightAngleX: Double,
        lightAngleY: Double
    ) -> some View {
        let middleWidth = width + taperPerLayer * 0.5
        let middleHeight = height + taperPerLayer * 0.5

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
                .frame(width: middleWidth, height: middleHeight)

            // Subtle top edge highlight
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLight.opacity(isDarkMode ? 0.2 : 0.5),
                            Color.clear,
                            Color.black.opacity(isDarkMode ? 0.2 : 0.1)
                        ],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    ),
                    lineWidth: 1.5
                )
                .frame(width: middleWidth - 1, height: middleHeight - 1)
        }
    }

    // MARK: - Top Layer (Dished surface)

    private func keycapTopLayer(
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        lightAngleX: Double,
        lightAngleY: Double
    ) -> some View {
        let topWidth = width - taperPerLayer
        let topHeight = height - taperPerLayer

        return ZStack {
            // Top surface
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .fill(keycapTopColor)
                .frame(width: topWidth, height: topHeight)

            // Dish effect (concave center)
            RoundedRectangle(cornerRadius: cornerRadius - 2)
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDark.opacity(isDarkMode ? 0.15 : 0.1),
                            Color.clear,
                            shadowLight.opacity(isDarkMode ? 0.1 : 0.2)
                        ],
                        center: UnitPoint(
                            x: 0.65 + (reduceMotion ? 0 : tiltX * 0.3),
                            y: 0.65 - (reduceMotion ? 0 : tiltY * 0.3)
                        ),
                        startRadius: 0,
                        endRadius: topWidth * 0.5
                    )
                )
                .frame(width: topWidth - 4, height: topHeight - 4)

            // Top edge ring highlight
            RoundedRectangle(cornerRadius: cornerRadius - 1)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowLight.opacity(isDarkMode ? 0.3 : 0.7),
                            shadowLight.opacity(isDarkMode ? 0.1 : 0.3),
                            shadowDark.opacity(isDarkMode ? 0.3 : 0.2),
                            shadowDark.opacity(isDarkMode ? 0.15 : 0.1)
                        ],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    ),
                    lineWidth: 1
                )
                .frame(width: topWidth - 2, height: topHeight - 2)
        }
    }

    // MARK: - Keycap Legend

    private func keycapLegend(compact: Bool) -> some View {
        HStack(spacing: compact ? 5 : 7) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: compact ? 13 : 16, weight: .semibold))
                .foregroundColor(isKeyPressed ? accentColor : legendColor)
                .shadow(
                    color: isKeyPressed ? accentColor.opacity(0.5) : Color.clear,
                    radius: 4
                )

            Text("UNLOCK")
                .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(isKeyPressed ? accentColor.opacity(0.9) : legendColor.opacity(0.8))
        }
        .animation(.easeInOut(duration: 0.15), value: isKeyPressed)
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
