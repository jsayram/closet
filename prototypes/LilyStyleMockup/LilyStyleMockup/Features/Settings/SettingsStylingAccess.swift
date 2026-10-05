import SwiftUI

// MARK: - Simulated StoreKit actions

enum SettingsStoreKitAction: String, Identifiable, CaseIterable {
    case startTrial, restore, redeem, manage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startTrial: "Start free trial"
        case .restore: "Restore purchases"
        case .redeem: "Redeem offer code"
        case .manage: "Manage subscription"
        }
    }

    var systemImage: String {
        switch self {
        case .startTrial: "gift"
        case .restore: "arrow.clockwise.circle"
        case .redeem: "ticket"
        case .manage: "slider.horizontal.3"
        }
    }

    var identifier: String {
        switch self {
        case .startTrial: "startTrialButton"
        case .restore: "restorePurchasesButton"
        case .redeem: "redeemCodeButton"
        case .manage: "manageSubscriptionButton"
        }
    }

    /// What the real StoreKit flow would do.
    var realFlow: [String] {
        switch self {
        case .startTrial:
            ["Apple's purchase sheet shows the real local price and your renewal date.",
             "Your free month starts only when you confirm there.",
             "You can cancel any time in Manage subscription."]
        case .restore:
            ["Asks the App Store for purchases on your Apple Account.",
             "Brings back monthly access or a redeemed complimentary unlock.",
             "It doesn't restore closet data. That comes from iCloud sync or a backup."]
        case .redeem:
            ["Opens Apple's offer-code sheet.",
             "A complimentary code unlocks styling with no recurring billing.",
             "Redeeming doesn't cancel an existing monthly subscription. Use Manage subscription for that."]
        case .manage:
            ["Opens Apple's subscription settings for your account.",
             "Cancelling stops future renewals; access lasts until Apple reports it has ended.",
             "Your closet, looks and history stay whether or not you subscribe."]
        }
    }
}

/// One simulated outcome the demo can apply.
struct SettingsStoreKitOutcome: Identifiable {
    var id: String { title }
    var title: String
    var plan: AccessPlan?
    var result: String
}

extension SettingsStoreKitAction {
    func outcomes(current: AccessPlan) -> [SettingsStoreKitOutcome] {
        switch self {
        case .startTrial:
            if current == .trialEligible {
                return [SettingsStoreKitOutcome(title: "Simulate starting the free trial", plan: .trialActive,
                                                result: "Free trial (sample) is active in this demo. A real trial would show Apple's renewal date.")]
            }
            if current == .expired {
                return [SettingsStoreKitOutcome(title: "Simulate resubscribing", plan: .subscribed,
                                                result: "Monthly styling access (sample) is active again, with your existing closet and preferences.")]
            }
            return []
        case .restore:
            return [SettingsStoreKitOutcome(title: "Simulate: monthly access found", plan: .subscribed,
                                            result: "Restored monthly styling access (sample)."),
                    SettingsStoreKitOutcome(title: "Simulate: nothing to restore", plan: nil,
                                            result: "No purchases were found. Nothing changed.")]
        case .redeem:
            return [SettingsStoreKitOutcome(title: "Simulate redeeming a complimentary code", plan: .complimentary,
                                            result: "Complimentary access (sample) is active. A monthly subscription, if you had one, would keep renewing until you cancel it.")]
        case .manage:
            // Only a renewing trial or subscription has anything to cancel.
            guard current == .subscribed || current == .trialActive else { return [] }
            return [SettingsStoreKitOutcome(title: "Simulate cancelling, then expiry", plan: .expired,
                                            result: "Styling access ended in this demo. Your closet, saved looks and history are untouched.")]
        }
    }

    /// Explains why there's nothing to simulate for the current plan.
    func noOutcomeExplanation(current: AccessPlan) -> String {
        switch self {
        case .startTrial:
            return "You already have styling access (\(current.label)). The App Store wouldn't offer another purchase, so there's nothing to start."
        case .manage:
            switch current {
            case .complimentary, .sponsored:
                return "\(current.label) has no recurring billing, so there's no subscription to cancel."
            case .trialEligible:
                return "There's no active subscription to manage yet."
            case .expired:
                return "Styling access has already ended. Nothing renews, so there's nothing to cancel."
            case .trialActive, .subscribed:
                return ""
            }
        case .restore, .redeem:
            return "Nothing to simulate for the current plan."
        }
    }
}

// MARK: - Styling access screen

/// Current plan, sample terms, usage and reset, exhausted/expired states with the
/// always-free core, and simulated StoreKit actions.
struct StylingAccessView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var ui = app.settingsUI
        let access = app.store.access
        let blocked = !access.plan.hasStylingAccess || access.isStylingExhausted
        GeometryReader { geo in
            let twoColumns = geo.size.width >= 820 && !dynamicTypeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    SettingsAccessStateBanner()
                    if twoColumns {
                        HStack(alignment: .top, spacing: Spacing.l) {
                            VStack(spacing: Spacing.l) {
                                SettingsAccessPlanCard()
                                SettingsAccessTermsCard()
                                SettingsAccessActionsCard()
                            }
                            VStack(spacing: Spacing.l) {
                                SettingsAccessUsageCard()
                                SettingsAccessFreeCoreCard(emphasized: blocked)
                            }
                        }
                    } else {
                        SettingsAccessPlanCard()
                        if blocked { SettingsAccessFreeCoreCard(emphasized: true) }
                        SettingsAccessUsageCard()
                        SettingsAccessTermsCard()
                        SettingsAccessActionsCard()
                        if !blocked { SettingsAccessFreeCoreCard(emphasized: false) }
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: twoColumns ? 1040 : 680)
                .frame(maxWidth: .infinity)
            }
        }
        .themedScreenBackground()
        .navigationTitle("Styling Access")
        .settingsLabAwareSheet(item: $ui.accessSheet) { action in
            SettingsStoreKitSheet(action: action)
        }
    }
}

/// Exhausted / not active / expired explanation. Free core stays available in every case.
private struct SettingsAccessStateBanner: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let reset = access.resetsAt.formatted(date: .omitted, time: .shortened)
        switch access.plan {
        case .expired:
            InlineBanner(style: .caution,
                         title: "Styling access ended",
                         message: "Style Me, AI swaps and Find One search are paused. Nothing was deleted, and everything in Always free keeps working. Subscribe again any time to pick up with the same closet.",
                         summary: "Nothing was deleted. Free features keep working.",
                         isMessageExpanded: app.settingsUI.detailsBinding("accessBanner"))
                .accessibilityIdentifier("accessExpiredBanner")
        case .trialEligible:
            InlineBanner(style: .info,
                         title: "Styling access isn't active",
                         message: "Start the free month (sample terms) to use Style Me. Your closet, saved looks and manual editing work without it.",
                         summary: "Your closet and saved looks work without it.",
                         isMessageExpanded: app.settingsUI.detailsBinding("accessBanner"))
                .accessibilityIdentifier("accessInactiveBanner")
        default:
            if access.isStylingExhausted {
                InlineBanner(style: .caution,
                             title: "Today's styling allowance is used up",
                             message: "It resets at \(reset). Your closet, saved looks, history and manual editing stay free in the meantime.",
                             summary: "It resets at \(reset).",
                             isMessageExpanded: app.settingsUI.detailsBinding("accessBanner"))
                    .accessibilityIdentifier("accessExhaustedBanner")
            }
        }
    }
}

private struct SettingsAccessPlanCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let active = access.plan.hasStylingAccess
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    heading
                    Spacer(minLength: Spacing.xs)
                    stateBadge(active)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    heading
                    stateBadge(active)
                }
            }
            Text(access.plan.label)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("accessPlanLabel")
            CollapsibleText(explanation(access.plan), font: .subheadline, topic: "your plan",
                            isExpanded: app.settingsUI.detailsBinding("accessPlan"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(highlighted: access.plan == .sponsored)
    }

    private var heading: some View {
        Text("Your styling access")
            .font(.editorial(.title3))
            .foregroundStyle(Palette.primaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private func stateBadge(_ active: Bool) -> some View {
        SettingsBadge(text: active ? "Active" : "Not active",
                      systemImage: active ? "checkmark.circle" : "pause.circle",
                      tone: active ? .success : .caution)
    }

    private func explanation(_ plan: AccessPlan) -> String {
        switch plan {
        case .sponsored: "Owner-sponsored (sample): public daily limits don't apply; technical limits still do."
        case .complimentary: "Unlocked with an offer code (sample). This unlock has no recurring billing."
        case .subscribed: "Renews monthly until you cancel in Manage subscription."
        case .trialActive: "Your free month is running. Unless you cancel, it continues at the sample monthly price; the App Store shows the real renewal date."
        case .trialEligible: "You haven't started styling access. One free month is available under the sample terms."
        case .expired: "Nothing was deleted. Your closet, looks and history are all here."
        }
    }
}

private struct SettingsAccessTermsCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let terms = access.terms
        VStack(alignment: .leading, spacing: Spacing.s) {
            SettingsBadge(text: "Sample terms — not a final price", systemImage: "flask", tone: .accent)
                .accessibilityIdentifier("sampleTermsBadge")
            Text("\(terms.trialLabel), then \(terms.monthlyPriceLabel)/month (sample). Auto-renews until cancelled.")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sampleTermsText")
            DetailsDisclosure(
                "What's included",
                count: 4,
                isExpanded: app.settingsUI.detailsBinding("accessIncluded"),
                identifier: "accessIncludedDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    Text("Monthly styling access would include")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                    SettingsBullet("Up to \(terms.dailyStylingAllowance) Style Me requests a day", systemImage: "sparkles")
                    SettingsBullet("Up to \(terms.dailySwapAllowance) AI swap suggestions a day", systemImage: "arrow.left.arrow.right")
                    SettingsBullet("\(terms.monthlyImageAllowance) On Me picture units a month, if previews ship", systemImage: "person.crop.rectangle")
                    SettingsBullet("Find One web search within the same access", systemImage: "magnifyingglass")
                }
            }
            Divider().overlay(Palette.divider)
            InfoRow(title: "Free trial", value: eligibility(access.plan))
                .accessibilityIdentifier("trialEligibility")
            CollapsibleText(
                "Real prices, renewal dates and trial eligibility come from the App Store when you buy. Nothing here is final.",
                summary: "Real prices come from the App Store.",
                threshold: 1,
                topic: "sample terms"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func eligibility(_ plan: AccessPlan) -> String {
        switch plan {
        case .trialEligible: "Eligible (sample)"
        case .trialActive: "In use now"
        case .subscribed, .expired: "Already used. You'd see the monthly price."
        case .complimentary, .sponsored: "Not needed with your access"
        }
    }
}

private struct SettingsAccessUsageCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let counted = access.plan != .sponsored
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Usage", subtitle: "Resets \(access.resetsAt.formatted(date: .abbreviated, time: .shortened))",
                          info: "Reopening saved looks, history or earlier pictures never uses these.")
            if !counted {
                Text("Sponsored use isn't counted against these public limits.")
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SettingsAccessMeter(title: "Style Me requests today", used: access.stylingUsedToday,
                                total: access.terms.dailyStylingAllowance, counted: counted)
                .accessibilityIdentifier("usageStyling")
            SettingsAccessMeter(title: "AI swaps today", used: access.swapsUsedToday,
                                total: access.terms.dailySwapAllowance, counted: counted)
            SettingsAccessMeter(title: "On Me picture units this month", used: access.imageUnitsUsedThisMonth,
                                total: access.terms.monthlyImageAllowance, counted: counted)
            if app.purchasesDemo, counted {
                InfoRow(title: "Bought pictures", value: "\(access.imageWallet) left · don't expire")
                    .accessibilityIdentifier("usageImageWallet")
                Button { app.purchaseSheet = .imagePacks } label: {
                    Label("Get more pictures", systemImage: "plus.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .accessibilityIdentifier("getMorePicturesButton")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct SettingsAccessMeter: View {
    var title: String
    var used: Int
    var total: Int
    var counted: Bool

    private var valueText: String {
        counted ? "\(used) of \(total) used" : "\(used) used · not counted"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title).foregroundStyle(Palette.primaryText)
                    Spacer(minLength: Spacing.xs)
                    Text(valueText).monospacedDigit().foregroundStyle(Palette.secondaryText)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(Palette.primaryText)
                    Text(valueText).monospacedDigit().foregroundStyle(Palette.secondaryText)
                }
            }
            .font(.subheadline)
            ProgressView(value: Double(min(used, max(total, 1))), total: Double(max(total, 1)))
                .tint(counted && used >= total ? Palette.error : Palette.primaryAction)
                .opacity(counted ? 1 : 0.5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(valueText)
    }
}

private struct SettingsAccessActionsCard: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let ui = app.settingsUI
        let plan = app.store.access.plan
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(
                "Manage access",
                subtitle: "Simulated. No purchase, no charge.",
                info: "Each opens a simulated App Store review. No purchase, no charge.\n\nDeleting your data or the app doesn't cancel billing. Use Manage subscription to stop renewals."
                    + (plan.hasStylingAccess ? "\n\nYou already have styling access, so there's nothing to buy." : "")
            )
            // The likely actions stay out; the rest sit in the menu, each opening the same review.
            if plan == .complimentary || plan == .sponsored {
                // No recurring billing on these plans, so there's no subscription to manage first.
                ActionGroup(moreTitle: "More options", moreIdentifier: "manageAccessMore") {
                    storeKitButton(.restore)
                        .buttonStyle(SecondaryButtonStyle())
                    storeKitButton(.redeem)
                        .buttonStyle(SecondaryButtonStyle())
                } more: {
                    storeKitButton(.manage)
                    storeKitButton(.startTrial)
                        .accessibilityHint("You already have styling access, so the review explains there's nothing to buy")
                }
            } else if plan.hasStylingAccess {
                ActionGroup(moreTitle: "More options", moreIdentifier: "manageAccessMore") {
                    storeKitButton(.manage)
                        .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                } more: {
                    storeKitButton(.restore)
                    storeKitButton(.redeem)
                    storeKitButton(.startTrial)
                        .accessibilityHint("You already have styling access, so the review explains there's nothing to buy")
                }
            } else {
                ActionGroup(moreTitle: "More options", moreIdentifier: "manageAccessMore") {
                    Button {
                        if app.purchasesDemo { app.purchaseSheet = .paywall(.settings) } else { ui.openStoreKit(.startTrial) }
                    } label: {
                        Label(plan == .expired ? "Subscribe again (sample)" : "Start free trial", systemImage: "gift")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier(SettingsStoreKitAction.startTrial.identifier)
                } more: {
                    storeKitButton(.restore)
                    storeKitButton(.redeem)
                    storeKitButton(.manage)
                }
            }
            CollapsibleText(
                "Deleting your data or the app doesn't cancel billing. Use Manage subscription to stop renewals.",
                summary: "Deleting data doesn't cancel billing.",
                threshold: 1,
                topic: "billing"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private extension SettingsAccessActionsCard {
    func storeKitButton(_ action: SettingsStoreKitAction) -> some View {
        Button {
            app.settingsUI.openStoreKit(action)
        } label: {
            Label(action.title, systemImage: action.systemImage)
        }
        .accessibilityIdentifier(action.identifier)
    }
}

private struct SettingsAccessFreeCoreCard: View {
    @Environment(AppModel.self) private var app
    var emphasized: Bool

    private struct Item: Identifiable {
        let icon: String
        let text: String
        var id: String { text }
    }

    private let items: [Item] = [
        Item(icon: "cabinet", text: "Closet and availability"),
        Item(icon: "bookmark", text: "Saved looks and preview history"),
        Item(icon: "magnifyingglass", text: "Search"),
        Item(icon: "square.and.pencil", text: "Manual outfit editing"),
        Item(icon: "clock.arrow.circlepath", text: "Styling history"),
        Item(icon: "square.and.arrow.up", text: "Export and import"),
        Item(icon: "bubble.left.and.bubble.right", text: "Ask another stylist"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader("Always free", subtitle: "Closet, saved looks, search and more.",
                          info: "Works without styling access, after a trial ends or when today's allowance runs out.")
            DetailsDisclosure(
                "Everything that's free",
                count: items.count,
                isExpanded: app.settingsUI.detailsBinding("accessFreeCore"),
                identifier: "freeCoreDetails"
            ) {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    ForEach(items) { item in
                        SettingsBullet(item.text, systemImage: item.icon, tint: Palette.success)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(highlighted: emphasized)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("freeCoreList")
    }
}

// MARK: - Simulated StoreKit review sheet

struct SettingsStoreKitSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    var action: SettingsStoreKitAction

    var body: some View {
        let ui = app.settingsUI
        let access = app.store.access
        let outcomes = action.outcomes(current: access.plan)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    HStack(alignment: .top, spacing: Spacing.s) {
                        Image(systemName: action.systemImage)
                            .font(.largeTitle)
                            .foregroundStyle(Palette.primaryAction)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(action.title)
                                .font(.editorial(.title2))
                                .foregroundStyle(Palette.primaryText)
                                .accessibilityAddTraits(.isHeader)
                            HStack(spacing: Spacing.xxs) {
                                SettingsBadge(text: "Simulated StoreKit — no purchase, no charge", systemImage: "flask", tone: .accent)
                                    .accessibilityIdentifier("storeKitSimulationBadge")
                                InfoButton("what's simulated here", title: "Simulated",
                                           text: "Simulated StoreKit — no purchase, no charge. The real app would show Apple's own sheet here.")
                            }
                        }
                    }

                    DetailsDisclosure(
                        "In the real app",
                        count: action.realFlow.count,
                        isExpanded: ui.detailsBinding("storeKitRealFlow"),
                        identifier: "storeKitRealFlowDetails"
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(action.realFlow, id: \.self) { line in
                                SettingsBullet(line, systemImage: "info.circle", tint: Palette.secondaryText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    if action == .startTrial {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            SettingsBadge(text: "Sample terms — not a final price", systemImage: "flask", tone: .accent)
                            Text("\(access.terms.trialLabel), then \(access.terms.monthlyPriceLabel)/month (sample). Auto-renews until cancelled.")
                                .font(.headline)
                                .foregroundStyle(Palette.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cardStyle()
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        SectionHeader("Try it in this demo", subtitle: "Nothing is bought or charged.",
                                      info: "Simulate changes only this demo's access state. Nothing is bought or charged.")
                        if outcomes.isEmpty {
                            Text(action.noOutcomeExplanation(current: access.plan))
                                .font(.subheadline)
                                .foregroundStyle(Palette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        ForEach(Array(outcomes.enumerated()), id: \.offset) { index, outcome in
                            Button {
                                if let plan = outcome.plan { app.store.settingsSimulatePlan(plan) }
                                ui.storeKitResult = outcome.result
                            } label: {
                                Label(outcome.title, systemImage: "flask")
                            }
                            .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                            .accessibilityIdentifier("storeKitSimulate-\(index)")
                        }
                        if let result = ui.storeKitResult {
                            InlineBanner(style: .info,
                                         title: "Simulated — no purchase, no charge",
                                         message: "\(result) Current plan: \(app.store.access.plan.label).")
                                .accessibilityIdentifier("storeKitResult")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
                .padding(Spacing.m)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .themedScreenBackground()
            .navigationTitle("App Store (simulated)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ui.storeKitResult == nil ? "Cancel" : "Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Styling access · sponsored") {
    NavigationStack {
        StylingAccessView()
    }
    .previewEnvironment()
}

#Preview("Styling access · exhausted") {
    let model = AppModel.preview
    model.scenario = .exhaustedAllowance
    return NavigationStack {
        StylingAccessView()
    }
    .previewEnvironment(model)
}

#Preview("Styling access · wide", traits: .fixedLayout(width: 1000, height: 900)) {
    NavigationStack {
        StylingAccessView()
    }
    .previewEnvironment()
}

#Preview("StoreKit review") {
    SettingsStoreKitSheet(action: .redeem)
        .previewEnvironment()
}
