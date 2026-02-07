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

    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.userAcceleration = motion.userAcceleration
            self.rotationRate = motion.rotationRate
            self.gravity = motion.gravity
        }
    }

    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    var shakeIntensity: Double {
        let acc = userAcceleration
        return sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
    }

    var tiltX: Double { gravity.x }
    var tiltY: Double { gravity.y }
}
