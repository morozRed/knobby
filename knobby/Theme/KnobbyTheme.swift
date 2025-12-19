import SwiftUI

// MARK: - Color Palette (Neumorphic Soft UI)

enum KnobbyColors {
    // Base surface - warm soft gray
    static let surface = Color(hex: 0xE4E4E8)           // Main background
    static let surfaceLight = Color(hex: 0xEEEEF2)      // Lighter areas
    static let surfaceMid = Color(hex: 0xE4E4E8)        // Primary surface
    static let surfaceDark = Color(hex: 0xD8D8DC)       // Slightly darker
    static let surfaceDarkMid = Color(hex: 0xDCDCE0)    // Mid-dark

    // Neumorphic shadows - ENHANCED for more depth
    static let shadowDark = Color(hex: 0xA8A8B0)        // Deeper bottom-right shadow
    static let shadowLight = Color.white                 // Top-left highlight
    static let shadowInsetDark = Color(hex: 0xB0B0B8)   // Deeper inset dark
    static let shadowInsetLight = Color(hex: 0xFAFAFF)  // Inset light

    // Soft element colors (same as surface for neumorphic)
    static let knobBody = Color(hex: 0xE4E4E8)          // Matches surface
    static let knobHighlight = Color(hex: 0xF5F5F9)     // Bright highlight
    static let knobShadow = Color(hex: 0xB8B8C0)        // Deeper soft shadow
    static let knobRidge = Color(hex: 0xD5D5D9)         // Subtle ridges
    static let knobIndicator = Color(hex: 0x5A5A66)     // Graphite indicator

    // Recessed/inset areas
    static let metalDark = Color(hex: 0xD0D0D4)         // Recessed surface
    static let metalDeep = Color(hex: 0xC8C8CC)         // Deeper recess
    static let metalRim = Color(hex: 0xE8E8EC)          // Rim highlight

    // Primary accent - GRAPHITE (dark charcoal with subtle warmth)
    static let accent = Color(hex: 0x4A4A52)            // Main graphite
    static let accentLight = Color(hex: 0x6A6A75)       // Lighter graphite
    static let accentDark = Color(hex: 0x3A3A42)        // Darker graphite
    static let accentGlow = Color(hex: 0x7A7A88)        // Graphite glow

    // Secondary accent - cool graphite
    static let accentCool = Color(hex: 0x505058)        // Cool graphite
    static let accentCoolGlow = Color(hex: 0x686870)    // Cool glow

    // Text
    static let textPrimary = Color(hex: 0x4A4A52)       // Dark gray text
    static let textSubtle = Color(hex: 0x9090A0)        // Muted text
    static let textOnDark = Color.white

    // MARK: - Dark Mode Colors

    static let surfaceDarkMode = Color(hex: 0x2A2A30)           // Dark background
    static let surfaceLightDarkMode = Color(hex: 0x363640)      // Lighter dark areas
    static let surfaceMidDarkMode = Color(hex: 0x2A2A30)        // Primary dark surface
    static let surfaceDarkDarkMode = Color(hex: 0x202028)       // Deeper dark

    static let shadowDarkDarkMode = Color(hex: 0x18181C)        // Deep shadow for dark mode
    static let shadowLightDarkMode = Color(hex: 0x404050)       // Highlight for dark mode
}

// MARK: - Dimensions

enum KnobbyDimensions {
    // Grid system - 50% of iPhone 14 Pro width (393pt / 2 ≈ 195pt)
    static let gridUnit: CGFloat = 195

    // Knob sizing
    static let knobDiameter: CGFloat = 160
    static let knobHeight: CGFloat = 45                  // Visual depth
    static let ridgeCount: Int = 24                      // Grip ridges around edge
    static let ridgeWidth: CGFloat = 2
    static let ridgeHeight: CGFloat = 12
    static let indicatorSize: CGFloat = 8

    // Shadow
    static let shadowMaxOffset: CGFloat = 15             // Parallax range
    static let shadowBlurRadius: CGFloat = 20
    static let shadowOpacity: Double = 0.3

    // Animation
    static let motionUpdateInterval: Double = 1.0 / 60.0 // 60Hz
}

// MARK: - Haptic Parameters

enum KnobbyHaptics {
    static let detentIntensity: Float = 0.6
    static let detentSharpness: Float = 0.8
    static let rotationDegreePerDetent: Double = 15.0    // 24 detents per revolution
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
