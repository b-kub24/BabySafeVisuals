import UIKit

enum HapticManager {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
    }

    static func pop() {
        lightGenerator.impactOccurred()
    }

    static func tap() {
        softGenerator.impactOccurred(intensity: 0.4)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }

    static func unlock() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func milestone() {
        mediumGenerator.impactOccurred(intensity: 0.6)
    }
}
