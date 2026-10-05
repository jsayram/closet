import SwiftUI

/// Up to three result cards: side by side only when every card gets at least 300 pt
/// (more at accessibility text sizes); otherwise a vertical list of full-width cards.
struct StyleMeResultsGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var outfits: [Outfit]
    var outcome: StyleOutcome
    var width: CGFloat

    var body: some View {
        let count = outfits.count
        let spacing = Spacing.m
        let available = max(0, width)
        let minCard: CGFloat = dynamicTypeSize.isAccessibilitySize ? 460 : 300
        let sideWidth = count > 1 ? (available - spacing * CGFloat(count - 1)) / CGFloat(count) : available
        let sideBySide = count > 1 && sideWidth >= minCard
        Group {
            if sideBySide {
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                        StyleMeResultCard(outfit: outfit, index: index, total: count, outcome: outcome, cardWidth: sideWidth)
                            .frame(width: sideWidth)
                    }
                }
            } else {
                let cardWidth = min(available, 720)
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                        StyleMeResultCard(outfit: outfit, index: index, total: count, outcome: outcome, cardWidth: cardWidth)
                            .frame(maxWidth: cardWidth)
                    }
                }
                .scrollTargetLayout()
                .frame(maxWidth: .infinity, alignment: available > 720 ? .center : .leading)
            }
        }
        // With a single card SwiftUI merges this container into the card, which would
        // replace the card's own identifier; only group when there are several cards.
        .modifier(StyleMeResultsListContainer(enabled: count > 1))
    }
}

private struct StyleMeResultsListContainer: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("resultsList")
        } else {
            content
        }
    }
}

/// One outfit direction: lane label, tappable garment board, rationale/notes, image status and actions.
struct StyleMeResultCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var outfit: Outfit
    var index: Int
    var total: Int
    var outcome: StyleOutcome
    var cardWidth: CGFloat

    private var contentWidth: CGFloat { max(0, cardWidth - 2 * Spacing.m) }
    private var isSelected: Bool { app.style.selectedOutfitID == outfit.id }
    private var isEarlierLook: Bool { outcome.staleReason != nil }

    var body: some View {
        let horizontal = contentWidth >= 560 && !dynamicTypeSize.isAccessibilitySize
        let visualsWidth = horizontal ? contentWidth * 0.55 : contentWidth
        VStack(alignment: .leading, spacing: Spacing.s) {
            header
            if horizontal {
                HStack(alignment: .top, spacing: Spacing.m) {
                    visuals(width: visualsWidth)
                        .frame(width: visualsWidth)
                    details
                }
            } else {
                visuals(width: visualsWidth)
                details
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(highlighted: isSelected)
        .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .simultaneousGesture(TapGesture().onEnded { select() })
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(outfit.lane.title) look")
        .accessibilityIdentifier("resultCard-\(index)")
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            LaneLabel(lane: outfit.lane)
            Text(outfit.title)
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            BadgeRow(badges: headerBadges)
        }
    }

    private var headerBadges: [BadgeKind] {
        var badges: [BadgeKind] = []
        if isEarlierLook { badges.append(.earlier) }
        if outcome.fromHistory { badges.append(.fromHistory) }
        if isSelected, total > 1 { badges.append(.custom("Selected", "checkmark.circle")) }
        return badges
    }

    // MARK: Visuals

    private func visuals(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            StyleMeImageStatusView(outfit: outfit, index: index, maxFigureWidth: min(width, 220))
            // Flat-lay hero (pieces placed where they're worn) plus labelled chips that
            // carry names, colors and status in text for VoiceOver and large type.
            OutfitFlatLayView(pieces: outfit.pieces,
                              selectedSlot: editorSelectedSlot,
                              statusFor: { StyleMeLayout.badges(for: $0, request: outcome.request, store: app.store) },
                              onTap: { piece in openEditor(slot: piece.slot) })
                .frame(maxWidth: min(width, 420))
                .frame(maxWidth: .infinity)
            OutfitPieceChips(pieces: outfit.pieces,
                             selectedSlot: editorSelectedSlot,
                             statusFor: { StyleMeLayout.badges(for: $0, request: outcome.request, store: app.store) },
                             onTap: { piece in openEditor(slot: piece.slot) })
        }
    }

    /// The slot being edited for this result, if its editor is open.
    private var editorSelectedSlot: OutfitSlot? {
        guard let editor = app.editor, case let .result(id) = editor.origin, id == outfit.id else { return nil }
        return editor.selectedSlot
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            StyleMeLookNotes(rationale: outfit.rationale, notes: notes, key: outfit.id)
            unownedSection
            actions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Color, fit and source notes, shown behind the "Notes" row.
    private var notes: [StyleMeLookNotes.Note] {
        var notes: [StyleMeLookNotes.Note] = []
        if !outfit.colorNote.isEmpty { notes.append(.init(text: outfit.colorNote, icon: "paintpalette")) }
        if !outfit.fitNote.isEmpty { notes.append(.init(text: outfit.fitNote, icon: "ruler")) }
        notes.append(.init(text: "From \(outfit.capturedScopeName ?? outcome.request.scopeName)",
                           icon: StyleMeFormat.scopeIcon(outfit.capturedScope ?? outcome.request.scope)))
        return notes
    }

    @ViewBuilder
    private var unownedSection: some View {
        let hypothetical = outfit.pieces.filter(\.isHypothetical)
        if outfit.lane == .hypothetical {
            ActionBanner(style: .info, title: "Idea only — not from your closet",
                         message: "None of these pieces are in your saved closet. Open the look to mark Already Own on anything you have.",
                         summary: "None of these pieces are in your closet.",
                         isMessageExpanded: app.styleMeUI.disclosure("ideaOnly-\(outfit.id)")) {
                Button { openEditor(slot: nil) } label: { Label("Review pieces", systemImage: "hanger") }
                    .buttonStyle(SecondaryButtonStyle())
            }
        } else {
            ForEach(hypothetical) { piece in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    StatusBadge(kind: .unowned)
                    Text(piece.capturedName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    CollapsibleText("You don't own this piece. Nothing is searched or bought unless you choose Find One.",
                                    summary: "You don't own this piece.",
                                    threshold: 1,
                                    topic: "this piece",
                                    isExpanded: app.styleMeUI.disclosure("unowned-\(outfit.id)-\(piece.id)"))
                    FlowLayout(spacing: Spacing.xs) {
                        Button { openEditor(slot: piece.slot) } label: {
                            Label("Already own", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(SuccessButtonStyle())
                        .accessibilityLabel("I already own something like this")
                        .accessibilityIdentifier("alreadyOwnButton-\(index)")
                        Button {
                            select()
                            app.present(.findOne(app.findOneContext(for: piece, outfit: outfit)))
                        } label: {
                            Label("Find One", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("findOneButton-\(index)")
                    }
                }
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.5)))
                .accessibilityElement(children: .contain)
            }
        }
    }

    /// Swap and Save stay visible; the two ways to ask about the look sit in More.
    private var actions: some View {
        ActionGroup(moreIdentifier: "resultMoreButton-\(index)") {
            Button("Swap pieces") { openEditor(slot: nil) }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityHint("Opens the editor to swap one piece at a time")
                .accessibilityIdentifier("resultEditButton-\(index)")

            saveButton
        } more: {
            Button("Ask about this look", systemImage: "bubble.left.and.text.bubble.right") {
                select()
                app.openStylistChat(attaching: outfit)
            }
            .accessibilityHint("Opens the stylist chat with this look attached. Nothing is sent until you ask.")
            .accessibilityIdentifier("resultAskChatButton-\(index)")

            Button("Ask another stylist", systemImage: "person.2") {
                select()
                app.present(.askStylist(.outfit(outfit)))
            }
            .accessibilityHint("Prepares a collage and prompt you can share yourself")
            .accessibilityIdentifier("resultAskStylistButton-\(index)")
        }
    }

    @ViewBuilder
    private var saveButton: some View {
        if let savedID = app.styleMeUI.savedCopies[outfit.id], app.store.outfit(savedID) != nil {
            // Text only, like its neighbours, so Swap, Save and More share one row on a phone.
            Button("Saved") {
                app.push(.outfit(savedID), in: .saved)
            }
            .buttonStyle(SuccessButtonStyle())
            .accessibilityLabel("Saved on this device. View saved look")
            .accessibilityHint("Opens the saved look")
            .accessibilityIdentifier("resultSaveButton-\(index)")
        } else {
            Button("Save") {
                save()
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Save look")
            .accessibilityHint("Saves a copy to Saved Looks on this device")
            .accessibilityIdentifier("resultSaveButton-\(index)")
        }
    }

    // MARK: Actions

    private func select() {
        if app.style.selectedOutfitID != outfit.id { app.style.selectedOutfitID = outfit.id }
    }

    private func openEditor(slot: OutfitSlot?) {
        select()
        app.openEditor(forResult: outfit, selecting: slot)
    }

    /// Saves a copy of the delivered result under a new ID. Acknowledged only after the durable write.
    private func save() {
        select()
        var copy = outfit
        copy.id = UUID().uuidString
        copy.isSaved = false
        do {
            let saved = try app.store.saveOutfit(copy, asCopy: false)
            app.styleMeUI.savedCopies[outfit.id] = saved.id
            let savedID = saved.id
            app.showToast("Saved on this device.", actionTitle: "View") { [weak app] in
                app?.push(.outfit(savedID), in: .saved)
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? "Couldn't save on this device. Your result is still here."
            app.showToast(message, style: .error)
        }
    }
}

// MARK: - Image status (simulated On Me)

struct StyleMeImageStatusView: View {
    @Environment(AppModel.self) private var app
    var outfit: Outfit
    var index: Int
    var maxFigureWidth: CGFloat

    var body: some View {
        switch app.style.imageJobs[outfit.id] {
        case .none:
            EmptyView()
        case .queued?:
            statusRow(icon: "hourglass", text: "Simulated picture queued. The board works now.")
        case let .generating(progress)?:
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                statusRow(icon: "photo", text: "Generating simulated picture · \(Int(progress * 100))%")
                ProgressView(value: progress)
                    .tint(Palette.primaryAction)
                    .accessibilityLabel("Picture progress")
                    .accessibilityValue("\(Int(progress * 100)) percent")
            }
        case .saving?:
            statusRow(icon: "tray.and.arrow.down", text: "Saving the picture to your history…")
        case let .ready(previewID)?:
            picture(previewID: previewID, reused: false)
        case let .reused(previewID)?:
            picture(previewID: previewID, reused: true)
        case let .failed(reason)?:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                statusRow(icon: "xmark.octagon", text: "Picture failed — \(reason). The board below still works.", tint: Palette.error)
                retryButton
            }
        case .cancelRequested?:
            statusRow(icon: "hourglass", text: "Cancelling picture…")
        case .cancelled?:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                statusRow(icon: "stop.circle", text: "Picture cancelled. The board still works.")
                retryButton
            }
        case let .notStarted(reason)?:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                statusRow(icon: "photo", text: "No picture yet — \(reason)")
                retryButton(title: "Make picture", systemImage: "photo.badge.plus")
            }
        }
    }

    private func statusRow(icon: String, text: String, tint: Color = Palette.primaryAction) -> some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon).foregroundStyle(tint)
        }
        .font(.footnote)
        .foregroundStyle(Palette.primaryText)
        .padding(Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.imageWell))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func picture(previewID: String, reused: Bool) -> some View {
        let isEarlier = app.style.earlierPreviewOutfitIDs.contains(outfit.id)
        if let preview = app.store.preview(app.style.previewByOutfit[outfit.id] ?? previewID) {
            VStack(alignment: .center, spacing: Spacing.xxs) {
                OnMePreviewFigure(pieces: preview.snapshotPieces, label: preview.quality.label, isEarlier: isEarlier)
                    .frame(maxWidth: maxFigureWidth)
                BadgeRow(badges: pictureBadges(preview, reused: reused))
                Text(reused ? "Reused from your history — no new image work." : "Kept in your picture history automatically.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if isEarlier {
                    CollapsibleText("Earlier picture — the look changed after it was made. Use Update Preview in the editor when you want a new one.",
                                    summary: "Earlier picture. The look has changed since.",
                                    threshold: 1,
                                    font: .caption,
                                    centered: true,
                                    topic: "this earlier picture",
                                    isExpanded: app.styleMeUI.disclosure("earlierPicture-\(outfit.id)"))
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            statusRow(icon: "photo.badge.exclamationmark", text: "This picture is no longer in your history. The board still works.")
        }
    }

    private func pictureBadges(_ preview: PreviewEntry, reused: Bool) -> [BadgeKind] {
        var badges: [BadgeKind] = []
        switch preview.quality {
        case .ok: break
        case .approximate: badges.append(.approximate)
        case .appearanceMismatch: badges.append(.mismatch)
        }
        if preview.isDisliked { badges.append(.disliked) }
        if reused { badges.append(.fromHistory) }
        return badges
    }

    private var retryButton: some View { retryButton(title: "Retry picture", systemImage: "arrow.clockwise") }

    private func retryButton(title: String, systemImage: String) -> some View {
        let ready = app.isOnMeReady
        let admitted = app.admittedImageJobs(1) == 1
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Button {
                app.retryPreview(outfitID: outfit.id)
            } label: {
                Label(title, systemImage: systemImage)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!ready || !admitted)
            .accessibilityIdentifier("retryPreviewButton-\(index)")
            if !ready {
                Text("On Me needs to be set up in Profile to retry.")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
            } else if !admitted {
                Text("A new picture can't start: \(app.imageAdmissionBlockedReason)")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
