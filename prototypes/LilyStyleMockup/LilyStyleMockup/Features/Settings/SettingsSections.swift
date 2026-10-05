import SwiftUI

// MARK: - Default wardrobe view

/// Main Closet or one named active suitcase. This is the same remembered preference
/// Closet and Style Me use, so changing it in either place shows up here.
struct SettingsDefaultViewSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let store = app.store
        let suitcases = store.activeSuitcases()
        let current = app.workingScope
        Section {
            Picker(selection: Binding(get: { app.workingScope }, set: { app.selectScope($0) })) {
                Label("Main Closet", systemImage: "cabinet")
                    .tag(WardrobeScope.mainCloset)
                ForEach(suitcases) { suitcase in
                    let count = store.memberIDs(of: suitcase.id).count
                    Label("\(suitcase.name) · \(count) item\(count == 1 ? "" : "s")", systemImage: "suitcase")
                        .tag(WardrobeScope.suitcase(suitcase.id))
                }
                if let id = current.suitcaseID, !suitcases.contains(where: { $0.id == id }) {
                    Text(store.scopeName(current)).tag(current)
                }
            } label: {
                SettingsRowLabel(title: "Starting view",
                                 subtitle: "Closet and Style Me open here",
                                 systemImage: current.isSuitcase ? "suitcase" : "cabinet")
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("defaultSourcePicker")
            .accessibilityHint("Choose Main Closet or a suitcase. Changing it never restyles.")

            if let reason = store.scopeFallback {
                InlineBanner(style: .caution,
                             title: "Showing Main Closet for now",
                             message: reason.explanation,
                             actionTitle: store.awaitingSourceChoice ? "Use Main Closet" : nil,
                             action: store.awaitingSourceChoice ? { app.selectScope(.mainCloset) } : nil)
                    .accessibilityIdentifier("defaultSourceFallback")
            } else if store.awaitingSourceChoice {
                InlineBanner(style: .caution,
                             title: "Choose a source before styling",
                             message: "Browsing works as usual. Pick a source so styling never broadens on its own.",
                             actionTitle: "Use Main Closet",
                             action: { app.selectScope(.mainCloset) })
            }
        } header: {
            SettingsListHeader("Default wardrobe view", systemImage: "rectangle.stack",
                               info: "Choosing a source in Closet or Style Me updates this too, and it's remembered on this device. A look you're already editing keeps its own source. Changing this never restyles or calls the stylist.")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Styling access row

struct SettingsAccessSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        Section {
            NavigationLink(value: AppRoute.access) {
                SettingsRowWithBadge {
                    SettingsRowLabel(title: access.plan.label, subtitle: usageLine(access), systemImage: "creditcard")
                } badge: {
                    SettingsBadge(text: "Sample", systemImage: "flask", tone: .accent)
                }
            }
            .accessibilityIdentifier("stylingAccessRow")
            .accessibilityHint("Plan, sample terms, usage and purchase simulations")
        } header: {
            SettingsListHeader("Styling access", systemImage: "sparkles",
                               info: "Closet, saved looks, search, manual editing, history and export are always free.")
        }
        .listRowBackground(Palette.surface)
    }

    private func usageLine(_ access: AccessState) -> String {
        if access.plan == .sponsored {
            return "Public daily limits don't apply; technical limits still do."
        }
        guard access.plan.hasStylingAccess else {
            return "Style Me is paused. Everything else keeps working."
        }
        let reset = access.resetsAt.formatted(date: .omitted, time: .shortened)
        return "Style Me \(access.stylingUsedToday) of \(access.terms.dailyStylingAllowance) today · resets \(reset)"
    }
}

// MARK: - Processing permissions

struct SettingsPermissionsSection: View {
    var body: some View {
        Section {
            SimulationNotice(text: "Recipients are simulated, so nothing leaves this device in the prototype.",
                             summary: "Nothing leaves this device.")
            ForEach(ProcessingPurpose.allCases) { purpose in
                SettingsPermissionRow(purpose: purpose)
            }
            NavigationLink(value: AppRoute.profile) {
                SettingsRowLabel(title: "Review in Profile",
                                 subtitle: "What each one sends",
                                 systemImage: "person.crop.circle")
            }
            .accessibilityIdentifier("permissionsProfileLink")
            .accessibilityHint("What each one sends, plus the simulated On Me reference")
        } header: {
            SettingsListHeader("Processing permissions", systemImage: "lock.shield",
                               info: "Each permission covers one purpose and never allows another. Recipients are simulated, so nothing leaves this device in the prototype.\n\nReview in Profile shows what each one sends, plus the simulated On Me reference.")
        }
        .listRowBackground(Palette.surface)
    }
}

/// One purpose: title, named recipient, state and an inline Allow / Withdraw.
struct SettingsPermissionRow: View {
    @Environment(AppModel.self) private var app
    var purpose: ProcessingPurpose
    var showsDataSent = false
    @State private var confirmingAllow = false

    var body: some View {
        let state = app.store.profile.permission(purpose)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    titleBlock
                    Spacer(minLength: Spacing.xs)
                    badge(state)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    titleBlock
                    badge(state)
                }
            }
            if showsDataSent {
                // Allow… shows the recipient and this list again before anything is agreed.
                DetailsDisclosure(
                    "Would send",
                    isExpanded: app.settingsUI.detailsBinding("wouldSend-\(purpose.rawValue)"),
                    identifier: "settingsWouldSend-\(purpose.rawValue)"
                ) {
                    SettingsDetailText(purpose.dataSent)
                }
            }
            actionButton(state)
        }
        .padding(.vertical, Spacing.xxs)
        .confirmationDialog("Allow \(purpose.title)?", isPresented: $confirmingAllow, titleVisibility: .visible) {
            Button("Allow") {
                app.store.setPermission(purpose, .allowed)
                app.showToast("\(purpose.title) allowed. No other permission changed.")
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Recipient: \(purpose.recipient)\nWould send: \(purpose.dataSent)\nSimulated: nothing leaves this device in the prototype.")
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(purpose.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("To \(purpose.recipient)")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func badge(_ state: PermissionState) -> some View {
        SettingsBadge(text: state.label, systemImage: state.settingsSystemImage, tone: state.settingsTone)
            .accessibilityLabel("\(purpose.title): \(state.label)")
            .accessibilityIdentifier("settingsPermissionState-\(purpose.rawValue)")
    }

    @ViewBuilder
    private func actionButton(_ state: PermissionState) -> some View {
        if state == .allowed {
            Button {
                app.store.setPermission(purpose, .declined)
                app.showToast("Withdrawn: \(purpose.title). Future requests stop; looks and pictures you already have stay.", style: .info)
            } label: {
                Label("Withdraw", systemImage: "hand.raised")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Withdraw \(purpose.title)")
            .accessibilityHint("Stops future requests for this purpose only")
            .accessibilityIdentifier("settingsWithdraw-\(purpose.rawValue)")
        } else {
            Button {
                confirmingAllow = true
            } label: {
                Label("Allow…", systemImage: "checkmark")
            }
            .buttonStyle(SuccessButtonStyle())
            .accessibilityLabel("Allow \(purpose.title)")
            .accessibilityHint("Shows the recipient and what would be sent before allowing")
            .accessibilityIdentifier("settingsAllow-\(purpose.rawValue)")
        }
    }
}

// MARK: - iCloud sync

struct SettingsSyncSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let store = app.store
        let sync = store.sync
        let enabled = store.profile.iCloudSyncEnabled
        Section {
            Toggle(isOn: Binding(get: { app.store.profile.iCloudSyncEnabled },
                                 set: { app.store.settingsSetICloudSync($0) })) {
                SettingsRowLabel(title: "Private iCloud sync",
                                 subtitle: enabled ? "On. A full copy also stays on this device." : "Off. Everything is saved on this device only.",
                                 systemImage: "icloud")
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("syncToggle")

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Image(systemName: statusIcon(sync.status))
                        .foregroundStyle(statusTint(sync.status))
                        .accessibilityHidden(true)
                    Text(sync.status.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("syncStatus")

                if let saveError = store.lastSaveError {
                    // A failed local save is a blocker, so it stays on screen.
                    InfoRow(title: "On this device", value: saveError)
                }
                DetailsDisclosure(
                    "Sync details",
                    count: 3,
                    isExpanded: app.settingsUI.detailsBinding("syncDetails"),
                    identifier: "syncDetails"
                ) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        InfoRow(title: "On this device", value: store.lastSaveError ?? "Saved")
                        InfoRow(title: "Waiting to upload", value: pendingText(sync.status))
                        InfoRow(title: "Last iCloud acknowledgement",
                                value: sync.lastAcknowledged.map { "\($0.formatted(.relative(presentation: .named))) (simulated)" } ?? "None yet",
                                valueIsUnknown: sync.lastAcknowledged == nil)
                    }
                }
            }
            .padding(.vertical, Spacing.xxs)

            if enabled, case .failed = sync.status {
                Button {
                    app.store.settingsRetrySync()
                    app.showToast("Retry queued (simulated). Your local copy was never affected.", style: .info)
                } label: {
                    Label("Retry sync", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("syncRetryButton")
            }

            ForEach(sync.conflicts) { conflict in
                SettingsConflictCard(conflict: conflict)
            }

            if sync.conflicts.isEmpty, let message = app.settingsUI.lastConflictResolution {
                InlineBanner(style: .success, title: "Conflict resolved", message: message,
                             actionTitle: "OK", action: { app.settingsUI.lastConflictResolution = nil })
                    .accessibilityIdentifier("conflictResolvedBanner")
            }

            SimulationNotice(text: "Simulated — no iCloud connection in the prototype. A last-sync time doesn't mean later edits were uploaded.",
                             systemImage: "icloud.slash",
                             summary: "No iCloud connection.")
        } header: {
            SettingsListHeader("iCloud sync", systemImage: "icloud",
                               info: "Sync keeps your devices up to date; it isn't a backup. Use Export for a snapshot you keep.")
        }
        .listRowBackground(Palette.surface)
    }

    private func pendingText(_ status: SyncStatus) -> String {
        switch status {
        case .off: "Nothing (sync is off)"
        case .upToDate: "Nothing waiting"
        case let .pending(count): "\(count) change\(count == 1 ? "" : "s") (simulated)"
        case .failed: "Changes not uploaded yet"
        case .conflict: "Waiting for your review"
        }
    }

    private func statusIcon(_ status: SyncStatus) -> String {
        switch status {
        case .off: "icloud.slash"
        case .upToDate: "checkmark.icloud"
        case .pending: "arrow.triangle.2.circlepath.icloud"
        case .failed: "exclamationmark.icloud"
        case .conflict: "exclamationmark.arrow.triangle.2.circlepath"
        }
    }

    private func statusTint(_ status: SyncStatus) -> Color {
        switch status {
        case .upToDate: Palette.success
        case .failed: Palette.error
        default: Palette.primaryAction
        }
    }
}

/// Review for one competing edit: both values side by side, nothing overwritten until she chooses.
struct SettingsConflictCard: View {
    @Environment(AppModel.self) private var app
    var conflict: SyncConflict

    var body: some View {
        let garment = app.store.garment(conflict.garmentID)
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label {
                Text("Needs your review")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
            } icon: {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .foregroundStyle(Palette.primaryAction)
            }
            HStack(alignment: .top, spacing: Spacing.s) {
                if let garment {
                    GarmentThumbnail(garment: garment, size: 64, showsStatus: false)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(garment?.displayName ?? "Deleted item")
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Text("\(conflict.field) was changed on two devices.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { valueTiles }
                VStack(spacing: Spacing.xs) { valueTiles }
            }
            CollapsibleText(
                "Nothing is overwritten until you choose. The value you keep applies to this garment everywhere.",
                summary: "Nothing is overwritten until you choose.",
                threshold: 1,
                topic: "this conflict"
            )
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { buttons }
                VStack(alignment: .leading, spacing: Spacing.xs) { buttons }
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var valueTiles: some View {
        valueTile("This device", conflict.thisDeviceValue, systemImage: "iphone")
        valueTile("Other device", conflict.otherDeviceValue, systemImage: "ipad")
    }

    private func valueTile(_ title: String, _ value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.s)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.background))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var buttons: some View {
        Button {
            resolve(keepThisDevice: true)
        } label: {
            Label("Keep this device (\(conflict.thisDeviceValue))", systemImage: "iphone")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("resolveConflictThisDevice")

        Button {
            resolve(keepThisDevice: false)
        } label: {
            Label("Use other device (\(conflict.otherDeviceValue))", systemImage: "ipad")
        }
        .buttonStyle(SecondaryButtonStyle())
        .accessibilityIdentifier("resolveConflictOtherDevice")
    }

    private func resolve(keepThisDevice: Bool) {
        let message = app.store.settingsResolveSyncConflict(conflict.id, keepThisDevice: keepThisDevice)
        guard !message.isEmpty else { return }
        app.settingsUI.lastConflictResolution = message
        app.showToast(message)
    }
}

// MARK: - Backup

struct SettingsBackupSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.settingsUI
        Section {
            Button {
                ui.openExport()
            } label: {
                SettingsRowLabel(title: "Export backup…", subtitle: "Review what a backup would include", systemImage: "square.and.arrow.up")
            }
            .accessibilityIdentifier("exportButton")
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button {
                ui.openImport()
            } label: {
                SettingsRowLabel(title: "Import backup…", subtitle: "Preview before anything changes", systemImage: "square.and.arrow.down")
            }
            .accessibilityIdentifier("importButton")

            if let at = ui.lastExportSimulation {
                Text("Last export review \(at.formatted(.relative(presentation: .named))). Simulated, so no file was written.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            SettingsListHeader("Backup", systemImage: "externaldrive",
                               info: "An export is a snapshot you keep in Files. It doesn't update itself; iCloud sync handles ongoing changes.\n\nImport lets you preview and check a backup before anything changes.")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Privacy & data link

struct SettingsPrivacyLinkSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            NavigationLink(value: AppRoute.privacyData) {
                SettingsRowLabel(title: "Privacy & data",
                                 subtitle: "What's stored, and Delete My Data",
                                 systemImage: "hand.raised")
            }
            .accessibilityIdentifier("privacyDataRow")
            .accessibilityHint("What's stored, what each permission would send, and Delete My Data")
            if let result = app.settingsUI.deletionResult {
                Text("Last deletion request: \(result.headline)")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            SettingsListHeader("Privacy", systemImage: "lock",
                               info: "Privacy & data shows what's stored, what each permission would send, and Delete My Data.")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Analytics

struct SettingsAnalyticsSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let on = app.store.profile.analyticsOptIn
        Section {
            Toggle(isOn: Binding(get: { app.store.profile.analyticsOptIn },
                                 set: { value in app.store.updateProfile { $0.analyticsOptIn = value } })) {
                SettingsRowLabel(title: "Share improvement analytics",
                                 subtitle: on ? "On. Turn it off any time." : "Off (default)",
                                 systemImage: "chart.bar")
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("analyticsToggle")

            DetailsDisclosure(
                "What it covers",
                summary: "Allowlisted events, never what you type",
                isExpanded: app.settingsUI.detailsBinding("analytics"),
                identifier: "analyticsDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SettingsBullet("Only allowlisted events: onboarding steps, Style Me finished or failed, saves and swaps, export and sync outcomes, app version and iPhone or iPad.", systemImage: "list.bullet.rectangle")
                    SettingsBullet("Never measurements, weight, photos, garment details, searches, prompts or anything you type.", systemImage: "eye.slash")
                    SettingsBullet("Turning it off stops collection and clears unsent events. No feature depends on it.", systemImage: "arrow.uturn.backward")
                }
            }

            SimulationNotice(text: "Prototype: nothing is collected or sent, whichever way this is set.",
                             summary: "Nothing is collected or sent.")
        } header: {
            SettingsListHeader("Analytics", systemImage: "chart.line.uptrend.xyaxis")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Help, support and legal

struct SettingsHelpSupportSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Section {
            NavigationLink(value: AppRoute.help) {
                SettingsRowLabel(title: "Help", subtitle: "Short task guides. Works offline.", systemImage: "questionmark.circle")
            }
            .accessibilityIdentifier("helpRow")

            NavigationLink(value: AppRoute.releaseNotes) {
                SettingsRowLabel(title: "What changed", subtitle: "Version notes and known limitations", systemImage: "sparkles.rectangle.stack")
            }
            .accessibilityIdentifier("releaseNotesRow")

            Button {
                app.open(.feedback, compact: sizeClass == .compact)
            } label: {
                SettingsRowLabel(title: "Feedback & support", subtitle: "Ideas board and private issue reports", systemImage: "bubble.left.and.text.bubble.right")
            }
            .accessibilityIdentifier("feedbackSupportRow")

            Button {
                app.settingsUI.settingsSheet = .terms
            } label: {
                SettingsRowLabel(title: "Terms of Use", subtitle: "Draft placeholder", systemImage: "doc.text")
            }
            .accessibilityIdentifier("termsRow")

            Button {
                app.settingsUI.settingsSheet = .privacyPolicy
            } label: {
                SettingsRowLabel(title: "Privacy Policy", subtitle: "Draft placeholder", systemImage: "lock.doc")
            }
            .accessibilityIdentifier("privacyPolicyRow")
        } header: {
            SettingsListHeader("Help & support", systemImage: "lifepreserver")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - Connections (exploration only)

/// PRD 24.5: informational text only. No toggle, no sign-in, no connection.
struct SettingsConnectionsSection: View {
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        title
                        Spacer(minLength: Spacing.xs)
                        badge
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        title
                        badge
                    }
                }
                CollapsibleText(
                    "This is being researched only. There's no sign-in or connection here, and styling in this prototype never uses a ChatGPT plan.",
                    summary: "Research only. No sign-in or connection.",
                    threshold: 1,
                    topic: "the ChatGPT plan connection"
                )
            }
            .padding(.vertical, Spacing.xxs)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("chatGPTPlanInfo")
        } header: {
            SettingsListHeader("Connections", systemImage: "link")
        }
        .listRowBackground(Palette.surface)
    }

    private var title: some View {
        SettingsRowLabel(title: "Optional ChatGPT plan connection",
                         subtitle: "Exploration — not available",
                         systemImage: "link",
                         tint: Palette.secondaryText)
    }

    private var badge: some View {
        SettingsBadge(text: "Not available", systemImage: "circle.slash", tone: .neutral)
    }
}

// MARK: - Development

struct SettingsDevelopmentSection: View {
    var body: some View {
        Section {
            NavigationLink(value: AppRoute.developer) {
                SettingsRowWithBadge {
                    SettingsRowLabel(title: "Demo Controls", subtitle: "Development only — fictional data", systemImage: "slider.horizontal.3")
                } badge: {
                    StatusBadge(kind: .demo, compact: true)
                }
            }
            .accessibilityIdentifier("demoControlsRow")
        } header: {
            SettingsListHeader("Development", systemImage: "hammer")
        }
        .listRowBackground(Palette.surface)
    }
}

// MARK: - About

struct SettingsAboutSection: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.1"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("My Petite Style")
                    .font(.editorial(.headline))
                    .foregroundStyle(Palette.primaryText)
                Text("Working title · prototype \(version)")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                SimulationNotice(
                    text: "Working title · prototype \(version). Fictional data and simulated services; nothing you do here leaves this device.",
                    label: "Prototype",
                    summary: "Nothing leaves this device."
                )
            }
            .padding(.vertical, Spacing.xxs)
        }
        .listRowBackground(Palette.surface)
    }
}
