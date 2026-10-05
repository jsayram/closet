import SwiftUI

/// A saved look: board with today's canonical badges, rationale, tags, retained pictures,
/// collections and quiet actions. Opening it never dispatches a service.
struct SavedOutfitDetailView: View {
    var outfitID: String
    /// True when shown beside the list in the wide Saved layout.
    var embedded: Bool = false

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var confirmDelete = false

    private var presenter: String { "outfit-\(outfitID)\(embedded ? "-pane" : "")" }

    var body: some View {
        Group {
            if let outfit = app.store.outfit(outfitID) {
                GeometryReader { geo in
                    ScrollView {
                        content(outfit, width: geo.size.width)
                            .padding(Spacing.m)
                            .frame(maxWidth: 1100)
                            .frame(maxWidth: .infinity)
                    }
                }
                .confirmationDialog("Delete “\(outfit.title)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete look", role: .destructive) { delete(outfit) }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(deleteMessage(outfit))
                }
            } else {
                missingState
            }
        }
        .savedDetailChrome(title: app.store.outfit(outfitID)?.title ?? "Saved look", embedded: embedded)
        .savedNamingAlert(presenter: presenter)
    }

    // MARK: Layout

    @ViewBuilder private func content(_ outfit: Outfit, width: CGFloat) -> some View {
        // Two columns only while both stay readable; accessibility text sizes get one column.
        if width >= 760 && !dynamicTypeSize.isAccessibilitySize {
            let sideWidth = min(400, width * 0.42)
            HStack(alignment: .top, spacing: Spacing.l) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    header(outfit)
                    boardSection(outfit)
                    previewsSection(outfit)
                    piecesSection(outfit)
                    rationaleSection(outfit)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: Spacing.m) {
                    actionsSection(outfit)
                    if app.savedUI.openWearSuggestions.contains(outfit.id) { wearSection(outfit) }
                    tagsSection(outfit)
                    SavedCollectionToggles(target: .outfit(outfit.id), presenter: presenter)
                    detailsSection(outfit)
                    deleteSection(outfit)
                }
                .frame(width: sideWidth)
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.m) {
                header(outfit)
                boardSection(outfit)
                actionsSection(outfit)
                if app.savedUI.openWearSuggestions.contains(outfit.id) { wearSection(outfit) }
                previewsSection(outfit)
                rationaleSection(outfit)
                tagsSection(outfit)
                SavedCollectionToggles(target: .outfit(outfit.id), presenter: presenter)
                piecesSection(outfit)
                detailsSection(outfit)
                deleteSection(outfit)
            }
        }
    }

    // MARK: Header

    private func header(_ outfit: Outfit) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(outfit.title)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            ChipCarousel(isExpanded: app.savedUI.disclosure("lookHeaderTags-\(outfit.id)"), itemsLabel: "tags", toggleSize: 24) {
                SavedHeaderTag(text: outfit.lane.title, systemImage: outfit.lane.systemImage)
                if let occasion = outfit.occasion {
                    SavedHeaderTag(text: occasion.label, systemImage: occasion.systemImage)
                }
                if let date = outfit.intendedDate {
                    SavedHeaderTag(text: "Planned \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                }
                SavedHeaderTag(text: SavedProvenance.label(scope: outfit.capturedScope, name: outfit.capturedScopeName),
                               systemImage: SavedProvenance.systemImage(scope: outfit.capturedScope))
                if outfit.isFavorite {
                    StatusBadge(kind: .favorite)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Board

    private func boardSection(_ outfit: Outfit) -> some View {
        let store = app.store
        let missing = outfit.pieces.filter { store.isMissing($0) }
        return VStack(alignment: .leading, spacing: Spacing.s) {
            if outfit.pieces.isEmpty {
                SavedMiniBoard(pieces: [])
                    .frame(maxWidth: 220)
            } else {
                OutfitFlatLayView(pieces: outfit.pieces,
                                  statusFor: { SavedLookStatus.badges(for: $0, in: store) })
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                OutfitPieceChips(pieces: outfit.pieces,
                                 statusFor: { SavedLookStatus.badges(for: $0, in: store) },
                                 scrolls: true,
                                 isExpanded: app.savedUI.disclosure("lookPieces-\(outfit.id)"))
            }
            HStack(spacing: Spacing.xxs) {
                Text("Badges show today's status")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("these badges", title: "Today's status",
                           text: "Badges show today's status — the saved look itself isn't changed.")
            }

            if !missing.isEmpty {
                InlineBanner(
                    style: .caution,
                    title: missing.count == 1 ? "1 piece was deleted from your closet" : "\(missing.count) pieces were deleted from your closet",
                    message: "The look keeps a placeholder in its place. Nothing was swapped in — replace it yourself in the editor if you like.",
                    actionTitle: "Replace in editor",
                    action: { app.openEditor(forSaved: outfit.id, in: nil) },
                    summary: "A placeholder holds its place. Nothing was swapped in.",
                    isMessageExpanded: app.savedUI.disclosure("lookMissingBanner-\(outfit.id)")
                )
            }
        }
        .cardStyle()
    }

    // MARK: Actions

    /// Edit and Favorite stay on screen; the quieter actions are in More.
    private func actionsSection(_ outfit: Outfit) -> some View {
        let showingWear = app.savedUI.openWearSuggestions.contains(outfit.id)
        return SavedSectionCard {
            HStack(alignment: .top, spacing: Spacing.xxs) {
                ActionGroup(moreIdentifier: "lookMoreMenu") {
                    primaryActions(outfit)
                } more: {
                    Button {
                        markWorn(outfit)
                    } label: {
                        Label("Mark worn", systemImage: "checkmark.circle")
                    }
                    .accessibilityHint("Adds today to this look's wear log. Laundry status doesn't change.")
                    .accessibilityIdentifier("markWornButton")

                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            if showingWear {
                                app.savedUI.openWearSuggestions.remove(outfit.id)
                            } else {
                                app.savedUI.openWearSuggestions.insert(outfit.id)
                            }
                        }
                    } label: {
                        Label(showingWear ? "Hide where I could wear this" : "Where could I wear this?", systemImage: "mappin.and.ellipse")
                    }
                    .accessibilityHint("Local suggestion from the garments' saved details. No AI.")
                    .accessibilityIdentifier("whereCouldIWearButton")

                    Button {
                        restyle(outfit)
                    } label: {
                        Label("Restyle with today's closet", systemImage: "sparkles")
                    }
                    .accessibilityHint("Opens Style Me with this occasion. Nothing is sent until you tap Style Me.")
                    .accessibilityIdentifier("restyleButton")

                    Button {
                        app.present(.askStylist(.outfit(outfit)))
                    } label: {
                        Label("Ask another stylist", systemImage: "person.2.wave.2")
                    }
                    .accessibilityHint("Builds a collage and prompt you can copy. Nothing is sent automatically.")
                    .accessibilityIdentifier("askStylistButton")
                }
                Spacer(minLength: 0)
                InfoButton("these actions", title: "What these do") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        InfoText(text: "Restyle opens Style Me with this occasion — you still tap Style Me. Nothing is sent from here.")
                        InfoText(text: "Mark worn adds today to this look's wear log. Laundry status doesn't change.")
                        InfoText(text: "Where could I wear this? is a local suggestion from the garments' saved details. No AI.")
                        InfoText(text: "Ask another stylist builds a collage and prompt you can copy. Nothing is sent automatically.")
                    }
                }
                .frame(minHeight: HitTarget.minimum)
            }
        }
    }

    @ViewBuilder private func primaryActions(_ outfit: Outfit) -> some View {
        Button {
            app.openEditor(forSaved: outfit.id, in: nil)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .buttonStyle(SecondaryButtonStyle())
        .keyboardShortcut("e", modifiers: .command)
        .accessibilityLabel("Edit look")
        .accessibilityIdentifier("editLookButton")

        Button {
            app.store.toggleFavorite(outfitID: outfit.id)
            app.savedSyncEditorMetadata(outfitID: outfit.id)
        } label: {
            Label(outfit.isFavorite ? "Favorited" : "Favorite", systemImage: outfit.isFavorite ? "star.fill" : "star")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel("Favorite")
        .accessibilityValue(outfit.isFavorite ? "On" : "Off")
        .accessibilityAddTraits(outfit.isFavorite ? [.isButton, .isSelected] : .isButton)
        .keyboardShortcut("d", modifiers: .command)
        .accessibilityIdentifier("favoriteButton")
    }

    // MARK: Where could I wear this?

    private func wearSection(_ outfit: Outfit) -> some View {
        let suggestion = SavedWearSuggestion.make(for: outfit, store: app.store, weather: app.weather)
        var reasons = [suggestion.formalityText, suggestion.seasonText, suggestion.warmthText, suggestion.weatherText].compactMap { $0 }
        if suggestion.skippedPieces > 0 {
            reasons.append("\(suggestion.skippedPieces) \(suggestion.skippedPieces == 1 ? "piece has" : "pieces have") no saved closet details and wasn't considered.")
        }
        let reasonLines = reasons
        return SavedSectionCard(
            "Where could I wear this?",
            subtitle: "From saved garment details · no AI",
            info: "Based on the garments' saved details · no AI. Suggestions only. Tap one to tag this look; change it any time."
        ) {
            if suggestion.occasions.isEmpty {
                CollapsibleText(
                    "There aren't enough saved garment details to suggest an occasion. Tag one yourself below.",
                    summary: "Not enough saved details to suggest one.",
                    font: .subheadline,
                    topic: "why there's no suggestion",
                    isExpanded: app.savedUI.disclosure("lookNoSuggestion-\(outfit.id)")
                )
            } else {
                ChipCarousel(isExpanded: app.savedUI.disclosure("wearChips-\(outfit.id)"), itemsLabel: "occasions") {
                    ForEach(suggestion.occasions) { occasion in
                        CapsuleChip(title: occasion.label, systemImage: occasion.systemImage, isSelected: outfit.occasion == occasion) {
                            setOccasion(outfit.occasion == occasion ? nil : occasion, outfit: outfit)
                        }
                        .accessibilityHint(outfit.occasion == occasion ? "Removes the \(occasion.label) tag" : "Tags this look \(occasion.label)")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Could work for")
            }
            if !reasonLines.isEmpty {
                DetailsDisclosure("Why these", count: reasonLines.count, isExpanded: app.savedUI.disclosure("wearWhy-\(outfit.id)"), identifier: "whereCouldIWearWhy") {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        ForEach(reasonLines, id: \.self) { line in
                            Label {
                                Text(line).fixedSize(horizontal: false, vertical: true)
                            } icon: {
                                Circle().fill(Palette.secondaryText).frame(width: 4, height: 4)
                            }
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("whereCouldIWearSuggestion")
    }

    // MARK: Pictures

    private func previewsSection(_ outfit: Outfit) -> some View {
        let previews = app.store.previews(forOutfit: outfit.id)
        return SavedSectionCard("Pictures of this look", subtitle: previews.isEmpty ? nil : "\(previews.count) kept · current and earlier versions") {
            if previews.isEmpty {
                CollapsibleText(
                    "No pictures of this look yet. Pictures are only made when you ask with On Me — opening this look never makes one.",
                    summary: "No pictures of this look yet.",
                    font: .subheadline,
                    topic: "pictures of this look",
                    isExpanded: app.savedUI.disclosure("lookNoPictures-\(outfit.id)")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: Spacing.s) {
                        ForEach(previews) { preview in
                            SavedPreviewThumb(preview: preview) {
                                app.savedPush(.preview(preview.id), from: .outfit(outfit.id))
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
                SimulationNotice(text: "Simulated placeholder pictures. A picture keeps the pieces it was made with.")
            }
        }
    }

    // MARK: Rationale

    @ViewBuilder private func rationaleSection(_ outfit: Outfit) -> some View {
        let lines: [(String, String)] = [
            ("Why it works", outfit.rationale),
            ("Colors", outfit.colorNote),
            ("Fit", outfit.fitNote),
            ("Your notes", outfit.notes),
        ].filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if let first = lines.first {
            let rest = Array(lines.dropFirst())
            SavedSectionCard("Notes", subtitle: "Saved with the look") {
                note(first, key: "lookNote-\(outfit.id)-0")
                if !rest.isEmpty {
                    DetailsDisclosure("More notes", summary: rest.map(\.0).joined(separator: ", "), count: rest.count,
                                      isExpanded: app.savedUI.disclosure("lookMoreNotes-\(outfit.id)"), identifier: "lookMoreNotes") {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            ForEach(Array(rest.enumerated()), id: \.offset) { index, line in
                                note(line, key: "lookNote-\(outfit.id)-\(index + 1)")
                            }
                        }
                    }
                }
            }
        }
    }

    /// One saved note: its label and the text, folded to two lines when it runs long.
    private func note(_ line: (String, String), key: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(line.0)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            CollapsibleText(line.1, collapsedLines: 2, threshold: 3, font: .body, color: Palette.primaryText,
                            topic: line.0, isExpanded: app.savedUI.disclosure(key))
        }
    }

    // MARK: Tags

    private func tagsSection(_ outfit: Outfit) -> some View {
        let occasionBinding = Binding<Occasion?>(
            get: { app.store.outfit(outfit.id)?.occasion },
            set: { setOccasion($0, outfit: outfit) }
        )
        let hasDate = Binding<Bool>(
            get: { app.store.outfit(outfit.id)?.intendedDate != nil },
            set: { on in
                let start = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
                app.store.savedSetIntendedDate(on ? start : nil, outfitID: outfit.id)
                app.savedSyncEditorMetadata(outfitID: outfit.id)
            }
        )
        let date = Binding<Date>(
            get: { app.store.outfit(outfit.id)?.intendedDate ?? .now },
            set: {
                app.store.savedSetIntendedDate($0, outfitID: outfit.id)
                app.savedSyncEditorMetadata(outfitID: outfit.id)
            }
        )
        return SavedSectionCard("Tags", info: "Optional. Change them any time.") {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text("Occasion").foregroundStyle(Palette.primaryText)
                    Spacer(minLength: Spacing.s)
                    occasionPicker(occasionBinding)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Occasion").foregroundStyle(Palette.primaryText)
                    occasionPicker(occasionBinding)
                }
            }
            .font(.subheadline)

            Toggle(isOn: hasDate) {
                Text("Planned date")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.primaryAction)
            .accessibilityIdentifier("intendedDateToggle")

            if outfit.intendedDate != nil {
                DatePicker("Date", selection: date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .font(.subheadline)
                    .accessibilityIdentifier("intendedDatePicker")
            }
        }
    }

    private func occasionPicker(_ binding: Binding<Occasion?>) -> some View {
        Picker("Occasion", selection: binding) {
            Text("No occasion").tag(Occasion?.none)
            ForEach(Occasion.allCases) { occasion in
                Label(occasion.label, systemImage: occasion.systemImage).tag(Occasion?.some(occasion))
            }
        }
        .pickerStyle(.menu)
        .tint(Palette.primaryAction)
        .accessibilityIdentifier("occasionTagPicker")
    }

    // MARK: Pieces

    private func piecesSection(_ outfit: Outfit) -> some View {
        let store = app.store
        return SavedSectionCard("Pieces", subtitle: "As saved, with today's status") {
            ForEach(outfit.sortedPieces) { piece in
                let garment = store.garment(piece.garmentID)
                let badges = SavedLookStatus.todayBadges(for: piece, in: store)
                let row = HStack(alignment: .top, spacing: Spacing.s) {
                    PieceThumbnail(piece: piece)
                        .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(piece.capturedName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(piece.slot.label + " · " + (piece.capturedColor?.name ?? "color unknown"))
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                        if let garment, garment.displayName != piece.capturedName {
                            Text("Now called “\(garment.displayName)”")
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                        }
                        if badges.isEmpty {
                            Label("Available", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(Palette.success)
                        } else {
                            BadgeRow(badges: badges)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if garment != nil {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Palette.secondaryText)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())

                let label = "\(piece.slot.label): \(piece.capturedName), \(piece.capturedColor?.name ?? "color unknown"). Today: \(badges.isEmpty ? "Available" : badges.map(\.text).joined(separator: ", "))"
                if let garment {
                    Button {
                        app.push(.garment(garment.id))
                    } label: { row }
                        .buttonStyle(.plain)
                        .hoverEffect(.highlight)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(label)
                        .accessibilityHint("Opens the item in your closet")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier("savedPieceRow-\(piece.slot.rawValue)")
                } else {
                    row
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(label)
                }
            }
        }
    }

    // MARK: Details

    private func detailsSection(_ outfit: Outfit) -> some View {
        DetailsDisclosure(
            "Details",
            summary: "Saved \(outfit.createdAt.formatted(date: .abbreviated, time: .omitted))",
            isExpanded: app.savedUI.disclosure("lookDetails-\(outfit.id)"),
            identifier: "lookDetails"
        ) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                InfoRow(title: "Made from", value: SavedProvenance.plainName(scope: outfit.capturedScope, name: outfit.capturedScopeName),
                        valueIsUnknown: outfit.capturedScope == nil && outfit.capturedScopeName == nil)
                InfoRow(title: "Saved", value: outfit.createdAt.formatted(date: .abbreviated, time: .omitted))
                if outfit.updatedAt > outfit.createdAt.addingTimeInterval(60) {
                    InfoRow(title: "Last edited", value: outfit.updatedAt.formatted(date: .abbreviated, time: .omitted))
                }
                InfoRow(title: "Wear log", value: wearLogText(outfit), valueIsUnknown: outfit.wornDates.isEmpty)
                Text("The wear log is optional and never changes laundry status.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: Spacing.s)
    }

    private func wearLogText(_ outfit: Outfit) -> String {
        guard let last = outfit.wornDates.max() else { return "Not logged" }
        let n = outfit.wornDates.count
        return "\(n) \(n == 1 ? "time" : "times") · last \(last.formatted(date: .abbreviated, time: .omitted))"
    }

    // MARK: Delete

    private func deleteSection(_ outfit: Outfit) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete look", systemImage: "trash")
            }
            .buttonStyle(DestructiveButtonStyle(fullWidth: true))
            .accessibilityHint("Asks for confirmation. Its pictures stay in Preview History.")
            .accessibilityIdentifier("deleteLookButton")
            // What Delete removes stays on screen in short form; the full sentence is one tap away.
            HStack(spacing: Spacing.xxs) {
                Text("Its pictures and garments stay.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                InfoButton("deleting a look", title: "Delete look",
                           text: "Deleting a look keeps its pictures in Preview History and doesn't change any garment.")
            }
        }
        .padding(.top, Spacing.xs)
    }

    private func deleteMessage(_ outfit: Outfit) -> String {
        let n = app.store.previews(forOutfit: outfit.id).count
        let pictures = n == 0 ? "" : " Its \(n) \(n == 1 ? "picture stays" : "pictures stay") in Preview History."
        return "Removes the look from Saved and from its collections.\(pictures) Garments aren't changed."
    }

    // MARK: Missing

    private var missingState: some View {
        ScrollView {
            EmptyStateView(
                title: "This look isn't saved anymore",
                message: "It may have been deleted. Any pictures made from it stay in Preview History.",
                systemImage: "bookmark.slash",
                actionTitle: "Open Preview History"
            ) {
                app.savedUI.segment = .previewHistory
                app.popToRoot(.saved)
                app.select(.saved)
            }
            .padding(.top, Spacing.xxl)
        }
    }

    // MARK: Actions

    private func setOccasion(_ occasion: Occasion?, outfit: Outfit) {
        app.store.savedSetOccasion(occasion, outfitID: outfit.id)
        app.savedSyncEditorMetadata(outfitID: outfit.id)
        app.showToast(occasion.map { "Tagged \($0.label)." } ?? "Occasion tag removed.", style: .info)
    }

    private func markWorn(_ outfit: Outfit) {
        let date = Date.now
        app.store.markWorn(outfitID: outfit.id, on: date)
        app.savedSyncEditorMetadata(outfitID: outfit.id)
        let id = outfit.id
        let model = app
        model.showToast("Noted — laundry status unchanged", actionTitle: "Undo") { [weak model] in
            guard let model else { return }
            model.store.savedRemoveWornDate(date, outfitID: id)
            model.savedSyncEditorMetadata(outfitID: id)
            model.showToast("Wear log entry removed.", style: .info)
        }
    }

    private func restyle(_ outfit: Outfit) {
        app.select(.styleMe)
        if let occasion = outfit.occasion {
            app.style.draft.occasion = occasion
            app.showToast("Style Me is set for \(occasion.label) with today's closet. Tap Style Me when you're ready.", style: .info)
        } else {
            // The look has no occasion tag, so the draft keeps whatever occasion it already had.
            app.showToast("This look has no occasion tag, so Style Me keeps \(app.style.draft.occasion.label). Change it there, then tap Style Me.", style: .info)
        }
    }

    private func delete(_ outfit: Outfit) {
        let title = outfit.title
        let keptPictures = app.store.previews(forOutfit: outfit.id).count
        if !embedded { dismiss() }
        app.savedClearSelection(.outfit(outfit.id))
        app.store.deleteOutfit(outfit.id)
        app.savedUI.openWearSuggestions.remove(outfit.id)
        app.showToast(keptPictures > 0 ? "“\(title)” deleted. Its pictures stay in Preview History." : "“\(title)” deleted.")
    }
}

/// Quiet capsule tag in a detail header.
struct SavedHeaderTag: View {
    var text: String
    var systemImage: String

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.primaryText)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxs)
        .background(Capsule().fill(Palette.imageWell))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Saved look") {
    NavigationStack {
        SavedOutfitDetailView(outfitID: "o-interview")
    }
    .previewEnvironment()
}

#Preview("Saved look — status badges") {
    NavigationStack {
        SavedOutfitDetailView(outfitID: "o-blazer")
    }
    .previewEnvironment()
}

#Preview("Saved look — missing") {
    NavigationStack {
        SavedOutfitDetailView(outfitID: "o-missing")
    }
    .previewEnvironment()
}
