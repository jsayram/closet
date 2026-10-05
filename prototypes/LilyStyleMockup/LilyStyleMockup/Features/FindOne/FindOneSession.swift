import SwiftUI
import Observation

// MARK: - Navigation inside the Find One sheet

/// Pushed screens inside the Find One sheet. Kept in the session (not @State) so
/// rotation, resizing and leaving/returning keep the same place.
enum FindOneRoute: Hashable {
    case handoff(ShoppingCandidate, visitID: String?)
    case purchase(PurchaseReviewContext)
}

// MARK: - Search lifecycle

enum FindOneSearchPhase: Equatable {
    case idle
    case searching(startedAt: Date)
    case ranking(startedAt: Date)
    case cancelled
    case notCompleted(String)
    /// The private fit comparison stopped; any public leads are kept.
    case rankingIncomplete(String)

    var isBusy: Bool {
        switch self {
        case .searching, .ranking: true
        default: false
        }
    }
}

/// Fit-relevant profile facts captured with a ranked search. Retailer, permission
/// or display-name edits don't make a fit comparison stale; these do.
struct FindOneFitSnapshot: Hashable {
    var measurements: [MeasurementFact]
    var fitReferences: [FitReference]
    var usualTopSize: String?
    var usualBottomSize: String?
    var preferredRise: String
    var preferredPantsLength: String
    var jacketLengthNote: String
    /// Cues and the rough size band. Holds no weight, so only a band change counts.
    var bodyFit: BodyFit

    init(_ profile: UserProfile) {
        measurements = profile.measurements
        fitReferences = profile.fitReferences
        usualTopSize = profile.usualTopSize
        usualBottomSize = profile.usualBottomSize
        preferredRise = profile.preferredRise
        preferredPantsLength = profile.preferredPantsLength
        jacketLengthNote = profile.jacketLengthNote
        bodyFit = profile.bodyFit
    }
}

/// One completed (simulated) search, captured with the exact public intent and
/// profile revision used. Never refreshed automatically.
struct FindOneSearchRecord: Hashable {
    var intent: PublicShoppingIntent
    var outcome: SearchOutcome
    /// Leads after hard-criteria checks (avoided stores, retailer-only), before ranking.
    var unrankedLeads: [ShoppingCandidate]
    /// What's displayed: ranked when private fit comparison ran, otherwise unranked.
    var leads: [ShoppingCandidate]
    var attempts: [SourceAttempt]
    var isRanked: Bool
    var profileRevision: Int
    var fitSnapshot: FindOneFitSnapshot?
    var hiddenAvoided: [String]
    var hiddenOutsidePreferred: [String]
    var completedAt: Date
    var rankedAt: Date?

    func isOverBudget(_ candidate: ShoppingCandidate) -> Bool {
        guard let budget = intent.budgetMax, let price = candidate.price else { return false }
        return price > Double(budget)
    }

    func isPreferred(_ candidate: ShoppingCandidate) -> Bool {
        intent.preferredRetailers.contains { $0.caseInsensitiveCompare(candidate.retailer) == .orderedSame }
    }

    var overBudgetCount: Int { leads.filter(isOverBudget).count }
}

/// Shown after returning from a (simulated) store page.
struct FindOneReturnPrompt: Hashable {
    var candidate: ShoppingCandidate
    var visitID: String?
}

// MARK: - Session

/// Everything one Find One request needs to survive rotation, resizing, leaving and
/// returning: the reviewed public intent, the explicit search task, results and
/// in-sheet navigation. Nothing here dispatches on its own.
@Observable
final class FindOneSession {
    let context: FindOneContext

    // Editable public intent (per request).
    var garment: String
    var color: String
    var budgetText: String
    var shipsTo: String
    /// "Add another store" draft, kept here so a layout change never loses it.
    var newStore = ""
    /// "Include my size range". Off by default and per request; turning it on never searches.
    var includesSizeRange = false

    var phase: FindOneSearchPhase = .idle
    var showsSlowNotice = false
    var record: FindOneSearchRecord?
    var path: [FindOneRoute] = []
    var openWorksWith: Set<String> = []
    var showsExcluded = false
    var showsOverBudget = false
    var returnPrompt: FindOneReturnPrompt?
    /// Open details rows, "More" texts and chip rows, by key. Kept here so rotation and
    /// the one-pane/two-pane switch don't close what she opened.
    var openDetails: Set<String> = []

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var watchdog: Task<Void, Never>?
    @ObservationIgnored private var didTimeOut = false

    init(context: FindOneContext, profile: UserProfile) {
        self.context = context
        garment = context.description
        color = context.colorFamily?.label ?? ""
        budgetText = profile.budgetMax.map(String.init) ?? ""
        shipsTo = profile.shippingCountry
    }

    var isBusy: Bool { phase.isBusy }

    /// Open state for one disclosure on this request's screen.
    func detailsBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDetails.contains(key) },
            set: { open in
                if open { self.openDetails.insert(key) } else { self.openDetails.remove(key) }
            }
        )
    }

    /// The reviewed public intent. No weight, measurements, photos, garment names or closet data.
    /// A size label is added only when she turns on "Include my size range".
    func intent(profile: UserProfile) -> PublicShoppingIntent {
        let digits = budgetText.filter(\.isNumber)
        let destination = shipsTo.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)
        return PublicShoppingIntent(
            garment: garment.trimmingCharacters(in: .whitespacesAndNewlines),
            color: trimmedColor.isEmpty ? nil : trimmedColor,
            budgetMax: Int(digits),
            shipsTo: destination.isEmpty ? profile.shippingCountry : destination,
            preferredRetailers: profile.retailers.filter { $0.isPreferred && !$0.isAvoided }.map(\.name),
            retailerOnly: profile.retailerOnlyMode,
            sizeRange: includesSizeRange ? Self.sizeRangeText(profile: profile) : nil
        )
    }

    /// Exact text "Include my size range" would add, e.g. "size M". Only the rough
    /// height-and-weight band qualifies; confirmed measurements are compared privately
    /// after the search and never added as numbers. Nil when there's nothing to add.
    static func sizeRangeText(profile: UserProfile) -> String? {
        profile.bodyFit.sizeRangeSearchText
    }

    /// The fit comparison used profile facts that have since changed.
    func profileChangedSinceRanking(_ profile: UserProfile) -> Bool {
        guard let record, record.isRanked else { return false }
        return record.profileRevision != profile.revision && record.fitSnapshot != FindOneFitSnapshot(profile)
    }

    /// The reviewed public intent differs from the one these results used.
    func intentChangedSinceSearch(_ profile: UserProfile) -> Bool {
        guard let record else { return false }
        return record.intent != intent(profile: profile)
    }

    // MARK: Explicit actions (the only dispatch points)

    /// Explicit Search button. Runs the public search, then — only if private fit
    /// comparison is allowed — the tool-free ranker. Repeated taps are ignored.
    func startSearch(app: AppModel) {
        guard !isBusy else { return }
        let profile = app.store.profile
        guard profile.permission(.webSearch) == .allowed else { return }
        // Metered discovery pauses with styling access; saved links and manual browsing stay free.
        guard app.store.access.plan.hasStylingAccess else { return }
        let intent = intent(profile: profile)
        guard !intent.garment.isEmpty else { return }
        let rankingAllowed = profile.permission(.fitRanking) == .allowed
        let context = context
        let started = Date.now
        begin(.searching(startedAt: started))

        task = Task { @MainActor [weak self] in
            do {
                let response = try await app.services.webSearch.search(intent)
                try Task.checkCancellation()
                let checked = Self.applyHardCriteria(response.leads, intent: intent, profile: profile)
                var leads = checked.kept
                var ranked = false
                var rankingError: Error?
                if rankingAllowed, !leads.isEmpty {
                    self?.phase = .ranking(startedAt: started)
                    do {
                        leads = try await app.services.ranker.rank(checked.kept, profile: Self.rankingProfile(profile), context: context)
                        try Task.checkCancellation()
                        leads = Self.applyRoughSizeEstimate(leads, bodyFit: profile.bodyFit)
                        ranked = true
                    } catch {
                        // The public search already finished: keep its leads, unranked and labelled.
                        leads = checked.kept
                        rankingError = error
                    }
                }
                var outcome = response.outcome
                if outcome == .resultsFound, checked.kept.isEmpty { outcome = .noMatchingResultsWithinSearch }
                self?.record = FindOneSearchRecord(
                    intent: intent, outcome: outcome, unrankedLeads: checked.kept, leads: leads,
                    attempts: response.attempts, isRanked: ranked, profileRevision: profile.revision,
                    fitSnapshot: ranked ? FindOneFitSnapshot(profile) : nil,
                    hiddenAvoided: checked.avoided, hiddenOutsidePreferred: checked.outside,
                    completedAt: .now, rankedAt: ranked ? .now : nil
                )
                self?.openWorksWith = []
                self?.showsExcluded = false
                // New results open short: only the form's own rows keep their state.
                self?.openDetails.formIntersection(["stores", "closetFirstEmpty", "searchCaption"])
                if let rankingError {
                    self?.finish(from: rankingError, rankingNote: "The leads found are shown unranked.")
                } else {
                    self?.finish(.idle)
                }
            } catch {
                self?.finish(from: error)
            }
        }
    }

    /// Explicit "Compare fit" / "Re-rank": runs only the tool-free ranker on the
    /// leads already found. Never re-runs the public search.
    func rank(app: AppModel) {
        guard !isBusy, let record, !record.unrankedLeads.isEmpty else { return }
        let profile = app.store.profile
        guard profile.permission(.fitRanking) == .allowed, app.store.access.plan.hasStylingAccess else { return }
        let context = context
        begin(.ranking(startedAt: .now))

        task = Task { @MainActor [weak self] in
            do {
                let fromRanker = try await app.services.ranker.rank(record.unrankedLeads, profile: Self.rankingProfile(profile), context: context)
                try Task.checkCancellation()
                let ranked = Self.applyRoughSizeEstimate(fromRanker, bodyFit: profile.bodyFit)
                guard var current = self?.record else { return }
                current.leads = ranked
                current.isRanked = true
                current.profileRevision = profile.revision
                current.fitSnapshot = FindOneFitSnapshot(profile)
                current.rankedAt = .now
                self?.record = current
                self?.finish(.idle)
            } catch {
                self?.finish(from: error, rankingNote: "Your results are unchanged.")
            }
        }
    }

    func cancel() {
        guard isBusy else { return }
        task?.cancel()
    }

    // MARK: Lifecycle helpers

    private func begin(_ phase: FindOneSearchPhase) {
        self.phase = phase
        showsSlowNotice = false
        didTimeOut = false
        watchdog?.cancel()
        // Local timer only: useful status by 10 s, then a 30 s aggregate deadline.
        watchdog = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled, let self, self.isBusy else { return }
            self.showsSlowNotice = true
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            guard !Task.isCancelled, self.isBusy else { return }
            self.didTimeOut = true
            self.task?.cancel()
        }
    }

    private func finish(_ phase: FindOneSearchPhase) {
        watchdog?.cancel()
        watchdog = nil
        task = nil
        showsSlowNotice = false
        self.phase = phase
    }

    /// Maps an error to an honest phase. `rankingNote` marks a ranking-only stop.
    private func finish(from error: Error, rankingNote: String? = nil) {
        let cancelled = error is CancellationError || (error as? ServiceError) == .cancelled
        let reason: String
        if didTimeOut {
            reason = "It passed the 30-second limit, so it was stopped. Nothing was invented."
        } else if cancelled {
            reason = "You cancelled it."
        } else {
            reason = error.localizedDescription
        }
        if let rankingNote {
            finish(.rankingIncomplete("\(reason) \(rankingNote)"))
        } else if cancelled, !didTimeOut {
            finish(.cancelled)
        } else {
            finish(.notCompleted(reason))
        }
    }

    // MARK: Hard criteria (validated on device after search)

    /// Avoided stores are always removed; with "Only these retailers" on, other stores are removed too.
    /// Preferred flags are recomputed from the reviewed intent, not trusted from the lead.
    static func applyHardCriteria(_ leads: [ShoppingCandidate], intent: PublicShoppingIntent, profile: UserProfile)
        -> (kept: [ShoppingCandidate], avoided: [String], outside: [String]) {
        let avoided = Set(profile.retailers.filter(\.isAvoided).map { $0.name.lowercased() })
        let preferred = Set(intent.preferredRetailers.map { $0.lowercased() })
        var kept: [ShoppingCandidate] = []
        var hiddenAvoided: [String] = []
        var hiddenOutside: [String] = []
        for lead in leads {
            let key = lead.retailer.lowercased()
            if avoided.contains(key) {
                hiddenAvoided.append(lead.retailer)
            } else if intent.retailerOnly, !preferred.contains(key) {
                hiddenOutside.append(lead.retailer)
            } else {
                var copy = lead
                copy.isPreferredRetailer = preferred.contains(key)
                kept.append(copy)
            }
        }
        return (kept, hiddenAvoided, hiddenOutside)
    }

    // MARK: Rough size estimate (on this device, after ranking)

    /// The profile handed to the fit ranker. Raw weight is never sent to it.
    static func rankingProfile(_ profile: UserProfile) -> UserProfile {
        var copy = profile
        copy.weight = nil
        return copy
    }

    /// Only when BodyFit falls back to the height-and-weight band: notes the estimate on
    /// leads that already need fit confirmation and orders those leads by how close the
    /// listed size is to the band. It never moves a lead between fit groups, never sets a
    /// recommended size and never excludes anything. Snippet-only leads and shoes or
    /// accessories are left as they are.
    static func applyRoughSizeEstimate(_ leads: [ShoppingCandidate], bodyFit: BodyFit) -> [ShoppingCandidate] {
        guard bodyFit.source == .heightAndWeightEstimate, let band = bodyFit.estimatedBand else { return leads }
        let clothing: Set<GarmentCategory> = [.top, .bottom, .dress, .layer]
        var result = leads
        var needsSlots: [Int] = []
        for (index, lead) in leads.enumerated() where lead.fitState == .needsFitConfirmation {
            needsSlots.append(index)
            guard clothing.contains(lead.kind.defaultCategory), let size = lead.listedSize,
                  !lead.evidence.contains(where: { $0.sourceType == .snippet }) else { continue }
            result[index].sizeEstimate = LeadSizeEstimate(bandLabel: band.label, listedSize: size,
                                                          distance: letterDistance(size, band: band))
        }
        // Closest listed size first; leads that can't be placed keep the ranker's order after them.
        let reordered = needsSlots.map { result[$0] }.enumerated().sorted { a, b in
            let aDistance = a.element.sizeEstimate?.distance ?? Int.max
            let bDistance = b.element.sizeEstimate?.distance ?? Int.max
            return aDistance != bDistance ? aDistance < bDistance : a.offset < b.offset
        }
        for (slot, entry) in zip(needsSlots, reordered) { result[slot] = entry.element }
        return result
    }

    /// Reads labels like "XS Regular" by their leading letter size. Numeric sizes stay nil.
    private static func letterDistance(_ size: String, band: BodyFit.SizeBand) -> Int? {
        if let distance = BodyFit.sizeDistance(listingSize: size, to: band) { return distance }
        guard let first = size.split(separator: " ").first, first.count < size.count else { return nil }
        return BodyFit.sizeDistance(listingSize: String(first), to: band)
    }
}

// MARK: - Bought-item review draft

enum FindOnePurchaseChoice: String, CaseIterable, Identifiable, Hashable {
    case ordered, bought
    var id: String { rawValue }
    var title: String { self == .ordered ? "I ordered this" : "I bought this" }
    var systemImage: String { self == .ordered ? "shippingbox" : "bag" }
}

/// Bought-item review draft, kept in UI state so rotation or a keyboard never loses it.
@Observable
final class FindOnePurchaseDraft {
    var choice: FindOnePurchaseChoice?
    var name: String
    var size: String
    var colorName: String
    var colorHex: String?
    var arrival: ArrivalState?
    var photoData: Data?
    var reminders: Set<ReminderKind> = []
    var usesReminderDate = false
    var reminderDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    var savedGarmentID: String?
    var saveMessage: String?
    var saveError: String?
    var outfitMessage: String?
    var suitcaseMessage: String?

    init(name: String, size: String = "", colorName: String, colorHex: String?) {
        self.name = name
        self.size = size
        self.colorName = colorName
        self.colorHex = colorHex
    }
}

// MARK: - Saved products filter

enum FindOneFinishFilter: String, CaseIterable, Identifiable, Hashable {
    case reminders, needsDetails, notArrived
    var id: String { rawValue }
    var title: String {
        switch self {
        case .reminders: "Reminders"
        case .needsDetails: "Needs details"
        case .notArrived: "Not arrived"
        }
    }
}
