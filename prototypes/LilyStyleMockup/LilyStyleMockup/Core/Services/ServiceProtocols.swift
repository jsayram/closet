import Foundation
import Observation

// MARK: - Dispatch accounting

/// Each kind of simulated external service. The dispatch counter proves that
/// passive interactions (navigation, scrolling, resizing, opening pickers) make
/// no service calls.
enum ServiceKind: String, CaseIterable, Identifiable, Hashable {
    case stylist, image, webSearch, fitRanker, weather, photoUnderstanding

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stylist: "Stylist"
        case .image: "Image"
        case .webSearch: "Web search"
        case .fitRanker: "Fit ranker"
        case .weather: "Weather"
        case .photoUnderstanding: "Photo describer"
        }
    }

    var systemImage: String {
        switch self {
        case .stylist: "sparkles"
        case .image: "photo"
        case .webSearch: "magnifyingglass"
        case .fitRanker: "ruler"
        case .weather: "cloud.sun"
        case .photoUnderstanding: "text.viewfinder"
        }
    }
}

struct DispatchRecord: Identifiable, Hashable {
    let id = UUID()
    let kind: ServiceKind
    let operation: String
    let at: Date
}

@Observable
final class DispatchLog {
    private(set) var counts: [ServiceKind: Int] = [:]
    private(set) var records: [DispatchRecord] = []
    /// Local reuse events that avoided a dispatch (history hits, exact preview reuse).
    private(set) var avoidedDispatches: Int = 0
    /// Calls the app made on its own for context (the once-per-session weather load).
    /// Included in `total`, but kept out of `userInitiatedTotal`.
    private(set) var automaticDispatches: Int = 0

    func record(_ kind: ServiceKind, _ operation: String, automatic: Bool = false) {
        counts[kind, default: 0] += 1
        if automatic { automaticDispatches += 1 }
        records.insert(DispatchRecord(kind: kind, operation: operation, at: .now), at: 0)
        if records.count > 200 { records.removeLast() }
    }

    func recordAvoided() { avoidedDispatches += 1 }

    func count(_ kind: ServiceKind) -> Int { counts[kind, default: 0] }
    var total: Int { counts.values.reduce(0, +) }
    /// Calls an explicit action started (everything except automatic context loads).
    var userInitiatedTotal: Int { total - automaticDispatches }

    func reset() {
        counts = [:]
        records = []
        avoidedDispatches = 0
        automaticDispatches = 0
    }
}

// MARK: - Service contracts (provider-independent)

/// What the simulated cloud stylist receives. Raw weight never travels: the profile copy
/// has it removed, and only the fit cues or the rough size band derived on this device
/// come along, and only while cloud styling is allowed.
struct StylistContext {
    var preflight: ScopePreflight
    var profile: UserProfile
    var recentOutfits: [Outfit]
    /// Fit cues or the rough size band, worked out before the weight is removed. Nil unless
    /// cloud styling is allowed. Carries no weight and no new measurement numbers.
    var bodyFit: BodyFit?

    init(preflight: ScopePreflight, profile: UserProfile, recentOutfits: [Outfit]) {
        var shared = profile
        shared.weight = nil
        self.preflight = preflight
        self.profile = shared
        self.recentOutfits = recentOutfits
        bodyFit = profile.permission(.cloudStyling) == .allowed ? profile.bodyFit : nil
    }

    /// The only fit text the stylist may repeat: cues or the band label, never weight.
    var shareableFit: String? { bodyFit?.shareableSummary }
}

enum ServiceError: LocalizedError, Equatable {
    case offline
    case timedOut
    case cancelled
    case permissionDeclined(ProcessingPurpose)
    case allowanceExhausted
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .offline: "The simulated service is offline."
        case .timedOut: "The simulated service didn't respond in time."
        case .cancelled: "Cancelled."
        case let .permissionDeclined(p): "\(p.title) is turned off in your permissions."
        case .allowanceExhausted: "Today's styling allowance is used up (sample terms)."
        case .malformedResponse: "The simulated service returned something invalid, so nothing was applied."
        }
    }
}

protocol StylistService {
    func generateOutfits(_ request: StyleRequest, context: StylistContext) async throws -> OutfitGenerationResult
    func explainSwap(outfit: Outfit, slot: OutfitSlot, newGarment: Garment) -> String
    /// Ask Stylist (FR-14): a short typed answer, optionally with one look built from eligible IDs.
    func answer(question: String, attachedOutfit: Outfit?, mode: StylistChatMode,
                baseRequest: StyleRequest, context: StylistContext) async throws -> StylistAnswer
}

struct ImageJobRequest: Hashable {
    var jobID: String
    var outfit: Outfit
    var referenceVersion: Int
    var renderKey: String
}

enum ImageJobPhase: Hashable {
    case queued
    case generating(progress: Double)
    case saving
    case ready(previewID: String)
    case reused(previewID: String)
    case failed(reason: String)
    case cancelRequested
    case cancelled
    /// No picture job was started (history reuse, or no access or units left). Nothing was charged.
    case notStarted(reason: String)

    var isTerminal: Bool {
        switch self {
        case .ready, .reused, .failed, .cancelled, .notStarted: true
        default: false
        }
    }

    var label: String {
        switch self {
        case .queued: "Queued"
        case let .generating(p): "Generating \(Int(p * 100))%"
        case .saving: "Saving to your history"
        case .ready: "Ready"
        case .reused: "Ready — reused from your history"
        case let .failed(reason): "Failed — \(reason)"
        case .cancelRequested: "Cancelling…"
        case .cancelled: "Cancelled"
        case let .notStarted(reason): "Not started — \(reason)"
        }
    }
}

protocol ImageProvider {
    /// Simulated personal preview rendering. Reports progress via the callback.
    func render(_ job: ImageJobRequest, progress: @escaping (Double) -> Void) async throws -> PreviewQualityLabel
}

protocol WebSearchService {
    func search(_ intent: PublicShoppingIntent) async throws -> (outcome: SearchOutcome, leads: [ShoppingCandidate], attempts: [SourceAttempt])
}

protocol ShoppingRanker {
    /// Tool-free fit-first ranking against minimal confirmed fit context.
    func rank(_ leads: [ShoppingCandidate], profile: UserProfile, context: FindOneContext) async throws -> [ShoppingCandidate]
}

protocol WeatherService {
    /// `automatic` marks the once-per-session load the app makes on its own (not a Refresh tap).
    func currentConditions(automatic: Bool) async throws -> WeatherSnapshot
}

struct MetadataProposal: Identifiable, Hashable {
    let id = UUID()
    var field: String
    var value: String
    var uncertainty: String
}

protocol GarmentUnderstandingService {
    func proposeDetails(for garment: Garment) async throws -> [MetadataProposal]
}

/// The injected service container. Screens never choose a live provider.
struct Services {
    var stylist: StylistService
    var images: ImageProvider
    var webSearch: WebSearchService
    var ranker: ShoppingRanker
    var weather: WeatherService
    var garmentUnderstanding: GarmentUnderstandingService
}
