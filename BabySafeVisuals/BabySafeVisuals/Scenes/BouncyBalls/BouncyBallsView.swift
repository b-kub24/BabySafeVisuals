import SwiftUI
import AudioToolbox

struct BouncyBallsView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @State private var balls: [BouncyBall] = []
    @State private var lastUpdate: Date = .now
    
    private let ballColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    for ball in balls {
                        let rect = CGRect(x: ball.x - ball.radius, y: ball.y - ball.radius, width: ball.radius * 2, height: ball.radius * 2)
                        context.opacity = 0.9
                        context.fill(Circle().path(in: rect), with: .color(ball.color))
                        
                        // Shine
                        let shineRect = CGRect(x: ball.x - ball.radius * 0.3, y: ball.y - ball.radius * 0.5, width: ball.radius * 0.4, height: ball.radius * 0.3)
                        context.opacity = 0.35
                        context.fill(Ellipse().path(in: shineRect), with: .color(.white))
                        
                        // Shadow
                        let shadowRect = CGRect(x: ball.x - ball.radius * 0.6, y: size.height - 5, width: ball.radius * 1.2, height: 4)
                        let shadowOpacity = max(0, 1.0 - (size.height - ball.y) / size.height) * 0.2
                        context.opacity = shadowOpacity
                        context.fill(Ellipse().path(in: shadowRect), with: .color(.black))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(Color(red: 0.08, green: 0.06, blue: 0.12))
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if balls.count < 25 {
                            balls.append(BouncyBall(
                                x: Double(value.location.x),
                                y: Double(value.location.y),
                                vx: Double.random(in: -50...50),
                                vy: Double.random(in: -100...0),
                                radius: Double.random(in: 15...35),
                                color: ballColors.randomElement()!
                            ))
                        }
                    }
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        let gravity = 500.0
        let tiltX = motion.tiltX
        let shake = motion.shakeIntensity
        
        for i in balls.indices {
            // Gravity
            balls[i].vy += gravity * dt
            
            // Tilt
            balls[i].vx += tiltX * 200 * dt
            
            // Shake boost
            if shake > 0.5 {
                balls[i].vx += Double.random(in: -shake * 100...shake * 100) * dt
                balls[i].vy -= shake * 200 * dt
            }
            
            balls[i].x += balls[i].vx * dt
            balls[i].y += balls[i].vy * dt
            
            // Floor bounce
            if balls[i].y > Double(size.height) - balls[i].radius {
                balls[i].y = Double(size.height) - balls[i].radius
                balls[i].vy = -abs(balls[i].vy) * 0.75
                if abs(balls[i].vy) > 30 && appState.soundEnabled {
                    AudioServicesPlaySystemSound(1104)
                }
            }
            
            // Wall bounce
            if balls[i].x < balls[i].radius {
                balls[i].x = balls[i].radius
                balls[i].vx = abs(balls[i].vx) * 0.8
            }
            if balls[i].x > Double(size.width) - balls[i].radius {
                balls[i].x = Double(size.width) - balls[i].radius
                balls[i].vx = -abs(balls[i].vx) * 0.8
            }
            
            // Ceiling
            if balls[i].y < balls[i].radius {
                balls[i].y = balls[i].radius
                balls[i].vy = abs(balls[i].vy) * 0.6
            }
            
            // Air friction
            balls[i].vx *= (1.0 - 0.3 * dt)
        }
    }
}

private struct BouncyBall {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var color: Color
}
