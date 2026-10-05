import SwiftUI

// MARK: - Navigation helpers (no services)

extension AppModel {
    /// The section whose navigation stack currently hosts the Settings screens:
    /// the compact secondary sheet's section, or the selected sidebar section.
    var settingsHostSection: AppSection {
        if case let .secondary(hosted)? = sheet { return hosted }
        return section
    }

    /// Resets the demo store and session (development only) while keeping the
    /// Settings / Privacy / Demo Controls stack the request came from, so its
    /// result can be shown in place instead of jumping back to the root.
    func settingsResetDemoKeepingPlace() {
        let host = settingsHostSection
        let kept = paths[host]
        resetDemo()
        if let kept { paths[host] = kept }
    }
}

// MARK: - Simulated sync, access and deletion bookkeeping

extension DemoStore {
    /// Number of records a first upload would include (simulated estimate).
    var settingsSyncableRecordCount: Int {
        garments.count + suitcases.count + memberships.count + outfits.count
            + collections.count + previews.count + history.count + 1
    }

    /// Photos the user added, plus demo items that stand in for her own photos.
    var settingsPhotoCount: Int {
        garments.filter { $0.photoFilename != nil || $0.imageKind == .actualPhoto }.count
    }

    /// Turns simulated private iCloud sync on or off. Local records are never touched.
    func settingsSetICloudSync(_ enabled: Bool) {
        guard profile.iCloudSyncEnabled != enabled else { return }
        profile.iCloudSyncEnabled = enabled
        if enabled {
            if let first = sync.conflicts.first {
                let name = garment(first.garmentID)?.displayName ?? "An item"
                sync.status = .conflict(description: "\(name) was edited on another device")
            } else {
                sync.status = .pending(count: settingsSyncableRecordCount)
            }
        } else {
            sync.status = .off
        }
        persist()
    }

    /// Explicit Retry after a simulated failure: queues the upload again.
    func settingsRetrySync() {
        guard profile.iCloudSyncEnabled, case .failed = sync.status else { return }
        sync.status = .pending(count: 1)
        persist()
    }

    /// Demo control: pretend iCloud acknowledged every pending change.
    func settingsSimulateSyncAcknowledged() {
        guard profile.iCloudSyncEnabled, sync.conflicts.isEmpty else { return }
        sync.status = .upToDate
        sync.lastAcknowledged = .now
        persist()
    }

    /// Demo control: pretend the next upload failed. Local data is unchanged.
    func settingsSimulateSyncFailure() {
        guard profile.iCloudSyncEnabled else { return }
        sync.status = .failed(reason: "iCloud storage is full")
        persist()
    }

    /// After a local Delete My Data, the matching iCloud deletion stays pending
    /// until iCloud is reachable (always simulated here).
    func settingsMarkCloudDeletionPending() {
        guard profile.iCloudSyncEnabled else { return }
        sync.status = .pending(count: 1)
        persist()
    }

    /// Demo-only access state change behind a clearly labelled simulated StoreKit review.
    func settingsSimulatePlan(_ plan: AccessPlan) {
        guard access.plan != plan else { return }
        access.plan = plan
        persist()
    }

    /// Demo control: clears today's simulated usage counters.
    func settingsResetUsage() {
        access.stylingUsedToday = 0
        access.swapsUsedToday = 0
        access.imageUnitsUsedThisMonth = 0
        persist()
    }

    /// Resolves one simulated sync conflict with the chosen device's value.
    ///
    /// For a Status conflict the chosen value is applied to the canonical garment through
    /// the store's own availability methods (markDirty, setAvailable, archive/unarchive,
    /// setUnavailable), so their ownership and archive rules still apply and the change
    /// shows everywhere. The conflict is cleared and the resolution is recorded as a
    /// pending upload. Returns a user-facing summary.
    @discardableResult
    func settingsResolveSyncConflict(_ conflictID: String, keepThisDevice: Bool) -> String {
        guard let conflict = sync.conflicts.first(where: { $0.id == conflictID }) else { return "" }
        let chosen = keepThisDevice ? conflict.thisDeviceValue : conflict.otherDeviceValue
        let name = garment(conflict.garmentID)?.displayName ?? "This item"

        // Clear the conflict first so the store method's commit records one pending
        // change (the resolution) instead of leaving the status on "conflict".
        sync.conflicts.removeAll { $0.id == conflictID }
        if let next = sync.conflicts.first {
            let nextName = garment(next.garmentID)?.displayName ?? "An item"
            sync.status = .conflict(description: "\(nextName) was edited on another device")
        } else {
            sync.status = profile.iCloudSyncEnabled ? .upToDate : .off
        }

        var applied = false
        var refused = false
        if conflict.field.caseInsensitiveCompare("Status") == .orderedSame,
           let target = Availability.allCases.first(where: { $0.label.caseInsensitiveCompare(chosen) == .orderedSame }),
           let current = garment(conflict.garmentID) {
            if current.availability != target {
                let id = conflict.garmentID
                if current.availability == .archived, target != .archived {
                    unarchive(id)
                }
                if garment(id)?.availability != target {
                    switch target {
                    case .dirty: markDirty(id)
                    case .available: setAvailable(id)
                    case .archived: archive(id)
                    case .unavailable: setUnavailable(id, until: nil)
                    }
                }
                applied = garment(id)?.availability == target
                refused = !applied
            }
        }
        if !applied { commit(inventoryChanged: false) }

        if refused {
            return "\(name) couldn't be set to \(chosen) because of its current ownership or archive state. The conflict is cleared; check the item in Closet."
        }
        if keepThisDevice {
            return "Kept this device: \(name) stays \(chosen). Your choice uploads when sync resumes (simulated)."
        }
        return "Used the other device: \(name) is now \(chosen) everywhere in your closet."
    }
}
