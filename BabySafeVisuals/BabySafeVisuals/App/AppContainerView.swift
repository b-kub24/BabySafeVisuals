import SwiftUI

struct AppContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager
    @State private var launchOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Dark background prevents white flash during scene transitions
            Color.black.ignoresSafeArea()

            activeSceneView
                .ignoresSafeArea()
                .id(appState.activeScene)
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))

            ParentGateOverlay()
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .opacity(launchOpacity)
        .onAppear {
            motionManager.startUpdates()
            withAnimation(.easeIn(duration: 0.8)) {
                launchOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                appState.hasLaunched = true
            }
        }
        .onDisappear {
            motionManager.stopUpdates()
        }
        .sheet(isPresented: parentUnlockedBinding) {
            ParentMenuView()
                .interactiveDismissDisabled(true)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6), value: appState.activeScene)
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
