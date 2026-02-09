import SwiftUI
import UIKit

struct WaterRipplesView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ripples: [Ripple] = []
    @State private var lastRippleTime: TimeInterval = 0
    @State private var currentSize: CGSize = .zero

    private let baseMaxRipples = 12

    // MARK: - Computed Helpers

    private var batteryMultiplier: Double {
        let level = UIDevice.current.batteryLevel
        return (level > 0 && level < 0.2) ? 0.5 : 1.0
    }

    private var effectiveMaxRipples: Int {
        max(1, Int(Double(baseMaxRipples) * appState.particleDensity.multiplier * batteryMultiplier))
    }

    private func isInDeadZone(_ point: CGPoint, in size: CGSize) -> Bool {
        point.x < 15 || point.x > size.width - 15 ||
        point.y < 15 || point.y > size.height - 15
    }

    private let rippleColors: [Color] = [
        Color(red: 0.4, green: 0.7, blue: 0.9),
        Color(red: 0.3, green: 0.6, blue: 0.85),
        Color(red: 0.5, green: 0.75, blue: 0.95),
        Color(red: 0.35, green: 0.65, blue: 0.88),
        Color(red: 0.45, green: 0.72, blue: 0.92),
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate

                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    // Tilt-responsive caustics background
                    let tiltX = reduceMotion ? 0.0 : motion.smoothTiltX
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

                    // Touch radius scaling from sensitivity setting
                    let radiusMul = appState.touchSensitivity.radiusMultiplier

                    for ripple in ripples {
                        let elapsed = now - ripple.startTime
                        let progress = elapsed / ripple.duration
                        guard progress >= 0, progress < 1.0 else { continue }

                        let maxRadius = min(size.width, size.height) * 0.4 * radiusMul
                        let radius = maxRadius * progress
                        let alpha = (1.0 - progress) * 0.45

                        // 3 concentric rings with alpha falloff
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

                        // Center glow for fresh ripples (first 20% of lifetime)
                        if progress < 0.2 {
                            let glowAlpha = (0.2 - progress) / 0.2 * 0.25
                            let glowR = 15.0 * radiusMul
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
                        addRipple(at: value.location)
                    }
            )
        }
    }

    // MARK: - Ripple Logic

    private func addRipple(at point: CGPoint) {
        let now = Date.now.timeIntervalSinceReferenceDate
        guard ripples.count < effectiveMaxRipples else { return }

        // 0.08s debounce
        guard now - lastRippleTime > 0.08 else { return }

        // 15pt minimum spacing from last ripple
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

// MARK: - Data Types

private struct Ripple {
    let x, y, startTime, duration: Double
    let color: Color
}
