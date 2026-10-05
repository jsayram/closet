import SwiftUI

// MARK: - Header

struct FindOneHeaderCard: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var context: FindOneContext

    private var outfitTitle: String? {
        if let id = context.outfitID {
            if let editor = app.editor, editor.outfit.id == id || editor.baseOutfit.id == id { return editor.outfit.title }
            return app.store.outfit(id)?.title
        }
        return nil
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.s))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.m))
        layout {
            GarmentArtwork(kind: context.kind, hex: context.colorFamily?.swatchHex)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                let header = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
                    : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                header {
                    Text("Looking for")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                        .textCase(.uppercase)
                    InfoButton("Find One", text: "Find One is optional — your closet comes first. Nothing is searched until you tap Search.")
                    if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: Spacing.xs) }
                    StatusBadge(kind: .simulated, compact: true)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(context.description.prefix(1).uppercased() + context.description.dropFirst())
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .contain)
    }

    private var subtitle: String {
        var parts = ["\(context.slot.label) piece", "Source: \(app.store.scopeName(context.scope))"]
        if let outfitTitle { parts.insert("For “\(outfitTitle)”", at: 0) }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Return prompt (after the simulated store page)

struct FindOneReturnPromptCard: View {
    @Environment(AppModel.self) private var app
    @Bindable var session: FindOneSession
    var prompt: FindOneReturnPrompt

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: "bag")
                .font(.title3)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Text("Ordered or bought it?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    InfoButton("adding a purchase", title: "Ordered or bought it?",
                               text: "\(prompt.candidate.title) · \(prompt.candidate.retailer). A store visit isn't a purchase — only your choice adds it.")
                }
                Text("\(prompt.candidate.title) · \(prompt.candidate.retailer)")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .lineLimit(2)
                Button {
                    guard session.path.isEmpty else { return }
                    resolve()
                    // Reuse a record she already confirmed for this product, so no duplicate is created.
                    let existing = app.store.findOnePurchasedGarment(for: prompt.candidate)?.id
                    session.path.append(.purchase(PurchaseReviewContext(candidate: prompt.candidate, findOne: session.context,
                                                                        existingGarmentID: existing)))
                } label: {
                    Label("Add to closet", systemImage: "plus.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("findOneReturnAddToCloset")
            }
            Spacer(minLength: 0)
            Button {
                resolve()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.secondaryText)
                    .minimumHitTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
            .accessibilityHint("Won't ask again for this visit. The product stays in Recent store visits.")
            .accessibilityIdentifier("findOneReturnDismiss")
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.7)))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.primaryAction.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("findOneReturnPrompt")
    }

    private func resolve() {
        if let visitID = prompt.visitID { app.store.findOneDismissVisitPrompt(visitID) }
        session.returnPrompt = nil
    }
}

// MARK: - 1. Closet first

struct FindOneClosetFirstSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    var session: FindOneSession
    @State private var swapError: String?

    private var context: FindOneContext { session.context }

    /// The open editor draft this Find One belongs to, if its outfit has the slot.
    private var swappableEditor: OutfitEditorSession? {
        guard let editor = app.editor, editor.outfit.piece(for: context.slot) != nil else { return nil }
        if let id = context.outfitID, id != editor.outfit.id, id != editor.baseOutfit.id { return nil }
        return editor
    }

    var body: some View {
        let editor = swappableEditor
        let currentID = app.editor?.outfit.piece(for: context.slot)?.garmentID
        let alternatives = app.store.findOneOwnedAlternatives(for: context, excluding: Set([currentID].compactMap { $0 }))
        let scopeName = app.store.scopeName(context.scope)
        let plural = context.slot.category.pluralLabel.lowercased()

        CardSection("Closet first", subtitle: "Eligible \(plural) you already own in \(scopeName)",
                    info: editor == nil && !alternatives.isEmpty ? "Open a look in the outfit editor to swap one of these in directly." : nil,
                    step: 1) {
            if alternatives.isEmpty {
                CollapsibleText("I couldn't find another eligible \(context.slot.label.lowercased()) in \(scopeName). That's based on your recorded items only — it doesn't mean you own none.",
                                summary: "No other eligible \(context.slot.label.lowercased()) recorded here.",
                                threshold: 1, font: .subheadline, topic: "your closet",
                                isExpanded: session.detailsBinding("closetFirstEmpty"))
            } else {
                VStack(spacing: Spacing.s) {
                    ForEach(alternatives) { garment in
                        row(garment, editor: editor)
                    }
                }
            }
            if let swapError {
                Label(swapError, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(Palette.error)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func row(_ garment: Garment, editor: OutfitEditorSession?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: Spacing.s) {
                rowInfo(garment)
                Spacer(minLength: Spacing.xs)
                rowAction(garment, editor: editor)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                rowInfo(garment)
                rowAction(garment, editor: editor)
            }
        }
    }

    private func rowInfo(_ garment: Garment) -> some View {
        HStack(spacing: Spacing.s) {
            GarmentThumbnail(garment: garment, size: 56, showsStatus: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(garment.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(garment.colorLabel) · \(garment.kind.label)")
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                StatusBadge(kind: .owned, compact: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func rowAction(_ garment: Garment, editor: OutfitEditorSession?) -> some View {
        if editor != nil {
            Button {
                if app.applySwap(slot: context.slot, garmentID: garment.id) {
                    app.showToast("Swapped in \(garment.displayName). Nothing was searched or bought.")
                    dismiss()
                } else {
                    swapError = "\(garment.displayName) can't be used in this look right now. Its status may have changed."
                }
            } label: {
                Label("Use this instead", systemImage: "arrow.triangle.swap")
            }
            .buttonStyle(SuccessButtonStyle())
            .accessibilityLabel("Use \(garment.displayName) instead")
            .accessibilityHint("Swaps only this piece in your look and closes Find One")
            .accessibilityIdentifier("findOneOwnedAlternative-\(garment.id)")
        } else {
            Button {
                dismiss()
                app.push(.garment(garment.id), in: .closet)
            } label: {
                Label("View in Closet", systemImage: "cabinet")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("View \(garment.displayName) in Closet")
            .accessibilityIdentifier("findOneOwnedAlternative-\(garment.id)")
        }
    }
}

// MARK: - 2. Review what's sent

struct FindOneIntentSection: View {
    @Environment(AppModel.self) private var app
    @Bindable var session: FindOneSession
    @FocusState private var focusedField: FindOneIntentField?

    private enum FindOneIntentField: Hashable { case garment, color, budget, shipsTo, store }

    private var retailerOnly: Binding<Bool> {
        Binding(
            get: { app.store.profile.retailerOnlyMode },
            set: { value in app.store.updateProfile { $0.retailerOnlyMode = value } }
        )
    }

    var body: some View {
        let profile = app.store.profile
        let intent = session.intent(profile: profile)
        CardSection("Review what's sent", subtitle: "Only public garment details leave this device.",
                    info: "Edit before you search. Only public garment details leave this device.", step: 2) {
            FindOneLabeledField(title: "Garment") {
                TextField("e.g. ankle trousers", text: $session.garment)
                    .focused($focusedField, equals: .garment)
                    .submitLabel(.done)
                    .accessibilityLabel("Garment to search for")
                    .accessibilityIdentifier("findOneIntentField")
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.s) {
                    colorField
                    budgetField
                }
                VStack(alignment: .leading, spacing: Spacing.s) {
                    colorField
                    budgetField
                }
            }
            FindOneLabeledField(title: "Ships to", info: "Your weather location never changes this.") {
                TextField("Country", text: $session.shipsTo)
                    .focused($focusedField, equals: .shipsTo)
                    .textContentType(.countryName)
                    .accessibilityIdentifier("findOneShipsToField")
            }
            retailers(profile)
            FindOneToggleRow(
                title: "Only these retailers",
                caption: profile.retailerOnlyMode ? "On · other stores are left out" : "Off · other stores can appear",
                info: profile.retailerOnlyMode
                    ? "Other stores are left out, even with better fit evidence."
                    : "Off: other permitted stores can appear when they have stronger fit evidence.",
                isOn: retailerOnly,
                identifier: "findOneRetailerOnlyToggle"
            )
            sizeRange(profile)
            sentBox(intent: intent)
        }
        .toolbar {
            if focusedField != nil {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .accessibilityIdentifier("findOneKeyboardDone")
                }
            }
        }
    }

    private var colorField: some View {
        FindOneLabeledField(title: "Color") {
            TextField("Any color", text: $session.color)
                .focused($focusedField, equals: .color)
                .accessibilityIdentifier("findOneColorField")
        }
    }

    private var budgetField: some View {
        FindOneLabeledField(title: "Budget (USD)") {
            HStack(spacing: Spacing.xxs) {
                Text("up to $")
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
                TextField("No limit", text: $session.budgetText)
                    .focused($focusedField, equals: .budget)
                    .keyboardType(.numberPad)
                    .accessibilityLabel("Budget, up to dollars")
                    .accessibilityIdentifier("findOneBudgetField")
            }
        }
    }

    /// "Include my size range": off by default, shows the exact text it adds, and only ever
    /// adds the rough size band label. Toggling it changes the reviewed intent; it never searches.
    @ViewBuilder
    private func sizeRange(_ profile: UserProfile) -> some View {
        let text = FindOneSession.sizeRangeText(profile: profile)
        FindOneToggleRow(
            title: "Include my size range",
            caption: sizeRangeState(text: text, fit: profile.bodyFit),
            info: sizeRangeCaption(text: text, fit: profile.bodyFit),
            isOn: text == nil ? .constant(false) : $session.includesSizeRange,
            isEnabled: text != nil,
            identifier: "findOneSizeRangeToggle"
        )
    }

    /// The short line under the switch. It always names the exact text the switch adds.
    private func sizeRangeState(text: String?, fit: BodyFit) -> String {
        guard let text else {
            return fit.source == .measurements ? "Not needed · your measurements are compared privately" : "Nothing to add yet"
        }
        return session.includesSizeRange ? "On · adds “\(text)”" : "Off · no size is sent. On adds “\(text)”."
    }

    private func sizeRangeCaption(text: String?, fit: BodyFit) -> String {
        guard let text else {
            return fit.source == .measurements
                ? "Not needed: your confirmed measurements are compared privately after the search. They're never added to it as numbers."
                : "Nothing to add. Your waist, hip and bust are Unknown. Add them in Profile so size charts can be compared privately after the search. They're never added to it as numbers."
        }
        let origin = "It's a rough estimate from your height and weight. Your weight itself is never sent."
        return session.includesSizeRange
            ? "On: adds “\(text)” to the search. \(origin)"
            : "Off: no size is sent. Turning it on adds “\(text)”. \(origin)"
    }

    private func retailers(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                Text("Store preferences")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                InfoButton("Store preferences",
                           text: "Tap a store to switch Preferred → Avoid → No preference. Stores are discovery hints, never sizing authorities. Saved to your Profile; changing them doesn't search.")
            }
            ChipCarousel(isExpanded: session.detailsBinding("stores"), itemsLabel: "stores") {
                ForEach(profile.retailers) { preference in
                    FindOneRetailerChip(
                        preference: preference,
                        onCycle: { cycle(preference.name) },
                        onSet: { preferred, avoided in set(preference.name, preferred: preferred, avoided: avoided) },
                        onRemove: { remove(preference.name) }
                    )
                }
            }
            HStack(spacing: Spacing.xs) {
                TextField("Add another store", text: $session.newStore)
                    .focused($focusedField, equals: .store)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit(addStore)
                    .padding(.horizontal, Spacing.s)
                    .frame(minHeight: HitTarget.minimum)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                    .accessibilityIdentifier("findOneAddStoreField")
                Button("Add", action: addStore)
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(session.newStore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Add store")
                    .accessibilityIdentifier("findOneAddStoreButton")
            }
        }
    }

    private func sentBox(intent: PublicShoppingIntent) -> some View {
        let hints = intent.preferredRetailers.isEmpty ? "none" : intent.preferredRetailers.joined(separator: ", ")
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text("Only this is sent to search: \(Text(intent.summary).fontWeight(.semibold)). No weight, measurements, photos, names or closet.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(Palette.primaryAction)
            }
            Text("Store hints: \(hints) · Only these retailers: \(intent.retailerOnly ? "On" : "Off")")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("findOneSentSummary")
    }

    // MARK: Retailer edits (profile only; no search)

    private func cycle(_ name: String) {
        app.store.updateProfile { profile in
            guard let i = profile.retailers.firstIndex(where: { $0.name == name }) else { return }
            let r = profile.retailers[i]
            if r.isAvoided {
                profile.retailers[i].isAvoided = false
                profile.retailers[i].isPreferred = false
            } else if r.isPreferred {
                profile.retailers[i].isPreferred = false
                profile.retailers[i].isAvoided = true
            } else {
                profile.retailers[i].isPreferred = true
            }
        }
    }

    private func set(_ name: String, preferred: Bool, avoided: Bool) {
        app.store.updateProfile { profile in
            guard let i = profile.retailers.firstIndex(where: { $0.name == name }) else { return }
            profile.retailers[i].isPreferred = preferred
            profile.retailers[i].isAvoided = avoided
        }
    }

    private func remove(_ name: String) {
        app.store.updateProfile { $0.retailers.removeAll { $0.name == name } }
    }

    private func addStore() {
        let name = session.newStore.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        session.newStore = ""
        guard !app.store.profile.retailers.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        app.store.updateProfile { $0.retailers.append(RetailerPreference(name: name)) }
    }
}

// MARK: - Permissions

struct FindOnePermissionSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let profile = app.store.profile
        let web = profile.permission(.webSearch)
        let ranking = profile.permission(.fitRanking)
        if web != .allowed || ranking != .allowed {
            VStack(spacing: Spacing.s) {
                if web != .allowed { card(.webSearch, state: web) }
                if ranking != .allowed { card(.fitRanking, state: ranking) }
            }
        }
    }

    private func card(_ purpose: ProcessingPurpose, state: PermissionState) -> some View {
        let isSearch = purpose == .webSearch
        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(isSearch ? "Allow Find One web search?" : "Private fit comparison (optional)",
                  systemImage: isSearch ? "magnifyingglass" : "ruler")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            if state == .declined {
                CollapsibleText(isSearch
                                ? "Web search is off, so Find One can't search. Your closet, saved products and manual browser search still work."
                                : "Private fit comparison is off. Results stay unranked as “Needs fit confirmation” with chart guidance you check yourself.",
                                summary: isSearch ? "Web search is off, so Find One can't search." : "Off, so results stay unranked.",
                                threshold: 1, font: .subheadline, color: Palette.primaryText,
                                topic: isSearch ? "web search being off" : "fit comparison being off")
            }
            InfoRow(title: "Recipient", value: purpose.recipient)
            VStack(alignment: .leading, spacing: 2) {
                Text("What's sent")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                Text(purpose.dataSent)
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { consentButtons(purpose, state: state, isSearch: isSearch) }
                VStack(alignment: .leading, spacing: Spacing.xs) { consentButtons(purpose, state: state, isSearch: isSearch) }
            }
            SimulationNotice(text: isSearch
                             ? "Simulated recipient — no real service is contacted. Change this any time in Profile."
                             : "Separate from web search — allowing one never allows the other. Simulated recipient — no real service is contacted. Change this any time in Profile.",
                             label: "Simulated recipient",
                             summary: isSearch ? nil : "Separate from web search")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .findOnePanel(highlighted: isSearch && state == .notAsked)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func consentButtons(_ purpose: ProcessingPurpose, state: PermissionState, isSearch: Bool) -> some View {
        Button {
            app.store.setPermission(purpose, .allowed)
        } label: {
            Text("Allow")
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
        .accessibilityLabel("Allow \(purpose.title)")
        .accessibilityIdentifier(isSearch ? "findOneAllowSearch" : "findOneAllowRanking")
        if state != .declined {
            Button("Not now") {
                app.store.setPermission(purpose, .declined)
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier(isSearch ? "findOneDeclineSearch" : "findOneDeclineRanking")
        }
    }
}

// MARK: - 3. Search

struct FindOneSearchControls: View {
    @Environment(AppModel.self) private var app
    var session: FindOneSession

    var body: some View {
        let profile = app.store.profile
        let searchAllowed = profile.permission(.webSearch) == .allowed
        let accessActive = app.store.access.plan.hasStylingAccess
        let hasGarment = !session.garment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: Spacing.s) {
            switch session.phase {
            case let .searching(startedAt), let .ranking(startedAt):
                progress(startedAt: startedAt)
            default:
                Button {
                    session.startSearch(app: app)
                } label: {
                    Label(session.record == nil ? "Search" : "Search again", systemImage: "magnifyingglass")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!accessActive || !searchAllowed || !hasGarment)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityHint("Runs one bounded simulated search with the details above")
                .accessibilityIdentifier("findOneSearchButton")
                let rankingAllowed = profile.permission(.fitRanking) == .allowed
                CollapsibleText(caption(accessActive: accessActive, searchAllowed: searchAllowed, hasGarment: hasGarment, rankingAllowed: rankingAllowed),
                                summary: shortCaption(accessActive: accessActive, searchAllowed: searchAllowed, hasGarment: hasGarment, rankingAllowed: rankingAllowed),
                                threshold: 1, font: .caption, topic: "this search",
                                isExpanded: session.detailsBinding("searchCaption"))
                if session.phase == .cancelled {
                    InlineBanner(style: .info, title: "Search cancelled", message: "Nothing was changed. Earlier results, if any, are still here.")
                }
                if case let .notCompleted(detail) = session.phase {
                    InlineBanner(style: .error, title: "Search not completed", message: "\(SearchOutcome.searchNotCompleted.explanation) \(detail)")
                }
                if case let .rankingIncomplete(detail) = session.phase {
                    InlineBanner(style: .caution, title: "Fit comparison didn't finish", message: detail)
                }
            }
        }
    }

    private func caption(accessActive: Bool, searchAllowed: Bool, hasGarment: Bool, rankingAllowed: Bool) -> String {
        if !accessActive { return "Styling access isn't active (sample terms), so Find One search and fit comparison are paused. Your closet, saved products and manual browser search still work." }
        if !searchAllowed { return "Allow web search above to search. Your closet and manual browser search still work." }
        if !hasGarment { return "Describe the garment to search for." }
        let ranking = rankingAllowed ? "then a private fit comparison" : "results stay unranked (fit comparison is off)"
        return "One explicit, bounded search: up to 5 sources and 5 leads, \(ranking). Simulated — no checkout."
    }

    /// One line under the Search button. Blockers and the size of the search stay on screen.
    private func shortCaption(accessActive: Bool, searchAllowed: Bool, hasGarment: Bool, rankingAllowed: Bool) -> String {
        if !accessActive { return "Styling access isn't active, so search is paused." }
        if !searchAllowed { return "Allow web search above to search." }
        if !hasGarment { return "Describe the garment to search for." }
        return rankingAllowed ? "One simulated search, up to 5 leads." : "One simulated search, up to 5 leads, unranked."
    }

    private func progress(startedAt: Date) -> some View {
        let isRanking: Bool = {
            if case .ranking = session.phase { return true }
            return false
        }()
        return VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                ProgressView()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isRanking ? "Comparing fit privately…" : "Searching a bounded set of stores…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    TimelineView(.periodic(from: startedAt, by: 1)) { context in
                        Text("\(max(0, Int(context.date.timeIntervalSince(startedAt)))) s · simulated · 30-second limit")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.secondaryText)
                    }
                }
            }
            if session.showsSlowNotice {
                Label("Still searching — you can cancel", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityIdentifier("findOneSlowNotice")
            }
            Button {
                session.cancel()
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityHint("Stops this search. Nothing is invented.")
            .accessibilityIdentifier("findOneCancel")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .findOnePanel()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isRanking ? "Comparing fit privately" : "Searching")
    }
}

// MARK: - Manual browser fallback

struct FindOneManualFallback: View {
    @Environment(AppModel.self) private var app
    var session: FindOneSession
    @State private var copied = false

    var body: some View {
        let intent = session.intent(profile: app.store.profile)
        let query = intent.summary
        CardSection("Search yourself (unverified)",
                    subtitle: intent.sizeRange == nil ? nil : "Includes the size range you turned on.",
                    info: intent.sizeRange == nil
                        ? "Search yourself in your browser. Copy the public query and search anywhere. Nothing from your profile is included, and results there aren't checked here."
                        : "Search yourself in your browser. Copy the public query and search anywhere. From your profile it includes only the size range you turned on, and results there aren't checked here.",
                    systemImage: "safari") {
            Text(query)
                .font(.body.monospaced())
                .foregroundStyle(Palette.primaryText)
                .textSelection(.enabled)
                .padding(Spacing.s)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                .accessibilityLabel("Public query: \(query)")
            Button {
                UIPasteboard.general.string = query
                copied = true
            } label: {
                Label(copied ? "Copied" : "Copy query", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("findOneCopyQuery")
            .task(id: copied) {
                guard copied else { return }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                copied = false
            }
        }
    }
}
