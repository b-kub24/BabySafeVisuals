import SwiftUI

struct CalmStaticView: View {
    @State private var glowPoints: [GlowPoint] = []
    @State private var lastUpdate: Date = .now
    @State private var stars: [Star] = []
    @State private var hasInitialized = false

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 15.0)

                Canvas { context, size in
                    // Cached stars with gentle twinkle
                    for star in stars {
                        let twinkle = (sin(time * star.twinkleSpeed + star.phaseOffset) + 1) / 2
                        let opacity = star.baseOpacity + twinkle * 0.25

                        let rect = CGRect(
                            x: star.x - star.radius,
                            y: star.y - star.radius,
                            width: star.radius * 2,
                            height: star.radius * 2
                        )
                        context.opacity = opacity
                        context.fill(Circle().path(in: rect), with: .color(.white))

                        // Subtle glow for brighter stars
                        if star.baseOpacity > 0.3 {
                            let glowR = star.radius * 3
                            let glowGradient = Gradient(colors: [
                                Color.white.opacity(opacity * 0.15),
                                .clear
                            ])
                            context.fill(
                                Circle().path(in: CGRect(
                                    x: star.x - glowR, y: star.y - glowR,
                                    width: glowR * 2, height: glowR * 2
                                )),
                                with: .radialGradient(
                                    glowGradient,
                                    center: CGPoint(x: star.x, y: star.y),
                                    startRadius: 0,
                                    endRadius: glowR
                                )
                            )
                        }
                    }

                    // Central breathing glow
                    let breathe = (sin(time * 0.15) + 1) / 2 * 0.06 + 0.02
                    let breatheR = min(size.width, size.height) * 0.4
                    let breatheGradient = Gradient(colors: [
                        Color(red: 0.2, green: 0.25, blue: 0.5).opacity(breathe),
                        .clear
                    ])
                    context.fill(
                        Circle().path(in: CGRect(
                            x: size.width / 2 - breatheR,
                            y: size.height / 2 - breatheR,
                            width: breatheR * 2,
                            height: breatheR * 2
                        )),
                        with: .radialGradient(
                            breatheGradient,
                            center: CGPoint(x: size.width / 2, y: size.height / 2),
                            startRadius: 0,
                            endRadius: breatheR
                        )
                    )

                    // Touch glow points
                    for glow in glowPoints {
                        let progress = glow.age / glow.lifetime
                        guard progress < 1.0 else { continue }

                        let alpha = (1.0 - progress) * 0.25
                        let radius = 35.0 + progress * 25.0
                        let gradient = Gradient(colors: [
                            Color.white.opacity(alpha),
                            Color(red: 0.35, green: 0.4, blue: 0.75).opacity(alpha * 0.4),
                            .clear
                        ])
                        context.fill(
                            Circle().path(in: CGRect(
                                x: glow.x - radius, y: glow.y - radius,
                                width: radius * 2, height: radius * 2
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
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.03, green: 0.03, blue: 0.07),
                            Color(red: 0.05, green: 0.05, blue: 0.11),
                            Color(red: 0.03, green: 0.03, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: timeline.date) { _, newDate in
                    for i in glowPoints.indices {
                        glowPoints[i].age += dt
                    }
                    glowPoints.removeAll { $0.age >= $0.lifetime }
                    lastUpdate = newDate
                }
            }
            .onAppear {
                if !hasInitialized {
                    initStars(size: geo.size)
                    hasInitialized = true
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in addGlow(at: value.location) }
            )
        }
    }

    private func initStars(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        stars = (0..<50).map { _ in
            Star(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                radius: Double.random(in: 0.5...1.8),
                baseOpacity: Double.random(in: 0.1...0.5),
                twinkleSpeed: Double.random(in: 0.3...0.8),
                phaseOffset: Double.random(in: 0...(2 * .pi))
            )
        }
    }

    private func addGlow(at point: CGPoint) {
        guard glowPoints.count < 10 else { return }
        if let last = glowPoints.last {
            let dx = last.x - Double(point.x)
            let dy = last.y - Double(point.y)
            if sqrt(dx * dx + dy * dy) < 25 { return }
        }

        glowPoints.append(GlowPoint(
            x: Double(point.x),
            y: Double(point.y),
            age: 0,
            lifetime: Double.random(in: 3...6)
        ))
    }
}

private struct Star {
    let x, y, radius, baseOpacity, twinkleSpeed, phaseOffset: Double
}

private struct GlowPoint {
    var x, y, age, lifetime: Double
}
