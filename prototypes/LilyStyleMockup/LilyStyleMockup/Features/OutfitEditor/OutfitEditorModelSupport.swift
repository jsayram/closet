import SwiftUI

/// Editor text fields. Both commit to the draft on Return / leaving the field,
/// never per keystroke, so each rename or note is one undoable edit.
enum OutfitEditorFocusField: Hashable {
    case title
    case notes
}

// MARK: - AppModel helpers (feature-prefixed)

extension AppModel {
    /// Records a notes edit with the same bounded undo semantics as `renameDraft`:
    /// the previous draft goes on the undo stack (max 20), redo is cleared and the
    /// draft is marked unsaved. Notes don't change the picture, so an existing
    /// preview is not relabelled Earlier. Dispatches nothing.
    func outfitEditorUpdateNotes(_ notes: String) {
        guard let editor, editor.outfit.notes != notes else { return }
        editor.undoStack.append(editor.outfit)
        if editor.undoStack.count > 20 { editor.undoStack.removeFirst() }
        editor.redoStack.removeAll()
        editor.outfit.notes = notes
        editor.draftRevision += 1
        if editor.saveState != .saving { editor.saveState = .unsaved }
        persistEditorDraft()
    }

    /// Save as Copy that keeps the open draft's own save state honest. The core
    /// `saveEditor(asCopy: true)` marks the draft `.saved` even though only the copy
    /// was written; the draft itself is unchanged, so its previous state comes back.
    /// Returns when the copy was written, or nil if the write failed.
    @discardableResult
    func outfitEditorSaveCopy() -> Date? {
        guard let editor else { return nil }
        let previous = editor.saveState
        saveEditor(asCopy: true)
        guard case let .saved(date) = editor.saveState else { return nil }
        switch previous {
        case .saved, .unsaved: editor.saveState = previous
        case .saving, .failed: editor.saveState = .unsaved
        }
        return date
    }

    /// Discard that also clears a stale "Couldn't save" state once the draft is back
    /// to its committed version (nothing is left unsaved to fail).
    func outfitEditorDiscardChanges() {
        discardEditorChanges()
        guard let editor, case .failed = editor.saveState, !editor.hasUnsavedChanges else { return }
        editor.saveState = .unsaved
    }

    /// Current canonical status badges for a board piece. Captured facts on the
    /// piece are never rewritten; these badges are resolved from the live record.
    func outfitEditorBoardBadges(for piece: OutfitPiece, editor: OutfitEditorSession) -> [BadgeKind] {
        if store.isMissing(piece) { return [.missing] }
        var badges = (store.currentIssues(for: piece) ?? []).map(BadgeKind.from)
        if let id = piece.garmentID, let garment = store.garment(id) {
            if !store.isInScope(garment, editor.scope), !badges.contains(.outsideSource) {
                badges.append(.outsideSource)
            }
            if editor.overrideIDs.contains(id),
               store.eligibility(of: garment, scope: editor.scope, overrides: editor.overrideIDs).overridden {
                badges.append(.usedThisRequest)
            }
        }
        return badges
    }

    /// Per-request exceptions that are actually in effect: the item still has an
    /// overridable issue (Dirty / Unavailable / Archived) and is allowed only here.
    func outfitEditorActiveOverrides(_ editor: OutfitEditorSession) -> [Garment] {
        editor.overrideIDs
            .compactMap { store.garment($0) }
            .filter { garment in
                let e = store.eligibility(of: garment, scope: editor.scope)
                return !e.isEligible && e.canOverride
            }
            .sorted { $0.displayName < $1.displayName }
    }
}

// MARK: - Session helpers

extension OutfitEditorSession {
    /// True when the draft differs from the last committed/delivered version.
    /// (Unlike `hasUnsavedChanges`, an unedited, never-saved result is not "edited".)
    var outfitEditorHasEditsSinceBase: Bool {
        outfit.pieces.map(\.garmentID) != baseOutfit.pieces.map(\.garmentID)
            || outfit.pieces.map(\.capturedName) != baseOutfit.pieces.map(\.capturedName)
            || outfit.title != baseOutfit.title
            || outfit.notes != baseOutfit.notes
    }

    /// Empty slots the user can fill: layer, shoes, accessory, and top/bottom when
    /// there's no dress (or a dress when the look has no top, bottom or dress).
    var outfitEditorEmptySlots: [OutfitSlot] {
        let filled = Set(outfit.pieces.map(\.slot))
        var slots: [OutfitSlot] = []
        if !filled.contains(.dress) {
            if !filled.contains(.top) { slots.append(.top) }
            if !filled.contains(.bottom) { slots.append(.bottom) }
            if !filled.contains(.top), !filled.contains(.bottom) { slots.append(.dress) }
        }
        for slot in [OutfitSlot.layer, .shoes, .accessory] where !filled.contains(slot) {
            slots.append(slot)
        }
        return slots.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - Copy and announcements

/// User-facing wording for eligibility, kept in one place so the board, picker and
/// summary say the same thing.
enum OutfitEditorCopy {
    /// Overridable issues only, e.g. "Dirty" or "Dirty and Archived".
    static func statusPhrase(_ issues: [EligibilityIssue]) -> String {
        let labels = issues.filter(\.isOverridable).map(\.label)
        return labels.isEmpty ? "unavailable" : labels.joined(separator: " and ")
    }

    /// Why a still-owned item is left out by default, and what a per-request use means.
    static func overridableExplanation(for garment: Garment) -> String {
        let note = garment.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        switch garment.availability {
        case .dirty:
            return "Dirty — left out of styling until it's clean, unless you choose to use it."
        case .unavailable:
            var text = "Unavailable"
            if let until = garment.unavailableUntil {
                text += " until \(until.formatted(date: .abbreviated, time: .omitted))"
            }
            if !note.isEmpty { text += " — \(note)" }
            return text + "."
        case .archived:
            return "Archived — kept out of styling unless you choose to use it."
        case .available:
            return ""
        }
    }

    /// Why an item can't be used even for one request.
    static func blockedReason(_ issues: [EligibilityIssue], scopeName: String) -> String {
        switch issues.first(where: { !$0.isOverridable }) {
        case .notArrived?: "Not arrived yet — confirm arrival in Closet before styling it."
        case .arrivalUnknown?: "Arrival isn't confirmed yet — confirm it in Closet first."
        case .noLongerOwned?: "No longer owned — kept for history only."
        case .notOwned?: "Not owned — wishlist and inspiration pieces can't be styled as yours."
        case .trashed?: "In Trash."
        case .outsideSource?: "Not in \(scopeName)."
        default: issues.map(\.label).joined(separator: ", ")
        }
    }

    /// Spoken confirmation for VoiceOver users.
    static func announce(_ text: String) {
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
