import SwiftUI

// MARK: - Draft

/// Editable copy of one optional measurement. Unknown stays absent: there is
/// no default number, and clearing removes the fact instead of storing zero.
struct ProfileMeasurementDraft: Equatable {
    var dimension: MeasurementDimension
    var valueText = ""
    var feet = 4
    var inches = 11
    var unit: MeasurementUnit = .inches
    var basis: MeasurementBasis = .body
    var confirmed = true
    var existed = false

    init(dimension: MeasurementDimension, fact: MeasurementFact?) {
        self.dimension = dimension
        if let fact {
            unit = fact.unit
            basis = fact.basis
            confirmed = fact.confirmed
            existed = true
            setValue(fact.value)
        } else {
            feet = 0
            inches = 0
        }
    }

    /// Height in inches is entered as feet + inches.
    var usesFeetInches: Bool { dimension == .height && unit == .inches }

    var value: Double? {
        if usesFeetInches {
            let total = feet * 12 + inches
            return total > 0 ? Double(total) : nil
        }
        let normalized = valueText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(normalized), v > 0 else { return nil }
        let upper: Double = unit == .inches ? 120 : 300
        return v <= upper ? (v * 10).rounded() / 10 : nil
    }

    var validationMessage: String? {
        if usesFeetInches { return value == nil ? "Choose feet and inches." : nil }
        if valueText.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter a value, or Cancel to keep it Unknown." }
        return value == nil ? "Enter a number in \(unit == .inches ? "inches" : "centimeters")." : nil
    }

    mutating func setValue(_ v: Double) {
        if usesFeetInches {
            let total = Int(v.rounded())
            feet = total / 12
            inches = total % 12
        } else {
            valueText = Self.format(v)
        }
    }

    /// Deterministic unit conversion; the basis is preserved.
    mutating func convert(to newUnit: MeasurementUnit) {
        guard newUnit != unit else { return }
        let current = value
        unit = newUnit
        if let current {
            let converted = newUnit == .centimeters ? current * 2.54 : current / 2.54
            setValue((converted * 10).rounded() / 10)
        } else {
            valueText = ""
            feet = 0
            inches = 0
        }
    }

    static func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

/// Editable copy of the optional weight. Clearing removes it; nothing is stored as zero.
struct ProfileWeightDraft: Equatable {
    var valueText = ""
    var unit: WeightUnit = .pounds
    var approximate = true
    var existed = false

    init(weight: BodyWeight?) {
        guard let weight else { return }
        valueText = ProfileMeasurementDraft.format(weight.value)
        unit = weight.unit
        approximate = weight.approximate
        existed = true
    }

    /// Plausible adult range in the chosen unit, so a typo isn't saved as a weight.
    private var range: ClosedRange<Double> { unit == .pounds ? 50...500 : 23...230 }

    var value: Double? {
        let normalized = valueText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(normalized), range.contains(v) else { return nil }
        return (v * 10).rounded() / 10
    }

    var isEmpty: Bool { valueText.trimmingCharacters(in: .whitespaces).isEmpty }

    var validationMessage: String? {
        if isEmpty { return "Enter a value, or Cancel to leave it out." }
        return value == nil ? "Enter a number in \(unit.label.lowercased())." : nil
    }

    var weight: BodyWeight? {
        value.map { BodyWeight(value: $0, unit: unit, approximate: approximate, updatedAt: .now) }
    }

    /// Converts the typed value so switching units never changes the weight itself.
    mutating func convert(to newUnit: WeightUnit) {
        guard newUnit != unit else { return }
        let current = value
        unit = newUnit
        if let current {
            let converted = newUnit == .kilograms ? current / 2.204_62 : current * 2.204_62
            valueText = ProfileMeasurementDraft.format((converted * 10).rounded() / 10)
        } else {
            valueText = ""
        }
    }
}

/// Waist, hip and bust entered together in onboarding. Each field is optional; anything
/// she types is saved as a confirmed body measurement. An emptied field goes back to Unknown.
struct ProfileBodyTrioDraft: Equatable {
    static let dimensions: [MeasurementDimension] = [.waist, .hip, .bust]

    var texts: [MeasurementDimension: String] = [:]
    var unit: MeasurementUnit = .inches

    init(profile: UserProfile? = nil) {
        guard let profile else { return }
        let facts = Self.dimensions.compactMap { profile.measurement($0) }
        if let first = facts.first { unit = first.unit }
        for fact in facts {
            let value = fact.unit == unit ? fact.value : (fact.unit == .inches ? fact.value * 2.54 : fact.value / 2.54)
            texts[fact.dimension] = ProfileMeasurementDraft.format((value * 10).rounded() / 10)
        }
    }

    enum Entry: Equatable {
        case empty, invalid
        case value(Double)
    }

    func text(_ dimension: MeasurementDimension) -> String { texts[dimension] ?? "" }

    func entry(_ dimension: MeasurementDimension) -> Entry {
        let raw = text(dimension).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !raw.isEmpty else { return .empty }
        let range: ClosedRange<Double> = unit == .inches ? 15...80 : 38...200
        guard let v = Double(raw), range.contains(v) else { return .invalid }
        return .value((v * 10).rounded() / 10)
    }

    var invalidDimensions: [MeasurementDimension] {
        Self.dimensions.filter { entry($0) == .invalid }
    }

    /// Converts every usable value so switching units keeps what she typed.
    mutating func convert(to newUnit: MeasurementUnit) {
        guard newUnit != unit else { return }
        let entries = Self.dimensions.map { ($0, entry($0)) }
        unit = newUnit
        for (dimension, entry) in entries {
            guard case let .value(v) = entry else { continue }
            let converted = newUnit == .centimeters ? v * 2.54 : v / 2.54
            texts[dimension] = ProfileMeasurementDraft.format((converted * 10).rounded() / 10)
        }
    }

    var validationMessage: String? {
        guard !invalidDimensions.isEmpty else { return nil }
        let names = invalidDimensions.map { $0 == .hip ? "hip" : $0.label.lowercased() }
        let unitName = unit == .inches ? "inches" : "centimeters"
        return "Check your \(ListFormatter.localizedString(byJoining: names)). Enter a number in \(unitName), or leave it empty."
    }
}

extension MeasurementBasis {
    /// Plain-language basis help for the editor.
    var profileHelp: String {
        switch self {
        case .body: "Measured on your body."
        case .preferredGarment: "The garment length you like, such as where a hem should fall."
        case .actualGarment: "Measured flat on a garment that already fits you well."
        case .chartRange: "A range copied from a brand's size chart."
        }
    }
}

extension MeasurementDimension {
    var profileShortLabel: String {
        switch self {
        case .inseam: "Inseam"
        case .hip: "Hip / seat"
        default: label
        }
    }
}

// MARK: - Section

/// Profile → Fit & measurements. Height is the only confirmed value in the demo;
/// everything else reads Unknown until Lily adds it. Waist, hip and bust come first
/// because they're the main fit inputs; weight sits last as the rough fallback.
struct ProfileMeasurementsSection: View {
    @Environment(AppModel.self) private var app

    private static let fitInputs: [MeasurementDimension] = [.waist, .hip, .bust]
    private static let otherDimensions = MeasurementDimension.allCases.filter { !fitInputs.contains($0) }

    var body: some View {
        let profile = app.store.profile
        Section {
            ProfileFitSourceRow(fit: profile.bodyFit)

            ProfileMeasurementGroupLabel(
                title: "Main fit inputs",
                detail: "Confirmed waist, hip and bust shape what Fitted, Comfortable and Relaxed mean for you, and help compare size charts."
            )
            ForEach(Self.fitInputs) { dimension in
                measurementRow(dimension, profile: profile)
            }

            ProfileMeasurementGroupLabel(title: "Lengths and proportions", detail: nil)
            ForEach(Self.otherDimensions) { dimension in
                measurementRow(dimension, profile: profile)
            }

            ProfileWeightRow()
        } header: {
            ProfileListHeader(
                "Fit & measurements",
                subtitle: "Optional. Unknown stays unknown.",
                info: "Waist, hip and bust guide fit best. Unknown stays unknown.\n\nEvery value is optional. Add only what's useful. Height and weight only give a rough size estimate when waist, hip and bust are missing. Height never sets your inseam, and your weight is never shared.\n\nBody measurements and garment lengths are kept separate. Updating a value only changes your profile — it doesn't re-run any looks.",
                systemImage: "ruler"
            )
        }
        .listRowBackground(Palette.surface)
    }

    private func measurementRow(_ dimension: MeasurementDimension, profile: UserProfile) -> some View {
        ProfileMeasurementRow(dimension: dimension, fact: profile.measurement(dimension)) {
            app.profileUI.openMeasurement(dimension, profile: app.store.profile)
        }
    }
}

/// Small group label inside the measurements list.
private struct ProfileMeasurementGroupLabel: View {
    var title: String
    var detail: String?

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            if let detail {
                InfoButton(title, text: detail)
            }
        }
        .padding(.top, Spacing.xs)
    }
}

/// One line saying what fit notes are based on right now, read fresh from `BodyFit`.
struct ProfileFitSourceRow: View {
    var fit: BodyFit

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: systemImage)
                .foregroundStyle(fit.source == .measurements ? Palette.success : Palette.primaryAction)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.headline(for: fit))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("profileFitSource")
    }

    /// "Fit notes use: your waist, hip and bust", or a short prompt when there's nothing yet.
    static func headline(for fit: BodyFit) -> String {
        switch fit.source {
        case .measurements:
            let names = fit.measuredDimensions.map { $0 == .hip ? "hip" : $0.label.lowercased() }
            return "Fit notes use: your \(ListFormatter.localizedString(byJoining: names))"
        case .heightAndWeightEstimate:
            return "Fit notes use: a rough estimate from height and weight"
        case .none:
            return "Add measurements for fit notes"
        }
    }

    private var systemImage: String {
        switch fit.source {
        case .measurements: "checkmark.seal"
        case .heightAndWeightEstimate: "dial.low"
        case .none: "ruler"
        }
    }

    private var detail: String? {
        switch fit.source {
        case .measurements:
            if let cuePhrase = fit.cuePhrase { return "Styling allows for \(cuePhrase)." }
            return nil
        case .heightAndWeightEstimate:
            guard let band = fit.estimatedBand else { return nil }
            return "Around \(band.label), always labeled as an estimate. Adding your waist, hip or bust replaces it."
        case .none:
            return "Waist, hip or bust works best. Nothing is guessed in the meantime."
        }
    }
}

/// One measurement row: confirmed value with provenance and basis, or Unknown with Add.
struct ProfileMeasurementRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var dimension: MeasurementDimension
    var fact: MeasurementFact?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            let stacked = dynamicTypeSize.isAccessibilitySize
            let layout = stacked
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
                : AnyLayout(HStackLayout(alignment: .center, spacing: Spacing.s))
            layout {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(dimension.label)
                        .font(.body)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    if let fact {
                        FlowLayout(spacing: Spacing.xxs) {
                            if fact.confirmed {
                                ProfileToneBadge(text: fact.provenance, systemImage: "checkmark.seal", tone: .success)
                            } else {
                                ProfileToneBadge(text: "Not confirmed", systemImage: "questionmark.circle", tone: .caution)
                            }
                            ProfileToneBadge(text: fact.basis.label, systemImage: "ruler", tone: .neutral)
                        }
                    }
                }
                if !stacked { Spacer(minLength: Spacing.xs) }
                if let fact {
                    Text(fact.displayValue)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                } else {
                    Text("Unknown")
                        .italic()
                        .foregroundStyle(Palette.secondaryText)
                }
                ProfileEditCue(isAdd: fact == nil)
            }
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(dimension.label)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(fact == nil ? "Adds this optional measurement" : "Edits or clears this measurement")
        .accessibilityIdentifier("profileMeasurement-\(dimension.rawValue)")
    }

    private var accessibilityValue: String {
        guard let fact else { return "Unknown" }
        let status = fact.confirmed ? fact.provenance : "Not confirmed"
        return "\(fact.displayValue), \(fact.basis.label), \(status)"
    }
}

/// Optional weight: a rough size fallback only, never shared.
struct ProfileWeightRow: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let profile = app.store.profile
        let weight = profile.weight
        ProfileEditableRow(
            title: "Weight (optional)",
            caption: Self.caption(profile: profile),
            value: weight?.displayValue,
            emptyLabel: "Not added",
            stacksValue: true
        ) {
            app.profileUI.openWeight(profile: app.store.profile)
        }
        .swipeActions(edge: .trailing) {
            if weight != nil {
                Button(role: .destructive) {
                    app.profileClearWeight()
                } label: {
                    Label("Clear", systemImage: "eraser")
                }
            }
        }
        .accessibilityIdentifier("profileWeightContext")
    }

    /// Says whether weight is in use right now, so she never has to guess.
    static func caption(profile: UserProfile) -> String {
        let fit = profile.bodyFit
        guard profile.weight != nil else {
            return "Rough estimate only. Never shared."
        }
        switch fit.source {
        case .measurements:
            return "Not in use: your waist, hip or bust comes first. Never shared."
        case .heightAndWeightEstimate:
            let band = fit.estimatedBand.map { ", around \($0.label)" } ?? ""
            return "In use for a rough size estimate\(band). Never shared."
        case .none:
            return "Not in use yet: the rough estimate also needs your confirmed height. Never shared."
        }
    }
}

extension AppModel {
    /// Removes the optional weight locally, with Undo. Never calls a service.
    func profileClearWeight() {
        guard let removed = store.profile.weight else { return }
        store.updateProfile { $0.weight = nil }
        store.pushUndo(UndoEntry(label: "Clear weight") { store in
            guard store.profile.weight == nil else { return "Not restored — a newer weight was saved." }
            store.updateProfile { $0.weight = removed }
            return "Weight restored."
        })
        if store.lastSaveError != nil {
            profileConfirmSave("")
        } else {
            showUndoToast("Weight cleared. Saved on this device")
        }
    }
}

// MARK: - Weight editor

/// Add/edit the optional weight: value, lb or kg, Approximate, Save/Clear.
struct ProfileWeightEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var ui = app.profileUI
        let draft = ui.weightDraft
        let unitBinding = Binding<WeightUnit>(
            get: { app.profileUI.weightDraft.unit },
            set: { app.profileUI.weightDraft.convert(to: $0) }
        )
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Value", text: $ui.weightDraft.valueText)
                            .keyboardType(.decimalPad)
                            .focused($focused)
                            .accessibilityLabel("Weight in \(draft.unit.label.lowercased())")
                            .accessibilityIdentifier("weightValue")
                        Text(draft.unit.symbol)
                            .foregroundStyle(Palette.secondaryText)
                            .accessibilityHidden(true)
                    }
                    Picker("Unit", selection: unitBinding) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.label).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("weightUnit")
                    if let message = draft.validationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                    }
                } header: {
                    ProfileFormHeader("Value", info: "Used only for a rough size estimate when your waist, hip and bust aren't added, and always labeled as an estimate. It never overrides a measurement you confirmed.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    HStack(spacing: Spacing.xxs) {
                        ProfileInfoLabel(title: "Approximate", info: "Leave this on for a rough figure. Turn it off if it's a recent reading.")
                        Spacer(minLength: Spacing.xs)
                        Toggle("Approximate", isOn: $ui.weightDraft.approximate)
                            .labelsHidden()
                            .accessibilityIdentifier("weightApproximate")
                    }
                }
                .listRowBackground(Palette.surface)

                Section {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Image(systemName: "lock")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .accessibilityHidden(true)
                        CollapsibleText(
                            "Never shared: not in searches, stylist requests or anything you export to another stylist. It's kept with your private data, on this device and in your private iCloud if sync is on.",
                            summary: "Never shared with anyone.",
                            threshold: 1,
                            topic: "how your weight is kept"
                        )
                    }
                }
                .listRowBackground(Palette.surface)

                if draft.existed {
                    Section {
                        Button(role: .destructive) {
                            app.profileClearWeight()
                            dismiss()
                        } label: {
                            Label("Clear — back to Not added", systemImage: "eraser")
                                .foregroundStyle(Palette.error)
                        }
                        .accessibilityIdentifier("weightClear")
                    } footer: {
                        Text("Clearing removes your weight. Nothing is estimated in its place.")
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.weight == nil)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("weightSave")
                }
            }
            .onAppear { focused = !draft.existed }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let weight = app.profileUI.weightDraft.weight else { return }
        app.profileSave { $0.weight = weight }
        dismiss()
    }
}

// MARK: - Editor

/// Add/edit one measurement: value, unit, basis, confirmed, help, Save/Clear.
struct ProfileMeasurementEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var ui = app.profileUI
        let draft = ui.measurementDraft
        let unitBinding = Binding<MeasurementUnit>(
            get: { app.profileUI.measurementDraft.unit },
            set: { app.profileUI.measurementDraft.convert(to: $0) }
        )
        NavigationStack {
            Form {
                Section {
                    if draft.usesFeetInches {
                        Stepper(value: $ui.measurementDraft.feet, in: 0...7) {
                            Text("\(draft.feet) ft")
                                .monospacedDigit()
                        }
                        .accessibilityLabel("Feet")
                        .accessibilityValue("\(draft.feet)")
                        Stepper(value: $ui.measurementDraft.inches, in: 0...11) {
                            Text("\(draft.inches) in")
                                .monospacedDigit()
                        }
                        .accessibilityLabel("Inches")
                        .accessibilityValue("\(draft.inches)")
                    } else {
                        HStack {
                            TextField("Value", text: $ui.measurementDraft.valueText)
                                .keyboardType(.decimalPad)
                                .accessibilityLabel("\(draft.dimension.profileShortLabel) value in \(draft.unit == .inches ? "inches" : "centimeters")")
                                .accessibilityIdentifier("measurementValue")
                            Text(draft.unit.symbol)
                                .foregroundStyle(Palette.secondaryText)
                                .accessibilityHidden(true)
                        }
                    }
                    Picker("Unit", selection: unitBinding) {
                        Text("Inches").tag(MeasurementUnit.inches)
                        Text("Centimeters").tag(MeasurementUnit.centimeters)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("measurementUnit")
                    if let message = draft.validationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                    }
                } header: {
                    ProfileFormHeader("Value", info: draft.dimension.help)
                }
                .listRowBackground(Palette.surface)

                Section {
                    Picker("What this value measures", selection: $ui.measurementDraft.basis) {
                        ForEach(MeasurementBasis.allCases) { basis in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(basis.label)
                                Text(basis.profileHelp)
                                    .font(.caption)
                                    .foregroundStyle(Palette.secondaryText)
                            }
                            .tag(basis)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    ProfileFormHeader("What this value measures", info: "Body and garment values are never treated as interchangeable.")
                }
                .listRowBackground(Palette.surface)

                Section {
                    HStack(spacing: Spacing.xxs) {
                        ProfileInfoLabel(
                            title: "Confirmed by \(app.profileOwnerName)",
                            info: "Only confirmed values guide fit advice. An unconfirmed value is kept and shown as Not confirmed."
                        )
                        Spacer(minLength: Spacing.xs)
                        Toggle("Confirmed by \(app.profileOwnerName)", isOn: $ui.measurementDraft.confirmed)
                            .labelsHidden()
                            .accessibilityIdentifier("measurementConfirmed")
                    }
                }
                .listRowBackground(Palette.surface)

                if draft.existed {
                    Section {
                        Button(role: .destructive) {
                            clear()
                        } label: {
                            Label("Clear — back to Unknown", systemImage: "eraser")
                                .foregroundStyle(Palette.error)
                        }
                        .accessibilityIdentifier("measurementClear")
                    } footer: {
                        Text("Clearing removes this value. Nothing is estimated in its place.")
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle(draft.dimension.profileShortLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.value == nil)
                        .keyboardShortcut("s", modifiers: .command)
                        .accessibilityIdentifier("measurementSave")
                }
            }
        }
    }

    private func save() {
        let draft = app.profileUI.measurementDraft
        guard let value = draft.value else { return }
        let owner = app.profileOwnerName
        let fact = MeasurementFact(
            dimension: draft.dimension,
            value: value,
            unit: draft.unit,
            basis: draft.basis,
            provenance: draft.confirmed ? "Confirmed by \(owner)" : "Entered by \(owner), not confirmed",
            confirmed: draft.confirmed,
            updatedAt: .now
        )
        app.profileSave { profile in
            if let i = profile.measurements.firstIndex(where: { $0.dimension == fact.dimension }) {
                profile.measurements[i] = fact
            } else {
                profile.measurements.append(fact)
            }
        }
        dismiss()
    }

    private func clear() {
        let dimension = app.profileUI.measurementDraft.dimension
        guard let removed = app.store.profile.measurement(dimension) else { dismiss(); return }
        app.store.updateProfile { $0.measurements.removeAll { $0.dimension == dimension } }
        app.store.pushUndo(UndoEntry(label: "Clear \(dimension.profileShortLabel)") { store in
            guard store.profile.measurement(dimension) == nil else {
                return "Not restored — a newer \(dimension.profileShortLabel.lowercased()) value was saved."
            }
            store.updateProfile { $0.measurements.append(removed) }
            return "\(dimension.profileShortLabel) restored."
        })
        if app.store.lastSaveError != nil {
            app.profileConfirmSave("")
        } else {
            app.showUndoToast("\(dimension.profileShortLabel) cleared — now Unknown. Saved on this device")
        }
        dismiss()
    }
}

#Preview("Measurement editor") {
    let model = AppModel.preview
    model.profileUI.measurementDraft = ProfileMeasurementDraft(dimension: .inseam, fact: nil)
    return ProfileMeasurementEditor()
        .previewEnvironment(model)
}

#Preview("Weight editor") {
    let model = AppModel.preview
    model.profileUI.weightDraft = ProfileWeightDraft(weight: model.store.profile.weight)
    return ProfileWeightEditor()
        .previewEnvironment(model)
}
