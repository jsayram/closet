import Foundation

// MARK: - Garment vocabulary

/// Broad slot-level category used for styling rules and swaps.
enum GarmentCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case top, bottom, dress, layer, shoes, accessory, unknown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        case .dress: "Dress"
        case .layer: "Layer"
        case .shoes: "Shoes"
        case .accessory: "Accessory"
        case .unknown: "Unknown category"
        }
    }

    var pluralLabel: String {
        switch self {
        case .top: "Tops"
        case .bottom: "Bottoms"
        case .dress: "Dresses"
        case .layer: "Layers"
        case .shoes: "Shoes"
        case .accessory: "Accessories"
        case .unknown: "Uncategorized"
        }
    }

    var systemImage: String {
        switch self {
        case .top: "tshirt"
        case .bottom: "rectangle.portrait.split.2x1"
        case .dress: "figure.dress.line.vertical.figure"
        case .layer: "jacket"
        case .shoes: "shoe"
        case .accessory: "handbag"
        case .unknown: "questionmark.square.dashed"
        }
    }
}

/// Illustration kind. Drives the app-owned representative artwork.
enum GarmentKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case blouse, tee, lacyTop, sweater, knitTop
    case trousers, jeans, skirt
    case dress
    case cardigan, jacket, blazer, coat
    case flats, heels, sneakers, loafers, boots
    case bag, scarf
    case unknown

    var id: String { rawValue }

    var defaultCategory: GarmentCategory {
        switch self {
        case .blouse, .tee, .lacyTop, .sweater, .knitTop: .top
        case .trousers, .jeans, .skirt: .bottom
        case .dress: .dress
        case .cardigan, .jacket, .blazer, .coat: .layer
        case .flats, .heels, .sneakers, .loafers, .boots: .shoes
        case .bag, .scarf: .accessory
        case .unknown: .unknown
        }
    }

    var label: String {
        switch self {
        case .blouse: "Blouse"
        case .tee: "T-shirt"
        case .lacyTop: "Lace top"
        case .sweater: "Sweater"
        case .knitTop: "Knit top"
        case .trousers: "Trousers"
        case .jeans: "Jeans"
        case .skirt: "Skirt"
        case .dress: "Dress"
        case .cardigan: "Cardigan"
        case .jacket: "Jacket"
        case .blazer: "Blazer"
        case .coat: "Coat"
        case .flats: "Flats"
        case .heels: "Heels"
        case .sneakers: "Sneakers"
        case .loafers: "Loafers"
        case .boots: "Boots"
        case .bag: "Bag"
        case .scarf: "Scarf"
        case .unknown: "Garment"
        }
    }

    static func kinds(for category: GarmentCategory) -> [GarmentKind] {
        allCases.filter { $0.defaultCategory == category }
    }
}

/// Coarse colour family used for constraints and search facets. The exact
/// confirmed shade lives in `GarmentColor.name`/`hex` and is never rewritten.
enum ColorFamily: String, Codable, CaseIterable, Identifiable, Hashable {
    case navy, blue, denim, pink, red, brick, burgundy, white, cream, beige, tan, brown, olive, green, gray, black, multi

    var id: String { rawValue }

    var label: String {
        switch self {
        case .navy: "Navy"
        case .blue: "Blue"
        case .denim: "Denim"
        case .pink: "Pink"
        case .red: "Red"
        case .brick: "Brick"
        case .burgundy: "Burgundy"
        case .white: "White"
        case .cream: "Cream"
        case .beige: "Beige"
        case .tan: "Tan"
        case .brown: "Brown"
        case .olive: "Olive"
        case .green: "Green"
        case .gray: "Gray"
        case .black: "Black"
        case .multi: "Multicolor"
        }
    }

    /// Representative swatch hex for pickers (not a garment's confirmed shade).
    var swatchHex: String {
        switch self {
        case .navy: "1F2A44"
        case .blue: "5B7FB8"
        case .denim: "4A6A8F"
        case .pink: "F2C4CE"
        case .red: "B3262E"
        case .brick: "A4492F"
        case .burgundy: "6D2433"
        case .white: "F7F5F0"
        case .cream: "EFE6D2"
        case .beige: "D8B79A"
        case .tan: "B08155"
        case .brown: "6B4226"
        case .olive: "5B6236"
        case .green: "3F6B45"
        case .gray: "8A8D91"
        case .black: "1E1E1E"
        case .multi: "9A7AA0"
        }
    }

    /// Neutral families for "safe" styling heuristics.
    var isNeutral: Bool {
        switch self {
        case .navy, .white, .cream, .beige, .tan, .gray, .black, .denim, .brown: true
        default: false
        }
    }

    /// Related families searched as a separately labelled expansion.
    var relatedFamilies: [ColorFamily] {
        switch self {
        case .navy: [.blue, .denim]
        case .blue: [.navy, .denim]
        case .denim: [.blue, .navy]
        case .pink: [.red, .burgundy]
        case .red: [.brick, .burgundy, .pink]
        case .brick: [.red, .brown]
        case .burgundy: [.red, .pink]
        case .white: [.cream]
        case .cream: [.white, .beige]
        case .beige: [.cream, .tan]
        case .tan: [.beige, .brown]
        case .brown: [.tan, .brick]
        case .olive: [.green]
        case .green: [.olive]
        case .gray: []
        case .black: []
        case .multi: []
        }
    }
}

/// Confirmed garment colour. `nil` on a garment means the colour is Unknown.
struct GarmentColor: Codable, Hashable {
    var name: String
    var hex: String
    var family: ColorFamily
}

enum Formality: Int, Codable, CaseIterable, Comparable, Hashable {
    case casual = 0, smart = 1, dressy = 2

    static func < (lhs: Formality, rhs: Formality) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .casual: "Casual"
        case .smart: "Smart"
        case .dressy: "Dressy"
        }
    }
}

enum Season: String, Codable, CaseIterable, Identifiable, Hashable {
    case spring, summer, fall, winter
    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    static func from(date: Date, calendar: Calendar = .current) -> Season {
        switch calendar.component(.month, from: date) {
        case 3...5: .spring
        case 6...8: .summer
        case 9...11: .fall
        default: .winter
        }
    }
}

// MARK: - Ownership, availability, arrival

/// Ownership is independent of availability. Only `owned` and arrived
/// `purchasedConfirmed` records count as current inventory.
enum OwnershipStatus: String, Codable, CaseIterable, Hashable {
    case inspiration, wishlisted, owned, purchasedConfirmed, noLongerOwned

    var label: String {
        switch self {
        case .inspiration: "Inspiration"
        case .wishlisted: "Wishlist"
        case .owned: "Owned"
        case .purchasedConfirmed: "Bought"
        case .noLongerOwned: "No longer owned"
        }
    }
}

enum Availability: String, Codable, CaseIterable, Hashable {
    case available, dirty, unavailable, archived

    var label: String {
        switch self {
        case .available: "Available"
        case .dirty: "Dirty"
        case .unavailable: "Unavailable"
        case .archived: "Archived"
        }
    }
}

enum ArrivalState: String, Codable, CaseIterable, Hashable {
    case notArrived, arrived, unknown

    var label: String {
        switch self {
        case .notArrived: "Not arrived"
        case .arrived: "Arrived"
        case .unknown: "Arrival unknown"
        }
    }
}

/// How the garment is depicted. Representative artwork is always labelled.
enum ImageSourceKind: String, Codable, CaseIterable, Hashable {
    /// A user-supplied photo of her actual garment (demo uses illustrated stand-ins).
    case actualPhoto
    /// App-owned representative artwork; not her actual garment.
    case representative
    /// Text-only entry shown with a labelled representative tile.
    case textOnly

    var label: String {
        switch self {
        case .actualPhoto: "Your photo"
        case .representative: "Representative image"
        case .textOnly: "Text-only item"
        }
    }
}

/// Optional on-device processing state for an imported photo (simulated).
enum PhotoProcessingState: String, Codable, Hashable {
    case originalOnly, processing, ready, failed, skipped

    var label: String {
        switch self {
        case .originalOnly: "Original"
        case .processing: "Processing"
        case .ready: "Processed version ready"
        case .failed: "Processing failed — original kept"
        case .skipped: "Original kept"
        }
    }
}

// MARK: - Names and annotations

enum AnnotationKind: String, Codable, Hashable {
    case alias, detail
}

enum AnnotationProvenance: String, Codable, Hashable {
    case userEntered, rememberedFromSearch, acceptedSuggestion, importedFixture

    var label: String {
        switch self {
        case .userEntered: "Added by you"
        case .rememberedFromSearch: "Remembered from a search"
        case .acceptedSuggestion: "Accepted suggestion"
        case .importedFixture: "Demo data"
        }
    }
}

/// Item-scoped personal vocabulary (Other names) and reviewed descriptors (Add details).
struct GarmentAnnotation: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var kind: AnnotationKind
    var text: String
    var provenance: AnnotationProvenance
    var createdAt: Date = .now
}

// MARK: - Garment record

struct Garment: Identifiable, Codable, Hashable {
    var id: String
    var revision: Int = 1
    /// Personal name such as "Cute pink shirt".
    var displayName: String
    var annotations: [GarmentAnnotation] = []
    var category: GarmentCategory
    var kind: GarmentKind
    /// `nil` means the colour is Unknown.
    var color: GarmentColor?
    var brand: String?
    var sizeLabel: String?
    var fabric: String?
    var notes: String = ""
    var formality: Formality = .smart
    var seasons: Set<Season> = Set(Season.allCases)
    /// 0 = light, 3 = very warm.
    var warmth: Int = 1

    var ownership: OwnershipStatus = .owned
    var ownershipRevision: Int = 1
    var availability: Availability = .available
    var availabilityRevision: Int = 1
    /// Remembered status before Archive, used for honest Unarchive review.
    var statusBeforeArchive: Availability?
    var unavailableUntil: Date?
    /// Independent arrival state for `purchasedConfirmed` records.
    var arrival: ArrivalState?
    var trashedAt: Date?

    var imageKind: ImageSourceKind = .representative
    /// Filename of a user-selected photo stored by `PhotoStore`, if any.
    var photoFilename: String?
    var processing: PhotoProcessingState = .originalOnly
    /// Bumped when appearance inputs change (photo/confirmed colour), not for names/status.
    var appearanceRevision: Int = 1

    var sourceRetailer: String?
    var sourceURL: String?
    var purchaseDate: Date?
    var addedAt: Date = .now

    var aliases: [GarmentAnnotation] { annotations.filter { $0.kind == .alias } }
    var details: [GarmentAnnotation] { annotations.filter { $0.kind == .detail } }

    var isTrashed: Bool { trashedAt != nil }

    /// Current ownership: Owned, or Bought and confirmed arrived, and not in Trash.
    var isCurrentlyOwned: Bool {
        guard !isTrashed else { return false }
        switch ownership {
        case .owned: return true
        case .purchasedConfirmed: return arrival == .arrived
        default: return false
        }
    }

    /// Ownership that still belongs to her (including not-yet-arrived purchases).
    var isOwnedOrPurchased: Bool {
        !isTrashed && (ownership == .owned || ownership == .purchasedConfirmed)
    }

    var colorLabel: String { color?.name ?? "Color unknown" }

    /// Short accessible description used for VoiceOver.
    var accessibilityDescription: String {
        var parts = [displayName]
        if let color { parts.append(color.name) } else { parts.append("color unknown") }
        parts.append(kind.label)
        return parts.joined(separator: ", ")
    }
}
