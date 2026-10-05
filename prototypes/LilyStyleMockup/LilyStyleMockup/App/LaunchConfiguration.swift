import SwiftUI

/// Development launch arguments for deterministic screenshots and UI tests.
///
///     -resetDemo              start from fresh fixtures
///     -skipOnboarding         mark onboarding complete
///     -fastMocks              shorten simulated delays
///     -showHUD                show the dispatch counter
///     -scenario <name>        DemoScenario raw value (e.g. partialCloset)
///     -scope <main|jose|weekend|spring>
///     -occasion <raw>         Occasion raw value
///     -customOccasion "<text>" fill in the Other occasion (selects Other, opens the occasion row)
///     -onMeDemo               enable simulated On Me reference + permission + toggle
///     -route <name[:id]>      styleMe, results, editor, swap, closet, garment:<id>, suitcases,
///                             suitcase:<id>, laundry, search, saved, outfit:<id>, preview:<id>,
///                             profile, settings, access, help, feedback, developer, findOne,
///                             askStylist, onboarding, addItem, purchase, handoff, savedProducts,
///                             chat, chatLook (look attached + question), chatIdea
///     -autoStyle              tap Style Me automatically after launch
///     -searchQuery "<text>"   prefill the search field
///     -appearance <light|dark> force a color scheme (screenshots)
///     -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL  (system flag: Dynamic Type)
struct LaunchConfiguration {
    var resetDemo = false
    var skipOnboarding = false
    var fastMocks = false
    var showHUD = false
    var scenario: DemoScenario?
    var scope: String?
    var occasion: Occasion?
    var customOccasion: String?
    var onMeDemo = false
    var route: String?
    var autoStyle = false
    var searchQuery: String?
    var appearance: ColorScheme?

    static let current: LaunchConfiguration = {
        let args = ProcessInfo.processInfo.arguments
        func value(_ flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        var c = LaunchConfiguration()
        c.resetDemo = args.contains("-resetDemo")
        c.skipOnboarding = args.contains("-skipOnboarding")
        c.fastMocks = args.contains("-fastMocks")
        c.showHUD = args.contains("-showHUD")
        c.scenario = value("-scenario").flatMap(DemoScenario.init(rawValue:))
        c.scope = value("-scope")
        c.occasion = value("-occasion").flatMap(Occasion.init(rawValue:))
        c.customOccasion = value("-customOccasion")
        c.onMeDemo = args.contains("-onMeDemo")
        c.route = value("-route")
        c.autoStyle = args.contains("-autoStyle")
        c.searchQuery = value("-searchQuery")
        switch value("-appearance") {
        case "dark": c.appearance = .dark
        case "light": c.appearance = .light
        default: c.appearance = nil
        }
        return c
    }()

    @MainActor
    func apply(to app: AppModel) async {
        app.showDispatchHUD = showHUD
        if let scenario { app.scenario = scenario }
        switch scope {
        case "main": app.selectScope(.mainCloset)
        case "jose": app.selectScope(.suitcase(DemoFixtures.jose))
        case "weekend": app.selectScope(.suitcase(DemoFixtures.weekend))
        case "spring": app.selectScope(.suitcase(DemoFixtures.empty))
        default: break
        }
        if let occasion { app.style.draft.occasion = occasion }
        if let customOccasion {
            app.style.draft.occasion = .other
            app.style.draft.customOccasion = customOccasion
            // Open the occasion row so the text field is on screen.
            app.styleMeUI.occasionExpanded = true
        }
        if onMeDemo {
            app.enableSimulatedOnMe()
            app.style.draft.onMe = true
        }
        if let searchQuery { app.searchUI.prefillQuery = searchQuery }
        app.loadWeatherIfNeeded()

        guard let route else {
            if autoStyle { await styleAndWait(app) }
            return
        }
        let parts = route.split(separator: ":", maxSplits: 1).map(String.init)
        let name = parts[0]
        let id = parts.count > 1 ? parts[1] : nil
        switch name {
        case "styleMe": app.select(.styleMe); if autoStyle { await styleAndWait(app) }
        case "results": await styleAndWait(app)
        case "editor", "swap":
            await styleAndWait(app)
            if let first = app.style.current?.result.outfits.first {
                app.openEditor(forResult: first)
                if name == "swap" { app.editor?.selectedSlot = first.sortedPieces.first(where: { $0.slot == .top })?.slot ?? first.sortedPieces.first?.slot }
            }
        case "closet": app.select(.closet)
        case "garment": app.push(.garment(id ?? "g-pink-blouse"), in: .closet)
        case "suitcases": app.push(.suitcases, in: .closet)
        case "suitcase": app.push(.suitcase(id ?? DemoFixtures.weekend), in: .closet)
        case "laundry": app.push(.laundry, in: .closet)
        case "search": app.push(.search(.everything), in: .closet)
        case "saved": app.select(.saved)
        case "outfit": app.push(.outfit(id ?? "o-interview"), in: .saved)
        case "preview": app.push(.preview(id ?? "p-interview-current"), in: .saved)
        case "savedProducts": app.push(.savedProducts, in: .saved)
        case "profile", "settings", "access", "help", "feedback", "developer":
            let section: AppSection = switch name {
            case "profile": .profile
            case "settings": .settings
            case "access": .access
            case "help": .help
            case "feedback": .feedback
            default: .developer
            }
            let compact = UIDevice.current.userInterfaceIdiom == .phone
            app.open(section, compact: compact)
        case "findOne":
            app.present(.findOne(FindOneContext(slot: .bottom, description: "trousers", kind: .trousers, colorFamily: .navy, scope: .mainCloset)))
        case "askStylist":
            if let o = app.store.outfit("o-interview") { app.present(.askStylist(.outfit(o))) }
        case "onboarding": app.present(.onboarding)
        case "chat":
            app.openStylistChat()
        case "chatLook":
            await styleAndWait(app)
            if let look = app.style.current?.result.outfits.dropFirst().first {
                app.openStylistChat(attaching: look)
                try? await Task.sleep(nanoseconds: 600_000_000)
                app.sendChat("Would white sneakers work with this?")
            }
        case "chatIdea":
            app.openStylistChat()
            try? await Task.sleep(nanoseconds: 600_000_000)
            app.sendChat("What goes with my olive trousers?")
        case "addItem": app.present(.addGarment(nil))
        case "purchase":
            let candidate = MockWebSearch.leads(for: PublicShoppingIntent(garment: "trousers", color: "Navy", budgetMax: 80, shipsTo: "United States", preferredRetailers: [], retailerOnly: false)).first
            app.present(.purchaseReview(PurchaseReviewContext(candidate: candidate)))
        case "handoff":
            if let candidate = MockWebSearch.leads(for: PublicShoppingIntent(garment: "trousers", color: "Navy", budgetMax: 80, shipsTo: "United States", preferredRetailers: [], retailerOnly: false)).first {
                app.present(.storeHandoff(candidate, nil))
            }
        default: break
        }
    }

    @MainActor
    private func styleAndWait(_ app: AppModel) async {
        app.select(.styleMe)
        // Let the simulated weather snapshot arrive first so the request uses it.
        for _ in 0..<30 where app.weather == nil || app.isLoadingWeather {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        app.styleMe()
        for _ in 0..<80 where app.style.isGenerating {
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
    }
}
