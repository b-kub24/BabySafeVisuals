import SwiftUI

struct AppContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager

    var body: some View {
        ZStack {
            activeSceneView
                .ignoresSafeArea()

            ParentGateOverlay()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            motionManager.startUpdates()
        }
        .onDisappear {
            motionManager.stopUpdates()
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
