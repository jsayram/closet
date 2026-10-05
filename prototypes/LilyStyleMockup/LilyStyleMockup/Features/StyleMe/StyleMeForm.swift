import SwiftUI

/// The request form: calm and garment-led, with advanced options tucked under "More options".
struct StyleMeFormColumn: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var resultsInline: Bool
    var maxContentWidth: CGFloat

    var body: some View {
        @Bindable var ui = app.styleMeUI
        // At accessibility text sizes, and in a short landscape window where the keyboard would
        // leave no room, the action area scrolls with the form instead of pinning.
        let pinnedBar = !dynamicTypeSize.isAccessibilitySize && verticalSizeClass != .compact
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                StyleMeHeader()
                    .id(StyleMeFormAnchor.top)
                StyleMeSourceSection()
                    .id(StyleMeFormAnchor.source)
                if !resultsInline, StyleMeReadyCard.isVisible(app) {
                    StyleMeReadyCard()
                        .id(StyleMeFormAnchor.readyCard)
                }
                StyleMeOccasionSection()
                    .id(StyleMeFormAnchor.occasion)
                StyleMeStartingItemSection()
                    .id(StyleMeFormAnchor.startingItem)
                StyleMeMoreOptionsSection()
                    .id(StyleMeFormAnchor.moreOptions)
                StyleMeOnMeSection()
                    .id(StyleMeFormAnchor.onMe)
                StyleMeBlockersSection()
                    .id(StyleMeFormAnchor.blockers)
                if !pinnedBar {
                    StyleMeActionArea(resultsInline: resultsInline, pinned: false)
                        .id(StyleMeFormAnchor.action)
                }
                StyleMeAffirmationLine()
            }
            .scrollTargetLayout()
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
            .frame(maxWidth: maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollPosition(id: $ui.formAnchor, anchor: .top)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if pinnedBar {
                StyleMeActionArea(resultsInline: resultsInline, pinned: true)
            }
        }
    }
}

// MARK: - Header

struct StyleMeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    title
                    StatusBadge(kind: .demo, compact: true)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    title
                    StatusBadge(kind: .demo, compact: true)
                }
            }
            StyleMeWeatherSummaryButton()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: some View {
        Text("My Petite Style")
            .font(.editorial(.largeTitle, weight: .bold))
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Today's short note from the local library (FR-02). Sits quietly at the end of the form.
struct StyleMeAffirmationLine: View {
    var body: some View {
        let affirmation = StyleMeAffirmations.forDay()
        Text(affirmation)
            .font(.system(.body, design: .serif))
            .italic()
            .foregroundStyle(Palette.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityLabel("Today's note: \(affirmation)")
    }
}

// MARK: - Source

struct StyleMeSourceSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let scope = app.workingScope
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    SourceSelector(onManage: { app.push(.suitcases) })
                    caption(scope)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SourceSelector(onManage: { app.push(.suitcases) })
                    caption(scope)
                }
            }
            if app.store.scopeFallback != nil || app.store.awaitingSourceChoice {
                fallbackBanner
            }
            if let sid = scope.suitcaseID, app.store.suitcase(sid) != nil, app.store.memberIDs(of: sid).isEmpty {
                ActionBanner(style: .info, title: "\(app.workingScopeName) is empty",
                             message: "It stays selected. Add garments from Main Closet, or pick another source above.") {
                    Button { app.push(.suitcase(sid)) } label: { Label("Add garments", systemImage: "plus") }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func caption(_ scope: WardrobeScope) -> some View {
        if let sid = scope.suitcaseID {
            Label("Strict · only the \(app.store.memberIDs(of: sid).count) pieces in this suitcase", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Label("All your clothes", systemImage: "checkmark.circle")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
        }
    }

    private var fallbackBanner: some View {
        InlineBanner(style: .caution,
                     title: "Choose a source before styling",
                     message: (app.store.scopeFallback?.explanation ?? StyleBlocker.awaitingSourceChoice.message)
                        + " Main Closet is shown for browsing only until you choose.",
                     actionTitle: "Use Main Closet",
                     action: useMainCloset)
    }

    /// A deliberate choice. Fallback alone never authorizes broader styling.
    private func useMainCloset() {
        if app.workingScope == .mainCloset, !app.store.awaitingSourceChoice {
            // Already browsing Main Closet after a fallback: record the deliberate choice to clear it.
            app.store.selectScope(.mainCloset)
        } else {
            app.selectScope(.mainCloset)
        }
    }
}

// MARK: - Ready card (navigation only)

struct StyleMeReadyCard: View {
    @Environment(AppModel.self) private var app

    static func isVisible(_ app: AppModel) -> Bool {
        app.style.isGenerating || app.style.current != nil || app.style.historyOffer != nil
    }

    var body: some View {
        let content = summary
        Button {
            app.push(.results, in: .styleMe)
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: content.icon)
                    .font(.title3)
                    .foregroundStyle(Palette.primaryAction)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Text(content.detail)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: Spacing.xs)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).fill(Palette.accentSurface))
            .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.primaryAction.opacity(0.6), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens your results")
        .accessibilityIdentifier("resultsReadyCard")
    }

    private var summary: (icon: String, title: String, detail: String) {
        let style = app.style
        if style.isGenerating { return ("hourglass", "Styling in progress", "View progress — you can keep editing here meanwhile.") }
        if let offer = style.historyOffer {
            return ("clock", "A look from your history matches", "\(offer.request.occasion.label) · \(offer.request.scopeName) · no new styling needed")
        }
        guard let current = style.current else { return ("sparkles", "Your looks", "") }
        let earlier = current.staleReason != nil ? "Earlier · " : ""
        if current.fromHistory { return ("clock", "Your look from history", "\(earlier)Revalidated against today's closet") }
        switch current.result {
        case let .outfitSet(outfits):
            return ("sparkles", current.staleReason == nil ? "Your looks are ready" : "Earlier looks",
                    "\(earlier)\(StyleMeFormat.lookCount(outfits.count)) for \(current.request.occasion.label) · \(current.request.scopeName)")
        case let .partialWardrobe(outfits, _):
            return ("square.split.2x1", "Partial result — \(StyleMeFormat.lookCount(outfits.count))", "\(earlier)Only what \(current.request.scopeName) can make today")
        case .insufficientWardrobe:
            return ("exclamationmark.circle", "No complete look in \(current.request.scopeName)", "\(earlier)See what's missing and what you can do")
        case .generationNotCompleted:
            return ("exclamationmark.triangle", "Styling didn't finish", "Your request is kept — retry or build a look yourself")
        }
    }
}

// MARK: - Occasion

struct StyleMeOccasionSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var style = app.style
        let expanded = app.styleMeUI.occasionExpanded
        let selected = StyleMeFormat.occasionText(style.draft.occasion, custom: style.draft.customOccasion)
        VStack(alignment: .leading, spacing: Spacing.s) {
            Button {
                Motion.perform(reduceMotion: reduceMotion) { app.styleMeUI.occasionExpanded.toggle() }
            } label: {
                toggleLabel(expanded: expanded, selected: selected, icon: style.draft.occasion.systemImage)
                    .frame(minHeight: HitTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Occasion")
            .accessibilityValue(selected)
            .accessibilityHint(expanded ? "Hides the other occasions" : "Shows all occasions")
            .accessibilityIdentifier("occasionToggle")

            if expanded {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Where are you going?")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(Occasion.allCases) { occasion in
                            CapsuleChip(title: occasion.label, systemImage: occasion.systemImage,
                                        isSelected: style.draft.occasion == occasion) {
                                choose(occasion)
                            }
                            .accessibilityIdentifier("occasion-\(occasion.rawValue)")
                        }
                    }
                    if style.draft.occasion == .other {
                        TextField("Describe it, e.g. museum visit", text: $style.draft.customOccasion)
                            .textFieldStyle(StyleMeTextFieldStyle())
                            .submitLabel(.done)
                            .accessibilityLabel("Other occasion")
                            .accessibilityIdentifier("customOccasionField")
                        Text("Kept with this request only.")
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }

    /// Any occasion except Other closes the row; Other keeps it open so the text field shows.
    private func choose(_ occasion: Occasion) {
        app.style.draft.occasion = occasion
        guard occasion != .other else { return }
        Motion.perform(reduceMotion: reduceMotion) { app.styleMeUI.occasionExpanded = false }
    }

    /// The chip sits beside the label when it fits on one line. When it doesn't (large text or a
    /// long "Other: ..." description) it drops under the label and wraps instead of truncating.
    private func toggleLabel(expanded: Bool, selected: String, icon: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                title
                Spacer(minLength: Spacing.xs)
                if !expanded {
                    selectedChip(selected, icon: icon, wraps: false)
                        .transition(.opacity)
                }
                chevron(expanded: expanded)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.s) {
                    title
                    Spacer(minLength: Spacing.xs)
                    chevron(expanded: expanded)
                }
                if !expanded {
                    selectedChip(selected, icon: icon, wraps: true)
                        .transition(.opacity)
                }
            }
        }
    }

    private var title: some View {
        Text("Occasion")
            .font(.headline)
            .foregroundStyle(Palette.primaryText)
            .fixedSize()
    }

    private func chevron(expanded: Bool) -> some View {
        Image(systemName: "chevron.down")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.primaryAction)
            .rotationEffect(.degrees(expanded ? 180 : 0))
    }

    /// The current choice, drawn like a selected chip (icon, label and checkmark). Not a control
    /// of its own: the whole row is the button.
    private func selectedChip(_ text: String, icon: String, wraps: Bool) -> some View {
        let large = dynamicTypeSize.isAccessibilitySize
        return HStack(spacing: Spacing.xxs + 2) {
            Image(systemName: icon)
                .font(.subheadline)
            // Inline, the text reports its full one-line width so ViewThatFits can tell when it
            // no longer fits. Stacked, it wraps.
            Text(text)
                .font(.subheadline.weight(.semibold))
                .lineLimit(wraps ? 4 : 1)
                .truncationMode(.tail)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: !wraps, vertical: true)
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(Palette.primaryAction)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, large ? Spacing.xs : Spacing.xxs + 2)
        .background(Capsule().fill(Palette.accentSurface))
        .overlay(Capsule().strokeBorder(Palette.primaryAction, lineWidth: 1.5))
    }
}

// MARK: - On Me (separately enabled)

struct StyleMeOnMeSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        let ready = app.isOnMeReady
        let onMe = Binding<Bool>(
            get: { app.style.draft.onMe },
            set: { newValue in
                // Turning it off is always allowed; turning it on needs the reference + permission.
                if !newValue || ready { app.style.draft.onMe = newValue }
            }
        )
        VStack(alignment: .leading, spacing: Spacing.s) {
            Toggle(isOn: onMe) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text("On Me")
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                        StatusBadge(kind: .simulated, compact: true)
                    }
                    Text("Simulated pictures")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .tint(Palette.primaryAction)
            .disabled(!ready && !app.style.draft.onMe)
            .accessibilityIdentifier("onMeToggle")
            .accessibilityHint(ready ? "Adds simulated pictures to new looks" : "Unavailable until On Me is set up in Profile")

            if ready {
                // How many pictures and what's free stay on screen; the rest is behind the info button.
                statusLine("Up to 3 pictures. History matches are free.",
                           info: "Placeholder figures wearing your selected pieces — not a real photo and not a fit preview. Up to three; exact matches already in your history are reused at no cost. Boards work without them.")
            } else {
                statusLine("Off until it's set up in Profile.",
                           info: "Off until you add a simulated reference and allow On Me pictures in Profile. Your outfit boards work without pictures.")
                Button {
                    app.open(.profile, compact: sizeClass == .compact)
                } label: {
                    Label("Set up in Profile", systemImage: "person.crop.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private func statusLine(_ text: String, info: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            InfoButton("On Me", text: info)
        }
    }
}

// MARK: - Blockers (honest reasons + free local alternatives)

struct StyleMeBlockersSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let blockers = app.styleBlockers
        if !blockers.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s) {
                SectionHeader("Before you style", subtitle: "Style Me is paused. Nothing has been sent.")
                ForEach(blockers) { blocker in
                    banner(for: blocker)
                }
                freeAlternatives
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("styleBlockers")
        }
    }

    @ViewBuilder
    private func banner(for blocker: StyleBlocker) -> some View {
        let compact = sizeClass == .compact
        switch blocker {
        case .permissionDeclined:
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker), message: blocker.message) {
                Button { app.open(.settings, compact: compact) } label: { Label("Review permission", systemImage: "hand.raised") }
                    .buttonStyle(SecondaryButtonStyle())
                Button { app.open(.profile, compact: compact) } label: { Label("Profile", systemImage: "person.crop.circle") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        case .allowanceExhausted, .noAccess:
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker), message: blocker.message) {
                Button { app.open(.access, compact: compact) } label: { Label("Styling Access", systemImage: "creditcard") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        case .awaitingSourceChoice:
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker),
                         message: "Pick Main Closet or a suitcase in the source selector at the top.") {
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { app.styleMeUI.formAnchor = .source }
                } label: { Label("Go to source", systemImage: "arrow.up") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        case .startingItemIneligible:
            startingItemBanner(blocker)
        case .onMeNotReady:
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker), message: blocker.message) {
                Button { app.open(.profile, compact: compact) } label: { Label("Set up in Profile", systemImage: "person.crop.circle") }
                    .buttonStyle(SecondaryButtonStyle())
                Button { app.style.draft.onMe = false } label: { Label("Turn off On Me", systemImage: "eye.slash") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private func startingItemBanner(_ blocker: StyleBlocker) -> some View {
        let garment = app.store.garment(app.style.draft.startingItemID)
        let eligibility = garment.map { app.store.eligibility(of: $0, scope: app.workingScope, overrides: app.style.draft.overrideIDs) }
        if let garment, let eligibility, eligibility.canOverride {
            // Two ways forward stay visible; the others sit in More.
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker), message: blocker.message,
                         moreIdentifier: "startingItemBlockerMore") {
                Button("Use for this request") { StyleMeStartingActions.choose(garment, withOverride: true, app: app) }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Choose another") { app.styleMeUI.showStartingPicker = true }
                    .buttonStyle(SecondaryButtonStyle())
            } more: {
                if garment.availability == .dirty {
                    Button("Mark clean", systemImage: "sparkles") { StyleMeStartingActions.markClean(garment, app: app) }
                }
                Button("Remove starting piece", systemImage: "xmark") { StyleMeStartingActions.clear(app: app) }
            }
        } else {
            ActionBanner(style: .caution, title: StyleMeBlockerInfo.shortText(blocker), message: blocker.message) {
                Button { app.styleMeUI.showStartingPicker = true } label: { Label("Choose another", systemImage: "hanger") }
                    .buttonStyle(SecondaryButtonStyle())
                Button { StyleMeStartingActions.clear(app: app) } label: { Label("Remove", systemImage: "xmark") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Remove starting piece")
            }
        }
    }

    private var freeAlternatives: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            CollapsibleText("Still free meanwhile: matching looks from your history, your Closet, Saved Looks, search and building a look yourself.",
                            summary: "Your closet and saved looks are still free.",
                            threshold: 1,
                            topic: "what's still free",
                            isExpanded: app.styleMeUI.disclosure("freeAlternatives"))
            if app.styleMeCanCheckHistoryOnly {
                ActionGroup(moreIdentifier: "freeAlternativesMore") {
                    Button("Check history (free)") {
                        let ui = app.styleMeUI
                        ui.lastSubmittedRequest = app.buildRequest()
                        ui.wasCancelled = false
                        if !app.styleMeCheckHistoryOnly() {
                            app.showToast("No look in your history matches this request yet. Nothing was sent.", style: .info)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Check my history (free)")
                    .accessibilityHint("Looks for a matching earlier look on this device. No stylist or image work.")
                    .accessibilityIdentifier("checkHistoryButton")
                    buildLookButton
                } more: {
                    Button("Saved Looks", systemImage: "bookmark") { app.select(.saved) }
                }
            } else {
                ActionGroup {
                    buildLookButton
                    Button { app.select(.saved) } label: { Label("Saved Looks", systemImage: "bookmark") }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private var buildLookButton: some View {
        Button("Build a look") { app.openNewOutfitEditor(in: .styleMe) }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Build a look yourself")
    }
}

// MARK: - Action area: Style Me beside a smaller Ask stylist button

struct StyleMeActionArea: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var resultsInline: Bool
    var pinned: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if app.style.isGenerating {
                generatingRow
            } else {
                idleContent
            }
        }
        .frame(maxWidth: 680)
        .padding(.horizontal, pinned ? Spacing.m : 0)
        .padding(.vertical, pinned ? Spacing.s : 0)
        .frame(maxWidth: .infinity)
        .background {
            if pinned {
                Palette.background
                    .overlay(alignment: .top) { Rectangle().fill(Palette.divider).frame(height: 1) }
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    @ViewBuilder
    private var idleContent: some View {
        let blockers = app.styleBlockers
        if let first = blockers.first {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) {
                    blockerText(first, count: blockers.count)
                    Spacer(minLength: Spacing.xs)
                    reviewButton(first)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    blockerText(first, count: blockers.count)
                    reviewButton(first)
                }
            }
        }
        if dynamicTypeSize.isAccessibilitySize {
            // Large text: the two buttons stack, Style Me first.
            VStack(spacing: Spacing.xs) {
                styleMeButton(blockers, fillsRowHeight: false)
                askStylistButton(fillsRowHeight: false)
            }
        } else {
            StyleMeActionRowLayout(spacing: Spacing.xs) {
                styleMeButton(blockers, fillsRowHeight: true)
                askStylistButton(fillsRowHeight: true)
            }
        }
        Text(actionCaption)
            .font(.caption)
            .foregroundStyle(Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    /// Sponsored access has no daily count to show. Metered plans say what a new set costs
    /// before she taps, so the cost is never a surprise.
    private var actionCaption: String {
        let access = app.store.access
        guard access.plan != .sponsored, access.plan.hasStylingAccess else { return "Checks your history first (free)" }
        return "Checks your history first (free) · a new set uses 1 of \(access.stylingRemaining) left today"
    }

    /// In the side-by-side row the label stretches so both buttons end up the same height.
    private func styleMeButton(_ blockers: [StyleBlocker], fillsRowHeight: Bool) -> some View {
        Button {
            submit()
        } label: {
            Label("Style Me", systemImage: "sparkles")
                .frame(maxHeight: fillsRowHeight ? .infinity : nil)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!blockers.isEmpty)
        .keyboardShortcut(.return, modifiers: .command)
        .accessibilityIdentifier("styleMeButton")
        .accessibilityHint(blockers.first.map { "Unavailable: \(StyleMeBlockerInfo.shortText($0))" }
                           ?? "Checks your history first, then styles looks from \(app.workingScopeName)")
    }

    /// Opening the chat is navigation only. Nothing is sent until she asks a question there.
    private func askStylistButton(fillsRowHeight: Bool) -> some View {
        Button {
            app.openStylistChat()
        } label: {
            Label("Ask stylist", systemImage: "bubble.left")
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: fillsRowHeight ? .infinity : nil)
        }
        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
        .accessibilityLabel("Ask your stylist a question")
        .accessibilityHint("Opens a short chat. Buttons stay the main way to style.")
        .accessibilityIdentifier("openStylistChatButton")
    }

    private func blockerText(_ blocker: StyleBlocker, count: Int) -> some View {
        Label {
            Text(StyleMeBlockerInfo.shortText(blocker) + (count > 1 ? " · \(count - 1) more" : ""))
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.circle").foregroundStyle(Palette.primaryAction)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Palette.primaryText)
    }

    private func reviewButton(_ blocker: StyleBlocker) -> some View {
        Button("Review") {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                app.styleMeUI.formAnchor = StyleMeBlockerInfo.anchor(blocker)
            }
        }
        .font(.footnote.weight(.semibold))
        .minimumHitTarget()
        .accessibilityHint("Scrolls to what needs attention")
    }

    private var generatingRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                progressLabel
                Spacer(minLength: Spacing.xs)
                cancelButton
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                progressLabel
                cancelButton
            }
        }
        .frame(minHeight: 50)
    }

    private var progressLabel: some View {
        HStack(spacing: Spacing.s) {
            ProgressView()
                .tint(Palette.primaryAction)
            Text(resultsInline ? "Styling… your looks will appear alongside." : "Styling from \(app.workingScopeName)…")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var cancelButton: some View {
        // When results show alongside, Cancel lives with the progress there (one Cancel on screen).
        if !resultsInline {
            Button {
                app.styleMeUI.wasCancelled = true
                app.cancelStyling()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(SecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
            .accessibilityIdentifier("cancelStylingButton")
        }
    }

    private func submit() {
        let ui = app.styleMeUI
        ui.lastSubmittedRequest = app.buildRequest()
        ui.wasCancelled = false
        app.styleMe()
    }
}

/// Two buttons side by side, the first about 1.7 times as wide as the second, both the same height.
/// If the second button's label needs more room on a narrow screen it may take up to 45% of the row.
private struct StyleMeActionRowLayout: Layout {
    var spacing: CGFloat = Spacing.xs
    var ratio: CGFloat = 1.7

    private func widths(total: CGFloat, subviews: Subviews) -> (primary: CGFloat, secondary: CGFloat) {
        let available = max(0, total - spacing)
        let share = available / (ratio + 1)
        let ideal = subviews[1].sizeThatFits(.unspecified).width
        let secondary = max(share, min(ideal, available * 0.45))
        return (available - secondary, secondary)
    }

    private func totalWidth(_ proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        if let width = proposal.width, width.isFinite { return width }
        return subviews.reduce(spacing) { $0 + $1.sizeThatFits(.unspecified).width }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let total = totalWidth(proposal, subviews: subviews)
        let w = widths(total: total, subviews: subviews)
        let height = max(subviews[0].sizeThatFits(ProposedViewSize(width: w.primary, height: nil)).height,
                         subviews[1].sizeThatFits(ProposedViewSize(width: w.secondary, height: nil)).height)
        return CGSize(width: total, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let w = widths(total: bounds.width, subviews: subviews)
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: w.primary, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.minX + w.primary + spacing, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: w.secondary, height: bounds.height))
    }
}

// MARK: - Free local history check while paid styling is paused (PRD §8.2, §11.11)

extension AppModel {
    /// True when the only reasons Style Me is paused are access, allowance or cloud-styling permission.
    /// Looking up and applying a revalidated history look stays local and free in those cases.
    /// Source choice, an ineligible starting piece or an unready On Me still need attention first.
    var styleMeCanCheckHistoryOnly: Bool {
        let blockers = styleBlockers
        guard !blockers.isEmpty, !style.isGenerating else { return false }
        return blockers.allSatisfy { blocker in
            switch blocker {
            case .permissionDeclined, .allowanceExhausted, .noAccess: true
            case .awaitingSourceChoice, .startingItemIneligible, .onMeNotReady: false
            }
        }
    }

    /// Local history lookup only. Never calls the stylist or image services and never consumes units.
    /// Returns false when no revalidated match exists (nothing changes in that case).
    @discardableResult
    func styleMeCheckHistoryOnly() -> Bool {
        guard styleMeCanCheckHistoryOnly else { return false }
        let request = buildRequest()
        guard let match = store.historyMatch(for: request) else { return false }
        style.historyOffer = HistoryOffer(entry: match, request: request)
        style.current = nil
        style.phase = .finished
        // Same routing as Style Me: inline beside the form when wide, otherwise one pushed results screen.
        if style.resultsShownInline {
            select(.styleMe)
        } else if (paths[.styleMe] ?? NavigationPath()).isEmpty {
            push(.results, in: .styleMe)
        } else {
            select(.styleMe)
        }
        return true
    }
}
