import SwiftUI

/// 30-second scene preview for parents to test any scene (including premium)
struct ScenePreviewView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager
    let scene: SceneID
    let onDismiss: () -> Void
    
    @State private var remainingSeconds: Int = 30
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Full scene view
            sceneView
                .ignoresSafeArea()
            
            // Countdown badge (top center)
            VStack {
                Text("\(remainingSeconds)s")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.black.opacity(0.3)))
                    .padding(.top, 8)
                
                Spacer()
            }
            
            // X dismiss button (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.gray.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.black.opacity(0.15)))
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .statusBarHidden(true)
        .onAppear {
            motionManager.startUpdates()
            startTimer()
        }
        .onDisappear {
            stopTimer()
            motionManager.stopUpdates()
        }
    }
    
    @ViewBuilder
    private var sceneView: some View {
        switch scene {
        case .snowglobe:
            SnowglobeView()
        case .waterRipples:
            WaterRipplesView()
        case .colorMixer:
            ColorMixerView()
        case .bubbles:
            BubblesView()
        case .magneticParticles:
            MagneticParticlesView()
        case .auroraOrbs:
            AuroraOrbsView()
        case .calmStatic:
            CalmStaticView()
        case .drawing:
            DrawingView()
        case .sand:
            SandView()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 1 {
                remainingSeconds -= 1
            } else {
                dismiss()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func dismiss() {
        stopTimer()
        onDismiss()
    }
}
