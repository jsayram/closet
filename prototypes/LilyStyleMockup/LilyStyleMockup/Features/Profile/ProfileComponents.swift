import SwiftUI

// MARK: - Local saving helpers

extension AppModel {
    /// A local profile edit: `store.updateProfile` bumps the profile revision and
    /// persists. It never calls the stylist, image, search or ranking services.
    func profileSave(message: String = "Saved on this device", _ mutate: (inout UserProfile) -> Void) {
        store.updateProfile(mutate)
        profileConfirmSave(message)
    }

    /// Records one processing permission. Each purpose is independent.
    func profileSetPermission(_ purpose: ProcessingPurpose, _ state: PermissionState) {
        store.setPermission(purpose, state)
        profileConfirmSave("Saved on this device")
    }

    /// Shows the save confirmation, or an honest error if the write failed.
    func profileConfirmSave(_ message: String) {
        if store.lastSaveError != nil {
            showToast("Couldn't write to this device's storage. Your change is shown but not saved yet — try again.", style: .error)
        } else {
            showToast(message)
        }
    }

    /// First name used in provenance labels ("Confirmed by Lily").
    var profileOwnerName: String {
        let name = store.profile.displayName
        return name.split(separator: " ").first.map(String.init) ?? "you"
    }
}

// MARK: - Retailer stance

enum ProfileRetailerStance: String, CaseIterable, Identifiable, Hashable {
    case prefer, neutral, avoid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .prefer: "Prefer"
        case .neutral: "Neutral"
        case .avoid: "Avoid"
        }
    }

    var systemImage: String {
        switch self {
        case .prefer: "hand.thumbsup"
        case .neutral: "minus.circle"
        case .avoid: "hand.raised"
        }
    }
}

extension RetailerPreference {
    var profileStance: ProfileRetailerStance {
        if isAvoided { return .avoid }
        return isPreferred ? .prefer : .neutral
    }

    mutating func profileSetStance(_ stance: ProfileRetailerStance) {
        isPreferred = stance == .prefer
        isAvoided = stance == .avoid
    }
}

// MARK: - Free-text profile fields

/// Free-text profile fields edited in `ProfileTextEditor`.
enum ProfileTextField: String, Identifiable, Hashable {
    case rise, pantsLength, jacketLength, topSize, bottomSize

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rise: "Preferred rise"
        case .pantsLength: "Pants length"
        case .jacketLength: "Jacket length"
        case .topSize: "Usual top size"
        case .bottomSize: "Usual bottom size"
        }
    }

    var placeholder: String {
        switch self {
        case .rise: "e.g. Around the navel"
        case .pantsLength: "e.g. Hem clears the floor with flats"
        case .jacketLength: "e.g. Ends at the hip, not mid-thigh"
        case .topSize: "e.g. S (US) at Demo Brand B"
        case .bottomSize: "e.g. 2P (US) at Demo Brand A"
        }
    }

    var help: String {
        switch self {
        case .rise:
            "Describe where you like the waistband to sit. Brands label rise differently, so a description travels better than “mid-rise”."
        case .pantsLength:
            "How you like the hem to fall, and with which shoes. This is a preference, not a measurement. Your inseam only guides fit once you've confirmed it."
        case .jacketLength:
            "Anything about jacket or blazer length that matters to you."
        case .topSize, .bottomSize:
            "Include the brand or sizing system. A size label is context, not proof of fit, and sizes don't convert between brands."
        }
    }

    /// Optional fields store nil when cleared; descriptive preferences store an empty string.
    var isOptional: Bool {
        switch self {
        case .topSize, .bottomSize: true
        case .rise, .pantsLength, .jacketLength: false
        }
    }

    var emptyLabel: String {
        switch self {
        case .topSize, .bottomSize: "Unknown"
        default: "Not set"
        }
    }

    func value(in profile: UserProfile) -> String? {
        let raw: String? = switch self {
        case .rise: profile.preferredRise
        case .pantsLength: profile.preferredPantsLength
        case .jacketLength: profile.jacketLengthNote
        case .topSize: profile.usualTopSize
        case .bottomSize: profile.usualBottomSize
        }
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return raw
    }

    func apply(_ text: String?, to profile: inout UserProfile) {
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let stored = (trimmed?.isEmpty ?? true) ? nil : trimmed
        switch self {
        case .rise: profile.preferredRise = stored ?? ""
        case .pantsLength: profile.preferredPantsLength = stored ?? ""
        case .jacketLength: profile.jacketLengthNote = stored ?? ""
        case .topSize: profile.usualTopSize = stored
        case .bottomSize: profile.usualBottomSize = stored
        }
    }
}

/// Edits one free-text field. Save and Clear are explicit, local actions.
struct ProfileTextEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    var field: ProfileTextField

    var body: some View {
        @Bindable var ui = app.profileUI
        let hasValue = field.value(in: app.store.profile) != nil
        NavigationStack {
            Form {
                Section {
                    TextField(field.placeholder, text: $ui.textDraft, axis: .vertical)
                        .lineLimit(2...6)
                        .focused($focused)
                        .accessibilityLabel(field.title)
                } footer: {
                    CollapsibleText(field.help, topic: field.title)
                }
                .listRowBackground(Palette.surface)

                if hasValue {
                    Section {
                        Button(role: .destructive) {
                            app.profileSave(message: "\(field.title) cleared. Saved on this device") { field.apply(nil, to: &$0) }
                            dismiss()
                        } label: {
                            Label(field.isOptional ? "Clear — back to \(field.emptyLabel)" : "Clear this preference", systemImage: "eraser")
                                .foregroundStyle(Palette.error)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .themedScreenBackground()
            .navigationTitle(field.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let text = ui.textDraft
                        app.profileSave { field.apply(text, to: &$0) }
                        dismiss()
                    }
                    .keyboardShortcut("s", modifiers: .command)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Small shared views

/// Text + icon badge in the StatusBadge style, with a tone chosen by meaning.
struct ProfileToneBadge: View {
    typealias Tone = BadgeKind.Tone

    var text: String
    var systemImage: String
    var tone: Tone = .neutral

    var body: some View {
        ToneBadge(text: text, systemImage: systemImage, tone: tone)
    }
}

/// "Unknown"/"Not set" value text: italic and secondary, never a zero.
struct ProfileValueText: View {
    var value: String?
    var emptyLabel = "Unknown"

    var body: some View {
        if let value {
            Text(value)
                .foregroundStyle(Palette.primaryText)
        } else {
            Text(emptyLabel)
                .italic()
                .foregroundStyle(Palette.secondaryText)
        }
    }
}

/// Tappable row: title, optional caption, value and a trailing Add/Edit cue.
/// Long descriptive values (and accessibility text sizes) stack the value under
/// the title so nothing is squeezed or clipped.
struct ProfileEditableRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var title: String
    var caption: String?
    var value: String?
    var emptyLabel = "Unknown"
    var stacksValue = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if stacksValue || dynamicTypeSize.isAccessibilitySize {
                    HStack(alignment: .center, spacing: Spacing.s) {
                        VStack(alignment: .leading, spacing: 2) {
                            titleBlock
                            ProfileValueText(value: value, emptyLabel: emptyLabel)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                        Spacer(minLength: Spacing.xs)
                        ProfileEditCue(isAdd: value == nil)
                    }
                } else {
                    HStack(alignment: .center, spacing: Spacing.s) {
                        titleBlock
                            .layoutPriority(1)
                        Spacer(minLength: Spacing.xs)
                        ProfileValueText(value: value, emptyLabel: emptyLabel)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                        ProfileEditCue(isAdd: value == nil)
                    }
                }
            }
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel(title)
        .accessibilityValue([value ?? emptyLabel, caption].compactMap { $0 }.joined(separator: ". "))
        .accessibilityHint(value == nil ? "Adds this optional detail" : "Edits or clears this detail")
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Trailing "Add ›" / "Edit ›" cue.
struct ProfileEditCue: View {
    var isAdd: Bool

    var body: some View {
        HStack(spacing: 2) {
            Text(isAdd ? "Add" : "Edit")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryAction)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
        }
        .accessibilityHidden(true)
    }
}

/// Inline "type and Add" field used for chips, color pairs and retailers.
struct ProfileAddField: View {
    var placeholder: String
    @Binding var text: String
    var buttonTitle = "Add"
    var identifier: String?
    var onAdd: () -> Void

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        HStack(spacing: Spacing.xs) {
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .onSubmit { if !trimmed.isEmpty { onAdd() } }
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(Palette.background))
                .overlay(RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
                .accessibilityLabel(placeholder)
            Button {
                onAdd()
            } label: {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(trimmed.isEmpty)
            .accessibilityIdentifier(identifier ?? "")
        }
    }
}

/// Section header with the design-system header style (no list uppercase).
struct ProfileListHeader<Trailing: View>: View {
    var title: String
    var subtitle: String?
    /// Longer notes about the section, shown from an info button beside the title.
    var info: String?
    var systemImage: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, info: String? = nil, systemImage: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.info = info
        self.systemImage = systemImage
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            SectionHeader(title, subtitle: subtitle, info: info) { trailing() }
        }
        .textCase(nil)
        .padding(.top, Spacing.xs)
    }
}

/// Footer note in secondary text. A long note shows its first line with More.
struct ProfileFooterNote: View {
    var text: String

    var body: some View {
        CollapsibleText(text)
    }
}

/// A label with an info button beside it, for helper text that used to sit under
/// the control.
struct ProfileInfoLabel: View {
    var title: String
    var info: String
    var font: Font = .body

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(font)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            InfoButton(title, text: info)
        }
    }
}

/// Form section header with an info button for the note that used to be the footer.
struct ProfileFormHeader: View {
    var title: String
    var info: String

    init(_ title: String, info: String) {
        self.title = title
        self.info = info
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
            InfoButton(title, text: info)
                .textCase(nil)
        }
    }
}
