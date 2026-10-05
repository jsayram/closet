import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

// MARK: - Fit evidence badge

/// Fit state with icon + text. Tone supports, never replaces, the label.
struct FindOneFitBadge: View {
    var state: FitEvidenceState
    var unranked = false

    private var title: String { unranked ? "Needs fit confirmation" : state.title }

    private var colors: (fg: Color, bg: Color, border: Color) {
        if unranked { return (Palette.primaryText, Palette.accentSurface, Palette.controlBorder) }
        switch state {
        case .supportedGuidance: return (Palette.success, Palette.successSurface, Palette.success.opacity(0.6))
        case .needsFitConfirmation: return (Palette.primaryText, Palette.accentSurface, Palette.controlBorder)
        case .knownFitConflict: return (Palette.error, Palette.surface, Palette.error.opacity(0.7))
        }
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: unranked ? FitEvidenceState.needsFitConfirmation.systemImage : state.systemImage)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(colors.fg)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background(Capsule().fill(colors.bg))
        .overlay(Capsule().strokeBorder(colors.border, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fit: \(title)")
    }
}

// MARK: - Retailer preference chip

/// Store preference chip: Preferred → Avoid → No preference. State is shown with
/// an icon and text styling as well as color, and announced to VoiceOver.
struct FindOneRetailerChip: View {
    var preference: RetailerPreference
    var onCycle: () -> Void
    var onSet: (_ preferred: Bool, _ avoided: Bool) -> Void
    var onRemove: () -> Void

    private var stateLabel: String {
        if preference.isAvoided { return "Avoid" }
        if preference.isPreferred { return "Preferred" }
        return "No preference"
    }

    private var icon: String {
        if preference.isAvoided { return "nosign" }
        if preference.isPreferred { return "checkmark" }
        return "circle.dashed"
    }

    var body: some View {
        Button(action: onCycle) {
            HStack(spacing: Spacing.xxs + 2) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                Text(preference.name)
                    .font(.subheadline.weight(preference.isPreferred && !preference.isAvoided ? .semibold : .regular))
                    .strikethrough(preference.isAvoided)
                    .fixedSize(horizontal: false, vertical: true)
                if preference.isAvoided {
                    Text("Avoid")
                        .font(.caption)
                }
            }
            .foregroundStyle(preference.isAvoided ? Palette.secondaryText : (preference.isPreferred ? Palette.primaryAction : Palette.primaryText))
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(preference.isPreferred && !preference.isAvoided ? Palette.accentSurface : Palette.surface))
            .overlay(Capsule().strokeBorder(preference.isPreferred && !preference.isAvoided ? Palette.primaryAction : Palette.controlBorder,
                                            style: StrokeStyle(lineWidth: preference.isPreferred ? 1.5 : 1, dash: preference.isAvoided ? [4, 3] : [])))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .contextMenu {
            Button { onSet(true, false) } label: { Label("Prefer", systemImage: "checkmark") }
            Button { onSet(false, true) } label: { Label("Avoid", systemImage: "nosign") }
            Button { onSet(false, false) } label: { Label("No preference", systemImage: "circle.dashed") }
            Divider()
            Button(role: .destructive) { onRemove() } label: { Label("Remove store", systemImage: "trash") }
        }
        .accessibilityLabel(preference.name)
        .accessibilityValue(stateLabel)
        .accessibilityHint("Changes between preferred, avoid and no preference. Saved to your Profile.")
        .accessibilityAddTraits(preference.isPreferred && !preference.isAvoided ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("findOneRetailerChip-\(preference.name)")
    }
}

// MARK: - Labelled text field

struct FindOneLabeledField<Field: View>: View {
    var title: String
    var caption: String?
    /// How-it-works text, shown from an info button beside the title.
    var info: String?
    @ViewBuilder var field: () -> Field

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                if let info {
                    InfoButton(title, text: info)
                }
            }
            field()
                .textFieldStyle(.plain)
                .font(.body)
                .padding(.horizontal, Spacing.s)
                .frame(minHeight: HitTarget.minimum)
                .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
                .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Switch with a short state line

/// A switch with its title, one short line that reports the current state, and the
/// longer explanation behind an info button. The info button stays usable when the
/// switch itself is disabled.
struct FindOneToggleRow: View {
    var title: String
    var caption: String
    var info: String
    @Binding var isOn: Bool
    var isEnabled = true
    var identifier: String

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHidden(true)
                    InfoButton(title, text: info)
                }
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            Spacer(minLength: Spacing.xs)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(Palette.primaryAction)
                .disabled(!isEnabled)
                .accessibilityLabel(title)
                .accessibilityHint(caption)
                .accessibilityIdentifier(identifier)
        }
        .frame(minHeight: HitTarget.minimum)
    }
}

// MARK: - Overflow menu

/// Icon-only "more actions" menu for the corner of a row, where a labelled More button
/// would take a row of its own. 44 pt target; destructive items still confirm.
struct FindOneOverflowMenu<Items: View>: View {
    var identifier: String
    @ViewBuilder var items: () -> Items

    var body: some View {
        Menu {
            items()
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.primaryAction)
                .frame(width: HitTarget.minimum, height: HitTarget.minimum)
                .contentShape(Rectangle())
        }
        .hoverEffect(.highlight)
        .accessibilityLabel("More actions")
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Bullet list for compared dimensions / unknowns

struct FindOneBulletList: View {
    var title: String
    var items: [String]
    var systemImage: String
    var tint: Color

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.secondaryText)
                    .textCase(.uppercase)
                ForEach(items, id: \.self) { item in
                    Label {
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: systemImage)
                            .foregroundStyle(tint)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Representative product tile

/// Search citations don't license product images, so leads use a labelled
/// representative tile drawn in the listed color.
struct FindOneProductTile: View {
    var candidate: ShoppingCandidate
    var size: CGFloat = 76
    var showsCaption = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            GarmentArtwork(kind: candidate.kind, hex: candidate.colorHex)
                .frame(width: size, height: size)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "bag.badge.plus")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Palette.primaryAction)
                        .padding(4)
                        .background(Circle().fill(Palette.surface))
                        .padding(3)
                }
            if showsCaption {
                Text("Representative tile")
                    .font(.caption2)
                    .foregroundStyle(Palette.secondaryText)
                    .frame(width: size, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Representative image of \(candidate.colorName) \(candidate.kind.label.lowercased()), not a product photo. Not owned.")
    }
}

// MARK: - Paste image payload

/// Explicit Paste Image payload. Only read when she taps the system Paste button.
struct FindOnePastedImage: Transferable {
    var data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in FindOnePastedImage(data: data) }
    }
}

// MARK: - Inner panel

extension View {
    /// Inner panel inside a Find One step card (avoids nesting full cards).
    func findOnePanel(highlighted: Bool = false) -> some View {
        padding(Spacing.s)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(highlighted ? Palette.primaryAction : Palette.controlBorder, lineWidth: highlighted ? 1.5 : 1))
    }
}
