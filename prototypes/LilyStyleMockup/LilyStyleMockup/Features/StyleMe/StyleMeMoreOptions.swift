import SwiftUI

/// Secondary request controls, collapsed by default: today-only comfort, required/preferred color,
/// wardrobe mode, and the separately explicit new-piece idea.
struct StyleMeMoreOptionsSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let expanded = app.styleMeUI.showMoreOptions
        VStack(alignment: .leading, spacing: Spacing.m) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { app.styleMeUI.showMoreOptions.toggle() }
            } label: {
                HStack(spacing: Spacing.s) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("More options")
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                        Text(summary)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: Spacing.xs)
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.primaryAction)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: HitTarget.minimum)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .hoverEffect(.highlight)
            .accessibilityElement(children: .combine)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Comfort, color, wardrobe mode and new-piece ideas")
            .accessibilityIdentifier("moreOptionsToggle")

            if expanded {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    StyleMeComfortOptions()
                    StyleMeColorOptions()
                    StyleMeModeOptions()
                    StyleMeNewPieceOption()
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle()
    }

    /// What's set, so collapsed options are never hidden surprises.
    private var summary: String {
        let draft = app.style.draft
        let scope = app.workingScope
        var parts: [String] = []
        if let comfort = draft.comfort {
            parts.append("\(comfort.label) today")
        } else {
            parts.append("\(app.store.profile.usualFit.label) (usual fit)")
        }
        if let color = draft.colorConstraint { parts.append("\(color.family.label) \(color.strength.label.lowercased())") }
        parts.append(StyleMeFormat.modeText(scope: scope, mode: draft.mode))
        if draft.allowNewPiece, !scope.isSuitcase { parts.append("1 new-piece idea") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Comfort (today only)

struct StyleMeComfortOptions: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            StyleMeOptionHeader(title: "Today's comfort",
                                info: "When nothing is picked, your usual fit (\(app.store.profile.usualFit.label)) is used. A choice here is for today only and doesn't change your profile. Tap a choice again to clear it.")
            ChipCarousel(isExpanded: app.styleMeUI.disclosure("comfortChips"), itemsLabel: "comfort choices") {
                ForEach(Comfort.allCases) { comfort in
                    CapsuleChip(title: comfort.label, isSelected: app.style.draft.comfort == comfort) {
                        app.style.draft.comfort = app.style.draft.comfort == comfort ? nil : comfort
                    }
                    .accessibilityHint("Today only. Tap again to clear.")
                    .accessibilityIdentifier("comfort-\(comfort.rawValue)")
                }
            }
            // Reports what's in effect; how it works is behind the info button.
            Label(app.style.draft.comfort == nil
                  ? "Using your usual fit (\(app.store.profile.usualFit.label))"
                  : "Today only",
                  systemImage: "calendar")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Color (required vs preferred, with scope)

struct StyleMeColorOptions: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let constraint = app.style.draft.colorConstraint
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                StyleMeOptionHeader(title: "Color",
                                    info: "Optional. Pick a color to require or prefer it — for this request only. Tap the color again to clear it.")
                Spacer(minLength: Spacing.xs)
                if constraint != nil {
                    Button("Clear") { app.style.draft.colorConstraint = nil }
                        .font(.subheadline.weight(.semibold))
                        .minimumHitTarget()
                        .accessibilityLabel("Clear color")
                        .accessibilityIdentifier("clearColorButton")
                }
            }
            ChipCarousel(isExpanded: app.styleMeUI.disclosure("colorChips"), itemsLabel: "colors") {
                ForEach(ColorFamily.allCases) { family in
                    StyleMeColorChip(family: family, isSelected: constraint?.family == family) {
                        select(family)
                    }
                }
            }
            if let constraint {
                StyleMeChoicePicker(title: "Strength", selection: strengthBinding, options: ColorStrength.allCases,
                                    label: { $0.label }, identifier: "colorStrengthPicker")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) {
                        appliesToLabel
                        Spacer(minLength: Spacing.xs)
                        scopePicker
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        appliesToLabel
                        scopePicker
                    }
                }
                .frame(minHeight: HitTarget.minimum)
                CollapsibleText(explanation(constraint), summary: summary(constraint), threshold: 1,
                                topic: "how this color is used",
                                isExpanded: app.styleMeUI.disclosure("colorExplanation"))
            }
        }
    }

    private var appliesToLabel: some View {
        Text("Applies to")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.secondaryText)
            .accessibilityHidden(true)
    }

    private var scopePicker: some View {
        Picker("Applies to", selection: scopeBinding) {
            ForEach(ColorScope.allCases) { Text($0.label).tag($0) }
        }
        .pickerStyle(.menu)
        .minimumHitTarget()
        .accessibilityIdentifier("colorScopePicker")
    }

    private func select(_ family: ColorFamily) {
        if let current = app.style.draft.colorConstraint {
            app.style.draft.colorConstraint = current.family == family
                ? nil
                : ColorConstraint(family: family, strength: current.strength, scope: current.scope)
        } else {
            app.style.draft.colorConstraint = ColorConstraint(family: family, strength: .preferred, scope: .anyPiece)
        }
    }

    private var strengthBinding: Binding<ColorStrength> {
        Binding(
            get: { app.style.draft.colorConstraint?.strength ?? .preferred },
            set: { app.style.draft.colorConstraint?.strength = $0 }
        )
    }

    private var scopeBinding: Binding<ColorScope> {
        Binding(
            get: { app.style.draft.colorConstraint?.scope ?? .anyPiece },
            set: { app.style.draft.colorConstraint?.scope = $0 }
        )
    }

    /// What's set, in a few words.
    private func summary(_ c: ColorConstraint) -> String {
        "\(c.strength.label): \(c.family.label.lowercased()) \(StyleMeFormat.colorScopePhrase(c.scope))"
    }

    private func explanation(_ c: ColorConstraint) -> String {
        let place = StyleMeFormat.colorScopePhrase(c.scope)
        switch c.strength {
        case .required:
            return "Required: every look includes \(c.family.label.lowercased()) \(place), using real pieces only. If nothing fits, you'll see why — the color is never painted onto a different garment."
        case .preferred:
            return "Preferred: \(c.family.label.lowercased()) \(place) is used when it works; looks without it can still appear."
        }
    }
}

/// Swatch + name chip. Selection uses a checkmark and outline, not color alone.
struct StyleMeColorChip: View {
    var family: ColorFamily
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        CapsuleChip(title: family.label, isSelected: isSelected, swatchHex: family.swatchHex, action: action)
            .accessibilityLabel(family.label)
            .accessibilityHint(isSelected ? "Tap again to clear the color" : "Uses this color for this request")
            .accessibilityIdentifier("color-\(family.rawValue)")
    }
}

// MARK: - Mode

struct StyleMeModeOptions: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            StyleMeOptionHeader(title: "Wardrobe mode", info: app.workingScope.isSuitcase
                                ? "Only clothes in \(app.workingScopeName) are used — nothing outside it and no invented pieces. To style more broadly, switch to Main Closet at the top."
                                : "Suggestions: Uses your clothes first. Where something's missing, ideas you don't own are clearly labelled.\n\nUse only my wardrobe: Every piece comes from your current, available clothes. Nothing invented.")
            if app.workingScope.isSuitcase {
                Label("Use only this suitcase (strict)", systemImage: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(Spacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                    .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("modePicker")
            } else {
                StyleMeChoicePicker(title: "Mode", selection: modeBinding, options: [StyleMode.suggestions, .ownedOnly],
                                    label: { $0 == .suggestions ? "Suggestions" : "Use only my wardrobe" }, identifier: "modePicker")
            }
        }
    }

    private var modeBinding: Binding<StyleMode> {
        Binding(get: { app.style.draft.mode }, set: { app.style.draft.mode = $0 })
    }
}

// MARK: - New-piece idea (independent, explicit, Main Closet only)

struct StyleMeNewPieceOption: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let inSuitcase = app.workingScope.isSuitcase
        let binding = Binding<Bool>(
            get: { !inSuitcase && app.style.draft.allowNewPiece },
            set: { app.style.draft.allowNewPiece = inSuitcase ? false : $0 }
        )
        VStack(alignment: .leading, spacing: Spacing.xs) {
            StyleMeOptionHeader(title: "New-piece idea", info: inSuitcase
                                ? "Not available in a suitcase: strict suitcase looks only use clothes in \(app.workingScopeName). Switch to Main Closet to include one."
                                : "Off unless you turn it on. One look may include a clearly labelled piece you don't own. It never starts shopping — Find One stays your choice.")
            Toggle(isOn: binding) {
                Text("Include one new-piece idea (not owned)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .tint(Palette.primaryAction)
            .disabled(inSuitcase)
            .accessibilityIdentifier("newPieceToggle")
            if inSuitcase {
                // Why the switch is disabled stays on screen, in short form.
                Text("Not available in a suitcase.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
