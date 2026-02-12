import SwiftUI

struct AquariumView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @State private var fish: [Fish] = []
    @State private var bubbles: [AquaBubble] = []
    @State private var lastUpdate: Date = .now
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let baseDt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let dt = baseDt * appState.animationSpeedMultiplier
                    
                    // Draw bubbles
                    for b in bubbles {
                        let rect = CGRect(x: b.x - b.radius, y: b.y - b.radius, width: b.radius * 2, height: b.radius * 2)
                        context.opacity = 0.3
                        context.stroke(Circle().path(in: rect), with: .color(.white), lineWidth: 0.5)
                    }
                    
                    // Draw fish
                    for f in fish {
                        let direction: CGFloat = f.vx >= 0 ? 1 : -1
                        
                        // Body
                        let bodyRect = CGRect(x: f.x - f.size, y: f.y - f.size * 0.4, width: f.size * 2, height: f.size * 0.8)
                        context.opacity = 0.85
                        context.fill(Ellipse().path(in: bodyRect), with: .color(f.color))
                        
                        // Tail
                        var tail = Path()
                        let tailX = f.x - direction * f.size * 0.8
                        tail.move(to: CGPoint(x: tailX, y: f.y))
                        tail.addLine(to: CGPoint(x: tailX - direction * f.size * 0.5, y: f.y - f.size * 0.4))
                        tail.addLine(to: CGPoint(x: tailX - direction * f.size * 0.5, y: f.y + f.size * 0.4))
                        tail.closeSubpath()
                        context.fill(tail, with: .color(f.color.opacity(0.7)))
                        
                        // Eye
                        let eyeX = f.x + direction * f.size * 0.4
                        let eyeRect = CGRect(x: eyeX - 3, y: f.y - 5, width: 6, height: 6)
                        context.opacity = 1.0
                        context.fill(Circle().path(in: eyeRect), with: .color(.white))
                        let pupilRect = CGRect(x: eyeX - 1.5 + direction * 1, y: f.y - 3.5, width: 3, height: 3)
                        context.fill(Circle().path(in: pupilRect), with: .color(.black))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.02, green: 0.1, blue: 0.25),
                        Color(red: 0.03, green: 0.15, blue: 0.3),
                        Color(red: 0.02, green: 0.08, blue: 0.2)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .onAppear { initScene(size: geo.size) }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        // Tap to feed — attract fish
                        for i in fish.indices {
                            let dx = Double(value.location.x) - fish[i].x
                            let dy = Double(value.location.y) - fish[i].y
                            let dist = sqrt(dx * dx + dy * dy)
                            if dist > 10 {
                                fish[i].vx += (dx / dist) * 30
                                fish[i].vy += (dy / dist) * 30
                            }
                        }
                        // Add bubbles at tap
                        for _ in 0..<3 {
                            bubbles.append(AquaBubble(
                                x: Double(value.location.x) + Double.random(in: -10...10),
                                y: Double(value.location.y),
                                vy: Double.random(in: -30 ... -15),
                                radius: Double.random(in: 2...6)
                            ))
                        }
                    }
            )
        }
    }
    
    private func initScene(size: CGSize) {
        let fishColors: [Color] = [.orange, .red, .yellow, .cyan, .green, .purple, .pink, .blue]
        fish = (0..<8).map { _ in
            Fish(
                x: Double.random(in: 40...Double(size.width) - 40),
                y: Double.random(in: 40...Double(size.height) - 40),
                vx: Double.random(in: -30...30),
                vy: Double.random(in: -10...10),
                size: Double.random(in: 15...30),
                color: fishColors.randomElement()!
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        // Update fish
        for i in fish.indices {
            fish[i].x += fish[i].vx * dt
            fish[i].y += fish[i].vy * dt
            
            // Gentle random wandering
            fish[i].vx += Double.random(in: -10...10) * dt
            fish[i].vy += Double.random(in: -8...8) * dt
            
            // Tilt influence
            fish[i].vx += motion.tiltX * 15 * dt
            
            // Speed limit
            fish[i].vx = max(-40, min(40, fish[i].vx))
            fish[i].vy = max(-25, min(25, fish[i].vy))
            
            // Damping
            fish[i].vx *= (1.0 - 0.3 * dt)
            fish[i].vy *= (1.0 - 0.5 * dt)
            
            // Bounce off walls
            if fish[i].x < fish[i].size { fish[i].vx = abs(fish[i].vx) }
            if fish[i].x > Double(size.width) - fish[i].size { fish[i].vx = -abs(fish[i].vx) }
            if fish[i].y < fish[i].size { fish[i].vy = abs(fish[i].vy) }
            if fish[i].y > Double(size.height) - fish[i].size { fish[i].vy = -abs(fish[i].vy) }
        }
        
        // Update bubbles
        for i in bubbles.indices {
            bubbles[i].y += bubbles[i].vy * dt
            bubbles[i].x += sin(bubbles[i].y * 0.05) * 10 * dt
        }
        bubbles.removeAll { $0.y < -10 }
        
        // Random ambient bubbles
        if bubbles.count < 20 && Double.random(in: 0...1) < 0.02 {
            bubbles.append(AquaBubble(
                x: Double.random(in: 0...Double(size.width)),
                y: Double(size.height) + 5,
                vy: Double.random(in: -25 ... -10),
                radius: Double.random(in: 1...4)
            ))
        }
    }
}

private struct Fish {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var size: Double
    var color: Color
}

private struct AquaBubble {
    var x: Double
    var y: Double
    var vy: Double
    var radius: Double
}
