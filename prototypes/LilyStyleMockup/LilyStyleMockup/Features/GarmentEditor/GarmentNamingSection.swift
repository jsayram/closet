import SwiftUI

/// Inline "Names & details" card for garment detail screens (PRD 7.6, FR-60/62).
/// Name + Rename, Other names with provenance and undoable removal, additive
/// details, and a local suggested name. Naming edits never change earlier
/// pictures or start any AI.
struct GarmentNamingSection: View {
    var garmentID: String

    @Environment(AppModel.self) private var app
    @State private var showSuggestion = false
    @State private var aliasMessage: String?
    @State private var detailMessage: String?

    init(garmentID: String) {
        self.garmentID = garmentID
    }

    private var ui: GarmentEditorUIState { app.garmentEditorUI }

    var body: some View {
        if let garment = app.store.garment(garmentID) {
            card(garment)
                .sheet(isPresented: renamePresented) {
                    GarmentEditorRenameSheet(garmentID: garmentID)
                        .environment(app)
                        .tint(Palette.primaryAction)
                }
        } else {
            CardSection("Names & details", systemImage: "character.cursor.ibeam") {
                Text("That item no longer exists.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    private var renamePresented: Binding<Bool> {
        let state = app.garmentEditorUI
        let id = garmentID
        return Binding(
            get: { state.renameTarget == id },
            set: { presented in
                if !presented, state.renameTarget == id { state.renameTarget = nil }
            }
        )
    }

    // MARK: Card

    private func card(_ g: Garment) -> some View {
        CardSection("Names & details",
                    info: "In your own words. Search finds the item by any of these. Names don't change earlier pictures or start any AI.",
                    systemImage: "character.cursor.ibeam") {
            nameRow(g)
            suggestion(g)

            Divider().overlay(Palette.divider)
            otherNames(g)

            Divider().overlay(Palette.divider)
            details(g)
        }
        .accessibilityIdentifier("garmentNamingSection")
    }

    private func nameRow(_ g: Garment) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Spacing.s) {
                nameText(g)
                Spacer(minLength: Spacing.xs)
                renameButton(g)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                nameText(g)
                renameButton(g)
            }
        }
    }

    private func nameText(_ g: Garment) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Name")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(g.displayName)
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func renameButton(_ g: Garment) -> some View {
        Button {
            startRename(g, prefill: nil)
        } label: {
            Label("Rename", systemImage: "pencil")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("renameButton")
        .accessibilityHint("Choose a new name. You can keep the old one as another name.")
    }

    @ViewBuilder
    private func suggestion(_ g: Garment) -> some View {
        if !showSuggestion {
            Button {
                showSuggestion = true
            } label: {
                Label("Suggest a name", systemImage: "lightbulb")
            }
            .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
            .accessibilityIdentifier("suggestNameButton")
            .accessibilityHint("Makes a simple name on this device from its kind and color. No AI.")
        } else if let suggested = GarmentEditorNaming.suggestedName(for: g) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("“\(suggested)”")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text("Made on this device from its kind and color — no AI.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                ActionGroup {
                    Button("Use as name") {
                        startRename(g, prefill: suggested)
                        showSuggestion = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Button("Not now") { showSuggestion = false }
                        .buttonStyle(SecondaryButtonStyle(tint: Palette.secondaryText))
                } more: {
                    Button("Add as another name", systemImage: "plus") {
                        addAnnotation(.alias, text: suggested, provenance: .acceptedSuggestion, garment: g)
                        showSuggestion = false
                    }
                }
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
            .accessibilityElement(children: .contain)
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(g.color == nil && g.kind == .unknown && g.category == .unknown
                     ? "Add its category or color in Details and a simple name can be suggested from those."
                     : "Its name already matches what's recorded — nothing new to suggest.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.xs)
                Button("OK") { showSuggestion = false }
                    .font(.footnote.weight(.semibold))
                    .minimumHitTarget()
            }
        }
    }

    private func otherNames(_ g: Garment) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GarmentEditorFieldLabel(title: "Other names",
                                    hint: g.aliases.isEmpty ? "None yet. Add anything else you'd call it, like “Date-night top”." : nil,
                                    isListHeading: true)
            ForEach(g.aliases) { alias in
                GarmentEditorNoteRow(text: alias.text, provenance: alias.provenance.label, kindLabel: "other name") {
                    remove(alias)
                }
            }
            GarmentEditorAddRow(placeholder: "Add another name", text: inputBinding(\.aliasInput),
                                fieldIdentifier: "otherNameField", accessibilityLabel: "Another name") {
                addAnnotation(.alias, text: ui.aliasInput[garmentID] ?? "", provenance: .userEntered, garment: g)
            }
            if let aliasMessage {
                Text(aliasMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    private func details(_ g: Garment) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            GarmentEditorFieldLabel(title: "Details",
                                    hint: g.details.isEmpty
                                        ? "Little things you notice, like “Bow at the neck”. New details are added — nothing is replaced."
                                        : "New details are added — nothing is replaced.",
                                    isListHeading: true)
            ForEach(g.details) { detail in
                GarmentEditorNoteRow(text: detail.text, provenance: detail.provenance.label, kindLabel: "detail") {
                    remove(detail)
                }
            }
            GarmentEditorAddRow(placeholder: "Add details", text: inputBinding(\.detailInput),
                                fieldIdentifier: "addDetailField", accessibilityLabel: "Detail") {
                addAnnotation(.detail, text: ui.detailInput[garmentID] ?? "", provenance: .userEntered, garment: g)
            }
            if let detailMessage {
                Text(detailMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
    }

    // MARK: Actions

    private func inputBinding(_ keyPath: ReferenceWritableKeyPath<GarmentEditorUIState, [String: String]>) -> Binding<String> {
        let state = app.garmentEditorUI
        let id = garmentID
        return Binding(
            get: { state[keyPath: keyPath][id] ?? "" },
            set: { state[keyPath: keyPath][id] = $0 }
        )
    }

    private func startRename(_ g: Garment, prefill: String?) {
        ui.renameText = prefill ?? g.displayName
        ui.renameKeepsOldName = true
        ui.renameTarget = g.id
    }

    private func addAnnotation(_ kind: AnnotationKind, text: String, provenance: AnnotationProvenance, garment g: Garment) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let lower = trimmed.lowercased()
        let existing = kind == .alias ? g.aliases : g.details
        let duplicate = existing.contains { $0.text.lowercased() == lower } || (kind == .alias && g.displayName.lowercased() == lower)
        if duplicate {
            let message = kind == .alias ? "“\(trimmed)” is already a name for this item." : "“\(trimmed)” is already one of its details."
            if kind == .alias { aliasMessage = message } else { detailMessage = message }
            UIAccessibility.post(notification: .announcement, argument: message)
            return
        }
        app.store.addAnnotation(garmentID, kind: kind, text: trimmed, provenance: provenance)
        if kind == .alias {
            ui.aliasInput[garmentID] = ""
            aliasMessage = nil
        } else {
            ui.detailInput[garmentID] = ""
            detailMessage = nil
        }
        UIAccessibility.post(notification: .announcement, argument: kind == .alias ? "Added \(trimmed) as another name" : "Added detail \(trimmed)")
    }

    private func remove(_ annotation: GarmentAnnotation) {
        app.store.removeAnnotation(garmentID, annotationID: annotation.id)
        app.showUndoToast("Removed “\(annotation.text)”")
    }
}

// MARK: - Rename sheet

struct GarmentEditorRenameSheet: View {
    var garmentID: String

    @Environment(AppModel.self) private var app
    @FocusState private var nameFocused: Bool

    var body: some View {
        @Bindable var ui = app.garmentEditorUI
        let oldName = app.store.garment(garmentID)?.displayName ?? ""
        let newName = ui.renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let unchanged = newName.lowercased() == oldName.lowercased()
        NavigationStack {
            Form {
                Section {
                    TextField("New name", text: $ui.renameText, prompt: Text("e.g. Cute pink shirt"))
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .onSubmit { if !newName.isEmpty, !unchanged { save() } }
                        .accessibilityIdentifier("renameField")
                } header: {
                    FormSectionHeader("New name")
                } footer: {
                    Text("Use your own words — no clothing terms needed. Now: “\(oldName)”.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    Toggle("Keep the old name as another name", isOn: $ui.renameKeepsOldName)
                        .tint(Palette.primaryAction)
                        .accessibilityIdentifier("keepOldNameToggle")
                } footer: {
                    Text(ui.renameKeepsOldName
                         ? "Searching “\(oldName)” will still find this item."
                         : "“\(oldName)” won't be kept as another name.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    Label("Names don't change earlier pictures or start any AI", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { ui.renameTarget = nil }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("renameCancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .keyboardShortcut("s", modifiers: .command)
                        .disabled(newName.isEmpty || unchanged)
                        .accessibilityIdentifier("renameSave")
                }
            }
            .onAppear { nameFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let ui = app.garmentEditorUI
        let newName = ui.renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else { return }
        app.store.rename(garmentID, to: newName, keepOldAsOtherName: ui.renameKeepsOldName)
        ui.renameTarget = nil
        app.showToast("Renamed to “\(newName)”. Earlier pictures keep their captured names.")
    }
}

// MARK: - Previews

#Preview("Names & details") {
    NavigationStack {
        ScrollView {
            GarmentNamingSection(garmentID: "g-pink-blouse")
                .padding(Spacing.m)
        }
        .themedScreenBackground()
        .navigationTitle("Cute pink shirt")
    }
    .previewEnvironment()
}

#Preview("Rename") {
    let model = AppModel.preview
    model.garmentEditorUI.renameText = "Pink bow blouse"
    return GarmentEditorRenameSheet(garmentID: "g-pink-blouse")
        .previewEnvironment(model)
}
