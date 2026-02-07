import SwiftUI

@Observable
final class AppState {
    var activeScene: SceneID {
        didSet {
            guard activeScene != oldValue else { return }
            UserDefaults.standard.set(activeScene.rawValue, forKey: "activeScene")
        }
    }

    var soundEnabled: Bool {
        didSet {
            guard soundEnabled != oldValue else { return }
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    var parentUnlocked: Bool = false

    var isPurchased: Bool {
        didSet {
            guard isPurchased != oldValue else { return }
            UserDefaults.standard.set(isPurchased, forKey: "isPurchased")
        }
    }

    /// Tracks whether the app has finished its launch fade-in
    var hasLaunched: Bool = false

    init() {
        let savedScene = UserDefaults.standard.string(forKey: "activeScene") ?? SceneID.snowglobe.rawValue
        self.activeScene = SceneID(rawValue: savedScene) ?? .snowglobe

        // Validate: if saved scene is locked and not purchased, fall back to snowglobe
        let purchased = UserDefaults.standard.bool(forKey: "isPurchased")
        if !purchased && !(SceneID(rawValue: savedScene)?.isFree ?? true) {
            self.activeScene = .snowglobe
        }

        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        self.isPurchased = purchased
    }

    func isSceneUnlocked(_ scene: SceneID) -> Bool {
        scene.isFree || isPurchased
    }

    func lockParentMode() {
        parentUnlocked = false
    }
}
