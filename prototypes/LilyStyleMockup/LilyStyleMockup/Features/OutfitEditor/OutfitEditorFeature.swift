import SwiftUI

// MARK: - UI state

/// Editor UI state that must survive rotation, resizing and navigation. The draft
/// itself (pieces, selected slot, color filter, per-request overrides, preview) lives
/// in `app.editor`; this holds in-progress text, the sheet detent and confirmations.
@Observable
final class OutfitEditorUIState {
    /// Uncommitted title text (committed on Return / leaving the field).
    var titleDraft: OutfitEditorTextDraft?
    /// Uncommitted notes text (committed when leaving the field).
    var notesDraft: OutfitEditorTextDraft?
    /// Detent of the compact swap sheet.
    var swapDetent: PresentationDetent = .medium
    /// Last slot shown in the swap UI, so the sheet keeps its content while closing.
    var lastPresentedSlot: OutfitSlot?
    /// Brief confirmation after a swap, removal, override or Mark clean.
    var notice: OutfitEditorNotice?
    /// Last Save as Copy from this editor session (the draft stays open afterwards).
    var lastCopy: OutfitEditorCopyRecord?
    /// Open state of the calm-screen disclosures, kept here so rotation and the
    /// sheet/pane switch don't close them.
    var overridesOpen = false
    var addSlotsOpen = false
    var colorFiltersOpen = false
    var pieceChipsOpen = false

    init() {}

    func titleText(for editor: OutfitEditorSession) -> String? {
        guard let titleDraft, titleDraft.editorID == editor.id else { return nil }
        return titleDraft.text
    }

    func notesText(for editor: OutfitEditorSession) -> String? {
        guard let notesDraft, notesDraft.editorID == editor.id else { return nil }
        return notesDraft.text
    }

    func notice(for editor: OutfitEditorSession) -> OutfitEditorNotice? {
        guard let notice, notice.editorID == editor.id else { return nil }
        return notice
    }

    func copySavedAt(for editor: OutfitEditorSession) -> Date? {
        guard let lastCopy, lastCopy.editorID == editor.id else { return nil }
        return lastCopy.savedAt
    }

    /// Shows a confirmation and (unless a toast already speaks it) announces it to VoiceOver.
    func post(_ notice: OutfitEditorNotice, announce: Bool = true) {
        self.notice = notice
        if announce {
            OutfitEditorCopy.announce([notice.title, notice.detail].compactMap { $0 }.joined(separator: ". "))
        }
    }

    func clearNotice(_ id: UUID) {
        if notice?.id == id { notice = nil }
    }

    /// Undo from a confirmation. Editor undo applies only if nothing changed since;
    /// Mark clean undo applies only if it's still the latest store undo entry.
    func performUndo(for notice: OutfitEditorNotice, app: AppModel) {
        guard let undo = notice.undo, let editor = app.editor, editor.id == notice.editorID else { return }
        switch undo {
        case let .editorEdit(revision):
            guard editor.draftRevision == revision, editor.canUndo else {
                post(OutfitEditorNotice(editorID: editor.id, style: .info, title: "Nothing undone",
                                        detail: "The look changed since — use Undo at the top to step back."))
                return
            }
            app.undoEdit()
            post(OutfitEditorNotice(editorID: editor.id, style: .info, title: "Undone", detail: "The look is back to how it was."))
        case let .markClean(name):
            guard app.store.undoStack.last?.label == "Mark \(name) clean", let message = app.store.undoLast() else {
                post(OutfitEditorNotice(editorID: editor.id, style: .info, title: "Nothing undone",
                                        detail: "\(name) changed since, so its status was left as it is."))
                return
            }
            if app.toast?.actionTitle == "Undo" { app.toast = nil }
            post(OutfitEditorNotice(editorID: editor.id, style: .info, title: message))
        }
    }
}

struct OutfitEditorTextDraft: Equatable {
    var editorID: UUID
    var text: String
}

struct OutfitEditorCopyRecord: Equatable {
    var editorID: UUID
    var savedAt: Date
}

struct OutfitEditorNotice: Identifiable, Equatable {
    enum Style: Equatable { case success, info, error }
    enum Undo: Equatable {
        /// Editor undo, valid while the draft is still at this revision.
        case editorEdit(revision: Int)
        /// Store undo for an individual Mark clean.
        case markClean(name: String)
    }

    let id = UUID()
    var editorID: UUID
    var style: Style = .success
    var title: String
    var detail: String?
    var undo: Undo?
}

// MARK: - Screen

/// Outfit editor and swap. Works on `app.editor` (a draft separate from the
/// committed look). Opening, tapping pieces, scrolling and filtering dispatch
/// nothing; only the explicit Update Preview button may start a (simulated) image job.
struct OutfitEditorScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let editor = app.editor {
            OutfitEditorWorkspace(editor: editor)
                .id(editor.id)
        } else {
            ScrollView {
                EmptyStateView(
                    title: "No look open",
                    message: "Open a look from your Style Me results or Saved Looks to swap pieces and save it. Saved looks stay in Saved Looks.",
                    systemImage: "hanger",
                    actionTitle: "Go to Style Me"
                ) {
                    dismiss()
                    app.select(.styleMe)
                }
                .padding(.top, Spacing.xxl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedScreenBackground()
            .navigationTitle("Edit Look")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Workspace

/// Adaptive editor layout. Compact: one column with the swap UI in a sheet.
/// Intermediate/wide: the board stays visible with a trailing swap pane.
struct OutfitEditorWorkspace: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let editor: OutfitEditorSession

    @FocusState private var focus: OutfitEditorFocusField?
    @State private var confirmDiscard = false
    @State private var confirmClose = false
    /// Mirrors the layout decision so actions outside the GeometryReader know
    /// whether the swap UI is a sheet (which must close before a root sheet opens).
    @State private var layoutUsesPane = false

    private var ui: OutfitEditorUIState { app.editorUI }
    private var motion: Animation? { reduceMotion ? nil : .snappy(duration: 0.28) }
    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }
    private var scopeName: String { app.store.scopeName(editor.scope) }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let widthClass = WidthClass(width: width)
            let usesPane = widthClass == .wide || (widthClass == .intermediate && !isAccessibilitySize)
            layout(width: width, widthClass: widthClass, usesPane: usesPane)
                .sheet(isPresented: swapSheetBinding(usesPane: usesPane)) { swapSheet }
                .onChange(of: usesPane, initial: true) { _, newValue in layoutUsesPane = newValue }
        }
        .themedScreenBackground()
        .navigationTitle("Edit Look")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { editorToolbar }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
        .confirmationDialog("Discard changes to this look?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { discardChanges() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text(editor.outfit.isSaved
                 ? "The look goes back to its last saved version. You can undo this."
                 : "The look goes back to how it was when you opened it. You can undo this.")
        }
        .confirmationDialog("Close this look?", isPresented: $confirmClose, titleVisibility: .visible) {
            if canReopenDraft {
                Button("Keep draft") { keepDraftAndLeave() }
            } else if !editor.outfit.pieces.isEmpty {
                Button("Save look") { saveAndLeave() }
            }
            Button("Discard changes", role: .destructive) { closeAndLeave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(closeMessage)
        }
        .onChange(of: focus) { oldValue, newValue in
            if oldValue == .title, newValue != .title { commitTitle() }
            if oldValue == .notes, newValue != .notes { commitNotes() }
        }
        .onChange(of: editor.selectedSlot, initial: true) { _, slot in
            if let slot { ui.lastPresentedSlot = slot }
        }
        .onDisappear { commitTextDrafts() }
    }

    // MARK: Layout

    /// One stable structure for every width (the main column keeps its identity, so
    /// focus, drafts and scroll survive rotation); only the trailing pane comes and goes.
    private func layout(width: CGFloat, widthClass: WidthClass, usesPane: Bool) -> some View {
        let paneWidth: CGFloat = isAccessibilitySize ? 420 : (widthClass == .wide ? 380 : 320)
        let paneVisible = usesPane && (widthClass == .wide || editor.selectedSlot != nil)
        return HStack(spacing: 0) {
            mainColumn(contentWidth: paneVisible ? width - paneWidth - 1 : width)
                .frame(maxWidth: .infinity)
            if paneVisible {
                Rectangle()
                    .fill(Palette.divider)
                    .frame(width: 1)
                    .ignoresSafeArea(edges: .bottom)
                    .accessibilityHidden(true)
                swapPane
                    .frame(width: paneWidth)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    private var showsPreviewSection: Bool {
        if app.store.preview(editor.previewID) != nil { return true }
        if editor.previewJob != nil { return true }
        return app.isOnMeReady && !editor.outfit.pieces.isEmpty
    }

    private func mainColumn(contentWidth: CGFloat) -> some View {
        let previewColumn: CGFloat = 260
        let twoColumn = showsPreviewSection && contentWidth >= 640 && !isAccessibilitySize
        let maxContent: CGFloat = twoColumn ? 1040 : 720

        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                if editor.selectedSlot == nil, let notice = ui.notice(for: editor) {
                    noticeBanner(notice)
                }
                OutfitEditorHeaderView(
                    editor: editor,
                    title: titleBinding,
                    focus: $focus,
                    hasPendingText: hasPendingTextDrafts,
                    copySavedAt: ui.copySavedAt(for: editor),
                    onCommitTitle: commitTitle
                )
                if twoColumn {
                    HStack(alignment: .top, spacing: Spacing.l) {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            boardSection()
                        }
                        previewCard(stacked: true)
                            .frame(width: previewColumn)
                    }
                } else {
                    if showsPreviewSection { previewCard(stacked: false) }
                    boardSection()
                }
                OutfitEditorActionsCard(
                    editor: editor,
                    canSave: canSave,
                    hasPendingText: hasPendingTextDrafts,
                    onSave: { save(asCopy: false) },
                    onSaveCopy: { save(asCopy: true) },
                    onDiscard: { commitTextDrafts(); afterSwapSheetCloses { confirmDiscard = true } },
                    onAskStylist: askAnotherStylist,
                    onClose: requestClose
                )
                OutfitEditorFootnote(
                    summary: "Nothing is sent until you tap Update Preview.",
                    text: "Opening this look, tapping pieces, scrolling and color filters don't contact any service. Only Update Preview makes a (simulated) picture, and only when you tap it. This prototype keeps drafts while the app is open; it doesn't restore them after relaunch."
                )
            }
            .padding(Spacing.m)
            .frame(maxWidth: maxContent)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func boardSection() -> some View {
        OutfitEditorBoardCard(editor: editor, onSelect: select)
        OutfitEditorOverridesSummary(editor: editor)
        OutfitEditorNotesCard(editor: editor, text: notesBinding, focus: $focus,
                              isPending: ui.notesText(for: editor).map { $0 != editor.outfit.notes } ?? false)
    }

    private func previewCard(stacked: Bool) -> some View {
        OutfitEditorPreviewCard(editor: editor, stacked: stacked) {
            afterSwapSheetCloses { app.open(.profile, compact: sizeClass == .compact) }
        }
    }

    // MARK: Swap UI

    private func swapSheetBinding(usesPane: Bool) -> Binding<Bool> {
        Binding(
            get: { !usesPane && editor.selectedSlot != nil },
            set: { presented in
                // Only a user dismissal in compact layout clears the selection; a layout
                // change that hides the sheet keeps it so the pane can take over.
                if !presented, !usesPane { editor.selectedSlot = nil }
            }
        )
    }

    private var detentBinding: Binding<PresentationDetent> {
        Binding(
            get: { isAccessibilitySize ? .large : ui.swapDetent },
            set: { ui.swapDetent = $0 }
        )
    }

    @ViewBuilder
    private var swapSheet: some View {
        if let slot = editor.selectedSlot ?? ui.lastPresentedSlot {
            NavigationStack {
                OutfitEditorSwapPicker(
                    editor: editor,
                    slot: slot,
                    presentation: .sheet,
                    onClose: { editor.selectedSlot = nil },
                    onCommitDrafts: commitTextDrafts
                )
                .id(slot)
            }
            .presentationDetents(isAccessibilitySize ? [.large] : [.medium, .large], selection: detentBinding)
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationContentInteraction(.scrolls)
            .presentationBackground(Palette.background)
            .environment(app)
            .tint(Palette.primaryAction)
        }
    }

    @ViewBuilder
    private var swapPane: some View {
        if let slot = editor.selectedSlot {
            OutfitEditorSwapPicker(
                editor: editor,
                slot: slot,
                presentation: .pane,
                onClose: { withAnimation(motion) { editor.selectedSlot = nil } },
                onCommitDrafts: commitTextDrafts
            )
            .id(slot)
        } else {
            OutfitEditorPaneHint(scopeName: scopeName)
        }
    }

    private func noticeBanner(_ notice: OutfitEditorNotice) -> some View {
        OutfitEditorNoticeBanner(
            notice: notice,
            onUndo: notice.undo == nil ? nil : { withAnimation(motion) { ui.performUndo(for: notice, app: app) } },
            onDismiss: { withAnimation(motion) { ui.clearNotice(notice.id) } }
        )
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { undo() } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!editor.canUndo && !hasPendingTextDrafts)
            .keyboardShortcut("z", modifiers: .command)
            .accessibilityHint("Undoes the last change to this look")
            .accessibilityIdentifier("undoButton")

            Button { redo() } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!editor.canRedo)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .accessibilityHint("Redoes the change you just undid")
            .accessibilityIdentifier("redoButton")

            Button { save(asCopy: false) } label: {
                Text("Save").fontWeight(.semibold)
            }
            .disabled(!canSave)
            .keyboardShortcut("s", modifiers: .command)
            .accessibilityLabel("Save look")
            .accessibilityHint(editor.outfit.isSaved ? "Updates this saved look on this device" : "Adds this look to Saved Looks on this device")
            .accessibilityIdentifier("saveLookButton")
        }
    }

    // MARK: Text drafts

    private var titleBinding: Binding<String> {
        Binding(
            get: { ui.titleText(for: editor) ?? editor.outfit.title },
            set: { newValue in
                // The title field wraps (vertical axis) so long names stay readable at
                // large text sizes; Return arrives as a newline and commits instead.
                if newValue.contains(where: \.isNewline) {
                    ui.titleDraft = OutfitEditorTextDraft(editorID: editor.id, text: newValue.filter { !$0.isNewline })
                    commitTitle()
                    focus = nil
                } else {
                    ui.titleDraft = OutfitEditorTextDraft(editorID: editor.id, text: newValue)
                }
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { ui.notesText(for: editor) ?? editor.outfit.notes },
            set: { ui.notesDraft = OutfitEditorTextDraft(editorID: editor.id, text: $0) }
        )
    }

    private var hasPendingTextDrafts: Bool {
        let title = ui.titleText(for: editor).map { $0 != editor.outfit.title } ?? false
        let notes = ui.notesText(for: editor).map { $0 != editor.outfit.notes } ?? false
        return title || notes
    }

    private func commitTitle() {
        guard let text = ui.titleText(for: editor) else { return }
        ui.titleDraft = nil
        guard app.editor?.id == editor.id else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ui.post(OutfitEditorNotice(editorID: editor.id, style: .info, title: "A look needs a name",
                                       detail: "Kept “\(editor.outfit.title)”."))
            return
        }
        guard trimmed != editor.outfit.title else { return }
        app.renameDraft(trimmed)
    }

    private func commitNotes() {
        guard let text = ui.notesText(for: editor) else { return }
        ui.notesDraft = nil
        guard app.editor?.id == editor.id else { return }
        app.outfitEditorUpdateNotes(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func commitTextDrafts() {
        commitTitle()
        commitNotes()
    }

    private func discardTextDrafts() {
        ui.titleDraft = nil
        ui.notesDraft = nil
        focus = nil
    }

    // MARK: Actions

    private var canSave: Bool {
        guard !editor.outfit.pieces.isEmpty, editor.saveState != .saving else { return false }
        if case .failed = editor.saveState { return true }
        return editor.hasUnsavedChanges || hasPendingTextDrafts
    }

    private func select(_ slot: OutfitSlot) {
        focus = nil
        withAnimation(motion) { editor.selectedSlot = slot }
    }

    private func undo() {
        let hadPendingText = hasPendingTextDrafts
        discardTextDrafts()
        if hadPendingText {
            OutfitEditorCopy.announce("Typing undone")
            return
        }
        guard editor.canUndo else { return }
        withAnimation(motion) { app.undoEdit() }
        OutfitEditorCopy.announce("Undone")
    }

    private func redo() {
        discardTextDrafts()
        guard editor.canRedo else { return }
        withAnimation(motion) { app.redoEdit() }
        OutfitEditorCopy.announce("Redone")
    }

    private func save(asCopy: Bool) {
        commitTextDrafts()
        focus = nil
        if asCopy {
            if let savedAt = app.outfitEditorSaveCopy() {
                ui.lastCopy = OutfitEditorCopyRecord(editorID: editor.id, savedAt: savedAt)
            }
        } else {
            app.saveEditor(asCopy: false)
        }
    }

    private func discardChanges() {
        discardTextDrafts()
        withAnimation(motion) { app.outfitEditorDiscardChanges() }
        ui.post(OutfitEditorNotice(editorID: editor.id, style: .info, title: "Changes discarded",
                                   detail: "Undo brings them back.",
                                   undo: .editorEdit(revision: editor.draftRevision)))
    }

    private func askAnotherStylist() {
        commitTextDrafts()
        let outfit = editor.outfit
        afterSwapSheetCloses { app.present(.askStylist(.outfit(outfit))) }
    }

    /// Root sheets and dialogs can't appear over the compact swap sheet (which allows
    /// background taps at its medium height), so close it first.
    private func afterSwapSheetCloses(_ present: @escaping () -> Void) {
        if !layoutUsesPane, editor.selectedSlot != nil {
            editor.selectedSlot = nil
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                present()
            }
        } else {
            present()
        }
    }

    private func requestClose() {
        commitTextDrafts()
        focus = nil
        if editor.outfitEditorHasEditsSinceBase {
            afterSwapSheetCloses { confirmClose = true }
        } else {
            closeAndLeave()
        }
    }

    /// A draft of a saved look or a Style Me result reopens from where it came from.
    /// A brand-new look has no entry point to come back to, so it isn't offered "Keep draft".
    private var canReopenDraft: Bool {
        if case .new = editor.origin { return false }
        return true
    }

    private var closeMessage: String {
        switch editor.origin {
        case .saved:
            return "You have unsaved changes. Keep the draft to come back to it while the app is open, or discard them. Your saved version doesn't change either way."
        case .result:
            return "You have unsaved changes. Keep the draft to come back to it from your Style Me results while the app is open, or discard them."
        case .new:
            return editor.outfit.pieces.isEmpty
                ? "This new look has no pieces yet, so there's nothing to save. Discard it to leave."
                : "This new look isn't saved. Save it to Saved Looks, or discard it."
        }
    }

    private func keepDraftAndLeave() {
        editor.selectedSlot = nil
        dismiss()
        let whereFrom = if case .result = editor.origin { "from your Style Me results" } else { "from Saved Looks" }
        app.showToast("Draft kept — open this look again \(whereFrom) to continue (while the app is open).", style: .info)
    }

    private func saveAndLeave() {
        save(asCopy: false)
        if case .saved = editor.saveState { closeAndLeave() }
    }

    private func closeAndLeave() {
        let id = editor.id
        editor.selectedSlot = nil
        ui.titleDraft = nil
        ui.notesDraft = nil
        if ui.notice?.editorID == id { ui.notice = nil }
        dismiss()
        // Close the session after the pop so the screen doesn't flash its empty state.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            if app.editor?.id == id { app.closeEditor() }
        }
    }
}

// MARK: - Previews

/// Fixture-backed models for previews (fictional demo data only).
enum OutfitEditorPreviewModels {
    static func saved(_ outfitID: String = "o-interview", selecting slot: OutfitSlot? = nil) -> AppModel {
        let model = AppModel.preview
        model.openEditor(forSaved: outfitID)
        model.editor?.selectedSlot = slot
        return model
    }
}

#Preview("Saved look") {
    NavigationStack { OutfitEditorScreen() }
        .previewEnvironment(OutfitEditorPreviewModels.saved())
}

#Preview("Swap — bottoms") {
    NavigationStack { OutfitEditorScreen() }
        .previewEnvironment(OutfitEditorPreviewModels.saved(selecting: .bottom))
}

#Preview("Dirty piece on a saved look") {
    NavigationStack { OutfitEditorScreen() }
        .previewEnvironment(OutfitEditorPreviewModels.saved("o-lace-date", selecting: .top))
}

#Preview("No look open") {
    NavigationStack { OutfitEditorScreen() }
        .previewEnvironment()
}
