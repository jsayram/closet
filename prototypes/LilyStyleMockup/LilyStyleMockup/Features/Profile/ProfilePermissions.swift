import SwiftUI

extension PermissionState {
    var profileSystemImage: String {
        switch self {
        case .notAsked: "questionmark.circle"
        case .allowed: "checkmark.shield"
        case .declined: "xmark.shield"
        }
    }

    var profileTone: ProfileToneBadge.Tone {
        switch self {
        case .notAsked: .neutral
        case .allowed: .success
        case .declined: .caution
        }
    }
}

// MARK: - Processing permissions

/// Profile → Processing permissions: one independent row per purpose.
struct ProfilePermissionsSection: View {
    var body: some View {
        Section {
            SimulationNotice(
                text: "Recipients are simulated in this prototype — nothing leaves this device.",
                summary: "Nothing leaves this device."
            )
            ForEach(ProcessingPurpose.allCases) { purpose in
                ProfilePermissionRow(purpose: purpose)
            }
        } header: {
            ProfileListHeader(
                "Processing permissions",
                subtitle: "Each permission covers only its own purpose.",
                info: "Allowing one never allows another. Recipients are simulated in this prototype — nothing leaves this device. Withdrawing stops future requests; it doesn't delete looks or previews you already have.",
                systemImage: "lock.shield"
            )
        }
        .listRowBackground(Palette.surface)
    }
}

/// Recipient, what is sent, current state and Allow / Decline / Withdraw.
struct ProfilePermissionRow: View {
    @Environment(AppModel.self) private var app
    var purpose: ProcessingPurpose

    var body: some View {
        let state = app.store.profile.permission(purpose)
        VStack(alignment: .leading, spacing: Spacing.xs) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    title
                    Spacer(minLength: Spacing.xs)
                    badge(state)
                }
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    title
                    badge(state)
                }
            }
            if state == .allowed {
                // Already agreed: the terms fold away and stay one tap from here.
                DetailsDisclosure(
                    "What's shared",
                    summary: purpose.recipient,
                    isExpanded: app.profileUI.detailsBinding("permissionShared-\(purpose.rawValue)")
                ) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        detail("Recipient", purpose.recipient)
                        detail("What is sent", purpose.dataSent)
                        detail("Retention and training", Self.retentionNote)
                    }
                }
            } else {
                // She is being asked here, so who receives what stays on screen.
                detail("Recipient", purpose.recipient)
                detail("What is sent", purpose.dataSent)
                DetailsDisclosure(
                    "Retention and training",
                    summary: "Not set in this prototype",
                    isExpanded: app.profileUI.detailsBinding("permissionRetention-\(purpose.rawValue)")
                ) {
                    Text(Self.retentionNote)
                        .font(.subheadline)
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let note = note(for: state) {
                Label {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Palette.primaryAction)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.xs) { buttons(state) }
                VStack(alignment: .leading, spacing: Spacing.xs) { buttons(state) }
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private static let retentionNote = "No real provider is chosen in this prototype. A real app shows the provider's actual retention and training terms here before you allow."

    private var title: some View {
        Text(purpose.title)
            .font(.headline)
            .foregroundStyle(Palette.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    private func badge(_ state: PermissionState) -> some View {
        ProfileToneBadge(text: state.label, systemImage: state.profileSystemImage, tone: state.profileTone)
            .accessibilityLabel("\(purpose.title): \(state.label)")
            .accessibilityIdentifier("permissionState-\(purpose.rawValue)")
    }

    private func detail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func buttons(_ state: PermissionState) -> some View {
        if state != .allowed {
            Button {
                app.profileSetPermission(purpose, .allowed)
            } label: {
                Label("Allow", systemImage: "checkmark")
            }
            .buttonStyle(SuccessButtonStyle())
            .accessibilityLabel("Allow \(purpose.title)")
            .accessibilityIdentifier("permissionAllow-\(purpose.rawValue)")
        }
        if state != .declined {
            Button {
                app.profileSetPermission(purpose, .declined)
            } label: {
                Label(state == .allowed ? "Withdraw" : "Decline", systemImage: state == .allowed ? "hand.raised" : "xmark")
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("\(state == .allowed ? "Withdraw" : "Decline") \(purpose.title)")
            .accessibilityHint(state == .allowed ? "Stops future requests for this purpose only" : "")
            .accessibilityIdentifier("permissionDecline-\(purpose.rawValue)")
        }
    }

    private func note(for state: PermissionState) -> String? {
        switch (purpose, state) {
        case (.cloudStyling, .declined):
            return "Style Me needs the cloud stylist on iPhone 12 (simulated). Your closet, saved looks, search and manual outfits still work."
        case (.onMeImages, .allowed) where app.store.profile.onMeReference.version == nil:
            return "On Me previews also need a reference. Add one under On Me reference in this profile."
        case (.onMeImages, .declined):
            return "Outfit boards keep working without pictures."
        case (.photoUnderstanding, .declined):
            return "You can still name and describe garments yourself."
        case (.webSearch, .declined):
            return "Find One can't search for you; your saved links and manual notes still work."
        default:
            return nil
        }
    }
}

// MARK: - Analytics

/// Optional improvement analytics. Off by default; nothing is sent in the prototype.
struct ProfileAnalyticsSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Section {
            Toggle(isOn: Binding(
                get: { app.store.profile.analyticsOptIn },
                set: { on in app.profileSave { $0.analyticsOptIn = on } }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share improvement analytics")
                        .foregroundStyle(Palette.primaryText)
                    Text(app.store.profile.analyticsOptIn ? "On — you can turn it off any time." : "Off (default)")
                        .font(.caption)
                        .foregroundStyle(Palette.secondaryText)
                }
            }
            .frame(minHeight: HitTarget.minimum)
            .accessibilityIdentifier("profileAnalyticsToggle")

            DetailsDisclosure(
                "What it covers",
                summary: "Never what you type",
                isExpanded: app.profileUI.detailsBinding("analytics"),
                identifier: "profileAnalyticsDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ProfileBullet(systemImage: "chart.bar", text: "Would collect: coarse events such as onboarding finished, Style Me completed or failed, outfit saved, with app version and iPhone/iPad.")
                    ProfileBullet(systemImage: "eye.slash", text: "Never: measurements, weight, photos, garment details, searches, prompts or anything you type.")
                    ProfileBullet(systemImage: "arrow.uturn.backward", text: "Turning it off stops collection and clears unsent events. Free and paid features never depend on it.")
                }
            }

            SimulationNotice(text: "Prototype: no analytics are collected or sent, whichever way this is set.", summary: "Nothing is collected or sent.")
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.s, bottom: Spacing.xs, trailing: Spacing.s))
        } header: {
            ProfileListHeader("Analytics", subtitle: "Optional and separate from styling.", systemImage: "chart.line.uptrend.xyaxis")
        }
        .listRowBackground(Palette.surface)
    }
}

/// Icon + wrapped text line.
struct ProfileBullet: View {
    var systemImage: String
    var text: String
    var tint: Color = Palette.primaryAction

    var body: some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Permissions") {
    NavigationStack {
        List {
            ProfilePermissionsSection()
            ProfileAnalyticsSection()
        }
        .scrollContentBackground(.hidden)
        .themedScreenBackground()
    }
    .previewEnvironment()
}
