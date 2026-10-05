import Foundation
import Observation

enum StylePhase: Equatable {
    case idle
    case generating(requestID: String, startedAt: Date)
    case finished
}

/// A delivered stylist outcome with the exact request that produced it.
struct StyleOutcome: Identifiable {
    var request: StyleRequest
    var result: OutfitGenerationResult
    var deliveredAt: Date = .now
    var fromHistory: Bool = false
    var historyCapturedAt: Date?
    /// Set when the source or inputs changed after delivery. Results stay viewable as Earlier.
    var staleReason: String?

    var id: String { request.id }
}

/// A local history match found before any dispatch.
struct HistoryOffer: Identifiable {
    var entry: StylingHistoryEntry
    var request: StyleRequest
    var id: String { entry.id }
}

/// Style Me request/result state. Lives in `AppModel` so it survives
/// rotation, resizing, keyboard and navigation without re-dispatch.
@Observable
final class StyleSession {
    var draft = StyleRequestDraft()
    var phase: StylePhase = .idle
    var current: StyleOutcome?
    var historyOffer: HistoryOffer?
    var selectedOutfitID: String?
    /// Per-result-outfit image job status.
    var imageJobs: [String: ImageJobPhase] = [:]
    /// Current retained preview for each result outfit.
    var previewByOutfit: [String: String] = [:]
    /// Result outfits whose preview is now an Earlier version (after a swap).
    var earlierPreviewOutfitIDs: Set<String> = []
    /// Set by Style Me when results render inline beside the form (wide layouts),
    /// so Style Me doesn't also push a duplicate results screen.
    var resultsShownInline = false

    @ObservationIgnored var generationTask: Task<Void, Never>?
    /// One task per explicit picture request, so Cancel pictures can stop all of them.
    @ObservationIgnored var imageTasks: [UUID: Task<Void, Never>] = [:]

    var isGenerating: Bool {
        if case .generating = phase { return true }
        return false
    }

    var hasActiveImageJobs: Bool { imageJobs.values.contains { !$0.isTerminal } }

    func cancelImageTasks() {
        imageTasks.values.forEach { $0.cancel() }
        imageTasks.removeAll()
    }
}

enum EditorOrigin: Hashable, Codable {
    case result(outfitID: String)
    case saved(outfitID: String)
    case new
}

enum EditorSaveState: Equatable {
    case unsaved
    case saving
    case saved(Date)
    case failed(String)
}

/// Durable copy of an open editor draft, so meaningful work survives relaunch (FR-31).
struct EditorDraftRecord: Codable, Hashable {
    var origin: EditorOrigin
    var baseOutfit: Outfit
    var outfit: Outfit
    var scope: WardrobeScope
    var overrideIDs: Set<String>
    var previewID: String?
    var previewIsEarlier: Bool
    var savedAt: Date = .now
}

/// Working draft for one outfit. Committed versions only change on explicit Save.
@Observable
final class OutfitEditorSession: Identifiable {
    let id = UUID()
    var origin: EditorOrigin
    /// The last committed/delivered version (for Discard and change detection).
    var baseOutfit: Outfit
    var outfit: Outfit
    var undoStack: [Outfit] = []
    var redoStack: [Outfit] = []
    var selectedSlot: OutfitSlot?
    var colorFilter: ColorFamily?
    var saveState: EditorSaveState = .unsaved
    var draftRevision: Int = 0
    /// Working source captured for this draft (separate from the remembered preference).
    var scope: WardrobeScope
    /// Individually confirmed per-request overrides for Dirty/Unavailable/Archived items.
    var overrideIDs: Set<String> = []
    /// Preview currently associated with this draft, and whether it's now Earlier.
    var previewID: String?
    var previewIsEarlier = false
    var previewJob: ImageJobPhase?

    init(origin: EditorOrigin, outfit: Outfit, scope: WardrobeScope) {
        self.origin = origin
        self.baseOutfit = outfit
        self.outfit = outfit
        self.scope = scope
    }

    var hasUnsavedChanges: Bool {
        outfit.pieces.map(\.garmentID) != baseOutfit.pieces.map(\.garmentID)
            || outfit.pieces.map(\.capturedName) != baseOutfit.pieces.map(\.capturedName)
            || outfit.title != baseOutfit.title
            || outfit.notes != baseOutfit.notes
            || !outfit.isSaved
    }

    var record: EditorDraftRecord {
        EditorDraftRecord(origin: origin, baseOutfit: baseOutfit, outfit: outfit, scope: scope,
                          overrideIDs: overrideIDs, previewID: previewID, previewIsEarlier: previewIsEarlier)
    }

    convenience init(record: EditorDraftRecord) {
        self.init(origin: record.origin, outfit: record.baseOutfit, scope: record.scope)
        outfit = record.outfit
        overrideIDs = record.overrideIDs
        previewID = record.previewID
        previewIsEarlier = record.previewIsEarlier
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}
