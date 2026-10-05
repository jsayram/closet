import SwiftUI

/// Result-type filters, facets and the visible active-filter list with Clear All.
/// Facets combine with AND; choices within one facet combine with OR.
/// Each chip row stays on one line that scrolls sideways; the control at its end
/// opens the whole row when the chips don't fit.
struct SearchFilterBar: View {
    @Bindable var ui: SearchUIState
    var output: SearchOutput
    var collections: [OutfitCollection]

    private var scopeTypes: [SearchResultType] { ui.scope.searchResultTypes }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            if scopeTypes.count > 1 {
                SearchChipRow(label: "Show", itemsLabel: "result types", isExpanded: ui.disclosure("typeChips")) {
                    ForEach(scopeTypes) { type in
                        let count = output.typeCounts[type] ?? 0
                        CapsuleChip(
                            title: output.isIdle ? type.filterLabel : "\(type.filterLabel) · \(count)",
                            systemImage: type.systemImage,
                            isSelected: ui.filters.types.contains(type)
                        ) {
                            toggle(&ui.filters.types, type)
                        }
                        .accessibilityLabel(type.filterLabel)
                        .accessibilityValue(output.isIdle ? "" : "\(count) \(count == 1 ? "result" : "results")")
                        .accessibilityHint("Shows only this type. Combine types to show several.")
                        .accessibilityIdentifier("searchTypeFilter-\(type.rawValue)")
                    }
                }
            }

            SearchChipRow(label: "Filters", itemsLabel: "filters", isExpanded: ui.disclosure("facetChips")) {
                categoryMenu
                colorMenu
                if ui.scope != .saved || ui.filters.ownership != .current { ownershipMenu }
                CapsuleChip(title: "Available only", systemImage: "checkmark.circle", isSelected: ui.filters.availableOnly) {
                    ui.filters.availableOnly.toggle()
                }
                .accessibilityHint("Shows garments you can wear today and looks whose pieces are all available. Dirty and other items stay searchable when this is off.")
                .accessibilityIdentifier("searchFacet-\(SearchFacetKind.availability.identifierName)")
                if ui.scope != .closet || ui.filters.favoritesOnly {
                    CapsuleChip(title: "Favorites", systemImage: "star", isSelected: ui.filters.favoritesOnly) {
                        ui.filters.favoritesOnly.toggle()
                    }
                    .accessibilityHint("Shows favorite saved looks and previews")
                    .accessibilityIdentifier("searchFacet-\(SearchFacetKind.favorites.identifierName)")
                }
                if (ui.scope != .closet && !collections.isEmpty) || !ui.filters.collectionIDs.isEmpty { collectionMenu }
                imageSourceMenu
            }

            if !ui.filters.isDefault { activeFilters }
        }
    }

    // MARK: Facet menus

    private var categoryMenu: some View {
        Menu {
            Section("Looks match when any piece is in the category") {
                ForEach(GarmentCategory.allCases) { category in
                    toggleButton(category.label, isOn: ui.filters.categories.contains(category)) {
                        toggle(&ui.filters.categories, category)
                    }
                }
            }
        } label: {
            SearchFacetChipLabel(title: "Category", value: summary(ui.filters.categories.map(\.label)), systemImage: "square.grid.2x2")
        }
        .accessibilityLabel("Category filter")
        .accessibilityValue(summary(ui.filters.categories.map(\.label)) ?? "Any")
        .accessibilityIdentifier("searchFacet-\(SearchFacetKind.category.identifierName)")
    }

    private var colorMenu: some View {
        Menu {
            Section("Confirmed or captured color family") {
                ForEach(ColorFamily.allCases) { family in
                    toggleButton(family.label, isOn: ui.filters.colors.contains(family)) {
                        toggle(&ui.filters.colors, family)
                    }
                }
            }
        } label: {
            SearchFacetChipLabel(title: "Color", value: summary(ui.filters.colors.map(\.label)), systemImage: "paintpalette")
        }
        .accessibilityLabel("Color filter")
        .accessibilityValue(summary(ui.filters.colors.map(\.label)) ?? "Any")
        .accessibilityHint("Matches the exact color family. Related shades are never added by this filter.")
        .accessibilityIdentifier("searchFacet-\(SearchFacetKind.color.identifierName)")
    }

    private var ownershipMenu: some View {
        Menu {
            Picker("Garment ownership", selection: $ui.filters.ownership) {
                ForEach(SearchOwnershipScope.allCases) { scope in
                    Text(scope.label).tag(scope)
                }
            }
        } label: {
            SearchFacetChipLabel(
                title: "Garments",
                value: ui.filters.ownership.chipLabel,
                systemImage: "person.crop.square",
                isActive: ui.filters.ownership != .current
            )
        }
        .accessibilityLabel("Garment ownership")
        .accessibilityValue(ui.filters.ownership.label)
        .accessibilityHint("No longer owned garments appear only with All ownership. Saved looks keep their history either way.")
        .accessibilityIdentifier("searchFacet-\(SearchFacetKind.ownership.identifierName)")
    }

    private var collectionMenu: some View {
        Menu {
            Section("Saved looks and previews in") {
                ForEach(collections) { collection in
                    toggleButton(collection.name, isOn: ui.filters.collectionIDs.contains(collection.id)) {
                        toggle(&ui.filters.collectionIDs, collection.id)
                    }
                }
            }
        } label: {
            SearchFacetChipLabel(title: "Collection", value: summary(selectedCollectionNames), systemImage: "folder")
        }
        .accessibilityLabel("Collection filter")
        .accessibilityValue(summary(selectedCollectionNames) ?? "Any")
        .accessibilityIdentifier("searchFacet-\(SearchFacetKind.collection.identifierName)")
    }

    private var imageSourceMenu: some View {
        Menu {
            Section("What the picture is") {
                ForEach(SearchImageSource.allCases) { source in
                    toggleButton(source.label, isOn: ui.filters.imageSources.contains(source)) {
                        toggle(&ui.filters.imageSources, source)
                    }
                }
            }
        } label: {
            SearchFacetChipLabel(title: "Image", value: summary(ui.filters.imageSources.map(\.label)), systemImage: "photo")
        }
        .accessibilityLabel("Image source filter")
        .accessibilityValue(summary(ui.filters.imageSources.map(\.label)) ?? "Any")
        .accessibilityIdentifier("searchFacet-\(SearchFacetKind.imageSource.identifierName)")
    }

    private var selectedCollectionNames: [String] {
        collections.filter { ui.filters.collectionIDs.contains($0.id) }.map(\.name)
    }

    // MARK: Active filters

    private struct ActiveChip: Identifiable {
        var id: String
        var label: String
        var remove: () -> Void
    }

    private var activeChips: [ActiveChip] {
        var chips: [ActiveChip] = []
        for type in SearchResultType.allCases where ui.filters.types.contains(type) {
            chips.append(ActiveChip(id: "type-\(type.rawValue)", label: type.filterLabel) { ui.filters.types.remove(type) })
        }
        for category in GarmentCategory.allCases where ui.filters.categories.contains(category) {
            chips.append(ActiveChip(id: "cat-\(category.rawValue)", label: category.label) { ui.filters.categories.remove(category) })
        }
        for family in ColorFamily.allCases where ui.filters.colors.contains(family) {
            chips.append(ActiveChip(id: "color-\(family.rawValue)", label: family.label) { ui.filters.colors.remove(family) })
        }
        if ui.filters.ownership != .current {
            chips.append(ActiveChip(id: "ownership", label: ui.filters.ownership.chipLabel) { ui.filters.ownership = .current })
        }
        if ui.filters.availableOnly {
            chips.append(ActiveChip(id: "available", label: "Available only") { ui.filters.availableOnly = false })
        }
        if ui.filters.favoritesOnly {
            chips.append(ActiveChip(id: "favorites", label: "Favorites") { ui.filters.favoritesOnly = false })
        }
        for collection in collections where ui.filters.collectionIDs.contains(collection.id) {
            chips.append(ActiveChip(id: "collection-\(collection.id)", label: collection.name) { ui.filters.collectionIDs.remove(collection.id) })
        }
        let knownCollections = Set(collections.map(\.id))
        for id in ui.filters.collectionIDs.sorted() where !knownCollections.contains(id) {
            chips.append(ActiveChip(id: "collection-\(id)", label: "Removed collection") { ui.filters.collectionIDs.remove(id) })
        }
        for source in SearchImageSource.allCases where ui.filters.imageSources.contains(source) {
            chips.append(ActiveChip(id: "image-\(source.rawValue)", label: source.label) { ui.filters.imageSources.remove(source) })
        }
        return chips
    }

    private var activeFilters: some View {
        let chips = activeChips
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                Text("Active filters · \(chips.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityLabel("Active filters, \(chips.count)")
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.xs)
                Button("Clear All") { ui.filters.resetAll() }
                    .buttonStyle(.quietLinkInline)
                    .hoverEffect(.highlight)
                    .accessibilityHint("Removes every filter. Garments return to Current owned.")
                    .accessibilityIdentifier("clearAllFilters")
            }
            ChipCarousel(isExpanded: ui.disclosure("activeFilterChips"), itemsLabel: "active filters") {
                ForEach(chips) { chip in
                    Button(action: chip.remove) {
                        HStack(spacing: Spacing.xxs) {
                            Text(chip.label)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Image(systemName: "xmark")
                                .font(.caption.weight(.bold))
                                .accessibilityHidden(true)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryAction)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xxs)
                        .frame(minHeight: HitTarget.minimum)
                        .background(Capsule().fill(Palette.accentSurface))
                        .overlay(Capsule().strokeBorder(Palette.primaryAction, lineWidth: 1))
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityLabel("Remove filter \(chip.label)")
                    .accessibilityIdentifier("searchActiveFilter-\(chip.id)")
                }
            }
        }
    }

    // MARK: Helpers

    private func toggle<T: Hashable>(_ set: inout Set<T>, _ value: T) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }

    private func toggleButton(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isOn {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
        .menuActionDismissBehavior(.disabled)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func summary(_ values: [String]) -> String? {
        let sorted = values.sorted()
        switch sorted.count {
        case 0: return nil
        case 1: return sorted[0]
        default: return "\(sorted[0]) +\(sorted.count - 1)"
        }
    }
}

/// One row of chips that scrolls sideways, with a control at the end to show them all.
private struct SearchChipRow<Content: View>: View {
    var label: String
    var itemsLabel: String
    var isExpanded: Binding<Bool>
    @ViewBuilder var content: () -> Content

    var body: some View {
        ChipCarousel(isExpanded: isExpanded, itemsLabel: itemsLabel) { content() }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
    }
}

/// Capsule label for a facet menu: title, current value and a disclosure chevron.
private struct SearchFacetChipLabel: View {
    var title: String
    var value: String?
    var systemImage: String
    var isActive: Bool?

    private var active: Bool { isActive ?? (value != nil) }

    var body: some View {
        HStack(spacing: Spacing.xxs + 2) {
            Image(systemName: active ? "checkmark" : systemImage)
                .font(active ? .caption.weight(.bold) : .subheadline)
            Text(value.map { "\(title): \($0)" } ?? title)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(active ? Palette.primaryAction : Palette.primaryText)
        .padding(.horizontal, Spacing.m)
        .frame(minHeight: HitTarget.minimum)
        .background(Capsule().fill(active ? Palette.accentSurface : Palette.surface))
        .overlay(Capsule().strokeBorder(active ? Palette.primaryAction : Palette.controlBorder, lineWidth: active ? 1.5 : 1))
        .contentShape(Capsule())
        .hoverEffect(.highlight)
    }
}
