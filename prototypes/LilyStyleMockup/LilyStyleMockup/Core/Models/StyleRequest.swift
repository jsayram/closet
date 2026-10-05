import Foundation

enum Occasion: String, Codable, CaseIterable, Identifiable, Hashable {
    case office, dateNight, brunch, concert, casual, event, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .office: "Office"
        case .dateNight: "Date Night"
        case .brunch: "Brunch"
        case .concert: "Concert"
        case .casual: "Casual"
        case .event: "Event"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .office: "briefcase"
        case .dateNight: "moon.stars"
        case .brunch: "cup.and.saucer"
        case .concert: "music.note"
        case .casual: "sun.max"
        case .event: "sparkles"
        case .other: "ellipsis.circle"
        }
    }

    /// Allowed formality band for this occasion.
    var formalityRange: ClosedRange<Int> {
        switch self {
        case .office: 1...2
        case .dateNight: 1...2
        case .brunch: 0...2
        case .concert: 0...1
        case .casual: 0...1
        case .event: 1...2
        case .other: 0...2
        }
    }

    /// Natural phrase for explanations ("for the office").
    var phrase: String {
        switch self {
        case .office: "the office"
        case .dateNight: "date night"
        case .brunch: "brunch"
        case .concert: "a concert"
        case .casual: "a casual day"
        case .event: "an event"
        case .other: "today"
        }
    }

    var preferredFormality: Formality {
        switch self {
        case .office, .event, .dateNight: .dressy
        case .brunch: .smart
        case .concert, .casual: .casual
        case .other: .smart
        }
    }
}

/// Today-only neutral clothing comfort. Never changes measurements or usual fit.
/// The PRD calls the first option "Close"; it's shown as "Fitted" so it doesn't read as "tight".
/// The raw value stays `close` so saved data still decodes.
enum Comfort: String, Codable, CaseIterable, Identifiable, Hashable {
    case close, comfortable, relaxed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .close: "Fitted"
        case .comfortable: "Comfortable"
        case .relaxed: "Relaxed"
        }
    }
}

enum ColorStrength: String, Codable, CaseIterable, Identifiable, Hashable {
    case required, preferred
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum ColorScope: String, Codable, CaseIterable, Identifiable, Hashable {
    case anyPiece, top, bottom, layer, shoes, wholePalette

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anyPiece: "Any one piece"
        case .top: "Top"
        case .bottom: "Bottom"
        case .layer: "Layer"
        case .shoes: "Shoes"
        case .wholePalette: "Overall palette"
        }
    }

    var slot: OutfitSlot? {
        switch self {
        case .top: .top
        case .bottom: .bottom
        case .layer: .layer
        case .shoes: .shoes
        case .anyPiece, .wholePalette: nil
        }
    }
}

struct ColorConstraint: Codable, Hashable {
    var family: ColorFamily
    var strength: ColorStrength
    var scope: ColorScope
}

/// Owned-only versus Suggestions. A suitcase source always forces strict owned-only.
enum StyleMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case ownedOnly, suggestions
    var id: String { rawValue }

    var label: String {
        switch self {
        case .ownedOnly: "Use only my wardrobe"
        case .suggestions: "Suggestions"
        }
    }
}

enum WeatherCondition: String, Codable, CaseIterable, Identifiable, Hashable {
    case clear, cloudy, rain, wind, snow, hot
    var id: String { rawValue }

    var label: String {
        switch self {
        case .clear: "Clear"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .wind: "Windy"
        case .snow: "Snow"
        case .hot: "Hot"
        }
    }

    var systemImage: String {
        switch self {
        case .clear: "sun.max"
        case .cloudy: "cloud"
        case .rain: "cloud.rain"
        case .wind: "wind"
        case .snow: "cloud.snow"
        case .hot: "thermometer.sun"
        }
    }
}

enum WeatherSource: String, Codable, Hashable {
    case simulatedForecast, manual, seasonOnly

    var label: String {
        switch self {
        case .simulatedForecast: "Simulated weather (demo data)"
        case .manual: "Set by you"
        case .seasonOnly: "Season only — forecast unavailable"
        }
    }
}

struct WeatherSnapshot: Codable, Hashable {
    var temperatureF: Int
    var condition: WeatherCondition
    var season: Season
    var source: WeatherSource
    var fetchedAt: Date = .now
    var locationLabel: String = "Demo city"

    var summary: String { "\(temperatureF)°F · \(condition.label) · \(season.label)" }

    var needsLayer: Bool { temperatureF < 64 || condition == .rain || condition == .wind || condition == .snow }
}

/// The scoped request envelope captured when Style Me is tapped.
struct StyleRequest: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var scope: WardrobeScope
    var scopeName: String
    var occasion: Occasion
    var customOccasion: String = ""
    var weather: WeatherSnapshot
    var startingItemID: String?
    var startingText: String = ""
    var comfort: Comfort?
    /// Her saved usual fit when the request was captured. Used only when `comfort` is nil.
    var usualFit: Comfort?
    var colorConstraint: ColorConstraint?
    var mode: StyleMode
    var allowNewPiece: Bool
    var onMe: Bool
    /// Individually confirmed per-request overrides (still-owned Dirty/Unavailable/Archived IDs).
    var overrideIDs: Set<String> = []
    var profileRevision: Int
    var inventoryRevision: Int
    var createdAt: Date = .now

    /// Strict when a suitcase is selected or the user chose owned-only.
    var isStrictOwned: Bool { scope.isSuitcase || mode == .ownedOnly }

    /// The comfort styling works to: today's choice, otherwise the usual fit captured with the
    /// request. `profile` only covers requests captured before the usual fit was recorded.
    func effectiveComfort(profile: UserProfile) -> Comfort {
        profile.comfort(today: comfort ?? usualFit)
    }
}

/// Editable form state for the Style Me screen (survives layout changes).
struct StyleRequestDraft: Codable, Hashable {
    var occasion: Occasion = .office
    var customOccasion: String = ""
    var weatherOverride: WeatherSnapshot?
    var startingItemID: String?
    var startingText: String = ""
    var comfort: Comfort?
    var colorConstraint: ColorConstraint?
    var mode: StyleMode = .suggestions
    var allowNewPiece: Bool = false
    var onMe: Bool = false
    var overrideIDs: Set<String> = []
}

// MARK: - Results

struct SwapOption: Identifiable, Hashable {
    var garment: Garment
    var eligibility: Eligibility
    var isCurrent: Bool
    var matchesColorFilter: Bool

    var id: String { garment.id }
}

enum GenerationOutcomeKind: String, Codable, Hashable {
    case outfitSet, partialWardrobe, insufficientWardrobe, generationNotCompleted
}

/// Typed stylist outcome. Partial/insufficient require complete-scope evidence;
/// a model/service failure is `generationNotCompleted`, never missing-clothes proof.
enum OutfitGenerationResult: Hashable {
    case outfitSet([Outfit])
    case partialWardrobe([Outfit], evidence: [String])
    case insufficientWardrobe(evidence: [String])
    case generationNotCompleted(reason: String)

    var kind: GenerationOutcomeKind {
        switch self {
        case .outfitSet: .outfitSet
        case .partialWardrobe: .partialWardrobe
        case .insufficientWardrobe: .insufficientWardrobe
        case .generationNotCompleted: .generationNotCompleted
        }
    }

    var outfits: [Outfit] {
        switch self {
        case let .outfitSet(o): o
        case let .partialWardrobe(o, _): o
        default: []
        }
    }
}

/// Complete-scope preflight evidence computed locally before dispatch.
struct ScopePreflight: Hashable {
    var scope: WardrobeScope
    var scopeName: String
    var eligibleGarments: [Garment]
    var excluded: [(garment: Garment, issues: [EligibilityIssue])]
    var isReady: Bool

    static func == (lhs: ScopePreflight, rhs: ScopePreflight) -> Bool {
        lhs.scope == rhs.scope && lhs.eligibleGarments.map(\.id) == rhs.eligibleGarments.map(\.id)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(scope)
        hasher.combine(eligibleGarments.map(\.id))
    }

    func eligible(in category: GarmentCategory) -> [Garment] {
        eligibleGarments.filter { $0.category == category }
    }

    func excludedCount(in category: GarmentCategory) -> Int {
        excluded.filter { $0.garment.category == category }.count
    }
}
