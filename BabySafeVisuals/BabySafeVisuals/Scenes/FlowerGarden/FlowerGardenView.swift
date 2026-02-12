import SwiftUI

struct FlowerGardenView: View {
    @Environment(AppState.self) private var appState
    @State private var flowers: [Flower] = []
    @State private var lastUpdate: Date = .now
    
    private let petalColors: [Color] = [
        .pink, .red, .yellow, .purple, .orange, .white, .cyan
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    // Draw grass
                    let grassRect = CGRect(x: 0, y: size.height * 0.7, width: size.width, height: size.height * 0.3)
                    context.opacity = 1.0
                    context.fill(Rectangle().path(in: grassRect), with: .color(Color(red: 0.15, green: 0.35, blue: 0.1)))
                    
                    for flower in flowers {
                        let growth = min(1.0, flower.age / 2.0)  // 2 second grow animation
                        guard growth > 0 else { continue }
                        
                        // Stem
                        let stemHeight = 60 * growth
                        var stem = Path()
                        stem.move(to: CGPoint(x: flower.x, y: flower.y))
                        stem.addLine(to: CGPoint(x: flower.x, y: flower.y - stemHeight))
                        context.opacity = 0.8
                        context.stroke(stem, with: .color(.green), lineWidth: 3)
                        
                        // Petals
                        if growth > 0.5 {
                            let petalGrowth = (growth - 0.5) * 2  // 0 to 1
                            let petalSize = flower.size * petalGrowth
                            let centerY = flower.y - stemHeight
                            
                            for p in 0..<6 {
                                let angle = Double(p) * (.pi / 3) + flower.rotationOffset
                                let px = flower.x + cos(angle) * petalSize
                                let py = centerY + sin(angle) * petalSize
                                let rect = CGRect(x: px - petalSize * 0.5, y: py - petalSize * 0.5, width: petalSize, height: petalSize)
                                context.opacity = 0.75
                                context.fill(Ellipse().path(in: rect), with: .color(flower.color))
                            }
                            
                            // Center
                            let centerRect = CGRect(x: flower.x - petalSize * 0.3, y: centerY - petalSize * 0.3, width: petalSize * 0.6, height: petalSize * 0.6)
                            context.opacity = 1.0
                            context.fill(Circle().path(in: centerRect), with: .color(.yellow))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        for i in flowers.indices {
                            flowers[i].age += dt * appState.animationSpeedMultiplier
                        }
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.9),
                        Color(red: 0.3, green: 0.55, blue: 0.8)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let y = max(Double(geo.size.height) * 0.7, Double(value.location.y))
                        if flowers.count < 30 {
                            flowers.append(Flower(
                                x: Double(value.location.x),
                                y: y,
                                size: Double.random(in: 12...22),
                                color: petalColors.randomElement()!,
                                rotationOffset: Double.random(in: 0...(2 * .pi))
                            ))
                        }
                    }
            )
        }
    }
}

private struct Flower {
    var x: Double
    var y: Double
    var size: Double
    var color: Color
    var rotationOffset: Double
    var age: Double = 0
}
