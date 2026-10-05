import SwiftUI
import Observation

/// Find One UI state owned by AppModel (`app.findOneUI`). Sessions are stored per
/// context so leaving/returning, rotating or resizing never re-runs a search.
@Observable
final class FindOneUIState {
    /// Lookup tables only; each session/draft is itself observable.
    @ObservationIgnored private var sessions: [String: FindOneSession] = [:]
    @ObservationIgnored private var sessionByContent: [String: String] = [:]
    @ObservationIgnored private var purchaseDrafts: [UUID: FindOnePurchaseDraft] = [:]
    @ObservationIgnored private var resolvedPurchaseContexts: [UUID: PurchaseReviewContext] = [:]

    /// Saved products › Purchases to finish filter.
    var finishFilter: FindOneFinishFilter = .reminders

    init() {}

    /// The session for this Find One context. Reopening Find One for the same piece
    /// (same outfit, slot, garment and source) restores the earlier session too.
    func session(for context: FindOneContext, profile: UserProfile) -> FindOneSession {
        if let existing = sessions[context.id] { return existing }
        let key = Self.contentKey(context)
        if let id = sessionByContent[key], let existing = sessions[id] {
            sessions[context.id] = existing
            return existing
        }
        let created = FindOneSession(context: context, profile: profile)
        sessions[context.id] = created
        sessionByContent[key] = context.id
        return created
    }

    /// Every entry point (Find One, a store visit, the return toast, Saved products) resolves
    /// to the record she already confirmed for this product, so a second confirmation
    /// updates it instead of creating a duplicate. Resolved once per review.
    func resolvedPurchaseContext(_ context: PurchaseReviewContext, store: DemoStore) -> PurchaseReviewContext {
        if let resolved = resolvedPurchaseContexts[context.id] { return resolved }
        var resolved = context
        if resolved.existingGarmentID == nil, let candidate = context.candidate {
            resolved.existingGarmentID = store.findOnePurchasedGarment(for: candidate)?.id
        }
        resolvedPurchaseContexts[context.id] = resolved
        return resolved
    }

    func purchaseDraft(for context: PurchaseReviewContext, store: DemoStore) -> FindOnePurchaseDraft {
        if let draft = purchaseDrafts[context.id] { return draft }
        let draft: FindOnePurchaseDraft
        if let id = context.existingGarmentID, let garment = store.garment(id) {
            // Her own earlier confirmed size may be reused; a listing's recommendation never is.
            let confirmedSize = garment.ownership == .purchasedConfirmed ? (garment.sizeLabel ?? "") : ""
            draft = FindOnePurchaseDraft(name: garment.displayName, size: confirmedSize, colorName: garment.color?.name ?? "", colorHex: garment.color?.hex)
        } else if let candidate = context.candidate {
            draft = FindOnePurchaseDraft(name: candidate.title, colorName: candidate.colorName, colorHex: candidate.colorHex)
        } else if let findOne = context.findOne {
            let name = findOne.description.prefix(1).uppercased() + findOne.description.dropFirst()
            draft = FindOnePurchaseDraft(name: name, colorName: findOne.colorFamily?.label ?? "", colorHex: findOne.colorFamily?.swatchHex)
        } else {
            draft = FindOnePurchaseDraft(name: "", colorName: "", colorHex: nil)
        }
        purchaseDrafts[context.id] = draft
        return draft
    }

    func discardPurchaseDraft(_ id: UUID) {
        purchaseDrafts[id] = nil
        resolvedPurchaseContexts[id] = nil
    }

    static func contentKey(_ c: FindOneContext) -> String {
        let scope: String = switch c.scope {
        case .mainCloset: "main"
        case let .suitcase(id): "suitcase:\(id)"
        }
        return [c.outfitID ?? "-", c.slot.rawValue, c.kind.rawValue, c.description.lowercased(), c.colorFamily?.rawValue ?? "-", scope]
            .joined(separator: "|")
    }
}

// MARK: - Find One (root sheet)

/// Optional, explicit missing-piece search. Closet first; public intent reviewed
/// before an explicit Search; fit-first results; nothing owned from a click.
struct FindOneView: View {
    var context: FindOneContext
    @Environment(AppModel.self) private var app

    var body: some View {
        FindOneScreen(session: app.findOneUI.session(for: context, profile: app.store.profile))
    }
}

private struct FindOneScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var session: FindOneSession
    @State private var citation: EvidenceItem?

    var body: some View {
        NavigationStack(path: $session.path) {
            GeometryReader { geo in
                let widthClass = WidthClass(width: geo.size.width)
                // Two panes only when the results pane can hold a full lead card;
                // accessibility text sizes always get one readable column.
                if widthClass == .compact || geo.size.width < 700 || dynamicTypeSize.isAccessibilitySize {
                    compactLayout
                } else {
                    splitLayout(width: geo.size.width, wide: widthClass == .wide)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Nonblocking, dismissible and always in view after returning from the store page.
                if let prompt = session.returnPrompt {
                    FindOneReturnPromptCard(session: session, prompt: prompt)
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.xs)
                        .readableWidth(640)
                        .background(Palette.background.opacity(0.95).ignoresSafeArea(edges: .bottom))
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
            }
            .themedScreenBackground()
            .navigationTitle("Find One")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityHint("Closes Find One. Your search and results are kept.")
                        .accessibilityIdentifier("findOneDone")
                }
            }
            .navigationDestination(for: FindOneRoute.self) { route in
                destination(route)
            }
            .onChange(of: session.record?.completedAt) { _, newValue in
                guard newValue != nil, let record = session.record else { return }
                AccessibilityNotification.Announcement(announcement(for: record)).post()
            }
        }
        .alert("Simulated source — fictional link, no real page",
               isPresented: Binding(get: { citation != nil }, set: { if !$0 { citation = nil } }),
               presenting: citation) { _ in
            Button("OK", role: .cancel) {}
        } message: { item in
            Text("\(item.sourceType.label) · \(item.sourceLabel)\n“\(item.claim)”\nRetrieved \(FindOneFormat.relative(item.retrievedAt)). A real build would open the cited page.")
        }
    }

    // MARK: Layouts

    private var compactLayout: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    leadingSections
                    results(multiColumn: false)
                        .id("findOneResults")
                    FindOneManualFallback(session: session)
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: session.record?.completedAt) { _, newValue in
                guard newValue != nil else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                    proxy.scrollTo("findOneResults", anchor: .top)
                }
            }
        }
    }

    private func splitLayout(width: CGFloat, wide: Bool) -> some View {
        let leading = min(max(width * (wide ? 0.36 : 0.42), 300), 440)
        return HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    leadingSections
                    FindOneManualFallback(session: session)
                }
                .padding(Spacing.m)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(width: leading)
            Rectangle()
                .fill(Palette.divider)
                .frame(width: 1)
                .accessibilityHidden(true)
            ScrollView {
                results(multiColumn: true)
                    .padding(Spacing.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var leadingSections: some View {
        FindOneHeaderCard(context: session.context)
        FindOneClosetFirstSection(session: session)
        FindOneIntentSection(session: session)
        CardSection("Search", info: "Runs only when you tap Search — never on opening, scrolling or editing.", step: 3) {
            FindOnePermissionSection()
            FindOneSearchControls(session: session)
        }
    }

    private func results(multiColumn: Bool) -> some View {
        FindOneResultsSection(
            session: session,
            multiColumn: multiColumn,
            onCitation: { citation = $0 },
            onViewAtStore: viewAtStore,
            onBought: { candidate in
                // One push per tap: a quick double tap never stacks duplicate screens.
                guard session.path.isEmpty else { return }
                let existing = app.store.findOnePurchasedGarment(for: candidate)?.id
                session.path.append(.purchase(PurchaseReviewContext(candidate: candidate, findOne: session.context, existingGarmentID: existing)))
            }
        )
    }

    private func announcement(for record: FindOneSearchRecord) -> String {
        guard !record.leads.isEmpty else { return "Search finished. \(record.outcome.explanation)" }
        guard record.isRanked else { return "Search finished: \(record.leads.count) leads, unranked. Each needs fit confirmation." }
        let supported = record.leads.filter { $0.fitState == .supportedGuidance }.count
        return "Search finished: \(supported) with supported sizing guidance, \(record.leads.count - supported) others."
    }

    // MARK: Actions

    /// Saves the visit (with outfit/product context) before the handoff. No search.
    private func viewAtStore(_ candidate: ShoppingCandidate) {
        // Ignore a second tap while the store page is already open (no duplicate visit or push).
        guard session.path.isEmpty else { return }
        let visit = app.store.recordVisit(candidate, context: session.context)
        session.returnPrompt = nil
        session.path.append(.handoff(candidate, visitID: visit.id))
    }

    @ViewBuilder
    private func destination(_ route: FindOneRoute) -> some View {
        switch route {
        case let .handoff(candidate, visitID):
            StoreHandoffView(candidate: candidate, context: session.context, embedded: true) { returned in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    session.returnPrompt = FindOneReturnPrompt(candidate: returned, visitID: visitID)
                }
                session.path.removeAll()
                AccessibilityNotification.Announcement("Back in Find One. Ordered or bought it? Add to closet is at the bottom of the screen.").post()
            }
        case let .purchase(context):
            PurchaseReviewView(context: context, embedded: true) {
                if !session.path.isEmpty { session.path.removeLast() }
            }
        }
    }
}

// MARK: - Previews

#Preview("Find One · trousers") {
    FindOneView(context: FindOneContext(slot: .bottom, description: "trousers", kind: .trousers, colorFamily: .navy, scope: .mainCloset))
        .previewEnvironment()
}

#Preview("Find One · suitcase top") {
    FindOneView(context: FindOneContext(slot: .top, description: "blouse", kind: .blouse, colorFamily: .pink, scope: .suitcase(DemoFixtures.jose)))
        .previewEnvironment()
}
