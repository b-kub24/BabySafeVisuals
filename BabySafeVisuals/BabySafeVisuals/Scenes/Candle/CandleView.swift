import SwiftUI

struct CandleView: View {
    @Environment(AppState.self) private var appState
    @State private var flameParticles: [FlameParticle] = []
    @State private var lastUpdate: Date = .now
    @State private var flickerOffset: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let cx = size.width / 2
                    let candleBottom = size.height * 0.75
                    let candleTop = size.height * 0.45
                    
                    // Candle body
                    let candleRect = CGRect(x: cx - 25, y: candleTop, width: 50, height: candleBottom - candleTop)
                    context.opacity = 1.0
                    context.fill(
                        RoundedRectangle(cornerRadius: 4).path(in: candleRect),
                        with: .color(Color(red: 0.95, green: 0.9, blue: 0.8))
                    )
                    
                    // Wick
                    var wick = Path()
                    wick.move(to: CGPoint(x: cx, y: candleTop))
                    wick.addLine(to: CGPoint(x: cx + flickerOffset * 2, y: candleTop - 20))
                    context.opacity = 0.7
                    context.stroke(wick, with: .color(.black), lineWidth: 2)
                    
                    // Flame glow
                    let glowCenter = CGPoint(x: cx + flickerOffset * 3, y: candleTop - 45)
                    for r in stride(from: 60.0, through: 10.0, by: -10.0) {
                        let rect = CGRect(x: glowCenter.x - r, y: glowCenter.y - r, width: r * 2, height: r * 2)
                        context.opacity = 0.05
                        context.fill(Circle().path(in: rect), with: .color(.orange))
                    }
                    
                    // Flame body (layered ellipses)
                    let flameX = cx + flickerOffset * 4
                    let flameY = candleTop - 40
                    
                    // Outer flame (orange)
                    let outerRect = CGRect(x: flameX - 12, y: flameY - 25, width: 24, height: 50)
                    context.opacity = 0.7
                    context.fill(Ellipse().path(in: outerRect), with: .color(.orange))
                    
                    // Mid flame (yellow)
                    let midRect = CGRect(x: flameX - 8, y: flameY - 18, width: 16, height: 36)
                    context.opacity = 0.8
                    context.fill(Ellipse().path(in: midRect), with: .color(.yellow))
                    
                    // Inner flame (white)
                    let innerRect = CGRect(x: flameX - 4, y: flameY - 8, width: 8, height: 20)
                    context.opacity = 0.9
                    context.fill(Ellipse().path(in: innerRect), with: .color(.white))
                    
                    // Floating particles
                    for p in flameParticles {
                        let fade = 1.0 - p.age / p.lifetime
                        guard fade > 0 else { continue }
                        let r = p.radius * fade
                        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
                        context.opacity = fade * 0.5
                        context.fill(Circle().path(in: rect), with: .color(p.color))
                    }
                    
                    // Wax drips
                    let drip1 = CGRect(x: cx + 20, y: candleTop + 15, width: 8, height: 20)
                    let drip2 = CGRect(x: cx - 22, y: candleTop + 30, width: 6, height: 15)
                    context.opacity = 0.5
                    context.fill(Ellipse().path(in: drip1), with: .color(Color(red: 0.9, green: 0.85, blue: 0.75)))
                    context.fill(Ellipse().path(in: drip2), with: .color(Color(red: 0.9, green: 0.85, blue: 0.75)))
                    
                    DispatchQueue.main.async {
                        updateFlame(dt: dt, cx: cx, candleTop: candleTop)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    RadialGradient(colors: [
                        Color(red: 0.1, green: 0.06, blue: 0.02),
                        Color(red: 0.04, green: 0.02, blue: 0.01),
                        Color.black
                    ], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 50, endRadius: 400)
                )
            }
        }
    }
    
    private func updateFlame(dt: Double, cx: Double, candleTop: Double) {
        // Flicker
        flickerOffset = sin(Date.now.timeIntervalSinceReferenceDate * 8) * 2 + sin(Date.now.timeIntervalSinceReferenceDate * 13) * 1.5
        
        // Spawn particles
        if flameParticles.count < 30 {
            let colors: [Color] = [.orange, .yellow, Color(red: 1, green: 0.6, blue: 0.2)]
            flameParticles.append(FlameParticle(
                x: cx + flickerOffset * 3 + Double.random(in: -6...6),
                y: candleTop - 50 + Double.random(in: -10...0),
                vy: Double.random(in: -40 ... -15),
                radius: Double.random(in: 1...3),
                color: colors.randomElement()!,
                lifetime: Double.random(in: 0.5...1.5)
            ))
        }
        
        // Update particles
        for i in flameParticles.indices {
            flameParticles[i].y += flameParticles[i].vy * dt
            flameParticles[i].x += sin(flameParticles[i].age * 5) * 5 * dt
            flameParticles[i].age += dt
        }
        
        flameParticles.removeAll { $0.age >= $0.lifetime }
    }
}

private struct FlameParticle {
    var x: Double
    var y: Double
    var vy: Double
    var radius: Double
    var color: Color
    var lifetime: Double
    var age: Double = 0
}
