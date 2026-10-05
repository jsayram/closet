import SwiftUI

// MARK: - Explicit garment actions (store rule + honest acknowledgement)

/// Closet-prefixed wrappers that call the canonical `DemoStore` rules and then
/// acknowledge the result truthfully, with Undo where the change is reversible.
/// None of these dispatch a stylist, image, search or photo service.
extension AppModel {
    func closetMarkClean(_ id: String) {
        guard let garment = store.garment(id) else { return }
        if store.markClean(id) {
            showUndoToast("\(garment.displayName) is clean and Available again.")
        } else {
            showToast("Only a Dirty item you own (and that has arrived) can be marked clean.", style: .info)
        }
    }

    func closetMarkDirty(_ id: String) {
        guard let garment = store.garment(id), garment.isCurrentlyOwned, garment.availability != .archived, garment.availability != .dirty else { return }
        let prior = garment.availability
        let priorUntil = garment.unavailableUntil
        store.markDirty(id)
        guard let revision = store.garment(id)?.availabilityRevision else { return }
        let name = garment.displayName
        showToast("\(name) is marked Dirty. It's left out of new looks until you mark it clean.", actionTitle: "Undo") { [weak self] in
            guard let self else { return }
            guard let now = self.store.garment(id), now.availabilityRevision == revision, now.availability == .dirty else {
                self.showToast("\(name) changed since, so undo was skipped.", style: .info)
                return
            }
            if prior == .unavailable {
                self.store.setUnavailable(id, until: priorUntil)
            } else {
                self.store.setAvailable(id)
            }
            self.showToast("\(name) is \(prior.label) again.", style: .info)
        }
    }

    func closetMarkUnavailable(_ id: String, until: Date?) {
        guard let garment = store.garment(id), garment.isCurrentlyOwned, garment.availability != .archived else { return }
        let prior = garment.availability
        store.setUnavailable(id, until: until)
        guard let revision = store.garment(id)?.availabilityRevision else { return }
        let name = garment.displayName
        let when = until.map { " until \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""
        let text = "\(name) is Unavailable\(when). It's left out of new looks."
        guard prior == .available else {
            showToast(text)
            return
        }
        showToast(text, actionTitle: "Undo") { [weak self] in
            guard let self else { return }
            guard let now = self.store.garment(id), now.availabilityRevision == revision else {
                self.showToast("\(name) changed since, so undo was skipped.", style: .info)
                return
            }
            self.store.setAvailable(id)
            self.showToast("\(name) is Available again.", style: .info)
        }
    }

    func closetMarkAvailable(_ id: String) {
        guard let garment = store.garment(id), garment.availability == .unavailable else { return }
        store.setAvailable(id)
        showToast("\(garment.displayName) is Available. Ownership and arrival didn't change.")
    }

    func closetArchive(_ id: String) {
        guard let garment = store.garment(id), garment.availability != .archived, !garment.isTrashed else { return }
        store.archive(id)
        let name = garment.displayName
        showToast("\(name) is archived and put away with its history. It's left out of new looks.", actionTitle: "Unarchive") { [weak self] in
            guard let self, self.store.garment(id)?.availability == .archived else { return }
            self.showToast(self.store.unarchive(id), style: .info)
        }
    }

    func closetUnarchive(_ id: String) {
        guard store.garment(id)?.availability == .archived else { return }
        let message = store.unarchive(id)
        showToast(message.isEmpty ? "Unarchived." : message, style: .info)
    }

    func closetMarkNoLongerOwned(_ id: String) {
        guard let garment = store.garment(id), garment.ownership != .noLongerOwned, !garment.isTrashed else { return }
        store.markNoLongerOwned(id)
        showUndoToast("\(garment.displayName) is marked no longer owned. Photos, names and past looks are kept.")
    }

    func closetOwnAgain(_ id: String) {
        guard store.garment(id)?.ownership == .noLongerOwned else { return }
        let message = store.ownAgain(id)
        showToast(message, style: .info)
    }

    func closetMoveToTrash(_ id: String) {
        guard let garment = store.garment(id), !garment.isTrashed else { return }
        store.moveToTrash(id)
        let name = garment.displayName
        showToast("\(name) moved to Trash. You can restore it for 30 days.", actionTitle: "Restore") { [weak self] in
            guard let self, self.store.garment(id)?.isTrashed == true else { return }
            self.store.restoreFromTrash(id)
            self.showToast("\(name) is restored with its links to looks and suitcases.", style: .info)
        }
    }

    func closetRestore(_ id: String) {
        guard let garment = store.garment(id), garment.isTrashed else { return }
        store.restoreFromTrash(id)
        let status = store.garment(id).map { BadgeKind.status(for: $0).map(\.text).joined(separator: ", ") } ?? ""
        showToast("\(garment.displayName) is restored with its links to looks and suitcases." + (status.isEmpty ? "" : " Status: \(status)."), style: .info)
    }

    func closetMarkArrived(_ id: String) {
        guard let garment = store.garment(id), garment.ownership == .purchasedConfirmed, garment.arrival != .arrived else { return }
        store.markArrived(id)
        let status = store.garment(id)?.availability.label ?? Availability.available.label
        showToast("\(garment.displayName) arrived and is in your current closet. Status: \(status). Review it if that's not right.")
    }

    /// Explicit "I already own this" for a wishlist/inspiration record.
    func closetMarkOwned(_ id: String) {
        guard let garment = store.garment(id), !garment.isTrashed,
              garment.ownership == .wishlisted || garment.ownership == .inspiration else { return }
        let previous = garment.ownership
        store.updateGarment(id) { record in
            record.ownership = .owned
            record.ownershipRevision += 1
        }
        guard let revision = store.garment(id)?.ownershipRevision else { return }
        let name = garment.displayName
        showToast("\(name) is in your current closet as owned. Status: \(garment.availability.label). Add your photo any time.", actionTitle: "Undo") { [weak self] in
            guard let self else { return }
            guard let now = self.store.garment(id), now.ownershipRevision == revision, now.ownership == .owned else {
                self.showToast("\(name) changed since, so undo was skipped.", style: .info)
                return
            }
            self.store.updateGarment(id) { record in
                record.ownership = previous
                record.ownershipRevision += 1
            }
            self.showToast("\(name) is back in \(previous.label).", style: .info)
        }
    }

    func closetAddToSuitcase(_ id: String, suitcaseID: String) {
        let name = store.suitcase(suitcaseID)?.name ?? "the suitcase"
        let result = store.addMembers([id], to: suitcaseID)
        if !result.added.isEmpty {
            showToast("Added to \(name). It's the same garment, not a copy.")
        } else if !result.alreadyPresent.isEmpty {
            showToast("Already in \(name). Nothing changed.", style: .info)
        } else {
            showToast("Couldn't add to \(name). Items in Trash and archived suitcases can't be linked.", style: .error)
        }
    }

    func closetRemoveFromSuitcase(_ id: String, suitcaseID: String) {
        guard store.membership(garmentID: id, suitcaseID: suitcaseID) != nil else { return }
        let name = store.suitcase(suitcaseID)?.name ?? "the suitcase"
        store.removeMember(id, from: suitcaseID)
        showUndoToast("Removed from \(name). It's still in Main Closet.")
    }

    /// Reviewed, irreversible purge. Clears dangling references held by Closet and the Style Me draft.
    func closetDeletePermanently(_ id: String) {
        guard let garment = store.garment(id) else { return }
        let looks = store.deletionImpact(of: id).outfits.count
        store.deletePermanently(id)
        if closetUI.selectedGarmentID == id { closetUI.selectedGarmentID = nil }
        if style.draft.startingItemID == id { style.draft.startingItemID = nil }
        style.draft.overrideIDs.remove(id)
        let tail = looks == 0 ? "" : (looks == 1 ? " 1 saved look now shows a missing-piece placeholder." : " \(looks) saved looks now show a missing-piece placeholder.")
        showToast("\(garment.displayName) was deleted permanently.\(tail)", style: .info)
    }

    /// Sets the Style Me starting piece. Never styles anything by itself.
    func closetUseAsStartingPiece(_ id: String, forThisRequestOnly: Bool) {
        guard let garment = store.garment(id) else { return }
        let eligibility = store.eligibility(of: garment, scope: workingScope)
        if forThisRequestOnly {
            guard eligibility.canOverride else { return }
            style.draft.overrideIDs.insert(id)
        } else {
            guard eligibility.isEligible else { return }
        }
        // The previous starting piece's exception ends with it, as in Style Me's picker.
        if let old = style.draft.startingItemID, old != id { style.draft.overrideIDs.remove(old) }
        style.draft.startingItemID = id
        if case .secondary = sheet { sheet = nil }
        select(.styleMe)
        if forThisRequestOnly {
            let status = eligibility.issues.map(\.label).joined(separator: ", ")
            showToast("Starting piece: \(garment.displayName), for this request only. It stays marked \(status). Nothing is styled until you tap Style Me.", style: .info)
        } else {
            showToast("Starting piece: \(garment.displayName). Nothing is styled until you tap Style Me.", style: .info)
        }
    }

    /// Plain-language reason a garment can't start a look in the working source.
    func closetIneligibilityExplanation(_ garment: Garment, issues: [EligibilityIssue]) -> String {
        let source = workingScopeName
        let reasons = issues.map { issue -> String in
            switch issue {
            case .dirty: "it's marked Dirty"
            case .unavailable: "it's marked Unavailable"
            case .archived: "it's archived"
            case .notArrived: "it hasn't arrived yet"
            case .arrivalUnknown: "its arrival isn't confirmed"
            case .noLongerOwned: "you no longer own it"
            case .notOwned: garment.ownership == .inspiration ? "it's inspiration, not something you own" : "it's on your wishlist, not something you own"
            case .trashed: "it's in Trash"
            case .outsideSource: "it isn't linked to \(source)"
            }
        }
        let joined = ListFormatter.localizedString(byJoining: reasons)
        var text = "Can't start a look in \(source) right now: \(joined)."
        if issues.contains(.outsideSource) {
            text += " Switch to Main Closet, or add it to this suitcase below."
        } else if issues.contains(.dirty) {
            text += " Mark it clean, or use it for this request only."
        } else if issues.contains(.notArrived) || issues.contains(.arrivalUnknown) {
            text += " Mark it arrived first."
        }
        return text
    }
}

// MARK: - Confirmations

/// Actions that need an explicit confirmation before changing canonical state.
enum ClosetPendingAction: Identifiable, Hashable {
    case noLongerOwn(String)
    case moveToTrash(String)
    case markOwned(String)
    case useForThisRequest(String)

    var id: String {
        switch self {
        case let .noLongerOwn(id): "nlo-\(id)"
        case let .moveToTrash(id): "trash-\(id)"
        case let .markOwned(id): "owned-\(id)"
        case let .useForThisRequest(id): "override-\(id)"
        }
    }

    var garmentID: String {
        switch self {
        case let .noLongerOwn(id), let .moveToTrash(id), let .markOwned(id), let .useForThisRequest(id): id
        }
    }
}

/// Shared confirmation dialogs for context menus and the detail screen.
struct ClosetLifecycleConfirmations: ViewModifier {
    @Environment(AppModel.self) private var app
    @Binding var pending: ClosetPendingAction?

    func body(content: Content) -> some View {
        content.confirmationDialog(
            title,
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            titleVisibility: .visible,
            presenting: pending
        ) { action in
            buttons(for: action)
        } message: { action in
            Text(message(for: action))
        }
    }

    private func name(_ id: String) -> String { app.store.garment(id)?.displayName ?? "this item" }

    private var title: String {
        guard let pending else { return "" }
        let item = name(pending.garmentID)
        switch pending {
        case .noLongerOwn: return "Mark “\(item)” as no longer owned?"
        case .moveToTrash: return "Move “\(item)” to Trash?"
        case .markOwned: return "Do you already own “\(item)”?"
        case .useForThisRequest: return "Use “\(item)” for this request only?"
        }
    }

    private func message(for action: ClosetPendingAction) -> String {
        let id = action.garmentID
        switch action {
        case .noLongerOwn:
            return "Use this if you donated, sold or gave it away. Its photos, names and past looks are kept, and it's left out of today's styling. You can undo, or choose “I own this again” later."
        case .moveToTrash:
            let impact = app.store.deletionImpact(of: id)
            return "You can restore it for 30 days. After that it's deleted permanently: \(ClosetImpactText.summary(looks: impact.outfits.count, previews: impact.previews.count, suitcases: impact.suitcases.count)) To keep its history instead, archive it."
        case .markOwned:
            return "Only confirm if you actually have it. It joins your current closet as owned and can be used in looks. Nothing is bought or charged."
        case .useForThisRequest:
            let status = app.store.garment(id).map { app.store.eligibility(of: $0, scope: app.workingScope).issues.map(\.label).joined(separator: ", ") } ?? ""
            return "It stays marked \(status). The exception lasts only while it's your Style Me starting piece in \(app.workingScopeName). Ask Stylist and other suggestions still leave it out."
        }
    }

    @ViewBuilder private func buttons(for action: ClosetPendingAction) -> some View {
        let id = action.garmentID
        switch action {
        case .noLongerOwn:
            Button("No longer own") { app.closetMarkNoLongerOwned(id) }
        case .moveToTrash:
            Button("Move to Trash", role: .destructive) { app.closetMoveToTrash(id) }
            if let garment = app.store.garment(id), garment.isCurrentlyOwned, garment.availability != .archived {
                Button("Archive instead") { app.closetArchive(id) }
            }
        case .markOwned:
            Button("Yes, I own this") { app.closetMarkOwned(id) }
        case .useForThisRequest:
            Button("Use for this request") { app.closetUseAsStartingPiece(id, forThisRequestOnly: true) }
        }
        Button("Cancel", role: .cancel) {}
    }
}

extension View {
    func closetLifecycleConfirmations(_ pending: Binding<ClosetPendingAction?>) -> some View {
        modifier(ClosetLifecycleConfirmations(pending: pending))
    }
}

/// Wording for deletion consequences.
enum ClosetImpactText {
    static func summary(looks: Int, previews: Int, suitcases: Int) -> String {
        var parts: [String] = []
        if looks > 0 { parts.append(looks == 1 ? "1 saved look would show a missing piece" : "\(looks) saved looks would show a missing piece") }
        if previews > 0 { parts.append(previews == 1 ? "1 retained preview would be removed" : "\(previews) retained previews would be removed") }
        if suitcases > 0 { parts.append(suitcases == 1 ? "it would leave 1 suitcase" : "it would leave \(suitcases) suitcases") }
        if parts.isEmpty { return "nothing else changes, since no saved looks, previews or suitcases include it." }
        return ListFormatter.localizedString(byJoining: parts) + "."
    }
}
