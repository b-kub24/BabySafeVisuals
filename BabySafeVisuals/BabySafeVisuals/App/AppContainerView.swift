import SwiftUI

struct AppContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager
    @Environment(SessionTimerManager.self) private var timerManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var resetTrigger: Bool = false
    
    var body: some View {
        ZStack {
            activeSceneView
                .ignoresSafeArea()
                .opacity(timerManager.dimmingOpacity)
                .animation(.easeInOut(duration: 1.0), value: timerManager.dimmingOpacity)
                .nightMode(
                    isActive: appState.isNightModeActive,
                    preserveNightVision: appState.preserveNightVision,
                    brightnessLevel: appState.brightnessLevel
                )
                .id(resetTrigger) // Forces view recreation on reset

            // Start Over button (bottom center, subtle)
            if !appState.parentUnlocked {
                VStack {
                    Spacer()
                    Button {
                        resetTrigger.toggle()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white.opacity(0.20))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.05)))
                    }
                    .padding(.bottom, 30)
                }
            }

            ParentGateOverlay()
            
            // Session timer overlay (subtle indicator + completion screen)
            if timerManager.isTimerEnabled {
                SessionTimerOverlayView()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            motionManager.startUpdates()
            appState.systemColorScheme = colorScheme
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .onChange(of: colorScheme) { _, newValue in
            appState.systemColorScheme = newValue
        }
        .sheet(isPresented: parentUnlockedBinding) {
            ParentMenuView()
                .interactiveDismissDisabled(true)
        }
    }

    private var parentUnlockedBinding: Binding<Bool> {
        Binding(
            get: { appState.parentUnlocked },
            set: { newValue in
                if !newValue {
                    appState.lockParentMode()
                }
            }
        )
    }

    @ViewBuilder
    private var activeSceneView: some View {
        switch appState.activeScene {
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
}
