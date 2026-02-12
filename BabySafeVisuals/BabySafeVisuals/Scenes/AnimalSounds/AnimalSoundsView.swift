import SwiftUI
import AVFoundation

struct AnimalSoundsView: View {
    @Environment(AppState.self) private var appState
    @State private var activeAnimal: Int? = nil
    @State private var synthesizer = AVSpeechSynthesizer()
    
    private let animals: [(emoji: String, name: String, sound: String, bg: Color)] = [
        ("🐶", "Dog", "Woof woof!", .brown),
        ("🐱", "Cat", "Meow!", .orange),
        ("🐮", "Cow", "Mooo!", .green),
        ("🐷", "Pig", "Oink oink!", .pink),
        ("🐸", "Frog", "Ribbit!", .green.opacity(0.7)),
        ("🦁", "Lion", "Roar!", .yellow),
        ("🐔", "Chicken", "Bawk bawk!", .red),
        ("🦆", "Duck", "Quack quack!", .yellow.opacity(0.7)),
        ("🐴", "Horse", "Neigh!", .brown.opacity(0.7)),
        ("🐑", "Sheep", "Baa baa!", .gray),
        ("🐝", "Bee", "Buzz buzz!", .yellow.opacity(0.5)),
        ("🦉", "Owl", "Hoo hoo!", .purple),
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.15, blue: 0.08).ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<animals.count, id: \.self) { i in
                        animalCell(index: i)
                    }
                }
                .padding(16)
            }
            
            // Big display when tapped
            if let idx = activeAnimal {
                let animal = animals[idx]
                VStack(spacing: 12) {
                    Text(animal.emoji)
                        .font(.system(size: 120))
                    Text(animal.sound)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.7))
                .transition(.opacity)
                .onTapGesture {
                    withAnimation { activeAnimal = nil }
                }
            }
        }
    }
    
    private func animalCell(index: Int) -> some View {
        let animal = animals[index]
        let isActive = activeAnimal == index
        
        return Button {
            withAnimation(.spring(duration: 0.3)) { activeAnimal = index }
            speakSound(animal.sound)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { if activeAnimal == index { activeAnimal = nil } }
            }
        } label: {
            VStack(spacing: 4) {
                Text(animal.emoji)
                    .font(.system(size: 44))
                Text(animal.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(animal.bg.opacity(isActive ? 0.8 : 0.4))
            )
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.spring(duration: 0.2), value: isActive)
        }
    }
    
    private func speakSound(_ sound: String) {
        guard appState.soundEnabled else { return }
        let utterance = AVSpeechUtterance(string: sound)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
}
