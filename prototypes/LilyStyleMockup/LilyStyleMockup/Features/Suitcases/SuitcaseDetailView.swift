import SwiftUI

/// One suitcase: its source state, linked garments and membership actions.
/// Removing a garment only removes the link; the garment stays in Main Closet.
struct SuitcaseDetailView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var suitcaseID: String
    /// True when shown beside the Suitcases list instead of pushed on its own.
    var embedded: Bool

    @State private var isOnScreen = false
    @State private var lifecycle = SuitcasesLifecycleState()
    @State private var isDropTargeted = false

    init(suitcaseID: String, embedded: Bool = false) {
        self.suitcaseID = suitcaseID
        self.embedded = embedded
    }

    var body: some View {
        let suitcase = app.store.suitcase(suitcaseID)
        GeometryReader { geo in
            let width = WidthClass(width: geo.size.width)
            ScrollView {
                if let suitcase {
                    content(suitcase, width: width, available: min(geo.size.width, width == .wide ? 1080 : 860) - Spacing.m * 2)
                } else {
                    missingState
                }
            }
        }
        .themedScreenBackground()
        .modifier(SuitcasesTitleModifier(title: suitcase?.name ?? "Suitcase", enabled: !embedded))
        .onAppear { isOnScreen = true }
        .onDisappear { isOnScreen = false }
        // Kept in `suitcasesUI` so the picker reopens after a resize or shell switch.
        .sheet(isPresented: Binding(
            get: { isOnScreen && app.suitcasesUI.isPickerPresented && app.suitcasesUI.pickerSuitcaseID == suitcaseID },
            set: { if !$0, isOnScreen { app.suitcasesUI.isPickerPresented = false } }
        )) {
            SuitcasesMembershipPicker(suitcaseID: suitcaseID)
                .environment(app)
                .tint(Palette.primaryAction)
        }
        .modifier(SuitcasesLifecycleModifier(state: $lifecycle) { _ in
            if embedded {
                app.suitcasesUI.selection = nil
            } else {
                dismiss()
            }
        })
    }

    // MARK: Content

    private func content(_ suitcase: Suitcase, width: WidthClass, available: CGFloat) -> some View {
        let members = app.store.suitcasesMembers(of: suitcase.id)
        return VStack(alignment: .leading, spacing: Spacing.l) {
            header(suitcase, members: members)

            if suitcase.isArchived {
                InlineBanner(style: .caution, title: "Archived",
                             message: "Hidden from source choices. Its links are kept and its garments weren't changed. Unarchive it to add garments or use it as a source.",
                             summary: "Hidden from source choices. Links are kept.")
            }

            if let outcome = app.suitcasesUI.lastAddOutcome, outcome.suitcaseID == suitcase.id {
                InlineBanner(style: outcome.addedCount > 0 ? .success : .info, title: outcome.title, message: outcome.detail,
                             actionTitle: "Dismiss") {
                    app.suitcasesUI.lastAddOutcome = nil
                }
                .accessibilityIdentifier("membershipAddOutcome")
            }

            if members.isEmpty {
                emptyState(suitcase)
            } else {
                memberGrid(suitcase, members: members, width: width, available: available)
            }

            manageCard(suitcase)

            CollapsibleText(SuitcasesText.membershipNote, summary: "Links only. Nothing is copied or moved.",
                            threshold: 1, topic: "suitcase membership")
        }
        .padding(Spacing.m)
        .readableWidth(width == .wide ? 1080 : 860)
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.primaryAction, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .padding(Spacing.xs)
                    .allowsHitTesting(false)
            }
        }
        .dropDestination(for: String.self) { items, _ in
            handleDrop(items, suitcase)
        } isTargeted: { targeted in
            isDropTargeted = targeted && !suitcase.isArchived
        }
    }

    private func header(_ suitcase: Suitcase, members: [Garment]) -> some View {
        let dirty = app.store.dirtyGarments(scope: .suitcase(suitcase.id)).count
        let shared = members.filter { !app.store.suitcasesOtherActive(containing: $0.id, excluding: suitcase.id).isEmpty }.count
        let isCurrent = app.suitcasesIsCurrentSource(.suitcase(suitcase.id))
        var summary = [SuitcasesText.count(members.count, "garment")]
        if dirty > 0 { summary.append("\(dirty) dirty") }
        if shared > 0 { summary.append("\(shared) shared") }

        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(suitcase.name)
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(summary.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer(minLength: 0)
                SuitcasesMoreMenu(suitcase: suitcase, lifecycle: $lifecycle) {
                    unarchive(suitcase)
                }
            }

            if suitcase.isArchived {
                StatusBadge(kind: .archived)
            } else if isCurrent {
                HStack(spacing: Spacing.xxs) {
                    SuitcasesTag(text: "Current source", systemImage: "checkmark.circle.fill")
                    InfoButton("your current source", title: "Current source",
                               text: "Style Me and Closet use only these garments. Remembered next time you open the app.")
                }
            } else {
                Text("Not your current source. You're using \(app.workingScopeName).")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !suitcase.isArchived, !isCurrent {
                Button {
                    app.suitcasesUseAsSource(.suitcase(suitcase.id))
                } label: {
                    Label("Use as source", systemImage: "checkmark.circle")
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 360, alignment: .leading)
                .accessibilityLabel("Use \(suitcase.name) as source")
                .accessibilityHint("Style Me and Closet will use only its garments. Remembered across launches.")
                .accessibilityIdentifier("useAsSourceButton")
            }

            // One row: the two things she does most here. Rename, archive and delete
            // are in the menu at the top of this card.
            ActionGroup {
                if suitcase.isArchived {
                    Button {
                        unarchive(suitcase)
                    } label: {
                        Label("Unarchive", systemImage: "tray.and.arrow.up")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("unarchiveSuitcaseButton")
                } else {
                    if !members.isEmpty {
                        Button {
                            openPicker(suitcase)
                        } label: {
                            Label("Add garments", systemImage: "plus")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .keyboardShortcut("a", modifiers: [.command, .shift])
                        .accessibilityHint("Opens Add from Main Closet. Your styling source won't change.")
                        .accessibilityIdentifier("addGarmentsButton")
                    }
                    Button {
                        openLaundry(suitcase)
                    } label: {
                        Label(dirty > 0 ? "Laundry · \(dirty) dirty" : "Laundry", systemImage: "washer")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel(dirty > 0 ? "Laundry for this suitcase, \(dirty) dirty" : "Laundry for this suitcase")
                    .accessibilityIdentifier("suitcaseLaundryButton")
                }
            }
        }
        .cardStyle()
    }

    private func memberGrid(_ suitcase: Suitcase, members: [Garment], width: WidthClass, available: CGFloat) -> some View {
        let preferred: CGFloat = dynamicTypeSize.isAccessibilitySize ? 280 : (width == .compact ? 150 : 180)
        // Clamp to the space we have so a narrow embedded pane never clips cards.
        let minimum = min(preferred, max(available, 140))
        return VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("In this suitcase", info: "Tap a garment for details. Removing one only removes the link.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: Spacing.s, alignment: .top)],
                      alignment: .leading, spacing: Spacing.s) {
                ForEach(members) { garment in
                    SuitcasesMemberCard(
                        garment: garment,
                        suitcase: suitcase,
                        otherSuitcases: app.store.suitcasesOtherActive(containing: garment.id, excluding: suitcase.id),
                        onOpen: { app.suitcasesPush(.garment(garment.id)) },
                        onRemove: { remove(garment, from: suitcase) }
                    )
                }
            }
        }
    }

    private func emptyState(_ suitcase: Suitcase) -> some View {
        let isCurrent = app.suitcasesIsCurrentSource(.suitcase(suitcase.id))
        let others = app.store.activeSuitcases().filter { $0.id != suitcase.id }
        return VStack(spacing: Spacing.s) {
            Image(systemName: "suitcase")
                .font(.largeTitle)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            Text("\(suitcase.name) is empty")
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            CollapsibleText(isCurrent
                            ? "That's okay. It stays your source, and Style Me won't pull in clothes from outside it. Add garments from Main Closet, or choose another source."
                            : "Add garments from Main Closet whenever you're ready. Nothing is copied, and your source stays the same.",
                            summary: isCurrent ? "It stays your source. Nothing is pulled in from outside." : "Add garments from Main Closet when you're ready.",
                            font: .subheadline, centered: true, topic: "this empty suitcase")

            if !suitcase.isArchived {
                FlowLayout(spacing: Spacing.xs) {
                    Button {
                        openPicker(suitcase)
                    } label: {
                        Label("Add garments", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    .accessibilityHint("Opens Add from Main Closet. Your styling source won't change.")
                    .accessibilityIdentifier("addGarmentsButton")

                    if isCurrent {
                        Menu {
                            Button {
                                app.suitcasesUseAsSource(.mainCloset)
                            } label: {
                                Label("Main Closet", systemImage: "cabinet")
                            }
                            ForEach(others) { other in
                                Button {
                                    app.suitcasesUseAsSource(.suitcase(other.id))
                                } label: {
                                    Label("\(other.name) · \(app.store.memberIDs(of: other.id).count)", systemImage: "suitcase")
                                }
                            }
                        } label: {
                            Label("Choose another source", systemImage: "arrow.left.arrow.right")
                                .modifier(SuitcasesOutlinedLabel(minHeight: 50))
                        }
                        .accessibilityHint("Pick Main Closet or another suitcase")
                        .accessibilityIdentifier("chooseAnotherSourceMenu")
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .cardStyle(padding: Spacing.l)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("emptySuitcaseState")
    }

    /// Rename, archive and delete, closed until she opens it. Delete sits in the
    /// More menu and still asks first.
    private func manageCard(_ suitcase: Suitcase) -> some View {
        DetailsDisclosure("Manage suitcase", summary: suitcase.isArchived ? "rename or delete" : "rename, archive or delete",
                          systemImage: "slider.horizontal.3", identifier: "manageSuitcaseToggle") {
            VStack(alignment: .leading, spacing: Spacing.s) {
                ActionGroup(moreIdentifier: "manageSuitcaseMore") {
                    Button {
                        lifecycle.rename = suitcase
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Rename \(suitcase.name)")
                    .accessibilityIdentifier("renameSuitcaseButton")

                    if !suitcase.isArchived {
                        Button {
                            lifecycle.archive = suitcase
                        } label: {
                            Label("Archive…", systemImage: "archivebox")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Archive \(suitcase.name)")
                        .accessibilityHint("Asks first. Keeps its links and hides it from source choices.")
                        .accessibilityIdentifier("archiveSuitcaseButton")
                    }
                } more: {
                    Button("Delete suitcase…", systemImage: "trash", role: .destructive) {
                        lifecycle.delete = suitcase
                    }
                    .accessibilityIdentifier("deleteSuitcaseButton")
                }
                Text(suitcase.isArchived ? "Archived suitcases keep their links." : "Archiving hides it from source choices and keeps its links.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Deleting removes the suitcase and its links only. Garments, saved looks and pictures stay.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .cardStyle()
    }

    private var missingState: some View {
        EmptyStateView(
            title: "This suitcase is gone",
            message: "It was deleted. Every garment is still in Main Closet, and saved looks keep a “Former suitcase” label.",
            systemImage: "suitcase",
            actionTitle: embedded ? nil : "Back to Suitcases",
            action: embedded ? nil : { dismiss() }
        )
        .padding(.top, Spacing.xl)
    }

    // MARK: Actions

    private func openPicker(_ suitcase: Suitcase, preselecting ids: [String] = []) {
        app.suitcasesUI.preparePicker(for: suitcase.id, preselecting: ids)
        app.suitcasesUI.isPickerPresented = true
    }

    private func openLaundry(_ suitcase: Suitcase) {
        app.laundryUI.focus(onSuitcase: suitcase.id)
        app.suitcasesPush(.laundry)
    }

    private func remove(_ garment: Garment, from suitcase: Suitcase) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            app.store.removeMember(garment.id, from: suitcase.id)
        }
        app.showUndoToast("Removed \(garment.displayName) from \(suitcase.name). It's still in Main Closet.")
    }

    private func unarchive(_ suitcase: Suitcase) {
        app.store.archiveSuitcase(suitcase.id, archived: false)
        app.showToast("\(suitcase.name) is back in your source choices. Your current source didn't change.", style: .info)
    }

    /// Dropped garments open the reviewed picker with them preselected; nothing is linked until confirmed.
    private func handleDrop(_ items: [String], _ suitcase: Suitcase) -> Bool {
        guard !suitcase.isArchived else { return false }
        let ids = items.compactMap(DragPayload.garmentID(from:)).filter { id in
            guard let garment = app.store.garment(id), !garment.isTrashed else { return false }
            return app.store.membership(garmentID: id, suitcaseID: suitcase.id) == nil
        }
        guard !ids.isEmpty else { return false }
        openPicker(suitcase, preselecting: ids)
        return true
    }
}

/// A linked garment inside a suitcase.
struct SuitcasesMemberCard: View {
    var garment: Garment
    var suitcase: Suitcase
    var otherSuitcases: [Suitcase]
    var onOpen: () -> Void
    var onRemove: () -> Void

    private var statusBadges: [BadgeKind] { BadgeKind.status(for: garment) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    GarmentThumbnail(garment: garment, showsStatus: false)
                    Text(garment.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(garment.colorLabel) · \(garment.kind.label)")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityLabel(garment.accessibilityDescription)
            .accessibilityValue(statusBadges.isEmpty ? "Available" : statusBadges.map(\.text).joined(separator: ", "))
            .accessibilityHint("Opens garment details")
            .accessibilityIdentifier("suitcaseMember-\(garment.id)")

            if !statusBadges.isEmpty {
                // Status badges wrap so none is ever scrolled out of sight.
                BadgeRow(badges: statusBadges)
            }
            if !otherSuitcases.isEmpty {
                BadgeRow(badges: otherSuitcases.map { .custom("Also in \($0.name)", "suitcase") }, scrolls: true)
            }

            Button(action: onRemove) {
                ViewThatFits(in: .horizontal) {
                    Label("Remove from suitcase", systemImage: "minus.circle")
                    Label("Remove", systemImage: "minus.circle")
                }
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityLabel("Remove \(garment.displayName) from \(suitcase.name)")
            .accessibilityHint("It stays in Main Closet. You can undo.")
            .accessibilityIdentifier("removeFromSuitcase-\(garment.id)")
        }
        .cardStyle(padding: Spacing.s)
        .contextMenu {
            Button(action: onOpen) {
                Label("Open details", systemImage: "info.circle")
            }
            Button(action: onRemove) {
                Label("Remove from \(suitcase.name)", systemImage: "minus.circle")
            }
        }
    }
}

#Preview("Suitcase · Weekend") {
    NavigationStack {
        SuitcaseDetailView(suitcaseID: DemoFixtures.weekend)
    }
    .previewEnvironment()
}

#Preview("Suitcase · empty") {
    NavigationStack {
        SuitcaseDetailView(suitcaseID: DemoFixtures.empty)
    }
    .previewEnvironment()
}
