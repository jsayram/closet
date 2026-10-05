import SwiftUI

/// "Add from Main Closet": a reviewed, multi-select picker that links existing
/// canonical garments to one suitcase. It never changes the styling source,
/// ownership or laundry state, and it makes no AI call.
struct SuitcasesMembershipPicker: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var suitcaseID: String
    /// Prevents a second tap from adding again and replacing the honest result.
    @State private var didConfirm = false

    private var suitcase: Suitcase? { app.store.suitcase(suitcaseID) }
    private var name: String { suitcase?.name ?? "this suitcase" }

    var body: some View {
        @Bindable var ui = app.suitcasesUI
        NavigationStack {
            List {
                Section {
                    notice
                }
                .listRowBackground(Palette.accentSurface.opacity(0.6))

                Section {
                    categoryChips
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
                    Toggle(isOn: $ui.pickerIncludesNotCurrent) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Include wishlist & not arrived")
                                .foregroundStyle(Palette.primaryText)
                            // Reports what the list is showing right now, so it stays on screen.
                            Text(ui.pickerIncludesNotCurrent ? "Also showing wishlist, inspiration, not-arrived and no-longer-owned items. Trash is never shown." : "Showing only clothes you currently own. Trash is never shown.")
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Palette.primaryAction)
                    .accessibilityIdentifier("membershipPickerIncludeToggle")
                }
                .listRowBackground(Palette.surface)

                Section {
                    let list = candidates
                    if list.isEmpty {
                        Text(emptyMessage)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, Spacing.xs)
                    }
                    ForEach(list) { garment in
                        SuitcasesPickerRow(
                            garment: garment,
                            suitcaseName: name,
                            isAlreadyLinked: app.store.membership(garmentID: garment.id, suitcaseID: suitcaseID) != nil,
                            isSelected: ui.pickerSelection.contains(garment.id),
                            otherSuitcases: app.store.suitcasesOtherActive(containing: garment.id, excluding: suitcaseID)
                        ) {
                            toggle(garment.id)
                        }
                    }
                } header: {
                    Text(listHeader)
                } footer: {
                    if let hiddenNote {
                        Text(hiddenNote)
                    }
                }
                .listRowBackground(Palette.surface)
            }
            .accessibilityIdentifier("membershipPicker")
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .searchable(text: $ui.pickerQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search names, colors, brands")
            .navigationTitle("Add from Main Closet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                        .accessibilityHint("Closes without adding anything")
                        .accessibilityIdentifier("membershipPickerCancel")
                }
            }
            .safeAreaInset(edge: .bottom) {
                reviewBar
            }
        }
    }

    // MARK: Sections

    private var notice: some View {
        HStack(spacing: Spacing.xs) {
            Label {
                Text("This doesn't change your styling source")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
            } icon: {
                Image(systemName: "link")
                    .foregroundStyle(Palette.primaryAction)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 0)
            InfoButton("linking garments", title: "This doesn't change your styling source",
                       text: "You're linking garments from Main Closet to \(name). Nothing is copied, and ownership, laundry status and your current source (\(app.workingScopeName)) stay the same.")
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var categoryChips: some View {
        let ui = app.suitcasesUI
        let pool = app.store.garments.filter { !$0.isTrashed && (ui.pickerIncludesNotCurrent || $0.isCurrentlyOwned) }
        let categories = GarmentCategory.allCases.filter { category in pool.contains { $0.category == category } }
        return ChipCarousel(itemsLabel: "categories") {
            CapsuleChip(title: "All", isSelected: ui.pickerCategory == nil) {
                ui.pickerCategory = nil
            }
            ForEach(categories) { category in
                CapsuleChip(title: category.pluralLabel, systemImage: category.systemImage, isSelected: ui.pickerCategory == category) {
                    ui.pickerCategory = ui.pickerCategory == category ? nil : category
                }
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category")
    }

    private var reviewBar: some View {
        let ui = app.suitcasesUI
        let selected = selectedGarments
        let visibleIDs = Set(candidates.map(\.id))
        let hiddenSelected = selected.filter { !visibleIDs.contains($0.id) }.count
        let count = ui.pickerSelection.count
        let archived = suitcase?.isArchived ?? true

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            if !selected.isEmpty, !dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(selected) { garment in
                            GarmentThumbnail(garment: garment, size: 40, showsStatus: false)
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(count == 0 ? "Nothing selected yet" : "Review: \(count) selected")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Text(hiddenSelected > 0
                         ? "\(SuitcasesText.count(hiddenSelected, "selected item")) hidden by your filters \(hiddenSelected == 1 ? "is" : "are") still included."
                         : "Links only. Ownership, laundry and your source stay the same.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if count > 0 {
                    Button("Clear") { ui.pickerSelection = [] }
                        .font(.subheadline.weight(.semibold))
                        .minimumHitTarget()
                        .accessibilityLabel("Clear selection")
                }
            }
            .accessibilityElement(children: .contain)

            Button {
                confirm()
            } label: {
                Text(count == 0 ? "Add to \(name)" : "Add \(count) to \(name)")
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(count == 0 || archived || didConfirm)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint("Links the selected garments. Nothing is copied.")
            .accessibilityIdentifier("membershipPickerConfirm")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(Palette.surface.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Palette.divider).frame(height: 1)
        }
    }

    // MARK: Data

    private var candidates: [Garment] {
        let ui = app.suitcasesUI
        let query = ui.pickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return app.store.garments.filter { garment in
            guard !garment.isTrashed else { return false }
            guard ui.pickerIncludesNotCurrent || garment.isCurrentlyOwned else { return false }
            if let category = ui.pickerCategory, garment.category != category { return false }
            return SuitcasesSearch.matches(garment, query: query)
        }
        .sorted(by: SuitcasesSort.byCategoryThenName)
    }

    private var selectedGarments: [Garment] {
        let ids = app.suitcasesUI.pickerSelection
        return app.store.garments.filter { ids.contains($0.id) }.sorted(by: SuitcasesSort.byCategoryThenName)
    }

    private var listHeader: String {
        let list = candidates
        let linked = list.filter { app.store.membership(garmentID: $0.id, suitcaseID: suitcaseID) != nil }.count
        var text = "Main Closet · \(SuitcasesText.count(list.count, "item")) shown"
        if linked > 0 { text += " · \(linked) already in \(name)" }
        return text
    }

    private var hiddenNote: String? {
        guard !app.suitcasesUI.pickerIncludesNotCurrent else { return nil }
        let hidden = app.store.garments.filter { !$0.isTrashed && !$0.isCurrentlyOwned }.count
        guard hidden > 0 else { return nil }
        return "\(SuitcasesText.count(hidden, "item")) not shown: wishlist, inspiration, not arrived or no longer owned. Turn on the switch above to see them."
    }

    private var emptyMessage: String {
        let ui = app.suitcasesUI
        if !ui.pickerQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No matches for “\(ui.pickerQuery)” in Main Closet. Try another word or category."
        }
        return "Nothing in this category right now."
    }

    // MARK: Actions

    private func toggle(_ id: String) {
        let ui = app.suitcasesUI
        if ui.pickerSelection.contains(id) {
            ui.pickerSelection.remove(id)
        } else {
            ui.pickerSelection.insert(id)
        }
    }

    private func cancel() {
        app.suitcasesUI.resetPickerDraft()
        dismiss()
    }

    private func confirm() {
        guard !didConfirm, let suitcase else { return }
        didConfirm = true
        let ui = app.suitcasesUI
        let existing = selectedGarments.map(\.id)
        let missing = ui.pickerSelection.subtracting(existing).sorted()
        let result = app.store.addMembers(existing + missing, to: suitcase.id)
        let outcome = SuitcasesAddOutcome(
            suitcaseID: suitcase.id,
            suitcaseName: suitcase.name,
            addedCount: result.added.count,
            alreadyPresentCount: result.alreadyPresent.count,
            skippedCount: result.skipped.count,
            containerArchived: suitcase.isArchived
        )
        ui.lastAddOutcome = outcome
        ui.resetPickerDraft()
        dismiss()
        app.showToast(outcome.toastText, style: result.added.isEmpty ? .info : .success)
    }
}

/// One Main Closet garment in the picker. Already-linked garments are shown but not selectable.
struct SuitcasesPickerRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var garment: Garment
    var suitcaseName: String
    var isAlreadyLinked: Bool
    var isSelected: Bool
    var otherSuitcases: [Suitcase]
    var onToggle: () -> Void

    var body: some View {
        if isAlreadyLinked {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(garment.accessibilityDescription)
                .accessibilityValue("Already in \(suitcaseName)")
                .accessibilityIdentifier("membershipPickerRow-\(garment.id)")
        } else {
            Button(action: onToggle) {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel(garment.accessibilityDescription)
            .accessibilityValue(([isSelected ? "Selected" : "Not selected"] + badges.map(\.text)).joined(separator: ", "))
            .accessibilityHint(isSelected ? "Removes it from this review" : "Adds it to this review")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("membershipPickerRow-\(garment.id)")
        }
    }

    private var content: some View {
        // At accessibility sizes the text moves under the checkmark and photo so names don't squeeze.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
        return layout {
            HStack(spacing: Spacing.s) {
                Image(systemName: isAlreadyLinked ? "checkmark.circle" : (isSelected ? "checkmark.circle.fill" : "circle"))
                    .font(.title2)
                    .foregroundStyle(isAlreadyLinked ? Palette.secondaryText : (isSelected ? Palette.primaryAction : Palette.controlBorder))
                    .frame(minWidth: 28)
                    .accessibilityHidden(true)
                GarmentThumbnail(garment: garment, size: 56, showsStatus: false)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(garment.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isAlreadyLinked ? Palette.secondaryText : Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(garment.colorLabel) · \(garment.kind.label)")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                BadgeRow(badges: badges)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var badges: [BadgeKind] {
        var list: [BadgeKind] = []
        if isAlreadyLinked { list.append(.custom("Already in \(suitcaseName)", "checkmark.circle")) }
        let status = BadgeKind.status(for: garment)
        if status.isEmpty, garment.isCurrentlyOwned {
            list.append(.custom("Owned · Available", "checkmark.circle"))
        } else {
            list += status
        }
        list += otherSuitcases.map { .custom("In \($0.name)", "suitcase") }
        return list
    }
}

#Preview("Add from Main Closet") {
    SuitcasesMembershipPicker(suitcaseID: DemoFixtures.weekend)
        .previewEnvironment()
}
