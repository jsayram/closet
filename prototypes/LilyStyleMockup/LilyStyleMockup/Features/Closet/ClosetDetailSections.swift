import SwiftUI

// MARK: - Shared bits

/// Secondary explanatory line under an action.
struct ClosetNote: View {
    var text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Status badge plus a plain-language sentence about what it means. A sentence
/// that runs past two lines shows `summary` with a "More" control.
struct ClosetStatusLine: View {
    var badge: BadgeKind
    var text: String
    var summary: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            StatusBadge(kind: badge)
            CollapsibleText(text, summary: summary, font: .subheadline, color: Palette.primaryText, topic: "this status")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// An action with its how-it-works note behind an info button beside it.
struct ClosetActionRow<Action: View>: View {
    /// What the note is about; VoiceOver reads "About <topic>".
    var topic: String
    var info: String
    @ViewBuilder var action: () -> Action

    var body: some View {
        HStack(spacing: Spacing.s) {
            action()
            InfoButton(topic, text: info)
        }
    }
}

// MARK: - Status

/// Current ownership/availability with distinctly labelled actions and their consequences.
struct ClosetStatusCard: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    @Binding var pending: ClosetPendingAction?
    var onReviewDeletion: () -> Void

    /// The form draft lives in `ClosetUIState` so it survives the detail moving
    /// between the side pane and a pushed screen when the width changes.
    private var draft: ClosetUnavailableDraft? {
        guard let d = app.closetUI.unavailableDraft, d.garmentID == garment.id else { return nil }
        return d
    }

    private var hasEndDateBinding: Binding<Bool> {
        Binding(
            get: { draft?.hasEndDate ?? false },
            set: { value in if draft != nil { app.closetUI.unavailableDraft?.hasEndDate = value } }
        )
    }

    private var endDateBinding: Binding<Date> {
        Binding(
            get: { draft?.endDate ?? .now },
            set: { value in if draft != nil { app.closetUI.unavailableDraft?.endDate = value } }
        )
    }

    var body: some View {
        CardSection("Status", systemImage: "checklist") {
            stateContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("garmentStatusSection")
    }

    @ViewBuilder private var stateContent: some View {
        if garment.isTrashed {
            trashContent
        } else {
            switch garment.ownership {
            case .noLongerOwned:
                noLongerOwnedContent
            case .wishlisted, .inspiration:
                notOwnedContent
            case .purchasedConfirmed where garment.arrival != .arrived:
                notArrivedContent
            case .owned, .purchasedConfirmed:
                availabilityContent
            }
        }
    }

    // MARK: Trash

    @ViewBuilder private var trashContent: some View {
        let trashedAt = garment.trashedAt ?? .now
        let deadline = ClosetDates.recoveryDeadline(trashedAt: trashedAt)
        let days = ClosetDates.daysLeft(trashedAt: trashedAt)
        ClosetStatusLine(
            badge: .trash,
            text: "Moved to Trash \(trashedAt.formatted(.relative(presentation: .named))). Recoverable until \(deadline.formatted(date: .abbreviated, time: .omitted)), \(days == 1 ? "1 day" : "\(days) days") left. After that it's deleted permanently.",
            summary: "\(ClosetDates.recoveryCaption(trashedAt: trashedAt)), then deleted."
        )
        ClosetActionRow(topic: "Restore", info: "Restoring keeps the same item, its saved looks and suitcase links.") {
            Button {
                app.closetRestore(garment.id)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityHint("Brings it back with the same looks and suitcase links")
            .accessibilityIdentifier("restoreButton")
        }

        ClosetActionRow(topic: "Delete permanently", info: "You'll review exactly what's removed before anything is deleted.") {
            Button(action: onReviewDeletion) {
                Label("Delete permanently…", systemImage: "trash.slash")
            }
            .buttonStyle(DestructiveButtonStyle(fullWidth: true))
            .accessibilityHint("Reviews exactly what is removed before anything is deleted")
            .accessibilityIdentifier("deletePermanentlyButton")
        }
    }

    // MARK: No longer owned

    @ViewBuilder private var noLongerOwnedContent: some View {
        ClosetStatusLine(
            badge: .noLongerOwned,
            text: "You've marked this as no longer owned. Its photos, names and past looks are kept, and it isn't used for styling.",
            summary: "Kept for history. Not used for styling."
        )
        ClosetActionRow(topic: "I own this again",
                        info: "Its last status (\(garment.availability.label)) is kept for you to review. It isn't automatically marked Available.") {
            Button {
                app.closetOwnAgain(garment.id)
            } label: {
                Label("I own this again", systemImage: "arrow.uturn.backward.circle")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityHint("Returns it to your current closet. Its status is kept for you to review")
            .accessibilityIdentifier("ownAgainButton")
        }
    }

    // MARK: Wishlist / inspiration

    @ViewBuilder private var notOwnedContent: some View {
        let isWishlist = garment.ownership == .wishlisted
        ClosetStatusLine(
            badge: isWishlist ? .wishlist : .inspiration,
            text: isWishlist
                ? "On your wishlist: an idea, not something you own. It's never used as one of your clothes."
                : "Saved for inspiration, not something you own. It's never used as one of your clothes.",
            summary: isWishlist ? "An idea, not something you own." : "Inspiration, not something you own."
        )
        if let retailer = garment.sourceRetailer {
            ClosetNote("Seen at \(retailer).")
        }
        ClosetActionRow(topic: "I bought this",
                        info: "Record what you actually bought. Arrival is confirmed separately, and nothing is charged.") {
            Button {
                app.present(.purchaseReview(PurchaseReviewContext(existingGarmentID: garment.id)))
            } label: {
                Label("I bought this", systemImage: "bag")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityHint("Nothing is charged")
            .accessibilityIdentifier("boughtThisButton")
        }

        ClosetActionRow(topic: "I already own this", info: "Moves it into your current closet after you confirm.") {
            Button {
                pending = .markOwned(garment.id)
            } label: {
                Label("I already own this", systemImage: "checkmark.circle")
            }
            .buttonStyle(SuccessButtonStyle(fullWidth: true))
            .accessibilityIdentifier("alreadyOwnButton")
        }
    }

    // MARK: Bought, not arrived

    @ViewBuilder private var notArrivedContent: some View {
        let bought = garment.purchaseDate.map { " on \($0.formatted(date: .abbreviated, time: .omitted))" } ?? ""
        let badge: BadgeKind = garment.arrival == .notArrived ? .notArrived : .arrivalUnknown
        ClosetStatusLine(
            badge: badge,
            text: "Bought\(bought), not here yet. It isn't used for styling until you mark it arrived.",
            summary: "Not here yet, so it isn't styled."
        )
        ClosetActionRow(topic: "Mark arrived",
                        info: "Only when it's actually here. It joins your current closet with status \(garment.availability.label); review it after.") {
            Button {
                app.closetMarkArrived(garment.id)
            } label: {
                Label("Mark arrived", systemImage: "shippingbox")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityHint("Only when it's actually here. Adds it to your current closet")
            .accessibilityIdentifier("markArrivedButton")
        }
        remindersList
    }

    @ViewBuilder private var remindersList: some View {
        let reminders = app.store.reminders.filter { $0.garmentID == garment.id }
        if !reminders.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Text("Reminders")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    InfoButton("Reminders", text: "Private reminders on this device. No notification is scheduled in this prototype.")
                }
                ForEach(reminders) { reminder in
                    reminderRow(reminder)
                }
            }
            .padding(.top, Spacing.xs)
        }
    }

    private func reminderRow(_ reminder: PurchaseReminder) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: reminderIcon(reminder.status))
                .foregroundStyle(reminder.status == .completed ? Palette.success : Palette.secondaryText)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(reminder.kind.label)
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                Text(reminderStatus(reminder))
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: Spacing.xs)
            if reminder.status == .pending, reminder.kind != .arrival {
                Button("Done") {
                    app.store.setReminder(reminder.id, status: .completed)
                }
                .font(.subheadline.weight(.semibold))
                .minimumHitTarget()
                .accessibilityLabel("Mark “\(reminder.kind.label)” done")
            }
        }
    }

    private func reminderIcon(_ status: ReminderStatus) -> String {
        switch status {
        case .completed: "checkmark.circle.fill"
        case .dismissed: "xmark.circle"
        case .deferred: "clock"
        case .pending: "circle"
        }
    }

    private func reminderStatus(_ reminder: PurchaseReminder) -> String {
        switch reminder.status {
        case .pending:
            if let due = reminder.dueDate { return "To do · \(due.formatted(date: .abbreviated, time: .omitted))" }
            return reminder.kind == .arrival ? "To do. Mark arrived above when it's here" : "To do"
        case .deferred: return "Later"
        case .completed: return "Done"
        case .dismissed: return "Dismissed"
        }
    }

    // MARK: Current clothes (availability)

    @ViewBuilder private var availabilityContent: some View {
        switch garment.availability {
        case .available:
            ClosetStatusLine(badge: .custom("Available", "checkmark.circle"), text: "Available for new looks.")
            ClosetActionRow(topic: "Mark dirty", info: "When it needs washing. Wearing it doesn't mark it dirty automatically.") {
                Button {
                    app.closetMarkDirty(garment.id)
                } label: {
                    Label("Mark dirty", systemImage: BadgeKind.dirty.systemImage)
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityHint("Leaves it out of new looks until you mark it clean")
                .accessibilityIdentifier("markDirtyButton")
            }
            unavailableControls(isChange: false)

        case .dirty:
            ClosetStatusLine(badge: .dirty, text: "Left out of new looks until you mark it clean.")
            ClosetActionRow(topic: "Mark clean", info: "Using it once doesn't clean it. Marking it clean sets it to Available, with Undo.") {
                Button {
                    app.closetMarkClean(garment.id)
                } label: {
                    Label("Mark clean", systemImage: "checkmark.circle")
                }
                .buttonStyle(SuccessButtonStyle(fullWidth: true))
                .accessibilityHint("Sets it to Available. You can undo")
                .accessibilityIdentifier("markCleanButton")
            }

        case .unavailable:
            ClosetStatusLine(badge: .unavailable, text: unavailableText, summary: unavailableSummary)
            ClosetActionRow(topic: "Mark available", info: "Sets it to Available. Ownership and arrival don't change.") {
                Button {
                    app.closetMarkAvailable(garment.id)
                } label: {
                    Label("Mark available", systemImage: "checkmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityIdentifier("markAvailableButton")
            }
            unavailableControls(isChange: true)

        case .archived:
            ClosetStatusLine(badge: .archived, text: "Put away. Ownership, photos and history are kept; it's left out of new looks.",
                             summary: "Put away and left out of new looks.")
            ClosetActionRow(topic: "Unarchive",
                            info: "Only the archive restriction is removed. Its earlier status (\((garment.statusBeforeArchive ?? .available).label)) comes back. It isn't marked clean.") {
                Button {
                    app.closetUnarchive(garment.id)
                } label: {
                    Label("Unarchive", systemImage: "archivebox")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityHint("Removes only the archive restriction")
                .accessibilityIdentifier("unarchiveButton")
            }
        }
    }

    private var unavailableSummary: String {
        if let until = garment.unavailableUntil {
            return "Unavailable until \(until.formatted(date: .abbreviated, time: .omitted))."
        }
        return "Unavailable, no end date."
    }

    private var unavailableText: String {
        var text = "Unavailable"
        if let until = garment.unavailableUntil {
            text += " until \(until.formatted(date: .abbreviated, time: .omitted))"
        } else {
            text += ", no end date"
        }
        text += ". It's left out of new looks."
        if !garment.notes.isEmpty { text += " Note: \(garment.notes)" }
        return text
    }

    @ViewBuilder private func unavailableControls(isChange: Bool) -> some View {
        if let draft {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Toggle("Until a date", isOn: hasEndDateBinding)
                    .font(.subheadline)
                    .tint(Palette.primaryAction)
                if draft.hasEndDate {
                    DatePicker("Back on", selection: endDateBinding,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                        .font(.subheadline)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.s) { unavailableFormButtons(isChange: isChange) }
                    VStack(spacing: Spacing.xs) { unavailableFormButtons(isChange: isChange) }
                }
            }
            .padding(Spacing.s)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        } else {
            HStack(spacing: Spacing.s) {
                Button {
                    let defaultEnd = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
                    if isChange {
                        app.closetUI.unavailableDraft = ClosetUnavailableDraft(
                            garmentID: garment.id,
                            hasEndDate: garment.unavailableUntil != nil,
                            endDate: garment.unavailableUntil ?? defaultEnd
                        )
                    } else {
                        app.closetUI.unavailableDraft = ClosetUnavailableDraft(garmentID: garment.id, hasEndDate: true, endDate: defaultEnd)
                    }
                } label: {
                    Label(isChange ? "Change date…" : "Mark unavailable…", systemImage: "calendar.badge.clock")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                .accessibilityIdentifier(isChange ? "changeUnavailableDateButton" : "markUnavailableButton")
                if !isChange {
                    InfoButton("Mark unavailable", text: "For example at the tailor or lent to a friend. You can say when it's back.")
                }
            }
        }
    }

    @ViewBuilder private func unavailableFormButtons(isChange: Bool) -> some View {
        Button(isChange ? "Save date" : "Mark unavailable") {
            let until = (draft?.hasEndDate ?? false) ? draft?.endDate : nil
            app.closetUI.unavailableDraft = nil
            app.closetMarkUnavailable(garment.id, until: until)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier("confirmUnavailableButton")
        Button("Cancel") {
            app.closetUI.unavailableDraft = nil
        }
        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
    }
}

// MARK: - Style with it

/// Starting piece for Style Me (only when eligible in the working source) and Ask another stylist.
struct ClosetStylingCard: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    @Binding var pending: ClosetPendingAction?

    var body: some View {
        let eligibility = app.store.eligibility(of: garment, scope: app.workingScope)
        let isCurrent = app.style.draft.startingItemID == garment.id
        CardSection("Style with it", subtitle: "Source: \(app.workingScopeName)", systemImage: "sparkles") {
            if isCurrent {
                currentStartingPiece
            } else if eligibility.isEligible {
                HStack(spacing: Spacing.s) {
                    Button {
                        app.closetUseAsStartingPiece(garment.id, forThisRequestOnly: false)
                    } label: {
                        Label("Use as starting piece", systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityHint("Sets it in Style Me. Nothing is styled until you tap Style Me")
                    .accessibilityIdentifier("useAsStartingPieceButton")
                    InfoButton("Use as starting piece", text: "Sets it in Style Me. Nothing is styled until you tap Style Me.")
                }
                askRow(fullWidth: true) { EmptyView() }
            } else {
                // The blocker stays on screen in short form; the rest opens in place.
                CollapsibleText(app.closetIneligibilityExplanation(garment, issues: eligibility.issues), collapsedLines: 2, topic: "why it can't start a look")
                if eligibility.canOverride {
                    askRow(fullWidth: false) {
                        Button {
                            pending = .useForThisRequest(garment.id)
                        } label: {
                            Label("Use for this request only…", systemImage: "checkmark.circle.badge.questionmark")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("useForThisRequestButton")
                    }
                } else {
                    askRow(fullWidth: true) { EmptyView() }
                }
            }
        }
    }

    @ViewBuilder private var currentStartingPiece: some View {
        Label("This is your starting piece in Style Me.", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.success)
        if app.style.draft.overrideIDs.contains(garment.id) {
            ClosetNote("Using it for this request only. Its status hasn't changed.")
        }
        askRow(fullWidth: false) {
            Button {
                app.select(.styleMe)
            } label: {
                Label("Open Style Me", systemImage: "sparkles")
            }
            .buttonStyle(SecondaryButtonStyle())
        } more: {
            Button("Remove as starting piece", systemImage: "xmark.circle") {
                app.style.draft.startingItemID = nil
                app.style.draft.overrideIDs.remove(garment.id)
            }
        }
    }

    /// At most two buttons side by side, with Ask another stylist as the second one and
    /// its note behind the info button. Anything else goes in the More menu.
    private func askRow<Leading: View, MoreItems: View>(
        fullWidth: Bool,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder more: () -> MoreItems
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            ActionGroup(moreIdentifier: "stylingMoreButton") {
                leading()
                Button {
                    app.present(.askStylist(.garments([garment.id])))
                } label: {
                    Label("Ask another stylist", systemImage: "person.2")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: fullWidth))
                .accessibilityHint("Nothing is sent")
                .accessibilityIdentifier("askStylistGarmentButton")
            } more: {
                more()
            }
            InfoButton("Ask another stylist",
                       text: "Builds a picture and an editable prompt you can copy or share yourself. Nothing is sent.")
                .frame(minHeight: HitTarget.minimum)
        }
    }

    private func askRow<Leading: View>(fullWidth: Bool, @ViewBuilder leading: () -> Leading) -> some View {
        askRow(fullWidth: fullWidth, leading: leading, more: { EmptyView() })
    }
}

// MARK: - Facts

struct ClosetFactsCard: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    var onEdit: () -> Void

    var body: some View {
        let ui = app.closetUI
        CardSection("About this item", info: "Anything not confirmed stays Unknown.", systemImage: "list.bullet.rectangle") {
            // The header above already shows category, type, color, brand and size,
            // so the card opens with the facts that aren't on screen yet.
            InfoRow(title: "Fabric", value: garment.fabric ?? "Unknown", valueIsUnknown: garment.fabric == nil)
            InfoRow(title: "Dressiness", value: garment.formality.label)
            InfoRow(title: "Seasons", value: seasonsText)
            if !garment.notes.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notes")
                        .foregroundStyle(Palette.secondaryText)
                    CollapsibleText(garment.notes, font: .subheadline, color: Palette.primaryText, topic: "notes")
                }
                .font(.subheadline)
            }
            DetailsDisclosure("More facts", count: moreFactsCount,
                              isExpanded: Binding(get: { ui.factsExpanded }, set: { ui.factsExpanded = $0 }),
                              identifier: "garmentMoreFacts") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    InfoRow(title: "Category", value: garment.category.label, valueIsUnknown: garment.category == .unknown)
                    InfoRow(title: "Type", value: garment.kind.label, valueIsUnknown: garment.kind == .unknown)
                    InfoRow(title: "Color", value: garment.colorLabel, valueIsUnknown: garment.color == nil)
                    InfoRow(title: "Brand", value: garment.brand ?? "Unknown", valueIsUnknown: garment.brand == nil)
                    InfoRow(title: "Size", value: garment.sizeLabel ?? "Unknown", valueIsUnknown: garment.sizeLabel == nil)
                    InfoRow(title: "Warmth", value: warmthText)
                    InfoRow(title: "Ownership", value: ownershipText)
                    if let retailer = garment.sourceRetailer {
                        InfoRow(title: "From", value: retailer)
                    }
                    if let purchased = garment.purchaseDate {
                        InfoRow(title: "Bought", value: purchased.formatted(date: .abbreviated, time: .omitted))
                    }
                    InfoRow(title: "Added", value: garment.addedAt.formatted(date: .abbreviated, time: .omitted))
                }
            }
            Button(action: onEdit) {
                Label("Edit details", systemImage: "pencil")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .keyboardShortcut("e", modifiers: .command)
            .accessibilityHint("Edit category, color, brand, size and notes")
            .accessibilityIdentifier("editDetailsButton")
        }
    }

    private var moreFactsCount: Int {
        8 + (garment.sourceRetailer == nil ? 0 : 1) + (garment.purchaseDate == nil ? 0 : 1)
    }

    private var seasonsText: String {
        if garment.seasons.count == Season.allCases.count { return "All seasons" }
        if garment.seasons.isEmpty { return "Unknown" }
        return Season.allCases.filter { garment.seasons.contains($0) }.map(\.label).joined(separator: ", ")
    }

    private var warmthText: String {
        switch garment.warmth {
        case ...0: "Light"
        case 1: "Medium"
        case 2: "Warm"
        default: "Very warm"
        }
    }

    private var ownershipText: String {
        switch garment.ownership {
        case .purchasedConfirmed: "Bought · \((garment.arrival ?? .unknown).label)"
        default: garment.ownership.label
        }
    }
}

// MARK: - Suitcase membership

/// Explicit Add/Remove per suitcase. Membership is a link, never a copy.
struct ClosetSuitcaseMembershipCard: View {
    @Environment(AppModel.self) private var app
    var garment: Garment

    var body: some View {
        let active = app.store.activeSuitcases()
        let archivedLinks = app.store.suitcases(containing: garment.id).filter(\.isArchived)
        let canAdd = garment.isOwnedOrPurchased
        CardSection("Suitcases", info: "Same garment in every suitcase — no copies.", systemImage: "suitcase") {
            if active.isEmpty, archivedLinks.isEmpty {
                ClosetNote("No suitcases yet. Create one for a trip or another place you keep clothes.")
                Button {
                    app.push(.suitcases)
                } label: {
                    Label("Manage suitcases", systemImage: "suitcase")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            }
            // Suitcases it's already in come first; the rest of a long list sits behind a details row.
            let linked = active.filter { app.store.membership(garmentID: garment.id, suitcaseID: $0.id) != nil }
            let unlinked = active.filter { app.store.membership(garmentID: garment.id, suitcaseID: $0.id) == nil }
            let shownUnlinked = unlinked.prefix(max(0, Self.visibleRows - linked.count - archivedLinks.count))
            let hidden = unlinked.dropFirst(shownUnlinked.count)
            ForEach(linked) { suitcase in
                row(suitcase, archived: false, canAdd: canAdd)
            }
            ForEach(archivedLinks) { suitcase in
                row(suitcase, archived: true, canAdd: false)
            }
            ForEach(shownUnlinked) { suitcase in
                row(suitcase, archived: false, canAdd: canAdd)
            }
            if !hidden.isEmpty {
                DetailsDisclosure("Other suitcases", count: hidden.count,
                                  isExpanded: Binding(get: { app.closetUI.otherSuitcasesExpanded }, set: { app.closetUI.otherSuitcasesExpanded = $0 }),
                                  identifier: "garmentMoreSuitcases") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(hidden) { suitcase in
                            row(suitcase, archived: false, canAdd: canAdd)
                        }
                    }
                }
            }
            if !canAdd, !active.isEmpty {
                ClosetNote(garment.isTrashed
                           ? "Restore it from Trash to link it to a suitcase."
                           : "Suitcases hold clothes you own, so this item can't be added.")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("garmentSuitcasesSection")
    }

    /// Rows shown before the rest fold behind "Other suitcases".
    private static let visibleRows = 3

    private func row(_ suitcase: Suitcase, archived: Bool, canAdd: Bool) -> some View {
        let isMember = app.store.membership(garmentID: garment.id, suitcaseID: suitcase.id) != nil
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.s) {
                rowLabel(suitcase, isMember: isMember, archived: archived)
                Spacer(minLength: Spacing.xs)
                rowButton(suitcase, isMember: isMember, canAdd: canAdd)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                rowLabel(suitcase, isMember: isMember, archived: archived)
                rowButton(suitcase, isMember: isMember, canAdd: canAdd)
            }
        }
    }

    private func rowLabel(_ suitcase: Suitcase, isMember: Bool, archived: Bool) -> some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: isMember ? "suitcase.fill" : "suitcase")
                .foregroundStyle(isMember ? Palette.primaryAction : Palette.secondaryText)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(suitcase.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text(statusText(suitcase, isMember: isMember, archived: archived))
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statusText(_ suitcase: Suitcase, isMember: Bool, archived: Bool) -> String {
        let count = app.store.memberIDs(of: suitcase.id).count
        let items = count == 1 ? "1 item" : "\(count) items"
        if archived { return "Linked · archived suitcase · \(items)" }
        return (isMember ? "Linked" : "Not linked") + " · \(items)"
    }

    @ViewBuilder private func rowButton(_ suitcase: Suitcase, isMember: Bool, canAdd: Bool) -> some View {
        if isMember {
            Button {
                app.closetRemoveFromSuitcase(garment.id, suitcaseID: suitcase.id)
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Remove from \(suitcase.name)")
            .accessibilityHint("Removes only the link. It stays in Main Closet")
            .accessibilityIdentifier("removeFromSuitcase-\(suitcase.id)")
        } else if canAdd {
            Button {
                app.closetAddToSuitcase(garment.id, suitcaseID: suitcase.id)
            } label: {
                Label("Add", systemImage: "plus.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Add to \(suitcase.name)")
            .accessibilityHint("Links the same garment. No copy is made")
            .accessibilityIdentifier("addToSuitcase-\(suitcase.id)")
        }
    }
}

// MARK: - Saved looks

struct ClosetSavedLooksCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var typeSize
    var garment: Garment

    var body: some View {
        let looks = app.store.savedOutfits.filter { $0.garmentIDs.contains(garment.id) }
        let previewCount = app.store.previews.filter { $0.snapshotPieces.contains { $0.garmentID == garment.id } }.count
        CardSection("In saved looks", subtitle: looks.isEmpty ? nil : (looks.count == 1 ? "1 look" : "\(looks.count) looks"), systemImage: "bookmark") {
            if looks.isEmpty {
                ClosetNote("Not in any saved looks yet.")
            }
            ForEach(looks.prefix(Self.visibleLooks)) { look in
                lookButton(look)
            }
            if looks.count > Self.visibleLooks {
                DetailsDisclosure("More looks", count: looks.count - Self.visibleLooks, identifier: "garmentMoreLooks") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ForEach(looks.dropFirst(Self.visibleLooks)) { look in
                            lookButton(look)
                        }
                    }
                }
            }
            if previewCount > 0 {
                HStack(spacing: Spacing.xxs) {
                    Text(previewCount == 1 ? "Also in 1 simulated preview" : "Also in \(previewCount) simulated previews")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                    InfoButton("retained previews",
                               title: "Retained previews",
                               text: previewCount == 1
                                   ? "Also in 1 retained simulated preview. Previews keep the pieces they were made with."
                                   : "Also in \(previewCount) retained simulated previews. Previews keep the pieces they were made with.")
                    Spacer(minLength: 0)
                }
            }
        }
    }

    /// Looks shown before the rest fold behind "More looks".
    private static let visibleLooks = 3

    private func lookButton(_ look: Outfit) -> some View {
        Button {
            app.push(.outfit(look.id))
        } label: {
            lookRow(look)
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(look.title)
        .accessibilityValue(([look.occasion?.label] + [look.isFavorite ? "Favorite" : nil]).compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Opens the saved look")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("garmentLook-\(look.id)")
    }

    @ViewBuilder private func lookRow(_ look: Outfit) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.s))
        layout {
            // One small flat-lay with every piece, like look thumbnails elsewhere.
            OutfitFlatLayView(pieces: look.pieces, compact: true, animateIn: false)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.imageWell))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(look.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Spacing.xxs) {
                    if look.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(Palette.primaryAction)
                    }
                    Text(look.occasion?.label ?? look.lane.title)
                        .foregroundStyle(Palette.secondaryText)
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(Spacing.xs)
        .frame(minHeight: HitTarget.minimum)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
    }
}

// MARK: - Lifecycle (archive / no longer own / Trash)

/// Three distinct choices with different labels and consequences.
struct ClosetLifecycleCard: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    @Binding var pending: ClosetPendingAction?

    var body: some View {
        let impact = app.store.deletionImpact(of: garment.id)
        let canArchive = garment.isCurrentlyOwned && garment.availability != .archived
        let canDisown = garment.isOwnedOrPurchased
        CardSection("Put away or remove", systemImage: "archivebox") {
            if canArchive || canDisown {
                // Two choices stay visible; Trash sits in the menu and still asks first.
                ActionGroup(moreIdentifier: "garmentLifecycleMore") {
                    if canArchive {
                        Button {
                            app.closetArchive(garment.id)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityHint("Puts it away. Keeps ownership and history")
                        .accessibilityIdentifier("archiveButton")
                    }
                    if canDisown {
                        Button {
                            pending = .noLongerOwn(garment.id)
                        } label: {
                            Label("No longer own…", systemImage: "arrow.uturn.left.circle")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityHint("Asks you to confirm. Keeps photos, names and past looks")
                        .accessibilityIdentifier("noLongerOwnButton")
                    }
                } more: {
                    Button("Move to Trash…", systemImage: "trash", role: .destructive) {
                        pending = .moveToTrash(garment.id)
                    }
                    .accessibilityIdentifier("trashButton")
                }
            } else {
                Button {
                    pending = .moveToTrash(garment.id)
                } label: {
                    Label("Move to Trash…", systemImage: "trash")
                }
                .buttonStyle(DestructiveButtonStyle(fullWidth: true))
                .accessibilityHint("Asks you to confirm. Recoverable for 30 days")
                .accessibilityIdentifier("trashButton")
            }
            DetailsDisclosure("What each choice does", count: 1 + (canArchive ? 1 : 0) + (canDisown ? 1 : 0),
                              identifier: "garmentLifecycleDetails") {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    if canArchive {
                        explanation("Archive", "Put it away. Keeps ownership, photos and history; left out of new looks until you unarchive it.")
                    }
                    if canDisown {
                        explanation("No longer own", "You donated, sold or gave it away. Keeps photos, names and past looks; left out of today's styling.")
                    }
                    explanation("Move to Trash", "Hides it now. Recoverable for 30 days, then deleted permanently. If it's deleted, \(ClosetImpactText.summary(looks: impact.outfits.count, previews: impact.previews.count, suitcases: impact.suitcases.count))")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("garmentLifecycleSection")
    }

    private func explanation(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
            ClosetNote(detail)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Permanent deletion review

/// Scoped review of what a permanent deletion removes, then a destructive confirmation.
struct ClosetDeletionReviewSheet: View {
    var garmentID: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        NavigationStack {
            Group {
                if let garment = app.store.garment(garmentID) {
                    review(garment)
                } else {
                    EmptyStateView(title: "Deleted", message: "This item has been deleted permanently.", systemImage: "checkmark.circle")
                        .padding(.top, Spacing.xxl)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .themedScreenBackground()
            .navigationTitle("Delete permanently")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }

    private func review(_ garment: Garment) -> some View {
        let impact = app.store.deletionImpact(of: garment.id)
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                HStack(spacing: Spacing.s) {
                    GarmentThumbnail(garment: garment, size: 72, showsStatus: false)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(garment.displayName)
                            .font(.editorial(.title3))
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        if let trashedAt = garment.trashedAt {
                            Text(ClosetDates.recoveryCaption(trashedAt: trashedAt))
                                .font(.footnote)
                                .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }

                group(title: "Removed from this device", systemImage: "trash") {
                    bullet(garment.photoFilename != nil ? "Its picture and your photo file" : "Its picture")
                    bullet("Its name, \(countText(garment.aliases.count, "other name")) and \(countText(garment.details.count, "detail"))")
                    bullet("Category, color, brand, size, notes and other facts")
                    bullet("Purchase reminders and undo history")
                }

                group(title: "Saved looks (\(impact.outfits.count))", systemImage: "rectangle.on.rectangle") {
                    if impact.outfits.isEmpty {
                        bullet("No saved looks include it.")
                    } else {
                        ClosetNote("These looks keep their layout. The piece becomes a “Deleted item” placeholder you can replace by hand.")
                        names(impact.outfits.map(\.title), noun: "looks")
                    }
                }

                group(title: "Retained previews to purge (\(impact.previews.count))", systemImage: "photo.stack") {
                    if impact.previews.isEmpty {
                        bullet("No retained previews include it.")
                    } else {
                        ClosetNote("These simulated previews show this item, so they're removed with it rather than kept as an old picture.")
                        names(impact.previews.map { "\($0.title) · \($0.createdAt.formatted(date: .abbreviated, time: .omitted))" }, noun: "previews")
                    }
                }

                group(title: "Suitcase links (\(impact.suitcases.count))", systemImage: "suitcase") {
                    if impact.suitcases.isEmpty {
                        bullet("Not linked to any suitcase.")
                    } else {
                        ClosetNote("Only the links are removed. The suitcases and their other clothes stay.")
                        names(impact.suitcases.map(\.name), noun: "suitcases")
                    }
                }

                SimulationNotice(text: "Demo: this deletes fictional data on this device only. Nothing is sent anywhere, and copies you exported yourself can't be erased by the app.",
                                 label: "Demo", summary: "Fictional data, this device only")

                Button {
                    confirming = true
                } label: {
                    Label("Delete permanently", systemImage: "trash.slash")
                }
                .buttonStyle(DestructiveButtonStyle(fullWidth: true))
                .accessibilityIdentifier("confirmDeletePermanentlyButton")

                Button {
                    app.closetRestore(garment.id)
                    dismiss()
                } label: {
                    Label("Restore instead", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            }
            .padding(Spacing.m)
            .readableWidth(640)
        }
        .confirmationDialog("Delete “\(garment.displayName)” permanently?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) {
                app.closetDeletePermanently(garmentID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func countText(_ count: Int, _ noun: String) -> String {
        count == 1 ? "1 \(noun)" : "\(count) \(noun)s"
    }

    private func group<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    /// The first few names stay on screen under the group's count; the rest open in place.
    @ViewBuilder private func names(_ items: [String], noun: String) -> some View {
        let visible = 3
        ForEach(Array(items.prefix(visible).enumerated()), id: \.offset) { _, item in
            bullet(item)
        }
        if items.count > visible {
            DetailsDisclosure("More \(noun)", count: items.count - visible) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(Array(items.dropFirst(visible).enumerated()), id: \.offset) { _, item in
                        bullet(item)
                    }
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text("•")
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
    }
}

#Preview("Deletion review") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ClosetDeletionReviewSheet(garmentID: "g-gray-leggings").previewEnvironment()
        }
        .previewEnvironment()
}
