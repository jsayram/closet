import SwiftUI

/// Laundry UI state owned by `AppModel`: scope, the in-progress load selection and
/// the captured review survive rotation, resizing and navigation.
@Observable
final class LaundryUIState {
    /// `nil` until she picks; defaults to the working source when it's a suitcase.
    var scopeChoice: LaundryScopeChoice?
    /// Suitcase used for "This suitcase" (set from a suitcase, or picked here).
    var suitcaseID: String?
    var isSelectingLoad = false
    /// Never pre-filled: a load starts empty and she picks what she washed.
    var loadSelection: Set<String> = []
    /// Reviewed targets captured when a review opens.
    var pendingReview: LaundryReviewDraft?
    var lastOutcome: LaundryOutcome?
    var showsMarkDirtyPicker = false

    init() {}

    /// Opens laundry scoped to one suitcase (from Suitcase detail).
    func focus(onSuitcase id: String) {
        scopeChoice = .thisSuitcase
        suitcaseID = id
        endSelection()
    }

    func focusEntireCloset() {
        scopeChoice = .entireCloset
        endSelection()
    }

    func endSelection() {
        isSelectingLoad = false
        loadSelection = []
    }
}

/// Laundry: individual Mark clean, a reviewed selected load, and a scoped,
/// confirmed Mark all. Local only; no AI, pictures or allowance.
struct LaundryScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var ui = app.laundryUI
        GeometryReader { geo in
            let width = WidthClass(width: geo.size.width)
            // Two panes only when both stay readable; accessibility sizes keep one column until wide.
            let split = width == .wide || (width == .intermediate && !dynamicTypeSize.isAccessibilitySize)
            let sideColumn: CGFloat = width == .wide ? 380 : 320
            if !split {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l) {
                        controls
                        dirtySection(minimumColumn: 280, available: min(geo.size.width, 720) - Spacing.m * 2)
                        leftAloneSection
                        markDirtyCard
                        LaundryRulesNote()
                    }
                    .padding(Spacing.m)
                    .readableWidth()
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.l) {
                            dirtySection(minimumColumn: width == .wide ? 320 : 300,
                                         available: geo.size.width - sideColumn - 1 - Spacing.m * 2)
                            leftAloneSection
                        }
                        .padding(Spacing.m)
                    }
                    .frame(maxWidth: .infinity)
                    Divider()
                        .ignoresSafeArea(edges: .bottom)
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.l) {
                            controls
                            markDirtyCard
                            LaundryRulesNote()
                        }
                        .padding(Spacing.m)
                    }
                    .frame(width: sideColumn)
                }
            }
        }
        .themedScreenBackground()
        .navigationTitle("Laundry")
        .safeAreaInset(edge: .bottom) {
            if ui.isSelectingLoad {
                selectionBar
            }
        }
        .sheet(item: $ui.pendingReview) { draft in
            LaundryReviewSheet(draft: draft)
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .sheet(isPresented: $ui.showsMarkDirtyPicker) {
            LaundryMarkDirtySheet(scope: wardrobeScope, scopeName: scopeName)
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }

    // MARK: Scope resolution

    private var requestedChoice: LaundryScopeChoice {
        app.laundryUI.scopeChoice ?? (resolvedSuitcase != nil && app.workingScope.isSuitcase ? .thisSuitcase : .entireCloset)
    }

    /// The suitcase for "This suitcase": an explicit pick, else the working source.
    /// Archived or deleted suitcases don't resolve (laundry for them would skip everything).
    private var resolvedSuitcase: Suitcase? {
        let id = app.laundryUI.suitcaseID ?? app.workingScope.suitcaseID
        guard let suitcase = app.store.suitcase(id), !suitcase.isArchived else { return nil }
        return suitcase
    }

    private var needsSuitcase: Bool { requestedChoice == .thisSuitcase && resolvedSuitcase == nil }

    private var wardrobeScope: WardrobeScope {
        if requestedChoice == .thisSuitcase, let suitcase = resolvedSuitcase { return .suitcase(suitcase.id) }
        return .mainCloset
    }

    private var sweepScope: LaundryScope {
        if case let .suitcase(id) = wardrobeScope { return .suitcase(id) }
        return .entireCloset
    }

    private var scopeName: String {
        if case .suitcase = wardrobeScope, let suitcase = resolvedSuitcase { return suitcase.name }
        return "Entire closet"
    }

    private var scopeLabel: String {
        if case .suitcase = wardrobeScope, let suitcase = resolvedSuitcase { return "This suitcase: \(suitcase.name)" }
        return "Entire closet"
    }

    private var unresolvedNote: String? {
        guard needsSuitcase else { return nil }
        if let id = app.laundryUI.suitcaseID {
            if let suitcase = app.store.suitcase(id), suitcase.isArchived {
                return "\(suitcase.name) is archived, so its items can't be cleaned as a suitcase. Unarchive it, or pick another suitcase."
            }
            if app.store.suitcase(id) == nil {
                return "That suitcase was deleted. Its garments are still in Main Closet. Pick another suitcase or use Entire closet."
            }
        }
        return "Choose which suitcase."
    }

    private var dirtyItems: [Garment] {
        guard !needsSuitcase else { return [] }
        return app.store.dirtyGarments(scope: wardrobeScope)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    /// Selected items that are still visible in this scope's Dirty list.
    private var effectiveSelection: [String] {
        let selection = app.laundryUI.loadSelection
        return dirtyItems.map(\.id).filter { selection.contains($0) }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            scopeCard
            if let outcome = app.laundryUI.lastOutcome {
                LaundryOutcomeCard(outcome: outcome) {
                    app.laundryUI.lastOutcome = nil
                }
            }
            actionsCard
        }
    }

    private var scopeCard: some View {
        let choice = Binding<LaundryScopeChoice>(
            get: { requestedChoice },
            set: { newValue in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    app.laundryUI.scopeChoice = newValue
                }
            }
        )
        let active = app.store.activeSuitcases()
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Which clothes?")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)

            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    Picker("Laundry scope", selection: choice) {
                        Text("Entire closet").tag(LaundryScopeChoice.entireCloset)
                        Text("This suitcase").tag(LaundryScopeChoice.thisSuitcase)
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("Laundry scope", selection: choice) {
                        Text("Entire closet").tag(LaundryScopeChoice.entireCloset)
                        Text("This suitcase").tag(LaundryScopeChoice.thisSuitcase)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .accessibilityIdentifier("laundryScopePicker")

            if requestedChoice == .thisSuitcase {
                if let suitcase = resolvedSuitcase {
                    HStack(spacing: Spacing.s) {
                        Label(suitcase.name, systemImage: "suitcase.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.primaryText)
                        Spacer(minLength: Spacing.xs)
                        if active.count > 1 {
                            Menu {
                                ForEach(active) { other in
                                    Button {
                                        app.laundryUI.suitcaseID = other.id
                                        app.laundryUI.scopeChoice = .thisSuitcase
                                    } label: {
                                        if other.id == suitcase.id {
                                            Label(other.name, systemImage: "checkmark")
                                        } else {
                                            Text(other.name)
                                        }
                                    }
                                }
                            } label: {
                                Text("Change")
                                    .font(.subheadline.weight(.semibold))
                                    .minimumHitTarget()
                            }
                            .accessibilityLabel("Change suitcase")
                            .accessibilityIdentifier("laundrySuitcaseMenu")
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        if let unresolvedNote {
                            Text(unresolvedNote)
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if active.isEmpty {
                            Text("You don't have any active suitcases.")
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                        } else {
                            ChipCarousel(itemsLabel: "suitcases") {
                                ForEach(active) { suitcase in
                                    CapsuleChip(title: suitcase.name, systemImage: "suitcase", isSelected: false) {
                                        app.laundryUI.suitcaseID = suitcase.id
                                        app.laundryUI.scopeChoice = .thisSuitcase
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if !needsSuitcase {
                Text(dirtyItems.isEmpty ? "Nothing dirty in \(scopeName)." : "\(LaundryText.items(dirtyItems.count)) dirty in \(scopeName).")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityIdentifier("laundryDirtyCount")
            }
        }
        .cardStyle()
    }

    private var actionsCard: some View {
        let ui = app.laundryUI
        let hasDirty = !dirtyItems.isEmpty
        let sweepTitle: String = {
            if !hasDirty { return "Nothing to mark clean" }
            return sweepScope == .entireCloset ? "Mark all dirty items clean" : "Mark dirty items in this suitcase clean"
        }()
        // The visible label is shorter beside the More menu; VoiceOver keeps the full one.
        let sweepShortTitle = hasDirty && sweepScope != .entireCloset ? "Mark suitcase clean" : sweepTitle

        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xxs) {
                Text("Mark clean")
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                InfoButton("marking clean", title: "Mark clean") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        InfoText(text: "Select a load. For one load: pick only what you actually washed. Nothing is selected for you.")
                        InfoText(text: "Mark all. You'll see the scope, count and items before anything changes.")
                    }
                }
            }

            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                    if ui.isSelectingLoad {
                        ui.endSelection()
                    } else {
                        ui.loadSelection = []
                        ui.isSelectingLoad = true
                    }
                }
            } label: {
                Label(ui.isSelectingLoad ? "Stop selecting" : "Select a load", systemImage: ui.isSelectingLoad ? "xmark" : "checklist")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .disabled(!hasDirty && !ui.isSelectingLoad)
            .accessibilityHint(ui.isSelectingLoad ? "Leaves selection without changing anything" : "Pick only the items you actually washed")
            .accessibilityIdentifier("laundrySelectLoad")

            HStack(spacing: Spacing.xs) {
                Button {
                    reviewSweep()
                } label: {
                    Label(sweepShortTitle, systemImage: hasDirty ? "washer" : "checkmark.seal")
                        .multilineTextAlignment(.center)
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .disabled(!hasDirty || ui.isSelectingLoad)
                .accessibilityLabel(sweepTitle)
                .accessibilityHint("Shows the scope and count before anything changes")
                .accessibilityIdentifier("laundryMarkAll")

                if sweepScope != .entireCloset {
                    // Entire closet stays a separate, reviewed shortcut while viewing a suitcase.
                    let closetDirty = app.store.dirtyGarments(scope: .mainCloset).count
                    MoreMenu(identifier: "laundryMarkAllMore") {
                        Button(closetDirty == 0 ? "Entire closet: nothing to mark clean" : "Mark all dirty items clean · Entire closet",
                               systemImage: "cabinet") {
                            reviewSweep(.entireCloset)
                        }
                        .disabled(closetDirty == 0)
                        .accessibilityHint("Reviews every dirty item in your closet, not just this suitcase, before anything changes")
                        .accessibilityIdentifier("laundryMarkAllEntireCloset")
                    }
                    .disabled(ui.isSelectingLoad)
                }
            }
        }
        .cardStyle()
    }

    /// Demo convenience, kept apart from the real cleaning actions.
    private var markDirtyCard: some View {
        let ui = app.laundryUI
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Button {
                ui.showsMarkDirtyPicker = true
            } label: {
                Label("Mark items dirty…", systemImage: "drop.triangle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.primaryAction)
            .hoverEffect(.highlight)
            .disabled(needsSuitcase || ui.isSelectingLoad)
            .accessibilityHint("Demo shortcut: pick available items to mark Dirty")
            .accessibilityIdentifier("laundryMarkDirtyButton")
            SimulationNotice(text: "Demo shortcut for trying laundry. Normally you'd mark something Dirty from the garment itself.",
                             systemImage: "theatermasks", label: "Demo", summary: "Shortcut for trying laundry")
        }
        .cardStyle(padding: Spacing.s)
    }

    // MARK: Dirty list

    @ViewBuilder
    private func dirtySection(minimumColumn: CGFloat, available: CGFloat) -> some View {
        let ui = app.laundryUI
        let items = dirtyItems
        // Never ask for a column wider than the space we have, or cards clip at large text sizes.
        let column = min(dynamicTypeSize.isAccessibilitySize ? 300 : minimumColumn, max(available, 160))
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Dirty", subtitle: needsSuitcase ? "Choose a suitcase first" : "\(LaundryText.items(items.count)) in \(scopeName)", editorial: true)

            if needsSuitcase {
                EmptyStateView(title: "Choose a suitcase",
                               message: unresolvedNote ?? "Pick which suitcase to look at, or switch to Entire closet.",
                               systemImage: "suitcase")
                    .cardStyle()
            } else if items.isEmpty {
                EmptyStateView(title: "Nothing to mark clean",
                               message: "No dirty items in \(scopeName). Anything you mark Dirty shows up here.",
                               systemImage: "checkmark.seal",
                               actionTitle: "Mark items dirty…") {
                    ui.showsMarkDirtyPicker = true
                }
                .cardStyle()
                .accessibilityIdentifier("laundryNothingToClean")
            } else {
                if ui.isSelectingLoad {
                    CollapsibleText("Tap each item you washed. Mark clean buttons come back when you stop selecting.",
                                    summary: "Tap each item you washed.", threshold: 1, topic: "selecting a load")
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: column), spacing: Spacing.s, alignment: .top)],
                          alignment: .leading, spacing: Spacing.s) {
                    ForEach(items) { garment in
                        LaundryDirtyRow(
                            garment: garment,
                            suitcaseNames: app.store.suitcases(containing: garment.id).filter { !$0.isArchived }.map(\.name),
                            isSelecting: ui.isSelectingLoad,
                            isSelected: ui.loadSelection.contains(garment.id),
                            onMarkClean: { markClean(garment) },
                            onToggle: { toggle(garment.id) }
                        )
                    }
                }
            }
        }
    }

    /// Dirty records laundry deliberately leaves alone (not arrived, no longer owned, Trash).
    @ViewBuilder
    private var leftAloneSection: some View {
        let items = needsSuitcase ? [] : app.store.garments.filter {
            app.store.isInScope($0, wardrobeScope) && $0.availability == .dirty && !$0.isCurrentlyOwned
        }
        if !items.isEmpty {
            DetailsDisclosure("Dirty but left alone", count: items.count, identifier: "laundryLeftAloneToggle") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Marked Dirty but left alone. Laundry never changes these.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(items) { garment in
                        HStack(alignment: .top, spacing: Spacing.s) {
                            GarmentThumbnail(garment: garment, size: 44, showsStatus: false)
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(garment.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.primaryText)
                                BadgeRow(badges: BadgeKind.status(for: garment))
                            }
                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: Selection bar

    private var selectionBar: some View {
        let count = effectiveSelection.count
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        return layout {
            VStack(alignment: .leading, spacing: 2) {
                Text(count == 0 ? "Select what you washed" : "\(LaundryText.items(count)) selected")
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                Text("Nothing changes until you confirm.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .accessibilityElement(children: .combine)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            Button("Cancel") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { app.laundryUI.endSelection() }
            }
            .buttonStyle(SecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            .accessibilityHint("Leaves selection. Nothing changes.")
            Button(count == 0 ? "Review" : "Review \(count)") {
                reviewLoad()
            }
            .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            .disabled(count == 0)
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityHint("Shows the selected items before anything changes")
            .accessibilityIdentifier("laundryReviewButton")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    // MARK: Actions

    private func toggle(_ id: String) {
        let ui = app.laundryUI
        if ui.loadSelection.contains(id) {
            ui.loadSelection.remove(id)
        } else {
            ui.loadSelection.insert(id)
        }
    }

    /// Individual Mark clean: one explicit tap, no extra modal, with Undo.
    private func markClean(_ garment: Garment) {
        var cleaned = false
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            cleaned = app.store.markClean(garment.id)
        }
        guard cleaned else {
            app.showToast("\(garment.displayName) wasn't changed. Its status changed since this list loaded.", style: .info)
            return
        }
        if let error = app.store.lastSaveError {
            app.showUndoToast("\(garment.displayName) marked clean, but \(error.prefix(1).lowercased() + error.dropFirst())")
        } else {
            app.showUndoToast("\(garment.displayName) marked clean. Saved on this device.")
        }
    }

    private func reviewLoad() {
        let ids = effectiveSelection
        guard !ids.isEmpty else { return }
        app.laundryUI.pendingReview = LaundryReviewDraft(
            kind: .selectedLoad,
            scope: .selected(ids),
            scopeLabel: "Selected items · \(scopeName)",
            targets: app.store.laundryTargets(for: .selected(ids)),
            requestedIDs: ids
        )
    }

    private func reviewSweep(_ override: LaundryScope? = nil) {
        let scope = override ?? sweepScope
        let targets = app.store.laundryTargets(for: scope)
        app.laundryUI.pendingReview = LaundryReviewDraft(
            kind: .sweep,
            scope: scope,
            scopeLabel: scope == .entireCloset ? "Entire closet" : scopeLabel,
            targets: targets,
            requestedIDs: targets.map(\.garmentID)
        )
    }
}

#Preview("Laundry · Entire closet") {
    NavigationStack {
        LaundryScreen()
    }
    .previewEnvironment()
}

#Preview("Laundry · Weekend") {
    let model = AppModel.preview
    model.laundryUI.focus(onSuitcase: DemoFixtures.weekend)
    return NavigationStack {
        LaundryScreen()
    }
    .previewEnvironment(model)
}
