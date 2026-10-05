import SwiftUI

// MARK: - Review and confirm

/// Review for a selected load or a scoped Mark all. Shows the captured scope,
/// count and items; confirming commits exactly the reviewed targets and reports
/// cleaned and skipped counts honestly. Cancel makes no changes.
struct LaundryReviewSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var draft: LaundryReviewDraft
    @State private var showsList = false
    /// Guards against a second tap re-committing the same reviewed targets
    /// (which would replace an honest result with "nothing was cleaned").
    @State private var didCommit = false

    private var garments: [Garment] { draft.targets.compactMap { app.store.garment($0.garmentID) } }
    private var count: Int { draft.targets.count }
    private var notCleanable: Int { max(0, draft.requestedIDs.count - count) }

    private var confirmTitle: String {
        switch draft.kind {
        case .selectedLoad:
            return count == 1 ? "Confirm: Mark this item clean" : "Confirm: Mark these \(count) items clean"
        case .sweep:
            return count == 1 ? "Confirm: Mark 1 dirty item clean" : "Confirm: Mark all \(count) dirty items clean"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    summaryCard

                    if draft.kind == .selectedLoad, notCleanable > 0 {
                        InlineBanner(style: .caution,
                                     title: "\(count) of \(draft.requestedIDs.count) selected can be marked clean",
                                     message: "\(LaundryText.items(notCleanable)) \(notCleanable == 1 ? "isn't" : "aren't") Dirty or owned anymore and will be left as \(notCleanable == 1 ? "it is" : "they are").")
                    }

                    if count == 0 {
                        EmptyStateView(title: "Nothing to mark clean",
                                       message: "None of these are owned, arrived Dirty items right now, so nothing would change.",
                                       systemImage: "checkmark.seal")
                            .cardStyle()
                    } else if draft.kind == .selectedLoad {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            SectionHeader("In this load", subtitle: LaundryText.items(count))
                            thumbnailGrid
                        }
                    } else {
                        DisclosureGroup(isExpanded: $showsList) {
                            thumbnailGrid
                                .padding(.top, Spacing.s)
                        } label: {
                            Text("Review the \(LaundryText.items(count))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.primaryText)
                        }
                        .tint(Palette.primaryAction)
                        .cardStyle()
                        .accessibilityIdentifier("laundryReviewList")
                    }

                    LaundryRulesNote()
                }
                .padding(Spacing.m)
                .readableWidth(680)
            }
            .themedScreenBackground()
            .navigationTitle(draft.kind == .selectedLoad ? "Review this load" : "Mark all clean")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                        .accessibilityHint("Closes without changing anything")
                }
            }
            .safeAreaInset(edge: .bottom) {
                confirmBar
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(draft.kind == .selectedLoad ? "Mark these items clean?" : "Mark all dirty items clean?")
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            InfoRow(title: "Scope", value: draft.scopeLabel)
            InfoRow(title: "Affected", value: LaundryText.items(count))
            InfoRow(title: "Reviewed", value: draft.capturedAt.formatted(date: .omitted, time: .shortened))
            CollapsibleText("Each becomes Available. Anything marked Dirty after this review isn't included, and anything that changes before you confirm is skipped.",
                            summary: "Each becomes Available.", threshold: 1, topic: "this review")
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("laundryReviewSummary")
    }

    private var thumbnailGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 220 : 96), spacing: Spacing.s, alignment: .top)], alignment: .leading, spacing: Spacing.s) {
            ForEach(garments) { garment in
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    GarmentThumbnail(garment: garment, showsStatus: false)
                    Text(garment.displayName)
                        .font(.caption)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(garment.accessibilityDescription)
            }
        }
    }

    private var confirmBar: some View {
        VStack(spacing: Spacing.xs) {
            Button(confirmTitle) { confirm() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(count == 0 || didCommit)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier(draft.kind == .selectedLoad ? "laundryReviewConfirm" : "laundryMarkAllConfirm")
            Button("Cancel, make no changes") { cancel() }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityIdentifier("laundryReviewCancel")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    private func cancel() {
        app.laundryUI.pendingReview = nil
        dismiss()
    }

    private func confirm() {
        guard !didCommit else { return }
        didCommit = true
        let names = Dictionary(
            draft.targets.compactMap { target in app.store.garment(target.garmentID).map { (target.garmentID, $0.displayName) } },
            uniquingKeysWith: { first, _ in first }
        )
        let result = app.store.commitLaundry(draft.targets, scope: draft.scope)
        let outcome = LaundryOutcome(
            kind: draft.kind,
            scopeLabel: draft.scopeLabel,
            cleanedNames: result.cleanedIDs.map { names[$0] ?? "Item" },
            skipped: result.skipped.map { LaundryOutcome.Skip(name: names[$0.id] ?? "A deleted item", reason: $0.reason) },
            saveError: result.cleanedIDs.isEmpty ? nil : app.store.lastSaveError
        )
        app.laundryUI.lastOutcome = outcome
        if draft.kind == .selectedLoad { app.laundryUI.endSelection() }
        app.laundryUI.pendingReview = nil
        dismiss()
        // Undo only when this commit pushed an undo entry (something was cleaned).
        if result.cleanedIDs.isEmpty {
            app.showToast(outcome.toastText, style: .info)
        } else {
            app.showUndoToast(outcome.toastText)
        }
    }
}

// MARK: - Demo: mark items dirty

/// Demo convenience for trying laundry: pick available owned items to mark Dirty.
struct LaundryMarkDirtySheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    var scope: WardrobeScope
    var scopeName: String
    @State private var selection: Set<String> = []

    private var candidates: [Garment] {
        app.store.garments
            .filter { app.store.isInScope($0, scope) && $0.isCurrentlyOwned && $0.availability == .available }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SimulationNotice(text: "A demo shortcut for trying laundry. Pick items you've worn and want to wash. They'll show Dirty everywhere, including every suitcase they're in.",
                                     systemImage: "theatermasks", label: "Demo", summary: "Pick items to mark Dirty")
                }
                .listRowBackground(Palette.accentSurface.opacity(0.6))

                Section {
                    if candidates.isEmpty {
                        Text("Nothing available to mark dirty in \(scopeName).")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                    }
                    ForEach(candidates) { garment in
                        let isSelected = selection.contains(garment.id)
                        Button {
                            if isSelected { selection.remove(garment.id) } else { selection.insert(garment.id) }
                        } label: {
                            HStack(spacing: Spacing.s) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? Palette.primaryAction : Palette.controlBorder)
                                    .frame(minWidth: 28)
                                    .accessibilityHidden(true)
                                GarmentThumbnail(garment: garment, size: 44, showsStatus: false)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(garment.displayName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Palette.primaryText)
                                    Text("\(garment.colorLabel) · \(garment.kind.label)")
                                        .font(.caption)
                                        .foregroundStyle(Palette.secondaryText)
                                }
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(garment.accessibilityDescription)
                        .accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("laundryDirtyPick-\(garment.id)")
                    }
                } header: {
                    Text("Available in \(scopeName)")
                }
                .listRowBackground(Palette.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle("Mark items dirty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selection.isEmpty ? "Mark dirty" : "Mark \(selection.count) dirty") { confirm() }
                        .disabled(selection.isEmpty)
                        .accessibilityIdentifier("laundryMarkDirtyConfirm")
                }
            }
        }
    }

    private func confirm() {
        let ids = candidates.map(\.id).filter { selection.contains($0) }
        for id in ids { app.store.markDirty(id) }
        dismiss()
        app.showToast("Marked \(LaundryText.items(ids.count)) Dirty. \(ids.count == 1 ? "It shows" : "They show") as Dirty in Main Closet and every suitcase \(ids.count == 1 ? "it's" : "they're") in.")
    }
}

#Preview("Review · selected load") {
    let model = AppModel.preview
    let ids = ["g-lace-top", "g-black-tee"]
    let draft = LaundryReviewDraft(kind: .selectedLoad, scope: .selected(ids), scopeLabel: "Selected items · Entire closet",
                                   targets: model.store.laundryTargets(for: .selected(ids)), requestedIDs: ids)
    return LaundryReviewSheet(draft: draft)
        .previewEnvironment(model)
}
