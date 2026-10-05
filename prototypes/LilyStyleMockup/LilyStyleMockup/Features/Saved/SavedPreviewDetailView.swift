import SwiftUI

/// One retained (simulated) picture: what it captured versus today's canonical status.
/// A changed garment is never relabelled in the old picture, and viewing never generates.
struct PreviewDetailView: View {
    var previewID: String
    /// True when shown beside the list in the wide Saved layout.
    var embedded: Bool = false

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var confirmDelete = false

    private var presenter: String { "preview-\(previewID)\(embedded ? "-pane" : "")" }

    var body: some View {
        Group {
            if let preview = app.store.preview(previewID) {
                GeometryReader { geo in
                    ScrollView {
                        content(preview, width: geo.size.width)
                            .padding(Spacing.m)
                            .frame(maxWidth: 1100)
                            .frame(maxWidth: .infinity)
                    }
                }
                .confirmationDialog("Delete this picture?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete picture", role: .destructive) { delete(preview) }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Removes this picture from your history. The look and its garments aren't changed. This can't be undone.")
                }
            } else {
                ScrollView {
                    EmptyStateView(
                        title: "This picture was deleted",
                        message: "It's no longer in your Preview History. Saved looks and garments weren't affected.",
                        systemImage: "photo.on.rectangle",
                        actionTitle: "Open Preview History"
                    ) {
                        app.savedUI.segment = .previewHistory
                        app.popToRoot(.saved)
                        app.select(.saved)
                    }
                    .padding(.top, Spacing.xxl)
                }
            }
        }
        .savedDetailChrome(title: app.store.preview(previewID)?.title ?? "Picture", embedded: embedded)
        .savedNamingAlert(presenter: presenter)
    }

    // MARK: Layout

    @ViewBuilder private func content(_ preview: PreviewEntry, width: CGFloat) -> some View {
        let version = SavedPreviewVersion.of(preview, in: app.store)
        if width >= 700 && !dynamicTypeSize.isAccessibilitySize {
            HStack(alignment: .top, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    figure(preview, version: version)
                    footnote
                }
                .frame(width: min(420, width * 0.42))
                VStack(alignment: .leading, spacing: Spacing.m) {
                    header(preview, version: version)
                    qualitySection(preview)
                    actionsSection(preview)
                    capturedSection(preview)
                    detailsSection(preview, version: version)
                    SavedCollectionToggles(target: .preview(preview.id), presenter: presenter)
                    deleteSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.m) {
                figure(preview, version: version)
                    .frame(maxWidth: 300)
                    .frame(maxWidth: .infinity)
                header(preview, version: version)
                qualitySection(preview)
                actionsSection(preview)
                capturedSection(preview)
                detailsSection(preview, version: version)
                SavedCollectionToggles(target: .preview(preview.id), presenter: presenter)
                deleteSection
                footnote
            }
        }
    }

    private func figure(_ preview: PreviewEntry, version: SavedPreviewVersion) -> some View {
        OnMePreviewFigure(pieces: preview.snapshotPieces, label: preview.title, isEarlier: version.isEarlier)
            .accessibilityIdentifier("previewFigure")
    }

    private var footnote: some View {
        SimulationNotice(
            text: "Simulated placeholder — not a real person, not a fit preview. Viewing never generates new pictures.",
            summary: "Not a real person or fit preview"
        )
    }

    // MARK: Header

    private func header(_ preview: PreviewEntry, version: SavedPreviewVersion) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(preview.title)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            BadgeRow(badges: [.simulated] + SavedPreviewVersion.badges(for: preview, version: version), compact: false)
            Text("\(version.label) · captured \(preview.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func qualitySection(_ preview: PreviewEntry) -> some View {
        switch preview.quality {
        case .ok:
            Label(preview.quality.label, systemImage: "flask")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
        case .approximate:
            InlineBanner(style: .info, title: preview.quality.label,
                         message: "Pieces without your own photo were drawn from representative artwork. The Captured list below is the accurate record.",
                         summary: "The Captured list below is the accurate record.",
                         isMessageExpanded: app.savedUI.disclosure("pictureQuality-\(preview.id)"))
        case .appearanceMismatch:
            InlineBanner(style: .caution, title: preview.quality.label,
                         message: "Some colors or details in this picture don't match the garments' saved details. It's kept for review; the Captured list below is the accurate record.",
                         summary: "The Captured list below is the accurate record.",
                         isMessageExpanded: app.savedUI.disclosure("pictureQuality-\(preview.id)"))
        }
    }

    // MARK: Actions

    private func actionsSection(_ preview: PreviewEntry) -> some View {
        let outfit = app.store.outfit(preview.outfitID)
        return SavedSectionCard {
            ActionGroup { toggles(preview) }
            if preview.isDisliked {
                Label("Disliked · kept in your history", systemImage: "hand.thumbsdown")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            if let outfit {
                // A plain row instead of a third button: the look's name, then a chevron.
                Button {
                    app.savedPush(.outfit(outfit.id), from: .preview(preview.id))
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                            .foregroundStyle(Palette.primaryAction)
                        Text("Related look")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.primaryText)
                        Text("· \(outfit.title)")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                            .lineLimit(1)
                        Spacer(minLength: Spacing.xs)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressFeedback)
                .hoverEffect(.highlight)
                .accessibilityLabel("Open related look")
                .accessibilityHint("Opens “\(outfit.title)”")
                .accessibilityIdentifier("openRelatedLookButton")
            } else {
                CollapsibleText(
                    "The look this picture came from isn't in Saved, so there's nothing to open. The picture stays here.",
                    summary: "Its look isn't in Saved anymore.",
                    topic: "the related look",
                    isExpanded: app.savedUI.disclosure("pictureRelatedLook-\(preview.id)")
                )
            }
        }
    }

    @ViewBuilder private func toggles(_ preview: PreviewEntry) -> some View {
        Button {
            app.store.toggleFavorite(previewID: preview.id)
            app.showToast(preview.isFavorite ? "Removed from Favorites — still kept in your history." : "Added to Favorites.", style: preview.isFavorite ? .info : .success)
        } label: {
            Label(preview.isFavorite ? "Favorited" : "Favorite", systemImage: preview.isFavorite ? "star.fill" : "star")
        }
        .buttonStyle(SecondaryButtonStyle())
        .keyboardShortcut("d", modifiers: .command)
        .accessibilityLabel("Favorite")
        .accessibilityValue(preview.isFavorite ? "On" : "Off")
        .accessibilityAddTraits(preview.isFavorite ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("favoriteButton")

        Button {
            let disliking = !preview.isDisliked
            app.store.setDisliked(previewID: preview.id, disliking)
            app.showToast(disliking ? "Disliked. Kept in your history." : "Dislike removed.", style: .info)
        } label: {
            Label(preview.isDisliked ? "Disliked" : "Dislike", systemImage: preview.isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
        }
        .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
        .accessibilityLabel("Dislike")
        .accessibilityValue(preview.isDisliked ? "On" : "Off")
        .accessibilityHint("A preference only. The picture stays in your history.")
        .accessibilityAddTraits(preview.isDisliked ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("dislikeButton")
    }

    // MARK: Captured vs today

    private func capturedSection(_ preview: PreviewEntry) -> some View {
        let store = app.store
        let pieces = preview.snapshotPieces.sorted { $0.slot.sortOrder < $1.slot.sortOrder }
        let rendered = SavedPreviewVersion.renderedAppearanceRevisions(preview.renderKey)
        return SavedSectionCard("Captured vs. today", info: "The picture keeps each piece as it was. “Today” comes from your closet now.") {
            ForEach(pieces) { piece in
                SavedCapturedRow(piece: piece, garment: store.garment(piece.garmentID), today: SavedLookStatus.todayBadges(for: piece, in: store),
                                 isMissing: store.isMissing(piece), renderedAppearanceRevision: piece.garmentID.flatMap { rendered[$0] })
                if piece.id != pieces.last?.id {
                    Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)
                }
            }
        }
        .accessibilityIdentifier("capturedVsToday")
    }

    // MARK: Details

    private func detailsSection(_ preview: PreviewEntry, version: SavedPreviewVersion) -> some View {
        DetailsDisclosure(
            "Details",
            summary: SavedProvenance.label(scope: preview.capturedScope, name: preview.capturedScopeName),
            isExpanded: app.savedUI.disclosure("pictureDetails-\(preview.id)"),
            identifier: "pictureDetails"
        ) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                InfoRow(title: "Captured", value: preview.createdAt.formatted(date: .abbreviated, time: .shortened))
                InfoRow(title: "Made from", value: SavedProvenance.plainName(scope: preview.capturedScope, name: preview.capturedScopeName),
                        valueIsUnknown: preview.capturedScope == nil && preview.capturedScopeName == nil)
                InfoRow(title: "Occasion then", value: preview.occasion?.label ?? "Not recorded", valueIsUnknown: preview.occasion == nil)
                InfoRow(title: "Version", value: version.label)
                InfoRow(title: "Reference photo", value: "Simulated reference v\(preview.referenceVersion)")
                InfoRow(title: "Kept", value: "Automatically — independent of Favorites")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: Spacing.s)
    }

    // MARK: Delete

    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete picture", systemImage: "trash")
            }
            .buttonStyle(DestructiveButtonStyle(fullWidth: true))
            .accessibilityHint("Asks for confirmation. Removes this picture from your history.")
            .accessibilityIdentifier("deletePreviewButton")
            // What Delete removes stays on screen in short form; the full sentence is one tap away.
            HStack(spacing: Spacing.xxs) {
                Text("Removes it from your history.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("deleting a picture", title: "Delete picture",
                           text: "Pictures stay until you delete them — disliking or unfavoriting never removes one. Deleting removes this picture from your history; the look and its garments aren't changed.")
            }
        }
        .padding(.top, Spacing.xs)
    }

    private func delete(_ preview: PreviewEntry) {
        if !embedded { dismiss() }
        app.savedClearSelection(.preview(preview.id))
        app.store.deletePreview(preview.id)
        app.showToast("Picture deleted from your history.")
    }
}

/// One captured piece: the snapshot as it was, plus today's canonical status.
struct SavedCapturedRow: View {
    var piece: OutfitPiece
    var garment: Garment?
    var today: [BadgeKind]
    var isMissing: Bool
    /// The garment's appearance revision when the picture was made, if recorded.
    var renderedAppearanceRevision: Int? = nil

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            PieceThumbnail(piece: piece)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Captured")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .textCase(.uppercase)
                Text(piece.capturedName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.xxs) {
                    if let hex = piece.capturedColor?.hex { ColorSwatch(hex: hex, size: 12) }
                    Text(piece.slot.label + " · " + (piece.capturedColor?.name ?? "color unknown"))
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                Text("Today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .textCase(.uppercase)
                    .padding(.top, Spacing.xxs)
                if today.isEmpty {
                    Label("Available", systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.success)
                } else {
                    BadgeRow(badges: today)
                }
                ForEach(changeNotes, id: \.self) { note in
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// Differences between the captured snapshot and today's record. The picture isn't relabelled.
    private var changeNotes: [String] {
        if isMissing { return ["Deleted from your closet since this picture was made."] }
        guard let garment else {
            return piece.isHypothetical ? ["An idea piece — not from your closet."] : []
        }
        var notes: [String] = []
        if garment.displayName != piece.capturedName {
            notes.append("Now called “\(garment.displayName)”.")
        }
        if garment.color?.hex != piece.capturedColor?.hex || garment.color?.name != piece.capturedColor?.name {
            notes.append("Saved color is now \(garment.colorLabel) — this picture still shows \(piece.capturedColor?.name ?? "an unknown color").")
        }
        if let then = renderedAppearanceRevision, garment.appearanceRevision != then {
            notes.append("Its photo changed after this picture was made — the picture isn't redrawn.")
        }
        return notes
    }

    private var accessibilityText: String {
        var parts = ["\(piece.slot.label). Captured: \(piece.capturedName), \(piece.capturedColor?.name ?? "color unknown")"]
        parts.append("Today: " + (today.isEmpty ? "Available" : today.map(\.text).joined(separator: ", ")))
        parts.append(contentsOf: changeNotes)
        return parts.joined(separator: ". ")
    }
}

#Preview("Picture — current") {
    NavigationStack {
        PreviewDetailView(previewID: "p-interview-current")
    }
    .previewEnvironment()
}

#Preview("Picture — needs review") {
    NavigationStack {
        PreviewDetailView(previewID: "p-lace-mismatch")
    }
    .previewEnvironment()
}
