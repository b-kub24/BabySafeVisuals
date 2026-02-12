import SwiftUI
import AVFoundation

struct ABCLettersView: View {
    @Environment(AppState.self) private var appState
    @State private var activeLetter: String? = nil
    @State private var synthesizer = AVSpeechSynthesizer()
    
    private let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)
    private let columns = [GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)]
    
    private let letterColors: [Color] = [
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
        .red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink,
        .red, .orange
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<letters.count, id: \.self) { i in
                        letterCell(letters[i], color: letterColors[i])
                    }
                }
                .padding(16)
            }
            
            // Big letter display when tapped
            if let letter = activeLetter {
                Text(letter)
                    .font(.system(size: 200, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .blue, radius: 30)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        withAnimation { activeLetter = nil }
                    }
            }
        }
    }
    
    private func letterCell(_ letter: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { activeLetter = letter }
            speak(letter)
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { if activeLetter == letter { activeLetter = nil } }
            }
        } label: {
            Text(letter)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.7))
                )
        }
    }
    
    private func speak(_ letter: String) {
        guard appState.soundEnabled else { return }
        let utterance = AVSpeechUtterance(string: letter)
        utterance.rate = 0.35
        utterance.pitchMultiplier = 1.2
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
