import SwiftUI

struct DrawingView: View {
    @Environment(AppState.self) private var appState
    @State private var lines: [DrawingLine] = []
    @State private var currentLine: DrawingLine? = nil
    @State private var colorIndex: Int = 0
    @State private var brushSize: CGFloat = 6
    
    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .white
    ]
    
    private let brushSizes: [CGFloat] = [3, 6, 12]
    
    private var backgroundGradient: [Color] {
        appState.isNightModeActive ? [
            Color(red: 0.03, green: 0.03, blue: 0.05),
            Color(red: 0.05, green: 0.04, blue: 0.07)
        ] : [
            Color(red: 0.08, green: 0.06, blue: 0.15),
            Color(red: 0.05, green: 0.04, blue: 0.12)
        ]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: backgroundGradient, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                Canvas { context, size in
                    for line in lines {
                        drawLine(line, in: &context)
                    }
                    if let current = currentLine {
                        drawLine(current, in: &context)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            if currentLine == nil {
                                currentLine = DrawingLine(
                                    color: colors[colorIndex],
                                    lineWidth: brushSize,
                                    points: [point]
                                )
                            } else {
                                currentLine?.points.append(point)
                            }
                        }
                        .onEnded { _ in
                            if let line = currentLine {
                                lines.append(line)
                                currentLine = nil
                                // Auto-rotate color
                                colorIndex = (colorIndex + 1) % colors.count
                            }
                        }
                )
                
                // Color & brush UI at bottom
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        // Color dots
                        ForEach(0..<colors.count, id: \.self) { i in
                            Circle()
                                .fill(colors[i])
                                .frame(width: colorIndex == i ? 28 : 20, height: colorIndex == i ? 28 : 20)
                                .overlay(
                                    Circle().stroke(.white.opacity(colorIndex == i ? 0.6 : 0), lineWidth: 2)
                                )
                                .onTapGesture { colorIndex = i }
                        }
                    }
                    .padding(.bottom, 4)
                    
                    HStack(spacing: 16) {
                        // Brush sizes
                        ForEach(brushSizes, id: \.self) { size in
                            Circle()
                                .fill(.white.opacity(brushSize == size ? 0.8 : 0.3))
                                .frame(width: size * 2 + 8, height: size * 2 + 8)
                                .onTapGesture { brushSize = size }
                        }
                        
                        Spacer()
                        
                        // Erase button
                        Button {
                            lines.removeAll()
                            currentLine = nil
                        } label: {
                            Image(systemName: "eraser.fill")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func drawLine(_ line: DrawingLine, in context: inout GraphicsContext) {
        guard line.points.count > 1 else {
            // Single dot
            if let p = line.points.first {
                let rect = CGRect(x: p.x - line.lineWidth/2, y: p.y - line.lineWidth/2, width: line.lineWidth, height: line.lineWidth)
                context.fill(Circle().path(in: rect), with: .color(line.color))
            }
            return
        }
        
        var path = Path()
        path.move(to: line.points[0])
        
        if line.points.count == 2 {
            path.addLine(to: line.points[1])
        } else {
            for i in 1..<line.points.count {
                let mid = CGPoint(
                    x: (line.points[i-1].x + line.points[i].x) / 2,
                    y: (line.points[i-1].y + line.points[i].y) / 2
                )
                path.addQuadCurve(to: mid, control: line.points[i-1])
            }
            if let last = line.points.last {
                path.addLine(to: last)
            }
        }
        
        context.stroke(path, with: .color(line.color), style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round))
    }
    
    func resetScene() {
        lines.removeAll()
        currentLine = nil
    }
}

private struct DrawingLine {
    let color: Color
    let lineWidth: CGFloat
    var points: [CGPoint]
}
