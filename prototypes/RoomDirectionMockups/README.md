# Room direction mockups

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

## Try-on person placeholders, 7 October 2026

Owner requested a lightweight generic person in every simulated try-on portrait, including saved-picture grids, picture details, linked thumbnails, iPad and their tour copies. All retain Simulated and explain: “In the app, this would be you wearing this look. For now, it is an example person in different clothes.” The shared SVG is `art/tryon-person-placeholder.svg`, styled by `css/tryon-placeholder.css`. This is not a body/avatar feature, a real photo or a try-on result. Affected screens are R7; native code and PRD are unchanged by this placeholder task.

## Weight editor update, 7 October 2026

Owner requested an editable optional weight in the HTML mockups, starting at **130 lb**. `screens/fit.html` now uses the measurement sheet for weight with Save, Clear and Cancel, pounds/kilograms, number validation and preview-session persistence. The former fixed 120 lb demo fixture migrates to 130 lb; subsequent edited values are preserved. No weight is posted to the shared notes service. The Fit screen alone is marked R6 in the registry; other screens remain R5. Verified locally: default, editing/save and refresh, invalid input, cancellation, unit display and clearing. Native code and PRD were not changed.

Static HTML mockups of the "home as rooms" direction for My Petite Style, made 5–7 October 2026 (current revision R5, 7 Oct). They are a design reference for bringing the new look into the SwiftUI prototype (`prototypes/LilyStyleMockup`). None of this is in the app yet, and other mockup proposals do not change the PRD. The owner accepted tours into master PRD Section 7.8 on 7 October 2026.

All data is fictional and matches the prototype's demo fixtures. Prices are sample values. Try-on pictures are simulated placeholders.

## How to view

The gallery loads the screens in frames, so serve the folder rather than opening the files directly:

```bash
python3 -m http.server 8766 --directory prototypes/RoomDirectionMockups
```

Then open `http://localhost:8766/index.html`. Screens are grouped by journey, each with its versions, a full-screen link and Previous/Next. Served locally, the notes box under each screen runs in preview mode and saves nothing. PNG snapshots of every version are in `snapshots/`, named `<screen>--<version>.png`.

The shared review copy, where Lily's notes are saved, is published to here.now from a clean `site/` folder; see "Publishing the review site" below.

Add `?theme=dark`, `?text=xl` or `?motion=reduce` to any screen URL for dark appearance, the largest text size or reduced motion.

## Decisions to carry into the app

These are the owner's decisions from the review rounds. Where a screen in this folder and this list disagree, this list wins.

1. **Soft, no-box style (approved).** No outlines on cards, tiles, rows, chips or label plates. Separate items with space, soft tints and shadows that fall only below. Items rest on the background. Buttons are gently rounded and the selected chip is a solid plum pill. The person the app is for is autistic and finds boxy design uncomfortable. The reference screen is `screens/results.html`; the rules are in `css/soft.css`.
2. **Looks are sticker bundles.** A look is shown as her real garment photos, cut out with a thick white sticker outline, slightly tilted and overlapping, with no tiles and no hangers. In these mockups the drawn garments stand in for her photos. The prototype's `OutfitFlatLayView` is the starting point.
3. **Saved Looks has two tabs.** Looks shows every saved look as its bundle, which works without image credits. Pictures holds only saved try-on pictures, each linked to its look.
4. **No avatar, no portrait, no faces in the room or Profile.** A small wooden sign on the bedroom wall shows her first name as live text. Profile has a "Name on your sign" row. Owner-approved exception, 7 October: simulated try-on picture placeholders and the Profile reference-photo sheet show a generic illustrated person to explain the intended picture; it is not Lily and its clothes deliberately do not match the look.
5. **Clothes are always shown as clothes.** The only image of her wearing clothes is an optional generated try-on picture, made per look from the results screen ("Try it on").
6. **The first tab is "Home".** The desk laptop is the Style Me action.
7. **Home has no Ask stylist card and no On Me toggle.** Ask stylist and Try it on live on the Style Me results. The SwiftUI prototype still has the On Me toggle on its Style Me form, so moving it is a change to make there.
8. **Closet:** the wardrobe is a small fixed illustration that only says where you are. Under it are a search field, the filter chips, Suitcases and Laundry, then the grid of her real photos.
9. **Suitcases:** three favourites in the hall scene and at the top of the list, then "See all" for the rest (`screens/suitcases.html`).
10. **Maya,** her apricot toy poodle, sleeps on the home rug with slowly rising z's. Decoration only, not tappable, and the z's stay still under Reduce Motion. Drawn from the owner's own illustration.
11. **Large text:** the room shrinks to a banner and the controls become large rows (`screens/home-ax.html`).
12. **iPad:** use landscape space throughout. Home is a wide room with bottom navigation (owner update, 7 October). Closet, Results and Saved Looks use a sidebar and wide browsing areas, with details beside browsing where relevant. Do not center a phone composition in a tablet frame.

## Screens

The full list, with every version and its URL parameters, is in `js/registry.js`, which the gallery reads. All screens now use the soft style. In short:

| Journey | Screens |
|---|---|
| Home | `home.html` (weather windows: rain, sun, cloudy, snow, night; hamper states), `home-tour.html` (four-step quick tour), `home-ax.html`, `home-landscape.html`, `ipad-home.html`, `ipad-home-portrait.html` |
| Style Me | `styleme.html` (request and option sheets), `results.html` (Your looks: Current/Earlier, Shuffle, partial, insufficient, generating, failed, offline), `swap.html`, `editor.html`, `ipad-results.html` |
| Saved Looks | `saved.html` (Looks/Pictures, search, empty, favourites proposal), `look.html`, `picture.html`, `ipad-saved.html` |
| Closet | `closet.html`, `garment.html`, `garment-edit.html` (photo or words, simulated cleanup and review), `laundry.html`, `suitcases.html`, `suitcase.html`, `ipad-closet.html` |
| Profile and help | `settings.html`, `laundry-off.html`, `fit.html`, `access.html`, `paywall.html`, `packs.html`, `help.html`, `feedback.html`, `privacy.html`, `developer.html` |
| Stylists | `chat.html`, `export.html` |
| Shopping (open question) | `findone.html`, `purchase.html`, `handoff.html`, `products.html` |
| First run | `onboarding.html` |

Proposals that aren't decided yet are marked on the screen as options (for example the pictures-left hint, Favorites and collections, Find One placement, where saved products live).

The screens before R5 are kept in `archive/screens-2026-10-06/`.

## Tours for every screen, 7 October 2026

Jose asked to extend the approved Home tour to the remaining screens. All **37 other registered screens** now have a separate `screens/<screen>-tour.html` copy, covering **102 short tips**, including large-text Home, sideways iPhone and all iPad layouts. These are guides to each screen's default layout, not every error state or option sheet. Original pages are preserved; the only original changed in this task is Profile's existing App tours sheet, whose placeholder buttons now open real tour copies. Its main list stays short, with the remaining guides under **More screen tours**. The sheet scrolls on small frames.

The gallery's **Quick tours** group registers every new guide and each tip as a reviewable version, with the usual shared notes box. Profile and the new guides are R6. Existing screen ids and review-note keys are preserved.

`js/screen-tours.js` owns the simple wording and target selectors. `js/screen-tour.js` supplies the shared dialog, focus handling, Skip / Escape, Next and final **Got it**. `css/screen-tour.css` adapts the approved Home card and spotlight styles from `css/home-tour.css`. Positions follow the actual controls; long screens scroll inside a temporary viewport so tips and fixed bottom navigation remain aligned. Closing removes the viewport, restores the page and restores background controls. `?tip=N` opens a specific tip without colliding with the screen's own `?step=` flow parameters; `?tour=off` shows the normal page. Home keeps its approved four-step implementation and `?step=1..4` links.

Verification: rendered and inspected all 102 new tips with `tools/shot.sh`, at 390 × 844 for phone, 844 × 390 sideways, 1194 × 834 iPad and 834 × 1194 upright iPad. Renders are in `/private/tmp/screen-tour-renders/`, outside project snapshots. Browser checks exercised all 102 steps and completion on all 37 guides: no card/spotlight overlap, no clipped cards, Next focused on every step, and clean removal of overlays/inert state. Copy-preservation checks confirmed all 37 copies contain the complete source page plus tour imports. Native first-use tracking, the tips preference's automatic behavior and real-app acceptance remain future work. The owner accepted the tours into master PRD Section 7.8 / FR-73 / AC-103 on 7 October 2026. No commit was made.

## Home quick tour mockup, 7 October 2026

`screens/home-tour.html` is a separate copy of Home with the approved plum dim, soft spotlight and frosted coach marks. `home.html` is unchanged. The tour covers Style Me, Closet, the suitcase source and the name sign. It opens on load; `?step=1` through `?step=4` select a step, and `?tour=off` shows normal Home. Next advances in place; Skip, Escape and Start styling remove the overlay. Background controls resume working when it closes. Focus moves to Next on each step and remains within the dialog; reduced motion disables transitions.

Registered as `home-tour` in `js/registry.js`, with all four steps, the closed tour and a compact iPad view. CSS and tour behavior live in `css/home-tour.css` and `js/home-tour.js`. Review renders are outside `snapshots/`, in `/private/tmp/home-tour-renders/step-1.png` through `step-4.png`; the gallery uses its existing live-preview fallback. The profile replay entry is now wired to the tour copies (see Tours for every screen above). Real first-launch tracking remains future implementation work. The native app is unchanged; the owner subsequently approved the tour requirement in master PRD Section 7.8.

Verification: all four 390 × 844 step renders were inspected and two tails were aligned to their object centers. A 507 × 834 reduced-motion render keeps the tour aligned with the centered room stage. Browser checks passed for Next through all four steps, focus on each Next button, Start styling, Skip, Escape, `?tour=off`, restored Home links, and the original weather sheet after closing. Syntax checks passed. No commit was made.

## What is in the folder

- `screens/`: one HTML file per screen (390 x 844 phone, also checked at 507 x 834 for iPad Split View; 1194 x 834 iPad). Pages starting with `_` are art check sheets and aren't published.
- `art/`: hand-drawn SVG furniture and props, one SVG unit per point at phone size. Some files are no longer used by any screen.
- `js/garments.js`: drawings of the 21 fixture garments, standing in for her photos. `js/icons.js`: line icons in the SF Symbols manner. `js/theme.js` (dark, large text, reduced motion), `js/mock-state.js` (choices kept for the session), `js/registry.js` (screens and versions). `js/avatar.js` is left over from the dropped avatar and no screen loads it.
- `css/room.css` (tokens and shared pieces), `css/soft.css` (the approved soft rules) and `css/dark.css` (dark appearance).
- `index.html`, `review.html`, `summary.html`, `js/review.js`, `css/review.css`: the gallery, the one-screen review page with the notes box, and the notes summary with export. `site-data.json` describes the notes table for here.now.
- `ART_DIRECTION.md`: the style contract the illustrations were drawn to (palette, outline rules, scale), with the revision notes. Revisions 2 and 3 there override its earlier avatar sections.
- `ref/owner-reference-home.png`: the owner's picture that started the direction.
- `tools/shot.sh`: renders a screen (with its URL parameters) to PNG at an exact size. `tools/build-site.sh`: builds the publishable `site/` folder. `tools/pull-notes.sh`: pulls every review note from the live site into `feedback/notes-<date>.md` (grouped by screen, with the file and review link for each version) and a raw `.json` copy.
- `snapshots/`: PNGs of every screen version and the older art sheets.
- `archive/`: work kept for reuse even though the app won't use it.
  - `archive/avatar/attempt-a`, `attempt-b`, `attempt-c`: the three full-body avatar attempts (each folder has its own `avatar.js`, `hero.html` and `sheet.html`). Attempt a won and became `js/avatar.js`, which still contains the full-body, back and portrait views, all six portrait presets and the slim, medium and round face shapes.
  - `archive/avatar/final/`: hero and option sheet pages for the final avatar.
  - `archive/renders/`: final renders from every round: avatar and portrait sheets, the earlier screen versions (dressing-room results, full-body saved looks, onboarding avatar step), furniture kits, Maya's drafts, before/after comparisons and the gallery. The first-round flat mockup was rejected and is not kept.
  - The oval portrait frame SVG was deleted when the portrait was dropped; `archive/renders/portrait-presets-sheet.png` still shows it.

## Notes for the SwiftUI build

- **Art:** the SVGs can become PDF or SVG assets in the asset catalogue, or be redrawn as SwiftUI shapes. The small Closet wardrobe should be redrawn at its small size; here it is the large one scaled down, so its outlines are thinner than the rest. Maya's SVG is heavy (lots of fur detail) and should be simplified or replaced with the owner's original image.
- **Labels stay live text** over the art, so Dynamic Type, VoiceOver and dark mode keep working. The large-text layout is required, not optional.
- **Cutouts:** the sticker look depends on clean garment cutouts. iOS can lift a subject from a photo on the device, so nothing needs uploading. Pieces without a clean cutout can fall back to a rounded photo tile.
- **PRD:** several of these decisions change behaviour the PRD describes (On Me on the Style Me form, results presentation, Saved Looks structure). They would need an amendment proposal; the PRD itself stays as it is.

## Publishing the review site

1. Run `tools/build-site.sh`. It copies only what the review needs into `site/` (no archive, reference images, tools, notes or art check sheets) and puts the notes table description at `site/.herenow/data.json`.
2. Publish `site/` from this folder, not from inside it, so the local publish record isn't uploaded. Updates go to the same site, and notes already saved are kept.
3. Notes are open to read and add for anyone with the link. Changing or deleting them needs the owner's key, from the here.now dashboard or API.


## Lily's notes: pull, sign off, run

Two separate commands from the owner, and nothing changes in the mockups between them.

**"Pull Lily notes"** means pull and sort only. Run `tools/pull-notes.sh`, then write `feedback/signoff-<date>.md`. Every "What I'd change" request becomes one numbered item (L1, L2 and so on) with:

- the screen, version and review link, and her words quoted exactly
- the proposed fix, written to do what she asked rather than a reinterpretation of it
- a type: **UI** (a change to the HTML mockups only) or **Needs a talk** (it would need a backend, a service, a new data flow or an architecture change, or it reopens one of the open product choices). For a Needs a talk item, the sheet also suggests a simpler way to get her what she wants, if there is one.
- a decision line for the owner: `Decision: [ ] Approve  [ ] No  Notes:`

Every item needs the owner's sign-off, UI ones included. The owner either ticks the boxes in the sheet or replies in chat, one by one or in bulk:

- one by one: "approve L1, L3; no on L2; L4 make it smaller instead"
- in bulk: "approve all", "approve all UI", "approve all except L2 and L5"

A bulk approval never covers a Needs a talk item. Those still need an agreed approach first, unless the owner names the item.

**"Run Lily notes"** means make only the approved items, following the owner's notes on each. Nothing else gets changed. After that, re-render the changed screens, bump `rev` on those screens in `js/registry.js` (so her old notes show as an earlier revision), rebuild and republish to the same slug, and mark each item in the sheet as done, with what changed. Items marked No, or with no decision, are left alone. Needs a talk items are never built until the owner and Claude have agreed on an approach.
