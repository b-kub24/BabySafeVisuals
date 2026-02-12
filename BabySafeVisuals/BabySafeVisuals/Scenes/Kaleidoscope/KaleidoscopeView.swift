import SwiftUI

struct KaleidoscopeView: View {
    @Environment(AppState.self) private var appState
    @State private var touchPoints: [CGPoint] = []
    @State private var time: Double = 0
    @State private var lastUpdate: Date = .now
    
    private let segments = 8
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let cx = size.width / 2
                    let cy = size.height / 2
                    
                    // Auto-generate patterns
                    let shapes = generateShapes(time: time, cx: cx, cy: cy)
                    
                    // Draw mirrored segments
                    for seg in 0..<segments {
                        let angle = Double(seg) * (2 * .pi / Double(segments))
                        
                        context.drawLayer { layerContext in
                            let transform = CGAffineTransform(translationX: cx, y: cy)
                                .rotated(by: angle)
                                .translatedBy(x: -cx, y: -cy)
                            layerContext.concatenate(transform)
                            
                            for shape in shapes {
                                layerContext.opacity = shape.opacity
                                let rect = CGRect(x: shape.x - shape.size, y: shape.y - shape.size, width: shape.size * 2, height: shape.size * 2)
                                layerContext.fill(Circle().path(in: rect), with: .color(shape.color))
                            }
                        }
                    }
                    
                    // Draw touch-generated shapes
                    for point in touchPoints {
                        for seg in 0..<segments {
                            let angle = Double(seg) * (2 * .pi / Double(segments))
                            let rx = cx + (Double(point.x) - cx) * cos(angle) - (Double(point.y) - cy) * sin(angle)
                            let ry = cy + (Double(point.x) - cx) * sin(angle) + (Double(point.y) - cy) * cos(angle)
                            let rect = CGRect(x: rx - 4, y: ry - 4, width: 8, height: 8)
                            context.opacity = 0.6
                            context.fill(Circle().path(in: rect), with: .color(.white))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        time += dt * appState.animationSpeedMultiplier
                        lastUpdate = timeline.date
                    }
                }
                .background(Color.black)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        touchPoints.append(value.location)
                        if touchPoints.count > 50 { touchPoints.removeFirst() }
                    }
                    .onEnded { _ in
                        // Slowly clear
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            touchPoints.removeAll()
                        }
                    }
            )
        }
    }
    
    private func generateShapes(time: Double, cx: Double, cy: Double) -> [KShape] {
        var shapes: [KShape] = []
        let hues: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]
        
        for i in 0..<12 {
            let t = time + Double(i) * 0.5
            let r = 40 + sin(t * 0.3) * 30
            let x = cx + cos(t * (0.5 + Double(i) * 0.1)) * (50 + r)
            let y = cy + sin(t * (0.4 + Double(i) * 0.08)) * (40 + r * 0.5)
            let size = 5 + sin(t * 0.7) * 3
            
            shapes.append(KShape(
                x: x, y: y,
                size: abs(size),
                color: hues[i % hues.count],
                opacity: 0.5 + sin(t) * 0.2
            ))
        }
        return shapes
    }
}

private struct KShape {
    var x: Double
    var y: Double
    var size: Double
    var color: Color
    var opacity: Double
}
