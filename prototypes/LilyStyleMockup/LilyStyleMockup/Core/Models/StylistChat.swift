import Foundation
import Observation

/// Ask Stylist (FR-14): a lightweight, secondary chat surface for questions such
/// as "would white sneakers work?". Buttons remain the main way to style; chat is
/// optional. Chats are kept in memory only — raw conversation text is never
/// persisted, synced or indexed (PRD §11.11, §15.4).
enum StylistChatMode: String, CaseIterable, Identifiable, Hashable, Codable {
    case closetOnly, closetPlusIdeas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closetOnly: "Closet only"
        case .closetPlusIdeas: "Closet + new ideas"
        }
    }

    var detail: String {
        switch self {
        case .closetOnly: "Answers use only clothes you own in the current source."
        case .closetPlusIdeas: "May include one clearly labelled piece you don't own. Nothing is searched or bought."
        }
    }

    var systemImage: String {
        switch self {
        case .closetOnly: "cabinet"
        case .closetPlusIdeas: "lightbulb"
        }
    }
}

enum StylistChatRole: String, Hashable {
    case user, stylist, notice
}

struct StylistChatMessage: Identifiable, Hashable {
    let id = UUID()
    var role: StylistChatRole
    var text: String
    var outfit: Outfit?
    var followUps: [String] = []
    var createdAt = Date.now
}

/// Typed answer from the stylist contract (never free-form ownership claims).
struct StylistAnswer: Hashable {
    var text: String
    var outfit: Outfit?
    var followUps: [String]
}

/// In-memory chat session owned by `AppModel`, so it survives layout changes.
@Observable
final class StylistChatSession {
    var messages: [StylistChatMessage] = []
    var draftText = ""
    var mode: StylistChatMode = .closetOnly
    /// A look the question is about (from results, the editor or Saved).
    var attachedOutfit: Outfit?
    /// Answer message ID → the saved copy of its look, so reopening the chat can't save the same look twice.
    var savedLookIDs: [UUID: String] = [:]
    var isResponding = false
    @ObservationIgnored var task: Task<Void, Never>?
}
