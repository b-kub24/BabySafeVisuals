import CoreMotion
import SwiftUI

@Observable
final class MotionManager {
    var userAcceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    var rotationRate: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)
    var gravity: CMAcceleration = CMAcceleration(x: 0, y: -1, z: 0)
    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 60.0
    private var isRunning = false

    func startUpdates() {
        guard !isRunning, motionManager.isDeviceMotionAvailable else { return }
        isRunning = true
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, self.isRunning, let motion else {
                if error != nil { self?.isRunning = false }
                return
            }
            self.userAcceleration = motion.userAcceleration
            self.rotationRate = motion.rotationRate
            self.gravity = motion.gravity
        }
    }

    func stopUpdates() {
        guard isRunning else { return }
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
    }

    var shakeIntensity: Double {
        let acc = userAcceleration
        return sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
    }

    var tiltX: Double { gravity.x }
    var tiltY: Double { gravity.y }

    /// Damped tilt values for smoother scene responses
    var smoothTiltX: Double { gravity.x * 0.7 }
    var smoothTiltY: Double { gravity.y * 0.7 }
}
