import SwiftUI
import SpriteKit

struct MagneticParticlesView: View {
    @Environment(MotionManager.self) private var motion
    @State private var scene: MagneticScene?

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: getScene(size: geo.size), options: [.allowsTransparency])
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            scene?.touchLocation = value.location
                            scene?.isTouching = true
                        }
                        .onEnded { _ in
                            scene?.isTouching = false
                        }
                )
                .onChange(of: motion.tiltX) { _, newValue in
                    scene?.tiltX = newValue
                }
                .onChange(of: motion.tiltY) { _, newValue in
                    scene?.tiltY = newValue
                }
        }
    }

    private func getScene(size: CGSize) -> MagneticScene {
        if let existing = scene, existing.size == size {
            return existing
        }
        let newScene = MagneticScene(size: size)
        DispatchQueue.main.async { self.scene = newScene }
        return newScene
    }
}

class MagneticScene: SKScene {
    var touchLocation: CGPoint = .zero
    var isTouching: Bool = false
    var tiltX: Double = 0
    var tiltY: Double = 0

    private let particleCount = 200
    private var particles: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        self.view?.allowsTransparency = true
        scaleMode = .resizeFill

        // Background
        let bg = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        bg.fillColor = SKColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0)
        bg.strokeColor = .clear
        bg.zPosition = -1
        addChild(bg)

        // Create particles
        for _ in 0..<particleCount {
            let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            node.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            let hue = CGFloat.random(in: 0.6...0.85)
            node.fillColor = SKColor(hue: hue, saturation: 0.6, brightness: 0.9, alpha: 0.7)
            node.strokeColor = .clear
            node.zPosition = 1
            addChild(node)
            particles.append(node)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = 1.0 / 60.0

        for node in particles {
            var dx: CGFloat = 0
            var dy: CGFloat = 0

            if isTouching {
                // Convert touch from SwiftUI coordinates (top-left origin) to SpriteKit (bottom-left origin)
                let target = CGPoint(x: touchLocation.x, y: size.height - touchLocation.y)
                let toTarget = CGPoint(x: target.x - node.position.x, y: target.y - node.position.y)
                let dist = sqrt(toTarget.x * toTarget.x + toTarget.y * toTarget.y)

                if dist > 5 {
                    let strength: CGFloat = min(200 / max(dist, 1), 8)
                    dx += (toTarget.x / dist) * strength * 60 * dt
                    dy += (toTarget.y / dist) * strength * 60 * dt

                    // Orbital component
                    dx += (-toTarget.y / dist) * strength * 20 * dt
                    dy += (toTarget.x / dist) * strength * 20 * dt
                }
            }

            // Tilt influence
            dx += CGFloat(tiltX) * 30 * dt
            dy -= CGFloat(tiltY) * 30 * dt

            // Apply movement with damping
            let newX = node.position.x + dx
            let newY = node.position.y + dy

            // Soft boundary
            let margin: CGFloat = 20
            let boundedX = max(margin, min(size.width - margin, newX))
            let boundedY = max(margin, min(size.height - margin, newY))

            node.position = CGPoint(x: boundedX, y: boundedY)
        }
    }
}
