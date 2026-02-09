import SwiftUI
import UIKit

struct ColorMixerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blobs: [ColorBlob] = []
    @State private var lastUpdate: Date = .now
    @State private var currentSize: CGSize = .zero
    @State private var nextColorIndex: Int = 0
    @State private var blobCounter: Int = 0
    @State private var activeBlobID: Int? = nil

    private let blobColors: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.4),   // red
        Color(red: 0.3, green: 0.5, blue: 0.9),   // blue
        Color(red: 0.3, green: 0.8, blue: 0.5),   // green
        Color(red: 0.9, green: 0.7, blue: 0.2),   // yellow
        Color(red: 0.7, green: 0.3, blue: 0.9),   // purple
    ]

    // MARK: - Computed Helpers

    private var batteryMultiplier: Double {
        let level = UIDevice.current.batteryLevel
        return (level > 0 && level < 0.2) ? 0.5 : 1.0
    }

    private func isInDeadZone(_ point: CGPoint, in size: CGSize) -> Bool {
        point.x < 15 || point.x > size.width - 15 ||
        point.y < 15 || point.y > size.height - 15
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let blobRadius = min(geo.size.width, geo.size.height) * 0.18

            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    // Ambient outer glow layer (drawn under blobs)
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

                    // Main blobs with screen blend mode for color mixing
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
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                currentSize = geo.size
            }
            .onChange(of: geo.size) { _, newSize in
                currentSize = newSize
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isInDeadZone(value.location, in: currentSize) else { return }
                        handleTouch(at: value.location, radius: blobRadius)
                    }
                    .onEnded { _ in
                        if let id = activeBlobID {
                            fadeOutBlob(id: id)
                            activeBlobID = nil
                        }
                    }
            )
        }
    }

    // MARK: - Touch Handling

    private func handleTouch(at point: CGPoint, radius: CGFloat) {
        let radiusMul = appState.touchSensitivity.radiusMultiplier
        let densityMul = appState.particleDensity.multiplier
        let effectiveRadius = Double(radius) * radiusMul * (0.7 + densityMul * 0.3)

        if let activeID = activeBlobID,
           let index = blobs.firstIndex(where: { $0.id == activeID }) {
            // Update existing active blob: lerp toward touch position
            let lerpFactor = reduceMotion ? 0.5 : 0.25
            blobs[index].targetX = Double(point.x)
            blobs[index].targetY = Double(point.y)
            blobs[index].x += (Double(point.x) - blobs[index].x) * lerpFactor
            blobs[index].y += (Double(point.y) - blobs[index].y) * lerpFactor
            blobs[index].targetOpacity = 0.85
        } else {
            // Create a new blob with the next cycling color
            let id = blobCounter
            blobCounter += 1
            let colorIndex = nextColorIndex
            nextColorIndex = (nextColorIndex + 1) % 5

            // Cap at 5 visible blobs; evict oldest fading one if needed
            while blobs.count >= 5 {
                if let fadingIndex = blobs.firstIndex(where: { $0.targetOpacity == 0 }) {
                    blobs.remove(at: fadingIndex)
                } else {
                    blobs.removeFirst()
                }
            }

            blobs.append(ColorBlob(
                id: id,
                x: Double(point.x), y: Double(point.y),
                targetX: Double(point.x), targetY: Double(point.y),
                radius: effectiveRadius,
                color: blobColors[colorIndex],
                opacity: 0.05, targetOpacity: 0.85
            ))
            activeBlobID = id
        }
    }

    private func fadeOutBlob(id: Int) {
        if let index = blobs.firstIndex(where: { $0.id == id }) {
            blobs[index].targetOpacity = 0
        }
    }

    private func updateBlobs(dt: Double) {
        for i in blobs.indices {
            // Smooth lerp toward target position
            blobs[i].x += (blobs[i].targetX - blobs[i].x) * min(dt * 8, 1.0)
            blobs[i].y += (blobs[i].targetY - blobs[i].y) * min(dt * 8, 1.0)

            // Smooth opacity transition (fade in / fade out)
            blobs[i].opacity += (blobs[i].targetOpacity - blobs[i].opacity) * min(dt * 4, 1.0)
        }
        blobs.removeAll { $0.opacity < 0.005 && $0.targetOpacity == 0 }
    }
}

// MARK: - Data Types

private struct ColorBlob: Identifiable {
    let id: Int
    var x, y, targetX, targetY, radius: Double
    var color: Color
    var opacity, targetOpacity: Double
}
