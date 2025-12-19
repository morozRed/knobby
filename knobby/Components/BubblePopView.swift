import SwiftUI

/// Bubble wrap style grid of poppable bubbles.
/// Satisfying pop with reset capability - infinite popping pleasure.
struct BubblePopView: View {
    var motionManager: MotionManager
    var hapticEngine: HapticEngine
    var soundEngine: SoundEngine
    var themeManager: ThemeManager?

    private let gridSizeX = 8
    private let gridSizeY = 3
    private let bubbleSize: CGFloat = 32
    private let spacing: CGFloat = 6

    @State private var poppedBubbles: Set<Int> = []
    @State private var animatingBubbles: Set<Int> = []

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
        VStack(spacing: spacing) {
            ForEach(0..<gridSizeY, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<gridSizeX, id: \.self) { col in
                        let index = row * gridSizeX + col
                        bubbleCell(index: index)
                    }
                }
            }
        }
        .padding(12)
        .background(bubbleWrapBackground)
    }

    // MARK: - Background

    private var bubbleWrapBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        surfaceColor.opacity(0.3),
                        surfaceColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    // MARK: - Bubble Cell

    private func bubbleCell(index: Int) -> some View {
        let isPopped = poppedBubbles.contains(index)
        let isAnimating = animatingBubbles.contains(index)

        return ZStack {
            if isPopped {
                // Popped state (flat indent)
                poppedBubble
            } else {
                // Inflated bubble
                inflatedBubble(isAnimating: isAnimating)
            }
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .contentShape(Circle())
        .onTapGesture {
            if !isPopped {
                popBubble(index: index)
            }
        }
        .onLongPressGesture(minimumDuration: 0.8) {
            // Long press to reset all bubbles
            resetAllBubbles()
        }
    }

    private var poppedBubble: some View {
        ZStack {
            // Flat indent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.3 : 0.2),
                            surfaceColor.opacity(0.5),
                            shadowLightColor.opacity(isDarkMode ? 0.1 : 0.2)
                        ],
                        center: UnitPoint(x: 0.6, y: 0.6),
                        startRadius: 0,
                        endRadius: bubbleSize * 0.4
                    )
                )
                .frame(width: bubbleSize - 4, height: bubbleSize - 4)

            // Inner shadow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            shadowDarkColor.opacity(isDarkMode ? 0.35 : 0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: bubbleSize - 8, height: bubbleSize - 8)
                .blur(radius: 1)
        }
    }

    private func inflatedBubble(isAnimating: Bool) -> some View {
        ZStack {
            // Bubble body - translucent plastic feel
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(isDarkMode ? 0.2 : 0.5),
                            Color(hex: 0xE8E8F0).opacity(isDarkMode ? 0.3 : 0.6),
                            Color(hex: 0xD0D0D8).opacity(isDarkMode ? 0.25 : 0.5)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: bubbleSize * 0.5
                    )
                )
                .frame(width: bubbleSize, height: bubbleSize)
                .shadow(
                    color: shadowLightColor.opacity(isDarkMode ? 0.2 : 0.7),
                    radius: 4,
                    x: -2,
                    y: -2
                )
                .shadow(
                    color: shadowDarkColor.opacity(isDarkMode ? 0.5 : 0.35),
                    radius: 4,
                    x: 2,
                    y: 2
                )

            // Air pocket highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 7)
                .offset(x: -bubbleSize * 0.15, y: -bubbleSize * 0.18)

            // Secondary highlight
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 4, height: 4)
                .offset(x: bubbleSize * 0.08, y: bubbleSize * 0.12)
                .blur(radius: 0.5)

            // Subtle edge reflection
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: bubbleSize - 2, height: bubbleSize - 2)
        }
        .scaleEffect(isAnimating ? 0.7 : 1.0)
        .opacity(isAnimating ? 0.5 : 1.0)
    }

    // MARK: - Actions

    private func popBubble(index: Int) {
        // Start animation
        animatingBubbles.insert(index)

        // Haptic feedback - satisfying pop
        hapticEngine.playDetent()
        soundEngine.play(.buttonPress)

        // Delay then mark as popped
        withAnimation(.easeOut(duration: 0.1)) {
            poppedBubbles.insert(index)
        }

        // Clean up animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animatingBubbles.remove(index)
        }

        // Check if all popped - auto reset after delay
        if poppedBubbles.count == gridSizeY * gridSizeX - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                resetAllBubbles()
            }
        }
    }

    private func resetAllBubbles() {
        // Staggered reset animation
        let indices = Array(0..<(gridSizeY * gridSizeX))
        for (delay, index) in indices.shuffled().enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay) * 0.05) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    poppedBubbles.remove(index)
                }
                if delay % 2 == 0 {
                    hapticEngine.playDetent()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        KnobbyColors.surface.ignoresSafeArea()
        BubblePopView(
            motionManager: MotionManager(),
            hapticEngine: HapticEngine(),
            soundEngine: SoundEngine()
        )
    }
}
