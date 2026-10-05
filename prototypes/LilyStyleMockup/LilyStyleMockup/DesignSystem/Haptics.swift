import UIKit

/// Haptics for explicit user actions and arrivals. These use UIKit generators from `onChange`
/// and button actions instead of SwiftUI's `.sensoryFeedback`: on iPad that modifier's
/// location-based adaptor crashed the app when a selection changed while the layout was
/// being rebuilt in the same update. Firing from actions also keeps programmatic changes
/// (restored requests, launch routes) silent.
@MainActor
enum Haptics {
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func lightImpact() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
