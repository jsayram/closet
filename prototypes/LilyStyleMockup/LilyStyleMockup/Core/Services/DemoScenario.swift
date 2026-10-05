import Foundation

/// Development-only scenario picker. Selects deterministic mock behavior.
enum DemoScenario: String, CaseIterable, Identifiable, Hashable, Codable {
    case normal
    case partialCloset
    case slowImages
    case failedImage
    case staleAfterSwap
    case offlineWeather
    case offlineAI
    case declinedPermission
    case exhaustedAllowance
    case saveFailure
    case syncConflict

    var id: String { rawValue }

    var title: String {
        switch self {
        case .normal: "Normal success"
        case .partialCloset: "Partial / insufficient closet"
        case .slowImages: "Slow image job (cancellable)"
        case .failedImage: "One image fails"
        case .staleAfterSwap: "Stale result after swap/source change"
        case .offlineWeather: "Weather offline"
        case .offlineAI: "AI service offline"
        case .declinedPermission: "Cloud permission declined"
        case .exhaustedAllowance: "Allowance exhausted"
        case .saveFailure: "Save failure"
        case .syncConflict: "Sync conflict"
        }
    }

    var detail: String {
        switch self {
        case .normal: "Three owned directions, images ready in a few seconds when On Me is on."
        case .partialCloset: "Selects the Jose's house suitcase: only one complete look is possible (lace top is Dirty)."
        case .slowImages: "Each preview takes ~12 seconds so you can leave, return or cancel."
        case .failedImage: "The second preview fails; its board stays usable with Retry."
        case .staleAfterSwap: "Image jobs finish slowly; swap a piece or change source meanwhile to see Earlier labelling."
        case .offlineWeather: "Weather can't load; season and manual conditions are used."
        case .offlineAI: "The stylist can't finish: GenerationNotCompleted, never 'missing clothes'."
        case .declinedPermission: "Cloud stylist permission is declined; closet and saved looks still work."
        case .exhaustedAllowance: "Sample daily allowance is used up; free core stays available."
        case .saveFailure: "Explicit outfit saves fail; the earlier saved version and draft are kept."
        case .syncConflict: "A competing edit from another device needs review in Settings."
        }
    }
}

/// Timing used by mocks; scaled down for UI tests via launch argument.
struct MockTiming {
    var stylistDelay: Double = 1.2
    var imageDuration: Double = 3.0
    var searchDelay: Double = 1.5

    static func forScenario(_ s: DemoScenario, fast: Bool) -> MockTiming {
        var t = MockTiming()
        switch s {
        case .slowImages, .staleAfterSwap: t.imageDuration = 12
        default: break
        }
        if fast {
            t.stylistDelay = 0.2
            t.imageDuration = min(t.imageDuration, 0.8)
            t.searchDelay = 0.2
        }
        return t
    }
}
