import SwiftUI

/// Finger drawing canvas - draw freely and watch paths fade away.
/// Provides satisfying tactile feedback as you draw with auto-fading trails.
struct DrawPathView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    @State private var currentPath: [CGPoint] = []
    @State private var allPaths: [[CGPoint]] = []
    @State private var pathOpacities: [Double] = []
    @State private var isDrawing = false
    @State private var lastSoundPoint: CGPoint? = nil

    private let soundThreshold: CGFloat = 12 // Distance between sound triggers

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

    // Dynamic stroke colors - gradient through warm tones
    private var strokeColors: [Color] {
        [
            Color(hex: 0x5AB8C8), // Teal
            Color(hex: 0x7A9EC4), // Blue
            Color(hex: 0x9A7AC4), // Purple
            Color(hex: 0xC49A7A), // Coral
            Color(hex: 0x8AB87A), // Green
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas background (subtle inset)
                canvasBackground

                // Fading paths
                ForEach(allPaths.indices, id: \.self) { index in
                    if index < pathOpacities.count {
                        pathShape(for: allPaths[index], colorIndex: index)
                            .opacity(pathOpacities[index])
                    }
                }

                // Current active path
                if !currentPath.isEmpty {
                    pathShape(for: currentPath, colorIndex: allPaths.count)
                        .opacity(1.0)
                }

                // Draw hint when empty
                if allPaths.isEmpty && currentPath.isEmpty {
                    drawHint
                }
            }
            .contentShape(Rectangle())
            .gesture(drawGesture(in: geometry.size))
        }
    }

    // MARK: - Canvas Background

    private var canvasBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        shadowDarkColor.opacity(isDarkMode ? 0.2 : 0.12),
                        surfaceColor.opacity(0.98),
                        shadowLightColor.opacity(isDarkMode ? 0.08 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                shadowDarkColor.opacity(isDarkMode ? 0.3 : 0.18),
                                Color.clear,
                                shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }

    // MARK: - Path Shape

    private func pathShape(for points: [CGPoint], colorIndex: Int) -> some View {
        let color = strokeColors[colorIndex % strokeColors.count]

        return Path { path in
            guard points.count > 1 else { return }

            path.move(to: points[0])

            if points.count == 2 {
                path.addLine(to: points[1])
            } else {
                for i in 1..<points.count {
                    let current = points[i]
                    let previous = points[i - 1]
                    let midPoint = CGPoint(
                        x: (previous.x + current.x) / 2,
                        y: (previous.y + current.y) / 2
                    )
                    path.addQuadCurve(to: midPoint, control: previous)
                }
                if let last = points.last {
                    path.addLine(to: last)
                }
            }
        }
        .stroke(
            LinearGradient(
                colors: [
                    color,
                    color.opacity(0.7),
                    color.opacity(0.5)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(
                lineWidth: 4,
                lineCap: .round,
                lineJoin: .round
            )
        )
        .shadow(color: color.opacity(0.4), radius: 3, x: 0, y: 1)
    }

    // MARK: - Draw Hint

    private var drawHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35))

            Text("draw here")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(shadowDarkColor.opacity(isDarkMode ? 0.4 : 0.3))
                .tracking(0.5)
        }
    }

    // MARK: - Gesture

    private func drawGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location

                // Clamp to bounds with padding
                let padding: CGFloat = 8
                let clampedPoint = CGPoint(
                    x: min(max(point.x, padding), size.width - padding),
                    y: min(max(point.y, padding), size.height - padding)
                )

                if !isDrawing {
                    isDrawing = true
                    currentPath = [clampedPoint]
                    lastSoundPoint = clampedPoint
                    hapticEngine.playDetent()
                    soundEngine.play(.sliderTick)
                } else {
                    currentPath.append(clampedPoint)

                    // Sound feedback based on distance traveled
                    if let lastPoint = lastSoundPoint {
                        let distance = hypot(
                            clampedPoint.x - lastPoint.x,
                            clampedPoint.y - lastPoint.y
                        )
                        if distance > soundThreshold {
                            hapticEngine.playDetent()
                            soundEngine.play(.sliderTick)
                            lastSoundPoint = clampedPoint
                        }
                    }
                }
            }
            .onEnded { _ in
                isDrawing = false
                lastSoundPoint = nil

                // Move current path to all paths
                if currentPath.count > 1 {
                    allPaths.append(currentPath)
                    pathOpacities.append(1.0)
                    let pathIndex = allPaths.count - 1

                    // Start fade animation
                    fadeOutPath(at: pathIndex)
                }
                currentPath = []
            }
    }

    // MARK: - Fade Animation

    private func fadeOutPath(at index: Int) {
        // Gradual fade over 3 seconds
        let fadeDuration: Double = 3.0
        let steps = 30
        let stepDuration = fadeDuration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                guard index < pathOpacities.count else { return }
                let progress = Double(step) / Double(steps)
                pathOpacities[index] = 1.0 - progress

                // Remove when fully faded
                if step == steps {
                    cleanupFadedPaths()
                }
            }
        }
    }

    private func cleanupFadedPaths() {
        // Remove paths with zero opacity
        var indicesToRemove: [Int] = []
        for (index, opacity) in pathOpacities.enumerated() {
            if opacity <= 0.01 {
                indicesToRemove.append(index)
            }
        }

        // Remove in reverse order to maintain indices
        for index in indicesToRemove.reversed() {
            if index < allPaths.count && index < pathOpacities.count {
                allPaths.remove(at: index)
                pathOpacities.remove(at: index)
            }
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        DrawPathView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
        .frame(width: 350, height: 120)
    }
}
