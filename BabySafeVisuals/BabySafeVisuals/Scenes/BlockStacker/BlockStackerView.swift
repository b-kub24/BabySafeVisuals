import SwiftUI
import AudioToolbox

struct BlockStackerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motion
    @State private var blocks: [Block] = []
    @State private var lastUpdate: Date = .now
    
    private let blockColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .cyan, .pink
    ]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    // Draw floor line
                    context.opacity = 0.2
                    var floor = Path()
                    floor.move(to: CGPoint(x: 0, y: size.height - 2))
                    floor.addLine(to: CGPoint(x: size.width, y: size.height - 2))
                    context.stroke(floor, with: .color(.white), lineWidth: 2)
                    
                    for block in blocks {
                        let rect = CGRect(
                            x: block.x - block.width / 2,
                            y: block.y - block.height / 2,
                            width: block.width,
                            height: block.height
                        )
                        
                        context.opacity = 0.85
                        context.fill(
                            RoundedRectangle(cornerRadius: 4).path(in: rect),
                            with: .color(block.color)
                        )
                        
                        // Top highlight
                        let highlightRect = CGRect(
                            x: block.x - block.width / 2 + 2,
                            y: block.y - block.height / 2 + 2,
                            width: block.width - 4,
                            height: block.height * 0.3
                        )
                        context.opacity = 0.2
                        context.fill(Rectangle().path(in: highlightRect), with: .color(.white))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(Color(red: 0.06, green: 0.06, blue: 0.1))
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { value in
                        if blocks.count < 30 {
                            let w = Double.random(in: 40...70)
                            let h = Double.random(in: 25...45)
                            blocks.append(Block(
                                x: Double(value.location.x),
                                y: Double(value.location.y),
                                vx: 0, vy: 0,
                                width: w, height: h,
                                color: blockColors.randomElement()!
                            ))
                            if appState.soundEnabled {
                                AudioServicesPlaySystemSound(1104)
                            }
                        }
                    }
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        let gravity = 400.0
        let shake = motion.shakeIntensity
        let tiltX = motion.tiltX
        
        // Sort by Y position for stacking
        for i in blocks.indices {
            blocks[i].vy += gravity * dt
            
            // Shake knocks blocks
            if shake > 1.0 {
                blocks[i].vx += Double.random(in: -shake * 100...shake * 100) * dt
                blocks[i].vy -= shake * 150 * dt
            }
            
            blocks[i].vx += tiltX * 80 * dt
            
            blocks[i].x += blocks[i].vx * dt
            blocks[i].y += blocks[i].vy * dt
            
            // Floor
            let bottom = Double(size.height)
            if blocks[i].y + blocks[i].height / 2 > bottom {
                blocks[i].y = bottom - blocks[i].height / 2
                blocks[i].vy = -abs(blocks[i].vy) * 0.2
                if abs(blocks[i].vy) < 5 { blocks[i].vy = 0 }
                blocks[i].vx *= 0.8
            }
            
            // Walls
            if blocks[i].x - blocks[i].width / 2 < 0 {
                blocks[i].x = blocks[i].width / 2
                blocks[i].vx = abs(blocks[i].vx) * 0.5
            }
            if blocks[i].x + blocks[i].width / 2 > Double(size.width) {
                blocks[i].x = Double(size.width) - blocks[i].width / 2
                blocks[i].vx = -abs(blocks[i].vx) * 0.5
            }
            
            // Simple block-on-block stacking
            for j in blocks.indices where j != i {
                let overlap = blocksOverlap(blocks[i], blocks[j])
                if overlap > 0 && blocks[i].y < blocks[j].y {
                    // i is above j
                    let topOfJ = blocks[j].y - blocks[j].height / 2
                    if blocks[i].y + blocks[i].height / 2 > topOfJ {
                        blocks[i].y = topOfJ - blocks[i].height / 2
                        blocks[i].vy = min(0, -abs(blocks[i].vy) * 0.1)
                    }
                }
            }
            
            // Friction
            blocks[i].vx *= (1.0 - 2.0 * dt)
        }
    }
    
    private func blocksOverlap(_ a: Block, _ b: Block) -> Double {
        let overlapX = min(a.x + a.width/2, b.x + b.width/2) - max(a.x - a.width/2, b.x - b.width/2)
        let overlapY = min(a.y + a.height/2, b.y + b.height/2) - max(a.y - a.height/2, b.y - b.height/2)
        return max(0, min(overlapX, overlapY))
    }
}

private struct Block {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var width: Double
    var height: Double
    var color: Color
}
