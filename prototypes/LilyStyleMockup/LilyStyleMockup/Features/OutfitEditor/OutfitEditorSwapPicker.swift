import SwiftUI

/// Real alternatives for one slot, from the draft's captured source only. Shown as a
/// sheet on compact widths and as a trailing pane on wider ones so the outfit stays
/// visible. Opening, scrolling and filtering dispatch nothing; a choice changes only
/// this slot and keeps every other piece ID.
struct OutfitEditorSwapPicker: View {
    enum Presentation { case sheet, pane }

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let editor: OutfitEditorSession
    let slot: OutfitSlot
    var presentation: Presentation = .sheet
    var onClose: () -> Void
    /// Commits pending title/notes text before an edit, so undo order stays honest.
    var onCommitDrafts: () -> Void = {}

    private var ui: OutfitEditorUIState { app.editorUI }
    private var motion: Animation? { reduceMotion ? nil : .snappy(duration: 0.28) }
    private var scopeName: String { app.store.scopeName(editor.scope) }
    private var title: String { "\(slot.label) — \(scopeName)" }
    private var currentPiece: OutfitPiece? { editor.outfit.piece(for: slot) }
    private var pluralLabel: String { slot.category.pluralLabel.lowercased() }

    private var scopeNote: String {
        let only = "Choosing one changes only the \(slot.label.lowercased()); everything else stays."
        return editor.scope.isSuitcase
            ? "Only pieces in \(scopeName) — swaps stay within it. \(only)"
            : "Pieces you own in Main Closet. \(only)"
    }

    var body: some View {
        let options = app.swapOptions(for: slot)
        let content = ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if presentation == .pane {
                    paneHeader
                } else {
                    scopeLine
                }
                if let notice = ui.notice(for: editor) {
                    OutfitEditorNoticeBanner(
                        notice: notice,
                        onUndo: notice.undo == nil ? nil : { withAnimation(motion) { ui.performUndo(for: notice, app: app) } },
                        onDismiss: { withAnimation(motion) { ui.clearNotice(notice.id) } }
                    )
                }
                currentSection
                if let piece = currentPiece, piece.isHypothetical {
                    hypotheticalCard(piece)
                }
                if !options.isEmpty {
                    colorFilters(options)
                }
                results(options)
                manageSection
                OutfitEditorFootnote(
                    summary: "Browsing sends nothing.",
                    text: "Opening this list, scrolling and color filters don't contact any service or make pictures. Only the piece you choose changes."
                )
            }
            .padding(Spacing.m)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Palette.background)
        .accessibilityIdentifier("swapSheet")

        if presentation == .sheet {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onClose)
                            .keyboardShortcut(.cancelAction)
                            .accessibilityHint("Closes swap options. Your look keeps any change you made.")
                    }
                }
        } else {
            content
        }
    }

    // MARK: Header and current piece

    /// One short line under the title; the full scope note opens from the info button.
    private var scopeLine: some View {
        HStack(spacing: Spacing.xxs) {
            Text("Only the \(slot.label.lowercased()) changes")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            InfoButton("these options", title: title, text: scopeNote)
        }
    }

    private var paneHeader: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.editorial(.title3))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                scopeLine
            }
            Spacer(minLength: Spacing.xs)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .minimumHitTarget()
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Close swap options")
        }
    }

    @ViewBuilder private var currentSection: some View {
        if let piece = currentPiece {
            let isMissing = app.store.isMissing(piece)
            let badges = app.outfitEditorBoardBadges(for: piece, editor: editor) + (piece.isHypothetical ? [.unowned] : [])
            HStack(alignment: .top, spacing: Spacing.s) {
                PieceThumbnail(piece: piece)
                    .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("On this look now")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    Text(piece.capturedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(piece.capturedColor?.name ?? "Color unknown")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    BadgeRow(badges: badges)
                    if isMissing {
                        Text("This item was deleted. Choose a replacement below or remove it.")
                            .font(.caption)
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("swapCurrentPiece")
        } else {
            let displaced = displacedPieces
            // What a choice replaces stays on screen; the rest is in the info button.
            HStack(alignment: .top, spacing: Spacing.xxs) {
                Label(displaced.isEmpty
                      ? "Nothing in this slot yet"
                      : "Choosing a \(slot.label.lowercased()) replaces the \(displacedNames(displaced))",
                      systemImage: "plus.circle")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                InfoButton("this empty slot", title: "Nothing in this slot yet",
                           text: displaced.isEmpty
                               ? "Nothing in this slot yet. Choose a piece below to add it — the other pieces stay the same."
                               : "Nothing in this slot yet. Choosing a \(slot.label.lowercased()) replaces the \(displacedNames(displaced)); everything else stays.")
            }
        }
    }

    /// Pieces in other slots that a choice here would replace (a dress replaces the
    /// top and bottom; a top or bottom replaces a dress).
    private var displacedPieces: [OutfitPiece] {
        switch slot {
        case .dress: editor.outfit.pieces.filter { $0.slot == .top || $0.slot == .bottom }
        case .top, .bottom: editor.outfit.pieces.filter { $0.slot == .dress }
        default: []
        }
    }

    private func displacedNames(_ pieces: [OutfitPiece]) -> String {
        pieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }.map { $0.slot.label.lowercased() }.joined(separator: " and ")
    }

    // MARK: Hypothetical piece

    private func hypotheticalCard(_ piece: OutfitPiece) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("\(piece.capturedName) is an idea, not something in your closet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            CollapsibleText("Already have something like it? Add it with one tap — no photo needed. Or look for one, only if you want to.",
                            summary: "Own one like it? Add it, no photo needed.",
                            threshold: 1, topic: "this idea")
            FlowLayout(spacing: Spacing.xs) {
                Button { alreadyOwn(piece) } label: {
                    Label("Already own", systemImage: "checkmark.circle")
                }
                .buttonStyle(SuccessButtonStyle())
                .accessibilityHint("Adds it to your closet as owned with a representative image. No photo needed.")
                .accessibilityIdentifier("alreadyOwnButton")

                Button { openRootSheet(.findOne(app.findOneContext(for: piece, outfit: editor.outfit))) } label: {
                    Label("Find One", systemImage: "magnifyingglass")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Looks for simulated store leads. Nothing is bought.")
                .accessibilityIdentifier("findOneButton")
            }
        }
        .cardStyle()
    }

    // MARK: Color filter

    @ViewBuilder
    private func colorFilters(_ options: [SwapOption]) -> some View {
        let families = ColorFamily.allCases.filter { family in
            editor.colorFilter == family || options.contains { $0.garment.color?.family == family }
        }
        @Bindable var ui = app.editorUI
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Color")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
                .accessibilityAddTraits(.isHeader)
            // One row that scrolls; the button at the end shows every color.
            ChipCarousel(isExpanded: $ui.colorFiltersOpen, itemsLabel: "colors", toggleIdentifier: "colorFilterShowAll") {
                OutfitEditorColorChip(title: "Any", hex: nil, readyCount: nil, isSelected: editor.colorFilter == nil) {
                    setFilter(nil)
                }
                .accessibilityIdentifier("colorFilter-any")
                ForEach(families) { family in
                    let ready = options.filter { $0.eligibility.isEligible && $0.garment.color?.family == family }.count
                    OutfitEditorColorChip(title: family.label, hex: family.swatchHex, readyCount: ready, isSelected: editor.colorFilter == family) {
                        setFilter(family)
                    }
                    .accessibilityIdentifier("colorFilter-\(family.rawValue)")
                }
            }
        }
    }

    private func setFilter(_ family: ColorFamily?) {
        withAnimation(motion) { editor.colorFilter = family }
    }

    // MARK: Options

    @ViewBuilder
    private func results(_ options: [SwapOption]) -> some View {
        let shown = options.filter(\.matchesColorFilter)
        let ready = shown.filter { $0.eligibility.isEligible }
        let needsOK = shown.filter { !$0.eligibility.isEligible && $0.eligibility.canOverride }
        let blocked = shown.filter { !$0.eligibility.isEligible && !$0.eligibility.canOverride }

        if options.isEmpty {
            noOptionsCard
        } else {
            if let family = editor.colorFilter, ready.isEmpty {
                noColorMatchCard(family, options: options, hasNeedsOK: !needsOK.isEmpty)
            } else if ready.isEmpty {
                InlineBanner(style: .caution,
                             title: "No eligible \(pluralLabel) in \(scopeName) right now",
                             message: "The ones below need your OK or can't be used. Nothing was swapped automatically.")
            }
            optionGroup("Ready to use", ready, note: nil)
            optionGroup("Needs your OK", needsOK,
                        note: "Left out of styling by default. You can use one for this look only — its status stays the same.")
            optionGroup("Can't be used right now", blocked, note: nil)
        }
    }

    @ViewBuilder
    private func optionGroup(_ heading: String, _ items: [SwapOption], note: String?) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(heading)
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                        Text("\(items.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                    if let note {
                        InfoButton(heading, text: note)
                    }
                }
                ForEach(items) { option in
                    OutfitEditorSwapOptionRow(
                        option: option,
                        slot: slot,
                        scopeName: scopeName,
                        onUse: { use(option) },
                        onAllowOnce: { allowOnce(option) },
                        onMarkClean: { markClean(option.garment) }
                    )
                }
            }
        }
    }

    private var noOptionsCard: some View {
        InlineBanner(
            style: .info,
            title: "No \(pluralLabel) in \(scopeName)",
            message: editor.scope.isSuitcase
                ? "Swaps stay within this suitcase. Add a \(slot.label.lowercased()) to \(scopeName) from Closet, or start a new look from Main Closet in Style Me."
                : "Add one in Closet when you're ready — a text-only entry is enough."
        )
        .accessibilityIdentifier("swapNoOptions")
    }

    private func noColorMatchCard(_ family: ColorFamily, options: [SwapOption], hasNeedsOK: Bool) -> some View {
        let closest = family.relatedFamilies.filter { related in
            options.contains { $0.eligibility.isEligible && $0.garment.color?.family == related }
        }
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Label {
                Text("No eligible \(family.label.lowercased()) \(pluralLabel) in \(scopeName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "paintpalette")
                    .foregroundStyle(Palette.primaryAction)
            }
            CollapsibleText("Nothing was recolored or swapped. Clear the filter, try a close color, or choose another piece."
                            + (hasNeedsOK ? " \(family.label) pieces that need your OK are listed below." : ""),
                            summary: "Nothing was recolored or swapped.",
                            threshold: 1, topic: "this color filter")
            // Clear filter first, then the close colors, on one row that scrolls.
            ChipCarousel(itemsLabel: "color options") {
                Button { setFilter(nil) } label: {
                    Label("Clear filter", systemImage: "xmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("clearColorFilterButton")
                ForEach(closest) { related in
                    Button { setFilter(related) } label: {
                        HStack(spacing: Spacing.xs) {
                            ColorSwatch(hex: related.swatchHex, size: 14)
                            Text("Try \(related.label.lowercased())")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Try \(related.label.lowercased()) instead")
                }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.primaryAction.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swapNoColorMatch")
    }

    // MARK: Remove / Find One

    private func canRemove(_ piece: OutfitPiece) -> Bool {
        [.layer, .shoes, .accessory].contains(piece.slot) || piece.isHypothetical || app.store.isMissing(piece)
    }

    @ViewBuilder private var manageSection: some View {
        let piece = currentPiece
        let showsFindOne = piece?.isHypothetical != true
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showsFindOne {
                HStack(spacing: Spacing.xxs) {
                    Text("Nothing here you like?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    InfoButton("Find One", text: "Find One looks for a new \(slot.label.lowercased()) only when you ask. It shows simulated store leads; nothing is bought or added to your closet."
                               + (editor.scope.isSuitcase ? " A new piece wouldn't be part of \(scopeName) unless you add it later." : ""))
                }
            }
            // Everything else you can do with this slot, in one group. Remove sits last, apart from the rest.
            FlowLayout(spacing: Spacing.xs) {
                if let target = switchTarget {
                    Button { switchSlot(to: target) } label: {
                        Label(target == .dress ? "Use a dress instead" : "Switch to a top and bottom",
                              systemImage: "arrow.triangle.swap")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityHint(target == .dress
                                       ? "Shows dresses. Choosing one replaces the top and bottom."
                                       : "Shows tops. Choosing one replaces the dress.")
                    .accessibilityIdentifier("swapSwitchSlotButton")
                }
                if showsFindOne {
                    Button { openRootSheet(.findOne(findOneContext())) } label: {
                        Label("Find One", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityHint("Opens Find One for this slot. Nothing is searched until you ask there.")
                    .accessibilityIdentifier("findOneButton")
                }
                if let piece, canRemove(piece) {
                    Button(role: .destructive) { remove(piece) } label: {
                        Label("Remove from look", systemImage: "minus.circle")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                    .accessibilityHint("Takes this piece off the look. Everything else stays. You can undo.")
                    .accessibilityIdentifier("removePieceButton")
                }
            }
        }
    }

    /// Dress ↔ separates switch: nothing changes until a piece is chosen in the new slot.
    private var switchTarget: OutfitSlot? {
        switch slot {
        case .dress where currentPiece != nil: .top
        case .top, .bottom: editor.outfit.piece(for: .dress) == nil ? .dress : nil
        default: nil
        }
    }

    private func switchSlot(to target: OutfitSlot) {
        withAnimation(motion) { editor.selectedSlot = target }
    }

    private func findOneContext() -> FindOneContext {
        if let piece = currentPiece {
            var context = app.findOneContext(for: piece, outfit: editor.outfit)
            if let filter = editor.colorFilter { context.colorFamily = filter }
            return context
        }
        return FindOneContext(outfitID: editor.outfit.id, slot: slot, description: slot.label.lowercased(), kind: .unknown,
                              colorFamily: editor.colorFilter, scope: editor.scope)
    }

    // MARK: Actions

    private func use(_ option: SwapOption) {
        onCommitDrafts()
        let name = option.garment.displayName
        let previous = currentPiece?.capturedName
        let displaced = displacedPieces
        let swapped = withAnimation(motion) { app.applySwap(slot: slot, garmentID: option.garment.id) }
        if swapped {
            let title: String
            if displaced.isEmpty {
                title = previous == nil ? "Added — other pieces unchanged" : "Swapped — other pieces unchanged"
            } else {
                title = "Swapped — the \(displacedNames(displaced)) came off"
            }
            var detail = previous.map { "Now using \(name) instead of \($0)." } ?? "Added \(name) as the \(slot.label.lowercased())."
            if !displaced.isEmpty { detail += " Everything else is unchanged." }
            ui.post(OutfitEditorNotice(
                editorID: editor.id,
                title: title,
                detail: detail,
                undo: .editorEdit(revision: editor.draftRevision)
            ))
        } else {
            ui.post(OutfitEditorNotice(editorID: editor.id, style: .error, title: "\(name) can't be used right now",
                                       detail: "It isn't eligible in \(scopeName). Nothing changed."))
        }
    }

    private func allowOnce(_ option: SwapOption) {
        onCommitDrafts()
        let garment = option.garment
        let status = OutfitEditorCopy.statusPhrase(option.eligibility.issues)
        app.allowForThisRequest(garment.id)
        guard editor.overrideIDs.contains(garment.id) else {
            ui.post(OutfitEditorNotice(editorID: editor.id, style: .error, title: "\(garment.displayName) can't be used",
                                       detail: "Its status changed. Nothing was swapped."))
            return
        }
        if option.isCurrent {
            ui.post(OutfitEditorNotice(editorID: editor.id, title: "Using \(garment.displayName) for this request",
                                       detail: "It stays \(status) — its status is unchanged."))
            return
        }
        let displaced = displacedPieces
        let swapped = withAnimation(motion) { app.applySwap(slot: slot, garmentID: garment.id) }
        let swapTitle = displaced.isEmpty ? "Swapped — other pieces unchanged" : "Swapped — the \(displacedNames(displaced)) came off"
        ui.post(OutfitEditorNotice(
            editorID: editor.id,
            title: swapped ? swapTitle : "Allowed for this request",
            detail: "Using \(status) \(garment.displayName) for this request. It stays \(status) — its status is unchanged.",
            undo: swapped ? .editorEdit(revision: editor.draftRevision) : nil
        ))
    }

    private func markClean(_ garment: Garment) {
        guard app.store.markClean(garment.id) else {
            ui.post(OutfitEditorNotice(editorID: editor.id, style: .error, title: "Couldn't mark \(garment.displayName) clean",
                                       detail: "Its status changed since. Nothing else changed."))
            return
        }
        app.showUndoToast("Marked \(garment.displayName) clean.")
        // The toast already speaks the confirmation; don't announce it twice.
        ui.post(OutfitEditorNotice(editorID: editor.id, title: "Marked \(garment.displayName) clean",
                                   detail: "It's Available now, everywhere it appears.",
                                   undo: .markClean(name: garment.displayName)),
                announce: false)
    }

    private func alreadyOwn(_ piece: OutfitPiece) {
        onCommitDrafts()
        withAnimation(motion) { app.markAlreadyOwn(pieceID: piece.id) }
        guard editor.outfit.piece(for: slot)?.isHypothetical == false else { return }
        // This confirmation carries the same message (plus the suitcase note); avoid a duplicate toast.
        app.toast = nil
        ui.post(OutfitEditorNotice(
            editorID: editor.id,
            title: "Added \(piece.capturedName) to your closet as owned",
            detail: "It uses a representative image until you add a photo."
                + (editor.scope.isSuitcase ? " It's in Main Closet only for now." : ""),
            undo: nil
        ))
    }

    private func remove(_ piece: OutfitPiece) {
        onCommitDrafts()
        withAnimation(motion) { app.removePiece(slot: slot) }
        ui.post(OutfitEditorNotice(
            editorID: editor.id,
            title: "Removed — other pieces unchanged",
            detail: piece.isHypothetical || piece.garmentID == nil || app.store.isMissing(piece)
                ? "\(piece.capturedName) is off this look."
                : "\(piece.capturedName) is off this look. It's still in your closet.",
            undo: .editorEdit(revision: editor.draftRevision)
        ))
    }

    /// Root sheets (Find One) can't open over the compact swap sheet, so close it first.
    private func openRootSheet(_ sheet: AppSheet) {
        onCommitDrafts()
        if presentation == .sheet {
            onClose()
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                app.present(sheet)
            }
        } else {
            app.present(sheet)
        }
    }
}

// MARK: - Option row

/// One real alternative: thumbnail, name, color, status badges, Current marker and
/// the action its eligibility allows.
struct OutfitEditorSwapOptionRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let option: SwapOption
    let slot: OutfitSlot
    let scopeName: String
    var onUse: () -> Void
    var onAllowOnce: () -> Void
    var onMarkClean: () -> Void

    private var garment: Garment { option.garment }
    private var eligibility: Eligibility { option.eligibility }
    private var status: String { OutfitEditorCopy.statusPhrase(eligibility.issues) }
    private var canMarkClean: Bool { garment.availability == .dirty && garment.isCurrentlyOwned }

    private var badges: [BadgeKind] {
        var list = BadgeKind.status(for: garment)
        if eligibility.overridden { list.append(.usedThisRequest) }
        if garment.photoFilename == nil, garment.imageKind != .actualPhoto {
            list.append(BadgeKind.image(for: garment.imageKind))
        }
        return list
    }

    private var explanation: String? {
        if eligibility.overridden {
            return "Allowed for this request — it stays \(status). Its stored status doesn't change."
        }
        if eligibility.isEligible { return nil }
        if eligibility.canOverride { return OutfitEditorCopy.overridableExplanation(for: garment) }
        return OutfitEditorCopy.blockedReason(eligibility.issues, scopeName: scopeName)
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s))
        VStack(alignment: .leading, spacing: Spacing.s) {
            layout {
                GarmentThumbnail(garment: garment, size: 72, showsStatus: false)
                VStack(alignment: .leading, spacing: 3) {
                    details
                    if let explanation {
                        // Short reasons show in full; a longer one folds to its first line with More.
                        CollapsibleText(explanation, font: .caption, topic: garment.displayName)
                    }
                }
            }
            actions
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(option.isCurrent ? Palette.primaryAction : Palette.divider, lineWidth: option.isCurrent ? 2 : 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swapOption-\(garment.id)")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(garment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                if option.isCurrent {
                    StatusBadge(kind: .custom("Current", "checkmark.circle.fill"), compact: true)
                }
            }
            HStack(spacing: Spacing.xxs + 2) {
                if let color = garment.color {
                    ColorSwatch(hex: color.hex, size: 12)
                }
                Text(garment.colorLabel)
            }
            .font(.caption)
            .foregroundStyle(Palette.primaryText)
            Text([garment.kind.label, garment.brand].compactMap { $0 }.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
            BadgeRow(badges: badges)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var actions: some View {
        FlowLayout(spacing: Spacing.xs) {
            if eligibility.isEligible {
                if option.isCurrent {
                    Label("On this look", systemImage: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.success)
                        .frame(minHeight: HitTarget.minimum)
                } else {
                    Button(action: onUse) {
                        Label("Use this", systemImage: "arrow.left.arrow.right")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Use \(garment.displayName)")
                    .accessibilityHint("Replaces only the \(slot.label.lowercased()). Other pieces stay the same.")
                    .accessibilityIdentifier("swapUse-\(garment.id)")
                }
            } else if eligibility.canOverride {
                Button(action: onAllowOnce) {
                    Label(option.isCurrent ? "Keep for this request" : "Use for this request", systemImage: "checkmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("\(option.isCurrent ? "Keep" : "Use") \(garment.displayName) for this request")
                .accessibilityHint("For this look only. It stays \(status).")
                .accessibilityIdentifier("swapAllowOnce-\(garment.id)")
            } else {
                Button(action: {}) {
                    Label("Use this", systemImage: "nosign")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(true)
                .accessibilityLabel("Use \(garment.displayName), not available")
                .accessibilityHint(OutfitEditorCopy.blockedReason(eligibility.issues, scopeName: scopeName))
                .accessibilityIdentifier("swapUse-\(garment.id)")
            }
            if canMarkClean {
                Button(action: onMarkClean) {
                    Label("Mark clean", systemImage: "washer")
                }
                .buttonStyle(SuccessButtonStyle())
                .accessibilityLabel("Mark \(garment.displayName) clean")
                .accessibilityHint("Changes its status to Available everywhere. You can undo.")
                .accessibilityIdentifier("swapMarkClean-\(garment.id)")
            }
        }
    }
}

// MARK: - Color chip

/// Capsule color filter with a swatch, selection checkmark and ready count.
struct OutfitEditorColorChip: View {
    var title: String
    var hex: String?
    var readyCount: Int?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        CapsuleChip(title: title, isSelected: isSelected, swatchHex: hex, trailingCount: readyCount, action: action)
            .accessibilityLabel(readyCount.map { "\(title), \($0) ready to use" } ?? "\(title) color")
            .accessibilityHint("Filters the list. Nothing is recolored.")
    }
}

#Preview("Swap picker — top") {
    let model = OutfitEditorPreviewModels.saved("o-lace-date", selecting: .top)
    return NavigationStack {
        if let editor = model.editor {
            OutfitEditorSwapPicker(editor: editor, slot: .top, onClose: {})
        }
    }
    .previewEnvironment(model)
}
