import SwiftUI

struct CalmStaticView: View {
    @State private var glowPoints: [GlowPoint] = []
    @State private var lastUpdate: Date = .now

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 15.0)

                    // Subtle stars
                    for i in 0..<40 {
                        let seed = Double(i) * 137.5
                        let x = (seed.truncatingRemainder(dividingBy: Double(size.width)))
                        let y = ((seed * 2.3).truncatingRemainder(dividingBy: Double(size.height)))
                        let twinkle = (sin(time * 0.5 + seed) + 1) / 2 * 0.4 + 0.1
                        let r = 1.0 + sin(seed) * 0.5

                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.opacity = twinkle
                        context.fill(Circle().path(in: rect), with: .color(.white))
                    }

                    // Touch glow points
                    for glow in glowPoints {
                        let progress = glow.age / glow.lifetime
                        guard progress < 1.0 else { continue }

                        let alpha = (1.0 - progress) * 0.3
                        let radius = 40.0 + progress * 30.0
                        let gradient = Gradient(colors: [
                            Color.white.opacity(alpha),
                            Color(red: 0.4, green: 0.5, blue: 0.8).opacity(alpha * 0.5),
                            Color.clear
                        ])

                        context.drawLayer { ctx in
                            ctx.fill(
                                Circle().path(in: CGRect(
                                    x: glow.x - radius,
                                    y: glow.y - radius,
                                    width: radius * 2,
                                    height: radius * 2
                                )),
                                with: .radialGradient(
                                    gradient,
                                    center: CGPoint(x: glow.x, y: glow.y),
                                    startRadius: 0,
                                    endRadius: radius
                                )
                            )
                        }
                    }

                    DispatchQueue.main.async {
                        for i in glowPoints.indices {
                            glowPoints[i].age += dt
                        }
                        glowPoints.removeAll { $0.age >= $0.lifetime }
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.04, blue: 0.08),
                            Color(red: 0.06, green: 0.06, blue: 0.12),
                            Color(red: 0.04, green: 0.04, blue: 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addGlow(at: value.location)
                    }
            )
        }
    }

    private func addGlow(at point: CGPoint) {
        guard glowPoints.count < 8 else { return }

        // Throttle
        if let last = glowPoints.last {
            let dx = last.x - Double(point.x)
            let dy = last.y - Double(point.y)
            if sqrt(dx * dx + dy * dy) < 30 { return }
        }

        glowPoints.append(GlowPoint(
            x: Double(point.x),
            y: Double(point.y),
            age: 0,
            lifetime: Double.random(in: 3...5)
        ))
    }
}

private struct GlowPoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var age: Double
    var lifetime: Double
}
