import SwiftUI
import Combine

// MARK: - Night Mode Preference
enum NightModePreference: String, CaseIterable {
    case auto = "auto"
    case on = "on"
    case off = "off"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .on: return "Always On"
        case .off: return "Off"
        }
    }
    
    var icon: String {
        switch self {
        case .auto: return "moon.circle"
        case .on: return "moon.fill"
        case .off: return "sun.max.fill"
        }
    }
}

@Observable
final class AppState {
    // ⚠️ TESTING MODE: Set to true to unlock all scenes without purchase
    // IMPORTANT: Set back to false before submitting to App Store!
    static let TESTING_MODE = false
    
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
    
    // MARK: - Night Mode Settings
    
    /// User's night mode preference (auto/on/off)
    var nightModePreference: NightModePreference {
        didSet {
            UserDefaults.standard.set(nightModePreference.rawValue, forKey: "nightModePreference")
        }
    }
    
    /// Red-shift filter for preserving night vision
    var preserveNightVision: Bool {
        didSet {
            UserDefaults.standard.set(preserveNightVision, forKey: "preserveNightVision")
        }
    }
    
    /// System color scheme (updated by view)
    var systemColorScheme: ColorScheme = .light
    
    /// Computed: Whether night mode should currently be active
    var isNightModeActive: Bool {
        switch nightModePreference {
        case .on:
            return true
        case .off:
            return false
        case .auto:
            // Auto mode: check system dark mode OR time-based (8pm-7am)
            if systemColorScheme == .dark {
                return true
            }
            let hour = Calendar.current.component(.hour, from: Date())
            return hour >= 20 || hour < 7
        }
    }
    
    /// Animation speed multiplier (slower in night mode)
    var animationSpeedMultiplier: Double {
        isNightModeActive ? 0.6 : 1.0
    }
    
    /// Brightness level (reduced in night mode)
    var brightnessLevel: Double {
        isNightModeActive ? 0.3 : 1.0
    }

    init() {
        let savedScene = UserDefaults.standard.string(forKey: "activeScene") ?? SceneID.snowglobe.rawValue
        self.activeScene = SceneID(rawValue: savedScene) ?? .snowglobe
        self.soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        self.isPurchased = UserDefaults.standard.bool(forKey: "isPurchased")
        
        // Night mode settings
        let savedNightMode = UserDefaults.standard.string(forKey: "nightModePreference") ?? NightModePreference.auto.rawValue
        self.nightModePreference = NightModePreference(rawValue: savedNightMode) ?? .auto
        self.preserveNightVision = UserDefaults.standard.bool(forKey: "preserveNightVision")
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
