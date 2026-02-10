import SwiftUI
import Combine

@Observable
final class AppState {
    // ⚠️ TESTING MODE: Set to true to unlock all scenes without purchase
    // IMPORTANT: Set back to false before submitting to App Store!
    static let TESTING_MODE = true
    
    var activeScene: SceneID {
        didSet {
            UserDefaults.standard.set(activeScene.rawValue, forKey: "activeScene")
        }
    }

    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    var parentUnlocked: Bool = false

    var isPurchased: Bool {
        didSet {
            UserDefaults.standard.set(isPurchased, forKey: "isPurchased")
        }
    }

    init() {
        let savedScene = UserDefaults.standard.string(forKey: "activeScene") ?? SceneID.snowglobe.rawValue
        self.activeScene = SceneID(rawValue: savedScene) ?? .snowglobe
        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
    }

    func isSceneUnlocked(_ scene: SceneID) -> Bool {
        // If testing mode is enabled, all scenes are unlocked
        if Self.TESTING_MODE {
            return true
        }
        return scene.isFree || isPurchased
    }

    func lockParentMode() {
        parentUnlocked = false
    }
}
