import SwiftUI
import AudioToolbox

struct DrumPadView: View {
    @Environment(AppState.self) private var appState
    @State private var activePad: Int? = nil
    
    private let pads: [(name: String, color: Color, icon: String, soundID: SystemSoundID)] = [
        ("KICK", .red, "speaker.wave.3.fill", 1104),
        ("SNARE", .orange, "waveform", 1105),
        ("HI-HAT", .yellow, "metronome.fill", 1057),
        ("CLAP", .green, "hands.sparkles.fill", 1109),
        ("TOM", .blue, "circle.circle.fill", 1106),
        ("CRASH", .purple, "bolt.fill", 1110),
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.04, blue: 0.08).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<pads.count, id: \.self) { i in
                        padButton(index: i)
                    }
                }
                .padding(20)
                
                Spacer()
            }
        }
    }
    
    private func padButton(index: Int) -> some View {
        let pad = pads[index]
        let isActive = activePad == index
        
        return Button {
            activePad = index
            if appState.soundEnabled {
                AudioServicesPlaySystemSound(pad.soundID)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                if activePad == index { activePad = nil }
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: pad.icon)
                    .font(.system(size: 30))
                Text(pad.name)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(pad.color.opacity(isActive ? 1.0 : 0.5))
            )
            .scaleEffect(isActive ? 0.92 : 1.0)
            .animation(.spring(duration: 0.1), value: isActive)
        }
    }
}
