import SwiftUI

struct SpinningTopView: View {
    @Environment(AppState.self) private var appState
    @State private var tops: [SpinTop] = []
    @State private var lastUpdate: Date = .now
    
    private let topColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .cyan, .pink]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    for top in tops {
                        let wobble = sin(top.age * 3) * max(0, (1.0 - top.spinSpeed / 10)) * 5
                        let cx = top.x + wobble
                        
                        // Spinning disc — draw colored segments
                        for seg in 0..<8 {
                            let startAngle = top.angle + Double(seg) * (.pi / 4)
                            let endAngle = startAngle + .pi / 4
                            
                            var path = Path()
                            path.move(to: CGPoint(x: cx, y: top.y))
                            path.addArc(center: CGPoint(x: cx, y: top.y), radius: top.radius, startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
                            path.closeSubpath()
                            
                            let colorIdx = (seg + Int(top.colorOffset)) % topColors.count
                            context.opacity = 0.8
                            context.fill(path, with: .color(topColors[colorIdx]))
                        }
                        
                        // Center dot
                        let centerRect = CGRect(x: cx - 4, y: top.y - 4, width: 8, height: 8)
                        context.opacity = 1.0
                        context.fill(Circle().path(in: centerRect), with: .color(.white))
                        
                        // Tip (point)
                        var tip = Path()
                        tip.move(to: CGPoint(x: cx - 3, y: top.y + top.radius))
                        tip.addLine(to: CGPoint(x: cx + 3, y: top.y + top.radius))
                        tip.addLine(to: CGPoint(x: cx, y: top.y + top.radius + 12))
                        tip.closeSubpath()
                        context.opacity = 0.7
                        context.fill(tip, with: .color(.gray))
                        
                        // Shadow
                        let shadowRect = CGRect(x: cx - top.radius * 0.4, y: top.y + top.radius + 12, width: top.radius * 0.8, height: 4)
                        context.opacity = 0.15
                        context.fill(Ellipse().path(in: shadowRect), with: .color(.black))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt)
                        lastUpdate = timeline.date
                    }
                }
                .background(Color(red: 0.95, green: 0.92, blue: 0.88)) // Light wooden surface
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        // Swipe speed determines spin speed
                        let speed = sqrt(Double(value.velocity.width * value.velocity.width + value.velocity.height * value.velocity.height))
                        let spinSpeed = min(30, speed / 100)
                        
                        if tops.count < 5 {
                            tops.append(SpinTop(
                                x: Double(value.location.x),
                                y: Double(value.location.y),
                                radius: Double.random(in: 30...50),
                                spinSpeed: spinSpeed,
                                colorOffset: Double.random(in: 0...8)
                            ))
                        }
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        // Tap to boost nearest top
                        if let idx = tops.indices.min(by: { a, b in
                            let da = pow(tops[a].x - Double(value.location.x), 2) + pow(tops[a].y - Double(value.location.y), 2)
                            let db = pow(tops[b].x - Double(value.location.x), 2) + pow(tops[b].y - Double(value.location.y), 2)
                            return da < db
                        }) {
                            tops[idx].spinSpeed = min(30, tops[idx].spinSpeed + 5)
                        }
                    }
            )
        }
    }
    
    private func update(dt: Double) {
        for i in tops.indices {
            tops[i].age += dt
            tops[i].angle += tops[i].spinSpeed * dt
            tops[i].spinSpeed *= (1.0 - 0.15 * dt)  // Gradual slowdown
        }
        
        // Remove stopped tops
        tops.removeAll { $0.spinSpeed < 0.3 }
    }
}

private struct SpinTop {
    var x: Double
    var y: Double
    var radius: Double
    var spinSpeed: Double
    var angle: Double = 0
    var colorOffset: Double
    var age: Double = 0
}
