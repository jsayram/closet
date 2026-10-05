# Verification evidence

This records what was actually checked, how, and what wasn't. It keeps three kinds of evidence apart, as the mockup prompt asks: **native simulator checks** (the real SwiftUI app running on iOS simulators), **source-only review** (reading code, no rendering), and **Not run**.

Environment: macOS with Xcode 26.6, iOS simulator runtimes 26.5 and 27.0, XcodeGen 2.45.4. Everything ran locally against fictional fixtures and mock services. No network service, account, purchase, iCloud container or real photo was used.

## Native simulator checks

### Build

- `xcodebuild` Debug build for the iOS Simulator: **BUILD SUCCEEDED**, no errors and no warnings in app source, after every integration step.

### UI tests (XCUITest, `LilyStyleMockupUITests/FlowTests.swift`)

Each test launches with `-resetDemo -skipOnboarding -fastMocks -showHUD` and reads the dispatch counter (the development HUD) to prove which interactions call simulated services.

| Test | What it proves | iPhone 12 Pro Max · iOS 27.0 | iPad Pro 11-inch (M5) · iOS 27.0 |
| --- | --- | --- | --- |
| `testCoreStyleSwapSaveJourney` | Style Me returns three directions with exactly one stylist call; tapping a piece opens real swap options; a one-piece swap makes no call; Save shows "Saved". | Passed | Passed |
| `testRotationAndNavigationDoNotDispatch` | Rotating to landscape and back, scrolling and switching tabs keep the results on screen and make no service calls. | Passed | Passed |
| `testHistoryReuseAvoidsDispatch` | The six-month-old Date Night look is offered from local history, and using it makes zero calls and counts one "reused locally". | Passed | Passed |
| `testPartialSuitcaseResult` | Jose's house shows "Partial result" with one look and no invented second card. | Passed | Passed |
| `testLaundryMarkCleanWithUndo` | Individual Mark clean offers Undo and makes no service call. | Passed | Passed |
| `testSearchPossibleMatches` | "lacy white shirt with ruffles" finds labeled possible matches locally with no service call. | Passed | Passed |
| `testStylistChatOneDispatchPerQuestion` | Opening Ask Stylist makes no call; one suggested question is exactly one stylist call and returns a look that can open in the editor. | Passed | Passed |

The iPad Pro 11-inch run used the sidebar (NavigationSplitView) layout. All seven tests were run on both devices twice: once after the haptics fix, and again after the review fixes were merged. Both times they all passed.

In the last iPhone run, `testRotationAndNavigationDoNotDispatch` took 621 seconds instead of about 30. After the device turned back to portrait, XCTest's wait for the app to go idle timed out after 60 seconds before every step. The assertions still passed. This happened while the iPad tests ran on a second simulator at the same time. It didn't happen again in six diagnostic runs that rotated the app from different screens, or in three back-to-back runs of the same test, which all finished in about 28 seconds, so it reads as an intermittent simulator stall rather than an app animation that never ends. If it comes back, run the iPhone and iPad suites one after the other instead of in parallel.

### Screenshots

The screenshot tour (`LilyStyleMockupUITests/ScreenshotTour.swift`) opens each destination and state with launch arguments and saves a native capture. `Tools/capture_screenshots.sh` runs it on one simulator and exports the PNGs to `Screenshots/<set>/`, and `Tools/make_contact_sheet.swift` builds an overview sheet per set. The sets below were captured on 5 October 2026, after the review fixes were merged, and every capture run passed. They were reviewed through the contact sheets and then removed, because the UI is still changing. Run the tour again to regenerate them.

| Set | Device · runtime | Appearance and text size | Orientation | Shots |
| --- | --- | --- | --- | ---: |
| `iphone12promax-ios27-light` | iPhone 12 Pro Max · iOS 27.0 | Light, default | Portrait | 38 |
| `iphone12promax-ios27-dark` | iPhone 12 Pro Max · iOS 27.0 | Dark, default | Portrait | 38 |
| `iphone12promax-ios27-largetext` | iPhone 12 Pro Max · iOS 27.0 | Light, Accessibility XXXL | Portrait | 14 |
| `iphone12promax-ios27-landscape` | iPhone 12 Pro Max · iOS 27.0 | Light, default | Landscape | 14 |
| `iphone14-ios26.5-light` | iPhone 14 · iOS 26.5 | Light, default | Portrait | 14 |
| `ipadpro13-ios27-portrait` | iPad Pro 13-inch (M5) · iOS 27.0 | Light, default | Portrait | 41 |
| `ipadpro13-ios27-landscape` | iPad Pro 13-inch (M5) · iOS 27.0 | Light, default | Landscape | 38 |
| `ipadpro13-ios27-dark-landscape` | iPad Pro 13-inch (M5) · iOS 27.0 | Dark, default | Landscape | 14 |
| `ipadmini-ios27-portrait` | iPad mini (A17 Pro) · iOS 27.0 | Light, default | Portrait | 14 |

That was 225 captures. A full set is the 37 tour states plus the keyboard shot. The tour covers every destination in the prompt and the main edge states:

- Style Me and its results: onboarding, Style Me, three results, On Me pending and ready, the partial Jose's house result, insufficient Weekend for the office, history reuse, AI offline, and declined permission.
- Editing and wardrobe: the editor, a swap, the closet, a Dirty garment, adding an item, suitcases, an empty suitcase, and laundry.
- Search and saved items: two searches, Saved Looks, a saved look with today's badges, a preview detail, and saved products.
- Shopping: Find One, the store handoff, and purchase review.
- Help and settings: profile, Ask another stylist, settings, exhausted styling access, feedback, demo controls, and help.
- The Ask Stylist chat: its greeting, an answer with a look, and an idea.

The smaller sets use 13 key screens plus the keyboard shot: Style Me, results, editor, swap, closet, garment detail, laundry, search, saved, profile, Find One, settings and the chat answer. The iPad Pro portrait set adds the in-app layout lab at 320, 507 and 678 pt. The keyboard shot is always portrait.

The screenshots caught the iPad crash, the large-text truncation and the chat footer listed below. They also showed one simulator problem. On the iPhone 12 Pro Max simulator the on-screen keyboard stayed hidden for every text field in this session, Search included. XCTest reported the keyboard's frame just below the bottom of the screen, which is what the simulator does once it treats a hardware keyboard as attached; rebooting that simulator didn't clear it. The same build shows the keyboard normally on iPhone 14 and both iPads, so the keyboard evidence was `40-keyboard-other-occasion` in those sets. In the iPhone 12 Pro Max sets that shot showed the field focused without the keyboard. The shot now fills its text in at launch (`-customOccasion`) instead of typing it, because typing from XCTest sends hardware key events.

### Issues found on device and fixed

- The development HUD covered the Closet toolbar's Search and Add buttons. It moved to the bottom-leading corner, clear of navigation and the tab bar.
- Auto-styling at launch could run before the simulated weather arrived, which showed a confusing "weather changed" banner. Launch now waits for the weather snapshot.
- With a single result card, SwiftUI merged the list container into the card and the card lost its own accessibility identifier. The container now only groups when there are several cards.
- After root sheets started hosting their own toast, feature-level "toast mirrors" would have shown duplicate toasts. The app now has one toast per context, with one VoiceOver announcement.
- Flat-lay thumbnails rendered blank at small sizes because the artwork used a fixed inset. The inset now scales with size.
- On iPad, launching straight into the history-reuse result crashed the app, so the first screenshot runs captured the Home Screen for `10-history-reuse` in both orientations. The crash came from SwiftUI's `.sensoryFeedback` modifier: on iPad its location-based feedback read a view that had already gone when an occasion chip's selection changed during a layout rebuild. Haptics now go through UIKit generators called from actions and `onChange`. The same launch then ran three times without a crash, and the iPad flow tests pass.
- At the largest accessibility text size, the Profile name and the Find One "Simulated" badge were cut off with an ellipsis. Both headers now stack vertically at accessibility sizes, and badges wrap instead of truncating.
- In the Ask Stylist chat, earlier messages showed faintly through the area below the composer. The composer now sits on an opaque background.

## Source-only review

- Each of the 11 feature areas was built by one agent and then reviewed by a second, skeptical agent against the prompt, the PRD sections and the shared rules (dispatch, honesty, Unknown stays Unknown, state preservation, accessibility, naming isolation). Reviewers fixed most confirmed issues and listed the rest. See the remaining gaps in [Traceability.md](Traceability.md).
- The mock stylist's composition logic was checked against the fixtures with a standalone simulator binary. Main Closet gives three distinct owned looks for Office, Casual, Event and Date Night; Jose's house gives a one-look partial; Weekend gives "insufficient" for Office, explaining that the white sneakers are too casual; Spring trip says the suitcase is empty; the new-piece lane appears only when requested; the Date Night history entry matches.
- Theme contrast was computed from the asset catalog ([contrast-table.md](contrast-table.md)). All text pairings pass 4.5:1 in light and dark, and control outlines pass 3:1.

### Code review of the integrated app

After the feature areas were merged, four reviewers read the whole source again, each along one line: product rules and honesty; adaptive layout, state and dispatch; accessibility; and visual consistency. They reported 47 findings. A separate skeptical verifier checked each one against the code. One was refuted and 46 held up, 14 of them rated major.

The major ones:

- Using a look from history started new On Me picture jobs, even though the card said reuse was local and free.
- Find One gave "Supported sizing guidance" for jackets from a listed length alone, and its inseam check was one-sided and ignored unit and basis.
- When the stylist padded Suggestions with ideas, it could drop the required color, the starting piece or the occasion, and still billed the result as a full set.
- Ask Stylist kept answering from Main Closet after a remembered suitcase fell back, before Lily had chosen what to do.
- The history offer said a look "still matches today's requirements" without checking today's weather or a required color.
- A "Use for this request" exception was never cleared and carried into later requests and chat.
- On Me picture jobs didn't check the image allowance, and Cancel couldn't stop jobs left over from a retry.
- Opening any look in the editor silently replaced the one draft, including unsaved edits.
- Narrowing an iPad window while a sheet was open could leave the app on a hidden destination.
- The global Command-Return for Style Me collided with the screens' own Command-Return.
- Results that arrive later (chat answers, Style Me results, pictures) weren't announced to VoiceOver.
- The chat composer overflowed the screen at accessibility text sizes.

All 46 were fixed. Five fixer agents each worked in their own copy of the project, grouped by theme. Their changes were merged back with three-way merges, with seven overlaps resolved by hand, and the merged app built with no errors or warnings. A verifier per group then rechecked every finding in the merged code: 44 passed, two fixes were incomplete, and two had small regressions (an action toast that stayed up after its action under VoiceOver, and chat "Saved" state keyed to a reused look ID). A repair pass fixed those four and the app built cleanly again.

A few of these fixes change behavior that only hardware can confirm. Hardware keyboard shortcuts, VoiceOver announcements, action toasts staying up under VoiceOver or Switch Control, and the chat composer at the largest text sizes were checked in code but not exercised on a device.

### Body size and fit inputs (added after the screenshot pass)

Body size as a fit input was built after the screenshots above were captured and after the last flow-test run. That covers confirmed waist, hip and bust cues, the optional weight with its rough height-and-weight band, usual fit as the default comfort, hip chart checks and "Include my size range" in Find One, and the "Size & fit cues" export field. It was checked only by building the app and by reading the code against the rules in [Traceability.md](Traceability.md): weight stays out of the stylist context, the ranker input, search queries and exports, and the band never supports a size or excludes a lead. No screenshot shows any of these screens, and the flow tests still need to be run again against this build. Until then, treat this feature as source-only review.

### Style Me layout change (weather line, occasion row, button bar)

The Style Me form was rearranged after the screenshot pass: the weather card became a one-line summary under the title that opens a details sheet, the occasion chips moved into a collapsible row, the affirmation moved to the end of the form, and Ask stylist became a real button beside Style Me. This was checked by building the app and by code review. The review turned up four things, all fixed: the weather line and the occasion row weren't announced as buttons, the collapsed occasion chip could truncate at the largest standard text sizes, the two bottom buttons could end up different heights, and the pinned bar left almost no room above the keyboard in iPhone landscape. The flow tests were updated to open the occasion row before tapping a chip, and they are re-run separately from this pass. No screenshots were taken, so the Style Me screenshots above still show the old layout.

## Not run

These are outside what a prototype with mocks can show, and the PRD's acceptance, RV and TO checks all remain **Not run**:

- Physical iPhone 12 or iPad performance, thermal behavior, launch/search/save timing targets (PRD §16, RV-10).
- Real AI quality, fit accuracy, image fidelity or On Me rendering (TO-01–TO-08, RV-29).
- Whether the cue thresholds (10 in and 6 in) or the illustrative height-and-weight band match how real garments fit Lily. The mapping is a placeholder for the prototype, not a sizing standard.
- StoreKit purchases, trials, offer codes or restore (AC-17–20, RV-19).
- iCloud sync, conflict resolution, fresh-device restore, real export/import archives (AC-13–16, RV-07/08).
- Real web search, retailer pages, purchase capture against real stores, local notifications (RV-28).
- App Review, privacy labels, legal review.
- VoiceOver walkthroughs and Full Keyboard Access on hardware. Accessibility labels, traits, identifiers and announcements were added and some were exercised through XCUITest, but no screen-reader session was recorded. Hardware keyboard shortcuts weren't pressed on a real keyboard either.
- Real system multitasking windows on iPad (Split View or Stage Manager resizing). Narrow and intermediate widths were checked through iPad devices of different sizes and orientations and the in-app layout lab, which renders a section inside a constrained frame. That's an in-app simulation, not system multitasking.
