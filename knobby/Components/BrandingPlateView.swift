import SwiftUI

/// A debossed branding nameplate showing the app name.
/// Styled as an industrial manufacturer's mark - pressed into the surface.
/// Does nothing when touched - purely decorative brand signature.
struct BrandingPlateView: View {
    var motionManager: MotionManager?
    var themeManager: ThemeManager?

    // Dynamic tilt properties
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

    // Theme colors
    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
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

    // Text colors - slightly muted to feel embossed
    private var textColor: Color {
        isDarkMode ? Color(hex: 0x505058) : Color(hex: 0xB8B8C0)
    }

    private var textShadowColor: Color {
        isDarkMode ? Color(hex: 0x606068) : Color(hex: 0xD0D0D8)
    }

    var body: some View {
        ZStack {
            // Debossed channel for the text
            debossedChannel

            // The brand text with embossed effect
            brandText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Debossed Channel

    private var debossedChannel: some View {
        // Calculate dynamic lighting for the inset
        let concaveCenter = DynamicShadow.concaveGradientCenter(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        shadowDarkColor.opacity(isDarkMode ? 0.25 : 0.15),
                        surfaceColor.opacity(0.5),
                        shadowLightColor.opacity(isDarkMode ? 0.08 : 0.2)
                    ],
                    center: concaveCenter,
                    startRadius: 0,
                    endRadius: 80
                )
            )
            .frame(width: 120, height: 36)
            // Inner shadow (debossed effect)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                                Color.clear,
                                shadowLightColor.opacity(isDarkMode ? 0.2 : 0.5)
                            ],
                            startPoint: debossedGradientStart,
                            endPoint: debossedGradientEnd
                        ),
                        lineWidth: 1.5
                    )
            }
    }

    // Dynamic gradient points for debossed edge
    private var debossedGradientStart: UnitPoint {
        let x = 0.2 - (reduceMotion ? 0 : tiltX * 0.3)
        let y = 0.2 + (reduceMotion ? 0 : tiltY * 0.3)
        return UnitPoint(x: x, y: y)
    }

    private var debossedGradientEnd: UnitPoint {
        let x = 0.8 - (reduceMotion ? 0 : tiltX * 0.3)
        let y = 0.8 + (reduceMotion ? 0 : tiltY * 0.3)
        return UnitPoint(x: x, y: y)
    }

    // MARK: - Brand Text

    private var brandText: some View {
        // Calculate highlight offset based on tilt
        let highlightOffset = DynamicShadow.highlightOffset(
            tiltX: tiltX,
            tiltY: tiltY,
            baseOffset: CGSize(width: -0.5, height: -0.5),
            maxShift: 1.5,
            reduceMotion: reduceMotion
        )

        return ZStack {
            // Shadow layer (bottom-right, makes text look pressed in)
            Text("knobby")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35))
                .offset(
                    x: 0.8 - highlightOffset.width * 0.5,
                    y: 0.8 - highlightOffset.height * 0.5
                )

            // Highlight layer (top-left, catches light)
            Text("knobby")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(shadowLightColor.opacity(isDarkMode ? 0.3 : 0.8))
                .offset(
                    x: highlightOffset.width,
                    y: highlightOffset.height
                )

            // Main text (the actual debossed letterforms)
            Text("knobby")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundColor(textColor)
        }
    }
}

// MARK: - Preview

#Preview("Branding Plate") {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()

        VStack(spacing: 30) {
            // Light mode
            NeumorphicCell {
                BrandingPlateView()
            }
            .frame(width: 180, height: 80)

            // Simulated context
            HStack(spacing: 16) {
                NeumorphicCell {
                    Circle()
                        .fill(KnobbyColors.accent)
                        .frame(width: 40, height: 40)
                }
                .frame(width: 150, height: 120)

                NeumorphicCell {
                    BrandingPlateView()
                }
                .frame(width: 150, height: 120)
            }
        }
    }
}

#Preview("Dark Mode") {
    ZStack {
        Color(hex: 0x2A2A30).ignoresSafeArea()

        NeumorphicCell(
            themeManager: {
                let tm = ThemeManager()
                return tm
            }()
        ) {
            BrandingPlateView(
                themeManager: {
                    let tm = ThemeManager()
                    return tm
                }()
            )
        }
        .frame(width: 180, height: 100)
    }
    .preferredColorScheme(.dark)
}
