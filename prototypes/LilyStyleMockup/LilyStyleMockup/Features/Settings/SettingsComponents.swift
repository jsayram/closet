import SwiftUI

// MARK: - Layout lab awareness

private struct SettingsIsInLayoutLabKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True for screens rendered inside the Demo Controls layout lab frame.
    var settingsIsInLayoutLab: Bool {
        get { self[SettingsIsInLayoutLabKey.self] }
        set { self[SettingsIsInLayoutLabKey.self] = newValue }
    }
}

/// Presents a sheet from shared `SettingsUIState`, but only from one copy of the
/// screen. While the layout lab is open, the copy inside the lab frame presents and
/// any copy left in the app's navigation stack stays quiet (and the other way round),
/// so one sheet value never triggers two presentations.
private struct SettingsLabAwareSheet<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Environment(AppModel.self) private var app
    @Environment(\.settingsIsInLayoutLab) private var inLab
    @Binding var item: Item?
    let sheetContent: (Item) -> SheetContent

    func body(content: Content) -> some View {
        let isActive = (app.layoutLabWidth != nil) == inLab
        content.sheet(item: Binding(
            get: { isActive ? item : nil },
            set: { newValue in if isActive { item = newValue } }
        )) { value in
            sheetContent(value)
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }
}

extension View {
    func settingsLabAwareSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(SettingsLabAwareSheet(item: item, sheetContent: content))
    }
}

// MARK: - Rows and headers

/// Icon + title + optional wrapped subtitle for list rows.
struct SettingsRowLabel: View {
    var title: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = Palette.primaryAction

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Palette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
    }
}

/// Quiet sentence-case list section header.
struct SettingsListHeader: View {
    var title: String
    var systemImage: String
    /// Notes about the section, shown from an info button beside the title.
    var info: String?

    init(_ title: String, systemImage: String, info: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.info = info
    }

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Label(title, systemImage: systemImage)
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

/// Footnote for list section footers. A long one shows its first line with More.
struct SettingsFooterText: View {
    var text: String
    var summary: String?

    init(_ text: String, summary: String? = nil) {
        self.text = text
        self.summary = summary
    }

    var body: some View {
        CollapsibleText(text, summary: summary)
    }
}

/// Plain paragraph used inside details rows.
struct SettingsDetailText: View {
    var text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Icon + wrapped line used for short explanations and checklists.
struct SettingsBullet: View {
    var text: String
    var systemImage: String = "checkmark"
    var tint: Color = Palette.primaryAction

    init(_ text: String, systemImage: String = "checkmark", tint: Color = Palette.primaryAction) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
    }
}

/// A row label with a trailing badge that moves under the label at accessibility
/// text sizes, so the title and subtitle keep the full row width.
struct SettingsRowWithBadge<Label: View, Badge: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder var label: Label
    @ViewBuilder var badge: Badge

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                label
                badge
            }
        } else {
            HStack(spacing: Spacing.s) {
                label
                Spacer(minLength: 0)
                badge
            }
        }
    }
}

// MARK: - Badge

/// Text + icon capsule with a tone. Meaning is always in the text, never the color alone.
struct SettingsBadge: View {
    typealias Tone = BadgeKind.Tone

    var text: String
    var systemImage: String
    var tone: Tone = .neutral

    var body: some View {
        ToneBadge(text: text, systemImage: systemImage, tone: tone, lineLimit: 3)
    }
}

extension PermissionState {
    var settingsSystemImage: String {
        switch self {
        case .notAsked: "questionmark.circle"
        case .allowed: "checkmark.shield"
        case .declined: "xmark.shield"
        }
    }

    var settingsTone: SettingsBadge.Tone {
        switch self {
        case .notAsked: .neutral
        case .allowed: .success
        case .declined: .caution
        }
    }
}

// MARK: - Count tile

/// A labelled number used in export/import reviews and the data inventory.
struct SettingsCountTile: View {
    var value: String
    var title: String
    var detail: String?
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primaryAction)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(Palette.primaryText)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.divider, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// Adaptive grid of count tiles that stacks at accessibility text sizes.
struct SettingsCountGrid<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 260 : 150), spacing: Spacing.s, alignment: .top)],
                  alignment: .leading, spacing: Spacing.s) {
            content
        }
    }
}

// MARK: - Toast mirror

/// The app's toast overlay sits beneath the layout lab's full-screen cover, so the
/// lab mirrors the current toast. Root sheets host the real overlay, which still
/// handles timing and the VoiceOver announcement.
struct SettingsToastMirror: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let toast = app.toast {
            ToastCard(toast: toast)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .id(toast.id)
        }
    }
}
