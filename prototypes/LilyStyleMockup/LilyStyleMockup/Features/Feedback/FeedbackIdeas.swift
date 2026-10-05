import SwiftUI

// MARK: - Ideas segment

/// Approved public ideas: search, status/topic filters, sort, vote, report and block.
struct FeedbackIdeasSection: View {
    var width: WidthClass

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var reportTarget: FeedbackIdea?
    @State private var blockTarget: FeedbackIdea?

    var body: some View {
        let ui = app.feedbackUI
        let ideas = ui.visibleIdeas(app.store.ideas)
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Ideas board", subtitle: "Vote for the ones you'd use.",
                          info: "Approved ideas from people using the app. Vote for the ones you'd use.\n\nStatus shows where an idea stands. It isn't a promised delivery date.")
            FeedbackAccountStrip()
            FeedbackIdeaFilters()
            HStack(alignment: .firstTextBaseline) {
                Text(ideas.count == 1 ? "1 idea" : "\(ideas.count) ideas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Spacer(minLength: Spacing.xs)
                if ui.hasActiveFilters {
                    Button("Clear filters") { ui.clearFilters() }
                        .font(.subheadline)
                        .minimumHitTarget()
                        .hoverEffect(.highlight)
                }
            }
            if ideas.isEmpty {
                EmptyStateView(
                    title: app.store.ideas.isEmpty ? "No ideas yet" : "No matching ideas",
                    message: app.store.ideas.isEmpty
                        ? "Approved ideas will appear here."
                        : "Try another word or status — or suggest it as a new idea.",
                    systemImage: "lightbulb",
                    actionTitle: "Suggest an idea",
                    action: { ui.showComposer = true }
                )
            } else {
                LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.m) {
                    ForEach(ideas) { idea in
                        FeedbackIdeaCard(
                            idea: idea,
                            isReported: ui.reportedIdeaIDs.contains(idea.id),
                            onVote: { vote(idea) },
                            onReport: { reportTarget = idea },
                            onBlock: { blockTarget = idea }
                        )
                    }
                }
            }
            FeedbackBlockedAuthorsRow()
            SimulationNotice(
                text: "Showing a read-only copy of approved ideas saved on this device (simulated board). One vote per idea, no paid votes.\n\nStatus shows where an idea stands. It isn't a promised delivery date.",
                label: "Simulated board",
                summary: "Read-only copy on this device."
            )
        }
        .confirmationDialog("Report this idea?", isPresented: Binding(get: { reportTarget != nil }, set: { if !$0 { reportTarget = nil } }),
                            titleVisibility: .visible, presenting: reportTarget) { idea in
            ForEach(["Harassment or body shaming", "Personal information", "Spam or advertising", "Something else"], id: \.self) { reason in
                Button(reason) { report(idea, reason: reason) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { idea in
            Text("“\(idea.title)” goes to a moderator for review. Simulated: nothing is sent from this demo.")
        }
        .confirmationDialog("Block this author?", isPresented: Binding(get: { blockTarget != nil }, set: { if !$0 { blockTarget = nil } }),
                            titleVisibility: .visible, presenting: blockTarget) { idea in
            Button("Block \(idea.publicAlias)", role: .destructive) { block(idea) }
            Button("Cancel", role: .cancel) {}
        } message: { idea in
            Text("You won't see ideas from \(idea.publicAlias). They aren't told. Simulated: stored only in this demo.")
        }
    }

    private var columns: [GridItem] {
        let count: Int
        if dynamicTypeSize.isAccessibilitySize {
            count = 1
        } else {
            switch width {
            case .compact: count = 1
            case .intermediate: count = 2
            case .wide: count = 3
            }
        }
        return Array(repeating: GridItem(.flexible(), spacing: Spacing.m, alignment: .top), count: count)
    }

    private func vote(_ idea: FeedbackIdea) {
        let ui = app.feedbackUI
        guard ui.isSignedIn else {
            ui.requestSignIn(for: .vote(idea.id), from: .board)
            return
        }
        app.store.toggleVote(idea.id)
        let updated = app.store.ideas.first { $0.id == idea.id }
        app.showToast(updated?.hasVoted == true
                      ? "Vote added (simulated, saved on this device)."
                      : "Vote removed.", style: .info)
    }

    private func report(_ idea: FeedbackIdea, reason: String) {
        app.feedbackUI.reportedIdeaIDs.insert(idea.id)
        reportTarget = nil
        app.showToast("Report noted: \(reason.lowercased()). Simulated — nothing was sent. In the real app a moderator reviews it within a day.", style: .info)
    }

    private func block(_ idea: FeedbackIdea) {
        let ui = app.feedbackUI
        let alias = idea.publicAlias
        ui.blockedAliases.insert(alias)
        blockTarget = nil
        app.showToast("Blocked \(alias) (simulated). Their ideas are hidden for you.", style: .info, actionTitle: "Undo") {
            ui.blockedAliases.remove(alias)
        }
    }
}

// MARK: - Account strip

/// Shows whether she's browsing without an account or signed in with an alias.
struct FeedbackAccountStrip: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                statusWithInfo
                Spacer(minLength: Spacing.xs)
                action
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                statusWithInfo
                action
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(ui.isSignedIn ? Palette.successSurface : Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
    }

    /// The state stays on screen; the note about it sits behind the info button.
    private var statusWithInfo: some View {
        let ui = app.feedbackUI
        return HStack(spacing: Spacing.xxs) {
            Label {
                Text(ui.isSignedIn ? "Signed in (simulated) as \(ui.publicAlias ?? "your alias")" : "Browsing without an account")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: ui.isSignedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                    .foregroundStyle(ui.isSignedIn ? Palette.success : Palette.primaryAction)
            }
            InfoButton("the feedback account", title: "Feedback account",
                       text: ui.isSignedIn
                           ? "Others see only this alias — never your name or email."
                           : "Reading needs no account. Sign-in is only for posting and voting.")
        }
    }

    @ViewBuilder private var action: some View {
        let ui = app.feedbackUI
        if ui.isSignedIn {
            Menu {
                Button {
                    ui.signOut()
                    app.showToast("Signed out of the feedback board. Your closet is unaffected.", style: .info)
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                Button(role: .destructive) {
                    ui.confirmAccountDeletion = true
                } label: {
                    Label("Delete feedback account (simulated)…", systemImage: "trash")
                }
            } label: {
                Label("Account", systemImage: "ellipsis.circle")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: HitTarget.minimum)
                    .contentShape(Rectangle())
            }
            .hoverEffect(.highlight)
            .accessibilityLabel("Feedback account options")
        } else {
            Button {
                ui.requestSignIn(for: nil, from: .board)
            } label: {
                Label("Sign in to vote or post", systemImage: "apple.logo")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

// MARK: - Filters

/// Search, status chips, topic and sort controls for the ideas board.
struct FeedbackIdeaFilters: View {
    @Environment(AppModel.self) private var app
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var ui = app.feedbackUI
        let topics = Array(Set(app.store.ideas.map(\.topic))).sorted()
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
                TextField("Search ideas", text: $ui.searchText)
                    .focused($searchFocused)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .foregroundStyle(Palette.primaryText)
                if !ui.searchText.isEmpty {
                    Button {
                        ui.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Palette.secondaryText)
                            .minimumHitTarget()
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Spacing.s)
            .frame(minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(searchFocused ? Palette.primaryAction : Palette.controlBorder, lineWidth: searchFocused ? 2 : 1)
            )
            .frame(maxWidth: 600)

            ChipCarousel(isExpanded: ui.detailsBinding("statusChips"), itemsLabel: "statuses", toggleIdentifier: "feedbackStatusChipsToggle") {
                CapsuleChip(title: "All statuses", systemImage: "line.3.horizontal.decrease", isSelected: ui.statusFilter == nil) {
                    ui.statusFilter = nil
                }
                ForEach(IdeaStatus.allCases) { status in
                    CapsuleChip(title: status.label, systemImage: status.feedbackSymbol, isSelected: ui.statusFilter == status) {
                        ui.statusFilter = ui.statusFilter == status ? nil : status
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Filter by status")

            FlowLayout(spacing: Spacing.xs) {
                Menu {
                    Picker("Topic", selection: $ui.topicFilter) {
                        Text("All topics").tag(String?.none)
                        ForEach(topics, id: \.self) { topic in
                            Text(topic).tag(String?.some(topic))
                        }
                    }
                } label: {
                    FeedbackMenuChip(title: "Topic", value: ui.topicFilter ?? "All", systemImage: "tag")
                }
                .accessibilityLabel("Topic: \(ui.topicFilter ?? "All topics")")

                Menu {
                    Picker("Sort", selection: $ui.sort) {
                        ForEach(FeedbackIdeaSort.allCases) { sort in
                            Text(sort.label).tag(sort)
                        }
                    }
                } label: {
                    FeedbackMenuChip(title: "Sort", value: ui.sort.label, systemImage: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort: \(ui.sort.label)")
            }
        }
    }
}

/// Capsule menu label shared by Feedback filters.
struct FeedbackMenuChip: View {
    var title: String
    var value: String
    var systemImage: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the label wraps, so a rounded rectangle replaces the capsule.
        let shape = RoundedRectangle(cornerRadius: dynamicTypeSize.isAccessibilitySize ? Radius.tile : 999, style: .continuous)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
            (Text(title + " ").foregroundStyle(Palette.secondaryText)
                + Text(value).fontWeight(.semibold).foregroundStyle(Palette.primaryText))
                .fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .font(.subheadline)
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: HitTarget.minimum)
        .background(shape.fill(Palette.surface))
        .overlay(shape.strokeBorder(Palette.controlBorder, lineWidth: 1))
        .contentShape(shape)
        .hoverEffect(.highlight)
    }
}

// MARK: - Idea card

/// One public idea: status (text + icon), title, description, topic, public alias, votes.
struct FeedbackIdeaCard: View {
    var idea: FeedbackIdea
    var isReported = false
    /// Preview cards (composer) show the layout without live controls.
    var isPreview = false
    var onVote: (() -> Void)?
    var onReport: (() -> Void)?
    var onBlock: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                BadgeRow(badges: [idea.status.feedbackBadge] + (isReported ? [BadgeKind.custom("Reported", "flag")] : []))
                Spacer(minLength: Spacing.xs)
                if !isPreview, onReport != nil || onBlock != nil {
                    Menu {
                        if let onReport {
                            Button { onReport() } label: { Label("Report idea…", systemImage: "flag") }
                        }
                        if let onBlock {
                            Button(role: .destructive) { onBlock() } label: { Label("Block author…", systemImage: "hand.raised") }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(Palette.secondaryText)
                            .minimumHitTarget()
                    }
                    .hoverEffect(.highlight)
                    .accessibilityLabel("More actions for \(idea.title)")
                }
            }
            Text(idea.title)
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if !idea.body.isEmpty {
                CollapsibleText(idea.body, collapsedLines: 2, threshold: 3, font: .subheadline, topic: idea.title)
            }
            FlowLayout(spacing: Spacing.s) {
                Label(idea.topic, systemImage: "tag")
                Label("by \(idea.publicAlias)", systemImage: "person.circle")
                Text(idea.createdAt, format: .relative(presentation: .named))
            }
            .font(.caption)
            .foregroundStyle(Palette.secondaryText)
            voteButton
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("feedbackIdea-\(idea.id)")
    }

    @ViewBuilder private var voteButton: some View {
        let label = HStack(spacing: Spacing.xs) {
            Image(systemName: idea.hasVoted ? "arrow.up.circle.fill" : "arrow.up.circle")
            Text(idea.hasVoted ? "Voted" : "Vote")
            Text("·")
                .accessibilityHidden(true)
            Text("\(idea.votes)")
                .monospacedDigit()
        }
        if isPreview {
            label
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(idea.votes) votes")
        } else if idea.hasVoted {
            Button { onVote?() } label: { label }
                .buttonStyle(SuccessButtonStyle())
                .accessibilityLabel("Voted for \(idea.title)")
                .accessibilityValue("\(idea.votes) votes")
                .accessibilityHint("Removes your vote")
                .accessibilityAddTraits(.isSelected)
                .accessibilityIdentifier("feedbackVote-\(idea.id)")
        } else {
            Button { onVote?() } label: { label }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityLabel("Vote for \(idea.title)")
                .accessibilityValue("\(idea.votes) votes")
                .accessibilityHint("One vote per idea. You can take it back.")
                .accessibilityIdentifier("feedbackVote-\(idea.id)")
        }
    }
}

// MARK: - Blocked authors

/// Lets her see and undo blocks she made on this device.
struct FeedbackBlockedAuthorsRow: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.feedbackUI
        if !ui.blockedAliases.isEmpty {
            HStack(spacing: Spacing.s) {
                Label(ui.blockedAliases.count == 1 ? "1 blocked author" : "\(ui.blockedAliases.count) blocked authors",
                      systemImage: "hand.raised")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Spacer(minLength: Spacing.xs)
                Menu {
                    ForEach(ui.blockedAliases.sorted(), id: \.self) { alias in
                        Button("Unblock \(alias)") { ui.blockedAliases.remove(alias) }
                    }
                } label: {
                    Text("Manage")
                        .font(.subheadline.weight(.semibold))
                        .minimumHitTarget()
                }
                .hoverEffect(.highlight)
            }
        }
    }
}

/// Small icon + footnote line.
struct FeedbackFootnote: View {
    var systemImage: String
    var text: String
    /// Optional shorter line shown while a long note is closed.
    var summary: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: systemImage)
                .font(.footnote)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            CollapsibleText(text, summary: summary)
        }
    }
}

#Preview("Idea card") {
    let model = AppModel.preview
    return FeedbackIdeaCard(idea: model.store.ideas[0], onVote: {}, onReport: {}, onBlock: {})
        .padding()
        .themedScreenBackground()
        .previewEnvironment(model)
}
