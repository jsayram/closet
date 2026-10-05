import SwiftUI

/// Simulated retailer page. A real build opens the retailer in a Safari sheet or
/// its app; here it's a local mock destination. Opening or returning never
/// searches, and nothing here is bought, charged or owned.
struct StoreHandoffView: View {
    var candidate: ShoppingCandidate
    var context: FindOneContext?
    /// True when pushed inside Find One's navigation stack.
    var embedded: Bool = false
    /// Called by "Return to My Petite Style" when embedded. Root sheets dismiss instead.
    var onReturn: ((ShoppingCandidate) -> Void)? = nil

    var body: some View {
        if embedded {
            StoreHandoffPage(candidate: candidate, context: context, onReturn: onReturn)
        } else {
            NavigationStack {
                StoreHandoffPage(candidate: candidate, context: context, onReturn: onReturn)
            }
        }
    }
}

private struct StoreHandoffPage: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    var candidate: ShoppingCandidate
    var context: FindOneContext?
    var onReturn: ((ShoppingCandidate) -> Void)?
    @State private var selectedSize: String?
    @State private var sizesExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.m) {
                InlineBanner(style: .caution,
                             title: "Simulated store page",
                             message: "Simulated store page — fictional product, local mock destination (a real build opens the retailer in a Safari sheet or its app).",
                             summary: "Fictional product. No real page opens.")
                    .accessibilityIdentifier("handoffSimulationBanner")
                addressBar
                product
                selectors
                notes
                Button(action: returnToApp) {
                    Label("Return to My Petite Style", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityHint("Goes back to the same look and product. Nothing is searched.")
                .accessibilityIdentifier("returnToAppButton")
            }
            .padding(Spacing.m)
            .readableWidth(640)
        }
        .themedScreenBackground()
        .navigationTitle(candidate.retailer)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: returnToApp) {
                    Label("Return", systemImage: "chevron.backward")
                        .labelStyle(.titleAndIcon)
                }
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("Return to My Petite Style")
            }
        }
    }

    // MARK: Pieces

    private var addressBar: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "lock")
                .foregroundStyle(Palette.secondaryText)
                .accessibilityHidden(true)
            Text(candidate.domain)
                .font(.subheadline.monospaced())
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.xs)
            StatusBadge(kind: .simulated, compact: true)
        }
        .padding(.horizontal, Spacing.s)
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: HitTarget.minimum)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.surface))
        .overlay(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).strokeBorder(Palette.controlBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Destination: \(candidate.domain), simulated. Fictional link, no real page.")
    }

    private var product: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.m) {
                    hero
                    productText
                }
                VStack(alignment: .leading, spacing: Spacing.s) {
                    hero
                    productText
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            GarmentArtwork(kind: candidate.kind, hex: candidate.colorHex)
                .frame(width: 150, height: 150)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Representative image of \(candidate.colorName) \(candidate.kind.label.lowercased()), not a product photo")
            HStack(spacing: Spacing.xxs) {
                Text("Representative tile")
                    .font(.caption2)
                    .foregroundStyle(Palette.secondaryText)
                    .accessibilityHidden(true)
                InfoButton("the picture", title: "Representative tile",
                           text: "Representative tile — no product photos on this simulated page")
            }
        }
    }

    private var productText: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(candidate.retailer)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.secondaryText)
                .textCase(.uppercase)
            Text(candidate.title)
                .font(.editorial(.title2))
                .foregroundStyle(Palette.primaryText)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(FindOneFormat.price(candidate)) · sample price")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
            Text("The retailer shows the final price, shipping and returns.")
                .font(.caption)
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: Spacing.xxs) {
                StatusBadge(kind: .custom(candidate.stock.label, "shippingbox"), compact: false)
                StatusBadge(kind: .custom(candidate.shipping.label, "box.truck"), compact: false)
            }
            .padding(.top, Spacing.xxs)
        }
    }

    private var selectors: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("The retailer confirms final size and color")
                .font(.headline)
                .foregroundStyle(Palette.primaryText)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xxs) {
                    Text("Size")
                        .font(.subheadline.weight(.semibold))
                    Text("· preview only")
                        .font(.subheadline)
                        .foregroundStyle(Palette.secondaryText)
                    InfoButton("choosing a size here", title: "Size is a preview",
                               text: "Choosing a size here is only a preview. It isn't recorded as what you bought, and no size is filled in for you later.")
                }
                ChipCarousel(isExpanded: $sizesExpanded, itemsLabel: "sizes") {
                    ForEach(FindOneFormat.sizeOptions(for: candidate.kind), id: \.self) { size in
                        CapsuleChip(title: size, isSelected: selectedSize == size) {
                            selectedSize = selectedSize == size ? nil : size
                        }
                        .accessibilityIdentifier("handoffSize-\(size)")
                    }
                }
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Color")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: Spacing.xs) {
                    ColorSwatch(hex: candidate.colorHex, size: 22)
                    Text(candidate.colorName)
                        .font(.subheadline)
                        .foregroundStyle(Palette.primaryText)
                }
                .padding(.horizontal, Spacing.m)
                .frame(minHeight: HitTarget.minimum)
                .background(Capsule().fill(Palette.accentSurface))
                .overlay(Capsule().strokeBorder(Palette.primaryAction, lineWidth: 1.5))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Color: \(candidate.colorName), the only listed color")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            // What she needs before leaving stays on screen; the rest opens in place.
            Label {
                CollapsibleText("Checkout happens on the retailer's site. Nothing here is bought, charged or added to your closet.\n\nYour look and this product are saved — you'll come back to the same place.",
                                summary: "Nothing here is bought or charged.",
                                threshold: 1,
                                font: .subheadline,
                                color: Palette.primaryText,
                                topic: "checkout and what's saved")
            } icon: {
                Image(systemName: "cart")
                    .foregroundStyle(Palette.primaryAction)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("handoffSavedNote")
        }
        .font(.subheadline)
        .foregroundStyle(Palette.primaryText)
        .padding(Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.tile, style: .continuous).fill(Palette.successSurface.opacity(0.6)))
    }

    // MARK: Return

    private func returnToApp() {
        if let onReturn {
            onReturn(candidate)
            return
        }
        // Root sheet: dismiss, then offer a nonblocking, dismissible prompt. No search.
        let candidate = candidate
        let context = context
        let visitID = app.store.findOneLatestVisit(candidateID: candidate.id)?.id
        dismiss()
        app.showToast("Ordered or bought it? Add to closet", style: .info, actionTitle: "Add to closet") { [weak app] in
            guard let app else { return }
            if let visitID { app.store.findOneDismissVisitPrompt(visitID) }
            app.present(.purchaseReview(PurchaseReviewContext(candidate: candidate, findOne: context)))
        }
    }
}

#Preview("Store handoff") {
    let candidate = MockWebSearch.leads(for: PublicShoppingIntent(garment: "trousers", color: "Navy", budgetMax: 80, shipsTo: "United States",
                                                                    preferredRetailers: [], retailerOnly: false))[0]
    return StoreHandoffView(candidate: candidate, context: nil)
        .previewEnvironment()
}
