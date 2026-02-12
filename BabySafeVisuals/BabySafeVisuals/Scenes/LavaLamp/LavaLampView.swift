import SwiftUI

struct LavaLampView: View {
    @Environment(AppState.self) private var appState
    @State private var blobs: [LavaBlob] = []
    @State private var lastUpdate: Date = .now
    
    private let blobColors: [Color] = [
        .red, .orange, .yellow, .pink, .purple, .cyan
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    for blob in blobs {
                        // Main blob
                        let wobbleX = sin(blob.age * blob.wobbleSpeed) * blob.radius * 0.15
                        let wobbleY = cos(blob.age * blob.wobbleSpeed * 0.7) * blob.radius * 0.1
                        let rect = CGRect(
                            x: blob.x - blob.radius + wobbleX,
                            y: blob.y - blob.radius * 1.1 + wobbleY,
                            width: blob.radius * 2,
                            height: blob.radius * 2.2
                        )
                        
                        context.opacity = 0.7
                        context.fill(Ellipse().path(in: rect), with: .color(blob.color))
                        
                        // Inner glow
                        let innerRect = CGRect(
                            x: blob.x - blob.radius * 0.5 + wobbleX,
                            y: blob.y - blob.radius * 0.6 + wobbleY,
                            width: blob.radius,
                            height: blob.radius * 1.2
                        )
                        context.opacity = 0.4
                        context.fill(Ellipse().path(in: innerRect), with: .color(.white))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    LinearGradient(colors: [
                        Color(red: 0.05, green: 0.02, blue: 0.1),
                        Color(red: 0.08, green: 0.03, blue: 0.15),
                        Color(red: 0.04, green: 0.02, blue: 0.08)
                    ], startPoint: .top, endPoint: .bottom)
                )
            }
            .onAppear { initBlobs(size: geo.size) }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if blobs.count < 12 {
                            blobs.append(LavaBlob(
                                x: Double(value.location.x),
                                y: Double(value.location.y),
                                vy: Double.random(in: -15 ... -5),
                                radius: Double.random(in: 25...50),
                                color: blobColors.randomElement()!,
                                wobbleSpeed: Double.random(in: 1...3)
                            ))
                        }
                    }
            )
        }
    }
    
    private func initBlobs(size: CGSize) {
        blobs = (0..<6).map { _ in
            LavaBlob(
                x: Double.random(in: 40...Double(size.width) - 40),
                y: Double.random(in: 100...Double(size.height) - 100),
                vy: Double.random(in: -15 ... -5),
                radius: Double.random(in: 30...60),
                color: blobColors.randomElement()!,
                wobbleSpeed: Double.random(in: 1...3)
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        for i in blobs.indices {
            blobs[i].age += dt * appState.animationSpeedMultiplier
            
            // Slow rise and fall cycle
            blobs[i].y += blobs[i].vy * dt
            
            // Reverse direction at bounds
            if blobs[i].y < 50 {
                blobs[i].vy = Double.random(in: 5...15)
            }
            if blobs[i].y > Double(size.height) - 50 {
                blobs[i].vy = Double.random(in: -15 ... -5)
            }
            
            // Gentle horizontal drift
            blobs[i].x += sin(blobs[i].age * 0.3) * 8 * dt
            
            // Keep in bounds
            blobs[i].x = max(blobs[i].radius, min(Double(size.width) - blobs[i].radius, blobs[i].x))
        }
    }
}

private struct LavaBlob {
    var x: Double
    var y: Double
    var vy: Double
    var radius: Double
    var color: Color
    var wobbleSpeed: Double
    var age: Double = 0
}
