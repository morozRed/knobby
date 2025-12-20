import SwiftUI

struct SensoryWallView: View {
    @State private var motionManager = MotionManager()
    @State private var hapticEngine = HapticEngine()
    @State private var soundEngine = SoundEngine()
    @State private var themeManager = ThemeManager()

    @State private var showFirstLaunchHint = true
    @State private var hasInteracted = false
    @State private var showPurchaseSheet = false

    // MARK: - Pop Animation State
    @State private var cellsAppeared: Set<Int> = []
    @State private var randomizedOrder: [Int] = []
    private let totalCells = 11

    // Unlocked cells (free tier): Knob, Theme Toggle, Toggle Switch
    private let freeCells: Set<Int> = [0, 1, 5]

    // Purchase manager - observed for pro status changes
    private var purchaseManager = PurchaseManager.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Track pro status for SwiftUI observation
    private var isProUser: Bool { purchaseManager.isProUser }

    var body: some View {
        // Reference isProUser directly to ensure SwiftUI tracks changes
        let _ = isProUser

        GeometryReader { geometry in
            ZStack {
                // Premium surface with texture
                surfaceBackground

                // Subtle ambient edge glow
                ambientEdgeGlow

                // Tactile objects in deliberate composition
                objectsLayout(in: geometry)
                    .simultaneousGesture(
                        TapGesture().onEnded { dismissHint() }
                    )

                // First launch hint
                if showFirstLaunchHint {
                    firstLaunchHint
                }
            }
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isProUser)
        .onAppear {
            motionManager.reduceMotion = reduceMotion
            motionManager.startUpdates()
            checkFirstLaunch()
            startPopAnimation()
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .onChange(of: reduceMotion) { _, newValue in
            motionManager.reduceMotion = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            motionManager.stopUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            motionManager.startUpdates()
        }
        .sheet(isPresented: $showPurchaseSheet) {
            PurchaseSheetView(
                themeManager: themeManager,
                hapticEngine: hapticEngine,
                soundEngine: soundEngine,
                onPurchaseSuccess: {
                    // Purchase succeeded - UI will update automatically
                    // via purchaseManager.isProUser observation
                }
            )
        }
    }

    // MARK: - Lock State Helper

    private func isLocked(_ cellIndex: Int) -> Bool {
        // If user is pro, nothing is locked
        if purchaseManager.isProUser {
            return false
        }
        // Otherwise, only free cells are unlocked
        return !freeCells.contains(cellIndex)
    }

    private func showUnlock() {
        showPurchaseSheet = true
    }

    // MARK: - Objects Layout (Grid with Neumorphic Cells)

    private func objectsLayout(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let safeTop = geometry.safeAreaInsets.top
        let padding: CGFloat = 14
        let spacing: CGFloat = 16

        // Calculate cell sizes for a 2-column layout
        let availableWidth = width - (padding * 2)
        let smallCellSize = (availableWidth - spacing) / 2
        let largeCellWidth = availableWidth * 0.62
        let mediumCellWidth = availableWidth * 0.38 - spacing
        let tallCellHeight: CGFloat = 170
        let standardCellHeight: CGFloat = 150
        let shortCellHeight: CGFloat = 130
        let drawPathHeight: CGFloat = 110

        return ScrollView(showsIndicators: false) {
            LazyVStack(spacing: spacing) {
                // Row 1: Main Knob (hero, FREE) + Theme Toggle (FREE)
                HStack(spacing: spacing) {
                    NeumorphicCell(
                        isLocked: isLocked(0),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        KnobView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: largeCellWidth, height: tallCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(0), reduceMotion: reduceMotion)

                    NeumorphicCell(
                        isLocked: isLocked(1),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        ThemeToggleView(
                            themeManager: themeManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine
                        )
                    }
                    .frame(width: mediumCellWidth, height: tallCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(1), reduceMotion: reduceMotion)
                }

                // Row 2: Pressure Button (LOCKED) + Joystick (LOCKED)
                HStack(spacing: spacing) {
                    NeumorphicCell(
                        isLocked: isLocked(2),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        PressureButtonView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(2), reduceMotion: reduceMotion)

                    NeumorphicCell(
                        isLocked: isLocked(3),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        JoystickView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(3), reduceMotion: reduceMotion)
                }

                // Row 3: Roller Ball (LOCKED) + Toggle Switch (FREE)
                HStack(spacing: spacing) {
                    NeumorphicCell(
                        isLocked: isLocked(4),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        RollerBallView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(4), reduceMotion: reduceMotion)

                    NeumorphicCell(
                        isLocked: isLocked(5),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        ToggleSwitchView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(5), reduceMotion: reduceMotion)
                }

                // Row 4: Bubble Pop (LOCKED, full width)
                NeumorphicCell(
                    isLocked: isLocked(6),
                    themeManager: themeManager,
                    hapticEngine: hapticEngine,
                    soundEngine: soundEngine,
                    onUnlockTapped: showUnlock
                ) {
                    BubblePopView(
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        themeManager: themeManager
                    )
                }
                .frame(width: availableWidth, height: shortCellHeight)
                .popFromSurface(isVisible: cellHasAppeared(6), reduceMotion: reduceMotion)

                // Row 5: Frequency Dial (LOCKED) + Keycap (LOCKED)
                HStack(spacing: spacing) {
                    NeumorphicCell(
                        isLocked: isLocked(7),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        FrequencyDialView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(7), reduceMotion: reduceMotion)

                    NeumorphicCell(
                        isLocked: isLocked(8),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        MechanicalKeycapView(
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager,
                            primaryIcon: "power",
                            primaryText: "OFF",
                            secondaryIcon: "bolt.fill",
                            secondaryText: "ON",
                            accentColor: Color(hex: 0x7C5CFF)
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(8), reduceMotion: reduceMotion)
                }

                // Row 6: Tap Pad (LOCKED, full width)
                NeumorphicCell(
                    isLocked: isLocked(9),
                    themeManager: themeManager,
                    hapticEngine: hapticEngine,
                    soundEngine: soundEngine,
                    onUnlockTapped: showUnlock
                ) {
                    TapPadView(
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        themeManager: themeManager
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
                .frame(width: availableWidth, height: standardCellHeight)
                .popFromSurface(isVisible: cellHasAppeared(9), reduceMotion: reduceMotion)

                // Row 7: Click Counter (LOCKED, half width) - TE-style mechanical key + LCD
                HStack(spacing: spacing) {
                    NeumorphicCell(
                        isLocked: isLocked(10),
                        themeManager: themeManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        PressureMeterView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(10), reduceMotion: reduceMotion)

                    Spacer()
                }

                // Bottom padding for safe scrolling
                Spacer().frame(height: 20)
            }
            .padding(.horizontal, padding)
        }
    }

    // MARK: - Surface Background (Neumorphic)

    private var surfaceBackground: some View {
        ZStack {
            // Soft base color
            themeManager.surface

            // Subtle gradient from top-left (light source)
            LinearGradient(
                colors: [
                    themeManager.shadowLight.opacity(themeManager.isDarkMode ? 0.1 : 0.3),
                    Color.clear,
                    themeManager.shadowDark.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .drawingGroup() // Rasterize entire background stack
        .ignoresSafeArea()
    }

    // MARK: - Ambient Edge Glow

    private var ambientEdgeGlow: some View {
        ZStack {
            // Soft top-left highlight (light source indication)
            RadialGradient(
                colors: [
                    themeManager.shadowLight.opacity(themeManager.isDarkMode ? 0.08 : 0.2),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.05),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            // Subtle bottom-right shadow
            RadialGradient(
                colors: [
                    Color.clear,
                    themeManager.shadowDark.opacity(0.1)
                ],
                center: UnitPoint(x: 0.9, y: 0.95),
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
        .drawingGroup() // Rasterize gradients to avoid per-frame recalculation
        .allowsHitTesting(false)
    }

    // MARK: - First Launch Hint

    private var firstLaunchHint: some View {
        VStack {
            Spacer()

            Text("Touch anything. There's nothing to finish.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .tracking(0.3)
                .foregroundColor(themeManager.textSubtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
                .transition(.opacity)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func dismissHint() {
        guard showFirstLaunchHint else { return }

        withAnimation(.easeOut(duration: 0.5)) {
            showFirstLaunchHint = false
        }

        // Mark as interacted (persist for future launches)
        if !hasInteracted {
            hasInteracted = true
            UserDefaults.standard.set(true, forKey: "knobby.hasInteracted")
        }
    }

    private func checkFirstLaunch() {
        hasInteracted = UserDefaults.standard.bool(forKey: "knobby.hasInteracted")
        if hasInteracted {
            showFirstLaunchHint = false
        } else {
            // Auto-dismiss after 5 seconds per PRD
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismissHint()
            }
        }
    }

    // MARK: - Pop Animation

    private func startPopAnimation() {
        // Generate random order for cell appearance
        randomizedOrder = Array(0..<totalCells).shuffled()

        // Stagger the appearances with delightful timing
        for (sequenceIndex, cellIndex) in randomizedOrder.enumerated() {
            let baseDelay = 0.15 // Initial pause before first pop
            let staggerDelay = Double(sequenceIndex) * 0.08 // 80ms between each pop

            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay + staggerDelay) {
                withAnimation(popSpring) {
                    _ = cellsAppeared.insert(cellIndex)
                }
            }
        }
    }

    // Satisfying spring with slight overshoot for "pop" feel
    private var popSpring: Animation {
        if reduceMotion {
            return .easeOut(duration: 0.2)
        }
        return .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }

    private func cellHasAppeared(_ index: Int) -> Bool {
        reduceMotion || cellsAppeared.contains(index)
    }
}

// MARK: - Pop Animation Modifier

struct PopFromSurface: ViewModifier {
    let isVisible: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.3)
            .offset(y: isVisible ? 0 : 25)
            .opacity(isVisible ? 1 : 0)
            // Removed blur - it's expensive and the scale+opacity+offset provides sufficient effect
    }
}

/// Deterministic random number generator for consistent noise patterns
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64 algorithm
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

extension View {
    func popFromSurface(isVisible: Bool, reduceMotion: Bool = false) -> some View {
        modifier(PopFromSurface(isVisible: isVisible, reduceMotion: reduceMotion))
    }
}

#Preview {
    SensoryWallView()
}
