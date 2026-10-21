# Room direction and Lily's review: PRD amendment

**Approved for Stage A on 13 October 2026.** Jose authorized all of Stage A (Phases 0b to 18 in [SWIFT_BUILD_PLAN.md](SWIFT_BUILD_PLAN.md)) to go ahead without stopping at checkpoints, so this amendment is the working spec for the native app now. He can still edit it. If he does, his edit wins and the phases that already used the old text get a follow-up.

This file amends [Nifty_Outfit_Nook_PRD_v2.md](Nifty_Outfit_Nook_PRD_v2.md), the master PRD. It is not yet merged into the master's body text. Until it is, **where this amendment and the master PRD disagree, this amendment wins.** Everything the amendment doesn't mention stays as the master says, including security, cost protection, persistence, consent, image gates and deletion rules.

Section numbers below refer to the master PRD as of 13 October 2026.

## Sources

- The decisions list in [the mockup README](prototypes/RoomDirectionMockups/README.md) ("Decisions to carry into the app") and the owner decisions in [NEXT_SESSION.md](prototypes/RoomDirectionMockups/NEXT_SESSION.md) (Home navigation, laundry, desk drawers).
- Lily's sign-off sheet, [feedback/signoff-2026-10-13.md](prototypes/RoomDirectionMockups/feedback/signoff-2026-10-13.md), with Jose's decision on every item and Lily's showcase picks (warm neutral, Preferences, "Perfect." on the new results).
- The HTML mockups in `prototypes/RoomDirectionMockups/screens/` are the visual reference. They are frozen and were **not** updated for Lily's review. Where a mockup and this amendment differ, this amendment wins. `screens/results-versions.html` is the one mockup that shows the new results layout.

## How to use the IDs

- **RD-nn** is a room-direction change. **LR-nn** is one of Lily's review items, numbered to match her sheet (LR-05a is item L5a).
- Each acceptance check is numbered under its change (RD-01.1, LR-07.3). Phase PRs and tests cite these IDs.
- The IDs are stable. If Jose changes an item, its ID stays and the text changes. Retired items keep their ID with a note.

## Summary

| ID | Change | Master PRD sections touched |
|---|---|---|
| RD-01 | Home is the first tab, and the room is the home screen | §7 Home / Style Me row, §7.1 Applying the theme, §7.2, §7.5 |
| RD-02 | The desk laptop opens Style Me, with Comfort, Color and Preferences on it | §5.1, §7 Home / Style Me row, FR-05, FR-48 |
| RD-03 | No avatar; her first name on a wooden sign | §7 Profile row |
| RD-04 | Clothes are always shown as clothes | FR-08, §9.2 |
| RD-05 | Soft, no-box style | §7.1 Typography and layout, Applying the theme |
| RD-06 | Try it on and Ask stylist move to results | §5.1, §7 Home / Style Me and Results rows, §9.2.1, FR-08, FR-14 |
| RD-07 | Looks are sticker bundles | FR-08, FR-20, §7 Results row |
| RD-08 | Saved Looks has Looks and Pictures tabs, with search on both | §7 Saved row, §7.5, FR-13, FR-49 |
| RD-09 | Three favourite suitcases plus See all | §7.7, §7 Wardrobe row |
| RD-10 | Desk drawers: Help, Send feedback, Privacy and terms | §7 Help, Feedback, Settings rows |
| RD-11 | Laundry tracking is opt-in, with a hamper on Home | §7.3, FR-34, FR-64, FR-65 |
| RD-12 | Maya the poodle, decoration only | new |
| RD-13 | Closet layout | §7 Wardrobe row |
| LR-02 | Warm neutral palette | §7.1 tokens, §7.8 tour colours |
| LR-03 | "Preferences" replaces "Mode" | §5.1, §7 Home / Style Me row, §8.1 |
| LR-04 | Weather row with explanation and a sheet | FR-04, FR-16, §11.5 |
| LR-05a | One outfit in three versions, plus Try a different outfit | FR-06, §5.1 STYLIST, §5.2, §7 Results row, §7.1, §8 |
| LR-05b | Something new follows Preferences; Find one sits on its new piece | FR-06, FR-12, §8.1, §13 |
| LR-06 | "Saved" tab instead of Earlier; no Shuffle | §8.2, §11.11, FR-58 |
| LR-07 | Swap explains its picks, Show 3 more, See all, Find one | §7 Item swap sheet row, FR-09, §8 provider contract |
| LR-08 | Swap a piece handles every piece change; the editor is only Make your own look | FR-32, FR-09, §7.3, §7 Saved row |
| LR-09 | Piece and colour filters in Saved Looks and Closet | §7.5, FR-39, FR-51 |
| LR-10 | Last worn, a recent-wear note and a repeat setting | FR-39, §8.1, §8.2, §7.3 |
| LR-11 | Suitcase icon, filter, names on detail, search by suitcase | §7.7, §7 Wardrobe row |
| LR-12 | "Thinking of buying?" | §13, FR-37, §9.2 |
| LR-13 | "Add a piece that fits you well" | §10.1, §7 Profile row |
| LR-16 | Remove from closet sheet | §7.4, FR-38, FR-63 |
| LR-17 | "+ Add a suitcase" always visible | §7.7 |
| LR-18 | Fit profile versus Comfort wording | §8.3, FR-05 |

Not changed: LR-01 (later), LR-14 and LR-19 (no), LR-15 (no change). See the end of this file.

---

## Room direction

### RD-01. Home is the first tab, and the room is the home screen

**Before.** §7's Home / Style Me row describes Home as the styling form itself (affirmation, source selector, occasion, weather, starting item, comfort, colour, mode, Style Me). §7.1 "Applying the theme" says Home has "one prominent plum Style Me button". §7.2 gives wide iPad a sidebar with Style Me, Wardrobe, Saved and Feedback. §7.5 keeps "the primary Style Me / Closet / Saved navigation".

**Now.**
- The tabs are **Home, Closet, Saved Looks**. Profile opens from the name sign (RD-03) and from a top-right icon. Feedback is not a tab (RD-10).
- Home is an illustrated bedroom. Its objects are the controls, each with a small live-text plate:
  - the desk laptop opens Style Me (RD-02);
  - the wardrobe opens Closet (the whole wardrobe is the link);
  - a suitcase stands where the clothes rack was. It carries the source plate ("Source · Jose's house") and the piece count, and opens Suitcases, where she picks the source;
  - the hamper opens Laundry (RD-11);
  - the three desk drawers open Help, Send feedback, and Privacy and terms (RD-10);
  - the name sign opens Profile (RD-03).
- The starting piece is no longer picked on Home. She picks it from a garment's "Style with this" in Closet.
- The window matches the current weather: rain, sun, cloudy, snow, and night after dark.
- At accessibility text sizes the room shrinks to a banner and the controls become large rows (`screens/home-ax.html`).
- On iPad the room is a wide scene with bottom tabs (owner update, 7 October). Closet, results and Saved Looks use sidebars and wide grids. A phone layout is never centred in a tablet frame. This replaces §7.2's iPad sidebar list for Home; §7.2's other rules (no state loss on resize, no AI request on rotation, keyboard and pointer support) stay.
- The affirmation (FR-02) and every Style Me input still exist. They moved to the Style Me sheet (RD-02).

**Acceptance.**
- RD-01.1 The app opens on Home with three tabs labelled Home, Closet, Saved Looks.
- RD-01.2 Tapping the laptop, wardrobe, suitcase, hamper, each drawer and the name sign opens Style Me, Closet, Suitcases, Laundry (or the laundry-off sheet), Help, Send feedback, Privacy and terms, and Profile. Each object is one VoiceOver element with a label that names its destination.
- RD-01.3 The suitcase plate shows the current source name and piece count, and changes when the source changes.
- RD-01.4 The window shows each weather state from the weather fixtures, and the night window after dark.
- RD-01.5 At the largest accessibility text size Home shows the banner and row layout, with no clipped labels.
- RD-01.6 On iPad in both orientations Home is the wide room with bottom tabs. Rotating or resizing doesn't lose state or start a request.

### RD-02. The desk laptop opens Style Me

**Before.** §5.1 and §7's Home / Style Me row put the source, occasion, weather, starting item, comfort, colour and mode on Home, with Style Me as a button there. The old prototype kept Comfort, Color and Mode in a "More options" sheet.

**Now.**
- Tapping the laptop never styles straight away. It opens one calm Style Me screen: the request summary (source, occasion, starting piece), the Weather row (LR-04), Comfort, Color and Preferences (LR-03), each showing its current value, and one primary **Style me** button that sends the request and opens Your looks.
- "More options" is gone. Its contents live on this screen because this is the screen that uses them.
- The defaults are good enough that she can just tap Style me.
- Request rules in FR-05, FR-48 and §8.3 don't change: Comfort and Color apply to this request only.

**Acceptance.**
- RD-02.1 Opening Style Me from the laptop dispatches no request. Only the Style me button does.
- RD-02.2 Each row shows its current value and opens its own small sheet. Closing a sheet keeps the other choices.
- RD-02.3 With all defaults, one tap on Style me produces results.
- RD-02.4 Comfort and Color reset to their defaults for the next new request (FR-05).

### RD-03. No avatar; her name on a sign

**Before.** The master PRD has no avatar requirement, but the earlier mockups and prototype had a full-body avatar and portrait. §7's Profile row lists the optional On Me reference photo.

**Now.**
- No avatar, portrait or face anywhere in the room or in Profile.
- A small wooden sign on the bedroom wall shows her first name as live text. Profile has a **Name on your sign** row.
- Owner-approved exception (7 October): simulated try-on picture placeholders and the Profile try-on photo sheet show a generic illustrated person to explain what the picture will be. It is not Lily, and its clothes deliberately don't match the look.

**Acceptance.**
- RD-03.1 Changing "Name on your sign" updates the sign right away and after relaunch.
- RD-03.2 An empty name shows the sign with a neutral fallback, never a blank plate.
- RD-03.3 The sign text scales with Dynamic Type (or moves to the large-text rows) and is read by VoiceOver.
- RD-03.4 No screen outside try-on placeholders shows a person.

### RD-04. Clothes are always shown as clothes

**Before.** FR-08 and §9.2 make On Me the preferred, opt-in result mode, with boards as the fallback.

**Now.** Clothes always appear as clothes: her garment photos, cut out where possible. The only image of her wearing clothes is an optional simulated try-on picture made per look from results (RD-06). §9.2's gates, consent, cost and history rules still apply to that picture.

**Acceptance.**
- RD-04.1 Results, Saved Looks (Looks tab), look detail, Closet and swap show garments only.
- RD-04.2 Every try-on picture is labelled Simulated.

### RD-05. Soft, no-box style

**Before.** §7.1 asks for "quiet surfaces", 16 pt card padding and corners, and a divider token used for "card boundaries".

**Now.**
- No outlines on cards, tiles, rows, chips or label plates. Items are separated by space, soft tints and shadows that fall only below. Items rest on the background.
- Buttons are gently rounded. The selected chip is a solid accent pill (espresso in the warm palette, LR-02).
- Dividers, where needed, are soft fades, not boxes.
- Reason: Lily is autistic and finds boxy design uncomfortable. The reference screen is `screens/results.html`; the rules are in `css/soft.css`.
- §7.1's contrast rules still apply. A control that needs a visible boundary for 3:1 contrast gets it from its fill or shadow, not an outline.

**Acceptance.**
- RD-05.1 The component catalog (Phase 2b) shows no stroked borders on cards, rows, tiles, chips or plates in light, dark and largest text.
- RD-05.2 Snapshot tests cover the catalog in those three settings.
- RD-05.3 Interactive controls still meet §7.1's 3:1 boundary contrast and 44 pt targets.

### RD-06. Try it on and Ask stylist move to results

**Before.** §5.1 and §7's Home / Style Me row have an "On Me state" on the request form. §9.2.1 step 3 lets one Style Me in On Me mode request up to three previews. FR-14 makes Ask Stylist a secondary surface without saying where.

**Now.**
- Home and the Style Me sheet have no On Me toggle and no Ask stylist card.
- Results have four equal buttons in a 2 × 2 grid: **Save look**, **Try it on**, **Swap a piece**, **Ask stylist**, with one fine-print line under them: "Try-on pictures are simulated."
- Try it on is per look. It makes at most one picture for the selected version and spends one picture only when she taps it. §9.2's gates, permission, reuse-before-generate (FR-59) and history rules all still apply. Style Me itself never generates pictures.
- Ask stylist stays a secondary surface (FR-14), reached from results.
- The try-on photo lives in Profile ("Your try-on photo", approved 7 October), as in §9.2.1 step 1.
- In Stage A, Try it on uses the simulated placeholder only (FR-56). Real pictures wait for Phase 33.

**Acceptance.**
- RD-06.1 No request form has an On Me control.
- RD-06.2 Opening results, switching versions or swapping a piece starts no picture job. Only Try it on does, for one look.
- RD-06.3 The four buttons are the same size at every text size, and stack rather than clip at the largest sizes.
- RD-06.4 A simulated picture is labelled Simulated and links back to its look.

### RD-07. Looks are sticker bundles

**Before.** FR-08 and FR-20 talk about "boards" and "outfit cards"; §7's Results row asks for "visual directions" and garment chips.

**Now.**
- A look is shown as her garment photos, cut out, each with a thick white sticker outline, slightly tilted and overlapping. No tiles, no hangers.
- Pieces without a clean cutout fall back to a rounded photo tile with the same outline.
- The bundle is the same view everywhere a look appears: results, Saved Looks, look detail, swap.
- Each bundle has a text list of its pieces underneath, so the look reads without the picture.

**Acceptance.**
- RD-07.1 Bundles of 2 to 6 pieces lay out without clipping at phone and iPad sizes.
- RD-07.2 A piece with no cutout shows the tile fallback.
- RD-07.3 VoiceOver reads the look as one element that lists its pieces, with each piece also reachable in the list below.
- RD-07.4 With Reduce Motion on, bundles don't animate their tilt.

### RD-08. Saved Looks: Looks and Pictures tabs

**Before.** §7's Saved row and FR-13 / FR-49 describe saved outfits, Favorites, collections and preview history. §7.5 offers All Looks, Preview History, Favorites and collections as filters inside Saved.

**Now.**
- Saved Looks has two tabs. **Looks** shows every saved look as its bundle and works with no picture allowance. **Pictures** holds only saved try-on pictures, each linked to its look.
- A search field ("Search your looks") sits under the tab switch on both tabs. It matches look name, occasion and piece names; on Pictures it searches the look each picture came from. LR-09 adds filters.
- "+ Make your own" on Saved Looks opens the look builder (LR-08).
- Favorites and collections from FR-13 / FR-49 are not in Stage A. They stay in the master PRD for later; the mockups marked them as a proposal.
- §7.5's retained-preview history rules don't change. Every delivered picture is still kept and searchable.

**Acceptance.**
- RD-08.1 The Looks tab shows saved looks with no picture allowance and offline.
- RD-08.2 Each picture opens its look, and the look shows its pictures.
- RD-08.3 Search on each tab finds matches by look name, occasion and piece name, and shows an empty state with Clear when nothing matches.
- RD-08.4 The empty Saved Looks screen explains how to save a look.

### RD-09. Three favourite suitcases plus See all

**Before.** §7.7 requires multiple named suitcases with a source selector and "+ Add Suitcase", but doesn't say how many show at once.

**Now.**
- Suitcases shows her three favourites in the hall scene and at the top of the list, then "See all" for the rest: "Your 3 favourites · See all 5".
- Favourites are the three most recently used suitcases. There is no star, to avoid one more idea to learn.
- With three or fewer suitcases there is no See all.
- "+ Add a suitcase" is always visible (LR-17).
- §7.7's rules on membership, strict suitcase styling and source fallback don't change.

**Acceptance.**
- RD-09.1 With 0, 1, 2, 3 and 5 suitcases the screen shows the right number of favourites and shows See all only above three.
- RD-09.2 Using a suitcase as the source moves it into the favourites.
- RD-09.3 See all lists every suitcase, including archived ones only under an explicit filter.

### RD-10. Desk drawers: Help, Send feedback, Privacy and terms

**Before.** §7's Help / What changed, Feedback and Settings / Privacy & Data rows reach these from Settings. §7.2 lists Feedback in the iPad sidebar.

**Now.**
- The three Home desk drawers are labelled **Help** (top), **Send feedback** (middle) and **Privacy and terms** (bottom). They are not used for laundry or styling options.
- Profile still lists Help, feedback, privacy and terms too.
- In the large-text layout the drawers become three rows.
- What Send feedback opens in Stage A is the private feedback form (§22). The public feedback board needs moderation (§22.1) and is not in Stage A.

**Acceptance.**
- RD-10.1 Each drawer opens its screen, and the same screens open from Profile.
- RD-10.2 Each drawer has a VoiceOver label naming its screen.

### RD-11. Laundry tracking is opt-in, with a hamper on Home

**Before.** §7.3 "Laundry controls and bulk cleaning", FR-34, FR-64 and FR-65 assume laundry tracking is always on: a Dirty filter, badges and cleaning flows.

**Now.**
- Profile has a **Track laundry** switch, **off by default**.
- **Off:** no Dirty chip, no Laundry entry in Closet, no laundry badges, and every owned, arrived, available piece counts for Style Me. Turning tracking off keeps existing Dirty marks stored, so they come back if she turns it on again.
- **On:** the master PRD's laundry behaviour applies unchanged (Dirty filter, Laundry screen, Mark clean with Undo, Style Me skips dirty pieces unless she allows one).
- A hamper stands on the Home floor:
  - on, with dirty pieces: a real control with the plate "Laundry · 2 to wash" and a subtle bulge of clothes above the rim; it opens Laundry;
  - on, all clean: "Laundry · all clean", closed or empty, no clothes showing;
  - off: faded and empty with the quiet plate "Laundry · Off". Tapping it opens a short sheet that explains tracking, with "Turn on" and a link to the Profile switch. It never nags.
- Wear today never changes laundry status (LR-10, matching §7.3).

**Acceptance.**
- RD-11.1 A fresh install has tracking off, and no Dirty chip, badge or Laundry entry appears anywhere.
- RD-11.2 With tracking off, a piece stored as Dirty is eligible for styling. Turning tracking on makes it Dirty again.
- RD-11.3 The hamper shows each of the three states and opens Laundry or the off sheet.
- RD-11.4 "Turn on" in the sheet turns tracking on and the hamper updates without relaunch.
- RD-11.5 With tracking on, the master PRD laundry checks apply as written.

### RD-12. Maya the poodle

**Before.** Not in the master PRD.

**Now.** Maya, her apricot toy poodle, sleeps curled on the Home rug with slowly rising z's. She is decoration only: not tappable, not a VoiceOver element. The z's stay still under Reduce Motion. On the smallest phones she can be dropped before any label shrinks. Lily's own pet (LR-01) is for later.

**Acceptance.**
- RD-12.1 Maya appears on Home and is hidden from VoiceOver.
- RD-12.2 With Reduce Motion on, the z's don't move.
- RD-12.3 Tapping Maya does nothing.

### RD-13. Closet layout

**Before.** §7's Wardrobe row lists Closet's contents without a layout.

**Now.** At the top, a small fixed wardrobe illustration that only says where you are. Under it: the search field, the filter chips (LR-09, LR-11), Suitcases, Laundry (only when tracking is on, RD-11), then the grid of her garment photos. "Recently deleted · N" sits at the bottom when there is anything in it (LR-16). Add a piece stays in Closet only.

**Acceptance.**
- RD-13.1 Closet shows these parts in this order with the empty, demo and large (2,000+) closets, and the grid stays smooth with the large one.
- RD-13.2 The empty closet explains how to add a piece.

---

## Lily's review, 13 October 2026

### LR-02. Warm neutral palette

**Before.** §7.1's token table: ivory background, deep plum primary action, dusty rose accent surface, and so on. §7.8 gives the tour a plum-tinted dim and plum tokens.

**Now.**
- The colour tokens come from the warm neutral palette Lily picked: cream, sand and taupe, with an espresso accent replacing plum. The source values are `html.palette-warm` in `prototypes/RoomDirectionMockups/css/palette.css` (for example wall `#F4EEE6`, accent `#4B3628`, accent soft `#EFE6DB`, ink `#2A211B`, soft ink `#6B5E54`, plate `#FFFDF9`).
- Garments keep their real colours. Only the room and the interface change.
- The room art gets properly recoloured in the warm palette. The mockups' preview filter is not used.
- The palette study only covers light appearance. Phase 2a defines the dark appearance from the same family (warm charcoal and espresso tones) and checks it against §7.1's contrast rules.
- The tour dim and card (§7.8) use the warm tokens instead of plum. Shapes, sizes and behaviour stay as §7.8 says.
- Success and error colours stay distinct from the accent and are never the only signal.

**Acceptance.**
- LR-02.1 No plum or pink token values remain in the design system.
- LR-02.2 Every text and control pairing meets §7.1's contrast minimums in light and dark.
- LR-02.3 Room art, tour overlay and components render in the warm palette in both appearances.

### LR-03. "Preferences" replaces "Mode"

**Before.** §5.1 and §7's Home / Style Me row use "Use Only My Wardrobe / Suggestions" and a separate "explicit new-piece exploration off by default". The prototype called this row Mode.

**Now.**
- The row is called **Preferences** everywhere: the Style Me screen, its sheet, tours and iPad.
- Its two values are **Mine + one idea** and **Only mine**.
  - Only mine is the master's strict Use Only My Wardrobe (FR-35).
  - Mine + one idea is closet-first with permission for one new-piece idea in the Something new version (LR-05b).
- Lily's default is **Mine + one idea** (Jose, L5b). This replaces "new-piece ideas off by default" (§5.1, §7, §8.1) for her.
- A suitcase source still forces strict styling (§7.7, §8.1). See LR-05b for what that means for Something new.
- Hypothetical ideas for an empty Main Closet (§8.1) don't change.

**Acceptance.**
- LR-03.1 The word "Mode" doesn't appear in the app.
- LR-03.2 The Preferences sheet offers exactly the two values and shows the current one on the Style Me row.
- LR-03.3 A fresh install defaults to Mine + one idea.
- LR-03.4 With Only mine, no result contains a piece she doesn't own.

### LR-04. Weather row, explanation and sheet

**Before.** FR-04 and §7's Home / Style Me row: weather is automatic and editable. §11.5 covers WeatherKit and manual overrides.

**Now.**
- The Style Me screen has a **Weather** row ("Weather · 58° and rain") with a short line under it: "Your looks are picked for today's weather."
- Tapping it opens a small sheet: **Use today's weather** (default), **I'll be indoors**, **Ignore the weather**. The choice applies to this request only, like Comfort.
- When the weather can't be read, the row says so and the sheet still works.
- Weather at a trip destination is later. It needs a place and dates plus WeatherKit (Phase 29).
- Stage A uses fixture weather behind the weather service protocol.

**Acceptance.**
- LR-04.1 The row shows the fixture temperature and condition, and the explanation line.
- LR-04.2 Each sheet choice is sent with the request, and the next new request starts on Use today's weather.
- LR-04.3 With weather unavailable, the row shows an honest message and styling still works.

### LR-05a. One outfit in three versions

**Before.** FR-06, §5.1 STYLIST and §5.2: three distinct directions, Safe/Simple, Stylish/Elevated owned, and another Elevated owned look or an explicit new-piece direction. §7's Results row and §7.1 "Applying the theme" describe three cards with lane labels. §8 and §12's OutfitGenerationResult assume three independent outfits.

**Now.**
- A styling result is **one base outfit in three versions**:
  - **Simple**: easy and safe;
  - **Dressed up**: the same outfit, a little classier. It keeps the base pieces and swaps one or two for dressier ones she owns;
  - **Something new**: the same outfit plus one piece she doesn't own (LR-05b), or another owned version with Only mine.
- Results show a one-line switch, **Simple · Dressed up · Something new**, with the description of the selected version under it ("Easy and safe", "The same outfit, a little classier", "The same outfit, plus one piece you don't have").
- Shared pieces stay visibly the same. In the piece list, a piece that matches Simple says "Same as Simple"; changed pieces are marked.
- Under the buttons, **Try a different outfit** asks for a new base. It is one styling request, the same cost as Style me, and says so ("uses 1 styling").
- Above the switch, a quiet line repeats the request: "Office · Main closet · 58° and rain".
- The master's partial and failure rules still apply, in version terms:
  - if only one or two versions are possible from verified inventory, show those and say why (PartialWardrobe);
  - if no valid outfit exists, InsufficientWardrobe;
  - a model failure is GenerationNotCompleted and never claims the closet is too small.
- Strict ownership, eligibility, suitcase scope and validation rules in §8 and §8.1 are unchanged. They apply to each version.
- The stylist response contract (§8) changes from three independent directions to one base plus versions. Each version records which pieces it shares with Simple.

**Acceptance.**
- LR-05a.1 A normal result has three versions. Dressed up and Something new share at least one piece with Simple.
- LR-05a.2 Switching versions dispatches nothing and keeps the scroll position.
- LR-05a.3 Shared and changed pieces are marked in text, not by colour alone.
- LR-05a.4 Try a different outfit sends exactly one request and replaces all three versions. The previous result stays in background history (LR-06).
- LR-05a.5 Partial, insufficient, generating, failed and offline states each show correctly with the mock stylist.
- LR-05a.6 With VoiceOver, the switch reads as three selectable options with the selected one announced.

### LR-05b. Something new follows Preferences

**Before.** FR-06 and §8.1: only an explicit new-piece choice allows an unowned piece, off by default. FR-12 and §13 make Find One an explicit request. Where shopping sits in the room design was an open question in NEXT_SESSION.md.

**Now.**
- With **Mine + one idea**, Something new adds one piece she doesn't own, tagged **"Not in your closet"**, with a small **Find one** link on that piece.
- With **Only mine**, Something new is another owned version.
- This settles the open question: shopping lives on Something new's new piece and at the end of swap options (LR-07). There is no general shop button.
- The new piece never counts as owned and never adds itself to a closet, suitcase or shopping list (FR-37).
- **Suitcase source (decision for Jose, see "Decisions made in drafting"):** the master keeps suitcase styling strict. So with a suitcase source, Something new is an owned version from the suitcase and has no unowned piece, whatever Preferences says. A short line says why.
- Find one opens the master's Find One flow (§13). In Stage A it opens a stub that says shopping comes later. The real flow is Phase 34.
- The stylist instructions change so the Something new version is built from the Simple base plus one new piece. Those instructions live in the private backend, not the app repo.

**Acceptance.**
- LR-05b.1 With Mine + one idea and Main Closet, Something new has exactly one piece tagged "Not in your closet" with Find one.
- LR-05b.2 With Only mine, or with a suitcase source, no version has an unowned piece.
- LR-05b.3 Saving a Something new look keeps the new piece tagged and doesn't make it owned.
- LR-05b.4 Find one starts no network request in Stage A.

### LR-06. "Saved" tab instead of Earlier; no Shuffle

**Before.** §8.2 and §11.11 present matching history as "From your history" with Use this look / Browse similar / New ideas, and FR-58 checks local history before paid inference. The prototype added Current/Earlier tabs and a Shuffle that drew from past results and saved looks (6 October decision in NEXT_SESSION.md, now replaced).

**Now.**
- Your looks has two tabs: **Today** (the current result) and **Saved**.
- Saved shows only looks she saved that fit the current source and occasion. It's free and sends no request.
- **Shuffle is removed.** The two ways to see something else are Saved (free) and Try a different outfit (one request).
- Unsaved past results are still kept in background history and in search, as §8.2, §11.11 and FR-57 require. They just aren't shown on this screen.
- FR-58's history check before paid inference still runs. If a revalidated earlier result is used, it appears as today's result with the label "From your history". Browse similar is dropped from this screen.

**Acceptance.**
- LR-06.1 The Saved tab lists only saved looks that match the current source and occasion, and opening it sends nothing.
- LR-06.2 The Saved tab has an empty state that explains how to save a look.
- LR-06.3 No Shuffle control exists.
- LR-06.4 An unsaved earlier result is not listed on the Saved tab. Saved Looks' Looks tab has a Saved | All switch (decided 21 October 2026, replacing a first version where typed search alone brought earlier results up under the saved ones). Saved lists only saved looks. All lists saved looks and unsaved earlier results in one list, each unsaved one tagged "Not saved" with a Save look button. Search and filters work the same way in both. On Saved, when they also match unsaved looks, one line at the end says "N more in All" and switches to All with them kept. The scope goes back to Saved each time she opens the screen.

### LR-07. Swap explains its picks; Show 3 more; See all; Find one

**Before.** §7's Item swap sheet row: the closest valid owned alternatives with colour and style filters, Already Own and explicit Find One. FR-09 covers real-item swaps. §8's provider contract has `suggestSwaps`.

**Now.**
- Swap a piece shows a line above the options: "Your tops that go with this look" (the piece type changes with the slot).
- Options are her own pieces from the current source that suit the occasion, weather and her fit, and go with the rest of the look. They are ranked on the phone with no request and no styling used.
- **Show 3 more** shows the next three.
- At the end: "That's every top in Jose's house" (the source name) and **See all tops**. Weaker matches there are marked "May not match".
- When Preferences is Mine + one idea, the end of the list has **"Not in your closet? Find one"**.
- An "Ask the stylist" link was discussed and not approved.
- Committing a swap changes one piece only and keeps the others (FR-09). Remove and Undo are in LR-08.
- **Public repo note:** on-phone ranking uses plain matching on stored facts (category, colour, occasion tags, weather fit, availability, source). The proprietary fit and styling rules stay in the private backend (SECURITY_STANDARD.md, app repo rules). If better ranking needs those rules, it becomes a server call later.

**Acceptance.**
- LR-07.1 Opening swap and tapping Show 3 more send no request and use no styling.
- LR-07.2 Options come only from eligible pieces in the current source.
- LR-07.3 At the end of the list the "That's every …" line and See all appear. See all marks weaker matches "May not match".
- LR-07.4 Find one appears at the end only with Mine + one idea.
- LR-07.5 With the large closet, Show 3 more responds without a visible stall.

### LR-08. Swap a piece for every change; the editor is only Make your own look

**Before.** FR-32 and §7.3 describe a manual outfit editor that creates or edits saved looks. §7's Saved row includes "manual editing". The prototype opened the editor from Your looks ("Edit").

**Now.**
- Changing a piece in any look, on results or saved, always uses **Swap a piece**. The Edit path from Your looks to the editor is removed.
- Swap gets **Remove this piece**. Removing or swapping shows an **Undo** toast.
- The editor becomes **Make your own look**, only for building a look from scratch. It opens from Saved Looks ("+ Make your own") and from a garment's "Style with this".
- Its tour starts "Build an outfit yourself, piece by piece."
- Looks are named when saved.
- FR-32's offline, free, no-AI rules and §7.3's draft and undo rules still apply to both swap and Make your own look.

**Acceptance.**
- LR-08.1 No path leads from results or a saved look to the editor.
- LR-08.2 Remove this piece and swap each offer Undo, and Undo restores the exact earlier look.
- LR-08.3 Make your own look opens from "+ Make your own" and from Style with this, works offline and saves a named look.
- LR-08.4 A half-built look survives relaunch as a draft (§7.3).

### LR-09. Piece and colour filters

**Before.** §7.5 lists facets (result type, category, colour, style, occasion and more) without a layout. FR-39 and FR-51 require local search.

**Now.**
- Saved Looks (both tabs) and Closet get the same filter rows under the search field:
  - piece chips: Tops, Bottoms, Dresses, Layers, Shoes, Bags;
  - named colour swatches.
- Filters combine with typed search and with each other. There's a **Clear** link.
- Empty state: "No saved looks with black bottoms" with **Clear filters**.
- Everything runs on the phone.

**Acceptance.**
- LR-09.1 Each chip and swatch filters correctly alone, combined with another, and with typed text, in both places.
- LR-09.2 Colour swatches have text names for VoiceOver and are not told apart by colour alone.
- LR-09.3 The empty state names the active filters, and Clear filters resets them.
- LR-09.4 Filtering the large closet stays smooth.

### LR-10. Last worn, a recent-wear note and a repeat setting

**Before.** FR-39 and §8.1: recommendation and save history reduce repetition; actual Worn is "quiet and optional". §7's Saved row has a quiet Worn action. §7.3 says marking Worn doesn't change laundry.

**Now.**
- A saved look has **Wear today**. It records today's date for the look and its pieces.
- **"Last worn 3 Oct"** shows on saved looks and on garment detail.
- Your looks shows a quiet note when the result matches a look worn recently: "You wore this last week".
- The stylist skips recently worn looks and avoids repeating main-piece combinations inside the repeat window. Single favourite pieces can still come back.
- Profile has **"Avoid repeating outfits for: 1 week (default) · 2 weeks · I don't mind"**.
- Wear today doesn't touch laundry status (option A). This matches §7.3.
- Worn stays optional. Saving or selecting a look is still not wear.

**Acceptance.**
- LR-10.1 Wear today sets Last worn on the look and its pieces, and Undo removes it.
- LR-10.2 With the default setting, a look worn 5 days ago is not offered again as a new result, and the recent-wear note shows when an earlier worn look is reused.
- LR-10.3 With "I don't mind", nothing is skipped for wear.
- LR-10.4 Wear today leaves Dirty status unchanged.
- LR-10.5 The mock stylist applies the window; the real rule lives on the backend.

### LR-11. Which suitcase is a piece in?

**Before.** §7.7 manages membership from the suitcase side. Garment detail lists suitcases, but it's easy to miss.

**Now.**
- In the Closet grid, a packed piece shows a tiny suitcase icon, with no text. VoiceOver reads the suitcase names.
- Closet has a **Suitcase** filter beside the LR-09 chips: In a suitcase · Not packed · each suitcase by name.
- Garment detail shows **"In suitcases: …"** near the title. Each name opens that suitcase.
- Closet search matches suitcase names.

**Acceptance.**
- LR-11.1 A piece in two suitcases shows one icon, and VoiceOver reads both names.
- LR-11.2 Each Suitcase filter value returns the right pieces, including with the large closet.
- LR-11.3 Searching a suitcase name returns its pieces.
- LR-11.4 Each name on garment detail opens that suitcase.

### LR-12. "Thinking of buying?"

**Before.** §13 covers Find One and purchase capture. FR-37 has a Wishlisted state. §9.2 gates try-on pictures. There's no way to check a piece she's considering that didn't come from Find One.

**Now.**
- A **"Thinking of buying?"** flow: she adds a piece she's considering (photo, screenshot, or from Find One) as a **Wishlist** piece.
- She gets a text **fit check** from her measurements and fit references, for example "Likely fits · may be long in the leg".
- Optionally, a simulated **Try it on** with her own clothes, labelled Simulated, with the line "Pictures show the style, not the exact fit."
- Built in two steps: the wishlist and fit check with the shopping phase (Phase 34); the picture only after try-on passes its gate (Phase 33).
- Added photos need clothing-only moderation before any cloud use.
- Wishlist pieces never count as owned (FR-37). The fit check is evidence-based and follows §13.8; it never invents certainty.

**Acceptance (Phase 34 and 33; not in Stage A).**
- LR-12.1 A wishlist piece is never offered as owned in any version, swap or suitcase.
- LR-12.2 The fit check names its evidence and its unknowns.
- LR-12.3 The picture is labelled Simulated with the fit line, and is made only on request.

### LR-13. "Add a piece that fits you well"

**Before.** §10.1 calls this an "optional reference": a brand, category and size she confirms fits well. The prototype called it "Add a fit reference".

**Now.**
- The action is **"Add a piece that fits you well"**, with the line "Pick something you own that fits just right. We'll use its brand and size to suggest sizes for you."
- First-time example: "For example: your favourite jeans or a blazer that fits perfectly."
- Added pieces read in plain words, for example "Old Navy jeans · 0 Petite · Fits well", with "Used for fit checks when you're thinking of buying." (ties to LR-12).
- The Fit tour uses the same wording.

**Acceptance.**
- LR-13.1 The words "fit reference" don't appear in the app.
- LR-13.2 An added piece reads as brand, size and fit in one line.
- LR-13.3 The example line shows only when she has none.

### LR-16. Remove from closet

**Before.** §7.4 and FR-38 / FR-63 define No longer own, Archive, Trash (30 days) and permanent deletion. The mockups didn't show them.

**Now.**
- Garment detail has a quiet **Remove from closet**. It opens a sheet with two choices, and both ask first:
  - **"I don't have it any more"**: the master's NoLongerOwned. The piece leaves Closet, suitcases and styling and stays in history. Saved looks show it as "No longer in your closet". An Undo toast follows.
  - **"Delete it"**: the master's Move to Trash, shown as **Recently deleted** for 30 days. Before confirming, it shows the saved looks it affects.
- Saved looks with a removed piece show it faded with **Swap it**.
- **"Recently deleted · N"** sits at the bottom of Closet.
- Archive is not on this sheet. It stays in the data model, with no Stage A screen.
- §7.4's purge, deletion-marker and history rules are unchanged.

**Acceptance.**
- LR-16.1 "I don't have it any more" removes the piece from Closet, suitcases and styling, keeps its looks, and Undo restores it.
- LR-16.2 "Delete it" lists affected saved looks first, then moves the piece to Recently deleted with its deadline.
- LR-16.3 Restoring from Recently deleted brings back the same piece and its links.
- LR-16.4 A saved look with a removed piece shows it faded with Swap it.

### LR-17. "+ Add a suitcase" always visible

**Before.** §7.7 requires "+ Add Suitcase" but doesn't say where.

**Now.** A clear **"+ Add a suitcase"** on every version of Suitcases: none, one, two, three favourites and more than three. She can start with none or one. Three is only how many show before See all.

**Acceptance.**
- LR-17.1 "+ Add a suitcase" is visible without scrolling with 0, 1, 2, 3 and 5 suitcases, at default text size.
- LR-17.2 Adding one with no suitcases works and shows it at once.

### LR-18. Fit profile versus Comfort

**Before.** §8.3 and FR-05 separate the permanent fit profile from today-only comfort, but the screens don't say so.

**Now.**
- Fit profile: the line **"Saved until you change it."**
- Style Me Comfort: the line **"Just for this outfit."**
- When they differ, Comfort shows "Today: fitted (you usually like relaxed)".
- The Fit tour uses the "Saved until you change it" wording.

**Acceptance.**
- LR-18.1 Both lines show in their places.
- LR-18.2 Choosing a Comfort that differs from the fit profile shows the "Today: … (you usually like …)" line, and the next new request starts back on the usual fit.

### Items not changing the PRD

Recorded so nobody raises them again without new information.

- **LR-01, her own pet: Later.** Last priority and not in the first version. Later it's mainly choosing pet and breed art. Maya stays (RD-12).
- **LR-14, rename "sponsored access": No.** That screen is mock-only and Lily won't see it in the real app. Public users still need a clear free-versus-paid explanation, handled in the subscription phase and Apple's rules.
- **LR-15, weather in Demo controls: No change.** It was praise. Demo controls are mock-only; the real window follows real weather (RD-01).
- **LR-19, charge for more than 100 pieces: No.** Pricing is Jose's decision. The master's FR-36 (no closet cap) stands.

---

## Data model notes

These extend §12. Phase 3 builds them as mock models; Stage B persists them.

- **Outfit:** a version kind (Simple, Dressed up, Something new) and a shared result or base ID, so the three versions of one result stay linked. Each piece records whether it matches Simple. Look name is set on save.
- **Wear record:** dates worn per look and per piece (optional, explicit). Last worn is derived from it.
- **Preferences:** piece mode (Mine + one idea or Only mine, default Mine + one idea), repeat window (1 week default, 2 weeks, I don't mind), Track laundry (off by default), name on sign.
- **Request context:** weather mode (today's weather, indoors, ignore), request-scoped like Comfort.
- **Suitcase:** last-used date, for favourites.
- **Wishlist piece and fit check:** use the master's Wishlisted ownership state and FitAssessment (Phase 34).
- **NoLongerOwned and Trash:** unchanged from §7.4; "Recently deleted" is the user-facing name for Trash.

## Which phases build what

From [SWIFT_BUILD_PLAN.md](SWIFT_BUILD_PLAN.md). A phase that touches an ID should cite it in its PR and tests.

| Phase | Builds |
|---|---|
| 1a Project skeleton | RD-01 (Home, Closet, Saved Looks tabs as placeholders) |
| 2a Design tokens | LR-02 (warm neutral light and dark), RD-05 tokens |
| 2b Components and catalog | RD-05 (no-box components, accent pill chips), LR-09 chip and swatch components |
| 3 Models and mock data | Data model notes above; LR-05a result shape, LR-10 wear records, RD-11 laundry preference, LR-03 preference values |
| 4 Home room, phone | RD-01, RD-03 (sign), RD-10 (drawers), RD-09 (suitcase object and plate) |
| 5a Home weather and life | RD-01 windows, RD-11 hamper states, RD-12 Maya |
| 5b Home variants | RD-01 large text and sideways phone, dark room art (LR-02) |
| 6 Closet browsing | RD-13, LR-09, LR-11 (icon, filter, search), LR-16 (Recently deleted row), RD-11 (Laundry entry only when on) |
| 7a Garment detail | LR-11 ("In suitcases"), LR-10 (Last worn), LR-16 (Remove from closet sheet) |
| 8b, 9 Stickers and bundles | RD-04, RD-07 |
| 10a Style Me request | RD-02, LR-03, LR-04, LR-18 (Comfort line) |
| 10b Style Me results | LR-05a, LR-05b, LR-06, RD-06 buttons, LR-10 (recent-wear note and mock repeat rule) |
| 11 Swap and editor | LR-07, LR-08 |
| 12a Saved Looks, Looks | RD-08, LR-09, LR-10 (Wear today, Last worn), LR-16 (faded piece with Swap it), LR-08 ("+ Make your own") |
| 12b Saved Looks, Pictures | RD-08 Pictures tab, RD-06 simulated picture |
| 13 Suitcases and Laundry | RD-09, LR-17, RD-11 |
| 14a Profile essentials | RD-03 (Name on your sign), LR-13, LR-18 (fit line), LR-10 (repeat setting), RD-06 (try-on photo sheet) |
| 14b Remaining settings | RD-11 (Track laundry switch), RD-10 screens |
| 15a, 15b iPad | RD-01 wide room, iPad layouts for every item above |
| 16a, 16b Tours | Tour copy for LR-08, LR-13, LR-18; tour colours from LR-02 |
| 27a Cloud stylist | LR-05a and LR-05b stylist contract, LR-10 repeat rule on the server |
| 29 Weather | LR-04 with real weather; trip destination weather later |
| 33 Try-on | RD-06 real pictures, LR-12 picture |
| 34 Find One | LR-05b and LR-07 Find one, LR-12 wishlist and fit check |

## Decisions made in drafting

Jose may want to look at these. Each one follows the master PRD where the sign-off sheet was silent.

1. **Something new with a suitcase source** (LR-05b): kept strict, so no unowned piece in a suitcase, because §7.7 and §8.1 forbid outside pieces there. If Lily wants a new-piece idea at Jose's house too, this is the line to change.
2. **"Style with this"** does two things now: it set the starting piece for Style Me (Home cleanup, 6 October), and L8 makes it open Make your own look. The plan is a small choice when she taps it: "Style me with it" or "Make my own look".
3. **Swap ranking on the phone** (LR-07): uses plain matching only, so no fit or styling rules land in the public app repo.
4. **Favorites and collections** (RD-08) and **Archive** (LR-16) stay in the master PRD but have no Stage A screen.
5. **Lily's default** is Mine + one idea (LR-03). The master's "new-piece ideas off by default" may still be right for public users later; that's a question for the public launch, not Stage A.
