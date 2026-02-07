import UIKit

enum GuidedAccessStatus {
    static var isEnabled: Bool {
        UIAccessibility.isGuidedAccessEnabled
    }
}
