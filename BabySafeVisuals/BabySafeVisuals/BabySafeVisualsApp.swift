import SwiftUI
import UIKit

@main
struct BabySafeVisualsApp: App {
    @State private var appState = AppState()
    @State private var motionManager = MotionManager()

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environment(appState)
                .environment(motionManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    motionManager.stopUpdates()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    motionManager.startUpdates()
                }
        }
    }
}
