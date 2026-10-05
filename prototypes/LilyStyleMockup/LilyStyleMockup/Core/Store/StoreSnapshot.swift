import Foundation
import UIKit

/// Everything the resettable demo store persists. Fictional data only.
struct StoreSnapshot: Codable {
    var schemaVersion: Int = StoreSnapshot.currentSchema
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
    var rememberedScope: WardrobeScope = .mainCloset
    var scopeFallback: ScopeFallbackReason?
    var awaitingSourceChoice: Bool = false
    var inventoryRevision: Int = 1
    var hasCompletedOnboarding: Bool = false
    var editorDraft: EditorDraftRecord?

    static let currentSchema = 4
}

/// Local JSON persistence for the demo store. Writes are atomic; a failed
/// write never reports success.
enum StorePersistence {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("LilyStyleMockupDemo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var storeURL: URL { directory.appendingPathComponent("demo-store.json") }

    static func load() -> StoreSnapshot? {
        guard let data = try? Data(contentsOf: storeURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(StoreSnapshot.self, from: data),
              snapshot.schemaVersion == StoreSnapshot.currentSchema else { return nil }
        return snapshot
    }

    static func save(_ snapshot: StoreSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        try data.write(to: storeURL, options: [.atomic])
    }

    static func eraseAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// Stores user-selected photos (from PhotosPicker/paste/drop) as local files.
/// Fictional demo garments use illustrated artwork instead of photos.
enum PhotoStore {
    static var directory: URL {
        let dir = StorePersistence.directory.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves the original bytes first (original-first import). Returns the filename.
    static func saveOriginal(_ data: Data) throws -> String {
        let name = "photo-\(UUID().uuidString).img"
        try data.write(to: directory.appendingPathComponent(name), options: [.atomic])
        return name
    }

    static func image(named filename: String) -> UIImage? {
        UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }
}
