import SwiftUI

// Style Me request screen and results (PRD §5.1, §7 Home/Style Me + Results, §7.1, §7.2, §8.1–8.3, §11.11).
// Passive UI (appear, scroll, resize, selection, typing) never dispatches a mock service.
// The only dispatching controls are Style Me / Retry / Restyle / New ideas, weather Refresh and picture Retry.

/// Sections of the Style Me form that can be scrolled to (keeps scroll context across layout changes).
enum StyleMeFormAnchor: Hashable {
    case top, source, readyCard, occasion, startingItem, moreOptions, onMe, blockers, action
}

/// Local, deterministic result of resolving the starting-piece text against the working source.
enum StyleMeTextResolution: Equatable {
    case unique(garmentID: String)
    case multiple(garmentIDs: [String])
    /// Matches exist only outside the selected suitcase. Never broadened automatically.
    case outsideSource(garmentID: String)
    case notFound
    case keptAsNote
}

struct StyleMeResolvedText: Equatable {
    var query: String
    var scope: WardrobeScope
    var result: StyleMeTextResolution
}

/// Style Me UI state that must survive rotation, resizing and navigation.
/// The request itself lives in `app.style.draft`; this holds presentation state only.
@Observable
final class StyleMeUIState {
    /// "More options" disclosure — collapsed by default so advanced controls stay secondary.
    var showMoreOptions = false
    /// Occasion row: collapsed to the selected occasion by default; open while she is choosing.
    var occasionExpanded = false
    /// Weather details sheet, opened from the weather line under the title.
    var showWeatherSheet = false
    var isEditingWeather = false
    var showStartingPicker = false
    var resolvedText: StyleMeResolvedText?
    /// A garment dropped on the starting-piece control, waiting for explicit confirmation.
    var pendingDropGarmentID: String?
    var dropMessage: String?
    /// Top-most visible form section (restored after layout changes).
    var formAnchor: StyleMeFormAnchor?
    /// Top-most visible result card (restored after layout changes and navigation).
    var resultsAnchor: String?
    /// The request as captured when the user last tapped Style Me / Retry / Restyle (summary while generating).
    var lastSubmittedRequest: StyleRequest?
    var wasCancelled = false
    /// Result outfit ID → saved copy ID, so a saved result shows "Saved — View" instead of saving twice.
    var savedCopies: [String: String] = [:]
    /// Weather is not AI; it may load once on first appear if nothing is loaded yet.
    var didRequestInitialWeather = false
    /// Calm-screen disclosures that are open, by key ("evidence-<outcome id>", "notes-<outfit id>"),
    /// so they stay open across rotation and the tab/sidebar switch.
    var openDisclosures: Set<String> = []

    init() {}

    /// Open state for one disclosure, for the shared disclosure components.
    func disclosure(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDisclosures.contains(key) },
            set: { open in
                if open { self.openDisclosures.insert(key) } else { self.openDisclosures.remove(key) }
            }
        )
    }
}

// MARK: - Style Me screen

struct StyleMeScreen: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var ui = app.styleMeUI
        GeometryReader { geo in
            let widthClass = WidthClass(width: geo.size.width)
            layout(for: widthClass, width: geo.size.width)
                .onAppear { syncInlineResults(widthClass) }
                .onChange(of: widthClass) { _, newValue in syncInlineResults(newValue) }
        }
        .themedScreenBackground()
        // A gentle success tap when new looks arrive (not for history offers or failures).
        .onChange(of: app.style.current?.id) { _, newID in
            guard newID != nil, let current = app.style.current else { return }
            if !current.result.outfits.isEmpty && !current.fromHistory { Haptics.success() }
        }
        .navigationTitle("Style Me")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $ui.showStartingPicker) {
            StyleMeStartingPickerSheet()
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .sheet(isPresented: $ui.showWeatherSheet) {
            StyleMeWeatherSheet()
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .onAppear { loadWeatherOnceIfMissing() }
        // No onDisappear reset: when the shell swaps TabView <-> split view, the new screen's onAppear
        // can run before the old screen's onDisappear, which would clear the flag while wide and let
        // AppModel push a duplicate results screen. Whichever Style Me screen is visible keeps it in sync.
    }

    @ViewBuilder
    private func layout(for widthClass: WidthClass, width: CGFloat) -> some View {
        switch widthClass {
        case .wide:
            let formWidth = width >= 1300 ? 380 : min(440, max(380, width * 0.36))
            HStack(spacing: 0) {
                StyleMeFormColumn(resultsInline: true, maxContentWidth: formWidth)
                    .frame(width: formWidth)
                Rectangle()
                    .fill(Palette.divider)
                    .frame(width: 1)
                    .ignoresSafeArea(edges: .bottom)
                    .accessibilityHidden(true)
                StyleMeInlineResultsPane(width: max(0, width - formWidth - 1))
            }
        case .intermediate, .compact:
            StyleMeFormColumn(resultsInline: false, maxContentWidth: 680)
        }
    }

    /// Results render beside the form only while wide, so AppModel won't push a duplicate.
    private func syncInlineResults(_ widthClass: WidthClass) {
        let inline = widthClass == .wide
        if app.style.resultsShownInline != inline { app.style.resultsShownInline = inline }
    }

    /// Weather isn't AI. Load it at most once per session, and only when nothing is loaded yet.
    private func loadWeatherOnceIfMissing() {
        let ui = app.styleMeUI
        guard app.weather == nil, !app.isLoadingWeather, !ui.didRequestInitialWeather else { return }
        ui.didRequestInitialWeather = true
        app.loadWeatherIfNeeded()
    }
}

// MARK: - Results (pushed on compact/intermediate; embedded beside the form when wide)

struct StyleResultsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                StyleMeResultsContent(embedded: false,
                                      width: max(0, geo.size.width - 2 * Spacing.m),
                                      onEditRequest: { dismiss() })
                    .padding(Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .rememberedScrollPosition(resultsScrollAnchor(app), firstID: app.style.current?.result.outfits.first?.id)
        }
        .themedScreenBackground()
        .navigationTitle("Your looks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Right-hand results pane for wide layouts. Same content as the pushed results screen.
struct StyleMeInlineResultsPane: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var width: CGFloat

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                SectionHeader("Your looks", subtitle: "Shown beside your request while there's room", editorial: true)
                StyleMeResultsContent(embedded: true,
                                      width: max(0, width - 2 * Spacing.m),
                                      onEditRequest: {
                                          withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                                              app.styleMeUI.formAnchor = .occasion
                                          }
                                      })
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .rememberedScrollPosition(resultsScrollAnchor(app), firstID: app.style.current?.result.outfits.first?.id)
        .frame(width: width)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Your looks")
    }
}

/// Scroll memory shared by the pushed results and the inline pane. An anchor left by an
/// earlier set of looks is ignored, so new results start at the top.
private func resultsScrollAnchor(_ app: AppModel) -> Binding<String?> {
    Binding(
        get: {
            let ids = app.style.current?.result.outfits.map(\.id) ?? []
            return app.styleMeUI.resultsAnchor.flatMap { ids.contains($0) ? $0 : nil }
        },
        set: { app.styleMeUI.resultsAnchor = $0 }
    )
}

// MARK: - Previews

private func styleMePreviewModel(withResults: Bool, scope: WardrobeScope = .mainCloset, onMe: Bool = false) -> AppModel {
    let model = AppModel.preview
    model.store.rememberedScope = scope
    if onMe {
        model.store.profile.onMeReference = .simulatedReference(version: 1, addedAt: .now)
        model.store.profile.permissions[.onMeImages] = .allowed
        model.style.draft.onMe = true
    }
    if withResults {
        let request = model.buildRequest()
        let context = StylistContext(preflight: model.store.preflight(scope: request.scope),
                                     profile: model.store.profile, recentOutfits: [])
        let result = MockStylist.compose(request: request, context: context)
        model.style.current = StyleOutcome(request: request, result: result)
        model.style.selectedOutfitID = result.outfits.first?.id
        model.style.phase = .finished
        if onMe, let first = result.outfits.first {
            model.style.imageJobs[first.id] = .generating(progress: 0.4)
        }
    }
    return model
}

#Preview("Style Me — iPhone") {
    NavigationStack { StyleMeScreen() }
        .previewEnvironment(styleMePreviewModel(withResults: false))
}

#Preview("Style Me — suitcase") {
    NavigationStack { StyleMeScreen() }
        .previewEnvironment(styleMePreviewModel(withResults: false, scope: .suitcase(DemoFixtures.jose)))
}

#Preview("Style Me — wide with results", traits: .landscapeLeft) {
    NavigationStack { StyleMeScreen() }
        .frame(width: 1180, height: 820)
        .previewEnvironment(styleMePreviewModel(withResults: true, onMe: true))
}

#Preview("Results — three looks") {
    NavigationStack { StyleResultsView() }
        .previewEnvironment(styleMePreviewModel(withResults: true, onMe: true))
}

#Preview("Results — partial suitcase") {
    NavigationStack { StyleResultsView() }
        .previewEnvironment(styleMePreviewModel(withResults: true, scope: .suitcase(DemoFixtures.jose)))
}
