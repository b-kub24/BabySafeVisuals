import SwiftUI
import UIKit

struct BubblesView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bubbles: [Bubble] = []
    @State private var lastUpdate: Date = .now
    @State private var currentSize: CGSize = .zero

    private let baseMaxBubbles = 30

    // MARK: - Computed Helpers

    private var batteryMultiplier: Double {
        let level = UIDevice.current.batteryLevel
        return (level > 0 && level < 0.2) ? 0.5 : 1.0
    }

    private var effectiveMaxBubbles: Int {
        max(1, Int(Double(baseMaxBubbles) * appState.particleDensity.multiplier * batteryMultiplier))
    }

    private func isInDeadZone(_ point: CGPoint, in size: CGSize) -> Bool {
        point.x < 15 || point.x > size.width - 15 ||
        point.y < 15 || point.y > size.height - 15
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)

                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    for bubble in bubbles {
                        if bubble.isPopping {
                            drawPop(context: &context, bubble: bubble)
                            continue
                        }

                        let rect = CGRect(
                            x: bubble.x - bubble.radius,
                            y: bubble.y - bubble.radius,
                            width: bubble.radius * 2,
                            height: bubble.radius * 2
                        )

                        // Iridescent bubble body: off-center radial gradient
                        let bodyGradient = Gradient(colors: [
                            bubble.color.opacity(0.08),
                            bubble.color.opacity(0.2),
                            bubble.color.opacity(0.08),
                        ])
                        context.fill(
                            Circle().path(in: rect),
                            with: .radialGradient(
                                bodyGradient,
                                center: CGPoint(x: bubble.x - bubble.radius * 0.2, y: bubble.y - bubble.radius * 0.2),
                                startRadius: bubble.radius * 0.1,
                                endRadius: bubble.radius
                            )
                        )

                        // Rim shine
                        context.opacity = 0.35
                        context.stroke(Circle().path(in: rect), with: .color(.white), lineWidth: 0.8)

                        // Top highlight
                        let hlSize = bubble.radius * 0.35
                        let hlRect = CGRect(
                            x: bubble.x - bubble.radius * 0.3,
                            y: bubble.y - bubble.radius * 0.45,
                            width: hlSize,
                            height: hlSize * 0.6
                        )
                        context.opacity = 0.55
                        context.fill(Ellipse().path(in: hlRect), with: .color(.white))

                        // Bottom secondary highlight
                        let bl = bubble.radius * 0.15
                        let blRect = CGRect(
                            x: bubble.x + bubble.radius * 0.15,
                            y: bubble.y + bubble.radius * 0.25,
                            width: bl, height: bl * 0.5
                        )
                        context.opacity = 0.2
                        context.fill(Ellipse().path(in: blRect), with: .color(.white))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.14, blue: 0.24),
                            Color(red: 0.06, green: 0.22, blue: 0.33),
                            Color(red: 0.04, green: 0.18, blue: 0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: timeline.date) { _, newDate in
                    updateBubbles(dt: dt, size: currentSize)
                    lastUpdate = newDate
                }
            }
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                currentSize = geo.size
                initBubbles(size: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in currentSize = newSize }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isInDeadZone(value.location, in: currentSize) else { return }
                        popBubble(at: value.location)
                    }
            )
        }
    }

    // MARK: - Pop Rendering

    private func drawPop(context: inout GraphicsContext, bubble: Bubble) {
        let progress = bubble.popProgress
        guard progress < 1.0 else { return }

        // 6 fragments flying outward
        let fragmentCount = 6
        for i in 0..<fragmentCount {
            let angle = Double(i) * (2.0 * .pi / Double(fragmentCount)) + bubble.popAngleOffset
            let dist = bubble.radius * progress * 2.5
            let x = bubble.x + cos(angle) * dist
            let y = bubble.y + sin(angle) * dist
            let r = (3.0 - Double(i) * 0.3) * (1.0 - progress)
            let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
            context.opacity = (1.0 - progress) * 0.5
            context.fill(Circle().path(in: rect), with: .color(bubble.color))
        }

        // Expanding ring on pop
        let ringR = bubble.radius * (0.5 + progress * 2)
        let ringRect = CGRect(x: bubble.x - ringR, y: bubble.y - ringR, width: ringR * 2, height: ringR * 2)
        context.opacity = (1.0 - progress) * 0.15
        context.stroke(Circle().path(in: ringRect), with: .color(.white), lineWidth: max(0.5, 1.5 * (1.0 - progress)))
    }

    // MARK: - Bubble Logic

    private func initBubbles(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let count = min(15, effectiveMaxBubbles)
        bubbles = (0..<count).map { _ in Bubble.random(in: size) }
    }

    private func updateBubbles(dt: Double, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let maxB = effectiveMaxBubbles
        let tiltX = reduceMotion ? 0.0 : motion.tiltX
        let shake = reduceMotion ? 0.0 : motion.shakeIntensity

        // Spawn new bubbles from the bottom
        if bubbles.count < maxB && Double.random(in: 0...1) < 0.04 {
            bubbles.append(Bubble.random(in: size, fromBottom: true))
        }

        for i in bubbles.indices {
            if bubbles[i].isPopping {
                bubbles[i].popProgress += dt * 2.5
                continue
            }

            // Rise upward
            bubbles[i].vy -= 8 * dt

            // Tilt drift
            bubbles[i].vx += tiltX * 15 * dt

            // Shake pushes bubbles up
            if shake > 0.5 { bubbles[i].vy -= shake * 10 * dt }

            // Wobble
            bubbles[i].vx += sin(bubbles[i].age * bubbles[i].wobbleFreq) * 3 * dt

            // Damping
            bubbles[i].vx *= (1.0 - 0.5 * dt)
            bubbles[i].vy *= (1.0 - 0.3 * dt)

            // Position integration
            bubbles[i].x += bubbles[i].vx * dt
            bubbles[i].y += bubbles[i].vy * dt
            bubbles[i].age += dt

            // Horizontal wrap
            if bubbles[i].x < -bubbles[i].radius { bubbles[i].x = size.width + bubbles[i].radius }
            if bubbles[i].x > size.width + bubbles[i].radius { bubbles[i].x = -bubbles[i].radius }
        }

        // Remove fully popped or off-screen bubbles
        bubbles.removeAll { $0.popProgress >= 1.0 || $0.y < -$0.radius * 2 }
    }

    private func popBubble(at point: CGPoint) {
        let radiusMul = appState.touchSensitivity.radiusMultiplier
        if let index = bubbles.firstIndex(where: { b in
            !b.isPopping && {
                let dx = b.x - Double(point.x)
                let dy = b.y - Double(point.y)
                return sqrt(dx * dx + dy * dy) < 1.5 * b.radius * radiusMul
            }()
        }) {
            bubbles[index].isPopping = true
            bubbles[index].popProgress = 0
            HapticManager.pop()
        }
    }
}

// MARK: - Data Types

private struct Bubble {
    var x, y, vx, vy, radius: Double
    var color: Color
    var age: Double = 0
    var wobbleFreq: Double
    var isPopping = false
    var popProgress: Double = 0
    var popAngleOffset: Double = 0

    static func random(in size: CGSize, fromBottom: Bool = false) -> Bubble {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.8, blue: 0.95),
            Color(red: 0.6, green: 0.85, blue: 0.9),
            Color(red: 0.4, green: 0.75, blue: 0.9),
            Color(red: 0.55, green: 0.7, blue: 0.95),
            Color(red: 0.65, green: 0.8, blue: 0.85),
        ]
        return Bubble(
            x: Double.random(in: 0...max(1, Double(size.width))),
            y: fromBottom ? Double(size.height) + 20 : Double.random(in: 0...max(1, Double(size.height))),
            vx: Double.random(in: -5...5),
            vy: Double.random(in: -15...-5),
            radius: Double.random(in: 15...45),
            color: colors.randomElement() ?? .cyan,
            wobbleFreq: Double.random(in: 0.5...2.0),
            popAngleOffset: Double.random(in: 0...(2 * .pi))
        )
    }
}
