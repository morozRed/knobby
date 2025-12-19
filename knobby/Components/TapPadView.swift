import SwiftUI

/// Multi-zone tap surface with spreading ripple effects.
/// Each tap creates visual and haptic ripples that fade naturally.
struct TapPadView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var ripples: [Ripple] = []
    @State private var tapLocations: [CGPoint] = []

    private let padWidth: CGFloat = 340
    private let padHeight: CGFloat = 110

    struct Ripple: Identifiable {
        let id = UUID()
        var location: CGPoint
        var scale: CGFloat = 0.3
        var opacity: Double = 0.8
        var isActive: Bool = true
    }

    // Theme-aware colors
    private var surfaceColor: Color {
        themeManager?.surface ?? KnobbyColors.surface
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
            // Pad surface (neumorphic inset)
            padSurface

            // Ripple effects
            ForEach(ripples) { ripple in
                rippleView(ripple)
            }

            // Touch feedback dots
            touchFeedbackDots
        }
        .frame(width: padWidth, height: padHeight)
        .contentShape(Rectangle())
        .gesture(tapGesture)
    }

    // MARK: - Pad Surface

    private var padSurface: some View {
        ZStack {
            // Outer raised frame
            RoundedRectangle(cornerRadius: 16)
                .fill(surfaceColor)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.25 : 0.85),
                    radius: 10,
                    x: -6,
                    y: -6
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.75 : 0.6),
                    radius: 10,
                    x: 6,
                    y: 6
                )

            // Inset pad area
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.3 : 0.18),
                            surfaceColor.opacity(0.95),
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: padWidth - 12, height: padHeight - 12)

            // Inner shadow
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.25),
                            Color.clear,
                            shadowLightColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: padWidth - 14, height: padHeight - 14)
                .blur(radius: 1)

            // Subtle grid pattern
            gridPattern
        }
    }

    private var gridPattern: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 20
            let dotSize: CGFloat = 1.5

            for x in stride(from: gridSpacing, to: size.width - gridSpacing, by: gridSpacing) {
                for y in stride(from: gridSpacing, to: size.height - gridSpacing, by: gridSpacing) {
                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(shadowDarkColor.opacity(isDarkMode ? 0.25 : 0.15))
                    )
                }
            }
        }
        .frame(width: padWidth - 16, height: padHeight - 16)
        .allowsHitTesting(false)
    }

    // MARK: - Ripple View

    private func rippleView(_ ripple: Ripple) -> some View {
        ZStack {
            // Outer ripple ring
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [
                            KnobbyColors.accent.opacity(ripple.opacity * 0.6),
                            KnobbyColors.accent.opacity(ripple.opacity * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    ),
                    lineWidth: 3
                )
                .frame(width: 80, height: 80)

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            KnobbyColors.accent.opacity(ripple.opacity * 0.4),
                            KnobbyColors.accent.opacity(ripple.opacity * 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)
        }
        .scaleEffect(ripple.scale)
        .position(ripple.location)
        .allowsHitTesting(false)
    }

    // MARK: - Touch Feedback Dots

    private var touchFeedbackDots: some View {
        ForEach(tapLocations.indices, id: \.self) { index in
            Circle()
                .fill(KnobbyColors.accent.opacity(0.6))
                .frame(width: 8, height: 8)
                .position(tapLocations[index])
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Gesture

    private var tapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location

                // Clamp to pad bounds
                let clampedX = min(max(location.x, 10), padWidth - 10)
                let clampedY = min(max(location.y, 10), padHeight - 10)
                let clampedLocation = CGPoint(x: clampedX, y: clampedY)

                // Add touch indicator
                if tapLocations.isEmpty || distance(from: tapLocations.last!, to: clampedLocation) > 15 {
                    withAnimation(.easeOut(duration: 0.1)) {
                        tapLocations.append(clampedLocation)
                    }

                    // Trigger ripple
                    createRipple(at: clampedLocation)

                    // Haptic feedback
                    hapticEngine.playDetent()

                    // Limit stored locations
                    if tapLocations.count > 5 {
                        tapLocations.removeFirst()
                    }
                }
            }
            .onEnded { _ in
                // Clear touch indicators with animation
                withAnimation(.easeOut(duration: 0.3)) {
                    tapLocations.removeAll()
                }
            }
    }

    // MARK: - Helpers

    private func createRipple(at location: CGPoint) {
        var ripple = Ripple(location: location)
        ripples.append(ripple)

        // Animate ripple expansion and fade
        withAnimation(.easeOut(duration: 0.6)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].scale = 1.5
                ripples[index].opacity = 0
            }
        }

        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        TapPadView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
