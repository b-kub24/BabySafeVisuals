import SwiftUI
import Combine
import AVFoundation

/// Manages session timer state and wind-down phases for baby screen time limits.
/// Provides gentle transition from active viewing to session end.
@Observable
final class SessionTimerManager {
    
    // MARK: - Wind-Down Phase
    
    enum WindDownPhase: Equatable {
        case none           // Normal playback
        case dimming        // 60 seconds before end - gradually dim visuals
        case ending         // Session complete - show completion overlay
    }
    
    // MARK: - Timer Presets
    
    static let presets: [TimeInterval] = [
        5 * 60,   // 5 minutes
        10 * 60,  // 10 minutes
        15 * 60,  // 15 minutes
        20 * 60,  // 20 minutes
        30 * 60   // 30 minutes
    ]
    
    // MARK: - Persisted Properties
    
    /// Whether the session timer feature is enabled
    var isTimerEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isTimerEnabled, forKey: "sessionTimerEnabled")
        }
    }
    
    /// Selected session duration in seconds
    var sessionDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(sessionDuration, forKey: "sessionTimerDuration")
        }
    }
    
    // MARK: - Session State
    
    /// When the current session started (nil if no active session)
    private(set) var sessionStartTime: Date?
    
    /// Whether a timer session is currently active
    var isTimerActive: Bool {
        sessionStartTime != nil && windDownPhase != .ending
    }
    
    /// Current wind-down phase
    private(set) var windDownPhase: WindDownPhase = .none
    
    /// Remaining time in seconds (0 if no active session)
    var remainingTime: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, sessionDuration - elapsed)
    }
    
    /// Progress from 0.0 (just started) to 1.0 (complete)
    var progress: Double {
        guard sessionDuration > 0, sessionStartTime != nil else { return 0 }
        return 1.0 - (remainingTime / sessionDuration)
    }
    
    /// Opacity multiplier for scene dimming during wind-down
    var dimmingOpacity: Double {
        switch windDownPhase {
        case .none:
            return 1.0
        case .dimming:
            // Gradually dim from 1.0 to 0.5 over the 60-second wind-down
            let windDownProgress = 1.0 - (remainingTime / 60.0)
            return 1.0 - (windDownProgress * 0.5)
        case .ending:
            return 0.3
        }
    }
    
    /// Animation speed multiplier during wind-down (slows animations)
    var animationSpeedMultiplier: Double {
        switch windDownPhase {
        case .none:
            return 1.0
        case .dimming:
            // Gradually slow from 1.0 to 0.3 over the 60-second wind-down
            let windDownProgress = 1.0 - (remainingTime / 60.0)
            return 1.0 - (windDownProgress * 0.7)
        case .ending:
            return 0.1
        }
    }
    
    // MARK: - Timer
    
    private var updateTimer: Timer?
    private var hapticGenerator: UINotificationFeedbackGenerator?
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Initialization
    
    init() {
        self.isTimerEnabled = UserDefaults.standard.bool(forKey: "sessionTimerEnabled")
        
        let savedDuration = UserDefaults.standard.double(forKey: "sessionTimerDuration")
        self.sessionDuration = savedDuration > 0 ? savedDuration : 10 * 60 // Default 10 minutes
    }
    
    // MARK: - Session Control
    
    /// Start a new session timer
    func startSession() {
        sessionStartTime = Date()
        windDownPhase = .none
        
        // Prepare haptic feedback for end
        hapticGenerator = UINotificationFeedbackGenerator()
        hapticGenerator?.prepare()
        
        // Start update timer
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerState()
        }
    }
    
    /// Stop the current session
    func stopSession() {
        sessionStartTime = nil
        windDownPhase = .none
        updateTimer?.invalidate()
        updateTimer = nil
        hapticGenerator = nil
    }
    
    /// Extend the current session by 5 minutes
    func extendSession() {
        guard sessionStartTime != nil else { return }
        
        // Add 5 minutes by adjusting the start time backwards
        sessionStartTime = sessionStartTime?.addingTimeInterval(-5 * 60)
        
        // If we were in wind-down, check if we should exit
        updateTimerState()
    }
    
    /// Reset and dismiss the completion overlay
    func dismissCompletion() {
        stopSession()
    }
    
    // MARK: - Timer Updates
    
    private func updateTimerState() {
        let remaining = remainingTime
        
        if remaining <= 0 {
            // Session complete
            if windDownPhase != .ending {
                windDownPhase = .ending
                triggerEndHaptic()
            }
        } else if remaining <= 60 {
            // Wind-down phase (last 60 seconds)
            if windDownPhase != .dimming {
                windDownPhase = .dimming
            }
        } else {
            windDownPhase = .none
        }
    }
    
    private func triggerEndHaptic() {
        hapticGenerator?.notificationOccurred(.success)
        playEndChime()
    }
    
    private func playEndChime() {
        // Play a gentle system sound as end chime
        // Using system sound ID 1057 (soft bell/chime)
        AudioServicesPlaySystemSound(1057)
    }
    
    // MARK: - Formatting
    
    /// Format remaining time as MM:SS
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format a duration preset for display
    static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
