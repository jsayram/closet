# Room direction: art direction and build contract

Read this whole file before drawing or building anything. Everyone working on these mockups follows it, so pieces made by different people fit together.

## What this is

A design exploration for the iOS app "My Petite Style" (a wardrobe styling app). The owner wants to see the app's screens presented as rooms of a home: an illustrated bedroom where each object is a real control. These are static HTML mockups in a scratch folder. They are not the app. Do not touch anything under `/Users/jramirez/Git/closet`. Do not publish anything, do not install anything, do not use the network.

Root folder (called ROOT below):
`<this folder>`

The owner's reference picture is `ROOT/ref/home.png` (978 x 1926 px, a phone screen). It sets the quality bar and the style. Crops of each object are in `ROOT/ref/` (`wardrobe.png`, `figure.png`, `window.png`, `shelf.png`, `calendar.png`, `mirror.png`, `desk.png`, `rack.png`, `bed-rug.png`, `header.png`, `tabbar.png`). Look at them with the Read tool before you draw.

The first attempt at this (flat rectangles, a stick-like figure, emoji icons) was rejected as low quality. The owner asked for "better higher quality illustrations similar to what I showed" and an avatar she can edit.

## The style

Cozy flat-vector storybook interior, like the reference.

- **Shapes:** soft and slightly rounded. Furniture has real construction detail: cornices, door panels, knobs, rails, brackets, seams, legs, drawer lines. Nothing is a bare rectangle.
- **Outlines:** every object has a thin outline in a darker shade of its own fill colour. Never black, never grey on a coloured object. Width 1.25 to 1.75 at phone scale, round joins and caps.
- **Shading:** flat fills, plus one darker tone for the side or underside and one lighter tone for highlights. A two-stop gradient is fine for glass, walls and floors. No SVG filters, no blur, no drop shadows inside art. Objects that stand on the floor get a soft contact shadow: a flat ellipse, the floor colour darkened, 10 to 14 percent opacity.
- **Mood:** warm, light, calm. Plenty of pale wall showing. Pastel colours with one strong plum accent that is reserved for the primary action.
- **No text inside art.** Every label, number and name on a screen is live HTML text laid over the art. Art must leave clear, flat areas where the contract says a label will sit.
- **No emoji anywhere.** Icons come from `js/icons.js`.

### Palette (use these exact values)

| Token | Fill | Shade | Outline | Used for |
|---|---|---|---|---|
| wall | `#FBE5E8` | `#F7D6DC` | | wall, top to bottom gradient |
| floor | `#F6DDD2` | `#EFCFC2` | `#E3BBAE` | floor, baseboard line |
| blue | `#A9CBEF` | `#8FB8E6` | `#6C9AD0` | wardrobe body |
| blue-deep | `#7FA8D8` | `#6590C6` | `#557FB6` | wardrobe interior |
| wood | `#E7BC6E` | `#D9A650` | `#B98632` | rails, shelves, rack, hangers, frames |
| cream | `#FFF7EA` | `#F3E6D0` | `#D9C6A5` | curtains, frame mats, linen, flats |
| sage | `#B7D5B1` | `#9FC49C` | `#7BA67D` | desk |
| lilac | `#D8C6F0` | `#C3ABE6` | `#A98CD6` | mirror frame |
| glass | `#EFE8FA` | `#DCD0F2` | | mirror glass, top to bottom |
| butter | `#FBE9A6` | `#F3D97C` | `#DDBB4E` | calendar, sticky notes |
| pink | `#F4B4C2` | `#EC9DB0` | `#D97F97` | chair, rug, bedding, sweater |
| rug | `#F3BCC8` | `#EDA9B9` | `#E294A8` | rug |
| leaf | `#77AE84` | `#5C9670` | `#44795A` | plants |
| sky-rain | `#9DB7D6` | `#86A3C6` | | rainy window |
| plum | `#6A1F58` | `#4F1541` | | primary accent only |
| navy | `#27335F` | `#1D2749` | `#161E3A` | navy garments |
| ink | `#2B1B27` | | | text |
| ink-soft | `#6B5563` | | | secondary text |

Skin, hair and garment colours are in the avatar and garment sections.

### Scale rule

Phone screens are 390 x 844 CSS px. **One SVG unit equals one CSS px at phone size.** An asset meant to appear 164 px wide has a viewBox 164 units wide and is placed at `width:164px`. This keeps outline widths equal across every asset. Do not scale assets up or down on phone screens by more than about 15 percent.

## How to check your work (required)

You cannot draw well blind. Render, look, fix, and repeat.

- Render any `.svg` or `.html` to PNG: `ROOT/tools/shot.sh <input> <out.png> [width] [height] [scale]`. Defaults are 390 844 2. Put renders in `ROOT/shots/`. Each render takes a few seconds.
- For a standalone SVG, pass its viewBox width and height, and scale 3 or 4 so you can see detail.
- Look at the PNG with the Read tool, next to the matching reference crop.
- Crop a detail: `ROOT/tools/crop.sh <in.png> <out.png> <x> <y> <w> <h>`.
- Do at least three render-and-fix rounds on anything you draw. After each one, write down what looks wrong before you fix it. Compare against the reference crop honestly: does yours look as finished and charming as theirs? Stop when it does, not when it merely renders.

## Shared code (all plain scripts, no modules, no dependencies, no network)

Every screen page includes these, in this order, at the end of `<body>`:

```html
<script src="../js/icons.js"></script>
<script src="../js/garments.js"></script>
<script src="../js/avatar.js"></script>
```

Each script mounts itself on `DOMContentLoaded` and exposes a `mountAll(root)` function for content added later.

### `js/icons.js`

Line icons in the SF Symbols manner: 24 x 24 grid, stroke `currentColor`, width 1.8, round caps and joins, no fill unless the name ends in `-fill`.

- Markup: `<i data-icon="rain"></i>` becomes an inline `<svg>` sized `1em` (override with `style="font-size:20px"`).
- API: `window.Icons = { NAMES, svg(name), mountAll(root) }`.
- Names: `rain, sun, cloud, moon, suitcase, lock, bookmark, bookmark-fill, calendar, sparkles, hanger, search, chevron-right, chevron-left, chevron-down, chevron-up, chevron-updown, check, person-circle, pencil, heart, heart-fill, swap, plus, minus, close, basket, gear, shirt, trousers, shoe, bag, camera, photo, info, mirror, palette, undo, trash, star, home, door, washer, creditcard, chat, send, sliders, eye, wifi-off, clock, tag, sparkle-wand`.

### `js/garments.js`

Drawings of the fictional closet, in the same style as the room.

- Markup: `<span data-garment="g-pink-blouse" data-hanger></span>`. With `data-hanger` the piece hangs from a wood hanger with a hook at top centre. Without it the piece is drawn alone for a tile.
- Every garment uses viewBox `0 0 120 170`. With a hanger, the hook tip is at (60, 4). The SVG has `width="100%"`, so the container sets the size.
- API: `window.Garments = { LIST, svg(id, {hanger}), mountAll(root) }`. `LIST` items are `{id, name, category, color}`.

The closet (fictional fixtures already used by the app):

| id | name | category | main colour |
|---|---|---|---|
| g-pink-blouse | Cute pink shirt | top | `#F4B4C2` |
| g-cream-sweater | Cream knit sweater | top | `#FFF3E0` |
| g-lace-top | White lace top | top | `#FFFDF8` |
| g-brick-top | Brick knit top | top | `#B5533C` |
| g-black-tee | Black tee | top | `#2E2A30` |
| g-cream-crop | Cream lace crop top | top | `#F8ECD8` |
| g-navy-cardigan | Navy cardigan | layer | `#27335F` |
| g-gray-blazer | Gray blazer | layer | `#A9ABB3` |
| g-brown-jacket | Brown leather jacket | layer | `#7A4B2E` |
| g-camel-trench | Camel trench coat | layer | `#C9A06A` |
| g-navy-trousers | Navy dress pants | bottom | `#27335F` |
| g-olive-trousers | Olive trousers | bottom | `#7C8450` |
| g-wide-jeans | Wide-leg jeans | bottom | `#6F93C4` |
| g-black-skirt | Black midi skirt | bottom | `#2E2A30` |
| g-gray-leggings | Old gray leggings | bottom | `#8E9098` |
| g-blue-dress | Blue floral dress | dress | `#8FB3E3` |
| g-nude-flats | Nude pointed flats | shoes | `#F1DCC6` |
| g-black-heels | Black block heels | shoes | `#2E2A30` |
| g-white-sneakers | White sneakers | shoes | `#FAFAFA` |
| g-tan-loafers | Tan loafers | shoes | `#B98552` |
| g-burgundy-bag | Burgundy crossbody bag | accessory | `#7B2338` |

### `js/avatar.js`

The illustrated person in the room. She is a drawing the user sets up to look like herself. She is never a photo. She wears whatever look the screen is showing.

- Markup: `<div data-avatar data-view="full"></div>`. Optional outfit attributes: `data-top`, `data-layer`, `data-bottom`, `data-dress`, `data-shoes`, each holding a garment id. A `data-dress` replaces top and bottom. Missing outfit attributes fall back to `DEFAULT_OUTFIT`. Optional appearance overrides for swatch previews: `data-skin`, `data-hair-style`, `data-hair-color`, `data-eyes`, `data-glasses`, `data-earrings`, `data-lips`.
- Views: `full` (standing, front, relaxed pose like the reference; viewBox `0 0 240 880`, feet on the baseline at y = 864, head top near y = 20), `bust` (head and shoulders; viewBox `0 0 240 260`), `back` (standing, seen from behind, for the mirror reflection; same viewBox as `full`).
- The SVG has `width="100%" height="100%"` and `preserveAspectRatio="xMidYMax meet"`, so the container sets the size and the feet sit on the container's bottom edge.
- API:

```js
window.Avatar = {
  OPTIONS,          // { skin:[{id,label,color}], hairStyle:[{id,label}], hairColor:[{id,label,color}],
                    //   eyes:[{id,label,color}], glasses:[{id,label}], earrings:[{id,label}], lips:[{id,label,color}] }
  DEFAULTS,         // { skin:'s3', hairStyle:'wavy-bob', hairColor:'chestnut', eyes:'brown',
                    //   glasses:'none', earrings:'hoops', lips:'rose' }
  DEFAULT_OUTFIT,   // { top:'g-pink-blouse', bottom:'g-navy-trousers', shoes:'g-nude-flats', layer:null, dress:null }
  get(),            // current appearance (saved, or DEFAULTS)
  set(patch),       // merge, save, re-render every mounted avatar, notify
  reset(),
  onChange(fn),
  svg(appearance, outfit, {view}),   // returns an SVG string
  mountAll(root)
}
```

- Saved appearance lives in `localStorage` under `mps.avatar.v1`, with every access in try/catch. Pages also listen for the `storage` event and a `BroadcastChannel('mps.avatar')` so an edit in one frame redraws avatars in the others. Everything must render correctly with storage unavailable.
- Required options: 6 skin tones (`s1` lightest to `s6` deepest), at least 6 hair styles (`wavy-bob` is the default and matches the reference; also `long-waves`, `long-straight`, `high-bun`, `curly`, `ponytail`), 7 hair colours (`black`, `dark-brown`, `chestnut`, `auburn`, `blonde`, `silver`, `rose`), 4 eye colours, glasses (`none`, `round`, `cat-eye`), earrings (`none`, `hoops`, `studs`), 3 lip shades.
- Required worn garments: tops `g-pink-blouse, g-cream-sweater, g-lace-top, g-brick-top, g-black-tee`; layers `g-gray-blazer, g-navy-cardigan, g-camel-trench`; bottoms `g-navy-trousers, g-olive-trousers, g-wide-jeans, g-black-skirt`; dress `g-blue-dress`; shoes `g-nude-flats, g-white-sneakers, g-tan-loafers, g-black-heels`. An unknown id falls back to the nearest category default and never throws.

### `css/room.css`

Tokens and the shared UI pieces: `.screen` (the 390 x 844 canvas), `.room` (wall and floor), `.nav`, `.title-display`, `.tag` (white label plate on an object), `.tag.green/.pink/.butter`, `.chip`, `.chip.on`, `.btn`, `.btn.ghost`, `.tabbar`, `.card`, `.row`, `.toggle`, `.sim` (simulation label), `.abs` (absolute positioning helper). Read the file. Reuse its classes. Add screen-specific rules in a `<style>` block in your own page; do not edit `room.css` unless your task says you own it.

## Screen pages

- One file per screen: `ROOT/screens/<id>.html`. The body is exactly the device size with no scroll. Phone: 390 x 844. iPad landscape: 1194 x 834.
- Art is placed with `<img src="../art/name.svg">` or inline SVG, absolutely positioned. Labels are HTML on top.
- Every tappable thing is at least 44 x 44 px and has a text label. Nothing overlaps another label. Nothing is clipped. Text never sits on a busy part of the art without a plate (`.tag`) behind it.
- Body text is 13 px or larger. Captions 11 px minimum.
- Anything simulated says so with `.sim` ("Simulated"). Prices are sample values and say so.
- The bottom tab bar is the app's real one: Style Me, Closet, Saved Looks. The active tab is a plum pill.
- The room is decoration around working controls. If art and legibility conflict, legibility wins.
- Write plain, calm UI copy. No exclamation marks, no marketing voice.

## App facts to use on screens (fictional fixtures from the prototype)

Use these so the mockups show the same data as the working prototype. Do not invent other people, prices or features.

- **App name:** My Petite Style. Tabs: Style Me, Closet, Saved Looks. Profile button top right opens Profile and Settings.
- **Weather (simulated):** 58°F, rain today. Tap opens a weather detail.
- **Style Me inputs:** Source (Main closet, or a suitcase), Occasion (Office, Date Night, Brunch, Concert, Casual, Event, Other), Starting piece (optional, "Choose a piece", hint "e.g. navy dress pants"), On Me (a simulated preview of looks on the person; labelled "Simulated"), More options (weather override, pieces to avoid, notes). Primary action: Style Me. Secondary: Ask stylist (opens a chat with a simulated stylist).
- **Suitcases:** "Jose's house" (5 pieces: g-navy-trousers, g-pink-blouse, g-navy-cardigan, g-nude-flats, g-lace-top), "Weekend" (8 pieces: g-navy-trousers, g-olive-trousers, g-wide-jeans, g-brick-top, g-cream-sweater, g-brown-jacket, g-white-sneakers, g-black-tee), "Spring trip" (empty). When a suitcase is the source, a green plate says "5 pieces · Suitcase only".
- **Main closet:** the 21 garments in the garments table above.
- **Laundry:** two pieces are dirty: g-lace-top and g-black-tee. Closet shows a "Dirty (2)" filter. Marking clean offers Undo.
- **Saved looks:** "Interview navy & pink" (g-navy-cardigan, g-pink-blouse, g-navy-trousers, g-nude-flats), "Weekend olive & brick" (g-brown-jacket, g-brick-top, g-olive-trousers, g-white-sneakers), "Lace date night" (g-lace-top, g-black-skirt, g-black-heels, g-burgundy-bag), "Gray blazer office" (g-gray-blazer, g-cream-sweater, g-navy-trousers, g-black-heels), "Pink & black date night" (g-pink-blouse, g-navy-trousers, g-black-heels, g-burgundy-bag).
- **Style Me results:** three looks per request. Each look has its pieces, a short note on why it works, Save, Swap a piece, and Ask stylist. Picture previews of a look are simulated and say so.
- **Styling access (simulated):** the demo profile has sponsored access at no charge. Allowances shown separately: styling requests and outfit pictures, each with a reset date (use 1 Nov).
- **Paywall (sample values, labelled as sample):** 7-day free trial, then $9.99 a month, renews monthly until cancelled. Must show Restore Purchases, Redeem code, Terms, Privacy, the trial end date and the first charge date. Local features (closet, suitcases, saved looks, manual outfits) stay free.
- **The avatar** is an illustration the user sets up to look like herself. It is never a photo and nothing is uploaded; say "Saved on this iPhone". It is separate from On Me.
- **Copy voice:** short, plain, calm. Sentence case. No exclamation marks.

## Revision 2: portrait, not avatar (owner decision, 6 Oct)

This overrides anything above about the avatar.

- **No body anywhere.** Her likeness is only a **portrait**: head and shoulders, in a picture frame on the wall or a round frame in Profile. It is decoration. She never wears clothes in the app, never appears full length, and has no mirror reflection.
- **Clothes are always shown as clothes:** hanging on a rail or rack, in the wardrobe, or laid out flat as a set. In the real app these are her own photos of her garments; the drawn garments in these mockups stand in for those photos.
- **Try-on is the only "on her" image.** When she asks for it, a generated picture of her wearing the real pieces. In the mockups it is a placeholder frame: a soft warm-grey to blush gradient, a centred photo icon (Icons "photo"), the text "Try-on picture" and a `.sim` "Simulated" label. Never draw a figure in it. Try-on pictures live in Saved Looks, which is a gallery wall of frames.
- **A look without a try-on picture** is shown as its pieces laid out flat in the frame (garments without hangers, arranged top above bottom, shoes and bag beside), or hung together on a short rail.
- **Portrait choice:** six ready-made presets plus a face shape, picked with one tap in Profile ("Your portrait"). No editor, no sliders, no other options exposed.

### avatar.js additions (contract)

- `Avatar.PRESETS`: six presets `{id, label, skin, hairStyle, hairColor, eyes, glasses, earrings, lips}`, ids `p1`..`p6`, covering all six skin tones and a spread of hair styles and colours. `p3` matches today's default (s3, wavy-bob, chestnut).
- `Avatar.OPTIONS.faceShape = [{id:'slim',label:'Slim'},{id:'medium',label:'Medium'},{id:'round',label:'Round'}]`. Round is a fuller face for fuller-figured women: fuller cheeks and jaw, softer chin, a little fuller neck and shoulders. Slim is narrower. Medium is today's face.
- Appearance gains `preset` (default `p3`) and `faceShape` (default `medium`). `Avatar.set({preset:'p5'})` applies that preset's fields. `Avatar.set({faceShape:'round'})` changes only the face shape.
- New view `portrait`: head and shoulders only, viewBox `0 0 240 260`, shoulders cropped by the bottom edge, wearing a plain neutral top (no garment ids). `bust` becomes an alias of `portrait`. Override attributes for previews: `data-preset`, `data-face-shape`.
- Full and back views may stay in the file but no screen may use them.

## File ownership

Only write the files your task names. Never edit another agent's files. If you need something from a shared file that is missing, say so in your final report.

## Revision 3: a name sign, no portrait (owner decision, 6 Oct)

This overrides Revision 2 and everything above about the avatar.

- **No portrait and no likeness of her anywhere.** No faces in the app. `avatar.js` is no longer loaded by any screen, and the portrait picker (`avatar-edit.html`) is gone.
- **The room has a name sign instead**, in the wall spot the portrait used: `art/name-sign.svg`, a small wooden sign on two strings from a nail (110 x 64 at 1:1). It shows the profile's first name, "Lily" for the demo profile, as live HTML text in the display serif, plum, centred in the flat panel at x 17..93, y 27..53 of the SVG. The name is never drawn into the art.
- Tapping the sign opens Profile (on iPad, Profile opens beside the sidebar). Profile shows the sign larger on its wall and has a "Name on your sign" row with the value "Lily". The iPad sidebar card is "Lily" / "Profile" with a person-circle icon.
- Clothes are still shown only as clothes, and try-on pictures are still simulated placeholders, as in Revision 2.
