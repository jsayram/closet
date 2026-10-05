import SwiftUI
import PhotosUI

/// Explicit "I ordered this / I bought this" review. Only this confirmation changes
/// ownership; the actual size is entered by her (never the recommended size), and
/// arrival is confirmed separately. Free and offline — no AI, search or image work.
struct PurchaseReviewView: View {
    var context: PurchaseReviewContext
    /// True when pushed inside Find One's navigation stack.
    var embedded: Bool = false
    /// Called to close when embedded. Root sheets dismiss instead.
    var onClose: (() -> Void)? = nil
    @Environment(AppModel.self) private var app

    var body: some View {
        let context = app.findOneUI.resolvedPurchaseContext(self.context, store: app.store)
        let draft = app.findOneUI.purchaseDraft(for: context, store: app.store)
        if embedded {
            FindOnePurchaseForm(context: context, draft: draft, onClose: onClose)
        } else {
            NavigationStack {
                FindOnePurchaseForm(context: context, draft: draft, onClose: onClose)
            }
        }
    }
}

private struct FindOnePurchaseForm: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var context: PurchaseReviewContext
    @Bindable var draft: FindOnePurchaseDraft
    var onClose: (() -> Void)?
    @State private var photoItem: PhotosPickerItem?
    @State private var photoError: String?

    private var existingGarment: Garment? { app.store.garment(context.existingGarmentID) }
    private var savedGarment: Garment? { app.store.garment(draft.savedGarmentID) }

    private var canSave: Bool {
        draft.choice != nil && draft.arrival != nil && !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            if let saved = savedGarment {
                savedSections(saved)
            } else {
                editSections
            }
        }
        .scrollContentBackground(.hidden)
        .themedScreenBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(savedGarment == nil ? "Add bought item" : "Added to closet")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(onClose != nil)
        .toolbar { toolbar }
        .safeAreaInset(edge: .bottom) {
            if savedGarment == nil { saveBar }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { @MainActor in
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        draft.photoData = data
                        draft.reminders.remove(.photo)
                        photoError = nil
                    } else {
                        photoError = "That photo couldn't be read. Choose another, or add one later."
                    }
                } catch {
                    photoError = "That photo couldn't be read. Choose another, or add one later."
                }
                photoItem = nil
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if savedGarment == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    app.findOneUI.discardPurchaseDraft(context.id)
                    close()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityHint("Nothing is added to your closet")
                .accessibilityIdentifier("purchaseCancelButton")
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    app.findOneUI.discardPurchaseDraft(context.id)
                    close()
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("purchaseDoneButton")
            }
        }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    // MARK: - Editing

    @ViewBuilder
    private var editSections: some View {
        Section {
            summaryRow
        }
        .listRowBackground(Palette.surface)

        Section {
            ForEach(FindOnePurchaseChoice.allCases) { choice in
                Button {
                    draft.choice = choice
                    if draft.arrival == nil, choice == .ordered { draft.arrival = .notArrived }
                } label: {
                    HStack {
                        Label(choice.title, systemImage: choice.systemImage)
                            .foregroundStyle(Palette.primaryText)
                        Spacer()
                        if draft.choice == choice {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Palette.primaryAction)
                        }
                    }
                    .frame(minHeight: HitTarget.minimum)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(draft.choice == choice ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("purchaseChoice-\(choice.rawValue)")
            }
        } header: {
            header("What happened?",
                   info: "Only your choice below changes ownership. Opening a store, a click or a receipt-looking page isn't proof of purchase.")
        }
        .listRowBackground(Palette.surface)

        Section {
            fieldRow(title: "Name") {
                TextField("What you call it", text: $draft.name)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("purchaseNameField")
            }
            fieldRow(title: "Size", info: sizeFooter) {
                TextField("Size you actually ordered", text: $draft.size)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Size you actually ordered")
                    .accessibilityIdentifier("purchaseSizeField")
            }
            fieldRow(title: "Color") {
                HStack(spacing: Spacing.xs) {
                    if let hex = draft.colorHex, !draft.colorName.isEmpty {
                        ColorSwatch(hex: hex, size: 20)
                    }
                    TextField("Color unknown", text: $draft.colorName)
                        .accessibilityIdentifier("purchaseColorField")
                }
            }
        } header: {
            FormSectionHeader("The item you got")
        } footer: {
            // The listing's guidance is named so she can see it wasn't filled in for her.
            if let recommended = context.candidate?.recommendedSize {
                Text("Listing guidance was \(recommended). It isn't filled in for you.")
            }
        }
        .listRowBackground(Palette.surface)

        Section {
            arrivalPicker
        } header: {
            FormSectionHeader("Arrival")
        } footer: {
            Text(arrivalFooter)
        }
        .listRowBackground(Palette.surface)

        Section {
            photoRows
        } header: {
            header("Photo · optional, simulated import",
                   info: "Never required. A chosen photo is kept as the original on this device (simulated import); optional processing stays separate.")
        }
        .listRowBackground(Palette.surface)

        Section {
            reminderRows
        } header: {
            header("Want a reminder to finish adding this?",
                   info: "Optional and off by default. In this prototype reminders stay in the app — no notification is scheduled, and nothing is inferred.")
        }
        .listRowBackground(Palette.surface)

        if let error = draft.saveError {
            Section {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(Palette.error)
            }
            .listRowBackground(Palette.surface)
        }
    }

    private var summaryRow: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            if let candidate = context.candidate {
                FindOneProductTile(candidate: candidate, size: 60)
            } else if let garment = existingGarment {
                GarmentThumbnail(garment: garment, size: 60, showsStatus: false)
            } else {
                GarmentArtwork(kind: context.findOne?.kind ?? .unknown, hex: draft.colorHex)
                    .frame(width: 60, height: 60)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let candidate = context.candidate {
                    Text("\(candidate.retailer) · \(candidate.domain)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                    Text(candidate.title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Listing: \(candidate.colorName) · \(FindOneFormat.price(candidate)) sample price")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    StatusBadge(kind: .simulated, compact: true)
                    if existingGarment != nil {
                        Text("You already added this. Confirming again updates that item — no duplicate is created.")
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if let garment = existingGarment {
                    Text(garment.displayName)
                        .font(.headline)
                    BadgeRow(badges: BadgeKind.status(for: garment))
                    Text("Confirming updates this record — no duplicate is created.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("An item you bought")
                        .font(.headline)
                    Text("No product link — add what you know. Unknown stays Unknown.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }

    /// Section header with the how-it-works text behind an info button.
    private func header(_ title: String, info: String) -> some View {
        HStack(spacing: Spacing.xxs) {
            FormSectionHeader(title)
            InfoButton(title, text: info)
                .textCase(nil)
        }
    }

    private func fieldRow<Field: View>(title: String, info: String? = nil, @ViewBuilder field: () -> Field) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
                if let info {
                    InfoButton(title, text: info)
                }
            }
            field()
                .frame(minHeight: HitTarget.minimum)
        }
    }

    private var sizeFooter: String {
        var text = "Enter the size on your order. Leave it empty if you're not sure — it stays Unknown."
        if let recommended = context.candidate?.recommendedSize {
            text = "The listing's sourced guidance was \(recommended); it isn't filled in for you. " + text
        }
        return text
    }

    @ViewBuilder
    private var arrivalPicker: some View {
        let picker = Picker("Has it arrived?", selection: $draft.arrival) {
            Text("Not arrived yet").tag(ArrivalState?.some(.notArrived))
            Text("Arrived").tag(ArrivalState?.some(.arrived))
        }
        .accessibilityIdentifier("purchaseArrivalPicker")
        if dynamicTypeSize.isAccessibilitySize {
            picker.pickerStyle(.inline)
        } else {
            picker.pickerStyle(.segmented)
        }
    }

    private var arrivalFooter: String {
        switch draft.arrival {
        case .arrived?: "Arrived items count as owned and can appear in today's looks. Its status starts Available."
        case .notArrived?: "Not arrived — won't appear in today's looks until you mark it arrived."
        default: "Choose one. Arrival is confirmed separately from buying, and nothing marks it arrived for you."
        }
    }

    @ViewBuilder
    private var photoRows: some View {
        if let data = draft.photoData, let image = UIImage(data: data) {
            HStack(spacing: Spacing.s) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
                    .accessibilityLabel("Selected photo")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo added")
                        .font(.subheadline.weight(.semibold))
                    Text("The original is kept when you save.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer()
                Button("Remove", role: .destructive) { draft.photoData = nil }
                    .buttonStyle(.borderless)
                    .minimumHitTarget()
                    .accessibilityIdentifier("purchasePhotoRemove")
            }
        } else {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo later")
                    Text("Default. A text-only item works everywhere.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(Palette.primaryAction)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isSelected)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                    .frame(minHeight: HitTarget.minimum)
            }
            .accessibilityIdentifier("purchasePhotoPicker")
            HStack {
                Text("Or paste an image you copied")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Spacer()
                PasteButton(payloadType: FindOnePastedImage.self) { items in
                    guard let first = items.first else { return }
                    Task { @MainActor in
                        draft.photoData = first.data
                        draft.reminders.remove(.photo)
                    }
                }
                .labelStyle(.titleAndIcon)
                .buttonBorderShape(.capsule)
                .tint(Palette.primaryAction)
                .accessibilityIdentifier("purchasePasteImage")
            }
        }
        if let photoError {
            Label(photoError, systemImage: "exclamationmark.triangle")
                .font(.footnote)
                .foregroundStyle(Palette.error)
        }
    }

    @ViewBuilder
    private var reminderRows: some View {
        ForEach(ReminderKind.allCases) { kind in
            let unavailableReason: String? = switch kind {
            case .arrival: draft.arrival == .arrived ? "Already arrived" : nil
            case .photo: draft.photoData != nil ? "Photo added" : nil
            case .description: nil
            }
            Toggle(isOn: Binding(
                get: { draft.reminders.contains(kind) && unavailableReason == nil },
                set: { on in if on { draft.reminders.insert(kind) } else { draft.reminders.remove(kind) } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.label)
                    if let unavailableReason {
                        Text(unavailableReason)
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            .tint(Palette.primaryAction)
            .disabled(unavailableReason != nil)
            .accessibilityIdentifier("purchaseReminder-\(kind.rawValue)")
        }
        if !activeReminderKinds.isEmpty {
            Toggle("Pick a date", isOn: $draft.usesReminderDate)
                .tint(Palette.primaryAction)
                .accessibilityIdentifier("purchaseReminderDateToggle")
            if draft.usesReminderDate {
                DatePicker("Remind me on", selection: $draft.reminderDate, in: Date.now..., displayedComponents: .date)
                    .accessibilityIdentifier("purchaseReminderDate")
            }
        }
    }

    private var activeReminderKinds: Set<ReminderKind> {
        var kinds = draft.reminders
        if draft.arrival == .arrived { kinds.remove(.arrival) }
        if draft.photoData != nil { kinds.remove(.photo) }
        return kinds
    }

    private var saveBar: some View {
        VStack(spacing: Spacing.xs) {
            if !canSave {
                Text(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     ? "Add a name, choose I ordered or I bought, and whether it has arrived."
                     : "Choose I ordered or I bought, and whether it has arrived.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: save) {
                Label(draft.choice == .ordered ? "Save as ordered" : "Save to closet", systemImage: "checkmark")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave)
            .keyboardShortcut("s", modifiers: .command)
            .accessibilityIdentifier("purchaseSaveButton")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity)
        .background(Palette.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Palette.divider).frame(height: 1) }
    }

    // MARK: - Save

    private func save() {
        // Repeated taps or retries never create a second record.
        guard draft.savedGarmentID == nil, canSave, let arrival = draft.arrival else { return }
        let arrived = arrival == .arrived
        let kinds = activeReminderKinds
        let trimmedSize = draft.size.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedColor = draft.colorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let color = resolvedColor(name: trimmedColor)
        let kind = context.candidate?.kind ?? existingGarment?.kind ?? context.findOne?.kind ?? .unknown
        let retailer = context.candidate.map { "\($0.retailer) (fictional demo)" }
        let url = context.candidate?.url
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        let saved: Garment?
        if let existingID = context.existingGarmentID, existingGarment != nil {
            saved = app.store.findOneConfirmExistingPurchase(existingID, name: name, color: color, size: trimmedSize.isEmpty ? nil : trimmedSize,
                                                             retailer: retailer, url: url, arrived: arrived, reminderKinds: kinds)
        } else {
            saved = app.store.confirmPurchase(name: name, kind: kind, color: color, size: trimmedSize.isEmpty ? nil : trimmedSize,
                                              retailer: retailer, url: url, arrived: arrived, reminderKinds: kinds)
        }
        guard let garment = saved else {
            draft.saveError = "That item couldn't be found any more, so nothing was changed."
            return
        }
        draft.savedGarmentID = garment.id
        draft.saveError = app.store.lastSaveError.map { "\($0) The item is kept for this session; try again later." }

        // Original-first photo import.
        if let data = draft.photoData {
            do {
                let filename = try PhotoStore.saveOriginal(data)
                app.store.findOneAttachPhoto(garment.id, filename: filename)
            } catch {
                draft.saveError = "The photo couldn't be saved, so the item was saved text-only. Add the photo later."
            }
        }
        if draft.usesReminderDate {
            for reminder in app.store.reminders where reminder.garmentID == garment.id && kinds.contains(reminder.kind) && reminder.status == .pending {
                app.store.setReminder(reminder.id, status: .pending, dueDate: draft.reminderDate)
            }
        }
        if let candidate = context.candidate {
            app.store.findOneDismissVisitPrompts(candidateID: candidate.id)
        }
        let choice = draft.choice == .ordered ? "ordered" : "bought"
        draft.saveMessage = arrived
            ? "Saved as \(choice) and arrived. It's in your current closet."
            : "Saved as \(choice) — not arrived yet."
        app.showToast(arrived ? "Added to your closet." : "Added to your closet as not arrived yet.")
    }

    private func resolvedColor(name: String) -> GarmentColor? {
        guard !name.isEmpty else { return nil }
        let hex = draft.colorHex ?? context.findOne?.colorFamily?.swatchHex
        let family: ColorFamily
        if let match = ColorFamily.allCases.first(where: { name.lowercased().contains($0.label.lowercased()) }) {
            family = match
        } else if let hex {
            family = FindOneFormat.nearestFamily(hex: hex)
        } else {
            family = context.findOne?.colorFamily ?? .multi
        }
        return GarmentColor(name: name, hex: hex ?? family.swatchHex, family: family)
    }

    // MARK: - After saving

    @ViewBuilder
    private func savedSections(_ garment: Garment) -> some View {
        Section {
            HStack(alignment: .top, spacing: Spacing.s) {
                GarmentThumbnail(garment: garment, size: 64, showsStatus: false)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(garment.displayName)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    BadgeRow(badges: [.custom(garment.ownership.label, "bag")] + BadgeKind.status(for: garment)
                             + [BadgeKind.image(for: garment.photoFilename != nil ? .actualPhoto : garment.imageKind)])
                    Text("Size: \(garment.sizeLabel ?? "Unknown") · Color: \(garment.colorLabel)")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            if let message = draft.saveMessage {
                Label(message, systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Palette.success)
                    .accessibilityIdentifier("purchaseSavedMessage")
            }
            if garment.arrival != .arrived {
                Text("Not arrived — won't appear in today's looks until you mark it arrived.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
            }
            if let error = draft.saveError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
            }
        }
        .listRowBackground(Palette.surface)

        Section {
            addToOutfitRow(garment)
            if let suitcaseID = context.findOne?.scope.suitcaseID {
                addToSuitcaseRow(garment, suitcaseID: suitcaseID)
            }
        } header: {
            header("Next — only if you want",
                   info: "Nothing is added automatically. Your look and suitcases stay as they are until you choose.")
        }
        .listRowBackground(Palette.surface)
    }

    @ViewBuilder
    private func addToOutfitRow(_ garment: Garment) -> some View {
        let editor = app.editor
        let eligibility = editor.map { app.store.eligibility(of: garment, scope: $0.scope, overrides: $0.overrideIDs) }
        let slot = OutfitSlot.slot(for: garment.category) ?? context.findOne?.slot
        let enabled = editor != nil && eligibility?.isEligible == true && slot != nil && draft.outfitMessage == nil
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Button {
                guard let slot, let editor else { return }
                if app.applySwap(slot: slot, garmentID: garment.id) {
                    draft.outfitMessage = "Added to “\(editor.outfit.title)”. Save the look in the editor to keep it."
                } else {
                    draft.outfitMessage = "It couldn't be added — its status may have changed."
                }
            } label: {
                Label("Add to this outfit", systemImage: "rectangle.stack.badge.plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .disabled(!enabled)
            .accessibilityIdentifier("addToOutfitButton")
            Text(outfitReason(editor: editor, eligibility: eligibility))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func outfitReason(editor: OutfitEditorSession?, eligibility: Eligibility?) -> String {
        if let message = draft.outfitMessage { return message }
        guard let editor else { return "Open a look in the outfit editor to add it there." }
        guard let eligibility else { return "" }
        if eligibility.isEligible { return "Replaces only that piece in “\(editor.outfit.title)”." }
        if eligibility.issues.contains(.notArrived) || eligibility.issues.contains(.arrivalUnknown) {
            return "Not arrived items can't be used for today's looks yet"
        }
        if eligibility.issues.contains(.outsideSource) {
            return "This look uses only \(app.store.scopeName(editor.scope)). Add it to that suitcase first."
        }
        return "Can't be used right now: \(eligibility.issues.map(\.label).joined(separator: ", "))."
    }

    private func addToSuitcaseRow(_ garment: Garment, suitcaseID: String) -> some View {
        let name = app.store.scopeName(.suitcase(suitcaseID))
        let isMember = app.store.membership(garmentID: garment.id, suitcaseID: suitcaseID) != nil
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Button {
                let result = app.store.addMembers([garment.id], to: suitcaseID)
                if !result.added.isEmpty {
                    draft.suitcaseMessage = "Added to \(name). It's linked, not copied."
                } else if !result.alreadyPresent.isEmpty {
                    draft.suitcaseMessage = "Already in \(name)."
                } else {
                    draft.suitcaseMessage = "Couldn't add — \(name) is archived or changed."
                }
            } label: {
                Label("Add to this suitcase", systemImage: "suitcase")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .disabled(isMember)
            .accessibilityHint("Links it to \(name)")
            .accessibilityIdentifier("addToSuitcaseButton")
            Text(draft.suitcaseMessage ?? (garment.arrival == .arrived
                ? "Links it to \(name). Nothing else changes."
                : "Links it to \(name). It joins looks there once you mark it arrived."))
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview("Bought item review") {
    let candidate = MockWebSearch.leads(for: PublicShoppingIntent(garment: "trousers", color: "Navy", budgetMax: 80, shipsTo: "United States",
                                                                    preferredRetailers: [], retailerOnly: false))[0]
    return PurchaseReviewView(context: PurchaseReviewContext(candidate: candidate,
                                                             findOne: FindOneContext(slot: .bottom, description: "trousers", kind: .trousers,
                                                                                     colorFamily: .navy, scope: .suitcase(DemoFixtures.jose))))
        .previewEnvironment()
}
