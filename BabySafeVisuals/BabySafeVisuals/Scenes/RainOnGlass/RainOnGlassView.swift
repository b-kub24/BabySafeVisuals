import SwiftUI

struct RainOnGlassView: View {
    @Environment(AppState.self) private var appState
    @State private var drops: [RainDrop] = []
    @State private var streaks: [RainStreak] = []
    @State private var lastUpdate: Date = .now
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    // Draw streaks (flowing drops)
                    for streak in streaks {
                        var path = Path()
                        if streak.trail.count > 1 {
                            path.move(to: streak.trail[0])
                            for i in 1..<streak.trail.count {
                                path.addLine(to: streak.trail[i])
                            }
                        }
                        context.opacity = 0.15
                        context.stroke(path, with: .color(.white), lineWidth: streak.width)
                        
                        // Drop head
                        if let last = streak.trail.last {
                            let rect = CGRect(x: last.x - streak.width, y: last.y - streak.width, width: streak.width * 2, height: streak.width * 2)
                            context.opacity = 0.35
                            context.fill(Circle().path(in: rect), with: .color(.white))
                        }
                    }
                    
                    // Static droplets
                    for drop in drops {
                        let r = drop.radius * (1.0 + sin(drop.age * 2) * 0.1)
                        let rect = CGRect(x: drop.x - r, y: drop.y - r, width: r * 2, height: r * 2)
                        context.opacity = 0.2
                        context.fill(Circle().path(in: rect), with: .color(.white))
                        
                        // Highlight
                        let hlRect = CGRect(x: drop.x - r * 0.3, y: drop.y - r * 0.4, width: r * 0.4, height: r * 0.3)
                        context.opacity = 0.4
                        context.fill(Ellipse().path(in: hlRect), with: .color(.white))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.15, green: 0.18, blue: 0.25),
                        Color(red: 0.1, green: 0.12, blue: 0.18),
                        Color(red: 0.08, green: 0.09, blue: 0.14)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .onAppear { initScene(size: geo.size) }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Touch creates a drop
                        if drops.count < 100 {
                            drops.append(RainDrop(
                                x: Double(value.location.x) + Double.random(in: -5...5),
                                y: Double(value.location.y) + Double.random(in: -5...5),
                                radius: Double.random(in: 2...5)
                            ))
                        }
                    }
            )
        }
    }
    
    private func initScene(size: CGSize) {
        // Initial static drops
        drops = (0..<40).map { _ in
            RainDrop(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                radius: Double.random(in: 1.5...4)
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        // Update drop ages
        for i in drops.indices {
            drops[i].age += dt
        }
        
        // Spawn new streaks
        if streaks.count < 8 && Double.random(in: 0...1) < 0.03 {
            let x = Double.random(in: 0...Double(size.width))
            streaks.append(RainStreak(
                trail: [CGPoint(x: x, y: -5)],
                vy: Double.random(in: 80...200),
                width: Double.random(in: 1...3),
                wobble: Double.random(in: 0.5...2)
            ))
        }
        
        // Update streaks
        for i in streaks.indices {
            streaks[i].age += dt
            let lastY = streaks[i].trail.last?.y ?? 0
            let lastX = streaks[i].trail.last?.x ?? 0
            let newX = lastX + sin(streaks[i].age * streaks[i].wobble * 3) * 2
            let newY = lastY + streaks[i].vy * dt
            streaks[i].trail.append(CGPoint(x: newX, y: newY))
            
            // Limit trail length
            if streaks[i].trail.count > 20 { streaks[i].trail.removeFirst() }
        }
        
        // Remove off-screen streaks
        streaks.removeAll { $0.trail.last.map { $0.y > size.height + 10 } ?? true }
        
        // Random new static drops
        if drops.count < 80 && Double.random(in: 0...1) < 0.02 {
            drops.append(RainDrop(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: -5...0),
                radius: Double.random(in: 1.5...4)
            ))
        }
        
        // Drops slowly slide down
        for i in drops.indices {
            if drops[i].radius > 3 {
                drops[i].y += 5 * dt
            }
        }
        
        drops.removeAll { $0.y > Double(size.height) + 10 }
    }
}

private struct RainDrop {
    var x: Double
    var y: Double
    var radius: Double
    var age: Double = 0
}

private struct RainStreak {
    var trail: [CGPoint]
    var vy: Double
    var width: Double
    var wobble: Double
    var age: Double = 0
}
