import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Inline "Photo" card for garment detail screens (PRD 9, 9.1, FR-19/33).
///
/// Shows the current image with an honest source label; Add/Replace via Photos
/// or explicit Paste with a review before linking; optional simulated on-device
/// cleanup with Original / Processed / Reset; and Remove photo (the item stays,
/// with a representative image). Replacing keeps the garment ID and outfit links;
/// earlier previews keep their captured version.
struct GarmentPhotoSection: View {
    var garmentID: String

    @Environment(AppModel.self) private var app
    @State private var photosItem: PhotosPickerItem?
    @State private var importing = false
    @State private var notice: String?
    @State private var linkOffer: String?
    @State private var showRemoveConfirm = false

    init(garmentID: String) {
        self.garmentID = garmentID
    }

    private var ui: GarmentEditorUIState { app.garmentEditorUI }

    var body: some View {
        if let garment = app.store.garment(garmentID) {
            card(garment)
                .onChange(of: photosItem) { _, item in
                    guard let item else { return }
                    loadPicked(item)
                }
                .confirmationDialog("Remove this photo?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
                    Button("Remove photo", role: .destructive) { removePhoto(garment) }
                    Button("Keep photo", role: .cancel) {}
                } message: {
                    Text("The item stays in your closet with a representative image. Earlier previews keep their captured version.")
                }
        } else {
            CardSection("Photo", systemImage: "photo") {
                Text("That item no longer exists.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    // MARK: Card

    private func card(_ g: Garment) -> some View {
        let source = sourceInfo(g)
        return CardSection("Photo", subtitle: source.text, info: "Earlier previews keep their captured version.", systemImage: "photo") {
            if let pending = ui.pendingReplacements[garmentID] {
                replacementReview(g, pending: pending)
            } else {
                currentImage(g, badge: source.badge, label: source.text)
                if let active = g.photoFilename, GarmentEditorPhotoFiles.exists(active) {
                    GarmentEditorOriginalSavedLabel(detail: GarmentEditorPhotoFiles.isProcessed(active)
                                                    ? "A processed copy is shown. The original stays untouched."
                                                    : "Any cleanup makes a separate copy.")
                }
            }

            if importing {
                HStack(spacing: Spacing.xs) {
                    ProgressView()
                    Text("Saving the new original on this device…")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }

            actions(g)

            if let notice {
                InlineBanner(style: .error, title: notice)
            }
            if let linkOffer {
                InlineBanner(style: .info, title: "A link isn't a photo",
                             message: "Save “\(linkOffer)” as where this item is from? A photo can be added later.",
                             actionTitle: "Save link") {
                    app.store.updateGarment(garmentID) { $0.sourceURL = linkOffer }
                    self.linkOffer = nil
                    app.showToast("Link saved with this item")
                }
            }

            if ui.pendingReplacements[garmentID] == nil, let active = g.photoFilename, GarmentEditorPhotoFiles.exists(active) {
                processingPanel(g, active: active)
            }

            if let revert = ui.revertablePhotos[garmentID], ui.pendingReplacements[garmentID] == nil {
                InlineBanner(style: .info, title: revert.actionLabel,
                             message: "Changed your mind? You can put the previous photo back.",
                             actionTitle: "Revert to previous photo") {
                    revertPhoto(revert)
                }
            }
        }
        .accessibilityIdentifier("garmentPhotoSection")
    }

    private func currentImage(_ g: Garment, badge: BadgeKind, label: String) -> some View {
        GarmentEditorImageWell {
            imageContent(g)
        }
        .overlay(alignment: .topLeading) {
            StatusBadge(kind: badge, compact: true)
                .padding(Spacing.xs)
        }
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(g.accessibilityDescription)")
        .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private func imageContent(_ g: Garment) -> some View {
        if let active = g.photoFilename, GarmentEditorPhotoFiles.exists(active) {
            GarmentEditorStoredPhoto(filename: active)
        } else {
            GarmentArtwork(kind: g.kind, hex: g.color?.hex, showsWell: false)
        }
    }

    /// Photos and Paste stay visible (both are system controls); Remove photo sits in
    /// the More menu and still asks first.
    @ViewBuilder private func actions(_ g: Garment) -> some View {
        let hasPhoto = g.photoFilename != nil || g.imageKind == .actualPhoto
        if hasPhoto, ui.pendingReplacements[garmentID] == nil {
            ActionGroup(moreIdentifier: "photoMoreMenu") {
                intakeButtons(hasPhoto: hasPhoto)
            } more: {
                Button("Remove photo", systemImage: "trash", role: .destructive) {
                    showRemoveConfirm = true
                }
                .accessibilityIdentifier("removePhotoButton")
            }
        } else {
            ActionGroup {
                intakeButtons(hasPhoto: hasPhoto)
            }
        }
    }

    @ViewBuilder private func intakeButtons(hasPhoto: Bool) -> some View {
        PhotosPicker(selection: $photosItem, matching: .images, preferredItemEncoding: .current) {
            Label(hasPhoto ? "Replace photo" : "Add photo", systemImage: "photo.on.rectangle")
        }
        .garmentEditorIntakeStyle()
        .accessibilityIdentifier("photosPickerButton")
        .accessibilityHint("Pick one photo. You'll review it before it replaces anything.")

        PasteButton(supportedContentTypes: [.image, .url, .plainText]) { providers in
            GarmentEditorIncoming.load(providers) { incoming in
                handle(incoming)
            }
        }
        .garmentEditorIntakeStyle()
        .fixedSize()
        .accessibilityIdentifier("pasteButton")
    }

    // MARK: Replacement review

    private func replacementReview(_ g: Garment, pending: GarmentEditorPendingPhoto) -> some View {
        let hasPhoto = g.photoFilename != nil || g.imageKind == .actualPhoto
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text(hasPhoto ? "Review the new photo" : "Review your photo")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            GarmentEditorOriginalSavedLabel(detail: "\(pending.origin.label). It isn't linked to this item until you choose Use new photo.")
            GarmentEditorComparison {
                GarmentEditorComparisonTile(title: "Now", inUse: true, inUseText: "Current") {
                    imageContent(g)
                }
            } right: {
                GarmentEditorComparisonTile(title: "New photo", inUse: false) {
                    GarmentEditorStoredPhoto(filename: pending.filename, maxPixel: 600)
                }
            }
            CollapsibleText("Replacing keeps this item, its names and its outfit links. Earlier previews keep their captured version.",
                            summary: "Keeps this item, its names and its looks.", topic: "replacing the photo")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { reviewButtons(g, pending: pending) }
                VStack(alignment: .leading, spacing: Spacing.xs) { reviewButtons(g, pending: pending) }
            }
        }
    }

    @ViewBuilder private func reviewButtons(_ g: Garment, pending: GarmentEditorPendingPhoto) -> some View {
        Button {
            usePending(g, pending: pending)
        } label: {
            Label("Use new photo", systemImage: "checkmark")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("useNewPhotoButton")
        Button {
            GarmentEditorPhotoFiles.delete(pending.filename)
            ui.pendingReplacements[garmentID] = nil
        } label: {
            Label("Keep current", systemImage: "xmark")
        }
        .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
        .accessibilityIdentifier("keepCurrentPhotoButton")
    }

    // MARK: Processing

    private func processingPanel(_ g: Garment, active: String) -> some View {
        let original = GarmentEditorPhotoFiles.originalName(for: active)
        let processed = GarmentEditorPhotoFiles.processedName(for: original)
        let usingProcessed = GarmentEditorPhotoFiles.isProcessed(active)
        let phase: GarmentEditorProcessingPanel.Phase
        if ui.processingIDs.contains(garmentID) {
            phase = .processing
        } else if usingProcessed || (g.processing == .ready && GarmentEditorPhotoFiles.exists(processed)) {
            phase = .ready(processed: processed, usingProcessed: usingProcessed)
        } else if g.processing == .failed {
            phase = .failed(ui.processingFailures[garmentID] ?? "Processing didn't finish.")
        } else if g.processing == .skipped {
            phase = .keptOriginal
        } else {
            phase = .idle
        }
        return GarmentEditorProcessingPanel(
            phase: phase,
            originalFilename: original,
            onProcess: {
                ui.startGarmentProcessing(garmentID, store: app.store, fast: app.fastMocks, simulateFailure: app.scenario == .saveFailure)
            },
            onCancel: { ui.cancelGarmentProcessing(garmentID) },
            onUseProcessed: {
                app.store.updateGarment(garmentID, appearanceChanged: true) {
                    $0.photoFilename = processed
                    $0.processing = .ready
                }
                app.showToast("Using the processed copy. Your original is kept.")
            },
            onKeepOriginal: {
                GarmentEditorPhotoFiles.delete(processed)
                app.store.updateGarment(garmentID) { $0.processing = .skipped }
            },
            onReset: {
                app.store.updateGarment(garmentID, appearanceChanged: true) {
                    $0.photoFilename = original
                    $0.processing = .ready
                }
                app.showToast("Back to your original photo.", style: .info)
            }
        )
    }

    // MARK: Actions

    private func loadPicked(_ item: PhotosPickerItem) {
        importing = true
        notice = nil
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            photosItem = nil
            guard let data else {
                importing = false
                notice = "Couldn't load that photo. Your current photo is unchanged."
                return
            }
            await stage(data, origin: .photos)
        }
    }

    private func handle(_ incoming: GarmentEditorIncoming) {
        notice = nil
        switch incoming {
        case let .image(data):
            importing = true
            Task { await stage(data, origin: .paste) }
        case let .link(link):
            linkOffer = link
        case .text:
            notice = "That's text, not a photo or a link. Your current photo is unchanged."
        case .unreadable:
            notice = "Couldn't read what was pasted. Your current photo is unchanged."
        }
    }

    /// Original-first: writes the new bytes, then waits for review before linking.
    @MainActor
    private func stage(_ data: Data, origin: GarmentEditorPhotoOrigin) async {
        defer { importing = false }
        if let problem = GarmentEditorPhotoFiles.problem(with: data) {
            notice = "\(problem) Your current photo is unchanged."
            return
        }
        do {
            let filename = try await GarmentEditorPhotoFiles.saveOriginal(data)
            if let previous = ui.pendingReplacements[garmentID] {
                GarmentEditorPhotoFiles.delete(previous.filename)
            }
            ui.pendingReplacements[garmentID] = GarmentEditorPendingPhoto(filename: filename, origin: origin)
            UIAccessibility.post(notification: .announcement, argument: "New photo saved on this device. Review it before it replaces the current one.")
        } catch {
            notice = "Couldn't save the new photo on this device. Your current photo is unchanged."
        }
    }

    private func usePending(_ g: Garment, pending: GarmentEditorPendingPhoto) {
        let hadPhoto = g.photoFilename != nil || g.imageKind == .actualPhoto
        let before = GarmentEditorPhotoRevert(filename: g.photoFilename, imageKind: g.imageKind, processing: g.processing,
                                              replacedBy: pending.filename, actionLabel: hadPhoto ? "Photo replaced" : "Photo added")
        ui.cancelGarmentProcessing(garmentID)
        app.store.updateGarment(garmentID, appearanceChanged: true) {
            $0.photoFilename = pending.filename
            $0.imageKind = .actualPhoto
            $0.processing = .originalOnly
        }
        ui.processingFailures[garmentID] = nil
        ui.pendingReplacements[garmentID] = nil
        ui.revertablePhotos[garmentID] = before
        app.showToast(hadPhoto ? "Photo replaced. Earlier previews keep their captured version."
                               : "Photo added. Earlier previews keep their captured version.")
    }

    private func removePhoto(_ g: Garment) {
        let before = GarmentEditorPhotoRevert(filename: g.photoFilename, imageKind: g.imageKind, processing: g.processing,
                                              replacedBy: nil, actionLabel: "Photo removed")
        ui.cancelGarmentProcessing(garmentID)
        app.store.updateGarment(garmentID, appearanceChanged: true) {
            $0.photoFilename = nil
            $0.imageKind = .representative
            $0.processing = .originalOnly
        }
        ui.processingFailures[garmentID] = nil
        ui.revertablePhotos[garmentID] = before
        app.showToast("Photo removed. The item is still in your closet.", style: .info)
    }

    private func revertPhoto(_ revert: GarmentEditorPhotoRevert) {
        ui.cancelGarmentProcessing(garmentID)
        app.store.updateGarment(garmentID, appearanceChanged: true) {
            $0.photoFilename = revert.filename
            $0.imageKind = revert.imageKind
            $0.processing = revert.processing
        }
        if let newer = revert.replacedBy, newer != revert.filename {
            let original = GarmentEditorPhotoFiles.originalName(for: newer)
            GarmentEditorPhotoFiles.delete(original)
            GarmentEditorPhotoFiles.delete(GarmentEditorPhotoFiles.processedName(for: original))
        }
        ui.revertablePhotos[garmentID] = nil
        app.showToast("Previous photo restored.", style: .info)
    }

    // MARK: Source label

    private func sourceInfo(_ g: Garment) -> (badge: BadgeKind, text: String) {
        if let active = g.photoFilename {
            guard GarmentEditorPhotoFiles.exists(active) else {
                return (.missing, "The photo file isn't on this device, so a representative image is shown.")
            }
            if GarmentEditorPhotoFiles.isProcessed(active) {
                return (.custom("Your photo · processed", "wand.and.stars"), "Your photo — processed copy in use (simulated cleanup).")
            }
            return (.custom("Your photo", "camera"), "Your photo — the original, saved on this device.")
        }
        switch g.imageKind {
        case .actualPhoto:
            return (.yourPhoto, "Your photo (demo stand-in illustration).")
        case .representative:
            return (.representative, "Representative image — add your photo.")
        case .textOnly:
            return (.textOnly, "Text-only item, shown with a representative tile. Add a photo any time.")
        }
    }
}

// MARK: - Previews

#Preview("Photo · demo stand-in") {
    NavigationStack {
        ScrollView {
            GarmentPhotoSection(garmentID: "g-pink-blouse")
                .padding(Spacing.m)
        }
        .themedScreenBackground()
        .navigationTitle("Cute pink shirt")
    }
    .previewEnvironment()
}

#Preview("Photo · text-only item") {
    NavigationStack {
        ScrollView {
            GarmentPhotoSection(garmentID: "g-tan-loafers")
                .padding(Spacing.m)
        }
        .themedScreenBackground()
        .navigationTitle("Tan loafers")
    }
    .previewEnvironment()
}
