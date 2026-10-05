import SwiftUI

/// A local "Works with my closet" example: the unowned candidate plus real,
/// eligible recorded garments from the captured source.
struct FindOneCombination: Identifiable, Hashable {
    var garments: [Garment]
    var id: String { garments.map(\.id).joined(separator: "+") }
}

struct FindOneCompatibility: Hashable {
    var combinations: [FindOneCombination]
    /// Slots with no eligible item in the source, when no complete look was possible.
    var missingSlots: [OutfitSlot]
}

// MARK: - Feature-prefixed store helpers
//
// Queries reuse DemoStore's eligibility rules. Mutations follow the same
// revision + commit() semantics as the existing store methods.

extension DemoStore {
    /// Closet first: eligible owned items for the slot within the captured source.
    func findOneOwnedAlternatives(for context: FindOneContext, excluding: Set<String>, limit: Int = 3) -> [Garment] {
        garments
            .filter { $0.category == context.slot.category && !excluding.contains($0.id) }
            .filter { eligibility(of: $0, scope: context.scope).isEligible }
            .sorted { a, b in
                let aColor = a.color?.family == context.colorFamily
                let bColor = b.color?.family == context.colorFamily
                if aColor != bColor { return aColor }
                let aKind = a.kind == context.kind
                let bKind = b.kind == context.kind
                if aKind != bKind { return aKind }
                return a.displayName < b.displayName
            }
            .prefix(limit)
            .map { $0 }
    }

    /// Up to `limit` distinct complete looks that use the candidate plus eligible
    /// recorded items in `scope`. Honest smaller counts; never invents pieces.
    func findOneCompatibility(for candidate: ShoppingCandidate, slot: OutfitSlot, scope: WardrobeScope, limit: Int = 3) -> FindOneCompatibility {
        let candidateSlot = OutfitSlot.slot(for: candidate.kind.defaultCategory) ?? slot
        let eligible = preflight(scope: scope).eligibleGarments
        func pool(_ s: OutfitSlot) -> [Garment] {
            eligible
                .filter { OutfitSlot.slot(for: $0.category) == s }
                .sorted { a, b in
                    let an = a.color?.family.isNeutral ?? false
                    let bn = b.color?.family.isNeutral ?? false
                    if an != bn { return an }
                    return a.displayName < b.displayName
                }
        }

        let plans: [[OutfitSlot]]
        switch candidateSlot {
        case .top: plans = [[.bottom, .shoes]]
        case .bottom: plans = [[.top, .shoes]]
        case .dress: plans = [[.shoes]]
        case .layer, .accessory: plans = [[.top, .bottom, .shoes], [.dress, .shoes]]
        case .shoes: plans = [[.top, .bottom], [.dress]]
        }

        var missing: [OutfitSlot] = []
        var all: [[Garment]] = []
        for plan in plans {
            let pools = plan.map(pool)
            if let emptyIndex = pools.firstIndex(where: \.isEmpty) {
                if missing.isEmpty { missing.append(plan[emptyIndex]) }
                continue
            }
            all += Self.findOneCartesian(pools, cap: 240)
        }
        guard !all.isEmpty else { return FindOneCompatibility(combinations: [], missingSlots: missing) }

        // Prefer looks that don't reuse a piece already shown, then fill honestly.
        var picked: [[Garment]] = []
        var used = Set<String>()
        for combo in all where picked.count < limit {
            let ids = Set(combo.map(\.id))
            if ids.isDisjoint(with: used) {
                picked.append(combo)
                used.formUnion(ids)
            }
        }
        for combo in all where picked.count < limit {
            if !picked.contains(where: { $0.map(\.id) == combo.map(\.id) }) { picked.append(combo) }
        }
        return FindOneCompatibility(combinations: picked.map { FindOneCombination(garments: $0) }, missingSlots: [])
    }

    private static func findOneCartesian(_ pools: [[Garment]], cap: Int) -> [[Garment]] {
        var result: [[Garment]] = [[]]
        for pool in pools {
            var next: [[Garment]] = []
            for partial in result {
                for g in pool {
                    next.append(partial + [g])
                    if next.count >= cap { break }
                }
                if next.count >= cap { break }
            }
            result = next
        }
        return result
    }

    /// Removes a saved-for-later reference. It was never ownership, so nothing else changes.
    func findOneRemoveSavedProduct(_ id: String) {
        guard savedProducts.contains(where: { $0.id == id }) else { return }
        savedProducts.removeAll { $0.id == id }
        commit(inventoryChanged: false)
    }

    /// "Ordered or bought it?" was dismissed for this visit; it won't be asked again.
    func findOneDismissVisitPrompt(_ visitID: String) {
        guard let i = visits.firstIndex(where: { $0.id == visitID }), !visits[i].dismissedPrompt else { return }
        visits[i].dismissedPrompt = true
        commit(inventoryChanged: false)
    }

    /// Dismisses every open prompt for one product (used when she acts on it).
    func findOneDismissVisitPrompts(candidateID: String) {
        var changed = false
        for i in visits.indices where visits[i].candidate.id == candidateID && !visits[i].dismissedPrompt {
            visits[i].dismissedPrompt = true
            changed = true
        }
        if changed { commit(inventoryChanged: false) }
    }

    /// A record she already confirmed for this product, so a second "I bought this"
    /// updates it instead of creating a duplicate.
    func findOnePurchasedGarment(for candidate: ShoppingCandidate) -> Garment? {
        garments.first { g in
            !g.isTrashed && g.sourceURL == candidate.url && (g.ownership == .purchasedConfirmed || g.ownership == .owned)
        }
    }

    /// The latest visit recorded for a product, if any.
    func findOneLatestVisit(candidateID: String) -> ShoppingVisit? {
        visits.filter { $0.candidate.id == candidateID }.max { $0.openedAt < $1.openedAt }
    }

    /// Explicit purchase confirmation for an existing record (e.g. a Wishlist item):
    /// updates that canonical record instead of creating a duplicate.
    @discardableResult
    func findOneConfirmExistingPurchase(_ garmentID: String, name: String, color: GarmentColor?, size: String?,
                                        retailer: String?, url: String?, arrived: Bool,
                                        reminderKinds: Set<ReminderKind>) -> Garment? {
        guard let i = garments.firstIndex(where: { $0.id == garmentID }), !garments[i].isTrashed else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty { garments[i].displayName = trimmedName }
        if let color {
            if garments[i].color != color { garments[i].appearanceRevision += 1 }
            garments[i].color = color
        }
        if let size { garments[i].sizeLabel = size }
        if let retailer { garments[i].sourceRetailer = retailer }
        if let url { garments[i].sourceURL = url }
        garments[i].ownership = .purchasedConfirmed
        garments[i].ownershipRevision += 1
        garments[i].arrival = arrived ? .arrived : .notArrived
        garments[i].purchaseDate = .now
        garments[i].revision += 1
        for kind in reminderKinds where !reminders.contains(where: { $0.garmentID == garmentID && $0.kind == kind && ($0.status == .pending || $0.status == .deferred) }) {
            reminders.append(PurchaseReminder(garmentID: garmentID, kind: kind))
        }
        commit()
        return garments[i]
    }

    /// Attaches an original photo already written by PhotoStore (original-first).
    func findOneAttachPhoto(_ garmentID: String, filename: String) {
        updateGarment(garmentID, appearanceChanged: true) { g in
            if let old = g.photoFilename, old != filename { PhotoStore.delete(old) }
            g.photoFilename = filename
            g.imageKind = .actualPhoto
            g.processing = .originalOnly
        }
        findOneCompleteReminders(garmentID: garmentID, kind: .photo)
    }

    /// Marks open reminders of one kind complete for a garment.
    func findOneCompleteReminders(garmentID: String, kind: ReminderKind) {
        var changed = false
        for i in reminders.indices where reminders[i].garmentID == garmentID && reminders[i].kind == kind
            && (reminders[i].status == .pending || reminders[i].status == .deferred) {
            reminders[i].status = .completed
            changed = true
        }
        if changed { commit(inventoryChanged: false) }
    }

    /// Open reminders whose target still exists and can still be acted on.
    func findOneActiveReminders() -> [PurchaseReminder] {
        reminders.filter { r in
            guard r.status == .pending || r.status == .deferred, let g = garment(r.garmentID) else { return false }
            guard !g.isTrashed, g.ownership == .purchasedConfirmed || g.ownership == .owned else { return false }
            if r.kind == .arrival { return g.ownership == .purchasedConfirmed && g.arrival != .arrived }
            if r.kind == .photo { return g.photoFilename == nil }
            return true
        }
    }

    /// Purchased items still waiting for arrival confirmation.
    func findOneNotArrivedPurchases() -> [Garment] {
        garments
            .filter { !$0.isTrashed && $0.ownership == .purchasedConfirmed && $0.arrival != .arrived }
            .sorted { ($0.purchaseDate ?? $0.addedAt) > ($1.purchaseDate ?? $1.addedAt) }
    }
}

// MARK: - Small helpers

enum FindOneFormat {
    static func price(_ candidate: ShoppingCandidate) -> String {
        guard let price = candidate.price else { return "Price not listed" }
        return price.formatted(.currency(code: candidate.currency).precision(.fractionLength(price.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2)))
    }

    static func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }

    /// Nearest coarse color family for a listing hex (used only when no family is known).
    static func nearestFamily(hex: String) -> ColorFamily {
        func rgb(_ h: String) -> (Double, Double, Double) {
            var value: UInt64 = 0
            Scanner(string: h.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)).scanHexInt64(&value)
            return (Double((value >> 16) & 0xFF), Double((value >> 8) & 0xFF), Double(value & 0xFF))
        }
        let target = rgb(hex)
        return ColorFamily.allCases.filter { $0 != .multi }.min { a, b in
            let ca = rgb(a.swatchHex), cb = rgb(b.swatchHex)
            let da = pow(ca.0 - target.0, 2) + pow(ca.1 - target.1, 2) + pow(ca.2 - target.2, 2)
            let db = pow(cb.0 - target.0, 2) + pow(cb.1 - target.1, 2) + pow(cb.2 - target.2, 2)
            return da < db
        } ?? .multi
    }

    /// Fictional size options for the simulated store page. Not a size recommendation.
    static func sizeOptions(for kind: GarmentKind) -> [String] {
        switch kind.defaultCategory {
        case .bottom: ["00P", "0P", "2P", "4P", "6P"]
        case .top, .layer, .dress: ["XXS", "XS", "S", "M", "L"]
        case .shoes: ["5", "5.5", "6", "6.5", "7"]
        default: ["One size"]
        }
    }
}
