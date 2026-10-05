import Foundation

// MARK: - Styling access (sample terms, simulated)

enum AccessPlan: String, Codable, CaseIterable, Identifiable, Hashable {
    case trialEligible, trialActive, subscribed, complimentary, sponsored, expired

    var id: String { rawValue }

    var label: String {
        switch self {
        case .trialEligible: "Not subscribed — free trial available"
        case .trialActive: "Free trial (sample)"
        case .subscribed: "Monthly styling access (sample)"
        case .complimentary: "Complimentary access (sample)"
        case .sponsored: "Owner-sponsored access (sample)"
        case .expired: "Styling access expired"
        }
    }

    var hasStylingAccess: Bool {
        switch self {
        case .trialActive, .subscribed, .complimentary, .sponsored: true
        case .trialEligible, .expired: false
        }
    }
}

/// Configurable sample terms. Not a final price; clearly labelled as simulation.
struct SampleTerms: Codable, Hashable {
    var monthlyPriceLabel: String = "$9.99"
    var trialLabel: String = "1 month free"
    var dailyStylingAllowance: Int = 10
    var dailySwapAllowance: Int = 40
    var monthlyImageAllowance: Int = 30
}

/// A sample one-time picture pack. Sizes and prices are placeholders, not decided.
struct SampleImagePack: Identifiable, Hashable {
    var pictures: Int
    var priceLabel: String
    var perPictureLabel: String
    var tag: String?
    var id: Int { pictures }

    static let samples: [SampleImagePack] = [
        SampleImagePack(pictures: 10, priceLabel: "$1.99", perPictureLabel: "$0.20 each", tag: nil),
        SampleImagePack(pictures: 30, priceLabel: "$4.99", perPictureLabel: "$0.17 each", tag: "Most picked"),
        SampleImagePack(pictures: 75, priceLabel: "$9.99", perPictureLabel: "$0.13 each", tag: "Lowest per picture"),
    ]
}

/// The purchase screens shown when "Paywall and purchases" is on in Demo Controls.
enum PurchaseSheet: Identifiable, Hashable {
    /// What she was trying to do when the paywall came up.
    enum Trigger: String, Hashable { case styleMe, picture, findOne, settings }

    case paywall(Trigger)
    case imagePacks
    case outOfPictures

    var id: String {
        switch self {
        case let .paywall(trigger): "paywall-\(trigger.rawValue)"
        case .imagePacks: "imagePacks"
        case .outOfPictures: "outOfPictures"
        }
    }
}

struct AccessState: Codable, Hashable {
    var plan: AccessPlan = .sponsored
    var terms = SampleTerms()
    var stylingUsedToday: Int = 0
    var swapsUsedToday: Int = 0
    var imageUnitsUsedThisMonth: Int = 0
    /// Optional so snapshots saved before picture packs existed still load.
    var purchasedImageCredits: Int?
    var resetsAt: Date = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)

    var stylingRemaining: Int { max(0, terms.dailyStylingAllowance - stylingUsedToday) }
    var swapsRemaining: Int { max(0, terms.dailySwapAllowance - swapsUsedToday) }
    var imageUnitsRemaining: Int { max(0, terms.monthlyImageAllowance - imageUnitsUsedThisMonth) }
    /// Pictures bought in packs. They don't expire and are used after the monthly ones.
    var imageWallet: Int { purchasedImageCredits ?? 0 }
    /// When the monthly picture allowance starts again (sample: the first of next month).
    var imageResetsAt: Date {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .month, for: .now)?.end
        return start ?? .now.addingTimeInterval(30 * 86_400)
    }
    var isStylingExhausted: Bool { plan != .sponsored && stylingRemaining == 0 }
}

// MARK: - Sync (simulated)

enum SyncStatus: Codable, Hashable {
    case off
    case upToDate
    case pending(count: Int)
    case failed(reason: String)
    case conflict(description: String)

    var label: String {
        switch self {
        case .off: "iCloud sync off — saved on this device"
        case .upToDate: "Saved locally · sync simulated as up to date"
        case let .pending(count): "Saved locally · \(count) change\(count == 1 ? "" : "s") waiting to sync (simulated)"
        case let .failed(reason): "Saved locally · sync failed (simulated): \(reason)"
        case .conflict: "Saved locally · a sync conflict needs review (simulated)"
        }
    }
}

struct SyncConflict: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var garmentID: String
    var field: String
    var thisDeviceValue: String
    var otherDeviceValue: String
}

struct SyncState: Codable, Hashable {
    var status: SyncStatus = .upToDate
    var lastAcknowledged: Date? = .now.addingTimeInterval(-600)
    var conflicts: [SyncConflict] = []
}

// MARK: - Feedback board (simulated, no network)

enum IdeaStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case underReview, planned, inProgress, released, notPlanned
    var id: String { rawValue }
    var label: String {
        switch self {
        case .underReview: "Under review"
        case .planned: "Planned"
        case .inProgress: "In progress"
        case .released: "Released"
        case .notPlanned: "Not planned"
        }
    }
}

struct FeedbackIdea: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var body: String
    var topic: String
    var status: IdeaStatus
    var votes: Int
    var hasVoted: Bool = false
    var publicAlias: String
    var createdAt: Date
}

enum SubmissionState: String, Codable, Hashable {
    case pendingModeration, approved, rejected, merged
    var label: String {
        switch self {
        case .pendingModeration: "Pending moderation"
        case .approved: "Approved"
        case .rejected: "Not published"
        case .merged: "Merged with a similar idea"
        }
    }
}

struct MySubmission: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var body: String
    var state: SubmissionState = .pendingModeration
    var submittedAt: Date = .now
}

enum IssueCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case bug, stylingQuality, billing, privacy, security
    var id: String { rawValue }
    var label: String {
        switch self {
        case .bug: "Something isn't working"
        case .stylingQuality: "Styling quality"
        case .billing: "Billing"
        case .privacy: "Privacy"
        case .security: "Security"
        }
    }
}

struct PrivateIssueReport: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var category: IssueCategory
    var message: String
    var replyEmail: String?
    var includeDiagnostics: Bool
    var submittedAt: Date = .now
}

struct ReleaseNote: Identifiable, Codable, Hashable {
    var id: String { version }
    var version: String
    var date: Date
    var changes: [String]
    var knownLimitations: [String]
}
