import SwiftUI

/// Suggest an idea: title/body with limits, similar ideas first, an exact
/// public preview and a privacy warning. Submitting saves it locally as
/// Pending moderation; it never becomes public in this demo.
struct FeedbackComposerView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let ui = app.feedbackUI
        GeometryReader { geo in
            let twoColumns = geo.size.width >= 760 && !dynamicTypeSize.isAccessibilitySize
            ScrollView {
                Group {
                    if twoColumns {
                        HStack(alignment: .top, spacing: Spacing.l) {
                            VStack(alignment: .leading, spacing: Spacing.m) {
                                FeedbackComposerForm()
                                FeedbackComposerSubmit()
                            }
                            .frame(maxWidth: .infinity)
                            VStack(alignment: .leading, spacing: Spacing.m) {
                                FeedbackSimilarIdeas()
                                FeedbackPublicPreview()
                                FeedbackCommunityRules()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: 1100)
                    } else {
                        VStack(alignment: .leading, spacing: Spacing.m) {
                            FeedbackComposerForm()
                            FeedbackSimilarIdeas()
                            FeedbackPublicPreview()
                            FeedbackCommunityRules()
                            FeedbackComposerSubmit()
                        }
                        .frame(maxWidth: 680)
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .themedScreenBackground()
        .navigationTitle("Suggest an idea")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { ui.signInContext == .composer ? FeedbackSignInContext.composer : nil },
            set: { if $0 == nil, ui.signInContext == .composer { ui.signInContext = nil } }
        ), onDismiss: {
            if let message = ui.finishSignIn(store: app.store) { app.showToast(message) }
        }) { _ in
            FeedbackSignInSheet()
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }
}

// MARK: - Form

private struct FeedbackComposerForm: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @FocusState private var focus: Field?

    private enum Field { case title, body }

    var body: some View {
        @Bindable var ui = app.feedbackUI
        let warnings = FeedbackPrivacyCheck.warnings(in: ui.draftTitle + " " + ui.draftBody)
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Your idea", subtitle: "Public once a moderator approves it.",
                          info: "Ideas are public after a moderator approves them. Private problems belong in Private issue.")

            InlineBanner(
                style: .caution,
                title: "Don't include personal, body or closet details",
                message: "No names, contact details, measurements, photos or descriptions of your own wardrobe. Keep it about the app.",
                summary: "Keep it about the app.",
                isMessageExpanded: ui.detailsBinding("composerPrivacy")
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Title")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Spacer()
                    FeedbackCounter(count: ui.draftTitle.count, limit: FeedbackUIState.titleLimit)
                }
                TextField("A short summary, like “Pack a week of looks”", text: $ui.draftTitle, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focus, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focus = .body }
                    .padding(Spacing.s)
                    .frame(minHeight: HitTarget.minimum)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(fieldBorder(focused: focus == .title))
                    .accessibilityLabel("Idea title")
                    .accessibilityValue(ui.draftTitle.isEmpty ? "Empty" : ui.draftTitle)
                    .accessibilityHint("Up to \(FeedbackUIState.titleLimit) characters")
                    .accessibilityIdentifier("feedbackSubmitTitle")
                    .onChange(of: ui.draftTitle) { _, newValue in
                        // A vertical text field inserts a newline on Return instead of
                        // submitting; titles are one line, so Return moves to Details.
                        var title = newValue
                        if title.contains(where: \.isNewline) {
                            title = title.split(whereSeparator: \.isNewline).joined(separator: " ")
                            focus = .body
                        }
                        if title.count > FeedbackUIState.titleLimit {
                            title = String(title.prefix(FeedbackUIState.titleLimit))
                        }
                        if title != newValue { ui.draftTitle = title }
                    }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Details (optional)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Spacer()
                    FeedbackCounter(count: ui.draftBody.count, limit: FeedbackUIState.bodyLimit)
                }
                TextEditor(text: $ui.draftBody)
                    .focused($focus, equals: .body)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.xs)
                    .frame(minHeight: dynamicTypeSize.isAccessibilitySize ? 240 : 140)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(fieldBorder(focused: focus == .body))
                    .accessibilityLabel("Idea details")
                    .accessibilityHint("Optional. Up to \(FeedbackUIState.bodyLimit) characters")
                    .accessibilityIdentifier("feedbackSubmitBody")
                    .onChange(of: ui.draftBody) { _, newValue in
                        if newValue.count > FeedbackUIState.bodyLimit {
                            ui.draftBody = String(newValue.prefix(FeedbackUIState.bodyLimit))
                        }
                    }
            }

            if !warnings.isEmpty {
                InlineBanner(
                    style: .error,
                    title: "This may include personal details",
                    message: "It looks like it contains \(warnings.joined(separator: ", ")). Please remove it — moderators reject ideas with personal information."
                )
            }
        }
        .cardStyle()
    }

    private func fieldBorder(focused: Bool) -> some View {
        RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .strokeBorder(focused ? Palette.primaryAction : Palette.controlBorder, lineWidth: focused ? 2 : 1)
    }
}

/// "37 / 120" counter that turns into a warning near the limit.
private struct FeedbackCounter: View {
    var count: Int
    var limit: Int

    var body: some View {
        let near = count >= limit - max(10, limit / 20)
        Text("\(count) / \(limit)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(near ? Palette.error : Palette.secondaryText)
            .accessibilityLabel("\(count) of \(limit) characters used")
    }
}

// MARK: - Similar ideas

/// Local duplicate check shown before submitting: vote for an existing idea instead.
private struct FeedbackSimilarIdeas: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let ui = app.feedbackUI
        // Blocked authors stay hidden here too.
        let matches = FeedbackPrivacyCheck.similarIdeas(title: ui.draftTitle, body: ui.draftBody,
                                                        in: app.store.ideas.filter { !ui.blockedAliases.contains($0.publicAlias) })
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Similar ideas", info: "Already on the board? A vote there helps more than a duplicate.")
            if ui.trimmedTitle.count < 3 {
                Text("Start typing a title to check for similar ideas.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            } else if matches.isEmpty {
                Label("No similar ideas found on this device's copy of the board.", systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            } else {
                ForEach(matches) { idea in
                    Group {
                        if dynamicTypeSize.isAccessibilitySize {
                            VStack(alignment: .leading, spacing: Spacing.s) {
                                summary(idea)
                                voteButton(idea)
                            }
                        } else {
                            HStack(alignment: .top, spacing: Spacing.s) {
                                summary(idea)
                                Spacer(minLength: Spacing.xs)
                                voteButton(idea)
                            }
                        }
                    }
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                }
            }
        }
        .cardStyle()
    }

    private func summary(_ idea: FeedbackIdea) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(idea.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            StatusBadge(kind: idea.status.feedbackBadge, compact: true)
        }
    }

    private func voteButton(_ idea: FeedbackIdea) -> some View {
        Button {
            vote(idea)
        } label: {
            Label(idea.hasVoted ? "Voted · \(idea.votes)" : "Vote · \(idea.votes)",
                  systemImage: idea.hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel(idea.hasVoted ? "Voted for \(idea.title)" : "Vote for \(idea.title) instead")
        .accessibilityValue("\(idea.votes) votes")
        .accessibilityAddTraits(idea.hasVoted ? .isSelected : [])
    }

    private func vote(_ idea: FeedbackIdea) {
        let ui = app.feedbackUI
        guard ui.isSignedIn else {
            ui.requestSignIn(for: .vote(idea.id), from: .composer)
            return
        }
        app.store.toggleVote(idea.id)
        let voted = app.store.ideas.first { $0.id == idea.id }?.hasVoted == true
        app.showToast(voted ? "Vote added (simulated, saved on this device)." : "Vote removed.", style: .info)
    }
}

// MARK: - Public preview

/// Exactly what others will see once a moderator approves the idea.
private struct FeedbackPublicPreview: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        let preview = FeedbackIdea(
            id: "preview",
            title: ui.trimmedTitle.isEmpty ? "Your title appears here" : ui.trimmedTitle,
            body: ui.trimmedBody,
            topic: "Topic set by moderators",
            status: .underReview,
            votes: 0,
            publicAlias: ui.publicAlias ?? "your-alias",
            createdAt: .now
        )
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("This is what others will see", subtitle: "After approval.",
                          info: "After approval. Until then it stays private in My submissions.")
            FeedbackIdeaCard(idea: preview, isPreview: true)
            // Who sees what stays on screen before she submits.
            CollapsibleText(
                ui.isSignedIn
                    ? "Shown with your alias \(ui.publicAlias ?? ""), never your name, email or Apple ID."
                    : "You'll get a generated alias when you sign in. Your name, email and Apple ID are never shown.",
                summary: "Shown with an alias, never your name or email.",
                threshold: 1,
                topic: "what others see"
            )
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Community rules

private struct FeedbackCommunityRules: View {
    @Environment(AppModel.self) private var app

    private static let rules = [
        "Keep it about the app — no personal, contact, body or closet details.",
        "Be kind. No harassment, body shaming, sexual content, threats or spam.",
        "Moderators approve every idea before it's public, and may merge duplicates.",
        "Up to \(FeedbackUIState.dailyIdeaLimit) ideas a day (sample limit). No photos, comments or messages.",
    ]

    var body: some View {
        DetailsDisclosure(
            "Community rules",
            count: Self.rules.count,
            systemImage: "person.2",
            isExpanded: app.feedbackUI.detailsBinding("communityRules"),
            identifier: "feedbackCommunityRules"
        ) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(Self.rules, id: \.self) { rule in
                    Label(rule, systemImage: "checkmark")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Submit

private struct FeedbackComposerSubmit: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        let store = app.store
        let todayCount = ui.ideasSubmittedToday(store)
        let limitReached = todayCount >= FeedbackUIState.dailyIdeaLimit
        VStack(alignment: .leading, spacing: Spacing.s) {
            if limitReached {
                InlineBanner(
                    style: .caution,
                    title: "Daily limit reached",
                    message: "You've suggested \(todayCount) ideas in the last day (sample limit \(FeedbackUIState.dailyIdeaLimit)). Your draft is kept — try again tomorrow."
                )
            }
            Button {
                submit()
            } label: {
                Label(ui.isSignedIn ? "Submit for moderation" : "Sign in & submit for moderation", systemImage: "paperplane")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!ui.canSubmitIdea(store))
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityIdentifier("feedbackSubmitIdea")
            .accessibilityHint(ui.isSignedIn ? "Saves it as Pending moderation" : "Asks you to sign in first (simulated)")
            SimulationNotice(text: "Simulated: the idea is saved on this device as Pending moderation. Nothing is sent and it never becomes public in this demo.",
                             summary: "Saved on this device. Nothing is sent.")
        }
    }

    private func submit() {
        let ui = app.feedbackUI
        guard ui.canSubmitIdea(app.store) else { return }
        guard ui.isSignedIn else {
            ui.requestSignIn(for: .submitIdea, from: .composer)
            return
        }
        app.showToast(ui.submitDraft(store: app.store))
    }
}

// MARK: - Local checks

/// Local, keyword-only helpers. No AI moderation is used.
enum FeedbackPrivacyCheck {
    /// Phrases describing likely personal data, for a gentle warning.
    static func warnings(in text: String) -> [String] {
        var found: [String] = []
        if text.range(of: #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#, options: [.regularExpression, .caseInsensitive]) != nil {
            found.append("an email address")
        }
        if text.range(of: #"https?://|www\."#, options: [.regularExpression, .caseInsensitive]) != nil {
            found.append("a link")
        }
        if text.range(of: #"\b\d{1,3}(\.\d)?\s?(lb|lbs|kg|cm|inch|inches|″|′|'|")(?![a-z])"#, options: [.regularExpression, .caseInsensitive]) != nil {
            found.append("a measurement")
        }
        if text.range(of: #"\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b"#, options: .regularExpression) != nil {
            found.append("a phone number")
        }
        return found
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "your", "have", "what", "when", "show", "make",
        "more", "each", "would", "like", "could", "should", "into", "about", "them", "they", "please", "want",
    ]

    /// Approved ideas sharing meaningful words with the draft (simple local contains match).
    static func similarIdeas(title: String, body: String, in ideas: [FeedbackIdea]) -> [FeedbackIdea] {
        let words = (title + " " + body).lowercased()
            .split { !$0.isLetter }
            .map(String.init)
            .filter { $0.count >= 4 && !stopWords.contains($0) }
        guard !words.isEmpty else { return [] }
        let stems = Set(words.map { String($0.prefix(max(4, $0.count - 2))) })
        return ideas
            .map { idea -> (FeedbackIdea, Int) in
                let haystack = (idea.title + " " + idea.body + " " + idea.topic).lowercased()
                return (idea, stems.filter { haystack.contains($0) }.count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.votes > $1.0.votes }
            .prefix(3)
            .map(\.0)
    }
}

#Preview("Suggest an idea") {
    let model = AppModel.preview
    model.feedbackUI.draftTitle = "Plan a trip's outfits"
    return NavigationStack {
        FeedbackComposerView()
    }
    .previewEnvironment(model)
}
