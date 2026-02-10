import SwiftUI

struct AppContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager
    @Environment(SessionTimerManager.self) private var timerManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            activeSceneView
                .ignoresSafeArea()
                // Apply dimming based on wind-down phase
                .opacity(timerManager.dimmingOpacity)
                .animation(.easeInOut(duration: 1.0), value: timerManager.dimmingOpacity)
                // Apply night mode effects
                .nightMode(
                    isActive: appState.isNightModeActive,
                    preserveNightVision: appState.preserveNightVision,
                    brightnessLevel: appState.brightnessLevel
                )

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
        }
    }
}
