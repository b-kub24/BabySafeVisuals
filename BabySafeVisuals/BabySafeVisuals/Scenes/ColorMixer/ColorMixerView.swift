import SwiftUI

struct ColorMixerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blobs: [ColorBlob] = []
    @State private var lastUpdate: Date = .now

    private let blobColors: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.4),
        Color(red: 0.3, green: 0.5, blue: 0.9),
        Color(red: 0.3, green: 0.8, blue: 0.5),
        Color(red: 0.9, green: 0.7, blue: 0.2),
        Color(red: 0.7, green: 0.3, blue: 0.9),
    ]

    var body: some View {
        GeometryReader { geo in
            let blobRadius = min(geo.size.width, geo.size.height) * 0.18

            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                Canvas { context, size in
                    // Ambient outer glow
                    for blob in blobs where blob.opacity > 0.01 {
                        let outerR = blob.radius * 1.8
                        let outerGradient = Gradient(colors: [
                            blob.color.opacity(blob.opacity * 0.15),
                            .clear
                        ])
                        context.fill(
                            Circle().path(in: CGRect(
                                x: blob.x - outerR, y: blob.y - outerR,
                                width: outerR * 2, height: outerR * 2
                            )),
                            with: .radialGradient(
                                outerGradient,
                                center: CGPoint(x: blob.x, y: blob.y),
                                startRadius: blob.radius * 0.5,
                                endRadius: outerR
                            )
                        )
                    }

                    // Main blobs with screen blend
                    context.blendMode = .screen
                    for blob in blobs where blob.opacity > 0.01 {
                        let rect = CGRect(
                            x: blob.x - blob.radius, y: blob.y - blob.radius,
                            width: blob.radius * 2, height: blob.radius * 2
                        )
                        let gradient = Gradient(colors: [
                            blob.color.opacity(blob.opacity * 0.85),
                            blob.color.opacity(blob.opacity * 0.4),
                            blob.color.opacity(0.0)
                        ])
                        context.fill(
                            Circle().path(in: rect),
                            with: .radialGradient(
                                gradient,
                                center: CGPoint(x: blob.x, y: blob.y),
                                startRadius: 0,
                                endRadius: blob.radius
                            )
                        )
                    }
                }
                .background(Color(red: 0.08, green: 0.06, blue: 0.14))
                .onChange(of: timeline.date) { _, newDate in
                    updateBlobs(dt: dt)
                    lastUpdate = newDate
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateTouch(id: 0, at: value.location, radius: blobRadius)
                    }
                    .onEnded { _ in
                        fadeOutBlob(id: 0)
                    }
            )
        }
    }

    private func updateTouch(id: Int, at point: CGPoint, radius: CGFloat) {
        if let index = blobs.firstIndex(where: { $0.id == id }) {
            let lerpFactor = reduceMotion ? 0.5 : 0.25
            blobs[index].targetX = Double(point.x)
            blobs[index].targetY = Double(point.y)
            blobs[index].x += (Double(point.x) - blobs[index].x) * lerpFactor
            blobs[index].y += (Double(point.y) - blobs[index].y) * lerpFactor
            blobs[index].targetOpacity = 0.85
        } else {
            blobs.append(ColorBlob(
                id: id,
                x: Double(point.x), y: Double(point.y),
                targetX: Double(point.x), targetY: Double(point.y),
                radius: Double(radius),
                color: blobColors[id % blobColors.count],
                opacity: 0.05, targetOpacity: 0.85
            ))
        }
    }

    private func fadeOutBlob(id: Int) {
        if let index = blobs.firstIndex(where: { $0.id == id }) {
            blobs[index].targetOpacity = 0
        }
    }

    private func updateBlobs(dt: Double) {
        for i in blobs.indices {
            blobs[i].x += (blobs[i].targetX - blobs[i].x) * min(dt * 8, 1.0)
            blobs[i].y += (blobs[i].targetY - blobs[i].y) * min(dt * 8, 1.0)
            blobs[i].opacity += (blobs[i].targetOpacity - blobs[i].opacity) * min(dt * 4, 1.0)
        }
        blobs.removeAll { $0.opacity < 0.005 && $0.targetOpacity == 0 }
    }
}

private struct ColorBlob: Identifiable {
    let id: Int
    var x, y, targetX, targetY, radius: Double
    var color: Color
    var opacity, targetOpacity: Double
}
