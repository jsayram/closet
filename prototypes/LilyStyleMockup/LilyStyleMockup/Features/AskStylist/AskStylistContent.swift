import SwiftUI

// MARK: - Export model

/// One numbered piece in the export. Numbers are labels for the shared image
/// only; they are never internal record identifiers.
struct AskStylistItem: Identifiable, Hashable {
    var id: String
    var number: Int
    var name: String
    /// "Top · Blouse" style description of the piece.
    var typeLabel: String
    /// `nil` means the color is Unknown.
    var colorName: String?
    var colorHex: String?
    var kind: GarmentKind
    /// A user-selected photo file, if she added one.
    var photoFilename: String?
    /// True when the record is marked as her photo (demo stand-ins are illustrated).
    var isPhoto: Bool
    var ownershipBadge: BadgeKind
    var availabilityBadge: BadgeKind?
    var isCurrentlyOwned: Bool
    /// Short honest phrase used in the prompt for pieces she can't wear today ("is in the laundry").
    var caveat: String?

    var imageBadge: BadgeKind { isPhoto ? .yourPhoto : .representative }
    var isWearableNow: Bool { caveat == nil }

    var badges: [BadgeKind] {
        [ownershipBadge] + (availabilityBadge.map { [$0] } ?? []) + [imageBadge]
    }

    /// Plain-text line used in the device preview and VoiceOver.
    var summaryLine: String {
        ([colorName ?? "Color unknown", typeLabel] + badges.map(\.text)).joined(separator: " · ")
    }

    var accessibilitySummary: String { "Number \(number), \(name). \(summaryLine)" }
}

/// Everything the Ask another stylist sheet shows for one look or selection.
struct AskStylistContent {
    enum Kind { case look, items }

    static let pageSize = 6

    var kind: Kind
    var targetKey: String
    var title: String
    var items: [AskStylistItem]
    var defaultOccasion: Occasion?
    /// Selected records that no longer exist (deleted since selection).
    var missingSelectionCount: Int = 0

    var pages: [[AskStylistItem]] {
        stride(from: 0, to: items.count, by: Self.pageSize).map { start in
            Array(items[start..<min(start + Self.pageSize, items.count)])
        }
    }

    var pageCount: Int { max(1, pages.count) }

    var allCurrentlyOwned: Bool { !items.isEmpty && items.allSatisfy(\.isCurrentlyOwned) }

    func pageSubtitle(_ index: Int) -> String {
        let page = pages.indices.contains(index) ? pages[index] : []
        guard let first = page.first?.number, let last = page.last?.number else { return "" }
        let range = first == last ? "#\(first)" : "#\(first)–#\(last)"
        let count = items.count == 1 ? "1 piece" : "\(items.count) pieces"
        return pageCount > 1 ? "\(count) · this page shows \(range)" : "\(count) · numbered \(range)"
    }

    /// Changes whenever the rendered image would change.
    var renderKey: String {
        title + "|" + items.map { item in
            [String(item.number), item.id, item.name, item.colorHex ?? "-", item.colorName ?? "-",
             item.typeLabel, item.badges.map(\.text).joined(separator: ","), item.photoFilename ?? "-"].joined(separator: ":")
        }.joined(separator: "|")
    }

    // MARK: Building

    static func make(target: AskStylistTarget, store: DemoStore) -> AskStylistContent {
        switch target {
        case let .outfit(outfit):
            let items = outfit.sortedPieces.enumerated().map { offset, piece in
                item(number: offset + 1, piece: piece, store: store)
            }
            let key = "outfit-\(outfit.id)-r\(outfit.revision)-" + outfit.sortedPieces.map { $0.garmentID ?? "hyp-\($0.capturedName)" }.joined(separator: ",")
            return AskStylistContent(kind: .look, targetKey: key, title: outfit.title.isEmpty ? "Untitled look" : outfit.title,
                                     items: items, defaultOccasion: outfit.occasion)
        case let .garments(ids):
            var seen = Set<String>()
            let unique = ids.filter { seen.insert($0).inserted }
            let garments = unique.compactMap { store.garment($0) }
            let items = garments.enumerated().map { offset, garment in
                item(number: offset + 1, garment: garment, slotLabel: garment.category.label)
            }
            let title = items.count == 1 ? "1 selected piece" : "\(items.count) selected pieces"
            return AskStylistContent(kind: .items, targetKey: "garments-" + unique.joined(separator: ","), title: title,
                                     items: items, defaultOccasion: nil, missingSelectionCount: unique.count - garments.count)
        }
    }

    private static func typeLabel(_ slotLabel: String, _ kind: GarmentKind) -> String {
        slotLabel == kind.label || kind == .unknown ? slotLabel : "\(slotLabel) · \(kind.label)"
    }

    private static func item(number: Int, piece: OutfitPiece, store: DemoStore) -> AskStylistItem {
        if let id = piece.garmentID, let garment = store.garment(id) {
            return item(number: number, garment: garment, slotLabel: piece.slot.label)
        }
        let isHypothetical = piece.isHypothetical || piece.garmentID == nil
        return AskStylistItem(
            id: piece.id,
            number: number,
            name: piece.capturedName,
            typeLabel: typeLabel(piece.slot.label, piece.capturedKind),
            colorName: piece.capturedColor?.name,
            colorHex: piece.capturedColor?.hex,
            kind: piece.capturedKind,
            photoFilename: nil,
            isPhoto: false,
            ownershipBadge: isHypothetical ? .custom("Not owned — idea", "lightbulb") : .missing,
            availabilityBadge: nil,
            isCurrentlyOwned: false,
            caveat: isHypothetical ? "is an idea I don't own" : "was removed from my closet"
        )
    }

    private static func item(number: Int, garment g: Garment, slotLabel: String) -> AskStylistItem {
        var ownership: BadgeKind
        var caveat: String?
        switch g.ownership {
        case .owned:
            ownership = .custom("Owned", "checkmark.circle")
        case .purchasedConfirmed:
            switch g.arrival ?? .unknown {
            case .arrived: ownership = .custom("Owned", "checkmark.circle")
            case .notArrived: ownership = .notArrived; caveat = "hasn't arrived yet"
            case .unknown: ownership = .arrivalUnknown; caveat = "may not have arrived yet"
            }
        case .wishlisted: ownership = .wishlist; caveat = "is on my wishlist, not owned"
        case .inspiration: ownership = .inspiration; caveat = "is inspiration, not owned"
        case .noLongerOwned: ownership = .noLongerOwned; caveat = "is no longer mine"
        }
        if g.isTrashed {
            ownership = .trash
            caveat = "is in Trash"
        }

        var availability: BadgeKind?
        if g.isOwnedOrPurchased {
            switch g.availability {
            case .available: availability = .custom("Available", "checkmark")
            case .dirty: availability = .dirty; caveat = caveat ?? "is in the laundry"
            case .unavailable: availability = .unavailable; caveat = caveat ?? "is unavailable right now"
            case .archived: availability = .archived; caveat = caveat ?? "is archived"
            }
        }

        return AskStylistItem(
            id: g.id,
            number: number,
            name: g.displayName,
            typeLabel: typeLabel(slotLabel, g.kind),
            colorName: g.color?.name,
            colorHex: g.color?.hex,
            kind: g.kind,
            photoFilename: g.photoFilename,
            isPhoto: g.photoFilename != nil || g.imageKind == .actualPhoto,
            ownershipBadge: ownership,
            availabilityBadge: availability,
            isCurrentlyOwned: g.isCurrentlyOwned,
            caveat: caveat
        )
    }
}

// MARK: - Optional personal context

/// Personal context the export may include. Every field is off by default and
/// selected one at a time; anything not listed here is never added. Weight and
/// measurement numbers other than height are never among them: "Size & fit cues"
/// carries only `BodyFit.shareableSummary` (cue words or the rough band label).
enum AskStylistPersonalField: String, CaseIterable, Identifiable, Hashable {
    case height, fitCues, fitNotes, styleWords

    var id: String { rawValue }

    var title: String {
        switch self {
        case .height: "Height"
        case .fitCues: "Size & fit cues"
        case .fitNotes: "Fit notes"
        case .styleWords: "Style words"
        }
    }

    var systemImage: String {
        switch self {
        case .height: "ruler"
        case .fitCues: "figure.stand"
        case .fitNotes: "tape.measure"
        case .styleWords: "text.quote"
        }
    }

    /// The exact value that would be added, or `nil` when Profile has nothing to add.
    func value(in profile: UserProfile) -> String? {
        switch self {
        case .height:
            guard let fact = profile.measurement(.height), fact.confirmed else { return nil }
            return fact.displayValue
        case .fitCues:
            return profile.bodyFit.shareableSummary
        case .fitNotes:
            let parts = [
                ("rise", profile.preferredRise),
                ("pants length", profile.preferredPantsLength),
                ("jackets", profile.jacketLengthNote),
            ].filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            guard !parts.isEmpty else { return nil }
            return parts.map { "\($0.0): \($0.1)" }.joined(separator: "; ")
        case .styleWords:
            let words = profile.styleWords.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return words.isEmpty ? nil : words.joined(separator: ", ")
        }
    }

    /// Why there's nothing to add, shown when `value(in:)` is nil.
    func emptyText(in profile: UserProfile) -> String {
        if self == .fitCues, profile.bodyFit.source == .measurements {
            return "Your measurements don't add any fit cues, so there's nothing to share"
        }
        return "Not set in Profile — nothing to add"
    }

    func line(in profile: UserProfile) -> String? {
        // The shareable summary already reads as a full line ("Fit cues: room at the hip.").
        if self == .fitCues { return value(in: profile) }
        return value(in: profile).map { "\(title): \($0)" }
    }
}

// MARK: - Local prompt template

/// Prepares the editable prompt on this device from a fixed template. No AI is involved.
enum AskStylistPromptTemplate {
    static func prompt(for content: AskStylistContent, occasion: Occasion?, keep: Int?) -> String {
        let phrase = occasion.map { $0 == .other ? "my day" : $0.phrase } ?? "everyday wear"
        let noun = content.allCurrentlyOwned ? "owned items" : "items"
        var sentences: [String] = []
        switch content.kind {
        case .look:
            sentences.append("Style these \(noun) for \(phrase). They're one look from my closet, numbered in the attached image.")
        case .items:
            sentences.append("Style these \(noun) for \(phrase). They're numbered in the attached image.")
        }
        if let keep, let item = content.items.first(where: { $0.number == keep }) {
            sentences.append("Keep #\(keep) (\(item.name)).")
        }
        sentences.append("Suggest three combinations using the numbered garments.")
        let caveats = content.items.compactMap { item in item.caveat.map { "#\(item.number) \($0)" } }
        if !caveats.isEmpty {
            sentences.append("Note: \(caveats.joined(separator: "; ")) — ask before using those.")
        }
        if content.pageCount > 1, let last = content.items.last?.number {
            sentences.append("The image has \(content.pageCount) pages covering #1–#\(last).")
        }
        sentences.append("Ask before adding shopping items.")
        return sentences.joined(separator: " ")
    }

    /// The exact text that Share and Copy Prompt hand over.
    static func finalText(prompt: String, personalLines: [String]) -> String {
        let base = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !personalLines.isEmpty else { return base }
        let about = "About me (I chose to share this):\n" + personalLines.map { "• \($0)" }.joined(separator: "\n")
        return base.isEmpty ? about : base + "\n\n" + about
    }

    static func personalLines(_ fields: Set<AskStylistPersonalField>, profile: UserProfile) -> [String] {
        AskStylistPersonalField.allCases.filter { fields.contains($0) }.compactMap { $0.line(in: profile) }
    }
}
