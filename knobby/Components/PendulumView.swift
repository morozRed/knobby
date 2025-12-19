import SwiftUI

/// Swinging pendulum with realistic physics.
/// Drag and release to watch it swing with gradual damping.
struct PendulumView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var angle: Double = 0
    @State private var angularVelocity: Double = 0
    @State private var isDragging = false
    @State private var lastDragAngle: Double? = nil
    @State private var lastTickAngle: Double = 0

    private let frameWidth: CGFloat = 100
    private let frameHeight: CGFloat = 120
    private let rodLength: CGFloat = 70
    private let bobRadius: CGFloat = 18
    private let pivotY: CGFloat = 15

    // Physics constants
    private let gravity: Double = 0.4
    private let damping: Double = 0.995
    private let tickThreshold: Double = 15 // Degrees between ticks

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
            // Frame/mount
            pendulumFrame

            // Pendulum (rod + bob)
            pendulum
                .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 0))
                .offset(y: pivotY)

            // Pivot point
            pivotPoint
        }
        .frame(width: frameWidth, height: frameHeight)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onAppear {
            startPhysics()
        }
    }

    // MARK: - Frame

    private var pendulumFrame: some View {
        ZStack {
            // Top mount bar
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x606068),
                            Color(hex: 0x404048),
                            Color(hex: 0x505058)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 50, height: 12)
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.4),
                    radius: 4,
                    x: 2,
                    y: 2
                )
                .offset(y: -frameHeight / 2 + 10)

            // Side supports
            HStack(spacing: 40) {
                supportArm
                supportArm.scaleEffect(x: -1)
            }
            .offset(y: -frameHeight / 2 + 20)
        }
    }

    private var supportArm: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 8, y: 25))
            path.addLine(to: CGPoint(x: 4, y: 25))
            path.addLine(to: CGPoint(x: -2, y: 0))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(hex: 0x707078),
                    Color(hex: 0x505058)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    // MARK: - Pendulum

    private var pendulum: some View {
        VStack(spacing: 0) {
            // Rod
            rod

            // Bob (weight)
            bob
        }
    }

    private var rod: some View {
        ZStack {
            // Rod body
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xA0A0A8),
                            Color(hex: 0x707078),
                            Color(hex: 0x888890)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 4, height: rodLength)

            // Rod highlight
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: rodLength)
                .offset(x: -1)
        }
    }

    private var bob: some View {
        ZStack {
            // Bob shadow (dynamic based on angle)
            Ellipse()
                .fill(shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.3))
                .frame(width: bobRadius * 1.6, height: bobRadius * 0.4)
                .offset(y: bobRadius * 0.8)
                .blur(radius: 4)

            // Main bob body - brass/gold color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xD4A84B),
                            Color(hex: 0xB8862D),
                            Color(hex: 0x8B6914)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: bobRadius
                    )
                )
                .frame(width: bobRadius * 2, height: bobRadius * 2)
                .shadow(
                    color: Color(hex: 0x8B6914).opacity(0.5),
                    radius: 6,
                    x: 2,
                    y: 4
                )

            // Primary highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 7)
                .offset(x: -bobRadius * 0.25, y: -bobRadius * 0.35)

            // Edge rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xE8C060).opacity(0.6),
                            Color.clear,
                            Color(hex: 0x6B4A10).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: bobRadius * 2 - 2, height: bobRadius * 2 - 2)

            // Connection ring
            Circle()
                .fill(Color(hex: 0x808088))
                .frame(width: 8, height: 8)
                .offset(y: -bobRadius + 2)
        }
    }

    // MARK: - Pivot Point

    private var pivotPoint: some View {
        ZStack {
            // Pivot body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x909098),
                            Color(hex: 0x505058)
                        ],
                        center: UnitPoint(x: 0.4, y: 0.4),
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 14, height: 14)

            // Pivot highlight
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 4, height: 4)
                .offset(x: -2, y: -2)
        }
        .offset(y: -frameHeight / 2 + pivotY + 10)
    }

    // MARK: - Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true

                // Calculate angle from drag position relative to pivot
                let pivotPos = CGPoint(x: frameWidth / 2, y: pivotY)
                let dx = value.location.x - pivotPos.x
                let dy = value.location.y - pivotPos.y

                let dragAngle = atan2(dx, dy) * 180 / .pi

                // Clamp angle
                let clampedAngle = min(max(dragAngle, -60), 60)

                if let last = lastDragAngle {
                    let delta = clampedAngle - last
                    angularVelocity = delta * 0.5
                }

                angle = clampedAngle
                lastDragAngle = clampedAngle

                // Haptic feedback at extremes
                if abs(clampedAngle) > 55 {
                    hapticEngine.playDetent()
                }
            }
            .onEnded { _ in
                isDragging = false
                lastDragAngle = nil
            }
    }

    // MARK: - Physics

    private func startPhysics() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard !isDragging else { return }

            // Simple pendulum physics
            let angleRadians = angle * .pi / 180
            let acceleration = -gravity * sin(angleRadians)

            angularVelocity += acceleration
            angularVelocity *= damping
            angle += angularVelocity

            // Tick sound at regular intervals
            let tickDelta = abs(angle - lastTickAngle)
            if tickDelta > tickThreshold && abs(angularVelocity) > 0.3 {
                hapticEngine.playDetent()
                lastTickAngle = angle
            }

            // Stop when very slow
            if abs(angularVelocity) < 0.01 && abs(angle) < 0.5 {
                angle = 0
                angularVelocity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        PendulumView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
