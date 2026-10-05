import SwiftUI

/// My submissions: her ideas with moderation state, withdraw/delete, and the
/// optional feedback account (simulated) with deletion.
struct FeedbackSubmissionsSection: View {
    var width: WidthClass

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var removalTarget: MySubmission?

    var body: some View {
        let ui = app.feedbackUI
        let submissions = app.store.submissions.sorted { $0.submittedAt > $1.submittedAt }
        VStack(alignment: .leading, spacing: Spacing.m) {
            if dynamicTypeSize.isAccessibilitySize {
                SectionHeader("My submissions", subtitle: "Private until approved.", info: Self.headerInfo)
                suggestButton
            } else {
                SectionHeader("My submissions", subtitle: "Private until approved.", info: Self.headerInfo) {
                    suggestButton
                }
            }

            if submissions.isEmpty {
                EmptyStateView(
                    title: "No submissions yet",
                    message: "Ideas you suggest show up here with their moderation status.",
                    systemImage: "tray",
                    actionTitle: "Suggest an idea",
                    action: { ui.showComposer = true }
                )
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.m) {
                    ForEach(submissions) { submission in
                        FeedbackSubmissionCard(submission: submission) {
                            removalTarget = submission
                        }
                    }
                }
            }

            FeedbackAccountCard()
        }
        .confirmationDialog(
            removalTarget?.state == .pendingModeration ? "Withdraw this idea?" : "Delete this idea?",
            isPresented: Binding(get: { removalTarget != nil }, set: { if !$0 { removalTarget = nil } }),
            titleVisibility: .visible,
            presenting: removalTarget
        ) { submission in
            Button(submission.state == .pendingModeration ? "Withdraw idea" : "Delete idea", role: .destructive) {
                app.store.feedbackRemoveSubmission(submission.id)
                removalTarget = nil
                app.showToast(submission.state == .pendingModeration
                              ? "Withdrawn. It won't be reviewed or published."
                              : "Deleted from the board (simulated).", style: .info)
            }
            Button("Keep it", role: .cancel) {}
        } message: { submission in
            Text(submission.state == .pendingModeration
                 ? "“\(submission.title)” will be removed from the moderation queue. Simulated on this device."
                 : "“\(submission.title)” and its public listing will be removed. Simulated on this device.")
        }
    }

    private static let headerInfo = "Pending ideas are visible only to you until a moderator approves them."

    private var suggestButton: some View {
        Button {
            app.feedbackUI.showComposer = true
        } label: {
            Label("Suggest", systemImage: "square.and.pencil")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel("Suggest an idea")
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize || width == .compact ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.m, alignment: .top), count: count)
    }
}

/// One submission with its moderation state (text + icon).
private struct FeedbackSubmissionCard: View {
    var submission: MySubmission
    var onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    StatusBadge(kind: submission.state.feedbackBadge)
                    Spacer(minLength: Spacing.xs)
                    submittedDate
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    StatusBadge(kind: submission.state.feedbackBadge)
                    submittedDate
                }
            }
            Text(submission.title)
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if !submission.body.isEmpty, submission.body != "…" {
                CollapsibleText(submission.body, collapsedLines: 2, threshold: 3, font: .subheadline, topic: submission.title)
            }
            Text(explanation)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive, action: onRemove) {
                Label(submission.state == .pendingModeration ? "Withdraw" : "Delete", systemImage: "trash")
            }
            .buttonStyle(DestructiveButtonStyle())
            .accessibilityLabel("\(submission.state == .pendingModeration ? "Withdraw" : "Delete") “\(submission.title)”")
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    private var submittedDate: some View {
        Text(submission.submittedAt, format: .relative(presentation: .named))
            .font(.caption)
            .foregroundStyle(Palette.secondaryText)
    }

    private var explanation: String {
        switch submission.state {
        case .pendingModeration: "Only you can see this. It becomes public after a moderator approves it."
        case .approved: "Public on the board under your alias."
        case .rejected: "Not published, and kept private. You can delete it."
        case .merged: "Combined with a similar idea — votes go to that one."
        }
    }
}

/// Optional feedback account (simulated): sign in, sign out or delete.
private struct FeedbackAccountCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Feedback account", subtitle: "Optional. Only for posting and voting.",
                          info: "Optional, and only for posting and voting. Your closet never needs an account.")
            if ui.isSignedIn {
                InfoRow(title: "Public alias", value: ui.publicAlias ?? "—")
                InfoRow(title: "Signed in with", value: "Apple (simulated)")
                // Delete sits in the menu and still asks before anything is removed.
                ActionGroup(moreIdentifier: "feedbackAccountMore") {
                    signOutButton
                } more: {
                    deleteButton
                }
                CollapsibleText(
                    "Deleting the account removes your alias, votes and submitted ideas. It doesn't touch your closet, and it doesn't cancel billing.",
                    summary: "Deleting removes your alias, votes and ideas.",
                    threshold: 1,
                    topic: "deleting the account"
                )
            } else {
                CollapsibleText(
                    "You're not signed in. You can read the board and send private issues without an account.",
                    summary: "You're not signed in.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "browsing without an account"
                )
                Button {
                    ui.requestSignIn(for: nil, from: .board)
                } label: {
                    Label("Sign in to vote or post", systemImage: "apple.logo")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .cardStyle()
    }

    private var signOutButton: some View {
        Button {
            app.feedbackUI.signOut()
            app.showToast("Signed out of the feedback board. Your closet is unaffected.", style: .info)
        } label: {
            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            app.feedbackUI.confirmAccountDeletion = true
        } label: {
            Label("Delete feedback account (simulated)…", systemImage: "trash")
        }
    }
}
