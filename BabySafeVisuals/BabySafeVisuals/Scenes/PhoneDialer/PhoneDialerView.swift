import SwiftUI
import AVFoundation

struct PhoneDialerView: View {
    @Environment(AppState.self) private var appState
    @State private var lastPressed: String? = nil
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var displayText: String = ""
    
    private let buttons: [[DialButton]] = [
        [DialButton("1", sub: ""), DialButton("2", sub: "ABC"), DialButton("3", sub: "DEF")],
        [DialButton("4", sub: "GHI"), DialButton("5", sub: "JKL"), DialButton("6", sub: "MNO")],
        [DialButton("7", sub: "PQRS"), DialButton("8", sub: "TUV"), DialButton("9", sub: "WXYZ")],
        [DialButton("✱", sub: ""), DialButton("0", sub: "+"), DialButton("#", sub: "")],
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                // Display
                Text(displayText)
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 20)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Spacer().frame(height: 20)
                
                // Numpad grid
                ForEach(0..<buttons.count, id: \.self) { row in
                    HStack(spacing: 20) {
                        ForEach(buttons[row]) { button in
                            dialButtonView(button)
                        }
                    }
                }
                
                // Clear button
                Button {
                    displayText = ""
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 80, height: 44)
                }
                .padding(.top, 8)
                
                Spacer()
            }
        }
    }
    
    private func dialButtonView(_ button: DialButton) -> some View {
        Button {
            pressed(button)
        } label: {
            ZStack {
                Circle()
                    .fill(lastPressed == button.digit ? Color.white.opacity(0.3) : Color.white.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 2) {
                    Text(button.digit)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(.white)
                    if !button.sub.isEmpty {
                        Text(button.sub)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .tracking(2)
                    }
                }
            }
        }
    }
    
    private func pressed(_ button: DialButton) {
        lastPressed = button.digit
        displayText += button.digit
        
        // Keep display reasonable
        if displayText.count > 15 {
            displayText = String(displayText.suffix(15))
        }
        
        guard appState.soundEnabled else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { lastPressed = nil }
            return
        }
        
        // Speak the number
        let wordMap: [String: String] = [
            "1": "one", "2": "two", "3": "three", "4": "four", "5": "five",
            "6": "six", "7": "seven", "8": "eight", "9": "nine", "0": "zero",
            "✱": "star", "#": "hash"
        ]
        
        if let word = wordMap[button.digit] {
            let utterance = AVSpeechUtterance(string: word)
            utterance.rate = 0.4
            utterance.pitchMultiplier = 1.2  // Slightly higher pitch for kids
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.stopSpeaking(at: .immediate)
            synthesizer.speak(utterance)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { lastPressed = nil }
    }
}

private struct DialButton: Identifiable {
    let id = UUID()
    let digit: String
    let sub: String
    
    init(_ digit: String, sub: String) {
        self.digit = digit
        self.sub = sub
    }
}
