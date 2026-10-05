import SwiftUI

extension FitResult {
    var profileSystemImage: String {
        switch self {
        case .fitsWell: "checkmark.circle"
        case .tooLong: "arrow.down.to.line"
        case .tooShort: "arrow.up.to.line"
        case .tooTight: "arrow.right.and.line.vertical.and.arrow.left"
        case .tooLoose: "arrow.left.and.right"
        case .returned: "arrow.uturn.left"
        }
    }

    var profileTone: ProfileToneBadge.Tone {
        switch self {
        case .fitsWell: .success
        case .returned: .neutral
        default: .caution
        }
    }
}

// MARK: - Section

/// Profile → Fit references: real garments she confirmed fit (or didn't).
struct ProfileFitReferencesSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let references = app.store.profile.fitReferences
        Section {
            if references.isEmpty {
                Text("No fit references yet. A pair of trousers that fits well is the most useful one to add.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(references) { reference in
                ProfileFitReferenceRow(reference: reference, garment: app.store.garment(reference.garmentID)) {
                    app.profileUI.openFitReference(reference)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        app.profileDeleteFitReference(reference)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button {
                app.profileUI.openNewFitReference()
            } label: {
                Label("Add a fit reference", systemImage: "plus.circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Palette.primaryAction)
                    .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityIdentifier("fitReferenceAdd")
        } header: {
            ProfileListHeader(
                "Fit references",
                subtitle: "Real garments and how they fit.",
                info: "A reference describes one garment. A good waist fit doesn't prove seat, thigh or length, and a reference never fills in an unknown measurement.",
                systemImage: "tag"
            )
        }
        .listRowBackground(Palette.surface)
    }
}

extension AppModel {
    /// Deletes a fit reference locally with a bounded, revision-safe Undo.
    func profileDeleteFitReference(_ reference: FitReference) {
        let index = store.profile.fitReferences.firstIndex { $0.id == reference.id } ?? 0
        store.updateProfile { $0.fitReferences.removeAll { $0.id == reference.id } }
        store.pushUndo(UndoEntry(label: "Delete fit reference") { store in
            guard !store.profile.fitReferences.contains(where: { $0.id == reference.id }) else {
                return "That fit reference is already back."
            }
            store.updateProfile { profile in
                profile.fitReferences.insert(reference, at: min(index, profile.fitReferences.count))
            }
            return "Fit reference restored."
        })
        if store.lastSaveError != nil {
            profileConfirmSave("")
        } else {
            showUndoToast("Fit reference deleted. Saved on this device")
        }
    }
}

/// Row: linked garment thumbnail, brand · size, category, result and areas.
struct ProfileFitReferenceRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var reference: FitReference
    var garment: Garment?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.s) {
                if !dynamicTypeSize.isAccessibilitySize {
                    thumbnail
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(reference.sizeLabel.isEmpty ? reference.brand : "\(reference.brand) · \(reference.sizeLabel)")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: Spacing.xxs) {
                        ProfileToneBadge(text: reference.result.label, systemImage: reference.result.profileSystemImage, tone: reference.result.profileTone)
                        ForEach(reference.areas) { area in
                            ProfileToneBadge(text: area.label, systemImage: "scope", tone: .neutral)
                        }
                    }
                    if !reference.note.isEmpty {
                        Text(reference.note)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: Spacing.xs)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .padding(.top, Spacing.xxs)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.xxs)
            .frame(minHeight: HitTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Edits or deletes this fit reference")
        .accessibilityIdentifier("fitReference-\(reference.brand)")
    }

    @ViewBuilder private var thumbnail: some View {
        if let garment {
            GarmentThumbnail(garment: garment, size: 52, showsStatus: false)
        } else {
            RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                .fill(Palette.imageWell)
                .frame(width: 52, height: 52)
                .overlay(Image(systemName: "tag").foregroundStyle(Palette.secondaryText))
                .accessibilityHidden(true)
        }
    }

    private var subtitle: String {
        var parts = [reference.category.label]
        if let garment { parts.append("Linked: \(garment.displayName)") }
        return parts.joined(separator: " · ")
    }

    private var accessibilityText: String {
        var parts = ["\(reference.brand), size \(reference.sizeLabel.isEmpty ? "not noted" : reference.sizeLabel)", reference.category.label, reference.result.label]
        if !reference.areas.isEmpty { parts.append("Areas: " + reference.areas.map(\.label).joined(separator: ", ")) }
        if !reference.note.isEmpty { parts.append("Note: \(reference.note)") }
        if let garment { parts.append("Linked to \(garment.displayName)") }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Editor

/// Add/edit/delete one fit reference.
struct ProfileFitReferenceEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false

    var body: some View {
        @Bindable var ui = app.profileUI
        let draft = ui.fitReferenceDraft
        let canSave = !draft.brand.trimmingCharacters(in: .whitespaces).isEmpty
            && !draft.sizeLabel.trimmingCharacters(in: .whitespaces).isEmpty
        NavigationStack {
            Form {
                Section {
                    TextField("Brand", text: $ui.fitReferenceDraft.brand)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("fitReferenceBrand")
                    Picker("Category", selection: $ui.fitReferenceDraft.category) {
                        ForEach(GarmentCategory.allCases.filter { $0 != .unknown }) { category in
                            Text(category.label).tag(category)
                        }
                    }
                    TextField("Size label, as printed (e.g. 2P, S, 26 Short)", text: $ui.fitReferenceDraft.sizeLabel)
                        .textInputAutocapitalization(.characters)
                        .accessibilityIdentifier("fitReferenceSize")
                } header: {
                    ProfileFormHeader("Garment", info: "Keep the size exactly as the brand prints it. Sizes don't convert between brands.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("Result", selection: $ui.fitReferenceDraft.result) {
                        ForEach(FitResult.allCases) { result in
                            Label(result.label, systemImage: result.profileSystemImage).tag(result)
                        }
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Where (optional)")
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                        ChipCarousel(isExpanded: app.profileUI.detailsBinding("fitReferenceAreaChips"), itemsLabel: "areas") {
                            ForEach(FitArea.allCases) { area in
                                let selected = draft.areas.contains(area)
                                CapsuleChip(title: area.label, isSelected: selected) {
                                    if selected {
                                        app.profileUI.fitReferenceDraft.areas.removeAll { $0 == area }
                                    } else {
                                        app.profileUI.fitReferenceDraft.areas.append(area)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                    TextField("Note (optional)", text: $ui.fitReferenceDraft.note, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    ProfileFormHeader("How it fit", info: "A return isn't automatically a fit problem — add the reason in the note if it was something else.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("Closet item", selection: $ui.fitReferenceDraft.garmentID) {
                        Text("None").tag(String?.none)
                        ForEach(linkCandidates(for: draft)) { garment in
                            Text(garment.displayName).tag(Optional(garment.id))
                        }
                    }
                } header: {
                    ProfileFormHeader("Linked closet item (optional)", info: "Linking only connects the note to a piece you own. It doesn't change the garment.")
                }
                .listRowBackground(Palette.surface)

                if !ui.fitReferenceIsNew {
                    Section {
                        Button(role: .destructive) {
                            confirmingDelete = true
                        } label: {
                            Label("Delete fit reference", systemImage: "trash")
                                .foregroundStyle(Palette.error)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle(ui.fitReferenceIsNew ? "Add fit reference" : "Edit fit reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("fitReferenceSave")
                }
            }
            .confirmationDialog("Delete this fit reference?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    let reference = app.profileUI.fitReferenceDraft
                    if let stored = app.store.profile.fitReferences.first(where: { $0.id == reference.id }) {
                        app.profileDeleteFitReference(stored)
                    }
                    dismiss()
                }
            } message: {
                Text("Only this note is removed. The linked closet item isn't changed. You can undo right after.")
            }
        }
    }

    /// Owned, non-trashed garments in the chosen category (plus the current link).
    private func linkCandidates(for draft: FitReference) -> [Garment] {
        app.store.garments.filter { garment in
            garment.id == draft.garmentID || (garment.isOwnedOrPurchased && garment.category == draft.category)
        }
    }

    private func save() {
        var reference = app.profileUI.fitReferenceDraft
        reference.brand = reference.brand.trimmingCharacters(in: .whitespaces)
        reference.sizeLabel = reference.sizeLabel.trimmingCharacters(in: .whitespaces)
        reference.note = reference.note.trimmingCharacters(in: .whitespacesAndNewlines)
        reference.areas = FitArea.allCases.filter { reference.areas.contains($0) }
        app.profileSave { profile in
            if let i = profile.fitReferences.firstIndex(where: { $0.id == reference.id }) {
                profile.fitReferences[i] = reference
            } else {
                profile.fitReferences.append(reference)
            }
        }
        dismiss()
    }
}

#Preview("Fit reference editor") {
    let model = AppModel.preview
    if let first = model.store.profile.fitReferences.first { model.profileUI.openFitReference(first) }
    return ProfileFitReferenceEditor()
        .previewEnvironment(model)
}
