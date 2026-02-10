import SwiftUI

struct ColorMixerView: View {
    @Environment(AppState.self) private var appState
    @State private var touches: [TouchBlob] = []

    private let dayBlobColors: [Color] = [
        Color(red: 0.9, green: 0.3, blue: 0.4),
        Color(red: 0.3, green: 0.5, blue: 0.9),
        Color(red: 0.3, green: 0.8, blue: 0.5),
        Color(red: 0.9, green: 0.7, blue: 0.2),
        Color(red: 0.7, green: 0.3, blue: 0.9),
    ]
    
    private var blobColors: [Color] {
        appState.isNightModeActive ? NightModeColors.colorMixerColors : dayBlobColors
    }
    
    private var backgroundColor: Color {
        appState.isNightModeActive ? NightModeColors.colorMixerBackground : Color(red: 0.12, green: 0.1, blue: 0.18)
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { _ in
                Canvas { context, size in
                    for blob in touches {
                        let blobSize = blob.radius * 2
                        let rect = CGRect(
                            x: blob.x - blob.radius,
                            y: blob.y - blob.radius,
                            width: blobSize,
                            height: blobSize
                        )

                        context.opacity = blob.opacity
                        context.drawLayer { ctx in
                            let gradient = Gradient(colors: [
                                blob.color.opacity(0.8),
                                blob.color.opacity(0.4),
                                blob.color.opacity(0.0)
                            ])
                            ctx.fill(
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
                }
                .background(backgroundColor)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateTouch(id: 0, at: value.location)
                    }
                    .onEnded { _ in
                        removeTouch(id: 0)
                    }
            )
            .simultaneousGesture(
                secondFingerDrag
            )
        }
    }

    private var secondFingerDrag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                updateTouch(id: 1, at: value.location)
            }
            .onEnded { _ in
                removeTouch(id: 1)
            }
    }

    private func updateTouch(id: Int, at point: CGPoint) {
        // Apply animation speed multiplier for smoother movement in night mode
        let interpolationSpeed = 0.3 * appState.animationSpeedMultiplier
        
        if let index = touches.firstIndex(where: { $0.id == id }) {
            // Smooth interpolation toward new position (slower in night mode)
            touches[index].x += (Double(point.x) - touches[index].x) * interpolationSpeed
            touches[index].y += (Double(point.y) - touches[index].y) * interpolationSpeed
            touches[index].opacity = min(touches[index].opacity + 0.05, 0.85)
        } else {
            touches.append(TouchBlob(
                id: id,
                x: Double(point.x),
                y: Double(point.y),
                radius: 120,
                color: blobColors[id % blobColors.count],
                opacity: 0.1
            ))
        }
    }

    private func removeTouch(id: Int) {
        // Fade out gradually instead of removing immediately
        if let index = touches.firstIndex(where: { $0.id == id }) {
            touches[index].opacity = 0
            let capturedID = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                touches.removeAll { $0.id == capturedID }
            }
        }
    }
}

private struct TouchBlob: Identifiable {
    let id: Int
    var x: Double
    var y: Double
    var radius: Double
    var color: Color
    var opacity: Double
}
