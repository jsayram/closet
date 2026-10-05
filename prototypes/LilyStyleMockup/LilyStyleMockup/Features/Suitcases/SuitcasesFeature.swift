import SwiftUI

/// Suitcases UI state owned by `AppModel`, so the two-pane selection and the
/// Add from Main Closet draft survive rotation, resizing and navigation.
@Observable
final class SuitcasesUIState {
    /// Two-pane layouts: the entry shown beside the list. `nil` follows the working source.
    var selection: SuitcasesSelection?
    /// Details rows on the list, closed until she opens them.
    var showsArchived = false
    var showsShared = false
    /// "Manage suitcase" row on a suitcase's detail.
    var showsManage = false

    /// New suitcase sheet and its typed name, kept until Create or Cancel.
    var isCreatingSuitcase = false
    var createDraftName = ""

    // Add from Main Closet draft (kept per suitcase until confirmed or cancelled).
    var pickerSuitcaseID: String?
    var pickerQuery = ""
    var pickerCategory: GarmentCategory?
    var pickerIncludesNotCurrent = false
    var pickerSelection: Set<String> = []
    /// True while the picker sheet for `pickerSuitcaseID` is open.
    var isPickerPresented = false

    /// Latest membership add result, shown in the suitcase until dismissed.
    var lastAddOutcome: SuitcasesAddOutcome?

    init() {}

    /// Starts (or resumes) the picker draft for one suitcase, optionally preselecting dropped garments.
    func preparePicker(for suitcaseID: String, preselecting ids: [String] = []) {
        if pickerSuitcaseID != suitcaseID {
            pickerSuitcaseID = suitcaseID
            resetPickerDraft()
        }
        pickerSelection.formUnion(ids)
    }

    func resetPickerDraft() {
        pickerQuery = ""
        pickerCategory = nil
        pickerIncludesNotCurrent = false
        pickerSelection = []
    }
}

/// Suitcases: Main Closet plus named garment subsets. One source at a time;
/// membership links canonical garments and never copies them.
struct SuitcasesScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isOnScreen = false
    @State private var lifecycle = SuitcasesLifecycleState()
    @State private var isSplit = false

    var body: some View {
        GeometryReader { geo in
            let width = WidthClass(width: geo.size.width)
            // Side by side only when both panes stay readable; accessibility sizes keep one column until wide.
            let split = width == .wide || (width == .intermediate && !dynamicTypeSize.isAccessibilitySize)
            Group {
                if !split {
                    ScrollView {
                        listContent(split: false)
                            .padding(Spacing.m)
                            .readableWidth()
                    }
                } else {
                    HStack(spacing: 0) {
                        ScrollView {
                            listContent(split: true)
                                .padding(Spacing.m)
                        }
                        .frame(width: width == .wide ? 380 : 320)
                        Divider()
                            .ignoresSafeArea(edges: .bottom)
                        detailPane
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .onChange(of: split, initial: true) { _, newValue in
                isSplit = newValue
            }
        }
        .themedScreenBackground()
        .navigationTitle("Suitcases")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    app.suitcasesUI.isCreatingSuitcase = true
                } label: {
                    Label("Add Suitcase", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .accessibilityHint("Create a named suitcase")
                .accessibilityIdentifier("addSuitcaseToolbarButton")
            }
        }
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        // Only the visible Suitcases screen presents it; another tab may hold a hidden copy.
        .sheet(isPresented: Binding(
            get: { isOnScreen && app.suitcasesUI.isCreatingSuitcase },
            set: { if !$0, isOnScreen { app.suitcasesUI.isCreatingSuitcase = false } }
        )) {
            SuitcasesNameSheet(mode: .create) { name in create(name) }
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .modifier(SuitcasesLifecycleModifier(state: $lifecycle) { deletedID in
            if app.suitcasesUI.selection == .suitcase(deletedID) { app.suitcasesUI.selection = nil }
        })
    }

    // MARK: List

    @ViewBuilder
    private func listContent(split: Bool) -> some View {
        let active = app.store.activeSuitcases()
        let archived = app.store.archivedSuitcases().sorted { $0.createdAt < $1.createdAt }
        let shared = app.store.suitcasesShared()

        VStack(alignment: .leading, spacing: Spacing.l) {
            fallbackBanner

            CollapsibleText("Pick one source at a time. Style Me and Closet use only that source, and Main Closet always includes everything.",
                            summary: "Pick one source at a time.", threshold: 1, font: .subheadline, topic: "sources")

            mainClosetRow(split: split)

            VStack(alignment: .leading, spacing: Spacing.s) {
                SectionHeader("Your suitcases", subtitle: active.isEmpty ? "None yet" : SuitcasesText.count(active.count, "active suitcase"))
                ForEach(active) { suitcase in
                    suitcaseRow(suitcase, split: split)
                }
                addSuitcaseCard
            }

            if !shared.isEmpty {
                sharedCard(shared)
            }

            if !archived.isEmpty {
                archivedSection(archived, split: split)
            }

            HStack(spacing: Spacing.xxs) {
                Label("Saved on this device", systemImage: "lock")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("how suitcases are saved", title: "Saved on this device",
                           text: "Suitcase changes save on this device. No AI is used, and nothing is sent anywhere.")
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private var fallbackBanner: some View {
        if let reason = app.store.scopeFallback {
            InlineBanner(style: .caution, title: "Browsing Main Closet for now", message: reason.explanation,
                         actionTitle: "Use Main Closet") {
                app.suitcasesUseAsSource(.mainCloset)
            }
            .accessibilityIdentifier("suitcasesFallbackBanner")
        } else if app.store.awaitingSourceChoice {
            InlineBanner(style: .caution, title: "Choose a source before styling",
                         message: "You're browsing Main Closet. Pick Main Closet or a suitcase deliberately before Style Me uses it.",
                         actionTitle: "Use Main Closet", action: { app.suitcasesUseAsSource(.mainCloset) },
                         summary: "You're browsing Main Closet for now.")
        }
    }

    @ViewBuilder
    private func mainClosetRow(split: Bool) -> some View {
        let counts = app.store.suitcasesMainClosetCounts
        let selected = split && effectiveSelection == .mainCloset
        let summary = HStack(alignment: .top, spacing: Spacing.s) {
            SuitcasesIconWell(systemImage: "cabinet.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text("Main Closet")
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                Text("\(SuitcasesText.count(counts.all, "item")) · \(counts.current) currently owned")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Text("Includes everything across suitcases")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }

        VStack(alignment: .leading, spacing: Spacing.s) {
            if split {
                Button {
                    select(.mainCloset)
                } label: {
                    summary.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
                .accessibilityLabel("Main Closet, \(SuitcasesText.count(counts.all, "item")), \(counts.current) currently owned. Includes everything across suitcases.")
                .accessibilityHint("Shows Main Closet beside the list")
                .accessibilityAddTraits(selected ? .isSelected : [])
            } else {
                summary
                    .accessibilityElement(children: .combine)
            }
            SuitcasesSourceControl(scope: .mainCloset)
        }
        .cardStyle(highlighted: selected)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mainClosetRow")
    }

    private func suitcaseRow(_ suitcase: Suitcase, split: Bool) -> some View {
        let members = app.store.suitcasesMembers(of: suitcase.id)
        let dirty = app.store.dirtyGarments(scope: .suitcase(suitcase.id)).count
        let selected = split && effectiveSelection == .suitcase(suitcase.id)
        let isCurrent = app.suitcasesIsCurrentSource(.suitcase(suitcase.id))
        var summary = SuitcasesText.count(members.count, "garment")
        if dirty > 0 { summary += " · \(dirty) dirty" }

        return VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                open(suitcase, split: split)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(alignment: .top, spacing: Spacing.s) {
                        SuitcasesIconWell(systemImage: "suitcase.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suitcase.name)
                                .font(.headline)
                                .foregroundStyle(Palette.primaryText)
                                .multilineTextAlignment(.leading)
                            Text(summary)
                                .font(.subheadline)
                                .foregroundStyle(Palette.secondaryText)
                        }
                        Spacer(minLength: 0)
                        if !split {
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Palette.secondaryText)
                                .padding(.top, Spacing.xxs)
                        }
                    }
                    if members.isEmpty {
                        Text("Empty for now. Add garments from Main Closet.")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        SuitcasesThumbnailStrip(garments: members, limit: split ? 4 : 5)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel("\(suitcase.name), \(summary)\(isCurrent ? ", current source" : "")")
            .accessibilityHint(split ? "Shows the suitcase beside the list" : "Opens the suitcase")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("suitcaseRow-\(suitcase.id)")

            HStack(alignment: .center, spacing: Spacing.s) {
                SuitcasesSourceControl(scope: .suitcase(suitcase.id))
                Spacer(minLength: 0)
                SuitcasesMoreMenu(suitcase: suitcase, lifecycle: $lifecycle)
            }
        }
        .cardStyle(highlighted: selected)
    }

    private var addSuitcaseCard: some View {
        Button {
            app.suitcasesUI.isCreatingSuitcase = true
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("+ Add Suitcase")
                        .font(.headline)
                    Text("Name it, then add garments from Main Closet.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.primaryAction)
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.surface.opacity(0.6)))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.controlBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel("Add Suitcase")
        .accessibilityHint("Name it, then add garments from Main Closet")
        .accessibilityIdentifier("addSuitcaseButton")
    }

    private func sharedCard(_ shared: [SuitcasesSharedGarment]) -> some View {
        let ui = app.suitcasesUI
        return DetailsDisclosure("Shared garments", count: shared.count, systemImage: "link",
                                 isExpanded: Binding(get: { ui.showsShared }, set: { ui.showsShared = $0 }),
                                 identifier: "sharedGarmentsToggle") {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("One garment, linked to more than one suitcase. It's never duplicated, so its status is the same everywhere.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(shared) { item in
                    HStack(alignment: .top, spacing: Spacing.s) {
                        GarmentThumbnail(garment: item.garment, size: 48, showsStatus: false)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(item.garment.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                            // Status first so it is never scrolled out of sight; suitcase names follow.
                            ChipCarousel(spacing: Spacing.xxs, itemsLabel: "badges", toggleSize: 24) {
                                ForEach(Array(BadgeKind.status(for: item.garment).enumerated()), id: \.offset) { _, badge in
                                    StatusBadge(kind: badge, compact: true)
                                }
                                ForEach(item.suitcases) { suitcase in
                                    StatusBadge(kind: .custom(suitcase.name, "suitcase"), compact: true)
                                }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(item.garment.displayName) is in \(SuitcasesText.list(item.suitcases.map(\.name)))")
                            .accessibilityValue(BadgeKind.status(for: item.garment).map(\.text).joined(separator: ", "))
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sharedGarmentsNote")
    }

    private func archivedSection(_ archived: [Suitcase], split: Bool) -> some View {
        let ui = app.suitcasesUI
        return DetailsDisclosure("Archived", count: archived.count, systemImage: "archivebox",
                                 isExpanded: Binding(get: { ui.showsArchived }, set: { ui.showsArchived = $0 }),
                                 identifier: "archivedSuitcasesToggle") {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Hidden from source choices. Their links are kept.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(archived) { suitcase in
                    archivedRow(suitcase, split: split)
                }
            }
        }
    }

    private func archivedRow(_ suitcase: Suitcase, split: Bool) -> some View {
        let count = app.store.memberIDs(of: suitcase.id).count
        let selected = split && effectiveSelection == .suitcase(suitcase.id)
        return VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                open(suitcase, split: split)
            } label: {
                HStack(alignment: .top, spacing: Spacing.s) {
                    SuitcasesIconWell(systemImage: "archivebox")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suitcase.name)
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                            .multilineTextAlignment(.leading)
                        Text("\(SuitcasesText.count(count, "garment link")) kept")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    Spacer(minLength: 0)
                    if !split {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel("\(suitcase.name), archived, \(SuitcasesText.count(count, "garment link")) kept")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier("suitcaseRow-\(suitcase.id)")

            // Delete is destructive, so it sits in the More menu. It still asks first.
            ActionGroup(moreIdentifier: "archivedSuitcaseMore-\(suitcase.id)") {
                Button {
                    unarchive(suitcase)
                } label: {
                    Label("Unarchive", systemImage: "tray.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Unarchive \(suitcase.name)")
                .accessibilityIdentifier("unarchiveSuitcaseButton")
            } more: {
                Button("Delete suitcase…", systemImage: "trash", role: .destructive) {
                    lifecycle.delete = suitcase
                }
                .accessibilityLabel("Delete \(suitcase.name)")
                .accessibilityHint("Asks first. Garments, saved looks and pictures stay.")
                .accessibilityIdentifier("deleteSuitcaseButton")
            }
        }
        .cardStyle(highlighted: selected)
    }

    // MARK: Detail pane (two-pane layouts)

    @ViewBuilder
    private var detailPane: some View {
        switch effectiveSelection {
        case .mainCloset:
            SuitcasesMainClosetPane()
        case let .suitcase(id):
            SuitcaseDetailView(suitcaseID: id, embedded: true)
                .id(id)
        }
    }

    private var effectiveSelection: SuitcasesSelection {
        if let selection = app.suitcasesUI.selection {
            switch selection {
            case .mainCloset: return .mainCloset
            case let .suitcase(id): if app.store.suitcase(id) != nil { return selection }
            }
        }
        if let id = app.workingScope.suitcaseID, app.store.suitcase(id) != nil { return .suitcase(id) }
        return .mainCloset
    }

    // MARK: Actions

    private func select(_ selection: SuitcasesSelection) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            app.suitcasesUI.selection = selection
        }
    }

    private func open(_ suitcase: Suitcase, split: Bool) {
        if split {
            select(.suitcase(suitcase.id))
        } else {
            app.suitcasesUI.selection = .suitcase(suitcase.id)
            app.suitcasesPush(.suitcase(suitcase.id))
        }
    }

    private func create(_ name: String) {
        let suitcase = app.store.createSuitcase(named: name)
        app.suitcasesUI.selection = .suitcase(suitcase.id)
        if !isSplit { app.suitcasesPush(.suitcase(suitcase.id)) }
        app.showToast("Created \(suitcase.name). Add garments from Main Closet when you're ready. Your source didn't change.")
    }

    private func unarchive(_ suitcase: Suitcase) {
        app.store.archiveSuitcase(suitcase.id, archived: false)
        app.showToast("\(suitcase.name) is back in your source choices. Your current source didn't change.", style: .info)
    }
}

#Preview("Suitcases") {
    NavigationStack {
        SuitcasesScreen()
    }
    .previewEnvironment()
}

#Preview("Suitcases · iPad width") {
    NavigationStack {
        SuitcasesScreen()
    }
    .frame(width: 1024, height: 760)
    .previewEnvironment()
}
