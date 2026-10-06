# Room direction mockups

Static HTML mockups of the "home as rooms" direction for My Petite Style, made on 5 and 6 October 2026. They are a design reference for bringing the new look into the SwiftUI prototype (`prototypes/LilyStyleMockup`). None of this is in the app yet, and nothing here changes the PRD.

All data is fictional and matches the prototype's demo fixtures. Prices are sample values. Try-on pictures are simulated placeholders.

## How to view

The gallery and the comparison page load the screens in iframes, so serve the folder rather than opening the files directly:

```bash
python3 -m http.server 8766 --directory prototypes/RoomDirectionMockups
```

Then open `http://localhost:8766/index.html` (every screen) or `http://localhost:8766/soft-compare.html` (current style next to the softer style). PNG snapshots of every screen are in `snapshots/` if you just want to look.

## Decisions to carry into the app

These are the owner's decisions from the review rounds. Where a screen in this folder and this list disagree, this list wins.

1. **Soft, no-box style (approved).** No outlines on cards, tiles, rows, chips or label plates. Separate items with space, soft tints and shadows that fall only below. Items rest on the background. Buttons are gently rounded and the selected chip is a solid plum pill. The person the app is for is autistic and finds boxy design uncomfortable. The reference screen is `screens/results-flatlay.html`; the rules are in `css/soft.css`.
2. **Looks are sticker bundles.** A look is shown as her real garment photos, cut out with a thick white sticker outline, slightly tilted and overlapping, with no tiles and no hangers. In these mockups the drawn garments stand in for her photos. The prototype's `OutfitFlatLayView` is the starting point.
3. **Saved Looks has two tabs.** Looks shows every saved look as its bundle, which works without image credits. Pictures holds only saved try-on pictures, each linked to its look.
4. **No avatar, no portrait, no faces.** A small wooden sign on the bedroom wall shows her first name as live text. Profile has a "Name on your sign" row.
5. **Clothes are always shown as clothes.** The only image of her wearing clothes is an optional generated try-on picture, made per look from the results screen ("Try it on").
6. **The first tab is "Home".** The desk laptop is the Style Me action.
7. **Home has no Ask stylist card and no On Me toggle.** Ask stylist and Try it on live on the Style Me results. The SwiftUI prototype still has the On Me toggle on its Style Me form, so moving it is a change to make there.
8. **Closet:** the wardrobe is a small fixed illustration that only says where you are. Under it are a search field, the filter chips, Suitcases and Laundry, then the grid of her real photos.
9. **Suitcases:** three favourites in the hall scene and at the top of the list, then "See all" for the rest. Not mocked; settle it in the real build.
10. **Maya,** her apricot toy poodle, sleeps on the home rug with slowly rising z's. Decoration only, not tappable, and the z's stay still under Reduce Motion. Drawn from the owner's own illustration.
11. **Large text:** the room shrinks to a banner and the controls become large rows (`screens/home-ax.html`, soft version `home-ax-soft.html`).
12. **iPad:** a sidebar, the room drawn wide, and results or details in a side panel. Not a stretched phone screen.

## Screens

| Screen | Current style | Softer style |
|---|---|---|
| Home (bedroom) | `home.html` | (apply soft rules) |
| Home at largest text size | `home-ax.html` | `home-ax-soft.html` |
| Closet | `closet.html` | `closet-soft.html` |
| Garment detail | `garment.html` | |
| Suitcases | `suitcases.html` | |
| Laundry | `laundry.html` | `laundry-soft.html` |
| Style Me results | `results.html` (valet stand) | `results-flatlay.html` (approved) |
| Swap a piece | `swap.html` | |
| Saved Looks | `saved.html` | `saved-flatlay.html` (approved tabs) |
| Look detail | `look.html` | |
| Profile | `settings.html` | `settings-soft.html` |
| Styling access | `access.html` | `access-soft.html` |
| Paywall | `paywall.html` | |
| Onboarding | `onboarding.html` | |
| Ask stylist | `chat.html` | |
| iPad home, iPad closet | `ipad-home.html`, `ipad-closet.html` | |

Screens without a soft version were built before the soft style was approved; apply `css/soft.css` rules when bringing them over.

## What is in the folder

- `screens/`: one HTML file per screen (390 x 844 phone, 1194 x 834 iPad). Pages starting with `_` are art check sheets.
- `art/`: hand-drawn SVG furniture and props, one SVG unit per point at phone size. Some files are no longer used by any screen.
- `js/garments.js`: drawings of the 21 fixture garments, standing in for her photos. `js/icons.js`: line icons in the SF Symbols manner. `js/avatar.js` is left over from the dropped avatar; a few pages still load it, but nothing uses it.
- `css/room.css` (tokens and shared pieces) and `css/soft.css` (the approved soft rules).
- `ART_DIRECTION.md`: the style contract the illustrations were drawn to (palette, outline rules, scale), with the revision notes. Revisions 2 and 3 there override its earlier avatar sections.
- `ref/owner-reference-home.png`: the owner's picture that started the direction.
- `tools/shot.sh`: renders a screen to PNG with headless Chrome.
- `snapshots/`: PNGs of every screen and the art sheets.
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
