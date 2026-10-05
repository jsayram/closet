import SwiftUI

// MARK: - Fit preferences

/// Profile → Fit preferences: rise, lengths, usual fit and usual sizes.
struct ProfileFitPreferencesSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let profile = app.store.profile
        Section {
            textRow(.rise, profile: profile, stacksValue: true)
            textRow(.pantsLength, profile: profile, stacksValue: true)
            textRow(.jacketLength, profile: profile, stacksValue: true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ProfileInfoLabel(
                    title: "Usual fit",
                    info: "Your everyday preference, used by Style Me and the stylist chat unless you pick something else for one request. That choice never changes this."
                )
                ChipCarousel(isExpanded: app.profileUI.detailsBinding("usualFitChips"), itemsLabel: "fit choices") {
                    ForEach(Comfort.allCases) { comfort in
                        CapsuleChip(title: comfort.label, isSelected: profile.usualFit == comfort) {
                            guard app.store.profile.usualFit != comfort else { return }
                            app.profileSave { $0.usualFit = comfort }
                        }
                        .accessibilityIdentifier("profileUsualFit-\(comfort.rawValue)")
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Usual fit")

            textRow(.topSize, profile: profile, caption: "Optional · include brand or sizing system")
            textRow(.bottomSize, profile: profile, caption: "Optional · include brand or sizing system")
        } header: {
            ProfileListHeader(
                "Fit preferences",
                subtitle: "How you like clothes to sit.",
                info: "A Petite label isn't required — a regular or cropped piece can work better when its proportions suit you.",
                systemImage: "slider.horizontal.below.rectangle"
            )
        }
        .listRowBackground(Palette.surface)
    }

    private func textRow(_ field: ProfileTextField, profile: UserProfile, caption: String? = nil, stacksValue: Bool = false) -> some View {
        ProfileEditableRow(
            title: field.title,
            caption: caption,
            value: field.value(in: profile),
            emptyLabel: field.emptyLabel,
            stacksValue: stacksValue
        ) {
            app.profileUI.openText(field, profile: app.store.profile)
        }
        .accessibilityIdentifier("profilePreference-\(field.rawValue)")
    }
}

// MARK: - Style & color

/// Profile → Style & color: style words, liked/avoided color pairs and budget.
struct ProfileStyleColorSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var ui = app.profileUI
        let profile = app.store.profile
        Section {
            // Style words
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Style words")
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                if profile.styleWords.isEmpty {
                    ProfileValueText(value: nil, emptyLabel: "None yet")
                        .font(.subheadline)
                } else {
                    ChipCarousel(isExpanded: app.profileUI.detailsBinding("styleWordChips"), itemsLabel: "style words") {
                        ForEach(profile.styleWords, id: \.self) { word in
                            ProfileRemovableChip(title: word) {
                                app.profileSave { $0.styleWords.removeAll { $0 == word } }
                            }
                        }
                    }
                }
                ProfileAddField(placeholder: "Add a style word", text: $ui.newStyleWord, identifier: "styleWordAdd") {
                    addStyleWord()
                }
            }
            .padding(.vertical, Spacing.xxs)

            // Liked pairs
            ProfileColorPairList(
                title: "Color pairs you like",
                note: nil,
                pairs: profile.likedColorPairs,
                placeholder: "e.g. Navy + light pink",
                text: $ui.newLikedPair,
                identifier: "likedPairAdd",
                onRemove: { pair in app.profileSave { $0.likedColorPairs.removeAll { $0 == pair } } },
                onAdd: addLikedPair
            )

            // Avoided pairs
            ProfileColorPairList(
                title: "Color pairs you'd rather avoid",
                note: "A preference, not a rule — an explicit color request still wins.",
                pairs: profile.avoidedColorPairs,
                placeholder: "e.g. Strong red + green",
                text: $ui.newAvoidedPair,
                identifier: "avoidedPairAdd",
                onRemove: { pair in app.profileSave { $0.avoidedColorPairs.removeAll { $0 == pair } } },
                onAdd: addAvoidedPair
            )

            ProfileBudgetRow()
        } header: {
            ProfileListHeader(
                "Style & color",
                subtitle: "Chic, coordinated, never forced neutral.",
                info: "These guide your looks. They're reversible preferences, and explicit monochrome is always fine.",
                systemImage: "paintpalette"
            )
        }
        .listRowBackground(Palette.surface)
    }

    private func addStyleWord() {
        let word = app.profileUI.newStyleWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }
        app.profileUI.newStyleWord = ""
        if app.store.profile.styleWords.contains(where: { $0.caseInsensitiveCompare(word) == .orderedSame }) {
            app.showToast("“\(word)” is already one of your style words.", style: .info)
            return
        }
        app.profileSave { $0.styleWords.append(word) }
    }

    private func addLikedPair() {
        let pair = app.profileUI.newLikedPair.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pair.isEmpty else { return }
        app.profileUI.newLikedPair = ""
        guard !app.store.profile.likedColorPairs.contains(where: { $0.caseInsensitiveCompare(pair) == .orderedSame }) else {
            app.showToast("That pair is already on your list.", style: .info)
            return
        }
        app.profileSave { $0.likedColorPairs.append(pair) }
    }

    private func addAvoidedPair() {
        let pair = app.profileUI.newAvoidedPair.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pair.isEmpty else { return }
        app.profileUI.newAvoidedPair = ""
        guard !app.store.profile.avoidedColorPairs.contains(where: { $0.caseInsensitiveCompare(pair) == .orderedSame }) else {
            app.showToast("That pair is already on your list.", style: .info)
            return
        }
        app.profileSave { $0.avoidedColorPairs.append(pair) }
    }
}

/// Capsule chip with a remove action.
struct ProfileRemovableChip: View {
    var title: String
    var onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: Spacing.xxs + 2) {
                Text(title)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "xmark")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.secondaryText)
            }
            .foregroundStyle(Palette.primaryText)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(Palette.accentSurface))
            .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(title)
        .accessibilityHint("Removes this style word")
        .accessibilityIdentifier("styleWord-\(title)")
    }
}

/// A titled list of color pairs with remove buttons and an add field.
struct ProfileColorPairList: View {
    var title: String
    var note: String?
    var pairs: [String]
    var placeholder: String
    @Binding var text: String
    var identifier: String
    var onRemove: (String) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let note {
                ProfileInfoLabel(title: title, info: note)
            } else {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
            }
            if pairs.isEmpty {
                ProfileValueText(value: nil, emptyLabel: "None yet")
                    .font(.subheadline)
            }
            ForEach(pairs, id: \.self) { pair in
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "circle.lefthalf.filled")
                        .foregroundStyle(Palette.primaryAction)
                        .accessibilityHidden(true)
                    Text(pair)
                        .font(.subheadline)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: Spacing.xs)
                    Button {
                        onRemove(pair)
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.body)
                            .foregroundStyle(Palette.error)
                            .minimumHitTarget()
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityLabel("Remove \(pair)")
                }
            }
            ProfileAddField(placeholder: placeholder, text: $text, identifier: identifier, onAdd: onAdd)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// Budget ceiling for one new piece (Find One). Optional; nil means no limit.
struct ProfileBudgetRow: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let budget = app.store.profile.budgetMax
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ProfileInfoLabel(
                title: "Budget for one new piece",
                info: "Find One uses this as a ceiling. Store prices shown in this prototype are simulated, never final."
            )
            if let budget {
                Stepper(value: Binding(
                    get: { app.store.profile.budgetMax ?? budget },
                    set: { newValue in app.profileSave { $0.budgetMax = newValue } }
                ), in: 10...1000, step: 10) {
                    Text("Up to $\(budget)")
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                }
                .accessibilityLabel("Budget maximum")
                .accessibilityValue("Up to \(budget) dollars")
                .accessibilityIdentifier("profileBudgetStepper")
                Button("No budget limit") {
                    app.profileSave { $0.budgetMax = nil }
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                ProfileValueText(value: nil, emptyLabel: "No limit set")
                    .font(.subheadline)
                Button {
                    app.profileSave { $0.budgetMax = 80 }
                } label: {
                    Label("Set a budget", systemImage: "dollarsign.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

#Preview("Preferences") {
    NavigationStack {
        List {
            ProfileFitPreferencesSection()
            ProfileStyleColorSection()
        }
        .scrollContentBackground(.hidden)
        .themedScreenBackground()
    }
    .previewEnvironment()
}
