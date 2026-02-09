import SwiftUI
import UIKit

// MARK: - Orb Model

private struct AuroraOrb {
    var baseX: Double
    var baseY: Double
    var radius: Double
    var color: Color
    var opacity: Double
    var speed: Double
    var phaseOffset: Double
    var amplitudeX: Double
    var amplitudeY: Double
}

// MARK: - View

struct AuroraOrbsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var orbs: [AuroraOrb] = []
    @State private var lastUpdate: Date = .now
    @State private var touchPoint: CGPoint? = nil
    @State private var currentSize: CGSize = .zero

    private let orbCount = 8
    private let edgeDeadZone: Double = 15

    private let orbColors: [Color] = [
        Color(red: 0.15, green: 0.85, blue: 0.55),  // bright green
        Color(red: 0.25, green: 0.45, blue: 0.95),  // deep blue
        Color(red: 0.65, green: 0.25, blue: 0.85),  // rich purple
        Color(red: 0.15, green: 0.65, blue: 0.85),  // teal blue
        Color(red: 0.35, green: 0.85, blue: 0.65),  // mint green
        Color(red: 0.55, green: 0.35, blue: 0.95),  // violet
        Color(red: 0.20, green: 0.70, blue: 0.75),  // sea green
        Color(red: 0.45, green: 0.55, blue: 0.90),  // periwinkle
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                let time = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    let speedScale: Double = reduceMotion ? 0.3 : 1.0

                    // Draw each orb with outer glow + inner core
                    for orb in orbs {
                        let phase = time * orb.speed * speedScale + orb.phaseOffset
                        let cx = orb.baseX + sin(phase) * orb.amplitudeX
                        let cy = orb.baseY + cos(phase * 0.7) * orb.amplitudeY

                        // Outer glow layer
                        let outerR = orb.radius * 1.5
                        let outerGradient = Gradient(colors: [
                            orb.color.opacity(orb.opacity * 0.22),
                            orb.color.opacity(orb.opacity * 0.06),
                            .clear
                        ])
                        context.fill(
                            Ellipse().path(in: CGRect(
                                x: cx - outerR, y: cy - outerR,
                                width: outerR * 2, height: outerR * 2
                            )),
                            with: .radialGradient(
                                outerGradient,
                                center: CGPoint(x: cx, y: cy),
                                startRadius: 0,
                                endRadius: outerR
                            )
                        )

                        // Inner core layer
                        let coreGradient = Gradient(colors: [
                            orb.color.opacity(orb.opacity * 0.65),
                            orb.color.opacity(orb.opacity * 0.28),
                            orb.color.opacity(0.0)
                        ])
                        context.fill(
                            Ellipse().path(in: CGRect(
                                x: cx - orb.radius, y: cy - orb.radius,
                                width: orb.radius * 2, height: orb.radius * 2
                            )),
                            with: .radialGradient(
                                coreGradient,
                                center: CGPoint(x: cx, y: cy),
                                startRadius: 0,
                                endRadius: orb.radius
                            )
                        )
                    }

                    // Touch glow indicator
                    if let touch = touchPoint {
                        let touchGradient = Gradient(colors: [
                            Color.white.opacity(0.10),
                            Color(red: 0.3, green: 0.8, blue: 0.6).opacity(0.04),
                            .clear
                        ])
                        let tr: Double = 55
                        context.fill(
                            Circle().path(in: CGRect(
                                x: Double(touch.x) - tr,
                                y: Double(touch.y) - tr,
                                width: tr * 2,
                                height: tr * 2
                            )),
                            with: .radialGradient(
                                touchGradient,
                                center: CGPoint(x: Double(touch.x), y: Double(touch.y)),
                                startRadius: 0,
                                endRadius: tr
                            )
                        )
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.01, green: 0.03, blue: 0.10),
                            Color(red: 0.03, green: 0.08, blue: 0.16),
                            Color(red: 0.01, green: 0.06, blue: 0.13)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: timeline.date) { _, newDate in
                    updateOrbs(dt: dt, size: currentSize)
                    lastUpdate = newDate
                }
            }
            .onAppear {
                currentSize = geo.size
                initOrbs(size: geo.size)
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

    private func initOrbs(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let w = Double(size.width)
        let h = Double(size.height)

        orbs = (0..<orbCount).map { i in
            AuroraOrb(
                baseX: Double.random(in: w * 0.1...w * 0.9),
                baseY: Double.random(in: h * 0.1...h * 0.9),
                radius: Double.random(in: 80...180),
                color: orbColors[i % orbColors.count],
                opacity: Double.random(in: 0.30...0.55),
                speed: Double.random(in: 0.08...0.25),
                phaseOffset: Double.random(in: 0...(2 * .pi)),
                amplitudeX: Double.random(in: 30...100),
                amplitudeY: Double.random(in: 20...70)
            )
        }
    }

    // MARK: - Physics Update

    private func updateOrbs(dt: Double, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        guard let touch = touchPoint else { return }

        let repulsionRadius = 250.0 * appState.touchSensitivity.radiusMultiplier
        let w = Double(size.width)
        let h = Double(size.height)

        for i in orbs.indices {
            let dx = orbs[i].baseX - Double(touch.x)
            let dy = orbs[i].baseY - Double(touch.y)
            let dist = max(sqrt(dx * dx + dy * dy), 1.0)

            if dist < repulsionRadius {
                let strength = (repulsionRadius - dist) / repulsionRadius
                let force = strength * 35.0 * dt
                let nx = dx / dist
                let ny = dy / dist

                orbs[i].baseX += nx * force
                orbs[i].baseY += ny * force

                // Clamp to screen bounds
                orbs[i].baseX = max(0, min(w, orbs[i].baseX))
                orbs[i].baseY = max(0, min(h, orbs[i].baseY))
            }
        }
    }
}
