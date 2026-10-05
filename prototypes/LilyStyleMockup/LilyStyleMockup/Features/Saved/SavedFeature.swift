import SwiftUI

/// Saved UI state owned by `AppModel` so the chosen segment, filters, wide-layout
/// selection and any pending collection name survive rotation, resizing and navigation.
@Observable
final class SavedUIState {
    var segment: SavedSegment = .allLooks
    var previewFilter: SavedPreviewStatusFilter = .all
    /// Captured-source filter key (see `SavedProvenance.key`); nil means any source.
    var previewSourceKey: String?
    /// Wide layout: what's shown beside the list for each segment.
    var selections: [SavedSegment: SavedSelection] = [:]
    /// Pending create/rename prompt and its text draft.
    var naming: SavedNamingRequest?
    var nameDraft: String = ""
    /// Looks whose local "Where could I wear this?" suggestion is open.
    var openWearSuggestions: Set<String> = []
    /// Which Saved screen pushed each Saved detail ("section#depth" → pusher and pushed route), so
    /// look → picture → "Open related look" goes back instead of stacking duplicates.
    var pushOrigins: [String: SavedPushOrigin] = [:]
    /// Top-most visible card in each segment, so the list comes back where Lily left it.
    var scrollAnchors: [SavedSegment: String] = [:]
    /// Disclosures Lily opened (chip rows, notes, details rows), so they stay open
    /// through rotation and layout switches.
    var openDisclosures: Set<String> = []

    init() {}

    /// Open state for one named disclosure.
    func disclosure(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDisclosures.contains(key) },
            set: { isOpen in
                if isOpen { self.openDisclosures.insert(key) } else { self.openDisclosures.remove(key) }
            }
        )
    }

    var hasPreviewFilters: Bool { previewFilter != .all || previewSourceKey != nil }

    func clearPreviewFilters() {
        previewFilter = .all
        previewSourceKey = nil
    }
}

// MARK: - Saved Looks

/// Saved: All Looks, Preview History (every retained picture), Favorites and Collections.
/// Nothing here dispatches a stylist or image service; it only reads and organizes local records.
struct SavedLooksScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var collectionPendingDelete: OutfitCollection?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            Group {
                if Self.usesSplit(width: width) {
                    splitLayout(width: width)
                } else {
                    ScrollView {
                        mainColumn(width: width - Spacing.m * 2, inSplit: false)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.s)
                            .frame(maxWidth: 1200)
                            .frame(maxWidth: .infinity)
                    }
                    .rememberedScrollPosition(scrollAnchor, firstID: firstCardID)
                }
            }
            .onChange(of: Self.usesSplit(width: width)) { wasSplit, isSplit in
                if wasSplit && !isSplit { keepSelectionVisibleAfterNarrowing() }
            }
        }
        .themedScreenBackground()
        .navigationTitle("Saved Looks")
        .toolbar { toolbarContent }
        .savedNamingAlert(presenter: "screen")
        .confirmationDialog(
            collectionPendingDelete.map { "Delete “\($0.name)”?" } ?? "Delete collection?",
            isPresented: Binding(get: { collectionPendingDelete != nil }, set: { if !$0 { collectionPendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: collectionPendingDelete
        ) { collection in
            Button("Delete collection", role: .destructive) {
                app.store.deleteCollection(collection.id)
                app.savedClearSelection(.collection(collection.id))
                app.showToast("“\(collection.name)” deleted. Its looks and pictures stay.")
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Removes the collection only — looks and pictures stay.")
        }
    }

    /// Two panes on wide widths and on upper-intermediate widths where both stay readable.
    static func usesSplit(width: CGFloat) -> Bool {
        WidthClass(width: width) == .wide || width >= 860
    }

    // MARK: Toolbar

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                app.push(.search(.saved), in: .saved)
            } label: {
                Label("Search saved looks and pictures", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("f", modifiers: .command)
            .help("Search saved looks and pictures")
            .accessibilityIdentifier("savedSearchButton")

            Button {
                app.openNewOutfitEditor(in: .saved)
            } label: {
                Label("New look", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .help("Build a new look by hand")
            .accessibilityIdentifier("newLookButton")

            Button {
                app.push(.savedProducts, in: .saved)
            } label: {
                Label("Saved products", systemImage: "bag")
            }
            .help("Saved products from Find One")
            .accessibilityIdentifier("savedProductsButton")
        }
    }

    // MARK: Layouts

    private func splitLayout(width: CGFloat) -> some View {
        let listWidth = min(max(width * 0.44, 380), 540)
        return HStack(spacing: 0) {
            ScrollView {
                mainColumn(width: listWidth - Spacing.m * 2, inSplit: true)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.s)
            }
            .rememberedScrollPosition(scrollAnchor, firstID: firstCardID)
            .frame(width: listWidth)

            Rectangle()
                .fill(Palette.divider)
                .frame(width: 1)
                .ignoresSafeArea(edges: .bottom)
                .accessibilityHidden(true)

            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder private var detailPane: some View {
        let ui = app.savedUI
        switch ui.selections[ui.segment] {
        case let .outfit(id)?:
            SavedOutfitDetailView(outfitID: id, embedded: true).id("outfit-\(id)")
        case let .preview(id)?:
            PreviewDetailView(previewID: id, embedded: true).id("preview-\(id)")
        case let .collection(id)?:
            CollectionDetailView(collectionID: id, embedded: true).id("collection-\(id)")
        case nil:
            ScrollView {
                EmptyStateView(title: placeholderTitle, message: placeholderMessage, systemImage: ui.segment.systemImage)
                    .padding(.top, Spacing.xxl)
            }
        }
    }

    private var scrollAnchor: Binding<String?> {
        let ui = app.savedUI
        return Binding(get: { ui.scrollAnchors[ui.segment] }, set: { ui.scrollAnchors[ui.segment] = $0 })
    }

    /// The first card in the current segment (see `rememberedScrollPosition`).
    private var firstCardID: String? {
        switch app.savedUI.segment {
        case .allLooks: app.store.savedOutfits.first?.id
        case .previewHistory: filteredPreviews(app.store.previews.sorted { $0.createdAt > $1.createdAt }).first?.id
        case .favorites: app.store.savedOutfits.first(where: \.isFavorite)?.id
            ?? app.store.previews.filter(\.isFavorite).max { $0.createdAt < $1.createdAt }?.id
        case .collections: app.store.collections.min { $0.createdAt < $1.createdAt }?.id
        }
    }

    private var placeholderTitle: String {
        switch app.savedUI.segment {
        case .allLooks, .favorites: "Choose a look"
        case .previewHistory: "Choose a picture"
        case .collections: "Choose a collection"
        }
    }

    private var placeholderMessage: String {
        switch app.savedUI.segment {
        case .allLooks: "Pick a saved look to see its pieces, today's status and its pictures here."
        case .previewHistory: "Pick a picture to compare what it captured with today's status."
        case .favorites: "Pick a favorite look or picture to see it here."
        case .collections: "Pick a collection to see the looks and pictures in it."
        }
    }

    private func mainColumn(width: CGFloat, inSplit: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            segmentControl(width: width)
            switch app.savedUI.segment {
            case .allLooks: allLooks(width: width, inSplit: inSplit)
            case .previewHistory: previewHistory(width: width, inSplit: inSplit)
            case .favorites: favorites(width: width, inSplit: inSplit)
            case .collections: collectionsList(inSplit: inSplit)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Segment control

    private var segmentBinding: Binding<SavedSegment> {
        Binding(
            get: { app.savedUI.segment },
            set: { newValue in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { app.savedUI.segment = newValue }
            }
        )
    }

    /// Full labels when there's room, short labels on phones, wrapping chips at the largest text sizes.
    @ViewBuilder private func segmentControl(width: CGFloat) -> some View {
        if dynamicTypeSize >= .accessibility1 {
            segmentChips
        } else if width >= 520 {
            ViewThatFits(in: .horizontal) {
                segmentedPicker(short: false)
                segmentedPicker(short: true)
                segmentChips
            }
        } else {
            ViewThatFits(in: .horizontal) {
                segmentedPicker(short: true)
                segmentChips
            }
        }
    }

    private func segmentedPicker(short: Bool) -> some View {
        Picker("Saved view", selection: segmentBinding) {
            ForEach(SavedSegment.allCases) { segment in
                Text(short ? segment.shortTitle : segment.title)
                    .accessibilityLabel(segment.title)
                    .tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("savedSegment")
    }

    /// Fallback for the largest text sizes: wrapping chips instead of a squeezed segmented control.
    private var segmentChips: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(SavedSegment.allCases) { segment in
                CapsuleChip(title: segment.title, systemImage: segment.systemImage, isSelected: app.savedUI.segment == segment) {
                    segmentBinding.wrappedValue = segment
                }
                .accessibilityIdentifier("savedSegment-\(segment.rawValue)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Saved view")
        .accessibilityIdentifier("savedSegment")
    }

    // MARK: Navigation

    private func open(_ selection: SavedSelection, inSplit: Bool) {
        if inSplit {
            app.savedUI.selections[app.savedUI.segment] = selection
            return
        }
        // A fresh push from the root starts a new trail; older records no longer describe the stack.
        app.savedUI.pushOrigins = [:]
        switch selection {
        case let .outfit(id): app.push(.outfit(id), in: .saved)
        case let .preview(id): app.push(.preview(id), in: .saved)
        case let .collection(id): app.push(.collection(id), in: .saved)
        }
    }

    /// The window got too narrow for the side pane (Split View / Stage Manager resize): show the
    /// selected look, picture or collection as a pushed screen so it doesn't disappear. Navigation only.
    private func keepSelectionVisibleAfterNarrowing() {
        let ui = app.savedUI
        guard app.section == .saved, (app.paths[.saved]?.count ?? 0) == 0,
              let selection = ui.selections[ui.segment] else { return }
        let exists: Bool = switch selection {
        case let .outfit(id): app.store.outfit(id) != nil
        case let .preview(id): app.store.preview(id) != nil
        case let .collection(id): app.store.collection(id) != nil
        }
        guard exists else { return }
        open(selection, inSplit: false)
    }

    private func isSelected(_ selection: SavedSelection, inSplit: Bool) -> Bool {
        inSplit && app.savedUI.selections[app.savedUI.segment] == selection
    }

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    // MARK: All Looks

    @ViewBuilder private func allLooks(width: CGFloat, inSplit: Bool) -> some View {
        let looks = app.store.savedOutfits
        if looks.isEmpty {
            EmptyStateView(
                title: "No saved looks yet",
                message: "Save a look from Style Me results, or build one by hand from your closet.",
                systemImage: "bookmark",
                actionTitle: "Build a look"
            ) {
                app.openNewOutfitEditor(in: .saved)
            }
        } else {
            HStack(spacing: Spacing.xxs) {
                Text("\(looks.count) saved \(looks.count == 1 ? "look" : "looks")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                InfoButton("the badges on saved looks", title: "Today's status",
                           text: "Badges show today's status from your closet. Saved looks themselves aren't changed.")
            }

            LazyVGrid(columns: SavedGrid.columns(width: width, accessibilitySize: isAccessibilitySize), alignment: .leading, spacing: Spacing.m) {
                ForEach(looks) { outfit in
                    SavedOutfitCard(outfit: outfit, isSelected: isSelected(.outfit(outfit.id), inSplit: inSplit)) {
                        open(.outfit(outfit.id), inSplit: inSplit)
                    }
                }
            }
            .scrollTargetLayout()
        }
    }

    // MARK: Preview History

    private func filteredPreviews(_ all: [PreviewEntry]) -> [PreviewEntry] {
        let ui = app.savedUI
        return all.filter { preview in
            switch ui.previewFilter {
            case .all: break
            case .favorites: if !preview.isFavorite { return false }
            case .disliked: if !preview.isDisliked { return false }
            }
            if let key = ui.previewSourceKey, SavedProvenance.key(preview.capturedScope) != key { return false }
            return true
        }
    }

    @ViewBuilder private func previewHistory(width: CGFloat, inSplit: Bool) -> some View {
        let ui = app.savedUI
        let all = app.store.previews.sorted { $0.createdAt > $1.createdAt }
        SimulationNotice(
            text: "Every delivered preview is kept, even if you don't favorite it. Simulated placeholder pictures.",
            systemImage: "photo.on.rectangle",
            summary: "Every preview is kept"
        )

        if all.isEmpty {
            EmptyStateView(
                title: "No pictures yet",
                message: "Pictures appear here only after you turn on On Me and ask for them. Opening Saved never makes a new picture.",
                systemImage: "photo.on.rectangle"
            )
        } else {
            let sources = SavedSourceOption.options(for: all)
            let filtered = filteredPreviews(all)
            previewFilterBar(sources: sources)

            HStack(alignment: .firstTextBaseline) {
                Text(ui.hasPreviewFilters ? "\(filtered.count) of \(all.count) pictures" : "\(all.count) \(all.count == 1 ? "picture" : "pictures") kept · newest first")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: Spacing.xs)
                if ui.hasPreviewFilters {
                    Button("Clear filters") {
                        withAnimation(reduceMotion ? nil : .default) { ui.clearPreviewFilters() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .minimumHitTarget()
                    .accessibilityIdentifier("clearPreviewFiltersButton")
                }
            }

            if filtered.isEmpty {
                EmptyStateView(
                    title: "No pictures match",
                    message: "Nothing was removed — these filters just hide the other pictures.",
                    systemImage: "line.3.horizontal.decrease.circle",
                    actionTitle: "Clear filters"
                ) {
                    ui.clearPreviewFilters()
                }
            } else {
                LazyVGrid(columns: SavedGrid.columns(width: width, accessibilitySize: isAccessibilitySize, compactMinimum: 150, regularMinimum: 180), alignment: .leading, spacing: Spacing.m) {
                    ForEach(filtered) { preview in
                        SavedPreviewCard(preview: preview, isSelected: isSelected(.preview(preview.id), inSplit: inSplit)) {
                            open(.preview(preview.id), inSplit: inSplit)
                        }
                    }
                }
                .scrollTargetLayout()
            }
        }
    }

    private func previewFilterBar(sources: [SavedSourceOption]) -> some View {
        let ui = app.savedUI
        // A chosen source whose pictures were all deleted still reads as an active filter.
        let activeLabel: String? = ui.previewSourceKey.map { key in sources.first { $0.key == key }?.label ?? "No pictures left" }
        let isActive = activeLabel != nil
        return ChipCarousel(isExpanded: ui.disclosure("previewFilterChips"), itemsLabel: "filters") {
            ForEach(SavedPreviewStatusFilter.allCases) { filter in
                CapsuleChip(title: filter.title, systemImage: filter.systemImage, isSelected: ui.previewFilter == filter) {
                    withAnimation(reduceMotion ? nil : .default) { ui.previewFilter = filter }
                }
                .accessibilityIdentifier("previewFilter-\(filter.rawValue)")
            }
            Menu {
                Picker("Captured source", selection: Binding<String?>(
                    get: { ui.previewSourceKey },
                    set: { ui.previewSourceKey = $0 }
                )) {
                    Label("Any source", systemImage: "square.stack").tag(String?.none)
                    ForEach(sources) { option in
                        Label("\(option.label) · \(option.count)", systemImage: option.systemImage).tag(String?.some(option.key))
                    }
                }
            } label: {
                HStack(spacing: Spacing.xxs + 2) {
                    Image(systemName: isActive ? "checkmark" : "line.3.horizontal.decrease.circle")
                        .font(.subheadline.weight(isActive ? .bold : .regular))
                    Text(activeLabel.map { "Source: \($0)" } ?? "Captured source")
                        .font(.subheadline.weight(isActive ? .semibold : .regular))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(isActive ? Palette.primaryAction : Palette.primaryText)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.xxs)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: HitTarget.minimum / 2, style: .continuous).fill(isActive ? Palette.accentSurface : Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: HitTarget.minimum / 2, style: .continuous).strokeBorder(isActive ? Palette.primaryAction : Palette.controlBorder, lineWidth: isActive ? 1.5 : 1))
                .contentShape(RoundedRectangle(cornerRadius: HitTarget.minimum / 2, style: .continuous))
            }
            .hoverEffect(.highlight)
            .accessibilityLabel("Captured source")
            .accessibilityValue(activeLabel ?? "Any source")
            .accessibilityHint("Filters by where each picture was made, not by today's suitcase contents")
            .accessibilityIdentifier("previewSourceFilter")
        }
    }

    // MARK: Favorites

    @ViewBuilder private func favorites(width: CGFloat, inSplit: Bool) -> some View {
        let looks = app.store.savedOutfits.filter(\.isFavorite)
        let pictures = app.store.previews.filter(\.isFavorite).sorted { $0.createdAt > $1.createdAt }
        SectionHeader(
            "Favorite looks",
            subtitle: looks.isEmpty ? nil : "\(looks.count)",
            info: "Favorites are a separate marker. They don't change collections or which pictures are kept."
        )
        if looks.isEmpty {
            Text("No favorite looks yet. Tap the star on a saved look.")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
        } else {
            LazyVGrid(columns: SavedGrid.columns(width: width, accessibilitySize: isAccessibilitySize), alignment: .leading, spacing: Spacing.m) {
                ForEach(looks) { outfit in
                    SavedOutfitCard(outfit: outfit, isSelected: isSelected(.outfit(outfit.id), inSplit: inSplit)) {
                        open(.outfit(outfit.id), inSplit: inSplit)
                    }
                }
            }
            .scrollTargetLayout()
        }

        SectionHeader("Favorite pictures", subtitle: pictures.isEmpty ? nil : "\(pictures.count)")
            .padding(.top, Spacing.xs)
        if pictures.isEmpty {
            Text("No favorite pictures yet. Open a picture in Preview History and tap Favorite.")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
        } else {
            LazyVGrid(columns: SavedGrid.columns(width: width, accessibilitySize: isAccessibilitySize, compactMinimum: 150, regularMinimum: 180), alignment: .leading, spacing: Spacing.m) {
                ForEach(pictures) { preview in
                    SavedPreviewCard(preview: preview, isSelected: isSelected(.preview(preview.id), inSplit: inSplit)) {
                        open(.preview(preview.id), inSplit: inSplit)
                    }
                }
            }
            .scrollTargetLayout()
        }
    }

    // MARK: Collections

    @ViewBuilder private func collectionsList(inSplit: Bool) -> some View {
        let collections = app.store.collections.sorted { $0.createdAt < $1.createdAt }
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                collectionsHeader
                Spacer(minLength: Spacing.s)
                addCollectionButton
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                collectionsHeader
                addCollectionButton
            }
        }

        if collections.isEmpty {
            EmptyStateView(
                title: "No collections yet",
                message: "Make private groups like Work, Gym or Going Out. A look can be in several.",
                systemImage: "folder.badge.plus"
            )
        } else {
            LazyVStack(spacing: Spacing.s) {
                ForEach(collections) { collection in
                    SavedCollectionRow(
                        collection: collection,
                        isSelected: isSelected(.collection(collection.id), inSplit: inSplit),
                        onOpen: { open(.collection(collection.id), inSplit: inSplit) },
                        onRename: {
                            app.savedUI.nameDraft = collection.name
                            app.savedUI.naming = SavedNamingRequest(kind: .rename(collectionID: collection.id), presenter: "screen")
                        },
                        onDelete: { collectionPendingDelete = collection }
                    )
                }
            }
            .scrollTargetLayout()
        }
    }

    private var collectionsHeader: some View {
        HStack(spacing: Spacing.xxs) {
            Text("Your collections")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            InfoButton("collections", title: "Your collections",
                       text: "Private groups. Removing one never deletes its looks or pictures.")
        }
    }

    private var addCollectionButton: some View {
        Button {
            app.savedUI.nameDraft = ""
            app.savedUI.naming = SavedNamingRequest(kind: .create(addOutfitID: nil, addPreviewID: nil), presenter: "screen")
        } label: {
            Label("New collection", systemImage: "folder.badge.plus")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("addCollectionButton")
    }
}

#Preview("Saved — All Looks") {
    NavigationStack {
        SavedLooksScreen()
    }
    .previewEnvironment()
}

#Preview("Saved — Preview History") {
    let model = AppModel.preview
    model.savedUI.segment = .previewHistory
    return NavigationStack {
        SavedLooksScreen()
    }
    .previewEnvironment(model)
}

#Preview("Saved — Collections") {
    let model = AppModel.preview
    model.savedUI.segment = .collections
    return NavigationStack {
        SavedLooksScreen()
    }
    .previewEnvironment(model)
}
