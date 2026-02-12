import SwiftUI
import AudioToolbox

struct ShapeSorterView: View {
    @Environment(AppState.self) private var appState
    @State private var shapes: [SortShape] = []
    @State private var targets: [ShapeTarget] = []
    @State private var draggedIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var score: Int = 0
    @State private var isInitialized = false
    
    private let shapeTypes: [(type: ShapeType, color: Color)] = [
        (.circle, .red),
        (.square, .blue),
        (.triangle, .green),
        (.diamond, .yellow),
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.08, green: 0.06, blue: 0.12).ignoresSafeArea()
                
                // Score
                VStack {
                    HStack {
                        Spacer()
                        Text("⭐ \(score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                            .padding()
                    }
                    Spacer()
                }
                
                Canvas { context, size in
                    // Draw targets (holes)
                    for target in targets {
                        context.opacity = target.filled ? 0.3 : 0.5
                        drawShape(context: &context, type: target.type, x: target.x, y: target.y, size: 35, color: target.color.opacity(0.3), filled: false)
                        // Outline
                        context.opacity = 0.6
                        drawShapeOutline(context: &context, type: target.type, x: target.x, y: target.y, size: 36, color: target.color)
                    }
                    
                    // Draw draggable shapes
                    for (i, shape) in shapes.enumerated() {
                        guard !shape.matched else { continue }
                        var x = shape.x
                        var y = shape.y
                        if draggedIndex == i {
                            x += Double(dragOffset.width)
                            y += Double(dragOffset.height)
                        }
                        context.opacity = 0.9
                        drawShape(context: &context, type: shape.type, x: x, y: y, size: 30, color: shape.color, filled: true)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if draggedIndex == nil {
                                // Find shape under finger
                                for (i, shape) in shapes.enumerated() {
                                    guard !shape.matched else { continue }
                                    let dx = Double(value.startLocation.x) - shape.x
                                    let dy = Double(value.startLocation.y) - shape.y
                                    if sqrt(dx * dx + dy * dy) < 40 {
                                        draggedIndex = i
                                        break
                                    }
                                }
                            }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            if let idx = draggedIndex {
                                let dropX = shapes[idx].x + Double(value.translation.width)
                                let dropY = shapes[idx].y + Double(value.translation.height)
                                
                                // Check if dropped on matching target
                                for j in targets.indices {
                                    guard !targets[j].filled else { continue }
                                    let dx = dropX - targets[j].x
                                    let dy = dropY - targets[j].y
                                    if sqrt(dx * dx + dy * dy) < 50 && shapes[idx].type == targets[j].type {
                                        shapes[idx].matched = true
                                        targets[j].filled = true
                                        score += 1
                                        if appState.soundEnabled {
                                            AudioServicesPlaySystemSound(1025)
                                        }
                                        // Reset if all matched
                                        if shapes.allSatisfy({ $0.matched }) {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                resetPuzzle(size: geo.size)
                                            }
                                        }
                                        break
                                    }
                                }
                                
                                // Snap back if not matched
                                if !shapes[idx].matched {
                                    shapes[idx].x += Double(value.translation.width)
                                    shapes[idx].y += Double(value.translation.height)
                                }
                            }
                            draggedIndex = nil
                            dragOffset = .zero
                        }
                )
            }
            .onAppear {
                if !isInitialized {
                    resetPuzzle(size: geo.size)
                    isInitialized = true
                }
            }
        }
    }
    
    private func resetPuzzle(size: CGSize) {
        let shuffledTypes = shapeTypes.shuffled()
        
        // Targets on the right side
        targets = shuffledTypes.enumerated().map { (i, st) in
            ShapeTarget(
                type: st.type,
                color: st.color,
                x: Double(size.width) * 0.75,
                y: Double(size.height) * 0.2 + Double(i) * 90
            )
        }
        
        // Shapes on the left side (shuffled differently)
        let shuffledAgain = shapeTypes.shuffled()
        shapes = shuffledAgain.enumerated().map { (i, st) in
            SortShape(
                type: st.type,
                color: st.color,
                x: Double(size.width) * 0.25,
                y: Double(size.height) * 0.2 + Double(i) * 90
            )
        }
    }
    
    private func drawShape(context: inout GraphicsContext, type: ShapeType, x: Double, y: Double, size: Double, color: Color, filled: Bool) {
        switch type {
        case .circle:
            let rect = CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)
            if filled { context.fill(Circle().path(in: rect), with: .color(color)) }
        case .square:
            let rect = CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)
            if filled { context.fill(Rectangle().path(in: rect), with: .color(color)) }
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: x, y: y - size))
            path.addLine(to: CGPoint(x: x + size, y: y + size))
            path.addLine(to: CGPoint(x: x - size, y: y + size))
            path.closeSubpath()
            if filled { context.fill(path, with: .color(color)) }
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: x, y: y - size))
            path.addLine(to: CGPoint(x: x + size, y: y))
            path.addLine(to: CGPoint(x: x, y: y + size))
            path.addLine(to: CGPoint(x: x - size, y: y))
            path.closeSubpath()
            if filled { context.fill(path, with: .color(color)) }
        }
    }
    
    private func drawShapeOutline(context: inout GraphicsContext, type: ShapeType, x: Double, y: Double, size: Double, color: Color) {
        let style = StrokeStyle(lineWidth: 2, dash: [5, 3])
        switch type {
        case .circle:
            let rect = CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)
            context.stroke(Circle().path(in: rect), with: .color(color), style: style)
        case .square:
            let rect = CGRect(x: x - size, y: y - size, width: size * 2, height: size * 2)
            context.stroke(Rectangle().path(in: rect), with: .color(color), style: style)
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: x, y: y - size))
            path.addLine(to: CGPoint(x: x + size, y: y + size))
            path.addLine(to: CGPoint(x: x - size, y: y + size))
            path.closeSubpath()
            context.stroke(path, with: .color(color), style: style)
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: x, y: y - size))
            path.addLine(to: CGPoint(x: x + size, y: y))
            path.addLine(to: CGPoint(x: x, y: y + size))
            path.addLine(to: CGPoint(x: x - size, y: y))
            path.closeSubpath()
            context.stroke(path, with: .color(color), style: style)
        }
    }
}

private enum ShapeType: CaseIterable {
    case circle, square, triangle, diamond
}

private struct SortShape {
    var type: ShapeType
    var color: Color
    var x: Double
    var y: Double
    var matched: Bool = false
}

private struct ShapeTarget {
    var type: ShapeType
    var color: Color
    var x: Double
    var y: Double
    var filled: Bool = false
}
