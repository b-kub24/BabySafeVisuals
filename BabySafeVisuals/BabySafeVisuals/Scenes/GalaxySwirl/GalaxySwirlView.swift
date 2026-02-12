import SwiftUI

struct GalaxySwirlView: View {
    @Environment(AppState.self) private var appState
    @State private var stars: [GalaxyStar] = []
    @State private var nebulaClouds: [NebulaCloud] = []
    @State private var lastUpdate: Date = .now
    @State private var touchPoint: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let dt = min(timeline.date.timeIntervalSince(lastUpdate), 1.0 / 30.0)
                    
                    // Nebula clouds
                    for cloud in nebulaClouds {
                        let rect = CGRect(x: cloud.x - cloud.radius, y: cloud.y - cloud.radius, width: cloud.radius * 2, height: cloud.radius * 2)
                        context.opacity = cloud.opacity * 0.3
                        context.fill(Circle().path(in: rect), with: .color(cloud.color))
                        
                        let innerRect = CGRect(x: cloud.x - cloud.radius * 0.5, y: cloud.y - cloud.radius * 0.5, width: cloud.radius, height: cloud.radius)
                        context.opacity = cloud.opacity * 0.15
                        context.fill(Circle().path(in: innerRect), with: .color(.white))
                    }
                    
                    // Stars
                    for star in stars {
                        let rect = CGRect(x: star.x - star.radius, y: star.y - star.radius, width: star.radius * 2, height: star.radius * 2)
                        let twinkle = 0.5 + sin(star.age * star.twinkleSpeed) * 0.3
                        context.opacity = twinkle
                        context.fill(Circle().path(in: rect), with: .color(star.color))
                    }
                    
                    DispatchQueue.main.async {
                        update(dt: dt, size: size)
                        lastUpdate = timeline.date
                    }
                }
                .background(
                    RadialGradient(colors: [
                        Color(red: 0.06, green: 0.02, blue: 0.12),
                        Color(red: 0.02, green: 0.01, blue: 0.06),
                        Color.black
                    ], center: .center, startRadius: 0, endRadius: 400)
                )
            }
            .onAppear { initScene(size: geo.size) }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in touchPoint = value.location }
                    .onEnded { _ in touchPoint = nil }
            )
        }
    }
    
    private func initScene(size: CGSize) {
        let starColors: [Color] = [.white, .white, .cyan, .yellow, Color(red: 1, green: 0.7, blue: 0.7)]
        let nebulaColors: [Color] = [.purple, .blue, .cyan, .pink, Color(red: 0.3, green: 0.1, blue: 0.5)]
        
        stars = (0..<150).map { _ in
            GalaxyStar(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                vx: 0, vy: 0,
                radius: Double.random(in: 0.5...2.5),
                color: starColors.randomElement()!,
                twinkleSpeed: Double.random(in: 1...5)
            )
        }
        
        nebulaClouds = (0..<8).map { _ in
            NebulaCloud(
                x: Double.random(in: 0...Double(size.width)),
                y: Double.random(in: 0...Double(size.height)),
                vx: 0, vy: 0,
                radius: Double.random(in: 50...120),
                color: nebulaColors.randomElement()!,
                opacity: Double.random(in: 0.3...0.7)
            )
        }
    }
    
    private func update(dt: Double, size: CGSize) {
        let cx = size.width / 2
        let cy = size.height / 2
        
        for i in stars.indices {
            stars[i].age += dt
            
            if let touch = touchPoint {
                // Swirl around touch
                let dx = stars[i].x - Double(touch.x)
                let dy = stars[i].y - Double(touch.y)
                let dist = sqrt(dx * dx + dy * dy)
                if dist > 5 && dist < 200 {
                    let force = 80 / max(dist, 10)
                    stars[i].vx += (-dy / dist) * force * 60 * dt  // Tangential
                    stars[i].vy += (dx / dist) * force * 60 * dt
                    stars[i].vx -= (dx / dist) * force * 20 * dt  // Slight inward pull
                    stars[i].vy -= (dy / dist) * force * 20 * dt
                }
            } else {
                // Gentle galactic rotation around center
                let dx = stars[i].x - Double(cx)
                let dy = stars[i].y - Double(cy)
                let dist = sqrt(dx * dx + dy * dy)
                if dist > 5 {
                    let speed = 15.0 / max(sqrt(dist), 1)
                    stars[i].vx += (-dy / dist) * speed * dt
                    stars[i].vy += (dx / dist) * speed * dt
                }
            }
            
            stars[i].vx *= (1.0 - 1.5 * dt)
            stars[i].vy *= (1.0 - 1.5 * dt)
            stars[i].x += stars[i].vx * dt
            stars[i].y += stars[i].vy * dt
            
            // Wrap
            if stars[i].x < -10 { stars[i].x = Double(size.width) + 10 }
            if stars[i].x > Double(size.width) + 10 { stars[i].x = -10 }
            if stars[i].y < -10 { stars[i].y = Double(size.height) + 10 }
            if stars[i].y > Double(size.height) + 10 { stars[i].y = -10 }
        }
        
        // Nebula clouds follow similar but slower
        for i in nebulaClouds.indices {
            if let touch = touchPoint {
                let dx = nebulaClouds[i].x - Double(touch.x)
                let dy = nebulaClouds[i].y - Double(touch.y)
                let dist = sqrt(dx * dx + dy * dy)
                if dist > 10 {
                    let force = 20 / max(dist, 10)
                    nebulaClouds[i].vx += (-dy / dist) * force * 20 * dt
                    nebulaClouds[i].vy += (dx / dist) * force * 20 * dt
                }
            }
            nebulaClouds[i].vx *= (1.0 - 0.8 * dt)
            nebulaClouds[i].vy *= (1.0 - 0.8 * dt)
            nebulaClouds[i].x += nebulaClouds[i].vx * dt
            nebulaClouds[i].y += nebulaClouds[i].vy * dt
        }
    }
}

private struct GalaxyStar {
    var x, y, vx, vy, radius: Double
    var color: Color
    var twinkleSpeed: Double
    var age: Double = 0
}

private struct NebulaCloud {
    var x, y, vx, vy, radius: Double
    var color: Color
    var opacity: Double
}
