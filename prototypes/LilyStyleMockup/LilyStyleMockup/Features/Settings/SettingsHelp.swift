import SwiftUI

// MARK: - Help content

/// Short, offline, task-based help. Bundled text only: no AI, no account, no network.
struct SettingsHelpTopic: Identifiable {
    let id: Int
    let title: String
    let systemImage: String
    let steps: [String]

    static let all: [SettingsHelpTopic] = [
        SettingsHelpTopic(id: 0, title: "Get outfit ideas without a full closet", systemImage: "sparkles", steps: [
            "Add a few pieces you wear most. A name is enough; photos can come later.",
            "In Style Me, pick an occasion and tap Style Me.",
            "If there aren't enough pieces, you'll see an honest partial result. Nothing is invented.",
            "Add more garments whenever you like. You never need to finish your closet first.",
        ]),
        SettingsHelpTopic(id: 1, title: "Add a garment", systemImage: "plus.circle", steps: [
            "In Closet, tap Add Item and use Camera, Photos, Paste or just type a name.",
            "Name it your way, like “cute pink shirt”. Other names help search find it later.",
            "Details you don't know can stay Unknown.",
            "Your original photo is always kept.",
            "Bought something through Find One? Confirm the purchase and it's added for you. It's only used for styling once you've marked it arrived.",
        ]),
        SettingsHelpTopic(id: 2, title: "Swap, save and reopen a look", systemImage: "arrow.left.arrow.right", steps: [
            "Tap a piece in a look to see real alternatives from the same source.",
            "A swap changes only that piece; the rest of the look stays put.",
            "Save keeps the look in Saved Looks. Save as Copy makes a new one.",
            "Open it from Saved Looks any time to keep editing. Undo works while you edit.",
        ]),
        SettingsHelpTopic(id: 3, title: "Ownership & availability", systemImage: "tag", steps: [
            "Dirty: still yours, skipped for today's styling until you mark it clean. Wearing something never marks it Dirty on its own.",
            "Archive: kept but left out of everyday styling. Unarchive brings back its earlier status.",
            "No longer own: moves to history. Old looks keep it, clearly labelled.",
            "Trash: removed from your closet but restorable for a while. Permanent delete is a separate step.",
        ]),
        SettingsHelpTopic(id: 4, title: "Suitcases", systemImage: "suitcase", steps: [
            "A suitcase is a named group, like Jose's house, inside Closet.",
            "Adding a garment links it. It isn't copied and still shows in Main Closet.",
            "Styling from a suitcase uses only its pieces. Switch to Main Closet yourself if you want more.",
            "Deleting a suitcase keeps every garment and saved look.",
        ]),
        SettingsHelpTopic(id: 5, title: "Original photos & processing", systemImage: "photo", steps: [
            "Your original photo is saved first and never replaced.",
            "Cleaning up the background is optional, and you can go back to the original.",
            "Photo descriptions need their own permission. You can always name things yourself.",
        ]),
        SettingsHelpTopic(id: 6, title: "Saved locally vs iCloud vs export", systemImage: "externaldrive", steps: [
            "Everything saves on this device first.",
            "Private iCloud sync (optional) keeps your devices up to date. A last-sync time doesn't mean later edits have uploaded.",
            "An export is a snapshot file you keep in Files. It doesn't update itself.",
            "In this prototype, sync and export are simulated.",
        ]),
        SettingsHelpTopic(id: 7, title: "Restore safely", systemImage: "arrow.counterclockwise", steps: [
            "Import shows what's in a backup and checks it before anything changes.",
            "Merge adds what's new without duplicates. Replace makes a recovery export of your current closet first.",
            "A damaged backup is rejected and your closet stays exactly as it was.",
        ]),
        SettingsHelpTopic(id: 8, title: "Free core vs paid AI", systemImage: "creditcard", steps: [
            "Always free: closet, saved looks, search, manual editing, history, export and Ask another stylist.",
            "Style Me, AI swaps and Find One search use styling access (sample terms in this prototype).",
            "If access ends or today's allowance runs out, nothing is deleted.",
        ]),
        SettingsHelpTopic(id: 9, title: "On Me previews vs physical fit", systemImage: "person.crop.rectangle", steps: [
            "On Me pictures are simulated previews, not a photo of you.",
            "They can't show how something actually fits. Your measurements and fit notes are the better guide.",
            "Earlier pictures stay in your history after a swap.",
        ]),
        SettingsHelpTopic(id: 10, title: "Find One and fit evidence", systemImage: "magnifyingglass", steps: [
            "Find One starts only when you ask, for one specific piece.",
            "Each lead says whether it has supported sizing guidance or needs fit confirmation.",
            "Unknown measurements stay Unknown. No lead is a guaranteed fit.",
            "You buy at the store, then confirm what you bought and when it arrives.",
        ]),
    ]
}

// MARK: - Help screen

/// Offline task-based help. Opening or closing help never changes a draft, a request
/// or a result, and it never calls a service.
struct HelpView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geo in
            SettingsList(horizontalMargin: SettingsLayout.readableMargin(for: geo.size.width)) {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Label("Works offline · no account · no AI", systemImage: "wifi.slash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.primaryAction)
                            .accessibilityIdentifier("helpOfflineNote")
                        CollapsibleText(
                            "Short guides for everyday tasks. Opening help never changes what you're working on.",
                            summary: "Short guides for everyday tasks.",
                            threshold: 1,
                            font: .subheadline,
                            topic: "help"
                        )
                    }
                    .padding(.vertical, Spacing.xxs)
                }
                .listRowBackground(Palette.surface)

                Section {
                    ForEach(SettingsHelpTopic.all) { topic in
                        DisclosureGroup(isExpanded: expanded(topic.id)) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                ForEach(topic.steps, id: \.self) { step in
                                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                                        Text("•")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(Palette.primaryAction)
                                            .accessibilityHidden(true)
                                        Text(step)
                                            .font(.subheadline)
                                            .foregroundStyle(Palette.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.vertical, Spacing.xxs)
                        } label: {
                            Label {
                                Text(topic.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Palette.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Image(systemName: topic.systemImage)
                                    .foregroundStyle(Palette.primaryAction)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityIdentifier("helpTopic-\(topic.id)")
                    }
                } header: {
                    SettingsListHeader("Guides", systemImage: "book")
                } footer: {
                    Button(allExpanded ? "Collapse all" : "Expand all") {
                        app.settingsUI.expandedHelpTopics = allExpanded ? [] : Set(SettingsHelpTopic.all.map(\.id))
                    }
                    .font(.footnote.weight(.semibold))
                    .minimumHitTarget()
                    .accessibilityIdentifier("helpExpandAll")
                }
                .listRowBackground(Palette.surface)

                Section {
                    DetailsDisclosure(
                        "Needs a connection",
                        summary: "Styling and pictures",
                        systemImage: "wifi",
                        isExpanded: app.settingsUI.detailsBinding("helpOnline"),
                        identifier: "helpNeedsConnection"
                    ) {
                        SettingsDetailText("Style Me, AI swaps, Find One search and On Me pictures need styling access and a connection. In this prototype they're simulated.")
                    }
                    DetailsDisclosure(
                        "Works offline",
                        summary: "Everything else",
                        systemImage: "wifi.slash",
                        isExpanded: app.settingsUI.detailsBinding("helpOffline"),
                        identifier: "helpWorksOffline"
                    ) {
                        SettingsDetailText("Everything else, including your closet, saved looks, search, manual editing, history and export, works offline.")
                    }
                } header: {
                    SettingsListHeader("What needs a connection", systemImage: "antenna.radiowaves.left.and.right")
                }
                .listRowBackground(Palette.surface)

                Section {
                    NavigationLink(value: AppRoute.releaseNotes) {
                        SettingsRowLabel(title: "What changed", subtitle: "Version notes and known limitations", systemImage: "sparkles.rectangle.stack")
                    }
                    .accessibilityIdentifier("helpReleaseNotesRow")
                    Button {
                        app.open(.feedback, compact: sizeClass == .compact)
                    } label: {
                        SettingsRowLabel(title: "Feedback & support", subtitle: "Still stuck? Send a private report.", systemImage: "bubble.left.and.text.bubble.right")
                    }
                    .accessibilityIdentifier("helpFeedbackRow")
                } header: {
                    SettingsListHeader("More", systemImage: "ellipsis.circle")
                }
                .listRowBackground(Palette.surface)
            }
        }
        .themedScreenBackground()
        .navigationTitle("Help")
    }

    private var allExpanded: Bool {
        app.settingsUI.expandedHelpTopics.count == SettingsHelpTopic.all.count
    }

    private func expanded(_ id: Int) -> Binding<Bool> {
        Binding(
            get: { app.settingsUI.expandedHelpTopics.contains(id) },
            set: { isOpen in
                if isOpen {
                    app.settingsUI.expandedHelpTopics.insert(id)
                } else {
                    app.settingsUI.expandedHelpTopics.remove(id)
                }
            }
        )
    }
}

// MARK: - Release notes

/// Read-only, bundled version notes with dates, changes and known limitations.
struct ReleaseNotesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                CollapsibleText(
                    "Read-only notes, bundled so they work offline. Planned work lives on the Feedback board, not here.",
                    summary: "Read-only notes that work offline.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "these notes"
                )
                ForEach(Array(DemoFixtures.releaseNotes.enumerated()), id: \.offset) { index, note in
                    SettingsReleaseNoteCard(note: note, isCurrent: index == 0)
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .themedScreenBackground()
        .navigationTitle("What Changed")
    }
}

private struct SettingsReleaseNoteCard: View {
    @Environment(AppModel.self) private var app
    var note: ReleaseNote
    var isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    versionTitle
                    Spacer(minLength: Spacing.xs)
                    if isCurrent { currentBadge }
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    versionTitle
                    if isCurrent { currentBadge }
                }
            }
            Text(note.date.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)

            // The current version opens on its changes; older versions and the
            // limitations lists start closed.
            if isCurrent {
                SectionHeader("What changed")
                changes
            } else {
                DetailsDisclosure(
                    "What changed",
                    count: note.changes.count,
                    isExpanded: app.settingsUI.detailsBinding("releaseChanges-\(note.version)")
                ) {
                    changes
                }
            }

            Divider().overlay(Palette.divider)

            DetailsDisclosure(
                "Known limitations",
                count: note.knownLimitations.count,
                isExpanded: app.settingsUI.detailsBinding("releaseLimits-\(note.version)")
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(note.knownLimitations, id: \.self) { limitation in
                        SettingsBullet(limitation, systemImage: "exclamationmark.circle", tint: Palette.primaryAction)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("releaseNote-\(note.version)")
    }

    private var changes: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ForEach(note.changes, id: \.self) { change in
                SettingsBullet(change, systemImage: "checkmark.circle", tint: Palette.success)
            }
        }
    }

    private var versionTitle: some View {
        Text("Version \(note.version)")
            .font(.editorial(.title2))
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private var currentBadge: some View {
        SettingsBadge(text: "This version", systemImage: "checkmark.seal", tone: .success)
    }
}

// MARK: - Previews

#Preview("Help") {
    NavigationStack {
        HelpView()
    }
    .previewEnvironment()
}

#Preview("What changed") {
    NavigationStack {
        ReleaseNotesView()
    }
    .previewEnvironment()
}
