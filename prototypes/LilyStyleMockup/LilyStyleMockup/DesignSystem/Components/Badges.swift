import SwiftUI

/// Text + icon status badge. Meaning never relies on color alone.
enum BadgeKind: Hashable {
    case dirty, unavailable, archived, noLongerOwned, notArrived, arrivalUnknown, missing, trash
    case wishlist, inspiration, notOwned, outsideSource
    case representative, textOnly, yourPhoto
    case simulated, earlier, approximate, mismatch
    case owned, unowned, partial, fromHistory, favorite, disliked, demo, pending, failed, usedThisRequest
    case custom(String, String)

    var text: String {
        switch self {
        case .dirty: "Dirty"
        case .unavailable: "Unavailable"
        case .archived: "Archived"
        case .noLongerOwned: "No longer owned"
        case .notArrived: "Not arrived"
        case .arrivalUnknown: "Arrival unknown"
        case .missing: "Missing"
        case .trash: "In Trash"
        case .wishlist: "Wishlist"
        case .inspiration: "Inspiration"
        case .notOwned: "Not owned"
        case .outsideSource: "Not in this suitcase"
        case .representative: "Representative"
        case .textOnly: "Text only"
        case .yourPhoto: "Your photo (demo)"
        case .simulated: "Simulated"
        case .earlier: "Earlier"
        case .approximate: "Approximate"
        case .mismatch: "Needs review"
        case .owned: "Already own"
        case .unowned: "Not owned — new piece"
        case .partial: "Partial result"
        case .fromHistory: "From your history"
        case .favorite: "Favorite"
        case .disliked: "Disliked"
        case .demo: "Demo"
        case .pending: "Pending"
        case .failed: "Failed"
        case .usedThisRequest: "Using for this request"
        case let .custom(text, _): text
        }
    }

    var systemImage: String {
        switch self {
        case .dirty: "drop.triangle"
        case .unavailable: "clock.badge.exclamationmark"
        case .archived: "archivebox"
        case .noLongerOwned: "arrow.uturn.left.circle"
        case .notArrived: "shippingbox"
        case .arrivalUnknown: "shippingbox.circle"
        case .missing: "questionmark.square.dashed"
        case .trash: "trash"
        case .wishlist: "heart.text.square"
        case .inspiration: "lightbulb"
        case .notOwned: "circle.dashed"
        case .outsideSource: "suitcase"
        case .representative: "photo.artframe"
        case .textOnly: "text.alignleft"
        case .yourPhoto: "camera"
        case .simulated: "flask"
        case .earlier: "clock.arrow.circlepath"
        case .approximate: "circle.lefthalf.filled"
        case .mismatch: "exclamationmark.triangle"
        case .owned: "checkmark.circle.fill"
        case .unowned: "bag.badge.plus"
        case .partial: "square.split.2x1"
        case .fromHistory: "clock"
        case .favorite: "star.fill"
        case .disliked: "hand.thumbsdown"
        case .demo: "theatermasks"
        case .pending: "hourglass"
        case .failed: "xmark.octagon"
        case .usedThisRequest: "checkmark.circle"
        case let .custom(_, icon): icon
        }
    }

    enum Tone { case neutral, caution, success, error, accent }

    var tone: Tone {
        switch self {
        case .dirty, .unavailable, .archived, .notArrived, .arrivalUnknown, .outsideSource, .earlier, .approximate, .pending, .usedThisRequest: .caution
        case .noLongerOwned, .missing, .trash, .mismatch, .failed: .error
        case .owned: .success
        case .simulated, .demo, .unowned, .partial, .fromHistory, .favorite: .accent
        default: .neutral
        }
    }

    /// Current-status badges for a garment, resolved from its canonical record.
    static func status(for garment: Garment) -> [BadgeKind] {
        var badges: [BadgeKind] = []
        if garment.isTrashed { badges.append(.trash) }
        switch garment.ownership {
        case .noLongerOwned: badges.append(.noLongerOwned)
        case .wishlisted: badges.append(.wishlist)
        case .inspiration: badges.append(.inspiration)
        case .purchasedConfirmed:
            switch garment.arrival ?? .unknown {
            case .notArrived: badges.append(.notArrived)
            case .unknown: badges.append(.arrivalUnknown)
            case .arrived: break
            }
        case .owned: break
        }
        switch garment.availability {
        case .dirty: badges.append(.dirty)
        case .unavailable: badges.append(.unavailable)
        case .archived: badges.append(.archived)
        case .available: break
        }
        return badges
    }

    static func image(for kind: ImageSourceKind) -> BadgeKind {
        switch kind {
        case .actualPhoto: .yourPhoto
        case .representative: .representative
        case .textOnly: .textOnly
        }
    }

    static func from(_ issue: EligibilityIssue) -> BadgeKind {
        switch issue {
        case .dirty: .dirty
        case .unavailable: .unavailable
        case .archived: .archived
        case .notArrived: .notArrived
        case .arrivalUnknown: .arrivalUnknown
        case .noLongerOwned: .noLongerOwned
        case .notOwned: .notOwned
        case .trashed: .trash
        case .outsideSource: .outsideSource
        }
    }
}

struct StatusBadge: View {
    var kind: BadgeKind
    var compact = false

    var body: some View {
        ToneBadge(text: kind.text, systemImage: kind.systemImage, tone: kind.tone, lineLimit: compact ? 1 : 2)
    }
}

/// The one badge capsule: text + icon in a tone. StatusBadge and the feature badges
/// (counted summaries, Profile and Settings states) all draw through this.
struct ToneBadge: View {
    var text: String
    var systemImage: String
    var tone: BadgeKind.Tone = .neutral
    var lineLimit: Int? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// At accessibility text sizes the text wraps instead of truncating, so the capsule becomes a rounded rectangle.
    private var wraps: Bool { dynamicTypeSize.isAccessibilitySize }

    private var colors: (fg: Color, bg: Color) {
        switch tone {
        case .neutral: (Palette.secondaryText, Palette.imageWell)
        case .caution: (Palette.primaryText, Palette.accentSurface)
        case .success: (Palette.success, Palette.successSurface)
        case .error: (Palette.error, Palette.surface)
        case .accent: (Palette.primaryAction, Palette.accentSurface)
        }
    }

    private var borderColor: Color { colors.fg.opacity(tone == .error ? 0.6 : 0.25) }

    var body: some View {
        Label {
            Text(text)
                .lineLimit(wraps ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
        }
        .labelStyle(BadgeLabelStyle())
        .font(.caption.weight(.semibold))
        .foregroundStyle(colors.fg)
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, 3)
        .background {
            if wraps {
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous).fill(colors.bg)
            } else {
                Capsule().fill(colors.bg)
            }
        }
        .overlay {
            if wraps {
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous).strokeBorder(borderColor, lineWidth: 1)
            } else {
                Capsule().strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct BadgeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

/// Row of badges. Wraps by default so status badges are never scrolled out of sight;
/// set `scrolls` for long, secondary badge lists that should stay on one line with
/// an expand control.
struct BadgeRow: View {
    var badges: [BadgeKind]
    var compact = true
    var scrolls = false

    var body: some View {
        if badges.isEmpty {
            EmptyView()
        } else if scrolls {
            ChipCarousel(spacing: Spacing.xxs, itemsLabel: "badges", toggleSize: 24) { items }
        } else {
            FlowLayout(spacing: Spacing.xxs) { items }
        }
    }

    private var items: some View {
        ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
            StatusBadge(kind: badge, compact: compact)
        }
    }
}

/// Simple wrapping flow layout for chips and badges.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, min(x - spacing, maxWidth))
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
