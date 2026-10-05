import Foundation

/// Scripted Ask Stylist answers. Deterministic, closet-first, and bound by the
/// same eligibility rules as Style Me: any look it returns uses eligible
/// canonical IDs from the complete-scope preflight, plus at most one labelled
/// unowned idea when the user chose "Closet + new ideas" in Main Closet.
extension MockStylist {
    func answer(question: String, attachedOutfit: Outfit?, mode: StylistChatMode,
                baseRequest: StyleRequest, context: StylistContext) async throws -> StylistAnswer {
        log.record(.stylist, "askStylist")
        try await Task.sleep(nanoseconds: UInt64(timing().stylistDelay * 1_000_000_000))
        try Task.checkCancellation()
        if scenario() == .offlineAI { throw ServiceError.offline }
        return Self.compose(question: question, attached: attachedOutfit, mode: mode, base: baseRequest, context: context)
    }

    // MARK: - Intent handling

    static func compose(question: String, attached: Outfit?, mode: StylistChatMode,
                        base: StyleRequest, context: StylistContext) -> StylistAnswer {
        let q = " " + question.lowercased().replacingOccurrences(of: "[^a-z0-9' ]", with: " ", options: .regularExpression) + " "
        let pre = context.preflight
        let mentioned = mentionedGarments(in: q, pool: pre.eligibleGarments)
        let blockedMention = mentionedGarments(in: q, pool: pre.excluded.map(\.garment)).first
        let occasion = occasion(in: q)

        // 1. A mentioned piece isn't usable right now: say why, never substitute silently.
        if mentioned.isEmpty, let blocked = blockedMention,
           let issues = pre.excluded.first(where: { $0.garment.id == blocked.id })?.issues {
            let reason = issues.map(\.label).joined(separator: ", ").lowercased()
            return StylistAnswer(
                text: "\(blocked.displayName) is \(reason) in \(pre.scopeName), so I can't put it in a look right now. " + remedy(for: issues, scopeName: pre.scopeName),
                outfit: nil,
                followUps: ["What else could I wear instead?", "Which colors suit my closet?"])
        }

        // 2. Attached look + "would X work?" → evaluate a one-piece swap.
        if let attached, let garment = mentioned.first, let slot = OutfitSlot.slot(for: garment.category) {
            var variant = attached
            var newPiece = OutfitPiece.from(garment, slot: slot)
            if let i = variant.pieces.firstIndex(where: { $0.slot == slot }) {
                newPiece.id = variant.pieces[i].id
                variant.pieces[i] = newPiece
            } else {
                variant.pieces.append(newPiece)
            }
            variant.title = attached.title + " · with \(garment.displayName.lowercased())"
            variant.lane = .manual
            variant.capturedScope = base.scope
            variant.capturedScopeName = base.scopeName
            let target = occasion ?? attached.occasion ?? base.occasion
            var verdict: String
            if garment.formality.rawValue < target.formalityRange.lowerBound {
                verdict = "\(garment.displayName) would work, but it reads more casual than \(target.phrase). Keep it for a relaxed version of this look."
            } else if garment.formality == .dressy, target.formalityRange.upperBound < 2 {
                verdict = "\(garment.displayName) is a little dressy for \(target.phrase), but it can look intentional if the rest stays simple."
            } else {
                verdict = "Yes — \(garment.displayName.lowercased()) fits \(target.phrase) and keeps the look cohesive."
            }
            if let color = garment.color,
               let other = attached.pieces.first(where: { $0.slot != slot && $0.capturedColor != nil })?.capturedColor {
                let score = pairScore(color.family, other.family)
                if score >= 1.5 { verdict += " \(color.name) with \(other.name.lowercased()) is one of your favorite kinds of pairing." }
                else if score < 0 { verdict += " The \(color.name.lowercased()) and \(other.name.lowercased()) might compete — a neutral piece would calm it." }
            }
            if let effect = cueSentence(for: garment, context: context, comfort: base.effectiveComfort(profile: context.profile)) {
                verdict += " " + effect
            }
            verdict += " Only that one piece changes; everything else stays as it was."
            return StylistAnswer(text: verdict, outfit: variant,
                                 followUps: ["Make it warmer for rain", "Is this too dressy for brunch?", "What shoes would be safest?"])
        }

        // 2b. "Too tight?" / "more room" / "too loose" → answer from her fit cues, never a guess.
        if let direction = fitDirection(in: q) {
            return fitAnswer(direction: direction, q: q, attached: attached, mentioned: mentioned.first,
                             occasion: occasion, base: base, context: context)
        }

        // 3. Warmer / rain → add a layer to the attached look.
        if let attached, q.contains(" warm") || q.contains(" rain") || q.contains(" cold") || q.contains(" chilly") || q.contains(" layer") {
            let layers = pre.eligible(in: .layer).filter { l in !attached.pieces.contains { $0.garmentID == l.id } }
            let families = attached.pieces.compactMap { $0.capturedColor?.family }
            if let best = layers.max(by: { a, b in harmony(a, families) < harmony(b, families) }) {
                var variant = attached
                var layer = OutfitPiece.from(best, slot: .layer)
                if let i = variant.pieces.firstIndex(where: { $0.slot == .layer }) {
                    layer.id = variant.pieces[i].id
                    variant.pieces[i] = layer
                } else {
                    variant.pieces.append(layer)
                }
                variant.title = attached.title + " · warmer"
                variant.lane = .manual
                variant.capturedScope = base.scope
                variant.capturedScopeName = base.scopeName
                return StylistAnswer(
                    text: "Add your \(best.displayName.lowercased()) — it covers \(base.weather.temperatureF)°F and \(base.weather.condition.label.lowercased()) without changing the rest of the look." + (best.details.first.map { " (\($0.text.lowercased()))" } ?? ""),
                    outfit: variant,
                    followUps: ["Would white sneakers work with this?", "Which colors suit my closet?"])
            }
            return StylistAnswer(text: "There's no eligible layer in \(pre.scopeName) right now. A cardigan or jacket you own — once it's clean or added — would be the easiest fix.",
                                 outfit: nil, followUps: ["What else could I wear instead?"])
        }

        // 4. Colour advice.
        if q.contains(" color") || q.contains(" colour") || q.contains(" palette") || q.contains(" pair") && mentioned.isEmpty {
            let pairs = context.profile.likedColorPairs.joined(separator: " and ")
            let owned = Set(pre.eligibleGarments.compactMap { $0.color?.family })
            var example = ""
            if owned.contains(.olive), owned.contains(.brick) { example = " You already own both halves of olive + brick: your olive trousers and brick knit top." }
            else if owned.contains(.navy), owned.contains(.pink) { example = " Your navy dress pants with the cute pink shirt is an easy navy + pink." }
            return StylistAnswer(
                text: "You like \(pairs.isEmpty ? "soft, coordinated pairings" : pairs). Muted contrasts suit your chic, less trend-driven style better than loud ones.\(example) Monochrome is always fine too.",
                outfit: nil,
                followUps: ["What goes with my olive trousers?", "An outfit for a gallery opening"])
        }

        // 5. "What goes with X" / a named piece, or an occasion → build a look.
        if !mentioned.isEmpty || occasion != nil {
            var request = base
            request.occasion = occasion ?? base.occasion
            if let piece = mentioned.first { request.startingItemID = piece.id }
            let result = compose(request: request, context: context)
            let looks = result.outfits
            // An all-idea look is only used when nothing with her own clothes exists.
            let pick = looks.first(where: { $0.lane == .elevated }) ?? looks.first(where: { $0.lane == .newPiece && mode == .closetPlusIdeas })
                ?? looks.first(where: { $0.lane != .hypothetical }) ?? looks.first
            if var look = pick {
                let unowned = look.pieces.filter(\.isHypothetical).count
                if look.lane != .hypothetical { look.lane = unowned > 0 ? .newPiece : .manual }
                let lead = mentioned.first.map { "Here's a way to wear your \($0.displayName.lowercased())" } ?? "Here's an idea for \(request.occasion.phrase)"
                let using = switch unowned {
                case 0: "only clothes you own in \(pre.scopeName)"
                case look.pieces.count: "an idea made only of pieces you don't own (labelled)"
                case 1: "your clothes plus one idea you don't own (labelled)"
                default: "your clothes plus \(unowned) ideas you don't own (labelled)"
                }
                var text = "\(lead), using \(using). " + look.rationale
                if !look.fitNote.isEmpty { text += " " + look.fitNote }
                if context.bodyFit?.source == .heightAndWeightEstimate, !text.contains(estimateFitNote) { text += " " + estimateFitNote }
                return StylistAnswer(text: text, outfit: look,
                                     followUps: ["Make it warmer for rain", "Would white sneakers work with this?", "Which colors suit my closet?"])
            }
            if case let .insufficientWardrobe(evidence) = result {
                return StylistAnswer(text: "I couldn't make a complete look in \(pre.scopeName) for that. " + (evidence.first ?? ""),
                                     outfit: nil, followUps: ["Which colors suit my closet?"])
            }
        }

        // 6. Fallback: explain what it can do, briefly.
        return StylistAnswer(
            text: "I can build a look from your closet, check whether one piece would work in a look, make a look warmer, find more room or a closer fit, or talk through colors. I won't search stores or buy anything unless you choose Find One.",
            outfit: nil,
            followUps: ["What goes with my olive trousers?", "An outfit for a gallery opening", "Which colors suit my closet?"])
    }

    // MARK: - Fit questions

    private enum FitDirection {
        /// "Too tight", "more room": lean Relaxed for this answer.
        case moreRoom
        /// "Too loose", "baggy": lean Fitted for this answer.
        case closer

        var comfort: Comfort { self == .moreRoom ? .relaxed : .close }
    }

    private static func fitDirection(in q: String) -> FitDirection? {
        let closer = [" too loose", " baggy", " too big", " more fitted", " more tailored", " closer fit", " shapeless", " sloppy"]
        let room = [" tight ", " tighter", " too fitted", " snug", " more room", " roomier", " roomy", " looser", " pulling", " pulls ",
                    " gape", " gaping", " comfier", " more relaxed"]
        if closer.contains(where: { q.contains($0) }) { return .closer }
        if room.contains(where: { q.contains($0) }) { return .moreRoom }
        return nil
    }

    /// Which part of a look the question is about: the hip and waist mean the bottom,
    /// the bust and chest mean the top. Otherwise her first cue decides, if she has one.
    private static func fitArea(in q: String, fit: BodyFit?) -> GarmentCategory? {
        if [" hip", " seat", " thigh", " waist"].contains(where: { q.contains($0) }) { return .bottom }
        if [" bust", " chest", " button", " shoulder"].contains(where: { q.contains($0) }) { return .top }
        guard fit?.source == .measurements else { return nil }
        if fit?.cues.contains(.roomAtHip) == true { return .bottom }
        if fit?.cues.contains(.roomAtBust) == true { return .top }
        return nil
    }

    /// What the stylist actually knows, said plainly. Weight and measurement numbers never appear.
    private static func fitKnowledge(_ fit: BodyFit?) -> String {
        guard let fit else { return "I don't know your waist, hip or bust, so I can't tell where a piece might feel tight. Unknown stays unknown." }
        switch fit.source {
        case .measurements:
            if let cues = fit.cuePhrase { return "Your confirmed measurements point to \(cues)." }
            return "Your confirmed measurements don't call for extra room in one spot."
        case .heightAndWeightEstimate:
            let band = fit.estimatedBand.map { " (around \($0.label))" } ?? ""
            return "I only have a rough estimate from your height and weight\(band), so I can't tell where a piece might feel tight. Adding waist, hip and bust in Profile would help."
        case .none:
            return "I don't know your waist, hip or bust, so I can't tell where a piece might feel tight. Unknown stays unknown."
        }
    }

    /// The cue for an area: her own when she has it, otherwise the area's general one.
    private static func cue(for area: GarmentCategory) -> BodyFit.Cue {
        area == .top ? .roomAtBust : .roomAtHip
    }

    /// How a piece answers one of her cues, as a full sentence. Nil when it isn't in a cue area.
    private static func cueSentence(for garment: Garment, context: StylistContext, comfort: Comfort) -> String? {
        guard let fit = context.bodyFit, fit.source == .measurements else { return nil }
        for cue in fit.cues {
            let effect = cueEffect(cue, top: garment.category == .top ? garment : nil,
                                   bottom: garment.category == .bottom ? garment : nil,
                                   dress: garment.category == .dress ? garment : nil,
                                   layer: garment.category == .layer ? garment : nil, comfort: comfort)
            if let effect { return effect.capitalizedFirst }
        }
        return nil
    }

    /// Ease (or tailoring, for a closer fit) a piece offers in the area being asked about.
    private static func fitScore(_ g: Garment, area: GarmentCategory, direction: FitDirection) -> Double {
        let room = cueScore(g, cues: [cue(for: area)], comfort: .relaxed)
        switch direction {
        case .moreRoom: return room
        case .closer: return -room + ([.blouse, .trousers].contains(g.kind) ? 0.3 : 0)
        }
    }

    private static func fitAnswer(direction: FitDirection, q: String, attached: Outfit?, mentioned: Garment?,
                                  occasion: Occasion?, base: StyleRequest, context: StylistContext) -> StylistAnswer {
        let pre = context.preflight
        let fit = context.bodyFit
        let knowledge = fitKnowledge(fit)
        let usual = base.effectiveComfort(profile: context.profile)
        let unchanged = base.comfort == nil
            ? " Your usual fit (\(usual.label)) hasn't changed."
            : " Today's \(usual.label.lowercased()) setting hasn't changed."
        let want = direction == .moreRoom ? "more room" : "a closer fit"

        // An attached look: swap only the piece in that area for one with more ease (or more shape).
        if let attached {
            guard let area = fitArea(in: q, fit: fit) else {
                return StylistAnswer(text: knowledge + " Tell me where it feels \(direction == .moreRoom ? "tight" : "loose"), at the waist, hip or bust, and I'll swap just that piece.",
                                     outfit: nil, followUps: ["It feels tight at the hip", "It pulls at the bust"])
            }
            // A dress covers both areas, so it's the piece that changes in a dress look.
            let swapCategory: GarmentCategory = attached.pieces.contains { $0.slot == .dress } ? .dress : area
            let slot: OutfitSlot = swapCategory == .dress ? .dress : (area == .top ? .top : .bottom)
            let current = attached.pieces.first { $0.slot == slot }
            let currentGarment = current?.garmentID.flatMap { id in pre.eligibleGarments.first { $0.id == id } }
            let target = occasion ?? attached.occasion ?? base.occasion
            let pool = pre.eligible(in: swapCategory).filter { $0.id != current?.garmentID }
            let suitable = pool.filter { $0.formality.rawValue >= target.formalityRange.lowerBound }
            let floor = currentGarment.map { fitScore($0, area: area, direction: direction) } ?? -.infinity
            guard let best = (suitable.isEmpty ? pool : suitable).max(by: { fitScore($0, area: area, direction: direction) < fitScore($1, area: area, direction: direction) }),
                  fitScore(best, area: area, direction: direction) > floor else {
                let name = currentGarment.map { "Your \($0.displayName.lowercased())" } ?? "This piece"
                return StylistAnswer(text: knowledge + " \(name) is already the best option for \(want) in \(pre.scopeName). If it still doesn't feel right, the fit reference in Profile is a good place to note it.",
                                     outfit: nil, followUps: ["What else could I wear instead?", "Which colors suit my closet?"])
            }
            var variant = attached
            var piece = OutfitPiece.from(best, slot: slot)
            if let i = variant.pieces.firstIndex(where: { $0.slot == slot }) {
                piece.id = variant.pieces[i].id
                variant.pieces[i] = piece
            } else {
                variant.pieces.append(piece)
            }
            variant.title = attached.title + (direction == .moreRoom ? " · more room" : " · closer fit")
            variant.lane = .manual
            variant.capturedScope = base.scope
            variant.capturedScopeName = base.scopeName
            let effect = cueEffect(cue(for: area), top: swapCategory == .top ? best : nil, bottom: swapCategory == .bottom ? best : nil,
                                   dress: swapCategory == .dress ? best : nil, layer: nil, comfort: direction.comfort)
            var text = knowledge + " For \(want), try your \(best.displayName.lowercased()) instead"
            text += current.map { " of the \($0.capturedName.lowercased())." } ?? "."
            if direction == .moreRoom, let effect { text += " " + effect.capitalizedFirst }
            text += " Only that one piece changes; everything else stays as it was." + unchanged
            return StylistAnswer(text: text, outfit: variant,
                                 followUps: ["Make it warmer for rain", "Which colors suit my closet?"])
        }

        // No look yet: build one that leans Relaxed (or Fitted) for this answer only.
        var request = base
        request.comfort = direction.comfort
        request.occasion = occasion ?? base.occasion
        if let mentioned { request.startingItemID = mentioned.id }
        let result = compose(request: request, context: context)
        guard let look = result.outfits.first(where: { $0.lane != .hypothetical }) ?? result.outfits.first else {
            return StylistAnswer(text: knowledge + " I couldn't make a complete look in \(pre.scopeName) for that right now.",
                                 outfit: nil, followUps: ["Which colors suit my closet?"])
        }
        var styled = look
        if styled.lane != .hypothetical { styled.lane = styled.pieces.contains(where: \.isHypothetical) ? .newPiece : .manual }
        // The lean is for this answer only, so the rationale doesn't call it today's comfort.
        styled.rationale = removingComfortSentence(direction.comfort, from: look.rationale)
        let note = look.fitNote.replacingOccurrences(of: estimateFitNote, with: "").trimmingCharacters(in: .whitespaces)
        var text = knowledge + " Here's a look that leans \(direction.comfort.label.lowercased()) for \(request.occasion.phrase), just for this answer. " + styled.rationale
        if !note.isEmpty { text += " " + note }
        text += unchanged
        return StylistAnswer(text: text, outfit: styled,
                             followUps: ["Make it warmer for rain", "Would white sneakers work with this?"])
    }

    // MARK: - Helpers

    /// What she can actually do about a blocked piece, from its real issues.
    private static func remedy(for issues: [EligibilityIssue], scopeName: String) -> String {
        if Eligibility(issues: issues).canOverride {
            let clean = issues.contains(.dirty) ? "mark it clean in Closet or " : ""
            return "You can \(clean)use it once for a request from Style Me — its status won't change unless you say so."
        }
        if issues.contains(.notArrived) || issues.contains(.arrivalUnknown) { return "Once it arrives, confirm arrival in Closet and I can style it." }
        if issues.contains(.noLongerOwned) { return "It's kept for history only. If you have it again, choose “I own this again” in Closet." }
        if issues.contains(.outsideSource) { return "It isn't in \(scopeName). Add it there, or switch the source, to use it." }
        return ""
    }

    private static func harmony(_ garment: Garment, _ families: [ColorFamily]) -> Double {
        guard let f = garment.color?.family else { return 0 }
        return families.map { pairScore(f, $0) }.reduce(0, +)
    }

    private static func occasion(in q: String) -> Occasion? {
        let map: [(String, Occasion)] = [(" interview", .office), (" office", .office), (" work", .office), (" meeting", .office),
                                         (" date", .dateNight), (" dinner", .dateNight), (" brunch", .brunch), (" concert", .concert),
                                         (" gig", .concert), (" wedding", .event), (" party", .event), (" gala", .event),
                                         (" opening", .event), (" event", .event), (" casual", .casual), (" weekend", .casual)]
        return map.first { q.contains($0.0) }?.1
    }

    /// Garments the question names: by personal name/alias, or by kind plus colour.
    private static func mentionedGarments(in q: String, pool: [Garment]) -> [Garment] {
        func words(_ s: String) -> [String] {
            s.lowercased().replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
                .split(separator: " ").map(String.init).filter { $0.count > 2 }
        }
        var scored: [(Garment, Int)] = []
        for g in pool {
            var score = 0
            for name in [g.displayName] + g.aliases.map(\.text) {
                let w = words(name)
                if !w.isEmpty, w.allSatisfy({ q.contains(" \($0)") }) { score = max(score, 10 + w.count) }
            }
            let kindWords = words(g.kind.label) + (g.kind == .trousers ? ["pants"] : []) + (g.kind == .sneakers ? ["trainers"] : [])
            let kindHit = kindWords.contains { q.contains(" \($0)") }
            let colorHit = [g.color?.family.label, g.color?.name].compactMap { $0 }.flatMap(words).contains { q.contains(" \($0)") }
            if kindHit && colorHit { score = max(score, 6) }
            if score > 0 { scored.append((g, score)) }
        }
        return scored.sorted { $0.1 > $1.1 }.map(\.0)
    }
}
