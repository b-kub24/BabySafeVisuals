import SwiftUI

@main
struct BabySafeVisualsApp: App {
    @State private var appState = AppState()
    @State private var motionManager = MotionManager()
    @State private var timerManager = SessionTimerManager()

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environment(appState)
                .environment(motionManager)
                .environment(timerManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    motionManager.stopUpdates()
                    appState.lockParentMode()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    motionManager.startUpdates()
                }
        }
    }
}
