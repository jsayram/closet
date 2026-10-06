# Picking up the room direction

Written 6 October 2026 at the end of a long session, so the next session can continue without the old conversation.

## Prompt to start the next session

Paste this into a new session opened in `/Users/jramirez/Git/closet`:

```
Read prototypes/RoomDirectionMockups/NEXT_SESSION.md and prototypes/RoomDirectionMockups/README.md. Start with the "Home navigation cleanup", "Window shows the weather", "Search in Saved Looks" and "Results: shuffle and balanced buttons" sections, then do "The next job": write the PRD amendment proposal for the three behaviour changes as a separate file, then build them into the SwiftUI prototype in prototypes/LilyStyleMockup, update the flow tests, and check on the iPhone and iPad simulators. Follow the standing rules in that file. Don't commit until I ask.
```

## Where things stand

- The SwiftUI prototype is in `prototypes/LilyStyleMockup` on branch `closet/mock`, committed in `bc6c9e4`. All 14 flow tests passed on iPhone 14 and iPad Pro 11 after the last prototype changes.
- The room-direction mockups are in `prototypes/RoomDirectionMockups`, committed in `7bd29a9`. Its `README.md` lists the 12 owner decisions and every screen. Read that first.
- None of the room direction is in the SwiftUI app yet.
- The PRD (`My_Petite_Style_PRD_v2.md`) is never edited. Changes go in separate amendment proposals.

## The next job

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

After that, the wider visual work (soft no-box style across all screens, Home tab rename, name sign, illustrated rooms, Maya) can follow, in whatever order the owner picks.

## Standing rules

- Fictional data and mock services only. Never use a real body photo, connect real accounts or need API keys. Label simulations.
- Don't install tools or change global Xcode settings. Don't publish or share artifacts unless asked. Commit only when asked.
- Don't save simulator screenshots into the project until the owner asks for captures of every screen. One-off looks in a scratch folder are fine.
- Simulators: iPhone 14 `500C33A7-D39E-4963-836B-6D5B40F74AB6`, iPad Pro 11 `0735BF9F-BEC3-4956-B69E-5D2827AC2A7E`, iPhone 12 Pro Max `045671C5-F332-46A1-9411-6419E68C2092`.
- Build: `xcodebuild -project LilyStyleMockup.xcodeproj -scheme LilyStyleMockup -destination "id=<udid>" -derivedDataPath <scratch>/dd build CODE_SIGNING_ALLOWED=NO`. Tests: same with `test` and `-only-testing:LilyStyleMockupUITests/FlowTests`.
- The person the app is for is autistic and finds boxy design uncomfortable. The soft style (no outlines, space and below-only shadows) is approved.
