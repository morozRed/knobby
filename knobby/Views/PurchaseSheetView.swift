import SwiftUI

/// A purchase sheet that matches Knobby's neumorphic aesthetic.
/// Presented when user taps the unlock button on a locked cell.
struct PurchaseSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var themeManager: ThemeManager?
    var hapticEngine: HapticEngine?
    var soundEngine: SoundEngine?

    /// Callback when purchase succeeds
    var onPurchaseSuccess: (() -> Void)?

    /// Reference to purchase manager
    private var purchaseManager: PurchaseManager { PurchaseManager.shared }

    @State private var isPurchaseButtonPressed = false
    @State private var purchaseButtonDepth: CGFloat = 0
    @State private var appeared = false
    @State private var isPurchasing = false

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

    private var textPrimary: Color {
        isDarkMode ? .white : Color(hex: 0x3A3A42)
    }

    private var textSecondary: Color {
        isDarkMode ? Color(hex: 0x8A8A8A) : Color(hex: 0x6A6A6A)
    }

    private var accentColor: Color {
        Color(hex: 0x5A7A68) // Deep sage green
    }

    var body: some View {
        ZStack {
            // Background
            surfaceColor
                .ignoresSafeArea()

            // Subtle texture
            backgroundTexture
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
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            surfaceColor.opacity(0.8)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.2)
                .tint(accentColor)
        }
    }

    // MARK: - Background Texture

    private var backgroundTexture: some View {
        ZStack {
            // Gradient from top-left light source
            LinearGradient(
                colors: [
                    shadowLight.opacity(isDarkMode ? 0.08 : 0.25),
                    Color.clear,
                    shadowDark.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle noise
            Canvas { context, size in
                for _ in 0..<200 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let grainOpacity = Double.random(in: 0.01...0.025)
                    let grainSize = CGFloat.random(in: 0.5...1.0)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: grainSize, height: grainSize)),
                        with: .color(isDarkMode ? .white.opacity(grainOpacity) : .black.opacity(grainOpacity))
                    )
                }
            }
            .drawingGroup()
            .allowsHitTesting(false)
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
        VStack(spacing: 10) {
            // Icon - a stylized knob
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

                // Indicator dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .offset(y: -16)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            Text("Unlock the Full Wall")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(textPrimary)
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
                .foregroundColor(accentColor)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textSecondary)

            Spacer()
        }
    }

    // MARK: - Purchase Button (Mechanical Keycap Style)

    private var purchaseButton: some View {
        let keyWidth: CGFloat = 220
        let keyHeight: CGFloat = 56
        let cornerRadius: CGFloat = 12
        let maxTravel: CGFloat = 4

        return ZStack {
            // Shadow depth
            RoundedRectangle(cornerRadius: cornerRadius + 1)
                .fill(shadowDark.opacity(isDarkMode ? 0.5 : 0.35))
                .frame(width: keyWidth, height: keyHeight)
                .offset(y: 5 - purchaseButtonDepth * 0.5)
                .blur(radius: 3)

            // Housing recess
            RoundedRectangle(cornerRadius: cornerRadius + 2)
                .fill(accentColor.opacity(0.3))
                .frame(width: keyWidth + 8, height: keyHeight + 8)
                .offset(y: 4)

            // Main button
            ZStack {
                // Base
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: keyWidth, height: keyHeight)

                // Top highlight
                RoundedRectangle(cornerRadius: cornerRadius - 1)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: keyWidth - 4, height: keyHeight - 4)

                // Border
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: keyWidth, height: keyHeight)

                // Content - dynamic price from RevenueCat
                HStack(spacing: 10) {
                    if let price = purchaseManager.lifetimePrice {
                        Text(price)
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("lifetime")
                            .font(.system(size: 14, weight: .medium))
                            .opacity(0.75)
                    } else {
                        // Loading placeholder
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                }
                .foregroundColor(.white)
            }
            .offset(y: -purchaseButtonDepth)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Disable if purchasing or price not loaded
                    guard !isPurchasing, purchaseManager.lifetimePrice != nil else { return }
                    if !isPurchaseButtonPressed {
                        isPurchaseButtonPressed = true
                        withAnimation(.interpolatingSpring(stiffness: 800, damping: 15)) {
                            purchaseButtonDepth = maxTravel
                        }
                        hapticEngine?.playDetent()
                        soundEngine?.play(.keyThock)
                    }
                }
                .onEnded { _ in
                    guard !isPurchasing, purchaseManager.lifetimePrice != nil else { return }
                    isPurchaseButtonPressed = false
                    withAnimation(.interpolatingSpring(stiffness: 600, damping: 18)) {
                        purchaseButtonDepth = 0
                    }
                    hapticEngine?.playDetent()
                    soundEngine?.play(.keyClack)

                    // Trigger purchase
                    performPurchase()
                }
        )
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 24) {
            // Restore button
            Button {
                hapticEngine?.playDetent()
                performRestore()
            } label: {
                Text("Restore")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textSecondary.opacity(0.7))
            }
            .buttonStyle(.plain)

            // Dismiss button
            Button {
                hapticEngine?.playDetent()
                dismiss()
            } label: {
                Text("Not now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textSecondary.opacity(0.7))
            }
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
                hapticEngine: HapticEngine(),
                soundEngine: SoundEngine(),
                onPurchaseSuccess: { print("Success!") }
            )
        }
        .preferredColorScheme(.dark)
}
