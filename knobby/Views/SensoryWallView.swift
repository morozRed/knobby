import SwiftUI

struct SensoryWallView: View {
    @State private var motionManager = MotionManager()
    @State private var hapticEngine = HapticEngine()
    @State private var soundEngine = SoundEngine()
    @State private var themeManager = ThemeManager()

    @State private var showPurchaseSheet = false

    // MARK: - Pop Animation State
    @State private var cellsAppeared: Set<Int> = []
    @State private var randomizedOrder: [Int] = []
    private let totalCells = 12

    // MARK: - Unlock Animation State
    @State private var revealedCells: Set<Int> = []

    // Unlocked cells (free tier): Knob, Theme Toggle, Toggle Switch, Branding Plate
    private let freeCells: Set<Int> = [0, 1, 5, 11]

    // Cells that are locked for free users (complement of freeCells)
    private let lockedCellIndices: [Int] = [2, 3, 4, 6, 7, 8, 9, 10]

    // Purchase manager - observed for pro status changes
    private var purchaseManager = PurchaseManager.shared

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Track pro status for SwiftUI observation
    private var isProUser: Bool { purchaseManager.isProUser }

    var body: some View {
        // Reference isProUser directly to ensure SwiftUI tracks changes
        let _ = isProUser

        GeometryReader { geometry in
            let safeTop = geometry.safeAreaInsets.top

            ZStack {
                // Premium surface with texture - extends under status bar
                surfaceBackground

                // Subtle ambient edge glow
                ambientEdgeGlow

                // All content in a single ScrollView - status bar scrolls with content
                objectsLayout(in: geometry, safeTop: safeTop)
            }
        }
        .statusBarHidden()
        .ignoresSafeArea()
        // Removed global animation - staggered unlock now handled by animateUnlock()
        .onAppear {
            motionManager.reduceMotion = reduceMotion
            motionManager.startUpdates()
            startPopAnimation()

            // If already pro, mark all locked cells as revealed (no stagger needed)
            if purchaseManager.isProUser {
                revealedCells = Set(lockedCellIndices)
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .onChange(of: reduceMotion) { _, newValue in
            motionManager.reduceMotion = newValue
        }
        .onChange(of: purchaseManager.isProUser) { wasProUser, isProUser in
            // Trigger staggered unlock animation when user becomes pro
            if isProUser && !wasProUser {
                animateUnlock()
            }
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
                motionManager: motionManager,
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
        // Free cells are never locked
        if freeCells.contains(cellIndex) {
            return false
        }
        // Pro users: check if cell has been revealed (for staggered animation)
        if purchaseManager.isProUser {
            return !revealedCells.contains(cellIndex)
        }
        // Non-pro: locked
        return true
    }

    private func showUnlock() {
        showPurchaseSheet = true
    }

    @ViewBuilder
    private func unlockedContent<Content: View>(
        _ isLocked: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isLocked {
            EmptyView()
        } else {
            content()
        }
    }

    // MARK: - Objects Layout (Grid with Neumorphic Cells)

    private func objectsLayout(in geometry: GeometryProxy, safeTop: CGFloat) -> some View {
        let width = geometry.size.width
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
                // Custom status bar - scrolls with content, positioned below Dynamic Island
                CustomStatusBarView(
                    themeManager: themeManager,
                    motionManager: motionManager
                )
                .padding(.top, safeTop > 50 ? safeTop + 28 : safeTop + 14)
                .padding(.bottom, 8)

                // Row 1: Main Knob (hero, FREE) + Theme Toggle (FREE)
                HStack(spacing: spacing) {
                    let isLocked0 = isLocked(0)
                    NeumorphicCell(
                        isLocked: isLocked0,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked0) {
                            KnobView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: largeCellWidth, height: tallCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(0), reduceMotion: reduceMotion)

                    let isLocked1 = isLocked(1)
                    NeumorphicCell(
                        isLocked: isLocked1,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked1) {
                            ThemeToggleView(
                                themeManager: themeManager,
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine
                            )
                        }
                    }
                    .frame(width: mediumCellWidth, height: tallCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(1), reduceMotion: reduceMotion)
                }

                // Row 2: Pressure Button (LOCKED) + Joystick (LOCKED)
                HStack(spacing: spacing) {
                    let isLocked2 = isLocked(2)
                    NeumorphicCell(
                        isLocked: isLocked2,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked2) {
                            PressureButtonView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(2), reduceMotion: reduceMotion)

                    let isLocked3 = isLocked(3)
                    NeumorphicCell(
                        isLocked: isLocked3,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked3) {
                            JoystickView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(3), reduceMotion: reduceMotion)
                }

                // Row 3: Roller Ball (LOCKED) + Toggle Switch (FREE)
                HStack(spacing: spacing) {
                    let isLocked4 = isLocked(4)
                    NeumorphicCell(
                        isLocked: isLocked4,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked4) {
                            RollerBallView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(4), reduceMotion: reduceMotion)

                    let isLocked5 = isLocked(5)
                    NeumorphicCell(
                        isLocked: isLocked5,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked5) {
                            ToggleSwitchView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(5), reduceMotion: reduceMotion)
                }

                // Row 4: Bubble Pop (LOCKED, full width)
                let isLocked6 = isLocked(6)
                NeumorphicCell(
                    isLocked: isLocked6,
                    themeManager: themeManager,
                    motionManager: motionManager,
                    hapticEngine: hapticEngine,
                    soundEngine: soundEngine,
                    onUnlockTapped: showUnlock
                ) {
                    unlockedContent(isLocked6) {
                        BubblePopView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                    }
                }
                .frame(width: availableWidth, height: shortCellHeight)
                .popFromSurface(isVisible: cellHasAppeared(6), reduceMotion: reduceMotion)

                // Row 5: Frequency Dial (LOCKED) + Keycap (LOCKED)
                HStack(spacing: spacing) {
                    let isLocked7 = isLocked(7)
                    NeumorphicCell(
                        isLocked: isLocked7,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked7) {
                            FrequencyDialView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(7), reduceMotion: reduceMotion)

                    let isLocked8 = isLocked(8)
                    NeumorphicCell(
                        isLocked: isLocked8,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked8) {
                            MechanicalKeycapView(
                                motionManager: motionManager,
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
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(8), reduceMotion: reduceMotion)
                }

                // Row 6: Tap Pad (LOCKED, full width)
                let isLocked9 = isLocked(9)
                NeumorphicCell(
                    isLocked: isLocked9,
                    themeManager: themeManager,
                    motionManager: motionManager,
                    hapticEngine: hapticEngine,
                    soundEngine: soundEngine,
                    onUnlockTapped: showUnlock
                ) {
                    unlockedContent(isLocked9) {
                        TapPadView(
                            motionManager: motionManager,
                            hapticEngine: hapticEngine,
                            soundEngine: soundEngine,
                            themeManager: themeManager
                        )
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    }
                }
                .frame(width: availableWidth, height: standardCellHeight)
                .popFromSurface(isVisible: cellHasAppeared(9), reduceMotion: reduceMotion)

                // Row 7: Pressure Meter (LOCKED) + Branding Plate (decorative)
                HStack(spacing: spacing) {
                    let isLocked10 = isLocked(10)
                    NeumorphicCell(
                        isLocked: isLocked10,
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: showUnlock
                    ) {
                        unlockedContent(isLocked10) {
                            PressureMeterView(
                                motionManager: motionManager,
                                hapticEngine: hapticEngine,
                                soundEngine: soundEngine,
                                themeManager: themeManager
                            )
                        }
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(10), reduceMotion: reduceMotion)

                    // Branding plate - decorative nameplate showing "knobby"
                    NeumorphicCell(
                        isLocked: false,  // Never locked, it's just branding
                        themeManager: themeManager,
                        motionManager: motionManager,
                        hapticEngine: hapticEngine,
                        soundEngine: soundEngine,
                        onUnlockTapped: nil
                    ) {
                        BrandingPlateView(
                            motionManager: motionManager,
                            themeManager: themeManager
                        )
                    }
                    .frame(width: smallCellSize, height: standardCellHeight)
                    .popFromSurface(isVisible: cellHasAppeared(11), reduceMotion: reduceMotion)
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
        .allowsHitTesting(false)
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

    // MARK: - Unlock Animation

    /// Stagger the unlock animation to spread GPU load across multiple frames
    private func animateUnlock() {
        // Shuffle for organic feel (similar to startPopAnimation)
        let shuffled = lockedCellIndices.shuffled()

        for (index, cellIndex) in shuffled.enumerated() {
            let delay = Double(index) * 0.06  // 60ms between each cell
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = revealedCells.insert(cellIndex)
                }
            }
        }
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
