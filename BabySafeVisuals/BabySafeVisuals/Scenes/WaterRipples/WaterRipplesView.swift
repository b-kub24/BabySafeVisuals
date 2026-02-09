import SwiftUI

struct WaterRipplesView: View {
    @Environment(MotionManager.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripples: [Ripple] = []
    @State private var lastRippleTime: TimeInterval = 0
    private let maxRipples = 12

    private let rippleColors: [Color] = [
        Color(red: 0.4, green: 0.7, blue: 0.9),
        Color(red: 0.3, green: 0.6, blue: 0.85),
        Color(red: 0.5, green: 0.75, blue: 0.95),
        Color(red: 0.35, green: 0.65, blue: 0.88),
        Color(red: 0.45, green: 0.72, blue: 0.92),
    ]

    var body: some View {
        GeometryReader { _ in
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    // Subtle caustics pattern
                    let tiltX = reduceMotion ? 0 : motion.smoothTiltX
                    let offsetX = tiltX * 20
                    let causticsGradient = Gradient(colors: [
                        Color(red: 0.1, green: 0.28, blue: 0.42).opacity(0.3),
                        .clear
                    ])
                    context.fill(
                        Ellipse().path(in: CGRect(
                            x: size.width * 0.2 + offsetX,
                            y: size.height * 0.3,
                            width: size.width * 0.6,
                            height: size.height * 0.4
                        )),
                        with: .radialGradient(
                            causticsGradient,
                            center: CGPoint(x: size.width * 0.5 + offsetX, y: size.height * 0.5),
                            startRadius: 0,
                            endRadius: size.width * 0.4
                        )
                    )

                    for ripple in ripples {
                        let elapsed = now - ripple.startTime
                        let progress = elapsed / ripple.duration
                        guard progress >= 0, progress < 1.0 else { continue }

                        let maxRadius = min(size.width, size.height) * 0.4
                        let radius = maxRadius * progress
                        let alpha = (1.0 - progress) * 0.45

                        for ring in 0..<3 {
                            let ringOffset = Double(ring) * 10.0
                            let r = radius + ringOffset
                            guard r > 0 else { continue }

                            let rect = CGRect(x: ripple.x - r, y: ripple.y - r, width: r * 2, height: r * 2)
                            let ringAlpha = alpha * (1.0 - Double(ring) * 0.3)
                            let lineW = max(0.5, 3.0 * (1.0 - progress) - Double(ring) * 0.5)
                            context.opacity = ringAlpha
                            context.stroke(
                                Circle().path(in: rect),
                                with: .color(ripple.color),
                                lineWidth: lineW
                            )
                        }

                        // Center glow for fresh ripples
                        if progress < 0.2 {
                            let glowAlpha = (0.2 - progress) / 0.2 * 0.25
                            let glowR = 15.0
                            let gradient = Gradient(colors: [
                                ripple.color.opacity(glowAlpha),
                                .clear
                            ])
                            context.fill(
                                Circle().path(in: CGRect(x: ripple.x - glowR, y: ripple.y - glowR, width: glowR * 2, height: glowR * 2)),
                                with: .radialGradient(gradient, center: CGPoint(x: ripple.x, y: ripple.y), startRadius: 0, endRadius: glowR)
                            )
                        }
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.12, blue: 0.26),
                            Color(red: 0.06, green: 0.2, blue: 0.36),
                            Color(red: 0.04, green: 0.16, blue: 0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: timeline.date) { _, _ in
                    ripples.removeAll { now - $0.startTime >= $0.duration }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        addRipple(at: value.location)
                    }
            )
        }
    }

    private func addRipple(at point: CGPoint) {
        let now = Date.now.timeIntervalSinceReferenceDate
        guard ripples.count < maxRipples else { return }
        guard now - lastRippleTime > 0.08 else { return }
        if let last = ripples.last {
            let dx = last.x - Double(point.x)
            let dy = last.y - Double(point.y)
            if sqrt(dx * dx + dy * dy) < 15 { return }
        }

        lastRippleTime = now
        ripples.append(Ripple(
            x: Double(point.x),
            y: Double(point.y),
            startTime: now,
            duration: Double.random(in: 3...5),
            color: rippleColors.randomElement() ?? .cyan
        ))
    }
}

private struct Ripple {
    let x, y, startTime, duration: Double
    let color: Color
}
