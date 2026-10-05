import Foundation

// MARK: - Result types, scopes and facet vocabularies

/// The kinds of local records unified search can return.
enum SearchResultType: String, CaseIterable, Identifiable, Hashable {
    case garment, outfit, preview, product

    var id: String { rawValue }

    /// Short label for type filters.
    var filterLabel: String {
        switch self {
        case .garment: "Garment"
        case .outfit: "Saved look"
        case .preview: "Preview"
        case .product: "Saved product"
        }
    }

    var systemImage: String {
        switch self {
        case .garment: "tshirt"
        case .outfit: "bookmark"
        case .preview: "flask"
        case .product: "bag"
        }
    }

    var sortOrder: Int {
        switch self {
        case .garment: 0
        case .outfit: 1
        case .preview: 2
        case .product: 3
        }
    }
}

extension SearchScopeHint {
    var searchLabel: String {
        switch self {
        case .closet: "Closet"
        case .saved: "Saved"
        case .everything: "Everything"
        }
    }

    /// Record types each scope covers. Closet follows the working source; Saved
    /// covers retained history regardless of today's suitcase membership.
    var searchResultTypes: [SearchResultType] {
        switch self {
        case .closet: [.garment]
        case .saved: [.outfit, .preview, .product]
        case .everything: SearchResultType.allCases
        }
    }
}

/// Ownership facet. Applies to garments only; saved looks keep their history.
enum SearchOwnershipScope: String, CaseIterable, Identifiable, Hashable {
    case current, all, wishlist

    var id: String { rawValue }

    var label: String {
        switch self {
        case .current: "Current owned"
        case .all: "All, incl. no longer owned"
        case .wishlist: "Wishlist"
        }
    }

    var chipLabel: String {
        switch self {
        case .current: "Current owned"
        case .all: "All ownership"
        case .wishlist: "Wishlist"
        }
    }
}

/// Image-source facet: what a result's picture actually is.
enum SearchImageSource: String, CaseIterable, Identifiable, Hashable {
    case yourPhoto, representative, simulatedPreview

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yourPhoto: "Your photo"
        case .representative: "Representative"
        case .simulatedPreview: "Simulated preview"
        }
    }

    var systemImage: String {
        switch self {
        case .yourPhoto: "camera"
        case .representative: "photo.artframe"
        case .simulatedPreview: "flask"
        }
    }
}

enum SearchFacetKind: String, CaseIterable, Identifiable, Hashable {
    case type, category, color, ownership, availability, favorites, collection, imageSource

    var id: String { rawValue }

    var label: String {
        switch self {
        case .type: "Type"
        case .category: "Category"
        case .color: "Color"
        case .ownership: "Ownership"
        case .availability: "Available only"
        case .favorites: "Favorites"
        case .collection: "Collection"
        case .imageSource: "Image source"
        }
    }

    /// Accessibility identifier suffix (`searchFacet-<name>`).
    var identifierName: String { rawValue }
}

/// Explicit facet selections. Facets combine with AND; choices inside one facet
/// combine with OR. Search never relaxes these on its own.
struct SearchFilters: Hashable {
    var types: Set<SearchResultType> = []
    var categories: Set<GarmentCategory> = []
    var colors: Set<ColorFamily> = []
    var ownership: SearchOwnershipScope = .current
    var availableOnly = false
    var favoritesOnly = false
    var collectionIDs: Set<String> = []
    var imageSources: Set<SearchImageSource> = []

    /// Facets that differ from their defaults, in display order.
    var activeFacets: [SearchFacetKind] {
        var result: [SearchFacetKind] = []
        if !types.isEmpty { result.append(.type) }
        if !categories.isEmpty { result.append(.category) }
        if !colors.isEmpty { result.append(.color) }
        if ownership != .current { result.append(.ownership) }
        if availableOnly { result.append(.availability) }
        if favoritesOnly { result.append(.favorites) }
        if !collectionIDs.isEmpty { result.append(.collection) }
        if !imageSources.isEmpty { result.append(.imageSource) }
        return result
    }

    var isDefault: Bool { activeFacets.isEmpty }

    /// Number of individual active choices (for the filter count).
    var activeChoiceCount: Int {
        types.count + categories.count + colors.count + (ownership != .current ? 1 : 0)
            + (availableOnly ? 1 : 0) + (favoritesOnly ? 1 : 0) + collectionIDs.count + imageSources.count
    }

    mutating func reset(_ facet: SearchFacetKind) {
        switch facet {
        case .type: types = []
        case .category: categories = []
        case .color: colors = []
        case .ownership: ownership = .current
        case .availability: availableOnly = false
        case .favorites: favoritesOnly = false
        case .collection: collectionIDs = []
        case .imageSource: imageSources = []
        }
    }

    /// Widens a facet that is hiding matches. Ownership opens to All rather than
    /// returning to the Current owned default.
    mutating func widen(_ facet: SearchFacetKind) {
        if facet == .ownership { ownership = .all } else { reset(facet) }
    }

    mutating func resetAll() { self = SearchFilters() }
}

// MARK: - Index documents

/// Which kind of indexed field supplied a match. Drives ranking weight and the
/// matched-field provenance shown on each result.
enum SearchFieldRole: Int, Comparable, Hashable {
    case name, alias, keyword, detail, color, attribute, collection, favorite, retailer, note
    case linked, linkedColor, linkedCurrentName

    static func < (lhs: SearchFieldRole, rhs: SearchFieldRole) -> Bool { lhs.rawValue < rhs.rawValue }

    var weight: Double {
        switch self {
        case .name: 100
        case .alias: 95
        case .keyword: 75
        case .detail: 70
        case .color: 60
        case .attribute: 55
        case .collection: 50
        case .retailer: 50
        case .favorite: 45
        case .note: 40
        case .linked: 30
        case .linkedColor: 28
        case .linkedCurrentName: 25
        }
    }

    var isLinked: Bool {
        switch self {
        case .linked, .linkedColor, .linkedCurrentName: true
        default: false
        }
    }

    var isNameOrAlias: Bool { self == .name || self == .alias }
}

/// One normalized, reviewed field of a search document.
struct SearchField: Hashable {
    let role: SearchFieldRole
    /// Original display text.
    let text: String
    /// Human-readable source, completing "Matched …".
    let provenance: String
    /// Confirmed or captured colour family, for the labelled related-shade expansion.
    let colorFamily: ColorFamily?
    let normalized: String
    let tokens: [String]
    let stems: [String]
    /// Tokens without stopwords, joined — used for whole-name equality.
    let contentKey: String

    init(role: SearchFieldRole, text: String, provenance: String, colorFamily: ColorFamily? = nil) {
        self.role = role
        self.text = text
        self.provenance = provenance
        self.colorFamily = colorFamily
        let normalized = SearchText.normalize(text)
        self.normalized = normalized
        let tokens = SearchText.tokens(normalized)
        self.tokens = tokens
        self.stems = tokens.map(SearchText.stem)
        self.contentKey = tokens.filter { !SearchVocabulary.stopwords.contains($0) }.joined(separator: " ")
    }
}

struct SearchOwnershipFacts: Hashable {
    var isCurrentlyOwned: Bool
    var isWishlisted: Bool

    func passes(_ scope: SearchOwnershipScope) -> Bool {
        switch scope {
        case .current: isCurrentlyOwned
        case .all: true
        case .wishlist: isWishlisted
        }
    }
}

/// Facet values of one document, derived from canonical records (current state for
/// garments; captured composition plus current piece status for looks/previews).
struct SearchFacetValues: Hashable {
    var categories: Set<GarmentCategory> = []
    var colorFamilies: Set<ColorFamily> = []
    var ownership: SearchOwnershipFacts?
    var isAvailableNow = false
    var isFavorite = false
    var collectionIDs: Set<String> = []
    var imageSources: Set<SearchImageSource> = []
    /// False for a garment outside the selected suitcase source.
    var inWorkingSource = true
}

/// A rebuildable derivative of one canonical record. Never the source of truth.
struct SearchDocument: Identifiable, Hashable {
    let type: SearchResultType
    let sourceID: String
    let title: String
    let fields: [SearchField]
    let facets: SearchFacetValues

    var id: String { "\(type.rawValue)-\(sourceID)" }
}

// MARK: - Index input and builder

/// Plain-value input for the index builder so building and querying stay pure and testable.
struct SearchIndexInput {
    var garments: [Garment] = []
    var outfits: [Outfit] = []
    var previews: [PreviewEntry] = []
    var collections: [OutfitCollection] = []
    var savedProducts: [SavedProductReference] = []
    /// Garment IDs in the selected suitcase; `nil` means Main Closet (everything).
    var workingSourceMembers: Set<String>?
    /// Current Main Closet eligibility issues per garment, resolved by `DemoStore`.
    var currentIssues: [String: [EligibilityIssue]] = [:]

    init() {}

    /// Reads canonical state from the store. Reading never mutates or dispatches.
    init(store: DemoStore, workingScope: WardrobeScope) {
        garments = store.garments
        outfits = store.outfits.filter(\.isSaved)
        previews = store.previews
        collections = store.collections
        savedProducts = store.savedProducts
        if let suitcaseID = workingScope.suitcaseID {
            workingSourceMembers = store.memberIDs(of: suitcaseID)
        }
        var issues: [String: [EligibilityIssue]] = [:]
        for garment in store.garments {
            issues[garment.id] = store.eligibility(of: garment, scope: .mainCloset).issues
        }
        currentIssues = issues
    }
}

enum SearchIndexBuilder {
    /// Versioned so a future vocabulary/schema change can trigger a rebuild.
    static let schemaVersion = 1

    static func documents(from input: SearchIndexInput) -> [SearchDocument] {
        let garmentsByID = Dictionary(input.garments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var docs: [SearchDocument] = []
        for garment in input.garments where !garment.isTrashed {
            docs.append(garmentDocument(garment, input: input))
        }
        for outfit in input.outfits {
            docs.append(outfitDocument(outfit, input: input, garmentsByID: garmentsByID))
        }
        for preview in input.previews {
            docs.append(previewDocument(preview, input: input, garmentsByID: garmentsByID))
        }
        for product in input.savedProducts {
            docs.append(productDocument(product))
        }
        return docs
    }

    static func garmentDocument(_ g: Garment, input: SearchIndexInput) -> SearchDocument {
        var fields: [SearchField] = [
            SearchField(role: .name, text: g.displayName, provenance: "name “\(g.displayName)”"),
        ]
        for alias in g.aliases {
            fields.append(SearchField(role: .alias, text: alias.text, provenance: "other name “\(alias.text)”"))
        }
        for detail in g.details {
            fields.append(SearchField(role: .detail, text: detail.text, provenance: "detail “\(detail.text)”"))
        }
        if g.category != .unknown {
            fields.append(SearchField(role: .attribute, text: g.category.label, provenance: "category \(g.category.label)"))
        }
        if g.kind != .unknown {
            fields.append(SearchField(role: .attribute, text: g.kind.label, provenance: "type \(g.kind.label)"))
        }
        if let color = g.color {
            fields.append(SearchField(role: .color, text: color.name, provenance: "confirmed color \(color.name)"))
            fields.append(SearchField(role: .color, text: color.family.label, provenance: "color family \(color.family.label)", colorFamily: color.family))
        }
        if let brand = g.brand, !brand.isEmpty {
            fields.append(SearchField(role: .attribute, text: brand, provenance: "brand \(brand)"))
        }
        if !g.notes.isEmpty {
            fields.append(SearchField(role: .note, text: g.notes, provenance: "your note"))
        }

        var facets = SearchFacetValues()
        facets.categories = [g.category]
        if let color = g.color { facets.colorFamilies = [color.family] }
        facets.ownership = SearchOwnershipFacts(isCurrentlyOwned: g.isCurrentlyOwned, isWishlisted: g.ownership == .wishlisted)
        facets.isAvailableNow = (input.currentIssues[g.id] ?? []).isEmpty
        facets.imageSources = [g.photoFilename != nil || g.imageKind == .actualPhoto ? .yourPhoto : .representative]
        facets.inWorkingSource = input.workingSourceMembers?.contains(g.id) ?? true
        return SearchDocument(type: .garment, sourceID: g.id, title: g.displayName, fields: fields, facets: facets)
    }

    static func outfitDocument(_ o: Outfit, input: SearchIndexInput, garmentsByID: [String: Garment]) -> SearchDocument {
        var fields: [SearchField] = [
            SearchField(role: .name, text: o.title, provenance: "look title “\(o.title)”"),
        ]
        for keyword in o.keywords {
            fields.append(SearchField(role: .keyword, text: keyword, provenance: "keyword “\(keyword)”"))
        }
        if !o.notes.isEmpty {
            fields.append(SearchField(role: .note, text: o.notes, provenance: "your note"))
        }
        if let occasion = o.occasion {
            fields.append(SearchField(role: .attribute, text: occasion.label, provenance: "occasion \(occasion.label)"))
        }
        fields += pieceFields(o.pieces, captured: "linked garment", garmentsByID: garmentsByID)
        let collections = input.collections.filter { $0.outfitIDs.contains(o.id) }
        for c in collections {
            fields.append(SearchField(role: .collection, text: c.name, provenance: "collection \(c.name)"))
        }
        if o.isFavorite {
            fields.append(SearchField(role: .favorite, text: "favorite", provenance: "Favorite"))
        }

        var facets = pieceFacets(o.pieces, input: input)
        facets.isFavorite = o.isFavorite
        facets.collectionIDs = Set(collections.map(\.id))
        return SearchDocument(type: .outfit, sourceID: o.id, title: o.title, fields: fields, facets: facets)
    }

    static func previewDocument(_ p: PreviewEntry, input: SearchIndexInput, garmentsByID: [String: Garment]) -> SearchDocument {
        var fields: [SearchField] = [
            SearchField(role: .name, text: p.title, provenance: "preview title “\(p.title)”"),
        ]
        for keyword in p.keywords {
            fields.append(SearchField(role: .keyword, text: keyword, provenance: "preview keyword “\(keyword)” (from the captured outfit)"))
        }
        if let occasion = p.occasion {
            fields.append(SearchField(role: .attribute, text: occasion.label, provenance: "occasion \(occasion.label)"))
        }
        fields.append(SearchField(role: .attribute, text: p.quality.label, provenance: "quality label “\(p.quality.label)”"))
        fields += pieceFields(p.snapshotPieces, captured: "captured piece", garmentsByID: garmentsByID)
        let collections = input.collections.filter { $0.previewIDs.contains(p.id) }
        for c in collections {
            fields.append(SearchField(role: .collection, text: c.name, provenance: "collection \(c.name)"))
        }
        if p.isFavorite {
            fields.append(SearchField(role: .favorite, text: "favorite", provenance: "Favorite"))
        }

        var facets = pieceFacets(p.snapshotPieces, input: input)
        facets.isFavorite = p.isFavorite
        facets.collectionIDs = Set(collections.map(\.id))
        facets.imageSources = [.simulatedPreview]
        return SearchDocument(type: .preview, sourceID: p.id, title: p.title, fields: fields, facets: facets)
    }

    static func productDocument(_ ref: SavedProductReference) -> SearchDocument {
        let c = ref.candidate
        var fields: [SearchField] = [
            SearchField(role: .name, text: c.title, provenance: "product title “\(c.title)”"),
            SearchField(role: .retailer, text: c.retailer, provenance: "retailer \(c.retailer)"),
            SearchField(role: .color, text: c.colorName, provenance: "listed color \(c.colorName)"),
        ]
        if c.kind != .unknown {
            fields.append(SearchField(role: .attribute, text: c.kind.label, provenance: "type \(c.kind.label)"))
        }
        var facets = SearchFacetValues()
        facets.categories = [c.kind.defaultCategory]
        let colorTokens = Set(SearchText.tokens(SearchText.normalize(c.colorName)).map(SearchText.stem))
        facets.colorFamilies = Set(ColorFamily.allCases.filter { family in
            colorTokens.contains(SearchText.stem(SearchText.normalize(family.label)))
        })
        return SearchDocument(type: .product, sourceID: ref.id, title: c.title, fields: fields, facets: facets)
    }

    /// Captured piece names/colours/types, plus clearly labelled current names of linked garments.
    private static func pieceFields(_ pieces: [OutfitPiece], captured: String, garmentsByID: [String: Garment]) -> [SearchField] {
        var fields: [SearchField] = []
        for piece in pieces.sorted(by: { $0.slot.sortOrder < $1.slot.sortOrder }) {
            let name = piece.capturedName
            fields.append(SearchField(role: .linked, text: name, provenance: "\(captured) \(name)"))
            if piece.capturedKind != .unknown {
                fields.append(SearchField(role: .linked, text: piece.capturedKind.label, provenance: "\(captured) type \(piece.capturedKind.label) (\(name))"))
            }
            if let color = piece.capturedColor {
                fields.append(SearchField(role: .linkedColor, text: color.name, provenance: "\(captured) color \(color.name) (\(name))"))
                fields.append(SearchField(role: .linkedColor, text: color.family.label, provenance: "\(captured) color family \(color.family.label) (\(name))", colorFamily: color.family))
            }
            if let id = piece.garmentID, let current = garmentsByID[id], !current.isTrashed {
                if current.displayName.caseInsensitiveCompare(name) != .orderedSame {
                    fields.append(SearchField(role: .linkedCurrentName, text: current.displayName, provenance: "current name of linked garment “\(current.displayName)”"))
                }
                for alias in current.aliases {
                    fields.append(SearchField(role: .linkedCurrentName, text: alias.text, provenance: "linked garment’s other name “\(alias.text)” (\(current.displayName))"))
                }
            }
        }
        return fields
    }

    private static func pieceFacets(_ pieces: [OutfitPiece], input: SearchIndexInput) -> SearchFacetValues {
        var facets = SearchFacetValues()
        facets.categories = Set(pieces.map(\.slot.category))
        facets.colorFamilies = Set(pieces.compactMap { $0.capturedColor?.family })
        facets.imageSources = Set(pieces.map { $0.capturedImageKind == .actualPhoto ? SearchImageSource.yourPhoto : .representative })
        facets.isAvailableNow = !pieces.isEmpty && pieces.allSatisfy { piece in
            guard !piece.isHypothetical, let id = piece.garmentID, let issues = input.currentIssues[id] else { return false }
            return issues.isEmpty
        }
        return facets
    }
}
