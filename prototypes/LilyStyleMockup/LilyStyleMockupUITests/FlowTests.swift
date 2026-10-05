import XCTest

/// End-to-end prototype flows against fictional data and mock services.
/// Every test asserts on the dispatch counter (HUD) where passive interactions
/// must not call simulated services.
final class FlowTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: Helpers

    func launch(_ extra: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-resetDemo", "-skipOnboarding", "-fastMocks", "-showHUD"] + extra
        app.launch()
    }

    /// Parses "Simulated service calls: N. Reused locally: M." from the HUD.
    func dispatchCounts() -> (calls: Int, reused: Int) {
        let hud = app.buttons["dispatchHUD"].firstMatch
        XCTAssertTrue(hud.waitForExistence(timeout: 5), "Dispatch HUD missing")
        let label = hud.label
        let numbers = label.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init)
        return (numbers.first ?? -1, numbers.count > 1 ? numbers[1] : -1)
    }

    func waitForStableCounts(_ seconds: TimeInterval = 1.5) -> (calls: Int, reused: Int) {
        Thread.sleep(forTimeInterval: seconds)
        return dispatchCounts()
    }

    func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    func tapStyleMe() {
        let button = element("styleMeButton")
        if !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    func waitForResults() {
        XCTAssertTrue(element("resultCard-0").waitForExistence(timeout: 15), "No result cards appeared")
    }

    // MARK: Tests

    /// Style Me → three looks → one-piece swap → save, with exactly one stylist dispatch.
    func testCoreStyleSwapSaveJourney() {
        launch()
        let before = waitForStableCounts()
        // The occasion row is collapsed by default; open it to reach the chips.
        if element("occasionToggle").waitForExistence(timeout: 5) { element("occasionToggle").tap() }
        if element("occasion-office").waitForExistence(timeout: 5) { element("occasion-office").tap() }
        tapStyleMe()
        waitForResults()
        XCTAssertTrue(element("resultCard-1").exists, "Expected a second direction")
        XCTAssertTrue(element("resultCard-2").exists, "Expected a third direction")
        let afterStyle = waitForStableCounts()
        XCTAssertEqual(afterStyle.calls, before.calls + 1, "Style Me should dispatch exactly one stylist call")

        // Open the first look's top and swap it.
        let topTile = app.buttons.matching(identifier: "pieceTile-top").firstMatch
        XCTAssertTrue(topTile.waitForExistence(timeout: 5))
        topTile.tap()
        let useButton = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'swapUse-'")).firstMatch
        XCTAssertTrue(useButton.waitForExistence(timeout: 8), "No eligible swap option")
        useButton.tap()
        // Swapping and browsing options must not dispatch.
        XCTAssertEqual(waitForStableCounts().calls, afterStyle.calls, "Swap must not call services")

        // Dismiss a compact sheet if present, then save.
        if app.buttons["Done"].exists { app.buttons["Done"].firstMatch.tap() }
        let save = element("saveLookButton")
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        save.tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Saved'")).firstMatch.waitForExistence(timeout: 5))
    }

    /// Rotation, tab switching and scrolling preserve results and dispatch nothing.
    func testRotationAndNavigationDoNotDispatch() {
        launch()
        tapStyleMe()
        waitForResults()
        let baseline = waitForStableCounts()
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1)
        app.swipeUp()
        app.swipeDown()
        if app.tabBars.buttons["Closet"].exists {
            app.tabBars.buttons["Closet"].tap()
            app.tabBars.buttons["Style Me"].tap()
        } else if app.buttons["Closet"].exists {
            app.buttons["Closet"].firstMatch.tap()
            app.buttons["Style Me"].firstMatch.tap()
        }
        XCTAssertTrue(element("resultCard-0").waitForExistence(timeout: 5), "Results were lost after rotation/navigation")
        let after = waitForStableCounts()
        XCTAssertEqual(after.calls, baseline.calls, "Layout changes and navigation must not dispatch services")
    }

    /// A matching six-month-old Date Night look is offered from local history with zero stylist dispatch.
    func testHistoryReuseAvoidsDispatch() {
        launch(["-occasion", "dateNight"])
        let before = waitForStableCounts()
        tapStyleMe()
        XCTAssertTrue(element("historyUseLookButton").waitForExistence(timeout: 8), "History offer not shown")
        element("historyUseLookButton").tap()
        let after = waitForStableCounts()
        XCTAssertEqual(after.calls, before.calls, "History reuse must not dispatch the stylist")
        XCTAssertGreaterThan(after.reused, before.reused)
    }

    /// Jose's house can only make one complete look: an honest partial result, no invented cards.
    func testPartialSuitcaseResult() {
        launch(["-scope", "jose"])
        tapStyleMe()
        let partialLabel = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'Partial result'")).firstMatch
        XCTAssertTrue(partialLabel.waitForExistence(timeout: 10), "Partial result label missing")
        // The single card sits below the evidence; scroll to it (lazy content).
        for _ in 0..<4 where !element("resultCard-0").exists { app.swipeUp() }
        XCTAssertTrue(element("resultCard-0").waitForExistence(timeout: 3), "The one valid look is missing")
        app.swipeUp()
        XCTAssertFalse(element("resultCard-1").exists, "Must not invent a second look")
    }

    /// Individual Mark clean changes only that item and offers Undo; no service calls.
    func testLaundryMarkCleanWithUndo() {
        launch(["-route", "laundry"])
        let before = waitForStableCounts()
        let markClean = element("laundryMarkClean-g-lace-top")
        XCTAssertTrue(markClean.waitForExistence(timeout: 8))
        markClean.tap()
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 5))
        XCTAssertEqual(waitForStableCounts().calls, before.calls)
    }

    /// Ask Stylist (FR-14): opening the chat dispatches nothing; one question is one stylist call
    /// and returns a closet-only look that can be opened in the editor.
    func testStylistChatOneDispatchPerQuestion() {
        launch()
        let open = element("openStylistChatButton")
        for _ in 0..<3 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        let before = waitForStableCounts()
        open.tap()
        let suggestion = element("stylistChatSuggestion-0")
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "Suggested questions missing")
        XCTAssertEqual(waitForStableCounts(0.8).calls, before.calls, "Opening the chat must not dispatch")
        suggestion.tap()
        XCTAssertTrue(element("stylistChatOpenEditor").waitForExistence(timeout: 10), "No look in the answer")
        XCTAssertEqual(waitForStableCounts().calls, before.calls + 1, "One question should be one stylist call")
    }

    /// Personal-vocabulary search finds labelled possible matches locally.
    func testSearchPossibleMatches() {
        launch(["-route", "search", "-searchQuery", "lacy white shirt with ruffles"])
        let before = waitForStableCounts()
        let found = element("possibleMatchesSection").waitForExistence(timeout: 8)
            || app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'searchResult-'")).firstMatch.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "No search results for the personal phrase")
        XCTAssertEqual(waitForStableCounts().calls, before.calls, "Search must be local")
    }
}
