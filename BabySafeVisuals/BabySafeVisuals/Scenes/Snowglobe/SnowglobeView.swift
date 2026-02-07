import SwiftUI

struct SnowglobeView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [SnowParticle] = []
    @State private var touchGlows: [TouchGlow] = []
    @State private var lastUpdate: Date = .now
    @State private var currentSize: CGSize = .zero

    private let maxParticles = 400
    private let spawnRate = 3

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                Canvas { context, size in
                    // Vignette overlay for depth
                    let vignetteGradient = Gradient(colors: [
                        .clear,
                        Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.5)
                    ])
                    context.fill(
                        Rectangle().path(in: CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            vignetteGradient,
                            center: CGPoint(x: size.width / 2, y: size.height / 2),
                            startRadius: min(size.width, size.height) * 0.3,
                            endRadius: max(size.width, size.height) * 0.8
                        )
                    )

                    // Touch glow points
                    for glow in touchGlows {
                        let progress = glow.age / glow.lifetime
                        guard progress < 1.0 else { continue }
                        let alpha = (1.0 - progress) * 0.15
                        let r = 30.0 + progress * 20.0
                        let gradient = Gradient(colors: [
                            Color.white.opacity(alpha),
                            Color(red: 0.6, green: 0.7, blue: 1.0).opacity(alpha * 0.3),
                            .clear
                        ])
                        context.fill(
                            Circle().path(in: CGRect(x: glow.x - r, y: glow.y - r, width: r * 2, height: r * 2)),
                            with: .radialGradient(gradient, center: CGPoint(x: glow.x, y: glow.y), startRadius: 0, endRadius: r)
                        )
                    }

                    // Snow particles with fade-in/out
                    for particle in particles {
                        let lifeProgress = particle.age / particle.lifetime
                        guard lifeProgress < 1.0 else { continue }
                        let fadeIn = min(particle.age / 0.5, 1.0)
                        let fadeOut = 1.0 - max(0, (lifeProgress - 0.8) / 0.2)
                        let opacity = particle.opacity * fadeIn * fadeOut

                        let rect = CGRect(
                            x: particle.x - particle.radius,
                            y: particle.y - particle.radius,
                            width: particle.radius * 2,
                            height: particle.radius * 2
                        )
                        context.opacity = opacity
                        context.fill(Circle().path(in: rect), with: .color(.white))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.09, blue: 0.22),
                            Color(red: 0.12, green: 0.17, blue: 0.33),
                            Color(red: 0.08, green: 0.12, blue: 0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: timeline.date) { _, newDate in
                    updateParticles(dt: dt, size: currentSize)
                    updateTouchGlows(dt: dt)
                    lastUpdate = newDate
                }
            }
            .onAppear {
                currentSize = geo.size
                initParticles(size: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                currentSize = newSize
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addTouchBurst(at: value.location, size: currentSize)
                    }
            )
        }
    }

    private func initParticles(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        particles = (0..<maxParticles / 2).map { _ in
            SnowParticle.random(in: size, existingAge: true)
        }
    }

    private func updateTouchGlows(dt: Double) {
        for i in touchGlows.indices {
            touchGlows[i].age += dt
        }
        touchGlows.removeAll { $0.age >= $0.lifetime }
    }

    private func updateParticles(dt: Double, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let shake = reduceMotion ? 0 : motion.shakeIntensity
        let tiltX = reduceMotion ? 0 : motion.tiltX
        let tiltY = reduceMotion ? 0 : motion.tiltY

        if particles.count < maxParticles {
            for _ in 0..<spawnRate {
                particles.append(SnowParticle.random(in: size, existingAge: false))
            }
        }

        for i in particles.indices {
            particles[i].age += dt
            particles[i].vy += 15 * dt
            particles[i].vx += tiltX * 30 * dt
            particles[i].vy -= tiltY * 15 * dt

            if shake > 0.5 {
                particles[i].vx += Double.random(in: -shake * 40...shake * 40) * dt
                particles[i].vy += Double.random(in: -shake * 60...shake * 20) * dt
            }

            particles[i].vx += sin(particles[i].age * particles[i].driftFreq) * 5 * dt
            particles[i].vx *= (1.0 - 0.3 * dt)
            particles[i].vy *= (1.0 - 0.2 * dt)
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt

            if particles[i].x < -10 { particles[i].x = size.width + 10 }
            if particles[i].x > size.width + 10 { particles[i].x = -10 }

            if particles[i].y > size.height + 10 {
                particles[i].y = size.height - Double.random(in: 0...5)
                particles[i].vy = 0
                particles[i].vx *= 0.1
            }
            if particles[i].y < -30 {
                particles[i].y = -5
                particles[i].vy = abs(particles[i].vy) * 0.3
            }
        }

        particles.removeAll { $0.age >= $0.lifetime }
    }

    private func addTouchBurst(at point: CGPoint, size: CGSize) {
        let burstCount = 8
        guard particles.count + burstCount <= maxParticles + 50 else { return }

        if touchGlows.count < 6 {
            if let last = touchGlows.last {
                let dx = last.x - Double(point.x)
                let dy = last.y - Double(point.y)
                guard sqrt(dx * dx + dy * dy) > 25 else { return }
            }
            touchGlows.append(TouchGlow(x: Double(point.x), y: Double(point.y), age: 0, lifetime: 2.0))
        }

        for _ in 0..<burstCount {
            var p = SnowParticle.random(in: size, existingAge: false)
            p.x = Double(point.x) + Double.random(in: -20...20)
            p.y = Double(point.y) + Double.random(in: -20...20)
            p.vx = Double.random(in: -30...30)
            p.vy = Double.random(in: -40...10)
            p.radius = Double.random(in: 1.5...4.5)
            particles.append(p)
        }
    }
}

private struct SnowParticle {
    var x, y, vx, vy, radius, opacity, age, lifetime, driftFreq: Double

    static func random(in size: CGSize, existingAge: Bool) -> SnowParticle {
        SnowParticle(
            x: Double.random(in: 0...max(1, Double(size.width))),
            y: existingAge ? Double.random(in: 0...max(1, Double(size.height))) : Double.random(in: -20...0),
            vx: Double.random(in: -10...10),
            vy: Double.random(in: 5...25),
            radius: Double.random(in: 1...4.5),
            opacity: Double.random(in: 0.3...0.9),
            age: existingAge ? Double.random(in: 0...15) : 0,
            lifetime: Double.random(in: 15...30),
            driftFreq: Double.random(in: 0.5...2.0)
        )
    }
}

private struct TouchGlow {
    var x, y, age, lifetime: Double
}
