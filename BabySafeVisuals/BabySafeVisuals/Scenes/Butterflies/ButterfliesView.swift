import SwiftUI

struct ButterfliesView: View {
    @Environment(AppState.self) private var appState
    @State private var butterflies: [Butterfly] = []
    @State private var lastUpdate: Date = .now
    @State private var touchPoint: CGPoint? = nil
    
    private let wingColors: [Color] = [
        .orange, .purple, .blue, .pink, .yellow, .cyan, .red, .green
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    for bf in butterflies {
                        let wingAngle = sin(bf.age * 6) * 0.4  // Wing flap
                        
                        // Left wing
                        let leftWing = CGRect(
                            x: bf.x - bf.size * (1.0 + wingAngle),
                            y: bf.y - bf.size * 0.6,
                            width: bf.size * (0.8 + wingAngle * 0.5),
                            height: bf.size * 1.2
                        )
                        context.opacity = 0.7
                        context.fill(Ellipse().path(in: leftWing), with: .color(bf.color))
                        
                        // Right wing
                        let rightWing = CGRect(
                            x: bf.x + bf.size * 0.2,
                            y: bf.y - bf.size * 0.6,
                            width: bf.size * (0.8 + wingAngle * 0.5),
                            height: bf.size * 1.2
                        )
                        context.fill(Ellipse().path(in: rightWing), with: .color(bf.color))
                        
                        // Body
                        let bodyRect = CGRect(x: bf.x - 1.5, y: bf.y - bf.size * 0.4, width: 3, height: bf.size * 0.8)
                        context.opacity = 0.9
                        context.fill(Capsule().path(in: bodyRect), with: .color(.brown))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.15),
                        Color(red: 0.05, green: 0.15, blue: 0.1),
                        Color(red: 0.08, green: 0.12, blue: 0.08)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .onAppear { initButterflies(size: geo.size) }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in touchPoint = value.location }
                    .onEnded { _ in touchPoint = nil }
            )
        }
    }
    
    private func initButterflies(size: CGSize) {
        butterflies = (0..<10).map { _ in
            Butterfly(
                x: Double.random(in: 30...Double(size.width) - 30),
                y: Double.random(in: 30...Double(size.height) - 30),
                vx: Double.random(in: -20...20),
                vy: Double.random(in: -20...20),
                size: Double.random(in: 10...20),
                color: wingColors.randomElement()!,
                age: Double.random(in: 0...10)
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        for i in butterflies.indices {
            butterflies[i].age += dt
            
            // Follow finger
            if let touch = touchPoint {
                let dx = Double(touch.x) - butterflies[i].x
                let dy = Double(touch.y) - butterflies[i].y
                let dist = sqrt(dx * dx + dy * dy)
                if dist > 10 {
                    butterflies[i].vx += (dx / dist) * 60 * dt
                    butterflies[i].vy += (dy / dist) * 60 * dt
                }
            }
            
            // Random wandering
            butterflies[i].vx += Double.random(in: -30...30) * dt
            butterflies[i].vy += Double.random(in: -30...30) * dt
            
            // Speed limit
            let speed = sqrt(butterflies[i].vx * butterflies[i].vx + butterflies[i].vy * butterflies[i].vy)
            if speed > 60 {
                butterflies[i].vx *= 60 / speed
                butterflies[i].vy *= 60 / speed
            }
            
            // Damping
            butterflies[i].vx *= (1.0 - 1.0 * dt)
            butterflies[i].vy *= (1.0 - 1.0 * dt)
            
            butterflies[i].x += butterflies[i].vx * dt
            butterflies[i].y += butterflies[i].vy * dt
            
            // Wrap
            if butterflies[i].x < -20 { butterflies[i].x = Double(size.width) + 20 }
            if butterflies[i].x > Double(size.width) + 20 { butterflies[i].x = -20 }
            if butterflies[i].y < -20 { butterflies[i].y = Double(size.height) + 20 }
            if butterflies[i].y > Double(size.height) + 20 { butterflies[i].y = -20 }
        }
    }
}

private struct Butterfly {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var size: Double
    var color: Color
    var age: Double
}
