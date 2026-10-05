# My Petite Style: iPhone and iPad prototype

This folder holds an interactive SwiftUI prototype of My Petite Style (working title), built from the master spec [My_Petite_Style_PRD_v2.md](../../My_Petite_Style_PRD_v2.md) and the [mockup prompt](../../Claude_Code_iPhone_iPad_Mockup_Prompt.txt). It lets Lily tap through the intended experience on an iPhone or iPad simulator before any real AI, image, search, sync or billing service is connected.

It is a front-end prototype. All data is fictional, every external service is a mock, and nothing leaves the device. It doesn't prove production storage, iCloud sync, StoreKit billing, real AI or fit quality, or App Store approval. The PRD's release checks are still Not run.

What has been checked so far:

- The app builds with no errors or warnings.
- Seven flow UI tests pass on iPhone 12 Pro Max and iPad Pro 11-inch (iOS 27). They cover Style Me, swaps, saving, rotation, history reuse, partial suitcases, laundry, search and the Ask Stylist chat, and use the service-call counter to prove which actions call a service.
- A full pass of 225 native simulator screenshots, across nine device, appearance and text-size sets, was captured and reviewed on 5 October 2026. The images aren't kept while the UI is still changing; `Tools/capture_screenshots.sh` writes a fresh set to `Screenshots/` when needed.
- A code review of the integrated app confirmed 46 findings. All were fixed and rechecked.
- Body size as a fit input (waist, hip and bust first, weight only as a rough fallback) was added after the screenshot pass and the last flow-test run. It has been checked by building and by code review only, so no screenshot shows it yet and the flow tests need to be run again.

[Docs/Verification.md](Docs/Verification.md) has the details and lists what wasn't run.

## Run it

Requirements: macOS with Xcode 26 or later and an iOS 17+ simulator runtime. The checked-in project needs no extra tools.

1. Open `prototypes/LilyStyleMockup/LilyStyleMockup.xcodeproj` in Xcode.
2. Pick the `LilyStyleMockup` scheme and an iPhone or iPad simulator. iPhone 12 Pro Max and iPhone 14 have the same layout widths as Lily's iPhone 12 (iPhone 14 is 390 × 844 pt, identical to iPhone 12).
3. Press Run. The first launch shows the skippable onboarding.

From the command line:

```bash
cd prototypes/LilyStyleMockup
xcodebuild -project LilyStyleMockup.xcodeproj -scheme LilyStyleMockup -destination 'platform=iOS Simulator,name=iPhone 14' build
```

The project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and uses synchronized folders, so new Swift files are picked up without regenerating. Regenerating is only needed after changing `project.yml`:

```bash
xcodegen generate
```

Running on a physical device needs your own signing team in the target settings. The demo doesn't need any capabilities or entitlements. On iPad it runs as a single window (`Config/Info.plist` turns off multiple windows), and Split View, Slide Over and Stage Manager resizing still work.

### Demo controls

Open **Demo Controls** (sidebar on iPad, or the person menu at the top right on iPhone). From there you can:

- switch scenarios: normal success, partial or insufficient closet, slow, failed or cancelled image jobs, stale result after a swap or source change, offline weather or AI, declined permission, exhausted allowance, save failure, sync conflict
- watch the service-call counter, which shows that browsing, scrolling, rotating and resizing don't call any service
- set up the simulated On Me reference, change the sample access plan, and reset the demo data
- preview screens at fixed widths in the in-app layout lab

### Launch arguments

The same states can be opened directly, which is how the screenshots were taken:

| Argument | Effect |
| --- | --- |
| `-resetDemo` | Start from fresh fixtures |
| `-skipOnboarding` | Skip the onboarding sheet |
| `-fastMocks` | Shorten simulated delays |
| `-showHUD` | Show the service-call counter |
| `-scenario <name>` | `normal`, `partialCloset`, `slowImages`, `failedImage`, `staleAfterSwap`, `offlineWeather`, `offlineAI`, `declinedPermission`, `exhaustedAllowance`, `saveFailure`, `syncConflict` |
| `-scope <main\|jose\|weekend\|spring>` | Choose the wardrobe source |
| `-occasion <raw>` | `office`, `dateNight`, `brunch`, `concert`, `casual`, `event`, `other` |
| `-customOccasion "<text>"` | Choose Other and fill in its description |
| `-onMeDemo` | Enable the simulated On Me reference, permission and toggle |
| `-route <name[:id]>` | Open a screen: `styleMe`, `results`, `editor`, `swap`, `closet`, `garment:<id>`, `suitcases`, `suitcase:<id>`, `laundry`, `search`, `saved`, `outfit:<id>`, `preview:<id>`, `profile`, `settings`, `access`, `help`, `feedback`, `developer`, `findOne`, `askStylist` (export), `chat`, `chatLook`, `chatIdea` (Ask Stylist), `onboarding`, `addItem`, `purchase`, `handoff`, `savedProducts` |
| `-autoStyle` | Tap Style Me after launch |
| `-searchQuery "<text>"` | Prefill search |
| `-appearance <light\|dark>` | Force an appearance |
| `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` | System Dynamic Type override |

## How it's built

```text
LilyStyleMockup/
  App/            entry point, adaptive shell (tabs vs sidebar), root sheets, toasts, launch arguments
  Core/Models/    typed records: garments, suitcases, outfits, previews, profile, shopping, access, feedback
  Core/Store/     DemoStore (the canonical store and its rules), fixtures, local JSON persistence
  Core/Services/  service protocols, dispatch counter, demo scenarios, mock services
  Core/AppModel/  navigation, Style Me session, outfit editor session, preview helpers
  DesignSystem/   tokens and reusable components (see Docs/DesignSystem.md)
  Features/       one folder per area: StyleMe, OutfitEditor, Closet, GarmentEditor, Suitcases,
                  Laundry, Search, Saved, Profile, FindOne, AskStylist (export), StylistChat
                  (Ask Stylist chat), Feedback, Settings
LilyStyleMockupUITests/  flow tests and the screenshot tour
Tools/          screenshot capture, contact sheets, contrast check
Docs/           design system, traceability, verification evidence
```

A few decisions shape everything else:

- **One store owns the rules.** `DemoStore` is the only place that changes garments, suitcases, outfits and previews. Eligibility (owned, arrived, available, in this source), laundry preconditions, No longer own versus Archive versus Trash, and deletion scope are enforced there, so screens can't drift from the PRD.
- **State outlives layout.** The request draft, results, selected look, editor draft, navigation stacks and each feature's UI state live in `AppModel`. Rotating, resizing, switching between the iPhone tab layout and the iPad sidebar, or showing the keyboard keeps all of it, and none of those changes can start a service call.
- **Services are injected.** `MockStylist`, `MockImageProvider`, `MockWebSearch`, `MockShoppingRanker`, `MockWeather` and `MockGarmentUnderstanding` implement provider-neutral protocols (`Core/Services/ServiceProtocols.swift`). Screens never pick a provider, and every mock call increments the dispatch counter.
- **Only explicit actions dispatch.** Style Me, Retry, New ideas, Update Preview, Make picture, an Ask Stylist Send, Find One's Search, Suggest a description and weather Refresh are the only calls a tap starts. The one exception is the weather snapshot Style Me needs (PRD FR-04): it loads once at launch or when Style Me first appears, is reused for 30 minutes, and the counter shows it separately as "auto". Local history reuse and exact retained-preview reuse are counted as "reused locally" instead.
- **Fit inputs have an order of trust.** Confirmed waist, hip and bust come first and give fit cues (room at the hip or bust, or a straighter line) that shape styling and Find One's chart checks. Only when all three are missing does confirmed height plus an optional weight give a rough size band, always labeled as an estimate. The band never supports a size or excludes a listing, and raw weight is never shared: the stylist, search and exports only ever see the cue words or the band label, and only where a permission allows. The saved usual fit is the default comfort unless today's choice overrides it. The details and the PRD text this goes beyond are in [Docs/PRD-amendment-body-size.md](Docs/PRD-amendment-body-size.md).
- **Local persistence is real but simple.** The demo store is written atomically to JSON in the app's Application Support folder. A "Saved on this device" acknowledgement appears only after that write succeeds. The save-failure scenario shows the honest failure path.

### Design research applied

The visual and interaction choices were checked against current wardrobe, fashion and AI-chat apps on Mobbin. The full comparison is in [Wardrobe and AI stylist UX patterns](../../research/reports/Wardrobe%20and%20AI%20stylist%20UX%20patterns.md). Three findings shaped the prototype most:

- **Outfits as one flat-lay.** Alta, Whering and Depop show a look as garments laid out on a neutral canvas, not a grid of captioned tiles. `OutfitFlatLayView` does the same (two-column composition, shoes as a pair). Labeled piece chips underneath carry names, colors and status for VoiceOver and large text.
- **Ask Stylist as a calm, secondary chat (PRD FR-14).** The pattern is a greeting, a few suggested questions, one composer card with an attached look, and a plain **Closet only / Closet + new ideas** mode. Answers come back as a short note plus a flat-lay look you can open in the editor or save. It's never the main way to style, it dispatches only on Send, and the conversation isn't saved.
- **Restrained motion with clear meaning.** Pieces settle onto the canvas, swapped garments cross-fade in, and suggestions rise in. The stylist avatar breathes while idle and three dots pulse while it answers. Haptics confirm selections, sends, arrivals and saves. Every animation has a Reduce Motion fallback, defined in `DesignSystem/Motion.swift`.

### Fictional fixtures

About 20 garments, including navy and olive trousers, the "Cute pink shirt" blouse, a white lace top (Dirty), a navy cardigan, a brown leather jacket, distinguishable shoes (nude flats, black block heels, white sneakers, text-only tan loafers), an archived skirt, a dress at the tailor (Unavailable), a donated blazer (No longer owned), a not-yet-arrived cream lace crop top, a wishlist trench coat and an item in Trash. Suitcases: **Jose's house** (can only make one complete look), **Weekend** (fine for casual, insufficient for Office), and **Spring trip** (a valid empty suitcase). Navy dress pants belong to both Jose's house and Weekend as a single canonical record. Lily's profile has a confirmed 4′11″ height, an unconfirmed 26 in inseam, Unknown waist, hip and bust, and an approximate weight of about 120 lb, so the demo starts on the rough-estimate path (around M) until measurements are added in Profile. There are four saved looks, four retained previews (current, earlier, disliked, needs review), Work / Gym / Going Out collections, and a six-month-old Date Night look in structured history for the reuse demo.

Garment pictures are app-drawn illustrations in each garment's color. Items marked "Your photo (demo)" stand in for photos Lily would take. On Me previews use an abstract placeholder figure, not a person. No real photo of Lily or anyone else is used.
