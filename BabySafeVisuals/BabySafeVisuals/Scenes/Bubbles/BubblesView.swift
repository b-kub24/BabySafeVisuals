import SwiftUI

struct BubblesView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(AppState.self) private var appState
    @State private var bubbles: [Bubble] = []
    @State private var lastUpdate: Date = .now

    private let maxBubbles = 30
    
    // Night mode colors
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? NightModeColors.bubblesGradient : [
            Color(red: 0.06, green: 0.18, blue: 0.28),
            Color(red: 0.08, green: 0.25, blue: 0.35),
            Color(red: 0.06, green: 0.2, blue: 0.3)
        ]
    }
    
    private var rimColor: Color {
        appState.isNightModeActive ? NightModeColors.bubblesRimColor : .white
    }
    
    private var highlightColor: Color {
        appState.isNightModeActive ? NightModeColors.bubblesRimColor : .white
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    // Apply animation speed multiplier for night mode
                    let baseDt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    let dt = baseDt * appState.animationSpeedMultiplier

                    for bubble in bubbles {
                        guard !bubble.isPopping else {
                            drawPop(context: &context, bubble: bubble)
                            continue
                        }

                        let rect = CGRect(
                            x: bubble.x - bubble.radius,
                            y: bubble.y - bubble.radius,
                            width: bubble.radius * 2,
                            height: bubble.radius * 2
                        )

                        // Main bubble
                        context.opacity = 0.25
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(bubble.color)
                        )

                        // Rim (warm color in night mode)
                        context.opacity = 0.4
                        context.stroke(
                            Circle().path(in: rect),
                            with: .color(rimColor),
                            lineWidth: 1
                        )

                        // Highlight (warm color in night mode)
                        let highlightSize = bubble.radius * 0.3
                        let highlightRect = CGRect(
                            x: bubble.x - bubble.radius * 0.3,
                            y: bubble.y - bubble.radius * 0.4,
                            width: highlightSize,
                            height: highlightSize * 0.7
                        )
                        context.opacity = 0.5
                        context.fill(
                            Ellipse().path(in: highlightRect),
                            with: .color(highlightColor)
                        )
                    }

                    DispatchQueue.main.async {
                        updateBubbles(dt: dt, size: size)
                        lastUpdate = timeline.date
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
            .onAppear {
                initBubbles(size: geo.size)
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        popBubble(at: value.location)
                    }
            )
        }
    }

    private func drawPop(context: inout GraphicsContext, bubble: Bubble) {
        let progress = bubble.popProgress
        guard progress < 1.0 else { return }

        for i in 0..<5 {
            let angle = Double(i) * (2.0 * .pi / 5.0) + bubble.popAngleOffset
            let dist = bubble.radius * 0.5 * progress * 2
            let x = bubble.x + cos(angle) * dist
            let y = bubble.y + sin(angle) * dist
            let r = 2.0 * (1.0 - progress)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.opacity = (1.0 - progress) * 0.5
            context.fill(Circle().path(in: rect), with: .color(bubble.color))
        }
    }

    private func initBubbles(size: CGSize) {
        bubbles = (0..<15).map { _ in
            Bubble.random(in: size, isNightMode: appState.isNightModeActive)
        }
    }

    private func updateBubbles(dt: Double, size: CGSize) {
        let tiltX = motion.tiltX
        let shake = motion.shakeIntensity

        // Spawn (slower spawn rate in night mode)
        let spawnChance = appState.isNightModeActive ? 0.02 : 0.03
        if bubbles.count < maxBubbles && Double.random(in: 0...1) < spawnChance {
            bubbles.append(Bubble.random(in: size, fromBottom: true, isNightMode: appState.isNightModeActive))
        }

        for i in bubbles.indices {
            if bubbles[i].isPopping {
                bubbles[i].popProgress += dt * 3.0
                continue
            }

            // Float upward
            bubbles[i].vy -= 8 * dt
            bubbles[i].vx += tiltX * 15 * dt

            // Shake gives upward boost
            if shake > 0.5 {
                bubbles[i].vy -= shake * 10 * dt
            }

            // Gentle wobble
            bubbles[i].vx += sin(bubbles[i].age * bubbles[i].wobbleFreq) * 3 * dt

            // Damping
            bubbles[i].vx *= (1.0 - 0.5 * dt)
            bubbles[i].vy *= (1.0 - 0.3 * dt)

            bubbles[i].x += bubbles[i].vx * dt
            bubbles[i].y += bubbles[i].vy * dt
            bubbles[i].age += dt

            // Wrap horizontally
            if bubbles[i].x < -bubbles[i].radius {
                bubbles[i].x = size.width + bubbles[i].radius
            }
            if bubbles[i].x > size.width + bubbles[i].radius {
                bubbles[i].x = -bubbles[i].radius
            }
        }

        // Remove popped or offscreen
        bubbles.removeAll {
            $0.popProgress >= 1.0 || $0.y < -$0.radius * 2
        }
    }

    private func popBubble(at point: CGPoint) {
        if let index = bubbles.firstIndex(where: { bubble in
            let dx = bubble.x - Double(point.x)
            let dy = bubble.y - Double(point.y)
            return sqrt(dx * dx + dy * dy) < bubble.radius * 1.5
        }) {
            bubbles[index].isPopping = true
            bubbles[index].popProgress = 0
        }
    }
}

private struct Bubble: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var radius: Double
    var color: Color
    var age: Double = 0
    var wobbleFreq: Double
    var isPopping: Bool = false
    var popProgress: Double = 0
    var popAngleOffset: Double = 0

    static func random(in size: CGSize, fromBottom: Bool = false, isNightMode: Bool = false) -> Bubble {
        let dayColors: [Color] = [
            Color(red: 0.5, green: 0.8, blue: 0.95),
            Color(red: 0.6, green: 0.85, blue: 0.9),
            Color(red: 0.4, green: 0.75, blue: 0.9),
            Color(red: 0.55, green: 0.7, blue: 0.95),
        ]
        let colors = isNightMode ? NightModeColors.bubbleColors : dayColors
        
        return Bubble(
            x: Double.random(in: 0...Double(size.width)),
            y: fromBottom ? Double(size.height) + 20 : Double.random(in: 0...Double(size.height)),
            vx: Double.random(in: -5...5),
            vy: Double.random(in: -15...-5),
            radius: Double.random(in: 15...40),
            color: colors.randomElement() ?? .cyan,
            wobbleFreq: Double.random(in: 0.5...2.0),
            popAngleOffset: Double.random(in: 0...(2 * .pi))
        )
    }
}
