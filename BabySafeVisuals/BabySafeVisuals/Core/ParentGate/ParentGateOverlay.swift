import SwiftUI
import LocalAuthentication

struct ParentGateOverlay: View {
    @Environment(AppState.self) private var appState
    @State private var holdProgress: Double = 0
    @State private var isHolding: Bool = false
    @State private var holdTimer: Timer?
    @State private var showMathChallenge: Bool = false
    @State private var mathA: Int = 0
    @State private var mathB: Int = 0
    @State private var mathAnswer: String = ""

    private let holdDuration: Double = 2.0
    private let timerInterval: Double = 1.0 / 60.0

    private var hotspotSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 110 : 80
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                Color.clear

                // Thin progress bar across top of screen
                if isHolding {
                    VStack {
                        GeometryReader { barGeo in
                            Rectangle()
                                .fill(Color.white.opacity(0.50))
                                .frame(width: barGeo.size.width * holdProgress, height: 4)
                                .animation(.linear(duration: timerInterval), value: holdProgress)
                        }
                        .frame(height: 4)
                        .padding(.top, geo.safeAreaInsets.top + 8)
                        Spacer()
                    }
                }

                // Subtle gear icon in upper-right
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.white.opacity(0.30))
                    .padding(.top, geo.safeAreaInsets.top > 0 ? 12 : 16)
                    .padding(.trailing, 16)
                    .allowsHitTesting(false)

                hotspotArea
                    .padding(.top, geo.safeAreaInsets.top > 0 ? 4 : 8)
                    .padding(.trailing, 8)
            }
        }
        .ignoresSafeArea()
        .onDisappear {
            cancelHold()
        }
        .alert("Parent Verification", isPresented: $showMathChallenge) {
            TextField("Answer", text: $mathAnswer)
                .keyboardType(.numberPad)
            Button("Verify") {
                if let answer = Int(mathAnswer), answer == mathA * mathB {
                    appState.parentUnlocked = true
                }
                mathAnswer = ""
            }
            Button("Cancel", role: .cancel) {
                mathAnswer = ""
            }
        } message: {
            Text("What is \(mathA) × \(mathB)?")
        }
    }

    private var hotspotArea: some View {
        ZStack {
            // Invisible touch target
            Color.clear
                .frame(width: hotspotSize, height: hotspotSize)
                .contentShape(Rectangle())

            // Subtle progress ring - only visible while holding
            if isHolding {
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        Color.white.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: hotspotSize * 0.5, height: hotspotSize * 0.5)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: timerInterval), value: holdProgress)
            }
        }
        .accessibilityLabel("Parent Gate")
        .accessibilityHint("Press and hold for 2 seconds to access parent controls")
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
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
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { timer in
            holdProgress += timerInterval / holdDuration
            if holdProgress >= 1.0 {
                timer.invalidate()
                holdTimer = nil
                isHolding = false
                holdProgress = 0
                authenticateParent()
            }
        }
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdProgress = 0
    }

    private func generateMathChallenge() {
        mathA = Int.random(in: 5...12)
        mathB = Int.random(in: 5...12)
        mathAnswer = ""
        showMathChallenge = true
    }

    private func authenticateParent() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Authenticate to access parent controls"
            ) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        appState.parentUnlocked = true
                    }
                }
            }
        } else {
            // No biometrics or passcode available - use math challenge fallback
            generateMathChallenge()
        }
    }
}
