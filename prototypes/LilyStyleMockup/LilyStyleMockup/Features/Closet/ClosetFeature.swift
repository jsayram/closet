import SwiftUI

// MARK: - Closet UI state

/// Closet browsing state owned by `AppModel` (`app.closetUI`). It lives outside
/// the views so the chosen view, visible filters and selected garment survive
/// rotation, resizing, sheets and navigation. Nothing here dispatches a service.
@Observable
final class ClosetUIState {
    /// Inventory view (Current, Wishlist, Inspiration, Not arrived, No longer owned, Trash, All).
    var view: ClosetView = .current
    /// Optional category quick filter. Stays visible even when the view has none of it.
    var category: GarmentCategory?
    /// Shows only Dirty items.
    var dirtyOnly = false
    /// Shows only items whose status is Available. Never removed silently.
    var availableOnly = false
    /// Optional local name/other-name/notes filter. Search is the full surface.
    var filterText = ""
    /// Selected garment for the side-by-side detail pane (kept across width changes).
    var selectedGarmentID: String?
    /// Open "Mark unavailable" draft (garment, until-date choice). Kept here so it
    /// survives the detail moving between the side pane and a pushed screen.
    var unavailableDraft: ClosetUnavailableDraft?
    /// Garment whose permanent-deletion review was opened from a grid tile.
    var deletionReviewID: String?
    /// Garment whose Edit details sheet or deletion review is open from its detail screen.
    /// Kept here so the sheet comes back when the detail moves between the side pane and a
    /// pushed screen, or the shell switches between tabs and the sidebar.
    var factsEditorID: String?
    var detailDeletionReviewID: String?
    /// Garment the one-pane grid pushed as detail. If the window then widens to
    /// two panes, that pushed screen folds back into the side pane.
    var pushedDetailID: String?
    /// Top-most visible tile, so the grid comes back where Lily left it after a section
    /// switch or shell change even when nothing is selected.
    var scrollAnchor: String?
    /// Quick-filter chips shown wrapped instead of on one scrolling row.
    var filtersExpanded = false
    /// "More facts" row in the garment detail's About card.
    var factsExpanded = false
    /// "Other suitcases" row in the garment detail's Suitcases card.
    var otherSuitcasesExpanded = false

    init() {}

    var trimmedFilterText: String { filterText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasActiveFilters: Bool {
        category != nil || dirtyOnly || availableOnly || !trimmedFilterText.isEmpty
    }

    /// Dirty and Available only exclude each other; both stay on until she turns one off.
    var hasConflictingStatusFilters: Bool { dirtyOnly && availableOnly }

    func clearFilters() {
        category = nil
        dirtyOnly = false
        availableOnly = false
        filterText = ""
    }

    /// Applies the visible quick filters to an already scoped and viewed list.
    func applyFilters(to garments: [Garment]) -> [Garment] {
        let terms = trimmedFilterText.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        return garments.filter { garment in
            if let category, garment.category != category { return false }
            if dirtyOnly, garment.availability != .dirty { return false }
            if availableOnly, garment.availability != .available { return false }
            if !terms.isEmpty {
                let haystack = Self.filterableText(garment)
                return terms.allSatisfy { haystack.contains($0) }
            }
            return true
        }
    }

    /// Her own words for the item: name, other names, details, notes, plus confirmed color/brand/type.
    static func filterableText(_ garment: Garment) -> String {
        var parts = [garment.displayName, garment.notes, garment.kind.label, garment.category.label]
        parts += garment.annotations.map(\.text)
        if let brand = garment.brand { parts.append(brand) }
        if let color = garment.color { parts.append(color.name); parts.append(color.family.label) }
        return parts.joined(separator: " ").lowercased()
    }

    /// Plain-language summary of active filters, used in empty states and VoiceOver.
    var activeFilterSummary: String {
        var parts: [String] = []
        if dirtyOnly { parts.append("Dirty") }
        if availableOnly { parts.append("Available only") }
        if let category { parts.append(category.pluralLabel) }
        if !trimmedFilterText.isEmpty { parts.append("“\(trimmedFilterText)”") }
        return parts.joined(separator: ", ")
    }
}

/// In-progress "Mark unavailable" / "Change date" form for one garment.
struct ClosetUnavailableDraft: Equatable {
    var garmentID: String
    var hasEndDate: Bool
    var endDate: Date
}

/// Identifiable wrapper so the grid can present the deletion review sheet.
struct ClosetDeletionReviewTarget: Identifiable {
    var id: String
}

// MARK: - Layout

/// Available-space layout decision for the Closet. Two panes appear only when
/// both the grid and the detail stay readable; otherwise tiles push detail.
struct ClosetLayout: Equatable {
    /// Width the Closet actually receives (the detail column on iPad).
    var width: CGFloat
    /// Short windows (a phone on its side) keep one pane so the detail isn't a sliver.
    /// Uses the vertical size class rather than measured height, so the software
    /// keyboard appearing can't collapse the detail pane mid-edit.
    var isVerticallyCompact: Bool

    var widthClass: WidthClass { WidthClass(width: width) }

    /// Grid + selected detail side by side: needs room for two readable grid
    /// columns next to the detail.
    var isTwoPane: Bool {
        widthClass != .compact && width >= 680 && !isVerticallyCompact
    }

    var detailWidth: CGFloat {
        switch widthClass {
        case .wide: min(460, width * 0.4)
        default: min(400, max(340, width * 0.45))
        }
    }

    func tileMinimum(for typeSize: DynamicTypeSize) -> CGFloat {
        if typeSize.isAccessibilitySize { return 220 }
        if width < 360 { return 132 }
        return widthClass == .wide ? 170 : 150
    }
}

// MARK: - Closet screen

/// Closet: source selector, inventory views, visible quick filters, an adaptive
/// garment grid and (when there is room) the selected garment beside it.
struct ClosetScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var pending: ClosetPendingAction?

    init() {}

    var body: some View {
        GeometryReader { geo in
            let layout = ClosetLayout(width: geo.size.width, isVerticallyCompact: verticalSizeClass == .compact)
            HStack(spacing: 0) {
                ClosetBrowserView(layout: layout, pending: $pending)
                    .frame(maxWidth: .infinity)
                if layout.isTwoPane {
                    Rectangle()
                        .fill(Palette.divider)
                        .frame(width: 1)
                        .ignoresSafeArea(edges: .bottom)
                        .accessibilityHidden(true)
                    ClosetDetailPane()
                        .frame(width: layout.detailWidth)
                }
            }
            .navigationBarTitleDisplayMode(layout.isTwoPane ? .inline : .large)
        }
        .themedScreenBackground()
        .navigationTitle("Closet")
        .toolbar { toolbarContent }
        .closetLifecycleConfirmations($pending)
        .sheet(item: Binding(
            get: { app.closetUI.deletionReviewID.map(ClosetDeletionReviewTarget.init(id:)) },
            set: { app.closetUI.deletionReviewID = $0?.id }
        )) { target in
            ClosetDeletionReviewSheet(garmentID: target.id)
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                app.push(.suitcases)
            } label: {
                Label("Suitcases", systemImage: "suitcase")
            }
            .accessibilityHint("Create suitcases and manage which clothes are linked to them")
            .accessibilityIdentifier("suitcasesButton")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                app.push(.search(.closet))
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
            .keyboardShortcut("f", modifiers: .command)
            .accessibilityHint("Search your clothes by name, other names, color or notes")
            .accessibilityIdentifier("closetSearchButton")

            Button {
                app.present(.addGarment(AddGarmentPrefill(intoSuitcaseID: app.workingScope.suitcaseID)))
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .accessibilityHint(app.workingScope.isSuitcase
                               ? "Adds a garment to Main Closet; you can review linking it to \(app.workingScopeName)"
                               : "Adds a garment from a photo, a paste or just a name")
            .accessibilityIdentifier("addItemButton")
        }
    }
}

/// Right-hand pane in two-pane layouts: the selected garment, or a gentle prompt.
struct ClosetDetailPane: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Group {
            if let id = app.closetUI.selectedGarmentID {
                GarmentDetailView(garmentID: id, isEmbedded: true)
                    .id(id)
            } else {
                ScrollView {
                    EmptyStateView(
                        title: "Choose an item",
                        message: "Select a garment to see its status, names, suitcases and saved looks here.",
                        systemImage: "hand.tap"
                    )
                    .padding(.top, Spacing.xxl)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
    }
}

#Preview("Closet — iPhone") {
    NavigationStack {
        ClosetScreen()
            .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
    }
    .previewEnvironment()
}

#Preview("Closet — two panes", traits: .landscapeLeft) {
    let model = AppModel.preview
    model.closetUI.selectedGarmentID = "g-lace-top"
    return NavigationStack {
        ClosetScreen()
            .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
    }
    .frame(width: 1000, height: 760)
    .previewEnvironment(model)
}

#Preview("Closet — empty suitcase") {
    let model = AppModel.preview
    model.selectScope(.suitcase(DemoFixtures.empty))
    return NavigationStack {
        ClosetScreen()
    }
    .previewEnvironment(model)
}
