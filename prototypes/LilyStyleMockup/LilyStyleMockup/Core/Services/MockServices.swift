import Foundation

// MARK: - Weather (simulated; WeatherKit is not connected)

final class MockWeather: WeatherService {
    private let log: DispatchLog
    private let scenario: () -> DemoScenario

    init(log: DispatchLog, scenario: @escaping () -> DemoScenario) {
        self.log = log
        self.scenario = scenario
    }

    func currentConditions(automatic: Bool) async throws -> WeatherSnapshot {
        log.record(.weather, automatic ? "currentConditions (automatic)" : "currentConditions", automatic: automatic)
        try await Task.sleep(nanoseconds: 300_000_000)
        if scenario() == .offlineWeather { throw ServiceError.offline }
        return WeatherSnapshot(temperatureF: 58, condition: .rain, season: Season.from(date: .now), source: .simulatedForecast)
    }
}

// MARK: - Image provider (simulated On Me previews)

/// Produces no pixels: the app renders an honest placeholder figure for each
/// "delivered" preview. This only simulates the job lifecycle.
final class MockImageProvider: ImageProvider {
    private let log: DispatchLog
    private let scenario: () -> DemoScenario
    private let timing: () -> MockTiming
    private var renderedCount = 0

    init(log: DispatchLog, scenario: @escaping () -> DemoScenario, timing: @escaping () -> MockTiming) {
        self.log = log
        self.scenario = scenario
        self.timing = timing
    }

    func render(_ job: ImageJobRequest, progress: @escaping (Double) -> Void) async throws -> PreviewQualityLabel {
        log.record(.image, "render preview")
        renderedCount += 1
        let index = renderedCount
        let steps = 10
        let stepDelay = timing().imageDuration / Double(steps)
        for step in 1...steps {
            try await Task.sleep(nanoseconds: UInt64(stepDelay * 1_000_000_000))
            try Task.checkCancellation()
            await MainActor.run { progress(Double(step) / Double(steps)) }
            if scenario() == .failedImage, index % 3 == 2, step == 6 {
                throw ServiceError.timedOut
            }
        }
        let approximate = job.outfit.pieces.contains { $0.isHypothetical || $0.capturedImageKind != .actualPhoto }
        return approximate ? .approximate : .ok
    }
}

// MARK: - Garment understanding (simulated proposals for review)

final class MockGarmentUnderstanding: GarmentUnderstandingService {
    private let log: DispatchLog
    private let scenario: () -> DemoScenario

    init(log: DispatchLog, scenario: @escaping () -> DemoScenario) {
        self.log = log
        self.scenario = scenario
    }

    func proposeDetails(for garment: Garment) async throws -> [MetadataProposal] {
        log.record(.photoUnderstanding, "proposeDetails")
        try await Task.sleep(nanoseconds: 900_000_000)
        if scenario() == .offlineAI { throw ServiceError.offline }
        let colorWord = garment.color?.name ?? "Soft white"
        let kind = garment.kind == .unknown ? "Top" : garment.kind.label
        return [
            MetadataProposal(field: "Name", value: "\(colorWord) \(kind.lowercased()) with ruffled trim", uncertainty: "Suggested from the photo"),
            MetadataProposal(field: "Category", value: kind, uncertainty: "Likely"),
            MetadataProposal(field: "Color", value: "Off-white (could be cream)", uncertainty: "Uncertain — lighting may change it"),
            MetadataProposal(field: "Detail", value: "Lace-like trim at the neckline", uncertainty: "Visible detail"),
            MetadataProposal(field: "Fabric", value: "Unknown", uncertainty: "A photo can't confirm fabric"),
        ]
    }
}

// MARK: - Web search + tool-free fit ranking (simulated, fictional sources)

/// Fictional lead attributes the ranker compares against confirmed fit facts.
private struct LeadFit {
    var brand: String
    var sizeOffered: String
    var garmentInseam: Double?
    var garmentLength: Double?
    var bustRange: ClosedRange<Double>?
    var waistRange: ClosedRange<Double>?
    var hipRange: ClosedRange<Double>?
    var sameLineAsReferenceGarmentID: String?
    var snippetOnly: Bool = false
}

final class MockWebSearch: WebSearchService {
    private let log: DispatchLog
    private let scenario: () -> DemoScenario
    private let timing: () -> MockTiming
    fileprivate static var fitTable: [String: LeadFit] = [:]

    init(log: DispatchLog, scenario: @escaping () -> DemoScenario, timing: @escaping () -> MockTiming) {
        self.log = log
        self.scenario = scenario
        self.timing = timing
    }

    func search(_ intent: PublicShoppingIntent) async throws -> (outcome: SearchOutcome, leads: [ShoppingCandidate], attempts: [SourceAttempt]) {
        log.record(.webSearch, "search: \(intent.garment)\(intent.sizeRange.map { ", \($0)" } ?? "")")
        try await Task.sleep(nanoseconds: UInt64(timing().searchDelay * 1_000_000_000))
        try Task.checkCancellation()
        let attempts = [
            SourceAttempt(retailer: "Amazon", status: .evidenceFound),
            SourceAttempt(retailer: "TikTok Shop", status: .evidenceFound),
            SourceAttempt(retailer: "Target", status: .evidenceFound),
            SourceAttempt(retailer: "Walmart", status: .notAttempted),
            SourceAttempt(retailer: "H&M", status: .blocked),
        ]
        if scenario() == .offlineAI {
            return (.searchNotCompleted, [], attempts.map { SourceAttempt(retailer: $0.retailer, status: .notAttempted) })
        }
        let leads = Self.leads(for: intent)
        return (leads.isEmpty ? .noMatchingResultsWithinSearch : .resultsFound, leads, attempts)
    }

    private static func lead(_ id: String, retailer: String, preferred: Bool, title: String, price: Double, colorName: String, hex: String,
                             kind: GarmentKind, style: String, stock: AvailabilityEvidence = .inStock, shipping: ShippingEvidence = .shipsToDestination,
                             direct: Bool = true, tier: PriceTier? = nil, fit: LeadFit) -> ShoppingCandidate {
        fitTable[id] = fit
        let slug = retailer.lowercased().replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "&", with: "and")
        let now = Date.now
        var evidence: [EvidenceItem] = [EvidenceItem(claim: "Title, price and color as listed", sourceType: fit.snippetOnly ? .snippet : .productPage,
                                                     sourceLabel: "demo-\(slug).example", retrievedAt: now)]
        if let inseam = fit.garmentInseam {
            evidence.append(EvidenceItem(claim: "Garment inseam \(inseam.formatted()) in (size \(fit.sizeOffered))", sourceType: .garmentMeasurements,
                                         sourceLabel: "demo-\(slug).example size chart", retrievedAt: now))
        }
        if let length = fit.garmentLength {
            evidence.append(EvidenceItem(claim: "Garment length \(length.formatted()) in (size \(fit.sizeOffered))", sourceType: .garmentMeasurements,
                                         sourceLabel: "demo-\(slug).example size chart", retrievedAt: now))
        }
        if let bust = fit.bustRange {
            evidence.append(EvidenceItem(claim: "Body-chart bust \(bust.lowerBound.formatted())–\(bust.upperBound.formatted()) in for \(fit.sizeOffered)",
                                         sourceType: .sizeChart, sourceLabel: "demo-\(slug).example size chart", retrievedAt: now))
        }
        if let waist = fit.waistRange {
            evidence.append(EvidenceItem(claim: "Body-chart waist \(waist.lowerBound.formatted())–\(waist.upperBound.formatted()) in for \(fit.sizeOffered)",
                                         sourceType: .sizeChart, sourceLabel: "demo-\(slug).example size chart", retrievedAt: now))
        }
        if let hip = fit.hipRange {
            evidence.append(EvidenceItem(claim: "Body-chart hip \(hip.lowerBound.formatted())–\(hip.upperBound.formatted()) in for \(fit.sizeOffered)",
                                         sourceType: .sizeChart, sourceLabel: "demo-\(slug).example size chart", retrievedAt: now))
        }
        if fit.snippetOnly {
            evidence.append(EvidenceItem(claim: "“Runs small” — a shopper's comment, not a size recommendation", sourceType: .review,
                                         sourceLabel: "search snippet", retrievedAt: now))
        }
        return ShoppingCandidate(id: id, retailer: retailer, domain: "demo-\(slug).example", title: title,
                                 url: "https://demo-\(slug).example/p/\(id)", price: price, colorName: colorName, colorHex: hex, kind: kind,
                                 fitState: .needsFitConfirmation, fitReason: "", comparedDimensions: [], unknowns: [], recommendedSize: nil,
                                 evidence: evidence, styleReason: style, stock: stock, shipping: shipping, isPreferredRetailer: preferred,
                                 isDirectProductPage: direct, priceTier: tier, retrievedAt: now, listedSize: fit.sizeOffered)
    }

    static func leads(for intent: PublicShoppingIntent) -> [ShoppingCandidate] {
        let g = intent.garment.lowercased()
        if g.contains("trouser") || g.contains("pant") || g.contains("jean") {
            return [
                lead("l-pants-a", retailer: "Target", preferred: true, title: "Demo Brand A Petite Ankle Trouser", price: 39, colorName: "Navy", hex: "1F2A44",
                     kind: .trousers, style: "Same clean ankle line as your navy dress pants.", tier: .affordable,
                     fit: LeadFit(brand: "Demo Brand A", sizeOffered: "2P", garmentInseam: 26, sameLineAsReferenceGarmentID: "g-navy-trousers")),
                lead("l-pants-b", retailer: "Amazon", preferred: true, title: "Wide-Leg High-Rise Trouser (Regular)", price: 29, colorName: "Navy", hex: "202B47",
                     kind: .trousers, style: "Popular wide-leg cut; high rise may sit above your navel preference.",
                     fit: LeadFit(brand: "Demo Brand C", sizeOffered: "XS Regular", garmentInseam: 30.5)),
                lead("l-pants-c", retailer: "TikTok Shop", preferred: true, title: "Viral Petite Flare Pants", price: 24, colorName: "Navy", hex: "1E2640",
                     kind: .trousers, style: "Trending flare silhouette.", shipping: .unverified, direct: false,
                     fit: LeadFit(brand: "Unknown seller", sizeOffered: "S", snippetOnly: true)),
                lead("l-pants-d", retailer: "Lark & Line", preferred: false, title: "Cropped Straight Wool Trouser", price: 118, colorName: "Midnight navy", hex: "1A2238",
                     kind: .trousers, style: "Investment wool with a cropped regular length.", tier: .investment,
                     fit: LeadFit(brand: "Lark & Line", sizeOffered: "0", garmentInseam: 25.5, waistRange: 25...26, hipRange: 34...35.5)),
                lead("l-pants-e", retailer: "H&M", preferred: true, title: "Slim Ankle Pants", price: 27, colorName: "Navy", hex: "232E4A",
                     kind: .trousers, style: "Simple slim ankle pant.", stock: .unavailable,
                     fit: LeadFit(brand: "Demo Brand D", sizeOffered: "2", garmentInseam: 27, hipRange: 35...36.5)),
            ]
        }
        if g.contains("jacket") || g.contains("blazer") || g.contains("coat") || g.contains("cardigan") {
            return [
                lead("l-jacket-a", retailer: "Target", preferred: true, title: "Demo Brand B Classic Blazer", price: 49, colorName: "Heather gray", hex: "8A8D91",
                     kind: .blazer, style: "Classic office blazer.", fit: LeadFit(brand: "Demo Brand B", sizeOffered: "S", garmentLength: 27)),
                lead("l-jacket-b", retailer: "Amazon", preferred: true, title: "Cropped Petite Blazer", price: 44, colorName: "Camel", hex: "B48A5A",
                     kind: .blazer, style: "Cropped length to avoid an oversized look.", fit: LeadFit(brand: "Demo Brand E", sizeOffered: "XSP", garmentLength: 21.5)),
                lead("l-jacket-c", retailer: "Lark & Line", preferred: false, title: "Short Wool Jacket", price: 160, colorName: "Navy", hex: "1F2A44",
                     kind: .jacket, style: "Hip-length tailored jacket.", tier: .investment, fit: LeadFit(brand: "Lark & Line", sizeOffered: "0", garmentLength: 22)),
            ]
        }
        if g.contains("shoe") || g.contains("flat") || g.contains("heel") || g.contains("loafer") || g.contains("sneaker") {
            return [
                lead("l-shoe-a", retailer: "Walmart", preferred: true, title: "Pointed Ballet Flat", price: 25, colorName: "Nude", hex: "D8B79A",
                     kind: .flats, style: "Pointed toe lengthens the line with ankle trousers.", fit: LeadFit(brand: "Demo Brand F", sizeOffered: "6")),
                lead("l-shoe-b", retailer: "Target", preferred: true, title: "Low Block Heel Pump", price: 35, colorName: "Black", hex: "1E1E1E",
                     kind: .heels, style: "Low block heel, easy for a long day.", fit: LeadFit(brand: "Demo Brand G", sizeOffered: "6")),
            ]
        }
        // Tops and everything else.
        let color = intent.color ?? "Light pink"
        return [
            lead("l-top-a", retailer: "H&M", preferred: true, title: "Petite Bow-Neck Blouse", price: 25, colorName: color, hex: "F2C4CE",
                 kind: .blouse, style: "Soft bow neck, polished for office or dinner.", tier: .affordable,
                 fit: LeadFit(brand: "Demo Brand H", sizeOffered: "XSP", garmentLength: 22, bustRange: 31...32.5)),
            lead("l-top-b", retailer: "Target", preferred: true, title: "Satin Shell Blouse", price: 30, colorName: color, hex: "6D2433",
                 kind: .blouse, style: "Satin sheen dresses up trousers.",
                 fit: LeadFit(brand: "Demo Brand B", sizeOffered: "S", bustRange: 33...35)),
            lead("l-top-c", retailer: "Petite Atelier", preferred: false, title: "Silk Ruffle Blouse", price: 128, colorName: color, hex: "EFD6DC",
                 kind: .blouse, style: "Investment silk with a delicate ruffle.", tier: .investment,
                 fit: LeadFit(brand: "Petite Atelier", sizeOffered: "XXS", garmentLength: 21, bustRange: 30...31.5)),
            lead("l-top-d", retailer: "TikTok Shop", preferred: true, title: "Trending Puff-Sleeve Top", price: 19, colorName: color, hex: "F4C9D4",
                 kind: .blouse, style: "Puff sleeves — more trend-led than your usual style.", shipping: .unverified, direct: false,
                 fit: LeadFit(brand: "Unknown seller", sizeOffered: "S", snippetOnly: true)),
        ]
    }
}

/// Tool-free ranking: classifies fit first (non-compensatory), then orders by evidence,
/// retailer preference and price. Unknown critical fit is never promoted.
/// Confirmed waist, hip, bust and inseam are the only body inputs compared here. Weight is
/// never sent to the ranker; Find One adds the rough height-and-weight estimate on the
/// device afterwards (`FindOneSession.applyRoughSizeEstimate`).
final class MockShoppingRanker: ShoppingRanker {
    private let log: DispatchLog

    init(log: DispatchLog) { self.log = log }

    func rank(_ leads: [ShoppingCandidate], profile: UserProfile, context: FindOneContext) async throws -> [ShoppingCandidate] {
        log.record(.fitRanker, "rank \(leads.count) leads")
        try await Task.sleep(nanoseconds: 400_000_000)
        let ranked = leads.map { Self.classify($0, profile: profile) }
        let order: [FitEvidenceState: Int] = [.supportedGuidance: 0, .needsFitConfirmation: 1, .knownFitConflict: 2]
        return ranked.sorted { a, b in
            if order[a.fitState]! != order[b.fitState]! { return order[a.fitState]! < order[b.fitState]! }
            let aEvidence = a.evidence.filter { $0.sourceType != .snippet && $0.sourceType != .review }.count
            let bEvidence = b.evidence.filter { $0.sourceType != .snippet && $0.sourceType != .review }.count
            if aEvidence != bEvidence { return aEvidence > bEvidence }
            if a.isPreferredRetailer != b.isPreferredRetailer { return a.isPreferredRetailer }
            return (a.price ?? 0) < (b.price ?? 0)
        }
    }

    static func classify(_ lead: ShoppingCandidate, profile: UserProfile) -> ShoppingCandidate {
        var c = lead
        guard let fit = MockWebSearch.fitTable[lead.id] else {
            c.fitReason = "No size evidence was found for this listing."
            c.unknowns = ["Size chart", "Length"]
            return c
        }
        // Only confirmed values guide fit. Size charts are body ranges; listed inseams are garment lengths.
        func confirmed(_ d: MeasurementDimension, bases: Set<MeasurementBasis>) -> MeasurementFact? {
            profile.measurement(d).flatMap { $0.confirmed && bases.contains($0.basis) ? $0 : nil }
        }
        func missing(_ name: String, _ d: MeasurementDimension, listed: Bool = true) -> String {
            guard let fact = profile.measurement(d) else { return "\(name) — not confirmed in your profile" }
            if !fact.confirmed { return "\(name) — entered but not confirmed in your profile" }
            if !listed { return "\(name) — not listed for this size" }
            return "\(name) — yours is a garment measurement, and this listing gives a body chart"
        }
        let inseam = confirmed(.inseam, bases: [.preferredGarment, .actualGarment])
        let bust = confirmed(.bust, bases: [.body, .chartRange])
        let waist = confirmed(.waist, bases: [.body, .chartRange])
        let hip = confirmed(.hip, bases: [.body, .chartRange])
        let category = lead.kind.defaultCategory
        var compared: [String] = []
        var unknowns: [String] = []
        // Support needs at least one real comparison with her confirmed profile, not listing data alone.
        var confirmedComparisons = 0

        if fit.snippetOnly {
            c.fitState = .needsFitConfirmation
            c.fitReason = "Snippet-only lead: no seller size chart or garment measurements were found. A shopper saying it “runs small” isn't a size recommendation."
            c.unknowns = ["Size chart", "Waist", "Length", "Shipping"]
            return c
        }

        // Confirmed real-garment references can support or exclude same-brand, same-category items.
        if let ref = profile.fitReferences.first(where: { $0.brand == fit.brand && $0.category == category }) {
            if ref.result == .fitsWell, fit.sameLineAsReferenceGarmentID == ref.garmentID, ref.sizeLabel == fit.sizeOffered {
                c.fitState = .supportedGuidance
                c.recommendedSize = fit.sizeOffered
                c.comparedDimensions = ["Waist — matches your confirmed \(ref.brand) \(ref.sizeLabel) pair", "Length — same \(fit.garmentInseam.map { "\($0.formatted())″" } ?? "") ankle line as that pair"]
                c.unknowns = ["Rise on this style (not listed)"]
                c.fitReason = "Size \(fit.sizeOffered) matches the \(ref.brand) pair you confirmed fits, and this listing gives the same ankle inseam. Rise isn't listed — check it against your navel-area preference."
                return c
            }
            if ref.result == .tooLong || ref.result == .tooTight || ref.result == .tooLoose, ref.sizeLabel == fit.sizeOffered {
                c.fitState = .knownFitConflict
                c.comparedDimensions = ["\(ref.areas.map(\.label).joined(separator: ", ")) — your confirmed note: \(ref.result.label.lowercased()) in \(ref.brand) \(ref.sizeLabel)"]
                c.fitReason = "You confirmed \(ref.brand) size \(ref.sizeLabel) was \(ref.result.label.lowercased()) (\(ref.areas.map(\.label).joined(separator: ", ").lowercased())). This listing uses the same brand size, so it's excluded from recommendations."
                return c
            }
        }

        switch category {
        case .bottom:
            if let waist, let range = fit.waistRange {
                if range.contains(waist.inches) { compared.append("Waist \(waist.displayValue) is within the \(fit.sizeOffered) chart range"); confirmedComparisons += 1 }
                else { c.fitState = .knownFitConflict; c.fitReason = "Your confirmed waist \(waist.displayValue) is outside this size's chart range."; c.comparedDimensions = ["Waist"]; return c }
            } else {
                unknowns.append(missing("Waist", .waist, listed: fit.waistRange != nil))
            }
            // Hip is compared only when the chart lists it. An unknown hip is noted but isn't critical.
            if let range = fit.hipRange {
                if let hip {
                    if range.contains(hip.inches) { compared.append("Hip \(hip.displayValue) is within the \(fit.sizeOffered) chart range"); confirmedComparisons += 1 }
                    else { c.fitState = .knownFitConflict; c.fitReason = "Your confirmed hip \(hip.displayValue) is outside this size's chart range."; c.comparedDimensions = ["Hip"]; return c }
                } else {
                    unknowns.append(missing("Hip", .hip))
                }
            }
            if let inseam, let garmentInseam = fit.garmentInseam {
                let diff = garmentInseam - inseam.inches
                let amount = abs(diff).formatted(.number.precision(.fractionLength(1)))
                if diff > 1 {
                    c.fitState = .knownFitConflict
                    c.comparedDimensions = ["Inseam \(garmentInseam.formatted())″ vs your confirmed \(inseam.displayValue)"]
                    c.fitReason = "Listed inseam is about \(amount)″ longer than your confirmed length — excluded even though it's from a preferred store."
                    return c
                } else if diff < -1 {
                    unknowns.append("Length — listed inseam is about \(amount)″ shorter than your confirmed \(inseam.displayValue)")
                } else {
                    compared.append("Inseam \(garmentInseam.formatted())″ is within 1″ of your confirmed \(inseam.displayValue)")
                    confirmedComparisons += 1
                }
            } else if let garmentInseam = fit.garmentInseam {
                let why = switch profile.measurement(.inseam) {
                case nil: "your inseam is unknown"
                case let fact? where !fact.confirmed: "your inseam isn't confirmed yet"
                case let fact?: "your inseam is recorded as a \(fact.basis.label.lowercased())"
                }
                unknowns.append("Length — listing gives a \(garmentInseam.formatted())″ garment inseam, but \(why)")
            } else {
                unknowns.append("Length — not listed")
            }
            unknowns.append("Rise")
        case .top, .dress:
            if let bust, let range = fit.bustRange {
                if range.contains(bust.inches) { compared.append("Bust \(bust.displayValue) is within the \(fit.sizeOffered) body chart"); confirmedComparisons += 1 }
                else { c.fitState = .knownFitConflict; c.fitReason = "Your confirmed bust \(bust.displayValue) is outside this size's chart."; c.comparedDimensions = ["Bust"]; return c }
            } else {
                unknowns.append(missing("Bust", .bust, listed: fit.bustRange != nil))
            }
            if let length = fit.garmentLength { compared.append("Garment length \(length.formatted())″ listed") } else { unknowns.append("Garment length — not listed") }
        case .layer:
            if let bust, let range = fit.bustRange {
                if range.contains(bust.inches) { compared.append("Bust \(bust.displayValue) is within the \(fit.sizeOffered) body chart"); confirmedComparisons += 1 }
                else { c.fitState = .knownFitConflict; c.fitReason = "Your confirmed bust \(bust.displayValue) is outside this size's chart."; c.comparedDimensions = ["Bust"]; return c }
            } else {
                unknowns.append(missing("Bust", .bust, listed: fit.bustRange != nil))
            }
            // Sleeve isn't listed for these leads, and a listed body length alone isn't a comparison.
            unknowns.append(profile.measurement(.sleeve)?.confirmed == true ? "Sleeve — not listed" : "Sleeve — not confirmed in your profile")
            if let length = fit.garmentLength { unknowns.append("Body length \(length.formatted())″ listed — no confirmed jacket length to compare") } else { unknowns.append("Body length — not listed") }
        default:
            unknowns.append("Your shoe size — not confirmed in your profile")
        }

        c.comparedDimensions = compared
        c.unknowns = unknowns
        let criticalUnknown = unknowns.contains { $0.hasPrefix("Waist") || $0.hasPrefix("Length") || $0.hasPrefix("Bust") || $0.hasPrefix("Your shoe") || $0.hasPrefix("Body length") || $0.hasPrefix("Sleeve") }
        if criticalUnknown || confirmedComparisons == 0 {
            c.fitState = .needsFitConfirmation
            let reasons = unknowns.isEmpty ? "nothing in your confirmed profile could be compared" : unknowns.prefix(2).joined(separator: "; ")
            c.fitReason = "Needs fit confirmation: " + reasons + ". View the chart or ask the retailer before buying."
        } else {
            c.fitState = .supportedGuidance
            c.recommendedSize = fit.sizeOffered
            c.fitReason = "Size \(fit.sizeOffered): " + compared.joined(separator: "; ") + ". Not a guarantee of physical fit."
        }
        return c
    }
}
