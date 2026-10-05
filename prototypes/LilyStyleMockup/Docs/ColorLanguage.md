# Color language: what each color means

Status: proposal, 5 October 2026. Nothing in the app uses this yet. The app still follows the palette in PRD §7.1 (ivory, white, plum, sage). If you adopt this guide, the asset catalog and the shared components change, and §7.1 needs an amendment.

## The idea

Every kind of control gets its own matte pastel, and it keeps that color on every screen. Lily learns it once: rose things do something, blue things are choices, lavender things switch on and off, butter things open up, and sage things are only there to read. She can tell what a part of the screen is for before she reads it.

Color is never the only signal. Each role also keeps its own shape, icon and label, so the screen still works in grayscale, for color-blind users and with VoiceOver.

## Roles and their colors

| Role | What it means to her | Color | What else tells her |
| --- | --- | --- | --- |
| Primary action | "Do it." The one main action on a screen: Style Me, Save, Confirm, Search. | Plum, solid | Filled button, bold label, icon |
| Secondary action | Other things she can do: Ask stylist, Edit, Choose from closet, Mark clean, Already own. | Rose | Button shape, outline, verb label |
| Selector | Pick one or more from a set: source picker, occasion and filter chips, segmented controls, menus. | Powder blue | Chip or picker shape, up/down chevron; the selected choice is filled and has a checkmark |
| Switch | On or off: On Me, permissions, settings toggles. | Lavender | Switch shape; the row says the current state in words |
| Collapsible section | Opens in place: Occasion, More options, grouped settings, help topics. | Butter | Down or up chevron on the trailing edge |
| Read-only information | Only to read: explanations, fit notes, "what was checked", request summaries, simulation notices. | Sage | No outline, no chevron |
| Text input | Type here: fields, search, the chat composer. | Paper white | Neutral outline, placeholder, cursor |
| Navigation row | Goes to another screen: settings rows, "View in Closet". | Paper white | Right chevron |
| Card or group | Holds other things. | Paper white | None needed |
| Screen background | | Oat | |
| Garment panel | Behind clothes and outfit pictures. | Neutral stone, never tinted | |

Status is a separate, smaller layer. It says how something is, not what kind of control it is:

| Status | Color | Always with |
| --- | --- | --- |
| Positive (owned, clean, saved) | Moss green | Check icon and text |
| Caution (dirty, not arrived, needs review) | Apricot | Warning icon and text |
| Error or destructive | Brick red | Error icon and text; destructive actions also confirm |
| Neutral label (Simulated, Demo, Earlier) | Stone | Icon and text |

## Rules

1. **Outlined means touchable.** Buttons, selectors, switches, collapsible headers and inputs have a 1 pt outline in their family's edge color. Read-only sage areas have no outline. That gives a second cue besides the hue.
2. **One plum per screen.** Only the main action is solid plum. Everything else she can tap is a pastel.
3. **Selected and on states use the family's strong shade.** A selected chip is deep blue with a white label and a checkmark. A switch that's on has a deep violet track. Nothing borrows plum to show selection.
4. **Role colors don't stack.** A collapsible header is butter, but the body it opens is paper, so the controls inside keep their own colors on a neutral ground. A read-only note inside a card is a sage block on paper.
5. **Clothes stay on neutral.** Garment art and outfit pictures always sit on the stone panel. A rose or butter backdrop would change how their colors look.
6. **Status stays small.** Status colors appear only as badges and banners with an icon and text, never as the fill of a whole section, so apricot "caution" isn't confused with butter "opens up".
7. **Composite rows take the color of what a tap does.** The collapsed Occasion row is butter because tapping it opens the row. The chip that shows the current occasion inside it is selector blue.
8. **Dark mode keeps the hues.** Surfaces become deep matte versions of the same colors, and the strong shades become light pastels with dark labels.

## Palette

Each family has up to five shades:

- **Surface** fills the control.
- **Edge** is its outline.
- **Strong** fills the selected or on state (for rose, the primary button).
- **On strong** is the label on a strong fill.
- **Ink** is text and icons on the surface.

The values live in `Tools/color_language_check.py`, which also checks contrast.

### Light

| Family | Surface | Edge | Strong | On strong | Ink |
| --- | --- | --- | --- | --- | --- |
| Rose (actions) | `#EBD1D5` | `#A5637A` | `#633B55` plum | `#FFFFFF` | `#5A2E45` |
| Powder (selectors) | `#D3DFE6` | `#5C7F95` | `#2F5770` | `#FFFFFF` | `#23485E` |
| Lavender (switches) | `#DDD4E7` | `#856FA3` | `#5B4680` | `#FFFFFF` | `#443263` |
| Butter (collapsible) | `#F1E6C6` | `#97803A` | `#6F5A1E` | `#FFFFFF` | `#54431A` |
| Sage (read-only) | `#D6E0D1` | none | none | none | `#2F4A35` |

| Neutral | Value | Use |
| --- | --- | --- |
| Oat | `#F4EEE6` | Screen background |
| Paper | `#FBF7F1` | Cards, inputs, navigation rows |
| Stone | `#F3EEE8` | Garment panel |
| Ink | `#29242A` | Body text |
| Taupe | `#5F5360` | Secondary text (darker than today's `#6E626A` so it passes on every pastel) |
| Input outline | `#8C7F88` | Fields and neutral controls |

| Status | Surface | Ink |
| --- | --- | --- |
| Positive | `#E2EEDD` | `#2F5E3C` |
| Caution | `#F7E3CF` | `#8A4B12` |
| Error | `#F8E1E1` | `#A12D39` |
| Neutral | `#EAE4DC` | `#4F454C` |

### Dark

| Family | Surface | Edge | Strong | On strong | Ink |
| --- | --- | --- | --- | --- | --- |
| Rose (actions) | `#4A2F3A` | `#B98A98` | `#D9AFCB` soft plum | `#1C191B` | `#F3D9E0` |
| Powder (selectors) | `#2A3C47` | `#7FA3B8` | `#A9CBDD` | `#14232B` | `#D5E6EF` |
| Lavender (switches) | `#3A3149` | `#A593C2` | `#C9B8E6` | `#221A30` | `#E5DCF3` |
| Butter (collapsible) | `#453C22` | `#B9A260` | `#E2CF8E` | `#2B2410` | `#F3E8C2` |
| Sage (read-only) | `#2C3A2D` | none | none | none | `#D3E3D0` |

| Neutral | Value | Use |
| --- | --- | --- |
| Charcoal | `#1C191B` | Screen background |
| Soft charcoal | `#292529` | Cards, inputs, navigation rows |
| Stone | `#353035` | Garment panel |
| Ivory | `#FAF7F2` | Body text |
| Pale taupe | `#C5B8C0` | Secondary text |
| Input outline | `#8F838B` | Fields and neutral controls |

| Status | Surface | Ink |
| --- | --- | --- |
| Positive | `#273B2D` | `#AFCEB6` |
| Caution | `#4A3320` | `#F2C08D` |
| Error | `#4A2428` | `#FFB3B8` |
| Neutral | `#3A353A` | `#D8CDD4` |

## Where each element in the app lands

| Element | Role | Notes |
| --- | --- | --- |
| Style Me, Save, Confirm, Search (Find One), Send | Primary action | Solid plum |
| Ask stylist, Edit, Refresh, Choose from closet, Open in editor, Save look, Mark clean, Already own, Find One | Secondary action | Rose. Mark clean and Already own stop being green buttons; the green moves to the status badge they produce |
| Delete, Clear, Remove, No longer own | Destructive | Brick outline on paper, with confirmation |
| Toolbar icon buttons | Action | Plum icon, no fill |
| Source selector (Main Closet or a suitcase) | Selector | Powder pill |
| Occasion chips, filter chips, color chips, comfort chips | Selector | Powder; selected is deep blue with a checkmark |
| Segmented controls, menus, pickers, sort | Selector | Powder |
| On Me toggle, permission toggles, settings toggles | Switch | Lavender row; on is deep violet |
| Occasion row, More options, grouped sections in Profile, Settings and Help | Collapsible | Butter header, paper body |
| "Your request" summary chips on results | Read-only | Sage chips with no outline, so they don't look tappable |
| Fit notes, rationale, "What was checked", "What's different today", evidence and unknowns in Find One | Read-only | Sage blocks |
| Simulation notices ("Prototype with fictional demo data…") | Read-only | Sage block with the flask icon |
| Weather line on Style Me | Navigation row | Paper, plum icon, right chevron (it opens the weather sheet) |
| Text fields, search bars, chat composer, notes | Text input | Paper with the neutral outline; focus ring in plum |
| Settings rows, "View in Closet", saved look rows | Navigation row | Paper with a right chevron |
| Outfit cards, garment cards, sheets | Card | Paper. The selected look keeps a 2 pt plum outline |
| Flat-lay outfits, garment thumbnails, On Me placeholder | Garment panel | Stone, never tinted |
| Dirty, Not arrived, Earlier, Simulated, Saved, Already own | Status badge | Status layer colors with icon and text |
| Banners and toasts | Status | Status surface with icon; their buttons are rose |
| Tab bar and sidebar | Navigation | Paper. The current tab is plum with heavier weight |
| Lane names (Safe / Simple, Elevated, New piece) | Label | Text and icon only, no role color |

## Example: the Style Me screen

- Title and the weather line sit on oat. The weather line is a paper navigation row.
- The source selector is a powder pill.
- Occasion is a butter row with a chevron. It shows "Office" as a deep blue selected chip. Opened, the body is paper with powder chips.
- Starting piece is a paper card that holds a rose button ("Choose from Main Closet") and a paper text field.
- More options is a butter row. Opened, its comfort and color chips are powder, and its toggles sit on lavender rows.
- On Me is a lavender switch row.
- At the bottom, Style Me is solid plum and Ask stylist is rose.

## Accessibility

- Every pairing in the proposal passes its target: 4.5:1 for text and 3:1 for outlines and state fills, in both appearances. The full table of 98 checks is in [color-language-contrast.md](color-language-contrast.md).
- Nothing depends on hue alone. Each role has a shape and an icon or chevron, selected states add a checkmark, and switches state "On" or "Off" in the row's accessibility value.
- With Increase Contrast on, outlines go to 2 pt and pastel surfaces drop to paper, leaving the outline and ink to carry the role.
- The colors are matte and opaque, so Reduce Transparency changes nothing.

## What this changes from PRD §7.1

- **Kept:** ink and ivory text, plum as the primary action in both appearances, the neutral garment panel, the status meaning of green and red, typography, spacing and motion.
- **Changed:** the background warms from ivory `#FAF7F2` to oat `#F4EEE6`, cards go from white to paper `#FBF7F1`, and secondary text darkens to `#5F5360`.
- **Added:** four role families (rose, powder, lavender, butter), sage as the read-only color, and apricot for caution.
- **Moved:** "selected" no longer uses plum on dusty rose. It uses the selector family's deep blue.
- **Sage** changes meaning from "success" to "read-only", and success becomes the slightly deeper moss green used only in badges.

## Applying it

1. Add the families as color sets in `Resources/Assets.xcassets` and expose them through `Palette` as role tokens (`Palette.action`, `Palette.selector`, `Palette.toggle`, `Palette.disclosure`, `Palette.readOnly`).
2. Change the shared components first, because most screens inherit from them: `SecondaryButtonStyle`, `SuccessButtonStyle`, `CapsuleChip`, `SourceSelector`, `SimulationNotice`, `InlineBanner`, `StatusBadge`, `.cardStyle()`, plus two new ones for collapsible headers and switch rows.
3. Sweep each feature for places that set colors directly.
4. Regenerate both contrast tables and look at every screen in light, dark and the largest text size.
