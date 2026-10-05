import Foundation

// MARK: - Suitcases and scope

struct Suitcase: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var isArchived: Bool = false
    var revision: Int = 1
    var createdAt: Date = .now
}

/// One canonical garment ↔ suitcase link. Membership never copies the garment.
struct SuitcaseMembership: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var suitcaseID: String
    var garmentID: String
    var revision: Int = 1
    var addedAt: Date = .now
}

/// The visible browsing/styling source: Main Closet or exactly one Suitcase.
enum WardrobeScope: Hashable, Codable {
    case mainCloset
    case suitcase(String)

    var suitcaseID: String? {
        if case let .suitcase(id) = self { return id }
        return nil
    }

    var isSuitcase: Bool { suitcaseID != nil }
}

/// Why browsing fell back to Main Closet, if it did. Fallback is browsing access
/// only; a deliberate source choice is still needed before broader styling.
enum ScopeFallbackReason: String, Codable, Hashable {
    case rememberedSuitcaseArchived
    case rememberedSuitcaseDeleted
    case rememberedSuitcaseUnresolved

    var explanation: String {
        switch self {
        case .rememberedSuitcaseArchived: "Your remembered suitcase was archived, so you're browsing Main Closet. Choose a source before styling."
        case .rememberedSuitcaseDeleted: "Your remembered suitcase was deleted, so you're browsing Main Closet. Choose a source before styling."
        case .rememberedSuitcaseUnresolved: "Your remembered suitcase hasn't finished loading. Browsing Main Closet until it's ready."
        }
    }
}

// MARK: - Eligibility

/// Reasons a garment is not eligible for today's owned styling.
enum EligibilityIssue: String, Codable, Hashable, CaseIterable {
    case dirty, unavailable, archived, notArrived, arrivalUnknown, noLongerOwned, notOwned, trashed, outsideSource

    var label: String {
        switch self {
        case .dirty: "Dirty"
        case .unavailable: "Unavailable"
        case .archived: "Archived"
        case .notArrived: "Not arrived"
        case .arrivalUnknown: "Arrival unknown"
        case .noLongerOwned: "No longer owned"
        case .notOwned: "Not owned"
        case .trashed: "In Trash"
        case .outsideSource: "Not in this suitcase"
        }
    }

    /// Issues a per-request "Use for this request" override can waive for a still-owned item.
    var isOverridable: Bool {
        switch self {
        case .dirty, .unavailable, .archived: true
        default: false
        }
    }
}

struct Eligibility: Hashable {
    var issues: [EligibilityIssue]
    var overridden: Bool = false

    var isEligible: Bool { issues.isEmpty || overridden }
    var canOverride: Bool { !issues.isEmpty && issues.allSatisfy(\.isOverridable) }

    static let eligible = Eligibility(issues: [])
}

/// Inventory views in Closet.
enum ClosetView: String, CaseIterable, Identifiable, Hashable, Codable {
    case current, wishlist, inspiration, notArrived, noLongerOwned, trash, all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .current: "Current"
        case .wishlist: "Wishlist"
        case .inspiration: "Inspiration"
        case .notArrived: "Not arrived"
        case .noLongerOwned: "No longer owned"
        case .trash: "Trash"
        case .all: "All items"
        }
    }
}

// MARK: - Laundry

enum LaundryScope: Hashable {
    case selected([String])
    case entireCloset
    case suitcase(String)
}

struct LaundryResult: Hashable {
    var cleanedIDs: [String]
    var skipped: [(id: String, reason: String)]

    static func == (lhs: LaundryResult, rhs: LaundryResult) -> Bool {
        lhs.cleanedIDs == rhs.cleanedIDs && lhs.skipped.map(\.id) == rhs.skipped.map(\.id)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(cleanedIDs)
        hasher.combine(skipped.map(\.id))
    }
}

/// A reviewed laundry target captured before confirmation, so the commit can
/// recheck ownership/availability/membership revisions and skip changed items.
struct LaundryTarget: Hashable, Codable {
    var garmentID: String
    var ownershipRevision: Int
    var availabilityRevision: Int
    var membershipRevision: Int?
}

struct MembershipAddResult: Hashable {
    var added: [String] = []
    var alreadyPresent: [String] = []
    var skipped: [String] = []
}
