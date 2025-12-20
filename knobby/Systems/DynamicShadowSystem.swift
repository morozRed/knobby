import SwiftUI

/// Centralized shadow and 3D effect calculations responding to device tilt.
/// Creates the illusion of a fixed overhead light source and physical object depth.
///
/// DESIGN PHILOSOPHY: Effects should be VISCERAL and PHYSICAL.
/// This is a tactile fidget app - users should FEEL the parallax when tilting.
/// Subtle = boring. We want satisfying, tangible depth.
enum DynamicShadow {

    // MARK: - Intensity Multipliers (Tune these for overall effect strength)

    /// Master intensity multiplier for all tilt effects (1.0 = default, 2.0 = 2x stronger)
    private static let intensity: Double = 2.5

    // MARK: - Shadow Offset Calculation

    /// Calculates shadow offset based on device tilt.
    /// When device tilts right, shadows shift left (light appears fixed above).
    static func shadowOffsets(
        tiltX: Double,
        tiltY: Double,
        maxOffset: CGFloat = KnobbyDimensions.shadowMaxOffset,
        reduceMotion: Bool = false
    ) -> (light: CGSize, dark: CGSize) {
        guard !reduceMotion else {
            // Static fallback for accessibility
            let staticOffset: CGFloat = maxOffset * 0.4
            return (
                light: CGSize(width: -staticOffset, height: -staticOffset),
                dark: CGSize(width: staticOffset, height: staticOffset)
            )
        }

        // BOOSTED: Shadow displacement is now much more dramatic
        // Light source is "fixed" above-left, so tilting right moves shadow left
        let shadowX = -CGFloat(tiltX) * maxOffset * 1.4 * intensity
        let shadowY = -CGFloat(tiltY) * maxOffset * 1.4 * intensity

        // Base offset (static component) + dynamic component
        let baseOffset: CGFloat = maxOffset * 0.25

        return (
            light: CGSize(
                width: -baseOffset + shadowX * 0.4,
                height: -baseOffset + shadowY * 0.4
            ),
            dark: CGSize(
                width: baseOffset - shadowX,
                height: baseOffset - shadowY
            )
        )
    }

    // MARK: - Gradient Center Calculation

    /// Calculates gradient center point for convex surfaces (raised elements).
    /// Light reflects from top-left, shifting with device tilt.
    static func convexGradientCenter(
        tiltX: Double,
        tiltY: Double,
        reduceMotion: Bool = false
    ) -> UnitPoint {
        guard !reduceMotion else {
            return UnitPoint(x: 0.35, y: 0.35) // Static fallback
        }

        // BOOSTED: Gradient center shifts dramatically with tilt
        // Creates very noticeable "light rolling across surface" effect
        let centerX = 0.35 - tiltX * 0.4 * intensity
        let centerY = 0.35 + tiltY * 0.4 * intensity

        return UnitPoint(
            x: clamp(centerX, to: 0.0...0.7),
            y: clamp(centerY, to: 0.0...0.7)
        )
    }

    /// Calculates gradient center for concave surfaces (inset/recessed elements).
    /// Shadow pools in the direction opposite to the light.
    static func concaveGradientCenter(
        tiltX: Double,
        tiltY: Double,
        reduceMotion: Bool = false
    ) -> UnitPoint {
        guard !reduceMotion else {
            return UnitPoint(x: 0.65, y: 0.65) // Static fallback
        }

        // BOOSTED: Shadow pooling is more dramatic
        let centerX = 0.65 + tiltX * 0.35 * intensity
        let centerY = 0.65 - tiltY * 0.35 * intensity

        return UnitPoint(
            x: clamp(centerX, to: 0.3...1.0),
            y: clamp(centerY, to: 0.3...1.0)
        )
    }

    // MARK: - Highlight Position Calculation

    /// Calculates position offset for specular highlight (shiny reflection spot).
    /// Used for top-left highlights on raised objects.
    static func highlightOffset(
        tiltX: Double,
        tiltY: Double,
        baseOffset: CGSize,
        maxShift: CGFloat = 18,  // BOOSTED from 8
        reduceMotion: Bool = false
    ) -> CGSize {
        guard !reduceMotion else {
            return baseOffset
        }

        return CGSize(
            width: baseOffset.width - CGFloat(tiltX) * maxShift * intensity,
            height: baseOffset.height + CGFloat(tiltY) * maxShift * intensity
        )
    }

    // MARK: - Linear Gradient Points

    /// Calculates start and end points for edge highlight gradients.
    /// Used for strokes that catch light on one edge.
    static func edgeGradientPoints(
        tiltX: Double,
        tiltY: Double,
        reduceMotion: Bool = false
    ) -> (start: UnitPoint, end: UnitPoint) {
        guard !reduceMotion else {
            return (start: .topLeading, end: .bottomTrailing)
        }

        // BOOSTED: Edge gradients shift more dramatically
        let startX = 0.15 - tiltX * 0.3 * intensity
        let startY = 0.15 + tiltY * 0.3 * intensity
        let endX = 0.85 - tiltX * 0.3 * intensity
        let endY = 0.85 + tiltY * 0.3 * intensity

        return (
            start: UnitPoint(x: clamp(startX, to: -0.2...0.5), y: clamp(startY, to: -0.2...0.5)),
            end: UnitPoint(x: clamp(endX, to: 0.5...1.2), y: clamp(endY, to: 0.5...1.2))
        )
    }

    // MARK: - 3D Rim/Side Geometry

    /// Calculates offset for 3D rim layer that reveals object depth.
    /// When device tilts, the rim behind the object becomes visible.
    static func rimOffset(
        tiltX: Double,
        tiltY: Double,
        maxReveal: CGFloat = 8,  // BOOSTED from 3.5
        reduceMotion: Bool = false
    ) -> CGSize {
        guard !reduceMotion else {
            return .zero
        }

        // Rim offsets in same direction as tilt (reveals opposite edge)
        // This creates the satisfying "physical depth" effect
        return CGSize(
            width: CGFloat(tiltX) * maxReveal * intensity,
            height: -CGFloat(tiltY) * maxReveal * intensity
        )
    }

    /// Calculates gradient points for rim lighting.
    /// The rim is lit on the side facing the light source.
    static func rimGradientPoints(
        tiltX: Double,
        tiltY: Double,
        reduceMotion: Bool = false
    ) -> (start: UnitPoint, end: UnitPoint) {
        guard !reduceMotion else {
            return (start: UnitPoint(x: 0.3, y: 0.5), end: UnitPoint(x: 0.7, y: 0.5))
        }

        // BOOSTED: Rim lighting shifts more dramatically
        let startX = 0.3 - tiltX * 0.5 * intensity
        let endX = 0.7 - tiltX * 0.5 * intensity

        return (
            start: UnitPoint(x: clamp(startX, to: -0.3...0.8), y: 0.5),
            end: UnitPoint(x: clamp(endX, to: 0.2...1.3), y: 0.5)
        )
    }

    /// Calculates visible side wall thickness for keycaps.
    /// Returns thickness for left and right walls based on tilt.
    static func keycapWallThickness(
        tiltX: Double,
        maxWallDepth: CGFloat = 10,  // BOOSTED from 5
        reduceMotion: Bool = false
    ) -> (left: CGFloat, right: CGFloat) {
        guard !reduceMotion else {
            return (left: 0, right: 0)
        }

        // Tilting right reveals left wall, tilting left reveals right wall
        // BOOSTED: Walls are now much more visible when tilting
        let leftWall = max(0, CGFloat(tiltX) * maxWallDepth * intensity)
        let rightWall = max(0, CGFloat(-tiltX) * maxWallDepth * intensity)

        return (left: leftWall, right: rightWall)
    }

    /// Calculates visible top/bottom wall thickness for keycaps.
    static func keycapVerticalWallThickness(
        tiltY: Double,
        maxWallDepth: CGFloat = 8,  // BOOSTED from 4
        reduceMotion: Bool = false
    ) -> (top: CGFloat, bottom: CGFloat) {
        guard !reduceMotion else {
            return (top: 0, bottom: 0)
        }

        // Tilting forward reveals top wall, tilting back reveals bottom wall
        let topWall = max(0, CGFloat(-tiltY) * maxWallDepth * intensity)
        let bottomWall = max(0, CGFloat(tiltY) * maxWallDepth * intensity)

        return (top: topWall, bottom: bottomWall)
    }
}

// MARK: - Clamping Helper

extension DynamicShadow {
    fileprivate static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

// MARK: - View Modifier for Dynamic Neumorphic Shadows

/// ViewModifier that applies dynamic neumorphic shadows to raised elements.
struct DynamicNeumorphicShadow: ViewModifier {
    let tiltX: Double
    let tiltY: Double
    let shadowLight: Color
    let shadowDark: Color
    let lightOpacity: Double
    let darkOpacity: Double
    let radius: CGFloat
    let reduceMotion: Bool

    init(
        tiltX: Double,
        tiltY: Double,
        shadowLight: Color,
        shadowDark: Color,
        lightOpacity: Double = 0.85,
        darkOpacity: Double = 0.65,
        radius: CGFloat = 10,
        isDarkMode: Bool = false,
        reduceMotion: Bool = false
    ) {
        self.tiltX = tiltX
        self.tiltY = tiltY
        self.shadowLight = shadowLight
        self.shadowDark = shadowDark
        self.lightOpacity = isDarkMode ? lightOpacity * 0.35 : lightOpacity
        self.darkOpacity = isDarkMode ? darkOpacity * 1.2 : darkOpacity
        self.radius = isDarkMode ? radius * 0.6 : radius
        self.reduceMotion = reduceMotion
    }

    func body(content: Content) -> some View {
        let offsets = DynamicShadow.shadowOffsets(
            tiltX: tiltX,
            tiltY: tiltY,
            reduceMotion: reduceMotion
        )

        content
            .shadow(
                color: shadowLight.opacity(lightOpacity),
                radius: radius,
                x: offsets.light.width,
                y: offsets.light.height
            )
            .shadow(
                color: shadowDark.opacity(darkOpacity),
                radius: radius,
                x: offsets.dark.width,
                y: offsets.dark.height
            )
    }
}

extension View {
    func dynamicNeumorphicShadow(
        tiltX: Double,
        tiltY: Double,
        shadowLight: Color,
        shadowDark: Color,
        lightOpacity: Double = 0.85,
        darkOpacity: Double = 0.65,
        radius: CGFloat = 10,
        isDarkMode: Bool = false,
        reduceMotion: Bool = false
    ) -> some View {
        modifier(DynamicNeumorphicShadow(
            tiltX: tiltX,
            tiltY: tiltY,
            shadowLight: shadowLight,
            shadowDark: shadowDark,
            lightOpacity: lightOpacity,
            darkOpacity: darkOpacity,
            radius: radius,
            isDarkMode: isDarkMode,
            reduceMotion: reduceMotion
        ))
    }
}
