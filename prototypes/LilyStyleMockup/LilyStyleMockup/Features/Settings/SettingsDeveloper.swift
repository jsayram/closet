import SwiftUI

// MARK: - Demo Controls

/// Development-only controls: scenario picker, dispatch counter, HUD and fast mocks,
/// simulated access/sync/On Me state, demo reset, the constrained-frame layout lab and
/// a launch-argument cheat sheet. Everything is fictional and local.
struct DeveloperPanelView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.settingsIsInLayoutLab) private var inLab
    @State private var confirmingReset = false

    var body: some View {
        let ui = app.settingsUI
        // A copy of this screen pushed inside the lab frame must never present the lab
        // again (that would stack a lab inside the lab).
        let labPresented = Binding<Bool>(
            get: { !inLab && ui.layoutLabPresented },
            set: { newValue in if !inLab { ui.layoutLabPresented = newValue } }
        )
        GeometryReader { geo in
            SettingsList(horizontalMargin: SettingsLayout.readableMargin(for: geo.size.width, maxContent: 820)) {
                SettingsDeveloperIntroSection()
                SettingsScenarioSection()
                SettingsDispatchSection()
                SettingsDisplaySpeedSection()
                SettingsDemoAccessSection()
                SettingsDemoSyncSection()
                SettingsDemoOnMeSection()
                SettingsLayoutLabSection()
                SettingsLaunchArgumentsSection()
                Section {
                    Button(role: .destructive) {
                        confirmingReset = true
                    } label: {
                        Label("Reset demo data…", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(DestructiveButtonStyle(fullWidth: true))
                    .accessibilityIdentifier("resetDemoButton")
                    .confirmationDialog("Reset demo data?", isPresented: $confirmingReset, titleVisibility: .visible) {
                        Button("Reset demo data", role: .destructive) {
                            app.settingsResetDemoKeepingPlace()
                        }
                        .accessibilityIdentifier("confirmResetDemo")
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Everything returns to the fictional starting data. Nothing is sent anywhere.")
                    }
                } footer: {
                    // What the reset removes stays on screen beside the button.
                    SettingsFooterText("Restores the fictional closet, looks, profile, scenario and counters. You stay on this screen.",
                                       summary: "Restores the fictional starting data.")
                }
                .listRowBackground(Palette.surface)
            }
        }
        .themedScreenBackground()
        .navigationTitle("Demo Controls")
        .fullScreenCover(isPresented: labPresented) {
            SettingsLayoutLabView()
                .environment(app)
                .tint(Palette.primaryAction)
        }
    }
}

private struct SettingsDeveloperIntroSection: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    StatusBadge(kind: .demo)
                    Text("Development only — fictional data")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("developerOnlyLabel")
                CollapsibleText(
                    "These controls change simulated behavior for demos and tests. They never contact a real service, account or store.",
                    summary: "Never contacts a real service.",
                    threshold: 1,
                    topic: "Demo Controls"
                )
            }
            .padding(.vertical, Spacing.xxs)
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: Scenario

private struct SettingsScenarioSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let showsDetails = app.settingsUI.openDetails.contains("scenarioDetails")
        Section {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(DemoScenario.allCases) { scenario in
                    let selected = scenario == app.scenario
                    Button {
                        select(scenario)
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.s) {
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected ? Palette.primaryAction : Palette.secondaryText)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scenario.title)
                                    .font(.subheadline.weight(selected ? .semibold : .regular))
                                    .foregroundStyle(Palette.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                // The chosen scenario always says what it does; the rest
                                // show theirs with "Show descriptions" below.
                                if selected || showsDetails {
                                    Text(scenario.detail)
                                        .font(.caption)
                                        .foregroundStyle(Palette.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, Spacing.xs)
                        .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .hoverEffect(.highlight)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(scenario.title)
                    .accessibilityHint(scenario.detail)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                    .accessibilityIdentifier("scenario-\(scenario.rawValue)")
                    if scenario != DemoScenario.allCases.last {
                        Divider().overlay(Palette.divider)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("scenarioPicker")

            Button(showsDetails ? "Hide descriptions" : "Show descriptions") {
                Motion.perform(reduceMotion: reduceMotion) {
                    app.settingsUI.detailsBinding("scenarioDetails").wrappedValue.toggle()
                }
            }
            .buttonStyle(.quietLink)
            .accessibilityValue(showsDetails ? "Expanded" : "Collapsed")
            .accessibilityHint("Shows what every scenario does")
            .accessibilityIdentifier("scenarioDescriptionsToggle")
        } header: {
            SettingsListHeader("Scenario", systemImage: "theatermasks",
                               info: "Current: \(app.scenario.title). Choosing a scenario changes how the mocks behave from now on; it never restyles by itself.")
        }
        .listRowBackground(Palette.surface)
    }

    private func select(_ scenario: DemoScenario) {
        guard scenario != app.scenario else { return }
        app.scenario = scenario
        app.showToast("Scenario: \(scenario.title).\(hint(scenario))", style: .info)
    }

    private func hint(_ scenario: DemoScenario) -> String {
        switch scenario {
        case .syncConflict: " Review it in Settings, iCloud sync."
        case .exhaustedAllowance: " Styling Access shows the exhausted state."
        case .declinedPermission: " Allow it again in Settings when you're done."
        case .partialCloset: " Style Me now uses Jose's house."
        case .saveFailure: " Saving a look will fail; drafts are kept."
        default: ""
        }
    }
}

// MARK: Dispatch counter

private struct SettingsDispatchSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Recent-call rows stack vertically at accessibility text sizes.
    private var recordLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Spacing.xs))
    }

    var body: some View {
        let log = app.dispatch
        Section {
            HStack {
                Text("Total simulated calls")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Spacer()
                Text("\(log.total)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Palette.primaryAction)
                    .accessibilityLabel("\(log.total)")
                    .accessibilityIdentifier("dispatchCountTotal")
            }
            HStack {
                Label("Reused locally, no call", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Palette.primaryText)
                Spacer()
                Text("\(log.avoidedDispatches)")
                    .monospacedDigit()
                    .foregroundStyle(Palette.success)
                    .accessibilityIdentifier("dispatchAvoided")
            }
            .font(.subheadline)

            DetailsDisclosure(
                "By service",
                count: ServiceKind.allCases.count,
                isExpanded: app.settingsUI.detailsBinding("dispatchByService"),
                identifier: "dispatchByService"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(ServiceKind.allCases) { kind in
                        HStack {
                            Label(kind.label, systemImage: kind.systemImage)
                                .foregroundStyle(Palette.primaryText)
                            Spacer()
                            Text("\(log.count(kind))")
                                .monospacedDigit()
                                .foregroundStyle(Palette.primaryText)
                        }
                        .font(.subheadline)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("dispatchCount-\(kind.rawValue)")
                    }
                }
            }

            if log.records.isEmpty {
                CollapsibleText(
                    "No calls yet. Browsing, scrolling, resizing and opening screens never call a service.",
                    summary: "No calls yet.",
                    threshold: 1,
                    topic: "simulated calls"
                )
            } else {
                DetailsDisclosure(
                    "Recent calls",
                    count: min(log.records.count, 8),
                    isExpanded: app.settingsUI.detailsBinding("dispatchRecent"),
                    identifier: "dispatchRecent"
                ) {
                  VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(log.records.prefix(8)) { record in
                        recordLayout {
                            Image(systemName: record.kind.systemImage)
                                .foregroundStyle(Palette.primaryAction)
                                .accessibilityHidden(true)
                            Text("\(record.kind.label) · \(record.operation)")
                                .font(.footnote)
                                .foregroundStyle(Palette.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Spacing.xs)
                            Text(record.at.formatted(date: .omitted, time: .standard))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Palette.secondaryText)
                        }
                        .accessibilityElement(children: .combine)
                    }
                  }
                }
            }

            Button {
                app.dispatch.reset()
                app.showToast("Counters reset.", style: .info)
            } label: {
                Label("Reset counters", systemImage: "gobackward")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("dispatchReset")
        } header: {
            SettingsListHeader("Simulated service calls", systemImage: "antenna.radiowaves.left.and.right",
                               info: "Counts mock stylist, image, search, ranking, weather and photo calls since launch or the last reset. Only explicit actions should move them.")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: Display & speed

private struct SettingsDisplaySpeedSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var model = app
        Section {
            Toggle(isOn: $model.showDispatchHUD) {
                SettingsRowLabel(title: "Show call counter HUD", subtitle: "Small badge in the top corner of every screen", systemImage: "gauge.with.dots.needle.33percent")
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("showHUDToggle")
            Toggle(isOn: $model.fastMocks) {
                SettingsRowLabel(title: "Fast mocks", subtitle: "Shorter simulated delays for quick demos", systemImage: "hare")
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("fastMocksToggle")
        } header: {
            SettingsListHeader("Display & speed", systemImage: "speedometer")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: Access, sync, On Me

private struct SettingsDemoAccessSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        Section {
            Picker(selection: Binding(get: { app.store.access.plan }, set: { app.store.settingsSimulatePlan($0) })) {
                ForEach(AccessPlan.allCases) { plan in
                    Text(plan.label).tag(plan)
                }
            } label: {
                SettingsRowLabel(title: "Access plan", subtitle: "Simulated entitlement", systemImage: "creditcard")
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("accessPlanPicker")

            Toggle(isOn: Binding(get: { app.purchasesDemo }, set: { app.purchasesDemo = $0 })) {
                SettingsRowLabel(title: "Paywall and purchases", subtitle: "Shows the paywall, picture packs and out-of-pictures screens. Off while testing.", systemImage: "cart")
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("purchasesDemoToggle")
            if app.purchasesDemo {
                Button { app.purchaseSheet = .paywall(.settings) } label: { Label("Preview paywall", systemImage: "sparkles") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("previewPaywallButton")
                Button { app.purchaseSheet = .imagePacks } label: { Label("Preview picture packs", systemImage: "plus.circle") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("previewImagePacksButton")
                Button { app.purchaseSheet = .outOfPictures } label: { Label("Preview out of pictures", systemImage: "photo.badge.exclamationmark") }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityIdentifier("previewOutOfPicturesButton")
                Button {
                    app.store.purchasesUseUpPictures()
                    app.showToast("This month's sample pictures are used up.", style: .info)
                } label: { Label("Use up this month's pictures", systemImage: "photo.stack") }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(access.plan == .sponsored)
                    .accessibilityIdentifier("useUpPicturesButton")
            }
            InfoRow(title: "Style Me today",
                    value: access.plan == .sponsored ? "Not counted (sponsored)" : "\(access.stylingUsedToday) of \(access.terms.dailyStylingAllowance)")
            Button {
                app.store.settingsResetUsage()
                app.showToast("Usage counters cleared.", style: .info)
            } label: {
                Label("Reset usage counters", systemImage: "gobackward")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("resetUsageButton")
            NavigationLink(value: AppRoute.access) {
                SettingsRowLabel(title: "Open Styling Access", subtitle: nil, systemImage: "arrow.right.circle")
            }
        } header: {
            SettingsListHeader("Styling access", systemImage: "creditcard")
        }
        .listRowBackground(Palette.surface)
    }
}

private struct SettingsDemoSyncSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let store = app.store
        let enabled = store.profile.iCloudSyncEnabled
        Section {
            InfoRow(title: "Status", value: store.sync.status.label)
            Button {
                store.settingsSimulateSyncAcknowledged()
                app.showToast("Simulated: iCloud acknowledged every pending change.", style: .info)
            } label: {
                Label("Mark pending changes uploaded", systemImage: "checkmark.icloud")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!enabled || !store.sync.conflicts.isEmpty)
            .accessibilityIdentifier("simulateSyncAckButton")
            Button {
                store.settingsSimulateSyncFailure()
                app.showToast("Simulated sync failure. Local data is untouched.", style: .info)
            } label: {
                Label("Simulate a sync failure", systemImage: "exclamationmark.icloud")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!enabled)
            .accessibilityIdentifier("simulateSyncFailureButton")
        } header: {
            SettingsListHeader("Sync simulation", systemImage: "icloud")
        } footer: {
            SettingsFooterText(enabled
                ? "Use the Sync conflict scenario above to practice conflict review."
                : "Turn on iCloud sync in Settings to use these.")
        }
        .listRowBackground(Palette.surface)
    }
}

private struct SettingsDemoOnMeSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            InfoRow(title: "On Me",
                    value: app.isOnMeReady
                        ? "Ready · simulated reference v\(app.store.profile.onMeReference.version ?? 1)"
                        : "Not set up")
            Button {
                app.enableSimulatedOnMe()
                app.showToast("Simulated On Me reference and permission are set. No real person's photo is used.", style: .info)
            } label: {
                Label("Set up simulated On Me", systemImage: "person.crop.rectangle.badge.plus")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("onMeDemoButton")
        } header: {
            SettingsListHeader("On Me", systemImage: "person.crop.rectangle",
                               info: "Adds a placeholder reference and allows On Me pictures. Previews still only start from an explicit Style Me or Update Preview.")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: Layout lab entry

private struct SettingsLayoutLabSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.settingsIsInLayoutLab) private var inLab

    var body: some View {
        @Bindable var ui = app.settingsUI
        Section {
            if inLab {
                CollapsibleText(
                    "You're viewing Demo Controls inside the layout lab. Change the width or screen with the lab's own controls above the frame.",
                    summary: "You're inside the layout lab.",
                    threshold: 1,
                    topic: "the layout lab"
                )
                .padding(.vertical, Spacing.xxs)
            } else {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                        Text("In-app constrained-frame simulation — not system multitasking")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        InfoButton("the layout lab", title: "Layout lab",
                                   text: "Shows one screen inside a frame of the chosen width: compact size class under 600 pt, regular above. Check real Split View and Stage Manager on an iPad too.")
                    }
                    Picker(selection: $ui.layoutLabSection) {
                        ForEach(SettingsLayoutLabView.sections) { section in
                            Label(section.title, systemImage: section.systemImage).tag(section)
                        }
                    } label: {
                        Text("Screen")
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("layoutLabSectionPicker")
                    // These five chips wrap instead of scrolling: the screenshot tour taps each
                    // width by identifier, so every chip has to be on screen.
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(SettingsLayoutLabView.widths, id: \.self) { width in
                            CapsuleChip(title: "\(Int(width)) pt", systemImage: "rectangle.portrait",
                                        isSelected: ui.layoutLabWidth == width) {
                                ui.openLayoutLab(width: width, resultsShownInline: app.style.resultsShownInline)
                            }
                            .accessibilityIdentifier("layoutLabWidth-\(Int(width))")
                            .accessibilityHint("Opens the layout lab at this width")
                        }
                    }
                    Text("Tap a width to open the lab.")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
                .padding(.vertical, Spacing.xxs)
            }
        } header: {
            SettingsListHeader("Layout lab", systemImage: "rectangle.split.2x1")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: Launch arguments

private struct SettingsLaunchArgument: Identifiable {
    let flag: String
    let meaning: String
    var id: String { flag }
}

private struct SettingsLaunchArgumentsSection: View {
    @Environment(AppModel.self) private var app

    /// Mirrors the `LaunchConfiguration` documentation comment.
    static let arguments: [SettingsLaunchArgument] = [
        SettingsLaunchArgument(flag: "-resetDemo", meaning: "Start from fresh fixtures"),
        SettingsLaunchArgument(flag: "-skipOnboarding", meaning: "Mark onboarding complete"),
        SettingsLaunchArgument(flag: "-fastMocks", meaning: "Shorten simulated delays"),
        SettingsLaunchArgument(flag: "-showHUD", meaning: "Show the dispatch counter"),
        SettingsLaunchArgument(flag: "-scenario <name>", meaning: "DemoScenario raw value: " + DemoScenario.allCases.map(\.rawValue).joined(separator: ", ")),
        SettingsLaunchArgument(flag: "-scope <main|jose|weekend|spring>", meaning: "Starting wardrobe source"),
        SettingsLaunchArgument(flag: "-occasion <raw>", meaning: "Occasion raw value"),
        SettingsLaunchArgument(flag: "-onMeDemo", meaning: "Simulated On Me reference, permission and toggle"),
        SettingsLaunchArgument(flag: "-route <name[:id]>", meaning: "styleMe, results, editor, swap, closet, garment:<id>, suitcases, suitcase:<id>, laundry, search, saved, outfit:<id>, preview:<id>, profile, settings, access, help, feedback, developer, findOne, askStylist, onboarding, addItem, purchase, handoff, savedProducts"),
        SettingsLaunchArgument(flag: "-autoStyle", meaning: "Tap Style Me automatically after launch"),
        SettingsLaunchArgument(flag: "-searchQuery \"<text>\"", meaning: "Prefill the search field"),
    ]

    var body: some View {
        Section {
            DetailsDisclosure(
                "Cheat sheet",
                count: Self.arguments.count,
                isExpanded: app.settingsUI.detailsBinding("launchArguments"),
                identifier: "launchArgumentsToggle"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(Self.arguments) { argument in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(argument.flag)
                                .font(.callout.monospaced())
                                .foregroundStyle(Palette.primaryAction)
                                .textSelection(.enabled)
                            Text(argument.meaning)
                                .font(.caption)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.vertical, Spacing.xxs)
                .accessibilityIdentifier("launchArgumentsCheatSheet")
            }
        } header: {
            SettingsListHeader("Launch arguments", systemImage: "terminal")
        } footer: {
            SettingsFooterText("Example: -resetDemo -skipOnboarding -fastMocks -route settings")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Previews

#Preview("Demo Controls") {
    NavigationStack {
        DeveloperPanelView()
    }
    .previewEnvironment()
}
