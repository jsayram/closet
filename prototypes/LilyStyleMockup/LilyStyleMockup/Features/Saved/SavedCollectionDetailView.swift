import SwiftUI

/// A private collection: its looks and pictures, rename, membership-only removal and delete.
struct CollectionDetailView: View {
    var collectionID: String
    /// True when shown beside the list in the wide Saved layout.
    var embedded: Bool = false

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var confirmDelete = false

    private var presenter: String { "collection-\(collectionID)\(embedded ? "-pane" : "")" }

    var body: some View {
        Group {
            if let collection = app.store.collection(collectionID) {
                GeometryReader { geo in
                    ScrollView {
                        content(collection, width: geo.size.width)
                            .padding(Spacing.m)
                            .frame(maxWidth: 1100)
                            .frame(maxWidth: .infinity)
                    }
                }
                .confirmationDialog("Delete “\(collection.name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete collection", role: .destructive) { delete(collection) }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Removes the collection only — looks and pictures stay.")
                }
            } else {
                ScrollView {
                    EmptyStateView(
                        title: "This collection was deleted",
                        message: "Its looks and pictures are still in Saved.",
                        systemImage: "folder",
                        actionTitle: "Show collections"
                    ) {
                        app.savedUI.segment = .collections
                        app.popToRoot(.saved)
                        app.select(.saved)
                    }
                    .padding(.top, Spacing.xxl)
                }
            }
        }
        .savedDetailChrome(title: app.store.collection(collectionID)?.name ?? "Collection", embedded: embedded)
        .savedNamingAlert(presenter: presenter)
    }

    // MARK: Layout

    @ViewBuilder private func content(_ collection: OutfitCollection, width: CGFloat) -> some View {
        let store = app.store
        let outfits = collection.outfitIDs.compactMap { store.outfit($0) }
        let previews = collection.previewIDs.compactMap { store.preview($0) }.sorted { $0.createdAt > $1.createdAt }
        VStack(alignment: .leading, spacing: Spacing.m) {
            header(collection, looks: outfits.count, pictures: previews.count)
            if outfits.isEmpty && previews.isEmpty {
                EmptyStateView(
                    title: "Nothing in \(collection.name) yet",
                    message: "Add looks from a look's Collections section, or pictures from a picture's detail. A look can be in several collections.",
                    systemImage: "folder"
                )
                .cardStyle()
            } else if width >= 760 && !dynamicTypeSize.isAccessibilitySize {
                HStack(alignment: .top, spacing: Spacing.m) {
                    looksSection(outfits, collection: collection)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    picturesSection(previews, collection: collection)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                looksSection(outfits, collection: collection)
                picturesSection(previews, collection: collection)
            }
        }
    }

    private func header(_ collection: OutfitCollection, looks: Int, pictures: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Image(systemName: "folder")
                    .foregroundStyle(Palette.primaryAction)
                    .accessibilityHidden(true)
                Text(collection.name)
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.xs)
                // Rename and Delete sit in one menu, like the rows in the Collections list.
                Menu {
                    headerActions(collection)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(Palette.primaryAction)
                        .minimumHitTarget()
                }
                .accessibilityLabel("More for \(collection.name)")
                .accessibilityIdentifier("collectionActionsMenu")
            }
            HStack(spacing: Spacing.xxs) {
                Text("\(SavedCollectionRow.countText(looks: looks, pictures: pictures)) · private on this device (demo)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                InfoButton("removing from this collection", title: "Removing from a collection",
                           text: "Removing something here only changes this collection. The look or picture stays in Saved.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func headerActions(_ collection: OutfitCollection) -> some View {
        Button {
            app.savedUI.nameDraft = collection.name
            app.savedUI.naming = SavedNamingRequest(kind: .rename(collectionID: collection.id), presenter: presenter)
        } label: {
            Label("Rename…", systemImage: "pencil")
        }
        .accessibilityLabel("Rename collection")
        .accessibilityIdentifier("renameCollectionButton")

        Button(role: .destructive) {
            confirmDelete = true
        } label: {
            Label("Delete collection…", systemImage: "trash")
        }
        .accessibilityHint("Asks for confirmation. Looks and pictures stay.")
        .accessibilityIdentifier("deleteCollectionButton")
    }

    // MARK: Sections

    @ViewBuilder private func looksSection(_ outfits: [Outfit], collection: OutfitCollection) -> some View {
        let store = app.store
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Looks", subtitle: outfits.isEmpty ? "None yet" : "\(outfits.count)")
            ForEach(outfits) { outfit in
                SavedMembershipRow(
                    title: outfit.title,
                    lines: [outfit.occasion?.label ?? "No occasion tag",
                            SavedProvenance.label(scope: outfit.capturedScope, name: outfit.capturedScopeName)],
                    summary: SavedLookStatus.summary(for: outfit.pieces, in: store),
                    badges: outfit.isFavorite ? [.favorite] : [],
                    collectionName: collection.name,
                    identifier: "savedOutfitCard-\(outfit.id)",
                    removeIdentifier: "removeFromCollection-\(outfit.id)",
                    thumbnail: {
                        SavedMiniBoard(pieces: outfit.pieces)
                            .frame(width: 72)
                    },
                    onOpen: { app.savedPush(.outfit(outfit.id), from: .collection(collection.id)) },
                    onRemove: { removeOutfit(outfit, from: collection) }
                )
            }
        }
    }

    @ViewBuilder private func picturesSection(_ previews: [PreviewEntry], collection: OutfitCollection) -> some View {
        let store = app.store
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Pictures", subtitle: previews.isEmpty ? "None yet" : "\(previews.count) · simulated")
            ForEach(previews) { preview in
                let version = SavedPreviewVersion.of(preview, in: store)
                SavedMembershipRow(
                    title: preview.title,
                    lines: ["Captured \(preview.createdAt.formatted(date: .abbreviated, time: .omitted))",
                            SavedProvenance.label(scope: preview.capturedScope, name: preview.capturedScopeName)],
                    summary: [],
                    badges: [.simulated] + SavedPreviewVersion.badges(for: preview, version: version),
                    collectionName: collection.name,
                    identifier: "previewCard-\(preview.id)",
                    removeIdentifier: "removeFromCollection-\(preview.id)",
                    thumbnail: {
                        SavedPreviewMiniThumb(pieces: preview.snapshotPieces)
                            .frame(width: 72)
                    },
                    onOpen: { app.savedPush(.preview(preview.id), from: .collection(collection.id)) },
                    onRemove: { removePreview(preview, from: collection) }
                )
            }
        }
    }

    // MARK: Actions

    private func removeOutfit(_ outfit: Outfit, from collection: OutfitCollection) {
        let store = app.store
        guard store.collection(collection.id)?.outfitIDs.contains(outfit.id) == true else { return }
        store.toggleOutfit(outfit.id, inCollection: collection.id)
        let model = app
        model.showToast("Removed “\(outfit.title)” from \(collection.name). The look is still saved.", actionTitle: "Undo") { [weak model] in
            guard let model, let current = model.store.collection(collection.id), !current.outfitIDs.contains(outfit.id),
                  model.store.outfit(outfit.id) != nil else { return }
            model.store.toggleOutfit(outfit.id, inCollection: collection.id)
            model.showToast("Back in \(current.name).", style: .info)
        }
    }

    private func removePreview(_ preview: PreviewEntry, from collection: OutfitCollection) {
        let store = app.store
        guard store.collection(collection.id)?.previewIDs.contains(preview.id) == true else { return }
        store.togglePreview(preview.id, inCollection: collection.id)
        let model = app
        model.showToast("Removed the picture from \(collection.name). It's still in Preview History.", actionTitle: "Undo") { [weak model] in
            guard let model, let current = model.store.collection(collection.id), !current.previewIDs.contains(preview.id),
                  model.store.preview(preview.id) != nil else { return }
            model.store.togglePreview(preview.id, inCollection: collection.id)
            model.showToast("Back in \(current.name).", style: .info)
        }
    }

    private func delete(_ collection: OutfitCollection) {
        if !embedded { dismiss() }
        app.savedClearSelection(.collection(collection.id))
        app.store.deleteCollection(collection.id)
        app.showToast("“\(collection.name)” deleted. Its looks and pictures stay.")
    }
}

#Preview("Collection — Work") {
    NavigationStack {
        CollectionDetailView(collectionID: "c-work")
    }
    .previewEnvironment()
}

#Preview("Collection — empty") {
    NavigationStack {
        CollectionDetailView(collectionID: "c-gym")
    }
    .previewEnvironment()
}
