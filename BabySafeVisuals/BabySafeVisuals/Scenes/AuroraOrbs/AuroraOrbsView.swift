import SwiftUI

struct AuroraOrbsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbs: [AuroraOrb] = []
    @State private var lastUpdate: Date = .now
    @State private var touchPoint: CGPoint? = nil
    @State private var currentSize: CGSize = .zero

    private let orbCount = 8

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                let time = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    // Draw aurora bands with layered depth
                    for orb in orbs {
                        let speed = reduceMotion ? orb.speed * 0.3 : orb.speed
                        let phase = time * speed + orb.phaseOffset
                        let cx = orb.baseX + sin(phase) * orb.amplitudeX
                        let cy = orb.baseY + cos(phase * 0.7) * orb.amplitudeY

                        // Outer glow
                        let outerR = orb.radius * 1.4
                        let outerGradient = Gradient(colors: [
                            orb.color.opacity(orb.opacity * 0.2),
                            orb.color.opacity(orb.opacity * 0.05),
                            .clear
                        ])
                        context.fill(
                            Ellipse().path(in: CGRect(x: cx - outerR, y: cy - outerR, width: outerR * 2, height: outerR * 2)),
                            with: .radialGradient(outerGradient, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: outerR)
                        )

                        // Inner core
                        let coreGradient = Gradient(colors: [
                            orb.color.opacity(orb.opacity * 0.6),
                            orb.color.opacity(orb.opacity * 0.25),
                            orb.color.opacity(0.0)
                        ])
                        context.fill(
                            Ellipse().path(in: CGRect(x: cx - orb.radius, y: cy - orb.radius, width: orb.radius * 2, height: orb.radius * 2)),
                            with: .radialGradient(coreGradient, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: orb.radius)
                        )
                    }

                    // Touch glow indicator
                    if let touch = touchPoint {
                        let touchGradient = Gradient(colors: [
                            Color.white.opacity(0.08),
                            .clear
                        ])
                        let tr: Double = 50
                        context.fill(
                            Circle().path(in: CGRect(x: Double(touch.x) - tr, y: Double(touch.y) - tr, width: tr * 2, height: tr * 2)),
                            with: .radialGradient(touchGradient, center: CGPoint(x: Double(touch.x), y: Double(touch.y)), startRadius: 0, endRadius: tr)
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
            .onChange(of: geo.size) { _, newSize in currentSize = newSize }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in touchPoint = value.location }
                    .onEnded { _ in touchPoint = nil }
            )
        }
    }

    private func initOrbs(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let colors: [Color] = [
            Color(red: 0.15, green: 0.85, blue: 0.55),
            Color(red: 0.25, green: 0.45, blue: 0.95),
            Color(red: 0.65, green: 0.25, blue: 0.85),
            Color(red: 0.15, green: 0.65, blue: 0.85),
            Color(red: 0.35, green: 0.85, blue: 0.65),
            Color(red: 0.55, green: 0.35, blue: 0.95),
            Color(red: 0.2, green: 0.7, blue: 0.75),
            Color(red: 0.45, green: 0.55, blue: 0.9),
        ]

        orbs = (0..<orbCount).map { i in
            AuroraOrb(
                baseX: Double.random(in: Double(size.width) * 0.1...Double(size.width) * 0.9),
                baseY: Double.random(in: Double(size.height) * 0.1...Double(size.height) * 0.9),
                radius: Double.random(in: 80...180),
                color: colors[i % colors.count],
                opacity: Double.random(in: 0.3...0.55),
                speed: Double.random(in: 0.08...0.25),
                phaseOffset: Double.random(in: 0...(2 * .pi)),
                amplitudeX: Double.random(in: 30...100),
                amplitudeY: Double.random(in: 20...70)
            )
        }
    }

    private func updateOrbs(dt: Double, size: CGSize) {
        guard let touch = touchPoint else { return }

        for i in orbs.indices {
            let dx = orbs[i].baseX - Double(touch.x)
            let dy = orbs[i].baseY - Double(touch.y)
            let dist = max(sqrt(dx * dx + dy * dy), 1)

            if dist < 250 {
                let force = (250 - dist) / 250 * 30 * dt
                orbs[i].baseX += (dx / dist) * force
                orbs[i].baseY += (dy / dist) * force

                orbs[i].baseX = max(0, min(Double(size.width), orbs[i].baseX))
                orbs[i].baseY = max(0, min(Double(size.height), orbs[i].baseY))
            }
        }
    }
}

private struct AuroraOrb {
    var baseX, baseY, radius: Double
    var color: Color
    var opacity, speed, phaseOffset, amplitudeX, amplitudeY: Double
}
