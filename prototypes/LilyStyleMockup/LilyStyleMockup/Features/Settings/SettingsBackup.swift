import SwiftUI

// MARK: - Export review

/// Counts for an export review, read from the canonical store (nothing is written).
struct SettingsBackupCounts {
    var garments: Int
    var trashed: Int
    var noLongerOwned: Int
    var photos: Int
    var suitcases: Int
    var memberships: Int
    var savedLooks: Int
    var previews: Int
    var collections: Int
    var history: Int
    var measurements: Int
    /// 1 when an optional weight is saved, otherwise 0.
    var weight: Int
    var fitReferences: Int
    var savedProducts: Int
    var reminders: Int

    init(store: DemoStore) {
        garments = store.garments.count
        trashed = store.garments.filter(\.isTrashed).count
        noLongerOwned = store.garments.filter { $0.ownership == .noLongerOwned }.count
        photos = store.settingsPhotoCount
        suitcases = store.suitcases.count
        memberships = store.memberships.count
        savedLooks = store.savedOutfits.count
        previews = store.previews.count
        collections = store.collections.count
        history = store.history.count
        measurements = store.profile.measurements.count
        weight = store.profile.weight == nil ? 0 : 1
        fitReferences = store.profile.fitReferences.count
        savedProducts = store.savedProducts.count
        reminders = store.reminders.count
    }
}

/// Export review: what a versioned archive would include and exclude. Writes nothing.
struct SettingsExportReview: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    /// False when pushed inside another sheet (for example "Export first" in Delete My Data).
    var isSheetRoot = true

    var body: some View {
        let ui = app.settingsUI
        let counts = SettingsBackupCounts(store: app.store)
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                CollapsibleText(
                    "A backup is a snapshot of your closet that you save in Files. Here's what it would contain right now.",
                    summary: "A snapshot of your closet, saved in Files.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "backups",
                    isExpanded: ui.detailsBinding("exportIntro")
                )

                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader(
                        "Included",
                        subtitle: "IDs and links between items are kept",
                        info: "Stable IDs and links between items are kept.\n\nFormat: versioned archive v\(StoreSnapshot.currentSchema) with readable records and original photos, captured from one consistent snapshot."
                    )
                    let included = includedItems(counts)
                    SettingsCountGrid {
                        ForEach(included) { item in
                            SettingsCountTile(value: item.value, title: item.title, detail: nil, systemImage: item.systemImage)
                        }
                    }
                    DetailsDisclosure(
                        "What each count covers",
                        count: included.filter { $0.detail != nil }.count,
                        isExpanded: ui.detailsBinding("exportIncluded"),
                        identifier: "exportIncludedDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(included.filter { $0.detail != nil }) { item in
                                SettingsBullet("\(item.title): \(item.detail ?? "")", systemImage: item.systemImage)
                            }
                        }
                    }
                }

                DetailsDisclosure(
                    "Not included",
                    count: 4,
                    isExpanded: ui.detailsBinding("exportNotIncluded"),
                    identifier: "exportNotIncludedDetails"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        SettingsBullet("Sign-in tokens and service keys", systemImage: "key.slash", tint: Palette.secondaryText)
                        SettingsBullet("Items you permanently deleted", systemImage: "trash.slash", tint: Palette.secondaryText)
                        SettingsBullet("Caches and the search index (rebuilt after import)", systemImage: "arrow.triangle.2.circlepath", tint: Palette.secondaryText)
                        SettingsBullet("Styling access: it's restored from the App Store, never from a file", systemImage: "creditcard", tint: Palette.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                InlineBanner(style: .caution,
                             title: "Keep it somewhere private",
                             message: "A backup file isn't encrypted and contains personal information like your measurements, weight and photos. Delete My Data doesn't remove files you saved in Files.",
                             summary: "It isn't encrypted and holds personal information.",
                             isMessageExpanded: ui.detailsBinding("exportPrivate"))

                SimulationNotice(text: "No file is written in the prototype — a real export would save a versioned archive to Files.",
                                 summary: "No file is written.")

                Button {
                    ui.exportResultVisible = true
                    ui.lastExportSimulation = .now
                } label: {
                    Label("Simulate export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("simulateExportButton")

                if ui.exportResultVisible {
                    InlineBanner(style: .info,
                                 title: "Simulation finished. No file was written.",
                                 message: "A real export would now open Files so you can choose where to save it. Your closet is unchanged.")
                        .accessibilityIdentifier("exportSimulationResult")
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .themedScreenBackground()
        .navigationTitle("Export backup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheetRoot {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}

private struct SettingsExportItem: Identifiable {
    var value: String
    var title: String
    var detail: String?
    var systemImage: String
    var id: String { title }
}

private extension SettingsExportReview {
    /// The tiles show the number and its name; the longer note for each sits in the details row.
    func includedItems(_ counts: SettingsBackupCounts) -> [SettingsExportItem] {
        [
            SettingsExportItem(value: "\(counts.garments)", title: "Garments",
                               detail: "Including \(counts.trashed) in Trash and \(counts.noLongerOwned) no longer owned",
                               systemImage: "tshirt"),
            SettingsExportItem(value: "\(counts.photos)", title: "Original photos",
                               detail: "Demo items use illustrated stand-ins",
                               systemImage: "photo.on.rectangle"),
            SettingsExportItem(value: "\(counts.suitcases)", title: "Suitcases",
                               detail: "\(counts.memberships) garment links",
                               systemImage: "suitcase"),
            SettingsExportItem(value: "\(counts.savedLooks)", title: "Saved looks",
                               detail: "With layouts and revisions",
                               systemImage: "bookmark"),
            SettingsExportItem(value: "\(counts.previews)", title: "Retained previews",
                               detail: "Earlier and disliked ones too",
                               systemImage: "person.crop.rectangle"),
            SettingsExportItem(value: "\(counts.collections)", title: "Collections",
                               detail: nil,
                               systemImage: "folder"),
            SettingsExportItem(value: "\(counts.history)", title: "Styling history",
                               detail: "Structured looks, no raw requests",
                               systemImage: "clock.arrow.circlepath"),
            SettingsExportItem(value: "\(counts.measurements + counts.weight + counts.fitReferences)", title: "Profile facts",
                               detail: "\(counts.measurements) measurement\(counts.measurements == 1 ? "" : "s"), \(counts.weight == 1 ? "your weight" : "no weight"), \(counts.fitReferences) fit references, preferences and your starting view",
                               systemImage: "ruler"),
            SettingsExportItem(value: "\(counts.savedProducts + counts.reminders)", title: "Shopping notes",
                               detail: "\(counts.savedProducts) saved products, \(counts.reminders) reminders",
                               systemImage: "bag"),
        ]
    }
}

// MARK: - Import review

enum SettingsImportMode: String, CaseIterable, Identifiable {
    case merge, replace
    var id: String { rawValue }

    var title: String {
        switch self {
        case .merge: "Merge"
        case .replace: "Replace"
        }
    }

    var explanation: String {
        switch self {
        case .merge: "Adds what's new. Items already here (same ID) are matched, not duplicated, and any differences are listed for you to review."
        case .replace: "Replaces your current closet with the backup. A recovery export of what you have now is made first, and nothing changes unless the whole import succeeds."
        }
    }
}

/// Fictional sample archives the prototype offers instead of the Files picker.
enum SettingsSampleArchive: String, CaseIterable, Identifiable {
    case valid, damaged
    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .valid: "Valid sample"
        case .damaged: "Damaged sample"
        }
    }

    var fileName: String {
        switch self {
        case .valid: "PetiteStyle-Backup-2026-09-12.petitestyle"
        case .damaged: "PetiteStyle-Backup-2026-08-30.petitestyle"
        }
    }

    var createdLabel: String {
        switch self {
        case .valid: "Saved September 12, 2026 from an iPhone (fictional)"
        case .damaged: "Saved August 30, 2026 from an iPad (fictional)"
        }
    }

    var isValid: Bool { self == .valid }

    /// (passed, text) validation lines.
    var checks: [(passed: Bool, text: String)] {
        switch self {
        case .valid:
            [(true, "Format v\(StoreSnapshot.currentSchema) is supported"),
             (true, "All 38 records read correctly"),
             (true, "Every saved look's pieces are in the archive"),
             (true, "Suitcase links point to garments in the archive"),
             (true, "No photos to check (illustrated demo items)")]
        case .damaged:
            [(true, "Format v\(StoreSnapshot.currentSchema) is supported"),
             (false, "2 saved looks point to garments missing from the archive"),
             (false, "1 photo failed its integrity check")]
        }
    }
}

/// Import review: preview, validation and an explained Merge / Replace choice.
/// Never changes the closet.
struct SettingsImportReview: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var ui = app.settingsUI
        let archive = ui.importArchive
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader("1. Choose a backup", subtitle: "Two fictional samples",
                                  info: "In the app this opens Files. The prototype offers two fictional sample archives.")
                    Picker("Sample archive", selection: $ui.importArchive) {
                        ForEach(SettingsSampleArchive.allCases) { sample in
                            Text(sample.pickerTitle).tag(sample)
                        }
                    }
                    .settingsSegmentedUnlessLarge(dynamicTypeSize.isAccessibilitySize)
                    .accessibilityIdentifier("importSamplePicker")
                    .onChange(of: ui.importArchive) { _, _ in ui.importSimulated = false }
                }

                VStack(alignment: .leading, spacing: Spacing.s) {
                    SectionHeader("2. Preview", subtitle: archive.createdLabel)
                    Label(archive.fileName, systemImage: "doc.zipper")
                        .font(.footnote.monospaced())
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    SettingsCountGrid {
                        SettingsCountTile(value: "19", title: "Garments", detail: nil, systemImage: "tshirt")
                        SettingsCountTile(value: "0", title: "Photos", detail: "Illustrated demo items", systemImage: "photo.on.rectangle")
                        SettingsCountTile(value: "2", title: "Suitcases", detail: "9 garment links", systemImage: "suitcase")
                        SettingsCountTile(value: "3", title: "Saved looks", detail: nil, systemImage: "bookmark")
                        SettingsCountTile(value: "3", title: "Retained previews", detail: nil, systemImage: "person.crop.rectangle")
                        SettingsCountTile(value: "2", title: "Collections", detail: nil, systemImage: "folder")
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SectionHeader("3. Checks")
                    let failed = archive.checks.filter { !$0.passed }.count
                    if archive.isValid {
                        SettingsBullet("All \(archive.checks.count) checks passed", systemImage: "checkmark.circle.fill", tint: Palette.success)
                    } else {
                        InlineBanner(style: .error,
                                     title: "This backup can't be imported",
                                     message: "It was rejected before anything was changed. Your closet is exactly as it was.",
                                     summary: "Your closet is exactly as it was.")
                            .accessibilityIdentifier("importRejected")
                    }
                    DetailsDisclosure(
                        "What was checked",
                        summary: failed == 0 ? nil : "\(failed) failed",
                        count: archive.checks.count,
                        isExpanded: ui.detailsBinding("importChecks"),
                        identifier: "importChecksDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(Array(archive.checks.enumerated()), id: \.offset) { _, check in
                                SettingsBullet(check.text,
                                               systemImage: check.passed ? "checkmark.circle.fill" : "xmark.octagon.fill",
                                               tint: check.passed ? Palette.success : Palette.error)
                                    .accessibilityLabel("\(check.passed ? "Passed" : "Failed"): \(check.text)")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                if archive.isValid {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        SectionHeader("4. How to bring it in")
                        Picker("Import mode", selection: $ui.importMode) {
                            ForEach(SettingsImportMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .settingsSegmentedUnlessLarge(dynamicTypeSize.isAccessibilitySize)
                        .accessibilityIdentifier("importModePicker")
                        .onChange(of: ui.importMode) { _, _ in ui.importSimulated = false }
                        // Only the chosen mode is explained; the other one shows when she picks it above.
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ui.importMode.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                            Text(ui.importMode.explanation)
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .fill(Palette.accentSurface))
                        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                            .strokeBorder(Palette.primaryAction, lineWidth: 1))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("importModeExplanation")
                    }
                }

                SimulationNotice(text: "Simulation — your closet is unchanged. Nothing is read from Files and nothing is merged or replaced.",
                                 summary: "Your closet is unchanged.")

                Button {
                    ui.importSimulated = true
                } label: {
                    Label("Simulate \(ui.importMode.title.lowercased())", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!archive.isValid)
                .accessibilityIdentifier("simulateImportButton")

                if ui.importSimulated, archive.isValid {
                    InlineBanner(style: .info,
                                 title: "Simulation — your closet is unchanged",
                                 message: ui.importMode == .merge
                                    ? "A real merge would check everything again, match items by ID, list any differences for review, then commit all at once or not at all."
                                    : "A real replace would first save a recovery export of your current closet, check everything again, then commit all at once or not at all.")
                        .accessibilityIdentifier("importSimulationResult")
                }
            }
            .padding(Spacing.m)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .themedScreenBackground()
        .navigationTitle("Import backup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
    }
}

private extension View {
    /// Segmented pickers truncate at accessibility text sizes; use a menu there instead.
    @ViewBuilder
    func settingsSegmentedUnlessLarge(_ large: Bool) -> some View {
        if large {
            pickerStyle(.menu)
        } else {
            pickerStyle(.segmented)
        }
    }
}

// MARK: - Legal placeholders

enum SettingsLegalDocument {
    case terms, privacy

    var title: String {
        switch self {
        case .terms: "Terms of Use"
        case .privacy: "Privacy Policy"
        }
    }

    var outline: [(heading: String, summary: String)] {
        switch self {
        case .terms:
            [("Who provides the app", "The developer's name and how to reach them."),
             ("Free features and styling access", "What's always free and what styling access includes."),
             ("Subscriptions, trials and codes", "How Apple handles purchases, renewals, cancellations and offer codes."),
             ("Fit guidance", "Suggestions are guidance based on what you've confirmed. They can't guarantee fit."),
             ("Feedback board", "Expected conduct for public ideas and votes."),
             ("Changes", "How you'll hear about changes to these terms.")]
        case .privacy:
            [("What stays on your device", "Your closet, photos, looks, profile and history, and where copies are kept."),
             ("Optional permissions", "Each recipient, its purpose, what it receives, and how to withdraw."),
             ("Private iCloud sync", "How sync works through your own iCloud account."),
             ("Analytics", "Off unless you turn it on, with the exact allowlist of events."),
             ("Keeping and deleting data", "How long each kind of data is kept and what Delete My Data covers."),
             ("Your rights and contact", "How to ask a question or make a privacy request.")]
        }
    }
}

/// Clearly labelled placeholder for a legal document. Contains no legal text.
struct SettingsLegalPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    var document: SettingsLegalDocument

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack(spacing: Spacing.xxs) {
                        SettingsBadge(text: "Draft placeholder — not legal text", systemImage: "doc.badge.ellipsis", tone: .caution)
                            .accessibilityIdentifier("legalPlaceholderBadge")
                        InfoButton("this draft", title: "Draft placeholder",
                                   text: "Draft placeholder — not legal text. The real \(document.title) will be written and reviewed before launch and will describe what the shipped app actually does.")
                    }
                    Text(document.title)
                        .font(.editorial(.largeTitle))
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        SectionHeader("What it will cover")
                        ForEach(Array(document.outline.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                                Text("\(index + 1).")
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(Palette.primaryAction)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.heading)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Palette.primaryText)
                                    Text(item.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(Palette.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
                .padding(Spacing.m)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .themedScreenBackground()
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Export review") {
    NavigationStack { SettingsExportReview() }
        .previewEnvironment()
}

#Preview("Import review") {
    NavigationStack { SettingsImportReview() }
        .previewEnvironment()
}

#Preview("Privacy placeholder") {
    SettingsLegalPlaceholder(document: .privacy)
        .previewEnvironment()
}
