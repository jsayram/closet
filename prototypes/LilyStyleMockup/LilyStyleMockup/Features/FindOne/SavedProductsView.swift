import SwiftUI
import PhotosUI

/// Saved for later, recent store visits and purchases to finish. Everything here
/// is free and offline: no AI, search or image work, and prices are snapshots.
struct SavedProductsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        GeometryReader { geo in
            let wide = WidthClass(width: geo.size.width) != .compact
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    SimulationNotice(text: "Saved products, store visits and purchase reminders are free and work offline — no AI, search or image calls. Prices are snapshots from when you saved them and are never refreshed automatically.",
                                     summary: "Free and offline. Prices are snapshots.")
                    if wide {
                        HStack(alignment: .top, spacing: Spacing.l) {
                            VStack(alignment: .leading, spacing: Spacing.l) {
                                FindOneSavedForLaterSection()
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            VStack(alignment: .leading, spacing: Spacing.l) {
                                FindOneFinishSection()
                                FindOneVisitsSection()
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                    } else {
                        FindOneFinishSection()
                        FindOneSavedForLaterSection()
                        FindOneVisitsSection()
                    }
                }
                .padding(Spacing.m)
                .readableWidth(wide ? 1100 : 720)
            }
        }
        .themedScreenBackground()
        .navigationTitle("Saved products")
    }
}

// MARK: - Saved for later

private struct FindOneSavedForLaterSection: View {
    @Environment(AppModel.self) private var app
    @State private var pendingRemoval: SavedProductReference?

    var body: some View {
        let saved = app.store.savedProducts.sorted { $0.savedAt > $1.savedAt }
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Saved for later", info: "Private references. Saving never means you own it.", editorial: true)
            if saved.isEmpty {
                EmptyStateView(title: "Nothing saved yet",
                               message: "In Find One, Save for Later keeps a product here without buying it.",
                               systemImage: "bookmark")
                    .cardStyle()
            } else {
                ForEach(saved) { reference in
                    row(reference)
                }
            }
        }
        .confirmationDialog("Remove this saved product?",
                            isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }),
                            titleVisibility: .visible,
                            presenting: pendingRemoval) { reference in
            Button("Remove", role: .destructive) {
                app.store.findOneRemoveSavedProduct(reference.id)
                app.showToast("Removed from Saved for later. Nothing else changed.", style: .info)
            }
            Button("Keep", role: .cancel) {}
        } message: { reference in
            Text("“\(reference.candidate.title)” is removed from this list only.")
        }
    }

    private func row(_ reference: SavedProductReference) -> some View {
        let candidate = reference.candidate
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    FindOneProductTile(candidate: candidate, size: 64)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(candidate.retailer) · \(candidate.domain)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(candidate.title)
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(FindOneFormat.price(candidate)) sample price when saved · saved \(FindOneFormat.relative(reference.savedAt))")
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                // Remove sits apart from the two everyday actions and still confirms.
                FindOneOverflowMenu(identifier: "savedProductMore-\(candidate.id)") {
                    Button(role: .destructive) {
                        pendingRemoval = reference
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .accessibilityIdentifier("savedProductRemove-\(candidate.id)")
                }
            }
            BadgeRow(badges: app.store.findOnePurchasedGarment(for: candidate) == nil
                     ? [.simulated, .custom("Saved — not owned", "bookmark")]
                     : [.simulated, .custom("Saved", "bookmark"), .custom("In your closet — you confirmed buying it", "checkmark.seal")],
                     scrolls: true)
            // The fit state stays on screen; when it was captured is one tap away.
            HStack(spacing: Spacing.xxs) {
                FindOneFitBadge(state: candidate.fitState)
                Text("when saved")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("the fit when saved", title: "Fit when saved",
                           text: "Fit when saved: \(candidate.fitState.title)\(candidate.recommendedSize.map { " · sourced guidance \($0)" } ?? ""). Snapshot from \(FindOneFormat.relative(candidate.retrievedAt)) — not refreshed."
                               + (reference.context.map { " From Find One for \($0.description) · \(app.store.scopeName($0.scope))." } ?? ""))
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { actions(reference) }
                VStack(alignment: .leading, spacing: Spacing.xs) { actions(reference) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("savedProductRow-\(candidate.id)")
    }

    @ViewBuilder
    private func actions(_ reference: SavedProductReference) -> some View {
        Button {
            app.store.recordVisit(reference.candidate, context: reference.context)
            app.present(.storeHandoff(reference.candidate, reference.context))
        } label: {
            Label("View at Store", systemImage: "arrow.up.forward.app")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityHint("Opens a simulated store page. No search runs.")
        .accessibilityIdentifier("savedProductViewAtStore-\(reference.candidate.id)")
        let purchased = app.store.findOnePurchasedGarment(for: reference.candidate)
        Button {
            app.present(.purchaseReview(PurchaseReviewContext(candidate: reference.candidate, findOne: reference.context,
                                                              existingGarmentID: purchased?.id)))
        } label: {
            Label(purchased == nil ? "I bought this" : "Review purchase", systemImage: "checkmark.circle")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("savedProductBought-\(reference.candidate.id)")
    }
}

// MARK: - Recent store visits

private struct FindOneVisitsSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let visits = Array(app.store.visits.sorted { $0.openedAt > $1.openedAt }.prefix(8))
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Recent store visits", info: "A visit is never treated as a purchase.", editorial: true)
            if visits.isEmpty {
                CollapsibleText("No store visits yet. View at Store records one here so you can come back to it.",
                                summary: "No store visits yet.", threshold: 1, font: .subheadline, topic: "store visits")
                    .cardStyle()
            } else {
                ForEach(visits) { visit in
                    row(visit)
                }
            }
        }
    }

    private func row(_ visit: ShoppingVisit) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top, spacing: Spacing.s) {
                FindOneProductTile(candidate: visit.candidate, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(visit.candidate.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Opened \(visit.candidate.retailer) \(FindOneFormat.relative(visit.openedAt)) · simulated")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)
            if !visit.dismissedPrompt {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: Spacing.xs) {
                        visitPromptText
                        Spacer(minLength: Spacing.xs)
                        visitPromptAdd(visit)
                        visitPromptDismiss(visit)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack(alignment: .top, spacing: Spacing.xs) {
                            visitPromptText
                            Spacer(minLength: Spacing.xs)
                            visitPromptDismiss(visit)
                        }
                        visitPromptAdd(visit)
                    }
                }
                .padding(Spacing.xs)
                .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var visitPromptText: some View {
        Text("Ordered or bought it?")
            .font(.subheadline)
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func visitPromptAdd(_ visit: ShoppingVisit) -> some View {
        Button("Add to closet") {
            app.store.findOneDismissVisitPrompt(visit.id)
            // PurchaseReviewView reuses a record she already confirmed, so this never duplicates.
            app.present(.purchaseReview(PurchaseReviewContext(candidate: visit.candidate, findOne: visit.context)))
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("visitAddToCloset-\(visit.id)")
    }

    private func visitPromptDismiss(_ visit: ShoppingVisit) -> some View {
        Button {
            app.store.findOneDismissVisitPrompt(visit.id)
        } label: {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.secondaryText)
                .minimumHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss")
        .accessibilityHint("Won't ask again for this visit")
        .accessibilityIdentifier("visitDismiss-\(visit.id)")
    }
}

// MARK: - Purchases to finish (reminders, needs details, not arrived)

private struct FindOneFinishSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var arrivalTarget: Garment?
    @State private var descriptionTarget: PurchaseReminder?
    @State private var descriptionText = ""
    @State private var photoTarget: PurchaseReminder?
    @State private var photoItem: PhotosPickerItem?
    @State private var showsPhotoPicker = false

    var body: some View {
        @Bindable var ui = app.findOneUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Purchases to finish", info: "Optional. Missing photos or details never block anything.", editorial: true)
            filterPicker(selection: $ui.finishFilter)
            switch ui.finishFilter {
            case .reminders:
                reminderList(app.store.findOneActiveReminders(), empty: "No open reminders. Reminders only exist if you chose them when saving a purchase.",
                             emptySummary: "No open reminders.")
            case .needsDetails:
                reminderList(app.store.findOneActiveReminders().filter { $0.kind != .arrival },
                             empty: "Nothing needs details. Text-only items are complete enough to use.",
                             emptySummary: "Nothing needs details.")
            case .notArrived:
                notArrivedList
            }
        }
        .confirmationDialog(arrivalTarget.map { "Mark “\($0.displayName)” arrived?" } ?? "",
                            isPresented: Binding(get: { arrivalTarget != nil }, set: { if !$0 { arrivalTarget = nil } }),
                            titleVisibility: .visible,
                            presenting: arrivalTarget) { garment in
            Button("Mark arrived") { markArrived(garment) }
                .accessibilityIdentifier("confirmMarkArrived")
            Button("Not yet", role: .cancel) {}
        } message: { garment in
            Text("It joins your current closet and can appear in today's looks. Its status stays \(garment.availability.label) — change it in Closet if it needs washing or a tailor. No photo is needed.")
        }
        .alert("Add a description", isPresented: Binding(get: { descriptionTarget != nil }, set: { if !$0 { descriptionTarget = nil } })) {
            TextField("e.g. Ruffled neckline", text: $descriptionText)
            Button("Add") { addDescription() }
            Button("Cancel", role: .cancel) { descriptionText = "" }
        } message: {
            Text("Saved as a detail on this item. Your words, no special vocabulary needed.")
        }
        .photosPicker(isPresented: $showsPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item, let reminder = photoTarget else { return }
            Task { @MainActor in
                defer {
                    photoItem = nil
                    photoTarget = nil
                }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let filename = try? PhotoStore.saveOriginal(data) else {
                    app.showToast("That photo couldn't be saved. The item is unchanged.", style: .error)
                    return
                }
                app.store.findOneAttachPhoto(reminder.garmentID, filename: filename)
                app.showToast("Photo added. The original is kept on this device.")
            }
        }
    }

    @ViewBuilder
    private func filterPicker(selection: Binding<FindOneFinishFilter>) -> some View {
        let picker = Picker("Show", selection: selection) {
            ForEach(FindOneFinishFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .accessibilityIdentifier("finishFilterPicker")
        if dynamicTypeSize.isAccessibilitySize {
            picker.pickerStyle(.menu)
        } else {
            picker.pickerStyle(.segmented)
        }
    }

    // MARK: Lists

    @ViewBuilder
    private func reminderList(_ reminders: [PurchaseReminder], empty: String, emptySummary: String) -> some View {
        if reminders.isEmpty {
            emptyText(empty, summary: emptySummary)
        } else {
            ForEach(reminders) { reminder in
                if let garment = app.store.garment(reminder.garmentID) {
                    reminderRow(reminder, garment: garment)
                }
            }
        }
    }

    @ViewBuilder
    private var notArrivedList: some View {
        let items = app.store.findOneNotArrivedPurchases()
        if items.isEmpty {
            emptyText("Nothing is waiting to arrive.")
        } else {
            ForEach(items) { garment in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    garmentSummary(garment, detail: "Ordered \(FindOneFormat.relative(garment.purchaseDate ?? garment.addedAt)) · size \(garment.sizeLabel ?? "Unknown")")
                    // The Not arrived badge above carries the state; what it means is one tap away.
                    HStack(spacing: Spacing.xs) {
                        markArrivedButton(garment)
                        InfoButton("items that haven't arrived", title: "Not arrived",
                                   text: "Not arrived — won't appear in today's looks until you mark it arrived.")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
                .accessibilityElement(children: .contain)
            }
        }
    }

    private func emptyText(_ text: String, summary: String? = nil) -> some View {
        CollapsibleText(text, summary: summary, threshold: 1, font: .subheadline)
            .cardStyle()
    }

    private func garmentSummary(_ garment: Garment, detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            GarmentThumbnail(garment: garment, size: 52, showsStatus: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                BadgeRow(badges: BadgeKind.status(for: garment))
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func reminderRow(_ reminder: PurchaseReminder, garment: Garment) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            garmentSummary(garment, detail: reminderDetail(reminder))
            ActionGroup(moreIdentifier: "reminderMore-\(reminder.id)") {
                reminderAction(reminder, garment: garment)
            } more: {
                Menu {
                    Button("Tomorrow") { postpone(reminder, days: 1) }
                    Button("In 3 days") { postpone(reminder, days: 3) }
                    Button("Next week") { postpone(reminder, days: 7) }
                } label: {
                    Label("Later", systemImage: "clock")
                }
                .accessibilityHint("Choose when to see this reminder again")
                .accessibilityIdentifier("reminderLater-\(reminder.id)")
                Button {
                    app.store.setReminder(reminder.id, status: .dismissed)
                    app.showToast("Reminder dismissed. It won't come back.", style: .info)
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                }
                .accessibilityIdentifier("reminderDismiss-\(reminder.id)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("purchaseReminderRow-\(reminder.id)")
    }

    private func reminderDetail(_ reminder: PurchaseReminder) -> String {
        var text = reminder.kind.label
        if reminder.status == .deferred {
            text += reminder.dueDate.map { " · later, \($0.formatted(date: .abbreviated, time: .omitted))" } ?? " · later"
        } else if let due = reminder.dueDate {
            text += " · \(due.formatted(date: .abbreviated, time: .omitted))"
        }
        return text
    }

    @ViewBuilder
    private func reminderAction(_ reminder: PurchaseReminder, garment: Garment) -> some View {
        switch reminder.kind {
        case .arrival:
            markArrivedButton(garment)
        case .photo:
            Button {
                photoTarget = reminder
                showsPhotoPicker = true
            } label: {
                Label("Add photo", systemImage: "photo.badge.plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("reminderAddPhoto-\(garment.id)")
        case .description:
            Button {
                descriptionText = ""
                descriptionTarget = reminder
            } label: {
                Label("Add description", systemImage: "text.badge.plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("reminderAddDescription-\(garment.id)")
        }
    }

    private func markArrivedButton(_ garment: Garment) -> some View {
        Button {
            arrivalTarget = garment
        } label: {
            Label("Mark arrived", systemImage: "shippingbox")
        }
        .buttonStyle(SuccessButtonStyle())
        .accessibilityHint("Asks you to confirm first")
        .accessibilityIdentifier("reminderMarkArrived-\(garment.id)")
    }

    // MARK: Actions (local only)

    private func markArrived(_ garment: Garment) {
        guard let current = app.store.garment(garment.id), !current.isTrashed, current.ownership == .purchasedConfirmed else {
            app.showToast("That item changed, so nothing was marked.", style: .error)
            return
        }
        app.store.markArrived(garment.id)
        app.showToast("Marked arrived. \(current.displayName) is in your current closet.")
    }

    private func postpone(_ reminder: PurchaseReminder, days: Int) {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now)
        app.store.setReminder(reminder.id, status: .deferred, dueDate: date)
        app.showToast("Okay — later. It stays in this list.", style: .info)
    }

    private func addDescription() {
        guard let reminder = descriptionTarget else { return }
        let text = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        descriptionText = ""
        guard !text.isEmpty else { return }
        app.store.addAnnotation(reminder.garmentID, kind: .detail, text: text, provenance: .userEntered)
        app.store.setReminder(reminder.id, status: .completed)
        app.showToast("Description added.")
    }
}

#Preview("Saved products") {
    NavigationStack {
        SavedProductsView()
    }
    .previewEnvironment()
}
