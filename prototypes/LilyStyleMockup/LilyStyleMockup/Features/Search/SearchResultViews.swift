import SwiftUI

// MARK: - Presentation helpers (read-only lookups of canonical records)

enum SearchPresentation {
    /// Type label that distinguishes actual photos, representative art, saved looks,
    /// simulated previews and saved products.
    static func typeBadge(for document: SearchDocument, store: DemoStore) -> BadgeKind {
        switch document.type {
        case .garment:
            if let g = store.garment(document.sourceID), g.photoFilename != nil || g.imageKind == .actualPhoto {
                return .custom("Actual garment photo (demo)", "camera")
            }
            return .custom("Representative garment", "photo.artframe")
        case .outfit: return .custom("Saved look", "bookmark")
        case .preview: return .custom("AI visual preview (simulated)", "flask")
        case .product: return .custom("Saved product", "bag")
        }
    }

    /// Current status resolved from canonical records. Historical looks keep their
    /// captured pieces; these badges describe each piece today.
    static func statusBadges(for document: SearchDocument, store: DemoStore) -> [BadgeKind] {
        switch document.type {
        case .garment:
            guard let g = store.garment(document.sourceID) else { return [.missing] }
            var badges = BadgeKind.status(for: g)
            if g.imageKind == .textOnly, g.photoFilename == nil { badges.append(.textOnly) }
            return badges
        case .outfit:
            guard let o = store.outfit(document.sourceID) else { return [.missing] }
            return pieceSummaryBadges(o.pieces, store: store) + (o.isFavorite ? [.favorite] : [])
        case .preview:
            guard let p = store.preview(document.sourceID) else { return [.missing] }
            var badges: [BadgeKind] = []
            if isEarlier(p, store: store) { badges.append(.earlier) }
            switch p.quality {
            case .ok: break
            case .approximate: badges.append(.approximate)
            case .appearanceMismatch: badges.append(.mismatch)
            }
            badges += pieceSummaryBadges(p.snapshotPieces, store: store)
            if p.isFavorite { badges.append(.favorite) }
            if p.isDisliked { badges.append(.disliked) }
            return badges
        case .product:
            return [.notOwned]
        }
    }

    /// Per-piece current badges for boards inside a look or preview.
    static func pieceBadges(_ piece: OutfitPiece, store: DemoStore) -> [BadgeKind] {
        guard !piece.isHypothetical, piece.garmentID != nil else { return [] }
        if store.isMissing(piece) { return [.missing] }
        return (store.currentIssues(for: piece) ?? []).map(BadgeKind.from)
    }

    /// Look-level summary: "Includes Dirty piece" etc. (text + icon, never colour alone).
    static func pieceSummaryBadges(_ pieces: [OutfitPiece], store: DemoStore) -> [BadgeKind] {
        var counts: [BadgeKind: Int] = [:]
        var order: [BadgeKind] = []
        for piece in pieces {
            let kinds: [BadgeKind] = piece.isHypothetical ? [.unowned] : pieceBadges(piece, store: store)
            for kind in kinds {
                if counts[kind] == nil { order.append(kind) }
                counts[kind, default: 0] += 1
            }
        }
        let priority: [BadgeKind] = [.missing, .noLongerOwned, .trash, .archived, .dirty, .unavailable, .notArrived, .arrivalUnknown, .unowned]
        let sorted = order.sorted { (priority.firstIndex(of: $0) ?? 99) < (priority.firstIndex(of: $1) ?? 99) }
        return sorted.map { kind in
            let n = counts[kind] ?? 1
            let text = n == 1 ? "Includes \(kind.text) piece" : "\(n) pieces \(kind.text)"
            return .custom(text, kind.systemImage)
        }
    }

    static func isEarlier(_ preview: PreviewEntry, store: DemoStore) -> Bool {
        guard let latest = store.previews(forOutfit: preview.outfitID).first else { return false }
        return latest.id != preview.id
    }

    /// One-line description under the title.
    static func subtitle(for document: SearchDocument, store: DemoStore) -> String {
        switch document.type {
        case .garment:
            guard let g = store.garment(document.sourceID) else { return "Missing item" }
            let category = g.category == .unknown ? "Category unknown" : g.kind == .unknown ? g.category.label : g.kind.label
            return "\(category) · \(g.colorLabel)"
        case .outfit:
            guard let o = store.outfit(document.sourceID) else { return "Missing look" }
            var parts = ["\(o.pieces.count) pieces"]
            if let occasion = o.occasion { parts.append(occasion.label) }
            parts.append("from \(o.capturedScopeName ?? "unknown source")")
            return parts.joined(separator: " · ")
        case .preview:
            guard let p = store.preview(document.sourceID) else { return "Missing preview" }
            return "Made \(p.createdAt.formatted(.relative(presentation: .named))) · from \(p.capturedScopeName ?? "unknown source")"
        case .product:
            guard let ref = store.savedProducts.first(where: { $0.id == document.sourceID }) else { return "Missing product" }
            return "\(ref.candidate.retailer) · \(ref.candidate.colorName)"
        }
    }

    static func openTitle(for type: SearchResultType) -> String {
        switch type {
        case .garment: "View item"
        case .outfit: "Open look"
        case .preview: "Open preview"
        case .product: "Open saved products"
        }
    }

    /// "Matched: pink, shirt · Not recorded: cute"
    static func possibleExplanation(_ hit: SearchHit) -> String {
        let matched = hit.matchedWords.joined(separator: ", ")
        if hit.unmatchedWords.isEmpty {
            return "Matched: \(matched) · found separately, not as your exact phrase"
        }
        let missing = hit.unmatchedWords.map { "“\($0)”" }.joined(separator: ", ")
        return "Matched: \(matched) · Not recorded: \(missing)"
    }
}

// MARK: - Results content

struct SearchResultsContent: View {
    var output: SearchOutput
    /// True when the selected result shows in a side pane (rows show selection, no chevron).
    var showsPane: Bool
    var onSelect: (SearchHit) -> Void
    var onOpen: (SearchHit) -> Void
    var onRefine: () -> Void
    var onExample: (String) -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            if output.isIdle {
                if !output.query.raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    InlineBanner(
                        style: .info,
                        title: "Add a word that describes it",
                        message: "Filler words like “with” and “the” are ignored, so there's nothing to search for yet."
                    )
                }
                SearchIdleView(onExample: onExample)
            } else {
                queryNotices
                if !output.primary.isEmpty { primarySection }
                if !output.relatedShade.isEmpty { relatedSection }
                if !output.possible.isEmpty { possibleSection }
                hiddenNotices
                if output.primary.isEmpty, output.relatedShade.isEmpty, output.possible.isEmpty {
                    SearchNoResultsView(
                        query: output.query,
                        isBrowsing: output.isBrowsing,
                        hasHiddenMatches: output.hiddenByFilters + output.hiddenBySource > 0,
                        onRefine: onRefine
                    )
                }
            }
        }
    }

    // MARK: Sections

    private var primarySection: some View {
        let ui = app.searchUI
        let visible = Array(output.primary.prefix(ui.visibleLimit))
        let remaining = output.primary.count - visible.count
        return VStack(alignment: .leading, spacing: Spacing.s) {
            if output.isBrowsing {
                SectionHeader("Filtered items", subtitle: "\(output.primary.count) match your filters")
            } else {
                SectionHeader("Results", subtitle: "\(output.primary.count) found · best matches first")
            }
            LazyVStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(visible) { row($0) }
            }
            .scrollTargetLayout()
            if remaining > 0 {
                Button {
                    withAnimation(reduceMotion ? nil : .default) { ui.visibleLimit += SearchUIState.pageSize }
                } label: {
                    Label("Show more (\(remaining) more)", systemImage: "chevron.down")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityIdentifier("searchShowMore")
            }
        }
    }

    @ViewBuilder private var relatedSection: some View {
        let ui = app.searchUI
        let expansion = relatedExpansionText
        if !output.primary.isEmpty, !ui.showRelatedShades {
            InlineBanner(
                style: .info,
                title: "\(output.relatedShade.count) more through related shades",
                message: "\(expansion) Confirmed colors stay as recorded.",
                actionTitle: "Show related shades",
                action: { withAnimation(reduceMotion ? nil : .default) { ui.showRelatedShades = true } },
                summary: "Confirmed colors stay as recorded.",
                isMessageExpanded: ui.disclosure("relatedShadesNote")
            )
        } else {
            VStack(alignment: .leading, spacing: Spacing.s) {
                SectionHeader(
                    "Related shades",
                    subtitle: "A broader color match",
                    info: "\(expansion) This is a broader color match — each item's confirmed color is unchanged."
                )
                LazyVStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(output.relatedShade) { row($0) }
                }
                .scrollTargetLayout()
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("relatedShadesSection")
        }
    }

    private var relatedExpansionText: String {
        var pairs: [String: Set<String>] = [:]
        for hit in output.relatedShade {
            for match in hit.matches where match.kind == .relatedShade {
                pairs[match.term, default: []].insert(match.matchedWord)
            }
        }
        let parts = pairs.keys.sorted().map { term in "“\(term)” → \(pairs[term]!.sorted().joined(separator: ", "))" }
        return parts.isEmpty ? "" : "Searched \(parts.joined(separator: "; "))."
    }

    private var possibleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(
                "Possible matches",
                subtitle: "Not confirmed. These match some of your words.",
                info: "Nothing matched every word. These match some of your words — they aren't confirmed matches, and they don't prove anything is missing from your closet."
            )
            LazyVStack(alignment: .leading, spacing: Spacing.s) {
                ForEach(output.possible) { row($0) }
            }
            .scrollTargetLayout()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("possibleMatchesSection")
    }

    private func row(_ hit: SearchHit) -> some View {
        SearchResultRow(
            hit: hit,
            isSelected: showsPane && app.searchUI.selectedResultID == hit.id,
            showsChevron: !showsPane,
            onSelect: { onSelect(hit) },
            onOpen: { onOpen(hit) }
        )
    }

    // MARK: Notices

    @ViewBuilder private var queryNotices: some View {
        let q = output.query
        if q.wasTruncated {
            InlineBanner(
                style: .caution,
                title: "Search used the first part of your text",
                message: "Up to \(SearchVocabulary.maxTerms) words and \(SearchVocabulary.maxPhrases) quoted phrases are searched, so results stay quick and predictable.",
                summary: "Only part of your text was searched.",
                isMessageExpanded: app.searchUI.disclosure("truncatedNote")
            )
        }
        if !output.phrasesNotFound.isEmpty {
            InlineBanner(
                style: .info,
                title: "No exact match for \(output.phrasesNotFound.map { "“\($0)”" }.joined(separator: ", "))",
                message: "No single name, note or keyword contains \(output.phrasesNotFound.map { "“\($0)”" }.joined(separator: ", ")). Quoted phrases match exactly inside one field — words from different pieces are never stitched together. Anything below is a broader, labelled alternative.",
                summary: "Anything below is a broader, labelled alternative.",
                isMessageExpanded: app.searchUI.disclosure("phraseNotFoundNote")
            )
        }
        if !q.negated.isEmpty || (!q.ignoredStopwords.isEmpty && q.hasContent) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if !q.negated.isEmpty {
                    Label("Leaving out: \(q.negated.joined(separator: ", "))", systemImage: "minus.circle")
                }
                if !q.ignoredStopwords.isEmpty, q.hasContent {
                    Label("Filler words ignored: \(q.ignoredStopwords.joined(separator: ", "))", systemImage: "text.badge.minus")
                }
            }
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder private var hiddenNotices: some View {
        let ui = app.searchUI
        if output.hiddenByFilters > 0 {
            let n = output.hiddenByFilters
            let reasons = output.hiddenReasons.map { reason -> String in
                reason == .ownership ? "Ownership (\(ui.filters.ownership.chipLabel))" : reason.label
            }
            InlineBanner(
                style: .info,
                title: "\(n) more \(n == 1 ? "match is" : "matches are") hidden by your filters",
                message: "Hidden by \(reasons.joined(separator: ", ")). Filters are never removed for you.",
                actionTitle: "Include them",
                action: {
                    for reason in output.hiddenReasons { ui.filters.widen(reason) }
                },
                summary: "Hidden by \(reasons.joined(separator: ", ")).",
                isMessageExpanded: ui.disclosure("hiddenByFilters")
            )
            .accessibilityIdentifier("searchHiddenByFilters")
        }
        if output.hiddenBySource > 0 {
            let n = output.hiddenBySource
            InlineBanner(
                style: .info,
                title: "\(n) more \(n == 1 ? "garment" : "garments") in Main Closet",
                message: "Garment search follows your selected source, \(app.workingScopeName). Switching is your choice and also changes the source Style Me uses.",
                actionTitle: "Search Main Closet",
                action: { app.selectScope(.mainCloset) },
                summary: "Switching also changes the source Style Me uses.",
                isMessageExpanded: ui.disclosure("hiddenBySource")
            )
            .accessibilityIdentifier("searchHiddenBySource")
        }
    }
}

// MARK: - Result row

struct SearchResultRow: View {
    var hit: SearchHit
    var isSelected: Bool
    var showsChevron: Bool
    var onSelect: () -> Void
    var onOpen: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let store = app.store
        let doc = hit.document
        let typeBadge = SearchPresentation.typeBadge(for: doc, store: store)
        let status = SearchPresentation.statusBadges(for: doc, store: store)
        let subtitle = SearchPresentation.subtitle(for: doc, store: store)
        let provenance = hit.provenanceLines
        let large = dynamicTypeSize.isAccessibilitySize
        let layout = large
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s))

        Button(action: onSelect) {
            layout {
                SearchResultThumbnail(document: doc, size: large ? 112 : 72)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(doc.title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    BadgeRow(badges: [typeBadge] + status)
                        .padding(.vertical, 2)
                    if hit.tier == .possible {
                        Label(SearchPresentation.possibleExplanation(hit), systemImage: "circle.lefthalf.filled")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // One reason on the row; the rest are in "Why it matched" when she selects it.
                    if let first = provenance.first {
                        Text(provenance.count > 1 ? "\(first) · +\(provenance.count - 1) more" : first)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsChevron, !large {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                        .padding(.top, Spacing.xxs)
                        .accessibilityHidden(true)
                }
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(isSelected ? Palette.accentSurface : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Palette.primaryAction : Palette.divider, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .contextMenu {
            Button { onOpen() } label: {
                Label(SearchPresentation.openTitle(for: doc.type), systemImage: "arrow.up.forward.app")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(typeBadge: typeBadge, subtitle: subtitle, status: status, provenance: provenance))
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityHint(showsChevron ? "Shows a preview with details and actions" : "Shows details beside the results")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: Text(SearchPresentation.openTitle(for: doc.type))) { onOpen() }
        .accessibilityIdentifier("searchResult-\(doc.type.rawValue)-\(doc.sourceID)")
    }

    private func accessibilityLabel(typeBadge: BadgeKind, subtitle: String, status: [BadgeKind], provenance: [String]) -> String {
        var parts = [typeBadge.text, hit.document.title, subtitle]
        if !status.isEmpty { parts.append(status.map(\.text).joined(separator: ", ")) }
        if hit.tier == .possible { parts.append("Possible match. " + SearchPresentation.possibleExplanation(hit)) }
        parts += provenance.prefix(3)
        return parts.joined(separator: ". ")
    }
}

// MARK: - Thumbnails

struct SearchResultThumbnail: View {
    var document: SearchDocument
    var size: CGFloat

    @Environment(AppModel.self) private var app

    var body: some View {
        content
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            .accessibilityHidden(true)
    }

    @ViewBuilder private var content: some View {
        let store = app.store
        switch document.type {
        case .garment:
            if let g = store.garment(document.sourceID) {
                GarmentThumbnail(garment: g, size: size, showsStatus: false)
            } else {
                missing
            }
        case .outfit:
            if let o = store.outfit(document.sourceID) {
                SearchMiniBoard(pieces: o.pieces, size: size)
            } else {
                missing
            }
        case .preview:
            if let p = store.preview(document.sourceID) {
                // Same picture stand-in Saved uses, so previews don't read as looks.
                SavedPreviewMiniThumb(pieces: p.snapshotPieces)
                    .frame(width: size, height: size)
                    .background(Palette.imageWell)
            } else {
                missing
            }
        case .product:
            if let ref = store.savedProducts.first(where: { $0.id == document.sourceID }) {
                GarmentArtwork(kind: ref.candidate.kind, hex: ref.candidate.colorHex)
                    .overlay(alignment: .bottomTrailing) { cornerIcon("bag") }
            } else {
                missing
            }
        }
    }

    private var missing: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell)
            Image(systemName: "questionmark.square.dashed")
                .font(.title2)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    private func cornerIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.caption2.weight(.bold))
            .foregroundStyle(Palette.primaryAction)
            .padding(4)
            .background(Circle().fill(Palette.surface))
            .padding(3)
    }
}

/// Small captured flat-lay for saved looks.
private struct SearchMiniBoard: View {
    var pieces: [OutfitPiece]
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell)
            OutfitFlatLayView(pieces: pieces, compact: true, animateIn: false)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Idle and empty states

struct SearchIdleView: View {
    var onExample: (String) -> Void

    @Environment(AppModel.self) private var app

    private static let tips: [(icon: String, text: String)] = [
        ("quote.opening", "Put words in quotes to find an exact phrase in one name, note or keyword."),
        ("minus.circle", "Put a minus before a word to leave it out, like top -lace."),
        ("text.badge.plus", "When search finds something your way, you can remember that name on the item."),
    ]

    var body: some View {
        let ui = app.searchUI
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader(
                "Search in your own words",
                subtitle: "Try one of these, or type your own.",
                info: "Finds names, other names, details, colors, brands and notes, plus saved looks, previews and saved products on this device.",
                editorial: true
            )
            ChipCarousel(isExpanded: ui.disclosure("exampleChips"), itemsLabel: "examples") {
                ForEach(Array(SearchScreen.examples.enumerated()), id: \.offset) { index, example in
                    SearchExampleChip(title: example) { onExample(example) }
                        .accessibilityLabel("Search for \(example)")
                        .accessibilityIdentifier("searchExample-\(index)")
                }
            }
            DetailsDisclosure(
                "Search tips",
                count: Self.tips.count,
                systemImage: "lightbulb",
                isExpanded: ui.disclosure("searchTips"),
                identifier: "searchTips"
            ) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Self.tips, id: \.text) { tip in
                        Label {
                            Text(tip.text)
                                .font(.footnote)
                                .foregroundStyle(Palette.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: tip.icon)
                                .foregroundStyle(Palette.primaryAction)
                        }
                    }
                }
            }
            .cardStyle(padding: Spacing.s)
        }
    }
}

/// Example query chip styled like `CapsuleChip`, but its text wraps at large
/// accessibility sizes instead of truncating the example.
private struct SearchExampleChip: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs + 2) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityAddTraits(.isButton)
    }
}

struct SearchNoResultsView: View {
    var query: SearchParsedQuery
    var isBrowsing: Bool
    /// Matches exist but your filters or selected source hide them (see the banners above).
    var hasHiddenMatches = false
    var onRefine: () -> Void

    @Environment(AppModel.self) private var app

    private var title: String {
        if isBrowsing { return "Nothing matches these filters" }
        if hasHiddenMatches { return "No matches with these filters and source" }
        return "Nothing recorded matches “\(query.raw.trimmingCharacters(in: .whitespaces))”"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            Text(title)
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if isBrowsing {
                Text("Try removing a filter. Filters are never removed for you.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                CollapsibleText(
                    "Search only knows the names, other names, details and notes you've recorded. This doesn't mean the item isn't in your closet — it may just not be described this way yet.",
                    summary: "It may just not be described this way yet.",
                    font: .subheadline,
                    topic: "why nothing matched",
                    isExpanded: app.searchUI.disclosure("noResultsWhy")
                )
            }
            Group {
                if isBrowsing {
                    ActionGroup { mainButtons }
                } else {
                    ActionGroup(moreTitle: "Add details", moreIdentifier: "searchAddDetails") {
                        mainButtons
                    } more: {
                        Button {
                            app.popToRoot(.closet)
                            app.select(.closet)
                        } label: {
                            Label("Add details to an item in your closet", systemImage: "text.badge.plus")
                        }
                        Button {
                            app.present(.addGarment(AddGarmentPrefill(name: SearchEngine.rememberSuggestion(from: query.raw))))
                        } label: {
                            Label("Add a new item named “\(SearchEngine.rememberSuggestion(from: query.raw))”", systemImage: "plus")
                        }
                    }
                }
            }
            .padding(.top, Spacing.xxs)
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("searchNoResults")
    }

    @ViewBuilder private var mainButtons: some View {
        Button(action: onRefine) {
            Label("Refine search", systemImage: "pencil")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("searchRefine")

        Button {
            app.popToRoot(.closet)
            app.select(.closet)
        } label: {
            Label("Browse closet", systemImage: "cabinet")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("searchBrowseCloset")
    }
}

#Preview("Result rows") {
    let model = AppModel.preview
    let docs = SearchIndexBuilder.documents(from: SearchIndexInput(store: model.store, workingScope: .mainCloset))
    let output = SearchEngine.run("baggy jeans with the pocket", filters: SearchFilters(), scope: .everything, documents: docs)
    ScrollView {
        VStack(spacing: Spacing.s) {
            ForEach(output.primary) { hit in
                SearchResultRow(hit: hit, isSelected: false, showsChevron: true, onSelect: {}, onOpen: {})
            }
        }
        .padding()
    }
    .themedScreenBackground()
    .previewEnvironment(model)
}
