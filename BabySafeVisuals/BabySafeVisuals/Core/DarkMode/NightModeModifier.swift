import SwiftUI

// MARK: - Night Mode Colors
/// Provides warm, muted color variants for night mode
struct NightModeColors {
    
    // MARK: - Snowglobe Scene
    static var snowglobeParticleColor: Color { Color(red: 1.0, green: 0.85, blue: 0.7) } // Warm cream
    static var snowglobeGradient: [Color] {
        [
            Color(red: 0.04, green: 0.04, blue: 0.08),
            Color(red: 0.06, green: 0.06, blue: 0.12),
            Color(red: 0.04, green: 0.05, blue: 0.1)
        ]
    }
    
    // MARK: - Water Ripples Scene
    static var waterRippleColors: [Color] {
        [
            Color(red: 0.5, green: 0.35, blue: 0.25),  // Warm bronze
            Color(red: 0.45, green: 0.3, blue: 0.2),   // Deep amber
            Color(red: 0.55, green: 0.4, blue: 0.28),  // Soft copper
            Color(red: 0.48, green: 0.32, blue: 0.22)  // Muted rust
        ]
    }
    static var waterRipplesGradient: [Color] {
        [
            Color(red: 0.03, green: 0.03, blue: 0.06),
            Color(red: 0.05, green: 0.05, blue: 0.1),
            Color(red: 0.03, green: 0.04, blue: 0.08)
        ]
    }
    
    // MARK: - Color Mixer Scene
    static var colorMixerColors: [Color] {
        [
            Color(red: 0.6, green: 0.25, blue: 0.2),   // Deep rust
            Color(red: 0.25, green: 0.2, blue: 0.35),  // Muted purple
            Color(red: 0.25, green: 0.35, blue: 0.25), // Dark forest
            Color(red: 0.6, green: 0.45, blue: 0.2),   // Warm gold
            Color(red: 0.4, green: 0.2, blue: 0.35)    // Deep plum
        ]
    }
    static var colorMixerBackground: Color {
        Color(red: 0.06, green: 0.05, blue: 0.08)
    }
    
    // MARK: - Bubbles Scene
    static var bubbleColors: [Color] {
        [
            Color(red: 0.5, green: 0.4, blue: 0.3),    // Warm tan
            Color(red: 0.55, green: 0.45, blue: 0.35), // Soft beige
            Color(red: 0.45, green: 0.35, blue: 0.25), // Muted bronze
            Color(red: 0.5, green: 0.38, blue: 0.28)   // Dusty copper
        ]
    }
    static var bubblesRimColor: Color { Color(red: 1.0, green: 0.9, blue: 0.7) } // Warm cream
    static var bubblesGradient: [Color] {
        [
            Color(red: 0.03, green: 0.04, blue: 0.06),
            Color(red: 0.04, green: 0.06, blue: 0.09),
            Color(red: 0.03, green: 0.05, blue: 0.07)
        ]
    }
    
    // MARK: - Magnetic Particles Scene
    static var magneticBackground: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        (0.05, 0.03, 0.08)
    }
    static var magneticHueRange: ClosedRange<CGFloat> { 0.05...0.15 } // Warm orange-amber hues
    static var magneticBrightness: CGFloat { 0.5 }
    
    // MARK: - Aurora Orbs Scene
    static var auroraColors: [Color] {
        [
            Color(red: 0.4, green: 0.3, blue: 0.2),    // Warm amber
            Color(red: 0.3, green: 0.2, blue: 0.25),   // Muted mauve
            Color(red: 0.35, green: 0.2, blue: 0.25),  // Dusty rose
            Color(red: 0.3, green: 0.25, blue: 0.2),   // Soft taupe
            Color(red: 0.38, green: 0.3, blue: 0.22),  // Warm ochre
            Color(red: 0.32, green: 0.22, blue: 0.28)  // Deep plum
        ]
    }
    static var auroraGradient: [Color] {
        [
            Color(red: 0.02, green: 0.02, blue: 0.04),
            Color(red: 0.03, green: 0.03, blue: 0.06),
            Color(red: 0.02, green: 0.02, blue: 0.05)
        ]
    }
    
    // MARK: - Calm Static Scene
    static var calmStaticStarColor: Color { Color(red: 1.0, green: 0.9, blue: 0.7) } // Warm white
    static var calmStaticGlowColor: Color { Color(red: 0.5, green: 0.35, blue: 0.25) } // Amber glow
    static var calmStaticGradient: [Color] {
        [
            Color(red: 0.02, green: 0.02, blue: 0.04),
            Color(red: 0.03, green: 0.03, blue: 0.05),
            Color(red: 0.02, green: 0.02, blue: 0.04)
        ]
    }
    // MARK: - Drawing Scene
    static var drawingGradient: [Color] {
        [
            Color(red: 0.03, green: 0.03, blue: 0.05),
            Color(red: 0.05, green: 0.04, blue: 0.07)
        ]
    }
    
    // MARK: - Sand Scene
    static var sandGradient: [Color] {
        [
            Color(red: 0.04, green: 0.03, blue: 0.02),
            Color(red: 0.06, green: 0.04, blue: 0.03)
        ]
    }
}

// MARK: - Night Mode View Modifier
/// Applies brightness reduction and optional red-shift filter for night mode
struct NightModeModifier: ViewModifier {
    let isNightMode: Bool
    let preserveNightVision: Bool
    let brightnessLevel: Double
    
    func body(content: Content) -> some View {
        content
            .brightness(isNightMode ? brightnessLevel - 1.0 : 0) // Reduce brightness (brightnessLevel is 0.3, so -0.7)
            .saturation(isNightMode ? 0.7 : 1.0) // Slightly desaturate
            .overlay {
                if isNightMode && preserveNightVision {
                    // Red-shift overlay for preserving night vision
                    Color.red
                        .opacity(0.15)
                        .blendMode(.multiply)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - View Extension
extension View {
    /// Apply night mode effects to the view
    func nightMode(isActive: Bool, preserveNightVision: Bool = false, brightnessLevel: Double = 0.3) -> some View {
        modifier(NightModeModifier(
            isNightMode: isActive,
            preserveNightVision: preserveNightVision,
            brightnessLevel: brightnessLevel
        ))
    }
}

// MARK: - Color Extension for Night Mode
extension Color {
    /// Returns a warmer, muted version of the color for night mode
    func nightModeVariant(isNightMode: Bool) -> Color {
        guard isNightMode else { return self }
        // For generic colors, shift toward warmer tones
        // This is a simplified approach - scene-specific colors use NightModeColors
        return self.opacity(0.7)
    }
}
