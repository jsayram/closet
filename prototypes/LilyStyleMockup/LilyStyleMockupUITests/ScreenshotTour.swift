import XCTest

/// Captures labelled screenshots of every destination as XCTest attachments.
/// Export with: xcrun xcresulttool export attachments --path <bundle> --output-path <dir>
///
/// Environment (set via TEST_RUNNER_ prefix on xcodebuild):
///   SHOT_APPEARANCE = light | dark          (default light)
///   SHOT_LARGE_TEXT = 1                     (AX XXXL Dynamic Type subset)
///   SHOT_LANDSCAPE  = 1                     (also capture landscape for key screens)
///   SHOT_ORIENTATION = landscape            (capture the selected set in landscape only)
///   SHOT_ONLY_KEY   = 1                     (capture only the key subset)
///   SHOT_ONLY       = 10-history-reuse,...  (recapture just these shots; skips the keyboard test unless listed)
final class ScreenshotTour: XCTestCase {
    struct Shot {
        var name: String
        var args: [String]
        var settle: TimeInterval = 2.5
        var action: ((XCUIApplication) -> Void)?
    }

    var appearance: String { ProcessInfo.processInfo.environment["SHOT_APPEARANCE"] ?? "light" }
    var largeText: Bool { ProcessInfo.processInfo.environment["SHOT_LARGE_TEXT"] == "1" }
    var landscape: Bool { ProcessInfo.processInfo.environment["SHOT_LANDSCAPE"] == "1" }
    var landscapeOnly: Bool { ProcessInfo.processInfo.environment["SHOT_ORIENTATION"] == "landscape" }
    var onlyKey: Bool { ProcessInfo.processInfo.environment["SHOT_ONLY_KEY"] == "1" }
    var onlyNames: Set<String>? {
        guard let raw = ProcessInfo.processInfo.environment["SHOT_ONLY"], !raw.isEmpty else { return nil }
        return Set(raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
    }

    override func setUp() {
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
    }

    func capture(_ shot: Shot, orientation: UIDeviceOrientation = .portrait) {
        let app = XCUIApplication()
        var args = ["-resetDemo", "-skipOnboarding", "-fastMocks", "-appearance", appearance] + shot.args
        if largeText { args += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchArguments = args
        XCUIDevice.shared.orientation = orientation
        app.launch()
        Thread.sleep(forTimeInterval: shot.settle)
        shot.action?(app)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        let orient = orientation == .portrait ? "portrait" : "landscape"
        attachment.name = "\(shot.name)__\(appearance)__\(orient)\(largeText ? "__AXXXXL" : "")"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }

    var shots: [Shot] {
        [
            Shot(name: "01-onboarding", args: ["-route", "onboarding"]),
            Shot(name: "02-style-me", args: ["-route", "styleMe"]),
            Shot(name: "03-results-three-looks", args: ["-route", "results"], settle: 3.5),
            Shot(name: "04-results-on-me-pending", args: ["-route", "results", "-onMeDemo", "-scenario", "slowImages"], settle: 4),
            Shot(name: "05-results-on-me-ready", args: ["-route", "results", "-onMeDemo"], settle: 9),
            Shot(name: "06-editor", args: ["-route", "editor"], settle: 4),
            Shot(name: "07-swap", args: ["-route", "swap"], settle: 4) { app in
                let tile = app.buttons.matching(identifier: "pieceTile-top").firstMatch
                if tile.waitForExistence(timeout: 3) { tile.tap() }
                Thread.sleep(forTimeInterval: 1.5)
            },
            Shot(name: "08-partial-suitcase", args: ["-route", "results", "-scope", "jose"], settle: 3.5),
            Shot(name: "09-insufficient-weekend-office", args: ["-route", "results", "-scope", "weekend"], settle: 3.5),
            Shot(name: "10-history-reuse", args: ["-route", "results", "-occasion", "dateNight"], settle: 3.5),
            Shot(name: "11-ai-offline", args: ["-route", "results", "-scenario", "offlineAI"], settle: 3.5),
            Shot(name: "12-closet", args: ["-route", "closet"]),
            Shot(name: "13-garment-detail-dirty", args: ["-route", "garment:g-lace-top"]),
            Shot(name: "14-add-item", args: ["-route", "addItem"]),
            Shot(name: "15-suitcases", args: ["-route", "suitcases"]),
            Shot(name: "16-suitcase-empty", args: ["-route", "suitcase:s-spring"]),
            Shot(name: "17-laundry", args: ["-route", "laundry"]),
            Shot(name: "18-search-possible", args: ["-route", "search", "-searchQuery", "lacy white shirt with ruffles"], settle: 3),
            Shot(name: "19-search-cute-pink", args: ["-route", "search", "-searchQuery", "cute pink shirt"], settle: 3),
            Shot(name: "20-saved", args: ["-route", "saved"]),
            Shot(name: "21-saved-outfit-badges", args: ["-route", "outfit:o-lace-date"]),
            Shot(name: "22-preview-detail", args: ["-route", "preview:p-weekend-disliked"]),
            Shot(name: "23-profile", args: ["-route", "profile"]),
            Shot(name: "24-find-one", args: ["-route", "findOne"]),
            Shot(name: "25-store-handoff", args: ["-route", "handoff"]),
            Shot(name: "26-purchase-review", args: ["-route", "purchase"]),
            Shot(name: "27-ask-stylist", args: ["-route", "askStylist"]),
            Shot(name: "28-settings", args: ["-route", "settings"]),
            Shot(name: "29-styling-access-exhausted", args: ["-route", "access", "-scenario", "exhaustedAllowance"]),
            Shot(name: "30-feedback", args: ["-route", "feedback"]),
            Shot(name: "31-demo-controls", args: ["-route", "developer"]),
            Shot(name: "32-declined-permission", args: ["-route", "styleMe", "-scenario", "declinedPermission"]),
            Shot(name: "33-help", args: ["-route", "help"]),
            Shot(name: "34-saved-products", args: ["-route", "savedProducts"]),
            Shot(name: "35-ask-stylist-chat", args: ["-route", "chat"]),
            Shot(name: "36-ask-stylist-answer", args: ["-route", "chatLook"], settle: 6),
            Shot(name: "37-ask-stylist-idea", args: ["-route", "chatIdea"], settle: 4),
        ]
    }

    /// Representative subset for large Dynamic Type and landscape passes.
    var keyShotNames: Set<String> {
        ["02-style-me", "03-results-three-looks", "06-editor", "07-swap", "12-closet", "13-garment-detail-dirty",
         "17-laundry", "18-search-possible", "20-saved", "23-profile", "24-find-one", "28-settings", "36-ask-stylist-answer"]
    }

    func testCaptureTour() {
        var list = (largeText || onlyKey) ? shots.filter { keyShotNames.contains($0.name) } : shots
        if let onlyNames { list = list.filter { onlyNames.contains($0.name) } }
        for shot in list { capture(shot, orientation: landscapeOnly ? .landscapeLeft : .portrait) }
        if landscape {
            for shot in shots where keyShotNames.contains(shot.name) && (onlyNames?.contains(shot.name) ?? true) {
                capture(shot, orientation: .landscapeLeft)
            }
        }
    }

    /// In-app constrained-frame layout lab (narrow/intermediate widths). This is an
    /// in-app simulation of window widths, not system multitasking.
    func testCaptureLayoutLab() {
        for width in [320, 507, 678] {
            capture(Shot(name: "50-layout-lab-\(width)pt", args: ["-route", "developer"]) { app in
                let chip = app.descendants(matching: .any)["layoutLabWidth-\(width)"].firstMatch
                for _ in 0..<6 where !chip.exists || !chip.isHittable { app.swipeUp() }
                if chip.waitForExistence(timeout: 3) { chip.tap() }
                Thread.sleep(forTimeInterval: 2.5)
            })
        }
    }

    /// Keyboard state: Style Me "Other" occasion text field focused. The text is filled in at
    /// launch because typeText sends hardware key events, which make the simulator hide the
    /// on-screen keyboard.
    func testCaptureKeyboard() {
        if let onlyNames, !onlyNames.contains("40-keyboard-other-occasion") { return }
        capture(Shot(name: "40-keyboard-other-occasion", args: ["-route", "styleMe", "-customOccasion", "Gallery opening"]) { app in
            let field = app.textFields["customOccasionField"]
            if field.waitForExistence(timeout: 3) { field.tap() }
            Thread.sleep(forTimeInterval: 1.5)
        })
    }
}
