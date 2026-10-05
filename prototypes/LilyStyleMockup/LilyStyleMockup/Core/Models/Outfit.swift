import Foundation

enum OutfitSlot: String, Codable, CaseIterable, Identifiable, Hashable {
    case layer, top, dress, bottom, shoes, accessory

    var id: String { rawValue }

    var label: String {
        switch self {
        case .layer: "Layer"
        case .top: "Top"
        case .dress: "Dress"
        case .bottom: "Bottom"
        case .shoes: "Shoes"
        case .accessory: "Accessory"
        }
    }

    var category: GarmentCategory {
        switch self {
        case .layer: .layer
        case .top: .top
        case .dress: .dress
        case .bottom: .bottom
        case .shoes: .shoes
        case .accessory: .accessory
        }
    }

    static func slot(for category: GarmentCategory) -> OutfitSlot? {
        switch category {
        case .top: .top
        case .bottom: .bottom
        case .dress: .dress
        case .layer: .layer
        case .shoes: .shoes
        case .accessory: .accessory
        case .unknown: nil
        }
    }

    /// Display order on boards: top-to-bottom of the body.
    var sortOrder: Int {
        switch self {
        case .layer: 0
        case .top: 1
        case .dress: 2
        case .bottom: 3
        case .shoes: 4
        case .accessory: 5
        }
    }
}

/// Result-lane meaning. Color alone never distinguishes lanes; each has a text label and icon.
enum LanePurpose: String, Codable, CaseIterable, Hashable {
    case safeSimple, elevated, elevatedAlternate, newPiece, hypothetical, manual

    var title: String {
        switch self {
        case .safeSimple: "Safe / Simple"
        case .elevated: "Stylish / Elevated"
        case .elevatedAlternate: "Another Elevated look"
        case .newPiece: "Elevated with a new piece"
        case .hypothetical: "Idea (hypothetical pieces)"
        case .manual: "Your look"
        }
    }

    var subtitle: String {
        switch self {
        case .safeSimple: "Your clothes · easy and reliable"
        case .elevated: "Your clothes · a little more polished"
        case .elevatedAlternate: "Your clothes · a different direction"
        case .newPiece: "Includes one piece you don't own"
        case .hypothetical: "Suggestions only — not from your closet"
        case .manual: "Built by you"
        }
    }

    var systemImage: String {
        switch self {
        case .safeSimple: "checkmark.seal"
        case .elevated: "sparkles"
        case .elevatedAlternate: "wand.and.stars"
        case .newPiece: "bag.badge.plus"
        case .hypothetical: "lightbulb"
        case .manual: "hand.draw"
        }
    }
}

/// One piece of an outfit. Owned pieces reference a canonical garment ID; the
/// captured fields preserve what the look contained when it was made/saved.
struct OutfitPiece: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var slot: OutfitSlot
    /// Canonical garment ID. `nil` for a hypothetical/unowned candidate.
    var garmentID: String?
    var capturedName: String
    var capturedColor: GarmentColor?
    var capturedKind: GarmentKind
    var capturedImageKind: ImageSourceKind
    var capturedGarmentRevision: Int = 1
    /// True for an explicitly requested unowned new-piece idea or a Suggestions-mode idea.
    var isHypothetical: Bool = false

    static func from(_ garment: Garment, slot: OutfitSlot? = nil) -> OutfitPiece {
        OutfitPiece(
            slot: slot ?? OutfitSlot.slot(for: garment.category) ?? .accessory,
            garmentID: garment.id,
            capturedName: garment.displayName,
            capturedColor: garment.color,
            capturedKind: garment.kind,
            capturedImageKind: garment.imageKind,
            capturedGarmentRevision: garment.revision
        )
    }
}

struct Outfit: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var revision: Int = 1
    var title: String
    var lane: LanePurpose
    var pieces: [OutfitPiece]
    /// Concise reviewed explanation (no sensitive context).
    var rationale: String = ""
    var colorNote: String = ""
    var fitNote: String = ""
    var occasion: Occasion?
    var weatherSummary: String = ""
    var capturedScope: WardrobeScope?
    /// Name of the captured suitcase at capture time ("Former suitcase" if later deleted).
    var capturedScopeName: String?
    var isSaved: Bool = false
    var isFavorite: Bool = false
    var intendedDate: Date?
    var keywords: [String] = []
    var notes: String = ""
    var createdAt: Date = .now
    var updatedAt: Date = .now
    /// Quiet optional actual-wear log. Never changes laundry status.
    var wornDates: [Date] = []
    var sourceRequestID: String?

    var sortedPieces: [OutfitPiece] { pieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder } }

    var garmentIDs: [String] { pieces.compactMap(\.garmentID) }

    var hasHypotheticalPiece: Bool { pieces.contains(where: \.isHypothetical) }

    func piece(for slot: OutfitSlot) -> OutfitPiece? { pieces.first { $0.slot == slot } }

    /// Deterministic key for exact retained-preview reuse: ordered pieces and appearance revisions.
    func renderKey(referenceVersion: Int, appearanceRevisions: [String: Int]) -> String {
        let parts = sortedPieces.map { piece -> String in
            if let id = piece.garmentID {
                return "\(piece.slot.rawValue):\(id)@\(appearanceRevisions[id] ?? piece.capturedGarmentRevision)"
            }
            return "\(piece.slot.rawValue):hyp-\(piece.capturedName)"
        }
        return parts.joined(separator: "|") + "#ref\(referenceVersion)"
    }
}

/// Named private organization of saved looks and retained previews.
struct OutfitCollection: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var outfitIDs: [String] = []
    var previewIDs: [String] = []
    var createdAt: Date = .now
}

// MARK: - Retained preview history

enum PreviewQualityLabel: String, Codable, Hashable {
    case ok, approximate, appearanceMismatch

    var label: String {
        switch self {
        case .ok: "Simulated preview"
        case .approximate: "Approximate — some pieces are representative"
        case .appearanceMismatch: "Needs review — appearance mismatch"
        }
    }
}

/// Every technically valid delivered (simulated) preview is retained here,
/// independent of Favorites, dislikes, swaps or subscription state.
struct PreviewEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var outfitID: String
    var outfitRevision: Int
    var title: String
    var lane: LanePurpose
    /// Immutable composition snapshot used for the preview.
    var snapshotPieces: [OutfitPiece]
    var referenceVersion: Int
    var renderKey: String
    var quality: PreviewQualityLabel = .ok
    var isFavorite: Bool = false
    var isDisliked: Bool = false
    var keywords: [String] = []
    var capturedScope: WardrobeScope?
    var capturedScopeName: String?
    var occasion: Occasion?
    var createdAt: Date = .now
    /// Simulation marker. Every preview in this prototype is simulated.
    var isSimulated: Bool = true
}

// MARK: - Styling history (structured, no raw prompts)

struct StylingHistoryEntry: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var outfitSnapshot: Outfit
    var occasion: Occasion
    var scope: WardrobeScope
    var mode: StyleMode
    var startingItemID: String?
    var requiredColor: ColorFamily?
    var capturedAt: Date
    var feedback: HistoryFeedback = .none
    /// Comfort the look was made for (today's choice or her usual fit). Nil in older entries.
    var comfort: Comfort? = nil
    /// `BodyFit.fingerprint` when the look was made: source, cues and rough band, never numbers.
    var fitBasis: String? = nil
}

enum HistoryFeedback: String, Codable, Hashable {
    case none, liked, rejected
}
