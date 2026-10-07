# Picking up the room direction

## Review preview restored, 7 October 2026

Owner clarified that only full-screen “See it bigger” links should be removed. Those links are removed from gallery and review pages; the screen URL initialization required by the preview availability check is preserved. The embedded screen remains above the feedback form. Verify an actual rendered iframe when changing review navigation; presence of the notes button alone is insufficient.

## Centered tablet panes, 7 October 2026 (R11)

Owner requested centered two-pane layouts. The shared tablet layout centers each short pair vertically between its header and bottom navigation, with both panes aligned to the same center. Taller content retains its natural scrolling position. Direct tablet grids have a centered maximum width; compact account and shop layouts center within the available height. ResizeObserver recalculates paired panes after content changes and resize. Phone layouts are preserved. No native changes or commit.

## Adaptive tablet layouts, 7 October 2026 (R10)

Owner requested two panes or columns on all iPad views where useful, including ordinary screen routes opened on an iPad. Shared `css/tablet-layout.css` and `js/tablet-layout.js` adapt regular pages at 768 px and wider: Saved Looks has controls beside its gallery, Closet has the room header beside the clothing grid, Suitcases has the hall beside its list, and detail/request/settings screens separate their illustration or preview from their controls. The script moves existing elements and restores them below the breakpoint, preserving handlers and phone layouts. Tour copies use the same adaptation. Registry adds an “On iPad, sideways” review view to regular screens and uses live previews for R10 pages; stable screen IDs and existing view keys are preserved.

Visually checked 25 tablet routes at 1194 × 834, the three reported screens at 834 × 1194, and Saved Looks at 390 × 844. Confirmed search/picture switching, the request editor, breakpoint restoration, and tablet tour positioning. Renders are in `/private/tmp/tablet-*.png`, outside snapshots. Native code is unchanged. No commit.


## iPad landscape spacing, 7 October 2026

Owner requested full use of landscape tablet space across every iPad mockup. Home now arranges wardrobe, window, suitcase, desk, shelves and sign across a wide room with bottom navigation; the previous sidebar/request column Home composition is replaced. Its shared `css/home-wide.css` also adapts normal Home at landscape tablet widths while preserving phone and compact layouts. Closet, Results and Saved Looks retain navigation and browsing/detail columns, with slimmer navigation, wider grids and responsive spacing in `css/ipad-landscape.css`. All four iPad tour copies follow those layouts. Affected screens are R9 with live gallery previews. Checked at 1194 × 834 and 1024 × 768; phone Home checked at 390 × 844. Native code is unchanged.


## Come back later list, 7 October 2026

Owner requested a running list of skipped screens. Review pages now have Come back later, which saves the exact screen/view and advances to the next screen. The gallery and each review page show the saved list with direct return links and Done with this removal buttons. The list persists in localStorage in the same browser; it is not synced across devices or shared with notes. A storage failure stays on the screen and reports the problem. Shared notes and their manifest are unchanged.


## Review order, 7 October 2026

Jose requested all guided tours first on the gallery, followed by the regular app screens. The Home tour now belongs to Quick tours. Registry order also makes Take a look start with Home quick tour and Next screen follow all 38 tours before the 38 regular screens. IDs, variants, revisions and saved-note associations are unchanged.


## Profile try-on photo, 7 October 2026

Jose approved adding Your try-on photo to Profile. The row opens a simple optional reference-photo sheet, with Choose example photo, an explicitly simulated example choice, Change example photo and confirmed Remove photo. Jose clarified that Lily will not upload a real image in the mockups. Saved try-on pictures are preserved when the reference is removed. State stays in the preview session; no personal image is collected or uploaded. Profile and its tour copy are R8; review variants include the empty sheet, example choice and added state. Real image-service validation and native permissions remain governed by the PRD. No commit.

## Try-on portrait placeholders, 7 October 2026

Jose requested a simple generic person in the simulated try-on picture slots, keeping the Simulated label and bottom hint. Picture, Saved Looks, saved-outfit thumbnails, iPad Saved Looks and their tour copies now use one shared SVG placeholder and explain that the real picture would show her in that look, while the sample clothes do not match. This is an explicit exception to the earlier no-person rule only inside try-on previews; room/Profile and native app are unchanged. See README for files. No commit.

## Remaining screen tours completed, 7 October 2026

The owner requested tours for the remaining screens. There are now 37 additional `*-tour.html` copies and 102 tips, all registered in the Quick tours gallery group. Profile’s App tours sheet replays every guide; More screen tours keeps the main list short. Read the README’s Tours for every screen section for files, parameters and verification. Original pages are preserved except for those Profile replay links. Home retains its exact approved tour. First-use tracking and native integration are still future work; the tours requirement is now accepted in master PRD Section 7.8 / FR-73 / AC-103. Native implementation is pending. No commit was made.

## Home quick tour, 7 October 2026

The owner requested and approved a separate `screens/home-tour.html` mockup: four coach marks for laptop, wardrobe, suitcase and name sign. It is listed in `js/registry.js`, including direct step links and `?tour=off`. Read the README’s Home quick tour section for behavior and render locations. Original `home.html` is unchanged. Profile replay links were completed by the owner’s follow-up request. Actual first-launch integration remains future work.

## Reusable client review workflow, 7 October 2026

Jose asked to keep this review process for future client apps. Read [CLIENT_REVIEW_WORKFLOW.md](../../CLIENT_REVIEW_WORKFLOW.md) for the project handoff and pointers to the canonical Obsidian workflow/checklist. The live review copy is now personal to Lily, with short instructions and optional extra views; main navigation moves between main screens. Saved notes were preserved across that update. Future agents are welcome to add dated, verified lessons to the reusable workflow. This documentation does not change the feedback sign-off process below.

Written 6 October 2026 at the end of a long session, so the next session can continue without the old conversation.

## Status, 7 October 2026 (R5)

The mockup update described below is done. Every screen in the checklist is built in the soft style, with its versions listed in `js/registry.js`. The review site is live at https://turbo-gazebo-e3jy.here.now/ (notes summary at `summary.html`). Lily's notes are saved there and kept across updates. To update it, run `tools/build-site.sh` and publish `site/` to the same slug (`turbo-gazebo-e3jy`). Next step: Lily's notes go through the sign-off process in README.md ("Lily's notes: pull, sign off, run"). "Pull Lily notes" only pulls and writes a sign-off sheet. "Run Lily notes" makes only the items the owner approved. After that, wait for the go-ahead before the SwiftUI work or the PRD amendment.

## First-use tours (owner request, 7 Oct)

Jose approved a coach-mark tour for Home: the room dims, one object is spotlit and a soft frosted card says "Quick tour · 1 of 4" with Skip and Next (laptop, wardrobe, suitcase, name sign). `screens/home-tour.html` is being built from that design. Profile now has an "App tours" row that opens a sheet where she picks a screen to replay its tour, plus a "Show tips on new screens" switch (`screens/settings.html`, `?sheet=tours`). All registered screens now have separate replayable tour mockups; automatic first-use tracking remains future app work. The PRD change is proposed in [PRD_Amendment_First_Use_Tours.md](../../PRD_Amendment_First_Use_Tours.md) and was accepted and integrated into master PRD Section 7.8 on 7 October 2026.

## Prompt to start the next session

Paste this into a new session opened in `/Users/jramirez/Git/closet`:

```
Read prototypes/RoomDirectionMockups/NEXT_SESSION.md and prototypes/RoomDirectionMockups/README.md. Update the HTML mockups in prototypes/RoomDirectionMockups only: work through "Checklist: new screens these decisions need" (using the sections above it for detail), in the approved soft style, rendering and checking every screen, then refresh snapshots/, index.html and the README. Do NOT change the SwiftUI prototype, write the PRD amendment, or start "The next job" until I review the mockups and say so. Follow the standing rules in that file. Don't commit until I ask.
```

## Where things stand

- The SwiftUI prototype is in `prototypes/LilyStyleMockup` on branch `closet/mock`, committed in `bc6c9e4`. All 14 flow tests passed on iPhone 14 and iPad Pro 11 after the last prototype changes.
- The room-direction mockups are in `prototypes/RoomDirectionMockups`, committed in `7bd29a9`. Its `README.md` lists the 12 owner decisions and every screen. Read that first.
- None of the room direction is in the SwiftUI app yet.
- Edit the master PRD only with explicit owner approval. Jose approved integrating the first-use tours on 7 October 2026; Section 7.8 is authoritative. Other proposed amendments remain proposals.

## The next job (only after the owner approves the updated mockups)

Three decisions change prototype behaviour, not just looks:

1. The On Me toggle comes off the Style Me form. Try-on becomes a per-look "Try it on" action on the results, labelled Simulated, which spends one picture only when asked.
2. Style Me results show each look as a sticker bundle: garment cutouts with a thick white outline, slightly tilted and overlapping, no tiles or hangers. Looks 2 and 3 appear as small tappable bundles. Start from `DesignSystem/OutfitFlatLayView.swift`. Reference: `screens/results-flatlay.html` and `snapshots/results-flatlay.png`.
3. Saved Looks splits into two tabs. Looks shows every saved look as its bundle and works without image credits. Pictures holds only saved try-on pictures, each linked to its look. Reference: `screens/saved-flatlay.html`.

Plan: first write an amendment proposal as a new file (for example `PRD_Amendment_Room_Direction.md` at the repo root) covering the three changes, the reasons and the PRD sections and acceptance criteria they touch. Then build them in the prototype, update the flow tests, and check on the iPhone and iPad simulators.

## Home navigation cleanup (owner request, 6 Oct, not yet done)

Make the home room's paths match what the objects are. Update `screens/home.html`, `home-ax.html` and `ipad-home.html` in the mockups first, then carry it into the app:

- **Tapping the wardrobe opens Closet.** The whole wardrobe is the Closet link. Its Source plate and the "5 pieces · Suitcase only" plate come off it.
- **The Starting piece plate and the rack leave Home.** She picks a starting piece from the Closet (a garment's "Style with this", which already exists), not from Home.
- **A suitcase stands where the rack was.** It's the path to Suitcases and carries the Source plate ("Source · Jose's house") and the "5 pieces · Suitcase only" plate. Tapping it opens Suitcases, where she picks the source. Draw it in the room style (reuse or adapt `art/travel-suitcase-*.svg` or `art/closet-suitcase.svg`).
- Only the UI changes. The Style Me inputs and backend stay the same.

## Window shows the weather (owner request, 6 Oct, small)

The home window should match the current weather. `art/` already has `window-rain.svg`, `window-sun.svg` and `window-night.svg`. Add `window-cloudy.svg` and `window-snow.svg` in the same style (same frame, curtains and viewBox; only the sky and tree change). Pick the window from the weather condition in the mockups (for example a `?weather=` parameter on `home.html` and `ipad-home.html`), and in the app from the simulated weather snapshot, with night used after dark. Do it alongside the Home navigation cleanup.

## Search in Saved Looks (owner request, 6 Oct)

Saved Looks needs a search field on both the Looks and Pictures tabs, because scrolling alone won't work once she has many looks. Place it under the Looks/Pictures switch, in the soft style used by the Closet search ("Search your looks"). It matches look title, occasion and piece names, and on Pictures it searches the look each picture came from. The grid keeps scrolling for browsing. Add it to `screens/saved-flatlay.html` in the mockups and to Saved Looks in the app.

## Results: shuffle and balanced buttons (owner request, 6 Oct)

On the approved results screen (`screens/results-flatlay.html`):

- **Shuffle.** Add a "Shuffle" control (shuffle icon, soft pill) beside the "Look 1 of 3" dots. It swaps in three different looks drawn from looks already created (earlier Style Me results and saved looks that fit the current source and occasion), with no new AI request and no credits used. The screen always shows three looks. Say so in a short caption the first time, for example "From your earlier looks · no credits used". The prototype already reuses history without dispatching (see the `testHistoryReuseAvoidsDispatch` flow test), so build on that. If too few earlier looks fit, shuffle shows what it can and says so.
- **Balanced buttons.** Make the four actions a symmetric 2 x 2 grid of equal width and height: Save look (filled plum) and Try it on on the first row, Swap a piece and Ask stylist on the second. Move "Simulated" off the Try it on button so all four are the same height, and keep the single fine-print line "Try-on pictures are simulated" under the grid.

## Open question: where shopping (Find One) fits (design only)

The room mockups have no shopping yet. The proposal to show the owner: shopping appears only where a look has a gap, never as a general shop button.
- **Results:** when a look needs a piece she doesn't own, the bundle shows a dashed empty sticker slot ("No navy flats in this suitcase") with a "Find one" pill that opens the existing Find One flow.
- **Swap a piece:** a "Not in your closet? Find one" row at the end of the alternatives.
- **Saved products:** a third Saved Looks tab, or a row in Profile.
The Find One functionality stays as it is in the prototype; only its placement in the room design is open, to settle as the build goes. (`Simplified_Direction_On_Hold.md` would defer shopping if adopted.)

## Prototype screens with no room-direction mockup yet

Mocked so far: home, large-text home, closet, garment detail, suitcases, laundry, results, swap, Saved Looks, look detail, profile, styling access, paywall, onboarding, Ask stylist chat, iPad home and iPad closet. The prototype also has these, which have no mockup and no design decision yet:

- **Core flows (most important):** add or edit a garment (photo, cutout, name, category), the starting-piece picker, More options sheet, Occasion picker including "Other", the generating/loading state, the outfit editor (manual outfits), and a suitcase's detail screen.
- **States:** empty closet, empty suitcase, partial results when the source is too small, errors, offline.
- **Search:** the unified search screen (Closet now has a search field; decide whether they are the same).
- **Pictures:** the try-on picture detail ("preview"), picture packs and out-of-pictures (behind the purchases demo toggle).
- **Shopping:** Find One, purchase review, store handoff, saved products (placement is the open question above).
- **Other:** fit profile and measurements, Ask another stylist, Help, Feedback board, Demo controls, weather detail.
- **Across the board:** dark mode for the room art, and iPad versions of the remaining screens.

Not all need illustrated rooms: forms, settings and help can be plain screens in the soft style.

## Responsive layout and rotation (not covered yet)

The mockups are fixed-size pictures: iPhone portrait at 390 x 844 and iPad landscape at 1194 x 834 only. They do not cover other phone sizes, rotation, iPad portrait or multitasking. The SwiftUI prototype already handles rotation for its current screens (`testRotationAndNavigationDoNotDispatch`), but the room design has to be made adaptive when it is built:
- **Small and large phones** (iPhone SE to Pro Max): the room scales as one composed scene and keeps every label legible; on the smallest screens it can drop decoration (bed corner, Maya, plant) before shrinking labels.
- **iPhone landscape:** the room becomes a short banner or sits beside the controls; never a squashed portrait scene.
- **iPad portrait, Split View and Slide Over:** use the iPad layout at regular width and the phone layout at compact width.
- **Large text:** the banner-plus-rows layout (`home-ax.html`) at accessibility sizes.
- Rotating or resizing must not re-run a Style Me request or lose state.
Check each on the simulators and mock the iPhone landscape and iPad portrait home first.

## Laundry becomes opt-in (owner decision, 6 Oct)

Laundry tracking adds upkeep, so it is off by default and turned on with a toggle in Settings ("Track laundry").
- **Off (default):** no Dirty chip, no Laundry tile in Closet, no laundry badges, and every piece counts as available to Style Me.
- **On:** today's behaviour (Dirty filter, Laundry screen, Mark clean with Undo, Style Me skips dirty pieces unless she allows one).
- Known gaps to design when it is on: pieces left "dirty" forever silently shrink Style Me's choices (consider a gentle "Still in the wash?" check or auto-return to clean after a set number of days); whether "Wear today" marks pieces worn; different pieces need washing at different rates (jeans vs blouses); dry cleaning and items away on a trip; turning it off should not lose the dirty marks in case she turns it back on.
- **A hamper on the home room** makes laundry visible (today it is easy to miss, tucked in Closet). Draw it in the room style, standing on the floor in a clear spot (for example near the wardrobe or bed), reusing or adapting `art/travel-hamper.svg`.
  - **When on:** the hamper is a real control with a small plate, for example "Laundry · 2 to wash" (or "Laundry · all clean"), and opens the Laundry screen. When something is dirty, a very subtle bulge of clothing rises just above the hamper rim; when everything is clean, the hamper is closed or empty with no clothes showing.
  - **When off:** the hamper still stands there, a little faded and empty with no clothes showing at all, with a quiet plate "Laundry · Off". Tapping it opens a short sheet explaining what laundry tracking does, with a "Turn on" button and a link to the Settings toggle. It never nags.
- Update the prototype's laundry fixtures and flow test (`testLaundryMarkCleanWithUndo`) to switch the toggle on first.

## Discoverability from Home (review, 6 Oct)

**More options moves to the Style Me screen; the desk drawers hold "drawer stuff" (owner decision, final).**
- **Comfort, Color and Mode** (today in `Features/StyleMe/StyleMeMoreOptions.swift`: today's comfort, colour family and strength, Suggestions or Use only my wardrobe, and "Include one new-piece idea") live on the Style Me screen, since Style Me is what uses them. The Style Me screen is what the desk laptop opens: tapping the laptop no longer styles straight away; it opens a Style Me sheet showing the request (source, occasion and starting piece as summaries from Home) plus Comfort, Color and Mode, each showing its current value, and one primary "Style me" button that sends the request and leads to "Your looks". Keep it one calm screen; the defaults mean she can just tap "Style me".
- **The three desk drawers on Home** hold the things you'd keep in a drawer: Help and the like. Proposal: top drawer "Help", middle drawer "Send feedback", bottom drawer "Privacy and terms". They are not used for laundry (the hamper covers that) or styling options. The "More options" label goes away. In the large-text layout they become three rows.

**Other discoverability decisions:**
- **Past results:** "Your looks" (the results screen) gets tabs: the current three looks and an "Earlier" tab with past Style Me results. Shuffle draws from these too. Saved Looks still holds only what she saved.
- **Add a piece:** stays in Closet only. She won't add pieces often.
- **Remaining picture allowance:** show a quiet "31 pictures left" near Try it on (proposal; confirm with the owner).
- **Laundry:** the hamper (above). **Suitcases / source:** the suitcase object (Home navigation cleanup). **Ask stylist and Try it on:** results screen only. **Help, feedback, privacy, demo controls:** Profile, from the top-right icon or the name sign.

## Checklist: new screens these decisions need (none mocked yet)

1. **Home, updated:** wardrobe opens Closet, suitcase in place of the rack (with the Source plates), hamper (on with a subtle clothes bulge, on and all clean, off and faded), desk drawers labelled Help / Send feedback / Privacy and terms, window matching the weather.
2. **Window variants:** cloudy and snow (rain, sun and night exist).
3. **Style Me screen** (opened by the laptop): request summary, Comfort, Color, Mode, one "Style me" button. Plus the small sheets each option opens.
4. **Your looks, updated:** Shuffle, the balanced 2 x 2 buttons, the "Earlier" tab, and the "pictures left" hint near Try it on.
5. **Saved Looks with search** on both tabs, plus a search-results state and a no-results state.
6. **Laundry off sheet** (what tracking does, "Turn on") and the **Settings "Track laundry" toggle**.
7. **Drawer screens:** Help, Send feedback, Privacy and terms.
8. **Suitcases with more than three:** three favourites plus "See all" list.
9. **Responsive variants:** iPhone landscape home and iPad portrait home first.
10. **Soft versions** of the screens built before the soft style was approved (home, garment, suitcases, swap, look, paywall, onboarding, chat, iPad).
Then the prototype screens listed under "Prototype screens with no room-direction mockup yet".

## App Store guidelines: what's covered and what to answer (6 Oct)

Approval is never guaranteed; these are the points to keep checking against the current App Review Guidelines.

**Already handled in the prototype:** subscription disclosures on the paywall (3.1.2: price, period, trial end, first charge, renewal, Restore, Terms, Privacy); digital purchases through In-App Purchase and physical goods through the store (3.1.1, 3.1.3); local features free; simulations labelled.

**Needs care in the real build:**
1. 5.1.2(i): clear notice and explicit permission before sending personal data to a third-party AI. Try-on photo consent stays separate from text-styling consent.
2. 5.1.1(v): in-app account deletion if accounts exist.
3. 4.8: if any third-party login is offered, also offer an equivalent privacy-focused option such as Sign in with Apple.
4. 1.2: a public feedback board needs reporting, blocking and moderation (a reason it may be deferred).
5. Generated images: try-on only on her own photos, a way to report bad output, and an age rating that reflects generative AI.
6. Privacy nutrition label and privacy manifest (required-reason APIs, third-party SDKs).
7. WeatherKit attribution if Apple Weather supplies the weather.
8. 2.3: the store listing and screenshots must show only real, working features at submission.
9. 2.4.1: if it ships on iPad, every screen must work well there.
The room design itself (illustrations, Maya, the name sign) raises no guideline issues.

**Open questions for the owner to answer:**
- Final pricing and allowances, after measuring real costs.
- Which AI providers to use for text and for try-on.
- Whether PRD changes go in a v3 file or a separate amendment.
- Whether Supabase is the backend (`Simplified_Direction_On_Hold.md`).
- Who writes the privacy policy and terms.
- Whether "My Petite Style" is available as an App Store name and a trademark.

After that, the wider visual work (soft no-box style across all screens, Home tab rename, name sign, illustrated rooms, Maya) can follow, in whatever order the owner picks.

## Standing rules

- Fictional data and mock services only. Never use a real body photo, connect real accounts or need API keys. Label simulations.
- Don't install tools or change global Xcode settings. Don't publish or share artifacts unless asked. Commit only when asked.
- Don't save simulator screenshots into the project until the owner asks for captures of every screen. One-off looks in a scratch folder are fine.
- Simulators: iPhone 14 `500C33A7-D39E-4963-836B-6D5B40F74AB6`, iPad Pro 11 `0735BF9F-BEC3-4956-B69E-5D2827AC2A7E`, iPhone 12 Pro Max `045671C5-F332-46A1-9411-6419E68C2092`.
- Build: `xcodebuild -project LilyStyleMockup.xcodeproj -scheme LilyStyleMockup -destination "id=<udid>" -derivedDataPath <scratch>/dd build CODE_SIGNING_ALLOWED=NO`. Tests: same with `test` and `-only-testing:LilyStyleMockupUITests/FlowTests`.
- The person the app is for is autistic and finds boxy design uncomfortable. The soft style (no outlines, space and below-only shadows) is approved.
