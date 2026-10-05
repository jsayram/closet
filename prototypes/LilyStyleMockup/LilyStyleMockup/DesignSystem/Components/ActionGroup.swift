import SwiftUI

/// "More" menu button (ellipsis icon with a visible label) for the actions that
/// don't make the first two. Give destructive items `role: .destructive`; they still
/// need their own confirmation.
struct MoreMenu<Items: View>: View {
    private let title: String
    private let fullWidth: Bool
    private let identifier: String?
    private let items: Items
    @Environment(\.isEnabled) private var isEnabled

    init(_ title: String = "More", fullWidth: Bool = false, identifier: String? = nil, @ViewBuilder items: () -> Items) {
        self.title = title
        self.fullWidth = fullWidth
        self.identifier = identifier
        self.items = items()
    }

    var body: some View {
        Menu {
            items
        } label: {
            // Drawn to match SecondaryButtonStyle, which a Menu label can't adopt directly.
            HStack(spacing: Spacing.xxs + 2) {
                Image(systemName: "ellipsis")
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryAction.opacity(isEnabled ? 1 : 0.45))
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: HitTarget.minimum)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .hoverEffect(.highlight)
        .accessibilityLabel(title == "More" ? "More actions" : title)
        .optionalAccessibilityIdentifier(identifier)
    }
}

/// Up to two visible buttons side by side, most likely action first, with every other
/// action in a "More" menu. The buttons keep their own styles and identifiers.
/// If the row doesn't fit, the menu drops to a second row; if the two buttons still
/// don't fit side by side, they stack. At accessibility text sizes everything stacks.
struct ActionGroup<Buttons: View, MoreItems: View>: View {
    private let moreTitle: String
    private let moreIdentifier: String?
    private let showsMore: Bool
    private let buttons: Buttons
    private let moreItems: MoreItems
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - moreTitle: visible label of the menu button.
    ///   - moreIdentifier: accessibility identifier for the menu button.
    ///   - showsMore: pass false when the menu's items turn out empty, so no empty
    ///     menu is drawn.
    ///   - buttons: one or two buttons.
    ///   - more: menu items for the remaining actions.
    init(
        moreTitle: String = "More",
        moreIdentifier: String? = nil,
        showsMore: Bool = true,
        @ViewBuilder buttons: () -> Buttons,
        @ViewBuilder more: () -> MoreItems
    ) {
        self.moreTitle = moreTitle
        self.moreIdentifier = moreIdentifier
        self.showsMore = showsMore
        self.buttons = buttons()
        self.moreItems = more()
    }

    private var hasMore: Bool { showsMore && MoreItems.self != EmptyView.self }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                buttons
                menu
            }
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) {
                    buttons
                    menu
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) { buttons }
                    menu
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    buttons
                    menu
                }
            }
        }
    }

    @ViewBuilder private var menu: some View {
        if hasMore {
            MoreMenu(moreTitle, identifier: moreIdentifier) { moreItems }
        }
    }
}

extension ActionGroup where MoreItems == EmptyView {
    /// One or two buttons with no overflow menu.
    init(@ViewBuilder buttons: () -> Buttons) {
        self.init(buttons: buttons, more: { EmptyView() })
    }
}

#Preview("Action group") {
    VStack(alignment: .leading, spacing: Spacing.l) {
        ActionGroup {
            Button("Save look") {}
                .buttonStyle(SecondaryButtonStyle())
            Button("Swap a piece") {}
                .buttonStyle(SecondaryButtonStyle())
        } more: {
            Button("Share", systemImage: "square.and.arrow.up") {}
            Button("Report a problem", systemImage: "flag") {}
            Button("Remove look", systemImage: "trash", role: .destructive) {}
        }
        ActionGroup {
            Button("Try again") {}
                .buttonStyle(PrimaryButtonStyle())
            Button("Edit request") {}
                .buttonStyle(SecondaryButtonStyle())
        }
        MoreMenu {
            Button("Rename") {}
            Button("Delete collection", role: .destructive) {}
        }
    }
    .padding()
    .themedScreenBackground()
}
