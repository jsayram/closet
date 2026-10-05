import SwiftUI

/// Adaptive shell. Compact width → three tabs with stacks; regular width →
/// sidebar split view. All state lives in `AppModel`, so switching between the
/// two (rotation, Split View, Stage Manager resizing) preserves the request,
/// draft, selection, results and pushed screens, and dispatches nothing.
struct RootView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var app = app
        Group {
            if sizeClass == .compact {
                CompactRootView()
            } else {
                SplitRootView()
            }
        }
        .themedScreenBackground()
        .modifier(EditorReplaceAlert(active: app.sheet == nil))
        .sheet(item: $app.sheet, onDismiss: { app.rootSheetDidDismiss(compact: sizeClass == .compact) }) { sheet in
            SheetHost(sheet: sheet)
                .environment(app)
                .tint(Palette.primaryAction)
                .modifier(EditorReplaceAlert(active: true))
                .overlay(alignment: .bottom) { ToastOverlay() }
                .overlay(alignment: .bottomLeading) {
                    // Keep the development counter visible (and testable) above root sheets too.
                    if app.showDispatchHUD { DispatchHUD().padding(.leading, Spacing.xs).padding(.bottom, 120) }
                }
        }
        .overlay(alignment: .bottom) { if app.sheet == nil { ToastOverlay() } }
        .overlay(alignment: .bottomLeading) {
            // Development-only counter, kept clear of navigation bar buttons and the tab bar.
            if app.showDispatchHUD { DispatchHUD().padding(.leading, Spacing.xs).padding(.bottom, sizeClass == .compact ? 96 : Spacing.m) }
        }
        .onChange(of: sizeClass) { _, newValue in
            adapt(to: newValue)
        }
        .onAppear {
            app.isCompactLayout = sizeClass == .compact
            if !app.store.hasCompletedOnboarding, app.sheet == nil { app.sheet = .onboarding }
            app.restoreEditorDraftIfNeeded()
        }
    }

    /// Moves secondary destinations between sidebar selection and compact sheets.
    private func adapt(to sizeClass: UserInterfaceSizeClass?) {
        app.isCompactLayout = sizeClass == .compact
        if sizeClass == .compact {
            if !app.section.isCompactTab {
                let secondary = app.section
                app.section = app.lastPrimarySection
                if app.sheet == nil {
                    app.sheet = .secondary(secondary)
                } else {
                    // Another sheet is up: show this destination once that sheet closes.
                    app.returnSecondary = secondary
                }
            }
        } else if case let .secondary(section)? = app.sheet {
            app.sheet = nil
            app.select(section)
        } else if let section = app.returnSecondary {
            // Widened again before the covering sheet closed.
            app.returnSecondary = nil
            app.select(section)
        }
    }
}

/// Asks before another look replaces an open look with unsaved edits, since the editor
/// holds one look at a time. Attached to the shell and to root sheets (the chat can
/// open a look), and active only on whichever is in front.
struct EditorReplaceAlert: ViewModifier {
    @Environment(AppModel.self) private var app
    var active: Bool

    func body(content: Content) -> some View {
        content.alert(
            "Open another look?",
            isPresented: Binding(
                get: { active && app.pendingEditorOpen != nil },
                set: { if !$0, active { app.pendingEditorOpen = nil } }
            ),
            presenting: app.pendingEditorOpen
        ) { pending in
            if pending.canSave {
                Button("Save and continue") { app.resolvePendingEditorOpen(pending, saveFirst: true) }
            }
            Button("Discard changes", role: .destructive) { app.resolvePendingEditorOpen(pending, saveFirst: false) }
            Button("Keep editing", role: .cancel) { app.pendingEditorOpen = nil }
        } message: { pending in
            Text("“\(pending.title)” has changes you haven't saved. The editor holds one look at a time, so save or discard them first.")
        }
    }
}

struct CompactRootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let selection = Binding<AppSection>(
            get: { app.section.isCompactTab ? app.section : app.lastPrimarySection },
            // Only a real tab change selects: selecting a tab also closes a secondary sheet.
            set: { if $0 != app.section { app.select($0) } }
        )
        TabView(selection: selection) {
            ForEach(AppSection.compactTabs) { section in
                NavigationStack(path: app.path(for: section)) {
                    SectionRootView(section: section)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) { AccountMenuButton() }
                        }
                        .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
                }
                .tabItem { Label(section.title, systemImage: section.systemImage) }
                .tag(section)
            }
        }
    }
}

/// Profile, Settings, Feedback and Help from any compact tab.
struct AccountMenuButton: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Menu {
            Button { app.open(.profile, compact: true) } label: { Label("Profile", systemImage: AppSection.profile.systemImage) }
            Button { app.open(.settings, compact: true) } label: { Label("Settings & Privacy", systemImage: AppSection.settings.systemImage) }
            Button { app.open(.feedback, compact: true) } label: { Label("Feedback & Support", systemImage: AppSection.feedback.systemImage) }
            Button { app.open(.help, compact: true) } label: { Label("Help", systemImage: AppSection.help.systemImage) }
            Divider()
            Button { app.open(.developer, compact: true) } label: { Label("Demo Controls", systemImage: AppSection.developer.systemImage) }
        } label: {
            Image(systemName: "person.crop.circle")
                .font(.title3)
                .minimumHitTarget()
        }
        .accessibilityLabel("Profile, settings, feedback and help")
    }
}

struct SplitRootView: View {
    @Environment(AppModel.self) private var app
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        let selection = Binding<AppSection?>(
            get: { app.section },
            set: { if let s = $0 { app.select(s) } }
        )
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: selection) {
                Section {
                    ForEach(AppSection.sidebarPrimary) { section in
                        Label(section.title, systemImage: section.systemImage).tag(section)
                    }
                }
                Section("More") {
                    ForEach(AppSection.sidebarSecondary) { section in
                        Label(section.title, systemImage: section.systemImage).tag(section)
                    }
                    Label(AppSection.help.title, systemImage: AppSection.help.systemImage).tag(AppSection.help)
                    Label(AppSection.developer.title, systemImage: AppSection.developer.systemImage).tag(AppSection.developer)
                }
            }
            .navigationTitle("My Petite Style")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    StatusBadge(kind: .demo, compact: true)
                    Text("Fictional data · simulated services")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                        .lineLimit(2)
                    Spacer()
                }
                .padding(Spacing.s)
                // Rows that scroll under the footer (large text, short windows) blur instead of overlapping it.
                .background(.bar)
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        } detail: {
            NavigationStack(path: app.path(for: app.section)) {
                SectionRootView(section: app.section)
                    .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
            }
            .id(app.section)
        }
    }
}

/// Root screen for each section.
struct SectionRootView: View {
    var section: AppSection

    var body: some View {
        switch section {
        case .styleMe: StyleMeScreen()
        case .closet: ClosetScreen()
        case .saved: SavedLooksScreen()
        case .feedback: FeedbackScreen()
        case .search: SearchScreen(initialScope: .everything)
        case .suitcases: SuitcasesScreen()
        case .laundry: LaundryScreen()
        case .profile: ProfileScreen()
        case .settings: SettingsScreen()
        case .access: StylingAccessView()
        case .help: HelpView()
        case .developer: DeveloperPanelView()
        }
    }
}

/// Destination for every shared push route.
struct AppRouteDestination: View {
    var route: AppRoute

    var body: some View {
        switch route {
        case .results: StyleResultsView()
        case .editor: OutfitEditorScreen()
        case let .garment(id): GarmentDetailView(garmentID: id)
        case .suitcases: SuitcasesScreen()
        case let .suitcase(id): SuitcaseDetailView(suitcaseID: id)
        case .laundry: LaundryScreen()
        case let .search(scope): SearchScreen(initialScope: scope)
        case let .outfit(id): SavedOutfitDetailView(outfitID: id)
        case let .preview(id): PreviewDetailView(previewID: id)
        case let .collection(id): CollectionDetailView(collectionID: id)
        case .profile: ProfileScreen()
        case .settings: SettingsScreen()
        case .access: StylingAccessView()
        case .help: HelpView()
        case .releaseNotes: ReleaseNotesView()
        case .privacyData: PrivacyDataView()
        case .developer: DeveloperPanelView()
        case .feedback: FeedbackScreen()
        case .savedProducts: SavedProductsView()
        }
    }
}

/// Root-level sheet content.
struct SheetHost: View {
    @Environment(AppModel.self) private var app
    var sheet: AppSheet

    var body: some View {
        switch sheet {
        case let .addGarment(prefill): AddGarmentView(prefill: prefill)
        case let .findOne(context): FindOneView(context: context)
        case let .storeHandoff(candidate, context): StoreHandoffView(candidate: candidate, context: context)
        case let .purchaseReview(context): PurchaseReviewView(context: context)
        case let .askStylist(target): AskStylistView(target: target)
        case .onboarding: OnboardingView()
        case .stylistChat: StylistChatView()
        case let .secondary(section):
            NavigationStack(path: app.path(for: section)) {
                SectionRootView(section: section)
                    .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { app.sheet = nil }
                        }
                    }
            }
        }
    }
}
