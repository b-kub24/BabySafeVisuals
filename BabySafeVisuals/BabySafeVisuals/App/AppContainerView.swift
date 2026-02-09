import SwiftUI
import UIKit

struct AppContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(MotionManager.self) private var motionManager
    @State private var launchOpacity: Double = 0
    @State private var autoCycleTimer: Timer?
    @State private var sessionTimer: Timer?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            activeSceneView
                .ignoresSafeArea()
                .id(appState.activeScene)
                .transition(.opacity.animation(.easeInOut(duration: 0.6)))

            // Screen dimming overlay (night mode)
            if appState.screenDimming > 0 {
                Color.black
                    .opacity(appState.screenDimming)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Session limit overlay
            if appState.sessionLimitReached {
                sessionLimitOverlay
            }

            // First-launch onboarding hint
            if !appState.hasSeenOnboarding && appState.hasLaunched {
                onboardingHint
            }

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
            startAutoCycleIfNeeded()
            startSessionTimerIfNeeded()
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        .onDisappear {
            motionManager.stopUpdates()
            autoCycleTimer?.invalidate()
            sessionTimer?.invalidate()
        }
        .onChange(of: appState.autoCycleEnabled) { _, _ in
            startAutoCycleIfNeeded()
        }
        .onChange(of: appState.autoCycleMinutes) { _, _ in
            startAutoCycleIfNeeded()
        }
        .onChange(of: appState.sessionLimitMinutes) { _, _ in
            startSessionTimerIfNeeded()
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

    // MARK: - Onboarding Hint

    private var onboardingHint: some View {
        VStack {
            HStack {
                Spacer()
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .scaleEffect(appState.hasLaunched ? 2.5 : 1)
                            .opacity(appState.hasLaunched ? 0 : 0.6)
                            .animation(
                                .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                value: appState.hasLaunched
                            )
                    )
                    .padding(.trailing, 30)
                    .padding(.top, 20)
            }
            Spacer()
        }
        .allowsHitTesting(false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation { appState.markOnboardingSeen() }
            }
        }
    }

    // MARK: - Session Limit Overlay

    private var sessionLimitOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Time's Up")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Session limit reached")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: - Auto-Cycle

    private func startAutoCycleIfNeeded() {
        autoCycleTimer?.invalidate()
        autoCycleTimer = nil
        guard appState.autoCycleEnabled else { return }

        let interval = TimeInterval(appState.autoCycleMinutes * 60)
        autoCycleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            if let next = appState.nextUnlockedScene() {
                appState.activeScene = next
            }
        }
    }

    // MARK: - Session Timer

    private func startSessionTimerIfNeeded() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        appState.sessionLimitReached = false
        guard appState.sessionLimitMinutes > 0 else { return }

        let interval = TimeInterval(appState.sessionLimitMinutes * 60)
        sessionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            withAnimation(.easeIn(duration: 1.0)) {
                appState.sessionLimitReached = true
            }
        }
    }
}
