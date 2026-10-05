import SwiftUI
import Observation

/// Reasons Style Me can't dispatch right now. Each has an honest explanation
/// and the free local alternatives stay available.
enum StyleBlocker: Hashable, Identifiable {
    case permissionDeclined
    case allowanceExhausted
    case noAccess
    case awaitingSourceChoice
    case startingItemIneligible(String)
    case onMeNotReady

    var id: String { message }

    var message: String {
        switch self {
        case .permissionDeclined:
            "Cloud styling permission is off. On this iPhone, Style Me needs the cloud stylist (the on-device Apple model isn't available on iPhone 12 — simulated). Your closet, saved looks and manual editing still work."
        case .allowanceExhausted:
            "Today's sample styling allowance is used up. It resets tomorrow. Your closet, saved looks, history and manual outfit editing stay free."
        case .noAccess:
            "Styling access isn't active (sample terms). Closet, saved looks, search and manual editing remain free."
        case .awaitingSourceChoice:
            "Your remembered suitcase isn't available. Choose a source before styling — nothing will be broadened automatically."
        case let .startingItemIneligible(name):
            "\(name) isn't eligible in this source right now. Review its status, use it for this request, or choose another starting piece."
        case .onMeNotReady:
            "On Me needs a simulated reference photo and the On Me picture permission in Profile."
        }
    }
}

/// Another look waiting to open in the editor while the open look has unsaved edits.
struct PendingEditorOpen: Identifiable {
    let id = UUID()
    /// Title of the look that's open now.
    var title: String
    /// False for a look with no pieces yet, which can't be saved.
    var canSave: Bool
    var open: () -> Void
}

/// Root application model: canonical store, injected mock services, navigation,
/// Style Me session and editor. Passive UI changes never dispatch services;
/// only explicit actions below do.
@Observable
final class AppModel {
    let store: DemoStore
    let dispatch = DispatchLog()
    var services: Services!
    var scenario: DemoScenario = .normal {
        didSet { applyScenarioSideEffects(old: oldValue) }
    }
    var fastMocks = false

    // Navigation
    var section: AppSection = .styleMe
    var lastPrimarySection: AppSection = .styleMe
    var paths: [AppSection: NavigationPath] = [:] {
        didSet { trimRouteTrails() }
    }
    var sheet: AppSheet?
    /// Compact secondary destination to bring back when the root sheet covering it closes
    /// (a sheet opened from inside it, or a narrowing window while another sheet was up).
    var returnSecondary: AppSection?
    /// Mirrors the shell's size class, so a push never lands on a stack no compact tab shows.
    var isCompactLayout = false
    /// Routes pushed through `push`, per stack, so the app can tell what's on top
    /// (NavigationPath can't). Only trusted while its count matches the path's.
    @ObservationIgnored private var routeTrails: [AppSection: [AppRoute]] = [:]
    var toast: ToastMessage?
    var showDispatchHUD = false
    /// Demo control, off by default: shows the paywall, picture packs and the
    /// out-of-pictures screen where a blocked action would otherwise only explain itself.
    var purchasesDemo = false
    /// The purchase screen on show, presented above whatever else is open.
    var purchaseSheet: PurchaseSheet?
    /// True while a constrained-frame layout preview is shown (Demo Controls).
    var layoutLabWidth: CGFloat?

    // Weather
    var weather: WeatherSnapshot?
    var weatherError: String?
    var isLoadingWeather = false

    // Style Me + editor
    let style = StyleSession()
    var editor: OutfitEditorSession?
    /// An editor open waiting on her answer, because the open look has unsaved edits.
    var pendingEditorOpen: PendingEditorOpen?
    /// Ask Stylist chat (in memory only; never persisted).
    let chat = StylistChatSession()

    // Feature-owned UI state (declared by each feature; survives layout changes).
    let styleMeUI = StyleMeUIState()
    let editorUI = OutfitEditorUIState()
    let closetUI = ClosetUIState()
    let garmentEditorUI = GarmentEditorUIState()
    let suitcasesUI = SuitcasesUIState()
    let laundryUI = LaundryUIState()
    let searchUI = SearchUIState()
    let savedUI = SavedUIState()
    let profileUI = ProfileUIState()
    let findOneUI = FindOneUIState()
    let askStylistUI = AskStylistUIState()
    let feedbackUI = FeedbackUIState()
    let settingsUI = SettingsUIState()

    init(store: DemoStore, fastMocks: Bool = false) {
        self.store = store
        self.fastMocks = fastMocks
        let scenarioProvider: () -> DemoScenario = { [unowned self] in self.scenario }
        let timingProvider: () -> MockTiming = { [unowned self] in MockTiming.forScenario(self.scenario, fast: self.fastMocks) }
        services = Services(
            stylist: MockStylist(log: dispatch, scenario: scenarioProvider, timing: timingProvider),
            images: MockImageProvider(log: dispatch, scenario: scenarioProvider, timing: timingProvider),
            webSearch: MockWebSearch(log: dispatch, scenario: scenarioProvider, timing: timingProvider),
            ranker: MockShoppingRanker(log: dispatch),
            weather: MockWeather(log: dispatch, scenario: scenarioProvider),
            garmentUnderstanding: MockGarmentUnderstanding(log: dispatch, scenario: scenarioProvider)
        )
    }

    // MARK: - Navigation helpers

    func path(for section: AppSection) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[section] ?? NavigationPath() },
            set: { self.paths[section] = $0 }
        )
    }

    /// Pushes a route onto a section's stack (and selects that section).
    func push(_ route: AppRoute, in section: AppSection? = nil) {
        let target = stackHost(for: section)
        let trailKnown = (routeTrails[target]?.count ?? 0) == (paths[target]?.count ?? 0)
        var p = paths[target] ?? NavigationPath()
        p.append(route)
        paths[target] = p
        if trailKnown { routeTrails[target, default: []].append(route) }
        reveal(target)
    }

    /// The stack a push lands on. A compact secondary sheet (Profile, Settings, …) hosts its
    /// own stack, so pushes with no explicit section go there. In compact width a stale
    /// sidebar section falls back to the visible tab.
    private func stackHost(for section: AppSection?) -> AppSection {
        if let section { return section }
        if case let .secondary(sheetSection)? = sheet { return sheetSection }
        if isCompactLayout, !self.section.isCompactTab { return lastPrimarySection }
        return self.section
    }

    /// Selects the section after a push, unless the open secondary sheet already shows it
    /// (then the tab underneath stays as it is).
    private func reveal(_ target: AppSection) {
        if case let .secondary(hosted)? = sheet, hosted == target { return }
        select(target)
    }

    /// The route on top of a stack, when every route on it came through `push`.
    func topRoute(in section: AppSection) -> AppRoute? {
        guard let trail = routeTrails[section], trail.count == (paths[section]?.count ?? 0) else { return nil }
        return trail.last
    }

    /// Drops trail entries for screens that were popped (Back, swipe, popToRoot, direct edits).
    private func trimRouteTrails() {
        for (section, trail) in routeTrails {
            let count = paths[section]?.count ?? 0
            if trail.count > count { routeTrails[section] = Array(trail.prefix(count)) }
        }
    }

    func popToRoot(_ section: AppSection) { paths[section] = NavigationPath() }

    func select(_ section: AppSection) {
        if section.isCompactTab {
            // A tab can't show through a compact secondary sheet, and shouldn't be covered
            // again by one when the current sheet closes.
            returnSecondary = nil
            if case .secondary? = sheet { sheet = nil }
        }
        self.section = section
        if section.isCompactTab { lastPrimarySection = section }
    }

    /// Opens a secondary destination: sheet on compact, sidebar section on regular.
    func open(_ section: AppSection, compact: Bool) {
        if compact, !section.isCompactTab {
            returnSecondary = nil
            sheet = .secondary(section)
        } else {
            select(section)
        }
    }

    func present(_ sheet: AppSheet) {
        // A sheet opened from a compact secondary destination returns to it when it closes.
        if case let .secondary(section)? = self.sheet {
            if case .secondary = sheet { returnSecondary = nil } else { returnSecondary = section }
        }
        self.sheet = sheet
    }

    /// Runs once a root sheet has finished closing: brings back the compact secondary
    /// destination it covered. Nothing is dispatched.
    func rootSheetDidDismiss(compact: Bool) {
        guard sheet == nil, let section = returnSecondary else { return }
        returnSecondary = nil
        if compact { sheet = .secondary(section) } else { select(section) }
    }

    func showToast(_ text: String, style: ToastMessage.Style = .success, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        toast = ToastMessage(text: text, style: style, actionTitle: actionTitle, action: action)
    }

    /// Shows a toast with an Undo action wired to the store's latest bounded undo entry.
    func showUndoToast(_ text: String) {
        showToast(text, style: .success, actionTitle: "Undo") { [weak self] in
            guard let self, let message = self.store.undoLast() else { return }
            self.showToast(message, style: .info)
        }
    }

    // MARK: - Source

    var workingScope: WardrobeScope { store.rememberedScope }
    var workingScopeName: String { store.scopeName(store.rememberedScope) }

    /// Deliberate source selection. Marks any delivered result from another source as Earlier.
    func selectScope(_ scope: WardrobeScope) {
        guard scope != store.rememberedScope || store.awaitingSourceChoice else { return }
        store.selectScope(scope)
        if var current = style.current, current.request.scope != scope {
            current.staleReason = "These looks were made from \(current.request.scopeName). You've switched to \(store.scopeName(scope)) — restyle to use it. Nothing was re-run automatically."
            style.current = current
        }
        if scope.isSuitcase { style.draft.allowNewPiece = false }
    }

    // MARK: - Weather

    /// Loads simulated weather once; the snapshot is reused for 30 minutes. This is the one
    /// automatic call (PRD FR-04), and the dispatch counter keeps it apart from tapped ones.
    func loadWeatherIfNeeded() {
        if let weather, Date.now.timeIntervalSince(weather.fetchedAt) < 1800 { return }
        if isLoadingWeather { return }
        refreshWeather(automatic: true)
    }

    func refreshWeather(automatic: Bool = false) {
        isLoadingWeather = true
        weatherError = nil
        Task { @MainActor in
            do {
                let snapshot = try await services.weather.currentConditions(automatic: automatic)
                weather = snapshot
            } catch {
                weatherError = "Weather is unavailable right now (simulated). Using the season — set conditions yourself if you like."
                if weather == nil {
                    weather = WeatherSnapshot(temperatureF: 60, condition: .cloudy, season: Season.from(date: .now), source: .seasonOnly)
                }
            }
            isLoadingWeather = false
        }
    }

    var effectiveWeather: WeatherSnapshot {
        style.draft.weatherOverride ?? weather ?? WeatherSnapshot(temperatureF: 60, condition: .cloudy, season: Season.from(date: .now), source: .seasonOnly)
    }

    // MARK: - Style Me

    func buildRequest() -> StyleRequest {
        let d = style.draft
        let scope = workingScope
        return StyleRequest(
            scope: scope,
            scopeName: store.scopeName(scope),
            occasion: d.occasion,
            customOccasion: d.customOccasion,
            weather: effectiveWeather,
            startingItemID: d.startingItemID,
            startingText: d.startingText,
            comfort: d.comfort,
            usualFit: store.profile.usualFit,
            colorConstraint: d.colorConstraint,
            mode: scope.isSuitcase ? .ownedOnly : d.mode,
            allowNewPiece: scope.isSuitcase ? false : d.allowNewPiece,
            onMe: d.onMe,
            // A per-request exception only ever covers the current starting piece.
            overrideIDs: d.overrideIDs.intersection([d.startingItemID].compactMap { $0 }),
            profileRevision: store.profile.revision,
            inventoryRevision: store.inventoryRevision
        )
    }

    var styleBlockers: [StyleBlocker] {
        var blockers: [StyleBlocker] = []
        if store.awaitingSourceChoice { blockers.append(.awaitingSourceChoice) }
        if store.profile.permission(.cloudStyling) != .allowed { blockers.append(.permissionDeclined) }
        if !store.access.plan.hasStylingAccess { blockers.append(.noAccess) } else if store.access.isStylingExhausted { blockers.append(.allowanceExhausted) }
        if let id = style.draft.startingItemID, let g = store.garment(id) {
            if !store.eligibility(of: g, scope: workingScope, overrides: style.draft.overrideIDs).isEligible {
                blockers.append(.startingItemIneligible(g.displayName))
            }
        }
        if style.draft.onMe, !isOnMeReady { blockers.append(.onMeNotReady) }
        return blockers
    }

    var isOnMeReady: Bool {
        store.profile.permission(.onMeImages) == .allowed && store.profile.onMeReference.version != nil
    }

    /// The single explicit Style Me action. Checks local history first (zero dispatch).
    func styleMe() {
        guard !style.isGenerating else { return }
        // Local history lookup is free and stays available after expiry, quota exhaustion or
        // declined cloud permission (PRD 8.2/11.11). Only source/starting-item/On Me readiness
        // blockers stop it.
        let freeBlockers = styleBlockers.filter { blocker in
            switch blocker {
            case .permissionDeclined, .allowanceExhausted, .noAccess: false
            default: true
            }
        }
        guard freeBlockers.isEmpty else { return }
        let request = buildRequest()
        if let match = store.historyMatch(for: request) {
            dispatch.recordAvoided()
            style.historyOffer = HistoryOffer(entry: match, request: request)
            style.phase = .finished
            showResults()
            return
        }
        guard styleBlockers.isEmpty else { return }
        style.historyOffer = nil
        runGeneration(request)
    }

    /// Use a revalidated history look: local, free, no stylist or image dispatch.
    /// Only an exact retained picture is attached; a miss offers Make picture instead.
    func useHistoryLook() {
        guard let offer = style.historyOffer else { return }
        var outfit = offer.entry.outfitSnapshot
        outfit.id = UUID().uuidString
        outfit.isSaved = false
        outfit.capturedScope = offer.request.scope
        outfit.capturedScopeName = offer.request.scopeName
        // Fit notes and the comfort sentence describe the inputs the look was made with.
        // When those have changed, drop them rather than show stale guidance.
        if store.historyFitChanged(offer.entry) { outfit.fitNote = "" }
        if let made = offer.entry.comfort, made != offer.request.effectiveComfort(profile: store.profile) {
            outfit.fitNote = ""
            outfit.rationale = MockStylist.removingComfortSentence(made, from: outfit.rationale)
        }
        style.current = StyleOutcome(request: offer.request, result: .partialWardrobe([outfit], evidence: []), fromHistory: true, historyCapturedAt: offer.entry.capturedAt)
        style.historyOffer = nil
        style.selectedOutfitID = outfit.id
        style.cancelImageTasks()
        style.imageJobs = [:]
        style.previewByOutfit = [:]
        style.earlierPreviewOutfitIDs = []
        if offer.request.onMe, !attachRetainedPreview(for: outfit) {
            style.imageJobs[outfit.id] = .notStarted(reason: "this look came from your history, so no new picture was made. Make one only if you want it (1 sample image unit).")
        }
    }

    /// Explicit fresh styling that bypasses history reuse.
    func newIdeas() {
        guard styleBlockers.isEmpty else { return }
        let request = style.historyOffer?.request ?? buildRequest()
        style.historyOffer = nil
        runGeneration(request)
    }

    private func showResults() {
        if style.resultsShownInline { select(.styleMe); return }
        let path = paths[.styleMe] ?? NavigationPath()
        if path.isEmpty { push(.results, in: .styleMe) } else { select(.styleMe) }
    }

    private func runGeneration(_ request: StyleRequest) {
        style.generationTask?.cancel()
        style.cancelImageTasks()
        style.phase = .generating(requestID: request.id, startedAt: .now)
        style.current = nil
        style.imageJobs = [:]
        style.previewByOutfit = [:]
        style.earlierPreviewOutfitIDs = []
        showResults()
        let context = StylistContext(preflight: store.preflight(scope: request.scope, overrides: request.overrideIDs),
                                     profile: store.profile, recentOutfits: store.savedOutfits)
        style.generationTask = Task { @MainActor in
            do {
                let result = try await services.stylist.generateOutfits(request, context: context)
                guard case let .generating(id, _) = style.phase, id == request.id else { return }
                // Client-side revalidation: every owned piece must still be eligible in the captured source.
                let validated = revalidate(result, request: request)
                style.current = StyleOutcome(request: request, result: validated)
                style.phase = .finished
                style.selectedOutfitID = validated.outfits.first?.id
                if case .outfitSet = validated { store.consumeStylingUnit() }
                for outfit in validated.outfits where !outfit.hasHypotheticalPiece { store.recordHistory(outfit, request: request) }
                if request.onMe, isOnMeReady, !validated.outfits.isEmpty { startPreviews(for: validated.outfits, request: request) }
                announce(Self.outcomeAnnouncement(validated))
            } catch is CancellationError {
                // Cancelled by the user; request is kept in the draft.
            } catch {
                guard case let .generating(id, _) = style.phase, id == request.id else { return }
                style.current = StyleOutcome(request: request, result: .generationNotCompleted(reason: error.localizedDescription))
                style.phase = .finished
                announce(Self.outcomeAnnouncement(.generationNotCompleted(reason: "")))
            }
        }
    }

    /// What VoiceOver hears when styling finishes, since the results replace the working screen.
    private static func outcomeAnnouncement(_ result: OutfitGenerationResult) -> String {
        let count = result.outfits.count
        switch result {
        case .outfitSet: return count == 1 ? "1 look ready" : "\(count) looks ready"
        case .partialWardrobe:
            if count == 0 { return "No looks this time. See the notes about your closet." }
            return (count == 1 ? "1 look ready" : "\(count) looks ready") + ". Some notes about your closet are shown."
        case .insufficientWardrobe: return "No looks this time. See the notes about your closet."
        case .generationNotCompleted: return "Styling didn't complete. Your request is kept."
        }
    }

    /// Speaks a result that arrives while VoiceOver focus is somewhere else.
    private func announce(_ text: String) {
        AccessibilityNotification.Announcement(text).post()
    }

    /// Rejects stale/ineligible owned references rather than substituting garments.
    private func revalidate(_ result: OutfitGenerationResult, request: StyleRequest) -> OutfitGenerationResult {
        func valid(_ o: Outfit) -> Bool {
            o.pieces.allSatisfy { piece in
                guard let id = piece.garmentID else { return piece.isHypothetical && !request.isStrictOwned || piece.isHypothetical && request.allowNewPiece && !request.scope.isSuitcase }
                guard let g = store.garment(id) else { return false }
                return store.eligibility(of: g, scope: request.scope, overrides: request.overrideIDs).isEligible
            }
        }
        switch result {
        case let .outfitSet(outfits):
            let ok = outfits.filter(valid)
            return ok.count == outfits.count ? result : .generationNotCompleted(reason: "Your closet changed while styling, so these looks were not applied. Nothing was substituted — try again.")
        case let .partialWardrobe(outfits, evidence):
            let ok = outfits.filter(valid)
            return ok.count == outfits.count ? result : .partialWardrobe(ok, evidence: evidence + ["Some looks were withdrawn because pieces changed while styling."])
        default:
            return result
        }
    }

    /// Cancels applying the in-flight result. Already-dispatched simulated work may still count.
    func cancelStyling() {
        style.generationTask?.cancel()
        style.phase = .idle
        showToast("Cancelled. Your request is kept. (A real service may already have started the work.)", style: .info)
    }

    // MARK: - Simulated On Me previews

    func renderKey(for outfit: Outfit) -> String {
        outfit.renderKey(referenceVersion: store.profile.onMeReference.version ?? 0,
                         appearanceRevisions: Dictionary(uniqueKeysWithValues: store.garments.map { ($0.id, $0.appearanceRevision) }))
    }

    /// How many new picture jobs the sample plan can take right now. Exact reuse needs no admission.
    func admittedImageJobs(_ misses: Int) -> Int {
        let access = store.access
        if access.plan == .sponsored { return misses }
        let inFlight = style.imageJobs.values.filter { !$0.isTerminal }.count + ((editor?.previewJob).map { $0.isTerminal ? 0 : 1 } ?? 0)
        // Purchased pictures keep working without an active plan (PRD §14); included ones need it.
        let available = (access.plan.hasStylingAccess ? access.imageUnitsRemaining : 0) + access.imageWallet
        return max(0, min(misses, available - inFlight))
    }

    /// Why a new picture can't start. Shown instead of charging anything.
    var imageAdmissionBlockedReason: String {
        store.access.plan.hasStylingAccess
            ? "no sample picture units are left this month. Boards and saved pictures still work."
            : "styling access isn't active (sample terms), so no new pictures. Boards and saved pictures still work."
    }

    /// Attaches an exact retained picture with no dispatch or units. Returns false on a miss.
    @discardableResult
    private func attachRetainedPreview(for outfit: Outfit) -> Bool {
        guard let existing = store.retainedPreview(renderKey: renderKey(for: outfit)) else { return false }
        style.imageJobs[outfit.id] = .reused(previewID: existing.id)
        style.previewByOutfit[outfit.id] = existing.id
        dispatch.recordAvoided()
        return true
    }

    /// Starts previews for delivered directions. Exact retained matches are reused with no dispatch/units;
    /// misses run only as far as access and the image allowance admit them.
    func startPreviews(for outfits: [Outfit], request: StyleRequest) {
        var misses: [Outfit] = []
        for outfit in outfits {
            if !attachRetainedPreview(for: outfit) { misses.append(outfit) }
        }
        let admitted = admittedImageJobs(misses.count)
        let queue = Array(misses.prefix(admitted))
        for outfit in queue { style.imageJobs[outfit.id] = .queued }
        for outfit in misses.dropFirst(admitted) { style.imageJobs[outfit.id] = .notStarted(reason: imageAdmissionBlockedReason) }
        if admitted < misses.count {
            showToast(admitted == 0
                      ? "No new pictures were started: \(imageAdmissionBlockedReason)"
                      : "\(admitted) of \(misses.count) pictures fit your remaining sample allowance. Every board still works.", style: .info)
        }
        guard !queue.isEmpty else { return }
        let taskID = UUID()
        style.imageTasks[taskID] = Task { @MainActor in
            for outfit in queue {
                if Task.isCancelled { break }
                await runImageJob(for: outfit, request: request)
            }
            style.imageTasks[taskID] = nil
        }
    }

    /// A job may only write state while its look is still shown and wasn't cancelled.
    private func isLiveImageJob(_ outfitID: String) -> Bool {
        guard style.current?.result.outfits.contains(where: { $0.id == outfitID }) == true else { return false }
        if case .cancelled? = style.imageJobs[outfitID] { return false }
        return true
    }

    @MainActor
    private func runImageJob(for outfit: Outfit, request: StyleRequest) async {
        guard isLiveImageJob(outfit.id) else { return }
        let key = renderKey(for: outfit)
        let job = ImageJobRequest(jobID: UUID().uuidString, outfit: outfit, referenceVersion: store.profile.onMeReference.version ?? 0, renderKey: key)
        style.imageJobs[outfit.id] = .generating(progress: 0)
        do {
            let quality = try await services.images.render(job) { [weak self] p in
                guard let self, self.isLiveImageJob(outfit.id) else { return }
                self.style.imageJobs[outfit.id] = .generating(progress: p)
            }
            // A cancelled or replaced job is dropped: nothing is retained or charged.
            guard !Task.isCancelled, isLiveImageJob(outfit.id) else { return }
            style.imageJobs[outfit.id] = .saving
            let entry = PreviewEntry(outfitID: outfit.id, outfitRevision: outfit.revision, title: outfit.title, lane: outfit.lane,
                                     snapshotPieces: outfit.pieces, referenceVersion: job.referenceVersion, renderKey: key, quality: quality,
                                     keywords: outfit.keywords, capturedScope: request.scope, capturedScopeName: request.scopeName,
                                     occasion: request.occasion)
            // Retained automatically before Ready is shown.
            store.retainPreview(entry)
            store.consumeImageUnits(1)
            style.imageJobs[outfit.id] = .ready(previewID: entry.id)
            style.previewByOutfit[outfit.id] = entry.id
            announce("Picture ready for \(outfit.title)")
            // If the draft for this outfit changed meanwhile, the delivered picture is Earlier.
            if let editor, case let .result(id) = editor.origin, id == outfit.id, editor.draftRevision > 0 {
                style.earlierPreviewOutfitIDs.insert(outfit.id)
                editor.previewID = entry.id
                editor.previewIsEarlier = true
            }
        } catch is CancellationError {
            if style.current?.result.outfits.contains(where: { $0.id == outfit.id }) == true { style.imageJobs[outfit.id] = .cancelled }
        } catch {
            guard isLiveImageJob(outfit.id) else { return }
            style.imageJobs[outfit.id] = .failed(reason: (error as? ServiceError)?.errorDescription ?? "Simulated failure")
            announce("Picture failed for \(outfit.title). The board still works.")
        }
    }

    func cancelPreviews() {
        style.cancelImageTasks()
        for (id, phase) in style.imageJobs where !phase.isTerminal { style.imageJobs[id] = .cancelled }
        showToast("Picture previews cancelled. Boards stay usable.", style: .info)
    }

    /// Explicit retry of one failed, cancelled or not-started preview. Goes through normal admission.
    func retryPreview(outfitID: String) {
        guard let current = style.current, let outfit = current.result.outfits.first(where: { $0.id == outfitID }) else { return }
        guard style.imageJobs[outfitID]?.isTerminal ?? true else { return }
        startPreviews(for: [outfit], request: current.request)
    }

    // MARK: - Editor

    func openEditor(forResult outfit: Outfit, selecting slot: OutfitSlot? = nil) {
        if let editor, case let .result(id) = editor.origin, id == outfit.id {
            if let slot { editor.selectedSlot = slot }
            showEditor(in: .styleMe)
            return
        }
        replaceEditor { [weak self] in
            guard let self else { return }
            let session = OutfitEditorSession(origin: .result(outfitID: outfit.id), outfit: outfit, scope: style.current?.request.scope ?? workingScope)
            session.overrideIDs = style.current?.request.overrideIDs ?? []
            session.previewID = style.previewByOutfit[outfit.id]
            session.selectedSlot = slot
            editor = session
            showEditor(in: .styleMe)
        }
    }

    /// `section` nil opens the editor on the stack the caller is on (including a compact secondary sheet).
    func openEditor(forSaved outfitID: String, in section: AppSection? = .saved) {
        guard let outfit = store.outfit(outfitID) else { return }
        if let editor, case let .saved(id) = editor.origin, id == outfitID {
            showEditor(in: section)
            return
        }
        replaceEditor { [weak self] in
            guard let self else { return }
            let session = OutfitEditorSession(origin: .saved(outfitID: outfitID), outfit: outfit, scope: outfit.capturedScope ?? .mainCloset)
            session.previewID = store.previews(forOutfit: outfitID).first?.id
            editor = session
            showEditor(in: section)
        }
    }

    func openNewOutfitEditor(in section: AppSection = .saved) {
        if let editor, case .new = editor.origin {
            showEditor(in: section)
            return
        }
        replaceEditor { [weak self] in
            guard let self else { return }
            let outfit = Outfit(title: "New look", lane: .manual, pieces: [], capturedScope: workingScope, capturedScopeName: workingScopeName)
            editor = OutfitEditorSession(origin: .new, outfit: outfit, scope: workingScope)
            showEditor(in: section)
        }
    }

    /// The editor holds one look at a time. When the open look has edits she hasn't saved,
    /// ask before another look replaces it (see `EditorReplaceAlert`); otherwise open right away.
    private func replaceEditor(_ open: @escaping () -> Void) {
        guard let editor, editor.outfitEditorHasEditsSinceBase else {
            open()
            return
        }
        pendingEditorOpen = PendingEditorOpen(title: editor.outfit.title, canSave: !editor.outfit.pieces.isEmpty, open: open)
    }

    /// Her answer to `pendingEditorOpen`: save the open look first, or discard its changes.
    /// If the save fails, its error toast explains and the open look stays as it is.
    func resolvePendingEditorOpen(_ pending: PendingEditorOpen, saveFirst: Bool) {
        pendingEditorOpen = nil
        if saveFirst {
            saveEditor(asCopy: false)
            guard let editor, case .saved = editor.saveState else { return }
        }
        closeEditor()
        pending.open()
    }

    /// Shows the open editor on a stack. An editor screen already on top is reused rather
    /// than stacked again, and editor screens on other stacks are popped so none of them
    /// shows a different look than the one it opened.
    private func showEditor(in section: AppSection?) {
        let host = stackHost(for: section)
        for (other, trail) in routeTrails where other != host {
            guard let index = trail.firstIndex(of: .editor), var p = paths[other], p.count > index else { continue }
            p.removeLast(p.count - index)
            paths[other] = p
        }
        if topRoute(in: host) == .editor {
            reveal(host)
        } else {
            push(.editor, in: host)
        }
    }

    /// Real alternatives for a slot within the draft's captured source, with honest eligibility.
    func swapOptions(for slot: OutfitSlot) -> [SwapOption] {
        guard let editor else { return [] }
        let currentID = editor.outfit.piece(for: slot)?.garmentID
        return store.garments
            .filter { $0.category == slot.category && store.isInScope($0, editor.scope) && !$0.isTrashed }
            .filter { $0.ownership == .owned || $0.ownership == .purchasedConfirmed }
            .map { g in
                SwapOption(garment: g,
                           eligibility: store.eligibility(of: g, scope: editor.scope, overrides: editor.overrideIDs),
                           isCurrent: g.id == currentID,
                           matchesColorFilter: editor.colorFilter == nil || g.color?.family == editor.colorFilter)
            }
            .sorted { a, b in
                if a.isCurrent != b.isCurrent { return a.isCurrent }
                if a.eligibility.isEligible != b.eligibility.isEligible { return a.eligibility.isEligible }
                if a.matchesColorFilter != b.matchesColorFilter { return a.matchesColorFilter }
                return a.garment.displayName < b.garment.displayName
            }
    }

    /// Per-request exception for one still-owned Dirty/Unavailable/Archived item. Stored status is unchanged.
    func allowForThisRequest(_ garmentID: String) {
        guard let editor, let g = store.garment(garmentID), store.eligibility(of: g, scope: editor.scope).canOverride else { return }
        editor.overrideIDs.insert(garmentID)
        persistEditorDraft()
    }

    /// Writes the open draft durably (or clears it when nothing is unsaved).
    func persistEditorDraft() {
        if let editor, editor.hasUnsavedChanges {
            store.editorDraft = editor.record
        } else {
            store.editorDraft = nil
        }
        store.persist()
    }

    /// Restores an unsaved draft written before the app was closed.
    func restoreEditorDraftIfNeeded() {
        guard editor == nil, let record = store.editorDraft else { return }
        editor = OutfitEditorSession(record: record)
        let section: AppSection = {
            if case .saved = record.origin { return .saved }
            if case .new = record.origin { return .saved }
            return .styleMe
        }()
        showToast("Your unsaved look “\(record.outfit.title)” was kept on this device.", style: .info, actionTitle: "Open") { [weak self] in
            self?.showEditor(in: section)
        }
    }

    private func recordEdit(affectsPicture: Bool = true, _ change: (inout Outfit) -> Void) {
        guard let editor else { return }
        editor.undoStack.append(editor.outfit)
        if editor.undoStack.count > 20 { editor.undoStack.removeFirst() }
        editor.redoStack.removeAll()
        change(&editor.outfit)
        editor.draftRevision += 1
        if editor.saveState != .saving { editor.saveState = .unsaved }
        if affectsPicture, editor.previewID != nil {
            editor.previewIsEarlier = true
            if case let .result(id) = editor.origin { style.earlierPreviewOutfitIDs.insert(id) }
        }
        persistEditorDraft()
    }

    /// Commits a one-piece swap. Only the chosen slot changes; other piece IDs/layout stay fixed.
    @discardableResult
    func applySwap(slot: OutfitSlot, garmentID: String) -> Bool {
        guard let editor, let g = store.garment(garmentID) else { return false }
        guard store.eligibility(of: g, scope: editor.scope, overrides: editor.overrideIDs).isEligible else { return false }
        recordEdit { outfit in
            var newPiece = OutfitPiece.from(g, slot: slot)
            if let i = outfit.pieces.firstIndex(where: { $0.slot == slot }) {
                newPiece.id = outfit.pieces[i].id
                outfit.pieces[i] = newPiece
            } else {
                outfit.pieces.append(newPiece)
            }
            if slot == .dress { outfit.pieces.removeAll { $0.slot == .top || $0.slot == .bottom } }
            if slot == .top || slot == .bottom { outfit.pieces.removeAll { $0.slot == .dress } }
        }
        return true
    }

    func removePiece(slot: OutfitSlot) {
        recordEdit { $0.pieces.removeAll { $0.slot == slot } }
    }

    /// Renaming changes no garment, so an existing picture is not marked Earlier.
    func renameDraft(_ title: String) {
        recordEdit(affectsPicture: false) { $0.title = title }
    }

    func undoEdit() {
        guard let editor, let previous = editor.undoStack.popLast() else { return }
        editor.redoStack.append(editor.outfit)
        editor.outfit = previous
        editor.draftRevision += 1
        persistEditorDraft()
    }

    func redoEdit() {
        guard let editor, let next = editor.redoStack.popLast() else { return }
        editor.undoStack.append(editor.outfit)
        editor.outfit = next
        editor.draftRevision += 1
        persistEditorDraft()
    }

    func discardEditorChanges() {
        guard let editor else { return }
        editor.undoStack.append(editor.outfit)
        editor.redoStack.removeAll()
        editor.outfit = editor.baseOutfit
        editor.draftRevision += 1
        if case .failed = editor.saveState { editor.saveState = editor.baseOutfit.isSaved ? .saved(editor.baseOutfit.updatedAt) : .unsaved }
        persistEditorDraft()
    }

    /// Explicit Save / Save as Copy. Acknowledged only after the durable write succeeds.
    func saveEditor(asCopy: Bool) {
        guard let editor else { return }
        editor.saveState = .saving
        var outfit = editor.outfit
        if case .result = editor.origin, !asCopy, !outfit.isSaved {
            outfit.id = UUID().uuidString // a delivered result becomes a new saved look
        }
        do {
            let saved = try store.saveOutfit(outfit, asCopy: asCopy)
            if !asCopy {
                editor.outfit = saved
                editor.baseOutfit = saved
                editor.origin = .saved(outfitID: saved.id)
            }
            if asCopy {
                // The copy was written; this draft itself is unchanged.
                editor.saveState = editor.hasUnsavedChanges ? .unsaved : .saved(.now)
            } else {
                editor.saveState = .saved(.now)
            }
            showToast(asCopy ? "Saved as a new copy on this device." : "Saved on this device.")
            persistEditorDraft()
        } catch {
            editor.saveState = .failed(error.localizedDescription)
            showToast(error.localizedDescription, style: .error)
        }
    }

    /// Explicit Update Preview: checks exact retained reuse first, then admits one new job.
    func updatePreview() {
        guard let editor else { return }
        guard isOnMeReady else {
            showToast("On Me needs a simulated reference and permission in Profile.", style: .info)
            return
        }
        let outfit = editor.outfit
        let key = renderKey(for: outfit)
        if let existing = store.retainedPreview(renderKey: key) {
            dispatch.recordAvoided()
            editor.previewID = existing.id
            editor.previewIsEarlier = false
            editor.previewJob = .reused(previewID: existing.id)
            showToast("Reused a matching picture from your history — no new image work.", style: .info)
            return
        }
        guard admittedImageJobs(1) == 1 else {
            editor.previewJob = .notStarted(reason: imageAdmissionBlockedReason)
            return
        }
        editor.previewJob = .queued
        let scope = editor.scope
        let scopeName = store.scopeName(scope)
        Task { @MainActor in
            let job = ImageJobRequest(jobID: UUID().uuidString, outfit: outfit, referenceVersion: store.profile.onMeReference.version ?? 0, renderKey: key)
            do {
                let quality = try await services.images.render(job) { [weak self] p in self?.editor?.previewJob = .generating(progress: p) }
                let entry = PreviewEntry(outfitID: outfit.id, outfitRevision: outfit.revision, title: outfit.title, lane: outfit.lane,
                                         snapshotPieces: outfit.pieces, referenceVersion: job.referenceVersion, renderKey: key, quality: quality,
                                         keywords: outfit.keywords, capturedScope: scope, capturedScopeName: scopeName, occasion: outfit.occasion)
                store.retainPreview(entry)
                store.consumeImageUnits(1)
                guard let current = self.editor, current.id == editor.id else { return }
                current.previewJob = .ready(previewID: entry.id)
                // Apply as current only if the draft still matches what was rendered.
                if renderKey(for: current.outfit) == key {
                    current.previewID = entry.id
                    current.previewIsEarlier = false
                }
            } catch {
                self.editor?.previewJob = .failed(reason: "Simulated failure — your board is unchanged.")
            }
        }
    }

    /// Already Own on a hypothetical piece: creates an owned, text-only record (no photo needed)
    /// and links it into the draft. Never adds suitcase membership automatically.
    func markAlreadyOwn(pieceID: String) {
        guard let editor, let piece = editor.outfit.pieces.first(where: { $0.id == pieceID }), piece.isHypothetical else { return }
        var g = Garment(id: "g-\(UUID().uuidString.prefix(8))", displayName: piece.capturedName, category: piece.slot.category, kind: piece.capturedKind, color: piece.capturedColor)
        g.ownership = .owned
        g.imageKind = .representative
        g.formality = .smart
        let saved = store.addGarment(g)
        recordEdit { outfit in
            if let i = outfit.pieces.firstIndex(where: { $0.id == pieceID }) {
                var p = OutfitPiece.from(saved, slot: piece.slot)
                p.id = pieceID
                outfit.pieces[i] = p
            }
        }
        let note = editor.scope.isSuitcase ? " It's in Main Closet only — add it to this suitcase separately if you want." : ""
        showToast("Added to your closet as owned, with a representative image. Add your photo any time.\(note)")
    }

    func closeEditor() {
        editor = nil
        store.editorDraft = nil
        store.persist()
    }

    // MARK: - Ask Stylist chat (FR-14)

    /// Opens the chat, optionally about a specific look. Opening dispatches nothing.
    func openStylistChat(attaching outfit: Outfit? = nil) {
        if let outfit { chat.attachedOutfit = outfit }
        if workingScope.isSuitcase { chat.mode = .closetOnly }
        present(.stylistChat)
    }

    /// Reasons a chat message can't be sent right now (closet tools stay free).
    var chatBlockers: [StyleBlocker] {
        var blockers: [StyleBlocker] = []
        if store.awaitingSourceChoice { blockers.append(.awaitingSourceChoice) }
        if store.profile.permission(.cloudStyling) != .allowed { blockers.append(.permissionDeclined) }
        if !store.access.plan.hasStylingAccess {
            blockers.append(.noAccess)
        } else if store.access.plan != .sponsored, store.access.swapsRemaining == 0 {
            blockers.append(.allowanceExhausted)
        }
        return blockers
    }

    /// Explicit send: the only action that dispatches the stylist from chat.
    func sendChat(_ rawText: String? = nil) {
        let text = (rawText ?? chat.draftText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, chatBlockers.isEmpty, !chat.isResponding else { return }
        chat.messages.append(StylistChatMessage(role: .user, text: text, outfit: nil))
        chat.draftText = ""
        chat.isResponding = true
        let attached = chat.attachedOutfit
        let mode = workingScope.isSuitcase ? .closetOnly : chat.mode
        var base = buildRequest()
        base.mode = mode == .closetOnly ? .ownedOnly : (workingScope.isSuitcase ? .ownedOnly : .suggestions)
        base.allowNewPiece = mode == .closetPlusIdeas && !workingScope.isSuitcase
        base.onMe = false
        // Chat answers are ordinary suggestions: a Style Me "use it once" exception never applies.
        base.overrideIDs = []
        let context = StylistContext(preflight: store.preflight(scope: base.scope, overrides: base.overrideIDs),
                                     profile: store.profile, recentOutfits: store.savedOutfits)
        chat.task = Task { @MainActor in
            do {
                let answer = try await services.stylist.answer(question: text, attachedOutfit: attached, mode: mode,
                                                               baseRequest: base, context: context)
                chat.messages.append(StylistChatMessage(role: .stylist, text: answer.text, outfit: answer.outfit, followUps: answer.followUps))
                let note = answer.outfit.flatMap { chatLookCheckNote($0, request: base) }
                if let note {
                    chat.messages.append(StylistChatMessage(role: .notice, text: note, outfit: nil))
                }
                store.consumeSwapUnit()
                announce("Stylist: \(answer.text)" + (answer.outfit == nil ? "" : " A look is included.") + (note.map { " " + $0 } ?? ""))
            } catch is CancellationError {
                chat.messages.append(StylistChatMessage(role: .notice, text: "Stopped. Nothing was changed.", outfit: nil))
                announce("Stopped. Nothing was changed.")
            } catch {
                chat.messages.append(StylistChatMessage(role: .notice, text: "The stylist didn't answer (simulated outage). Your closet and looks are unchanged — try again or use Style Me's buttons.", outfit: nil))
                announce("The stylist didn't answer. Your closet and looks are unchanged.")
            }
            chat.isResponding = false
        }
    }

    /// Client-side check of a chat look against the source and mode it was asked in.
    /// Pieces that can't be used are named, never swapped out silently.
    private func chatLookCheckNote(_ outfit: Outfit, request: StyleRequest) -> String? {
        var problems: [String] = []
        for piece in outfit.pieces {
            if let id = piece.garmentID {
                guard let g = store.garment(id) else { problems.append("\(piece.capturedName) is no longer in your closet"); continue }
                let e = store.eligibility(of: g, scope: request.scope)
                if !e.isEligible { problems.append("\(g.displayName) is \(e.issues.map(\.label).joined(separator: ", ").lowercased())") }
            } else if piece.isHypothetical, !request.allowNewPiece || request.scope.isSuitcase {
                problems.append("\(piece.capturedName) isn't something you own")
            }
        }
        guard !problems.isEmpty else { return nil }
        return "Checked on this device: " + problems.joined(separator: "; ") + ". Those pieces can't be used in \(request.scopeName) right now and are labelled on the look."
    }

    func stopChat() {
        chat.task?.cancel()
    }

    func clearChat() {
        chat.task?.cancel()
        chat.messages = []
        chat.savedLookIDs = [:]
        chat.draftText = ""
        chat.isResponding = false
    }

    /// Opens a look from the chat as an editable, unsaved draft (no dispatch).
    func openChatLookInEditor(_ outfit: Outfit) {
        var draft = outfit
        draft.id = UUID().uuidString
        draft.isSaved = false
        // Checked before the chat closes, so Keep editing leaves her in the chat.
        replaceEditor { [weak self] in
            guard let self else { return }
            let session = OutfitEditorSession(origin: .new, outfit: draft, scope: draft.capturedScope ?? workingScope)
            editor = session
            returnSecondary = nil
            sheet = nil
            let target: AppSection = section.isCompactTab ? section : .styleMe
            showEditor(in: target)
            persistEditorDraft()
        }
    }

    // MARK: - Find One entry

    func findOneContext(for piece: OutfitPiece, outfit: Outfit?) -> FindOneContext {
        FindOneContext(outfitID: outfit?.id, slot: piece.slot,
                       description: piece.capturedKind == .unknown ? piece.capturedName : piece.capturedKind.label.lowercased(),
                       kind: piece.capturedKind, colorFamily: piece.capturedColor?.family, scope: editor?.scope ?? workingScope)
    }

    // MARK: - Scenarios

    private func applyScenarioSideEffects(old: DemoScenario) {
        store.simulateSaveFailure = scenario == .saveFailure
        switch scenario {
        case .declinedPermission:
            store.setPermission(.cloudStyling, .declined)
        case .exhaustedAllowance:
            store.access.plan = .subscribed
            store.access.stylingUsedToday = store.access.terms.dailyStylingAllowance
            store.commit(inventoryChanged: false)
        case .syncConflict:
            store.sync.status = .conflict(description: "Navy cardigan was edited on another device")
            store.sync.conflicts = [SyncConflict(garmentID: "g-navy-cardigan", field: "Status", thisDeviceValue: "Available", otherDeviceValue: "Dirty")]
            store.commit(inventoryChanged: false)
        case .partialCloset:
            selectScope(.suitcase(DemoFixtures.jose))
        case .offlineWeather:
            refreshWeather()
        default:
            break
        }
        if old == .declinedPermission, scenario != .declinedPermission { store.setPermission(.cloudStyling, .allowed) }
        if old == .exhaustedAllowance, scenario != .exhaustedAllowance {
            store.access.plan = .sponsored
            store.access.stylingUsedToday = 0
            store.commit(inventoryChanged: false)
        }
        if old == .syncConflict, scenario != .syncConflict {
            store.sync.status = .upToDate
            store.sync.conflicts = []
            store.commit(inventoryChanged: false)
        }
    }

    /// Resets the demo store and session state (development only).
    func resetDemo() {
        style.generationTask?.cancel()
        style.cancelImageTasks()
        store.resetToFixtures()
        style.draft = StyleRequestDraft()
        style.current = nil
        style.historyOffer = nil
        style.phase = .idle
        style.imageJobs = [:]
        style.previewByOutfit = [:]
        style.earlierPreviewOutfitIDs = []
        editor = nil
        pendingEditorOpen = nil
        paths = [:]
        dispatch.reset()
        scenario = .normal
        showToast("Demo data reset.", style: .info)
    }

    /// Simulated On Me setup for demos: placeholder reference + permission.
    func enableSimulatedOnMe() {
        store.updateProfile {
            $0.onMeReference = .simulatedReference(version: ($0.onMeReference.version ?? 0) + 1, addedAt: .now)
            $0.permissions[.onMeImages] = .allowed
        }
    }
}

// MARK: - Purchase screens (simulated, Demo Controls)

extension AppModel {
    /// Opens the screen that fits a blocked picture: the paywall without a plan,
    /// the out-of-pictures choices with one.
    func presentPictureOptions() {
        purchaseSheet = store.access.plan.hasStylingAccess ? .outOfPictures : .paywall(.picture)
    }

    /// Simulated App Store confirmation of the free month. Nothing is charged.
    func purchasesStartTrial() {
        let wasExpired = store.access.plan == .expired
        store.settingsSimulatePlan(wasExpired ? .subscribed : .trialActive)
        purchaseSheet = nil
        showToast(wasExpired ? "Simulated: subscribed again. Nothing was charged." : "Simulated: free month started. Nothing was charged.", style: .info)
    }

    /// Simulated pack purchase. Nothing is charged.
    func purchasesBuy(_ pack: SampleImagePack) {
        store.purchasesAddImageCredits(pack.pictures)
        purchaseSheet = nil
        showToast("Simulated: \(pack.pictures) pictures added. Nothing was charged.", style: .info)
    }
}
