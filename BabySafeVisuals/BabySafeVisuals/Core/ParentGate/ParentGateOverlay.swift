import SwiftUI
import LocalAuthentication

struct ParentGateOverlay: View {
    @Environment(AppState.self) private var appState
    @State private var holdProgress: Double = 0
    @State private var isHolding: Bool = false
    @State private var holdTimer: Timer?
    @State private var isAuthenticating: Bool = false
    @State private var lastMilestone: Int = 0

    private let holdDuration: Double = 6.0
    private let timerInterval: Double = 1.0 / 60.0

    private var hotspotSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 110 : 80
    }

    private var ringSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 56 : 40
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Color.clear

                hotspotArea
                    .padding(.top, geo.safeAreaInsets.top > 0 ? 4 : 8)
                    .padding(.trailing, 8)
            }
        }
        .ignoresSafeArea()
    }

    private var hotspotArea: some View {
        ZStack {
            // Invisible touch target
            Color.clear
                .frame(width: hotspotSize, height: hotspotSize)
                .contentShape(Rectangle())

            // Progress ring - visible while holding
            if isHolding {
                ZStack {
                    // Track ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2.5)
                        .frame(width: ringSize, height: ringSize)

                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.5)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))

                    // Center dot brightens as progress increases
                    Circle()
                        .fill(Color.white.opacity(holdProgress > 0.8 ? 0.4 : 0.15))
                        .frame(width: 4, height: 4)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding && !isAuthenticating {
                        startHold()
                    }
                }
                .onEnded { _ in
                    cancelHold()
                }
        )
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0
        lastMilestone = 0
        holdTimer?.invalidate()

        HapticManager.tap()

        holdTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { timer in
            holdProgress += timerInterval / holdDuration

            // Haptic milestones at 33%, 66%, and 90%
            let currentMilestone = Int(holdProgress * 10)
            if currentMilestone > lastMilestone {
                lastMilestone = currentMilestone
                if currentMilestone == 3 || currentMilestone == 6 {
                    HapticManager.selection()
                } else if currentMilestone == 9 {
                    HapticManager.milestone()
                }
            }

            if holdProgress >= 1.0 {
                timer.invalidate()
                holdTimer = nil
                isHolding = false
                holdProgress = 0
                HapticManager.unlock()
                authenticateParent()
            }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdProgress = 0
        lastMilestone = 0
    }

    private func authenticateParent() {
        guard !isAuthenticating else { return }
        isAuthenticating = true

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to access parent controls"
            ) { success, _ in
                DispatchQueue.main.async {
                    isAuthenticating = false
                    if success {
                        appState.parentUnlocked = true
                    }
                }
            }
        } else {
            // No biometrics or passcode available - allow access after hold
            isAuthenticating = false
            appState.parentUnlocked = true
        }
    }
}
