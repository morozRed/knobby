import CoreMotion
import SwiftUI

@Observable
final class MotionManager {
    private let motionManager = CMMotionManager()
    private var isRunning = false
    private let motionQueue = OperationQueue()

    // Raw sensor values (updated on background queue)
    private var rawTiltX: Double = 0
    private var rawTiltY: Double = 0

    // Smoothed tilt values (-1 to 1) - these are the tracked properties
    var tiltX: Double = 0
    var tiltY: Double = 0

    // Smoothing factor (0 = no smoothing, 1 = max smoothing)
    // Lower = more responsive, higher = smoother
    private let smoothingFactor: Double = 0.15

    // Accessibility
    var reduceMotion: Bool = false

    // MARK: - Lifecycle

    init() {
        motionQueue.name = "com.knobby.motion"
        motionQueue.maxConcurrentOperationCount = 1
        motionQueue.qualityOfService = .userInteractive
    }

    func startUpdates() {
        guard !isRunning else {
            return
        }

        guard motionManager.isDeviceMotionAvailable else {
            return
        }

        // Use higher update rate for smoother data capture
        motionManager.deviceMotionUpdateInterval = 1.0 / 120.0

        // Process motion data on background queue
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }

            // Capture raw values
            self.rawTiltX = motion.gravity.x
            self.rawTiltY = motion.gravity.y
        }

        isRunning = true
    }

    /// Call this from your display link or animation loop for smooth interpolation
    func updateSmoothedValues() {
        // Exponential moving average for buttery smooth transitions
        tiltX += (rawTiltX - tiltX) * smoothingFactor
        tiltY += (rawTiltY - tiltY) * smoothingFactor
    }

    /// Direct update without smoothing (for immediate response)
    func syncValues() {
        tiltX = rawTiltX
        tiltY = rawTiltY
    }

    func stopUpdates() {
        guard isRunning else { return }
        motionManager.stopDeviceMotionUpdates()
        isRunning = false
    }
}
