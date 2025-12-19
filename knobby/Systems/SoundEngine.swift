import AVFoundation
import SwiftUI

/// Sound types for different tactile controls
enum SoundType {
    case knobTick       // Soft detent tick for rotary knob
    case switchClick    // Mechanical toggle switch click
    case buttonPress    // Squishy button press
    case buttonRelease  // Button release pop
    case joystickMove   // Subtle friction sound
    case joystickSnap   // Spring return snap
    case sliderTick     // Slider detent tick
    case sliderSnap     // Slider snap to position
    case keyThock       // Deep mechanical keyboard thock (press)
    case keyClack       // Higher mechanical keyboard clack (release)
}

@Observable
final class SoundEngine {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var soundBuffers: [SoundType: AVAudioPCMBuffer] = [:]

    var isEnabled: Bool = true  // TODO: Off by default per PRD, enabled for testing
    private var isSetup = false

    init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[SoundEngine] Audio session setup failed: \(error)")
        }
    }

    // MARK: - Engine Setup

    private func setupEngine() {
        guard !isSetup else { return }

        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else { return }

        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // Create all sound buffers
        soundBuffers[.knobTick] = createKnobTickBuffer(format: format)
        soundBuffers[.switchClick] = createSwitchClickBuffer(format: format)
        soundBuffers[.buttonPress] = createButtonPressBuffer(format: format)
        soundBuffers[.buttonRelease] = createButtonReleaseBuffer(format: format)
        soundBuffers[.joystickMove] = createJoystickMoveBuffer(format: format)
        soundBuffers[.joystickSnap] = createJoystickSnapBuffer(format: format)
        soundBuffers[.sliderTick] = createSliderTickBuffer(format: format)
        soundBuffers[.sliderSnap] = createSliderSnapBuffer(format: format)
        soundBuffers[.keyThock] = createKeyThockBuffer(format: format)
        soundBuffers[.keyClack] = createKeyClackBuffer(format: format)

        do {
            try engine.start()
            isSetup = true
        } catch {
            print("[SoundEngine] Engine start failed: \(error)")
        }
    }

    // MARK: - Sound Synthesis

    /// Knob tick - soft, precise detent click (like a quality volume knob)
    private func createKnobTickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.018
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 12)

            // Soft mid-frequency tick
            let tick = sin(2 * .pi * 2200 * t) * 0.3
            // Low resonance for body
            let body = sin(2 * .pi * 350 * t) * 0.2
            // Gentle high for definition
            let high = sin(2 * .pi * 5000 * t) * 0.1 * exp(-progress * 20)

            let sample = (tick + body + high) * decay * 0.5
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Switch click - mechanical, decisive toggle (like a light switch)
    private func createSwitchClickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.035
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            // Sharp attack
            let attack: Double = frame < 8 ? Double(frame) / 8.0 : 1.0
            let decay = exp(-progress * 10)

            // Metallic click (higher frequencies)
            let click = sin(2 * .pi * 3200 * t) * 0.35
            // Lower thunk for weight
            let thunk = sin(2 * .pi * 180 * t) * 0.4
            // Mid resonance
            let mid = sin(2 * .pi * 800 * t) * 0.2
            // Sharp transient
            let snap = sin(2 * .pi * 6000 * t) * 0.15 * exp(-progress * 25)

            let sample = (click + thunk + mid + snap) * decay * attack * 0.55
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Button press - squishy, satisfying press (like a arcade button)
    private func createButtonPressBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.045
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 8)

            // Deep, bassy thump
            let bass = sin(2 * .pi * 120 * t) * 0.45
            // Plastic click
            let plastic = sin(2 * .pi * 1400 * t) * 0.25
            // Soft high
            let high = sin(2 * .pi * 3500 * t) * 0.1 * exp(-progress * 15)
            // Subtle squish (frequency sweep down)
            let squish = sin(2 * .pi * (2000 - progress * 1500) * t) * 0.15 * exp(-progress * 12)

            let sample = (bass + plastic + high + squish) * decay * 0.5
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Button release - lighter pop when releasing
    private func createButtonReleaseBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.025
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 15)

            // Higher pitched pop
            let pop = sin(2 * .pi * 2800 * t) * 0.3
            // Light body
            let body = sin(2 * .pi * 600 * t) * 0.15
            // Airy high
            let air = sin(2 * .pi * 5500 * t) * 0.1 * exp(-progress * 20)

            let sample = (pop + body + air) * decay * 0.4
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Joystick move - subtle friction/resistance sound
    private func createJoystickMoveBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.015
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 18)

            // Very soft, low friction sound
            let friction = sin(2 * .pi * 400 * t) * 0.2
            // Subtle noise for texture
            let noise = Double.random(in: -0.08...0.08) * exp(-progress * 15)

            let sample = (friction + noise) * decay * 0.3
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Joystick snap - spring return to center
    private func createJoystickSnapBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.05
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 10)

            // Spring-like oscillation with decreasing frequency
            let springFreq = 600 + (1 - progress) * 400
            let spring = sin(2 * .pi * springFreq * t) * 0.3
            // Impact thump
            let thump = sin(2 * .pi * 200 * t) * 0.35 * exp(-progress * 8)
            // Rattle
            let rattle = sin(2 * .pi * 1800 * t) * 0.1 * exp(-progress * 20)

            let sample = (spring + thump + rattle) * decay * 0.45
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Slider tick - subtle detent for slider positions
    private func createSliderTickBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.012
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 20)

            // Very light tick
            let tick = sin(2 * .pi * 2800 * t) * 0.25
            // Tiny thump
            let thump = sin(2 * .pi * 500 * t) * 0.15

            let sample = (tick + thump) * decay * 0.35
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Slider snap - snapping to final position
    private func createSliderSnapBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.03
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let decay = exp(-progress * 12)

            // Satisfying snap
            let snap = sin(2 * .pi * 2000 * t) * 0.35
            // Body
            let body = sin(2 * .pi * 450 * t) * 0.25
            // Click
            let click = sin(2 * .pi * 4000 * t) * 0.1 * exp(-progress * 25)

            let sample = (snap + body + click) * decay * 0.45
            channelData[frame] = Float(sample)
        }
        return buffer
    }

    /// Mechanical keyboard THOCK - deep, resonant press sound (like lubed linear switches)
    private func createKeyThockBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.12  // Longer for that resonant decay
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            // Sharp attack envelope
            let attack: Double = frame < 20 ? Double(frame) / 20.0 : 1.0
            // Multi-stage decay for realistic sound
            let fastDecay = exp(-progress * 25)  // Initial transient
            let slowDecay = exp(-progress * 8)   // Body resonance

            // Deep "thock" fundamental (very low, like hitting a desk)
            let thock = sin(2 * .pi * 85 * t) * 0.55 * slowDecay

            // Housing resonance (the "o" in thock)
            let housing = sin(2 * .pi * 180 * t) * 0.4 * slowDecay

            // Stem impact (sharp transient)
            let stem = sin(2 * .pi * 1200 * t) * 0.25 * fastDecay

            // Plate ping (metallic overtone)
            let plate = sin(2 * .pi * 2800 * t) * 0.15 * fastDecay

            // High frequency attack definition
            let attack_click = sin(2 * .pi * 4500 * t) * 0.1 * exp(-progress * 40)

            // Subtle case resonance (gives it that "hollow" quality)
            let caseRes = sin(2 * .pi * 350 * t) * 0.2 * slowDecay * (1 - progress)

            let sample = (thock + housing + stem + plate + attack_click + caseRes) * attack * 0.6
            channelData[frame] = Float(max(-1.0, min(1.0, sample)))
        }
        return buffer
    }

    /// Mechanical keyboard CLACK - lighter upstroke sound
    private func createKeyClackBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration: Double = 0.06  // Shorter than press
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let progress = t / duration

            let attack: Double = frame < 10 ? Double(frame) / 10.0 : 1.0
            let decay = exp(-progress * 15)

            // Higher pitched "clack" (spring return)
            let clack = sin(2 * .pi * 1800 * t) * 0.35 * decay

            // Light housing tap
            let tap = sin(2 * .pi * 280 * t) * 0.25 * decay

            // Spring ping
            let spring = sin(2 * .pi * 3200 * t) * 0.15 * exp(-progress * 25)

            // Airy top-out
            let air = sin(2 * .pi * 5000 * t) * 0.08 * exp(-progress * 35)

            let sample = (clack + tap + spring + air) * attack * 0.5
            channelData[frame] = Float(max(-1.0, min(1.0, sample)))
        }
        return buffer
    }

    // MARK: - Playback

    func play(_ soundType: SoundType) {
        guard isEnabled else { return }

        if !isSetup {
            setupEngine()
        }

        guard let player = playerNode,
              let buffer = soundBuffers[soundType],
              let engine = audioEngine,
              engine.isRunning else {
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

        if !player.isPlaying {
            player.play()
        }
    }

    /// Legacy method for backwards compatibility
    func playClick() {
        play(.knobTick)
    }

    // MARK: - Lifecycle

    func prepare() {
        if isEnabled && !isSetup {
            setupEngine()
        }
    }

    func stop() {
        audioEngine?.stop()
        isSetup = false
    }
}
