import SwiftUI

struct WaterRipplesView: View {
    @Environment(AppState.self) private var appState
    @State private var ripples: [Ripple] = []
    @State private var droplets: [SplashDroplet] = []
    @State private var lastDragPoint: CGPoint? = nil
    private let maxRipples = 20
    private let maxDroplets = 40
    
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

                    // Draw ripples
                    for ripple in ripples {
                        let elapsed = now - ripple.startTime
                        let adjustedDuration = ripple.duration / appState.animationSpeedMultiplier
                        let progress = elapsed / adjustedDuration
                        guard progress < 1.0 else { continue }

                        let maxRadius = ripple.maxRadius
                        let radius = maxRadius * progress
                        let alpha = (1.0 - progress) * 0.5

                        // More rings for realism (6 rings)
                        for ring in 0..<6 {
                            let ringOffset = Double(ring) * 5.0
                            let r = radius + ringOffset
                            guard r > 0 else { continue }

                            let rect = CGRect(
                                x: ripple.x - r,
                                y: ripple.y - r,
                                width: r * 2,
                                height: r * 2
                            )
                            let ringAlpha = alpha * (1.0 - Double(ring) * 0.15)
                            context.opacity = ringAlpha
                            context.stroke(
                                Circle().path(in: rect),
                                with: .color(ripple.color),
                                lineWidth: max(0.5, 2.5 * (1.0 - progress))
                            )
                        }
                    }
                    
                    // Draw splash droplets
                    for droplet in droplets {
                        let elapsed = now - droplet.startTime
                        let progress = elapsed / droplet.lifetime
                        guard progress < 1.0 else { continue }
                        
                        // Parabolic arc
                        let x = droplet.startX + droplet.vx * elapsed
                        let y = droplet.startY + droplet.vy * elapsed + 0.5 * 400 * elapsed * elapsed
                        
                        let fadeOut = 1.0 - max((progress - 0.6) / 0.4, 0.0)
                        let r = droplet.radius * (1.0 - progress * 0.5)
                        
                        let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.opacity = 0.6 * fadeOut
                        context.fill(Circle().path(in: rect), with: .color(droplet.color))
                    }

                    DispatchQueue.main.async {
                        let speedMultiplier = appState.animationSpeedMultiplier
                        ripples.removeAll { 
                            let adjustedDuration = $0.duration / speedMultiplier
                            return now - $0.startTime >= adjustedDuration 
                        }
                        droplets.removeAll { now - $0.startTime >= $0.lifetime }
                        
                        // Droplets that land create secondary ripples
                        for droplet in droplets {
                            let elapsed = now - droplet.startTime
                            let progress = elapsed / droplet.lifetime
                            if progress > 0.8 && !droplet.hasLanded {
                                let x = droplet.startX + droplet.vx * elapsed
                                let y = droplet.startY + droplet.vy * elapsed + 0.5 * 400 * elapsed * elapsed
                                if y < size.height && ripples.count < maxRipples {
                                    ripples.append(Ripple(
                                        x: x, y: y,
                                        startTime: now,
                                        duration: Double.random(in: 1.5...2.5),
                                        color: rippleColors.randomElement() ?? .cyan,
                                        maxRadius: 30
                                    ))
                                }
                            }
                        }
                        // Mark landed droplets
                        for i in droplets.indices {
                            let elapsed = now - droplets[i].startTime
                            let progress = elapsed / droplets[i].lifetime
                            if progress > 0.8 { droplets[i].hasLanded = true }
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
                        let point = value.location
                        // Continuous trail of small ripples while dragging
                        if let last = lastDragPoint {
                            let dx = point.x - last.x
                            let dy = point.y - last.y
                            if sqrt(dx * dx + dy * dy) > 15 {
                                addRipple(at: point, size: geo.size, small: true)
                                lastDragPoint = point
                            }
                        } else {
                            addRipple(at: point, size: geo.size, small: false)
                            lastDragPoint = point
                        }
                    }
                    .onEnded { _ in
                        lastDragPoint = nil
                    }
            )
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        addRipple(at: value.location, size: geo.size, small: false)
                    }
            )
        }
    }

    private func addRipple(at point: CGPoint, size: CGSize, small: Bool) {
        guard ripples.count < maxRipples else { return }

        let maxRadius = small ? min(size.width, size.height) * 0.15 : min(size.width, size.height) * 0.4
        ripples.append(Ripple(
            x: Double(point.x),
            y: Double(point.y),
            startTime: Date.now.timeIntervalSinceReferenceDate,
            duration: small ? Double.random(in: 1.5...2.5) : Double.random(in: 3...5),
            color: rippleColors.randomElement() ?? .cyan,
            maxRadius: maxRadius
        ))
        
        // Add splash droplets for non-small taps
        if !small && droplets.count < maxDroplets {
            let dropletCount = Int.random(in: 4...8)
            let now = Date.now.timeIntervalSinceReferenceDate
            for _ in 0..<dropletCount {
                let angle = Double.random(in: 0...(2 * .pi))
                let speed = Double.random(in: 40...120)
                droplets.append(SplashDroplet(
                    startX: Double(point.x),
                    startY: Double(point.y),
                    vx: cos(angle) * speed,
                    vy: -abs(sin(angle)) * speed - Double.random(in: 30...80),
                    radius: Double.random(in: 1.5...4),
                    color: rippleColors.randomElement() ?? .cyan,
                    startTime: now,
                    lifetime: Double.random(in: 0.4...0.8)
                ))
            }
        }
    }
    
    func resetScene() {
        ripples.removeAll()
        droplets.removeAll()
        lastDragPoint = nil
    }
}

private struct Ripple: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let startTime: TimeInterval
    let duration: Double
    let color: Color
    var maxRadius: Double = 0
    
    init(x: Double, y: Double, startTime: TimeInterval, duration: Double, color: Color, maxRadius: Double? = nil) {
        self.x = x
        self.y = y
        self.startTime = startTime
        self.duration = duration
        self.color = color
        self.maxRadius = maxRadius ?? 150
    }
}

private struct SplashDroplet: Identifiable {
    let id = UUID()
    let startX: Double
    let startY: Double
    let vx: Double
    let vy: Double
    let radius: Double
    let color: Color
    let startTime: TimeInterval
    let lifetime: Double
    var hasLanded: Bool = false
}
