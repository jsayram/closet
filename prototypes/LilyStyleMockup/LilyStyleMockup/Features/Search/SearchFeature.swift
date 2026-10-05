import SwiftUI

/// Search UI state owned by `AppModel` so the query, scope, filters and selection
/// survive rotation, resizing and navigation. In memory only: queries are never
/// persisted, logged or kept as history.
@Observable
final class SearchUIState {
    /// Prefilled query from a launch argument or another screen. Consumed once when Search appears.
    var prefillQuery: String?
    var query: String = ""
    var scope: SearchScopeHint = .everything
    /// The last `initialScope` applied, so returning from a pushed item or resizing
    /// keeps the scope Lily chose instead of resetting it.
    var lastAppliedInitialScope: SearchScopeHint?
    /// Scope and type filters Lily left at each entry point (Closet, Saved, the sidebar), so
    /// moving between Search screens in different tabs brings back her own choice.
    var scopeByEntry: [SearchScopeHint: SearchScopeHint] = [:]
    var typesByEntry: [SearchScopeHint: Set<SearchResultType>] = [:]
    /// Top-most visible result row for each entry point.
    var scrollAnchors: [SearchScopeHint: String] = [:]
    var filters = SearchFilters()
    var visibleLimit = SearchUIState.pageSize
    var showRelatedShades = false
    var selectedResultID: String?
    /// Compact layouts show the selected result in a sheet; wide layouts use a side pane.
    var isQuickLookPresented = false
    /// The entry point whose Search screen opened quick look (Closet and Saved tabs can
    /// each hold a Search screen; only the visible one Lily tapped presents the sheet,
    /// and a rebuilt copy of it after a resize or shell switch picks the sheet back up).
    var quickLookOwner: SearchScopeHint?
    /// Editable Remember this name text for the selected garment and current query.
    var rememberDraft: SearchRememberDraft?
    /// Session-only hashes of (item, phrase) prompts already answered. Never persisted.
    var answeredRememberKeys: Set<Int> = []
    /// Inline confirmation for the selected result (visible even inside the compact sheet).
    var paneNotice: SearchPaneNotice?
    /// Disclosures Lily switched from their default (chip rows, tips, details rows), so
    /// they stay that way through rotation and layout switches.
    var toggledDisclosures: Set<String> = []

    static let pageSize = 30

    init() {}

    /// Open state for one named disclosure. Closed until she opens it, unless `startsOpen`.
    func disclosure(_ key: String, startsOpen: Bool = false) -> Binding<Bool> {
        Binding(
            get: { self.toggledDisclosures.contains(key) != startsOpen },
            set: { isOpen in
                if isOpen != startsOpen { self.toggledDisclosures.insert(key) } else { self.toggledDisclosures.remove(key) }
            }
        )
    }
}

struct SearchRememberDraft: Hashable {
    var garmentID: String
    var queryKey: String
    var text: String
}

struct SearchPaneNotice: Hashable {
    enum Kind: Hashable {
        case remembered(phrase: String)
        case rememberUndone(phrase: String)
        case declined
        /// `undoEntryID` is the store's revision-checked undo entry pushed by `markClean`.
        case cleaned(undoEntryID: UUID?)
        /// Result of Undo on Mark clean, as reported by the store (or why it was skipped).
        case cleanUndo(message: String)
    }

    var resultID: String
    var kind: Kind
}

/// Unified local search across garments, saved looks, retained previews and saved
/// products. Querying is deterministic and local: it never dispatches a service.
struct SearchScreen: View {
    var initialScope: SearchScopeHint

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var fieldFocused: Bool
    @State private var didFocusOnce = false
    @State private var isOnScreen = false

    static let examples = [
        "cute pink shirt",
        "lacy white shirt with ruffles",
        "baggy jeans with the pocket",
        "blue pants interview",
        "olive trousers brick top",
        "\"date night favorite\"",
    ]

    var body: some View {
        let ui = app.searchUI
        let documents = SearchIndexBuilder.documents(from: SearchIndexInput(store: app.store, workingScope: app.workingScope))
        let output = SearchEngine.run(ui.query, filters: ui.filters, scope: ui.scope, documents: documents)

        GeometryReader { geo in
            let widthClass = WidthClass(width: geo.size.width)
            // Accessibility text sizes need more room before two columns stay readable.
            let sideBySide = geo.size.width >= (dynamicTypeSize.isAccessibilitySize ? Self.sideBySideMinWidthAccessibility : Self.sideBySideMinWidth)
            Group {
                if !sideBySide {
                    resultsColumn(output: output, documents: documents, widthClass: widthClass, sideBySide: false)
                } else {
                    HStack(spacing: 0) {
                        resultsColumn(output: output, documents: documents, widthClass: widthClass, sideBySide: true)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(Palette.divider)
                            .frame(width: 1)
                            .ignoresSafeArea(edges: .bottom)
                            .accessibilityHidden(true)
                        selectionPane(output: output, documents: documents)
                            .frame(width: paneWidth(for: geo.size.width, widthClass: widthClass))
                    }
                }
            }
            // The side pane shows the selection, so a quick look left open from a narrower
            // layout closes instead of coming back later or blocking the field's autofocus.
            .onChange(of: sideBySide, initial: true) { _, isSideBySide in
                if isSideBySide { app.searchUI.isQuickLookPresented = false }
            }
            .sheet(isPresented: quickLookBinding(compact: !sideBySide)) {
                NavigationStack {
                    selectionPane(output: output, documents: documents)
                        .themedScreenBackground()
                        .navigationTitle(selectedTitle(documents))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { app.searchUI.isQuickLookPresented = false }
                                    .keyboardShortcut(.cancelAction)
                            }
                        }
                }
                .environment(app)
                .tint(Palette.primaryAction)
                .presentationDetents(quickLookNeedsFullHeight(output: output, documents: documents) ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .themedScreenBackground()
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: handleAppear)
        .onDisappear { isOnScreen = false }
        .onChange(of: ui.prefillQuery) { _, _ in consumePrefill() }
        .onChange(of: ui.query) { _, _ in
            ui.visibleLimit = SearchUIState.pageSize
            ui.showRelatedShades = false
            ui.paneNotice = nil
            ui.scrollAnchors = [:]
        }
        .onChange(of: ui.filters) { _, _ in ui.visibleLimit = SearchUIState.pageSize }
        .onChange(of: ui.scope) { _, newScope in
            ui.filters.types.formIntersection(newScope.searchResultTypes)
            ui.visibleLimit = SearchUIState.pageSize
        }
    }

    // MARK: Layout

    /// Below this width the selected result opens in a sheet so the results column stays readable.
    static let sideBySideMinWidth: CGFloat = 720
    static let sideBySideMinWidthAccessibility: CGFloat = 980

    private func paneWidth(for width: CGFloat, widthClass: WidthClass) -> CGFloat {
        switch widthClass {
        case .compact, .intermediate: min(400, max(320, width * 0.42))
        case .wide: min(480, max(360, width * 0.38))
        }
    }

    /// True while this screen's compact quick-look sheet is up (the pane shows the prompt there).
    private var isQuickLookShowing: Bool {
        isOnScreen && app.searchUI.isQuickLookPresented && app.searchUI.quickLookOwner == initialScope
            && app.searchUI.selectedResultID != nil
    }

    private func quickLookBinding(compact: Bool) -> Binding<Bool> {
        Binding(
            get: {
                compact && isQuickLookShowing
            },
            set: { if !$0, isOnScreen { app.searchUI.isQuickLookPresented = false } }
        )
    }

    /// The Remember this name prompt needs room, so that quick look opens full height.
    private func quickLookNeedsFullHeight(output: SearchOutput, documents: [SearchDocument]) -> Bool {
        let ui = app.searchUI
        guard let id = ui.selectedResultID,
              let doc = documents.first(where: { $0.id == id }), doc.type == .garment,
              let garment = app.store.garment(doc.sourceID) else { return false }
        return SearchRememberLogic.isOffered(ui: ui, query: output.query, hit: output.allHits.first { $0.id == id }, garment: garment)
    }

    private func selectedTitle(_ documents: [SearchDocument]) -> String {
        documents.first { $0.id == app.searchUI.selectedResultID }?.type.filterLabel ?? "Result"
    }

    private func resultsColumn(output: SearchOutput, documents: [SearchDocument], widthClass: WidthClass, sideBySide: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                scopeAndStatus(documents: documents)
                SearchFilterBar(
                    ui: app.searchUI,
                    output: output,
                    collections: app.store.collections
                )
                if !sideBySide, !isQuickLookShowing {
                    SearchPendingRememberCard(output: output, documents: documents)
                }
                SearchResultsContent(
                    output: output,
                    showsPane: sideBySide,
                    onSelect: { select($0, compact: !sideBySide) },
                    onOpen: { open($0.document) },
                    onRefine: refine,
                    onExample: { app.searchUI.query = $0 }
                )
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
            .padding(.top, Spacing.xs)
            .readableWidth(widthClass == .compact ? 720 : 900)
        }
        .rememberedScrollPosition(scrollAnchor, firstID: output.primary.first?.id ?? output.possible.first?.id)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) { searchField }
    }

    private var scrollAnchor: Binding<String?> {
        let ui = app.searchUI
        let entry = initialScope
        return Binding(get: { ui.scrollAnchors[entry] }, set: { ui.scrollAnchors[entry] = $0 })
    }

    // MARK: Search field, scope and status

    private var searchField: some View {
        @Bindable var ui = app.searchUI
        return HStack(spacing: Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            TextField("Search", text: $ui.query, prompt: Text("Describe it in your own words").foregroundStyle(Palette.secondaryText))
                .font(.body)
                .foregroundStyle(Palette.primaryText)
                .focused($fieldFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { fieldFocused = false }
                .onKeyPress(.escape) {
                    if !ui.query.isEmpty {
                        ui.query = ""
                    } else {
                        fieldFocused = false
                    }
                    return .handled
                }
                .accessibilityLabel("Search your closet, saved looks and previews")
                .accessibilityHint("Searches only the data on this device. Nothing is sent anywhere.")
                .accessibilityIdentifier("searchField")
            if !ui.query.isEmpty {
                Button {
                    ui.query = ""
                    fieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondaryText)
                        .minimumHitTarget()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search text")
            }
        }
        .padding(.leading, Spacing.s)
        .padding(.trailing, Spacing.xxs)
        .frame(minHeight: 48)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(fieldFocused ? Palette.primaryAction : Palette.controlBorder, lineWidth: fieldFocused ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { fieldFocused = true }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.xs)
        .background(Palette.background)
    }

    @ViewBuilder
    private func scopeAndStatus(documents: [SearchDocument]) -> some View {
        @Bindable var ui = app.searchUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    Picker("Search in", selection: $ui.scope) { scopeOptions }
                        .pickerStyle(.menu)
                } else {
                    Picker("Search in", selection: $ui.scope) { scopeOptions }
                        .pickerStyle(.segmented)
                }
            }
            .accessibilityIdentifier("searchScopePicker")
            .accessibilityHint("Closet searches garments in your selected source. Saved searches looks, previews and saved products.")

            if ui.scope != .saved {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s) {
                        Text("Garments from")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                        SourceSelector()
                        Spacer(minLength: 0)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Garments from")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                        SourceSelector()
                    }
                }
            }

            SearchStatusLine(documents: documents)
        }
    }

    @ViewBuilder private var scopeOptions: some View {
        ForEach([SearchScopeHint.closet, .saved, .everything], id: \.self) { scope in
            Text(scope.searchLabel).tag(scope)
        }
    }

    // MARK: Selection pane

    @ViewBuilder
    private func selectionPane(output: SearchOutput, documents: [SearchDocument]) -> some View {
        let selectedID = app.searchUI.selectedResultID
        let document = documents.first { $0.id == selectedID }
        let hit = output.allHits.first { $0.id == selectedID }
        if let document {
            ScrollView {
                SearchSelectionPane(
                    document: document,
                    hit: hit,
                    query: output.query,
                    onOpen: { open(document) }
                )
                .padding(Spacing.m)
                .padding(.bottom, Spacing.xl)
            }
            .background(Palette.background)
        } else {
            ScrollView {
                EmptyStateView(
                    title: "Select a result",
                    message: "Its details and actions appear here.",
                    systemImage: "sidebar.right",
                    detailsTitle: "What you'll see",
                    detailsExpanded: app.searchUI.disclosure("paneIntro")
                ) {
                    Text("Its details, why it matched and what you can do appear here. Selecting or opening a result never changes it.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, Spacing.xl)
            }
            .background(Palette.background)
        }
    }

    // MARK: Actions (local navigation only — nothing here dispatches a service)

    private func handleAppear() {
        let ui = app.searchUI
        isOnScreen = true
        if ui.lastAppliedInitialScope != initialScope {
            // Remember what Lily chose at the Search screen she is leaving, then bring back
            // her choice for this one (or start from its own scope the first time).
            if let previous = ui.lastAppliedInitialScope {
                ui.scopeByEntry[previous] = ui.scope
                ui.typesByEntry[previous] = ui.filters.types
            }
            ui.scope = ui.scopeByEntry[initialScope] ?? initialScope
            ui.filters.types = ui.typesByEntry[initialScope] ?? ui.filters.types.intersection(initialScope.searchResultTypes)
            ui.lastAppliedInitialScope = initialScope
        }
        consumePrefill()
        if !didFocusOnce {
            didFocusOnce = true
            if !ui.isQuickLookPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { fieldFocused = true }
            }
        }
    }

    private func consumePrefill() {
        let ui = app.searchUI
        guard let prefill = ui.prefillQuery else { return }
        ui.query = prefill
        ui.prefillQuery = nil
    }

    private func select(_ hit: SearchHit, compact: Bool) {
        fieldFocused = false
        let ui = app.searchUI
        if ui.selectedResultID != hit.id {
            ui.rememberDraft = nil
            ui.paneNotice = nil
        }
        ui.selectedResultID = hit.id
        if compact {
            ui.quickLookOwner = initialScope
            ui.isQuickLookPresented = true
        }
    }

    private func open(_ document: SearchDocument) {
        app.searchUI.isQuickLookPresented = false
        app.searchUI.selectedResultID = document.id
        fieldFocused = false
        let route: AppRoute = switch document.type {
        case .garment: .garment(document.sourceID)
        case .outfit: .outfit(document.sourceID)
        case .preview: .preview(document.sourceID)
        case .product: .savedProducts
        }
        app.push(route)
    }

    private func refine() {
        withAnimation(reduceMotion ? nil : .default) { app.searchUI.isQuickLookPresented = false }
        fieldFocused = true
    }
}

/// One quiet line: search is local, and the index is simulated. The full wording and the
/// index counts sit behind the info button.
private struct SearchStatusLine: View {
    var documents: [SearchDocument]

    private func count(_ type: SearchResultType) -> Int { documents.filter { $0.type == type }.count }

    private var indexText: String {
        "Index up to date · \(count(.garment)) garments, \(count(.outfit)) looks, \(count(.preview)) previews, \(count(.product)) products"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var deviceLabel: some View {
        Label {
            Text("On this device only")
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lock.shield")
                .foregroundStyle(Palette.success)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Palette.primaryText)
    }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // At accessibility text sizes the label and badge stack so the line wraps instead of truncating.
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        deviceLabel
                        StatusBadge(kind: .custom("Simulated index", "flask"), compact: true)
                    }
                } else {
                    HStack(spacing: Spacing.xs) {
                        deviceLabel
                        StatusBadge(kind: .custom("Simulated index", "flask"), compact: true)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Searching your local data — no AI, upload or account. \(indexText). Simulated index")
            .accessibilityIdentifier("searchStatusLine")

            InfoButton("how search works", title: "Search stays on this device") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    InfoText(text: "Searching your local data — no AI, upload or account.")
                    InfoText(text: "\(indexText).")
                    StatusBadge(kind: .custom("Simulated index", "flask"), compact: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Previews

private func searchPreviewModel(query: String, scope: SearchScopeHint = .everything) -> AppModel {
    let model = AppModel.preview
    model.searchUI.query = query
    model.searchUI.scope = scope
    model.searchUI.lastAppliedInitialScope = scope
    return model
}

#Preview("Search — examples") {
    NavigationStack { SearchScreen(initialScope: .everything) }
        .previewEnvironment()
}

#Preview("Search — lacy white shirt") {
    NavigationStack { SearchScreen(initialScope: .everything) }
        .previewEnvironment(searchPreviewModel(query: "lacy white shirt with ruffles"))
}

#Preview("Search — possible matches") {
    NavigationStack { SearchScreen(initialScope: .closet) }
        .previewEnvironment(searchPreviewModel(query: "cute ruffled shirt", scope: .closet))
}

#Preview("Search — related shades") {
    NavigationStack { SearchScreen(initialScope: .everything) }
        .previewEnvironment(searchPreviewModel(query: "blue pants interview"))
}
