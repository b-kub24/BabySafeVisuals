import SwiftUI

struct SnowglobeView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(AppState.self) private var appState
    @State private var particles: [SnowParticle] = []
    @State private var lastUpdate: Date = .now
    @State private var isInitialized = false

    private let maxParticles = 400
    private let spawnRate = 3
    
    // Night mode colors
    private var particleColor: Color {
        appState.isNightModeActive ? NightModeColors.snowglobeParticleColor : .white
    }
    
    private var secondaryParticleColor: Color {
        appState.isNightModeActive ? NightModeColors.snowglobeParticleColor.opacity(0.7) : Color(red: 0.7, green: 0.85, blue: 1.0)
    }
    
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? NightModeColors.snowglobeGradient : [
            Color(red: 0.05, green: 0.08, blue: 0.2),
            Color(red: 0.1, green: 0.15, blue: 0.35),
            Color(red: 0.15, green: 0.2, blue: 0.4)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: backgroundGradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let now = timeline.date
                        let baseDt = min(now.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                        let dt = baseDt * appState.animationSpeedMultiplier

                        // Draw each snowflake
                        for particle in particles {
                            let lifeFraction = particle.age / particle.lifetime
                            guard lifeFraction < 1.0 else { continue }
                            
                            // Fade in at start, fade out at end
                            let fadeIn = min(particle.age / 0.5, 1.0)
                            let fadeOut = 1.0 - max((lifeFraction - 0.8) / 0.2, 0.0)
                            let opacity = particle.opacity * fadeIn * fadeOut
                            guard opacity > 0.01 else { continue }
                            
                            let rect = CGRect(
                                x: particle.x - particle.radius,
                                y: particle.y - particle.radius,
                                width: particle.radius * 2,
                                height: particle.radius * 2
                            )
                            
                            // Alternate white and light blue snowflakes
                            let color = particle.isBlue ? secondaryParticleColor : particleColor
                            
                            context.opacity = opacity
                            
                            // Larger particles get a soft glow
                            if particle.radius > 2.5 {
                                let glowRect = CGRect(
                                    x: particle.x - particle.radius * 2,
                                    y: particle.y - particle.radius * 2,
                                    width: particle.radius * 4,
                                    height: particle.radius * 4
                                )
                                context.opacity = opacity * 0.15
                                context.fill(
                                    Circle().path(in: glowRect),
                                    with: .color(color)
                                )
                                context.opacity = opacity
                            }
                            
                            context.fill(
                                Circle().path(in: rect),
                                with: .color(color)
                            )
                        }

                        DispatchQueue.main.async {
                            updateParticles(dt: dt, size: size)
                            lastUpdate = now
                        }
                    }
                }
            }
            .onAppear {
                if !isInitialized {
                    initParticles(size: geo.size)
                    lastUpdate = .now
                    isInitialized = true
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addTouchBurst(at: value.location, size: geo.size)
                    }
            )
        }
    }

    private func initParticles(size: CGSize) {
        particles = (0..<maxParticles / 2).map { _ in
            SnowParticle.random(in: size, existingAge: true)
        }
    }

    private func updateParticles(dt: Double, size: CGSize) {
        let shake = motion.shakeIntensity
        let tiltX = motion.tiltX
        let tiltY = motion.tiltY

        // Spawn new particles
        if particles.count < maxParticles {
            for _ in 0..<spawnRate {
                particles.append(SnowParticle.random(in: size, existingAge: false))
            }
        }

        // Update existing particles
        for i in particles.indices {
            particles[i].age += dt

            // Gravity + tilt
            particles[i].vy += 15 * dt
            particles[i].vx += tiltX * 30 * dt
            particles[i].vy -= tiltY * 15 * dt

            // Shake adds energy — like a real snowglobe
            if shake > 0.5 {
                let force = shake * 4.0  // Strong multiplier for satisfying shake
                particles[i].vx += Double.random(in: -force * 50...force * 50) * dt
                particles[i].vy += Double.random(in: -force * 80...force * 10) * dt
                // Add chaotic spin
                particles[i].vx += Double.random(in: -20...20) * dt
            }

            // Gentle drift
            particles[i].vx += sin(particles[i].age * particles[i].driftFreq) * 5 * dt

            // Damping — gradual settling like a real snowglobe
            let dampX = shake > 0.3 ? 0.1 : 0.5  // Less damping during shake for more chaos
            let dampY = shake > 0.3 ? 0.05 : 0.3
            particles[i].vx *= (1.0 - dampX * dt)
            particles[i].vy *= (1.0 - dampY * dt)

            // Move
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt

            // Wrap horizontally
            if particles[i].x < -10 { particles[i].x = size.width + 10 }
            if particles[i].x > size.width + 10 { particles[i].x = -10 }

            // Settle at bottom
            if particles[i].y > size.height + 10 {
                particles[i].y = size.height - Double.random(in: 0...5)
                particles[i].vy = 0
                particles[i].vx *= 0.1
            }
        }

        // Remove dead particles
        particles.removeAll { $0.age >= $0.lifetime }
    }

    private func addTouchBurst(at point: CGPoint, size: CGSize) {
        let burstCount = 8
        guard particles.count + burstCount <= maxParticles + 50 else { return }
        for _ in 0..<burstCount {
            var p = SnowParticle.random(in: size, existingAge: false)
            p.x = Double(point.x) + Double.random(in: -20...20)
            p.y = Double(point.y) + Double.random(in: -20...20)
            p.vx = Double.random(in: -30...30)
            p.vy = Double.random(in: -40...10)
            p.radius = Double.random(in: 1.5...4)
            particles.append(p)
        }
    }
}

struct SnowParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var opacity: Double
    var age: Double
    var lifetime: Double
    var driftFreq: Double
    var isBlue: Bool

    static func random(in size: CGSize, existingAge: Bool) -> SnowParticle {
        SnowParticle(
            x: Double.random(in: 0...Double(size.width)),
            y: existingAge ? Double.random(in: 0...Double(size.height)) : Double.random(in: -20...0),
            vx: Double.random(in: -10...10),
            vy: Double.random(in: 5...25),
            radius: Double.random(in: 1...5),
            opacity: Double.random(in: 0.4...1.0),
            age: existingAge ? Double.random(in: 0...15) : 0,
            lifetime: Double.random(in: 15...30),
            driftFreq: Double.random(in: 0.5...2.0),
            isBlue: Bool.random()
        )
    }
}
