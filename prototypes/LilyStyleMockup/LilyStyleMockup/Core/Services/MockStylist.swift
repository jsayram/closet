import Foundation

/// Scripted, deterministic stylist that honors the same typed contract a real
/// provider would. It only ever uses canonical eligible garment IDs from the
/// complete-scope preflight, and never invents ownership. Hypothetical pieces
/// appear only in Main Closet Suggestions or an explicit new-piece direction.
final class MockStylist: StylistService {
    let log: DispatchLog
    let scenario: () -> DemoScenario
    let timing: () -> MockTiming

    init(log: DispatchLog, scenario: @escaping () -> DemoScenario, timing: @escaping () -> MockTiming) {
        self.log = log
        self.scenario = scenario
        self.timing = timing
    }

    func generateOutfits(_ request: StyleRequest, context: StylistContext) async throws -> OutfitGenerationResult {
        log.record(.stylist, "generateOutfits · \(request.occasion.label)")
        try await Task.sleep(nanoseconds: UInt64(timing().stylistDelay * 1_000_000_000))
        try Task.checkCancellation()
        if scenario() == .offlineAI {
            return .generationNotCompleted(reason: "The stylist service didn't finish (simulated outage). This says nothing about what's in your closet — your request is kept, so you can retry or build a look yourself.")
        }
        return Self.compose(request: request, context: context)
    }

    func explainSwap(outfit: Outfit, slot: OutfitSlot, newGarment: Garment) -> String {
        "Swapped in \(newGarment.displayName). The other pieces stay exactly as they were."
    }

    // MARK: - Composition

    private struct Look {
        var top: Garment?
        var bottom: Garment?
        var dress: Garment?
        var shoes: Garment
        var layer: Garment?
        var accessory: Garment?

        var all: [Garment] { [layer, top, dress, bottom, shoes, accessory].compactMap { $0 } }
        var coreIDs: [String?] { [top?.id, bottom?.id ?? dress?.id, shoes.id, layer?.id] }

        func differsEnough(from other: Look) -> Bool {
            zip(coreIDs, other.coreIDs).filter { $0 != $1 }.count >= 2
        }
    }

    static func compose(request: StyleRequest, context: StylistContext) -> OutfitGenerationResult {
        let pre = context.preflight
        let occasion = request.occasion
        let minFormality = occasion.formalityRange.lowerBound
        let weather = request.weather
        let comfort = request.effectiveComfort(profile: context.profile)
        let cues = context.bodyFit?.source == .measurements ? context.bodyFit?.cues ?? [] : []

        func suits(_ g: Garment) -> Bool {
            if g.category != .accessory, g.formality.rawValue < minFormality { return false }
            if weather.temperatureF >= 82, g.warmth >= 2, g.category != .shoes { return false }
            return true
        }

        var tops = pre.eligible(in: .top).filter(suits)
        var bottoms = pre.eligible(in: .bottom).filter(suits)
        var dresses = pre.eligible(in: .dress).filter(suits)
        var shoes = pre.eligible(in: .shoes).filter(suits)
        let layers = pre.eligible(in: .layer).filter(suits)
        let accessories = pre.eligible(in: .accessory)

        // Locked starting item must be eligible in this source.
        var locked: Garment?
        if let startID = request.startingItemID {
            guard let g = pre.eligibleGarments.first(where: { $0.id == startID }) else {
                return .insufficientWardrobe(evidence: ["Your starting item isn't eligible in \(pre.scopeName) right now. Review its status or choose another starting piece."])
            }
            locked = g
            switch g.category {
            case .top: tops = [g]
            case .bottom: bottoms = [g]
            case .dress: dresses = [g]; tops = []; bottoms = []
            case .shoes: shoes = [g]
            default: break
            }
        }

        // Required colour on a specific slot narrows that slot to confirmed matches.
        let constraint = request.colorConstraint
        if let constraint, constraint.strength == .required, let slot = constraint.scope.slot {
            let keep: (Garment) -> Bool = { $0.color?.family == constraint.family }
            switch slot {
            case .top: tops = tops.filter(keep)
            case .bottom: bottoms = bottoms.filter(keep)
            case .shoes: shoes = shoes.filter(keep)
            default: break
            }
        }

        var looks: [Look] = []
        let layerOptions: [Garment?] = layers.isEmpty ? [nil] : ([nil] + layers.map { Optional($0) })
        for shoe in shoes {
            for layer in layerOptions {
                for top in tops { for bottom in bottoms { looks.append(Look(top: top, bottom: bottom, shoes: shoe, layer: layer)) } }
                for dress in dresses { looks.append(Look(dress: dress, shoes: shoe, layer: layer)) }
            }
        }
        if let locked, locked.category == .layer { looks = looks.filter { $0.layer?.id == locked.id } }
        if let constraint, constraint.strength == .required {
            if constraint.scope == .layer { looks = looks.filter { $0.layer?.color?.family == constraint.family } }
            if constraint.scope == .anyPiece || constraint.scope == .wholePalette {
                looks = looks.filter { $0.all.contains { $0.color?.family == constraint.family } }
            }
        }

        let recentPairs = Set(context.recentOutfits.map { $0.garmentIDs.sorted().joined(separator: ",") })

        func harmony(_ look: Look) -> Double {
            let families = look.all.compactMap(\.color?.family)
            var score = 0.0
            for (i, a) in families.enumerated() {
                for b in families[(i + 1)...] { score += pairScore(a, b) }
            }
            return score
        }

        func baseScore(_ look: Look) -> Double {
            var s = 0.0
            for g in look.all where g.category != .accessory {
                s -= Double(abs(g.formality.rawValue - occasion.preferredFormality.rawValue)) * 0.8
            }
            if weather.needsLayer { s += look.layer == nil ? -1.2 : 1.5 } else if look.layer != nil { s -= 0.6 }
            if let constraint, constraint.strength == .preferred, look.all.contains(where: { $0.color?.family == constraint.family }) { s += 2 }
            switch comfort {
            case .relaxed: s += Double(look.all.filter { [.sweater, .knitTop, .jeans, .cardigan, .flats, .sneakers].contains($0.kind) }.count) * 0.4
            case .close: s += Double(look.all.filter { [.blouse, .trousers, .heels].contains($0.kind) }.count) * 0.3
            default: break
            }
            // Room where her confirmed measurements call for it. The rough height and weight
            // band says nothing about where she needs room, so it doesn't steer the pieces.
            s += look.all.map { cueScore($0, cues: cues, comfort: comfort) }.reduce(0, +)
            if recentPairs.contains(look.all.map(\.id).sorted().joined(separator: ",")) { s -= 0.8 }
            return s
        }

        func safeScore(_ look: Look) -> Double {
            let neutrals = look.all.filter { $0.color?.family.isNeutral ?? false }.count
            return baseScore(look) + Double(neutrals) * 0.9 + min(harmony(look), 1)
        }

        func elevatedScore(_ look: Look) -> Double {
            let accents = look.all.filter { !($0.color?.family.isNeutral ?? true) }.count
            return baseScore(look) + harmony(look) * 1.6 + Double(min(accents, 2)) * 0.8 + (look.top?.formality == .dressy ? 0.5 : 0)
        }

        var chosen: [(LanePurpose, Look)] = []
        if let safe = looks.max(by: { safeScore($0) < safeScore($1) }) { chosen.append((.safeSimple, safe)) }
        let elevatedCandidates = looks.sorted { elevatedScore($0) > elevatedScore($1) }
        for look in elevatedCandidates where chosen.allSatisfy({ look.differsEnough(from: $0.1) }) {
            chosen.append((chosen.count == 1 ? .elevated : .elevatedAlternate, look))
            if chosen.count == 3 { break }
        }

        // Elevated looks may carry a coordinating accessory when one is eligible.
        if let bag = accessories.first(where: { $0.formality.rawValue >= minFormality }) {
            for i in chosen.indices where chosen[i].0 != .safeSimple { chosen[i].1.accessory = bag }
        }

        // Explicit new-piece direction (Main Closet only) replaces the third owned direction.
        let wantsNewPiece = request.allowNewPiece && !request.scope.isSuitcase
        var outfits: [Outfit] = chosen.prefix(wantsNewPiece ? 2 : 3).map { lane, look in
            makeOutfit(lane: lane, look: look, request: request, context: context)
        }
        // The rough estimate gets one gentle note for the whole set, on the first look only.
        if context.bodyFit?.source == .heightAndWeightEstimate, !outfits.isEmpty {
            outfits[0].fitNote = ([estimateFitNote] + [outfits[0].fitNote].filter { !$0.isEmpty }).joined(separator: " ")
        }
        if wantsNewPiece, let base = chosen.dropFirst().first?.1 ?? chosen.first?.1 {
            outfits.append(makeNewPieceOutfit(base: base, request: request))
        }

        if outfits.count >= 3 { return .outfitSet(Array(outfits.prefix(3))) }

        let evidence = limitationEvidence(pre: pre, occasion: occasion, minFormality: minFormality,
                                          tops: tops, bottoms: bottoms, dresses: dresses, shoes: shoes, layers: layers,
                                          lookCount: outfits.count)

        // Suggestions within Main Closet may add labelled hypothetical ideas; strict modes may not.
        // An idea never weakens the request: one that misses the starting piece, a required colour
        // or the occasion is left out, and a short set comes back as partial, not a full set.
        if !request.isStrictOwned {
            let allIdeas = hypotheticalIdeas(for: request)
            let kept = allIdeas.filter { ideaKeepsRequest($0, request: request, hasStartingPiece: locked != nil) }
            var ideas = outfits
            for idea in kept where ideas.count < 3 { ideas.append(idea) }
            if ideas.count >= 3 { return .outfitSet(ideas) }
            let note = "Suggestions ideas that couldn't keep your request (\(requestSummary(request, hasStartingPiece: locked != nil))) were left out."
            if ideas.isEmpty { return .insufficientWardrobe(evidence: evidence + [note]) }
            return .partialWardrobe(ideas, evidence: evidence + [note])
        }

        if outfits.isEmpty { return .insufficientWardrobe(evidence: evidence) }
        return .partialWardrobe(outfits, evidence: evidence)
    }

    /// Whether a fixed hypothetical idea honours the request's hard requirements.
    private static func ideaKeepsRequest(_ idea: Outfit, request: StyleRequest, hasStartingPiece: Bool) -> Bool {
        // The fixed ideas can't include her own starting piece.
        if hasStartingPiece { return false }
        if let constraint = request.colorConstraint, constraint.strength == .required {
            let matches: (OutfitPiece) -> Bool = { $0.capturedColor?.family == constraint.family }
            if let slot = constraint.scope.slot {
                if !idea.pieces.contains(where: { $0.slot == slot && matches($0) }) { return false }
            } else if !idea.pieces.contains(where: matches) {
                return false
            }
        }
        let casualKinds: Set<GarmentKind> = [.sneakers, .jeans, .tee]
        if request.occasion.formalityRange.lowerBound >= 1, idea.pieces.contains(where: { casualKinds.contains($0.capturedKind) }) { return false }
        if request.weather.temperatureF >= 82, idea.pieces.contains(where: { [.sweater, .coat].contains($0.capturedKind) }) { return false }
        return true
    }

    private static func requestSummary(_ request: StyleRequest, hasStartingPiece: Bool) -> String {
        var parts: [String] = []
        if hasStartingPiece { parts.append("your starting piece") }
        if let c = request.colorConstraint, c.strength == .required {
            parts.append("required \(c.family.label.lowercased())" + (c.scope.slot.map { " \($0.label.lowercased())" } ?? ""))
        }
        parts.append(request.occasion.label)
        return parts.joined(separator: ", ")
    }

    // MARK: - Color heuristics (preferences, not universal rules)

    static func pairScore(_ a: ColorFamily, _ b: ColorFamily) -> Double {
        let pair = Set([a, b])
        // Lily's own positive examples weigh slightly more (still preferences, not rules).
        let named: [Set<ColorFamily>] = [[.navy, .pink], [.blue, .pink], [.olive, .brick]]
        if named.contains(pair) { return 2.0 }
        let discoveries: [Set<ColorFamily>] = [[.navy, .pink], [.blue, .pink], [.olive, .brick], [.navy, .burgundy],
                                               [.denim, .brick], [.brown, .cream], [.olive, .cream], [.pink, .burgundy],
                                               [.navy, .cream], [.olive, .brown], [.denim, .pink]]
        if discoveries.contains(pair) { return 1.5 }
        if pair == [.red, .green] { return -2 }
        if a == b { return 0.2 }
        if a.isNeutral && b.isNeutral { return 0.4 }
        if a.isNeutral || b.isNeutral { return 0.5 }
        return -0.3
    }

    private static func colorPairPhrase(_ look: Look) -> String? {
        let gs = look.all
        for (i, a) in gs.enumerated() {
            for b in gs[(i + 1)...] {
                guard let fa = a.color?.family, let fb = b.color?.family, pairScore(fa, fb) >= 1.5 else { continue }
                return "\(a.color!.name.lowercased()) + \(b.color!.name.lowercased())"
            }
        }
        return nil
    }

    // MARK: - Outfit text

    private static func makeOutfit(lane: LanePurpose, look: Look, request: StyleRequest, context: StylistContext) -> Outfit {
        let profile = context.profile
        let comfort = request.effectiveComfort(profile: profile)
        let pieces = look.all.map { OutfitPiece.from($0) }
        let main = look.dress ?? look.bottom
        let titleColor = [look.top?.color?.name, main?.color?.name].compactMap { $0 }.joined(separator: " & ")
        var outfit = Outfit(title: titleColor.isEmpty ? lane.title : titleColor.capitalizedFirst, lane: lane, pieces: pieces)
        outfit.occasion = request.occasion
        outfit.weatherSummary = request.weather.summary
        outfit.capturedScope = request.scope
        outfit.capturedScopeName = request.scopeName
        outfit.sourceRequestID = request.id

        let pair = colorPairPhrase(look)
        var reason: String
        switch lane {
        case .safeSimple:
            reason = "\(main?.displayName ?? "The base") with \(look.top?.displayName.lowercasedFirst ?? "a simple top") keeps it easy and polished for \(request.occasion.phrase)."
        default:
            if let pair {
                reason = "A coordinated \(pair) pairing — intentional color without being loud, in line with your chic, elegant preference."
            } else {
                reason = "\(look.top?.displayName ?? main?.displayName ?? "This look") gives a more polished, cohesive direction than your everyday basics."
            }
        }
        if let layer = look.layer, request.weather.needsLayer {
            reason += " The \(layer.displayName.lowercased()) covers \(request.weather.temperatureF)°F and \(request.weather.condition.label.lowercased())."
        }
        if let sentence = comfortSentence(today: request.comfort, effective: comfort) { reason += sentence }
        outfit.rationale = reason
        outfit.colorNote = pair.map { "Color idea: \($0)" } ?? "Mostly neutral palette"

        var fit: [String] = []
        if let fitCues = context.bodyFit, let note = measuredFitNote(look, fit: fitCues, comfort: comfort) { fit.append(note) }
        if let bottom = look.bottom, [.trousers, .jeans].contains(bottom.kind) {
            if let inseam = profile.measurement(.inseam), !inseam.confirmed {
                fit.append("Your \(inseam.displayValue) inseam isn't confirmed yet, so check the \(bottom.displayName.lowercased()) hem with the \(look.shoes.displayName.lowercased()).")
            } else if profile.measurement(.inseam) == nil {
                fit.append("Your inseam is still unknown, so check the \(bottom.displayName.lowercased()) hem with the \(look.shoes.displayName.lowercased()).")
            }
            if bottom.details.contains(where: { $0.text.lowercased().contains("navel") }) { fit.append("Waist sits near your preferred navel-area rise.") }
        }
        if let layer = look.layer, layer.details.contains(where: { $0.text.lowercased().contains("hip") }) {
            fit.append("The \(layer.displayName.lowercased()) ends at the hip, which keeps proportions balanced.")
        }
        outfit.fitNote = fit.joined(separator: " ")
        outfit.keywords = [request.occasion.label.lowercased()] + look.all.compactMap { $0.color?.family.label.lowercased() }
        return outfit
    }

    /// The rationale sentence naming the comfort a look was chosen for. Nil for the default.
    static func comfortSentence(today: Comfort?, effective: Comfort) -> String? {
        if let today { return " Chosen with today's \(today.label.lowercased()) comfort in mind." }
        return effective != .comfortable ? " Chosen with your usual fit (\(effective.label)) in mind." : nil
    }

    /// A rationale without either comfort sentence for `comfort`, for when it no longer applies.
    static func removingComfortSentence(_ comfort: Comfort, from rationale: String) -> String {
        [comfortSentence(today: comfort, effective: comfort), comfortSentence(today: nil, effective: comfort)]
            .compactMap { $0 }
            .reduce(rationale) { $0.replacingOccurrences(of: $1, with: "") }
    }

    // MARK: - Body fit (cues from confirmed measurements only)

    /// The single note used when only the rough height and weight band is known.
    static let estimateFitNote = "Using a rough estimate from your height and weight. Add waist, hip and bust in Profile for more specific fit notes."

    private static let easyCutWords = ["wide", "straight", "a-line", "full", "flare", "pleat", "relaxed", "wrap", "stretch", "drape", "baggie", "baggy"]
    private static let closeCutWords = ["skinny", "pencil", "slim", "bodycon", "sheath"]

    /// Cut words from her own names, aliases and confirmed details. Nothing is read from photos.
    private static func cutText(_ g: Garment) -> String {
        ([g.displayName] + g.aliases.map(\.text) + g.details.map(\.text)).joined(separator: " ").lowercased()
    }

    static func hasEasyCut(_ g: Garment) -> Bool {
        let text = cutText(g)
        return easyCutWords.contains { text.contains($0) }
    }

    static func hasCloseCut(_ g: Garment) -> Bool {
        let text = cutText(g)
        return closeCutWords.contains { text.contains($0) }
    }

    /// Small nudges toward room where her measurements call for it. Fitted keeps a clean,
    /// tailored line; Comfortable and Relaxed lean further into ease and drape.
    static func cueScore(_ g: Garment, cues: [BodyFit.Cue], comfort: Comfort) -> Double {
        guard !cues.isEmpty else { return 0 }
        let easy = hasEasyCut(g)
        let close = hasCloseCut(g)
        let easeBonus = comfort == .close ? 0.0 : 0.2
        var s = 0.0
        for cue in cues {
            switch cue {
            case .roomAtHip:
                guard g.category == .bottom || g.category == .dress else { continue }
                if close { s -= 0.6 }
                if easy { s += 0.5 + easeBonus } else if g.kind == .trousers, comfort == .close { s += 0.2 }
            case .roomAtBust:
                guard g.category == .top || g.category == .dress else { continue }
                switch g.kind {
                case .knitTop, .sweater: s += 0.5 + easeBonus
                case .tee: s += 0.2 + easeBonus
                case .blouse, .lacyTop: if !easy { s -= 0.3 }
                default: break
                }
                if easy { s += 0.3 }
                if close { s -= 0.4 }
            case .straighterLine:
                switch g.kind {
                case .blazer, .jacket: s += comfort == .relaxed ? 0.2 : 0.4
                case .cardigan: s += comfort == .relaxed ? 0.3 : 0.1
                default: break
                }
            }
        }
        return s
    }

    private static func isPlural(_ g: Garment) -> Bool {
        [.trousers, .jeans].contains(g.kind) || g.displayName.lowercased().hasSuffix("pants")
    }

    /// One short, neutral line on what the look does for her confirmed measurements,
    /// e.g. "Fitted with room at the hip: the olive trousers keep the line clean…".
    private static func measuredFitNote(_ look: Look, fit: BodyFit, comfort: Comfort) -> String? {
        // Measurements without cues change nothing in the look, so they get no note of their own.
        guard fit.source == .measurements, !fit.cues.isEmpty else { return nil }
        let lead = fit.fitSummary(comfort: comfort)
        for cue in fit.cues {
            if let effect = cueEffect(cue, top: look.top, bottom: look.bottom, dress: look.dress, layer: look.layer, comfort: comfort) {
                return "\(lead): \(effect)"
            }
        }
        return lead + "."
    }

    /// The effect of one cue on the pieces in a look, or nil when no piece is in that area.
    static func cueEffect(_ cue: BodyFit.Cue, top: Garment?, bottom: Garment?, dress: Garment?, layer: Garment?, comfort: Comfort) -> String? {
        func the(_ g: Garment) -> String { "the \(g.displayName.lowercased())" }
        switch cue {
        case .roomAtHip:
            guard let piece = bottom ?? dress else { return nil }
            let plural = isPlural(piece)
            if hasCloseCut(piece) {
                return "\(the(piece)) \(plural ? "are" : "is") a closer cut, so check the room through the hip and seat when you try \(plural ? "them" : "it") on."
            }
            if hasEasyCut(piece) {
                return comfort == .close
                    ? "\(the(piece)) \(plural ? "give" : "gives") room through the hip and seat while keeping the line clean."
                    : "\(the(piece)) \(plural ? "have" : "has") easy room through the hip and seat."
            }
            switch piece.kind {
            case .skirt, .dress:
                return "\(the(piece)) hangs best with room through the hip, so it doesn't pull across the seat."
            default:
                return comfort == .close
                    ? "\(the(piece)) keep the line clean. Check for room through the hip and seat when you try them on."
                    : "\(the(piece)) work best with easy room through the hip and seat, sized for the hip rather than the waist."
            }
        case .roomAtBust:
            guard let piece = top ?? dress else { return nil }
            if [.knitTop, .sweater, .tee].contains(piece.kind) || hasEasyCut(piece) {
                return "\(the(piece)) \(isPlural(piece) ? "have" : "has") some stretch through the bust, so it lies flat without pulling."
            }
            switch piece.kind {
            case .blouse:
                return "woven tops like \(the(piece)) have less give at the bust, so check that buttons and seams lie flat."
            case .lacyTop:
                return "lace has little stretch, so check that \(the(piece)) lies flat across the bust."
            default:
                return "check that \(the(piece)) has ease at the bust. Wrap or stretch fabric lies flatter."
            }
        case .straighterLine:
            if let layer, [.blazer, .jacket].contains(layer.kind) {
                return comfort == .relaxed
                    ? "\(the(layer)) adds a little structure over the easier pieces."
                    : "\(the(layer)) adds structure and a defined line."
            }
            // Only call the cut straight when the main piece really is an easy, non-close cut.
            if let main = dress ?? bottom, hasEasyCut(main), !hasCloseCut(main) {
                return "straight cuts hang cleanly here. A belt or half tuck marks the waist when you want more definition."
            }
            return "a belt or half tuck marks the waist when you want more definition."
        }
    }

    private static func makeNewPieceOutfit(base: Look, request: StyleRequest) -> Outfit {
        let bottomFamily = (base.bottom ?? base.dress)?.color?.family
        let idea: (String, GarmentKind, GarmentColor) = switch bottomFamily {
        case .olive: ("Brick ribbed knit top", .knitTop, GarmentColor(name: "Brick", hex: "A4492F", family: .brick))
        case .navy: ("Burgundy satin blouse", .blouse, GarmentColor(name: "Burgundy", hex: "6D2433", family: .burgundy))
        case .denim: ("Light pink fitted blouse", .blouse, GarmentColor(name: "Light pink", hex: "F2C4CE", family: .pink))
        default: ("Cream silk shell top", .blouse, GarmentColor(name: "Cream", hex: "EFE6D2", family: .cream))
        }
        var pieces = base.all.filter { $0.category != .top && $0.category != .dress }.map { OutfitPiece.from($0) }
        pieces.append(OutfitPiece(slot: .top, garmentID: nil, capturedName: idea.0, capturedColor: idea.2, capturedKind: idea.1,
                                  capturedImageKind: .representative, isHypothetical: true))
        var outfit = Outfit(title: "With a new \(idea.0.lowercased())", lane: .newPiece, pieces: pieces)
        outfit.occasion = request.occasion
        outfit.weatherSummary = request.weather.summary
        outfit.capturedScope = request.scope
        outfit.capturedScopeName = request.scopeName
        outfit.sourceRequestID = request.id
        outfit.rationale = "You asked for a new-piece idea: a \(idea.0.lowercased()) would pair with pieces you already own. It's not in your closet — use Already Own if you have something like it, or Find One to look deliberately."
        outfit.colorNote = "Unowned piece clearly labelled"
        return outfit
    }

    private static func hypotheticalIdeas(for request: StyleRequest) -> [Outfit] {
        let ideas: [(String, [(OutfitSlot, String, GarmentKind, GarmentColor)])] = [
            ("Navy & light pink idea", [(.top, "Light pink blouse", .blouse, .init(name: "Light pink", hex: "F2C4CE", family: .pink)),
                                        (.bottom, "Navy ankle trousers", .trousers, .init(name: "Navy", hex: "1F2A44", family: .navy)),
                                        (.shoes, "Nude flats", .flats, .init(name: "Nude", hex: "D8B79A", family: .beige))]),
            ("Olive & brick idea", [(.top, "Brick knit top", .knitTop, .init(name: "Brick", hex: "A4492F", family: .brick)),
                                    (.bottom, "Olive straight trousers", .trousers, .init(name: "Olive", hex: "5B6236", family: .olive)),
                                    (.shoes, "Tan loafers", .loafers, .init(name: "Tan", hex: "B08155", family: .tan))]),
            ("Cream & denim idea", [(.top, "Cream knit sweater", .sweater, .init(name: "Cream", hex: "EFE6D2", family: .cream)),
                                    (.bottom, "Cropped straight jeans", .jeans, .init(name: "Mid-wash denim", hex: "4A6A8F", family: .denim)),
                                    (.shoes, "White sneakers", .sneakers, .init(name: "White", hex: "F4F4F2", family: .white))]),
        ]
        return ideas.map { title, parts in
            var o = Outfit(title: title, lane: .hypothetical, pieces: parts.map {
                OutfitPiece(slot: $0.0, garmentID: nil, capturedName: $0.1, capturedColor: $0.3, capturedKind: $0.2,
                            capturedImageKind: .representative, isHypothetical: true)
            })
            o.occasion = request.occasion
            o.capturedScope = request.scope
            o.capturedScopeName = request.scopeName
            o.rationale = "A hypothetical idea from Suggestions — none of these pieces are from your closet. Mark Already Own on anything you have."
            return o
        }
    }

    private static func limitationEvidence(pre: ScopePreflight, occasion: Occasion, minFormality: Int,
                                           tops: [Garment], bottoms: [Garment], dresses: [Garment], shoes: [Garment], layers: [Garment],
                                           lookCount: Int) -> [String] {
        var lines: [String] = []
        let place = pre.scope.isSuitcase ? "in \(pre.scopeName)" : "in your saved closet"
        if pre.eligibleGarments.isEmpty, pre.excluded.isEmpty {
            return [pre.scope.isSuitcase
                ? "\(pre.scopeName) has no garments yet, so there's nothing to style here. Add garments from Main Closet, or choose another source."
                : "Your saved closet has no garments yet. Add a few items, or use Suggestions for ideas."]
        }
        func describe(_ category: GarmentCategory, _ usable: [Garment]) {
            let inScope = pre.eligible(in: category)
            let tooCasual = inScope.filter { $0.formality.rawValue < minFormality }
            let excluded = pre.excluded.filter { $0.garment.category == category }
            let noun = category == .shoes ? (usable.count == 1 ? "pair of shoes" : "pairs of shoes") : (usable.count == 1 ? category.label : category.pluralLabel).lowercased()
            var line = "\(usable.count) usable \(noun) for \(occasion.label) \(place)"
            var why: [String] = []
            if !tooCasual.isEmpty { why.append(tooCasual.map(\.displayName).joined(separator: ", ") + " too casual for \(occasion.label)") }
            if !excluded.isEmpty { why.append(excluded.map { "\($0.garment.displayName) is \($0.issues.map(\.label).joined(separator: "/"))" }.joined(separator: "; ")) }
            if !why.isEmpty { line += " — " + why.joined(separator: "; ") }
            lines.append(line + ".")
        }
        describe(.top, tops)
        describe(.bottom, bottoms)
        if !dresses.isEmpty || pre.excludedCount(in: .dress) > 0 { describe(.dress, dresses) }
        describe(.shoes, shoes)
        lines.insert(lookCount == 0
            ? "No complete look meets today's requirements \(place)."
            : "Only \(lookCount) distinct complete look\(lookCount == 1 ? "" : "s") meet\(lookCount == 1 ? "s" : "") today's requirements \(place).", at: 0)
        return lines
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}
