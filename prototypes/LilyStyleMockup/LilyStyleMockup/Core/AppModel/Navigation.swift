import SwiftUI

/// Top-level destinations. Compact uses three tabs; wide iPad uses a sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable, Codable {
    case styleMe, closet, saved, feedback
    case search, suitcases, laundry, profile, settings, access, help, developer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .styleMe: "Style Me"
        case .closet: "Closet"
        case .saved: "Saved Looks"
        case .feedback: "Feedback"
        case .search: "Search"
        case .suitcases: "Suitcases"
        case .laundry: "Laundry"
        case .profile: "Profile"
        case .settings: "Settings"
        case .access: "Styling Access"
        case .help: "Help"
        case .developer: "Demo Controls"
        }
    }

    var systemImage: String {
        switch self {
        case .styleMe: "sparkles"
        case .closet: "cabinet"
        case .saved: "bookmark"
        case .feedback: "bubble.left.and.text.bubble.right"
        case .search: "magnifyingglass"
        case .suitcases: "suitcase"
        case .laundry: "washer"
        case .profile: "person.crop.circle"
        case .settings: "gearshape"
        case .access: "creditcard"
        case .help: "questionmark.circle"
        case .developer: "slider.horizontal.3"
        }
    }

    static let compactTabs: [AppSection] = [.styleMe, .closet, .saved]
    static let sidebarPrimary: [AppSection] = [.styleMe, .closet, .saved, .feedback]
    static let sidebarSecondary: [AppSection] = [.search, .suitcases, .laundry, .profile, .settings]

    var isCompactTab: Bool { Self.compactTabs.contains(self) }
}

enum SearchScopeHint: String, Hashable, Codable {
    case closet, saved, everything
}

/// Shared push routes. Every NavigationStack registers `AppRouteDestination`.
enum AppRoute: Hashable {
    case results
    case editor
    case garment(String)
    case suitcases
    case suitcase(String)
    case laundry
    case search(SearchScopeHint)
    case outfit(String)
    case preview(String)
    case collection(String)
    case profile
    case settings
    case access
    case help
    case releaseNotes
    case privacyData
    case developer
    case feedback
    case savedProducts
}

/// Prefill for Add Item (from a Find One purchase, a drop, a paste, or a suitcase).
struct AddGarmentPrefill: Hashable, Identifiable {
    var id = UUID()
    var name: String = ""
    var kind: GarmentKind = .unknown
    var colorFamily: ColorFamily?
    var droppedImageData: Data?
    var linkText: String?
    var intoSuitcaseID: String?
}

/// What Ask another stylist exports.
enum AskStylistTarget: Hashable {
    case outfit(Outfit)
    case garments([String])
}

/// Context for bought-item review.
struct PurchaseReviewContext: Hashable, Identifiable {
    var id = UUID()
    var candidate: ShoppingCandidate?
    var findOne: FindOneContext?
    var existingGarmentID: String?
}

/// Root-level sheets. Attached above the adaptive shell so they survive
/// compact ↔ regular layout changes.
enum AppSheet: Identifiable, Hashable {
    case addGarment(AddGarmentPrefill?)
    case findOne(FindOneContext)
    case storeHandoff(ShoppingCandidate, FindOneContext?)
    case purchaseReview(PurchaseReviewContext)
    case askStylist(AskStylistTarget)
    case onboarding
    /// Compact-width secondary destinations (Profile, Settings, Feedback, …).
    case secondary(AppSection)
    /// Ask Stylist chat (FR-14), a secondary surface.
    case stylistChat

    var id: String {
        switch self {
        case .addGarment: "addGarment"
        case let .findOne(c): "findOne-\(c.id)"
        case let .storeHandoff(c, _): "handoff-\(c.id)"
        case let .purchaseReview(c): "purchase-\(c.id)"
        case .askStylist: "askStylist"
        case .onboarding: "onboarding"
        case let .secondary(s): "secondary-\(s.rawValue)"
        case .stylistChat: "stylistChat"
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    enum Style { case success, info, error }

    let id = UUID()
    var text: String
    var style: Style = .success
    var actionTitle: String?
    var action: (() -> Void)?

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool { lhs.id == rhs.id }
}
