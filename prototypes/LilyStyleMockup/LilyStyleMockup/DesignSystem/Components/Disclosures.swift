import SwiftUI

// Calm-screen disclosures (Docs/CalmScreens.md): the short version stays on screen and
// the full wording sits one tap away, in the same spot.

extension View {
    /// Gives a small inline control a 44 pt tap area without growing its layout size,
    /// so an info button or a "More" link doesn't push a one-line row taller.
    /// Use it on a Button's label.
    func inlineHitTarget() -> some View {
        overlay {
            Color.clear
                .frame(minWidth: HitTarget.minimum, minHeight: HitTarget.minimum)
                .contentShape(Rectangle())
        }
    }

    /// Sets an accessibility identifier only when one is given, so a missing one
    /// doesn't mask an identifier applied further out.
    @ViewBuilder func optionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

// MARK: - Quiet link

/// Quiet text link for "Why?" and "Learn more". Underlined so it doesn't read as a
/// link by color alone.
struct QuietLinkButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    /// Keeps the text's own height in layout (the tap area is still 44 pt). Use it
    /// when the link sits on a line with other text.
    var inline = false

    func makeBody(configuration: Configuration) -> some View {
        if inline {
            text(configuration).inlineHitTarget()
        } else {
            text(configuration)
                .frame(minHeight: HitTarget.minimum)
                .contentShape(Rectangle())
        }
    }

    private func text(_ configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .underline()
            .foregroundStyle(Palette.primaryAction.opacity(isEnabled ? (configuration.isPressed ? 0.6 : 1) : 0.45))
    }
}

extension ButtonStyle where Self == QuietLinkButtonStyle {
    /// Quiet underlined link with a 44 pt row height.
    static var quietLink: QuietLinkButtonStyle { QuietLinkButtonStyle() }
    /// Quiet underlined link that keeps the text's height (44 pt tap area).
    static var quietLinkInline: QuietLinkButtonStyle { QuietLinkButtonStyle(inline: true) }
}

// MARK: - Details row

/// A closed row with a title, an optional count or short summary and a chevron.
/// Tapping it opens the content in place. Pass a binding when the open state has to
/// survive the tab/sidebar switch; otherwise the row keeps its own state.
struct DetailsDisclosure<Content: View>: View {
    private let title: String
    private let summary: String?
    private let count: Int?
    private let systemImage: String?
    private let identifier: String?
    private let external: Binding<Bool>?
    private let content: () -> Content
    @State private var localExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        _ title: String,
        summary: String? = nil,
        count: Int? = nil,
        systemImage: String? = nil,
        isExpanded: Binding<Bool>? = nil,
        identifier: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.summary = summary
        self.count = count
        self.systemImage = systemImage
        self.external = isExpanded
        self.identifier = identifier
        self.content = content
    }

    private var expanded: Bool { external?.wrappedValue ?? localExpanded }

    private var detail: String? {
        switch (count, summary) {
        case let (count?, summary?): "\(count) · \(summary)"
        case let (count?, nil): "\(count)"
        case let (nil, summary?): summary
        case (nil, nil): nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Button(action: toggle) {
                HStack(spacing: Spacing.xs) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(Palette.primaryAction)
                    }
                    if let detail {
                        // The summary drops under the title when the two don't fit on
                        // one line, so neither gets cut.
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: Spacing.xs) {
                                titleText.lineLimit(1)
                                detailText("· \(detail)").lineLimit(1)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                titleText
                                detailText(detail).lineLimit(2)
                            }
                        }
                        .layoutPriority(1)
                    } else {
                        titleText
                    }
                    Spacer(minLength: Spacing.xs)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressFeedback)
            .hoverEffect(.highlight)
            .accessibilityLabel(detail.map { "\(title), \($0)" } ?? title)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityHint(expanded ? "Hides the details" : "Shows the details")
            .optionalAccessibilityIdentifier(identifier)

            if expanded {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(Motion.cardTransition(reduceMotion: reduceMotion))
            }
        }
    }

    private var titleText: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.primaryText)
            .multilineTextAlignment(.leading)
    }

    private func detailText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.secondaryText)
            .multilineTextAlignment(.leading)
    }

    private func toggle() {
        Motion.perform(reduceMotion: reduceMotion) {
            if let external {
                external.wrappedValue.toggle()
            } else {
                localExpanded.toggle()
            }
        }
    }
}

// MARK: - Info button

/// Body text style used inside an info popover.
struct InfoText: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Small info-circle button that shows helper text in a popover (a half-height sheet
/// on iPhone). It takes a 24 pt square in layout and has a 44 pt tap area.
struct InfoButton<Content: View>: View {
    private let topic: String
    private let title: String
    private let content: () -> Content
    @State private var isPresented = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// - Parameters:
    ///   - topic: what the text is about; VoiceOver reads "About <topic>".
    ///   - title: heading inside the popover. Defaults to the topic.
    init(_ topic: String, title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.topic = topic
        self.title = title ?? topic
        self.content = content
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.subheadline)
                .foregroundStyle(Palette.primaryAction)
                .frame(width: 24, height: 24)
                .inlineHitTarget()
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityLabel("About \(topic)")
        .popover(isPresented: $isPresented) {
            InfoPanel(title: title, showsDone: sizeClass == .compact, content: content) {
                isPresented = false
            }
        }
    }
}

extension InfoButton where Content == InfoText {
    /// Info button for plain helper text.
    init(_ topic: String, title: String? = nil, text: String) {
        self.init(topic, title: title) { InfoText(text: text) }
    }
}

private struct InfoPanel<Content: View>: View {
    var title: String
    var showsDone: Bool
    @ViewBuilder var content: () -> Content
    var dismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Spacing.xs)
                    if showsDone {
                        Button("Done", action: dismiss)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Palette.primaryAction)
                            .frame(minWidth: HitTarget.minimum, minHeight: HitTarget.minimum)
                            .contentShape(Rectangle())
                    }
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.l)
        }
        .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.background)
    }
}

// MARK: - Collapsible text

/// Text that shows in full when it is short, and as one short line with a "More"
/// control when it runs past `threshold` lines. The control opens the full wording in
/// place. Without a `summary` the collapsed line is the start of the text, and
/// VoiceOver still reads the whole text from it. A written `summary` is never cut
/// short: it wraps to a second line, with the control under it, when it doesn't fit
/// beside the control.
struct CollapsibleText: View {
    private let text: String
    private let summary: String?
    private let collapsedLines: Int
    private let threshold: Int
    private let font: Font
    private let color: Color
    private let centered: Bool
    private let topic: String?
    private let external: Binding<Bool>?
    @State private var localExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var thresholdHeight: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - summary: optional shorter line to show while closed, in place of the first line.
    ///   - collapsedLines: lines shown while closed.
    ///   - threshold: the text only collapses when it needs more lines than this.
    ///   - topic: what the text is about, for the control's VoiceOver label.
    init(
        _ text: String,
        summary: String? = nil,
        collapsedLines: Int = 1,
        threshold: Int = 2,
        font: Font = .footnote,
        color: Color = Palette.secondaryText,
        centered: Bool = false,
        topic: String? = nil,
        isExpanded: Binding<Bool>? = nil
    ) {
        self.text = text
        self.summary = summary
        self.collapsedLines = collapsedLines
        self.threshold = threshold
        self.font = font
        self.color = color
        self.centered = centered
        self.topic = topic
        self.external = isExpanded
    }

    private var expanded: Bool { external?.wrappedValue ?? localExpanded }

    /// Measured once laid out; before that, a length guess keeps the first frame close.
    private var isLong: Bool {
        if fullHeight > 0, thresholdHeight > 0 { return fullHeight > thresholdHeight + 1 }
        return text.count > 45 * threshold
    }

    var body: some View {
        Group {
            if !isLong {
                fullText
            } else if expanded {
                VStack(alignment: centered ? .center : .leading, spacing: Spacing.xxs) {
                    fullText
                    toggle
                }
            } else if centered {
                VStack(spacing: Spacing.xxs) {
                    shortText
                    toggle
                }
            } else if summary == nil {
                shortRow
            } else if dynamicTypeSize.isAccessibilitySize {
                shortStack
            } else {
                ViewThatFits(in: .horizontal) {
                    shortRow
                    shortStack
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .background(alignment: .top) { probes }
    }

    private var fullText: some View {
        styled(Text(text))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var shortText: some View {
        styled(Text(summary ?? text))
            .lineLimit(collapsedLines)
    }

    private var shortRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            shortText
            Spacer(minLength: 0)
            toggle
        }
    }

    /// A written summary that doesn't fit beside the control: it wraps, and the
    /// control sits under it.
    private var shortStack: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            styled(Text(summary ?? text))
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : max(collapsedLines, 2))
                .fixedSize(horizontal: false, vertical: true)
            toggle
        }
    }

    private func styled(_ text: Text) -> some View {
        text
            .font(font)
            .foregroundStyle(color)
            .multilineTextAlignment(centered ? .center : .leading)
    }

    private var toggle: some View {
        Button {
            Motion.perform(reduceMotion: reduceMotion) {
                if let external {
                    external.wrappedValue.toggle()
                } else {
                    localExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: 2) {
                Text(expanded ? "Less" : "More")
                Image(systemName: expanded ? "chevron.up" : "chevron.down")
                    .imageScale(.small)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.primaryAction)
            .fixedSize()
            .inlineHitTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(topic.map { "More about \($0)" } ?? "More")
        .accessibilityValue(expanded ? "Expanded" : "Collapsed")
        .accessibilityHint(expanded ? "Shortens the text" : "Shows the full text")
    }

    /// Hidden copies that measure the full height against `threshold` lines at the same width.
    private var probes: some View {
        ZStack(alignment: .top) {
            styled(Text(text))
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
            styled(Text(text))
                .lineLimit(threshold)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { thresholdHeight = $0 }
        }
        .hidden()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#Preview("Details row") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        DetailsDisclosure("What was checked", count: 4, systemImage: "checklist") {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(["Clean pieces", "This suitcase only", "Weather", "Recent wears"], id: \.self) { line in
                    Label(line, systemImage: "checkmark")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
        }
        DetailsDisclosure("Why only one look?", summary: "3 pieces left out") {
            InfoText(text: "Two tops are in the wash and the rain jacket hasn't arrived yet.")
        }
    }
    .cardStyle()
    .padding()
    .themedScreenBackground()
}

#Preview("Info button and quiet link") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        HStack(spacing: Spacing.xxs) {
            Text("Suitcase only")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
            InfoButton("Suitcase only", text: "When this is on, looks use only the pieces packed in this suitcase. Turn it off to borrow from the rest of your closet.")
        }
        Button("Why?") {}
            .buttonStyle(.quietLink)
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            Text("Partial result · 1 look")
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
            Button("Learn more") {}
                .buttonStyle(.quietLinkInline)
        }
    }
    .padding()
    .themedScreenBackground()
}

#Preview("Collapsible text") {
    VStack(alignment: .leading, spacing: Spacing.m) {
        CollapsibleText("Short text stays as it is.")
        CollapsibleText("The stylist could only build one look because two tops are in the wash, the rain jacket hasn't arrived and the weather calls for a warm layer you don't have packed.", topic: "this result")
        CollapsibleText(
            "The stylist could only build one look because two tops are in the wash, the rain jacket hasn't arrived and the weather calls for a warm layer you don't have packed.",
            summary: "Three pieces weren't ready.",
            centered: true
        )
    }
    .padding()
    .themedScreenBackground()
}
