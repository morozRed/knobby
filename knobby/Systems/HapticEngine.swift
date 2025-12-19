import CoreHaptics
import SwiftUI
import UIKit

/// Texture types for the texture slider - each has a unique haptic feel
enum HapticTexture {
    case smooth   // Soft, gentle, low intensity
    case bumpy    // Sharp, punchy, high intensity bursts
    case ridged   // Crisp, mechanical, medium intensity
    case grainy   // Light, rapid, subtle
    case silky    // Flowing, soft continuous feel
}

@Observable
final class HapticEngine {
    private var engine: CHHapticEngine?
    private var detentPlayer: CHHapticPatternPlayer?
    private var supportsHaptics: Bool = false

    // Texture-specific players
    private var smoothPlayer: CHHapticPatternPlayer?
    private var bumpyPlayer: CHHapticPatternPlayer?
    private var ridgedPlayer: CHHapticPatternPlayer?
    private var grainyPlayer: CHHapticPatternPlayer?
    private var silkyPlayer: CHHapticPatternPlayer?

    // Fallback generators for devices without Core Haptics
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    init() {
        prepareEngine()
    }

    // MARK: - Setup

    private func prepareEngine() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        guard supportsHaptics else {
            // Prepare fallback generator
            impactGenerator.prepare()
            return
        }

        do {
            engine = try CHHapticEngine()

            // Handle engine reset (e.g., after audio session interruption)
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                    self?.prepareDetentPattern()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }

            // Handle engine stop
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }

            try engine?.start()
            prepareDetentPattern()
            prepareTexturePatterns()

        } catch {
            print("Haptic engine creation failed: \(error)")
            supportsHaptics = false
        }
    }

    // MARK: - Texture Patterns

    private func prepareTexturePatterns() {
        guard supportsHaptics, let engine else { return }

        // SMOOTH: Very soft, gentle, almost imperceptible
        smoothPlayer = createTexturePlayer(
            engine: engine,
            intensity: 0.25,
            sharpness: 0.15
        )

        // BUMPY: Sharp, punchy, strong impact
        bumpyPlayer = createTexturePlayer(
            engine: engine,
            intensity: 0.9,
            sharpness: 0.95
        )

        // RIDGED: Crisp, mechanical, medium-high definition
        ridgedPlayer = createTexturePlayer(
            engine: engine,
            intensity: 0.6,
            sharpness: 0.85
        )

        // GRAINY: Light, subtle, like fine sandpaper
        grainyPlayer = createTexturePlayer(
            engine: engine,
            intensity: 0.35,
            sharpness: 0.5
        )

        // SILKY: Soft, flowing, low sharpness
        silkyPlayer = createTexturePlayer(
            engine: engine,
            intensity: 0.4,
            sharpness: 0.2
        )
    }

    private func createTexturePlayer(
        engine: CHHapticEngine,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticPatternPlayer? {
        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: intensity
        )
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: sharpness
        )

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            return try engine.makePlayer(with: pattern)
        } catch {
            print("Failed to create texture pattern: \(error)")
            return nil
        }
    }

    private func prepareDetentPattern() {
        guard supportsHaptics, let engine else { return }

        // Create a crisp, mechanical click feel
        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: KnobbyHaptics.detentIntensity
        )
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: KnobbyHaptics.detentSharpness
        )

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            detentPlayer = try engine.makePlayer(with: pattern)
        } catch {
            print("Failed to create detent pattern: \(error)")
        }
    }

    // MARK: - Playback

    /// Play a single detent click (for knob rotation)
    func playDetent() {
        if supportsHaptics {
            do {
                try detentPlayer?.start(atTime: CHHapticTimeImmediate)
            } catch {
                // Fallback if playback fails
                impactGenerator.impactOccurred()
            }
        } else {
            impactGenerator.impactOccurred()
        }
    }

    /// Play a texture-specific haptic (for texture slider)
    func playTexture(_ texture: HapticTexture) {
        if supportsHaptics {
            let player: CHHapticPatternPlayer?
            switch texture {
            case .smooth:
                player = smoothPlayer
            case .bumpy:
                player = bumpyPlayer
            case .ridged:
                player = ridgedPlayer
            case .grainy:
                player = grainyPlayer
            case .silky:
                player = silkyPlayer
            }

            do {
                try player?.start(atTime: CHHapticTimeImmediate)
            } catch {
                // Fallback
                playTextureFallback(texture)
            }
        } else {
            playTextureFallback(texture)
        }
    }

    private func playTextureFallback(_ texture: HapticTexture) {
        switch texture {
        case .smooth:
            softGenerator.impactOccurred(intensity: 0.3)
        case .bumpy:
            heavyGenerator.impactOccurred(intensity: 1.0)
        case .ridged:
            rigidGenerator.impactOccurred(intensity: 0.7)
        case .grainy:
            impactGenerator.impactOccurred(intensity: 0.4)
        case .silky:
            softGenerator.impactOccurred(intensity: 0.5)
        }
    }

    /// Prepare the engine (call before rapid haptics)
    func prepare() {
        if supportsHaptics {
            try? engine?.start()
        } else {
            impactGenerator.prepare()
            softGenerator.prepare()
            rigidGenerator.prepare()
            heavyGenerator.prepare()
        }
    }
}
