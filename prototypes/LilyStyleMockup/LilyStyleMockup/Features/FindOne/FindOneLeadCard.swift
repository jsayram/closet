import SwiftUI

/// One sourced (simulated) lead. Fit evidence comes first, then style, then
/// stock/shipping and citations. Actions never imply ownership.
struct FindOneLeadCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var candidate: ShoppingCandidate
    var record: FindOneSearchRecord
    @Bindable var session: FindOneSession
    var onCitation: (EvidenceItem) -> Void
    var onViewAtStore: () -> Void
    var onBought: () -> Void

    private var isUnverifiedLead: Bool {
        !candidate.isDirectProductPage || candidate.evidence.contains { $0.sourceType == .snippet }
    }

    private var purchased: Garment? { app.store.findOnePurchasedGarment(for: candidate) }

    private var isSaved: Bool {
        app.store.savedProducts.contains { $0.candidate.id == candidate.id }
    }

    private var badges: [BadgeKind] {
        // The row scrolls sideways, so what she needs before spending comes first.
        var list: [BadgeKind] = [.simulated]
        if record.isOverBudget(candidate), let budget = record.intent.budgetMax {
            list.append(.custom("Over your $\(budget) budget", "exclamationmark.circle"))
        }
        if isUnverifiedLead { list.append(.custom("Unverified lead", "questionmark.diamond")) }
        if purchased != nil { list.append(.custom("In your closet — you confirmed buying it", "checkmark.seal")) }
        if isSaved { list.append(.custom("Saved — not owned", "bookmark.fill")) }
        if record.isPreferred(candidate) { list.append(.custom("Preferred store", "star")) }
        if let tier = candidate.priceTier { list.append(.custom(tier.label, "tag")) }
        return list
    }

    private func openState(_ part: String) -> Binding<Bool> {
        session.detailsBinding("\(candidate.id)|\(part)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            identity
            ChipCarousel(spacing: Spacing.xxs, isExpanded: openState("badges"), itemsLabel: "badges", toggleSize: 24) {
                ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                    StatusBadge(kind: badge, compact: true)
                }
            }
            fitBlock
            styleBlock
            evidenceLabels
            VStack(alignment: .leading, spacing: 0) {
                FindOneSourcesList(candidate: candidate, isExpanded: openState("sources"), onCitation: onCitation)
                worksWith
            }
            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneLead-\(candidate.id)")
    }

    // MARK: Identity

    private var identity: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.s))
        return layout {
            FindOneProductTile(candidate: candidate, size: 76, showsCaption: true)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(candidate.retailer) · \(candidate.domain)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(candidate.title)
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(FindOneFormat.price(candidate)) · sample price")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                HStack(spacing: Spacing.xxs + 2) {
                    ColorSwatch(hex: candidate.colorHex, size: 14)
                    Text(candidate.colorName)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Listed color: \(candidate.colorName)")
            }
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 0) }
            saveForLater
        }
    }

    // MARK: Fit first

    private var unrankedGuidance: String {
        switch candidate.kind.defaultCategory {
        case .bottom: "Check the store's size chart: compare the garment inseam and rise with a pair that fits you well, and the waist with your confirmed measurement."
        case .top, .dress: "Check the store's size chart: compare bust and garment length with a top that fits you well."
        case .layer: "Check body and sleeve length against a jacket that fits — some jackets run long on you."
        case .shoes: "Check the store's size system and width against shoes that fit."
        default: "Check the store's size information before buying."
        }
    }

    private var unrankedNote: String {
        app.store.profile.permission(.fitRanking) == .allowed
            ? "Not compared with your fit profile yet."
            : "Not compared with your fit profile — private fit comparison is off."
    }

    private var fitBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    fitHeading
                    Spacer(minLength: Spacing.xs)
                    FindOneFitBadge(state: candidate.fitState, unranked: !record.isRanked)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    fitHeading
                    FindOneFitBadge(state: candidate.fitState, unranked: !record.isRanked)
                }
            }
            if record.isRanked {
                CollapsibleText(candidate.fitReason.isEmpty ? "No fit reasoning was returned for this lead." : candidate.fitReason,
                                font: .subheadline, color: Palette.primaryText, topic: "the fit of \(candidate.title)",
                                isExpanded: openState("fitReason"))
                if !candidate.comparedDimensions.isEmpty || !candidate.unknowns.isEmpty {
                    DetailsDisclosure("Fit evidence", summary: evidenceSummary, isExpanded: openState("fit"),
                                      identifier: "findOneFitEvidence-\(candidate.id)") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            FindOneBulletList(title: "Compared", items: candidate.comparedDimensions, systemImage: "checkmark.circle", tint: Palette.success)
                            FindOneBulletList(title: "Unknown", items: candidate.unknowns, systemImage: "questionmark.circle", tint: Palette.primaryAction)
                        }
                    }
                }
                if let estimate = candidate.sizeEstimate {
                    sizeEstimateNote(estimate)
                }
                if let size = candidate.recommendedSize {
                    // The caveat stays on the line; the full sentence is behind the info button.
                    HStack(alignment: .top, spacing: Spacing.xxs) {
                        Label {
                            Text("Sourced size guidance: \(size) · not a guarantee")
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "ruler")
                        }
                        .foregroundStyle(Palette.success)
                        InfoButton("this size guidance", title: "Sourced size guidance",
                                   text: "Sourced size guidance: \(size). Not a guarantee — the retailer confirms the final size.")
                    }
                }
            } else {
                CollapsibleText("\(unrankedNote) \(unrankedGuidance)", summary: unrankedNote,
                                threshold: 1, font: .subheadline, color: Palette.primaryText,
                                topic: "checking the fit of \(candidate.title)", isExpanded: openState("fitReason"))
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    /// "2 unknown · 3 compared": the counts stay on the closed row, unknowns first, so they are never out of sight.
    private var evidenceSummary: String {
        var parts: [String] = []
        if !candidate.unknowns.isEmpty { parts.append("\(candidate.unknowns.count) unknown") }
        if !candidate.comparedDimensions.isEmpty { parts.append("\(candidate.comparedDimensions.count) compared") }
        return parts.joined(separator: " · ")
    }

    /// The rough height-and-weight estimate, set apart so it never reads as sizing guidance.
    private func sizeEstimateNote(_ estimate: LeadSizeEstimate) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Label("Rough estimate, not measured", systemImage: "circle.dashed")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.secondaryText)
            CollapsibleText("\(estimate.note) \(estimate.closeness) Add your waist, hip and bust in Profile to compare this size chart instead.",
                            summary: "Around \(estimate.bandLabel) · not a fit check", threshold: 1, color: Palette.primaryText,
                            topic: "the rough size estimate", isExpanded: openState("estimate"))
        }
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .strokeBorder(Palette.controlBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneSizeEstimate-\(candidate.id)")
    }

    private var fitHeading: some View {
        Text("Fit first")
            .font(.caption.weight(.bold))
            .foregroundStyle(Palette.secondaryText)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: Style

    private var styleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Why it suits this look")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.secondaryText)
                .textCase(.uppercase)
            CollapsibleText(candidate.styleReason, threshold: 1, font: .subheadline, color: Palette.primaryText,
                            topic: "why it suits this look", isExpanded: openState("style"))
        }
    }

    // MARK: Stock / shipping evidence

    /// Stock and shipping problems wrap in full so they're never scrolled out of
    /// sight; the neutral notes share one scrolling row.
    private var evidenceLabels: some View {
        let stockCaution = candidate.stock != .inStock
        let shippingCaution = candidate.shipping != .shipsToDestination
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            if stockCaution || shippingCaution {
                FlowLayout(spacing: Spacing.xs) {
                    if stockCaution { stockLabel }
                    if shippingCaution { shippingLabel }
                }
            }
            ChipCarousel(isExpanded: openState("stock"), itemsLabel: "stock and shipping notes", toggleSize: 24) {
                if !stockCaution { stockLabel }
                if !shippingCaution { shippingLabel }
                evidenceLabel("Retrieved \(FindOneFormat.relative(candidate.retrievedAt))", icon: "clock", caution: false)
            }
        }
    }

    private var stockLabel: some View {
        evidenceLabel(candidate.stock == .unavailable ? "Variant unavailable — not a purchasable match right now" : candidate.stock.label,
                      icon: candidate.stock == .inStock ? "shippingbox" : "exclamationmark.circle",
                      caution: candidate.stock != .inStock)
    }

    private var shippingLabel: some View {
        evidenceLabel(candidate.shipping.label,
                      icon: candidate.shipping == .shipsToDestination ? "box.truck" : "questionmark.circle",
                      caution: candidate.shipping != .shipsToDestination)
    }

    private func evidenceLabel(_ text: String, icon: String, caution: Bool) -> some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
        }
        .font(.caption)
        .foregroundStyle(caution ? Palette.primaryText : Palette.secondaryText)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 4)
        .background(Capsule().fill(caution ? Palette.accentSurface : Palette.imageWell))
        .accessibilityElement(children: .combine)
    }

    // MARK: Works with my closet

    private var worksWith: some View {
        let title = session.context.scope.isSuitcase ? "Works with this suitcase" : "Works with my closet"
        let isOpen = Binding(
            get: { session.openWorksWith.contains(candidate.id) },
            set: { open in
                if open { session.openWorksWith.insert(candidate.id) } else { session.openWorksWith.remove(candidate.id) }
            }
        )
        return DetailsDisclosure(title, systemImage: "square.grid.2x2", isExpanded: isOpen,
                                 identifier: "worksWithCloset-\(candidate.id)") {
            FindOneWorksWithView(candidate: candidate, context: session.context,
                                 isNoteExpanded: openState("worksWithNote"))
        }
    }

    // MARK: Actions

    private var viewAtStore: some View {
        Button(action: onViewAtStore) {
            Label("View at Store", systemImage: "arrow.up.forward.app")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
        .accessibilityHint("Opens a simulated store page. Your look and this product are saved first.")
        .accessibilityIdentifier("viewAtStoreButton-\(candidate.id)")
    }

    /// Bookmark beside the product name. Once saved it's a status, not an action:
    /// removal lives in Saved products, and a "Saved — not owned" badge says so in words.
    @ViewBuilder private var saveForLater: some View {
        if isSaved {
            Image(systemName: "bookmark.fill")
                .font(.title3)
                .foregroundStyle(Palette.success)
                .frame(width: HitTarget.minimum, height: HitTarget.minimum)
                .accessibilityLabel("Saved for later — not owned")
                .accessibilityHint("Manage it in Saved products.")
                .accessibilityIdentifier("saveForLaterButton-\(candidate.id)")
        } else {
            Button {
                app.store.saveForLater(candidate, context: session.context)
            } label: {
                Image(systemName: "bookmark")
                    .font(.title3)
                    .foregroundStyle(Palette.primaryAction)
                    .frame(width: HitTarget.minimum, height: HitTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel("Save for Later")
            .accessibilityHint("Keeps a private reference. It doesn't make it yours.")
            .accessibilityIdentifier("saveForLaterButton-\(candidate.id)")
        }
    }

    private var bought: some View {
        Button(action: onBought) {
            Label(purchased == nil ? "I bought this" : "Review purchase", systemImage: "checkmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
        .accessibilityHint(purchased == nil
                           ? "Review the size and color you actually got, and whether it has arrived"
                           : "Updates the item you already added — no duplicate is created")
        .accessibilityIdentifier("iBoughtThisButton-\(candidate.id)")
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.xs) {
                viewAtStore
                bought
            }
            VStack(spacing: Spacing.xs) {
                viewAtStore
                bought
            }
        }
    }
}

// MARK: - Sources

/// Tappable citations. In this prototype every source is fictional.
struct FindOneSourcesList: View {
    var candidate: ShoppingCandidate
    /// Shared open state, so rotation keeps the list open. Nil keeps it in the row.
    var isExpanded: Binding<Bool>? = nil
    var onCitation: (EvidenceItem) -> Void

    var body: some View {
        DetailsDisclosure("Sources", count: candidate.evidence.count, systemImage: "link", isExpanded: isExpanded,
                          identifier: "findOneEvidenceToggle-\(candidate.id)") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(candidate.evidence.enumerated()), id: \.element.id) { index, item in
                    Button {
                        onCitation(item)
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            Text("[\(index + 1)]")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Palette.primaryAction)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.claim)
                                    .font(.caption)
                                    .foregroundStyle(Palette.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(item.sourceType.label) · \(item.sourceLabel) · retrieved \(FindOneFormat.relative(item.retrievedAt))")
                                    .font(.caption2)
                                    .foregroundStyle(Palette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(Palette.primaryAction)
                                .accessibilityHidden(true)
                        }
                        .padding(.vertical, Spacing.xxs)
                        .frame(minHeight: HitTarget.minimum)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Source \(index + 1): \(item.sourceType.label), \(item.sourceLabel). \(item.claim)")
                    .accessibilityHint("Shows that this source is simulated")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("findOneEvidence-\(candidate.id)-\(index)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneEvidence-\(candidate.id)")
    }
}

// MARK: - Works with my closet

/// Local, metadata-only compatibility. Uses only eligible recorded items in the
/// captured source; counts are honest and never padded.
struct FindOneWorksWithView: View {
    @Environment(AppModel.self) private var app
    var candidate: ShoppingCandidate
    var context: FindOneContext
    var isNoteExpanded: Binding<Bool>? = nil

    var body: some View {
        let compat = app.store.findOneCompatibility(for: candidate, slot: context.slot, scope: context.scope)
        let scopeName = app.store.scopeName(context.scope)
        let count = compat.combinations.count
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(countText(count: count, scopeName: scopeName, missing: compat.missingSlots))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(compat.combinations.enumerated()), id: \.element.id) { index, combo in
                comboRow(index: index, combo: combo)
            }
            CollapsibleText("Uses only eligible items recorded in \(scopeName) — not a claim about clothes you haven't added. The new piece is marked and stays outside \(context.scope.isSuitcase ? "this suitcase" : "your closet") until you buy and add it. Local only — nothing is sent.",
                            summary: "Local only. Uses eligible items recorded in \(scopeName).",
                            threshold: 1, font: .caption, topic: "these looks", isExpanded: isNoteExpanded)
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .accessibilityElement(children: .contain)
    }

    private func countText(count: Int, scopeName: String, missing: [OutfitSlot]) -> String {
        switch count {
        case 0:
            let what = missing.first.map { "no eligible \($0.category.pluralLabel.lowercased())" } ?? "not enough eligible pieces"
            return "No complete look yet with eligible items in \(scopeName) — \(what)."
        case 1:
            return "1 look with eligible items in \(scopeName) — that's all that's possible right now."
        case 2:
            return "2 looks with eligible items in \(scopeName) — that's all that's possible right now."
        default:
            return "\(count) looks with eligible items in \(scopeName)"
        }
    }

    private func comboRow(index: Int, combo: FindOneCombination) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                FindOneProductTile(candidate: candidate, size: 52)
                ForEach(combo.garments) { garment in
                    GarmentThumbnail(garment: garment, size: 52, showsStatus: false)
                }
            }
            Text("Look \(index + 1): \(candidate.title) (new — not owned) + \(combo.garments.map(\.displayName).joined(separator: " + "))")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Look \(index + 1): \(candidate.title), new and not owned, with \(combo.garments.map(\.accessibilityDescription).joined(separator: "; "))")
    }
}

// MARK: - Excluded lead

/// A lead with a known fit conflict: shown only so she knows why it was excluded.
struct FindOneExcludedRow: View {
    var candidate: ShoppingCandidate
    var session: FindOneSession
    var onCitation: (EvidenceItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.s) {
                FindOneProductTile(candidate: candidate, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(candidate.retailer) · \(candidate.domain)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                    Text(candidate.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    FindOneFitBadge(state: .knownFitConflict)
                }
            }
            Text(candidate.fitReason)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 0) {
                if !candidate.comparedDimensions.isEmpty {
                    DetailsDisclosure("Compared", count: candidate.comparedDimensions.count,
                                      isExpanded: session.detailsBinding("\(candidate.id)|fit")) {
                        FindOneBulletList(title: "Compared", items: candidate.comparedDimensions, systemImage: "xmark.circle", tint: Palette.error)
                    }
                }
                FindOneSourcesList(candidate: candidate, isExpanded: session.detailsBinding("\(candidate.id)|sources"), onCitation: onCitation)
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.error.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneLead-\(candidate.id)")
    }
}
