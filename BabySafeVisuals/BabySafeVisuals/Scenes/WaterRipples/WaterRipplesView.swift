import SwiftUI

struct WaterRipplesView: View {
    @Environment(AppState.self) private var appState
    @State private var ripples: [Ripple] = []
    private let maxRipples = 12
    
    // Night mode colors
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? NightModeColors.waterRipplesGradient : [
            Color(red: 0.05, green: 0.15, blue: 0.3),
            Color(red: 0.08, green: 0.22, blue: 0.38),
            Color(red: 0.05, green: 0.18, blue: 0.32)
        ]
    }
    
    private var rippleColors: [Color] {
        appState.isNightModeActive ? NightModeColors.waterRippleColors : [
            Color(red: 0.4, green: 0.7, blue: 0.9),
            Color(red: 0.3, green: 0.6, blue: 0.85),
            Color(red: 0.5, green: 0.75, blue: 0.95),
            Color(red: 0.35, green: 0.65, blue: 0.88)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    for ripple in ripples {
                        let elapsed = now - ripple.startTime
                        // Apply animation speed multiplier for night mode
                        let adjustedDuration = ripple.duration / appState.animationSpeedMultiplier
                        let progress = elapsed / adjustedDuration
                        guard progress < 1.0 else { continue }

                        let maxRadius = min(size.width, size.height) * 0.4
                        let radius = maxRadius * progress
                        let alpha = (1.0 - progress) * 0.5

                        for ring in 0..<3 {
                            let ringOffset = Double(ring) * 8.0
                            let r = radius + ringOffset
                            guard r > 0 else { continue }

                            let rect = CGRect(
                                x: ripple.x - r,
                                y: ripple.y - r,
                                width: r * 2,
                                height: r * 2
                            )
                            let ringAlpha = alpha * (1.0 - Double(ring) * 0.3)
                            context.opacity = ringAlpha
                            context.stroke(
                                Circle().path(in: rect),
                                with: .color(ripple.color),
                                lineWidth: max(1, 3.0 * (1.0 - progress))
                            )
                        }
                    }

                    DispatchQueue.main.async {
                        let speedMultiplier = appState.animationSpeedMultiplier
                        ripples.removeAll { 
                            let adjustedDuration = $0.duration / speedMultiplier
                            return now - $0.startTime >= adjustedDuration 
                        }
                    }
                }
                .background(
                    LinearGradient(
                        colors: backgroundGradient,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addRipple(at: value.location)
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        addRipple(at: value.location)
                    }
            )
        }
    }

    private func addRipple(at point: CGPoint) {
        guard ripples.count < maxRipples else { return }
        // Throttle: don't add if we recently added one very close
        if let last = ripples.last {
            let dx = last.x - Double(point.x)
            let dy = last.y - Double(point.y)
            if sqrt(dx * dx + dy * dy) < 20 { return }
        }

        ripples.append(Ripple(
            x: Double(point.x),
            y: Double(point.y),
            startTime: Date.now.timeIntervalSinceReferenceDate,
            duration: Double.random(in: 3...5),
            color: rippleColors.randomElement() ?? .cyan
        ))
    }
}

private struct Ripple: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let startTime: TimeInterval
    let duration: Double
    let color: Color
}
