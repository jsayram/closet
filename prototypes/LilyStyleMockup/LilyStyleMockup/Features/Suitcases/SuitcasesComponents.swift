import SwiftUI

// MARK: - Selection, text and sorting helpers

/// What the two-pane Suitcases layout shows beside the list.
enum SuitcasesSelection: Hashable {
    case mainCloset
    case suitcase(String)
}

enum SuitcasesText {
    static func count(_ n: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(n) \(n == 1 ? singular : (plural ?? singular + "s"))"
    }

    static func list(_ names: [String]) -> String {
        ListFormatter.localizedString(byJoining: names)
    }

    static let organizationNote = "Suitcases organize clothes you already have. Nothing is copied or moved, and Main Closet still shows everything."

    static let membershipNote = "Membership is organization only. It doesn't copy or move garments, or confirm anything is packed. Status like Dirty is shared, so it looks the same here and in Main Closet."
}

enum SuitcasesSort {
    static func rank(_ category: GarmentCategory) -> Int {
        GarmentCategory.allCases.firstIndex(of: category) ?? GarmentCategory.allCases.count
    }

    static func byCategoryThenName(_ a: Garment, _ b: Garment) -> Bool {
        if rank(a.category) != rank(b.category) { return rank(a.category) < rank(b.category) }
        return a.displayName.localizedCaseInsensitiveCompare(b.displayName) == .orderedAscending
    }
}

/// Offline matcher for the Add from Main Closet search field. Every word must match
/// a personal name, other name, detail, color, kind, category, brand, fabric or note.
enum SuitcasesSearch {
    static func matches(_ garment: Garment, query: String) -> Bool {
        let tokens = query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
        guard !tokens.isEmpty else { return true }
        var haystack: [String] = [garment.displayName, garment.kind.label, garment.category.label, garment.category.pluralLabel, garment.notes]
        haystack += garment.annotations.map(\.text)
        if let color = garment.color { haystack += [color.name, color.family.label] }
        if let brand = garment.brand { haystack.append(brand) }
        if let fabric = garment.fabric { haystack.append(fabric) }
        let text = haystack.joined(separator: " ").lowercased()
        return tokens.allSatisfy { text.contains($0) }
    }
}

struct SuitcasesSharedGarment: Identifiable {
    var garment: Garment
    var suitcases: [Suitcase]
    var id: String { garment.id }
}

/// Result of an Add from Main Closet confirmation, kept until dismissed.
struct SuitcasesAddOutcome: Identifiable, Equatable {
    let id = UUID()
    var suitcaseID: String
    var suitcaseName: String
    var addedCount: Int
    var alreadyPresentCount: Int
    var skippedCount: Int
    var containerArchived: Bool
    var at: Date = .now

    var title: String {
        if containerArchived { return "Nothing added" }
        if addedCount > 0 { return "Added \(SuitcasesText.count(addedCount, "garment")) to \(suitcaseName)" }
        return "Nothing new added"
    }

    var detail: String {
        if containerArchived { return "\(suitcaseName) is archived, so no links were added." }
        var parts: [String] = []
        if alreadyPresentCount > 0 { parts.append("\(alreadyPresentCount) already there") }
        if skippedCount > 0 { parts.append("\(skippedCount) skipped (in Trash or no longer in your closet)") }
        let lead = parts.isEmpty ? "" : parts.joined(separator: " · ") + ". "
        return lead + "Your styling source didn't change."
    }

    var toastText: String { "\(title). \(detail)" }
}

// MARK: - Read-only store queries

extension DemoStore {
    /// Canonical member garments of a suitcase, sorted by category then name.
    func suitcasesMembers(of suitcaseID: String) -> [Garment] {
        let ids = memberIDs(of: suitcaseID)
        return garments.filter { ids.contains($0.id) }.sorted(by: SuitcasesSort.byCategoryThenName)
    }

    /// Other active suitcases that link the same garment.
    func suitcasesOtherActive(containing garmentID: String, excluding suitcaseID: String?) -> [Suitcase] {
        suitcases(containing: garmentID)
            .filter { !$0.isArchived && $0.id != suitcaseID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Garments linked to two or more active suitcases (one record, several links).
    func suitcasesShared() -> [SuitcasesSharedGarment] {
        garments.compactMap { garment -> SuitcasesSharedGarment? in
            let linked = suitcases(containing: garment.id).filter { !$0.isArchived }.sorted { $0.createdAt < $1.createdAt }
            return linked.count >= 2 ? SuitcasesSharedGarment(garment: garment, suitcases: linked) : nil
        }
        .sorted { SuitcasesSort.byCategoryThenName($0.garment, $1.garment) }
    }

    /// Main Closet totals: every non-Trash record, and the currently owned subset.
    var suitcasesMainClosetCounts: (all: Int, current: Int) {
        let visible = garments.filter { !$0.isTrashed }
        return (visible.count, visible.filter(\.isCurrentlyOwned).count)
    }
}

// MARK: - App helpers

extension AppModel {
    /// Pushes onto whichever stack hosts the Suitcases and Laundry screens: the
    /// compact secondary sheet when one is open, otherwise the current section.
    func suitcasesPush(_ route: AppRoute) {
        if case let .secondary(section)? = sheet {
            var path = paths[section] ?? NavigationPath()
            path.append(route)
            paths[section] = path
        } else {
            push(route)
        }
    }

    /// True when this is the deliberate, remembered source (not a fallback awaiting a choice).
    func suitcasesIsCurrentSource(_ scope: WardrobeScope) -> Bool {
        !store.awaitingSourceChoice && workingScope == scope
    }

    /// Deliberate source choice from the Suitcases screens. Local and free; starts nothing.
    func suitcasesUseAsSource(_ scope: WardrobeScope) {
        selectScope(scope)
        let name = store.scopeName(scope)
        if scope.isSuitcase {
            showToast("\(name) is now your source. Style Me and Closet use only its garments. Remembered next time you open the app.")
        } else {
            showToast("Main Closet is now your source. Remembered next time you open the app.")
        }
    }
}

// MARK: - Small views

/// Accent capsule for source state ("Current source", "Browsing for now").
struct SuitcasesTag: View {
    var text: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Palette.primaryAction)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(Capsule().fill(Palette.accentSurface))
        .overlay(Capsule().strokeBorder(Palette.primaryAction.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// Round icon well used at the leading edge of list rows.
struct SuitcasesIconWell: View {
    var systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3)
            .foregroundStyle(Palette.primaryAction)
            .frame(width: HitTarget.minimum, height: HitTarget.minimum)
            .background(Circle().fill(Palette.accentSurface))
            .accessibilityHidden(true)
    }
}

/// A short strip of member thumbnails with a "+N" overflow tile.
struct SuitcasesThumbnailStrip: View {
    var garments: [Garment]
    var limit = 5
    var size: CGFloat = 40

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(garments.prefix(limit)) { garment in
                GarmentThumbnail(garment: garment, size: size, showsStatus: false)
            }
            if garments.count > limit {
                Text("+\(garments.count - limit)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.horizontal, Spacing.xxs)
                    .frame(minWidth: size, minHeight: size)
                    .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.imageWell))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Source state for Main Closet or a suitcase: a "Current source" tag with what that
/// means behind an info button, or a deliberate "Use as source" button. Choosing is
/// remembered across launches.
struct SuitcasesSourceControl: View {
    @Environment(AppModel.self) private var app
    var scope: WardrobeScope

    var body: some View {
        let name = app.store.scopeName(scope)
        if app.suitcasesIsCurrentSource(scope) {
            HStack(spacing: Spacing.xxs) {
                SuitcasesTag(text: "Current source", systemImage: "checkmark.circle.fill")
                InfoButton("your current source", title: "Current source",
                           text: scope.isSuitcase
                               ? "Style Me and Closet use only these garments. Remembered next time you open the app."
                               : "Style Me and Closet use all your clothes. Remembered next time you open the app.")
            }
        } else if scope == .mainCloset, app.store.awaitingSourceChoice {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SuitcasesTag(text: "Browsing for now", systemImage: "exclamationmark.circle")
                Button {
                    app.suitcasesUseAsSource(.mainCloset)
                } label: {
                    Label("Use Main Closet", systemImage: "checkmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Makes Main Closet your deliberate source for styling")
                .accessibilityIdentifier("useAsSourceButton")
            }
        } else {
            Button {
                app.suitcasesUseAsSource(scope)
            } label: {
                Label("Use as source", systemImage: "checkmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Use \(name) as source")
            .accessibilityHint(scope.isSuitcase ? "Style Me and Closet will use only its garments. Remembered across launches." : "Style Me and Closet will use all your clothes. Remembered across launches.")
            .accessibilityIdentifier("useAsSourceButton")
        }
    }
}

/// Outlined label that matches SecondaryButtonStyle, for Menu labels.
struct SuitcasesOutlinedLabel: ViewModifier {
    var minHeight: CGFloat = HitTarget.minimum

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryAction)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: minHeight)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            .hoverEffect(.highlight)
    }
}

/// Applies a navigation title only when the view is shown on its own (not embedded).
struct SuitcasesTitleModifier: ViewModifier {
    var title: String
    var enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
        }
    }
}

// MARK: - More actions menu

/// Rename / Archive / Delete targets owned by the presenting view.
struct SuitcasesLifecycleState {
    var rename: Suitcase?
    var archive: Suitcase?
    var delete: Suitcase?
}

struct SuitcasesMoreMenu: View {
    var suitcase: Suitcase
    @Binding var lifecycle: SuitcasesLifecycleState
    var onUnarchive: (() -> Void)?

    var body: some View {
        Menu {
            Button {
                lifecycle.rename = suitcase
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .accessibilityIdentifier("renameSuitcaseButton")
            if suitcase.isArchived {
                if let onUnarchive {
                    Button(action: onUnarchive) {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                    .accessibilityIdentifier("unarchiveSuitcaseButton")
                }
            } else {
                Button {
                    lifecycle.archive = suitcase
                } label: {
                    Label("Archive…", systemImage: "archivebox")
                }
                .accessibilityIdentifier("archiveSuitcaseButton")
            }
            Divider()
            Button(role: .destructive) {
                lifecycle.delete = suitcase
            } label: {
                Label("Delete suitcase…", systemImage: "trash")
            }
            .accessibilityIdentifier("deleteSuitcaseButton")
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(Palette.primaryAction)
                .minimumHitTarget()
        }
        .hoverEffect(.highlight)
        .accessibilityLabel("More actions for \(suitcase.name)")
        .accessibilityHint("Rename, archive or delete")
        .accessibilityIdentifier("suitcaseMoreMenu-\(suitcase.id)")
    }
}

// MARK: - Rename, archive and delete

/// Hosts the rename sheet and the archive/delete confirmations for a view.
struct SuitcasesLifecycleModifier: ViewModifier {
    @Environment(AppModel.self) private var app
    @Binding var state: SuitcasesLifecycleState
    var onDeleted: (String) -> Void = { _ in }

    func body(content: Content) -> some View {
        content
            .sheet(item: $state.rename) { suitcase in
                SuitcasesNameSheet(mode: .rename(id: suitcase.id, current: suitcase.name)) { newName in
                    app.store.renameSuitcase(suitcase.id, to: newName)
                    app.showToast("Renamed to “\(newName)”. Its garments and links didn't change.")
                }
                .environment(app)
                .tint(Palette.primaryAction)
            }
            .alert(
                confirmationTitle,
                isPresented: Binding(
                    get: { confirmation != nil },
                    set: { if !$0 { state.archive = nil; state.delete = nil } }
                ),
                presenting: confirmation
            ) { pending in
                switch pending {
                case let .archive(suitcase):
                    Button("Archive") { archive(suitcase) }
                case let .delete(suitcase):
                    Button("Delete suitcase", role: .destructive) { delete(suitcase) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { pending in
                switch pending {
                case let .archive(suitcase): Text(archiveMessage(suitcase))
                case let .delete(suitcase): Text(deleteMessage(suitcase))
                }
            }
    }

    /// One confirmation at a time (delete wins if both were somehow requested).
    private enum Confirmation {
        case archive(Suitcase)
        case delete(Suitcase)
    }

    private var confirmation: Confirmation? {
        if let suitcase = state.delete { return .delete(suitcase) }
        if let suitcase = state.archive { return .archive(suitcase) }
        return nil
    }

    private var confirmationTitle: String {
        switch confirmation {
        case let .archive(suitcase)?: "Archive \(suitcase.name)?"
        case let .delete(suitcase)?: "Delete \(suitcase.name)?"
        case nil: "Suitcase"
        }
    }

    private func isCurrent(_ suitcase: Suitcase) -> Bool {
        app.store.rememberedScope == .suitcase(suitcase.id)
    }

    private func archiveMessage(_ suitcase: Suitcase) -> String {
        let links = SuitcasesText.count(app.store.memberIDs(of: suitcase.id).count, "garment link")
        var text = "Its \(links) stay, and it's hidden from source choices until you unarchive it. Garments aren't archived, cleaned or changed."
        if isCurrent(suitcase) {
            text += "\n\nIt's your current source, so you'll browse Main Closet and choose a source before styling."
        }
        return text
    }

    private func deleteMessage(_ suitcase: Suitcase) -> String {
        let count = app.store.memberIDs(of: suitcase.id).count
        var text = "Deletes the suitcase and its links only — garments, saved looks and pictures stay."
        if count > 0 {
            text += "\n\n\(SuitcasesText.count(count, "garment link")) will be removed. Looks made from it will be labeled “Former suitcase”."
        }
        if isCurrent(suitcase) {
            text += "\n\nIt's your current source, so you'll browse Main Closet and choose a source before styling."
        }
        return text
    }

    private func archive(_ suitcase: Suitcase) {
        let id = suitcase.id
        let name = suitcase.name
        app.store.archiveSuitcase(id)
        app.showToast("Archived \(name). Its links are kept.", style: .success, actionTitle: "Unarchive") { [app] in
            app.store.archiveSuitcase(id, archived: false)
            app.showToast("\(name) is back in your source choices. Your current source didn't change.", style: .info)
        }
    }

    private func delete(_ suitcase: Suitcase) {
        app.store.deleteSuitcase(suitcase.id)
        if app.suitcasesUI.lastAddOutcome?.suitcaseID == suitcase.id { app.suitcasesUI.lastAddOutcome = nil }
        if app.suitcasesUI.pickerSuitcaseID == suitcase.id { app.suitcasesUI.pickerSuitcaseID = nil }
        onDeleted(suitcase.id)
        app.showToast("Deleted \(suitcase.name). Every garment is still in Main Closet.")
    }
}

// MARK: - Name sheet (create and rename)

struct SuitcasesNameSheet: View {
    enum Mode: Equatable {
        case create
        case rename(id: String, current: String)
    }

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    var mode: Mode
    var onSave: (String) -> Void

    /// Rename text. Create mode keeps its text in `suitcasesUI` so it survives a resize or shell switch.
    @State private var renameDraft: String
    @FocusState private var fieldFocused: Bool

    private static let suggestions = ["Work trip", "Beach weekend", "Gym bag", "Holiday visit"]

    init(mode: Mode, onSave: @escaping (String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        if case let .rename(_, current) = mode {
            _renameDraft = State(initialValue: current)
        } else {
            _renameDraft = State(initialValue: "")
        }
    }

    private var nameBinding: Binding<String> {
        guard mode == .create else { return $renameDraft }
        let ui = app.suitcasesUI
        return Binding(get: { ui.createDraftName }, set: { ui.createDraftName = $0 })
    }

    private var name: String { nameBinding.wrappedValue }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var editingID: String? {
        if case let .rename(id, _) = mode { return id }
        return nil
    }

    private var duplicate: Suitcase? {
        guard !trimmed.isEmpty else { return nil }
        return app.store.suitcases.first {
            $0.id != editingID && $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private var isUnchanged: Bool {
        if case let .rename(_, current) = mode { return trimmed == current }
        return false
    }

    private var isTooLong: Bool { trimmed.count > 40 }

    private var canSave: Bool { !trimmed.isEmpty && duplicate == nil && !isUnchanged && !isTooLong }

    private var availableSuggestions: [String] {
        Self.suggestions.filter { idea in
            !app.store.suitcases.contains { $0.name.compare(idea, options: .caseInsensitive) == .orderedSame }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Suitcase name", text: nameBinding)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($fieldFocused)
                        .onSubmit(save)
                        .accessibilityIdentifier("suitcaseNameField")
                } header: {
                    FormSectionHeader("Name")
                } footer: {
                    if let duplicate {
                        Text("You already have a suitcase called “\(duplicate.name)”\(duplicate.isArchived ? " (archived)" : ""). Try another name.")
                            .foregroundStyle(Palette.error)
                    } else if isTooLong {
                        Text("Keep it to 40 characters or fewer.")
                            .foregroundStyle(Palette.error)
                    } else {
                        Text(SuitcasesText.organizationNote)
                    }
                }
                .listRowBackground(Palette.surface)

                if mode == .create, !availableSuggestions.isEmpty {
                    Section {
                        ChipCarousel(itemsLabel: "name ideas") {
                            ForEach(availableSuggestions, id: \.self) { idea in
                                CapsuleChip(title: idea, isSelected: trimmed == idea) {
                                    nameBinding.wrappedValue = idea
                                }
                            }
                        }
                        .padding(.vertical, Spacing.xxs)
                    } header: {
                        FormSectionHeader("Ideas")
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle(mode == .create ? "New suitcase" : "Rename suitcase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if mode == .create { app.suitcasesUI.createDraftName = "" }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode == .create ? "Create" : "Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("suitcaseNameSave")
                }
            }
            .onAppear { fieldFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard canSave else { return }
        onSave(trimmed)
        if mode == .create { app.suitcasesUI.createDraftName = "" }
        dismiss()
    }
}

// MARK: - Main Closet pane (two-pane layouts)

struct SuitcasesMainClosetPane: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let counts = app.store.suitcasesMainClosetCounts
        let dirty = app.store.dirtyGarments(scope: .mainCloset).count
        let current = app.store.garments.filter(\.isCurrentlyOwned)
        let categories = GarmentCategory.allCases.filter { category in current.contains { $0.category == category } }

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Main Closet")
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(SuitcasesText.count(counts.all, "item")) · \(counts.current) currently owned\(dirty > 0 ? " · \(dirty) dirty" : "")")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    CollapsibleText("Every garment appears here once, including everything linked to suitcases. Putting something in a suitcase never hides it from Main Closet.",
                                    summary: "Every garment appears here once.", threshold: 1, font: .body, color: Palette.primaryText, topic: "Main Closet")
                    FlowLayout(spacing: Spacing.xs) {
                        SuitcasesSourceControl(scope: .mainCloset)
                        Button {
                            app.laundryUI.focusEntireCloset()
                            app.suitcasesPush(.laundry)
                        } label: {
                            Label(dirty > 0 ? "Laundry · \(dirty) dirty" : "Laundry", systemImage: "washer")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityHint("Opens laundry for the entire closet")
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader("Currently owned, by category")
                    ForEach(categories) { category in
                        let items = current.filter { $0.category == category }.sorted(by: SuitcasesSort.byCategoryThenName)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: Spacing.s) {
                                Label(category.pluralLabel, systemImage: category.systemImage)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.primaryText)
                                Spacer(minLength: Spacing.xs)
                                SuitcasesThumbnailStrip(garments: items, limit: 4, size: 40)
                                Text("\(items.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(Palette.secondaryText)
                                    .frame(minWidth: 24, alignment: .trailing)
                            }
                            HStack {
                                Label(category.pluralLabel, systemImage: category.systemImage)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.primaryText)
                                Spacer(minLength: Spacing.xs)
                                Text("\(items.count)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(Palette.secondaryText)
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(category.pluralLabel): \(items.count)")
                        if category != categories.last { Divider() }
                    }
                }
                .cardStyle()

                CollapsibleText("Wishlist, not-arrived, no-longer-owned and Trash items stay in their own Closet views. Suitcases never hide or change them.",
                                summary: "Other Closet views aren't changed.", threshold: 1, topic: "other Closet views")
            }
            .padding(Spacing.m)
            .readableWidth(760)
        }
    }
}
