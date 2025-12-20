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

    // Update throttling - don't update UI faster than 30fps for performance
    private var lastUpdateTime: TimeInterval = 0
    private let minUpdateInterval: TimeInterval = 1.0 / 30.0

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

        // Capture at 60Hz for smooth data, but throttle UI updates to 30Hz
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        // Process motion data on background queue
        motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }

            // Capture raw values
            let newRawX = motion.gravity.x
            let newRawY = motion.gravity.y

            // Apply smoothing on the capture thread
            let smoothedX = self.tiltX + (newRawX - self.tiltX) * self.smoothingFactor
            let smoothedY = self.tiltY + (newRawY - self.tiltY) * self.smoothingFactor

            // Throttle UI updates for performance
            let now = CACurrentMediaTime()
            guard now - self.lastUpdateTime >= self.minUpdateInterval else { return }
            self.lastUpdateTime = now

            // Update on main thread for SwiftUI observation
            DispatchQueue.main.async {
                self.tiltX = smoothedX
                self.tiltY = smoothedY
            }
        }

        isRunning = true
    }

    /// Call this from your display link or animation loop for smooth interpolation
    @discardableResult
    func updateSmoothedValues() -> Bool {
        // Now handled internally - this is kept for API compatibility
        return true
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
