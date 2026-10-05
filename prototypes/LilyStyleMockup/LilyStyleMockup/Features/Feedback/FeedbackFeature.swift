import SwiftUI

/// The three Feedback areas. Public ideas and private issues are separate forms.
enum FeedbackSegment: String, CaseIterable, Identifiable, Hashable {
    case ideas, submissions, issue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ideas: "Ideas"
        case .submissions: "My submissions"
        case .issue: "Private issue"
        }
    }

    var systemImage: String {
        switch self {
        case .ideas: "lightbulb"
        case .submissions: "tray.full"
        case .issue: "lock.shield"
        }
    }
}

enum FeedbackIdeaSort: String, CaseIterable, Identifiable, Hashable {
    case votes, recent

    var id: String { rawValue }

    var label: String {
        switch self {
        case .votes: "Most votes"
        case .recent: "Most recent"
        }
    }
}

/// What to finish after the optional (simulated) sign-in.
enum FeedbackPendingAction: Hashable {
    case vote(String)
    case submitIdea
}

/// Where the sign-in sheet is presented from (board root or the idea composer).
enum FeedbackSignInContext: String, Identifiable, Hashable {
    case board, composer
    var id: String { rawValue }
}

/// Feedback board + private support UI state, owned by `AppModel` (`app.feedbackUI`).
///
/// Segment, filters, drafts and the simulated feedback-only sign-in live here so
/// moving between the iPad sidebar and the compact sheet keeps them. The closet
/// never needs this account; nothing here talks to a network.
@Observable
final class FeedbackUIState {
    var segment: FeedbackSegment = .ideas

    // Ideas board
    var searchText = ""
    var statusFilter: IdeaStatus?
    var topicFilter: String?
    var sort: FeedbackIdeaSort = .votes
    var reportedIdeaIDs: Set<String> = []
    /// Blocking hides that alias's ideas for her only (simulated).
    var blockedAliases: Set<String> = []

    // Optional feedback-only sign-in (simulated Sign in with Apple)
    var isSignedIn = false
    var publicAlias: String?
    var pendingAction: FeedbackPendingAction?
    var signInContext: FeedbackSignInContext?
    var confirmAccountDeletion = false

    // Suggest an idea
    var showComposer = false
    var draftTitle = ""
    var draftBody = ""

    // Private issue
    var issueCategory: IssueCategory = .bug
    var issueMessage = ""
    var issueReplyEmail = ""
    var issueIncludeDiagnostics = false
    var issueReference = FeedbackUIState.makeReference()
    var lastSubmittedIssueID: String?

    // Disclosures
    /// Open details rows and expanded chip rows, by key, so they stay open through a
    /// rotation and the move between the iPad sidebar and the compact sheet.
    var openDetails: Set<String> = []

    func detailsBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { self.openDetails.contains(key) },
            set: { open in
                if open {
                    self.openDetails.insert(key)
                } else {
                    self.openDetails.remove(key)
                }
            }
        )
    }

    static let titleLimit = 120
    static let bodyLimit = 2000
    static let issueLimit = 2000
    static let dailyIdeaLimit = 3
    /// Sample per-installation limit for private tickets (PRD 22.1, proposed).
    static let dailyIssueLimit = 5

    init() {}

    // MARK: Sign-in

    /// True between a completed sign-in and its sheet finishing dismissal.
    private var signInCompleted = false

    /// Starts the optional sign-in, remembering what to finish afterwards.
    func requestSignIn(for action: FeedbackPendingAction?, from context: FeedbackSignInContext) {
        pendingAction = action
        signInCompleted = false
        signInContext = context
    }

    /// Dismisses the sign-in sheet without signing in.
    func cancelSignIn() {
        signInCompleted = false
        signInContext = nil
    }

    /// Simulated Sign in with Apple: assigns a generated public alias and closes the sheet.
    /// The action that needed it runs once the sheet has finished closing.
    func signIn(store: DemoStore) {
        isSignedIn = true
        if publicAlias == nil {
            publicAlias = Self.makeAlias(avoiding: Set(store.ideas.map(\.publicAlias)))
        }
        signInCompleted = true
        signInContext = nil
    }

    /// Called from the sheet's `onDismiss`. Finishes the pending vote or idea after a
    /// sign-in, or drops it after a cancel. Returns a toast message, if any.
    func finishSignIn(store: DemoStore) -> String? {
        let action = pendingAction
        pendingAction = nil
        guard signInCompleted else { return nil }
        signInCompleted = false
        let alias = publicAlias ?? "your alias"
        switch action {
        case let .vote(id)?:
            if let idea = store.ideas.first(where: { $0.id == id }), !idea.hasVoted {
                store.toggleVote(id)
            }
            return "Signed in (simulated) as \(alias). Your vote is counted — on this device only."
        case .submitIdea?:
            return submitDraft(store: store)
        case nil:
            return "Signed in (simulated). Others only ever see your alias, \(alias)."
        }
    }

    func signOut() {
        isSignedIn = false
    }

    /// Simulated account deletion: removes alias, votes and submitted ideas. Closet data is separate.
    func deleteAccount(store: DemoStore) {
        store.feedbackRemoveAccountContent()
        isSignedIn = false
        publicAlias = nil
    }

    // MARK: Ideas

    func visibleIdeas(_ ideas: [FeedbackIdea]) -> [FeedbackIdea] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ideas
            .filter { !blockedAliases.contains($0.publicAlias) }
            .filter { statusFilter == nil || $0.status == statusFilter }
            .filter { topicFilter == nil || $0.topic == topicFilter }
            .filter { idea in
                query.isEmpty || [idea.title, idea.body, idea.topic].contains { $0.lowercased().contains(query) }
            }
            .sorted { a, b in
                switch sort {
                case .votes: a.votes != b.votes ? a.votes > b.votes : a.createdAt > b.createdAt
                case .recent: a.createdAt > b.createdAt
                }
            }
    }

    var hasActiveFilters: Bool {
        !searchText.isEmpty || statusFilter != nil || topicFilter != nil
    }

    func clearFilters() {
        searchText = ""
        statusFilter = nil
        topicFilter = nil
    }

    // MARK: Composer

    var trimmedTitle: String { draftTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedBody: String { draftBody.trimmingCharacters(in: .whitespacesAndNewlines) }

    func ideasSubmittedToday(_ store: DemoStore) -> Int {
        store.submissions.filter { $0.submittedAt > Date.now.addingTimeInterval(-86_400) }.count
    }

    func canSubmitIdea(_ store: DemoStore) -> Bool {
        !trimmedTitle.isEmpty && draftTitle.count <= Self.titleLimit && draftBody.count <= Self.bodyLimit
            && ideasSubmittedToday(store) < Self.dailyIdeaLimit
    }

    /// Saves the idea locally as Pending moderation (private until approved).
    func submitDraft(store: DemoStore) -> String {
        guard canSubmitIdea(store) else { return "Your idea wasn't submitted. Check the title and limits." }
        store.submitIdea(title: trimmedTitle, body: trimmedBody)
        draftTitle = ""
        draftBody = ""
        showComposer = false
        segment = .submissions
        return "Submitted for moderation (simulated). It stays private until approved — nothing left this device."
    }

    // MARK: Private issue

    var issueEmailIsValid: Bool {
        let email = issueReplyEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return true }
        let parts = email.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".") && !email.contains(" ")
    }

    var canSubmitIssue: Bool {
        !issueMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && issueMessage.count <= Self.issueLimit && issueEmailIsValid
    }

    func issuesSubmittedToday(_ store: DemoStore) -> Int {
        store.issueReports.filter { $0.submittedAt > Date.now.addingTimeInterval(-86_400) }.count
    }

    /// Saves the private report on this device (simulated support queue).
    func submitIssue(store: DemoStore) {
        guard canSubmitIssue, issuesSubmittedToday(store) < Self.dailyIssueLimit else { return }
        let email = issueReplyEmail.trimmingCharacters(in: .whitespaces)
        let report = PrivateIssueReport(
            category: issueCategory,
            message: issueMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            replyEmail: email.isEmpty ? nil : email,
            includeDiagnostics: issueIncludeDiagnostics
        )
        store.submitIssue(report)
        lastSubmittedIssueID = report.id
        issueMessage = ""
        issueReplyEmail = ""
        issueIncludeDiagnostics = false
        issueReference = Self.makeReference()
    }

    // MARK: Helpers

    static func makeAlias(avoiding taken: Set<String>) -> String {
        let candidates = ["ivory-finch", "sage-robin", "linen-lark", "rose-plover", "dune-swallow"]
        return candidates.first { !taken.contains($0) } ?? "petite-\(Int.random(in: 100...999))"
    }

    static func makeReference() -> String {
        "ref-" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased()
    }
}

/// Feedback & Support: approved ideas with votes and status, the idea composer,
/// My submissions, and a separate private issue form. Browsing needs no
/// account; the simulated Sign in with Apple is only for posting and voting.
struct FeedbackScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var ui = app.feedbackUI
        GeometryReader { geo in
            let width = WidthClass(width: geo.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    segmentPicker
                    switch ui.segment {
                    case .ideas: FeedbackIdeasSection(width: width)
                    case .submissions: FeedbackSubmissionsSection(width: width)
                    case .issue: FeedbackIssueSection(width: width)
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: width == .compact ? 720 : 1180)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .themedScreenBackground()
        .navigationTitle("Feedback & Support")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    ui.showComposer = true
                } label: {
                    Label("Suggest an idea", systemImage: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .accessibilityHint("Opens a form to suggest a public idea")
            }
        }
        .navigationDestination(isPresented: $ui.showComposer) {
            FeedbackComposerView()
        }
        .sheet(item: Binding(
            get: { ui.signInContext == .board ? FeedbackSignInContext.board : nil },
            set: { if $0 == nil, ui.signInContext == .board { ui.signInContext = nil } }
        ), onDismiss: {
            if let message = ui.finishSignIn(store: app.store) { app.showToast(message) }
        }) { _ in
            FeedbackSignInSheet()
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .alert("Delete feedback account? (Simulated)", isPresented: $ui.confirmAccountDeletion) {
            Button("Delete feedback account", role: .destructive) {
                ui.deleteAccount(store: app.store)
                app.showToast("Feedback account deleted (simulated). Nothing was sent, and your closet is unchanged.", style: .info)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your public alias, your votes and the ideas you submitted. Your closet, looks and profile stay on this device — they never needed this account. Billing isn't cancelled; manage any subscription in Settings.")
        }

    }

    @ViewBuilder private var segmentPicker: some View {
        @Bindable var ui = app.feedbackUI
        if dynamicTypeSize.isAccessibilitySize {
            Picker("Feedback section", selection: $ui.segment) {
                ForEach(FeedbackSegment.allCases) { segment in
                    Label(segment.title, systemImage: segment.systemImage).tag(segment)
                }
            }
            .pickerStyle(.menu)
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("feedbackSegment")
        } else {
            Picker("Feedback section", selection: $ui.segment) {
                ForEach(FeedbackSegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("feedbackSegment")
        }
    }
}

// MARK: - Store helpers (feature-local)

extension DemoStore {
    /// Withdraws or deletes one of her submissions (local simulation).
    func feedbackRemoveSubmission(_ id: String) {
        submissions.removeAll { $0.id == id }
        commit(inventoryChanged: false)
    }

    /// Simulated feedback-account deletion: removes her votes and submitted ideas.
    /// Closet, outfits, profile and private support reports are untouched.
    func feedbackRemoveAccountContent() {
        for index in ideas.indices where ideas[index].hasVoted {
            ideas[index].hasVoted = false
            ideas[index].votes = max(0, ideas[index].votes - 1)
        }
        submissions.removeAll()
        commit(inventoryChanged: false)
    }
}

// MARK: - Shared visual vocabulary

extension IdeaStatus {
    var feedbackSymbol: String {
        switch self {
        case .underReview: "eye"
        case .planned: "calendar"
        case .inProgress: "hammer"
        case .released: "checkmark.seal"
        case .notPlanned: "xmark.circle"
        }
    }

    var feedbackBadge: BadgeKind { .custom(label, feedbackSymbol) }
}

extension SubmissionState {
    var feedbackBadge: BadgeKind {
        switch self {
        case .pendingModeration: .custom(label, "hourglass")
        case .approved: .custom(label, "checkmark.circle")
        case .rejected: .custom(label, "eye.slash")
        case .merged: .custom(label, "arrow.triangle.merge")
        }
    }
}

extension IssueCategory {
    var feedbackSymbol: String {
        switch self {
        case .bug: "ladybug"
        case .stylingQuality: "sparkles"
        case .billing: "creditcard"
        case .privacy: "hand.raised"
        case .security: "lock.shield"
        }
    }

    var feedbackHint: String {
        switch self {
        case .bug: "Say what you tapped and what happened. Screenshots aren't attached in this version."
        case .stylingQuality: "Describe the look in your own words. Outfits and prompts are never attached automatically."
        case .billing: "Billing changes aren't made from here. Manage subscriptions in Settings."
        case .privacy: "Privacy reports are handled privately and with priority."
        case .security: "Security reports are escalated right away."
        }
    }
}

// MARK: - Previews

#Preview("Feedback — Ideas") {
    NavigationStack {
        FeedbackScreen()
    }
    .previewEnvironment()
}

#Preview("Feedback — Private issue") {
    let model = AppModel.preview
    model.feedbackUI.segment = .issue
    return NavigationStack {
        FeedbackScreen()
    }
    .previewEnvironment(model)
}
