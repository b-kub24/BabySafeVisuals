import SwiftUI

/// Settings view for configuring and controlling session timer.
/// Embeds in ParentMenuView.
struct SessionTimerSettingsView: View {
    @Environment(SessionTimerManager.self) private var timerManager
    
    var body: some View {
        @Bindable var timer = timerManager
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Session Timer")
                    .font(.headline)
                
                Spacer()
                
                // Timer status badge
                if timerManager.isTimerActive {
                    Text(timerManager.formattedRemainingTime)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .clipShape(Capsule())
                }
            }
            
            VStack(spacing: 16) {
                // Enable toggle
                Toggle("Enable Timer", isOn: $timer.isTimerEnabled)
                    .accessibilityLabel("Enable session timer")
                    .accessibilityHint("When enabled, sets a time limit for screen time")
                
                if timerManager.isTimerEnabled {
                    // Duration presets
                    durationPicker
                    
                    // Start/Stop button
                    timerControlButton
                    
                    // Extend button (only when active and in wind-down)
                    if timerManager.isTimerActive && timerManager.windDownPhase != .none {
                        extendButton
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
            // Help text
            if timerManager.isTimerEnabled {
                Text("Timer shows a gentle wind-down 60 seconds before ending, with dimming visuals and slower animations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Duration Picker
    
    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(SessionTimerManager.presets, id: \.self) { duration in
                    durationButton(for: duration)
                }
            }
        }
    }
    
    private func durationButton(for duration: TimeInterval) -> some View {
        let isSelected = timerManager.sessionDuration == duration
        let isDisabled = timerManager.isTimerActive
        
        return Button {
            timerManager.sessionDuration = duration
        } label: {
            Text(SessionTimerManager.formatDuration(duration))
                .font(.system(.caption, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .accessibilityLabel("\(Int(duration / 60)) minutes")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
    
    // MARK: - Timer Control Button
    
    private var timerControlButton: some View {
        Button {
            if timerManager.isTimerActive {
                timerManager.stopSession()
            } else {
                timerManager.startSession()
            }
        } label: {
            HStack {
                Image(systemName: timerManager.isTimerActive ? "stop.fill" : "play.fill")
                Text(timerManager.isTimerActive ? "Stop Timer" : "Start Timer")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(timerManager.isTimerActive ? Color.red : Color.green)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(timerManager.isTimerActive ? "Stop session timer" : "Start session timer")
        .accessibilityHint(timerManager.isTimerActive ? "Double tap to stop the timer" : "Double tap to start a \(Int(timerManager.sessionDuration / 60)) minute session")
    }
    
    // MARK: - Extend Button
    
    private var extendButton: some View {
        Button {
            timerManager.extendSession()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add 5 Minutes")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Extend session by 5 minutes")
        .accessibilityHint("Double tap to add 5 more minutes to the current session")
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch timerManager.windDownPhase {
        case .none:
            return .green
        case .dimming:
            return .orange
        case .ending:
            return .red
        }
    }
}

// MARK: - Preview

#Preview {
    SessionTimerSettingsView()
        .padding()
        .environment(SessionTimerManager())
}
