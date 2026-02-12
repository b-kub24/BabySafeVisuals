import SwiftUI

enum SceneID: String, CaseIterable, Identifiable {
    case snowglobe
    case waterRipples
    case colorMixer
    case bubbles
    case magneticParticles
    case auroraOrbs
    case calmStatic
    case drawing
    case sand
    // New scenes
    case phoneDialer
    case abcLetters
    case babyPiano
    case drumPad
    case animalSounds
    case shapeSorter
    case fireworks
    case aquarium
    case butterflies
    case starfield
    case lavaLamp
    case flowerGarden
    case balloons
    case bouncyBalls
    case spinningTop
    case blockStacker
    case kaleidoscope
    case galaxySwirl
    case rainOnGlass
    case candle

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
        case .drawing: return "Drawing"
        case .sand: return "Sand"
        case .phoneDialer: return "Phone Dialer"
        case .abcLetters: return "ABC Letters"
        case .babyPiano: return "Baby Piano"
        case .drumPad: return "Drum Pad"
        case .animalSounds: return "Animal Sounds"
        case .shapeSorter: return "Shape Sorter"
        case .fireworks: return "Fireworks"
        case .aquarium: return "Aquarium"
        case .butterflies: return "Butterflies"
        case .starfield: return "Starfield"
        case .lavaLamp: return "Lava Lamp"
        case .flowerGarden: return "Flower Garden"
        case .balloons: return "Balloons"
        case .bouncyBalls: return "Bouncy Balls"
        case .spinningTop: return "Spinning Top"
        case .blockStacker: return "Block Stacker"
        case .kaleidoscope: return "Kaleidoscope"
        case .galaxySwirl: return "Galaxy Swirl"
        case .rainOnGlass: return "Rain on Glass"
        case .candle: return "Candle"
        }
    }

    var isFree: Bool {
        switch self {
        case .snowglobe, .bubbles, .drawing: return true
        default: return false
        }
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
        case .drawing: return "pencil.tip"
        case .sand: return "hourglass"
        case .phoneDialer: return "phone.fill"
        case .abcLetters: return "textformat.abc"
        case .babyPiano: return "pianokeys"
        case .drumPad: return "waveform"
        case .animalSounds: return "pawprint.fill"
        case .shapeSorter: return "square.on.circle"
        case .fireworks: return "sparkle"
        case .aquarium: return "fish.fill"
        case .butterflies: return "ladybug.fill"
        case .starfield: return "star.fill"
        case .lavaLamp: return "drop.fill"
        case .flowerGarden: return "camera.macro"
        case .balloons: return "balloon.fill"
        case .bouncyBalls: return "circle.fill"
        case .spinningTop: return "arrow.trianglehead.2.clockwise.rotate.90"
        case .blockStacker: return "square.stack.3d.up.fill"
        case .kaleidoscope: return "hexagon.fill"
        case .galaxySwirl: return "hurricane"
        case .rainOnGlass: return "cloud.rain.fill"
        case .candle: return "flame.fill"
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
        case .drawing: return Color(red: 0.25, green: 0.1, blue: 0.35)
        case .sand: return Color(red: 0.45, green: 0.35, blue: 0.2)
        case .phoneDialer: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .abcLetters: return Color(red: 0.2, green: 0.1, blue: 0.35)
        case .babyPiano: return Color(red: 0.15, green: 0.1, blue: 0.25)
        case .drumPad: return Color(red: 0.15, green: 0.08, blue: 0.2)
        case .animalSounds: return Color(red: 0.15, green: 0.3, blue: 0.15)
        case .shapeSorter: return Color(red: 0.2, green: 0.15, blue: 0.3)
        case .fireworks: return Color(red: 0.05, green: 0.02, blue: 0.15)
        case .aquarium: return Color(red: 0.05, green: 0.15, blue: 0.3)
        case .butterflies: return Color(red: 0.15, green: 0.25, blue: 0.15)
        case .starfield: return Color(red: 0.02, green: 0.02, blue: 0.08)
        case .lavaLamp: return Color(red: 0.15, green: 0.05, blue: 0.2)
        case .flowerGarden: return Color(red: 0.3, green: 0.5, blue: 0.3)
        case .balloons: return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .bouncyBalls: return Color(red: 0.2, green: 0.15, blue: 0.3)
        case .spinningTop: return Color(red: 0.45, green: 0.42, blue: 0.38)
        case .blockStacker: return Color(red: 0.15, green: 0.15, blue: 0.25)
        case .kaleidoscope: return Color(red: 0.1, green: 0.05, blue: 0.15)
        case .galaxySwirl: return Color(red: 0.08, green: 0.03, blue: 0.15)
        case .rainOnGlass: return Color(red: 0.2, green: 0.22, blue: 0.3)
        case .candle: return Color(red: 0.15, green: 0.08, blue: 0.02)
        }
    }
}
