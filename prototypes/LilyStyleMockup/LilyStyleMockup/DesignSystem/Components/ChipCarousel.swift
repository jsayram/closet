import SwiftUI

/// One row of chips or badges. Only chips that fit whole are shown; nothing is cut
/// off at the edge. When some don't fit, a "More" pill after the last visible chip
/// opens the full set as a wrapping layout, and "Less" closes it again. At
/// accessibility text sizes the content always wraps.
///
/// Pass a binding when the open state has to survive the tab/sidebar switch;
/// otherwise the row keeps its own state. For one choice out of many, prefer
/// `DropdownChip`, which always shows the current choice.
struct ChipCarousel<Content: View>: View {
    private let spacing: CGFloat
    private let itemsLabel: String
    private let toggleSize: CGFloat
    private let toggleIdentifier: String?
    private let external: Binding<Bool>?
    private let content: Content
    @State private var localExpanded = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - spacing: gap between items, in the row and when wrapped.
    ///   - isExpanded: optional shared open state.
    ///   - itemsLabel: plural noun for VoiceOver, as in "Show all filters".
    ///   - toggleSize: height of the More pill. Use about 24 for badge rows so the
    ///     row stays badge-height; the tap area is 44 pt either way.
    ///   - toggleIdentifier: accessibility identifier for the More pill.
    init(
        spacing: CGFloat = Spacing.xs,
        isExpanded: Binding<Bool>? = nil,
        itemsLabel: String = "items",
        toggleSize: CGFloat = 32,
        toggleIdentifier: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.external = isExpanded
        self.itemsLabel = itemsLabel
        self.toggleSize = toggleSize
        self.toggleIdentifier = toggleIdentifier
        self.content = content()
    }

    private var expanded: Bool { external?.wrappedValue ?? localExpanded }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            FlowLayout(spacing: spacing) { content }
        } else if expanded {
            FlowLayout(spacing: spacing) {
                content
                toggle
            }
        } else {
            WholeChipRowLayout(spacing: spacing) {
                content
                toggle
            }
            .clipped()
        }
    }

    private var toggle: some View {
        Button {
            Motion.perform(reduceMotion: reduceMotion, Motion.layout) {
                if let external {
                    external.wrappedValue.toggle()
                } else {
                    localExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                Text(expanded ? "Less" : "More")
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .imageScale(.small)
            }
            .font((toggleSize < 30 ? Font.caption : Font.subheadline).weight(.semibold))
            .foregroundStyle(Palette.primaryAction)
            .padding(.horizontal, toggleSize < 30 ? Spacing.xs : Spacing.s)
            .frame(height: toggleSize)
            .inlineHitTarget()
        }
        .buttonStyle(.pressFeedback)
        .hoverEffect(.highlight)
        .accessibilityLabel(expanded ? "Show fewer \(itemsLabel)" : "Show all \(itemsLabel)")
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
        .optionalAccessibilityIdentifier(toggleIdentifier)
    }
}

/// Lays chips out on one line and shows only the ones that fit whole. The last
/// subview is the More control: it sits right after the last visible chip, and is
/// moved out of sight along with the chips that don't fit when everything fits.
private struct WholeChipRowLayout: Layout {
    var spacing: CGFloat

    private static let offstage: CGFloat = -20_000

    private func plan(width: CGFloat?, subviews: Subviews) -> (sizes: [CGSize], visible: Int, showsToggle: Bool) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        guard let toggleSize = sizes.last else { return ([], 0, false) }
        let chips = sizes.dropLast()
        let total = chips.reduce(0) { $0 + $1.width } + spacing * CGFloat(max(chips.count - 1, 0))
        guard let width, total > width + 0.5 else { return (sizes, chips.count, false) }
        var x: CGFloat = 0
        var visible = 0
        for size in chips {
            if x + size.width + spacing + toggleSize.width > width { break }
            x += size.width + spacing
            visible += 1
        }
        // Always show at least one chip, squeezed if it has to be.
        return (sizes, max(visible, 1), true)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let plan = plan(width: proposal.width, subviews: subviews)
        guard !plan.sizes.isEmpty else { return .zero }
        var shown = Array(plan.sizes.prefix(plan.visible))
        if plan.showsToggle, let toggle = plan.sizes.last { shown.append(toggle) }
        let natural = shown.reduce(0) { $0 + $1.width } + spacing * CGFloat(max(shown.count - 1, 0))
        let height = shown.map(\.height).max() ?? 0
        return CGSize(width: min(natural, proposal.width ?? natural), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let plan = plan(width: bounds.width, subviews: subviews)
        guard !plan.sizes.isEmpty else { return }
        let toggleIndex = subviews.count - 1
        let toggleWidth = plan.showsToggle ? plan.sizes[toggleIndex].width + spacing : 0
        var x = bounds.minX
        for index in subviews.indices {
            let size = plan.sizes[index]
            let isToggle = index == toggleIndex
            if (isToggle && plan.showsToggle) || (!isToggle && index < plan.visible) {
                let room = bounds.maxX - x - (isToggle ? 0 : toggleWidth)
                let width = min(size.width, max(room, 0))
                subviews[index].place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading,
                                      proposal: ProposedViewSize(width: width, height: size.height))
                x += width + spacing
            } else {
                subviews[index].place(at: CGPoint(x: Self.offstage, y: bounds.midY), anchor: .leading,
                                      proposal: ProposedViewSize(size))
            }
        }
    }
}

/// A chip that opens a menu of choices and always shows the current one. Use it for
/// one choice out of many (category, kind, type filter) instead of a long chip row.
struct DropdownChip<Item: Hashable>: View {
    var items: [Item]
    var selection: Item
    var title: (Item) -> String
    var systemImage: (Item) -> String? = { _ in nil }
    var identifier: ((Item) -> String)? = nil
    /// Shown as active (tinted) when the choice narrows what's on screen.
    var isActive = false
    /// Read before the value by VoiceOver, as in "Type, All types".
    var accessibilityTitle: String
    var menuIdentifier: String? = nil
    var onSelect: (Item) -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Menu {
            Picker(accessibilityTitle, selection: Binding(get: { selection }, set: { item in
                Haptics.selection()
                onSelect(item)
            })) {
                ForEach(items, id: \.self) { item in
                    Group {
                        if let image = systemImage(item) {
                            Label(title(item), systemImage: image)
                        } else {
                            Text(title(item))
                        }
                    }
                    .optionalAccessibilityIdentifier(identifier?(item))
                    .tag(item)
                }
            }
        } label: {
            HStack(spacing: Spacing.xxs + 2) {
                if let image = systemImage(selection) {
                    Image(systemName: image)
                        .font(.subheadline)
                }
                Text(title(selection))
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isActive ? Palette.primaryAction : Palette.secondaryText)
            }
            .foregroundStyle(isActive ? Palette.primaryAction : Palette.primaryText)
            .padding(.horizontal, Spacing.m)
            .frame(minHeight: HitTarget.minimum)
            .background(Capsule().fill(isActive ? Palette.accentSurface : Palette.surface))
            .overlay(Capsule().strokeBorder(isActive ? Palette.primaryAction : Palette.controlBorder, lineWidth: isActive ? 1.5 : 1))
            .contentShape(Capsule())
        }
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(title(selection))
        .optionalAccessibilityIdentifier(menuIdentifier)
    }
}

#Preview("Chip carousel") {
    struct Demo: View {
        @State private var selected: Set<String> = ["Work"]
        let occasions = ["Work", "Dinner", "Weekend", "Travel", "Wedding guest", "Date night", "Gym", "Beach"]

        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.l) {
                ChipCarousel(itemsLabel: "occasions") {
                    ForEach(occasions, id: \.self) { occasion in
                        CapsuleChip(title: occasion, isSelected: selected.contains(occasion)) {
                            selected.formSymmetricDifference([occasion])
                        }
                    }
                }
                ChipCarousel(spacing: Spacing.xxs, itemsLabel: "badges", toggleSize: 24) {
                    ForEach([BadgeKind.dirty, .notArrived, .wishlist, .representative, .simulated, .approximate], id: \.self) { badge in
                        StatusBadge(kind: badge, compact: true)
                    }
                }
                ChipCarousel(itemsLabel: "filters") {
                    CapsuleChip(title: "Tops", isSelected: false) {}
                    CapsuleChip(title: "Shoes", isSelected: true) {}
                }
            }
            .padding()
            .themedScreenBackground()
        }
    }
    return Demo()
}
