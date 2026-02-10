import SwiftUI

/// Subtle timer overlay that shows session progress and wind-down state.
/// Designed to be visible to parents but not distracting to babies.
struct SessionTimerOverlayView: View {
    @Environment(SessionTimerManager.self) private var timerManager
    
    var body: some View {
        ZStack {
            // Timer indicator (top-left, subtle)
            if timerManager.isTimerActive {
                timerIndicator
            }
            
            // Wind-down overlay
            if timerManager.windDownPhase == .dimming {
                windDownBorder
            }
            
            // Session complete overlay
            if timerManager.windDownPhase == .ending {
                sessionCompleteOverlay
            }
        }
    }
    
    // MARK: - Timer Indicator
    
    private var timerIndicator: some View {
        VStack {
            HStack {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 60, height: 60)
                    
                    // Progress ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerManager.progress)
                    
                    // Time text
                    Text(timerManager.formattedRemainingTime)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 50) // Account for status bar area
            
            Spacer()
        }
    }
    
    private var progressColor: Color {
        switch timerManager.windDownPhase {
        case .none:
            return .white
        case .dimming:
            return .orange
        case .ending:
            return .red
        }
    }
    
    // MARK: - Wind-Down Border
    
    private var windDownBorder: some View {
        RoundedRectangle(cornerRadius: 0)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.6),
                        Color.yellow.opacity(0.4),
                        Color.orange.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 8
            )
            .ignoresSafeArea()
            .modifier(PulsingBorderModifier())
    }
    
    // MARK: - Session Complete Overlay
    
    private var sessionCompleteOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Moon/sleep icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.pulse)
                
                // Message
                Text("Time for cuddles!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Screen time is over")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                
                // Dismiss instructions (for parent)
                Text("Tap anywhere to dismiss")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 20)
            }
        }
        .transition(.opacity)
        .onTapGesture {
            timerManager.dismissCompletion()
        }
    }
}

// MARK: - Pulsing Border Modifier

private struct PulsingBorderModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue
        SessionTimerOverlayView()
    }
    .environment(SessionTimerManager())
}
