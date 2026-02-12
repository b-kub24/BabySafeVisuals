import SwiftUI

struct SandView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(AppState.self) private var appState
    @State private var grains: [SandGrain] = []
    @State private var lastUpdate: Date = .now
    @State private var isInitialized = false
    
    private let grainCount = 800
    
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? [
            Color(red: 0.04, green: 0.03, blue: 0.02),
            Color(red: 0.06, green: 0.04, blue: 0.03)
        ] : [
            Color(red: 0.12, green: 0.08, blue: 0.04),
            Color(red: 0.08, green: 0.06, blue: 0.03),
            Color(red: 0.1, green: 0.07, blue: 0.04)
        ]
    }
    
    private static let sandColors: [(r: Double, g: Double, b: Double)] = [
        (0.85, 0.75, 0.55),  // Light sand
        (0.78, 0.68, 0.48),  // Golden
        (0.72, 0.62, 0.42),  // Tan
        (0.65, 0.55, 0.38),  // Darker sand
        (0.90, 0.80, 0.60),  // Pale sand
        (0.55, 0.45, 0.30),  // Dark grain
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradient, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let baseDt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                        let dt = baseDt * appState.animationSpeedMultiplier
                        
                        for grain in grains {
                            let rect = CGRect(
                                x: grain.x - grain.radius,
                                y: grain.y - grain.radius,
                                width: grain.radius * 2,
                                height: grain.radius * 2
                            )
                            context.opacity = grain.opacity
                            context.fill(
                                Circle().path(in: rect),
                                with: .color(Color(red: grain.r, green: grain.g, blue: grain.b))
                            )
                        }
                        
                        DispatchQueue.main.async {
                            updateGrains(dt: dt, size: size)
                            lastUpdate = timeline.date
                        }
                    }
                }
            }
            .onAppear {
                if !isInitialized {
                    initGrains(size: geo.size)
                    lastUpdate = .now
                    isInitialized = true
                }
            }
        }
    }
    
    private func initGrains(size: CGSize) {
        grains = (0..<grainCount).map { _ in
            let color = Self.sandColors.randomElement()!
            return SandGrain(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                vx: 0, vy: 0,
                radius: Double.random(in: 0.8...2.0),
                opacity: Double.random(in: 0.6...1.0),
                r: color.r + Double.random(in: -0.05...0.05),
                g: color.g + Double.random(in: -0.05...0.05),
                b: color.b + Double.random(in: -0.05...0.05)
            )
        }
    }
    
    private func updateGrains(dt: Double, size: CGSize) {
        let gravX = motion.tiltX  // -1 to 1
        let gravY = -motion.tiltY // inverted for screen coords
        let shake = motion.shakeIntensity
        let gravity: Double = 600  // pixels/sec^2
        
        // Simple height-map for piling: divide screen into columns
        let columnCount = 40
        let columnWidth = Double(size.width) / Double(columnCount)
        var heightMap = [Double](repeating: Double(size.height), count: columnCount)
        
        // First pass: compute height map from settled grains
        for grain in grains where abs(grain.vy) < 5 && abs(grain.vx) < 5 {
            let col = min(columnCount - 1, max(0, Int(grain.x / columnWidth)))
            heightMap[col] = min(heightMap[col], grain.y)
        }
        
        for i in grains.indices {
            // Apply gravity based on tilt
            grains[i].vx += gravX * gravity * dt
            grains[i].vy += (1.0 + gravY) * gravity * 0.5 * dt  // Always some downward pull
            
            // Shake scatters grains
            if shake > 0.5 {
                let force = shake * 3.0
                grains[i].vx += Double.random(in: -force * 100...force * 100) * dt
                grains[i].vy += Double.random(in: -force * 150...force * 50) * dt
            }
            
            // Damping
            grains[i].vx *= (1.0 - 2.0 * dt)
            grains[i].vy *= (1.0 - 1.5 * dt)
            
            // Move
            grains[i].x += grains[i].vx * dt
            grains[i].y += grains[i].vy * dt
            
            // Floor collision with piling
            let col = min(columnCount - 1, max(0, Int(grains[i].x / columnWidth)))
            let floor = heightMap[col] - grains[i].radius
            if grains[i].y > floor {
                grains[i].y = floor - Double.random(in: 0...1)
                grains[i].vy = -abs(grains[i].vy) * 0.1  // Tiny bounce
                grains[i].vx *= 0.5
                // Update height map
                heightMap[col] = min(heightMap[col], grains[i].y)
            }
            
            // Wall collisions
            if grains[i].x < grains[i].radius {
                grains[i].x = grains[i].radius
                grains[i].vx = abs(grains[i].vx) * 0.3
            }
            if grains[i].x > Double(size.width) - grains[i].radius {
                grains[i].x = Double(size.width) - grains[i].radius
                grains[i].vx = -abs(grains[i].vx) * 0.3
            }
            // Ceiling
            if grains[i].y < grains[i].radius {
                grains[i].y = grains[i].radius
                grains[i].vy = abs(grains[i].vy) * 0.3
            }
        }
    }
    
    func resetScene() {
        isInitialized = false
        grains.removeAll()
    }
}

private struct SandGrain {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var opacity: Double
    var r: Double
    var g: Double
    var b: Double
}
