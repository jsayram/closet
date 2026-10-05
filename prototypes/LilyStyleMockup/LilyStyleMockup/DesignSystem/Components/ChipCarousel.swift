import SwiftUI

/// One row of chips or badges that scrolls sideways. When the row holds more than
/// fits, a button at the end opens the full set as a wrapping layout, and closes it
/// again. At accessibility text sizes the content always wraps, so nothing has to be
/// scrolled sideways at large type.
///
/// Pass a binding when the open state has to survive the tab/sidebar switch;
/// otherwise the row keeps its own state.
struct ChipCarousel<Content: View>: View {
    private let spacing: CGFloat
    private let itemsLabel: String
    private let toggleSize: CGFloat
    private let toggleIdentifier: String?
    private let external: Binding<Bool>?
    private let content: Content
    @State private var localExpanded = false
    @State private var contentWidth: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - spacing: gap between items, in the row and when wrapped.
    ///   - isExpanded: optional shared open state.
    ///   - itemsLabel: plural noun for VoiceOver, as in "Show all filters".
    ///   - toggleSize: diameter of the expand button's circle. Use about 24 for badge rows
    ///     so the row stays badge-height; the tap area is 44 pt either way.
    ///   - toggleIdentifier: accessibility identifier for the expand button.
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
    private var overflows: Bool { contentWidth > viewportWidth + 1 }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            FlowLayout(spacing: spacing) { content }
        } else if expanded {
            FlowLayout(spacing: spacing) {
                content
                toggle
            }
        } else {
            HStack(spacing: Spacing.xxs) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) { content }
                        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { viewportWidth = $0 }
                if overflows {
                    toggle
                }
            }
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
            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(Palette.primaryAction)
                .frame(width: toggleSize, height: toggleSize)
                .background(Circle().fill(Palette.surface))
                .overlay(Circle().strokeBorder(Palette.controlBorder, lineWidth: 1))
                .inlineHitTarget()
        }
        .buttonStyle(.pressFeedback)
        .hoverEffect(.highlight)
        .accessibilityLabel(expanded ? "Show fewer \(itemsLabel)" : "Show all \(itemsLabel)")
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
        .optionalAccessibilityIdentifier(toggleIdentifier)
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
