import Foundation

/// How her body shapes fit guidance, derived fresh from the profile each time.
///
/// Order of trust:
/// 1. Confirmed waist, hip and bust (body or size-chart basis) are the fit inputs.
/// 2. Only when all three are missing or unconfirmed, confirmed height plus weight gives a
///    rough overall size band, always labeled as an estimate. It never supports a size,
///    never excludes a listing and never overrides a confirmed measurement.
/// 3. Otherwise nothing is guessed.
///
/// Cues describe room, ease and cut, never body types. Raw weight never appears in any
/// string here; `shareableSummary` and `sizeRangeSearchText` carry only the band label
/// and the cues.
struct BodyFit: Hashable {
    enum Source: String, Hashable {
        case measurements, heightAndWeightEstimate, none
    }

    /// Functional fit cues from confirmed measurements (compared in inches).
    enum Cue: String, CaseIterable, Identifiable, Hashable {
        /// Hip is 10″ or more above waist.
        case roomAtHip
        /// Bust is 10″ or more above waist.
        case roomAtBust
        /// Hip and bust are each within 6″ of waist.
        case straighterLine

        var id: String { rawValue }

        /// Reads after "with", e.g. "Fitted with room at the hip".
        var phrase: String {
            switch self {
            case .roomAtHip: "room at the hip"
            case .roomAtBust: "room at the bust"
            case .straighterLine: "a straighter line"
            }
        }

        /// One plain styling note the stylist can lean on.
        var stylingHint: String {
            switch self {
            case .roomAtHip:
                "Bottoms with ease through the hip and seat, like straight or A-line cuts, sit smoothly without pulling at the waist."
            case .roomAtBust:
                "Tops with some stretch or ease through the bust, such as wrap fronts or softer drape, keep buttons and seams lying flat."
            case .straighterLine:
                "Straight and relaxed cuts hang cleanly. A belt or a half tuck marks the waist when you want more definition."
            }
        }
    }

    /// A rough overall letter-size range. Only produced by the height and weight fallback.
    enum SizeBand: String, CaseIterable, Identifiable, Hashable {
        case xs, xsToS, s, sToM, m, mToL, l, lToXL, xlPlus

        var id: String { rawValue }

        var label: String {
            switch self {
            case .xs: "XS"
            case .xsToS: "XS–S"
            case .s: "S"
            case .sToM: "S–M"
            case .m: "M"
            case .mToL: "M–L"
            case .l: "L"
            case .lToXL: "L–XL"
            case .xlPlus: "XL+"
            }
        }

        /// Letter-size steps the band covers, on the scale used by `BodyFit.letterStep(_:)`.
        var letterSteps: ClosedRange<Int> {
            switch self {
            case .xs: 0...0
            case .xsToS: 0...1
            case .s: 1...1
            case .sToM: 1...2
            case .m: 2...2
            case .mToL: 2...3
            case .l: 3...3
            case .lToXL: 3...4
            case .xlPlus: 4...BodyFit.largestLetterStep
            }
        }
    }

    static let cueThreshold: Double = 10
    static let straighterLineThreshold: Double = 6
    fileprivate static let largestLetterStep = 6

    let source: Source
    let cues: [Cue]
    /// Set only when `source == .heightAndWeightEstimate`.
    let estimatedBand: SizeBand?
    /// Confirmed fit measurements in inches. Nil means Unknown, never zero.
    let waistInches: Double?
    let hipInches: Double?
    let bustInches: Double?

    init(profile: UserProfile) {
        let waist = profile.confirmedBodyMeasurement(.waist)?.inches
        let hip = profile.confirmedBodyMeasurement(.hip)?.inches
        let bust = profile.confirmedBodyMeasurement(.bust)?.inches
        waistInches = waist
        hipInches = hip
        bustInches = bust

        if waist != nil || hip != nil || bust != nil {
            source = .measurements
            estimatedBand = nil
            var cues: [Cue] = []
            if let waist {
                let hipRoom = hip.map { $0 - waist }
                let bustRoom = bust.map { $0 - waist }
                if let hipRoom, hipRoom >= Self.cueThreshold { cues.append(.roomAtHip) }
                if let bustRoom, bustRoom >= Self.cueThreshold { cues.append(.roomAtBust) }
                if let hipRoom, let bustRoom,
                   hipRoom <= Self.straighterLineThreshold, bustRoom <= Self.straighterLineThreshold {
                    cues.append(.straighterLine)
                }
            }
            self.cues = cues
            return
        }

        cues = []
        if let height = profile.measurement(.height), height.confirmed, height.basis == .body, height.inches > 0,
           let weight = profile.weight, weight.pounds > 0 {
            source = .heightAndWeightEstimate
            estimatedBand = Self.estimateBand(heightInches: height.inches, pounds: weight.pounds)
        } else {
            source = .none
            estimatedBand = nil
        }
    }

    // MARK: - Estimate

    /// Illustrative mapping for the prototype, not a sizing standard. The ratio stays
    /// internal: it is never shown, named or framed as a health number.
    static func estimateBand(heightInches: Double, pounds: Double) -> SizeBand {
        let ratio = 703 * pounds / (heightInches * heightInches)
        switch ratio {
        case ..<18.5: return .xs
        case ..<20: return .xsToS
        case ..<21.5: return .s
        case ..<23: return .sToM
        case ..<25: return .m
        case ..<27: return .mToL
        case ..<29.5: return .l
        case ...32: return .lToXL
        default: return .xlPlus
        }
    }

    // MARK: - User-facing text

    /// Confirmed fit dimensions that fed the cues, in display order.
    var measuredDimensions: [MeasurementDimension] {
        var list: [MeasurementDimension] = []
        if waistInches != nil { list.append(.waist) }
        if hipInches != nil { list.append(.hip) }
        if bustInches != nil { list.append(.bust) }
        return list
    }

    /// "room at the hip and bust", or nil when there are no cues.
    var cuePhrase: String? {
        guard !cues.isEmpty else { return nil }
        if cues == [.roomAtHip, .roomAtBust] { return "room at the hip and bust" }
        return cues.map(\.phrase).joined(separator: " and ")
    }

    /// Short line pairing her comfort with the cues, e.g. "Fitted with room at the hip".
    func fitSummary(comfort: Comfort) -> String {
        switch source {
        case .measurements:
            if let cuePhrase { return "\(comfort.label) with \(cuePhrase)" }
            return "\(comfort.label), based on your confirmed measurements"
        case .heightAndWeightEstimate:
            guard let estimatedBand else { return comfort.label }
            return "\(comfort.label), around \(estimatedBand.label) (rough estimate)"
        case .none:
            return comfort.label
        }
    }

    /// Where the guidance comes from, e.g. "Rough estimate from your height and weight: around S–M".
    var sourceSummary: String {
        switch source {
        case .measurements:
            let names = measuredDimensions.map { $0 == .hip ? "hip" : $0.label.lowercased() }
            return "Based on your confirmed \(ListFormatter.localizedString(byJoining: names))"
        case .heightAndWeightEstimate:
            guard let estimatedBand else { return "Rough estimate from your height and weight" }
            return "Rough estimate from your height and weight: around \(estimatedBand.label)"
        case .none:
            return "Add your waist, hip or bust for fit guidance. Unknown stays unknown."
        }
    }

    /// What may be shared where the existing permission allows: cues or the band label only.
    /// Never raw weight and never measurement numbers. Nil when there is nothing to share.
    var shareableSummary: String? {
        switch source {
        case .measurements:
            guard let cuePhrase else { return nil }
            return "Fit cues: \(cuePhrase)."
        case .heightAndWeightEstimate:
            guard let estimatedBand else { return nil }
            return "Rough size range: around \(estimatedBand.label) (an estimate, not measured)."
        case .none:
            return nil
        }
    }

    /// Exact text Find One's "Include my size range" control would add, e.g. "size S–M".
    /// Only the fallback band qualifies; confirmed measurements are never added as numbers.
    var sizeRangeSearchText: String? {
        estimatedBand.map { "size \($0.label)" }
    }

    /// Compact record of what shaped fit guidance (source, cues, rough band), so a saved look
    /// can tell when it was made for different fit details. Holds no numbers.
    var fingerprint: String {
        [source.rawValue, cues.map(\.rawValue).joined(separator: ","), estimatedBand?.rawValue ?? ""].joined(separator: "|")
    }

    // MARK: - Listing sizes

    /// Position of a letter size on a simple scale: XXS = -1, XS = 0, S = 1, M = 2, L = 3,
    /// XL = 4, XXL = 5, XXXL = 6. A trailing petite "P" is ignored ("XSP" reads as XS).
    /// Nil for numeric or unfamiliar labels like "0" or "2P", which aren't compared.
    static func letterStep(_ label: String) -> Int? {
        var key = label.uppercased().filter { !$0.isWhitespace }
        if key.hasSuffix("PETITE") { key.removeLast("PETITE".count) }
        let steps: [String: Int] = [
            "XXS": -1, "2XS": -1, "XS": 0, "S": 1, "M": 2, "L": 3, "XL": 4,
            "XXL": 5, "2XL": 5, "XXXL": 6, "3XL": 6,
        ]
        if let step = steps[key] { return step }
        if key.count > 1, key.hasSuffix("P") { return steps[String(key.dropLast())] }
        return nil
    }

    /// Letter-size steps between a listing's size and a band: 0 inside the band, 1 for the
    /// next size out, and so on. Nil when the label isn't a letter size. For ranking only;
    /// a distance never supports a size or excludes a listing.
    static func sizeDistance(listingSize: String, to band: SizeBand) -> Int? {
        guard let step = letterStep(listingSize) else { return nil }
        let range = band.letterSteps
        if step < range.lowerBound { return range.lowerBound - step }
        if step > range.upperBound { return step - range.upperBound }
        return 0
    }

    /// Same as `sizeDistance(listingSize:to:)` against her estimated band, if there is one.
    func sizeDistance(listingSize: String) -> Int? {
        estimatedBand.flatMap { Self.sizeDistance(listingSize: listingSize, to: $0) }
    }
}

extension UserProfile {
    /// Fit guidance derived from this profile.
    var bodyFit: BodyFit { BodyFit(profile: self) }
}
