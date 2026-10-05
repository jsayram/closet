import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

enum GarmentEditorAddField: Hashable {
    case name, shade, brand, size, fabric, notes, link
}

/// Add Item: a root sheet with its own NavigationStack. Every intake route and
/// field is optional; the only required step is an explicit choice of how the
/// item is saved (I own this / Wishlist / Inspiration). Nothing is written to the
/// closet until that choice, and nothing calls a service except the explicit
/// "Suggest a description" button.
struct AddGarmentView: View {
    var prefill: AddGarmentPrefill?

    @Environment(AppModel.self) private var app
    @State private var showDiscardDialog = false
    @State private var showOwnershipDialog = false
    @State private var showStartOverDialog = false
    @State private var didPrepare = false
    @State private var resumedDraft = false
    @FocusState private var focus: GarmentEditorAddField?

    init(prefill: AddGarmentPrefill?) {
        self.prefill = prefill
    }

    private var draftKey: String { prefill?.id.uuidString ?? "blank" }

    private var draft: Binding<GarmentEditorDraft> {
        let ui = app.garmentEditorUI
        let key = draftKey
        return Binding(
            get: { ui.draft ?? GarmentEditorDraft(key: key) },
            set: { ui.draft = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    if app.garmentEditorUI.draft?.key == draftKey {
                        content(width: proxy.size.width)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.xl)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .themedScreenBackground()
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancelTapped)
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("addGarmentCancel")
                        .confirmationDialog("Discard this item?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
                            Button("Discard item", role: .destructive, action: discard)
                            Button("Keep editing", role: .cancel) {}
                        } message: {
                            Text("Nothing has been added to your closet yet. The photo copy made for this draft will be removed.")
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { showOwnershipDialog = true }
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("addGarmentSaveButton")
                        .accessibilityHint("Asks how to save it: owned, wishlist or inspiration.")
                        .confirmationDialog("How should this be saved?", isPresented: $showOwnershipDialog, titleVisibility: .visible) {
                            Button("Add to my closet — I own this") { save(as: .owned) }
                            Button("Save to Wishlist") { save(as: .wishlisted) }
                            Button("Save as Inspiration") { save(as: .inspiration) }
                            Button("Keep editing", role: .cancel) {}
                        } message: {
                            Text("A photo or a name doesn't make it yours. Choose how to save “\(draft.wrappedValue.finalName)”.")
                        }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focus = nil }
                }
            }
        }
        .interactiveDismissDisabled(app.garmentEditorUI.draft?.hasContent ?? false)
        .onAppear(perform: prepareDraft)
    }

    // MARK: Layout

    /// Two columns only when both stay readable (intermediate/wide sheets); otherwise one.
    @ViewBuilder
    private func content(width: CGFloat) -> some View {
        let hasPhoto = draft.wrappedValue.photo != nil
        let widthClass = WidthClass(width: width)
        if widthClass >= .intermediate, width >= 760 {
            let leftWidth = min(440, (width - Spacing.m * 3) * 0.45)
            VStack(alignment: .leading, spacing: Spacing.m) {
                header
                HStack(alignment: .top, spacing: Spacing.m) {
                    VStack(spacing: Spacing.m) {
                        GarmentEditorAddPhotoCard(draft: draft, focus: $focus)
                        if hasPhoto { GarmentEditorSuggestCard(draft: draft) }
                    }
                    .frame(width: leftWidth)
                    VStack(spacing: Spacing.m) {
                        GarmentEditorAddNameCard(draft: draft, focus: $focus)
                        GarmentEditorAddBasicsCard(draft: draft, focus: $focus)
                        GarmentEditorAddMoreCard(draft: draft, focus: $focus)
                        GarmentEditorAddSaveCard(draft: draft, onSave: save(as:))
                    }
                }
            }
            .padding(Spacing.m)
            .readableWidth(1100)
        } else {
            VStack(alignment: .leading, spacing: Spacing.m) {
                header
                GarmentEditorAddPhotoCard(draft: draft, focus: $focus)
                if hasPhoto { GarmentEditorSuggestCard(draft: draft) }
                GarmentEditorAddNameCard(draft: draft, focus: $focus)
                GarmentEditorAddBasicsCard(draft: draft, focus: $focus)
                GarmentEditorAddMoreCard(draft: draft, focus: $focus)
                GarmentEditorAddSaveCard(draft: draft, onSave: save(as:))
            }
            .padding(Spacing.m)
            .readableWidth(720)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Add a piece")
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText("Describe it your way. Everything is optional — at the end you choose how it's saved.",
                            summary: "Everything here is optional.", threshold: 1, font: .subheadline, topic: "adding a piece")
            if resumedDraft {
                InlineBanner(style: .info, title: "Your unsaved item is still here",
                             message: "Pick up where you left off, or start over.",
                             actionTitle: "Start over") { showStartOverDialog = true }
                    .confirmationDialog("Start over?", isPresented: $showStartOverDialog, titleVisibility: .visible) {
                        Button("Clear this item", role: .destructive, action: startOver)
                        Button("Keep editing", role: .cancel) {}
                    } message: {
                        Text("What you entered and the photo copy made for this draft will be removed. Nothing in your closet changes.")
                    }
            }
        }
    }

    // MARK: Draft lifecycle

    private func prepareDraft() {
        guard !didPrepare else { return }
        didPrepare = true
        let ui = app.garmentEditorUI
        if let existing = ui.draft {
            if existing.key == draftKey {
                resumedDraft = existing.hasContent
                return
            }
            let hadContent = existing.hasContent
            ui.discardDraft()
            if hadContent {
                app.showToast("An earlier unsaved item was cleared to start this one. Nothing in your closet changed.", style: .info)
            }
        }
        ui.draft = GarmentEditorDraft(key: draftKey, prefill: prefill)
        if let data = prefill?.droppedImageData {
            Task {
                if let problem = await ui.importDraftPhoto(data, origin: .drop) {
                    app.showToast(problem, style: .error)
                }
            }
        }
    }

    private func startOver() {
        let ui = app.garmentEditorUI
        ui.discardDraft()
        ui.draft = GarmentEditorDraft(key: draftKey, prefill: prefill)
        resumedDraft = false
    }

    private func cancelTapped() {
        if app.garmentEditorUI.draft?.hasContent == true {
            showDiscardDialog = true
        } else {
            discard()
        }
    }

    private func discard() {
        app.garmentEditorUI.discardDraft()
        app.sheet = nil
    }

    /// Explicit save with an explicit ownership choice. Saved to Main Closet first;
    /// linked to a suitcase only if she turned that on.
    private func save(as ownership: OwnershipStatus) {
        let ui = app.garmentEditorUI
        guard ui.draft != nil else { return }
        ui.cancelDraftProcessing()
        ui.suggestionTask?.cancel()
        ui.suggestionTask = nil
        guard let finished = ui.draft else { return }
        let saved = app.store.addGarment(finished.makeGarment(ownership: ownership))
        var suitcaseNote: String?
        if finished.alsoAddToSuitcase, let suitcaseID = finished.intoSuitcaseID, let suitcase = app.store.suitcase(suitcaseID), !suitcase.isArchived {
            if ownership == .owned {
                // Saved to Main Closet first; linked only because she turned this on.
                let result = app.store.addMembers([saved.id], to: suitcaseID)
                if result.added.isEmpty { suitcaseNote = "It wasn't added to \(suitcase.name)." }
            } else {
                // Suitcases hold clothes she owns; Wishlist/Inspiration never join one.
                suitcaseNote = "Not added to \(suitcase.name) — only items you own go in suitcases."
            }
        }
        if finished.photo?.usingProcessed != true, let processed = finished.photo?.processedFilename, finished.photo?.state != .ready {
            GarmentEditorPhotoFiles.delete(processed)
        }
        ui.draft = nil
        if let error = app.store.lastSaveError {
            app.showToast("\(error) The item is kept for this session.", style: .error)
        } else if let suitcaseNote {
            app.showToast("Saved on this device. \(suitcaseNote)", style: .info)
        } else {
            app.showToast("Saved on this device")
        }
        app.sheet = nil
    }
}

// MARK: - Draft photo import

extension GarmentEditorUIState {
    /// Original-first import: validates, writes the untouched bytes to this device,
    /// then attaches them to the draft. Returns a user-facing problem, if any.
    @MainActor
    func importDraftPhoto(_ data: Data, origin: GarmentEditorPhotoOrigin) async -> String? {
        if let problem = GarmentEditorPhotoFiles.problem(with: data) { return problem }
        guard let key = draft?.key else { return nil }
        do {
            let filename = try await GarmentEditorPhotoFiles.saveOriginal(data)
            guard draft?.key == key else {
                GarmentEditorPhotoFiles.delete(filename)
                return nil
            }
            cancelDraftProcessing()
            guard var current = draft else { return nil }
            if let old = current.photo {
                GarmentEditorPhotoFiles.delete(old.originalFilename)
                GarmentEditorPhotoFiles.delete(old.processedFilename)
            }
            current.photo = GarmentEditorDraftPhoto(originalFilename: filename, origin: origin)
            current.textOnlyChosen = false
            if current.suggestion.phase == .working || !current.suggestion.items.isEmpty {
                suggestionTask?.cancel()
                suggestionTask = nil
                current.suggestion.items = []
                current.suggestion.phase = .discarded
            }
            draft = current
            UIAccessibility.post(notification: .announcement, argument: "Original saved on this device")
            return nil
        } catch {
            return "Couldn't save the photo on this device. Nothing changed — try again."
        }
    }
}

// MARK: - Photo card

struct GarmentEditorAddPhotoCard: View {
    @Binding var draft: GarmentEditorDraft
    var focus: FocusState<GarmentEditorAddField?>.Binding

    @Environment(AppModel.self) private var app
    @State private var photosItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var cameraUnavailable = false
    @State private var importing = false
    @State private var notice: Notice?
    @State private var isDropTargeted = false
    @State private var showRemovePhotoDialog = false

    enum Notice: Equatable {
        case error(String)
        case text(String)
        case existingGarment(String)
    }

    var body: some View {
        CardSection("Photo", subtitle: "Optional",
                    info: "Text alone is fine — a photo can be added later. Paste works after you copy a photo or a link. Photos only shares the picture you pick. Up to 50 MB per photo in the demo. On iPad, drag a photo or a product link onto the image to preview it here.",
                    systemImage: "photo") {
            photoArea
            if importing {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                    Text("Saving the original on this device…")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }
            if let photo = draft.photo {
                GarmentEditorOriginalSavedLabel(detail: "\(photo.origin.label). It stays unchanged; any cleanup makes a separate copy.")
            } else if draft.textOnlyChosen {
                CollapsibleText("Text-only item — it will show a labelled representative image. Add a photo any time.",
                                summary: "Text-only item.", threshold: 1, topic: "text-only items")
            }
            intakeButtons
            notices
            if let photo = draft.photo {
                GarmentEditorProcessingPanel(
                    phase: processingPhase(photo),
                    originalFilename: photo.originalFilename,
                    onProcess: {
                        app.garmentEditorUI.startDraftProcessing(fast: app.fastMocks, simulateFailure: app.scenario == .saveFailure)
                    },
                    onCancel: { app.garmentEditorUI.cancelDraftProcessing() },
                    onUseProcessed: { draft.photo?.usingProcessed = true },
                    onKeepOriginal: {
                        GarmentEditorPhotoFiles.delete(draft.photo?.processedFilename)
                        draft.photo?.processedFilename = nil
                        draft.photo?.usingProcessed = false
                        draft.photo?.state = .skipped
                    },
                    onReset: { draft.photo?.usingProcessed = false }
                )
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            GarmentEditorCameraPicker(
                onImage: { data in
                    showCamera = false
                    importImage(data, origin: .camera)
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .onChange(of: photosItem) { _, item in
            guard let item else { return }
            loadPickedPhoto(item)
        }
    }

    // MARK: Photo area (also the iPad drop target)

    private var photoArea: some View {
        Group {
            GarmentEditorImageWell(highlighted: isDropTargeted) {
                if let photo = draft.photo {
                    GarmentEditorStoredPhoto(filename: photo.activeFilename)
                } else {
                    VStack(spacing: Spacing.xs) {
                        GarmentArtwork(kind: draft.kind, hex: draft.color?.hex, showsWell: false)
                            .frame(maxWidth: 150)
                        Text(isDropTargeted ? "Release to add" : "No photo yet")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                StatusBadge(kind: imageBadge, compact: true)
                    .padding(Spacing.xs)
            }
            .frame(maxWidth: 340)
            .frame(maxWidth: .infinity)
            .dropDestination(for: GarmentEditorDropItem.self) { items, _ in
                guard let first = items.first else { return false }
                handle(first.incoming, origin: .drop)
                return true
            } isTargeted: { targeted in
                isDropTargeted = targeted
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(photoAreaLabel)
            .accessibilityAddTraits(.isImage)
            .accessibilityHint("You can also drop a photo or a link here on iPad.")
            .accessibilityIdentifier("addGarmentPhotoArea")
        }
    }

    private var imageBadge: BadgeKind {
        if let photo = draft.photo {
            return photo.usingProcessed ? .custom("Your photo · processed", "wand.and.stars") : .custom("Your photo", "camera")
        }
        return draft.textOnlyChosen ? .textOnly : .representative
    }

    private var photoAreaLabel: String {
        if let photo = draft.photo {
            return photo.usingProcessed ? "Your photo, processed copy in use. The original is kept." : "Your photo, original. \(photo.origin.label)."
        }
        return "No photo yet. A representative image is shown."
    }

    // MARK: Intake

    /// Photos and Paste stay visible because both are system controls that only hand
    /// over what she picks. Camera, Text only and Remove photo sit in the More menu.
    private var intakeButtons: some View {
        ActionGroup(moreIdentifier: "addPhotoMoreMenu") {
            PhotosPicker(selection: $photosItem, matching: .images, preferredItemEncoding: .current) {
                Label(draft.photo == nil ? "Photos" : "Choose another", systemImage: "photo.on.rectangle")
            }
            .garmentEditorIntakeStyle()
            .accessibilityIdentifier("photosPickerButton")
            .accessibilityHint("Pick one photo or screenshot. Only the picture you choose is shared with the app.")

            PasteButton(supportedContentTypes: [.image, .url, .plainText]) { providers in
                GarmentEditorIncoming.load(providers) { incoming in
                    handle(incoming, origin: .paste)
                }
            }
            .garmentEditorIntakeStyle()
            .fixedSize()
            .accessibilityIdentifier("pasteButton")
        } more: {
            Button("Camera", systemImage: "camera", action: cameraTapped)
                .accessibilityHint("Take a photo of one garment.")
                .accessibilityIdentifier("cameraButton")
            if draft.photo == nil {
                Button("Text only", systemImage: "text.alignleft", action: textOnlyTapped)
                    .accessibilityHint("Skip the photo and describe it in words.")
                    .accessibilityIdentifier("textOnlyButton")
            } else {
                // Asks first, and the dialog says what goes.
                Button("Remove photo…", systemImage: "trash", role: .destructive) { showRemovePhotoDialog = true }
                    .accessibilityHint("Removes the unsaved photo copy. The rest of the form stays.")
                    .accessibilityIdentifier("removeDraftPhotoButton")
            }
        }
        .confirmationDialog("Remove this photo?", isPresented: $showRemovePhotoDialog, titleVisibility: .visible) {
            Button("Remove photo", role: .destructive, action: removePhoto)
            Button("Keep photo", role: .cancel) {}
        } message: {
            Text("Removes the unsaved photo copy. The rest of the form stays.")
        }
    }

    @ViewBuilder private var notices: some View {
        if cameraUnavailable {
            InlineBanner(style: .info, title: "Camera isn't available here — use Photos, Paste or text")
        }
        if !draft.sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, draft.photo == nil {
            InlineBanner(style: .info, title: "Link saved with this item",
                         message: "A link isn't a photo — the item can be saved now and a photo added later")
        }
        switch notice {
        case let .error(message)?:
            InlineBanner(style: .error, title: message)
        case let .text(text)?:
            InlineBanner(style: .info, title: "That's text, not a photo or a link",
                         message: "“\(String(text.prefix(60)))”",
                         actionTitle: "Use as the name") {
                draft.name = String(text.prefix(60))
                notice = nil
            }
        case let .existingGarment(name)?:
            InlineBanner(style: .info, title: "“\(name)” is already in your closet",
                         message: "Nothing was duplicated. Add a different piece here, or open that item to edit it.")
        case nil:
            EmptyView()
        }
    }

    private func cameraTapped() {
        notice = nil
        if GarmentEditorCameraPicker.isAvailable {
            cameraUnavailable = false
            showCamera = true
        } else {
            cameraUnavailable = true
            UIAccessibility.post(notification: .announcement, argument: "Camera isn't available here. Use Photos, Paste or text.")
        }
    }

    private func textOnlyTapped() {
        cameraUnavailable = false
        notice = nil
        draft.textOnlyChosen = true
        focus.wrappedValue = .name
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem) {
        importing = true
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            photosItem = nil
            guard let data else {
                importing = false
                notice = .error("Couldn't load that photo. Nothing was saved — try another one.")
                return
            }
            importImage(data, origin: .photos)
        }
    }

    private func handle(_ incoming: GarmentEditorIncoming, origin: GarmentEditorPhotoOrigin) {
        cameraUnavailable = false
        switch incoming {
        case let .image(data):
            importImage(data, origin: origin)
        case let .link(link):
            notice = nil
            draft.sourceURL = link
            UIAccessibility.post(notification: .announcement, argument: "Link saved with this item. A link isn't a photo.")
        case let .text(text):
            if let id = DragPayload.garmentID(from: text) {
                notice = .existingGarment(app.store.garment(id)?.displayName ?? "That item")
            } else {
                notice = .text(text)
            }
        case .unreadable:
            notice = .error("Couldn't read that. Nothing was added — try Photos, or type the details.")
        }
    }

    private func importImage(_ data: Data, origin: GarmentEditorPhotoOrigin) {
        importing = true
        notice = nil
        Task {
            let problem = await app.garmentEditorUI.importDraftPhoto(data, origin: origin)
            importing = false
            if let problem { notice = .error(problem) }
        }
    }

    private func removePhoto() {
        app.garmentEditorUI.cancelDraftProcessing()
        if let photo = draft.photo {
            GarmentEditorPhotoFiles.delete(photo.originalFilename)
            GarmentEditorPhotoFiles.delete(photo.processedFilename)
        }
        draft.photo = nil
        if draft.suggestion.phase == .working {
            app.garmentEditorUI.suggestionTask?.cancel()
        }
        draft.suggestion = GarmentEditorSuggestionSession()
        UIAccessibility.post(notification: .announcement, argument: "Photo removed")
    }

    private func processingPhase(_ photo: GarmentEditorDraftPhoto) -> GarmentEditorProcessingPanel.Phase {
        switch photo.state {
        case .originalOnly: return .idle
        case .skipped: return .keptOriginal
        case .processing: return .processing
        case .ready:
            if let processed = photo.processedFilename { return .ready(processed: processed, usingProcessed: photo.usingProcessed) }
            return .idle
        case .failed: return .failed(photo.failureReason ?? "Processing didn't finish.")
        }
    }
}

// MARK: - Name card

struct GarmentEditorAddNameCard: View {
    @Binding var draft: GarmentEditorDraft
    var focus: FocusState<GarmentEditorAddField?>.Binding
    @State private var showSuggestion = false

    var body: some View {
        CardSection("Name it your way", subtitle: "Optional",
                    info: "Your own words are perfect — no clothing terms needed.", systemImage: "character.cursor.ibeam") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                GarmentEditorFieldLabel(title: "Name")
                TextField("Name", text: $draft.name, prompt: Text("e.g. Cute pink shirt"))
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused(focus, equals: .name)
                    .garmentEditorField()
                    .accessibilityLabel("Name")
                    .accessibilityIdentifier("garmentNameField")
                if draft.trimmedName.isEmpty {
                    Text("Left empty, it'll be called “\(draft.fallbackName)”.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
                Button {
                    showSuggestion = true
                } label: {
                    Label("Suggest a name", systemImage: "lightbulb")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("suggestNameButton")
                .accessibilityHint("Makes a simple name on this device from the category and color. No AI.")
                if showSuggestion { suggestion }
            }

            Divider().overlay(Palette.divider)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                GarmentEditorFieldLabel(title: "Other names", hint: "Anything else you might call it, like “Date-night top”.", isListHeading: true)
                ForEach(draft.otherNames) { note in
                    GarmentEditorNoteRow(text: note.text, provenance: note.provenance.label, kindLabel: "other name") {
                        draft.otherNames.removeAll { $0.id == note.id }
                    }
                }
                GarmentEditorAddRow(placeholder: "Add another name", text: $draft.aliasInput, fieldIdentifier: "otherNameField",
                                    accessibilityLabel: "Another name") {
                    addNote(kind: .alias)
                }
            }

            Divider().overlay(Palette.divider)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                GarmentEditorFieldLabel(title: "Add details", hint: "Little things you notice, like “Bow at the neck”. Each one is kept.", isListHeading: true)
                ForEach(draft.details) { note in
                    GarmentEditorNoteRow(text: note.text, provenance: note.provenance.label, kindLabel: "detail") {
                        draft.details.removeAll { $0.id == note.id }
                    }
                }
                GarmentEditorAddRow(placeholder: "Add details", text: $draft.detailInput, fieldIdentifier: "addDetailField",
                                    accessibilityLabel: "Detail") {
                    addNote(kind: .detail)
                }
            }
        }
    }

    @ViewBuilder private var suggestion: some View {
        if let suggested = GarmentEditorNaming.suggestedName(kind: draft.kind, category: draft.category, color: draft.color) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("“\(suggested)”")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text("Made on this device from what you picked below — no AI.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                FlowLayout(spacing: Spacing.xs) {
                    Button("Use as name") {
                        draft.name = suggested
                        showSuggestion = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("useSuggestedNameButton")
                    Button("Add as another name") {
                        appendNote(.alias, suggested, provenance: .acceptedSuggestion)
                        showSuggestion = false
                    }
                    .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
                }
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
            .accessibilityElement(children: .contain)
        } else {
            Text("Choose a category, kind or color below and a simple name will be suggested from those.")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func addNote(kind: AnnotationKind) {
        let text = kind == .alias ? draft.aliasInput : draft.detailInput
        appendNote(kind, text, provenance: .userEntered)
        if kind == .alias { draft.aliasInput = "" } else { draft.detailInput = "" }
    }

    private func appendNote(_ kind: AnnotationKind, _ text: String, provenance: AnnotationProvenance) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let lower = trimmed.lowercased()
        switch kind {
        case .alias:
            guard lower != draft.trimmedName.lowercased(), !draft.otherNames.contains(where: { $0.text.lowercased() == lower }) else { return }
            draft.otherNames.append(GarmentEditorDraftNote(text: trimmed, provenance: provenance))
        case .detail:
            guard !draft.details.contains(where: { $0.text.lowercased() == lower }) else { return }
            draft.details.append(GarmentEditorDraftNote(text: trimmed, provenance: provenance))
        }
        UIAccessibility.post(notification: .announcement, argument: "Added \(trimmed)")
    }
}

// MARK: - Basics card (category, kind, color)

struct GarmentEditorAddBasicsCard: View {
    @Binding var draft: GarmentEditorDraft
    var focus: FocusState<GarmentEditorAddField?>.Binding

    private var categories: [GarmentCategory] {
        [.unknown] + GarmentCategory.allCases.filter { $0 != .unknown }
    }

    var body: some View {
        CardSection("What it is", info: "Pick what you know. Unknown is fine and can be filled in later.", systemImage: "tag") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                GarmentEditorFieldLabel(title: "Category")
                GarmentEditorChoiceChips(
                    items: categories,
                    selection: draft.category,
                    title: { $0 == .unknown ? "Unknown" : $0.label },
                    systemImage: { $0.systemImage },
                    identifier: { "category-\($0.rawValue)" },
                    onSelect: selectCategory,
                    itemsLabel: "categories"
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Category")
                .accessibilityIdentifier("categoryPicker")
            }

            if draft.category != .unknown {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    GarmentEditorFieldLabel(title: "Kind", hint: "Only if you know it.")
                    GarmentEditorChoiceChips(
                        items: [.unknown] + GarmentKind.kinds(for: draft.category).filter { $0 != .unknown },
                        selection: draft.kind,
                        title: { $0 == .unknown ? "Not sure" : $0.label },
                        systemImage: { _ in nil },
                        identifier: { "kind-\($0.rawValue)" },
                        onSelect: { draft.kind = $0 },
                        itemsLabel: "kinds"
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Kind")
                    .accessibilityIdentifier("kindPicker")
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                GarmentEditorFieldLabel(title: "Color", hint: "Pick the closest family, or leave it Unknown.")
                GarmentEditorColorPicker(family: $draft.colorFamily)
                if draft.colorFamily != nil {
                    TextField("Shade name", text: $draft.shadeName, prompt: Text("Shade name (optional), e.g. Dusty rose"))
                        .textInputAutocapitalization(.sentences)
                        .focused(focus, equals: .shade)
                        .garmentEditorField()
                        .accessibilityLabel("Shade name, optional")
                        .accessibilityIdentifier("shadeNameField")
                }
            }
        }
    }

    private func selectCategory(_ category: GarmentCategory) {
        draft.category = category
        if draft.kind.defaultCategory != category { draft.kind = .unknown }
    }
}

// MARK: - More details card

struct GarmentEditorAddMoreCard: View {
    @Binding var draft: GarmentEditorDraft
    var focus: FocusState<GarmentEditorAddField?>.Binding

    var body: some View {
        CardSection("More details", info: "All optional. Anything you leave stays Unknown — nothing is guessed.", systemImage: "list.bullet.rectangle") {
            DetailsDisclosure("Brand, size, fabric, notes, link", summary: filledSummary,
                              isExpanded: $draft.showsMoreDetails, identifier: "moreDetailsToggle") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    field("Brand", text: $draft.brand, field: .brand, identifier: "brandField")
                    field("Size", text: $draft.size, field: .size, identifier: "sizeField", hint: "As printed on the label, if you know it.")
                    field("Fabric", text: $draft.fabric, field: .fabric, identifier: "fabricField", hint: "Only if you know it — a photo can't tell fabric.")
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        GarmentEditorFieldLabel(title: "Notes")
                        TextField("Notes", text: $draft.notes, prompt: Text("Unknown — add later"), axis: .vertical)
                            .lineLimit(2...6)
                            .focused(focus, equals: .notes)
                            .garmentEditorField()
                            .accessibilityLabel("Notes")
                            .accessibilityIdentifier("notesField")
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        GarmentEditorFieldLabel(title: "Where it's from", hint: "An optional link. A link isn't a photo.")
                        TextField("Link", text: $draft.sourceURL, prompt: Text("Unknown — add later"))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused(focus, equals: .link)
                            .garmentEditorField()
                            .accessibilityLabel("Where it's from, link")
                            .accessibilityIdentifier("sourceLinkField")
                    }
                }
            }
        }
    }

    /// Says how many of the folded fields already hold something, so a prefilled
    /// link or brand isn't out of sight without a trace.
    private var filledSummary: String {
        let filled = [draft.brand, draft.size, draft.fabric, draft.notes, draft.sourceURL]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        return filled == 0 ? "all optional" : "\(filled) filled in"
    }

    private func field(_ title: String, text: Binding<String>, field: GarmentEditorAddField, identifier: String, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GarmentEditorFieldLabel(title: title, hint: hint)
            TextField(title, text: text, prompt: Text("Unknown — add later"))
                .textInputAutocapitalization(.words)
                .focused(focus, equals: field)
                .garmentEditorField()
                .accessibilityLabel(title)
                .accessibilityValue(text.wrappedValue.isEmpty ? "Unknown" : text.wrappedValue)
                .accessibilityIdentifier(identifier)
        }
    }
}

// MARK: - Save card (explicit ownership)

struct GarmentEditorAddSaveCard: View {
    @Binding var draft: GarmentEditorDraft
    var onSave: (OwnershipStatus) -> Void

    @Environment(AppModel.self) private var app

    var body: some View {
        CardSection("Save it",
                    info: "A photo or a name doesn't make it yours — you choose how it's saved. Owned items can be styled. Wishlist and Inspiration items are never used as owned. Bought something new? Use Find One's “I bought this” review instead.",
                    systemImage: "checkmark.seal") {
            if let suitcaseID = draft.intoSuitcaseID, let suitcase = app.store.suitcase(suitcaseID), !suitcase.isArchived {
                HStack(spacing: Spacing.xxs) {
                    Text("Also add to \(suitcase.name)")
                        .font(.body)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                    InfoButton("adding to \(suitcase.name)", title: "Also add to \(suitcase.name)",
                               text: "It's saved to Main Closet first. Turn this on to also link it to this suitcase — no copy is made. Only applies when you choose “I own this”.")
                    Spacer(minLength: Spacing.xs)
                    Toggle("Also add to \(suitcase.name)", isOn: $draft.alsoAddToSuitcase)
                        .labelsHidden()
                        .tint(Palette.primaryAction)
                        .accessibilityIdentifier("alsoAddToSuitcaseToggle")
                }
            }

            VStack(spacing: Spacing.xs) {
                Button {
                    onSave(.owned)
                } label: {
                    Label("Add to my closet — I own this", systemImage: "checkmark.circle")
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("addAsOwnedButton")
                .accessibilityHint("Saves it as owned. It can then be used in today's looks.")

                MoreMenu("Wishlist or Inspiration", fullWidth: true, identifier: "saveElsewhereMenu") {
                    alternatives
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("How to save it")
            .accessibilityIdentifier("ownershipChoice")

            Label("Saved only on this device in the demo.", systemImage: "iphone")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    @ViewBuilder private var alternatives: some View {
        Button {
            onSave(.wishlisted)
        } label: {
            Label("Save to Wishlist", systemImage: "heart")
        }
        .accessibilityIdentifier("saveToWishlistButton")
        Button {
            onSave(.inspiration)
        } label: {
            Label("Save as Inspiration", systemImage: "lightbulb")
        }
        .accessibilityIdentifier("saveAsInspirationButton")
    }
}

// MARK: - Previews

#Preview("Add Item") {
    AddGarmentView(prefill: nil)
        .previewEnvironment()
}

#Preview("Add Item · from a suitcase") {
    AddGarmentView(prefill: AddGarmentPrefill(name: "", kind: .cardigan, colorFamily: .cream, intoSuitcaseID: DemoFixtures.weekend))
        .previewEnvironment()
}

#Preview("Add Item · pasted link") {
    AddGarmentView(prefill: AddGarmentPrefill(name: "Navy work trousers", kind: .trousers, colorFamily: .navy, linkText: "https://example.com/demo-trousers"))
        .previewEnvironment()
}
