import SwiftUI

/// A purchase sheet that matches Knobby's neumorphic aesthetic.
/// Presented when user taps the unlock button on a locked cell.
struct PurchaseSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var themeManager: ThemeManager?
    var motionManager: MotionManager?
    var hapticEngine: HapticEngine?
    var soundEngine: SoundEngine?

    /// Callback when purchase succeeds
    var onPurchaseSuccess: (() -> Void)?

    /// Reference to purchase manager
    private var purchaseManager: PurchaseManager { PurchaseManager.shared }
    private let privacyPolicyURL = URL(string: "https://knobby.app/policy")!

    @State private var isPurchaseButtonPressed = false
    @State private var purchaseButtonDepth: CGFloat = 0
    @State private var appeared = false
    @State private var isPurchasing = false
    @State private var wobbleOffset: CGFloat = 0
    @State private var lifetimePulse: Bool = false

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

    // MARK: - Asphalt Color Palette

    /// Primary text - deep asphalt charcoal
    private var textPrimary: Color {
        isDarkMode ? Color(hex: 0xE8E8EC) : Color(hex: 0x2A2A2E)
    }

    /// Secondary text - medium asphalt gray
    private var textSecondary: Color {
        isDarkMode ? Color(hex: 0x8A8A8E) : Color(hex: 0x5A5A5E)
    }

    /// Tertiary/muted - lighter asphalt
    private var textTertiary: Color {
        isDarkMode ? Color(hex: 0x6A6A6E) : Color(hex: 0x7A7A7E)
    }

    /// Icon color - warm asphalt
    private var iconColor: Color {
        isDarkMode ? Color(hex: 0x9A9A9E) : Color(hex: 0x4A4A4E)
    }

    /// CTA accent - warm amber/gold for the keycap LED
    private var ctaAccentColor: Color {
        Color(hex: 0xE8A850)
    }

    /// Green LED color for "LIFETIME" text - mechanical keyboard RGB style
    private var greenLedColor: Color {
        Color(hex: 0x50E878)
    }

    // Keycap colors matching MechanicalKeycapView
    private var keycapColor: Color {
        isDarkMode ? Color(hex: 0x3A3A3C) : Color(hex: 0xE8E8E8)
    }

    private var keycapTopColor: Color {
        isDarkMode ? Color(hex: 0x4A4A4C) : Color(hex: 0xF5F5F5)
    }

    private var keycapSideColor: Color {
        isDarkMode ? Color(hex: 0x2A2A2C) : Color(hex: 0xD0D0D0)
    }

    // Dynamic tilt properties (matching MechanicalKeycapView)
    private var tiltX: Double { motionManager?.tiltX ?? 0 }
    private var tiltY: Double { motionManager?.tiltY ?? 0 }
    private var reduceMotion: Bool { motionManager?.reduceMotion ?? true }

    // 3D keycap depth constants (matching MechanicalKeycapView)
    private let keycapDepthLayer: CGFloat = 8
    private let taperPerLayer: CGFloat = 2
    private let parallaxStrength: CGFloat = 4

    var body: some View {
        ZStack {
            // Background
            surfaceColor
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Drag indicator
                dragIndicator
                    .padding(.top, 12)

                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Price button
                    purchaseButton

                    // Restore + Dismiss
                    bottomButtons
                }
                .padding(.horizontal, 28)

                Spacer()
                Spacer()
            }

            // Loading overlay
            if isPurchasing {
                loadingOverlay
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            // Start the green LED pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                lifetimePulse = true
            }
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            surfaceColor.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(ctaAccentColor)

                Text("Processing...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(textSecondary)
            }
        }
    }

    // MARK: - Drag Indicator

    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(shadowDark.opacity(0.3))
            .frame(width: 40, height: 5)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Icon - a stylized knob with asphalt indicator
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                surfaceColor,
                                shadowDark.opacity(0.15)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: shadowDark.opacity(0.3), radius: 8, x: 3, y: 3)
                    .shadow(color: shadowLight.opacity(0.8), radius: 8, x: -3, y: -3)

                // Indicator dot - asphalt colored
                Circle()
                    .fill(iconColor)
                    .frame(width: 8, height: 8)
                    .offset(y: -16)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            Text("Unlock the Full Wall")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(textPrimary)
                .tracking(-0.3)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 14) {
            featureRow(icon: "circle.grid.2x2.fill", text: "More tactile objects")
            featureRow(icon: "hand.draw.fill", text: "Different textures & resistance")
            featureRow(icon: "infinity", text: "Unlimited use, forever")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(textSecondary)

            Spacer()
        }
    }

    // MARK: - Purchase Button (Mechanical Keycap Style)

    // Keycap dimensions for wide CTA key (2.25u width)
    private let keycapWidth: CGFloat = 180
    private let keycapHeight: CGFloat = 56
    private let keycapDepth: CGFloat = 12
    private let keycapCornerRadius: CGFloat = 8
    private let maxTravel: CGFloat = 4

    private var purchaseButton: some View {
        // Calculate parallax offset based on tilt (matching MechanicalKeycapView)
        let parallaxX = reduceMotion ? 0 : CGFloat(tiltX) * parallaxStrength * 2.5
        let parallaxY = reduceMotion ? 0 : CGFloat(-tiltY) * parallaxStrength * 2.5

        // Light direction affects which edges appear lit vs shadowed
        let lightAngleX = reduceMotion ? 0.3 : 0.3 - tiltX * 0.5
        let lightAngleY = reduceMotion ? 0.3 : 0.3 + tiltY * 0.5

        return ZStack {
            // LED underglow (beneath everything) - warm amber glow
            ledUnderglow

            // Switch housing / plate
            keycapSwitchHousing

            // === LAYER 1: Bottom/Base layer (largest, creates visible sides) ===
            purchaseKeycapBaseLayer(lightAngleX: lightAngleX, lightAngleY: lightAngleY)
                .offset(
                    x: parallaxX * 0.8,
                    y: parallaxY * 0.8 + purchaseButtonDepth
                )

            // === LAYER 2: Middle body layer ===
            purchaseKeycapMiddleLayer(lightAngleX: lightAngleX, lightAngleY: lightAngleY)
                .offset(
                    x: parallaxX * 0.4,
                    y: -keycapDepthLayer * 0.4 + parallaxY * 0.4 + purchaseButtonDepth
                )

            // === LAYER 3: Top surface (smallest, the dished top) ===
            purchaseKeycapTopLayer(lightAngleX: lightAngleX, lightAngleY: lightAngleY)
                .offset(
                    x: parallaxX * 0.15,
                    y: -keycapDepthLayer * 0.75 + parallaxY * 0.15 + purchaseButtonDepth
                )

            // === LEGEND ===
            purchaseKeycapLegend
                .offset(
                    x: parallaxX * 0.1,
                    y: -keycapDepthLayer * 0.75 + parallaxY * 0.1 + purchaseButtonDepth
                )
        }
        .offset(x: wobbleOffset)
        .animation(.interpolatingSpring(stiffness: 800, damping: 15), value: purchaseButtonDepth)
        .animation(.interpolatingSpring(stiffness: 1000, damping: 10), value: wobbleOffset)
        .frame(width: keycapWidth + 24, height: keycapHeight + 28)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .gesture(purchaseKeyGesture)
    }

    // MARK: - LED Underglow

    private var ledUnderglow: some View {
        RoundedRectangle(cornerRadius: keycapCornerRadius + 4)
            .fill(
                RadialGradient(
                    colors: [
                        ctaAccentColor.opacity(isPurchaseButtonPressed ? 0.9 : 0.5),
                        ctaAccentColor.opacity(isPurchaseButtonPressed ? 0.5 : 0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: keycapWidth * 0.6
                )
            )
            .frame(width: keycapWidth + 28, height: keycapHeight + 20)
            .blur(radius: 10)  // Reduced from 14 for better performance
            .offset(y: 6)
            .drawingGroup()  // Rasterize blur
            .animation(.easeOut(duration: 0.15), value: isPurchaseButtonPressed)
    }

    // MARK: - Switch Housing

    private var keycapSwitchHousing: some View {
        ZStack {
            // Plate cutout (dark recess)
            RoundedRectangle(cornerRadius: keycapCornerRadius + 2)
                .fill(Color.black.opacity(isDarkMode ? 0.6 : 0.4))
                .frame(width: keycapWidth + 6, height: keycapHeight + 6)
                .offset(y: 8)

            // Switch housing visible inside
            RoundedRectangle(cornerRadius: keycapCornerRadius)
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
                .frame(width: keycapWidth - 4, height: keycapHeight - 4)
                .offset(y: 8 + purchaseButtonDepth)

            // Stem cross (visible when key is pressed)
            keycapStemCross
                .opacity(Double(purchaseButtonDepth / maxTravel) * 0.7)
        }
    }

    private var keycapStemCross: some View {
        ZStack {
            // Vertical bar
            RoundedRectangle(cornerRadius: 0.5)
                .fill(ctaAccentColor.opacity(0.9))
                .frame(width: 2, height: 10)

            // Horizontal bar
            RoundedRectangle(cornerRadius: 0.5)
                .fill(ctaAccentColor.opacity(0.9))
                .frame(width: 6, height: 2)
        }
        .offset(y: 8)
    }

    // MARK: - Base Layer (Shows the physical sides)

    private func purchaseKeycapBaseLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        // Base is slightly larger - the visible rim IS the "side" of the keycap
        let baseWidth = keycapWidth + taperPerLayer * 2
        let baseHeight = keycapHeight + taperPerLayer * 2

        // Colors for the base layer - darker, showing physical depth
        let baseColor = isDarkMode ? Color(hex: 0x252528) : Color(hex: 0xB8B8BC)
        let baseLitEdge = isDarkMode ? Color(hex: 0x404045) : Color(hex: 0xD0D0D4)
        let baseShadowEdge = isDarkMode ? Color(hex: 0x18181A) : Color(hex: 0x909094)

        return ZStack {
            // Main base shape with directional lighting gradient
            RoundedRectangle(cornerRadius: keycapCornerRadius + 2)
                .fill(
                    LinearGradient(
                        colors: [baseLitEdge, baseColor, baseShadowEdge],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    )
                )
                .frame(width: baseWidth, height: baseHeight)

            // Inner shadow to create depth between base and middle layer
            RoundedRectangle(cornerRadius: keycapCornerRadius + 1)
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

    private func purchaseKeycapMiddleLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        let middleWidth = keycapWidth + taperPerLayer * 0.5
        let middleHeight = keycapHeight + taperPerLayer * 0.5

        // Middle body colors
        let bodyColor = keycapColor
        let bodyLitEdge = isDarkMode ? Color(hex: 0x505055) : Color(hex: 0xE8E8EC)
        let bodyShadowEdge = isDarkMode ? Color(hex: 0x2A2A2E) : Color(hex: 0xC0C0C4)

        return ZStack {
            // Main body with lit/shadow gradient
            RoundedRectangle(cornerRadius: keycapCornerRadius + 1)
                .fill(
                    LinearGradient(
                        colors: [bodyLitEdge, bodyColor, bodyShadowEdge],
                        startPoint: UnitPoint(x: lightAngleX, y: lightAngleY),
                        endPoint: UnitPoint(x: 1 - lightAngleX, y: 1 - lightAngleY)
                    )
                )
                .frame(width: middleWidth, height: middleHeight)

            // Subtle top edge highlight
            RoundedRectangle(cornerRadius: keycapCornerRadius)
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

    private func purchaseKeycapTopLayer(lightAngleX: Double, lightAngleY: Double) -> some View {
        let topWidth = keycapWidth - taperPerLayer
        let topHeight = keycapHeight - taperPerLayer

        return ZStack {
            // Top surface
            RoundedRectangle(cornerRadius: keycapCornerRadius - 1)
                .fill(keycapTopColor)
                .frame(width: topWidth, height: topHeight)

            // Dish effect (concave center)
            RoundedRectangle(cornerRadius: keycapCornerRadius - 2)
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
            RoundedRectangle(cornerRadius: keycapCornerRadius - 1)
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

    private var purchaseKeycapLegend: some View {
        HStack(spacing: 8) {
            if let price = purchaseManager.lifetimePrice {
                Text(price)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isPurchaseButtonPressed ? ctaAccentColor : textPrimary)

                Text("·")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textTertiary)

                // LIFETIME text with green LED glow and pulse
                Text("LIFETIME")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(greenLedColor)
                    .tracking(1.5)
                    .shadow(
                        color: greenLedColor.opacity(lifetimePulse ? 0.8 : 0.4),
                        radius: lifetimePulse ? 8 : 4
                    )
                    .shadow(
                        color: greenLedColor.opacity(lifetimePulse ? 0.5 : 0.2),
                        radius: lifetimePulse ? 12 : 6
                    )
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: lifetimePulse
                    )
            } else {
                // Loading placeholder
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(textSecondary)
            }
        }
        .offset(y: -keycapDepth * 0.7)
        .shadow(
            color: isPurchaseButtonPressed ? ctaAccentColor.opacity(0.4) : Color.clear,
            radius: 6
        )
        .animation(.easeInOut(duration: 0.15), value: isPurchaseButtonPressed)
    }

    // MARK: - Purchase Key Gesture

    private var purchaseKeyGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                // Disable if purchasing or price not loaded
                guard !isPurchasing, purchaseManager.lifetimePrice != nil else { return }
                if !isPurchaseButtonPressed {
                    isPurchaseButtonPressed = true
                    purchaseButtonDepth = maxTravel

                    // Add slight random wobble for realism
                    wobbleOffset = CGFloat.random(in: -0.5...0.5)

                    // Haptic and sound
                    hapticEngine?.playDetent()
                    soundEngine?.play(.keyThock)
                }
            }
            .onEnded { _ in
                guard !isPurchasing, purchaseManager.lifetimePrice != nil else { return }
                isPurchaseButtonPressed = false
                purchaseButtonDepth = 0
                wobbleOffset = 0

                // Release haptic and sound
                hapticEngine?.playDetent()
                soundEngine?.play(.keyClack)

                // Trigger purchase
                performPurchase()
            }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                // Restore button
                Button {
                    hapticEngine?.playDetent()
                    performRestore()
                } label: {
                    Text("Restore")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textTertiary)
                }
                .buttonStyle(.plain)

                // Dismiss button
                Button {
                    hapticEngine?.playDetent()
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textTertiary)
                }
                .buttonStyle(.plain)
            }

            Link("Privacy Policy", destination: privacyPolicyURL)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textTertiary.opacity(0.8))
                .buttonStyle(.plain)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Purchase Actions

    private func performPurchase() {
        isPurchasing = true

        Task {
            let success = await purchaseManager.purchaseLifetime()
            await MainActor.run {
                isPurchasing = false
                if success {
                    onPurchaseSuccess?()
                    dismiss()
                }
            }
        }
    }

    private func performRestore() {
        isPurchasing = true

        Task {
            let success = await purchaseManager.restorePurchases()
            await MainActor.run {
                isPurchasing = false
                if success {
                    onPurchaseSuccess?()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Purchase Sheet - Light") {
    Color.gray
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PurchaseSheetView(
                motionManager: MotionManager(),
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                onPurchaseSuccess: { print("Success!") }
            )
        }
}

#Preview("Purchase Sheet - Dark") {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            PurchaseSheetView(
                themeManager: ThemeManager(),
                motionManager: MotionManager(),
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                onPurchaseSuccess: { print("Success!") }
            )
        }
        .preferredColorScheme(.dark)
}
