import Foundation

enum MeasurementDimension: String, Codable, CaseIterable, Identifiable, Hashable {
    case height, inseam, waist, hip, bust, sleeve, rise, torso

    var id: String { rawValue }

    var label: String {
        switch self {
        case .height: "Height"
        case .inseam: "Inseam / preferred trouser length"
        case .waist: "Waist"
        case .hip: "Hip / seat"
        case .bust: "Bust"
        case .sleeve: "Sleeve length"
        case .rise: "Rise"
        case .torso: "Torso length"
        }
    }

    var help: String {
        switch self {
        case .height: "Used for proportions. With your weight, it gives only a rough size estimate when waist, hip and bust are missing. It never sets your inseam."
        case .inseam: "Measure from the crotch seam to where you want the hem, or use a pair that fits well."
        case .waist: "Around your natural waist, or the waist of a garment that fits well."
        case .hip: "Around the fullest part of your hips/seat."
        case .bust: "Around the fullest part of the bust."
        case .sleeve: "From shoulder seam to where you like the cuff."
        case .rise: "Where you like the waistband to sit — for example, around your navel."
        case .torso: "Shoulder to natural waist."
        }
    }
}

enum MeasurementUnit: String, Codable, CaseIterable, Hashable {
    case inches, centimeters
    var symbol: String { self == .inches ? "in" : "cm" }
}

/// What a value measures. Body and garment values are never compared as if interchangeable.
enum MeasurementBasis: String, Codable, CaseIterable, Identifiable, Hashable {
    case body, preferredGarment, actualGarment, chartRange

    var id: String { rawValue }

    var label: String {
        switch self {
        case .body: "Body measurement"
        case .preferredGarment: "Preferred garment length"
        case .actualGarment: "From a garment that fits"
        case .chartRange: "Size-chart range"
        }
    }
}

/// A confirmed optional measurement. Absent dimensions are Unknown, never zero.
struct MeasurementFact: Identifiable, Codable, Hashable {
    var id: String { dimension.rawValue }
    var dimension: MeasurementDimension
    var value: Double
    var unit: MeasurementUnit
    var basis: MeasurementBasis
    var provenance: String
    var confirmed: Bool
    var updatedAt: Date = .now

    /// The value in inches, so charts and listings are never compared across units.
    var inches: Double { unit == .inches ? value : value / 2.54 }

    var displayValue: String {
        if dimension == .height, unit == .inches {
            let feet = Int(value) / 12
            let inches = Int(value) % 12
            return "\(feet)′\(inches)″"
        }
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
        return "\(formatted) \(unit.symbol)"
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable, Hashable {
    case pounds, kilograms

    var id: String { rawValue }
    var symbol: String { self == .pounds ? "lb" : "kg" }
    var label: String { self == .pounds ? "Pounds" : "Kilograms" }
}

/// Optional body weight. Private data (this device, plus her private iCloud when sync is on):
/// it is never put in a search query, a stylist request or an export. Only `BodyFit` reads it, and only as a fallback.
struct BodyWeight: Codable, Hashable {
    var value: Double
    var unit: WeightUnit
    /// She gave a rough figure ("about 120 lb") rather than a recent reading.
    var approximate: Bool = true
    var updatedAt: Date = .now

    var pounds: Double { unit == .pounds ? value : value * 2.204_62 }

    /// For her own Profile screen only, e.g. "About 120 lb".
    var displayValue: String {
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.1f", value)
        return approximate ? "About \(formatted) \(unit.symbol)" : "\(formatted) \(unit.symbol)"
    }
}

enum FitResult: String, Codable, CaseIterable, Identifiable, Hashable {
    case fitsWell, tooLong, tooShort, tooTight, tooLoose, returned
    var id: String { rawValue }

    var label: String {
        switch self {
        case .fitsWell: "Fits well"
        case .tooLong: "Too long"
        case .tooShort: "Too short"
        case .tooTight: "Too tight"
        case .tooLoose: "Too loose"
        case .returned: "Returned"
        }
    }
}

enum FitArea: String, Codable, CaseIterable, Identifiable, Hashable {
    case waist, seat, thigh, rise, length, jacketLength, sleeve, shoulders
    var id: String { rawValue }
    var label: String {
        switch self {
        case .jacketLength: "Jacket length"
        default: rawValue.capitalized
        }
    }
}

/// A well-fitting (or not) real garment reference she confirmed.
struct FitReference: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var brand: String
    var category: GarmentCategory
    var sizeLabel: String
    var result: FitResult
    var areas: [FitArea] = []
    var note: String = ""
    var garmentID: String?
}

enum PermissionState: String, Codable, CaseIterable, Hashable {
    case notAsked, allowed, declined

    var label: String {
        switch self {
        case .notAsked: "Not asked yet"
        case .allowed: "Allowed"
        case .declined: "Declined"
        }
    }
}

/// Separate processing purposes. One permission never authorizes another.
enum ProcessingPurpose: String, Codable, CaseIterable, Identifiable, Hashable {
    case cloudStyling, photoUnderstanding, onMeImages, webSearch, fitRanking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cloudStyling: "Cloud stylist (text)"
        case .photoUnderstanding: "Garment photo descriptions"
        case .onMeImages: "On Me picture previews"
        case .webSearch: "Find One web search"
        case .fitRanking: "Private fit comparison"
        }
    }

    /// Fictional recipient label. No production provider is selected.
    var recipient: String {
        switch self {
        case .cloudStyling: "Demo Stylist Service (simulated)"
        case .photoUnderstanding: "Demo Photo Describer (simulated)"
        case .onMeImages: "Demo Image Service (simulated)"
        case .webSearch: "Demo Web Search (simulated)"
        case .fitRanking: "Demo Fit Ranker (simulated)"
        }
    }

    var dataSent: String {
        switch self {
        case .cloudStyling: "Occasion, weather, today's choices and usual fit, relevant garment descriptions, confirmed fit facts and fit cues, or a rough size range when waist, hip and bust are missing. Never your weight. No photos."
        case .photoUnderstanding: "Only the garment photo you select, to suggest a name and visible details for your review."
        case .onMeImages: "Your selected reference photo and the selected garment photos for that preview."
        case .webSearch: "A reviewed public description such as “cream lace crop top, up to $60, ships to US”. No measurements or closet."
        case .fitRanking: "Product facts plus the minimum confirmed fit facts needed to compare. No browsing tools."
        }
    }
}

struct RetailerPreference: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var isPreferred: Bool = true
    var isAvoided: Bool = false
}

enum OnMeReferenceState: Codable, Hashable {
    case none
    /// A simulated reference (demo placeholder figure). Never a real person.
    case simulatedReference(version: Int, addedAt: Date)

    var version: Int? {
        if case let .simulatedReference(version, _) = self { return version }
        return nil
    }
}

struct UserProfile: Codable, Hashable {
    var revision: Int = 1
    var displayName: String = "Lily (demo profile)"
    var measurements: [MeasurementFact] = []
    /// Optional weight. Only a rough size fallback when waist, hip and bust are all
    /// missing or unconfirmed (see `BodyFit`). The raw value never leaves the device.
    /// Replaces the old free-text `weightContext`, which older snapshots still carry
    /// and the decoder simply ignores.
    var weight: BodyWeight?
    var fitReferences: [FitReference] = []
    var usualTopSize: String?
    var usualBottomSize: String?
    var usualFit: Comfort = .comfortable
    var preferredRise: String = "Around the navel — avoid low and extremely high rise"
    var preferredPantsLength: String = "Hem clears the floor with flats; ankle or full length"
    var jacketLengthNote: String = "Some jackets run too long and look oversized"
    var styleWords: [String] = ["Chic", "Elegant", "Classy", "Cohesive", "Less trend-driven"]
    var likedColorPairs: [String] = ["Blue + light pink", "Olive + brick"]
    var avoidedColorPairs: [String] = ["Strong red + green (preference, reversible)"]
    var budgetMax: Int? = 80
    var retailers: [RetailerPreference] = [
        .init(name: "Amazon"), .init(name: "TikTok Shop"), .init(name: "Target"),
        .init(name: "Walmart"), .init(name: "H&M"),
    ]
    var retailerOnlyMode: Bool = false
    var shippingCountry: String = "United States"
    var permissions: [ProcessingPurpose: PermissionState] = [
        .cloudStyling: .allowed,
        .photoUnderstanding: .notAsked,
        .onMeImages: .notAsked,
        .webSearch: .notAsked,
        .fitRanking: .notAsked,
    ]
    var onMeReference: OnMeReferenceState = .none
    var analyticsOptIn: Bool = false
    var iCloudSyncEnabled: Bool = true

    func measurement(_ dimension: MeasurementDimension) -> MeasurementFact? {
        measurements.first { $0.dimension == dimension }
    }

    /// A measurement that may guide fit: confirmed, and a body value or a size-chart range.
    /// Garment lengths never stand in for body measurements.
    func confirmedBodyMeasurement(_ dimension: MeasurementDimension) -> MeasurementFact? {
        guard let fact = measurement(dimension), fact.confirmed,
              fact.basis == .body || fact.basis == .chartRange else { return nil }
        return fact
    }

    /// Today's comfort when she picked one, otherwise her saved usual fit.
    /// Today's choice applies to that request only and never changes `usualFit`.
    func comfort(today: Comfort?) -> Comfort {
        today ?? usualFit
    }

    func permission(_ purpose: ProcessingPurpose) -> PermissionState {
        permissions[purpose] ?? .notAsked
    }
}
