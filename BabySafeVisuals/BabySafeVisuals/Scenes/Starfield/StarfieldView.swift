import SwiftUI

struct StarfieldView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @State private var stars: [Star] = []
    @State private var lastUpdate: Date = .now
    
    private let starCount = 200
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let cx = size.width / 2
                    let cy = size.height / 2
                    
                    for star in stars {
                        // Project from 3D to 2D
                        let scale = 300 / max(star.z, 1)
                        let screenX = cx + (star.x - cx) * scale / 100
                        let screenY = cy + (star.y - cy) * scale / 100
                        let r = max(0.5, star.baseRadius * scale / 100)
                        
                        guard screenX > -10 && screenX < size.width + 10 &&
                              screenY > -10 && screenY < size.height + 10 else { continue }
                        
                        let brightness = min(1.0, 300 / max(star.z, 1)) * star.brightness
                        let rect = CGRect(x: screenX - r, y: screenY - r, width: r * 2, height: r * 2)
                        context.opacity = brightness
                        context.fill(Circle().path(in: rect), with: .color(star.color))
                        
                        // Glow for close stars
                        if star.z < 100 {
                            let glowRect = CGRect(x: screenX - r * 2, y: screenY - r * 2, width: r * 4, height: r * 4)
                            context.opacity = brightness * 0.2
                            context.fill(Circle().path(in: glowRect), with: .color(star.color))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(Color.black)
            }
            .onAppear { initStars(size: geo.size) }
        }
    }
    
    private func initStars(size: CGSize) {
        let starColors: [Color] = [.white, .white, .white, .cyan, .yellow, Color(red: 1, green: 0.8, blue: 0.7)]
        stars = (0..<starCount).map { _ in
            Star(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                z: Double.random(in: 10...500),
                baseRadius: Double.random(in: 0.5...2.5),
                brightness: Double.random(in: 0.3...1.0),
                color: starColors.randomElement()!
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        let tiltX = motion.tiltX * 30
        let tiltY = motion.tiltY * 30
        
        for i in stars.indices {
            // Fly forward
            stars[i].z -= 40 * dt * appState.animationSpeedMultiplier
            
            // Tilt parallax — closer stars move more
            let parallax = 300 / max(stars[i].z, 1) * 0.5
            stars[i].x += tiltX * parallax * dt
            stars[i].y -= tiltY * parallax * dt
            
            // Respawn behind if too close
            if stars[i].z < 1 {
                stars[i].z = Double.random(in: 400...500)
                stars[i].x = Double.random(in: 0...Double(size.width))
                stars[i].y = Double.random(in: 0...Double(size.height))
            }
        }
    }
}

private struct Star {
    var x: Double
    var y: Double
    var z: Double
    var baseRadius: Double
    var brightness: Double
    var color: Color
}
