import SwiftUI

// MARK: - Affirmations (FR-02: curated local library, no AI)

enum StyleMeAffirmations {
    static let library: [String] = [
        "You already own more good outfits than you think.",
        "Polished doesn't have to mean complicated.",
        "Your proportions are the starting point, not a problem to fix.",
        "A little color can go a long way today.",
        "Comfortable and elegant can be the same outfit.",
        "Small details, chosen well, pull a whole look together.",
        "Dress for the day you want to have.",
        "Your style can change with your mood. That's allowed.",
        "Start with something you love and build from there.",
        "Simple pieces, put together on purpose.",
        "Chic is a habit, and you're good at it.",
        "You get to decide what feels like you.",
    ]

    /// Rotates once a day, deterministically.
    static func forDay(_ date: Date = .now, calendar: Calendar = .current) -> String {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return library[day % library.count]
    }
}

// MARK: - Small shared pieces

/// One short line with a quiet link ("Why?") that opens the full wording underneath.
struct StyleMeWhyLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var short: String
    var full: String
    var linkTitle = "Why?"
    /// What the full text is about, for the link's VoiceOver label.
    var topic: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(short)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button(isExpanded ? "Less" : linkTitle) {
                    Motion.perform(reduceMotion: reduceMotion) { isExpanded.toggle() }
                }
                .buttonStyle(.quietLinkInline)
                .fixedSize()
                .accessibilityLabel("More about \(topic)")
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
                .accessibilityHint(isExpanded ? "Hides the explanation" : "Shows the explanation")
            }
            if isExpanded {
                Text(full)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small section label with an info button for the helper text that used to sit under the control.
struct StyleMeOptionHeader: View {
    var title: String
    var info: String

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            InfoButton(title, text: info)
        }
    }
}

/// Read-only summary capsule (request chips on results).
struct StyleMeSummaryChip: View {
    var item: StyleMeSummaryItem

    var body: some View {
        Label {
            Text(item.text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(Palette.primaryAction)
        }
        .font(.footnote)
        .foregroundStyle(Palette.primaryText)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, 6)
        .background(Capsule().fill(Palette.surface))
        .overlay(Capsule().strokeBorder(Palette.divider, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

struct StyleMeSummaryItem: Identifiable, Hashable {
    var id: String
    var icon: String
    var text: String
}

/// Rounded field matching the design system (44 pt minimum, ≥3:1 outline).
struct StyleMeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .frame(minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
    }
}

/// Segmented picker that becomes a menu at accessibility text sizes (segments can't wrap).
struct StyleMeChoicePicker<Value: Hashable & Identifiable>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var title: String
    @Binding var selection: Value
    var options: [Value]
    var label: (Value) -> String
    var identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            if dynamicTypeSize.isAccessibilitySize {
                Picker(title, selection: $selection) {
                    ForEach(options) { Text(label($0)).tag($0) }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(identifier)
            } else {
                Picker(title, selection: $selection) {
                    ForEach(options) { Text(label($0)).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier(identifier)
            }
        }
    }
}

/// Visual copy of the current toast inside a sheet (the root toast sits behind sheets).
/// VoiceOver already hears the root toast's announcement, so this one doesn't announce again.
struct StyleMeSheetToast: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        if let toast = app.toast {
            ToastCard(toast: toast)
                .id(toast.id)
        }
    }
}

// MARK: - Formatting

enum StyleMeFormat {
    static func occasionText(_ occasion: Occasion, custom: String) -> String {
        let trimmed = custom.trimmingCharacters(in: .whitespacesAndNewlines)
        if occasion == .other, !trimmed.isEmpty { return "Other: \(trimmed)" }
        return occasion.label
    }

    static func modeText(scope: WardrobeScope, mode: StyleMode) -> String {
        scope.isSuitcase ? "Only this suitcase (strict)" : mode.label
    }

    static func colorText(_ c: ColorConstraint) -> String {
        "\(c.family.label) · \(c.strength.label.lowercased()) · \(c.scope.label.lowercased())"
    }

    static func colorScopePhrase(_ scope: ColorScope) -> String {
        switch scope {
        case .anyPiece: "on at least one piece"
        case .top: "on the top"
        case .bottom: "on the bottom"
        case .layer: "on the layer"
        case .shoes: "on the shoes"
        case .wholePalette: "in the overall palette"
        }
    }

    static func scopeIcon(_ scope: WardrobeScope?) -> String {
        scope?.isSuitcase == true ? "suitcase" : "cabinet"
    }

    static func summaryItems(_ request: StyleRequest, store: DemoStore) -> [StyleMeSummaryItem] {
        var items: [StyleMeSummaryItem] = [
            .init(id: "occasion", icon: request.occasion.systemImage, text: occasionText(request.occasion, custom: request.customOccasion)),
            .init(id: "source", icon: scopeIcon(request.scope), text: request.scopeName),
            .init(id: "weather", icon: request.weather.condition.systemImage,
                  text: request.weather.summary + (request.weather.source == .manual ? " (set by you)" : "")),
            .init(id: "mode", icon: request.scope.isSuitcase ? "lock" : "hanger", text: modeText(scope: request.scope, mode: request.mode)),
        ]
        if request.allowNewPiece, !request.scope.isSuitcase {
            items.append(.init(id: "newPiece", icon: "bag.badge.plus", text: "One new-piece idea"))
        }
        if let g = store.garment(request.startingItemID) {
            items.append(.init(id: "start", icon: "hanger", text: "Starting with \(g.displayName)"))
        } else if !request.startingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(.init(id: "startText", icon: "text.quote", text: "Note: “\(request.startingText.trimmingCharacters(in: .whitespacesAndNewlines))”"))
        }
        if let c = request.colorConstraint {
            items.append(.init(id: "color", icon: "paintpalette", text: colorText(c)))
        }
        if let comfort = request.comfort {
            items.append(.init(id: "comfort", icon: "figure.stand", text: "\(comfort.label) (today only)"))
        } else if let usual = request.usualFit {
            items.append(.init(id: "comfort", icon: "figure.stand", text: "\(usual.label) (your usual fit)"))
        }
        if let fit = bodyFitText(request, store: store) {
            items.append(.init(id: "bodyFit", icon: "ruler", text: fit))
        }
        if request.onMe {
            items.append(.init(id: "onMe", icon: "person.crop.rectangle", text: "Simulated pictures"))
        }
        return items
    }

    /// The fit guidance the stylist had, shown only while her profile is unchanged since the
    /// request and cloud styling is allowed. Cues or the band label only, never weight.
    static func bodyFitText(_ request: StyleRequest, store: DemoStore) -> String? {
        let profile = store.profile
        guard request.profileRevision == profile.revision, profile.permission(.cloudStyling) == .allowed else { return nil }
        let fit = profile.bodyFit
        switch fit.source {
        case .measurements: return fit.cuePhrase.map { "Fit: \($0)" } ?? "Fit: your confirmed measurements"
        case .heightAndWeightEstimate: return fit.estimatedBand.map { "Rough size estimate: around \($0.label)" }
        case .none: return nil
        }
    }

    /// Short reason a still-owned item can't be used, for issues an override can't waive.
    static func ineligibleReason(_ e: Eligibility, scopeName: String) -> String {
        if e.issues.contains(.notArrived) { return "Not arrived yet. Confirm it arrived in Closet before styling with it." }
        if e.issues.contains(.arrivalUnknown) { return "Arrival unknown. Confirm it arrived in Closet first." }
        if e.issues.contains(.noLongerOwned) { return "No longer owned. Mark it owned again in Closet to use it." }
        if e.issues.contains(.notOwned) { return "Not owned, so it can't be a starting piece." }
        if e.issues.contains(.trashed) { return "In Trash. Restore it in Closet first." }
        if e.issues.contains(.outsideSource) { return "Not in \(scopeName)." }
        return "Can't be used right now."
    }

    /// Plain status words for an overridable item ("Dirty", "Unavailable", "Archived").
    static func overridableStatus(_ e: Eligibility) -> String {
        e.issues.filter(\.isOverridable).map { $0.label.lowercased() }.joined(separator: " and ")
    }

    static func lookCount(_ n: Int) -> String { n == 1 ? "1 look" : "\(n) looks" }
}

// MARK: - Starting piece helpers (local only)

enum StyleMeStartingActions {
    /// Sets the starting piece. An override only waives Dirty/Unavailable/Archived for this request;
    /// the stored status never changes.
    static func choose(_ garment: Garment, withOverride: Bool, app: AppModel) {
        let draft = app.style.draft
        if let old = draft.startingItemID, old != garment.id { app.style.draft.overrideIDs.remove(old) }
        if withOverride { app.style.draft.overrideIDs.insert(garment.id) }
        app.style.draft.startingItemID = garment.id
        app.styleMeUI.pendingDropGarmentID = nil
        app.styleMeUI.dropMessage = nil
    }

    static func clear(app: AppModel) {
        if let id = app.style.draft.startingItemID { app.style.draft.overrideIDs.remove(id) }
        app.style.draft.startingItemID = nil
    }

    /// Explicit Mark clean from Style Me (shared canonical status) with an undo toast.
    static func markClean(_ garment: Garment, app: AppModel) {
        if app.store.markClean(garment.id) {
            app.showUndoToast("Marked \(garment.displayName) clean.")
        }
    }

    /// Garments that can appear in the starting-piece picker for a source: still-owned or once-owned
    /// records in that source (eligible, Dirty/Unavailable/Archived, not-arrived, no-longer-owned).
    static func pickerCandidates(store: DemoStore, scope: WardrobeScope) -> [Garment] {
        store.garments.filter { g in
            store.isInScope(g, scope) && !g.isTrashed && g.category != .unknown
                && [.owned, .purchasedConfirmed, .noLongerOwned].contains(g.ownership)
        }
    }
}

/// Resolves "use my navy dress pants" against personal names, other names and details, locally.
/// Nothing is sent anywhere; an unmatched color or garment-type word never counts as a match.
enum StyleMeStartingResolver {
    private static let stopWords: Set<String> = [
        "use", "using", "my", "the", "a", "an", "with", "wear", "wearing", "i", "id", "want", "to", "in", "please",
        "start", "starting", "from", "around", "build", "and", "for", "today", "some", "something", "like", "me",
        "would", "love", "maybe", "of", "on", "it", "that", "this",
    ]

    /// Everyday words people use for the same thing.
    private static let synonyms: [String: [String]] = [
        "lacy": ["lace"], "shirt": ["top", "blouse", "tee"], "pants": ["trousers", "jeans"], "baggy": ["wide", "baggie"],
        "tshirt": ["tee"], "jumper": ["sweater"], "denim": ["jeans"], "grey": ["gray"], "shoe": ["shoes"],
    ]

    private static let typeWords: Set<String> = {
        var set = Set(GarmentKind.allCases.filter { $0 != .unknown }.flatMap { words($0.label) })
        for category in GarmentCategory.allCases where category != .unknown {
            set.formUnion(words(category.label))
            set.formUnion(words(category.pluralLabel))
        }
        set.formUnion(["shirt", "pants", "shoe", "tshirt", "jumper"])
        set.remove("t")
        return set
    }()

    private static let colorWords: Set<String> = Set(ColorFamily.allCases.flatMap { words($0.label) })
        .union(["grey", "nude", "camel", "ivory", "khaki", "purple", "yellow", "orange", "plum", "lilac"])

    static func tokens(_ text: String) -> [String] {
        words(text).filter { !stopWords.contains($0) }
    }

    private static func words(_ text: String) -> [String] {
        text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }

    private static func similar(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        if a.count >= 3, b.count >= 3, a.hasPrefix(b) || b.hasPrefix(a) { return true }
        if a.count >= 5, b.count >= 5 { return a.commonPrefix(with: b).count >= 4 }
        return false
    }

    /// 3 = exact name/other name, 2 = a name contains the phrase, 1 = the words line up, 0 = no match.
    private static func strength(of garment: Garment, tokens: [String]) -> Int {
        let phrase = tokens.joined(separator: " ")
        let names = ([garment.displayName] + garment.aliases.map(\.text)).map { words($0).joined(separator: " ") }
        if names.contains(phrase) { return 3 }
        if names.contains(where: { $0.contains(phrase) || ($0.count >= 4 && phrase.contains($0)) }) { return 2 }
        var vocabulary = Set(names.flatMap { words($0) })
        for text in garment.details.map(\.text) + [garment.kind.label, garment.category.label, garment.category.pluralLabel] {
            vocabulary.formUnion(words(text))
        }
        if let color = garment.color {
            vocabulary.formUnion(words(color.name))
            vocabulary.formUnion(words(color.family.label))
        }
        let significant = tokens.filter { $0.count >= 3 }
        guard !significant.isEmpty else { return 0 }
        let unmatched = significant.filter { token in
            !([token] + (synonyms[token] ?? [])).contains { candidate in vocabulary.contains { similar($0, candidate) } }
        }
        if unmatched.isEmpty { return 1 }
        // One loose descriptive word may miss ("baggy jeans"), but never a color or garment type ("red dress").
        if unmatched.count == 1, significant.count >= 2,
           !typeWords.contains(unmatched[0]), !colorWords.contains(unmatched[0]) { return 1 }
        return 0
    }

    static func resolve(_ text: String, store: DemoStore, scope: WardrobeScope) -> StyleMeTextResolution? {
        let t = tokens(text)
        guard !t.isEmpty else { return nil }
        let pool = StyleMeStartingActions.pickerCandidates(store: store, scope: .mainCloset)
        let scored = pool.map { ($0, strength(of: $0, tokens: t)) }.filter { $0.1 > 0 }
        guard !scored.isEmpty else { return .notFound }
        let inScope = scored.filter { store.isInScope($0.0, scope) }
        if let best = inScope.map(\.1).max() {
            let top = inScope.filter { $0.1 == best }.map(\.0).sorted { $0.displayName < $1.displayName }
            return top.count == 1 ? .unique(garmentID: top[0].id) : .multiple(garmentIDs: Array(top.prefix(5).map(\.id)))
        }
        // Matches exist only outside the selected suitcase: say so, never broaden.
        let best = scored.map(\.1).max() ?? 1
        let outside = scored.filter { $0.1 == best }.map(\.0).sorted { $0.displayName < $1.displayName }
        return outside.first.map { .outsideSource(garmentID: $0.id) } ?? .notFound
    }
}

// MARK: - Blocker presentation

enum StyleMeBlockerInfo {
    static func shortText(_ blocker: StyleBlocker) -> String {
        switch blocker {
        case .permissionDeclined: "Cloud styling permission is off"
        case .allowanceExhausted: "Today's sample allowance is used up"
        case .noAccess: "Styling access isn't active"
        case .awaitingSourceChoice: "Choose a source first"
        case .startingItemIneligible: "Review your starting piece"
        case .onMeNotReady: "On Me isn't set up yet"
        }
    }

    static func anchor(_ blocker: StyleBlocker) -> StyleMeFormAnchor {
        switch blocker {
        case .awaitingSourceChoice: .source
        default: .blockers
        }
    }
}
