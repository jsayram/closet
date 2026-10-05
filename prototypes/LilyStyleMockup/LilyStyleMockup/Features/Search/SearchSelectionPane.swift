import SwiftUI

// MARK: - Remember this name rules

enum SearchRememberLogic {
    /// Session-only key for an answered prompt (item + phrase). Never persisted.
    static func key(garmentID: String, suggestion: String) -> Int {
        var hasher = Hasher()
        hasher.combine(garmentID)
        hasher.combine(SearchText.normalize(suggestion))
        return hasher.finalize()
    }

    /// Offered for a garment found by a multi-word query its names don't already
    /// cover, until Lily answers it. Selecting or opening alone writes nothing.
    static func isOffered(ui: SearchUIState, query: SearchParsedQuery, hit: SearchHit?, garment: Garment) -> Bool {
        guard let hit, hit.document.type == .garment, !garment.isTrashed else { return false }
        let suggestion = SearchEngine.rememberSuggestion(from: query.raw)
        guard !suggestion.isEmpty, !ui.answeredRememberKeys.contains(key(garmentID: garment.id, suggestion: suggestion)) else { return false }
        return SearchEngine.shouldOfferRemember(query: query, hit: hit, garment: garment)
    }
}

// MARK: - Inline confirmations

/// Confirmation for the selected result's last action (Remember, Not now, Mark clean).
/// Shown in the pane itself, inside the compact quick-look sheet and in the compact
/// results column, so it stays visible wherever the action happened.
struct SearchPaneNoticeBanner: View {
    var document: SearchDocument

    @Environment(AppModel.self) private var app

    var body: some View {
        if let notice = app.searchUI.paneNotice, notice.resultID == document.id {
            Group {
                switch notice.kind {
                case let .remembered(phrase):
                    InlineBanner(
                        style: .success,
                        title: "Saved as another name",
                        message: "“\(phrase)” now finds \(document.title), here on this device. Only this item changed.",
                        actionTitle: "Undo",
                        action: { undoRemember(phrase) }
                    )
                case let .rememberUndone(phrase):
                    InlineBanner(style: .info, title: "Removed “\(phrase)”", message: "This item's other names are back as they were.")
                case .declined:
                    InlineBanner(style: .info, title: "Nothing was saved", message: "Selecting or opening an item never teaches search on its own.")
                case let .cleaned(undoEntryID):
                    InlineBanner(
                        style: .success,
                        title: "Marked clean",
                        message: "Only this item changed. Nothing else was cleaned.",
                        actionTitle: "Undo",
                        action: { undoMarkClean(undoEntryID) }
                    )
                case let .cleanUndo(message):
                    InlineBanner(style: .info, title: "Undo", message: message)
                }
            }
            .accessibilityIdentifier("searchPaneNotice")
        }
    }

    /// Removes only the alias this prompt saved (matched by search provenance).
    private func undoRemember(_ phrase: String) {
        let store = app.store
        let id = document.sourceID
        let key = SearchText.normalize(phrase)
        if let alias = store.garment(id)?.aliases.first(where: { $0.provenance == .rememberedFromSearch && SearchText.normalize($0.text) == key }) {
            store.removeAnnotation(id, annotationID: alias.id)
        }
        app.searchUI.paneNotice = SearchPaneNotice(resultID: document.id, kind: .rememberUndone(phrase: phrase))
        UIAccessibility.post(notification: .announcement, argument: "Removed \(phrase).")
    }

    /// Applies the store's own revision-checked undo entry for this Mark clean, and
    /// only while it is still the latest one. Otherwise nothing changes.
    private func undoMarkClean(_ undoEntryID: UUID?) {
        let store = app.store
        let name = store.garment(document.sourceID)?.displayName ?? document.title
        let message: String
        if let undoEntryID, store.undoStack.last?.id == undoEntryID, let result = store.undoLast() {
            message = result
        } else if store.garment(document.sourceID)?.availability == .dirty {
            message = "\(name) is already Dirty. Nothing else changed."
        } else {
            message = "\(name) changed since, so undo was skipped. Nothing else changed."
        }
        app.searchUI.paneNotice = SearchPaneNotice(resultID: document.id, kind: .cleanUndo(message: message))
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

/// Compact layouts: keeps Remember this name (and its confirmation) reachable after
/// quick look closes or the item was opened directly from a context menu or the
/// VoiceOver action, without presenting anything on its own.
struct SearchPendingRememberCard: View {
    var output: SearchOutput
    var documents: [SearchDocument]

    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.searchUI
        if let id = ui.selectedResultID,
           let document = documents.first(where: { $0.id == id }), document.type == .garment,
           let garment = app.store.garment(document.sourceID) {
            if SearchRememberLogic.isOffered(ui: ui, query: output.query, hit: output.allHits.first { $0.id == id }, garment: garment) {
                SearchRememberPrompt(garment: garment, suggestion: SearchEngine.rememberSuggestion(from: output.query.raw))
            } else {
                SearchPaneNoticeBanner(document: document)
            }
        }
    }
}

// MARK: - Selection pane

/// Details of the selected result: what it is, its current status, why it matched,
/// Remember this name (garments) and the Open action. Used as the wide-layout side
/// pane and inside the compact quick-look sheet.
struct SearchSelectionPane: View {
    var document: SearchDocument
    var hit: SearchHit?
    var query: SearchParsedQuery
    var onOpen: () -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        let store = app.store
        VStack(alignment: .leading, spacing: Spacing.m) {
            header(store: store)
            visual(store: store)
                .frame(maxWidth: .infinity)
            BadgeRow(badges: SearchPresentation.statusBadges(for: document, store: store), compact: false)
            actions(store: store)
            SearchPaneNoticeBanner(document: document)
            if document.type == .garment, let garment = store.garment(document.sourceID),
               SearchRememberLogic.isOffered(ui: app.searchUI, query: query, hit: hit, garment: garment) {
                SearchRememberPrompt(garment: garment, suggestion: SearchEngine.rememberSuggestion(from: query.raw))
            }
            whyItMatched
            facts(store: store)
        }
        .frame(maxWidth: 560, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("searchSelectionPane")
    }

    // MARK: Header and visual

    private func header(store: DemoStore) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            StatusBadge(kind: SearchPresentation.typeBadge(for: document, store: store), compact: true)
            Text(document.title)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(SearchPresentation.subtitle(for: document, store: store))
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func visual(store: DemoStore) -> some View {
        switch document.type {
        case .garment:
            if let g = store.garment(document.sourceID) {
                GarmentThumbnail(garment: g, showsImageKind: true, showsStatus: false)
                    .frame(maxWidth: 220)
            }
        case .outfit:
            if let o = store.outfit(document.sourceID) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    OutfitFlatLayView(
                        pieces: o.pieces,
                        statusFor: { SearchPresentation.pieceBadges($0, store: store) }
                    )
                    OutfitPieceChips(
                        pieces: o.pieces,
                        statusFor: { SearchPresentation.pieceBadges($0, store: store) },
                        scrolls: true,
                        isExpanded: app.searchUI.disclosure("panePieces")
                    )
                    HStack(spacing: Spacing.xxs) {
                        Text("Badges show today's status")
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                        InfoButton("these badges", title: "Saved pieces, today's status",
                                   text: "Pieces are shown as they were saved. Badges show each piece's status today.")
                    }
                }
                .frame(maxWidth: 380)
            }
        case .preview:
            if let p = store.preview(document.sourceID) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    OnMePreviewFigure(pieces: p.snapshotPieces, isEarlier: SearchPresentation.isEarlier(p, store: store))
                        .frame(maxWidth: 240)
                        .frame(maxWidth: .infinity)
                    // Same captured-vs-today rows as the picture's page in Saved. The status
                    // summary badges under the picture stay visible while this is closed.
                    let pieces = p.snapshotPieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }
                    DetailsDisclosure(
                        "Captured pieces",
                        count: pieces.count,
                        isExpanded: app.searchUI.disclosure("paneCapturedPieces"),
                        identifier: "searchCapturedPieces"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            ForEach(pieces) { piece in
                                SavedCapturedRow(piece: piece, garment: store.garment(piece.garmentID),
                                                 today: SavedLookStatus.todayBadges(for: piece, in: store),
                                                 isMissing: store.isMissing(piece))
                                if piece.id != pieces.last?.id {
                                    Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)
                                }
                            }
                            Text("The picture keeps its captured pieces and colors. Badges show each piece's status today; they don't change the picture.")
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: 420)
            }
        case .product:
            if let ref = store.savedProducts.first(where: { $0.id == document.sourceID }) {
                GarmentArtwork(kind: ref.candidate.kind, hex: ref.candidate.colorHex)
                    .frame(maxWidth: 160)
            }
        }
    }

    // MARK: Actions

    @ViewBuilder
    private func actions(store: DemoStore) -> some View {
        let garment = document.type == .garment ? store.garment(document.sourceID) : nil
        let canMarkClean = garment.map { $0.isCurrentlyOwned && $0.availability == .dirty } ?? false
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                openButton
                if canMarkClean, let garment { markClean(garment) }
            }
            VStack(alignment: .leading, spacing: Spacing.s) {
                openButton
                if canMarkClean, let garment { markClean(garment) }
            }
        }
    }

    /// Mark clean with its how-it-works note behind an info button.
    private func markClean(_ garment: Garment) -> some View {
        HStack(spacing: Spacing.xs) {
            markCleanButton(garment)
            InfoButton("Mark clean", text: "Selecting it here doesn't clean it — only Mark clean does. It changes only this item from Dirty to Available, and you can undo.")
        }
    }

    private var openButton: some View {
        Button(action: onOpen) {
            Label(SearchPresentation.openTitle(for: document.type), systemImage: "arrow.up.forward.app")
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
        .keyboardShortcut("o", modifiers: .command)
        .accessibilityIdentifier("searchOpenResult")
    }

    private func markCleanButton(_ garment: Garment) -> some View {
        Button {
            if app.store.markClean(garment.id) {
                let undoEntryID = app.store.undoStack.last?.id
                app.showUndoToast("\(garment.displayName) marked clean.")
                app.searchUI.paneNotice = SearchPaneNotice(resultID: document.id, kind: .cleaned(undoEntryID: undoEntryID))
            }
        } label: {
            Label("Mark clean", systemImage: "sparkles")
        }
        .buttonStyle(SuccessButtonStyle())
        .accessibilityHint("Changes only this item from Dirty to Available. You can undo.")
        .accessibilityIdentifier("searchMarkClean")
    }

    // MARK: Why it matched

    @ViewBuilder private var whyItMatched: some View {
        if let hit, !hit.matches.isEmpty {
            let possible = hit.tier == .possible
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if possible {
                    // The honest core of a limited result stays on screen.
                    Label("Possible match only, not confirmed", systemImage: "circle.lefthalf.filled")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                DetailsDisclosure(
                    possible ? "Why it might match" : "Why it matched",
                    summary: hit.unmatchedWords.isEmpty ? nil : "\(hit.unmatchedWords.count) not recorded",
                    count: hit.matches.count,
                    // Open to start with: this is where the row's "+2 more" reasons land.
                    isExpanded: app.searchUI.disclosure("paneWhy", startsOpen: true),
                    identifier: "searchWhyMatched"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(Array(hit.matches.enumerated()), id: \.offset) { _, match in
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(matchLine(match))
                                        .font(.subheadline)
                                        .foregroundStyle(Palette.primaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                    if let explanation = match.kind.explanation {
                                        Text(explanation)
                                            .font(.caption)
                                            .foregroundStyle(Palette.secondaryText)
                                    }
                                }
                            } icon: {
                                Image(systemName: icon(for: match.kind))
                                    .foregroundStyle(Palette.primaryAction)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        if !hit.unmatchedWords.isEmpty {
                            Label {
                                Text("Not recorded: \(hit.unmatchedWords.map { "“\($0)”" }.joined(separator: ", "))")
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(Palette.secondaryText)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        if possible {
                            Text("A possible match only — not a confirmed match or a sign of what the picture looks like.")
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .cardStyle(padding: Spacing.s)
        } else if hit == nil {
            CollapsibleText(
                "Not in the current results. It's shown here because you selected it earlier.",
                summary: "Not in the current results.",
                topic: "why this is shown",
                isExpanded: app.searchUI.disclosure("paneNotInResults")
            )
        }
    }

    private func matchLine(_ match: SearchTermMatch) -> String {
        switch match.kind {
        case .phrase:
            return "\(match.term) → \(match.field.provenance)"
        case .exact:
            return "\(match.term) → \(match.field.provenance)"
        case .relatedShade:
            return "\(match.term) → related shade \(match.matchedWord) (\(match.field.provenance))"
        case .variant, .synonym, .prefix:
            return "\(match.term) → “\(match.matchedWord)” in \(match.field.provenance)"
        }
    }

    private func icon(for kind: SearchMatchKind) -> String {
        switch kind {
        case .phrase: "quote.opening"
        case .exact: "checkmark.circle"
        case .variant: "textformat.abc"
        case .synonym: "arrow.left.arrow.right"
        case .prefix: "text.cursor"
        case .relatedShade: "circle.lefthalf.filled"
        }
    }

    // MARK: Facts

    @ViewBuilder
    private func facts(store: DemoStore) -> some View {
        switch document.type {
        case .garment:
            if let g = store.garment(document.sourceID) { garmentFacts(g, store: store) }
        case .outfit:
            if let o = store.outfit(document.sourceID) { outfitFacts(o, store: store) }
        case .preview:
            if let p = store.preview(document.sourceID) { previewFacts(p, store: store) }
        case .product:
            if let ref = store.savedProducts.first(where: { $0.id == document.sourceID }) { productFacts(ref) }
        }
    }

    /// A closed "About this …" row; the label/value rows open in place.
    /// Short form of the quality label for the closed row; the full label is the Quality row inside.
    private func previewQualitySummary(_ quality: PreviewQualityLabel) -> String? {
        switch quality {
        case .ok: nil
        case .approximate: "Approximate"
        case .appearanceMismatch: "Needs review"
        }
    }

    private func factsCard<Rows: View>(_ title: String, summary: String? = nil, @ViewBuilder rows: @escaping () -> Rows) -> some View {
        DetailsDisclosure(
            title,
            summary: summary,
            isExpanded: app.searchUI.disclosure("paneFacts"),
            identifier: "searchAboutResult"
        ) {
            VStack(alignment: .leading, spacing: Spacing.xs) { rows() }
        }
    }

    private func garmentFacts(_ g: Garment, store: DemoStore) -> some View {
        let suitcases = store.suitcases(containing: g.id).map(\.name)
        var ownership = g.ownership.label
        if g.ownership == .purchasedConfirmed, let arrival = g.arrival { ownership += " · \(arrival.label)" }
        let ownershipText = ownership
        return factsCard("About this item", summary: g.brand) {
            InfoRow(title: "Category", value: g.category == .unknown ? "Unknown" : g.category.label, valueIsUnknown: g.category == .unknown)
            InfoRow(title: "Color", value: g.color?.name ?? "Unknown", valueIsUnknown: g.color == nil)
            InfoRow(title: "Brand", value: g.brand ?? "Unknown", valueIsUnknown: g.brand == nil)
            InfoRow(title: "Other names", value: g.aliases.isEmpty ? "None yet" : g.aliases.map(\.text).joined(separator: ", "), valueIsUnknown: g.aliases.isEmpty)
            InfoRow(title: "Details", value: g.details.isEmpty ? "None yet" : g.details.map(\.text).joined(separator: ", "), valueIsUnknown: g.details.isEmpty)
            InfoRow(title: "Ownership", value: ownershipText)
            InfoRow(title: "Status", value: g.availability.label)
            InfoRow(title: "Suitcases", value: suitcases.isEmpty ? "None" : suitcases.joined(separator: ", "), valueIsUnknown: suitcases.isEmpty)
            if g.photoFilename == nil, g.imageKind == .actualPhoto {
                Text("Demo stand-in illustration for a photo of your own garment.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else if g.photoFilename == nil {
                Text("Representative image — not a photo of your garment.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle(padding: Spacing.s)
    }

    private func outfitFacts(_ o: Outfit, store: DemoStore) -> some View {
        let collections = store.collections(containingOutfit: o.id).map(\.name)
        return factsCard("About this look", summary: "Saved \(o.updatedAt.formatted(date: .abbreviated, time: .omitted))") {
            InfoRow(title: "Occasion", value: o.occasion?.label ?? "Not set", valueIsUnknown: o.occasion == nil)
            InfoRow(title: "Captured from", value: o.capturedScopeName ?? "Unknown source", valueIsUnknown: o.capturedScopeName == nil)
            InfoRow(title: "Saved", value: o.updatedAt.formatted(date: .abbreviated, time: .omitted))
            InfoRow(title: "Collections", value: collections.isEmpty ? "None" : collections.joined(separator: ", "), valueIsUnknown: collections.isEmpty)
            InfoRow(title: "Favorite", value: o.isFavorite ? "Yes" : "No")
            Text("Finding an older look doesn't make its pieces available today. Restyling uses your current closet.")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle(padding: Spacing.s)
    }

    private func previewFacts(_ p: PreviewEntry, store: DemoStore) -> some View {
        let collections = store.collections(containingPreview: p.id).map(\.name)
        var reaction: [String] = []
        if p.isFavorite { reaction.append("Favorite") }
        if p.isDisliked { reaction.append("Disliked (kept in history)") }
        let reactionText = reaction.isEmpty ? "None" : reaction.joined(separator: ", ")
        let noReaction = reaction.isEmpty
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            factsCard("About this preview", summary: previewQualitySummary(p.quality)) {
                InfoRow(title: "Made", value: p.createdAt.formatted(date: .abbreviated, time: .omitted))
                InfoRow(title: "Captured from", value: p.capturedScopeName ?? "Unknown source", valueIsUnknown: p.capturedScopeName == nil)
                InfoRow(title: "Quality", value: p.quality.label)
                InfoRow(title: "Collections", value: collections.isEmpty ? "None" : collections.joined(separator: ", "), valueIsUnknown: collections.isEmpty)
                InfoRow(title: "Your reaction", value: reactionText, valueIsUnknown: noReaction)
            }
            SimulationNotice(
                text: "Simulated appearance approximation — not a photo and not a fit preview. Its keywords come from the captured outfit and your edits; the picture itself isn't analyzed.",
                summary: "Not a photo or fit preview"
            )
        }
        .cardStyle(padding: Spacing.s)
    }

    private func productFacts(_ ref: SavedProductReference) -> some View {
        let c = ref.candidate
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            factsCard("About this saved product", summary: c.retailer) {
                InfoRow(title: "Retailer", value: c.retailer)
                InfoRow(title: "Listed color", value: c.colorName)
                InfoRow(title: "Price", value: c.price.map { "\($0.formatted(.currency(code: c.currency))) as listed — not final" } ?? "Unknown", valueIsUnknown: c.price == nil)
                InfoRow(title: "Fit evidence", value: c.fitState.title)
                InfoRow(title: "Saved", value: ref.savedAt.formatted(date: .abbreviated, time: .omitted))
            }
            SimulationNotice(
                text: "Fictional demo product. It isn't owned, and nothing was bought.",
                label: "Demo",
                summary: "Not owned, nothing bought"
            )
        }
        .cardStyle(padding: Spacing.s)
    }
}

// MARK: - Remember this name prompt

/// Optional, editable prompt to save a reviewed phrase as another name for this
/// item only. Nothing is written unless Lily taps Remember.
struct SearchRememberPrompt: View {
    var garment: Garment
    var suggestion: String

    @Environment(AppModel.self) private var app
    @FocusState private var fieldFocused: Bool

    private var queryKey: String { SearchText.normalize(suggestion) }

    private var text: Binding<String> {
        let ui = app.searchUI
        let id = garment.id
        let key = queryKey
        let fallback = suggestion
        return Binding(
            get: {
                if let draft = ui.rememberDraft, draft.garmentID == id, draft.queryKey == key { return draft.text }
                return fallback
            },
            set: { ui.rememberDraft = SearchRememberDraft(garmentID: id, queryKey: key, text: $0) }
        )
    }

    var body: some View {
        let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let alreadyName = !trimmed.isEmpty && SearchEngine.isExistingName(trimmed, of: garment)
        let tooLong = trimmed.count > 60
        let canSave = !trimmed.isEmpty && !alreadyName && !tooLong
        let withoutFiller = SearchEngine.withoutStopwords(trimmed)

        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xxs) {
                Label {
                    Text("Remember this name?")
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                } icon: {
                    Image(systemName: "text.badge.plus")
                        .foregroundStyle(Palette.primaryAction)
                }
                .accessibilityAddTraits(.isHeader)
                InfoButton("remembering a name", title: "Remember this name",
                           text: "Saved only on this item as another name, so the same words find it next time. Your search isn't kept, and other items are unchanged.")
            }

            Text("Remember “\(trimmed.isEmpty ? suggestion : trimmed)” for \(garment.displayName)?")
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            TextField("Other name", text: text)
                .font(.body)
                .foregroundStyle(Palette.primaryText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fieldFocused)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.background))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                        .strokeBorder(fieldFocused ? Palette.primaryAction : Palette.controlBorder, lineWidth: fieldFocused ? 2 : 1)
                )
                .accessibilityLabel("Other name to remember")
                .accessibilityHint("Edit the words before saving. Only this phrase is saved, on this item.")
                .accessibilityIdentifier("rememberNameField")

            if withoutFiller != trimmed, !withoutFiller.isEmpty {
                Button {
                    text.wrappedValue = withoutFiller
                } label: {
                    Label("Leave out filler words", systemImage: "text.badge.minus")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.primaryAction)
                .minimumHitTarget()
                .accessibilityHint("Changes the phrase to “\(withoutFiller)”")
            }

            if alreadyName {
                Label("That's already one of its names.", systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            } else if tooLong {
                Label("Keep it to 60 characters or fewer.", systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
            }

            // What Remember saves stays on screen, in short form, before she agrees.
            Text("Saved on this item only. Your search isn't kept.")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    rememberButton(trimmed, enabled: canSave)
                    declineButton
                }
                VStack(alignment: .leading, spacing: Spacing.s) {
                    rememberButton(trimmed, enabled: canSave)
                    declineButton
                }
            }
        }
        .cardStyle(highlighted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rememberNamePrompt")
    }

    private func rememberButton(_ phrase: String, enabled: Bool) -> some View {
        Button {
            remember(phrase)
        } label: {
            Label("Remember", systemImage: "checkmark")
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
        .disabled(!enabled)
        .accessibilityHint("Adds “\(phrase)” as another name for \(garment.displayName)")
        .accessibilityIdentifier("rememberNameButton")
    }

    private var declineButton: some View {
        Button {
            decline()
        } label: {
            Text("Not now")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint("Nothing is saved")
        .accessibilityIdentifier("rememberNameDecline")
    }

    private var resultID: String { "\(SearchResultType.garment.rawValue)-\(garment.id)" }

    /// Writes only the reviewed phrase, only to this item, with search provenance.
    private func remember(_ phrase: String) {
        let ui = app.searchUI
        fieldFocused = false
        app.store.addAnnotation(garment.id, kind: .alias, text: phrase, provenance: .rememberedFromSearch)
        // Confirm only what the store actually holds (it ignores duplicates of existing names).
        let key = SearchText.normalize(phrase)
        let saved = app.store.garment(garment.id)?.aliases.contains { SearchText.normalize($0.text) == key } ?? false
        ui.answeredRememberKeys.insert(SearchRememberLogic.key(garmentID: garment.id, suggestion: suggestion))
        ui.rememberDraft = nil
        if saved {
            ui.paneNotice = SearchPaneNotice(resultID: resultID, kind: .remembered(phrase: phrase))
            UIAccessibility.post(notification: .announcement, argument: "Saved \(phrase) as another name for \(garment.displayName).")
        } else {
            ui.paneNotice = SearchPaneNotice(resultID: resultID, kind: .declined)
            UIAccessibility.post(notification: .announcement, argument: "Nothing was saved.")
        }
    }

    private func decline() {
        let ui = app.searchUI
        fieldFocused = false
        ui.answeredRememberKeys.insert(SearchRememberLogic.key(garmentID: garment.id, suggestion: suggestion))
        ui.rememberDraft = nil
        ui.paneNotice = SearchPaneNotice(resultID: resultID, kind: .declined)
        UIAccessibility.post(notification: .announcement, argument: "Nothing was saved.")
    }
}

#Preview("Selection pane — remember prompt") {
    let model = AppModel.preview
    let docs = SearchIndexBuilder.documents(from: SearchIndexInput(store: model.store, workingScope: .mainCloset))
    let output = SearchEngine.run("lacy white shirt with ruffles", filters: SearchFilters(), scope: .everything, documents: docs)
    let hit = output.primary.first { $0.document.sourceID == "g-lace-top" }
    ScrollView {
        if let hit {
            SearchSelectionPane(document: hit.document, hit: hit, query: output.query, onOpen: {})
                .padding()
        }
    }
    .themedScreenBackground()
    .previewEnvironment(model)
}

#Preview("Selection pane — saved look") {
    let model = AppModel.preview
    let docs = SearchIndexBuilder.documents(from: SearchIndexInput(store: model.store, workingScope: .mainCloset))
    let output = SearchEngine.run("olive trousers brick top", filters: SearchFilters(), scope: .everything, documents: docs)
    ScrollView {
        if let hit = output.primary.first {
            SearchSelectionPane(document: hit.document, hit: hit, query: output.query, onOpen: {})
                .padding()
        }
    }
    .themedScreenBackground()
    .previewEnvironment(model)
}
