import SwiftUI

/// Onboarding pages. Every page can be skipped; nothing requires an account,
/// a full closet upload or a body photo.
enum ProfileOnboardingStep: Int, CaseIterable, Identifiable, Hashable {
    case welcome, measurements, access, privacy

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .measurements: "Optional measurements"
        case .access: "What's free"
        case .privacy: "Privacy"
        }
    }

    var next: ProfileOnboardingStep? { ProfileOnboardingStep(rawValue: rawValue + 1) }
    var previous: ProfileOnboardingStep? { ProfileOnboardingStep(rawValue: rawValue - 1) }
}

/// Root onboarding sheet: four short, skippable pages.
struct OnboardingView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var forward = true

    var body: some View {
        let step = app.profileUI.onboardingStep
        NavigationStack {
            VStack(spacing: 0) {
                ProfileOnboardingProgress(step: step)
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.s)
                ScrollView {
                    ZStack(alignment: .top) {
                        page(step)
                            .padding(.horizontal, Spacing.m)
                            .padding(.top, Spacing.s)
                            .padding(.bottom, Spacing.l)
                            .readableWidth(620)
                            .id(step)
                            .transition(transition)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                bottomBar(step)
            }
            .themedScreenBackground()
            .navigationTitle(step.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { complete() }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityHint("Closes the welcome. You can change everything later in Profile.")
                        .accessibilityIdentifier("onboardingSkip")
                }
            }
        }
        .onDisappear {
            // Swiping the sheet away counts as Skip; it never changes permissions.
            if !app.store.hasCompletedOnboarding {
                app.store.hasCompletedOnboarding = true
                app.store.persist()
            }
            // Reset after the sheet is gone so the next visit starts at Welcome without a flash.
            app.profileUI.resetOnboarding()
        }
    }

    private var transition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal: .opacity
        )
    }

    @ViewBuilder
    private func page(_ step: ProfileOnboardingStep) -> some View {
        switch step {
        case .welcome: ProfileOnboardingWelcome()
        case .measurements: ProfileOnboardingMeasurements()
        case .access: ProfileOnboardingAccess()
        case .privacy: ProfileOnboardingPrivacy()
        }
    }

    private func bottomBar(_ step: ProfileOnboardingStep) -> some View {
        let buttons = Group {
            if let previous = step.previous {
                Button {
                    go(to: previous, forward: false)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(SecondaryButtonStyle(fullWidth: dynamicTypeSize.isAccessibilitySize))
                .keyboardShortcut("[", modifiers: .command)
                .accessibilityIdentifier("onboardingBack")
            }
            if let next = step.next {
                Button {
                    go(to: next, forward: true)
                } label: {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("onboardingContinue")
            } else {
                Button {
                    complete()
                } label: {
                    Text("Finish")
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("onboardingFinish")
            }
        }
        return VStack(spacing: 0) {
            Rectangle().fill(Palette.divider).frame(height: 1).accessibilityHidden(true)
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: Spacing.xs) { buttons }
                } else {
                    HStack(spacing: Spacing.s) { buttons }
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .readableWidth(620)
        }
        .background(Palette.background)
    }

    private func go(to step: ProfileOnboardingStep, forward: Bool) {
        self.forward = forward
        app.profileUI.onboardingSavedNote = nil
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            app.profileUI.onboardingStep = step
        }
    }

    /// Finish and Skip: mark onboarding complete and close. Permissions are untouched.
    private func complete() {
        app.store.hasCompletedOnboarding = true
        app.store.persist()
        app.sheet = nil
    }
}

/// "Step 2 of 4" with capsule segments (text + shape, not color alone).
struct ProfileOnboardingProgress: View {
    var step: ProfileOnboardingStep

    var body: some View {
        let total = ProfileOnboardingStep.allCases.count
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xxs) {
                ForEach(ProfileOnboardingStep.allCases) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? Palette.primaryAction : Palette.controlBorder.opacity(0.5))
                        .frame(height: s == step ? 6 : 4)
                }
            }
            .accessibilityHidden(true)
            Text("Step \(step.rawValue + 1) of \(total) · skippable")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
        }
        .readableWidth(620)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step.rawValue + 1) of \(total): \(step.title). Every step is optional.")
    }
}

// MARK: - Page 1: Welcome

struct ProfileOnboardingWelcome: View {
    @Environment(AppModel.self) private var app

    private var sampleGarments: [Garment] {
        ["g-pink-blouse", "g-navy-trousers", "g-nude-flats", "g-brown-jacket"].compactMap { app.store.garment($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("My Petite Style")
                    .font(.editorial(.subheadline))
                    .foregroundStyle(Palette.primaryAction)
                Text("Outfits from the clothes you already own")
                    .font(.editorial(.largeTitle))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Pieces are paired with petite proportions in mind: jacket lengths, rise, hems and shoes.")
                    .font(.body)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !sampleGarments.isEmpty {
                HStack(spacing: Spacing.xs) {
                    ForEach(sampleGarments) { garment in
                        GarmentArtwork(kind: garment.kind, hex: garment.color?.hex)
                            .frame(maxWidth: 96)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Illustration: " + sampleGarments.map(\.displayName).joined(separator: ", ") + " from the demo closet")
            }

            VStack(alignment: .leading, spacing: Spacing.s) {
                ProfileBullet(systemImage: "sparkles", text: "Three looks from your own clothes")
                ProfileBullet(systemImage: "tray.and.arrow.down", text: "Start small, add pieces as you go")
                ProfileBullet(systemImage: "person.crop.circle.badge.xmark", text: "No body photo and no account needed.")
                DetailsDisclosure(
                    "How it works",
                    count: 3,
                    isExpanded: app.profileUI.detailsBinding("onboardingWelcome"),
                    identifier: "onboardingWelcomeDetails"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        ProfileBullet(systemImage: "sparkles", text: "Three directions from your own clothes: a Safe / Simple look and two Elevated ones.")
                        ProfileBullet(systemImage: "ruler", text: "Shopping is optional. When you ask for ideas, they're ranked by how they'll fit you, not by a Petite label.")
                        ProfileBullet(systemImage: "tray.and.arrow.down", text: "Start small. No full closet upload — add pieces as you go, even as text.")
                    }
                }
            }
            .cardStyle()

            SimulationNotice(
                text: "Prototype with fictional demo data. Styling and pictures are simulated, and nothing is sent anywhere.",
                label: "Prototype",
                summary: "Demo data. Nothing is sent."
            )
        }
    }
}

// MARK: - Page 2: Optional measurements

struct ProfileOnboardingMeasurements: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var ui = app.profileUI
        let profile = app.store.profile
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Only what's useful")
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                CollapsibleText(
                    "All optional, and Unknown stays unknown. Waist, hip and bust guide fit best. Weight is only a rough fallback when those are missing, and it's never shared.",
                    summary: "All optional. Unknown stays unknown.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "optional measurements",
                    isExpanded: app.profileUI.detailsBinding("onboardingMeasurementsIntro")
                )
            }

            heightCard(profile: profile, ui: ui)
            bodyCard(profile: profile, ui: ui)
            inseamCard(profile: profile, ui: ui)
            weightCard(profile: profile, ui: ui)
            usualFitCard(profile: profile)

            if let note = ui.onboardingSavedNote {
                Label(note, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.success)
                    .accessibilityIdentifier("onboardingSavedNote")
            }
        }
    }

    // Height
    @ViewBuilder
    private func heightCard(profile: UserProfile, ui: ProfileUIState) -> some View {
        @Bindable var ui = ui
        let fact = profile.measurement(.height)
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .center) {
                ProfileInfoLabel(
                    title: "Height",
                    info: "Used for proportions. With your weight, it gives only a rough size estimate when waist, hip and bust are missing. It never sets your inseam.",
                    font: .headline
                )
                Spacer()
                if let fact {
                    Text(fact.displayValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                } else {
                    Text("Unknown").italic().foregroundStyle(Palette.secondaryText)
                }
            }
            if let fact, fact.confirmed {
                ProfileToneBadge(text: fact.provenance, systemImage: "checkmark.seal", tone: .success)
            }
            if ui.onboardingEditingHeight {
                Stepper(value: $ui.onboardingHeightFeet, in: 3...7) {
                    Text("\(ui.onboardingHeightFeet) ft").monospacedDigit()
                }
                .accessibilityLabel("Feet")
                .accessibilityValue("\(ui.onboardingHeightFeet)")
                Stepper(value: $ui.onboardingHeightInches, in: 0...11) {
                    Text("\(ui.onboardingHeightInches) in").monospacedDigit()
                }
                .accessibilityLabel("Inches")
                .accessibilityValue("\(ui.onboardingHeightInches)")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) { heightEditButtons(ui: ui) }
                    VStack(alignment: .leading, spacing: Spacing.xs) { heightEditButtons(ui: ui) }
                }
            } else {
                Button(fact == nil ? "Add height" : "Change") {
                    if let fact, fact.unit == .inches {
                        ui.onboardingHeightFeet = Int(fact.value) / 12
                        ui.onboardingHeightInches = Int(fact.value) % 12
                    }
                    ui.onboardingEditingHeight = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("onboardingHeightChange")
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func heightEditButtons(ui: ProfileUIState) -> some View {
        Button("Save height") { saveHeight() }
            .buttonStyle(SuccessButtonStyle())
            .accessibilityIdentifier("onboardingHeightSave")
        Button("Cancel") { ui.onboardingEditingHeight = false }
            .buttonStyle(SecondaryButtonStyle())
    }

    private func saveHeight() {
        let ui = app.profileUI
        let total = ui.onboardingHeightFeet * 12 + ui.onboardingHeightInches
        let fact = MeasurementFact(dimension: .height, value: Double(total), unit: .inches, basis: .body,
                                   provenance: "Confirmed by \(app.profileOwnerName)", confirmed: true, updatedAt: .now)
        app.store.updateProfile { profile in
            profile.measurements.removeAll { $0.dimension == .height }
            profile.measurements.append(fact)
        }
        ui.onboardingEditingHeight = false
        announce("Height saved on this device")
    }

    // Inseam
    @ViewBuilder
    private func inseamCard(profile: UserProfile, ui: ProfileUIState) -> some View {
        @Bindable var ui = ui
        let fact = profile.measurement(.inseam)
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .center) {
                ProfileInfoLabel(title: "Inseam", info: MeasurementDimension.inseam.help, font: .headline)
                Spacer()
                if let fact {
                    Text(fact.displayValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                } else {
                    Text("Unknown").italic().foregroundStyle(Palette.secondaryText)
                }
            }
            if let fact, !ui.onboardingAddingInseam {
                FlowLayout(spacing: Spacing.xxs) {
                    if fact.confirmed {
                        ProfileToneBadge(text: fact.provenance, systemImage: "checkmark.seal", tone: .success)
                    } else {
                        ProfileToneBadge(text: "Not confirmed", systemImage: "questionmark.circle", tone: .caution)
                    }
                    ProfileToneBadge(text: fact.basis.label, systemImage: "ruler", tone: .neutral)
                }
                if !fact.confirmed {
                    Text("Pre-filled from earlier notes. It isn't used for fit until you confirm it.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    ActionGroup(moreIdentifier: "onboardingInseamMore") {
                        Button("Confirm \(fact.displayValue)") { confirmInseam() }
                            .buttonStyle(SuccessButtonStyle())
                            .accessibilityIdentifier("onboardingInseamConfirm")
                        Button("Change") {
                            ui.onboardingInseamText = fact.value.formatted()
                            ui.onboardingInseamUnit = fact.unit
                            ui.onboardingInseamBasis = fact.basis
                            ui.onboardingAddingInseam = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityIdentifier("onboardingInseamChange")
                    } more: {
                        Button("Clear — back to Unknown", systemImage: "eraser", role: .destructive) { clearInseam() }
                    }
                } else {
                    Button("Clear — back to Unknown") { clearInseam() }
                        .buttonStyle(DestructiveButtonStyle())
                }
            } else {
                if fact == nil {
                    FlowLayout(spacing: Spacing.xs) {
                        ProfileOnboardingChoiceChip(title: "Skip for now (stays Unknown)", systemImage: "forward", isSelected: !ui.onboardingAddingInseam) {
                            ui.onboardingAddingInseam = false
                        }
                        .accessibilityIdentifier("onboardingInseamSkip")
                        ProfileOnboardingChoiceChip(title: "Add inseam", systemImage: "plus", isSelected: ui.onboardingAddingInseam) {
                            ui.onboardingAddingInseam = true
                        }
                        .accessibilityIdentifier("onboardingInseamAdd")
                    }
                }
                if ui.onboardingAddingInseam {
                    HStack(spacing: Spacing.xs) {
                        TextField("Inseam", text: $ui.onboardingInseamText)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, Spacing.s)
                            .frame(minHeight: HitTarget.minimum)
                            .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.background))
                            .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                            .accessibilityLabel("Inseam value")
                            .accessibilityIdentifier("onboardingInseamValue")
                        Picker("Unit", selection: $ui.onboardingInseamUnit) {
                            Text("in").tag(MeasurementUnit.inches)
                            Text("cm").tag(MeasurementUnit.centimeters)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 120)
                    }
                    Picker("What it measures", selection: $ui.onboardingInseamBasis) {
                        ForEach(MeasurementBasis.allCases) { basis in
                            Text(basis.label).tag(basis)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(ui.onboardingInseamBasis.profileHelp)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                    FlowLayout(spacing: Spacing.xs) {
                        Button("Save inseam") { saveInseam() }
                            .buttonStyle(SuccessButtonStyle())
                            .disabled(inseamValue == nil)
                        if fact != nil {
                            Button("Cancel") {
                                ui.onboardingAddingInseam = false
                                ui.onboardingInseamText = ""
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func clearInseam() {
        app.store.updateProfile { $0.measurements.removeAll { $0.dimension == .inseam } }
        announce("Inseam cleared. It's Unknown again")
    }

    private var inseamValue: Double? {
        let ui = app.profileUI
        let text = ui.onboardingInseamText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(text), v > 0, v <= (ui.onboardingInseamUnit == .inches ? 60 : 150) else { return nil }
        return (v * 10).rounded() / 10
    }

    /// She agrees the pre-filled value is right; from now on it can guide fit.
    private func confirmInseam() {
        app.store.updateProfile { profile in
            guard let i = profile.measurements.firstIndex(where: { $0.dimension == .inseam }) else { return }
            profile.measurements[i].confirmed = true
            profile.measurements[i].provenance = "Confirmed by \(app.profileOwnerName)"
            profile.measurements[i].updatedAt = .now
        }
        announce("Inseam confirmed")
    }

    private func saveInseam() {
        guard let value = inseamValue else { return }
        let ui = app.profileUI
        let fact = MeasurementFact(dimension: .inseam, value: value, unit: ui.onboardingInseamUnit, basis: ui.onboardingInseamBasis,
                                   provenance: "Confirmed by \(app.profileOwnerName)", confirmed: true, updatedAt: .now)
        app.store.updateProfile { profile in
            profile.measurements.removeAll { $0.dimension == .inseam }
            profile.measurements.append(fact)
        }
        ui.onboardingAddingInseam = false
        ui.onboardingInseamText = ""
        announce("Inseam saved on this device")
    }

    // Waist, hip and bust
    @ViewBuilder
    private func bodyCard(profile: UserProfile, ui: ProfileUIState) -> some View {
        @Bindable var ui = ui
        let dimensions = ProfileBodyTrioDraft.dimensions
        let hasAny = dimensions.contains { profile.measurement($0) != nil }
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .center) {
                ProfileInfoLabel(
                    title: "Waist, hip and bust",
                    info: "The main fit inputs. They shape what Fitted, Comfortable and Relaxed mean for you, and help compare size charts.",
                    font: .headline
                )
                Spacer(minLength: Spacing.xs)
                if !hasAny {
                    Text("Unknown").italic().foregroundStyle(Palette.secondaryText)
                }
            }
            if hasAny, !ui.onboardingAddingBody {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    ForEach(dimensions) { dimension in
                        let fact = profile.measurement(dimension)
                        InfoRow(title: dimension.profileShortLabel,
                                value: fact.map { $0.confirmed ? $0.displayValue : "\($0.displayValue), not confirmed" } ?? "Unknown",
                                valueIsUnknown: fact == nil)
                    }
                }
                FlowLayout(spacing: Spacing.xs) {
                    Button("Change") {
                        ui.onboardingBodyDraft = ProfileBodyTrioDraft(profile: app.store.profile)
                        ui.onboardingAddingBody = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("onboardingBodyChange")
                    Button("Clear — back to Unknown") { clearBody() }
                        .buttonStyle(DestructiveButtonStyle())
                }
            } else {
                if !hasAny {
                    FlowLayout(spacing: Spacing.xs) {
                        ProfileOnboardingChoiceChip(title: "Skip for now (stays Unknown)", systemImage: "forward", isSelected: !ui.onboardingAddingBody) {
                            ui.onboardingAddingBody = false
                        }
                        .accessibilityIdentifier("onboardingBodySkip")
                        ProfileOnboardingChoiceChip(title: "Add measurements", systemImage: "plus", isSelected: ui.onboardingAddingBody) {
                            if !ui.onboardingAddingBody { ui.onboardingBodyDraft = ProfileBodyTrioDraft() }
                            ui.onboardingAddingBody = true
                        }
                        .accessibilityIdentifier("onboardingBodyAdd")
                    }
                }
                if ui.onboardingAddingBody {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: Spacing.xs) { bodyFields(ui: ui) }
                        VStack(alignment: .leading, spacing: Spacing.xs) { bodyFields(ui: ui) }
                    }
                    Picker("Unit", selection: Binding(
                        get: { app.profileUI.onboardingBodyDraft.unit },
                        set: { app.profileUI.onboardingBodyDraft.convert(to: $0) }
                    )) {
                        Text("Inches").tag(MeasurementUnit.inches)
                        Text("Centimeters").tag(MeasurementUnit.centimeters)
                    }
                    .pickerStyle(.segmented)
                    Text(ui.onboardingBodyDraft.validationMessage ?? "Measured on your body. Fill in any of them; an empty one stays Unknown.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: Spacing.xs) {
                        Button("Save measurements") { saveBody() }
                            .buttonStyle(SuccessButtonStyle())
                            .disabled(!canSaveBody)
                            .accessibilityIdentifier("onboardingBodySave")
                        if hasAny {
                            Button("Cancel") { ui.onboardingAddingBody = false }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func bodyFields(ui: ProfileUIState) -> some View {
        ForEach(ProfileBodyTrioDraft.dimensions) { dimension in
            VStack(alignment: .leading, spacing: 2) {
                Text(dimension.profileShortLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
                TextField(ui.onboardingBodyDraft.unit.symbol, text: Binding(
                    get: { app.profileUI.onboardingBodyDraft.text(dimension) },
                    set: { app.profileUI.onboardingBodyDraft.texts[dimension] = $0 }
                ))
                .keyboardType(.decimalPad)
                .padding(.horizontal, Spacing.s)
                .frame(minWidth: 88, minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.background))
                .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                .accessibilityLabel("\(dimension.profileShortLabel) in \(ui.onboardingBodyDraft.unit == .inches ? "inches" : "centimeters")")
                .accessibilityIdentifier("onboardingBodyValue-\(dimension.rawValue)")
            }
        }
    }

    /// Something to save or clear, and nothing she typed is unusable.
    private var canSaveBody: Bool {
        let draft = app.profileUI.onboardingBodyDraft
        guard draft.invalidDimensions.isEmpty else { return false }
        let hasExisting = ProfileBodyTrioDraft.dimensions.contains { app.store.profile.measurement($0) != nil }
        return hasExisting || ProfileBodyTrioDraft.dimensions.contains { draft.entry($0) != .empty }
    }

    /// Saves what she typed as confirmed body measurements. A value she left as it was keeps
    /// its basis and confirmed state, so nothing is confirmed for her; an emptied field goes
    /// back to Unknown.
    private func saveBody() {
        let ui = app.profileUI
        let draft = ui.onboardingBodyDraft
        guard draft.invalidDimensions.isEmpty else { return }
        let owner = app.profileOwnerName
        app.store.updateProfile { profile in
            for dimension in ProfileBodyTrioDraft.dimensions {
                let existing = profile.measurement(dimension)
                switch draft.entry(dimension) {
                case .invalid:
                    continue
                case .empty:
                    profile.measurements.removeAll { $0.dimension == dimension }
                case let .value(value):
                    if let existing, Self.sameValue(existing, value, unit: draft.unit) { continue }
                    let fact = MeasurementFact(dimension: dimension, value: value, unit: draft.unit, basis: .body,
                                               provenance: "Confirmed by \(owner)", confirmed: true, updatedAt: .now)
                    profile.measurements.removeAll { $0.dimension == dimension }
                    profile.measurements.append(fact)
                }
            }
        }
        ui.onboardingAddingBody = false
        announce("Saved on this device. \(ProfileFitSourceRow.headline(for: app.store.profile.bodyFit))")
    }

    private static func sameValue(_ fact: MeasurementFact, _ value: Double, unit: MeasurementUnit) -> Bool {
        let existing = fact.unit == unit ? fact.value : (unit == .centimeters ? fact.value * 2.54 : fact.value / 2.54)
        return abs((existing * 10).rounded() / 10 - value) < 0.05
    }

    private func clearBody() {
        app.store.updateProfile { profile in
            profile.measurements.removeAll { ProfileBodyTrioDraft.dimensions.contains($0.dimension) }
        }
        app.profileUI.onboardingAddingBody = false
        announce("Waist, hip and bust cleared. They're Unknown again")
    }

    // Weight
    @ViewBuilder
    private func weightCard(profile: UserProfile, ui: ProfileUIState) -> some View {
        @Bindable var ui = ui
        let weight = profile.weight
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .center) {
                ProfileInfoLabel(
                    title: "Weight",
                    info: "Only for a rough size estimate when waist, hip and bust are missing. It's never shared: not in searches, stylist requests or exports.",
                    font: .headline
                )
                Spacer(minLength: Spacing.xs)
                if let weight, !ui.onboardingAddingWeight {
                    Text(weight.displayValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                } else if weight == nil {
                    Text("Not added").italic().foregroundStyle(Palette.secondaryText)
                }
            }
            Text("Rough estimate only. Never shared.")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)

            if weight != nil, !ui.onboardingAddingWeight {
                FlowLayout(spacing: Spacing.xs) {
                    Button("Change") {
                        ui.onboardingWeightDraft = ProfileWeightDraft(weight: app.store.profile.weight)
                        ui.onboardingAddingWeight = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("onboardingWeightChange")
                    Button("Clear") {
                        app.store.updateProfile { $0.weight = nil }
                        announce("Weight cleared")
                    }
                    .buttonStyle(DestructiveButtonStyle())
                }
            } else {
                if weight == nil {
                    FlowLayout(spacing: Spacing.xs) {
                        ProfileOnboardingChoiceChip(title: "Skip for now", systemImage: "forward", isSelected: !ui.onboardingAddingWeight) {
                            ui.onboardingAddingWeight = false
                        }
                        .accessibilityIdentifier("onboardingWeightSkip")
                        ProfileOnboardingChoiceChip(title: "Add weight", systemImage: "plus", isSelected: ui.onboardingAddingWeight) {
                            if !ui.onboardingAddingWeight { ui.onboardingWeightDraft = ProfileWeightDraft(weight: nil) }
                            ui.onboardingAddingWeight = true
                        }
                        .accessibilityIdentifier("onboardingWeightAdd")
                    }
                }
                if ui.onboardingAddingWeight {
                    HStack(spacing: Spacing.xs) {
                        TextField("Weight", text: $ui.onboardingWeightDraft.valueText)
                            .keyboardType(.decimalPad)
                            .padding(.horizontal, Spacing.s)
                            .frame(minHeight: HitTarget.minimum)
                            .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.background))
                            .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                            .accessibilityLabel("Weight in \(ui.onboardingWeightDraft.unit.label.lowercased())")
                            .accessibilityIdentifier("onboardingWeightValue")
                        Picker("Unit", selection: Binding(
                            get: { app.profileUI.onboardingWeightDraft.unit },
                            set: { app.profileUI.onboardingWeightDraft.convert(to: $0) }
                        )) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.symbol).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 120)
                    }
                    Text(weightHint(ui.onboardingWeightDraft))
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    FlowLayout(spacing: Spacing.xs) {
                        Button("Save weight") { saveWeight() }
                            .buttonStyle(SuccessButtonStyle())
                            .disabled(ui.onboardingWeightDraft.weight == nil)
                            .accessibilityIdentifier("onboardingWeightSave")
                        if weight != nil {
                            Button("Cancel") { ui.onboardingAddingWeight = false }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func weightHint(_ draft: ProfileWeightDraft) -> String {
        if !draft.isEmpty, let message = draft.validationMessage { return message }
        return draft.approximate
            ? "Saved as approximate. You can change that in Profile."
            : "Saved as a recent reading. You can change that in Profile."
    }

    private func saveWeight() {
        let ui = app.profileUI
        guard let weight = ui.onboardingWeightDraft.weight else { return }
        app.store.updateProfile { $0.weight = weight }
        ui.onboardingAddingWeight = false
        announce("Weight saved on this device")
    }

    // Usual fit
    private func usualFitCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ProfileInfoLabel(
                title: "Usual fit",
                info: "Your everyday preference, and the default for Style Me and the stylist chat. You can still pick something different for a single request.",
                font: .headline
            )
            ChipCarousel(isExpanded: app.profileUI.detailsBinding("onboardingUsualFitChips"), itemsLabel: "fit choices") {
                ForEach(Comfort.allCases) { comfort in
                    CapsuleChip(title: comfort.label, isSelected: profile.usualFit == comfort) {
                        guard app.store.profile.usualFit != comfort else { return }
                        app.store.updateProfile { $0.usualFit = comfort }
                        announce("Usual fit saved: \(comfort.label)")
                    }
                    .accessibilityIdentifier("onboardingUsualFit-\(comfort.rawValue)")
                }
            }
        }
        .cardStyle()
    }

    private func announce(_ text: String) {
        let message = app.store.lastSaveError == nil ? text : "Couldn't save on this device — try again"
        app.profileUI.onboardingSavedNote = message
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: - Page 3: Free core vs metered AI

struct ProfileOnboardingAccess: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let terms = access.terms
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your closet is free. Styling has a daily allowance.")
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("What's always free, and what uses styling access.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Free forever", systemImage: "checkmark.seal")
                    .font(.headline)
                    .foregroundStyle(Palette.success)
                Text("Your closet, saved looks, search and your own outfits.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                DetailsDisclosure(
                    "Everything that's free",
                    count: 6,
                    isExpanded: app.profileUI.detailsBinding("onboardingFree"),
                    identifier: "onboardingFreeDetails"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        ProfileBullet(systemImage: "cabinet", text: "Your closet and suitcases", tint: Palette.success)
                        ProfileBullet(systemImage: "bookmark", text: "Saved looks and every retained preview", tint: Palette.success)
                        ProfileBullet(systemImage: "magnifyingglass", text: "Search", tint: Palette.success)
                        ProfileBullet(systemImage: "square.grid.2x2", text: "Making and editing outfits yourself", tint: Palette.success)
                        ProfileBullet(systemImage: "square.and.arrow.up", text: "Export and import", tint: Palette.success)
                        ProfileBullet(systemImage: "person.2", text: "Ask another stylist (you copy or share a prompt yourself)", tint: Palette.success)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Styling access", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(Palette.primaryAction)
                    Spacer(minLength: Spacing.xs)
                    ProfileToneBadge(text: "Sample terms", systemImage: "flask", tone: .accent)
                }
                ProfileBullet(systemImage: "wand.and.stars", text: "Style Me: \(terms.dailyStylingAllowance) requests a day")
                ProfileBullet(systemImage: "arrow.left.arrow.right", text: "AI swaps: \(terms.dailySwapAllowance) a day")
                ProfileBullet(systemImage: "person.crop.rectangle", text: "On Me pictures, if enabled: \(terms.monthlyImageAllowance) a month")
                ProfileBullet(systemImage: "calendar", text: "\(terms.trialLabel), then \(terms.monthlyPriceLabel)/month. Auto-renews until cancelled.")
                CollapsibleText(
                    "Allowances reset daily. When access ends or the allowance runs out, your closet, saved looks and history stay.",
                    summary: "Your closet and saved looks always stay.",
                    threshold: 1,
                    topic: "allowances"
                )
                Divider().overlay(Palette.divider)
                InfoRow(title: "Your demo access", value: access.plan.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            SimulationNotice(
                text: "SAMPLE terms for review — not final prices. Nothing is purchased or charged in this prototype.",
                label: "Sample terms",
                summary: "Nothing is charged."
            )
        }
    }
}

// MARK: - Page 4: Privacy

struct ProfileOnboardingPrivacy: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let purpose = ProcessingPurpose.cloudStyling
        let state = app.store.profile.permission(purpose)
        VStack(alignment: .leading, spacing: Spacing.l) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Private by default")
                    .font(.editorial(.title2))
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Text("You decide what leaves this device, one purpose at a time.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }

            DetailsDisclosure(
                "How your data is kept",
                summary: "On this device first",
                systemImage: "iphone",
                isExpanded: app.profileUI.detailsBinding("onboardingPrivacy"),
                identifier: "onboardingPrivacyDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    ProfileBullet(systemImage: "iphone", text: "Local first: your closet, profile and photos are saved on this device.")
                    ProfileBullet(systemImage: "icloud", text: "Optional iCloud: private sync to your own iCloud account, which you can turn off in Settings (simulated here).")
                    ProfileBullet(systemImage: "hand.raised", text: "Nothing else is shared. Analytics stay off unless you opt in, and photos are never sent for text styling.")
                }
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(purpose.title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Spacer(minLength: Spacing.xs)
                    ProfileToneBadge(text: state.label, systemImage: state.profileSystemImage, tone: state.profileTone)
                }
                InfoRow(title: "Recipient", value: purpose.recipient)
                VStack(alignment: .leading, spacing: 2) {
                    Text("What is sent")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    Text(purpose.dataSent)
                        .font(.subheadline)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                InfoRow(title: "Retention and training", value: "Not set: no real provider is chosen in this prototype")
                // Asked here, so why it's needed and what is and isn't sent stay on screen; the scope notes open in place.
                Text("Style Me needs this for text styling. Your closet and saved looks work either way.")
                    .font(.footnote)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                CollapsibleText(
                    "Not sent: photos, weight or your whole closet. This permission covers text styling only — photo descriptions, On Me pictures and web search each ask separately.\n\nOn iPhone 12, Style Me uses this cloud stylist (simulated). Your closet, saved looks and manual outfits work either way.",
                    summary: "Not sent: photos, weight or your whole closet.",
                    threshold: 1,
                    topic: "what this permission covers",
                    isExpanded: app.profileUI.detailsBinding("onboardingCloudScope")
                )
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spacing.xs) { cloudButtons(purpose: purpose, state: state) }
                    VStack(spacing: Spacing.xs) { cloudButtons(purpose: purpose, state: state) }
                }
            }
            .cardStyle(highlighted: true)

            SimulationNotice(
                text: "The recipient is simulated and nothing leaves this device in the prototype. You can change this any time in Profile → Processing permissions.",
                summary: "Nothing leaves this device."
            )
        }
    }

    @ViewBuilder
    private func cloudButtons(purpose: ProcessingPurpose, state: PermissionState) -> some View {
                    Button {
                        app.store.setPermission(purpose, .allowed)
                        UIAccessibility.post(notification: .announcement, argument: "Cloud stylist allowed. Saved on this device")
                    } label: {
                        Label(state == .allowed ? "Allowed" : "Allow", systemImage: "checkmark")
                    }
                    .buttonStyle(SuccessButtonStyle(fullWidth: true))
                    .accessibilityLabel(state == .allowed ? "Cloud stylist allowed" : "Allow cloud stylist")
                    .accessibilityIdentifier("onboardingAllowCloud")
                    Button {
                        app.store.setPermission(purpose, .declined)
                        UIAccessibility.post(notification: .announcement, argument: "Cloud stylist not allowed. You can change this in Profile")
                    } label: {
                        Label("Not now", systemImage: state == .declined ? "checkmark" : "clock")
                    }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                    .accessibilityLabel(state == .declined ? "Not now, selected" : "Not now")
                    .accessibilityIdentifier("onboardingDeclineCloud")
    }
}

/// Wrapping choice chip for onboarding: icon + text, selection shown by a
/// checkmark and weight (never color alone), and no single-line truncation at
/// accessibility text sizes.
private struct ProfileOnboardingChoiceChip: View {
    var title: String
    var systemImage: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs + 2) {
                Image(systemName: isSelected ? "checkmark" : systemImage)
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isSelected ? Palette.primaryAction : Palette.primaryText)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xxs)
            .frame(minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(isSelected ? Palette.accentSurface : Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(isSelected ? Palette.primaryAction : Palette.controlBorder, lineWidth: isSelected ? 1.5 : 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview("Onboarding · measurements") {
    let model = AppModel.preview
    model.profileUI.onboardingStep = .measurements
    return OnboardingView()
        .previewEnvironment(model)
}
