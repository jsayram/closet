import SwiftUI

// MARK: - Saved look card (All Looks, Favorites)

/// Garment-led card for a saved look: mini board, title, occasion, captured source,
/// a favorite star and today's status summary resolved from canonical records.
struct SavedOutfitCard: View {
    @Environment(AppModel.self) private var app
    var outfit: Outfit
    var isSelected = false
    var showsFavoriteToggle = true
    var onOpen: () -> Void

    var body: some View {
        let summary = SavedLookStatus.summary(for: outfit.pieces, in: app.store)
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SavedMiniBoard(pieces: outfit.pieces)
                    Text(outfit.title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    metaLine
                    SavedStatusSummaryRow(items: summary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(padding: Spacing.s, highlighted: isSelected)
                .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            }
            .buttonStyle(.plain)
            .hoverEffect(.lift)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(summary: summary))
            .accessibilityHint("Opens the saved look")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("savedOutfitCard-\(outfit.id)")
            .contextMenu { contextMenu }

            if showsFavoriteToggle {
                SavedFavoriteStar(isFavorite: outfit.isFavorite, subject: outfit.title) {
                    app.store.toggleFavorite(outfitID: outfit.id)
                    app.savedSyncEditorMetadata(outfitID: outfit.id)
                }
                .padding(Spacing.xs)
            }
        }
    }

    /// Occasion and captured source on one quiet line. A look with no occasion tag shows
    /// only its source here; VoiceOver and the look's Tags section still say so.
    private var metaLine: some View {
        let source = SavedProvenance.label(scope: outfit.capturedScope, name: outfit.capturedScopeName)
        return Label {
            Text(outfit.occasion.map { "\($0.label) · \(source)" } ?? source)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: outfit.occasion?.systemImage ?? SavedProvenance.systemImage(scope: outfit.capturedScope))
        }
        .font(.caption)
        .foregroundStyle(Palette.secondaryText)
    }

    @ViewBuilder private var contextMenu: some View {
        Button(action: onOpen) { Label("Open", systemImage: "arrow.up.forward.square") }
        Button {
            app.openEditor(forSaved: outfit.id, in: .saved)
        } label: { Label("Edit look", systemImage: "pencil") }
        Button {
            app.store.toggleFavorite(outfitID: outfit.id)
            app.savedSyncEditorMetadata(outfitID: outfit.id)
        } label: {
            Label(outfit.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: outfit.isFavorite ? "star.slash" : "star")
        }
        Menu {
            ForEach(app.store.collections) { collection in
                Button {
                    app.store.toggleOutfit(outfit.id, inCollection: collection.id)
                } label: {
                    if collection.outfitIDs.contains(outfit.id) {
                        Label(collection.name, systemImage: "checkmark")
                    } else {
                        Text(collection.name)
                    }
                }
            }
        } label: { Label("Collections", systemImage: "folder") }
    }

    private func accessibilityLabel(summary: [SavedLookStatus.Item]) -> String {
        var parts = [outfit.title]
        if outfit.isFavorite { parts.append("Favorite") }
        parts.append(outfit.occasion.map { "Occasion: \($0.label)" } ?? "No occasion tag")
        parts.append(SavedProvenance.label(scope: outfit.capturedScope, name: outfit.capturedScopeName))
        parts.append("\(outfit.pieces.count) \(outfit.pieces.count == 1 ? "piece" : "pieces"): " + outfit.sortedPieces.map(\.capturedName).joined(separator: ", "))
        parts.append("Today: " + SavedStatusSummaryRow.accessibilityText(summary))
        return parts.joined(separator: ". ")
    }
}

/// Small garment collage without labels. An empty look shows a quiet placeholder.
struct SavedMiniBoard: View {
    var pieces: [OutfitPiece]

    var body: some View {
        if pieces.isEmpty {
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .fill(Palette.imageWell)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "hanger")
                            .font(.title2)
                        Text("No pieces yet")
                            .font(.caption)
                    }
                    .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityHidden(true)
        } else {
            OutfitFlatLayView(pieces: pieces, compact: true)
                .accessibilityHidden(true)
        }
    }
}

/// Circular favorite toggle with a ≥44 pt target and an announced state.
struct SavedFavoriteStar: View {
    var isFavorite: Bool
    var subject: String
    var action: () -> Void
    /// Grows with Dynamic Type so the star never spills out of its circle.
    @ScaledMetric(relativeTo: .body) private var diameter: CGFloat = 36

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.primaryAction)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(Palette.surface))
                .overlay(Circle().strokeBorder(Palette.controlBorder, lineWidth: 1))
                .minimumHitTarget()
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel("Favorite")
        .accessibilityValue(isFavorite ? "On" : "Off")
        .accessibilityHint(isFavorite ? "Removes \(subject) from Favorites" : "Adds \(subject) to Favorites")
        .accessibilityAddTraits(isFavorite ? [.isButton, .isSelected] : .isButton)
        .help(isFavorite ? "Remove from Favorites" : "Add to Favorites")
    }
}

// MARK: - Retained picture card (Preview History, Favorites)

struct SavedPreviewCard: View {
    @Environment(AppModel.self) private var app
    var preview: PreviewEntry
    var isSelected = false
    var onOpen: () -> Void

    var body: some View {
        let version = SavedPreviewVersion.of(preview, in: app.store)
        let badges = SavedPreviewVersion.badges(for: preview, version: version)
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                OnMePreviewFigure(pieces: preview.snapshotPieces, label: preview.title)
                Text(preview.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                BadgeRow(badges: badges)
                // The figure is labelled Simulated and the badges carry Approximate or Needs
                // review; the longer quality wording is on the picture's own page.
                Text(capturedLine)
                    .font(.caption2)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(padding: Spacing.s, highlighted: isSelected)
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(version: version, badges: badges))
        .accessibilityHint("Opens the picture")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("previewCard-\(preview.id)")
    }

    private var capturedLine: String {
        "Captured \(preview.createdAt.formatted(date: .abbreviated, time: .omitted)) · \(SavedProvenance.label(scope: preview.capturedScope, name: preview.capturedScopeName))"
    }

    private func accessibilityLabel(version: SavedPreviewVersion, badges: [BadgeKind]) -> String {
        var parts = ["Simulated picture: \(preview.title)"]
        parts.append(version.label)
        parts.append(contentsOf: badges.filter { $0 != .earlier }.map(\.text))
        parts.append(preview.quality.label)
        parts.append(capturedLine)
        return parts.joined(separator: ". ")
    }
}

/// Compact picture thumbnail for horizontal strips (a look's retained pictures).
struct SavedPreviewThumb: View {
    @Environment(AppModel.self) private var app
    var preview: PreviewEntry
    var onOpen: () -> Void

    var body: some View {
        let version = SavedPreviewVersion.of(preview, in: app.store)
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                OnMePreviewFigure(pieces: preview.snapshotPieces, label: preview.title)
                    .frame(width: 140)
                StatusBadge(kind: version.isEarlier ? .earlier : .custom(version.shortLabel, version == .current ? "checkmark.circle" : "bookmark.slash"), compact: true)
                HStack(spacing: Spacing.xxs) {
                    if preview.isFavorite { Image(systemName: "star.fill").accessibilityHidden(true) }
                    if preview.isDisliked { Image(systemName: "hand.thumbsdown").accessibilityHidden(true) }
                    Text(preview.createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption2)
                .foregroundStyle(Palette.secondaryText)
            }
            .frame(width: 140, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Simulated picture, \(version.label), captured \(preview.createdAt.formatted(date: .abbreviated, time: .omitted))" + (preview.isFavorite ? ", Favorite" : "") + (preview.isDisliked ? ", Disliked" : "") + ". \(preview.quality.label)")
        .accessibilityHint("Opens the picture")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("previewCard-\(preview.id)")
    }
}

/// Small picture stand-in for list rows, where the full placeholder figure's caption wouldn't fit.
/// Callers label the row as a simulated picture.
struct SavedPreviewMiniThumb: View {
    var pieces: [OutfitPiece]

    private func piece(_ slot: OutfitSlot) -> OutfitPiece? { pieces.first { $0.slot == slot } }

    var body: some View {
        let upper = piece(.dress) ?? piece(.top) ?? piece(.layer)
        let lower = piece(.dress) == nil ? piece(.bottom) : piece(.shoes)
        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .fill(Palette.imageWell)
            .aspectRatio(0.72, contentMode: .fit)
            .overlay {
                VStack(spacing: 0) {
                    if let upper { GarmentArtwork(kind: upper.capturedKind, hex: upper.capturedColor?.hex, showsWell: false) }
                    if let lower { GarmentArtwork(kind: lower.capturedKind, hex: lower.capturedColor?.hex, showsWell: false) }
                }
                .padding(4)
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: BadgeKind.simulated.systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.primaryAction)
                    .padding(4)
                    .background(Circle().fill(Palette.surface))
                    .padding(3)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Collection row (Collections segment)

struct SavedCollectionRow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var collection: OutfitCollection
    var isSelected = false
    var onOpen: () -> Void
    var onRename: () -> Void
    var onDelete: () -> Void

    var body: some View {
        let store = app.store
        let outfits = collection.outfitIDs.compactMap { store.outfit($0) }
        let previews = collection.previewIDs.compactMap { store.preview($0) }
        let counts = SavedCollectionRow.countText(looks: outfits.count, pictures: previews.count)
        HStack(spacing: Spacing.s) {
            Button(action: onOpen) {
                HStack(spacing: Spacing.s) {
                    // The decorative stack gives its width back to the name at accessibility sizes.
                    if !dynamicTypeSize.isAccessibilitySize {
                        SavedCollectionStack(pieces: (outfits.map(\.pieces) + previews.map(\.snapshotPieces)).compactMap { $0.sorted { $0.slot.sortOrder < $1.slot.sortOrder }.first })
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(collection.name)
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(counts)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Spacing.xs)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(collection.name) collection, \(counts)")
            .accessibilityHint("Opens the collection")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityIdentifier("collectionRow-\(collection.id)")

            Menu {
                Button(action: onRename) { Label("Rename…", systemImage: "pencil") }
                Button(role: .destructive, action: onDelete) { Label("Delete collection…", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Palette.primaryAction)
                    .minimumHitTarget()
            }
            .accessibilityLabel("More for \(collection.name)")
            .accessibilityIdentifier("collectionMenu-\(collection.id)")
        }
        .cardStyle(padding: Spacing.s, highlighted: isSelected)
        .contextMenu {
            Button(action: onRename) { Label("Rename…", systemImage: "pencil") }
            Button(role: .destructive, action: onDelete) { Label("Delete collection…", systemImage: "trash") }
        }
    }

    static func countText(looks: Int, pictures: Int) -> String {
        if looks == 0 && pictures == 0 { return "Empty" }
        var parts: [String] = []
        if looks > 0 { parts.append("\(looks) \(looks == 1 ? "look" : "looks")") }
        if pictures > 0 { parts.append("\(pictures) \(pictures == 1 ? "picture" : "pictures")") }
        return parts.joined(separator: " · ")
    }
}

/// Up to three overlapping garment tiles representing a collection's contents.
struct SavedCollectionStack: View {
    var pieces: [OutfitPiece]

    var body: some View {
        ZStack(alignment: .leading) {
            if pieces.isEmpty {
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .fill(Palette.imageWell)
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: "folder").foregroundStyle(Palette.secondaryText))
            } else {
                ForEach(Array(pieces.prefix(3).enumerated()), id: \.offset) { index, piece in
                    GarmentArtwork(kind: piece.capturedKind, hex: piece.capturedColor?.hex)
                        .frame(width: 48, height: 48)
                        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.surface, lineWidth: 2))
                        .offset(x: CGFloat(index) * 18)
                }
            }
        }
        .frame(width: 48 + CGFloat(max(0, min(pieces.count, 3) - 1)) * 18, alignment: .leading)
        .accessibilityHidden(true)
    }
}

// MARK: - Membership row (Collection detail)

/// One look or picture inside a collection. Remove (membership only) sits in the row's menu.
struct SavedMembershipRow<Thumb: View>: View {
    var title: String
    var lines: [String]
    var summary: [SavedLookStatus.Item]
    var badges: [BadgeKind]
    var collectionName: String
    var identifier: String
    var removeIdentifier: String
    @ViewBuilder var thumbnail: () -> Thumb
    var onOpen: () -> Void
    var onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.xs) {
            openButton
            Menu {
                removeButton
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(Palette.primaryAction)
                    .minimumHitTarget()
            }
            .accessibilityLabel("More for \(title)")
            .accessibilityIdentifier("membershipMenu-\(identifier)")
        }
        .cardStyle(padding: Spacing.s)
        .contextMenu { removeButton }
    }

    private var openButton: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: Spacing.s) {
                thumbnail()
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if !lines.isEmpty {
                        Text(lines.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    BadgeRow(badges: badges)
                    if !summary.isEmpty { SavedStatusSummaryRow(items: summary, showsAllClear: false) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(([title] + lines + badges.map(\.text) + summary.map(\.text)).joined(separator: ". "))
        .accessibilityHint("Opens it")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(identifier)
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Label("Remove from \(collectionName)", systemImage: "minus.circle")
        }
        .accessibilityLabel("Remove \(title) from \(collectionName)")
        .accessibilityHint("Membership only. Nothing is deleted.")
        .accessibilityIdentifier(removeIdentifier)
    }
}
