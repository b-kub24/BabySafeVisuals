import SwiftUI

struct AuroraOrbsView: View {
    @Environment(AppState.self) private var appState
    @State private var orbs: [AuroraOrb] = []
    @State private var lastUpdate: Date = .now
    @State private var touchPoint: CGPoint? = nil

    private let orbCount = 6
    
    // Night mode colors
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? NightModeColors.auroraGradient : [
            Color(red: 0.02, green: 0.05, blue: 0.12),
            Color(red: 0.04, green: 0.1, blue: 0.18),
            Color(red: 0.02, green: 0.08, blue: 0.15)
        ]
    }
    
    private var orbColors: [Color] {
        appState.isNightModeActive ? NightModeColors.auroraColors : [
            Color(red: 0.2, green: 0.8, blue: 0.6),
            Color(red: 0.3, green: 0.5, blue: 0.9),
            Color(red: 0.6, green: 0.3, blue: 0.8),
            Color(red: 0.2, green: 0.6, blue: 0.8),
            Color(red: 0.4, green: 0.8, blue: 0.7),
            Color(red: 0.5, green: 0.4, blue: 0.9)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    // Apply animation speed multiplier for night mode (slower movement)
                    let speedMultiplier = appState.animationSpeedMultiplier

                    // Draw aurora bands
                    for orb in orbs {
                        // Slow down the phase animation in night mode
                        let phase = time * orb.speed * speedMultiplier + orb.phaseOffset
                        let cx = orb.baseX + sin(phase) * orb.amplitudeX
                        let cy = orb.baseY + cos(phase * 0.7) * orb.amplitudeY

                        let gradient = Gradient(colors: [
                            orb.color.opacity(0.5),
                            orb.color.opacity(0.2),
                            orb.color.opacity(0.0)
                        ])

                        let rect = CGRect(
                            x: cx - orb.radius,
                            y: cy - orb.radius,
                            width: orb.radius * 2,
                            height: orb.radius * 2
                        )

                        context.drawLayer { ctx in
                            ctx.opacity = orb.opacity
                            ctx.fill(
                                Ellipse().path(in: rect),
                                with: .radialGradient(
                                    gradient,
                                    center: CGPoint(x: cx, y: cy),
                                    startRadius: 0,
                                    endRadius: orb.radius
                                )
                            )
                        }
                    }

                    DispatchQueue.main.async {
                        updateOrbs(dt: dt * speedMultiplier, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(
                        colors: backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .onAppear {
                initOrbs(size: geo.size)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchPoint = value.location
                    }
                    .onEnded { _ in
                        touchPoint = nil
                    }
            )
        }
    }

    private func initOrbs(size: CGSize) {
        let colors = orbColors

        orbs = (0..<orbCount).map { i in
            AuroraOrb(
                baseX: Double.random(in: 0...Double(size.width)),
                baseY: Double.random(in: 0...Double(size.height)),
                radius: Double.random(in: 100...200),
                color: colors[i % colors.count],
                opacity: Double.random(in: 0.3...0.6),
                speed: Double.random(in: 0.1...0.3),
                phaseOffset: Double.random(in: 0...(2 * .pi)),
                amplitudeX: Double.random(in: 30...80),
                amplitudeY: Double.random(in: 20...60)
            )
        }
    }

    private func updateOrbs(dt: Double, size: CGSize) {
        guard let touch = touchPoint else { return }

        // Touch gently repels orbs
        for i in orbs.indices {
            let dx = orbs[i].baseX - Double(touch.x)
            let dy = orbs[i].baseY - Double(touch.y)
            let dist = sqrt(dx * dx + dy * dy)

            if dist < 200, dist > 1 {
                let force = (200 - dist) / 200 * 15 * dt
                orbs[i].baseX += (dx / dist) * force
                orbs[i].baseY += (dy / dist) * force

                // Keep in bounds
                orbs[i].baseX = max(0, min(Double(size.width), orbs[i].baseX))
                orbs[i].baseY = max(0, min(Double(size.height), orbs[i].baseY))
            }
        }
    }
}

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
