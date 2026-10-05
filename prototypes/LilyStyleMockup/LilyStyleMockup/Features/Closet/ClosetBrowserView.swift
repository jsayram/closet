import SwiftUI

/// Scrollable Closet content: source, view picker, quick filters, summary and grid.
/// The same instance is kept when the layout switches between one and two panes,
/// so scroll position survives rotation and window resizing.
struct ClosetBrowserView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    var layout: ClosetLayout
    @Binding var pending: ClosetPendingAction?

    var body: some View {
        let ui = app.closetUI
        let scope = app.workingScope
        let base = app.store.garments(view: ui.view, scope: scope)
        let shown = ui.applyFilters(to: base)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ClosetHeaderView(base: base, shown: shown, onOpen: open)
                    content(base: base, shown: shown)
                }
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xxl)
            }
            .rememberedScrollPosition(Binding(get: { ui.scrollAnchor }, set: { ui.scrollAnchor = $0 }), firstID: shown.first?.id)
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("closetGrid")
            .task(id: layout.isTwoPane) {
                // Keep the selected garment in view after a layout change. A nil anchor
                // scrolls only if it is off screen, so returning from detail doesn't jump.
                guard let id = app.closetUI.selectedGarmentID, shown.contains(where: { $0.id == id }) else { return }
                await Task.yield()
                proxy.scrollTo(id)
            }
        }
    }

    // MARK: Content states

    @ViewBuilder
    private func content(base: [Garment], shown: [Garment]) -> some View {
        if let suitcaseID = app.workingScope.suitcaseID,
           let suitcase = app.store.suitcase(suitcaseID),
           app.store.memberIDs(of: suitcaseID).isEmpty {
            ClosetEmptySuitcaseView(suitcase: suitcase)
        } else if base.isEmpty {
            ClosetEmptyViewState(view: app.closetUI.view)
        } else if shown.isEmpty {
            ClosetNoMatchesView(totalInView: base.count)
        } else {
            grid(shown)
        }
    }

    private func grid(_ garments: [Garment]) -> some View {
        let columns = [GridItem(.adaptive(minimum: layout.tileMinimum(for: typeSize), maximum: 280),
                                spacing: Spacing.s, alignment: .top)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.l) {
            ForEach(garments) { garment in
                ClosetGarmentTile(
                    garment: garment,
                    isSelected: layout.isTwoPane && app.closetUI.selectedGarmentID == garment.id,
                    isRemembered: !layout.isTwoPane && app.closetUI.selectedGarmentID == garment.id,
                    onOpen: { open(garment.id) },
                    onRequest: { pending = $0 }
                )
                .id(garment.id)
            }
        }
        .scrollTargetLayout()
        .padding(.horizontal, Spacing.m)
    }

    /// Two panes: select in place. One pane: remember the selection and push detail.
    private func open(_ id: String) {
        app.closetUI.selectedGarmentID = id
        if !layout.isTwoPane {
            app.closetUI.pushedDetailID = id
            app.push(.garment(id))
        } else {
            app.closetUI.pushedDetailID = nil
        }
    }
}

// MARK: - Header

/// Source, view picker, local filter, quick-filter chips and the summary row.
struct ClosetHeaderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    var base: [Garment]
    var shown: [Garment]
    var onOpen: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sourceRow
                .padding(.horizontal, Spacing.m)
            if let fallback = app.store.scopeFallback {
                InlineBanner(style: .caution, title: "Browsing Main Closet", message: fallback.explanation,
                             actionTitle: "Use Main Closet") { app.selectScope(.mainCloset) }
                    .padding(.horizontal, Spacing.m)
            } else if app.store.awaitingSourceChoice {
                InlineBanner(style: .caution, title: "Choose a source before styling",
                             message: "You're browsing Main Closet. Pick Main Closet or a suitcase deliberately before Style Me uses it.",
                             actionTitle: "Use Main Closet", action: { app.selectScope(.mainCloset) },
                             summary: "You're browsing Main Closet for now.")
                    .padding(.horizontal, Spacing.m)
            }
            viewAndFilterRow
                .padding(.horizontal, Spacing.m)
            ClosetFilterChips(base: base)
            if let note = viewNote {
                CollapsibleText(note.full, summary: note.short, threshold: 1, topic: "the \(app.closetUI.view.label) view")
                    .padding(.horizontal, Spacing.m)
            }
            ClosetSummaryRow(base: base, shown: shown)
                .padding(.horizontal, Spacing.m)
            processingBanner
        }
    }

    // MARK: Source

    private var sourceRow: some View {
        HStack(spacing: Spacing.xs) {
            SourceSelector(onManage: { app.push(.suitcases) })
            if app.workingScope.isSuitcase {
                InfoButton("this source", title: app.workingScopeName,
                           text: "Only clothes linked to \(app.workingScopeName). Main Closet still has everything.")
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: View picker + local filter

    @ViewBuilder private var viewAndFilterRow: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ClosetViewPicker()
                ClosetLocalFilterField()
            }
        } else {
            HStack(spacing: Spacing.s) {
                ClosetViewPicker()
                ClosetLocalFilterField()
            }
        }
    }

    /// One short line for the view, with the full wording behind "More" when it doesn't fit.
    private var viewNote: (short: String, full: String)? {
        switch app.closetUI.view {
        case .current: nil
        case .wishlist: ("Ideas you might buy.", "Ideas you might buy. They're never counted as owned or used as your clothes.")
        case .inspiration: ("Inspiration only.", "Saved for inspiration only. Not part of your wardrobe.")
        case .notArrived: ("Bought but not here yet.", "Bought but not here yet. They join your current closet when you mark them arrived.")
        case .noLongerOwned: ("Kept for history.", "Kept for history with their photos, names and past looks. Not used for styling.")
        case .trash: ("Recoverable for 30 days.", "Recoverable for 30 days, then deleted permanently. Open an item to restore it or review deletion.")
        case .all: ("Everything except Trash.", "Everything except Trash, with each item's ownership and status shown.")
        }
    }

    // MARK: Processing / import status

    @ViewBuilder private var processingBanner: some View {
        let scoped = app.store.garments.filter { app.store.isInScope($0, app.workingScope) && !$0.isTrashed }
        let processing = scoped.filter { $0.processing == .processing }
        let failed = scoped.filter { $0.processing == .failed }
        if !processing.isEmpty || !failed.isEmpty {
            let first = (failed + processing).first
            InlineBanner(
                style: failed.isEmpty ? .info : .caution,
                title: processingTitle(processing: processing.count, failed: failed.count),
                message: "Simulated on-device photo processing. Your original photos are always kept, and items stay usable while this runs.",
                actionTitle: first.map { "Review \($0.displayName)" },
                action: first.map { garment in { onOpen(garment.id) } },
                summary: "Simulated. Your originals are kept."
            )
            .padding(.horizontal, Spacing.m)
        }
    }

    private func processingTitle(processing: Int, failed: Int) -> String {
        var parts: [String] = []
        if processing > 0 { parts.append(processing == 1 ? "1 photo processing" : "\(processing) photos processing") }
        if failed > 0 { parts.append(failed == 1 ? "1 couldn't be processed, original kept" : "\(failed) couldn't be processed, originals kept") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - View picker

struct ClosetViewPicker: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        @Bindable var ui = app.closetUI
        let scope = app.workingScope
        Menu {
            Picker("Closet view", selection: $ui.view) {
                ForEach(ClosetView.allCases) { view in
                    Label("\(view.label) (\(app.store.garments(view: view, scope: scope).count))",
                          systemImage: Self.icon(for: view))
                        .tag(view)
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: Self.icon(for: ui.view))
                    .foregroundStyle(Palette.primaryAction)
                    .accessibilityHidden(true)
                Text(ui.view.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .lineLimit(typeSize.isAccessibilitySize ? 3 : 1)
                    .multilineTextAlignment(.leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(Palette.surface))
            .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
            .contentShape(Capsule())
        }
        .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: false)
        .hoverEffect(.highlight)
        .accessibilityLabel("Closet view: \(ui.view.label)")
        .accessibilityValue("\(app.store.garments(view: ui.view, scope: scope).count) items")
        .accessibilityHint("Switch between current clothes, wishlist, inspiration, not arrived, no longer owned, Trash and all items")
        .accessibilityIdentifier("closetViewPicker")
    }

    static func icon(for view: ClosetView) -> String {
        switch view {
        case .current: "cabinet"
        case .wishlist: "heart.text.square"
        case .inspiration: "lightbulb"
        case .notArrived: "shippingbox"
        case .noLongerOwned: "arrow.uturn.left.circle"
        case .trash: "trash"
        case .all: "square.grid.2x2"
        }
    }
}

// MARK: - Local filter field

/// Quick filter over this view by her own words. Full search lives behind the Search button.
struct ClosetLocalFilterField: View {
    @Environment(AppModel.self) private var app
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var ui = app.closetUI
        HStack(spacing: Spacing.xs) {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            TextField("Filter by name or note", text: $ui.filterText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityLabel("Filter this view by name, other names or notes")
                .accessibilityIdentifier("closetFilterField")
            if !ui.filterText.isEmpty {
                Button {
                    ui.filterText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondaryText)
                        .minimumHitTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear name filter")
            }
        }
        .padding(.leading, Spacing.s)
        .frame(maxWidth: .infinity, minHeight: HitTarget.minimum)
        .background(Capsule().fill(Palette.surface))
        .overlay(Capsule().strokeBorder(focused ? Palette.primaryAction : Palette.controlBorder, lineWidth: focused ? 1.5 : 1))
        .onTapGesture { focused = true }
    }
}

// MARK: - Quick filter chips

/// Dirty and Available toggles plus a Type dropdown. The dropdown always shows the
/// type in use, even if the current view has nothing in that category.
struct ClosetFilterChips: View {
    @Environment(AppModel.self) private var app
    var base: [Garment]

    var body: some View {
        let ui = app.closetUI
        let present = GarmentCategory.allCases.filter { category in
            base.contains { $0.category == category } || ui.category == category
        }
        let dirtyInView = base.filter { $0.availability == .dirty }.count

        FlowLayout(spacing: Spacing.xs) {
            DropdownChip(items: [GarmentCategory?.none] + present.map { Optional($0) },
                         selection: ui.category,
                         title: { $0?.pluralLabel ?? "All types" },
                         systemImage: { $0?.systemImage },
                         identifier: { "closetCategory-\($0?.rawValue ?? "all")" },
                         isActive: ui.category != nil,
                         accessibilityTitle: "Type",
                         menuIdentifier: "closetCategoryMenu") { ui.category = $0 }

            CapsuleChip(title: dirtyInView > 0 ? "Dirty (\(dirtyInView))" : "Dirty",
                        systemImage: BadgeKind.dirty.systemImage,
                        isSelected: ui.dirtyOnly) {
                ui.dirtyOnly.toggle()
            }
            .accessibilityLabel(dirtyInView > 0 ? "Dirty filter, \(dirtyInView) dirty in this view" : "Dirty filter")
            .accessibilityValue(ui.dirtyOnly ? "On" : "Off")
            .accessibilityHint("Shows only items marked Dirty")
            .accessibilityIdentifier("closetFilter-dirty")

            CapsuleChip(title: "Available", systemImage: "checkmark.circle", isSelected: ui.availableOnly) {
                ui.availableOnly.toggle()
            }
            .accessibilityLabel("Available only filter")
            .accessibilityValue(ui.availableOnly ? "On" : "Off")
            .accessibilityHint("Hides Dirty, Unavailable and Archived items until you turn it off")
            .accessibilityIdentifier("closetFilter-available")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Quick filters")
    }
}

// MARK: - Summary row

struct ClosetSummaryRow: View {
    @Environment(AppModel.self) private var app
    var base: [Garment]
    var shown: [Garment]

    var body: some View {
        let dirty = app.store.dirtyGarments(scope: app.workingScope).count
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                countText
                Spacer(minLength: Spacing.xs)
                clearButton
                laundryButton(dirty: dirty)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                countText
                HStack(spacing: Spacing.s) {
                    clearButton
                    laundryButton(dirty: dirty)
                }
            }
            // Largest text sizes: stack everything so neither button is squeezed.
            VStack(alignment: .leading, spacing: Spacing.xs) {
                countText
                clearButton
                laundryButton(dirty: dirty)
            }
        }
    }

    private var countText: some View {
        let ui = app.closetUI
        let text: String = if ui.hasActiveFilters {
            "Showing \(shown.count) of \(base.count)"
        } else {
            base.count == 1 ? "1 item" : "\(base.count) items"
        }
        return Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryText)
            .accessibilityLabel(ui.hasActiveFilters
                                ? "Showing \(shown.count) of \(base.count) items. Filters: \(ui.activeFilterSummary)"
                                : text)
    }

    @ViewBuilder private var clearButton: some View {
        if app.closetUI.hasActiveFilters {
            Button("Clear filters") {
                app.closetUI.clearFilters()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryAction)
            .minimumHitTarget()
            .hoverEffect(.highlight)
            .accessibilityIdentifier("closetClearFilters")
        }
    }

    private func laundryButton(dirty: Int) -> some View {
        Button {
            app.push(.laundry)
        } label: {
            Label(dirty > 0 ? "\(dirty) dirty — Laundry" : "Laundry", systemImage: "washer")
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel(dirty > 0 ? "\(dirty) dirty items. Open Laundry" : "Laundry. Nothing is marked dirty")
        .accessibilityIdentifier("laundryShortcut")
    }
}

// MARK: - Empty states

/// A valid empty suitcase stays selected. No fallback, no broadening.
struct ClosetEmptySuitcaseView: View {
    @Environment(AppModel.self) private var app
    var suitcase: Suitcase

    var body: some View {
        VStack(spacing: Spacing.s) {
            EmptyStateView(
                title: "\(suitcase.name) is empty",
                message: "Nothing is linked to this suitcase yet. It stays selected.",
                systemImage: "suitcase",
                actionTitle: "Add garments",
                action: { app.push(.suitcase(suitcase.id)) },
                detailsTitle: "What you can do"
            ) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ClosetNote("Add clothes from Main Closet or choose another source; nothing is added automatically.")
                    ClosetSourceMenu(title: "Choose another source")
                }
            }
            .accessibilityIdentifier("closetEmptySuitcase")
        }
        .padding(.horizontal, Spacing.m)
    }
}

/// Deliberate source choice as a menu (used by the empty-suitcase state).
struct ClosetSourceMenu: View {
    @Environment(AppModel.self) private var app
    var title: String

    var body: some View {
        Menu {
            Picker("Wardrobe source", selection: Binding(
                get: { app.workingScope },
                set: { app.selectScope($0) }
            )) {
                Label("Main Closet", systemImage: "cabinet").tag(WardrobeScope.mainCloset)
                ForEach(app.store.activeSuitcases()) { suitcase in
                    Label("\(suitcase.name) · \(app.store.memberIDs(of: suitcase.id).count)", systemImage: "suitcase")
                        .tag(WardrobeScope.suitcase(suitcase.id))
                }
            }
        } label: {
            Label(title, systemImage: "arrow.left.arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryAction)
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .hoverEffect(.highlight)
        .accessibilityHint("Pick Main Closet or another suitcase")
        .accessibilityIdentifier("closetChooseSource")
    }
}

/// Nothing in this view for the current source (no filters involved).
struct ClosetEmptyViewState: View {
    @Environment(AppModel.self) private var app
    var view: ClosetView

    var body: some View {
        let source = app.workingScopeName
        Group {
            switch view {
            case .current:
                if app.workingScope.isSuitcase {
                    EmptyStateView(title: "No current clothes in \(source)",
                                   message: "Its linked items are in other views, such as Not arrived or No longer owned.",
                                   systemImage: "cabinet", actionTitle: "Show all items") { app.closetUI.view = .all }
                } else {
                    EmptyStateView(title: "Your closet is empty",
                                   message: "Add your first item. A photo helps, but just a name works too.",
                                   systemImage: "cabinet", actionTitle: "Add item") {
                        app.present(.addGarment(AddGarmentPrefill()))
                    }
                }
            case .wishlist:
                EmptyStateView(title: "No wishlist items", message: "Things you're thinking about buying show up here. They're never counted as owned.", systemImage: "heart.text.square")
            case .inspiration:
                EmptyStateView(title: "No inspiration saved", message: "Ideas you save for inspiration show up here. They're not part of your wardrobe.", systemImage: "lightbulb")
            case .notArrived:
                EmptyStateView(title: "Nothing waiting to arrive", message: "Clothes you've bought but not received show here until you mark them arrived.", systemImage: "shippingbox")
            case .noLongerOwned:
                EmptyStateView(title: "Nothing marked no longer owned", message: "If you donate, sell or give something away, it moves here with its photos and past looks kept.", systemImage: "arrow.uturn.left.circle")
            case .trash:
                EmptyStateView(title: "Trash is empty", message: "Items you move to Trash stay here for 30 days before they're deleted permanently.", systemImage: "trash")
            case .all:
                EmptyStateView(title: "No items in \(source)", message: "Add clothes, or switch to another source.", systemImage: "square.grid.2x2")
            }
        }
        .padding(.horizontal, Spacing.m)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("closetEmptyView")
    }
}

/// Honest no-results state for active filters, with a one-tap Clear.
struct ClosetNoMatchesView: View {
    @Environment(AppModel.self) private var app
    var totalInView: Int

    var body: some View {
        let ui = app.closetUI
        VStack(spacing: Spacing.s) {
            EmptyStateView(
                title: "Nothing matches these filters",
                message: message,
                systemImage: "line.3.horizontal.decrease.circle",
                actionTitle: "Clear filters",
                action: { ui.clearFilters() }
            )
            if ui.hasConflictingStatusFilters {
                MoreMenu("Turn one filter off", identifier: "closetConflictMenu") {
                    Button("Turn off Dirty", systemImage: BadgeKind.dirty.systemImage) { app.closetUI.dirtyOnly = false }
                    Button("Turn off Available only", systemImage: "checkmark.circle") { app.closetUI.availableOnly = false }
                }
            }
        }
        .padding(.horizontal, Spacing.m)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("closetNoMatches")
    }

    private var message: String {
        let ui = app.closetUI
        if ui.hasConflictingStatusFilters {
            return "An item can't be Dirty and Available at the same time. Turn one of those filters off to see items again."
        }
        return "\(totalInView) \(totalInView == 1 ? "item is" : "items are") in \(app.closetUI.view.label) for \(app.workingScopeName), but none match: \(ui.activeFilterSummary)."
    }
}
