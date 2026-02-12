import SwiftUI
import AVFoundation

struct BabyPianoView: View {
    @Environment(AppState.self) private var appState
    @State private var audioEngine = AVAudioEngine()
    @State private var pressedKey: Int? = nil
    
    // C major scale frequencies
    private let notes: [(name: String, freq: Float, color: Color)] = [
        ("C", 261.63, .red),
        ("D", 293.66, .orange),
        ("E", 329.63, .yellow),
        ("F", 349.23, .green),
        ("G", 392.00, .cyan),
        ("A", 440.00, .blue),
        ("B", 493.88, .purple),
        ("C", 523.25, .pink),
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.1).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Piano keys
                HStack(spacing: 4) {
                    ForEach(0..<notes.count, id: \.self) { i in
                        pianoKey(index: i)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 40)
                
                Spacer()
            }
        }
        .onAppear { setupAudio() }
        .onDisappear { audioEngine.stop() }
    }
    
    private func pianoKey(index: Int) -> some View {
        let note = notes[index]
        let isPressed = pressedKey == index
        
        return Button {
            pressedKey = index
            playTone(frequency: note.freq)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if pressedKey == index { pressedKey = nil }
            }
        } label: {
            VStack {
                Spacer()
                Text(note.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [note.color.opacity(isPressed ? 1.0 : 0.7), note.color.opacity(isPressed ? 0.8 : 0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.15), value: isPressed)
        }
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    private func playTone(frequency: Float) {
        guard appState.soundEnabled else { return }
        
        let sampleRate: Float = 44100
        let duration: Float = 0.4
        let samples = Int(sampleRate * duration)
        
        // Generate tone using AVAudioPlayer with WAV data
        var audioData = Data()
        for i in 0..<samples {
            let t = Float(i) / sampleRate
            let envelope = min(1.0, (duration - t) * 5) * min(1.0, t * 50) // Attack/release
            let sample = sin(2.0 * .pi * frequency * t) * envelope * 0.3
            var int16Sample = Int16(sample * Float(Int16.max))
            audioData.append(Data(bytes: &int16Sample, count: 2))
        }
        
        // WAV header
        var wav = Data()
        let dataSize = UInt32(audioData.count)
        let fileSize = dataSize + 36
        wav.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        wav.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        wav.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        wav.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // PCM
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) }) // Mono
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(88200).littleEndian) { Array($0) })
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        wav.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        wav.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        wav.append(audioData)
        
        if let player = try? AVAudioPlayer(data: wav) {
            player.play()
        }
    }
}
