import SwiftUI

/// Prominent plum action (Style Me, Save, Confirm).
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.onPrimaryAction)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.primaryAction.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4))
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .hoverEffect(.highlight)
    }
}

/// Outlined secondary action with a ≥3:1 boundary.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    var fullWidth = false
    var tint: Color = Palette.primaryAction

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint.opacity(isEnabled ? 1 : 0.45))
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: HitTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(configuration.isPressed ? Palette.accentSurface : Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(Palette.controlBorder, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            .hoverEffect(.highlight)
    }
}

/// Sage confirmation action (Already Own, Mark clean).
struct SuccessButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.success)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: HitTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Palette.successSurface.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(Palette.success.opacity(0.6), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            .hoverEffect(.highlight)
    }
}

/// Destructive outlined action. Use with a confirmation for irreversible steps.
struct DestructiveButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.error)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: HitTarget.minimum)
            .background(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .fill(Palette.surface.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                    .strokeBorder(Palette.error.opacity(0.7), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
    }
}

/// Selectable capsule chip (occasions, filters, colors). Selection is shown with a
/// checkmark and weight change as well as color.
struct CapsuleChip: View {
    var title: String
    var systemImage: String?
    var isSelected: Bool
    /// Color chips: a swatch that stays visible whether or not the chip is selected.
    var swatchHex: String? = nil
    /// Quiet count after the title, such as how many pieces are ready in that color.
    var trailingCount: Int? = nil
    var action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: Spacing.xxs + 2) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline)
                }
                if let swatchHex {
                    ColorSwatch(hex: swatchHex, size: 18)
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                    .multilineTextAlignment(.leading)
                if let trailingCount {
                    Text("\(trailingCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .foregroundStyle(isSelected ? Palette.primaryAction : Palette.primaryText)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? Spacing.xs : 0)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(isSelected ? Palette.accentSurface : Palette.surface))
            .overlay(Capsule().strokeBorder(isSelected ? Palette.primaryAction : Palette.controlBorder, lineWidth: isSelected ? 1.5 : 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.pressFeedback)
        .hoverEffect(.highlight)
        .animation(Motion.quick, value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Small color swatch with an outline so light colors stay visible.
struct ColorSwatch: View {
    var hex: String
    var size: CGFloat = 18

    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(Palette.controlBorder, lineWidth: 1))
            .accessibilityHidden(true)
    }
}
