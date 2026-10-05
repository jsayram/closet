import SwiftUI

/// Optional photo understanding for the Add Item draft (PRD 7.6 #2, 8.4, 15.4).
///
/// - Needs a photo and the separate `photoUnderstanding` permission. Styling and
///   On Me permissions never cover it.
/// - The only dispatch is the explicit "Suggest a description" button.
/// - Proposals show their uncertainty; each is Accepted, Edited or Skipped. Only
///   accepted values fill the form, and fabric/brand/size stay Unknown.
/// - Failure, cancellation or a changed photo leave the manual form untouched.
struct GarmentEditorSuggestCard: View {
    @Binding var draft: GarmentEditorDraft

    @Environment(AppModel.self) private var app
    @State private var editingID: UUID?
    @State private var editText = ""

    private let purpose = ProcessingPurpose.photoUnderstanding

    private var permission: PermissionState { app.store.profile.permission(purpose) }
    private var session: GarmentEditorSuggestionSession { draft.suggestion }

    var body: some View {
        CardSection("Suggest a description", subtitle: "Optional",
                    info: "Optional help naming it from this photo. You review every suggestion. A photo can't confirm fabric, brand, size, fit or ownership — those stay as you set them.",
                    systemImage: "text.viewfinder") {
            if session.phase == .working {
                working
            } else {
                requestButton
            }

            if session.showConsent, permission != .allowed {
                consentCard
            } else if permission != .allowed, session.phase == .idle, permission == .declined || session.consentDismissed {
                Text(permission == .declined
                     ? "Photo descriptions are turned off. Naming it yourself works exactly the same."
                     : "Not now — nothing was sent. Naming it yourself works exactly the same.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            phaseContent
        }
    }

    // MARK: Request

    private var requestButton: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: requestTapped) {
                Label(session.phase == .ready ? "Suggest again" : "Suggest a description", systemImage: "text.viewfinder")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .disabled(draft.photo == nil)
            .accessibilityIdentifier("suggestDescriptionButton")
            .accessibilityHint(permission == .allowed
                               ? "Sends only this photo to \(purpose.recipient)."
                               : "Asks for your permission first. Nothing is sent until you allow it.")
            Text(permission == .allowed
                 ? "Sends only this photo to \(purpose.recipient). Nothing is applied until you accept it."
                 : "Needs your OK first — nothing is sent until you allow it.")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var working: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.s) {
                ProgressView()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Looking at the photo… (simulated)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    Text("Only this photo was sent to \(purpose.recipient). Keep editing if you like.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            Button("Cancel suggestions", action: cancel)
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("cancelSuggestionButton")
        }
    }

    // MARK: Consent (separate, named permission)

    private var consentCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Allow garment photo descriptions?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            consentRow("Sent to", purpose.recipient)
            consentRow("What's sent", purpose.dataSent)
            // Who gets the photo and what's sent stay on screen; the rest is one tap away.
            DetailsDisclosure("More about this permission", count: 2, identifier: "photoUnderstandingConsentDetails") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    consentRow("Never sent", "Your body photo, measurements, or the rest of your closet.")
                    consentRow("Separate permission", "Styling and On Me permissions don't cover this. Change it any time in Settings.")
                }
            }
            SimulationNotice(text: "Demo: the describer is simulated. Nothing leaves this device.", style: .full)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { consentButtons }
                VStack(alignment: .leading, spacing: Spacing.xs) { consentButtons }
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("photoUnderstandingConsent")
    }

    @ViewBuilder private var consentButtons: some View {
        Button("Allow") {
            app.store.setPermission(purpose, .allowed)
            draft.suggestion.showConsent = false
            UIAccessibility.post(notification: .announcement, argument: "Allowed. Tap Suggest a description when you're ready.")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("photoUnderstandingAllow")
        .accessibilityHint("Allows sending a selected garment photo for suggestions. Nothing is sent yet.")
        Button("Not now") {
            draft.suggestion.showConsent = false
            draft.suggestion.consentDismissed = true
        }
        .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
        .accessibilityIdentifier("photoUnderstandingNotNow")
    }

    private func consentRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Phase content

    @ViewBuilder private var phaseContent: some View {
        switch session.phase {
        case .idle, .working:
            EmptyView()
        case let .failed(message):
            InlineBanner(style: .error, title: "Suggestions didn't come through",
                         message: "\(message) Nothing changed — naming it yourself works the same.",
                         actionTitle: "Try again", action: requestTapped)
        case .cancelled:
            InlineBanner(style: .info, title: "Cancelled — nothing was applied",
                         message: "The photo may already have reached the simulated describer, but no suggestion was added to this item.")
        case .discarded:
            InlineBanner(style: .info, title: "The photo changed",
                         message: "Earlier suggestions were set aside because they were for a different photo. Ask again if you like.")
        case .ready:
            proposals
        }
    }

    private var proposals: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.xs) {
                StatusBadge(kind: .simulated, compact: true)
                Text("Suggested — review each one")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
            }
            .accessibilityElement(children: .combine)
            ForEach(Array(session.items.enumerated()), id: \.element.id) { index, item in
                proposalRow(item, identifierKey: identifierKey(at: index))
            }
            if session.items.allSatisfy({ $0.status != .pending }) {
                Label("All reviewed. Only what you accepted is in the form.", systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Palette.success)
            }
        }
    }

    private func identifierKey(at index: Int) -> String {
        let key = session.items[index].fieldKey
        let earlier = session.items[..<index].filter { $0.fieldKey == key }.count
        return earlier == 0 ? key : "\(key)-\(earlier + 1)"
    }

    private func proposalRow(_ item: GarmentEditorProposalItem, identifierKey: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(item.proposal.field.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(item.proposal.value)
                .font(.body.weight(.semibold))
                .foregroundStyle(item.status == .skipped ? Palette.secondaryText : Palette.primaryText)
                .strikethrough(item.status == .skipped)
                .fixedSize(horizontal: false, vertical: true)
            Label(item.proposal.uncertainty, systemImage: "questionmark.circle")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            switch item.status {
            case .pending:
                if editingID == item.id {
                    editor(item, identifierKey: identifierKey)
                } else {
                    if let problem = item.resultNote {
                        Text(problem)
                            .font(.footnote)
                            .foregroundStyle(Palette.error)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if item.isUnknownOnly {
                        ActionGroup {
                            acceptButton(item, identifierKey: identifierKey)
                            skipButton(item, identifierKey: identifierKey)
                        }
                    } else {
                        ActionGroup(moreIdentifier: "proposalMore-\(identifierKey)") {
                            acceptButton(item, identifierKey: identifierKey)
                            skipButton(item, identifierKey: identifierKey)
                        } more: {
                            Button("Edit before adding", systemImage: "pencil") {
                                editText = item.proposal.value
                                editingID = item.id
                            }
                            .accessibilityIdentifier("proposalEdit-\(identifierKey)")
                            .accessibilityLabel("Edit \(item.proposal.field) before adding")
                        }
                    }
                }
            case .accepted, .edited:
                Label(item.resultNote ?? "Added to the form", systemImage: "checkmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.success)
                    .fixedSize(horizontal: false, vertical: true)
            case .skipped:
                Label("Skipped — nothing changed", systemImage: "forward")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func acceptButton(_ item: GarmentEditorProposalItem, identifierKey: String) -> some View {
        Button {
            apply(item, value: item.proposal.value, edited: false)
        } label: {
            Label(item.isUnknownOnly ? "Keep Unknown" : "Accept", systemImage: "checkmark")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("proposalAccept-\(identifierKey)")
        .accessibilityLabel(item.isUnknownOnly ? "Keep \(item.proposal.field) Unknown" : "Accept \(item.proposal.field): \(item.proposal.value)")
    }

    private func skipButton(_ item: GarmentEditorProposalItem, identifierKey: String) -> some View {
        Button {
            setStatus(item, .skipped, note: nil)
        } label: {
            Label("Skip", systemImage: "forward")
        }
        .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
        .accessibilityIdentifier("proposalSkip-\(identifierKey)")
        .accessibilityLabel("Skip \(item.proposal.field)")
    }

    private func editor(_ item: GarmentEditorProposalItem, identifierKey: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            TextField(item.proposal.field, text: $editText)
                .textInputAutocapitalization(.sentences)
                .garmentEditorField()
                .accessibilityLabel("Edit \(item.proposal.field)")
                .accessibilityIdentifier("proposalEditField-\(identifierKey)")
            FlowLayout(spacing: Spacing.xs) {
                Button {
                    let value = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else { return }
                    apply(item, value: value, edited: value != item.proposal.value)
                    editingID = nil
                } label: {
                    Label("Use this", systemImage: "checkmark")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("proposalUseEdit-\(identifierKey)")
                Button("Cancel") { editingID = nil }
                    .buttonStyle(SecondaryButtonStyle(tint: Palette.primaryText))
            }
        }
    }

    // MARK: Actions

    private func requestTapped() {
        guard draft.photo != nil else { return }
        guard permission == .allowed else {
            draft.suggestion.showConsent = true
            draft.suggestion.consentDismissed = false
            UIAccessibility.post(notification: .announcement, argument: "Permission needed. Review what would be sent.")
            return
        }
        dispatch()
    }

    /// The only service dispatch in this feature: an explicit tap with permission.
    private func dispatch() {
        guard let photo = draft.photo else { return }
        let ui = app.garmentEditorUI
        let key = draft.key
        let photoName = photo.originalFilename
        // Only the selected photo goes out, matching the consent card. Her typed
        // name, other names, details, notes, brand, size, link and choices stay here.
        var probe = Garment(id: "draft-\(key)", displayName: "Selected photo", category: .unknown, kind: .unknown, color: nil)
        probe.ownership = .inspiration
        probe.imageKind = .actualPhoto
        probe.photoFilename = photoName
        let service = app.services.garmentUnderstanding
        editingID = nil
        draft.suggestion.phase = .working
        draft.suggestion.items = []
        draft.suggestion.requestedPhoto = photoName
        draft.suggestion.showConsent = false
        ui.suggestionTask?.cancel()
        ui.suggestionTask = Task { @MainActor in
            do {
                let proposals = try await service.proposeDetails(for: probe)
                guard !Task.isCancelled else { return }
                guard var current = ui.draft, current.key == key, current.suggestion.phase == .working else { return }
                guard current.photo?.originalFilename == photoName else {
                    current.suggestion.items = []
                    current.suggestion.phase = .discarded
                    ui.draft = current
                    return
                }
                current.suggestion.items = proposals.map { GarmentEditorProposalItem(proposal: $0) }
                current.suggestion.phase = .ready
                ui.draft = current
                UIAccessibility.post(notification: .announcement, argument: "\(proposals.count) suggestions ready to review")
            } catch {
                guard !Task.isCancelled, var current = ui.draft, current.key == key, current.suggestion.phase == .working else { return }
                let message = (error as? LocalizedError)?.errorDescription ?? "The simulated describer didn't finish."
                current.suggestion.phase = .failed(message)
                ui.draft = current
                UIAccessibility.post(notification: .announcement, argument: "Suggestions didn't come through. Nothing changed.")
            }
        }
    }

    private func cancel() {
        app.garmentEditorUI.suggestionTask?.cancel()
        app.garmentEditorUI.suggestionTask = nil
        draft.suggestion.phase = .cancelled
    }

    private func setStatus(_ item: GarmentEditorProposalItem, _ status: GarmentEditorProposalStatus, note: String?) {
        guard let index = draft.suggestion.items.firstIndex(where: { $0.id == item.id }) else { return }
        draft.suggestion.items[index].status = status
        draft.suggestion.items[index].resultNote = note
    }

    /// Applies one reviewed value to the form. Unmatched values stay pending with a note.
    private func apply(_ item: GarmentEditorProposalItem, value: String, edited: Bool) {
        let field = item.proposal.field.lowercased()
        let status: GarmentEditorProposalStatus = edited ? .edited : .accepted
        if item.isUnknownOnly {
            setStatus(item, .accepted, note: "\(item.proposal.field) stays Unknown")
            return
        }
        switch field {
        case "name":
            let previous = draft.trimmedName
            draft.name = value
            if !previous.isEmpty, previous.lowercased() != value.lowercased(),
               !draft.otherNames.contains(where: { $0.text.lowercased() == previous.lowercased() }) {
                draft.otherNames.append(GarmentEditorDraftNote(text: previous, provenance: .userEntered))
                setStatus(item, status, note: "Name set to “\(value)”. Your “\(previous)” is kept as another name.")
            } else {
                setStatus(item, status, note: "Name set to “\(value)”")
            }
        case "category", "kind", "type":
            let (kind, category) = GarmentEditorNaming.kindOrCategory(matching: value)
            if let kind {
                draft.kind = kind
                draft.category = kind.defaultCategory
                setStatus(item, status, note: "Set to \(kind.defaultCategory.label) · \(kind.label)")
            } else if let category {
                draft.category = category
                if draft.kind.defaultCategory != category { draft.kind = .unknown }
                setStatus(item, status, note: "Category set to \(category.label)")
            } else {
                setStatus(item, .pending, note: "“\(value)” doesn't match a category. Edit it, skip it, or choose one in What it is.")
            }
        case "color", "colour":
            guard let family = GarmentEditorNaming.colorFamily(matching: value) else {
                setStatus(item, .pending, note: "“\(value)” doesn't match a color family. Edit it, skip it, or pick a swatch.")
                return
            }
            let shade = GarmentEditorNaming.shadeName(from: value)
            draft.colorFamily = family
            draft.shadeName = shade.lowercased() == family.label.lowercased() ? "" : shade
            setStatus(item, status, note: "Color set to \(shade.isEmpty ? family.label : shade) (\(family.label) family)")
        default:
            let lower = value.lowercased()
            if !draft.details.contains(where: { $0.text.lowercased() == lower }) {
                draft.details.append(GarmentEditorDraftNote(text: value, provenance: edited ? .userEntered : .acceptedSuggestion))
            }
            setStatus(item, status, note: "Added to details")
        }
        UIAccessibility.post(notification: .announcement, argument: draft.suggestion.items.first(where: { $0.id == item.id })?.resultNote ?? "Added")
    }
}
