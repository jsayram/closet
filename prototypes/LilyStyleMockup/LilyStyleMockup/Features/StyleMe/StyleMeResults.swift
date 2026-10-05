import SwiftUI

/// Results content shared by the pushed results screen and the wide inline pane.
/// Reads `app.style` only; nothing here dispatches on appear, scroll or resize.
struct StyleMeResultsContent: View {
    @Environment(AppModel.self) private var app
    var embedded: Bool
    var width: CGFloat
    var onEditRequest: () -> Void

    var body: some View {
        let style = app.style
        VStack(alignment: .leading, spacing: Spacing.m) {
            if case let .generating(_, startedAt) = style.phase {
                let request = submittedRequest(startedAt: startedAt)
                StyleMeRequestSummary(request: request, onEditRequest: onEditRequest)
                StyleMeGeneratingView(startedAt: startedAt, scopeName: request.scopeName)
            } else if let offer = style.historyOffer {
                StyleMeRequestSummary(request: offer.request, onEditRequest: onEditRequest)
                StyleMeHistoryOfferView(offer: offer, width: width)
            } else if let current = style.current {
                StyleMeRequestSummary(request: current.request, onEditRequest: onEditRequest)
                StyleMeOutcomeView(outcome: current, width: width, onEditRequest: onEditRequest)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The request captured when styling started. Falls back to the current draft when styling was
    /// started elsewhere (keyboard command, launch argument).
    private func submittedRequest(startedAt: Date) -> StyleRequest {
        if let request = app.styleMeUI.lastSubmittedRequest, abs(request.createdAt.timeIntervalSince(startedAt)) < 3 {
            return request
        }
        return app.buildRequest()
    }

    @ViewBuilder
    private var emptyState: some View {
        if embedded {
            EmptyStateView(title: app.styleMeUI.wasCancelled ? "Styling cancelled" : "Your looks will appear here",
                           message: app.styleMeUI.wasCancelled
                               ? "Your request is kept as you left it. Tap Style Me when you're ready."
                               : "Pick an occasion and tap Style Me. When your clothes allow it you'll see a Safe / Simple look and two Elevated looks, side by side when there's room.",
                           systemImage: app.styleMeUI.wasCancelled ? "xmark.circle" : "sparkles")
        } else {
            EmptyStateView(title: app.styleMeUI.wasCancelled ? "Styling cancelled" : "No looks yet",
                           message: app.styleMeUI.wasCancelled
                               ? "Your request is kept as you left it. Tap Style Me when you're ready."
                               : "Choose an occasion on Style Me and tap Style Me. Your request stays as you left it.",
                           systemImage: app.styleMeUI.wasCancelled ? "xmark.circle" : "sparkles",
                           actionTitle: "Back to Style Me",
                           action: onEditRequest)
        }
    }
}

// MARK: - Request summary

struct StyleMeRequestSummary: View {
    @Environment(AppModel.self) private var app
    var request: StyleRequest
    var onEditRequest: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Side by side when it fits; stacked at large text sizes so neither the title nor the button clips.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: Spacing.xs) {
                    title
                    Spacer(minLength: Spacing.xs)
                    editButton
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    title
                    editButton
                }
            }
            // One row that scrolls sideways; the button at the end opens the full set.
            ChipCarousel(spacing: 6,
                         isExpanded: app.styleMeUI.disclosure("requestChips"),
                         itemsLabel: "request details",
                         toggleSize: 28,
                         toggleIdentifier: "requestSummaryToggle") {
                ForEach(StyleMeFormat.summaryItems(request, store: app.store)) { item in
                    StyleMeSummaryChip(item: item)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("requestSummary")
    }

    private var title: some View {
        Text("Your request")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var editButton: some View {
        if let onEditRequest {
            Button(action: onEditRequest) {
                Label("Edit request", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityHint("Returns to your request. Nothing is re-run until you tap Style Me.")
            .accessibilityIdentifier("editRequestButton")
        }
    }
}

// MARK: - Generating

struct StyleMeGeneratingView: View {
    @Environment(AppModel.self) private var app
    var startedAt: Date
    var scopeName: String

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 1)) { context in
            let elapsed = max(0, Int(context.date.timeIntervalSince(startedAt)))
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.s) {
                    ProgressView()
                        .tint(Palette.primaryAction)
                    Text("Styling from \(scopeName)…")
                        .font(.editorial(.title3))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                HStack(spacing: Spacing.xs) {
                    StatusBadge(kind: .simulated, compact: true)
                    Text("\(elapsed) s")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Palette.secondaryText)
                        .accessibilityLabel("\(elapsed) seconds so far")
                    InfoButton("what's used while styling", title: "While it styles",
                               text: "Only eligible clothes from \(scopeName) are used, and nothing is saved until you choose.")
                }
                if elapsed >= 10 {
                    Label("Still working — you can leave and come back.", systemImage: "clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: Spacing.xs) {
                    Button {
                        app.styleMeUI.wasCancelled = true
                        app.cancelStyling()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("cancelStylingButton")
                    InfoButton("cancelling", title: "Cancelling",
                               text: "Cancelling stops applying the result. A real service might already have started the work (simulated).")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .frame(maxWidth: 720, alignment: .leading)
    }
}

// MARK: - History offer (§8.2, §11.11)

struct StyleMeHistoryOfferView: View {
    @Environment(AppModel.self) private var app
    var offer: HistoryOffer
    var width: CGFloat

    var body: some View {
        let outfit = offer.entry.outfitSnapshot
        let blocked = !app.styleBlockers.isEmpty
        let changes = app.store.historyChanges(offer.entry, for: offer.request)
        let ui = app.styleMeUI
        let made = offer.entry.capturedAt.formatted(.relative(presentation: .named))
        VStack(alignment: .leading, spacing: Spacing.s) {
            StatusBadge(kind: changes.isEmpty ? .fromHistory : .earlier)
            Text(changes.isEmpty ? "From your history, still a match" : "Earlier look from your history")
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText("Made \(made). Rechecked just now: same occasion and source, and every piece is still yours, available and in \(offer.request.scopeName)."
                            + (changes.isEmpty ? " Today's weather and season fit too, so it still matches today's requirements." : ""),
                            summary: "Made \(made). Rechecked just now.",
                            threshold: 1,
                            topic: "how this look was rechecked",
                            isExpanded: ui.disclosure("historyRecheck-\(offer.entry.id)"))
            if !changes.isEmpty {
                StyleMeEvidenceList(title: "What's different today",
                                    lines: changes,
                                    footnote: "You can still use it and adjust it in the editor, or ask for new ideas.",
                                    key: "historyChanges-\(offer.entry.id)")
            }

            LaneLabel(lane: outfit.lane)
            OutfitFlatLayView(pieces: outfit.pieces,
                              statusFor: { StyleMeLayout.badges(for: $0, request: offer.request, store: app.store) })
                .frame(maxWidth: 380)
                .frame(maxWidth: .infinity)
            OutfitPieceChips(pieces: outfit.pieces,
                             statusFor: { StyleMeLayout.badges(for: $0, request: offer.request, store: app.store) })
            StyleMeLookNotes(rationale: outfit.rationale,
                             notes: outfit.colorNote.isEmpty ? [] : [.init(text: outfit.colorNote, icon: "paintpalette")],
                             key: "history-\(offer.entry.id)")
            // What using it costs stays on screen.
            Label("Free to use. No new stylist or image work.", systemImage: "leaf")
                .font(.footnote)
                .foregroundStyle(Palette.success)
                .fixedSize(horizontal: false, vertical: true)

            ActionGroup(moreIdentifier: "historyMoreButton") {
                Button("Use this look") {
                    app.useHistoryLook()
                }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .accessibilityIdentifier("historyUseLookButton")

                Button("New ideas") {
                    var request = offer.request
                    request.createdAt = .now
                    app.styleMeUI.lastSubmittedRequest = request
                    app.styleMeUI.wasCancelled = false
                    app.newIdeas()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(blocked)
                .accessibilityIdentifier("historyNewIdeasButton")
            } more: {
                Button("Browse similar", systemImage: "square.grid.2x2") {
                    app.push(.search(.saved))
                }
                .accessibilityIdentifier("historyBrowseSimilarButton")
            }
            // What New ideas costs stays visible before she taps it; the rest is one tap away.
            HStack(spacing: Spacing.xxs) {
                Text(blocked ? "New ideas is paused." : "New ideas uses your styling allowance.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                InfoButton("New ideas", text: blocked
                           ? "New ideas is paused — see the notes on Style Me. This look stays free to use."
                           : "New ideas asks the stylist for fresh looks under your usual styling allowance. It doesn't request pictures on its own.")
            }
        }
        .cardStyle()
        .frame(maxWidth: 720, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("historyOfferCard")
    }
}

// MARK: - Outcome

struct StyleMeOutcomeView: View {
    @Environment(AppModel.self) private var app
    var outcome: StyleOutcome
    var width: CGFloat
    var onEditRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            changeBanner
            switch outcome.result {
            case let .outfitSet(outfits):
                let hasIdeas = outfits.contains(where: { $0.lane == .hypothetical })
                header(title: outfits.count == 3 ? "Three directions for \(outcome.request.occasion.phrase)" : "\(StyleMeFormat.lookCount(outfits.count)) for \(outcome.request.occasion.phrase)",
                       detail: hasIdeas
                           ? "Suggestions: where your saved closet didn't cover a direction, the idea uses pieces you don't own. They're labelled."
                           : "From \(outcome.request.scopeName). Tap any piece to swap it.",
                       summary: hasIdeas ? "Some ideas use pieces you don't own." : nil)
                StyleMeResultsGrid(outfits: outfits, outcome: outcome, width: width)
            case let .partialWardrobe(outfits, evidence):
                if outcome.fromHistory {
                    historyHeader
                } else {
                    partialHeader(count: outfits.count)
                    if !evidence.isEmpty {
                        StyleMeEvidenceList(title: "What was checked", summary: outcome.request.scopeName,
                                            lines: evidence, key: "evidence-\(outcome.id)")
                    }
                    StyleMeNextSteps(request: outcome.request, insufficient: false, onEditRequest: onEditRequest)
                }
                StyleMeResultsGrid(outfits: outfits, outcome: outcome, width: width)
            case let .insufficientWardrobe(evidence):
                header(title: "No complete look in \(outcome.request.scopeName) today",
                       detail: "Nothing was invented to fill the gap. Here's what was checked and what you can do.",
                       summary: "Nothing was invented to fill the gap.")
                StyleMeEvidenceList(title: "What was checked", summary: outcome.request.scopeName,
                                    lines: evidence, key: "evidence-\(outcome.id)")
                StyleMeNextSteps(request: outcome.request, insufficient: true, onEditRequest: onEditRequest)
            case let .generationNotCompleted(reason):
                notCompleted(reason)
            }
            if outcome.fromHistory {
                SimulationNotice(text: "Reused from your local styling history. Demo data; the original look came from the simulated stylist.")
                    .frame(maxWidth: 720, alignment: .leading)
            } else if !outcome.result.outfits.isEmpty {
                SimulationNotice(text: "Looks from the simulated demo stylist, using fictional closet data. Pictures, if any, are placeholder figures.")
                    .frame(maxWidth: 720, alignment: .leading)
            }
            if app.style.hasActiveImageJobs {
                HStack(spacing: Spacing.xs) {
                    Button {
                        app.cancelPreviews()
                    } label: {
                        Label("Cancel pictures", systemImage: "stop.circle")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("cancelPicturesButton")
                    InfoButton("cancelling pictures", title: "Cancelling pictures",
                               text: "Boards stay usable. A picture that already started may still count (simulated).")
                }
            }
        }
    }

    // Stale (source changed) or weather changed since delivery: explicit Restyle only.
    @ViewBuilder
    private var changeBanner: some View {
        let blocked = !app.styleBlockers.isEmpty
        if let stale = outcome.staleReason {
            ActionBanner(style: .caution, title: "These are earlier looks", message: stale,
                         isMessageExpanded: app.styleMeUI.disclosure("staleReason-\(outcome.id)")) {
                restyleButton(disabled: blocked)
            }
        } else if case .generationNotCompleted = outcome.result {
            EmptyView()
        } else if outcome.request.weather.summary != app.effectiveWeather.summary {
            ActionBanner(style: .info, title: "Weather changed since these looks",
                         message: "They were styled for \(outcome.request.weather.summary). It's now \(app.effectiveWeather.summary). Nothing changes automatically — restyle if you'd like looks for the new conditions.",
                         summary: "It's now \(app.effectiveWeather.summary).",
                         isMessageExpanded: app.styleMeUI.disclosure("weatherChanged-\(outcome.id)")) {
                restyleButton(disabled: blocked)
            }
        }
    }

    private func restyleButton(disabled: Bool) -> some View {
        Button {
            app.styleMeUI.lastSubmittedRequest = app.buildRequest()
            app.styleMeUI.wasCancelled = false
            app.newIdeas()
        } label: {
            Label("Restyle", systemImage: "arrow.clockwise")
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(disabled)
        .accessibilityHint(disabled ? "Paused — see the notes on Style Me" : "Makes a fresh styling request with your current choices")
        .accessibilityIdentifier("restyleButton")
    }

    /// Headline plus one line; a longer detail folds to its summary with More.
    private func header(title: String, detail: String, summary: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText(detail, summary: summary, threshold: 1, font: .subheadline, topic: title,
                            isExpanded: app.styleMeUI.disclosure("outcomeDetail-\(outcome.id)"))
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            StatusBadge(kind: .fromHistory)
            Text("From your history")
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            StyleMeWhyLine(short: "Rechecked against today's closet.",
                           full: "Earlier look — revalidated against today's closet"
                               + (outcome.historyCapturedAt.map { ". Made \($0.formatted(.relative(presentation: .named)))." } ?? ".")
                               + " This reused your history — no new stylist or image work. It isn't a fresh look at every new piece in your closet.",
                           linkTitle: "Learn more",
                           topic: "looks reused from your history",
                           isExpanded: app.styleMeUI.disclosure("historyHeader-\(outcome.id)"))
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    /// The honest core ("Partial result" and the look count) stays on screen; the reasons are one tap away.
    private func partialHeader(count: Int) -> some View {
        let ideas = outcome.result.outfits.filter { $0.lane == .hypothetical }.count
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            StatusBadge(kind: .partial)
            Text("Partial result · \(StyleMeFormat.lookCount(count))")
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText("Only \(count == 1 ? "one complete look meets" : "\(count) complete looks meet") today's requirements in \(outcome.request.scopeName)."
                            + (ideas == 0 ? " No cards were invented to fill the gap."
                                          : " \(ideas == 1 ? "One is a labelled idea" : "\(ideas) are labelled ideas") with pieces you don't own; ideas that didn't keep your request were left out."),
                            summary: (count == 1 ? "Only one complete look fits today." : "Only \(count) complete looks fit today.")
                                + (ideas == 0 ? "" : " Ideas are labelled."),
                            threshold: 1,
                            font: .subheadline,
                            topic: "this partial result",
                            isExpanded: app.styleMeUI.disclosure("partialDetail-\(outcome.id)"))
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    private func notCompleted(_ reason: String) -> some View {
        let blocked = !app.styleBlockers.isEmpty
        return VStack(alignment: .leading, spacing: Spacing.s) {
            ActionBanner(style: .error, title: "Styling didn't finish", message: reason,
                         isMessageExpanded: app.styleMeUI.disclosure("failureReason-\(outcome.id)")) {
                Button {
                    app.styleMeUI.lastSubmittedRequest = app.buildRequest()
                    app.styleMeUI.wasCancelled = false
                    app.newIdeas()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .disabled(blocked)
                .accessibilityIdentifier("retryButton")

                Button("Build a look") {
                    app.openNewOutfitEditor(in: .styleMe)
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Build a look yourself")
                .accessibilityIdentifier("buildYourselfButton")
            }
            CollapsibleText("This says nothing about what's in your closet. Your request is kept exactly as you left it.",
                            summary: "Your request is kept as you left it.",
                            threshold: 1,
                            topic: "what this means",
                            isExpanded: app.styleMeUI.disclosure("failureNote-\(outcome.id)"))
        }
        .frame(maxWidth: 720, alignment: .leading)
    }
}

// MARK: - Evidence and next steps

/// Evidence as a closed details row ("What was checked · 4"); the lines open in place.
struct StyleMeEvidenceList: View {
    @Environment(AppModel.self) private var app
    var title: String
    var summary: String? = nil
    var lines: [String]
    /// Closing sentence shown under the lines when open.
    var footnote: String? = nil
    /// Key in `StyleMeUIState.openDisclosures`.
    var key: String

    var body: some View {
        DetailsDisclosure(title, summary: summary, count: lines.count,
                          isExpanded: app.styleMeUI.disclosure(key), identifier: "evidenceToggle") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Label {
                        Text(line)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .imageScale(.small)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    .font(.footnote)
                    .foregroundStyle(Palette.primaryText)
                }
                if let footnote {
                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, Spacing.s)
        }
        .padding(.horizontal, Spacing.s)
        .frame(maxWidth: 720, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("evidenceList")
    }
}

/// "What you can do": the two most likely steps as buttons, the rest in a More menu.
struct StyleMeNextSteps: View {
    @Environment(AppModel.self) private var app
    var request: StyleRequest
    var insufficient: Bool
    var onEditRequest: () -> Void

    private struct Step: Identifiable {
        /// Also the accessibility identifier.
        var id: String
        var title: String
        /// Full wording for VoiceOver and the menu when the visible title is shortened.
        var fullTitle: String?
        var systemImage: String
        var isPrimary = false
        var action: () -> Void
    }

    var body: some View {
        let all = steps
        let visible = Array(all.prefix(2))
        let rest = Array(all.dropFirst(2))
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("What you can do")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            if rest.isEmpty {
                ActionGroup {
                    ForEach(visible) { button(for: $0) }
                }
            } else {
                ActionGroup(moreIdentifier: "nextStepsMoreButton") {
                    ForEach(visible) { button(for: $0) }
                } more: {
                    ForEach(rest) { step in
                        Button(step.fullTitle ?? step.title, systemImage: step.systemImage, action: step.action)
                            .accessibilityIdentifier(step.id)
                    }
                }
            }
            if request.scope.isSuitcase {
                if app.workingScope == request.scope {
                    StyleMeWhyLine(short: "Only \(request.scopeName) was checked.",
                                   full: "Missing pieces are missing in \(request.scopeName), not necessarily from your closet. Switching only changes the source; styling waits until you tap Style Me again.",
                                   topic: "what was checked, and switching to Main Closet",
                                   isExpanded: app.styleMeUI.disclosure("sourceCaveat"))
                } else {
                    Label("Source is now \(app.workingScopeName). Tap Style Me (or Restyle) when you're ready.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: 720, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    /// Visible steps are text only so two fit side by side on a phone; the menu rows carry the icons.
    @ViewBuilder
    private func button(for step: Step) -> some View {
        if step.isPrimary {
            Button(step.title, action: step.action)
                .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                .accessibilityLabel(step.fullTitle ?? step.title)
                .accessibilityIdentifier(step.id)
        } else {
            Button(step.title, action: step.action)
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel(step.fullTitle ?? step.title)
                .accessibilityIdentifier(step.id)
        }
    }

    /// Every available step, most likely first.
    private var steps: [Step] {
        let dirtyCount = app.store.dirtyGarments(scope: request.scope).count
        let emptySuitcaseID: String? = request.scope.suitcaseID.flatMap { sid in
            app.store.suitcase(sid) != nil && app.store.memberIDs(of: sid).isEmpty ? sid : nil
        }
        var steps: [Step] = []
        if insufficient, let sid = emptySuitcaseID {
            steps.append(Step(id: "addGarmentsButton", title: "Add garments", systemImage: "plus", isPrimary: true) {
                app.push(.suitcase(sid))
            })
        }
        if dirtyCount > 0 {
            steps.append(Step(id: "nextStepLaundryButton", title: "Laundry · \(dirtyCount) Dirty", systemImage: "washer") {
                app.push(.laundry)
            })
        }
        if request.scope.isSuitcase, app.workingScope == request.scope {
            steps.append(Step(id: "switchToMainClosetButton", title: "Use Main Closet", fullTitle: "Switch to Main Closet", systemImage: "cabinet") {
                app.selectScope(.mainCloset)
                app.showToast("Source is now Main Closet. Tap Style Me when you're ready — nothing was re-run.", style: .info)
            })
        }
        steps.append(Step(id: "nextStepAddItemButton", title: "Add an item", systemImage: "plus.circle") {
            app.present(.addGarment(AddGarmentPrefill(intoSuitcaseID: request.scope.suitcaseID)))
        })
        steps.append(Step(id: "nextStepRefineButton", title: "Refine request", systemImage: "slider.horizontal.3", action: onEditRequest))
        if !request.scope.isSuitcase, request.mode == .ownedOnly, app.style.draft.mode == .ownedOnly {
            steps.append(Step(id: "nextStepSuggestionsButton", title: "Use Suggestions next time", systemImage: "lightbulb") {
                app.style.draft.mode = .suggestions
                app.showToast("Suggestions is on for your next request. Nothing was re-run.", style: .info)
            })
        }
        return steps
    }
}

/// Why a look works, then its notes: one line of rationale with More, and the color, fit and
/// source notes behind a closed "Notes" row.
struct StyleMeLookNotes: View {
    struct Note: Identifiable {
        var text: String
        var icon: String
        var id: String { icon + text }
    }

    @Environment(AppModel.self) private var app
    var rationale: String
    var notes: [Note]
    /// Key suffix in `StyleMeUIState.openDisclosures`.
    var key: String

    var body: some View {
        let ui = app.styleMeUI
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if !rationale.isEmpty {
                CollapsibleText(rationale, threshold: 1, font: .subheadline, color: Palette.primaryText,
                                topic: "why this look works", isExpanded: ui.disclosure("rationale-\(key)"))
            }
            if !notes.isEmpty {
                DetailsDisclosure("Notes", count: notes.count, isExpanded: ui.disclosure("notes-\(key)")) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ForEach(notes) { note in
                            Label {
                                Text(note.text).fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: note.icon).foregroundStyle(Palette.primaryAction)
                            }
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Layout helpers

enum StyleMeLayout {
    /// Board columns from the space a board actually gets.
    static func boardColumns(for width: CGFloat, accessibility: Bool) -> Int {
        let minTile: CGFloat = accessibility ? 150 : 96
        return max(1, min(3, Int((width + Spacing.xs) / (minTile + Spacing.xs))))
    }

    /// Current-status and depiction badges for a delivered piece (resolved from canonical records).
    static func badges(for piece: OutfitPiece, request: StyleRequest, store: DemoStore) -> [BadgeKind] {
        guard let id = piece.garmentID else { return [] }
        guard let garment = store.garment(id) else { return [.missing] }
        var badges = BadgeKind.status(for: garment)
        if request.overrideIDs.contains(id), !badges.isEmpty { badges.insert(.usedThisRequest, at: 0) }
        if request.scope.isSuitcase, !store.isInScope(garment, request.scope) { badges.append(.outsideSource) }
        if piece.capturedImageKind != .actualPhoto { badges.append(BadgeKind.image(for: piece.capturedImageKind)) }
        return badges
    }
}
