import SwiftUI

struct FireworksView: View {
    @Environment(AppState.self) private var appState
    @State private var fireworks: [Firework] = []
    @State private var lastUpdate: Date = .now
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let baseDt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let dt = baseDt * appState.animationSpeedMultiplier
                    
                    for fw in fireworks {
                        if !fw.hasExploded {
                            // Draw rocket trail
                            let rect = CGRect(x: fw.x - 2, y: fw.y - 4, width: 4, height: 8)
                            context.opacity = 0.9
                            context.fill(Circle().path(in: rect), with: .color(.white))
                        } else {
                            // Draw explosion particles
                            for particle in fw.particles {
                                let age = particle.age / particle.lifetime
                                guard age < 1.0 else { continue }
                                let fade = 1.0 - age
                                let r = particle.radius * (1.0 - age * 0.5)
                                let rect = CGRect(x: particle.x - r, y: particle.y - r, width: r * 2, height: r * 2)
                                context.opacity = fade * 0.8
                                context.fill(Circle().path(in: rect), with: .color(particle.color))
                                
                                // Sparkle trail
                                if r > 1.5 {
                                    let trailRect = CGRect(x: particle.x - r * 0.5, y: particle.y - r * 0.5, width: r, height: r)
                                    context.opacity = fade * 0.3
                                    context.fill(Circle().path(in: trailRect), with: .color(.white))
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        updateFireworks(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.06),
                        Color(red: 0.05, green: 0.03, blue: 0.1)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        launchFirework(at: value.location, size: geo.size)
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if Double.random(in: 0...1) < 0.1 {
                            launchFirework(at: value.location, size: geo.size)
                        }
                    }
            )
        }
    }
    
    private func launchFirework(at point: CGPoint, size: CGSize) {
        guard fireworks.count < 15 else { return }
        var fw = Firework(
            x: Double(point.x),
            y: Double(size.height),
            targetY: Double(point.y),
            vy: -Double.random(in: 300...500)
        )
        fw.hue = Double.random(in: 0...1)
        fireworks.append(fw)
    }
    
    private func updateFireworks(dt: Double, size: CGSize) {
        for i in fireworks.indices {
            if !fireworks[i].hasExploded {
                fireworks[i].y += fireworks[i].vy * dt
                fireworks[i].vy *= (1.0 - 0.5 * dt)
                
                if fireworks[i].y <= fireworks[i].targetY {
                    // Explode!
                    fireworks[i].hasExploded = true
                    let count = Int.random(in: 30...60)
                    let hue = fireworks[i].hue
                    for _ in 0..<count {
                        let angle = Double.random(in: 0...(2 * .pi))
                        let speed = Double.random(in: 50...200)
                        let particleHue = hue + Double.random(in: -0.1...0.1)
                        fireworks[i].particles.append(FireworkParticle(
                            x: fireworks[i].x,
                            y: fireworks[i].y,
                            vx: cos(angle) * speed,
                            vy: sin(angle) * speed,
                            radius: Double.random(in: 1.5...4),
                            color: Color(hue: particleHue.truncatingRemainder(dividingBy: 1.0), saturation: 0.8, brightness: 1.0),
                            lifetime: Double.random(in: 0.8...2.0)
                        ))
                    }
                }
            } else {
                for j in fireworks[i].particles.indices {
                    fireworks[i].particles[j].vy += 80 * dt // gravity
                    fireworks[i].particles[j].x += fireworks[i].particles[j].vx * dt
                    fireworks[i].particles[j].y += fireworks[i].particles[j].vy * dt
                    fireworks[i].particles[j].vx *= (1.0 - 1.5 * dt)
                    fireworks[i].particles[j].vy *= (1.0 - 0.8 * dt)
                    fireworks[i].particles[j].age += dt
                }
            }
        }
        
        // Remove fully faded fireworks
        fireworks.removeAll { fw in
            fw.hasExploded && fw.particles.allSatisfy { $0.age >= $0.lifetime }
        }
    }
}

private struct Firework {
    var x: Double
    var y: Double
    var targetY: Double
    var vy: Double
    var hue: Double = 0
    var hasExploded: Bool = false
    var particles: [FireworkParticle] = []
}

private struct FireworkParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var color: Color
    var lifetime: Double
    var age: Double = 0
}
