import Foundation

/// What Find One is looking for, captured from an outfit piece.
struct FindOneContext: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var outfitID: String?
    var slot: OutfitSlot
    var description: String
    var kind: GarmentKind
    var colorFamily: ColorFamily?
    var scope: WardrobeScope
}

/// Reviewed public garment intent. Never contains weight, measurements, photos or closet data.
struct PublicShoppingIntent: Codable, Hashable {
    var garment: String
    var color: String?
    var budgetMax: Int?
    var currency: String = "USD"
    var shipsTo: String
    var preferredRetailers: [String]
    var retailerOnly: Bool
    var requestSizeEvidence: Bool = true
    /// Exact size text she chose to add with "Include my size range", e.g. "size M".
    /// Only ever a size label, never weight or measurement numbers. Nil unless she turned it on.
    var sizeRange: String? = nil

    var summary: String {
        var parts = [color.map { "\($0) \(garment)" } ?? garment]
        if let sizeRange { parts.append(sizeRange) }
        if let budgetMax { parts.append("up to $\(budgetMax)") }
        parts.append("ships to \(shipsTo == "United States" ? "US" : shipsTo)")
        return parts.joined(separator: ", ")
    }
}

enum FitEvidenceState: String, Codable, Hashable, CaseIterable {
    case supportedGuidance, needsFitConfirmation, knownFitConflict

    var title: String {
        switch self {
        case .supportedGuidance: "Supported sizing guidance"
        case .needsFitConfirmation: "Needs fit confirmation"
        case .knownFitConflict: "Excluded — known fit conflict"
        }
    }

    var systemImage: String {
        switch self {
        case .supportedGuidance: "ruler"
        case .needsFitConfirmation: "questionmark.circle"
        case .knownFitConflict: "xmark.octagon"
        }
    }
}

enum EvidenceSourceType: String, Codable, Hashable {
    case productPage, sizeChart, garmentMeasurements, snippet, review

    var label: String {
        switch self {
        case .productPage: "Product page"
        case .sizeChart: "Size chart"
        case .garmentMeasurements: "Garment measurements"
        case .snippet: "Search snippet (unverified)"
        case .review: "Shopper review (context only)"
        }
    }
}

struct EvidenceItem: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var claim: String
    var sourceType: EvidenceSourceType
    var sourceLabel: String
    var retrievedAt: Date
}

enum AvailabilityEvidence: String, Codable, Hashable {
    case inStock, backordered, unavailable, unknown
    var label: String {
        switch self {
        case .inStock: "Listed in stock"
        case .backordered: "Backordered"
        case .unavailable: "Variant unavailable"
        case .unknown: "Stock not verified"
        }
    }
}

enum ShippingEvidence: String, Codable, Hashable {
    case shipsToDestination, noDelivery, unverified
    var label: String {
        switch self {
        case .shipsToDestination: "Ships to US (per product page)"
        case .noDelivery: "Doesn't deliver to US"
        case .unverified: "Shipping not verified"
        }
    }
}

/// A fictional, mock-sourced lead. URLs use the reserved `.example` domain.
struct ShoppingCandidate: Identifiable, Codable, Hashable {
    var id: String
    var retailer: String
    var domain: String
    var title: String
    var url: String
    var price: Double?
    var currency: String = "USD"
    var colorName: String
    var colorHex: String
    var kind: GarmentKind
    var fitState: FitEvidenceState
    var fitReason: String
    var comparedDimensions: [String]
    var unknowns: [String]
    var recommendedSize: String?
    var evidence: [EvidenceItem]
    var styleReason: String
    var stock: AvailabilityEvidence
    var shipping: ShippingEvidence
    var isPreferredRetailer: Bool
    var isDirectProductPage: Bool = true
    var priceTier: PriceTier?
    var retrievedAt: Date
    /// The size this listing offers, as the store labels it (e.g. "S", "XSP", "2P").
    var listedSize: String? = nil
    /// Rough height-and-weight estimate, attached on this device only when no confirmed
    /// waist, hip or bust could be compared. Never sizing guidance and never an exclusion.
    var sizeEstimate: LeadSizeEstimate? = nil
}

/// How a listing's size sits against her rough height-and-weight size band. Used only
/// to order leads that already need fit confirmation. Holds the band label, never weight.
struct LeadSizeEstimate: Codable, Hashable {
    var bandLabel: String
    var listedSize: String
    /// Letter sizes between the listed size and the band: 0 inside it. Nil for numeric
    /// sizes like "0" or "2P", which aren't placed against a letter band.
    var distance: Int?

    var note: String {
        "Rough size estimate from your height and weight: around \(bandLabel). Not a fit check, so compare the size chart."
    }

    var closeness: String {
        switch distance {
        case 0?: "The listed size \(listedSize) falls inside that rough range."
        case 1?: "The listed size \(listedSize) is one size away from that rough range."
        case let steps?: "The listed size \(listedSize) is \(steps) sizes away from that rough range."
        case nil: "The listed size \(listedSize) uses a numeric scale, so it isn't placed against the estimate."
        }
    }
}

enum PriceTier: String, Codable, Hashable {
    case affordable, investment
    var label: String { self == .affordable ? "Affordable option" : "Investment option" }
}

enum SearchOutcome: String, Codable, Hashable {
    case resultsFound, noMatchingResultsWithinSearch, searchNotCompleted, unsupportedCoverage

    var explanation: String {
        switch self {
        case .resultsFound: "Results found within this bounded search."
        case .noMatchingResultsWithinSearch: "No matching results within this search. That doesn't mean no store sells it."
        case .searchNotCompleted: "The search didn't finish. Nothing was invented — your saved links and manual browsing still work."
        case .unsupportedCoverage: "This destination or category isn't supported by the demo search."
        }
    }
}

struct SourceAttempt: Identifiable, Codable, Hashable {
    var id: String { retailer }
    var retailer: String
    var status: SourceAttemptStatus
}

enum SourceAttemptStatus: String, Codable, Hashable {
    case evidenceFound, attemptedNoEvidence, blocked, notAttempted
    var label: String {
        switch self {
        case .evidenceFound: "Evidence found"
        case .attemptedNoEvidence: "Searched — no usable evidence"
        case .blocked: "Page unreadable/blocked"
        case .notAttempted: "Not attempted (search bounds reached)"
        }
    }
}

struct ShoppingSearchResult: Codable, Hashable {
    var intent: PublicShoppingIntent
    var outcome: SearchOutcome
    var candidates: [ShoppingCandidate]
    var attempts: [SourceAttempt]
    var completedAt: Date
}

/// Durable local record of a store visit started from Find One.
struct ShoppingVisit: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var candidate: ShoppingCandidate
    var context: FindOneContext?
    var openedAt: Date = .now
    var dismissedPrompt: Bool = false
}

enum ReminderKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case arrival, photo, description
    var id: String { rawValue }
    var label: String {
        switch self {
        case .arrival: "Mark it arrived"
        case .photo: "Add a photo"
        case .description: "Add a description"
        }
    }
}

enum ReminderStatus: String, Codable, Hashable {
    case pending, deferred, completed, dismissed
}

/// Private local completion reminder. No notification is scheduled in this prototype.
struct PurchaseReminder: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var garmentID: String
    var kind: ReminderKind
    var status: ReminderStatus = .pending
    var dueDate: Date?
}

/// Saved-for-later product reference (Wishlist). Never ownership.
struct SavedProductReference: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var candidate: ShoppingCandidate
    var savedAt: Date = .now
    var context: FindOneContext?
}
