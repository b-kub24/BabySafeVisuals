import SwiftUI

struct SnowglobeView: View {
    @Environment(MotionManager.self) private var motion
    @State private var particles: [SnowParticle] = []
    @State private var lastUpdate: Date = .now

    private let maxParticles = 400
    private let spawnRate = 3

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                    for particle in particles {
                        let opacity = particle.opacity * (1.0 - particle.age / particle.lifetime)
                        guard opacity > 0 else { continue }
                        let rect = CGRect(
                            x: particle.x - particle.radius,
                            y: particle.y - particle.radius,
                            width: particle.radius * 2,
                            height: particle.radius * 2
                        )
                        context.opacity = opacity
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(.white)
                        )
                    }

                    DispatchQueue.main.async {
                        updateParticles(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.12, blue: 0.25),
                            Color(red: 0.15, green: 0.2, blue: 0.35),
                            Color(red: 0.1, green: 0.15, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .onAppear {
                initParticles(size: geo.size)
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

            // Shake adds energy
            if shake > 0.5 {
                particles[i].vx += Double.random(in: -shake * 40...shake * 40) * dt
                particles[i].vy += Double.random(in: -shake * 60...shake * 20) * dt
            }

            // Gentle drift
            particles[i].vx += sin(particles[i].age * particles[i].driftFreq) * 5 * dt

            // Damping
            particles[i].vx *= (1.0 - 0.3 * dt)
            particles[i].vy *= (1.0 - 0.2 * dt)

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

    static func random(in size: CGSize, existingAge: Bool) -> SnowParticle {
        SnowParticle(
            x: Double.random(in: 0...Double(size.width)),
            y: existingAge ? Double.random(in: 0...Double(size.height)) : Double.random(in: -20...0),
            vx: Double.random(in: -10...10),
            vy: Double.random(in: 5...25),
            radius: Double.random(in: 1...4),
            opacity: Double.random(in: 0.3...0.9),
            age: existingAge ? Double.random(in: 0...15) : 0,
            lifetime: Double.random(in: 15...30),
            driftFreq: Double.random(in: 0.5...2.0)
        )
    }
}
