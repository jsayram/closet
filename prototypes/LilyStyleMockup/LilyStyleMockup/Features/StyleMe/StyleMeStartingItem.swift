import SwiftUI

/// Optional starting piece: picker, local name resolution, and an iPad drop target.
/// Every route ends in the same explicit confirmation; nothing changes a garment's stored status
/// except an explicit Mark clean.
struct StyleMeStartingItemSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isDropTargeted = false
    @FocusState private var textFocused: Bool

    var body: some View {
        @Bindable var style = app.style
        let ui = app.styleMeUI
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Starting piece", subtitle: "Optional",
                          info: "Optional — build the looks around something you'd like to wear."
                              + (sizeClass == .regular ? " You can also drag a garment here from your closet." : ""))

            if let garment = app.store.garment(style.draft.startingItemID) {
                StyleMeChosenStartingItem(garment: garment)
            }

            if let dropID = ui.pendingDropGarmentID, let garment = app.store.garment(dropID) {
                StyleMeCandidateConfirm(garment: garment,
                                        prompt: "Use \(garment.displayName) as your starting piece?",
                                        context: "Dropped here · \(garment.category.label)",
                                        onUse: { useOverride in
                                            StyleMeStartingActions.choose(garment, withOverride: useOverride, app: app)
                                        },
                                        onCancel: { ui.pendingDropGarmentID = nil })
            }

            if let message = ui.dropMessage {
                ActionBanner(style: .caution, title: "Couldn't use that item", message: message) {
                    Button("OK") { ui.dropMessage = nil }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }

            Button {
                ui.showStartingPicker = true
            } label: {
                Label(style.draft.startingItemID == nil ? "Choose from \(app.workingScopeName)" : "Choose a different piece",
                      systemImage: "hanger")
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
            .accessibilityHint("Shows garments in \(app.workingScopeName)")
            .accessibilityIdentifier("startingItemButton")

            textEntry(style: style)

            resolutionView(style: style)
        }
        .cardStyle(highlighted: isDropTargeted)
        .dropDestination(for: String.self) { items, _ in
            handleDrop(items)
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Free text

    @ViewBuilder
    private func textEntry(style session: StyleSession) -> some View {
        let isEmpty = session.draft.startingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    startingTextField(session: session)
                    findButton(disabled: isEmpty)
                }
            } else {
                HStack(spacing: Spacing.xs) {
                    startingTextField(session: session)
                    findButton(disabled: isEmpty)
                }
            }
        }
        .onChange(of: session.draft.startingText) { _, newValue in
            if let resolved = app.styleMeUI.resolvedText, resolved.query != newValue {
                app.styleMeUI.resolvedText = nil
            }
        }
    }

    private func startingTextField(session: StyleSession) -> some View {
        @Bindable var bindable = session
        return TextField("e.g. use my navy dress pants", text: $bindable.draft.startingText)
            .textFieldStyle(StyleMeTextFieldStyle())
            .submitLabel(.search)
            .focused($textFocused)
            .onSubmit { resolveText() }
            .accessibilityLabel("Starting piece by name")
            .accessibilityHint("Matches your names and other names in \(app.workingScopeName). Stays on this device.")
            .accessibilityIdentifier("startingItemTextField")
    }

    private func findButton(disabled: Bool) -> some View {
        Button("Find") { resolveText() }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(disabled)
            .accessibilityHint("Looks for a matching garment on this device")
    }

    private func resolveText() {
        let text = app.style.draft.startingText
        textFocused = false
        guard let result = StyleMeStartingResolver.resolve(text, store: app.store, scope: app.workingScope) else {
            app.styleMeUI.resolvedText = nil
            return
        }
        app.styleMeUI.resolvedText = StyleMeResolvedText(query: text, scope: app.workingScope, result: result)
    }

    @ViewBuilder
    private func resolutionView(style: StyleSession) -> some View {
        let ui = app.styleMeUI
        if let resolved = ui.resolvedText, resolved.scope == app.workingScope, resolved.query == style.draft.startingText {
            switch resolved.result {
            case let .unique(id):
                if let garment = app.store.garment(id) {
                    StyleMeCandidateConfirm(garment: garment,
                                            prompt: "Use \(garment.displayName)?",
                                            context: "Matched “\(resolved.query.trimmingCharacters(in: .whitespacesAndNewlines))” in \(app.workingScopeName)",
                                            cancelTitle: "Keep as a note",
                                            onUse: { useOverride in
                                                StyleMeStartingActions.choose(garment, withOverride: useOverride, app: app)
                                                ui.resolvedText = nil
                                                app.style.draft.startingText = ""
                                            },
                                            onCancel: { ui.resolvedText = StyleMeResolvedText(query: resolved.query, scope: resolved.scope, result: .keptAsNote) })
                }
            case let .multiple(ids):
                multipleMatches(ids: ids, resolved: resolved)
            case let .outsideSource(id):
                noteLine("\(app.store.garment(id)?.displayName ?? "That item") is in Main Closet but not in \(app.workingScopeName), so it's kept as a note. Add it to this suitcase in Closet if you want to style with it here.",
                         icon: "suitcase")
            case .notFound:
                noteLine("Not found in \(app.workingScopeName) — kept as a note for this request.", icon: "text.quote")
            case .keptAsNote:
                noteLine("Kept as a note for this request.", icon: "text.quote")
            }
        }
    }

    private func multipleMatches(ids: [String], resolved: StyleMeResolvedText) -> some View {
        let ui = app.styleMeUI
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("A few pieces in \(app.workingScopeName) match. Which one?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
            ForEach(ids, id: \.self) { id in
                if let garment = app.store.garment(id) {
                    Button {
                        ui.resolvedText = StyleMeResolvedText(query: resolved.query, scope: resolved.scope, result: .unique(garmentID: id))
                    } label: {
                        HStack(spacing: Spacing.s) {
                            GarmentThumbnail(garment: garment, size: 44, showsStatus: false)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(garment.displayName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Palette.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(garment.kind.label) · \(garment.colorLabel)")
                                    .font(.caption)
                                    .foregroundStyle(Palette.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                // Under the name (not beside it) so status never squeezes the name at large text sizes.
                                BadgeRow(badges: BadgeKind.status(for: garment))
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                        .frame(minHeight: HitTarget.minimum)
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityElement(children: .combine)
                }
            }
            Button("None of these — keep as a note") {
                ui.resolvedText = StyleMeResolvedText(query: resolved.query, scope: resolved.scope, result: .keptAsNote)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.5)))
    }

    /// A long note (the outside-source case) folds to its first line with More.
    private func noteLine(_ text: String, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            CollapsibleText(text, topic: "this note", isExpanded: app.styleMeUI.disclosure("startingNote"))
        }
    }

    // MARK: Drop (iPad) — validate, then preview before anything changes

    private func handleDrop(_ items: [String]) -> Bool {
        guard let first = items.first else { return false }
        let ui = app.styleMeUI
        guard let id = DragPayload.garmentID(from: first) else {
            // Plain dropped text goes through the same local name matching.
            app.style.draft.startingText = first
            resolveText()
            return true
        }
        guard let garment = app.store.garment(id) else {
            ui.dropMessage = "That item no longer exists."
            return false
        }
        guard app.store.isInScope(garment, app.workingScope) else {
            ui.dropMessage = "\(garment.displayName) isn't in \(app.workingScopeName). Starting pieces come from the selected source — add it to this suitcase in Closet, or switch source."
            return false
        }
        guard garment.category != .unknown, OutfitSlot.slot(for: garment.category) != nil else {
            ui.dropMessage = "\(garment.displayName) has no category yet. Add one in Closet to use it as a starting piece."
            return false
        }
        guard [.owned, .purchasedConfirmed, .noLongerOwned].contains(garment.ownership), !garment.isTrashed else {
            ui.dropMessage = "Only clothes you own can be a starting piece. \(garment.displayName) is \(garment.ownership.label.lowercased())."
            return false
        }
        ui.dropMessage = nil
        ui.pendingDropGarmentID = garment.id
        return true
    }
}

// MARK: - Chosen piece chip

struct StyleMeChosenStartingItem: View {
    @Environment(AppModel.self) private var app
    var garment: Garment

    var body: some View {
        let eligibility = app.store.eligibility(of: garment, scope: app.workingScope, overrides: app.style.draft.overrideIDs)
        let badges = (eligibility.overridden ? [BadgeKind.usedThisRequest] : []) + BadgeKind.status(for: garment)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    details(badges: badges)
                    Spacer(minLength: Spacing.xs)
                    removeButton
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    details(badges: badges)
                    removeButton
                }
            }
            if !eligibility.isEligible {
                if eligibility.canOverride {
                    CollapsibleText("It's \(StyleMeFormat.overridableStatus(eligibility)). Use it for this request (its status stays the same), or choose another piece.",
                                    summary: "It's \(StyleMeFormat.overridableStatus(eligibility)). Using it won't change that.",
                                    threshold: 1,
                                    topic: "using this piece",
                                    isExpanded: app.styleMeUI.disclosure("startingOverride"))
                    FlowLayout(spacing: Spacing.xs) {
                        Button("Use for this request") { StyleMeStartingActions.choose(garment, withOverride: true, app: app) }
                            .buttonStyle(SecondaryButtonStyle())
                        if garment.availability == .dirty {
                            Button("Mark clean") { StyleMeStartingActions.markClean(garment, app: app) }
                                .buttonStyle(SuccessButtonStyle())
                        }
                    }
                } else {
                    Text(StyleMeFormat.ineligibleReason(eligibility, scopeName: app.workingScopeName))
                        .font(.footnote)
                        .foregroundStyle(Palette.error)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.primaryAction.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("startingItemChip")
    }

    private func details(badges: [BadgeKind]) -> some View {
        HStack(spacing: Spacing.s) {
            GarmentThumbnail(garment: garment, size: 52, showsStatus: false)
            VStack(alignment: .leading, spacing: 2) {
                Text("Starting with")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                Text(garment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                BadgeRow(badges: badges)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var removeButton: some View {
        Button {
            StyleMeStartingActions.clear(app: app)
        } label: {
            Label("Remove", systemImage: "xmark")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityLabel("Remove starting piece \(garment.displayName)")
        .accessibilityIdentifier("removeStartingItemButton")
    }
}

// MARK: - Confirmation preview (text match, drop)

struct StyleMeCandidateConfirm: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    var prompt: String
    var context: String
    var cancelTitle: String = "Not this one"
    var onUse: (_ withOverride: Bool) -> Void
    var onCancel: () -> Void

    var body: some View {
        let eligibility = app.store.eligibility(of: garment, scope: app.workingScope, overrides: app.style.draft.overrideIDs)
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                GarmentThumbnail(garment: garment, size: 64, showsStatus: false)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(prompt)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(context)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    BadgeRow(badges: BadgeKind.status(for: garment))
                }
            }
            .accessibilityElement(children: .combine)

            if eligibility.isEligible {
                FlowLayout(spacing: Spacing.xs) {
                    Button("Use as starting piece") { onUse(false) }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                        .accessibilityIdentifier("confirmStartingItemButton")
                    Button(cancelTitle, action: onCancel)
                        .buttonStyle(SecondaryButtonStyle())
                }
            } else if eligibility.canOverride {
                CollapsibleText("It's \(StyleMeFormat.overridableStatus(eligibility)). You can use it for this request — its status stays the same.",
                                summary: "It's \(StyleMeFormat.overridableStatus(eligibility)). Using it won't change that.",
                                threshold: 1,
                                topic: "using this piece",
                                isExpanded: app.styleMeUI.disclosure("candidateOverride"))
                // Wraps to two rows at most: the main action, then the way out and More.
                FlowLayout(spacing: Spacing.xs) {
                    Button("Use for this request") { onUse(true) }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                        .accessibilityIdentifier("confirmStartingItemButton")
                    Button(cancelTitle, action: onCancel)
                        .buttonStyle(SecondaryButtonStyle())
                    if garment.availability == .dirty {
                        MoreMenu(identifier: "confirmStartingItemMore") {
                            Button("Mark clean", systemImage: "sparkles") { StyleMeStartingActions.markClean(garment, app: app) }
                        }
                    }
                }
            } else {
                Text(StyleMeFormat.ineligibleReason(eligibility, scopeName: app.workingScopeName))
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
                Button(cancelTitle, action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.5)))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Picker sheet (working source only)

struct StyleMeStartingPickerSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let categoryOrder: [GarmentCategory] = [.top, .bottom, .dress, .layer, .shoes, .accessory]

    var body: some View {
        let scope = app.workingScope
        let all = StyleMeStartingActions.pickerCandidates(store: app.store, scope: scope)
        let shown = filtered(all)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    HStack(spacing: Spacing.xxs) {
                        Text("From \(app.workingScopeName) only")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        InfoButton("choosing a starting piece", title: "Starting piece",
                                   text: "From \(app.workingScopeName) only. Choosing a piece doesn't change its status.")
                    }

                    if let current = app.store.garment(app.style.draft.startingItemID) {
                        Button {
                            StyleMeStartingActions.clear(app: app)
                            dismiss()
                        } label: {
                            Label("Remove \(current.displayName)", systemImage: "xmark")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    if all.isEmpty {
                        EmptyStateView(title: "Nothing here yet",
                                       message: "\(app.workingScopeName) has no clothes to start from. Add garments to it, or choose another source.",
                                       systemImage: "suitcase")
                    } else if shown.isEmpty {
                        EmptyStateView(title: "No match",
                                       message: "Nothing in \(app.workingScopeName) matches “\(query)”. Try another name or other name.",
                                       systemImage: "magnifyingglass")
                    }

                    ForEach(categoryOrder) { category in
                        let items = shown.filter { $0.category == category }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(category.pluralLabel)
                                    .font(.headline)
                                    .foregroundStyle(Palette.primaryText)
                                    .accessibilityAddTraits(.isHeader)
                                ForEach(items) { garment in
                                    StyleMeStartingPickerRow(garment: garment,
                                                             isCurrent: garment.id == app.style.draft.startingItemID) { useOverride in
                                        StyleMeStartingActions.choose(garment, withOverride: useOverride, app: app)
                                        app.styleMeUI.resolvedText = nil
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.m)
                .readableWidth(640)
            }
            .themedScreenBackground()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Names and other names")
            .navigationTitle("Starting piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
            .overlay(alignment: .bottom) { StyleMeSheetToast() }
        }
    }

    /// Eligible first, then by name. Search is local over names and other names.
    private func filtered(_ garments: [Garment]) -> [Garment] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let matched = q.isEmpty ? garments : garments.filter { g in
            ([g.displayName] + g.aliases.map(\.text) + [g.kind.label, g.color?.name ?? ""]).contains { $0.lowercased().contains(q) }
        }
        let scope = app.workingScope
        let overrides = app.style.draft.overrideIDs
        return matched.sorted { a, b in
            let ea = app.store.eligibility(of: a, scope: scope, overrides: overrides).isEligible
            let eb = app.store.eligibility(of: b, scope: scope, overrides: overrides).isEligible
            if ea != eb { return ea }
            return a.displayName < b.displayName
        }
    }
}

struct StyleMeStartingPickerRow: View {
    @Environment(AppModel.self) private var app
    var garment: Garment
    var isCurrent: Bool
    var onChoose: (_ withOverride: Bool) -> Void

    var body: some View {
        let eligibility = app.store.eligibility(of: garment, scope: app.workingScope, overrides: app.style.draft.overrideIDs)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if eligibility.isEligible {
                Button { onChoose(false) } label: { rowContent(eligibility) }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityHint("Uses this as your starting piece")
                    .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
            } else {
                rowContent(eligibility)
                if eligibility.canOverride {
                    FlowLayout(spacing: Spacing.xs) {
                        Button("Use for this request") { onChoose(true) }
                            .buttonStyle(SecondaryButtonStyle())
                            .accessibilityHint("Its \(StyleMeFormat.overridableStatus(eligibility)) status stays the same")
                        if garment.availability == .dirty {
                            Button("Mark clean") { StyleMeStartingActions.markClean(garment, app: app) }
                                .buttonStyle(SuccessButtonStyle())
                        }
                    }
                } else {
                    Text(StyleMeFormat.ineligibleReason(eligibility, scopeName: app.workingScopeName))
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
            .strokeBorder(isCurrent ? Palette.primaryAction : Palette.divider, lineWidth: isCurrent ? 2 : 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("startingPickerRow-\(garment.id)")
    }

    private func rowContent(_ eligibility: Eligibility) -> some View {
        HStack(spacing: Spacing.s) {
            GarmentThumbnail(garment: garment, size: 56, showsStatus: false)
                .opacity(eligibility.isEligible || eligibility.canOverride ? 1 : 0.6)
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(garment.kind.label) · \(garment.colorLabel)")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                BadgeRow(badges: (eligibility.overridden ? [BadgeKind.usedThisRequest] : []) + BadgeKind.status(for: garment))
            }
            Spacer(minLength: Spacing.xs)
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Palette.primaryAction)
                    .accessibilityLabel("Current starting piece")
            } else if eligibility.isEligible {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: HitTarget.minimum)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
