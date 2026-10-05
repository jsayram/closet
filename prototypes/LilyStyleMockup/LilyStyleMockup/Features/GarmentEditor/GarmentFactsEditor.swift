import SwiftUI

/// Sheet form for a garment's confirmed facts (category, kind, color, brand,
/// size, fabric, notes, formality, seasons). Correcting a fact replaces it — no
/// contradictory duplicate is kept. Color/kind changes count as appearance
/// changes; earlier previews keep their captured version.
///
/// Presenters show it in a sheet. It brings its own NavigationStack unless
/// `embedsNavigationStack` is false.
struct GarmentFactsEditor: View {
    var garmentID: String
    var embedsNavigationStack: Bool

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardDialog = false

    init(garmentID: String, embedsNavigationStack: Bool = true) {
        self.garmentID = garmentID
        self.embedsNavigationStack = embedsNavigationStack
    }

    private var ui: GarmentEditorUIState { app.garmentEditorUI }

    var body: some View {
        if embedsNavigationStack {
            NavigationStack { content }
        } else {
            content
        }
    }

    @ViewBuilder private var content: some View {
        if let garment = app.store.garment(garmentID) {
            editor(garment)
                .onAppear { prepare(garment) }
        } else {
            EmptyStateView(title: "Item not found", message: "That item no longer exists, so there's nothing to edit.",
                           systemImage: "questionmark.square.dashed", actionTitle: "Close") { dismiss() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .themedScreenBackground()
                .navigationTitle("Edit details")
        }
    }

    private func draftBinding(_ g: Garment) -> Binding<GarmentEditorFactsDraft> {
        let state = app.garmentEditorUI
        let id = garmentID
        return Binding(
            get: { state.factsDrafts[id] ?? GarmentEditorFactsDraft(g) },
            set: { state.factsDrafts[id] = $0 }
        )
    }

    private func prepare(_ g: Garment) {
        if let existing = ui.factsDrafts[garmentID], existing.baseRevision == g.revision { return }
        ui.factsDrafts[garmentID] = GarmentEditorFactsDraft(g)
    }

    // MARK: Form

    private func editor(_ g: Garment) -> some View {
        let draft = draftBinding(g)
        let d = draft.wrappedValue
        let hasChanges = d.differs(from: g)
        let kindOptions = d.category == .unknown
            ? GarmentKind.allCases.filter { $0 != .unknown }
            : GarmentKind.kinds(for: d.category).filter { $0 != .unknown }

        return Form {
            Section {
                HStack(spacing: Spacing.s) {
                    GarmentThumbnail(garment: g, size: 56, showsStatus: false)
                    Text(g.displayName)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Spacer(minLength: Spacing.xs)
                    InfoButton("editing details", title: "Edit details",
                               text: "Correcting a fact replaces the old value. Names and details are edited separately.")
                }
            }
            .listRowBackground(Palette.surface)

            Section {
                Picker("Category", selection: Binding(
                    get: { draft.wrappedValue.category },
                    set: { newValue in
                        draft.wrappedValue.category = newValue
                        if draft.wrappedValue.kind.defaultCategory != newValue { draft.wrappedValue.kind = .unknown }
                    }
                )) {
                    ForEach([GarmentCategory.unknown] + GarmentCategory.allCases.filter { $0 != .unknown }) { category in
                        Label(category == .unknown ? "Unknown" : category.label, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
                .accessibilityIdentifier("categoryPicker")

                Picker("Kind", selection: Binding(
                    get: { draft.wrappedValue.kind },
                    set: { newValue in
                        draft.wrappedValue.kind = newValue
                        if newValue != .unknown { draft.wrappedValue.category = newValue.defaultCategory }
                    }
                )) {
                    Text("Not sure").tag(GarmentKind.unknown)
                    ForEach(kindOptions) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                .accessibilityIdentifier("kindPicker")
            } header: {
                header("What it is", info: "Unknown is fine — fill it in whenever you like.")
            }
            .listRowBackground(Palette.surface)

            Section {
                GarmentEditorColorPicker(family: draft.colorFamily)
                    .padding(.vertical, Spacing.xs)
                if d.colorFamily != nil {
                    TextField("Shade name", text: draft.shadeName, prompt: Text("Shade name (optional), e.g. Dusty rose"))
                        .textInputAutocapitalization(.sentences)
                        .accessibilityLabel("Shade name, optional")
                        .accessibilityIdentifier("shadeNameField")
                }
            } header: {
                header("Color", info: "Changing the color or kind updates future looks. Earlier previews keep their captured version.")
            }
            .listRowBackground(Palette.surface)

            Section {
                factField("Brand", text: draft.brand, identifier: "factsBrandField")
                factField("Size", text: draft.size, identifier: "factsSizeField")
                factField("Fabric", text: draft.fabric, identifier: "factsFabricField")
            } header: {
                header("Label details", info: "Only what you know. Nothing here is guessed from photos.")
            }
            .listRowBackground(Palette.surface)

            Section {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("How dressy")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    // Wrapping chips instead of a segmented control so labels never truncate at AX sizes.
                    GarmentEditorChoiceChips(
                        items: Formality.allCases,
                        selection: d.formality,
                        title: { $0.label },
                        systemImage: { _ in nil },
                        identifier: { "formality-\($0.rawValue)" },
                        onSelect: { draft.wrappedValue.formality = $0 },
                        itemsLabel: "dressiness choices"
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("How dressy")
                    .accessibilityIdentifier("formalityPicker")
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Seasons")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    ChipCarousel(itemsLabel: "seasons") {
                        ForEach(Season.allCases) { season in
                            let selected = d.seasons.contains(season)
                            CapsuleChip(title: season.label, isSelected: selected) {
                                if selected {
                                    guard draft.wrappedValue.seasons.count > 1 else { return }
                                    draft.wrappedValue.seasons.remove(season)
                                } else {
                                    draft.wrappedValue.seasons.insert(season)
                                }
                            }
                            .accessibilityIdentifier("season-\(season.rawValue)")
                        }
                    }
                    if d.seasons.count == 1 {
                        Text("At least one season stays selected.")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
                Picker("Warmth", selection: draft.warmth) {
                    Text("Light").tag(0)
                    Text("Medium").tag(1)
                    Text("Warm").tag(2)
                    Text("Very warm").tag(3)
                }
                .accessibilityIdentifier("warmthPicker")
            } header: {
                FormSectionHeader("When you wear it")
            }
            .listRowBackground(Palette.surface)

            Section {
                TextField("Notes", text: draft.notes, prompt: Text("Unknown — add later"), axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityIdentifier("factsNotesField")
            } header: {
                FormSectionHeader("Notes")
            }
            .listRowBackground(Palette.surface)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .themedScreenBackground()
        .navigationTitle("Edit details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if hasChanges { showDiscardDialog = true } else { close() }
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("factsEditorCancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save(g) }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!hasChanges)
                    .accessibilityIdentifier("factsEditorSave")
            }
        }
        .confirmationDialog("Discard your changes?", isPresented: $showDiscardDialog, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive, action: close)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The saved details stay as they were.")
        }
        .interactiveDismissDisabled(hasChanges)
    }

    /// Section header with the helper text that used to sit in the footer behind an info button.
    private func header(_ title: String, info: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            FormSectionHeader(title)
            InfoButton(title, text: info)
                .textCase(nil)
        }
    }

    private func factField(_ title: String, text: Binding<String>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
            TextField(title, text: text, prompt: Text("Unknown — add later"))
                .textInputAutocapitalization(.words)
                .accessibilityLabel(title)
                .accessibilityValue(text.wrappedValue.isEmpty ? "Unknown" : text.wrappedValue)
                .accessibilityIdentifier(identifier)
        }
    }

    // MARK: Actions

    private func close() {
        ui.factsDrafts[garmentID] = nil
        dismiss()
    }

    private func save(_ g: Garment) {
        let d = ui.factsDrafts[garmentID] ?? GarmentEditorFactsDraft(g)
        let newColor = d.color(original: g.color)
        let appearanceChanged = d.kind != g.kind || newColor != g.color
        let trimmed: (String) -> String? = {
            let t = $0.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        app.store.updateGarment(garmentID, appearanceChanged: appearanceChanged) { garment in
            garment.category = d.category == .unknown && d.kind != .unknown ? d.kind.defaultCategory : d.category
            garment.kind = d.kind
            garment.color = newColor
            garment.brand = trimmed(d.brand)
            garment.sizeLabel = trimmed(d.size)
            garment.fabric = trimmed(d.fabric)
            garment.notes = d.notes.trimmingCharacters(in: .whitespacesAndNewlines)
            garment.formality = d.formality
            garment.seasons = d.seasons
            garment.warmth = d.warmth
        }
        ui.factsDrafts[garmentID] = nil
        app.showToast(appearanceChanged ? "Updated on this device. Earlier previews keep their captured version." : "Updated on this device")
        dismiss()
    }
}

// MARK: - Previews

#Preview("Edit details") {
    GarmentFactsEditor(garmentID: "g-navy-trousers")
        .previewEnvironment()
}

#Preview("Edit details · text-only loafers") {
    GarmentFactsEditor(garmentID: "g-tan-loafers")
        .previewEnvironment()
}
