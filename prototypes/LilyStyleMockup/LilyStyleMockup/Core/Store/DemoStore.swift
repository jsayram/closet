import Foundation
import Observation

enum StoreError: LocalizedError {
    case saveFailed
    case notFound
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed: "Couldn't save on this device. Your previous saved version is unchanged and your draft is kept."
        case .notFound: "That item no longer exists."
        case let .invalid(message): message
        }
    }
}

/// A bounded undo entry. `apply` rechecks current revisions and returns a
/// user-facing result message; it never overwrites newer edits silently.
struct UndoEntry: Identifiable {
    let id = UUID()
    let label: String
    let apply: (DemoStore) -> String
}

/// Canonical local demo store: the single source of truth for garments,
/// suitcases, outfits, previews, profile and supporting records.
///
/// All mutations go through methods here so the PRD's rules (ownership vs.
/// availability, strict scope, laundry preconditions, deletion fences) live in
/// one place. No method here dispatches a mock AI/image/search service.
@Observable
final class DemoStore {
    // MARK: Persisted state
    var garments: [Garment] = []
    var suitcases: [Suitcase] = []
    var memberships: [SuitcaseMembership] = []
    var outfits: [Outfit] = []
    var collections: [OutfitCollection] = []
    var previews: [PreviewEntry] = []
    var history: [StylingHistoryEntry] = []
    var profile = UserProfile()
    var savedProducts: [SavedProductReference] = []
    var visits: [ShoppingVisit] = []
    var reminders: [PurchaseReminder] = []
    var ideas: [FeedbackIdea] = []
    var submissions: [MySubmission] = []
    var issueReports: [PrivateIssueReport] = []
    var access = AccessState()
    var sync = SyncState()
    /// Latest deliberate source selection, remembered across launches.
    var rememberedScope: WardrobeScope = .mainCloset
    var scopeFallback: ScopeFallbackReason?
    /// Set after an automatic fallback; broader styling needs a deliberate source choice.
    var awaitingSourceChoice: Bool = false
    var inventoryRevision: Int = 1
    var hasCompletedOnboarding: Bool = false
    /// Unsaved outfit-editor draft, written durably so it survives relaunch.
    var editorDraft: EditorDraftRecord?

    // MARK: Transient state
    var undoStack: [UndoEntry] = []
    var lastSaveError: String?
    /// Set by the scenario picker: explicit outfit saves fail (simulated low storage).
    var simulateSaveFailure = false
    var lastCommitAt: Date?

    init(snapshot: StoreSnapshot) {
        apply(snapshot)
    }

    static func loadOrFixtures() -> DemoStore {
        if let snapshot = StorePersistence.load() {
            return DemoStore(snapshot: snapshot)
        }
        let store = DemoStore(snapshot: DemoFixtures.snapshot())
        store.persist()
        return store
    }

    // MARK: Snapshot

    var snapshot: StoreSnapshot {
        StoreSnapshot(
            garments: garments, suitcases: suitcases, memberships: memberships, outfits: outfits,
            collections: collections, previews: previews, history: history, profile: profile,
            savedProducts: savedProducts, visits: visits, reminders: reminders, ideas: ideas,
            submissions: submissions, issueReports: issueReports, access: access, sync: sync,
            rememberedScope: rememberedScope, scopeFallback: scopeFallback,
            awaitingSourceChoice: awaitingSourceChoice, inventoryRevision: inventoryRevision,
            hasCompletedOnboarding: hasCompletedOnboarding, editorDraft: editorDraft
        )
    }

    func apply(_ s: StoreSnapshot) {
        garments = s.garments
        suitcases = s.suitcases
        memberships = s.memberships
        outfits = s.outfits
        collections = s.collections
        previews = s.previews
        history = s.history
        profile = s.profile
        savedProducts = s.savedProducts
        visits = s.visits
        reminders = s.reminders
        ideas = s.ideas
        submissions = s.submissions
        issueReports = s.issueReports
        access = s.access
        sync = s.sync
        rememberedScope = s.rememberedScope
        scopeFallback = s.scopeFallback
        awaitingSourceChoice = s.awaitingSourceChoice
        inventoryRevision = s.inventoryRevision
        hasCompletedOnboarding = s.hasCompletedOnboarding
        editorDraft = s.editorDraft
    }

    /// Writes the store durably. Returns false (and records the error) on failure.
    @discardableResult
    func persist() -> Bool {
        do {
            try StorePersistence.save(snapshot)
            lastCommitAt = .now
            lastSaveError = nil
            return true
        } catch {
            lastSaveError = "Couldn't write to this device's storage."
            return false
        }
    }

    /// Records a canonical change: bumps inventory revision, marks sync pending, persists.
    @discardableResult
    func commit(inventoryChanged: Bool = true) -> Bool {
        if inventoryChanged { inventoryRevision += 1 }
        if profile.iCloudSyncEnabled {
            switch sync.status {
            case let .pending(count): sync.status = .pending(count: count + 1)
            case .upToDate: sync.status = .pending(count: 1)
            default: break
            }
        }
        return persist()
    }

    func pushUndo(_ entry: UndoEntry) {
        undoStack.append(entry)
        if undoStack.count > 20 { undoStack.removeFirst(undoStack.count - 20) }
    }

    /// Applies the latest undo entry and returns its result message.
    @discardableResult
    func undoLast() -> String? {
        guard let entry = undoStack.popLast() else { return nil }
        let message = entry.apply(self)
        commit()
        return message
    }

    func resetToFixtures() {
        StorePersistence.eraseAll()
        apply(DemoFixtures.snapshot())
        undoStack.removeAll()
        persist()
    }

    // MARK: - Queries: garments

    func garment(_ id: String?) -> Garment? {
        guard let id else { return nil }
        return garments.first { $0.id == id }
    }

    private func index(of id: String) -> Int? { garments.firstIndex { $0.id == id } }

    func activeSuitcases() -> [Suitcase] { suitcases.filter { !$0.isArchived }.sorted { $0.createdAt < $1.createdAt } }
    func archivedSuitcases() -> [Suitcase] { suitcases.filter(\.isArchived) }
    func suitcase(_ id: String?) -> Suitcase? { suitcases.first { $0.id == id } }

    func memberIDs(of suitcaseID: String) -> Set<String> {
        Set(memberships.filter { $0.suitcaseID == suitcaseID }.map(\.garmentID))
    }

    func membership(garmentID: String, suitcaseID: String) -> SuitcaseMembership? {
        memberships.first { $0.garmentID == garmentID && $0.suitcaseID == suitcaseID }
    }

    func suitcases(containing garmentID: String) -> [Suitcase] {
        let ids = Set(memberships.filter { $0.garmentID == garmentID }.map(\.suitcaseID))
        return suitcases.filter { ids.contains($0.id) }
    }

    func scopeName(_ scope: WardrobeScope?) -> String {
        guard let scope else { return "Unknown source" }
        switch scope {
        case .mainCloset: return "Main Closet"
        case let .suitcase(id): return suitcase(id)?.name ?? "Former suitcase"
        }
    }

    /// Whether a garment is part of the source (Main Closet includes everything).
    func isInScope(_ garment: Garment, _ scope: WardrobeScope) -> Bool {
        switch scope {
        case .mainCloset: true
        case let .suitcase(id): memberIDs(of: id).contains(garment.id)
        }
    }

    /// Closet browsing list for a view and source, deduplicated by garment ID.
    func garments(view: ClosetView, scope: WardrobeScope) -> [Garment] {
        let inScope = garments.filter { isInScope($0, scope) }
        let filtered: [Garment]
        switch view {
        case .current:
            filtered = inScope.filter { !$0.isTrashed && ($0.ownership == .owned || ($0.ownership == .purchasedConfirmed && $0.arrival == .arrived)) }
        case .wishlist:
            filtered = inScope.filter { !$0.isTrashed && $0.ownership == .wishlisted }
        case .inspiration:
            filtered = inScope.filter { !$0.isTrashed && $0.ownership == .inspiration }
        case .notArrived:
            filtered = inScope.filter { !$0.isTrashed && $0.ownership == .purchasedConfirmed && $0.arrival != .arrived }
        case .noLongerOwned:
            filtered = inScope.filter { !$0.isTrashed && $0.ownership == .noLongerOwned }
        case .trash:
            filtered = inScope.filter(\.isTrashed)
        case .all:
            filtered = inScope.filter { !$0.isTrashed }
        }
        return filtered.sorted { ($0.category.rawValue, $0.displayName) < ($1.category.rawValue, $1.displayName) }
    }

    func dirtyGarments(scope: WardrobeScope) -> [Garment] {
        garments.filter { isInScope($0, scope) && $0.isCurrentlyOwned && $0.availability == .dirty }
    }

    // MARK: - Eligibility (the single rule source)

    /// Eligibility for today's owned styling in a source, with optional per-request overrides.
    func eligibility(of garment: Garment, scope: WardrobeScope, overrides: Set<String> = []) -> Eligibility {
        var issues: [EligibilityIssue] = []
        if garment.isTrashed { issues.append(.trashed) }
        switch garment.ownership {
        case .owned: break
        case .purchasedConfirmed:
            switch garment.arrival ?? .unknown {
            case .arrived: break
            case .notArrived: issues.append(.notArrived)
            case .unknown: issues.append(.arrivalUnknown)
            }
        case .noLongerOwned: issues.append(.noLongerOwned)
        case .inspiration, .wishlisted: issues.append(.notOwned)
        }
        if !isInScope(garment, scope) { issues.append(.outsideSource) }
        switch garment.availability {
        case .available: break
        case .dirty: issues.append(.dirty)
        case .unavailable: issues.append(.unavailable)
        case .archived: issues.append(.archived)
        }
        var result = Eligibility(issues: issues)
        if overrides.contains(garment.id), result.canOverride { result.overridden = true }
        return result
    }

    /// Complete-current-scope preflight over the whole source, not a page or shortlist.
    func preflight(scope: WardrobeScope, overrides: Set<String> = []) -> ScopePreflight {
        var eligible: [Garment] = []
        var excluded: [(Garment, [EligibilityIssue])] = []
        for garment in garments where isInScope(garment, scope) && !garment.isTrashed && garment.ownership != .inspiration && garment.ownership != .wishlisted {
            let e = eligibility(of: garment, scope: scope, overrides: overrides)
            if e.isEligible { eligible.append(garment) } else { excluded.append((garment, e.issues)) }
        }
        let ready = scope.suitcaseID.map { suitcase($0) != nil } ?? true
        return ScopePreflight(scope: scope, scopeName: scopeName(scope), eligibleGarments: eligible, excluded: excluded, isReady: ready)
    }

    /// Current-status issues for a saved/historical piece, resolved from canonical records.
    func currentIssues(for piece: OutfitPiece) -> [EligibilityIssue]? {
        guard let id = piece.garmentID else { return nil }
        guard let g = garment(id) else { return nil }
        return eligibility(of: g, scope: .mainCloset).issues
    }

    func isMissing(_ piece: OutfitPiece) -> Bool {
        guard let id = piece.garmentID else { return false }
        return garment(id) == nil
    }

    // MARK: - Garment mutations

    @discardableResult
    func addGarment(_ garment: Garment) -> Garment {
        var g = garment
        if garments.contains(where: { $0.id == g.id }) { g.id = UUID().uuidString }
        garments.append(g)
        commit()
        return g
    }

    func updateGarment(_ id: String, appearanceChanged: Bool = false, _ mutate: (inout Garment) -> Void) {
        guard let i = index(of: id) else { return }
        mutate(&garments[i])
        garments[i].revision += 1
        if appearanceChanged { garments[i].appearanceRevision += 1 }
        commit()
    }

    /// Individual Mark clean: only a currently owned, arrived, non-Trash Dirty record.
    @discardableResult
    func markClean(_ id: String) -> Bool {
        guard let i = index(of: id), garments[i].isCurrentlyOwned, garments[i].availability == .dirty else { return false }
        garments[i].availability = .available
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        let rev = garments[i].availabilityRevision
        let name = garments[i].displayName
        pushUndo(UndoEntry(label: "Mark \(name) clean") { store in
            guard let j = store.index(of: id), store.garments[j].availabilityRevision == rev else {
                return "\(name) changed since — undo skipped."
            }
            store.garments[j].availability = .dirty
            store.garments[j].availabilityRevision += 1
            return "\(name) is Dirty again."
        })
        commit()
        return true
    }

    func markDirty(_ id: String) {
        guard let i = index(of: id), garments[i].isOwnedOrPurchased, garments[i].availability != .archived else { return }
        garments[i].availability = .dirty
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        commit()
    }

    func setUnavailable(_ id: String, until: Date?) {
        guard let i = index(of: id) else { return }
        garments[i].availability = .unavailable
        garments[i].unavailableUntil = until
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        commit()
    }

    func setAvailable(_ id: String) {
        guard let i = index(of: id), garments[i].availability != .archived else { return }
        garments[i].availability = .available
        garments[i].unavailableUntil = nil
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        commit()
    }

    /// Gathers the complete reviewed set of cleanable items for a laundry action.
    func laundryTargets(for scope: LaundryScope) -> [LaundryTarget] {
        let candidates: [Garment]
        switch scope {
        case let .selected(ids): candidates = ids.compactMap { garment($0) }
        case .entireCloset: candidates = garments
        case let .suitcase(sid): candidates = garments.filter { memberIDs(of: sid).contains($0.id) }
        }
        var seen = Set<String>()
        return candidates.compactMap { g in
            guard !seen.contains(g.id), g.isCurrentlyOwned, g.availability == .dirty else { return nil }
            seen.insert(g.id)
            var target = LaundryTarget(garmentID: g.id, ownershipRevision: g.ownershipRevision, availabilityRevision: g.availabilityRevision)
            if case let .suitcase(sid) = scope { target.membershipRevision = membership(garmentID: g.id, suitcaseID: sid)?.revision }
            return target
        }
    }

    /// Commits a reviewed laundry action, skipping targets whose revisions or membership changed.
    func commitLaundry(_ targets: [LaundryTarget], scope: LaundryScope) -> LaundryResult {
        var cleaned: [String] = []
        var skipped: [(String, String)] = []
        var undoRevisions: [String: Int] = [:]
        for t in targets {
            guard let i = index(of: t.garmentID) else { skipped.append((t.garmentID, "Deleted")); continue }
            let g = garments[i]
            if case let .suitcase(sid) = scope {
                guard suitcase(sid)?.isArchived == false,
                      let m = membership(garmentID: g.id, suitcaseID: sid), m.revision == t.membershipRevision else {
                    skipped.append((g.id, "No longer in this suitcase")); continue
                }
            }
            guard g.ownershipRevision == t.ownershipRevision, g.isCurrentlyOwned else { skipped.append((g.id, "Ownership changed")); continue }
            guard g.availabilityRevision == t.availabilityRevision, g.availability == .dirty else { skipped.append((g.id, "Status changed since review")); continue }
            garments[i].availability = .available
            garments[i].availabilityRevision += 1
            garments[i].revision += 1
            undoRevisions[g.id] = garments[i].availabilityRevision
            cleaned.append(g.id)
        }
        if !cleaned.isEmpty {
            let count = cleaned.count
            pushUndo(UndoEntry(label: "Mark \(count) items clean") { store in
                var restored = 0
                var changed = 0
                for (id, rev) in undoRevisions {
                    guard let j = store.index(of: id), store.garments[j].availabilityRevision == rev else { changed += 1; continue }
                    store.garments[j].availability = .dirty
                    store.garments[j].availabilityRevision += 1
                    restored += 1
                }
                return changed == 0 ? "\(restored) items are Dirty again." : "\(restored) items are Dirty again; \(changed) changed since and were left as they are."
            })
            commit()
        }
        return LaundryResult(cleanedIDs: cleaned, skipped: skipped.map { (id: $0.0, reason: $0.1) })
    }

    func archive(_ id: String) {
        guard let i = index(of: id), garments[i].availability != .archived else { return }
        garments[i].statusBeforeArchive = garments[i].availability
        garments[i].availability = .archived
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        commit()
    }

    /// Removes only the archive restriction and restores the known prior status (e.g. Dirty stays Dirty).
    @discardableResult
    func unarchive(_ id: String) -> String {
        guard let i = index(of: id), garments[i].availability == .archived else { return "" }
        let prior = garments[i].statusBeforeArchive ?? .available
        garments[i].availability = prior
        garments[i].statusBeforeArchive = nil
        garments[i].availabilityRevision += 1
        garments[i].revision += 1
        commit()
        return prior == .available ? "Unarchived and available." : "Unarchived. It's still marked \(prior.label)."
    }

    func markNoLongerOwned(_ id: String) {
        guard let i = index(of: id), garments[i].ownership != .noLongerOwned else { return }
        let previous = garments[i].ownership
        let name = garments[i].displayName
        garments[i].ownership = .noLongerOwned
        garments[i].ownershipRevision += 1
        garments[i].revision += 1
        let rev = garments[i].ownershipRevision
        pushUndo(UndoEntry(label: "No longer own \(name)") { store in
            guard let j = store.index(of: id), store.garments[j].ownershipRevision == rev else { return "\(name) changed since — undo skipped." }
            store.garments[j].ownership = previous
            store.garments[j].ownershipRevision += 1
            return "\(name) is back in your current closet. Its status is still \(store.garments[j].availability.label)."
        })
        commit()
    }

    /// Explicit "I own this again". Availability is kept for review, never silently set to Available.
    @discardableResult
    func ownAgain(_ id: String) -> String {
        guard let i = index(of: id), garments[i].ownership == .noLongerOwned else { return "" }
        garments[i].ownership = .owned
        garments[i].ownershipRevision += 1
        garments[i].revision += 1
        commit()
        return "Back in your closet. Status: \(garments[i].availability.label) — review it if that's changed."
    }

    func markArrived(_ id: String) {
        guard let i = index(of: id), garments[i].ownership == .purchasedConfirmed else { return }
        garments[i].arrival = .arrived
        garments[i].revision += 1
        for r in reminders.indices where reminders[r].garmentID == id && reminders[r].kind == .arrival {
            reminders[r].status = .completed
        }
        commit()
    }

    func moveToTrash(_ id: String) {
        guard let i = index(of: id) else { return }
        garments[i].trashedAt = .now
        garments[i].revision += 1
        commit()
    }

    func restoreFromTrash(_ id: String) {
        guard let i = index(of: id) else { return }
        garments[i].trashedAt = nil
        garments[i].revision += 1
        commit()
    }

    /// What permanent deletion would affect (shown before confirming).
    func deletionImpact(of id: String) -> (outfits: [Outfit], previews: [PreviewEntry], suitcases: [Suitcase]) {
        (
            outfits.filter { $0.garmentIDs.contains(id) },
            previews.filter { $0.snapshotPieces.contains { $0.garmentID == id } },
            suitcases(containing: id)
        )
    }

    /// Permanently purges a garment: removes its record, memberships, photo and dependent previews,
    /// and leaves a content-free missing-piece placeholder in saved outfits.
    func deletePermanently(_ id: String) {
        guard let i = index(of: id) else { return }
        if let photo = garments[i].photoFilename { PhotoStore.delete(photo) }
        garments.remove(at: i)
        memberships.removeAll { $0.garmentID == id }
        previews.removeAll { $0.snapshotPieces.contains { $0.garmentID == id } }
        for o in outfits.indices {
            for p in outfits[o].pieces.indices where outfits[o].pieces[p].garmentID == id {
                outfits[o].pieces[p].capturedName = "Deleted item"
                outfits[o].pieces[p].capturedColor = nil
                outfits[o].pieces[p].capturedKind = .unknown
            }
        }
        for h in history.indices {
            if history[h].outfitSnapshot.garmentIDs.contains(id) { history[h].feedback = .rejected }
        }
        reminders.removeAll { $0.garmentID == id }
        undoStack.removeAll()
        commit()
    }

    // MARK: - Names and details

    func addAnnotation(_ id: String, kind: AnnotationKind, text: String, provenance: AnnotationProvenance = .userEntered) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = index(of: id) else { return }
        let normalized = trimmed.lowercased()
        if garments[i].annotations.contains(where: { $0.kind == kind && $0.text.lowercased() == normalized }) { return }
        if kind == .alias, garments[i].displayName.lowercased() == normalized { return }
        garments[i].annotations.append(GarmentAnnotation(kind: kind, text: trimmed, provenance: provenance))
        garments[i].revision += 1
        commit(inventoryChanged: false)
    }

    func removeAnnotation(_ id: String, annotationID: String) {
        guard let i = index(of: id) else { return }
        guard let removed = garments[i].annotations.first(where: { $0.id == annotationID }) else { return }
        garments[i].annotations.removeAll { $0.id == annotationID }
        garments[i].revision += 1
        pushUndo(UndoEntry(label: "Remove “\(removed.text)”") { store in
            guard let j = store.index(of: id) else { return "That item no longer exists." }
            store.garments[j].annotations.append(removed)
            return "Restored “\(removed.text)”."
        })
        commit(inventoryChanged: false)
    }

    /// Renaming never changes appearance inputs or retained previews.
    func rename(_ id: String, to newName: String, keepOldAsOtherName: Bool) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = index(of: id) else { return }
        let old = garments[i].displayName
        garments[i].displayName = trimmed
        if keepOldAsOtherName, old.lowercased() != trimmed.lowercased(),
           !garments[i].annotations.contains(where: { $0.kind == .alias && $0.text.lowercased() == old.lowercased() }) {
            garments[i].annotations.append(GarmentAnnotation(kind: .alias, text: old, provenance: .userEntered))
        }
        garments[i].revision += 1
        commit(inventoryChanged: false)
    }

    // MARK: - Suitcases

    @discardableResult
    func createSuitcase(named name: String) -> Suitcase {
        let s = Suitcase(id: "s-\(UUID().uuidString.prefix(8))", name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        suitcases.append(s)
        commit(inventoryChanged: false)
        return s
    }

    func renameSuitcase(_ id: String, to name: String) {
        guard let i = suitcases.firstIndex(where: { $0.id == id }) else { return }
        suitcases[i].name = name
        suitcases[i].revision += 1
        commit(inventoryChanged: false)
    }

    /// Adds existing canonical garments as members. Already-linked items are no-ops.
    func addMembers(_ garmentIDs: [String], to suitcaseID: String) -> MembershipAddResult {
        var result = MembershipAddResult()
        guard suitcase(suitcaseID)?.isArchived == false else {
            result.skipped = garmentIDs
            return result
        }
        for id in Array(NSOrderedSet(array: garmentIDs)) as? [String] ?? garmentIDs {
            guard let g = garment(id), !g.isTrashed else { result.skipped.append(id); continue }
            if membership(garmentID: id, suitcaseID: suitcaseID) != nil { result.alreadyPresent.append(id); continue }
            memberships.append(SuitcaseMembership(suitcaseID: suitcaseID, garmentID: id))
            result.added.append(id)
        }
        if !result.added.isEmpty { commit() }
        return result
    }

    func removeMember(_ garmentID: String, from suitcaseID: String) {
        guard let m = membership(garmentID: garmentID, suitcaseID: suitcaseID) else { return }
        memberships.removeAll { $0.id == m.id }
        let name = garment(garmentID)?.displayName ?? "Item"
        pushUndo(UndoEntry(label: "Remove \(name) from suitcase") { store in
            guard store.suitcase(suitcaseID) != nil, store.garment(garmentID) != nil else { return "Can't restore — the suitcase or item changed." }
            var restored = m
            restored.revision += 1
            store.memberships.append(restored)
            return "\(name) is back in the suitcase."
        })
        commit()
    }

    func archiveSuitcase(_ id: String, archived: Bool = true) {
        guard let i = suitcases.firstIndex(where: { $0.id == id }) else { return }
        suitcases[i].isArchived = archived
        suitcases[i].revision += 1
        if archived, rememberedScope == .suitcase(id) {
            rememberedScope = .mainCloset
            scopeFallback = .rememberedSuitcaseArchived
            awaitingSourceChoice = true
        }
        commit()
    }

    /// Deletes the container and its memberships; garments, outfits and previews are preserved.
    func deleteSuitcase(_ id: String) {
        guard let s = suitcase(id) else { return }
        suitcases.removeAll { $0.id == id }
        memberships.removeAll { $0.suitcaseID == id }
        for o in outfits.indices where outfits[o].capturedScope == .suitcase(id) {
            outfits[o].capturedScopeName = "Former suitcase (\(s.name))"
        }
        for p in previews.indices where previews[p].capturedScope == .suitcase(id) {
            previews[p].capturedScopeName = "Former suitcase (\(s.name))"
        }
        if rememberedScope == .suitcase(id) {
            rememberedScope = .mainCloset
            scopeFallback = .rememberedSuitcaseDeleted
            awaitingSourceChoice = true
        }
        commit()
    }

    /// A deliberate source choice: remembered across launches and clears any fallback.
    func selectScope(_ scope: WardrobeScope) {
        rememberedScope = scope
        scopeFallback = nil
        awaitingSourceChoice = false
        commit(inventoryChanged: false)
    }

    // MARK: - Outfits and collections

    func outfit(_ id: String?) -> Outfit? { outfits.first { $0.id == id } }
    var savedOutfits: [Outfit] { outfits.filter(\.isSaved).sorted { $0.updatedAt > $1.updatedAt } }

    /// Save updates the same outfit ID atomically; Save as Copy creates a new ID.
    @discardableResult
    func saveOutfit(_ outfit: Outfit, asCopy: Bool) throws -> Outfit {
        if simulateSaveFailure { throw StoreError.saveFailed }
        var o = outfit
        o.isSaved = true
        o.updatedAt = .now
        if asCopy {
            o.id = UUID().uuidString
            o.revision = 1
            o.title = o.title.hasSuffix("(copy)") ? o.title : o.title + " (copy)"
            o.createdAt = .now
            o.isFavorite = false
            outfits.append(o)
        } else if let i = outfits.firstIndex(where: { $0.id == o.id }) {
            o.revision = outfits[i].revision + 1
            outfits[i] = o
        } else {
            outfits.append(o)
        }
        guard commit(inventoryChanged: false) else { throw StoreError.saveFailed }
        return o
    }

    func deleteOutfit(_ id: String) {
        outfits.removeAll { $0.id == id }
        for c in collections.indices { collections[c].outfitIDs.removeAll { $0 == id } }
        commit(inventoryChanged: false)
    }

    func toggleFavorite(outfitID: String) {
        guard let i = outfits.firstIndex(where: { $0.id == outfitID }) else { return }
        outfits[i].isFavorite.toggle()
        commit(inventoryChanged: false)
    }

    /// Quiet optional wear log. Never changes laundry status.
    func markWorn(outfitID: String, on date: Date = .now) {
        guard let i = outfits.firstIndex(where: { $0.id == outfitID }) else { return }
        outfits[i].wornDates.append(date)
        commit(inventoryChanged: false)
    }

    func collection(_ id: String?) -> OutfitCollection? { collections.first { $0.id == id } }

    @discardableResult
    func createCollection(named name: String) -> OutfitCollection {
        let c = OutfitCollection(id: "c-\(UUID().uuidString.prefix(8))", name: name)
        collections.append(c)
        commit(inventoryChanged: false)
        return c
    }

    func renameCollection(_ id: String, to name: String) {
        guard let i = collections.firstIndex(where: { $0.id == id }) else { return }
        collections[i].name = name
        commit(inventoryChanged: false)
    }

    /// Removing a collection removes membership only; outfits/previews survive.
    func deleteCollection(_ id: String) {
        collections.removeAll { $0.id == id }
        commit(inventoryChanged: false)
    }

    func toggleOutfit(_ outfitID: String, inCollection collectionID: String) {
        guard let i = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        if collections[i].outfitIDs.contains(outfitID) {
            collections[i].outfitIDs.removeAll { $0 == outfitID }
        } else {
            collections[i].outfitIDs.append(outfitID)
        }
        commit(inventoryChanged: false)
    }

    func togglePreview(_ previewID: String, inCollection collectionID: String) {
        guard let i = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        if collections[i].previewIDs.contains(previewID) {
            collections[i].previewIDs.removeAll { $0 == previewID }
        } else {
            collections[i].previewIDs.append(previewID)
        }
        commit(inventoryChanged: false)
    }

    func collections(containingOutfit id: String) -> [OutfitCollection] { collections.filter { $0.outfitIDs.contains(id) } }
    func collections(containingPreview id: String) -> [OutfitCollection] { collections.filter { $0.previewIDs.contains(id) } }

    // MARK: - Retained previews

    func preview(_ id: String?) -> PreviewEntry? { previews.first { $0.id == id } }
    func previews(forOutfit id: String) -> [PreviewEntry] { previews.filter { $0.outfitID == id }.sorted { $0.createdAt > $1.createdAt } }

    /// Exact retained-output match for reuse (no new dispatch or units). A picture she disliked or one
    /// marked as an appearance mismatch is never reused automatically; it stays in her history.
    func retainedPreview(renderKey: String) -> PreviewEntry? {
        previews
            .filter { $0.renderKey == renderKey && !$0.isDisliked && $0.quality != .appearanceMismatch }
            .max { $0.createdAt < $1.createdAt }
    }

    /// Automatically retains a delivered preview. Idempotent by ID.
    func retainPreview(_ entry: PreviewEntry) {
        guard !previews.contains(where: { $0.id == entry.id }) else { return }
        previews.append(entry)
        commit(inventoryChanged: false)
    }

    func toggleFavorite(previewID: String) {
        guard let i = previews.firstIndex(where: { $0.id == previewID }) else { return }
        previews[i].isFavorite.toggle()
        commit(inventoryChanged: false)
    }

    /// Dislike changes preference, never retention.
    func setDisliked(previewID: String, _ disliked: Bool) {
        guard let i = previews.firstIndex(where: { $0.id == previewID }) else { return }
        previews[i].isDisliked = disliked
        commit(inventoryChanged: false)
    }

    /// Explicit user-directed deletion of one retained preview.
    func deletePreview(_ id: String) {
        previews.removeAll { $0.id == id }
        for c in collections.indices { collections[c].previewIDs.removeAll { $0 == id } }
        commit(inventoryChanged: false)
    }

    // MARK: - Styling history (structured)

    func recordHistory(_ outfit: Outfit, request: StyleRequest) {
        history.append(StylingHistoryEntry(
            outfitSnapshot: outfit, occasion: request.occasion, scope: request.scope, mode: request.mode,
            startingItemID: request.startingItemID,
            requiredColor: request.colorConstraint?.strength == .required ? request.colorConstraint?.family : nil,
            capturedAt: .now, comfort: request.effectiveComfort(profile: profile), fitBasis: profile.bodyFit.fingerprint
        ))
        commit(inventoryChanged: false)
    }

    /// Exact typed-intent history match whose pieces still pass current rules.
    /// Free text or unresolved constraints never produce an exact hit.
    func historyMatch(for request: StyleRequest) -> StylingHistoryEntry? {
        guard request.startingText.trimmingCharacters(in: .whitespaces).isEmpty || request.startingItemID != nil else { return nil }
        let required = request.colorConstraint?.strength == .required ? request.colorConstraint?.family : nil
        return history
            .filter { $0.feedback != .rejected }
            .filter { $0.occasion == request.occasion && $0.scope == request.scope && $0.mode == request.mode && $0.startingItemID == request.startingItemID && $0.requiredColor == required }
            .sorted { $0.capturedAt > $1.capturedAt }
            .first { entry in
                entry.outfitSnapshot.pieces.allSatisfy { piece in
                    guard let id = piece.garmentID, let g = garment(id) else { return false }
                    return eligibility(of: g, scope: request.scope, overrides: request.overrideIDs).isEligible
                } && meetsRequiredColor(entry.outfitSnapshot.pieces, request.colorConstraint)
            }
    }

    /// A required colour is a hard constraint: the piece in its scope (or any piece) must still match.
    private func meetsRequiredColor(_ pieces: [OutfitPiece], _ constraint: ColorConstraint?) -> Bool {
        guard let constraint, constraint.strength == .required else { return true }
        func family(_ p: OutfitPiece) -> ColorFamily? { p.garmentID.flatMap { garment($0)?.color?.family } ?? p.capturedColor?.family }
        if let slot = constraint.scope.slot { return pieces.contains { $0.slot == slot && family($0) == constraint.family } }
        return pieces.contains { family($0) == constraint.family }
    }

    /// Weather, season and fit differences a typed history match can't vouch for. Empty means the
    /// look can be shown as still matching today's requirements; otherwise it's an Earlier look.
    func historyChanges(_ entry: StylingHistoryEntry, for request: StyleRequest) -> [String] {
        var changes: [String] = []
        let comfort = request.effectiveComfort(profile: profile)
        if let made = entry.comfort, made != comfort {
            changes.append("It was made with \(made.label) comfort in mind, and today's comfort is \(comfort.label).")
        }
        if historyFitChanged(entry) {
            changes.append("Your fit details have changed since this look was made, so its fit notes no longer apply.")
        }
        let weather = request.weather
        let pieces = entry.outfitSnapshot.pieces
        func warmth(_ p: OutfitPiece) -> Int { p.garmentID.flatMap { garment($0)?.warmth } ?? 1 }
        if weather.needsLayer, !pieces.contains(where: { $0.slot == .layer }) {
            changes.append("Today is \(weather.temperatureF)°F (\(weather.condition.label.lowercased())) and this look has no layer.")
        }
        if weather.temperatureF >= 82, pieces.contains(where: { $0.slot != .shoes && warmth($0) >= 2 }) {
            changes.append("Today is \(weather.temperatureF)°F and this look has a warm piece.")
        }
        let madeIn = Season.from(date: entry.capturedAt)
        if madeIn != weather.season {
            changes.append("It was made in \(madeIn.label.lowercased()), and it's \(weather.season.label.lowercased()) now.")
        }
        return changes
    }

    /// True when the fit details behind a history look differ from today's. Older entries
    /// without a record count as unchanged.
    func historyFitChanged(_ entry: StylingHistoryEntry) -> Bool {
        entry.fitBasis.map { $0 != profile.bodyFit.fingerprint } ?? false
    }

    // MARK: - Profile

    func updateProfile(_ mutate: (inout UserProfile) -> Void) {
        mutate(&profile)
        profile.revision += 1
        commit(inventoryChanged: false)
    }

    func setPermission(_ purpose: ProcessingPurpose, _ state: PermissionState) {
        updateProfile { $0.permissions[purpose] = state }
    }

    // MARK: - Shopping, purchases, reminders

    func saveForLater(_ candidate: ShoppingCandidate, context: FindOneContext?) {
        guard !savedProducts.contains(where: { $0.candidate.id == candidate.id }) else { return }
        savedProducts.append(SavedProductReference(candidate: candidate, context: context))
        commit(inventoryChanged: false)
    }

    @discardableResult
    func recordVisit(_ candidate: ShoppingCandidate, context: FindOneContext?) -> ShoppingVisit {
        let v = ShoppingVisit(candidate: candidate, context: context)
        visits.append(v)
        commit(inventoryChanged: false)
        return v
    }

    /// Explicit "I ordered/bought this". Creates a PurchasedConfirmed record; not eligible until arrival.
    @discardableResult
    func confirmPurchase(name: String, kind: GarmentKind, color: GarmentColor?, size: String?, retailer: String?, url: String?,
                         arrived: Bool, reminderKinds: Set<ReminderKind>) -> Garment {
        var g = Garment(id: "g-\(UUID().uuidString.prefix(8))", displayName: name, category: kind.defaultCategory, kind: kind, color: color)
        g.sizeLabel = size
        g.ownership = .purchasedConfirmed
        g.arrival = arrived ? .arrived : .notArrived
        g.imageKind = .textOnly
        g.sourceRetailer = retailer
        g.sourceURL = url
        g.purchaseDate = .now
        garments.append(g)
        for kind in reminderKinds { reminders.append(PurchaseReminder(garmentID: g.id, kind: kind)) }
        commit()
        return g
    }

    func setReminder(_ id: String, status: ReminderStatus, dueDate: Date? = nil) {
        guard let i = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[i].status = status
        if let dueDate { reminders[i].dueDate = dueDate }
        commit(inventoryChanged: false)
    }

    // MARK: - Feedback (local simulation)

    func toggleVote(_ ideaID: String) {
        guard let i = ideas.firstIndex(where: { $0.id == ideaID }) else { return }
        ideas[i].hasVoted.toggle()
        ideas[i].votes += ideas[i].hasVoted ? 1 : -1
        commit(inventoryChanged: false)
    }

    func submitIdea(title: String, body: String) {
        submissions.append(MySubmission(title: title, body: body))
        commit(inventoryChanged: false)
    }

    func submitIssue(_ report: PrivateIssueReport) {
        issueReports.append(report)
        commit(inventoryChanged: false)
    }

    // MARK: - Access

    func consumeStylingUnit() {
        guard access.plan != .sponsored else { return }
        access.stylingUsedToday += 1
        commit(inventoryChanged: false)
    }

    func consumeSwapUnit() {
        guard access.plan != .sponsored else { return }
        access.swapsUsedToday += 1
        commit(inventoryChanged: false)
    }

    func consumeImageUnits(_ n: Int) {
        guard access.plan != .sponsored else { return }
        // Admission happens before dispatch; this only keeps the meter from showing more than the allowance.
        access.imageUnitsUsedThisMonth = min(access.imageUnitsUsedThisMonth + n, access.terms.monthlyImageAllowance)
        commit(inventoryChanged: false)
    }
}
