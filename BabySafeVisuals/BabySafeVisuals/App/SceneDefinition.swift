import SwiftUI

enum SceneID: String, CaseIterable, Identifiable {
    case snowglobe
    case waterRipples
    case colorMixer
    case bubbles
    case magneticParticles
    case auroraOrbs
    case calmStatic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .snowglobe: return "Snowglobe"
        case .waterRipples: return "Water Ripples"
        case .colorMixer: return "Color Mixer"
        case .bubbles: return "Floating Bubbles"
        case .magneticParticles: return "Magnetic Particles"
        case .auroraOrbs: return "Aurora Orbs"
        case .calmStatic: return "Calm Static"
        }
    }

    var isFree: Bool {
        self == .snowglobe
    }

    var iconSystemName: String {
        switch self {
        case .snowglobe: return "snowflake"
        case .waterRipples: return "water.waves"
        case .colorMixer: return "paintpalette"
        case .bubbles: return "bubble.left.and.bubble.right"
        case .magneticParticles: return "sparkles"
        case .auroraOrbs: return "light.min"
        case .calmStatic: return "moon.stars"
        }
    }

    var previewColor: Color {
        switch self {
        case .snowglobe: return Color(red: 0.15, green: 0.2, blue: 0.35)
        case .waterRipples: return Color(red: 0.1, green: 0.25, blue: 0.4)
        case .colorMixer: return Color(red: 0.3, green: 0.15, blue: 0.3)
        case .bubbles: return Color(red: 0.1, green: 0.3, blue: 0.35)
        case .magneticParticles: return Color(red: 0.2, green: 0.1, blue: 0.3)
        case .auroraOrbs: return Color(red: 0.05, green: 0.2, blue: 0.25)
        case .calmStatic: return Color(red: 0.08, green: 0.08, blue: 0.15)
        }
    }
}
