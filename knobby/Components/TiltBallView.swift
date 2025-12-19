import SwiftUI
import QuartzCore

/// A minimalist ball rolling in a soft depression that responds to device tilt.
/// Tilt your device to roll the ball around - it bounces off walls with haptic feedback.
struct TiltBallView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var ballPosition: CGPoint = .zero
    @State private var physicsController: TiltBallPhysicsController?

    private let trackWidth: CGFloat = 280
    private let trackHeight: CGFloat = 100
    private let ballRadius: CGFloat = 12

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

    // Track bounds
    private var maxOffsetX: CGFloat {
        (trackWidth / 2) - ballRadius - 12
    }

    private var maxOffsetY: CGFloat {
        (trackHeight / 2) - ballRadius - 12
    }

    var body: some View {
        ZStack {
            // Soft recessed track
            trackContainer

            // Rolling ball - position updated directly from display link
            ball
                .offset(x: ballPosition.x, y: ballPosition.y)
        }
        .frame(width: trackWidth + 24, height: trackHeight + 24)
        .onAppear {
            startPhysics()
        }
        .onDisappear {
            physicsController?.stop()
        }
    }

    // MARK: - Track Container

    private var trackContainer: some View {
        ZStack {
            // Soft recessed capsule track
            Capsule()
                .fill(surfaceColor)
                .frame(width: trackWidth, height: trackHeight)
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.6 : 0.35),
                    radius: 6,
                    x: 4,
                    y: 4
                )
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.15 : 0.7),
                    radius: 6,
                    x: -4,
                    y: -4
                )

            // Inner shadow for depth
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.2),
                            Color.clear,
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: trackWidth - 4, height: trackHeight - 4)
                .blur(radius: 1)
        }
    }

    // MARK: - Ball

    private var ball: some View {
        ZStack {
            // Soft shadow underneath
            Ellipse()
                .fill(Color.black.opacity(isDarkMode ? 0.3 : 0.15))
                .frame(width: ballRadius * 1.6, height: ballRadius * 0.4)
                .offset(y: ballRadius * 0.6)
                .blur(radius: 2)

            // Simple frosted ball
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (isDarkMode ? Color.white.opacity(0.15) : Color.white.opacity(0.9)),
                            (isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: ballRadius
                    )
                )
                .frame(width: ballRadius * 2, height: ballRadius * 2)

            // Subtle highlight
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isDarkMode ? 0.4 : 0.8),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 6, height: 6)
                .offset(x: -ballRadius * 0.3, y: -ballRadius * 0.3)

            // Soft rim
            Circle()
                .stroke(
                    Color.white.opacity(isDarkMode ? 0.1 : 0.3),
                    lineWidth: 0.5
                )
                .frame(width: ballRadius * 2 - 1, height: ballRadius * 2 - 1)
        }
    }

    // MARK: - Physics

    private func startPhysics() {
        let controller = TiltBallPhysicsController(
            motionManager: motionManager,
            hapticEngine: hapticEngine,
            soundEngine: soundEngine,
            maxOffsetX: maxOffsetX,
            maxOffsetY: maxOffsetY,
            onPositionUpdate: { newPosition in
                ballPosition = newPosition
            }
        )
        controller.start()
        physicsController = controller
    }
}

// MARK: - CADisplayLink Physics Controller

/// High-performance physics controller using CADisplayLink for smooth 60/120fps updates
final class TiltBallPhysicsController {
    private var displayLink: CADisplayLink?
    private let motionManager: MotionManager
    private let hapticEngine: HapticEngine
    private let soundEngine: SoundEngine
    private let onPositionUpdate: (CGPoint) -> Void

    // Physics state
    private var position: CGPoint = .zero
    private var velocity: CGPoint = .zero

    // Bounds
    private let maxOffsetX: CGFloat
    private let maxOffsetY: CGFloat

    // Physics constants - tuned for smooth feel
    private let friction: CGFloat = 0.985
    private let gravity: CGFloat = 0.6
    private let bounceDamping: CGFloat = 0.45

    // Wall contact tracking
    private var touchingLeft = false
    private var touchingRight = false
    private var touchingTop = false
    private var touchingBottom = false

    init(
        motionManager: MotionManager,
        hapticEngine: HapticEngine,
        soundEngine: SoundEngine,
        maxOffsetX: CGFloat,
        maxOffsetY: CGFloat,
        onPositionUpdate: @escaping (CGPoint) -> Void
    ) {
        self.motionManager = motionManager
        self.hapticEngine = hapticEngine
        self.soundEngine = soundEngine
        self.maxOffsetX = maxOffsetX
        self.maxOffsetY = maxOffsetY
        self.onPositionUpdate = onPositionUpdate
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func update(_ displayLink: CADisplayLink) {
        // Update motion manager's smoothed values
        motionManager.updateSmoothedValues()

        // Get delta time for frame-rate independent physics
        let dt = displayLink.targetTimestamp - displayLink.timestamp
        let timeScale = CGFloat(min(dt * 60.0, 2.0)) // Normalize to 60fps, cap at 2x

        // Apply gravity based on device tilt
        let gravityX = CGFloat(motionManager.tiltX) * gravity * timeScale
        let gravityY = CGFloat(-motionManager.tiltY) * gravity * timeScale

        velocity.x += gravityX
        velocity.y += gravityY

        // Apply friction (frame-rate adjusted)
        let frictionAdjusted = pow(friction, timeScale)
        velocity.x *= frictionAdjusted
        velocity.y *= frictionAdjusted

        // Update position
        var newX = position.x + velocity.x * timeScale
        var newY = position.y + velocity.y * timeScale

        // Wall collision detection
        var newContact = false

        if newX < -maxOffsetX {
            newX = -maxOffsetX
            velocity.x = -velocity.x * bounceDamping
            if !touchingLeft { newContact = true }
            touchingLeft = true
        } else {
            touchingLeft = false
        }

        if newX > maxOffsetX {
            newX = maxOffsetX
            velocity.x = -velocity.x * bounceDamping
            if !touchingRight { newContact = true }
            touchingRight = true
        } else {
            touchingRight = false
        }

        if newY < -maxOffsetY {
            newY = -maxOffsetY
            velocity.y = -velocity.y * bounceDamping
            if !touchingTop { newContact = true }
            touchingTop = true
        } else {
            touchingTop = false
        }

        if newY > maxOffsetY {
            newY = maxOffsetY
            velocity.y = -velocity.y * bounceDamping
            if !touchingBottom { newContact = true }
            touchingBottom = true
        } else {
            touchingBottom = false
        }

        // Haptic and sound only on new wall contact
        if newContact {
            hapticEngine.playDetent()
            soundEngine.play(.joystickSnap)
        }

        position = CGPoint(x: newX, y: newY)
        onPositionUpdate(position)
    }

    deinit {
        stop()
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        TiltBallView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
