import SwiftUI
import UIKit

// MARK: - Particle Model

private struct MagneticParticle {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var hue: Double
}

// MARK: - View

struct MagneticParticlesView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var particles: [MagneticParticle] = []
    @State private var lastUpdate: Date = .now
    @State private var currentSize: CGSize = .zero
    @State private var touchPoint: CGPoint? = nil

    private let baseParticleCount = 200
    private let edgeDeadZone: Double = 15

    private var effectiveParticleCount: Int {
        var count = Int(Double(baseParticleCount) * appState.particleDensity.multiplier)

        // Battery-aware reduction
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel > 0 && batteryLevel < 0.2 {
            count = count / 2
        }

        return max(1, count)
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    for particle in particles {
                        let r = particle.radius
                        let rect = CGRect(
                            x: particle.x - r,
                            y: particle.y - r,
                            width: r * 2,
                            height: r * 2
                        )

                        // Glow layer (larger, faint)
                        let glowRadius = r * 3
                        let glowRect = CGRect(
                            x: particle.x - glowRadius,
                            y: particle.y - glowRadius,
                            width: glowRadius * 2,
                            height: glowRadius * 2
                        )
                        let glowColor = Color(
                            hue: particle.hue,
                            saturation: 0.5,
                            brightness: 1.0
                        ).opacity(0.15)
                        context.fill(
                            Circle().path(in: glowRect),
                            with: .radialGradient(
                                Gradient(colors: [glowColor, .clear]),
                                center: CGPoint(x: particle.x, y: particle.y),
                                startRadius: 0,
                                endRadius: glowRadius
                            )
                        )

                        // Core particle
                        let coreColor = Color(
                            hue: particle.hue,
                            saturation: 0.7,
                            brightness: 0.95
                        ).opacity(0.75)
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(coreColor)
                        )

                        // Bright center highlight
                        let hlRadius = r * 0.5
                        let hlRect = CGRect(
                            x: particle.x - hlRadius,
                            y: particle.y - hlRadius,
                            width: hlRadius * 2,
                            height: hlRadius * 2
                        )
                        let hlColor = Color(
                            hue: particle.hue,
                            saturation: 0.3,
                            brightness: 1.0
                        ).opacity(0.5)
                        context.fill(
                            Circle().path(in: hlRect),
                            with: .color(hlColor)
                        )
                    }
                }
                .background(Color(red: 0.08, green: 0.04, blue: 0.18))
                .onChange(of: timeline.date) { _, newDate in
                    updateParticles(dt: dt, size: currentSize)
                    lastUpdate = newDate
                }
            }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                currentSize = geo.size
                initParticles(size: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                currentSize = newSize
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let loc = value.location
                        // Ignore touches in the edge dead zone
                        if loc.x >= edgeDeadZone,
                           loc.x <= geo.size.width - edgeDeadZone,
                           loc.y >= edgeDeadZone,
                           loc.y <= geo.size.height - edgeDeadZone {
                            touchPoint = loc
                        } else {
                            touchPoint = nil
                        }
                    }
                    .onEnded { _ in
                        touchPoint = nil
                    }
            )
        }
    }

    // MARK: - Initialization

    private func initParticles(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let count = effectiveParticleCount
        particles = (0..<count).map { _ in
            MagneticParticle(
                x: Double.random(in: 0...size.width),
                y: Double.random(in: 0...size.height),
                vx: 0,
                vy: 0,
                radius: Double.random(in: 1.5...3.5),
                hue: Double.random(in: 0.55...0.9)
            )
        }
    }

    // MARK: - Physics Update

    private func updateParticles(dt: Double, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let tiltX = reduceMotion ? 0.0 : motion.tiltX
        let tiltY = reduceMotion ? 0.0 : motion.tiltY
        let hitRadiusScale = appState.touchSensitivity.radiusMultiplier
        let margin: Double = 10
        let damping: Double = 0.97

        for i in particles.indices {
            var vx = particles[i].vx
            var vy = particles[i].vy

            // Magnetic attraction to touch
            if let touch = touchPoint {
                let dx = touch.x - particles[i].x
                let dy = touch.y - particles[i].y
                let dist = sqrt(dx * dx + dy * dy)
                let hitRadius = 250.0 * hitRadiusScale

                if dist > 3, dist < hitRadius {
                    let strength = min(250.0 / max(dist, 1.0), 10.0)
                    let nx = dx / dist
                    let ny = dy / dist

                    // Attraction toward touch
                    vx += nx * strength * 50.0 * dt
                    vy += ny * strength * 50.0 * dt

                    // Orbital swirl component (perpendicular)
                    vx += (-ny) * strength * 18.0 * dt
                    vy += nx * strength * 18.0 * dt
                }
            }

            // Tilt response
            vx += tiltX * 25.0 * dt
            vy -= tiltY * 25.0 * dt

            // Damping
            vx *= damping
            vy *= damping

            // Integrate position
            var newX = particles[i].x + vx * dt
            var newY = particles[i].y + vy * dt

            // Soft boundary bounce
            if newX < margin {
                newX = margin
                vx = abs(vx) * 0.3
            } else if newX > size.width - margin {
                newX = size.width - margin
                vx = -abs(vx) * 0.3
            }

            if newY < margin {
                newY = margin
                vy = abs(vy) * 0.3
            } else if newY > size.height - margin {
                newY = size.height - margin
                vy = -abs(vy) * 0.3
            }

            particles[i].x = newX
            particles[i].y = newY
            particles[i].vx = vx
            particles[i].vy = vy
        }
    }
}
