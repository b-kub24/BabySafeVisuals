import SwiftUI

// MARK: - Settings Enums

enum ParticleDensity: String, CaseIterable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var multiplier: Double {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .high: return 1.5
        }
    }
}

enum TouchSensitivity: String, CaseIterable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var radiusMultiplier: Double {
        switch self {
        case .low: return 0.7
        case .medium: return 1.0
        case .high: return 1.4
        }
    }
}

// MARK: - App State

@Observable
final class AppState {
    // MARK: Active Scene

    var activeScene: SceneID {
        didSet {
            guard activeScene != oldValue else { return }
            UserDefaults.standard.set(activeScene.rawValue, forKey: "activeScene")
        }
    }

    // MARK: Sound

    var soundEnabled: Bool {
        didSet {
            guard soundEnabled != oldValue else { return }
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }

    // MARK: Parent Mode

    var parentUnlocked: Bool = false

    // MARK: Scene Unlock System

    var unlockedScenes: Set<SceneID> {
        didSet {
            let rawValues = Array(unlockedScenes.map(\.rawValue))
            UserDefaults.standard.set(rawValues, forKey: "unlockedScenes")
        }
    }

    var purchasedTiers: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(purchasedTiers), forKey: "purchasedTiers")
        }
    }

    var totalUnlockSlots: Int {
        var count = 0
        if purchasedTiers.contains(PurchaseManager.oneSceneProductID) { count += 1 }
        if purchasedTiers.contains(PurchaseManager.threeScenesProductID) { count += 3 }
        return count
    }

    var remainingUnlockSlots: Int {
        max(0, totalUnlockSlots - unlockedScenes.count)
    }

    var allScenesUnlocked: Bool {
        SceneID.allCases.allSatisfy { isSceneUnlocked($0) }
    }

    // MARK: Settings

    var screenDimming: Double {
        didSet {
            guard screenDimming != oldValue else { return }
            UserDefaults.standard.set(screenDimming, forKey: "screenDimming")
        }
    }

    var autoCycleEnabled: Bool {
        didSet {
            guard autoCycleEnabled != oldValue else { return }
            UserDefaults.standard.set(autoCycleEnabled, forKey: "autoCycleEnabled")
        }
    }

    var autoCycleMinutes: Int {
        didSet {
            guard autoCycleMinutes != oldValue else { return }
            UserDefaults.standard.set(autoCycleMinutes, forKey: "autoCycleMinutes")
        }
    }

    var sessionLimitMinutes: Int {
        didSet {
            guard sessionLimitMinutes != oldValue else { return }
            UserDefaults.standard.set(sessionLimitMinutes, forKey: "sessionLimitMinutes")
        }
    }

    var particleDensity: ParticleDensity {
        didSet {
            guard particleDensity != oldValue else { return }
            UserDefaults.standard.set(particleDensity.rawValue, forKey: "particleDensity")
        }
    }

    var touchSensitivity: TouchSensitivity {
        didSet {
            guard touchSensitivity != oldValue else { return }
            UserDefaults.standard.set(touchSensitivity.rawValue, forKey: "touchSensitivity")
        }
    }

    // MARK: State

    var hasLaunched: Bool = false
    var hasSeenOnboarding: Bool
    var sessionStartTime: Date = .now
    var sessionLimitReached: Bool = false

    // MARK: Init

    init() {
        let savedScene = UserDefaults.standard.string(forKey: "activeScene") ?? SceneID.snowglobe.rawValue
        self.activeScene = SceneID(rawValue: savedScene) ?? .snowglobe

        let savedUnlocked = UserDefaults.standard.stringArray(forKey: "unlockedScenes") ?? []
        self.unlockedScenes = Set(savedUnlocked.compactMap { SceneID(rawValue: $0) })

        let savedTiers = UserDefaults.standard.stringArray(forKey: "purchasedTiers") ?? []
        self.purchasedTiers = Set(savedTiers)

        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        self.screenDimming = UserDefaults.standard.double(forKey: "screenDimming")
        self.autoCycleEnabled = UserDefaults.standard.bool(forKey: "autoCycleEnabled")

        let savedCycleMin = UserDefaults.standard.integer(forKey: "autoCycleMinutes")
        self.autoCycleMinutes = savedCycleMin > 0 ? savedCycleMin : 5

        self.sessionLimitMinutes = UserDefaults.standard.integer(forKey: "sessionLimitMinutes")

        self.particleDensity = ParticleDensity(
            rawValue: UserDefaults.standard.string(forKey: "particleDensity") ?? ""
        ) ?? .medium

        self.touchSensitivity = TouchSensitivity(
            rawValue: UserDefaults.standard.string(forKey: "touchSensitivity") ?? ""
        ) ?? .medium

        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        // Validate: if saved scene is locked, fall back to snowglobe
        if !isSceneUnlocked(activeScene) {
            self.activeScene = .snowglobe
        }
    }

    // MARK: Methods

    func isSceneUnlocked(_ scene: SceneID) -> Bool {
        scene.isFree || unlockedScenes.contains(scene)
    }

    func lockParentMode() {
        parentUnlocked = false
    }

    func unlockScene(_ scene: SceneID) {
        unlockedScenes.insert(scene)
    }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }

    func nextUnlockedScene() -> SceneID? {
        let unlocked = SceneID.allCases.filter { isSceneUnlocked($0) }
        guard unlocked.count > 1 else { return nil }
        guard let currentIndex = unlocked.firstIndex(of: activeScene) else { return unlocked.first }
        let nextIndex = (currentIndex + 1) % unlocked.count
        return unlocked[nextIndex]
    }

    /// Formatted session duration string
    var sessionDurationString: String {
        let elapsed = Date.now.timeIntervalSince(sessionStartTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
