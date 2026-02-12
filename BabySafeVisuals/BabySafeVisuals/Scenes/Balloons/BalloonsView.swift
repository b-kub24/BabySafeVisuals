import SwiftUI
import AudioToolbox

struct BalloonsView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @State private var balloons: [Balloon] = []
    @State private var lastUpdate: Date = .now
    
    private let balloonColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    for balloon in balloons {
                        guard !balloon.popped else { continue }
                        
                        // String
                        var string = Path()
                        string.move(to: CGPoint(x: balloon.x, y: balloon.y + balloon.radius))
                        string.addCurve(
                            to: CGPoint(x: balloon.x + sin(balloon.age * 2) * 5, y: balloon.y + balloon.radius + 40),
                            control1: CGPoint(x: balloon.x - 5, y: balloon.y + balloon.radius + 15),
                            control2: CGPoint(x: balloon.x + 5, y: balloon.y + balloon.radius + 25)
                        )
                        context.opacity = 0.4
                        context.stroke(string, with: .color(.white), lineWidth: 1)
                        
                        // Balloon body
                        let rect = CGRect(
                            x: balloon.x - balloon.radius,
                            y: balloon.y - balloon.radius * 1.15,
                            width: balloon.radius * 2,
                            height: balloon.radius * 2.3
                        )
                        context.opacity = 0.8
                        context.fill(Ellipse().path(in: rect), with: .color(balloon.color))
                        
                        // Shine
                        let shineRect = CGRect(
                            x: balloon.x - balloon.radius * 0.4,
                            y: balloon.y - balloon.radius * 0.8,
                            width: balloon.radius * 0.4,
                            height: balloon.radius * 0.6
                        )
                        context.opacity = 0.3
                        context.fill(Ellipse().path(in: shineRect), with: .color(.white))
                        
                        // Knot
                        let knotRect = CGRect(x: balloon.x - 3, y: balloon.y + balloon.radius - 2, width: 6, height: 6)
                        context.opacity = 0.6
                        context.fill(Path(ellipseIn: knotRect), with: .color(balloon.color))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.95),
                        Color(red: 0.5, green: 0.8, blue: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        // Check if tapped a balloon to pop it
                        if let idx = balloons.firstIndex(where: { b in
                            let dx = b.x - Double(value.location.x)
                            let dy = b.y - Double(value.location.y)
                            return sqrt(dx * dx + dy * dy) < b.radius * 1.3 && !b.popped
                        }) {
                            balloons[idx].popped = true
                            if appState.soundEnabled {
                                AudioServicesPlaySystemSound(1104)
                            }
                        } else if balloons.filter({ !$0.popped }).count < 20 {
                            // Spawn new balloon
                            balloons.append(Balloon(
                                x: Double(value.location.x),
                                y: Double(value.location.y),
                                vy: 0,
                                radius: Double.random(in: 25...45),
                                color: balloonColors.randomElement()!
                            ))
                        }
                    }
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        let tiltX = motion.tiltX
        
        for i in balloons.indices {
            guard !balloons[i].popped else { continue }
            balloons[i].age += dt
            
            // Float upward
            balloons[i].vy -= 25 * dt
            balloons[i].vy = max(-40, balloons[i].vy)
            balloons[i].y += balloons[i].vy * dt
            
            // Tilt drift
            balloons[i].x += tiltX * 20 * dt
            
            // Gentle wobble
            balloons[i].x += sin(balloons[i].age * 1.5) * 8 * dt
            
            // Wrap horizontal
            if balloons[i].x < -balloons[i].radius { balloons[i].x = Double(size.width) + balloons[i].radius }
            if balloons[i].x > Double(size.width) + balloons[i].radius { balloons[i].x = -balloons[i].radius }
        }
        
        // Remove off-screen
        balloons.removeAll { $0.y < -60 || $0.popped }
    }
}

private struct Balloon {
    var x: Double
    var y: Double
    var vy: Double
    var radius: Double
    var color: Color
    var age: Double = 0
    var popped: Bool = false
}
