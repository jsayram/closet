import SwiftUI

// MARK: - Delete My Data scopes

enum SettingsDeleteScope: String, CaseIterable, Identifiable {
    case closet, developer, everything

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closet: "Closet & looks"
        case .developer: "Developer-held data"
        case .everything: "Everything"
        }
    }

    var subtitle: String {
        switch self {
        case .closet: "On this device and in your private iCloud"
        case .developer: "Optional feedback account, support reports and analytics"
        case .everything: "Both of the above"
        }
    }

    var systemImage: String {
        switch self {
        case .closet: "cabinet"
        case .developer: "server.rack"
        case .everything: "trash"
        }
    }

    var removes: [String] {
        let closet = [
            "Every garment, its original photo, names and details",
            "Suitcases and their garment links",
            "Saved looks, collections, drafts and every retained On Me preview",
            "Styling history, profile, measurements, weight, fit notes and preferences",
            "Your private iCloud copy, once iCloud is reachable",
        ]
        let developer = [
            "Your optional feedback account, public ideas and votes",
            "Private support reports you sent",
            "Linked improvement-analytics events and the analytics ID",
        ]
        switch self {
        case .closet: return closet
        case .developer: return developer
        case .everything: return closet + developer
        }
    }

    var keeps: [String] {
        switch self {
        case .closet:
            ["Backup files you saved in Files (delete those in Files)",
             "Feedback account and support reports (a separate scope)",
             "Your App Store subscription: deleting data doesn't cancel billing"]
        case .developer:
            ["Your closet, looks and photos on this device and in iCloud",
             "Minimal billing and security records the law requires",
             "Your App Store subscription"]
        case .everything:
            ["Backup files you saved in Files",
             "Minimal billing and security records the law requires",
             "Your App Store subscription: cancel it in Manage subscription"]
        }
    }

    var includesCloset: Bool { self != .developer }

    var confirmButtonTitle: String {
        switch self {
        case .closet: "Delete closet & looks…"
        case .developer: "Request developer-held deletion…"
        case .everything: "Delete everything…"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .closet: "Delete your closet and looks?"
        case .developer: "Delete developer-held data?"
        case .everything: "Delete all of your data?"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .closet: "This removes your closet and looks from this device and, once reachable, your private iCloud. It can't be undone."
        case .developer: "This asks for your feedback account, support reports and analytics to be deleted. In the prototype it's a simulation."
        case .everything: "This removes your closet and looks here and in iCloud, and asks for developer-held data to be deleted. It can't be undone."
        }
    }

    var simulationNote: String {
        switch self {
        case .closet: "Prototype: local deletion is real for the demo store, then the fictional demo closet is loaded again. iCloud deletion is simulated."
        case .developer: "Prototype: there's no server, feedback account or analytics, so this only shows what a real request would do."
        case .everything: "Prototype: local deletion is real for the demo store, then the fictional demo closet is loaded again. iCloud and developer-held deletion are simulated."
        }
    }
}

extension SettingsDeleteScope {
    /// One line of the simulation note that stays beside the Prototype label.
    var simulationSummary: String {
        switch self {
        case .closet, .everything: "The demo closet reloads after."
        case .developer: "Nothing is sent or deleted."
        }
    }
}

struct SettingsDeletionResult: Equatable {
    var scope: SettingsDeleteScope
    var at: Date
    var headline: String
    var lines: [String]
}

// MARK: - Privacy & data screen

/// Plain data inventory, what each permission would send, permission withdrawal and
/// scoped Delete My Data with consequences, an export-first suggestion and confirmation.
struct PrivacyDataView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var ui = app.settingsUI
        GeometryReader { geo in
            SettingsList(horizontalMargin: SettingsLayout.readableMargin(for: geo.size.width)) {
                SettingsPrivacyIntroSection()
                SettingsInventorySection()
                SettingsPrivacyPermissionsSection()
                SettingsDeleteSection()
                SettingsGoodToKnowSection()
            }
        }
        .themedScreenBackground()
        .navigationTitle("Privacy & Data")
        .settingsLabAwareSheet(item: $ui.privacySheet) { sheet in
            switch sheet {
            case .deleteMyData:
                SettingsDeleteMyDataSheet()
            }
        }
    }
}

private struct SettingsPrivacyIntroSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Text("Your closet lives on your device first")
                    .font(.editorial(.title3))
                    .foregroundStyle(Palette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                CollapsibleText(
                    "Nothing here needs an account. Optional services only receive what their own permission names, and you can withdraw each one separately.",
                    summary: "No account needed. You control each permission.",
                    threshold: 1,
                    font: .subheadline,
                    topic: "your privacy",
                    isExpanded: app.settingsUI.detailsBinding("privacyIntro")
                )
                SimulationNotice(text: "Prototype: every service is simulated, so nothing leaves this device.",
                                 summary: "Nothing leaves this device.")
            }
            .padding(.vertical, Spacing.xxs)
        }
        .listRowBackground(Palette.surface)
    }
}

private struct SettingsInventorySection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let store = app.store
        let place = store.profile.iCloudSyncEnabled ? "This device and your private iCloud (simulated)" : "This device only"
        Section {
            row("cabinet", "Closet", "\(store.garments.count) garments · \(store.settingsPhotoCount) photos")
            row("suitcase", "Suitcases", "\(store.suitcases.count) suitcases · \(store.memberships.count) garment links")
            row("bookmark", "Saved looks", "\(store.savedOutfits.count) looks · \(store.collections.count) collections")
            row("person.crop.rectangle", "Retained previews", "\(store.previews.count) pictures, earlier and disliked included")
            row("clock.arrow.circlepath", "Styling history", "\(store.history.count) structured looks, no raw requests")
            row("ruler", "Profile & fit", "\(store.profile.measurements.count) measurement\(store.profile.measurements.count == 1 ? "" : "s") (\(store.profile.measurements.filter(\.confirmed).count) confirmed) · \(store.profile.weight == nil ? "no weight" : "weight, never shared") · \(store.profile.fitReferences.count) fit references · preferences")
            row("bag", "Shopping notes", "\(store.savedProducts.count) saved products · \(store.reminders.count) reminders")
            row("bubble.left.and.text.bubble.right", "Feedback you wrote", "\(store.submissions.count) ideas · \(store.issueReports.count) private reports (simulated board)")
        } header: {
            SettingsListHeader("Stored on your side", systemImage: "internaldrive")
        } footer: {
            SettingsFooterText("Where: \(place). There's no developer-readable copy of your closet.")
        }
        .listRowBackground(Palette.surface)
    }

    private func row(_ icon: String, _ title: String, _ value: String) -> some View {
        SettingsRowLabel(title: title, subtitle: value, systemImage: icon)
            .accessibilityElement(children: .combine)
    }
}

private struct SettingsPrivacyPermissionsSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            ForEach(ProcessingPurpose.allCases) { purpose in
                SettingsPermissionRow(purpose: purpose, showsDataSent: true)
            }
            SettingsRowLabel(title: "Improvement analytics",
                             subtitle: app.store.profile.analyticsOptIn
                                ? "On: allowlisted events only. Turn it off in Settings."
                                : "Off: nothing is collected.",
                             systemImage: "chart.bar")
                .accessibilityElement(children: .combine)
        } header: {
            SettingsListHeader("What each permission would send", systemImage: "arrow.up.forward.app",
                               info: "Withdrawing stops future requests for that purpose only. Looks and pictures you already have stay unless you delete them below.")
        }
        .listRowBackground(Palette.surface)
    }
}

private struct SettingsDeleteSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.settingsUI
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                CollapsibleText(
                    "Choose what to delete: your closet and looks, developer-held data, or everything. You'll see exactly what happens and can export first. Nothing is deleted until you confirm.",
                    summary: "Nothing is deleted until you confirm.",
                    threshold: 1,
                    font: .subheadline,
                    color: Palette.primaryText,
                    topic: "Delete My Data",
                    isExpanded: ui.detailsBinding("deleteIntro")
                )
                Button(role: .destructive) {
                    ui.openDeleteMyData()
                } label: {
                    Label("Delete My Data…", systemImage: "trash")
                }
                .buttonStyle(DestructiveButtonStyle(fullWidth: true))
                .accessibilityIdentifier("deleteMyDataButton")

                if let result = ui.deletionResult {
                    InlineBanner(style: result.scope.includesCloset ? .success : .info,
                                 title: result.headline,
                                 message: "Requested \(result.at.formatted(.relative(presentation: .named))). \(result.lines.first ?? "")")
                        .accessibilityIdentifier("deletionResultBanner")
                }
            }
            .padding(.vertical, Spacing.xxs)
        } header: {
            SettingsListHeader("Delete My Data", systemImage: "trash")
        }
        .listRowBackground(Palette.surface)
    }
}

private struct SettingsGoodToKnowSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            explainer("Deleting the app isn't Delete My Data",
                      "Deleting the app removes this device's copy. Your private iCloud copy stays so you can restore later. Delete My Data removes both.",
                      "apps.iphone")
            explainer("Exported backups are yours",
                      "Backup files you saved in Files aren't touched by Delete My Data. Delete them in Files if you want them gone.",
                      "folder")
            explainer("Billing is separate",
                      "Deleting your data or the app doesn't cancel a subscription. Cancel it in Manage subscription.",
                      "creditcard")
            NavigationLink(value: AppRoute.access) {
                SettingsRowLabel(title: "Styling access & billing", subtitle: "Manage subscription (simulated)", systemImage: "creditcard")
            }
            .accessibilityIdentifier("privacyManageSubscriptionLink")
        } header: {
            SettingsListHeader("Good to know", systemImage: "info.circle")
        }
        .listRowBackground(Palette.surface)
    }

    private func explainer(_ title: String, _ text: String, _ icon: String) -> some View {
        DetailsDisclosure(title, systemImage: icon, isExpanded: app.settingsUI.detailsBinding("goodToKnow-\(icon)")) {
            SettingsDetailText(text)
        }
    }
}

// MARK: - Delete My Data sheet

/// Scoped deletion review: choose a scope, read the consequences, optionally export
/// first, then confirm. Closet deletion resets the demo store; developer-held
/// deletion is a labelled simulation.
struct SettingsDeleteMyDataSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        let ui = app.settingsUI
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    if ui.deleteSheetShowsResult, let result = ui.deletionResult {
                        SettingsDeletionResultView(result: result) { dismiss() }
                    } else {
                        form(scope: ui.deleteScope)
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .themedScreenBackground()
            .navigationTitle("Delete My Data")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRoute.self) { AppRouteDestination(route: $0) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ui.deleteSheetShowsResult ? "Done" : "Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }

    @ViewBuilder
    private func form(scope: SettingsDeleteScope) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("What do you want to delete?")
            ForEach(SettingsDeleteScope.allCases) { option in
                SettingsDeleteScopeOption(scope: option, isSelected: option == scope) {
                    app.settingsUI.deleteScope = option
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("This deletes")
            ForEach(scope.removes, id: \.self) { line in
                SettingsBullet(line, systemImage: "minus.circle", tint: Palette.error)
            }
            Divider().overlay(Palette.divider)
            DetailsDisclosure(
                "This keeps",
                count: scope.keeps.count,
                isExpanded: app.settingsUI.detailsBinding("deleteKeeps"),
                identifier: "deleteKeepsDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(scope.keeps, id: \.self) { line in
                        SettingsBullet(line, systemImage: "checkmark.circle", tint: Palette.success)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()

        if scope.includesCloset {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Label("Export first?", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(Palette.primaryText)
                Text("A backup lets you restore later. Files you export aren't removed by this.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    SettingsExportReview(isSheetRoot: false)
                } label: {
                    Label("Review export first", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("deleteExportFirst")
                if let at = app.settingsUI.lastExportSimulation {
                    Text("Export reviewed \(at.formatted(.relative(presentation: .named))) (simulated, no file written).")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }

        VStack(alignment: .leading, spacing: Spacing.xs) {
            SettingsBullet("Deleting data doesn't cancel billing. Manage your subscription separately.", systemImage: "creditcard", tint: Palette.secondaryText)
            NavigationLink(value: AppRoute.access) {
                Text("Open Styling access")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("deleteManageSubscription")
        }

        SimulationNotice(text: scope.simulationNote, label: "Prototype", summary: scope.simulationSummary)

        Button(role: .destructive) {
            confirming = true
        } label: {
            Label(scope.confirmButtonTitle, systemImage: "trash")
        }
        .buttonStyle(DestructiveButtonStyle(fullWidth: true))
        .accessibilityIdentifier("deleteMyDataConfirmButton")
        .confirmationDialog(scope.confirmationTitle, isPresented: $confirming, titleVisibility: .visible) {
            Button(scope == .developer ? "Request deletion" : "Delete", role: .destructive) {
                perform(scope)
            }
            .accessibilityIdentifier("confirmDeleteMyData")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(scope.confirmationMessage)
        }
    }

    private func perform(_ scope: SettingsDeleteScope) {
        var lines: [String] = []
        let headline: String
        if scope.includesCloset {
            // Capture the sync choice before the demo store reloads its fixtures, so the
            // result describes her real setup and the reload doesn't quietly turn sync back on.
            let wasSyncing = app.store.profile.iCloudSyncEnabled
            app.settingsResetDemoKeepingPlace()
            lines.append("Your closet, looks, previews, history and profile were removed from this device.")
            if wasSyncing {
                app.store.settingsMarkCloudDeletionPending()
                headline = "Local deletion complete · iCloud deletion pending (simulated)"
                lines.append("Your private iCloud copy would be deleted as soon as iCloud is reachable. It's simulated here, so nothing was contacted.")
            } else {
                app.store.settingsSetICloudSync(false)
                headline = "Local deletion complete · iCloud sync was off (simulated)"
                lines.append("iCloud sync was off, so there was no private iCloud copy to delete. It stays off.")
            }
        } else {
            headline = "Simulation — nothing was sent or deleted"
        }
        if scope != .closet {
            lines.append("Developer-held deletion is simulated: this prototype has no feedback account, server or analytics, so nothing was sent. A real request would remove your feedback account, posts and votes, support reports and linked analytics, then show any pending steps.")
        }
        if scope.includesCloset {
            lines.append("Prototype: the fictional demo closet was loaded again so you can keep exploring.")
        } else {
            lines.append("Your closet on this device and in iCloud is unchanged.")
        }
        lines.append("Exported files in Files and your subscription are unchanged.")
        let result = SettingsDeletionResult(scope: scope, at: .now, headline: headline, lines: lines)
        app.settingsUI.deletionResult = result
        app.settingsUI.deleteSheetShowsResult = true
        app.showToast(headline, style: .info)
    }
}

/// One selectable Delete My Data scope.
private struct SettingsDeleteScopeOption: View {
    var scope: SettingsDeleteScope
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.s) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Palette.primaryAction : Palette.secondaryText)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Label(scope.title, systemImage: scope.systemImage)
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Text(scope.subtitle)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(Spacing.s)
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .fill(isSelected ? Palette.accentSurface : Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(isSelected ? Palette.primaryAction : Palette.controlBorder, lineWidth: isSelected ? 1.5 : 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("deleteScope-\(scope.rawValue)")
    }
}

/// Completion / pending state after a Delete My Data request.
private struct SettingsDeletionResultView: View {
    @Environment(AppModel.self) private var app
    var result: SettingsDeletionResult
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Image(systemName: result.scope.includesCloset ? "checkmark.circle" : "flask")
                .font(.largeTitle)
                .foregroundStyle(result.scope.includesCloset ? Palette.success : Palette.primaryAction)
                .accessibilityHidden(true)
            Text(result.headline)
                .font(.editorial(.title3))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("deletionResultHeadline")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let first = result.lines.first {
                    SettingsBullet(first, systemImage: "info.circle")
                }
                if result.lines.count > 1 {
                    DetailsDisclosure(
                        "What else happened",
                        count: result.lines.count - 1,
                        isExpanded: app.settingsUI.detailsBinding("deletionResult"),
                        identifier: "deletionResultDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(result.lines.dropFirst(), id: \.self) { line in
                                SettingsBullet(line, systemImage: "info.circle")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            Button("Done", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("deletionDoneButton")
        }
    }
}

// MARK: - Previews

#Preview("Privacy & Data") {
    NavigationStack {
        PrivacyDataView()
    }
    .previewEnvironment()
}

#Preview("Delete My Data") {
    SettingsDeleteMyDataSheet()
        .previewEnvironment()
}
