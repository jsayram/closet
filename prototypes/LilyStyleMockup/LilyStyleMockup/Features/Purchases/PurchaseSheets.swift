import SwiftUI

// Simulated purchase screens (PRD §14, FR-23, FR-36). Prices, allowances and pack sizes
// are sample terms. Nothing here talks to the App Store and nothing is charged.
//
// What each screen keeps on show before any confirm button, as App Review expects:
// the price and billing period, the trial length and what happens when it ends, what
// the purchase includes and its limits, how to cancel, and Restore, Terms and Privacy.

/// Presents the purchase screen above the root or above an open root sheet.
struct PurchaseSheetPresenter: ViewModifier {
    @Environment(AppModel.self) private var app
    /// Only the topmost host presents, so two sheets never compete.
    var active: Bool

    func body(content: Content) -> some View {
        content.sheet(item: Binding(
            get: { active ? app.purchaseSheet : nil },
            set: { if active { app.purchaseSheet = $0 } }
        )) { sheet in
            Group {
                switch sheet {
                case let .paywall(trigger): PaywallView(trigger: trigger).pageSheetOnPad()
                case .imagePacks: ImagePacksView().pageSheetOnPad()
                case .outOfPictures: OutOfPicturesView()
                }
            }
            .environment(app)
            .tint(Palette.primaryAction)
        }
    }
}

// MARK: - Paywall

struct PaywallView: View {
    @Environment(AppModel.self) private var app
    var trigger: PurchaseSheet.Trigger
    @State private var confirming = false
    @State private var note: String?
    @State private var showTerms = false

    private var access: AccessState { app.store.access }
    /// A lapsed subscriber has used the free month, so the first charge is today.
    private var trialAvailable: Bool { access.plan != .expired }
    private var billingDate: Date { Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now }
    private var reminderDate: Date { Calendar.current.date(byAdding: .day, value: -2, to: billingDate) ?? billingDate }
    private var price: String { access.terms.monthlyPriceLabel }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header
                    // Side by side when the sheet is wide enough (iPad), stacked on iPhone.
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: Spacing.m) {
                            included.frame(minWidth: 300)
                            timeline.frame(minWidth: 300)
                        }
                        VStack(alignment: .leading, spacing: Spacing.l) {
                            included
                            timeline
                        }
                    }
                    DetailsDisclosure("Always free", summary: "Closet, saved looks, search", systemImage: "gift",
                                      identifier: "paywallFreeCore") {
                        Text("Your closet, laundry, suitcases, saved looks, picture history, search, manual outfit editing, and export and import work without a subscription, and keep working if one ends.")
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    DetailsDisclosure("Billing details", summary: "Renews monthly · cancel anytime", systemImage: "doc.text",
                                      isExpanded: $showTerms, identifier: "paywallBillingDetails") {
                        Text(billingDetails)
                            .font(.footnote)
                            .foregroundStyle(Palette.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) { footer }
            .themedScreenBackground()
            .navigationTitle("Styling access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { app.purchaseSheet = nil }
                        .accessibilityIdentifier("paywallClose")
                }
            }
            .alert("Simulated App Store confirmation", isPresented: $confirming) {
                Button(trialAvailable ? "Start free month (simulated)" : "Subscribe (simulated)") { app.purchasesStartTrial() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(trialAvailable
                     ? "The real App Store sheet would show \(access.terms.trialLabel), then \(price) a month from \(billingDate.formatted(date: .abbreviated, time: .omitted)). Nothing is charged in this prototype."
                     : "The real App Store sheet would show \(price) a month, charged today. Nothing is charged in this prototype.")
            }
        }
        .accessibilityIdentifier("paywallView")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            PurchaseSampleBadge()
            Text(headline)
                .font(.editorial(.title))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(trialAvailable ? "Free for a month. You won't be charged today." : "Pick up where you left off. Nothing was deleted.")
                .font(.subheadline)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headline: String {
        switch trigger {
        case .styleMe: "Style Me needs styling access"
        case .picture: "On Me pictures need styling access"
        case .findOne: "Find One needs styling access"
        case .settings: "A stylist for the clothes you own"
        }
    }

    private var included: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("What you get")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            PurchaseFeatureRow(icon: "sparkles", title: "Style Me",
                               detail: "Up to \(access.terms.dailyStylingAllowance) requests a day")
            PurchaseFeatureRow(icon: "figure.stand", title: "On Me pictures",
                               detail: "\(access.terms.monthlyImageAllowance) new pictures a month")
            PurchaseFeatureRow(icon: "arrow.triangle.swap", title: "AI swaps and Ask stylist",
                               detail: "Up to \(access.terms.dailySwapAllowance) swaps a day")
            PurchaseFeatureRow(icon: "bag", title: "Find One",
                               detail: "Shopping ideas ranked by how they'll fit you")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder private var timeline: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(trialAvailable ? "How the free month works" : "How billing works")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            if trialAvailable {
                PurchaseTimelineRow(icon: "lock.open", when: "Today", what: "Styling access starts. Nothing is charged.", isLast: false)
                PurchaseTimelineRow(icon: "bell", when: reminderDate.formatted(date: .abbreviated, time: .omitted),
                                    what: "We remind you the free month is ending.", isLast: false)
                PurchaseTimelineRow(icon: "creditcard", when: billingDate.formatted(date: .abbreviated, time: .omitted),
                                    what: "\(price) a month begins, unless you cancel before.", isLast: true)
            } else {
                PurchaseTimelineRow(icon: "creditcard", when: "Today", what: "\(price) is charged and styling access starts again.", isLast: false)
                PurchaseTimelineRow(icon: "arrow.clockwise", when: "Every month",
                                    what: "Renews at \(price) until you cancel.", isLast: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityIdentifier("paywallTimeline")
    }

    private var billingDetails: String {
        let trial = trialAvailable
            ? "The free month is for new subscribers and can be used once. It turns into a paid subscription at \(price) a month unless you cancel at least 24 hours before it ends. "
            : ""
        return trial
            + "The subscription renews every month at \(price) until you cancel. Cancel any time in Settings › Styling Access › Manage subscription, or in your App Store account. Payment goes through your Apple Account.\n\n"
            + "Daily and monthly limits apply and are shown above; styling is never unlimited. When this month's pictures run out you can wait for the next month or buy a picture pack. There are no automatic extra charges.\n\n"
            + "Deleting the app or your data doesn't cancel the subscription."
    }

    private var footer: some View {
        VStack(spacing: Spacing.xs) {
            Button {
                confirming = true
            } label: {
                Text(trialAvailable ? "Start free month" : "Subscribe for \(price) a month")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("paywallStartButton")
            // Price, period and what happens after the trial sit right under the button.
            Text(trialAvailable
                 ? "\(access.terms.trialLabel), then \(price) a month. Cancel anytime."
                 : "\(price) a month, charged today. Cancel anytime.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("paywallPriceLine")
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: Spacing.m) {
                PurchaseLink("Restore") { note = "Simulated: no earlier purchase to restore." }
                PurchaseLink("Redeem code") { note = "Simulated: the App Store's code sheet would open here." }
                PurchaseLink("Terms") { note = "Placeholder: the Terms of Use open from Settings › Legal." }
                PurchaseLink("Privacy") { note = "Placeholder: the Privacy Policy opens from Settings › Legal." }
            }
        }
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.s)
        .padding(.bottom, Spacing.xs)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .background(Palette.background)
        .overlay(alignment: .top) { Rectangle().fill(Palette.divider).frame(height: 1) }
    }
}

// MARK: - Picture packs

struct ImagePacksView: View {
    @Environment(AppModel.self) private var app
    @State private var selected = SampleImagePack.samples[1]
    @State private var confirming = false
    @State private var note: String?

    var body: some View {
        let access = app.store.access
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    PurchaseSampleBadge()
                    Text("More On Me pictures")
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    balance(access)
                    VStack(spacing: Spacing.xs) {
                        ForEach(SampleImagePack.samples) { pack in
                            packRow(pack)
                        }
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        PurchaseFact(icon: "infinity", text: "Bought pictures don't expire.")
                        PurchaseFact(icon: "arrow.down.to.line", text: "Your monthly pictures are used first.")
                        PurchaseFact(icon: "clock.arrow.circlepath", text: "Reopening an earlier picture is always free.")
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Spacing.xs) {
                    Button { confirming = true } label: {
                        Text("Buy \(selected.pictures) pictures · \(selected.priceLabel)")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("imagePackBuyButton")
                    Text("One-time purchase, not a subscription. No automatic top-ups.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(Palette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    HStack(spacing: Spacing.m) {
                        PurchaseLink("Terms") { note = "Placeholder: the Terms of Use open from Settings › Legal." }
                        PurchaseLink("Privacy") { note = "Placeholder: the Privacy Policy opens from Settings › Legal." }
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xs)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .background(Palette.background)
                .overlay(alignment: .top) { Rectangle().fill(Palette.divider).frame(height: 1) }
            }
            .themedScreenBackground()
            .navigationTitle("Picture packs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { app.purchaseSheet = nil }
                        .accessibilityIdentifier("imagePacksClose")
                }
            }
            .alert("Simulated App Store confirmation", isPresented: $confirming) {
                Button("Buy (simulated)") { app.purchasesBuy(selected) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The real App Store sheet would show \(selected.pictures) On Me pictures for \(selected.priceLabel), charged once. Nothing is charged in this prototype.")
            }
        }
        .accessibilityIdentifier("imagePacksView")
    }

    private func balance(_ access: AccessState) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if access.plan.hasStylingAccess {
                InfoRow(title: "Included this month", value: "\(access.imageUnitsRemaining) of \(access.terms.monthlyImageAllowance) left")
            }
            InfoRow(title: "Bought", value: "\(access.imageWallet) left")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityIdentifier("imagePacksBalance")
    }

    private func packRow(_ pack: SampleImagePack) -> some View {
        let isSelected = pack == selected
        return Button {
            Haptics.selection()
            selected = pack
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Palette.primaryAction : Palette.controlBorder)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pack.pictures) pictures")
                        .font(.headline)
                        .foregroundStyle(Palette.primaryText)
                    Text(pack.tag.map { "\(pack.perPictureLabel) · \($0)" } ?? pack.perPictureLabel)
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                }
                Spacer(minLength: Spacing.xs)
                Text(pack.priceLabel)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Palette.primaryText)
            }
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, minHeight: HitTarget.minimum, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(isSelected ? Palette.accentSurface : Palette.surface))
            .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous)
                .strokeBorder(isSelected ? Palette.primaryAction : Palette.controlBorder, lineWidth: isSelected ? 1.5 : 1))
            .contentShape(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pack.pictures) pictures, \(pack.priceLabel), \(pack.perPictureLabel)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("imagePack-\(pack.pictures)")
    }
}

// MARK: - Out of pictures

struct OutOfPicturesView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        let access = app.store.access
        let reset = access.imageResetsAt.formatted(date: .abbreviated, time: .omitted)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    PurchaseSampleBadge()
                    Text("This month's pictures are used up")
                        .font(.editorial(.title2))
                        .foregroundStyle(Palette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(access.imageUnitsUsedThisMonth) of \(access.terms.monthlyImageAllowance) used. \(access.terms.monthlyImageAllowance) more arrive on \(reset). Nothing was charged.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        app.purchaseSheet = .imagePacks
                    } label: {
                        Label("See picture packs", systemImage: "plus.circle")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("outOfPicturesBuy")
                    Text("From \(SampleImagePack.samples[0].priceLabel) for \(SampleImagePack.samples[0].pictures). One-time, no subscription change.")
                        .font(.footnote)
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        app.purchaseSheet = nil
                    } label: {
                        Label("Keep the board for now", systemImage: "square.grid.2x2")
                    }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: true))
                    .accessibilityIdentifier("outOfPicturesKeepBoard")
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        PurchaseFact(icon: "square.grid.2x2", text: "Looks still show as a board of your pieces.")
                        PurchaseFact(icon: "clock.arrow.circlepath", text: "Earlier pictures stay free to reopen.")
                        PurchaseFact(icon: "sparkles", text: "Style Me keeps working without pictures.")
                    }
                }
                .padding(Spacing.m)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .themedScreenBackground()
            .navigationTitle("On Me pictures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { app.purchaseSheet = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("outOfPicturesView")
    }
}

// MARK: - Pieces

private struct PurchaseSampleBadge: View {
    var body: some View {
        SimulationNotice(text: "Sample terms. Prices, limits and pack sizes aren't final, and nothing is bought or charged in this prototype.",
                         label: "Simulated · sample terms")
    }
}

private struct PurchaseFeatureRow: View {
    var icon: String
    var title: String
    var detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Palette.primaryAction)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PurchaseTimelineRow: View {
    var icon: String
    var when: String
    var what: String
    var isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Palette.primaryAction)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Palette.accentSurface))
                if !isLast {
                    Rectangle()
                        .fill(Palette.divider)
                        .frame(width: 2)
                        .frame(minHeight: 14, maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(when)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.primaryText)
                Text(what)
                    .font(.footnote)
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : Spacing.xs)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PurchaseFact: View {
    var icon: String
    var text: String

    var body: some View {
        Label {
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(Palette.primaryAction)
        }
    }
}

private struct PurchaseLink: View {
    var title: String
    var action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .font(.footnote)
            .foregroundStyle(Palette.primaryAction)
            .frame(minHeight: HitTarget.minimum)
    }
}
