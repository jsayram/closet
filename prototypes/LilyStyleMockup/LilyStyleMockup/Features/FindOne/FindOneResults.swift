import SwiftUI

/// Results grouped fit-first: Supported sizing guidance → Needs fit confirmation →
/// Excluded (known fit conflict, collapsed). Never padded to three matches.
struct FindOneResultsSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Bindable var session: FindOneSession
    var multiColumn: Bool
    var onCitation: (EvidenceItem) -> Void
    var onViewAtStore: (ShoppingCandidate) -> Void
    var onBought: (ShoppingCandidate) -> Void

    var body: some View {
        if let record = session.record {
            content(record)
        } else if multiColumn {
            EmptyStateView(title: "Results appear here",
                           message: "Nothing is searched until you tap Search. Your own clothes are listed first.",
                           systemImage: "magnifyingglass")
                .padding(.top, Spacing.xl)
        }
    }

    // MARK: Content

    @ViewBuilder
    private func content(_ record: FindOneSearchRecord) -> some View {
        let profile = app.store.profile
        let visible = record.leads.filter { session.showsOverBudget || !record.isOverBudget($0) }
        VStack(alignment: .leading, spacing: Spacing.m) {
            header(record)
            if session.profileChangedSinceRanking(profile) {
                staleRankBanner
            }
            if session.intentChangedSinceSearch(profile) {
                InlineBanner(style: .info, title: "Search details changed since these results",
                             message: "These results used “\(record.intent.summary)”. Tap Search again to use your edits — nothing runs automatically.",
                             summary: "Tap Search again to use your edits.",
                             isMessageExpanded: session.detailsBinding("intentChanged"))
            }
            if record.outcome != .resultsFound {
                outcomeBanner(record.outcome)
            }
            if record.isRanked {
                rankedGroups(record, visible: visible)
            } else if !record.leads.isEmpty {
                unrankedGroup(record, visible: visible)
            }
            hiddenNotes(record)
            measurementHint
            attempts(record)
        }
    }

    private func header(_ record: FindOneSearchRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .center, spacing: Spacing.xxs) {
                Text("Results")
                    .font(.editorial(.title3))
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.xs)
                StatusBadge(kind: .simulated, compact: true)
                InfoButton("these results", title: "Simulated results",
                           text: "Searched \(FindOneFormat.relative(record.completedAt)) for “\(record.intent.summary)”. Fictional stores and links; prices are samples and never refreshed automatically.")
            }
            Text("Searched \(FindOneFormat.relative(record.completedAt)) for “\(record.intent.summary)”")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .lineLimit(2)
            if session.isBusy {
                Label("Earlier results — kept until the new run finishes", systemImage: "clock.arrow.circlepath")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .padding(.top, Spacing.xxs)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Banners

    private var staleRankBanner: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Profile changed since this search — Re-rank", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
            CollapsibleText("These fit notes used your earlier profile and are kept as they were. Re-rank compares the same leads privately again — it doesn't search again.",
                            summary: "These fit notes used your earlier profile.",
                            threshold: 1, topic: "re-ranking", isExpanded: session.detailsBinding("staleRank"))
            Button {
                session.rank(app: app)
            } label: {
                Label("Re-rank", systemImage: "ruler")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(session.isBusy || app.store.profile.permission(.fitRanking) != .allowed || !app.store.access.plan.hasStylingAccess)
            .accessibilityIdentifier("findOneRerank")
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.primaryAction.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func outcomeBanner(_ outcome: SearchOutcome) -> some View {
        let title: String = switch outcome {
        case .resultsFound: "Results found"
        case .noMatchingResultsWithinSearch: "No matching results within this search"
        case .searchNotCompleted: "Search not completed"
        case .unsupportedCoverage: "Not supported by the demo search"
        }
        return InlineBanner(style: outcome == .searchNotCompleted ? .error : .info, title: title,
                            message: outcome.explanation + " Your closet, saved products and the manual browser search below still work.",
                            isMessageExpanded: session.detailsBinding("outcome"))
            .accessibilityIdentifier("findOneOutcome")
    }

    // MARK: Ranked groups

    @ViewBuilder
    private func rankedGroups(_ record: FindOneSearchRecord, visible: [ShoppingCandidate]) -> some View {
        let supported = visible.filter { $0.fitState == .supportedGuidance }
        let needs = visible.filter { $0.fitState == .needsFitConfirmation }
        let excluded = visible.filter { $0.fitState == .knownFitConflict }

        groupHeader(.supportedGuidance, count: supported.count,
                    note: supportedNote(count: supported.count))
        if !supported.isEmpty { leadGrid(supported, record: record) }

        if !needs.isEmpty {
            let estimateNote = needs.contains { $0.sizeEstimate != nil }
                ? " Listed sizes closest to your rough size estimate come first. That order isn't a fit check."
                : ""
            groupHeader(.needsFitConfirmation, count: needs.count,
                        note: "Missing or unclear fit evidence. These never count as matches — check the size chart or ask the retailer before buying." + estimateNote)
            leadGrid(needs, record: record)
        }

        if !excluded.isEmpty {
            excludedGroup(excluded)
        }
    }

    private func supportedNote(count: Int) -> String {
        switch count {
        case 0: "No lead in this search has supported sizing guidance. That isn't a reason to loosen your fit needs."
        case 1: "Only 1 lead has supported sizing guidance. The list isn't padded to three. Not a guarantee of physical fit."
        case 2: "Only 2 leads have supported sizing guidance. The list isn't padded to three. Not a guarantee of physical fit."
        default: "Sourced size evidence covers the critical fit points. Not a guarantee — the retailer confirms the final size."
        }
    }

    private func groupHeader(_ state: FitEvidenceState, count: Int, note: String) -> some View {
        // The fit state and the honest count stay on screen; what the group means is one tap away.
        HStack(spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                FindOneFitBadge(state: state)
                Text(count == 1 ? "1 lead" : "\(count) leads")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            InfoButton(state.title, text: note)
            Spacer(minLength: 0)
        }
        .padding(.top, Spacing.xs)
    }

    private func leadGrid(_ leads: [ShoppingCandidate], record: FindOneSearchRecord) -> some View {
        let columns = multiColumn
            ? [GridItem(.adaptive(minimum: 300), spacing: Spacing.m, alignment: .top)]
            : [GridItem(.flexible(), alignment: .top)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.m) {
            ForEach(leads) { candidate in
                FindOneLeadCard(candidate: candidate, record: record, session: session, onCitation: onCitation,
                                onViewAtStore: { onViewAtStore(candidate) }, onBought: { onBought(candidate) })
            }
        }
    }

    private func excludedGroup(_ excluded: [ShoppingCandidate]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                session.showsExcluded.toggle()
            } label: {
                HStack(spacing: Spacing.xs) {
                    FindOneFitBadge(state: .knownFitConflict)
                    Text(excluded.count == 1 ? "1 lead" : "\(excluded.count) leads")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Spacer(minLength: Spacing.xs)
                    Text(session.showsExcluded ? "Hide reasons" : "Show reasons")
                        .font(.subheadline)
                        .foregroundStyle(Palette.primaryAction)
                    Image(systemName: session.showsExcluded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Palette.primaryAction)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: HitTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel("Excluded, known fit conflict: \(excluded.count)")
            .accessibilityValue(session.showsExcluded ? "Expanded" : "Collapsed")
            .accessibilityHint("Shows why these leads aren't counted as matches")
            .accessibilityIdentifier("findOneExcludedToggle")
            if session.showsExcluded {
                Text("Never counted as matches, even from a preferred store. Shown only so you know why.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(excluded) { candidate in
                    FindOneExcludedRow(candidate: candidate, session: session, onCitation: onCitation)
                }
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: Unranked

    @ViewBuilder
    private func unrankedGroup(_ record: FindOneSearchRecord, visible: [ShoppingCandidate]) -> some View {
        let rankingAllowed = app.store.profile.permission(.fitRanking) == .allowed
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Only say "is off" when it is; an allowed comparison that didn't run or finish is labelled as such.
            Label(rankingAllowed
                  ? "Needs fit confirmation — not compared with your fit profile yet"
                  : "Needs fit confirmation — private fit comparison is off",
                  systemImage: FitEvidenceState.needsFitConfirmation.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText("These leads weren't compared with your fit profile, so none counts as a match. Check each store's size chart yourself: compare listed garment lengths with clothes that fit you well, and circumference charts with your confirmed measurements. Unknown stays Unknown.",
                            summary: "None counts as a match. Check each size chart yourself.",
                            threshold: 1, topic: "unranked leads", isExpanded: session.detailsBinding("unranked"))
            if rankingAllowed {
                Button {
                    session.rank(app: app)
                } label: {
                    Label("Compare fit for these results", systemImage: "ruler")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(session.isBusy || !app.store.access.plan.hasStylingAccess)
                .accessibilityHint("Runs the private, tool-free fit comparison on these leads. It doesn't search again.")
                .accessibilityIdentifier("findOneCompareFit")
            } else {
                Button {
                    app.store.setPermission(.fitRanking, .allowed)
                } label: {
                    Label("Allow private fit comparison", systemImage: "checkmark.shield")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Recipient: \(ProcessingPurpose.fitRanking.recipient). \(ProcessingPurpose.fitRanking.dataSent)")
                .accessibilityIdentifier("findOneAllowRankingInline")
                // Who receives what stays on screen at the moment she's asked.
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text("Goes to \(ProcessingPurpose.fitRanking.recipient)")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    InfoButton("what's sent for fit comparison", title: "What's sent", text: ProcessingPurpose.fitRanking.dataSent)
                }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
        .accessibilityElement(children: .contain)
        leadGrid(visible, record: record)
    }

    // MARK: Hidden by hard criteria

    @ViewBuilder
    private func hiddenNotes(_ record: FindOneSearchRecord) -> some View {
        let overBudget = record.overBudgetCount
        let total = record.hiddenAvoided.count + record.hiddenOutsidePreferred.count + overBudget
        if total > 0 {
            DetailsDisclosure(session.showsOverBudget && overBudget == total ? "Over your budget" : "Left out by your limits",
                              summary: count(total),
                              systemImage: "line.3.horizontal.decrease.circle",
                              isExpanded: session.detailsBinding("leftOut"),
                              identifier: "findOneLeftOut") {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if !record.hiddenAvoided.isEmpty {
                        note("Left out: \(count(record.hiddenAvoided.count)) from a store you avoid (\(Set(record.hiddenAvoided).sorted().joined(separator: ", "))).")
                    }
                    if !record.hiddenOutsidePreferred.isEmpty {
                        note("Left out: \(count(record.hiddenOutsidePreferred.count)) from other stores — Only these retailers is on.")
                    }
                    if overBudget > 0, let budget = record.intent.budgetMax {
                        note(session.showsOverBudget
                             ? "Showing \(count(overBudget)) over your $\(budget) budget, labelled."
                             : "\(count(overBudget)) over your $\(budget) budget \(overBudget == 1 ? "isn't" : "aren't") shown. Budget stays a hard limit unless you choose otherwise.")
                        Button(session.showsOverBudget ? "Hide over-budget leads" : "Show anyway") {
                            session.showsOverBudget.toggle()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("findOneOverBudgetToggle")
                    }
                }
            }
        }
    }

    private func count(_ n: Int) -> String { n == 1 ? "1 lead" : "\(n) leads" }

    private func note(_ text: String) -> some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundStyle(Palette.secondaryText)
        }
    }

    // MARK: Measurement hint

    @ViewBuilder
    private var measurementHint: some View {
        let profile = app.store.profile
        let category = session.context.slot.category
        let inseam = profile.measurement(.inseam)
        let missingLength = (category == .bottom || category == .dress) && inseam?.confirmed != true
        // Body-chart dimensions this kind of piece is compared on. Unknown stays unknown.
        let chartDimensions: [MeasurementDimension] = switch category {
        case .bottom: [.waist, .hip]
        case .top, .layer: [.bust]
        case .dress: [.bust, .waist, .hip]
        default: []
        }
        let missingChart = chartDimensions.filter { profile.confirmedBodyMeasurement($0) == nil }
        if missingLength || !missingChart.isEmpty {
            let lengthHint = inseam.map { "Your \($0.displayValue) inseam isn't confirmed, so listed lengths aren't compared with it yet. Confirm it in your profile to use it." }
                ?? "Your inseam is Unknown, so listed lengths can't be compared with yours. Height never sets it."
            let hints = (missingLength ? [lengthHint] : []) + (missingChart.isEmpty ? [] : [chartHint(missing: missingChart, fit: profile.bodyFit)])
            VStack(alignment: .leading, spacing: Spacing.xs) {
                CollapsibleText(hints.joined(separator: "\n\n"),
                                summary: hintSummary(missingLength: missingLength, inseamEntered: inseam != nil, missingChart: missingChart, fit: profile.bodyFit),
                                threshold: 1, topic: "missing measurements",
                                isExpanded: session.detailsBinding("measurementHint"))
                Button {
                    openProfile()
                } label: {
                    Label(hintButtonTitle(missingLength: missingLength, inseamEntered: inseam != nil, missingChart: missingChart), systemImage: "ruler")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Closes Find One and opens Profile. This search is kept; reopen Find One for this piece to see it. Nothing is re-run.")
                .accessibilityIdentifier("findOneAddMeasurement")
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        }
    }

    /// One line for the measurement hint. The full reasons open in place.
    private func hintSummary(missingLength: Bool, inseamEntered: Bool, missingChart: [MeasurementDimension], fit: BodyFit) -> String {
        if missingLength, !missingChart.isEmpty { return "Some measurements are missing, so not everything was compared." }
        if missingLength { return inseamEntered ? "Your inseam isn't confirmed, so lengths aren't compared." : "Your inseam is Unknown, so lengths aren't compared." }
        if fit.source == .heightAndWeightEstimate, fit.estimatedBand != nil { return "Sizes are placed against a rough estimate only." }
        let names = ListFormatter.localizedString(byJoining: missingChart.map(Self.shortName))
        return "Your \(names) \(missingChart.count == 1 ? "is" : "are") Unknown, so charts aren't compared."
    }

    private func chartHint(missing: [MeasurementDimension], fit: BodyFit) -> String {
        if fit.source == .heightAndWeightEstimate, let band = fit.estimatedBand {
            return "Without your waist, hip or bust, sizes are only placed against a rough estimate from your height and weight: around \(band.label). It sorts leads that need fit confirmation and never confirms a size. Add your waist, hip and bust so size charts can be compared."
        }
        let names = ListFormatter.localizedString(byJoining: missing.map(Self.shortName))
        let verb = missing.count == 1 ? "is" : "are"
        return "Your \(names) \(verb) Unknown, so body charts can't be compared. Unknown stays unknown."
    }

    private func hintButtonTitle(missingLength: Bool, inseamEntered: Bool, missingChart: [MeasurementDimension]) -> String {
        if missingLength, !missingChart.isEmpty { return "Add measurements in Profile" }
        if !missingChart.isEmpty {
            // The rough estimate only exists when waist, hip and bust are all missing, so suggest all three.
            let dims: [MeasurementDimension] = profileFitSource == .heightAndWeightEstimate ? [.waist, .hip, .bust] : missingChart
            return "Add your " + ListFormatter.localizedString(byJoining: dims.map(Self.shortName))
        }
        return inseamEntered ? "Confirm your inseam" : "Add a measurement to compare length"
    }

    private var profileFitSource: BodyFit.Source { app.store.profile.bodyFit.source }

    private static func shortName(_ dimension: MeasurementDimension) -> String {
        switch dimension {
        case .hip: "hip"
        default: dimension.label.lowercased()
        }
    }

    private func openProfile() {
        let compact = sizeClass == .compact
        if !compact { app.sheet = nil }
        app.open(.profile, compact: compact)
    }

    // MARK: Source attempts

    private func attempts(_ record: FindOneSearchRecord) -> some View {
        DetailsDisclosure("Where this search looked",
                          summary: record.attempts.count == 1 ? "1 store" : "\(record.attempts.count) stores",
                          systemImage: "list.bullet.rectangle",
                          isExpanded: session.detailsBinding("attempts"),
                          identifier: "findOneAttemptsToggle") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Five preferred stores don't mean five searches. The search stops at its bounds and says what it skipped.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(record.attempts) { attempt in
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Spacing.xs) {
                            attemptIcon(attempt.status)
                            Text(attempt.retailer)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: Spacing.xs)
                            Text(attempt.status.label)
                                .font(.subheadline)
                                .foregroundStyle(Palette.secondaryText)
                                .multilineTextAlignment(.trailing)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: Spacing.xs) {
                                attemptIcon(attempt.status)
                                Text(attempt.retailer)
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text(attempt.status.label)
                                .font(.subheadline)
                                .foregroundStyle(Palette.secondaryText)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                Text("Other permitted stores can appear when they have stronger fit evidence. Stock, shipping and price can change — the retailer confirms them.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .cardStyle(padding: 0)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneAttempts")
    }

    private func attemptIcon(_ status: SourceAttemptStatus) -> some View {
        let name: String = switch status {
        case .evidenceFound: "checkmark.circle"
        case .attemptedNoEvidence: "circle.slash"
        case .blocked: "lock.trianglebadge.exclamationmark"
        case .notAttempted: "pause.circle"
        }
        return Image(systemName: name)
            .foregroundStyle(status == .evidenceFound ? Palette.success : Palette.secondaryText)
            .accessibilityHidden(true)
    }
}
