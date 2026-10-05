import SwiftUI

// MARK: - Segments, filters and selection (UI state vocabulary)

/// The four views inside Saved. Collections are a segment, never extra top-level tabs.
enum SavedSegment: String, CaseIterable, Identifiable, Hashable {
    case allLooks, previewHistory, favorites, collections

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allLooks: "All Looks"
        case .previewHistory: "Preview History"
        case .favorites: "Favorites"
        case .collections: "Collections"
        }
    }

    /// Shorter label used when the full segmented control doesn't fit.
    var shortTitle: String {
        switch self {
        case .allLooks: "Looks"
        case .previewHistory: "History"
        case .favorites: "Favorites"
        case .collections: "Collections"
        }
    }

    var systemImage: String {
        switch self {
        case .allLooks: "square.grid.2x2"
        case .previewHistory: "clock.arrow.circlepath"
        case .favorites: "star"
        case .collections: "folder"
        }
    }
}

/// Status filter for Preview History. Combines with the captured-source filter.
enum SavedPreviewStatusFilter: String, CaseIterable, Identifiable, Hashable {
    case all, favorites, disliked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .favorites: "Favorites"
        case .disliked: "Disliked"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.stack"
        case .favorites: "star"
        case .disliked: "hand.thumbsdown"
        }
    }
}

/// What the wide layout shows beside the list/grid.
enum SavedSelection: Hashable {
    case outfit(String)
    case preview(String)
    case collection(String)
}

/// A pending collection name prompt. `presenter` identifies which on-screen view owns the
/// alert, so two visible panes never try to present the same prompt.
struct SavedNamingRequest: Hashable {
    enum Kind: Hashable {
        case create(addOutfitID: String?, addPreviewID: String?)
        case rename(collectionID: String)
    }

    var kind: Kind
    var presenter: String
}

/// Records which Saved screen pushed a Saved detail (see `AppModel.savedPush`).
struct SavedPushOrigin: Hashable {
    var origin: AppRoute
    var pushed: AppRoute
}

// MARK: - Captured source (provenance, not today's membership)

enum SavedProvenance {
    /// "From Weekend", "Former suitcase (Weekend)", "From Main Closet" or "Source unknown".
    static func label(scope: WardrobeScope?, name: String?) -> String {
        if let name, !name.isEmpty {
            return name.hasPrefix("Former suitcase") ? name : "From \(name)"
        }
        switch scope {
        case .none: return "Source unknown"
        case .mainCloset: return "From Main Closet"
        case .suitcase: return "From a suitcase (name not recorded)"
        }
    }

    /// Source name without the "From" prefix, for filters and info rows.
    static func plainName(scope: WardrobeScope?, name: String?) -> String {
        if let name, !name.isEmpty { return name }
        switch scope {
        case .none: return "Source unknown"
        case .mainCloset: return "Main Closet"
        case .suitcase: return "Suitcase (name not recorded)"
        }
    }

    static func systemImage(scope: WardrobeScope?) -> String {
        switch scope {
        case .none: "questionmark.circle"
        case .mainCloset: "cabinet"
        case .suitcase: "suitcase"
        }
    }

    /// Stable filter key built from the captured scope identity.
    static func key(_ scope: WardrobeScope?) -> String {
        switch scope {
        case .none: "unknown"
        case .mainCloset: "main"
        case let .suitcase(id): "suitcase:\(id)"
        }
    }
}

/// One captured-source filter option for Preview History.
struct SavedSourceOption: Identifiable, Hashable {
    var key: String
    var label: String
    var systemImage: String
    var count: Int

    var id: String { key }

    /// Options derived from the previews' captured provenance (newest name wins).
    static func options(for previews: [PreviewEntry]) -> [SavedSourceOption] {
        var order: [String] = []
        var byKey: [String: SavedSourceOption] = [:]
        for preview in previews.sorted(by: { $0.createdAt > $1.createdAt }) {
            let key = SavedProvenance.key(preview.capturedScope)
            if var existing = byKey[key] {
                existing.count += 1
                byKey[key] = existing
            } else {
                order.append(key)
                byKey[key] = SavedSourceOption(
                    key: key,
                    label: SavedProvenance.plainName(scope: preview.capturedScope, name: preview.capturedScopeName),
                    systemImage: SavedProvenance.systemImage(scope: preview.capturedScope),
                    count: 1
                )
            }
        }
        return order.compactMap { byKey[$0] }.sorted { a, b in
            if a.key == "main" { return true }
            if b.key == "main" { return false }
            if a.key == "unknown" { return false }
            if b.key == "unknown" { return true }
            return a.label < b.label
        }
    }
}

// MARK: - Current status (resolved from canonical records; the saved look is never changed)

enum SavedLookStatus {
    /// Today's badges for one saved/captured piece.
    static func badges(for piece: OutfitPiece, in store: DemoStore) -> [BadgeKind] {
        guard piece.garmentID != nil else { return [] }
        if store.isMissing(piece) { return [.missing] }
        return (store.currentIssues(for: piece) ?? []).map(BadgeKind.from)
    }

    /// Today's badges including the hypothetical marker (for views that don't add it themselves).
    static func todayBadges(for piece: OutfitPiece, in store: DemoStore) -> [BadgeKind] {
        piece.isHypothetical ? [.unowned] + badges(for: piece, in: store) : badges(for: piece, in: store)
    }

    struct Item: Hashable, Identifiable {
        var text: String
        var systemImage: String
        var tone: BadgeKind.Tone
        var id: String { text }
    }

    private enum Bucket: Int, CaseIterable {
        case missing, noLongerOwned, trashed, notOwned, notArrived, arrivalUnknown, dirty, unavailable, archived, idea

        init?(_ issue: EligibilityIssue) {
            switch issue {
            case .dirty: self = .dirty
            case .unavailable: self = .unavailable
            case .archived: self = .archived
            case .notArrived: self = .notArrived
            case .arrivalUnknown: self = .arrivalUnknown
            case .noLongerOwned: self = .noLongerOwned
            case .notOwned: self = .notOwned
            case .trashed: self = .trashed
            case .outsideSource: return nil
            }
        }

        var badge: BadgeKind {
            switch self {
            case .missing: .missing
            case .noLongerOwned: .noLongerOwned
            case .trashed: .trash
            case .notOwned: .notOwned
            case .notArrived: .notArrived
            case .arrivalUnknown: .arrivalUnknown
            case .dirty: .dirty
            case .unavailable: .unavailable
            case .archived: .archived
            case .idea: .unowned
            }
        }

        func text(count n: Int) -> String {
            switch self {
            case .missing: return n == 1 ? "Missing piece" : "\(n) missing pieces"
            case .noLongerOwned: return n == 1 ? "No longer owned piece" : "\(n) no-longer-owned pieces"
            case .idea: return n == 1 ? "New-piece idea" : "\(n) new-piece ideas"
            default: return "\(n) \(n == 1 ? "piece" : "pieces") \(badge.text)"
            }
        }
    }

    /// Compact summary such as "1 piece Dirty", "No longer owned piece", "Missing piece".
    static func summary(for pieces: [OutfitPiece], in store: DemoStore) -> [Item] {
        var counts: [Bucket: Int] = [:]
        for piece in pieces {
            if piece.isHypothetical && piece.garmentID == nil {
                counts[.idea, default: 0] += 1
                continue
            }
            guard piece.garmentID != nil else { continue }
            if store.isMissing(piece) {
                counts[.missing, default: 0] += 1
                continue
            }
            for issue in store.currentIssues(for: piece) ?? [] {
                if let bucket = Bucket(issue) { counts[bucket, default: 0] += 1 }
            }
        }
        return Bucket.allCases.compactMap { bucket in
            guard let n = counts[bucket], n > 0 else { return nil }
            return Item(text: bucket.text(count: n), systemImage: bucket.badge.systemImage, tone: bucket.badge.tone)
        }
    }
}

// MARK: - Retained preview version labels

/// Whether a retained picture shows the look's current pieces or an earlier version.
enum SavedPreviewVersion: Hashable {
    case current
    case earlierComposition
    case earlierReference
    case earlierAppearance
    case lookNotSaved

    var isEarlier: Bool { self == .earlierComposition || self == .earlierReference || self == .earlierAppearance }

    var label: String {
        switch self {
        case .current: "Current version"
        case .earlierComposition: "Earlier version of this look"
        case .earlierReference: "Made with an earlier reference photo"
        case .earlierAppearance: "Made before a garment's photo changed"
        case .lookNotSaved: "Look not in Saved"
        }
    }

    var shortLabel: String {
        switch self {
        case .current: "Current"
        case .earlierComposition, .earlierReference, .earlierAppearance: "Earlier"
        case .lookNotSaved: "Not in Saved"
        }
    }

    static func compositionKey(_ pieces: [OutfitPiece]) -> [String] {
        pieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }
            .map { "\($0.slot.rawValue):\($0.garmentID ?? "idea-\($0.capturedName)")" }
    }

    static func of(_ preview: PreviewEntry, in store: DemoStore) -> SavedPreviewVersion {
        if let currentReference = store.profile.onMeReference.version, preview.referenceVersion < currentReference {
            return .earlierReference
        }
        guard let outfit = store.outfit(preview.outfitID) else { return .lookNotSaved }
        guard compositionKey(outfit.pieces) == compositionKey(preview.snapshotPieces) else { return .earlierComposition }
        // Same pieces, but a garment's photo/appearance changed after the picture was made.
        let rendered = renderedAppearanceRevisions(preview.renderKey)
        let changed = preview.snapshotPieces.contains { piece in
            guard let id = piece.garmentID, let garment = store.garment(id), let then = rendered[id] else { return false }
            return garment.appearanceRevision != then
        }
        return changed ? .earlierAppearance : .current
    }

    /// Garment appearance revisions recorded in a render key ("slot:id@rev|...#refN").
    static func renderedAppearanceRevisions(_ renderKey: String) -> [String: Int] {
        let body = renderKey.split(separator: "#").first.map(String.init) ?? ""
        var result: [String: Int] = [:]
        for part in body.split(separator: "|") {
            guard let colon = part.firstIndex(of: ":"), let at = part.lastIndex(of: "@"), colon < at,
                  let rev = Int(part[part.index(after: at)...]) else { continue }
            result[String(part[part.index(after: colon)..<at])] = rev
        }
        return result
    }

    /// Badges shown on a picture card or detail (the figure itself carries "Simulated").
    static func badges(for preview: PreviewEntry, version: SavedPreviewVersion) -> [BadgeKind] {
        var badges: [BadgeKind] = []
        if version.isEarlier { badges.append(.earlier) }
        switch preview.quality {
        case .ok: break
        case .approximate: badges.append(.approximate)
        case .appearanceMismatch: badges.append(.mismatch)
        }
        if preview.isFavorite { badges.append(.favorite) }
        if preview.isDisliked { badges.append(.disliked) }
        return badges
    }
}

// MARK: - "Where could I wear this?" (local, from saved garment details)

struct SavedWearSuggestion {
    var occasions: [Occasion]
    var formalityText: String?
    var seasonText: String?
    var warmthText: String?
    var weatherText: String?
    var skippedPieces: Int

    /// Local suggestion from the pieces' saved formality, seasons and warmth. No service is called.
    static func make(for outfit: Outfit, store: DemoStore, weather: WeatherSnapshot?) -> SavedWearSuggestion {
        let garments = outfit.pieces.compactMap { store.garment($0.garmentID) }
        let skipped = outfit.pieces.count - garments.count
        guard !garments.isEmpty else {
            return SavedWearSuggestion(occasions: [], skippedPieces: skipped)
        }
        let levels = garments.map(\.formality.rawValue)
        let low = levels.min() ?? 1
        let high = levels.max() ?? 1
        let typical = Int((Double(levels.reduce(0, +)) / Double(levels.count)).rounded())
        let occasions = Occasion.allCases
            .filter { $0 != .other && $0.formalityRange.contains(low) && $0.formalityRange.contains(high) }
            .sorted { a, b in
                let da = abs(a.preferredFormality.rawValue - typical)
                let db = abs(b.preferredFormality.rawValue - typical)
                if da != db { return da < db }
                return (Occasion.allCases.firstIndex(of: a) ?? 0) < (Occasion.allCases.firstIndex(of: b) ?? 0)
            }

        let lowLabel = Formality(rawValue: low)?.label ?? "Smart"
        let highLabel = Formality(rawValue: high)?.label ?? "Smart"
        let formality = low == high ? "All pieces are saved as \(lowLabel.lowercased())." : "Pieces range from \(lowLabel.lowercased()) to \(highLabel.lowercased())."

        let shared = garments.reduce(Set(Season.allCases)) { $0.intersection($1.seasons) }
        let seasonText: String
        if shared.count == Season.allCases.count {
            seasonText = "Saved as fine for any season."
        } else if shared.isEmpty {
            seasonText = "The pieces don't share a saved season."
        } else {
            let names = Season.allCases.filter { shared.contains($0) }.map(\.label)
            seasonText = "Best in \(ListFormatter.localizedString(byJoining: names))."
        }

        let warmText = garments.contains { $0.warmth >= 2 } ? "Includes a warmer piece — good for cooler days." : nil

        var weatherText: String?
        if let weather {
            let hasLayer = outfit.pieces.contains { $0.slot == .layer }
            // Only weather that's already loaded; an older reading is labeled as such, never as today's.
            let when = Calendar.current.isDateInToday(weather.fetchedAt)
                ? "Today"
                : "Weather from \(weather.fetchedAt.formatted(date: .abbreviated, time: .omitted))"
            switch weather.source {
            case .seasonOnly:
                // No forecast: the season is the only real evidence, so no temperature is shown.
                weatherText = "Forecast unavailable — it's \(weather.season.label.lowercased()) season."
            case .manual, .simulatedForecast:
                let source = weather.source == .manual ? "set by you" : "simulated"
                if weather.needsLayer {
                    weatherText = hasLayer
                        ? "\(when) (\(source)): \(weather.summary). It already has a layer."
                        : "\(when) (\(source)): \(weather.summary). You may want a layer."
                } else {
                    weatherText = "\(when) (\(source)): \(weather.summary)."
                }
            }
        }

        return SavedWearSuggestion(occasions: occasions, formalityText: formality, seasonText: seasonText,
                                   warmthText: warmText, weatherText: weatherText, skippedPieces: skipped)
    }
}

// MARK: - Store helpers (tags and wear log)

extension DemoStore {
    /// Editable occasion tag. Organization metadata only: no revision bump, so retained
    /// pictures keep their current/earlier labels and render identity.
    func savedSetOccasion(_ occasion: Occasion?, outfitID: String) {
        guard let i = outfits.firstIndex(where: { $0.id == outfitID }) else { return }
        outfits[i].occasion = occasion
        commit(inventoryChanged: false)
    }

    /// Editable intended-date tag (nil clears it). Organization metadata only.
    func savedSetIntendedDate(_ date: Date?, outfitID: String) {
        guard let i = outfits.firstIndex(where: { $0.id == outfitID }) else { return }
        outfits[i].intendedDate = date
        commit(inventoryChanged: false)
    }

    /// Undo for the quiet wear log: removes exactly the logged date. Laundry is untouched.
    func savedRemoveWornDate(_ date: Date, outfitID: String) {
        guard let i = outfits.firstIndex(where: { $0.id == outfitID }),
              let j = outfits[i].wornDates.lastIndex(of: date) else { return }
        outfits[i].wornDates.remove(at: j)
        commit(inventoryChanged: false)
    }
}

extension AppModel {
    /// Keeps an open editor draft for this saved look in step with metadata changed from Saved
    /// (favorite, tags, wear log), so a later editor Save doesn't restore stale values.
    /// Pieces, title and notes are never touched.
    func savedSyncEditorMetadata(outfitID: String) {
        guard let editor, case let .saved(id) = editor.origin, id == outfitID, let stored = store.outfit(outfitID) else { return }
        let keyPaths: [ReferenceWritableKeyPath<OutfitEditorSession, Outfit>] = [\.outfit, \.baseOutfit]
        for keyPath in keyPaths {
            editor[keyPath: keyPath].isFavorite = stored.isFavorite
            editor[keyPath: keyPath].occasion = stored.occasion
            editor[keyPath: keyPath].intendedDate = stored.intendedDate
            editor[keyPath: keyPath].wornDates = stored.wornDates
        }
    }

    /// Pushes a Saved detail from another Saved screen (`origin`). When the screen directly
    /// underneath the current one is already `route` (look → picture → "Open related look"),
    /// it pops back to it instead of stacking a duplicate.
    func savedPush(_ route: AppRoute, from origin: AppRoute) {
        let target = section
        let depth = paths[target]?.count ?? 0
        if depth > 0, let entry = savedUI.pushOrigins["\(target.rawValue)#\(depth)"],
           entry.pushed == origin, entry.origin == route, var path = paths[target] {
            path.removeLast()
            paths[target] = path
            savedUI.pushOrigins["\(target.rawValue)#\(depth)"] = nil
            return
        }
        // Drop records for deeper screens that are no longer on this stack.
        let prefix = "\(target.rawValue)#"
        for key in savedUI.pushOrigins.keys where key.hasPrefix(prefix) {
            if let d = Int(key.dropFirst(prefix.count)), d > depth { savedUI.pushOrigins[key] = nil }
        }
        push(route)
        savedUI.pushOrigins["\(target.rawValue)#\(depth + 1)"] = SavedPushOrigin(origin: origin, pushed: route)
    }

    /// Clears a wide-layout selection that points at a deleted record.
    func savedClearSelection(_ selection: SavedSelection) {
        for (segment, value) in savedUI.selections where value == selection {
            savedUI.selections[segment] = nil
        }
    }
}

// MARK: - Small shared views

/// Wrapping row of counted status summaries, or a quiet all-clear line.
struct SavedStatusSummaryRow: View {
    var items: [SavedLookStatus.Item]
    var showsAllClear = true

    var body: some View {
        if items.isEmpty {
            if showsAllClear {
                Label("All pieces available", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(Palette.success)
            }
        } else {
            FlowLayout(spacing: Spacing.xxs) {
                ForEach(items) { item in
                    ToneBadge(text: item.text, systemImage: item.systemImage, tone: item.tone)
                }
            }
        }
    }

    static func accessibilityText(_ items: [SavedLookStatus.Item]) -> String {
        items.isEmpty ? "All pieces available" : items.map(\.text).joined(separator: ", ")
    }
}

/// Section container used across the Saved screens.
struct SavedSectionCard<Content: View>: View {
    var title: String?
    var subtitle: String?
    /// How-it-works text shown from an info button beside the title.
    var info: String?
    @ViewBuilder var content: () -> Content

    init(_ title: String? = nil, subtitle: String? = nil, info: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.info = info
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if let title {
                SectionHeader(title, subtitle: subtitle, info: info)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// Screen chrome for a detail view: full screen when pushed, plain when embedded in a pane.
struct SavedDetailChrome: ViewModifier {
    var title: String
    var embedded: Bool

    func body(content: Content) -> some View {
        if embedded {
            content.background(Palette.background)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .themedScreenBackground()
        }
    }
}

/// Create / rename collection prompt, owned by one presenter at a time.
struct SavedNamingAlert: ViewModifier {
    @Environment(AppModel.self) private var app
    var presenter: String

    func body(content: Content) -> some View {
        @Bindable var ui = app.savedUI
        let isPresented = Binding<Bool>(
            get: { ui.naming?.presenter == presenter },
            set: { if !$0, ui.naming?.presenter == presenter { ui.naming = nil } }
        )
        content.alert(title, isPresented: isPresented) {
            TextField("Collection name", text: $ui.nameDraft)
                .textInputAutocapitalization(.words)
            Button(confirmTitle) { commit() }
            Button("Cancel", role: .cancel) { ui.naming = nil }
        } message: {
            Text(message)
        }
    }

    private var isRename: Bool {
        if case .rename = app.savedUI.naming?.kind { return true }
        return false
    }

    private var title: String { isRename ? "Rename collection" : "New collection" }
    private var confirmTitle: String { isRename ? "Rename" : "Create" }
    private var message: String {
        isRename
            ? "Only the name changes. Looks and pictures in it stay as they are."
            : "A private group such as Work, Gym or Going Out. A look can be in several collections."
    }

    private func commit() {
        let ui = app.savedUI
        guard let request = ui.naming else { return }
        ui.naming = nil
        let store = app.store
        let name = ui.nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            app.showToast("A collection needs a name — nothing was changed.", style: .info)
            return
        }
        let existing = store.collections.first { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
        switch request.kind {
        case let .create(outfitID, previewID):
            if let existing {
                if let outfitID, !existing.outfitIDs.contains(outfitID) { store.toggleOutfit(outfitID, inCollection: existing.id) }
                if let previewID, !existing.previewIDs.contains(previewID) { store.togglePreview(previewID, inCollection: existing.id) }
                let added = outfitID != nil || previewID != nil
                app.showToast(added ? "You already have “\(existing.name)” — added it there." : "You already have a collection called “\(existing.name)”.", style: .info)
                return
            }
            let created = store.createCollection(named: name)
            if let outfitID { store.toggleOutfit(outfitID, inCollection: created.id) }
            if let previewID { store.togglePreview(previewID, inCollection: created.id) }
            let suffix = outfitID != nil ? " and added this look" : (previewID != nil ? " and added this picture" : "")
            app.showToast("Created “\(name)”\(suffix).")
        case let .rename(collectionID):
            if let existing, existing.id != collectionID {
                app.showToast("You already have a collection called “\(existing.name)”. Pick another name.", style: .info)
                return
            }
            store.renameCollection(collectionID, to: name)
            app.showToast("Renamed to “\(name)”.")
        }
        ui.nameDraft = ""
    }
}

extension View {
    func savedNamingAlert(presenter: String) -> some View {
        modifier(SavedNamingAlert(presenter: presenter))
    }

    func savedDetailChrome(title: String, embedded: Bool) -> some View {
        modifier(SavedDetailChrome(title: title, embedded: embedded))
    }
}

/// Collection membership toggles for a look or a picture (multi-select, membership only).
struct SavedCollectionToggles: View {
    enum Target: Hashable {
        case outfit(String)
        case preview(String)
    }

    @Environment(AppModel.self) private var app
    var target: Target
    var presenter: String

    var body: some View {
        let store = app.store
        let collections = store.collections.sorted { $0.createdAt < $1.createdAt }
        let memberCount = collections.filter(isMember).count
        SavedSectionCard("Collections", subtitle: memberCount == 0 ? "Not in any yet" : "In \(memberCount)", info: info) {
            ChipCarousel(isExpanded: app.savedUI.disclosure("collectionChips-\(presenter)"), itemsLabel: "collections") {
                ForEach(collections) { collection in
                    let member = isMember(collection)
                    CapsuleChip(title: collection.name, systemImage: "folder", isSelected: member) {
                        toggle(collection, wasMember: member)
                    }
                    .accessibilityHint(member ? "Removes from \(collection.name). Nothing is deleted." : "Adds to \(collection.name)")
                    .accessibilityIdentifier("collectionToggle-\(collection.id)")
                }
                CapsuleChip(title: "New collection", systemImage: "plus", isSelected: false) {
                    app.savedUI.nameDraft = ""
                    switch target {
                    case let .outfit(id): app.savedUI.naming = SavedNamingRequest(kind: .create(addOutfitID: id, addPreviewID: nil), presenter: presenter)
                    case let .preview(id): app.savedUI.naming = SavedNamingRequest(kind: .create(addOutfitID: nil, addPreviewID: id), presenter: presenter)
                    }
                }
                .accessibilityIdentifier("newCollectionFromDetailButton")
            }
        }
    }

    private var info: String {
        switch target {
        case .outfit: "Tap to add or remove. A look can be in several; removing never deletes it."
        case .preview: "Tap to add or remove. Removing never deletes the picture."
        }
    }

    private func isMember(_ collection: OutfitCollection) -> Bool {
        switch target {
        case let .outfit(id): collection.outfitIDs.contains(id)
        case let .preview(id): collection.previewIDs.contains(id)
        }
    }

    private func toggle(_ collection: OutfitCollection, wasMember: Bool) {
        switch target {
        case let .outfit(id): app.store.toggleOutfit(id, inCollection: collection.id)
        case let .preview(id): app.store.togglePreview(id, inCollection: collection.id)
        }
        app.showToast(wasMember ? "Removed from “\(collection.name)” — nothing was deleted." : "Added to “\(collection.name)”.", style: wasMember ? .info : .success)
    }
}

/// Grid columns tuned for the available width and Dynamic Type.
enum SavedGrid {
    static func columns(width: CGFloat, accessibilitySize: Bool, compactMinimum: CGFloat = 150, regularMinimum: CGFloat = 190) -> [GridItem] {
        let minimum: CGFloat = accessibilitySize ? 280 : (width < 600 ? compactMinimum : regularMinimum)
        return [GridItem(.adaptive(minimum: minimum, maximum: 340), spacing: Spacing.m, alignment: .top)]
    }
}
