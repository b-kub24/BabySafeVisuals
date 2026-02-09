import SwiftUI
import SpriteKit

struct MagneticParticlesView: View {
    @Environment(MotionManager.self) private var motion
    @State private var magneticScene: MagneticScene?
    @State private var currentSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.08, green: 0.04, blue: 0.18)

                if let scene = magneticScene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                currentSize = geo.size
                createScene(size: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                if currentSize != newSize {
                    currentSize = newSize
                    magneticScene?.size = newSize
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        magneticScene?.touchLocation = value.location
                        magneticScene?.isTouching = true
                    }
                    .onEnded { _ in
                        magneticScene?.isTouching = false
                    }
            )
            .onChange(of: motion.tiltX) { _, newValue in
                magneticScene?.tiltX = newValue
            }
            .onChange(of: motion.tiltY) { _, newValue in
                magneticScene?.tiltY = newValue
            }
        }
    }

    private func createScene(size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let scene = MagneticScene(size: size)
        scene.scaleMode = .resizeFill
        magneticScene = scene
    }
}

class MagneticScene: SKScene {
    var touchLocation: CGPoint = .zero
    var isTouching: Bool = false
    var tiltX: Double = 0
    var tiltY: Double = 0

    private let particleCount = 200
    private var particles: [SKShapeNode] = []
    private var velocities: [CGPoint] = []

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.08, green: 0.04, blue: 0.18, alpha: 1.0)
        view.allowsTransparency = true

        for _ in 0..<particleCount {
            let radius = CGFloat.random(in: 1.5...3.5)
            let node = SKShapeNode(circleOfRadius: radius)
            node.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            let hue = CGFloat.random(in: 0.55...0.9)
            node.fillColor = SKColor(hue: hue, saturation: 0.7, brightness: 0.95, alpha: 0.75)
            node.strokeColor = SKColor(hue: hue, saturation: 0.5, brightness: 1.0, alpha: 0.3)
            node.lineWidth = 0.5
            node.glowWidth = 1.5
            node.zPosition = 1
            addChild(node)
            particles.append(node)
            velocities.append(.zero)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = 1.0 / 60.0

        for i in particles.indices {
            let node = particles[i]
            var vx = velocities[i].x
            var vy = velocities[i].y

            if isTouching {
                let target = CGPoint(x: touchLocation.x, y: size.height - touchLocation.y)
                let dx = target.x - node.position.x
                let dy = target.y - node.position.y
                let dist = sqrt(dx * dx + dy * dy)

                if dist > 3 {
                    let strength = min(250 / max(dist, 1), 10)

                    // Attraction
                    vx += (dx / dist) * strength * 50 * dt
                    vy += (dy / dist) * strength * 50 * dt

                    // Orbital component for swirl effect
                    vx += (-dy / dist) * strength * 18 * dt
                    vy += (dx / dist) * strength * 18 * dt
                }
            }

            // Tilt
            vx += CGFloat(tiltX) * 25 * dt
            vy -= CGFloat(tiltY) * 25 * dt

            // Damping
            vx *= 0.97
            vy *= 0.97

            let newX = node.position.x + vx * dt
            let newY = node.position.y + vy * dt

            // Soft boundary with bounce
            let margin: CGFloat = 10
            let boundedX: CGFloat
            let boundedY: CGFloat

            if newX < margin {
                boundedX = margin
                vx = abs(vx) * 0.3
            } else if newX > size.width - margin {
                boundedX = size.width - margin
                vx = -abs(vx) * 0.3
            } else {
                boundedX = newX
            }

            if newY < margin {
                boundedY = margin
                vy = abs(vy) * 0.3
            } else if newY > size.height - margin {
                boundedY = size.height - margin
                vy = -abs(vy) * 0.3
            } else {
                boundedY = newY
            }

            node.position = CGPoint(x: boundedX, y: boundedY)
            velocities[i] = CGPoint(x: vx, y: vy)
        }
    }
}
