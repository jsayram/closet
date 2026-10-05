import SwiftUI

// MARK: - Header

/// Editable title, lane, captured working source and honest save state.
struct OutfitEditorHeaderView: View {
    @Environment(AppModel.self) private var app

    let editor: OutfitEditorSession
    @Binding var title: String
    var focus: FocusState<OutfitEditorFocusField?>.Binding
    var hasPendingText: Bool
    var copySavedAt: Date?
    var onCommitTitle: () -> Void

    private var isEditingTitle: Bool { focus.wrappedValue == .title }

    private var originText: String {
        switch editor.origin {
        case .result: "From today's Style Me results"
        case .saved: editor.outfit.isFavorite ? "Saved look · Favorite" : "Saved look"
        case .new: "New look"
        }
    }

    private var sourceText: String {
        let name = app.store.scopeName(editor.scope)
        return editor.scope.isSuitcase
            ? "Working source: \(name) — swaps stay within it"
            : "Working source: \(name) — swaps can use any eligible piece you own"
    }

    /// Everything the header used to say about the source, for the info button.
    private var sourceInfo: String {
        var text = sourceText + "."
        if editor.scope != app.workingScope {
            text += " Style Me is now set to \(app.workingScopeName). This look keeps its own source."
        }
        return text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(originText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)

            HStack(spacing: Spacing.xs) {
                TextField("Name this look", text: $title, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused(focus, equals: .title)
                    .onSubmit(onCommitTitle)
                    .accessibilityLabel("Look name")
                    .accessibilityHint("Renames this look. The new name goes into your draft when you press Return or leave the field.")
                    .accessibilityIdentifier("editorTitleField")
                Image(systemName: "pencil")
                    .foregroundStyle(isEditingTitle ? Palette.primaryAction : Palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: HitTarget.minimum)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isEditingTitle ? Palette.primaryAction : Palette.controlBorder)
                    .frame(height: isEditingTitle ? 2 : 1)
                    .accessibilityHidden(true)
            }

            LaneLabel(lane: editor.outfit.lane)

            // The source name stays on screen; what it means for swaps sits behind the info button.
            HStack(spacing: Spacing.xxs) {
                Label {
                    Text("Working source: \(app.store.scopeName(editor.scope))")
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: editor.scope.isSuitcase ? "suitcase" : "cabinet")
                        .foregroundStyle(Palette.primaryAction)
                }
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(sourceText)
                .accessibilityIdentifier("editorSource")
                InfoButton("the working source", title: "Working source", text: sourceInfo)
            }

            if editor.scope != app.workingScope {
                Text("Style Me now uses \(app.workingScopeName)")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(1)
                    .accessibilityLabel("Style Me is now set to \(app.workingScopeName). This look keeps its own source.")
            }

            OutfitEditorSaveStateLabel(editor: editor, hasPendingText: hasPendingText, copySavedAt: copySavedAt)
        }
    }
}

/// Save state from `editor.saveState`, never claiming success before the write.
struct OutfitEditorSaveStateLabel: View {
    let editor: OutfitEditorSession
    var hasPendingText: Bool
    var copySavedAt: Date?

    private enum Display {
        case saving, failed, saved(Date), unsaved, notSavedYet(edited: Bool), clean
    }

    private var display: Display {
        let changed = editor.hasUnsavedChanges || hasPendingText
        switch editor.saveState {
        case .saving: return .saving
        case .failed: return .failed
        case let .saved(date): return changed ? .unsaved : .saved(date)
        case .unsaved:
            if !editor.outfit.isSaved { return .notSavedYet(edited: editor.outfitEditorHasEditsSinceBase || hasPendingText) }
            return changed ? .unsaved : .clean
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xxs) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    icon
                    Text(text)
                        .foregroundStyle(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let copySavedAt {
                    Label("Copy saved on this device \(copySavedAt.formatted(date: .omitted, time: .shortened))", systemImage: "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .font(.subheadline.weight(.medium))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("editorSaveState")
            if let detail {
                InfoButton("this save state", title: text, text: detail)
            }
        }
    }

    private var text: String {
        switch display {
        case .saving: "Saving…"
        case .failed: "Couldn't save — draft kept"
        case let .saved(date): "Saved on this device \(date.formatted(date: .omitted, time: .shortened))"
        case .unsaved: "Unsaved changes"
        case let .notSavedYet(edited): edited ? "Unsaved changes" : "Not saved yet"
        case .clean: "No unsaved changes"
        }
    }

    /// The longer wording behind the info button, for states that need one.
    private var detail: String? {
        switch display {
        case .failed: "Couldn't save — your previous saved version is unchanged and this draft is kept."
        case let .notSavedYet(edited): edited ? "Unsaved changes — not in Saved Looks yet." : "Not saved yet — Save adds it to Saved Looks."
        default: nil
        }
    }

    private var textColor: Color {
        switch display {
        case .failed: Palette.error
        case .saved: Palette.success
        default: Palette.primaryText
        }
    }

    @ViewBuilder private var icon: some View {
        switch display {
        case .saving:
            ProgressView().controlSize(.small)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Palette.error)
        case .saved:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.success)
        case .unsaved, .notSavedYet:
            Image(systemName: "pencil.circle").foregroundStyle(Palette.primaryAction)
        case .clean:
            Image(systemName: "checkmark.circle").foregroundStyle(Palette.secondaryText)
        }
    }
}

// MARK: - Preview card

/// Simulated On Me picture associated with this draft. Labelled Earlier after a
/// swap; Update Preview is the only control here that can start image work.
struct OutfitEditorPreviewCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let editor: OutfitEditorSession
    /// Vertical arrangement (narrow side column or large text).
    var stacked: Bool
    var onOpenProfile: () -> Void

    private var isJobRunning: Bool {
        guard let job = editor.previewJob else { return false }
        return !job.isTerminal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("On Me picture", subtitle: "Simulated · placeholder figure")
            if let entry = app.store.preview(editor.previewID) {
                let vertical = stacked || dynamicTypeSize.isAccessibilitySize
                let layout = vertical
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.m))
                layout {
                    figure(entry, vertical: vertical)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        status(for: entry)
                        jobStatus
                        updateControl
                    }
                }
            } else {
                CollapsibleText("No On Me picture for this version of the look yet. Your board works without one.",
                                summary: "No picture for this version yet.",
                                font: .subheadline, topic: "the On Me picture")
                jobStatus
                updateControl
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editorPreview")
    }

    @ViewBuilder
    private func figure(_ entry: PreviewEntry, vertical: Bool) -> some View {
        let figure = OnMePreviewFigure(pieces: entry.snapshotPieces, isEarlier: editor.previewIsEarlier)
        if vertical {
            figure.frame(maxWidth: 220).frame(maxWidth: .infinity)
        } else {
            figure.frame(width: 140)
        }
    }

    @ViewBuilder
    private func status(for entry: PreviewEntry) -> some View {
        if editor.previewIsEarlier {
            Label("Earlier picture — from before your swap", systemImage: "clock.arrow.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("earlierPreviewLabel")
        } else {
            Label("Matches this version of the look", systemImage: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
        }
        // Quality and date stay on screen; the longer explanation sits behind the info button.
        let made = "\(entry.quality.label) · made \(entry.createdAt.formatted(date: .abbreviated, time: .omitted))"
        HStack(spacing: Spacing.xxs) {
            Text(made)
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            InfoButton("this picture", title: "About this picture") {
                if editor.previewIsEarlier {
                    InfoText(text: piecesMatch(entry)
                             ? "Your pieces match this picture again. It stays in your preview history."
                             : "Your board has changed since this picture was made. It stays in your preview history; the board shows the current look.")
                }
                InfoText(text: "\(made). Not a real person and not a fit preview.")
            }
        }
    }

    private func piecesMatch(_ entry: PreviewEntry) -> Bool {
        func key(_ p: OutfitPiece) -> String { "\(p.slot.rawValue):\(p.garmentID ?? "idea-\(p.capturedName)")" }
        return Set(entry.snapshotPieces.map(key)) == Set(editor.outfit.pieces.map(key))
    }

    @ViewBuilder private var jobStatus: some View {
        switch editor.previewJob {
        case .queued?:
            HStack(spacing: Spacing.xs) {
                ProgressView().controlSize(.small)
                Text("Queued — your board stays editable")
            }
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
        case let .generating(progress)?:
            ProgressView(value: progress) {
                Text("Making a simulated picture…")
                    .font(.footnote)
                    .foregroundStyle(Palette.primaryText)
            } currentValueLabel: {
                Text("\(Int(progress * 100))% · your board stays editable")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .tint(Palette.primaryAction)
        case .saving?:
            HStack(spacing: Spacing.xs) {
                ProgressView().controlSize(.small)
                Text("Saving to your preview history…")
            }
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
        case let .failed(reason)?:
            InlineBanner(style: .error, title: "The picture didn't finish",
                         message: "\(reason) Your board and earlier pictures are unchanged.")
        case let .ready(previewID)?:
            if previewID == editor.previewID, !editor.previewIsEarlier {
                Label("New simulated picture saved to your preview history", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Palette.success)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Label("A picture finished for an earlier version of this board. It's in your preview history.", systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .reused? where !editor.previewIsEarlier:
            Label("Reused a matching picture from your history — no new image work", systemImage: "arrow.uturn.backward.circle")
                .font(.footnote)
                .foregroundStyle(Palette.success)
                .fixedSize(horizontal: false, vertical: true)
        case .reused?:
            EmptyView()
        case .cancelRequested?, .cancelled?:
            Text("Picture cancelled. Your board is unchanged.")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
        case let .notStarted(reason)?:
            InlineBanner(style: .caution, title: "No new picture was started",
                         message: "Nothing was charged: \(reason)")
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder private var updateControl: some View {
        if app.isOnMeReady {
            if editor.previewIsEarlier || editor.previewID == nil {
                Button { app.updatePreview() } label: {
                    Label("Update Preview", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(isJobRunning || editor.outfit.pieces.isEmpty)
                .accessibilityHint("Makes one simulated picture of the current board, or reuses a matching one from your history")
                .accessibilityIdentifier("updatePreviewButton")
                // The cost stays visible before the tap; how reuse works is behind the info button.
                HStack(spacing: Spacing.xxs) {
                    Text("Uses 1 sample image unit, or reuses a match")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    InfoButton("Update Preview", text: "Reuses a matching picture from your history when there is one; otherwise makes one simulated picture (1 sample image unit). Nothing happens until you tap it.")
                }
            }
        } else {
            CollapsibleText("On Me pictures are off, so this picture can't be updated. Boards work without them.",
                            summary: "On Me pictures are off.",
                            font: .caption, topic: "On Me pictures")
            Button(action: onOpenProfile) {
                Label("Set up in Profile", systemImage: "person.crop.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

// MARK: - Board

/// The look's pieces. Tapping one selects its slot and opens the swap UI.
struct OutfitEditorBoardCard: View {
    @Environment(AppModel.self) private var app

    let editor: OutfitEditorSession
    var onSelect: (OutfitSlot) -> Void

    var body: some View {
        let emptySlots = editor.outfitEditorEmptySlots
        let isEmpty = editor.outfit.pieces.isEmpty
        @Bindable var ui = app.editorUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(
                "Pieces",
                subtitle: isEmpty ? nil : "Tap a piece to swap it",
                info: isEmpty
                    ? "No pieces yet. Add one below — only pieces you own in \(app.store.scopeName(editor.scope)) are offered."
                    : "Tap a piece to see real alternatives. Only that piece changes."
            )
            if isEmpty {
                Label("No pieces yet. Add one below.", systemImage: "square.dashed")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                OutfitFlatLayView(
                    pieces: editor.outfit.pieces,
                    selectedSlot: editor.selectedSlot,
                    statusFor: { app.outfitEditorBoardBadges(for: $0, editor: editor) },
                    onTap: { onSelect($0.slot) },
                    animateIn: false
                )
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
                OutfitPieceChips(
                    pieces: editor.outfit.pieces,
                    selectedSlot: editor.selectedSlot,
                    statusFor: { app.outfitEditorBoardBadges(for: $0, editor: editor) },
                    onTap: { onSelect($0.slot) }
                )
            }
            if !emptySlots.isEmpty {
                Text("Add a piece")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityAddTraits(.isHeader)
                ChipCarousel(isExpanded: $ui.addSlotsOpen, itemsLabel: "pieces you can add") {
                    ForEach(emptySlots) { slot in
                        let isSelected = editor.selectedSlot == slot
                        Button { onSelect(slot) } label: {
                            Label("Add \(slot.label.lowercased())", systemImage: isSelected ? "checkmark" : "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityHint("Shows pieces you can add as the \(slot.label.lowercased())")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("addSlot-\(slot.rawValue)")
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editorBoard")
    }
}

// MARK: - Per-request overrides

/// Lists individually allowed Dirty/Unavailable/Archived items. Their stored status is unchanged.
struct OutfitEditorOverridesSummary: View {
    @Environment(AppModel.self) private var app
    let editor: OutfitEditorSession

    var body: some View {
        let items = app.outfitEditorActiveOverrides(editor)
        @Bindable var ui = app.editorUI
        if !items.isEmpty {
            // One row by default; the sentence for each item opens in place.
            DetailsDisclosure("For this request only", summary: "status unchanged", count: items.count,
                              systemImage: "checkmark.circle", isExpanded: $ui.overridesOpen) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(items) { garment in
                        let status = OutfitEditorCopy.statusPhrase(app.store.eligibility(of: garment, scope: editor.scope).issues)
                        let onBoard = editor.outfit.garmentIDs.contains(garment.id)
                        Text(onBoard
                             ? "Using \(status) \(garment.displayName) for this request — its status is unchanged"
                             : "\(status) \(garment.displayName) is allowed for this request but isn't on the board now — its status is unchanged")
                            .font(.footnote)
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, Spacing.xs)
            }
            .padding(.horizontal, Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("editorOverrides")
        }
    }
}

// MARK: - Notes

struct OutfitEditorNotesCard: View {
    let editor: OutfitEditorSession
    @Binding var text: String
    var focus: FocusState<OutfitEditorFocusField?>.Binding
    var isPending: Bool

    private var isEditing: Bool { focus.wrappedValue == .notes }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader("Notes", info: "Private to you. Saved with the look.")
            TextField("Add a note — for example, “tuck the blouse in”", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .font(.body)
                .foregroundStyle(Palette.primaryText)
                .focused(focus, equals: .notes)
                .padding(Spacing.s)
                .frame(minHeight: HitTarget.minimum, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                        .strokeBorder(isEditing ? Palette.primaryAction : Palette.controlBorder, lineWidth: isEditing ? 2 : 1)
                )
                .accessibilityLabel("Notes for this look")
                .accessibilityHint("Your note goes into the draft when you leave the field")
                .accessibilityIdentifier("editorNotesField")
            if isPending {
                HStack(spacing: Spacing.xxs) {
                    Text("Not in the draft yet")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    InfoButton("this note", title: "Not in the draft yet",
                               text: "Your note goes into the draft when you tap Done or leave the field.")
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Actions

struct OutfitEditorActionsCard: View {
    @Environment(AppModel.self) private var app
    let editor: OutfitEditorSession
    var canSave: Bool
    var hasPendingText: Bool
    var onSave: () -> Void
    var onSaveCopy: () -> Void
    var onDiscard: () -> Void
    var onAskStylist: () -> Void
    var onClose: () -> Void

    private var subtitle: String {
        if editor.outfit.isSaved {
            return "Save updates this look. Save as Copy keeps it as it is and adds a new look."
        }
        return "Save adds this look to Saved Looks. Save as Copy adds a separate copy."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Save this look", info: subtitle)

            if case .failed = editor.saveState {
                InlineBanner(style: .error, title: "Couldn't save on this device",
                             message: "Your previous saved version is unchanged and this draft is kept. You can try again.")
            }

            Button(action: onSave) {
                Label("Save look", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave)
            .accessibilityIdentifier("saveLookInlineButton")

            // Save and Save as Copy stay visible; the other actions sit in the More menu.
            // Discard changes still asks before it does anything.
            ActionGroup(moreIdentifier: "editorMoreActions") {
                Button(action: onSaveCopy) {
                    Label("Save as Copy", systemImage: "plus.square.on.square")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(editor.outfit.pieces.isEmpty || editor.saveState == .saving)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .accessibilityHint("Saves a separate copy; this look stays as it is")
                .accessibilityIdentifier("saveCopyButton")
            } more: {
                Button {
                    app.openStylistChat(attaching: editor.outfit)
                } label: {
                    Label("Ask about this look", systemImage: "bubble.left.and.text.bubble.right")
                }
                .accessibilityHint("Opens the stylist chat with this look attached. Nothing is sent until you ask.")
                .accessibilityIdentifier("askAboutLookButton")

                Button(action: onAskStylist) {
                    Label("Ask another stylist", systemImage: "person.2")
                }
                .accessibilityHint("Builds a local collage and prompt you can copy or share yourself")
                .accessibilityIdentifier("askStylistButton")

                Button(action: onClose) {
                    Label("Close look", systemImage: "xmark.circle")
                }
                .accessibilityHint("Leaves the editor. If there are unsaved changes you can keep the draft or discard it.")
                .accessibilityIdentifier("closeLookButton")

                Divider()

                Button(role: .destructive, action: onDiscard) {
                    Label("Discard changes", systemImage: "arrow.counterclockwise")
                }
                .disabled(!editor.outfitEditorHasEditsSinceBase && !hasPendingText)
                .accessibilityHint("Returns the look to its last saved version, after you confirm")
                .accessibilityIdentifier("discardButton")
            }
        }
        .cardStyle()
    }
}

// MARK: - Small pieces

/// One short reassurance line; the full wording opens from the info button beside it.
struct OutfitEditorFootnote: View {
    var summary: String
    var text: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Label {
                Text(summary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .foregroundStyle(Palette.secondaryText)
            }
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
            .accessibilityElement(children: .combine)
            InfoButton("what contacts a service", title: summary, text: text)
        }
    }
}

/// Brief confirmation with an optional Undo. Clears itself after a few seconds.
struct OutfitEditorNoticeBanner: View {
    let notice: OutfitEditorNotice
    var onUndo: (() -> Void)?
    var onDismiss: () -> Void

    private var tint: Color {
        switch notice.style {
        case .success: Palette.success
        case .info: Palette.primaryAction
        case .error: Palette.error
        }
    }

    private var icon: String {
        switch notice.style {
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        case .error: "exclamationmark.triangle.fill"
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the Undo button moves below the text so nothing squeezes.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        layout {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = notice.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            if let onUndo {
                Button("Undo", action: onUndo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryAction)
                    .minimumHitTarget()
                    .hoverEffect(.highlight)
                    .accessibilityIdentifier("editorNoticeUndo")
            }
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .fill(notice.style == .success ? Palette.successSurface : Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(tint.opacity(0.6), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editorNotice")
        .task(id: notice.id) {
            try? await Task.sleep(for: .seconds(onUndo == nil ? 4 : 7))
            onDismiss()
        }
    }
}

/// Wide-layout pane content when no piece is selected.
struct OutfitEditorPaneHint: View {
    var scopeName: String

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: "hand.tap")
                .font(.largeTitle)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            Text("Choose a piece to swap")
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .multilineTextAlignment(.center)
            CollapsibleText("Tap any piece on the board to see real alternatives from \(scopeName). Only that piece changes, and nothing is sent anywhere.",
                            summary: "Tap any piece on the board.",
                            font: .subheadline, centered: true, topic: "swapping a piece")
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("swapPaneHint")
    }
}
