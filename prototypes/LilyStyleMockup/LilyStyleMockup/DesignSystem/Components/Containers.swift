import SwiftUI

/// Quiet surface card: 16 pt padding and corner radius, decorative divider edge.
struct CardModifier: ViewModifier {
    var padding: CGFloat = Spacing.m
    var highlighted = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(highlighted ? Palette.primaryAction : Palette.divider, lineWidth: highlighted ? 2 : 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Spacing.m, highlighted: Bool = false) -> some View {
        modifier(CardModifier(padding: padding, highlighted: highlighted))
    }
}

struct SectionHeader<Trailing: View>: View {
    var title: String
    var subtitle: String?
    /// Longer helper text shown from an info button beside the title, in place of a
    /// subtitle that explains how the section works.
    var info: String?
    var editorial = false
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, subtitle: String? = nil, info: String? = nil, editorial: Bool = false, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.info = info
        self.editorial = editorial
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xxs) {
                    Text(title)
                        .font(editorial ? .editorial(.title3) : .headline)
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    if let info {
                        InfoButton(title, text: info)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            Spacer(minLength: Spacing.xs)
            trailing()
        }
    }
}

/// "This is simulated" notice used wherever an action is outside prototype scope.
/// The compact form keeps a short label on screen and puts the full sentence behind
/// an info button. Use `.full` where she has to read the sentence before agreeing
/// to something.
struct SimulationNotice: View {
    enum Style { case compact, full }

    var text: String
    var systemImage = "flask"
    /// Short label that always stays visible in the compact form.
    var label = "Simulated"
    /// Optional single line shown after the label in the compact form.
    var summary: String?
    var style: Style = .compact
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        switch style {
        case .compact: compact
        case .full: full
        }
    }

    private var compact: some View {
        Group {
            if summary == nil {
                compactRow(summary: nil)
            } else if dynamicTypeSize.isAccessibilitySize {
                compactStack
            } else {
                // The label is never cut: when the summary doesn't fit beside it,
                // the summary drops to its own line.
                ViewThatFits(in: .horizontal) {
                    compactRow(summary: summary)
                    compactStack
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactRow(summary: String?) -> some View {
        HStack(spacing: Spacing.xs) {
            ToneBadge(text: label, systemImage: systemImage, tone: .accent, lineLimit: 1)
                .layoutPriority(1)
            if let summary {
                summaryText(summary).lineLimit(1)
            }
            InfoButton(label == "Simulated" ? "what's simulated here" : label, title: label, text: text)
            Spacer(minLength: 0)
        }
    }

    private var compactStack: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            compactRow(summary: nil)
            if let summary {
                summaryText(summary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func summaryText(_ summary: String) -> some View {
        Text(summary)
            .font(.footnote)
            .foregroundStyle(Palette.secondaryText)
    }

    private var full: some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.accentSurface.opacity(0.6)))
        .accessibilityElement(children: .combine)
    }
}

/// Quiet card with an icon (or a numbered step), a headline and an optional subtitle.
/// Used for the Closet detail, garment editor and Find One sections so they read alike.
struct CardSection<Content: View>: View {
    var title: String
    var subtitle: String?
    /// Longer helper text shown from an info button beside the title.
    var info: String?
    var systemImage: String?
    /// Numbered step badge shown in place of the icon (Find One's steps).
    var step: Int?
    @ViewBuilder var content: () -> Content

    init(_ title: String, subtitle: String? = nil, info: String? = nil, systemImage: String? = nil, step: Int? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.info = info
        self.systemImage = systemImage
        self.step = step
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                if let step {
                    Text("\(step)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Palette.onPrimaryAction)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Circle().fill(Palette.primaryAction))
                        .accessibilityHidden(true)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Palette.primaryAction)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xxs) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(Palette.primaryText)
                            .accessibilityAddTraits(.isHeader)
                        if let info {
                            InfoButton(title, text: info)
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// Inline informational/caution/error banner with an optional action.
/// The title always shows. A message longer than two lines shows its first line (or
/// `summary`) with a "More" control that opens the rest in place.
struct InlineBanner: View {
    enum Style { case info, caution, error, success }

    var style: Style = .info
    var title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?
    /// Optional shorter line to show while a long message is closed.
    var summary: String?
    /// Optional shared open state for a long message.
    var isMessageExpanded: Binding<Bool>?

    var body: some View {
        BannerChrome(style: style, title: title, message: message, summary: summary, isMessageExpanded: isMessageExpanded) {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

/// InlineBanner look with action buttons of the caller's own (each can carry its own
/// identifier and hint). With three or more actions, use the `more:` initializer: it
/// keeps two buttons visible and puts the rest in a "More" menu.
struct ActionBanner<Actions: View, MoreItems: View>: View {
    var style: InlineBanner.Style
    var title: String
    var message: String?
    var summary: String?
    var isMessageExpanded: Binding<Bool>?
    var moreIdentifier: String?
    var actions: Actions
    var moreItems: MoreItems

    /// Up to two visible buttons plus a "More" menu for the other actions.
    init(
        style: InlineBanner.Style = .info,
        title: String,
        message: String? = nil,
        summary: String? = nil,
        isMessageExpanded: Binding<Bool>? = nil,
        moreIdentifier: String? = nil,
        @ViewBuilder actions: () -> Actions,
        @ViewBuilder more: () -> MoreItems
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.summary = summary
        self.isMessageExpanded = isMessageExpanded
        self.moreIdentifier = moreIdentifier
        self.actions = actions()
        self.moreItems = more()
    }

    var body: some View {
        BannerChrome(style: style, title: title, message: message, summary: summary, isMessageExpanded: isMessageExpanded) {
            Group {
                if MoreItems.self == EmptyView.self {
                    FlowLayout(spacing: Spacing.xs) { actions }
                } else {
                    ActionGroup(moreIdentifier: moreIdentifier) { actions } more: { moreItems }
                }
            }
            .padding(.top, Spacing.xxs)
        }
    }
}

extension ActionBanner where MoreItems == EmptyView {
    /// One or two buttons. They wrap at large text sizes.
    init(
        style: InlineBanner.Style = .info,
        title: String,
        message: String? = nil,
        summary: String? = nil,
        isMessageExpanded: Binding<Bool>? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.init(style: style, title: title, message: message, summary: summary, isMessageExpanded: isMessageExpanded, actions: actions, more: { EmptyView() })
    }
}

/// Shared icon, text, fill and border for InlineBanner and ActionBanner.
private struct BannerChrome<Footer: View>: View {
    var style: InlineBanner.Style
    var title: String
    var message: String?
    var summary: String?
    var isMessageExpanded: Binding<Bool>?
    @ViewBuilder var footer: () -> Footer

    private var icon: String {
        switch style {
        case .info: "info.circle"
        case .caution: "exclamationmark.circle"
        case .error: "exclamationmark.triangle"
        case .success: "checkmark.circle"
        }
    }

    private var tint: Color {
        switch style {
        case .info, .caution: Palette.primaryAction
        case .error: Palette.error
        case .success: Palette.success
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: icon).foregroundStyle(tint)
            }
            if let message {
                CollapsibleText(message, summary: summary, topic: title, isExpanded: isMessageExpanded)
            }
            footer()
        }
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(style == .success ? Palette.successSurface : Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(tint.opacity(0.5), lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}

/// Label/value row for detail screens.
struct InfoRow: View {
    var title: String
    var value: String
    var valueIsUnknown = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).foregroundStyle(Palette.secondaryText)
                Spacer(minLength: Spacing.s)
                valueText.multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(Palette.secondaryText)
                valueText
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private var valueText: some View {
        Text(value)
            .foregroundStyle(valueIsUnknown ? Palette.secondaryText : Palette.primaryText)
            .italic(valueIsUnknown)
    }
}

/// Themed empty/limited state: an icon, a headline, one sentence and one main action.
/// A longer message folds to two lines with a "More" control. Evidence and anything
/// else go in `details`, which sits behind a details row.
struct EmptyStateView<Details: View>: View {
    var title: String
    var message: String
    var systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?
    var detailsTitle: String
    var detailsCount: Int?
    var detailsExpanded: Binding<Bool>?
    var details: () -> Details

    /// Empty state with extra content behind a details row.
    init(
        title: String,
        message: String,
        systemImage: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        detailsTitle: String,
        detailsCount: Int? = nil,
        detailsExpanded: Binding<Bool>? = nil,
        @ViewBuilder details: @escaping () -> Details
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
        self.detailsTitle = detailsTitle
        self.detailsCount = detailsCount
        self.detailsExpanded = detailsExpanded
        self.details = details
    }

    var body: some View {
        VStack(spacing: Spacing.s) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            Text(title)
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .multilineTextAlignment(.center)
            CollapsibleText(message, collapsedLines: 2, threshold: 3, font: .subheadline, centered: true, topic: title)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, Spacing.xs)
            }
            if Details.self != EmptyView.self {
                DetailsDisclosure(detailsTitle, count: detailsCount, isExpanded: detailsExpanded, content: details)
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.l)
        .frame(maxWidth: 460)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

extension EmptyStateView where Details == EmptyView {
    init(title: String, message: String, systemImage: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.init(title: title, message: message, systemImage: systemImage, actionTitle: actionTitle, action: action, detailsTitle: "Details") { EmptyView() }
    }
}

/// Quiet sentence-case header for Form sections, matching the Settings and Profile lists.
/// Pair it with `.listRowBackground(Palette.surface)` on the section so rows use the warm surface.
struct FormSectionHeader: View {
    var title: String
    /// Longer helper text shown from an info button beside the title.
    var info: String?

    init(_ title: String, info: String? = nil) {
        self.title = title
        self.info = info
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
                .accessibilityAddTraits(.isHeader)
            if let info {
                InfoButton(title, text: info)
            }
        }
        .textCase(nil)
    }
}

// MARK: - Previews

#Preview("Calm containers") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.l) {
            SectionHeader("Suitcase", info: "Looks use only the pieces packed in this suitcase unless you turn that off.")
            SimulationNotice(text: "Nothing is sent anywhere. This step is simulated in the prototype.")
            SimulationNotice(text: "Nothing is sent anywhere. This step is simulated in the prototype.", style: .full)
            InlineBanner(
                style: .caution,
                title: "Partial result · 1 look",
                message: "The stylist could only build one look because two tops are in the wash, the rain jacket hasn't arrived and the weather calls for a warm layer you don't have packed.",
                actionTitle: "Try again",
                action: {}
            )
            ActionBanner(style: .error, title: "Couldn't finish", message: "The connection dropped.") {
                Button("Try again") {}.buttonStyle(SecondaryButtonStyle())
                Button("Edit request") {}.buttonStyle(SecondaryButtonStyle())
            } more: {
                Button("Report a problem", systemImage: "flag") {}
                Button("Discard", systemImage: "trash", role: .destructive) {}
            }
            EmptyStateView(
                title: "Nothing packed yet",
                message: "Add pieces to this suitcase to style from it.",
                systemImage: "suitcase",
                actionTitle: "Add pieces",
                action: {},
                detailsTitle: "What was checked",
                detailsCount: 2
            ) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("This suitcase").font(.footnote)
                    Text("Clean pieces only").font(.footnote)
                }
                .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding()
    }
    .themedScreenBackground()
}
