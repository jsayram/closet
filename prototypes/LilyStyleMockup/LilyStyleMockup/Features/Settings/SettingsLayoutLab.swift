import SwiftUI

/// Full-screen layout lab: renders one real section root inside a bordered frame of a
/// chosen width, with a compact size class under 600 pt and regular above.
///
/// This is an in-app constrained-frame simulation, not system multitasking. The frame
/// has its own navigation stack, so pushes stay inside it; it shares the real demo
/// data and model, and nothing here dispatches a service.
struct SettingsLayoutLabView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    static let widths: [CGFloat] = [320, 375, 507, 678, 768]
    /// Demo Controls itself is left out so the lab can't open inside itself.
    static let sections: [AppSection] = AppSection.allCases.filter { $0 != .developer }

    var body: some View {
        VStack(spacing: 0) {
            SettingsLayoutLabControls(onClose: { dismiss() })
            Rectangle()
                .fill(Palette.divider)
                .frame(height: 1)
                .accessibilityHidden(true)
            GeometryReader { geo in
                SettingsLayoutLabCanvas(available: geo.size)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .onAppear {
            app.layoutLabWidth = app.settingsUI.layoutLabWidth
        }
        .onChange(of: app.settingsUI.layoutLabWidth) { _, width in
            app.layoutLabWidth = width
        }
        .onDisappear {
            app.layoutLabWidth = nil
            // A wide frame may lay Style Me out inline; give the real screen back its own choice.
            if let saved = app.settingsUI.layoutLabSavedResultsInline {
                app.style.resultsShownInline = saved
                app.settingsUI.layoutLabSavedResultsInline = nil
            }
        }
        .overlay(alignment: .bottom) { SettingsToastMirror() }
    }
}

// MARK: - Controls

private struct SettingsLayoutLabControls: View {
    @Environment(AppModel.self) private var app
    var onClose: () -> Void

    var body: some View {
        @Bindable var ui = app.settingsUI
        let width = ui.layoutLabWidth
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xxs) {
                        Text("Layout lab")
                            .font(.editorial(.title3))
                            .foregroundStyle(Palette.primaryText)
                            .accessibilityAddTraits(.isHeader)
                        InfoButton("the layout lab", title: "Layout lab",
                                   text: "Taps inside act on the real demo data. Screens that open a sheet or switch sections do it in the app behind the lab.")
                    }
                    Text("In-app constrained-frame simulation — not system multitasking")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.primaryAction)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("layoutLabDisclaimer")
                }
                Spacer(minLength: Spacing.xs)
                Button("Close", action: onClose)
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("layoutLabClose")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    Picker(selection: $ui.layoutLabSection) {
                        ForEach(SettingsLayoutLabView.sections) { section in
                            Label(section.title, systemImage: section.systemImage).tag(section)
                        }
                    } label: {
                        Text("Screen")
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, Spacing.xs)
                    .frame(minHeight: HitTarget.minimum)
                    .background(Capsule().fill(Palette.surface))
                    .overlay(Capsule().strokeBorder(Palette.controlBorder, lineWidth: 1))
                    .accessibilityIdentifier("layoutLabSectionPicker")

                    ForEach(Array(SettingsLayoutLabView.widths.enumerated()), id: \.offset) { index, preset in
                        CapsuleChip(title: "\(Int(preset))", systemImage: nil, isSelected: preset == width) {
                            ui.layoutLabWidth = preset
                        }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                        .accessibilityLabel("\(Int(preset)) points wide")
                        .accessibilityIdentifier("layoutLabWidth-\(Int(preset))")
                    }
                }
                .padding(.vertical, 2)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.s) {
                    summary(width)
                    Spacer(minLength: Spacing.xs)
                    scaleToggle($ui.layoutLabScaleToFit)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    summary(width)
                    scaleToggle($ui.layoutLabScaleToFit)
                }
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(Palette.surface.ignoresSafeArea(edges: .top))
    }

    private func summary(_ width: CGFloat) -> some View {
        let sizeClass = width < 600 ? "compact" : "regular"
        let layout: String = switch WidthClass(width: width) {
        case .compact: "single column"
        case .intermediate: "two panes where readable"
        case .wide: "multi-pane"
        }
        return Text("\(Int(width)) pt · \(sizeClass) size class · \(layout)")
            .font(.footnote.monospacedDigit())
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("layoutLabSummary")
    }

    private func scaleToggle(_ binding: Binding<Bool>) -> some View {
        Toggle("Scale to fit", isOn: binding)
            .font(.footnote)
            .fixedSize()
            .accessibilityIdentifier("layoutLabScaleToggle")
    }
}

// MARK: - Canvas

private struct SettingsLayoutLabCanvas: View {
    @Environment(AppModel.self) private var app
    var available: CGSize

    var body: some View {
        let ui = app.settingsUI
        let width = ui.layoutLabWidth
        let inset = Spacing.m
        let availableWidth = max(120, available.width - inset * 2)
        let availableHeight = max(240, available.height - inset * 2)
        let scale = ui.layoutLabScaleToFit ? min(1, availableWidth / width) : 1
        let frameHeight = availableHeight / scale
        let framed = SettingsLayoutLabFrame(section: ui.layoutLabSection, width: width, height: frameHeight)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: width * scale, height: frameHeight * scale, alignment: .topLeading)

        if width * scale <= availableWidth + 0.5 {
            VStack(spacing: Spacing.xxs) {
                framed
                if scale < 1 {
                    Text("Shown at \(Int((scale * 100).rounded()))% so the whole frame fits")
                        .font(.caption2)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(inset)
        } else {
            ScrollView(.horizontal) {
                framed.padding(inset)
            }
        }
    }
}

/// The bordered frame: a real section root with its own navigation stack and size class.
private struct SettingsLayoutLabFrame: View {
    var section: AppSection
    var width: CGFloat
    var height: CGFloat

    private var sizeClass: UserInterfaceSizeClass { width < 600 ? .compact : .regular }

    var body: some View {
        NavigationStack {
            SectionRootView(section: section)
                .environment(\.horizontalSizeClass, sizeClass)
                .navigationDestination(for: AppRoute.self) { route in
                    AppRouteDestination(route: route)
                        .environment(\.horizontalSizeClass, sizeClass)
                }
        }
        .id(section)
        .environment(\.horizontalSizeClass, sizeClass)
        .environment(\.settingsIsInLayoutLab, true)
        .frame(width: width, height: height)
        .background(Palette.background)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.primaryAction, lineWidth: 2)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(section.title), \(Int(width)) points wide")
        .accessibilityIdentifier("layoutLabFrame")
    }
}

#Preview("Layout lab") {
    SettingsLayoutLabView()
        .previewEnvironment()
}
