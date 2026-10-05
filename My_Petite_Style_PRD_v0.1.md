# MY PETITE STYLE

Product Requirements Document

Petite-first AI personal stylist for iPhone and iPad

Version 0.1 — consolidated master  |  Original draft September 26, 2026  |  Updated October 3, 2026

Primary design partner: Lily

## Document authority and navigation

**This Markdown file is the authoritative master specification.** It consolidates current product decisions, architecture, pricing direction, privacy controls, competitor-review evidence, try-on research, release checklists and next steps. Maintain future requirements here. The other Markdown files are navigation pointers; the original Word file is preserved as a historical draft and its superseded pricing, shopping and try-on scope are not current requirements.

This workspace contains planning documents, not an implemented app. Documentation review does not establish feature quality, fit accuracy, wallet recovery, App Store approval or release readiness. All application acceptance and RV/TO checks are **Not run**. Current counts are 47 functional requirements, 66 acceptance criteria, 22 core RV checks and eight conditional TO checks.

| Read for | Master sections |
| --- | --- |
| Lily-first product, user experience and design | [1–7](#1-executive-summary), [10](#10-petite-first-styling-layer) |
| AI behavior, optional images and provider research | [8](#8-ai-stylist-requirements), [9](#9-image-strategy) |
| Architecture, weather, cost controls and records | [11](#11-technical-architecture), [12](#12-core-data-model) |
| Optional missing-piece search and external sharing | [13](#13-shopping-and-retailer-integration) |
| Public subscription, Lily sponsorship and conditional image packs | [14](#14-monetization-monthly-subscription-and-complimentary-access) |
| Privacy, recovery, delivery and acceptance | [15–19](#15-privacy-security-and-trust) |
| Support, website, help, optional emails, analytics and Apple release requirements | [22–24](#22-feedback-board-and-private-support) |
| Competitor evidence, all 23 mappings and RV checks | [25](#25-review-derived-reliability-and-recovery-gates) |
| Status, naming limits, open decisions and next steps | [26](#26-project-status-and-next-steps) |

Core styling/wardrobe/recovery requirements apply to V1. The fit-aware finder and Generate Look remain optional services with separate evidence gates; image packs apply only if the image service is enabled. A disabled optional service cannot be advertised as implemented, and its conditional checks do not block the independent core experience. Broader sizes/lengths and men's clothing remain later validation work within the same app foundation.

Decision confirmed October 3, 2026: the intended public audience is adults aged 18 or older, with initial App Store distribution in the United States. Keep the same app ready for separately reviewed country expansion; international shopping destinations are a distinct capability. See Sections 11.8 and 24.2.

**Product thesis**

Help petite women decide what to wear, confidently use what they already own, discover better combinations, and buy only the pieces they genuinely need.

## 1. Executive Summary

My Petite Style is a free-to-download iOS app with monthly subscription access to its AI stylist, designed as a petite-first personal stylist. A user chooses an occasion, reviews automatically detected weather and season, optionally names a starting piece (for example, “navy dress pants” or “brown leather jacket”), and receives three complete outfit directions: Safe / Simple, Stylish / Elevated, and Creative / Risky.

V1 is a universal iPhone and iPad application. iPad gets a styling workspace with comparative outfit views, a closet grid, and contextual editing panes that adapt to the actual window size. A moderated feedback board and optional, privacy-conscious improvement analytics support product development. App Store compliance, consent, entitlement validation, and server-enforced usage and spending controls are release requirements.

The app centers on styling the clothes she owns and saving reusable looks. Every outfit is modular: swap garments, mark Already Own, arrange a visual outfit board, and ask which occasions a look suits. The app learns gradually from editable, user-confirmed preferences without requiring a full closet upload. An optional Generate Look try-on is now under feasibility exploration (Section 9.2); a personal photo is not required for ordinary styling.

Shopping is a secondary action when she still wants a missing piece after considering owned alternatives. Find One can offer actual products with size/length evidence, delivery to her chosen destination, and explicit purchase capture; it must not impose an arbitrary region restriction. No default shopping feed, automatic Amazon-first search, or gap checklist is planned. The finder remains a prototype-gated optional V1 target under Section 13, with no implemented/commercially validated catalog or fit service.

Decision confirmed October 3, 2026: Lily's complete daily experience is the first design and validation priority: 4'11" height, approximately 110–130 lb as optional context, her confirmed measurements/garment fit, preferred styles and low-friction workflow. Broader adoption or profitability must not dilute that experience. Build flexible profile data and conditional fit rules from day one, then validate Lily first. Additional sizes, lengths and men's clothing are later coverage work, not a current universal-support claim. Keep one app; no separate mass-market app is planned. See Sections 3.3 and 10.2.

**Monetization decision**

Decision updated October 3, 2026: The app is free to download, with a monthly auto-renewable subscription for AI styling. The owner prioritizes Lily's experience and accepts her usage as a personal expense; profitability is not the primary goal. Selected users can receive complimentary ongoing access through Apple-issued offer codes for a separate non-consumable unlock. Public pricing is open for revision from the earlier US$4.99 plan, with US$9.99/month a candidate if needed, not a finalized price. Retain the one-month introductory trial for eligible users. If optional try-on ships, plan an included monthly image service allowance plus optional purchased image packs. Lily's owner-sponsored usage policy removes public allowance/credit-purchase requirements while retaining technical controls and a separately approved owner budget. See Section 14.

## 2. Product Vision and Principles

### 2.1 Vision

A petite woman should be able to open the app, tell it where she is going, and within seconds see three useful ways to dress - without cataloging her entire closet or scrolling through hundreds of products.

### 2.2 Product principles

- Closet first, shopping second. Primary navigation is Style Me, Closet, and Saved Looks. Reuse what the user owns and offer swaps before a deliberate Find One action; no shopping feed, automatic gap checklist, or image-generated purchase recommendation.
- Lily-first validation with flexible fit rules. Apply petite/short-proportion guidance where the supplied profile, confirmed garment fit and user preferences make it relevant. Lily's confirmed preferences take precedence over generic styling defaults; expansion must pass her regression checks.
- Options over answers. Successful styling presents three distinct outfit directions rather than a single “correct” look. Strict wardrobe-only requests explain insufficient inventory instead of inventing owned items.
- Interactive, not static. Every visible outfit piece can be changed independently.
- Low setup burden. The wardrobe grows naturally through “Already Own,” optional photos, purchases, and feedback.
- Explain the creative choice. When the app proposes an unexpected color combination, it should briefly explain why it works.
- AI should feel invisible. Buttons and visual controls handle common actions; chat is available only when useful.
- No runtime image generation is required for the core experience. Reusable assets, user photos, and appropriately licensed retailer images support collage styling. Optional try-on requires an explicit Generate Look action and separate tested image permission/budget; see Section 9.2.
- Use the available space. iPad supports comparison and editing together; narrow windows retain the same essential actions.
- Keep users in control of their data. Cloud AI permission, optional analytics, public feedback, and private iCloud sync are separate choices.
- Make paid service limits clear. Enforce cost protection on the server and disclose meaningful styling allowances before subscription activation.

## 3. Primary User and Problem

### 3.1 Primary design persona: Lily

| Attribute | Requirement / context |
| --- | --- |
| Body profile | User-confirmed design context: petite; 4'11"; weight may vary approximately 110–130 lb. Initial user-reported inseam preference: 25 or 26 inches, editable in her profile; body-versus-preferred-garment measurement basis remains to be confirmed. Weight is optional context, never a fixed size mapping. Confirm other actual measurements, preferred fit and garments that fit well; do not infer them from height/weight or a photo. |
| Primary need | Build flattering, stylish combinations from her clothes for nice occasions, casual outings, and everyday looking put together, while avoiding unnecessary purchases. |
| Setup preference | Does not want to photograph or catalog her entire wardrobe upfront. |
| Interaction preference | Quick option buttons plus an optional free-text starting point; chat should not dominate the interface. |
| Styling preference | Wants simple/safe, stylish/elevated, and creative/risky choices with coordinated and complementary color combinations. Do not default to an entire outfit in one color; monochrome remains an explicit preference/request, not a blanket prohibition. |
| Priority fit frustration | Trouser fit and finding the right inseam/length are central frustrations. Use her editable 25-/26-inch inseam preference and evaluate trouser styles against confirmed proportions, desired hem/shoe relationship and compatible fit evidence. Preferred cuts and the measurement basis remain to be confirmed. |
| Visual decision support | Wants to compare how pieces, trouser styles and colors work together before physically trying them. Native outfit boards support combination comparison; optional Generate Look is the separately gated on-body preview, not proof of physical fit. |
| Other comfort preferences | No firm sleeve-length complaint or fabric dislike has been confirmed. Keep these editable optional preferences; fabric can matter for occasion, weather and drape without imposing a general exclusion. |
| Creative meaning | “Risky” means an unexpected color pairing that still looks intentional and good - not random or flashy. |
| Shopping preference | If she loves a look but is missing one item, she wants a direct path to find and order that item. |
| Planning behavior | Often plans outfits in advance, including work, dates, brunch, concerts, and other occasions. |

### 3.2 Problems to solve

- “I do not know what to wear for this occasion.”
- “I want help discovering my personal style.”
- “I own something similar - can I use that instead?”
- “I would never have thought those colors worked together.”
- “I do not want to buy another thing I effectively already own.”
- “Petite clothing is inconsistent across brands and regular sizing often fits poorly.”
- “I struggle to find pants with the right inseam, and want to see whether a trouser style works with the rest of my outfit.”
- “I want to plan ahead, but weather and season should still matter.”

### 3.3 Lily-first validation and staged expansion

Validate Lily's everyday styling, owned-piece swaps, occasion planning, saved looks, profile/fit feedback, recovery and sponsored access first on her iPhone 12. Optional shopping and try-on, if enabled, must also pass their own evidence gates using her confirmed needs and consented material. High quality means useful recommendations, accurate constraints, honest fit unknowns and recoverable work; physical fit and AI rendering are not guaranteed.

Keep profile/rule contracts adaptable without adding mandatory setup or presenting unsupported choices. There is no height, weight, size or gender eligibility cutoff, including no 5-foot maximum. Lily's measurements are her profile data, not application-wide constants. Initially validate her experience, then consider a small group with similar fit needs. Broader sizes/proportions and men's clothing require additional sizing, styling, catalog and any try-on evidence before claiming support. Existing core/recovery gates still apply to public release; one person's feedback does not establish population-wide fit quality. A separate app is a future product decision only if a substantially different experience becomes necessary.

## 4. Goals and Success Criteria

| Goal | MVP success signal |
| --- | --- |
| Fast styling | A first-time user can create a profile and generate a useful outfit without a wardrobe import. |
| Useful variety | Each successful generation produces three meaningfully different lanes: Safe, Elevated, Creative; insufficient wardrobe-only inventory has an honest, actionable outcome. |
| Modularity | Any major piece can be tapped and swapped without regenerating the entire experience from scratch. |
| Gradual learning | Marking “Already Own” immediately improves future recommendations. |
| Lily's fit and styling relevance | Recommendations respect her confirmed dimensions, fit references and preferences; consider petite/short variants where useful, preserve honest length unknowns, and pass her saved scenario suite before expansion or model/rule rollout. |
| Anti-overbuying | Shopping appears as an intentional action for missing pieces, not as the default output. |
| Weather awareness | Current or planned-date weather influences layers, shoes, fabric, and seasonality. |
| Subscription value | AI styling provides continuing monthly value; selected complimentary users receive equivalent styling access. Users retain access to their own closet and backups after a subscription expires. |
| iPad usefulness | Users can compare outfit lanes and work with their closet in adaptive panes, including in a resized window. |
| Product improvement | Moderated ideas and privacy-minimal metrics reveal problems and useful styling outcomes without uploading closet contents for analytics. |

## 5. Core User Experience

### 5.1 Primary workflow

```text
FIRST LAUNCH
  -> Skippable personal fit profile + style preferences + optional budget

APP OPEN
  -> Short affirmation
  -> Occasion buttons
  -> Weather + season (automatic, editable)
  -> Optional starting point: “Use my brown leather jacket”
  -> STYLE ME

STYLIST
  -> Safe / Simple
  -> Stylish / Elevated
  -> Creative / Risky

OUTFIT CARD
  -> Tap pants / top / jacket / shoes / accessories
  -> Swap | Already Own | explicit optional Find One
  -> Outfit updates

CORE SAVE + FEEDBACK
  -> Save outfit
  -> Reopen/edit, tag an occasion or ask where it could be worn
  -> Learn owned items + preferences
  -> Continue styling her existing wardrobe

OPTIONAL MISSING-PIECE SEARCH — only when explicitly requested
  -> Find One uses saved fit preferences + confirmed shopping destination
  -> If enabled after its gate: real product options with sourced evidence
  -> Otherwise honest unavailable status or unverified browser-search fallback
  -> View at Store uses a permitted Safari web sheet or external store/browser
  -> Return restores the same outfit/product; optional Bought it? Add to closet
  -> User taps “I bought this” (explicit confirmation)
  -> Review actual size/color, source link, optional details and arrival status
  -> Add Camera/Photos image or use app-owned placeholder
  -> Save confirmed owned item locally; unavailable until arrival is confirmed

OPTIONAL GENERATE LOOK — only if separately enabled after its gates
  -> Select optional reference photo + usable garment photos
  -> Review image permission and allowance/credit treatment
  -> Explicitly generate, review and save a preview linked to the outfit

OPTIONAL ASK ANOTHER STYLIST — local export, no app AI call
  -> Preview permitted garment collage + editable prompt
  -> Explicit share/save/copy; receiving service's terms apply
```

### 5.2 Example

Input: “First day at a new job; office-like; not too flashy but cute. I have navy blue dress pants.”

| Lane | Example recommendation |
| --- | --- |
| Safe / Simple | Navy trousers + white button-down + neutral flats. |
| Stylish / Elevated | Navy trousers + tan top + navy cardigan + small gold jewelry. |
| Creative / Risky | Navy trousers + muted green top + warm neutral accessory, with a short explanation of why the colors work together. |

If the user taps the pants, the app may offer blue jeans, black jeans, light-wash jeans, leggings, trousers, or contextually appropriate alternatives. Selecting a swap updates the look and styling explanation.

## 6. Functional Requirements

| ID | Capability | Requirement |
| --- | --- | --- |
| FR-01 | Flexible personal fit profile | Prioritize Lily's validated experience while storing editable optional height, inseam, sleeve length, waist and bust with units, measurement basis/source/update state, category/brand/sizing-system context, fit/style/color preferences and budget. Support supplied preferred lengths/ranges separately from exact body measurements; Lily's initial inseam preference is 25 or 26 inches. Reuse confirmed well-fitting garments. Weight is optional context, never a sizing rule or prerequisite. No height/weight/size/gender eligibility cutoff or extra mandatory onboarding. Apply relevant fit rules per profile; broader coverage requires separate validation. See Sections 10.1/10.2. |
| FR-02 | Affirmation | Display a brief positive affirmation on app open. Use a curated local library in V1 to avoid unnecessary AI calls. |
| FR-03 | Occasion selector | Provide quick chips for Office, Date Night, Brunch, Concert, Casual, Event, and Other. Additional occasions may be added without app redesign. |
| FR-04 | Weather + season | Automatically determine local weather and season. Allow override for future travel or planning. |
| FR-05 | Optional starting point | Provide a free-text field for “I want to wear…” / “I already have…” / special constraints. |
| FR-06 | Three lanes | Successful generation returns exactly three distinct outfit directions: Safe/Simple, Stylish/Elevated, Creative/Risky. A wardrobe-only request that cannot satisfy the constraints returns a typed insufficient-inventory outcome, never fabricated garments. |
| FR-07 | Coordinated color reasoning | All lanes respect the user's color preferences; Lily's initial preference favors coordinated, complementary combinations over a default single-color outfit. Creative/Risky explores less-obvious coherent pairings. Explain relevant pairing choices briefly; an explicit monochrome request remains supported. |
| FR-08 | Visual outfit cards | Represent each outfit with images for top, bottom, layer, shoes, and optional accessories. |
| FR-09 | Tap-to-swap | Every major piece is tappable. A one-item swap preserves all other piece IDs and layout values; changes to other pieces require a separate explicit action. |
| FR-10 | Already Own | Allow the user to mark a suggested item as already owned with one tap. A photo and metadata are optional, not required. |
| FR-11 | Wardrobe learning | Persist known owned items, colors, categories, fit feedback, rejected items, chosen lanes, and saved outfits. |
| FR-12 | Find One | At the user's request, search permitted product sources for real options that match the outfit and saved fit preferences, checking size/color variants and delivery evidence for an editable destination. No arbitrary single-region restriction. Show sourced size and length guidance, uncertainty, price/stock timestamps, and retailer links. A browser search is an explicitly unverified fallback. Catalog/fit access must pass Section 13's prototype gate before this V1 target is claimed; no affiliate monetization or retailer-account connection in V1. |
| FR-13 | Save outfit | Allow a completed look to be saved and optionally tagged to a future date/occasion. |
| FR-14 | Ask Stylist | Provide a lightweight secondary chat/action surface for questions such as “would white sneakers work?” without making chat the main UI. |
| FR-15 | Fit feedback | After a purchase or wear, optionally record “perfect,” “too long,” “too tight,” “too loose,” or “returned” to improve future recommendations. |
| FR-16 | Planning ahead | If a real forecast is not yet available for a future date, use season + user-selected conditions and refresh the recommendation when forecast data becomes available. |
| FR-17 | Purchase confirmation | Durably preserve outfit/product context before opening a retailer. On return or from a saved reference, offer a nonblocking Bought it? Add to closet action. Only explicit confirmation changes ownership; browser closure, a click, or a receipt-looking page is not proof of purchase. Ordered items stay Unavailable until the user confirms arrival. |
| FR-18 | Add bought item | After confirmation, review actual purchased size/color and optional brand/date/source link, then create or update the intended wardrobe record without duplicates. Recommended size is not automatically the purchased size. Support Camera, selected Photos (including screenshots), explicit Paste Image/Link, or text-only entry; photo may be added later. Best-effort metadata remains editable and unknown when unsupported. |
| FR-19 | Owned item photo | Offer Camera and Photos import to attach a user-provided image. If none is provided, use an app-owned representative image or a text placeholder. Save a retailer image as a lasting wardrobe asset only with explicit rights for that retailer and use. |
| FR-20 | Outfit snapshot | Show garments in a browsable closet grid and assemble any saved/draft look on a visual outfit board using user photos, labeled representatives, or appropriately licensed assets. Owned, wishlisted, inspiration, and not-arrived items stay distinguishable. Photo replacement preserves layout/relationships; preview and revert. Local collage export follows Section 13.5's media/measurement controls. |
| FR-21 | Export / import backup | Export a complete, versioned archive of user-created data and garment photos through Files, including iCloud Drive. Import with preview, validation, and explicit merge or replace choice. |
| FR-22 | iCloud recovery | With optional iCloud sync enabled, preserve records, retained unprocessed source photos, active derivatives, saved layouts, and meaningful drafts for recovery after reinstalling or replacing a device. Show pending uploads, errors, and last successful cloud acknowledgement; resolve concurrent edits without silent loss. |
| FR-23 | Monthly styling access | Use StoreKit 2 to purchase/restore monthly subscription access and show subscription management. Support verified complimentary access and the owner-sponsored policy in Section 14. If try-on/credit packs ship, use a separate verified consumable balance. Preserve closet and backup access after expiry. |
| FR-24 | Complimentary codes | Support Apple offer-code redemption for a non-consumable styling unlock, with verified entitlement restoration and no recurring billing for the unlock. |
| FR-25 | Adaptive iPad experience | Ship native iPhone and iPad layouts from V1, including comparative outfits, closet grid/detail, contextual swaps, and resizable-window support. See Section 7.2. |
| FR-26 | Feedback board | Let users browse approved ideas and development statuses, submit suggestions, and vote. Provide private issue reporting, moderation, report/block actions, and deletion. See Section 22. |
| FR-27 | Improvement analytics | Offer independent opt-in analytics with a strictly limited event schema, withdrawal, and retention controls. Local personalization remains separate. See Section 23. |
| FR-28 | Cloud AI consent | Before sending personal styling context to third-party AI, identify the recipient and data categories, obtain explicit permission, and enforce the permission on both client and server. See Section 15.4. |
| FR-29 | Usage and cost protection | Enforce cross-device allowances, request limits, atomic cost reservations, bounded retries, and global spending circuit breakers. Show understandable allowance/reset states. See Section 11.6. |
| FR-30 | Privacy and account controls | Provide data export/deletion, optional feedback-account deletion, consent withdrawal, accessible privacy/terms/support links, and accurate storage/deletion status. See Sections 15 and 24. |
| FR-31 | Durable drafts and undo | Autosave accepted edits locally, restore meaningful drafts after relaunch, provide bounded undo/redo, and acknowledge saves only after durable commit. Failed saves preserve the last saved version and recoverable draft. |
| FR-32 | Manual outfit editor | Create/edit saved looks, choose stored pieces, change layout, save in place, or save a copy without AI, payment, internet, or remaining AI allowance. |
| FR-33 | Resumable photo imports | Securely save an unprocessed source first, resume interrupted imports idempotently, and keep optional image processing separate with preview, skip, retry, and revert. |
| FR-34 | Wardrobe availability | Mark owned garments Available, Dirty, Unavailable, or Archived locally. Exclude ineligible items by default; a visibly confirmed per-request override permits only selected stored IDs. Wearing does not automatically mark an item Dirty. See Section 7.3. |
| FR-35 | Use only my wardrobe | Enforce strict current stored-item references and availability on both provider output and client application. Never substitute hypothetical pieces; explain insufficient inventory and require explicit user choice to change mode. |
| FR-36 | Upfront capacity and access | No artificial subscription-dependent closet/outfit count cap in V1. Disclose pricing, AI allowances, import bounds, storage/recovery requirements before setup/work. The 1,000-item/500-outfit test dataset is a minimum validation target, not a product limit. |
| FR-37 | Honest item states and tags | Distinguish inspiration, wishlisted, owned, and user-confirmed purchased items. Only owned/confirmed-purchased items count as inventory. AI-inferred tags are editable suggestions with provenance; unknown brand, size, fabric, and exact fit remain unknown. Generic imagery is labeled as a placeholder. |
| FR-38 | Archive and recoverable deletion | Offer Archive to retain garment history, or Move to Trash with a disclosed 30-day recovery window. Permanent deletion removes the item's personal content and associated image copies, including retained edit history, with an explicit scope preview. See Section 7.4. |
| FR-39 | Search and recommendation feedback | Provide offline text search across category, color, brand, and notes without mandatory tags. Offer reversible too dressy / not my style / wrong weather / don't suggest again feedback and use recent local outfit history to reduce repeats. |
| FR-40 | Migration and conflict safety | Prototype versioned migrations, file/record recovery, and offline multi-device conflicts before confirming the persistence stack. No destructive partial migration or silent conflict overwrite; retain a verified recovery path. See Section 11.7. |
| FR-41 | Ask another stylist | Optionally select a look or closet items, locally render a legible collage/contact sheet, and prepare an editable prompt without calling any AI API. Preview, Share, Save Image/File, Copy Image where supported, and Copy Prompt remain available offline and after styling expiry. Receiving-app support varies; save/upload + paste is the fallback. No automatic external answer import, ownership change, or fit guarantee. See Section 13.5. |
| FR-42 | Product and support website | Provide a compact companion website with a truthful product demonstration, pricing/free-core explanation, fit and AI limitations, FAQ, About, support/legal links, feedback and release notes. Use the grouped footer and staged content plan in Section 22.3; the website does not add primary app navigation or require an app account. |
| FR-43 | Versioned release notes | Publish read-only, dated notes for public app versions describing user-visible changes, addressed issues and known limitations. Link only approved public feedback; private tickets and personal content remain private. See Section 22.2. |
| FR-44 | Optional early-user emails | Offer independently opted-in welcome and check-in emails for interested early users, with reply, unsubscribe and deletion controls. Never reuse ticket, Apple identity, billing or analytics contacts to populate the list. Participation is unrelated to app access; the program is optional and can follow the core launch. See Sections 15.4 and 22.4. |
| FR-45 | Contextual help library | Provide short task-based help in the relevant app screens and on the website. Essential in-app help works offline and remains accessible without an account or styling entitlement. Content follows the actual shipped behavior and does not invoke AI or upload wardrobe data. See Section 22.3. |
| FR-46 | Adult public launch scope | Target adults 18+ and initial United States App Store distribution. Approve proportionate age eligibility for personal cloud services, truthful age-rating/EULA handling and applicable privacy processes before release. Age eligibility is separate from AI consent. See Section 24.2. |
| FR-47 | Regional expansion foundation | Reuse the same app with separate storefront/service configuration, localizable presentation, explicit units and raw size/currency contexts. Additional countries require their own launch evidence and Lily regression checks; no automatic worldwide enablement or promise that every expansion avoids an app update. See Section 11.8. |

## 7. Screen-Level Requirements

| Screen | Required elements |
| --- | --- |
| Onboarding | Petite-focused intro; skippable profile/measurements; optional fit/style preferences and budget; pricing/AI limits and privacy explanation before substantial setup. |
| Home / Style Me | Affirmation; occasion chips; weather/temperature; season; optional starting-point field; Suggestions / Use Only My Wardrobe mode; primary Style Me button. |
| Results | Three horizontally swipeable or vertically stacked visual outfit cards; lane label; concise explanation; weather context. |
| Item swap sheet | Selected category; visual alternatives; Already Own; Find One; optional free-text “something else.” |
| Wardrobe | Visual grid with offline search by category/color/brand/notes; separate owned, inspiration, and wishlist views; editable tags, availability, Archive/Trash, source/processed photo preview, resumable import status, labeled placeholders, Add Item from Camera/Photos/Paste/text, and select-items collage/share. No complete closet required. |
| Saved | Saved outfits, optional intended date, missing/unavailable-piece badges, manual editor, recoverable drafts, and a separately labeled AI “create a variation” action. |
| Find One | Editable shipping country/budget; reuse saved fit preferences; a few actual product options with recommended size when supported, separate length evidence/unknowns, and source freshness. View at Store through permitted web sheet/external opening; restore context on return; optional unverified browser-search fallback; saved reference link; explicit “I bought this.” |
| Profile | Measurements, style preferences, budget, preferred retailers, AI/privacy settings, cloud/local model status where applicable. Optional Try-on Photo is shown only when the separately validated image feature is enabled; no body-photo prerequisite. |
| Bought item review | Confirm actual size/color/ownership and whether arrived; editable permitted metadata; Camera/Photos/screenshot/explicit Paste Image/Link/text; source-photo preview and optional local cutout; photo later; durable local save and optional Add to This Outfit preserving its other selections. |
| Ask another stylist | Selected items/look, readable numbered collage, editable locally assembled prompt, optional personal fields default off, media-rights preview, Share/Save/Copy controls, and manual upload/paste instructions if the destination does not accept both. |
| Feedback | Approved ideas, search/filter, status, vote, submit idea, My Submissions, report/block, and a separate private issue form. |
| Settings / Privacy & Data | Cloud AI recipients and permission, analytics toggle, iCloud status, export/import, Delete My Data, optional feedback account/deletion, support, terms, privacy, and subscription management. |
| Help / What changed | Contextual task instructions, offline essential help and read-only versioned release notes reachable from Settings; no extra primary navigation tab or forced walkthrough. Optional email participation is a separate explicit choice. |
| Styling access / allowance | Localized subscription terms, trial eligibility, meaningful usage allowance/reset time, restore/redeem/manage actions, and service availability. |

### 7.1 Visual theme and color palette

Design decision added October 3, 2026: Use a warm editorial theme that feels like a personal styling notebook. The interface should feel calm, polished, and approachable, with garment imagery as the main visual focus. Keep everyday actions familiar to iOS users.

Define colors as semantic asset-catalog tokens with light and dark appearances. The following values are the V1 design baseline.

| Token | Light appearance | Dark appearance | Purpose |
| --- | --- | --- | --- |
| Background | Ivory `#FAF7F2` | Warm charcoal `#1C191B` | Main screen background |
| Surface | White `#FFFFFF` | Soft charcoal `#292529` | Outfit cards, sheets, and input surfaces |
| Primary text | Ink `#29242A` | Ivory `#FAF7F2` | Headings, body text, and important labels |
| Secondary text | Taupe `#6E626A` | Pale taupe `#C5B8C0` | Supporting explanations and metadata |
| Primary action | Deep plum `#633B55` | Soft plum `#D9AFCB` | Style Me, selected controls, and key actions |
| On primary action | White `#FFFFFF` | Warm charcoal `#1C191B` | Text and icons on primary action fills |
| Accent surface | Dusty rose `#F0E0E5` | Muted plum `#432F3D` | Selected chip backgrounds and quiet emphasis |
| Success | Forest sage `#42634E` | Light sage `#AFCEB6` | Ownership confirmations and successful saves |
| Success surface | Pale sage `#E7EFE8` | Deep sage `#273B2D` | Already Own badges and success backgrounds |
| Divider | Warm gray `#DED5DA` | Muted gray `#51464F` | Decorative separators and card boundaries |
| Error | Deep red `#A12D39` | Soft red `#FFB3B8` | Errors, destructive actions, and validation text |

#### Typography and layout

- Use the system font through SwiftUI. Use its serif design for the app title and occasional editorial headings; use the default system design for controls, body text, and metadata.
- Use Dynamic Type text styles rather than fixed font sizes. Body text starts at the standard `.body` size, and layouts expand as text grows.
- Use an 8-point spacing rhythm, typically 16-point screen margins, 16-point card padding, and 16-point card corner radii. Occasion chips use capsule shapes.
- Place garment images on a consistent neutral surface with enough space to see their silhouette. Preserve the garment's actual colors; avoid decorative image filters.
- Use SF Symbols for navigation and common actions, with text labels for unfamiliar actions.
- Use restrained transitions for card changes and swaps, respect Reduce Motion, and provide a brief confirmation after saving or marking ownership.

#### Applying the theme

- Home emphasizes occasion selection, weather, the optional starting item, and one prominent plum Style Me button.
- Results use consistent outfit-card layouts. Each lane has its full name and a short explanation; color alone must never distinguish Safe/Simple, Stylish/Elevated, and Creative/Risky.
- Swapping a piece uses a native sheet with clear alternatives. Already Own uses sage styling, while Find One remains a secondary action.
- Wardrobe and Saved use quiet surfaces and consistent image proportions so items are easy to scan.
- Follow the system appearance preference for light and dark mode. Keep garment imagery accurate in both appearances.
- Validate final text/background combinations against a minimum 4.5:1 contrast for normal text and 3:1 for large text. Meaningful control outlines, icons, and focus indicators need 3:1 against adjacent colors; the decorative divider token must not serve as the sole control boundary. Provide at least 44-by-44-point touch targets and VoiceOver labels.

### 7.2 iPhone and iPad adaptive experience

iPad support is a V1 product requirement, not an enlarged iPhone screen or a later delivery phase. Preserve the warm editorial theme and native controls on both platforms. Layout decisions use available window width/height, size class, safe areas, and Dynamic Type rather than device-name checks or orientation alone.

| Available space | Required behavior |
| --- | --- |
| Compact iPhone or narrow iPad window | Native tabs/stack navigation, readable outfit cards, category swaps in a sheet or pushed detail, and one clear primary action. All three lanes remain accessible without squeezing their text. |
| Intermediate window | Use two panes where readable, or collapse into a stack. Reduce grid columns and move secondary inspection into a sheet. Preserve the selected lane, garment, and draft. |
| Wide iPad window | Sidebar navigation with Style Me, Wardrobe, Saved, and Feedback. Compare three outfit lanes side by side when readable card widths fit. Wardrobe presents an adaptive grid with selected-item detail; selected-piece swaps use a contextual pane/inspector so the current outfit stays visible. |

- Comparison and editing modes may use different pane arrangements. Collapse the inspector, then the sidebar, as space narrows; do not compress three lanes into illegible cards merely to retain a column count. Bound card and reading widths on large displays while using remaining space for useful content.
- Support portrait and landscape, system-supported multitasking and resizable windows, software/hardware keyboards, pointer input, and safe areas. Do not require full-screen iPad use. Multiple app windows are optional in V1; if enabled, coordinate drafts and storage safely across them.
- Resizing, rotation, keyboard appearance, or navigation between panes must preserve the current request, unsaved form/feedback text, selection, saved/generated result, and useful scroll context. These UI changes must not trigger another AI request.
- Offer contextual keyboard commands such as Search, Add Item, Save, and Escape-to-dismiss where meaningful. Support Full Keyboard Access, visible focus, and native pointer behavior; touch remains sufficient for every action.
- On iPad, allow dragging an owned garment into the starting-piece control and dropping a user image or product link into item review. Validate category/source, preview the change, and retain explicit ownership/save confirmation. Provide tap, Photos, and paste equivalents; drag-and-drop must not be the only route.
- Reflow text through the largest accessibility Dynamic Type sizes; reduce columns or stack content before clipping labels. VoiceOver announces garment descriptions, lane labels, selection, pending/error states, and available actions. Respect Reduce Motion and never identify lanes or ownership only through color.
- Load downsampled thumbnails lazily for closet grids. Keep image decoding, archive processing, and network work off the main UI path. Provide empty, loading, offline, sync-pending, error, and permission-denied states in each layout.

Design and validation references: [Apple layout guidance](https://developer.apple.com/design/human-interface-guidelines/layout), [split views](https://developer.apple.com/design/human-interface-guidelines/split-views), [keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards), [pointing devices](https://developer.apple.com/design/human-interface-guidelines/pointing-devices), and [drag and drop](https://developer.apple.com/design/human-interface-guidelines/drag-and-drop). Test requirements are in Sections 16 and 19.

### 7.3 Editing, draft recovery, and unavailable garments

- Keep a durable local draft separate from the committed outfit/profile/item. Accepted editor selection, swap, layout, and tag changes are committed to the draft before showing a successful save acknowledgement. Text drafts autosave within a target of one second and on field exit/navigation where possible; indicate pending/failed saving honestly. Immediate Already Own/availability controls instead atomically commit the canonical item state, so later styling reads the acknowledged change. Do not depend on receiving an app-termination callback to save work.
- Restore active meaningful drafts after relaunch or interruption, retaining selected pieces, layout, request text, and editor position where practical. Let the user continue or explicitly discard. Private feedback drafts remain private and must not auto-publish on relaunch.
- **Save** atomically updates the existing outfit ID/revision; **Save as Copy** creates a new ID. Autosaving a draft must not silently overwrite the previously committed look. Explicit Discard returns to that committed state. Failed writes retain the old committed version and any safely staged draft; low-storage errors never claim success.
- Provide undo/redo for routine item/outfit/layout/photo edits. Keep a recoverable history of up to 20 actions, capped at 100 MB and seven days, clearly indicate when history expires, and clear personal history immediately on Delete My Data. Irreversible account/data deletion is separate from routine editor undo. Keep old photo assets while needed by this bounded history or live references.
- Manual creation, piece selection/replacement, layout changes, editing, and saving work offline and remain free after trial/subscription expiry or AI quota exhaustion. AI generation/swaps remain distinct paid actions. A manual change must not silently call AI or present an old AI explanation as newly validated.
- Track an editor/closet revision on asynchronous work. A late AI, sync, or processing result cannot overwrite newer user edits; revalidate it and offer review/retry when its inputs are stale. Cancellable loading preserves the existing outfit/draft; cancellation stops UI application, but does not falsely claim a dispatched provider charge has disappeared.
- Availability is separate from ownership. Dirty/Unavailable/Archived garments remain in the closet and exports, but are ineligible by default for new AI looks/swaps. The user marks them Available again when ready; optional unavailable-until dates remain editable. Saved looks retain their composition with an explicit badge instead of silently dropping/replacing the item. Deleted records show a missing-piece placeholder and an intentional manual replacement action.

The default eligibility rule above permits an explicit exception: show the status and let the user allow individually selected Dirty/Unavailable/Archived item IDs for this request only. Include those override IDs in the validated request, preserve their stored status, and recheck them on response application. An override cannot make inspiration/wishlist, trashed, or permanently deleted items owned or eligible. Marking an outfit Worn does not change laundry status unless the user separately confirms it. Keep text search and Saved within easy reach; no optional tag is required to find or edit an item. Authentication refresh for AI, billing, or feedback must not block opening the local store or using free core actions.

### 7.4 Archive, Trash, and permanent deletion

- **Archive** intentionally retains the garment, images, and linked outfit history while excluding it from ordinary new recommendations. Unarchive restores normal selection. Archive and Delete have different labels and consequences.
- **Move to Trash** hides an item from active inventory and begins a visible 30-day recovery window, separate from the seven-day editor undo limit. Restore preserves its stable ID and links. Saved outfits show a removed-item badge; only Archive promises ongoing garment-history retention. Display the recovery deadline and offer Delete Permanently now. Trash uses storage and syncs its removal state.
- Before permanent deletion, preview affected images and outfit references. Purge garment metadata, image versions/thumbnails, associated drafts, undo/history copies, and garment content embedded in saved pieces. Retain only a neutral missing-piece placeholder and the remaining outfit layout; do not preserve the deleted garment in an old collage or conditional generated try-on image. Rebuild/invalidate derived collages and purge affected opaque generated images without silently paying to regenerate them. A genuinely shared asset may remain for another undeleted item, which the preview must disclose.
- Invalidate associated local personal result caches and clear the principal's normalized backend result cache when cloud styling was used; retain only necessary financial settlement state. Fence late AI/image/import/sync writes against deletion so they cannot recreate purged content. Provider-held prior context follows the disclosed processor retention/deletion terms; do not claim immediate erasure beyond the app's controlled copies.
- Permanent deletion and expired Trash generate content-free deletion markers to prevent stale devices or an old merge archive resurrecting the record. Apply pending purges when the app next runs; show pending remote deletion until acknowledged. Retained assets and Trash recovery must obey storage bounds, with earlier permanent purge requiring explicit user action. Delete My Data bypasses the recovery window and clears Trash/history immediately.
- New exports identify included Trash/expiry state and omit already purged content. Independently saved older archives cannot be erased by the app: disclose this and require an explicit reviewed recovery action if the user deliberately restores a deleted record from one. Routine merge/sync must honor deletion markers.

## 8. AI Stylist Requirements

The AI is a reasoning component behind a structured product experience, not the product UI itself. All providers must implement the same application-facing contract so the app can use Apple’s on-device model when available and a cloud model when not.

```text
StylistAIProvider
  generateOutfits(StyleRequest) -> OutfitGenerationResult
  suggestSwaps(Outfit, PieceCategory, UserContext) -> [SwapOption]
  explainChoice(Outfit) -> StylingExplanation

Providers
  AppleFoundationProvider   // when SystemLanguageModel is available
  CloudLLMProvider          // iPhone 12 and fallback path
```

Provider output must be structured JSON / typed data, not free-form prose. Every cloud response is normalized and validated on the backend against the same versioned application-facing outfit schema before it is returned. The client also validates the result before displaying it; local-provider output follows the same contract. This makes the UI deterministic and allows compatible cloud model changes without rewriting screens or releasing an iOS update.

OutfitGenerationResult has a successful OutfitSet of exactly three lanes or an explicit typed failure, verified InsufficientWardrobe, or GenerationNotCompleted outcome. Non-success is not a fabricated or incomplete OutfitSet and does not consume the successful-generation allowance.

Availability alone does not authorize cloud fallback: it also requires valid styling access, permission for the selected AI recipient/data categories, and available server budget. Declined or withdrawn cloud permission leaves closet, saved outfits, backups, and eligible on-device styling usable according to their normal access rules. Explain cloud requirements before a cloud-dependent user starts the subscription trial.

| Input context | Examples |
| --- | --- |
| Profile | Height, measurements, preferred fit, colors, style preferences, budget. |
| Request | Occasion, date/time, starting item, free-text notes. |
| Environment | Weather, temperature, precipitation, season. |
| Wardrobe memory | Known owned pieces, saved looks, fit feedback, rejected or favored colors/styles. |
| Product rules | Versioned conditional fit guidance selected from supplied profile/preferences and evidence, including the initial petite rule set; lane definitions, closet-first policy and separately requested missing-piece search. |

### 8.1 Suggestions and strict wardrobe-only mode

Suggestions is the default closet-first mode: use known owned pieces when suitable, clearly mark hypothetical pieces as suggestions, and deliver useful outfit ideas with **zero wardrobe photos or imported items**. A photo/cataloging step is never a prerequisite for initial styling. Adding items through Already Own remains gradual; trial eligibility, cloud consent, and ordinary service controls still apply.

Use Only My Wardrobe is an explicit strict mode. Every recommended piece must reference an actual currently owned, eligible WardrobeItem ID; eligibility means Available or individually allowed by the Section 7.3 per-request status override. Canonical stored metadata/images determine its identity and appearance. No invented ownership, fabricated garment attributes, shopping placeholders, or silently relaxed constraints are permitted.

- Include a bounded snapshot of eligible item IDs/metadata and its revision in the request. The backend validates every returned reference against that transient allowlist; the client resolves it against its actual current store and rechecks ownership, availability, and requested constraints before display/save. This must work with both local and cloud providers without creating a developer-held closet replica.
- If a piece is edited, deleted, or marked unavailable while a request runs, reject the stale composition or offer explicit review/retry. Do not substitute a different garment unnoticed.
- Locally preflight/search the complete current eligible store before selecting the bounded request snapshot. A shortlist/model failure is not evidence that the whole closet lacks suitable clothes. InsufficientWardrobe is reserved for verifiable missing inventory/required constraints (for example, no available item in a required category). Otherwise use GenerationNotCompleted with an honest selected-context explanation and review/retry; reselect/expand candidates only within token, attempt, and spending bounds.
- Verified missing inventory offers useful next steps: change constraints, mark existing items available, add an owned item by text, or explicitly switch to Suggestions. Do not require photos, silently enable shopping, or make unbounded retries to force three lanes. Never count a rejected/insufficient/incomplete result as a successful styling action.

Buying suggestions appear only when wanted and after suitable owned alternatives. Missing inventory does not automatically create a shopping checklist. A switch from a strict result to inspiration is a separately labeled user choice. Swaps preserve the other selected pieces, and the response validator compares their IDs/layout values with the submitted look. Prefer recent unused combinations where suitable; keep local recent-wear/save history and reversible feedback separate from optional analytics. Provide too dressy, not my style, wrong weather, and don't suggest this again controls. The last action creates a visible, reversible exclusion for the selected item or combination, not an unexplained global style change. Constraint validity takes precedence over variety; explain when the small eligible closet limits alternatives.

### 8.2 Saved looks, occasions, and reversible learning

Saved looks retain actual piece IDs, not just a standalone collage/photo. Let the user tag an occasion or ask “Where could I wear this?” using the selected outfit's canonical metadata, weather where relevant, and confirmed preferences. Any suggested occasion is editable. Save/like/reject/worn/occasion feedback informs reversible local personalization and optional minimum-context stylist requests; no model fine-tuning or photo transmission is required. A saved AI preview does not prove actual fit, ownership, wear or laundry status. Keep explicit real-world fit observations distinct. Reopening a look resolves its pieces and shows current availability/missing-item badges, while preserving its saved version.

## 9. Image Strategy

The app should not generate a brand-new AI image for every outfit. Runtime image generation adds cost, latency, and inconsistency and is unnecessary for the core experience.

| Image type | Source | Use |
| --- | --- | --- |
| Representative garment | App-owned/licensed or pre-generated asset library | Visual stand-in for concepts such as “white button-down” or “tan cardigan.” |
| Known exact item | Optional user photo | Used when the user wants the app to remember her exact garment. |
| Shopping candidate | Licensed/permitted catalog imagery only after the Section 13 prototype gate | Display actual product options within allowed cache/retention rules. Use a labeled text placeholder if imagery is not permitted; checkout stays in the browser. |
| Optional try-on | Generated personal appearance preview linked to source/outfit/item versions | Prototype-gated proposal in Section 9.2; not a size guarantee, wardrobe photo replacement, or required styling step. No launch inclusion/provider is committed. |
| Bought item | User photo or licensed lasting image; otherwise app-owned placeholder | Permanent wardrobe image after explicit purchase confirmation. Keep its source link separately. |

When the user marks a representative piece as Already Own, the app stores a wardrobe record and may use a generic app-owned image labeled **Representative image — add your photo**. It must not imply a verified photograph of her actual garment. She can attach her own photo later. When a user marks a shopping candidate Bought, the app offers the same photo step and saves the source link separately. Retailer product photos may be stored as permanent wardrobe images only where a license explicitly permits that use; Amazon API product images must not be cached permanently. In-app display permission does not establish export/third-party-AI permission: replace restricted catalog media with a labeled representative/text tile in the share preview or let the user supply her own garment photo.

### 9.1 Original-first, reversible photo handling

Preserve a durable unprocessed import source in app-controlled storage before optional cutout/crop/background processing. Retain the imported resolution and garment appearance, subject to disclosed file/decoded-pixel safety checks and privacy-preserving metadata sanitization; do not silently replace it with a small processed image. The app copy must remain usable if access to the source Photos item is later lost. Downsample display thumbnails/derivatives rather than overwriting the source.

- Optional on-device processing has Original / Processing / Ready / Failed states, with Skip, Cancel, Retry, Preview, and Reset to Original. It must not block creating/editing/saving the wardrobe item or a look. Preserve color, pattern, silhouette, logos, and visible garment details; compare original and proposed result and fall back to the original when extraction loses them. Enhancement is an optional reviewed derivative, never an unnoticed replacement.
- Store source and derivative revisions separately. Replacing a photo preserves wardrobe ID, piece references, and per-outfit frame, scale, rotation, ordering, and crop/fit settings. Fit the new image into the existing frame, independent of pixel dimensions; preview the impact and support revert. An unsuccessful replacement leaves the previous usable photo intact.
- Import jobs record stable job/entry IDs and per-file status. Stage a complete validated source, then atomically link asset and item; resume pending entries and retry individual failures without duplicate garments. Do not deduplicate two legitimate identical garments solely from an image hash. Pause/cancel retains completed entries and makes the remaining state explicit.
- Check free space and safety bounds before staging/processing; handle sources that require iCloud download, permission loss, corrupt media, interrupted copying, and low storage. Recover/clean orphaned staging files safely on relaunch. Saved does not mean processing finished or iCloud uploaded.
- Source retention supersedes the earlier optimized-only default. Sync/export/restore includes retained sources and active derivatives; explain storage needs and any explicit source-removal choice. If a user deliberately frees an original, explain that full-source recovery/revert is no longer available; never remove it silently to meet a hidden item limit.

Accept optional batch photos, user-provided screenshots, and manual entries. Start with at most two concurrent image-processing jobs and one full-resolution decode per worker, use downsampled UI previews, and lower concurrency under memory pressure. Verify a 50-photo batch on iPhone 12; pixel/file limits must be disclosed in import preflight. Source copying, decoding, and archive work stay off the main UI path. AI/image-derived category/color tags remain editable suggestions, separate from user-confirmed values. Leave ambiguous brand, size, fabric, ownership, and exact fit unknown rather than inventing them. Preview, saved-view, and exported-collage rendering use the same versioned normalized layout rules; compare the same canvas so saving does not change the composition.

### 9.2 Optional Generate Look: consolidated feasibility research

Research checked October 3, 2026. **Optional prototype-gated proposal; no provider selected, API purchase, personal-photo upload, generated sample or quality test performed.** This supersedes the original categorical try-on exclusion without committing it to V1. Core launch does not depend on this image service. All eight TO checks below are Not run.

A reusable clothed full-body reference plus usable actual-garment photos would produce an AI visual preview saved with exact outfit/item/image revisions. Choosing/swapping clothes does not automatically generate or charge for pictures. Ordinary styling, the local collage/manual editor, saved-look viewing and export remain available without a body photo, image service or image allowance. Outfit/occasion learning uses editable confirmed metadata and feedback; no body-photo fine-tuning is required.

#### 9.2.1 Proposed user experience

1. **Optional profile photo.** In Profile → Try-on Photo, select/take a clear full-body image, standing naturally in fitted, fully clothed athletic wear with good light and visible limbs. Save a durable local source, sanitize metadata, and optionally include it in private iCloud/export. Basic styling has no body-photo prerequisite. Photo framing can be adjusted/replaced; never infer precise body measurements from it. [FASHN photo guidance](https://help.fashn.ai/using-fashn/studio/try-on) supports fitted clothing and clear standing views.
2. **Build from her clothes.** Select actual closet items or open a saved/generated outfit. Show the selected item images and available/owned status. Preview mode for wishlisted/not-arrived pieces is separately labeled. Actual-item try-on needs usable actual-garment images; a generic placeholder cannot silently become a faithful rendering of her garment.
3. **Explicit Generate Look.** Preview the reference/garments, supported pieces, processor, and image allowance/cost treatment. Obtain image-purpose permission before the first third-party dispatch. For an initially supported dress or top/bottom pair, request one output. Do not promise shoes/layers/accessories until the selected pipeline passes their checks.
4. **Keep working.** A durable job shows Queued / Generating / Saving / Ready / Failed / Cancel Requested. She can leave and return while local browsing/editing continues. Only a bounded polling/status operation runs on resume; no duplicate inference. Cancellation may not stop a provider that has already started or reverse its charge.
5. **Review and save.** Show the result next to its source garments, labeled **AI visual preview** with concise access to the size/detail limitations. Offer Save Look, Reject, Swap, and explicit Regenerate. Swapping changes the outfit board first; a new image requires another explicit action. Request preservation of appearance/proportions and garment details, but disclose that the rendering may differ.
6. **Revisit by occasion.** Save the picture, exact outfit/item IDs and image revisions together. She can tag Brunch/Office/Date Night, ask “Where could I wear this?”, or say “I like this for dinner.” The stylist can use stored garment metadata and confirmed preferences to suggest editable occasion labels without receiving the body photo again. User-confirmed occasion/like/worn feedback improves reversible local personalization; saving a generated image is not evidence of actual fit or wear.
7. **Optional missing-piece search.** First offer combinations/swaps from eligible owned items. If she explicitly requests a missing garment, use the existing fit-aware Find One and purchase-capture flow. Image generation never creates a purchase, marks an item owned, or adds a shopping checklist.

The preview is an approximation of appearance, not a sizing engine. A plausible rendering can depict a garment fitting even when the real size would not. Keep size-chart/fit-service evidence separate from the generated photo. [Google's own try-on guidance](https://support.google.com/googleshopping/answer/16253678?hl=en) distinguishes visualization from actual fit. “Learning her style” does not require fine-tuning a model on her body photo.

#### 9.2.2 Provider capabilities, input limits and sources

Published USD rates checked October 3, 2026; verify the selected configuration and contract before billing. Prices are per generated output unless noted. These are distinct approaches, not equivalent quality estimates.

| Candidate | Documented capability | Published starting/example cost | Main prototype question |
| --- | --- | --- | --- |
| Seedream 5.0 Lite editing through fal | General image editor with up to 10 reference images | $0.035/output | Can person-plus-separate-garment references preserve the actual clothes, appearance and body proportions? Multiple references do not establish VTO fidelity. |
| Google Virtual Try-On | Person + one clothing image; up to four outputs | $0.06/output | Useful single-garment/dress baseline; no arbitrary separate-item outfit array is established. |
| FASHN v1.6 direct API | Person + one garment reference; tops/bottoms/one-pieces | $0.075/output on demand | Dedicated single-garment baseline; rendering an outfit from one reference is not support for separate closet-item arrays. |
| FLUX.2 Klein 9B + fal's VTO LoRA | Model-card example explicitly uses person + separate top + bottom | About $0.08 for three 1MP inputs + one 1MP output at $0.02/MP input/output | Promising two-piece prototype; verify exact metering, garment fidelity and commercial endpoint/adapter terms. Shoes and layered full outfits are unproven. |
| FASHN Try-On Max | Person + one product reference; broader item categories | Default balanced 1K: $0.15/output; documented modes range $0.075–$0.375 | Preview model; separate garment-array support is not established, and cost depends on mode/resolution. |

Sources: [Seedream Lite endpoint](https://fal.ai/models/bytedance/seedream/v5/lite/edit), [Google model](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/vto/virtual-try-on-001) and [pricing](https://cloud.google.com/vertex-ai/generative-ai/pricing), [FASHN v1.6 API](https://docs.fashn.ai/api-reference/tryon-v1-6), [FASHN Max API](https://docs.fashn.ai/api-reference/tryon-max) and [on-demand credits](https://help.fashn.ai/plans-and-pricing/api-pricing), [fal's VTO model card](https://huggingface.co/fal/flux-klein-9b-virtual-tryon-lora) and [metered endpoint](https://fal.ai/models/fal-ai/flux-2/klein/9b/base/edit/lora).

Seedance is a video model family; Seedream is the still-image family relevant here. [BytePlus model catalog](https://www.byteplus.com/en/product/modelark). The user's “hyperseed” may mean Higgsfield, but that name is unconfirmed. [Higgsfield has a developer API](https://higgsfield.ai/creator-hub/help-center/integrations/what-is-the-higgsfield-api) with separate API billing; no specific try-on configuration/rate was verified for this project. Do not infer API access, input support or charges from a consumer site's subscriptions or multi-product UI.

#### 9.2.3 Image-cost scenarios

Arithmetic assumes one billed output per preview, no retries/sequential edits, and the exact listed mode. These estimates exclude text-stylist calls, storage/egress, hosting, failed-but-charged attempts, taxes, and payment fees. Three daily image generations are different from three daily app visits.

| Example rate | 10 outputs/month per user | 3 outputs/day × 365 days per user | 10 outputs/month × 10,000 users |
| --- | --- | --- | --- |
| Seedream Lite, $0.035 | $0.35 | $38.33 | $3,500/month |
| Google, $0.06 | $0.60 | $65.70 | $6,000/month |
| FASHN v1.6, $0.075 | $0.75 | $82.13 | $7,500/month |
| FLUX two-piece example, $0.08 | $0.80 | $87.60 | $8,000/month |
| FASHN Max default, $0.15 | $1.50 | $164.25 | $15,000/month |

Measure **cost per accepted saved look**, including paid rejected outputs and retries, rather than only the cheapest API image. Two single-garment passes can double image fees and damage an earlier garment; automatically generating all three outfit lanes multiplies outputs. Use one explicit output, reuse saved images, and offer regeneration only as a new clear action.

US$9.99/month is a candidate reopening the previous fixed US$4.99 assumption. With an eligible one-month trial and eleven retained paid months in a first-year cohort, gross subscription receipts would be $109.89 at $9.99 or $54.89 at $4.99, before fees/taxes and all service costs. Ten outputs per month is an illustrative beta scenario, not a chosen public allowance. Section 14 is authoritative for the included service allowance, optional non-expiring purchased wallet and Lily's separately authorized sponsored budget. Final quantities, pack prices and trial treatment require measurements; no automatic overage charge or unlimited public-generation promise.

#### 9.2.4 Image records, jobs, rights and personal-photo handling

Add a separate server-configurable TryOnProvider/image-job contract to the existing credential gateway and atomic reservation ledger. Keep the text-stylist outfit contract intact. Cloud model changes stay configurable, but recipient/terms/schema changes cannot bypass image permission or released-client compatibility. Keep image processing disabled until its quality, privacy and cost gates pass.

| Proposed record | Purpose |
| --- | --- |
| TryOnReference | Local source asset/hash/version, selected reference, optional private sync, deletion generation; independent of measurements and public account |
| TryOnJob | Stable ID/idempotency key, authenticated styling principal, outfit/reference/item/image revisions, selected provider/model/config, permission and financial reservation, finite deadline, status/cancel/settlement state |
| GeneratedLook | Durable downloaded result asset/hash, associated outfit/revision and item/image versions, job/config/source lineage, supported/unsupported pieces, saved date and AI-preview label |
| OccasionFeedback | User-confirmed occasion/like/worn/rejected association, local preference revision and reversible edits; separate from real-world FitFeedback |

- Keep reference and accepted output files local/private iCloud by default. Download/validate/atomically save the accepted image before acknowledging Saved; an expiring vendor URL is not the saved artifact. Sync/export includes retained reference/generated assets and their item relationships, with preview and personal-photo disclosure.
- The current text gateway still rejects unsolicited photos. Only an enabled, authenticated, separately consented image route accepts bounded approved uploads. Remove GPS/metadata from upload copies, validate bytes/pixels/types/counts, use private short-lived media access, and keep payloads/portraits/garment photos/signed URLs out of logs and analytics. Do not replace the local source with an upload-sized derivative.
- Actual garment reference images must be user-provided photos or licensed for this processor, image transformation, saved output and any export. A retailer's in-app display permission or product link does not authorize try-on processing or a generated-image export. Restricted assets use the regular labeled collage/manual flow until she adds a usable own photo.
- A proposed image job may need a bounded asynchronous deadline longer than the text gateway's 30 seconds. Start with one output and a finite 120-second overall job target for tested configurations; status by ten seconds, leave/resume and best-effort cancellation. Timeout is not proof of no charge. No unbounded polling, queue, retries or silent quality rerolls. Confirm actual latency before promising a completion time.
- Reuse the shared ledger for every image attempt, including pending reservations, provider charges, image/category/global budgets and cross-device idempotency. Reserve multi-pass/MP/multiple-output costs conservatively before dispatch. Keep text/image allowances, customer purchased-credit balance and owner-sponsored budget distinct; customer units are not provider dollars. Sponsor policy replaces public quotas but still obeys technical/global admission. Fail closed with unavailable pricing/ledger/permission; do not reuse the ten-full-styling-requests-per-day allowance as image allowance.
- Preserve exact input revisions. A late output cannot overwrite newer outfit edits or recreate deleted content; offer it only as the captured version when still authorized. Deleting a reference previews/purges dependent generated likenesses and staged/provider copies within actual processor controls; permanent garment deletion purges affected app-controlled opaque generated images under Section 7.4; independently exported copies remain outside app-controlled deletion. Delete My Data clears app-controlled sources/results/history/caches/jobs; remote completion and independently exported copies remain explicit.
- No reference image is sent to the text stylist merely to classify occasions. Prefer selected outfit metadata and optional explicit feedback. No body-photo/model fine-tuning or appearance scoring is required for personalization. Photo permission and prior text-styling consent do not authorize try-on processing.

Apple requires disclosed third-party-AI sharing permission and accurate retention/deletion behavior. [Current privacy guidelines](https://developer.apple.com/app-store/review/guidelines/#privacy). Record actual processor terms/settings, input/output storage, safety retention and processing location before enabling personal photos; do not promise no training or immediate deletion without contractual/configuration evidence.

Provider checks that materially affect selection:

- **FASHN direct:** documented base64 handling reduces temporary media retention; output URLs can expire quickly, and request records have separate retention. Do not put identifying content in prompt/URL metadata. Confirm the actual API account terms and successful/failed billing before selection. [Retention](https://docs.fashn.ai/api-overview/data-retention-privacy), [billing](https://docs.fashn.ai/api-overview/api-fundamentals).
- **fal-hosted models:** default CDN files can be read by anyone with their URLs. Configure and test input upload and output access/lifecycle separately; a payload-retention switch is not media deletion. Partner-model terms also matter. [File controls](https://fal.ai/docs/documentation/model-apis/file-access-controls), [payload retention](https://fal.ai/docs/documentation/model-apis/inference/payloads).
- **BytePlus direct:** current processing documentation describes longer safety-filter retention, including up to 180 days; an expired output link is not complete deletion. Review applicable terms/region before selection. [Data processing](https://docs.byteplus.com/zh-TW/docs/ModelArk/BytePlus_ModelArk_Data_Processing), [service terms](https://docs.byteplus.com/en/docs/legal/docs-service-specific-terms).
- **Higgsfield API:** its current terms allow training use by default unless an opt-out is processed, and metadata retention is separate. That must be resolved before any personal-photo pilot; a consumer subscription is not a privacy or API-rate contract. [API terms](https://open.higgsfield.ai/terms-of-service).

As an additional storage scenario, 50 saved generated images averaging 1–5 MB would add roughly 50–250 MB, plus the profile source, thumbnails, staging/history and sync/export copies. This is an assumption to measure, additional to Section 15.3's garment-photo estimates, which exclude generated previews.

#### 9.2.5 Conditional TO pilot/release checks

All checks are **Not run**. They apply before try-on is enabled, including a limited beta; original wardrobe recovery/privacy/payment controls remain mandatory.

| Gate | Required evidence | Status |
| --- | --- | --- |
| TO-01 Inputs and coverage | Verify actual usable garment photos, supported categories/item count/poses and requested outputs. Test a single garment first, then separate top/bottom; do not advertise shoes/layers/accessories based on an untested collage/pipeline. | Not run |
| TO-02 Fidelity | Prioritize Lily's consented reference and actual garments, then representative fixtures within the claimed coverage across heights/proportions/skin tones, poses, athleticwear, colors/patterns/logos and silhouettes. Compare identity/body and garment details against sources; no best-case-demo quality claim. Document accepted-look rate and unsupported cases. Broader categories/audiences need their own evidence and must pass Lily's prior scenarios before rollout. | Not run |
| TO-03 Personal-photo privacy | Named image-recipient permission, decline/withdrawal/recipient change, input/output ACL and expiry, log redaction, actual training/retention settings, source/output deletion and late-result fencing. No personal upload before these controls are verified. | Not run |
| TO-04 Durable saves | Force-close during upload/job/output-download/save. Relaunch resumes the same job without duplicate charges. Expiring result URL, low disk/corrupt output and interrupted sync/export preserve the prior look; fresh-install restore matches hashes/item/revision links. | Not run |
| TO-05 Budget and failure | Measure complete accepted-look cost and latency; exercise repeated taps, paid rejected outputs, ambiguity/retries, multi-pass charges, deadline/cancel, unavailable ledger and kill switch. If selling packs, pass PRD criterion 56 for transaction grant/debit/recovery/non-expiry/after-subscription use. Pass criterion 57 for authorized sponsored quota/budget policy. Show monthly allowance and purchased balance separately; no automatic extra charge. | Not run |
| TO-06 Version and deletion | Swap/edit a garment while generating, replace the reference, archive/Trash/permanently delete an item, withdraw consent, and Delete My Data during delayed completion. No stale overwrite/resurrection; saved versions remain accurately labeled and covered personal content is purged. | Not run |
| TO-07 Occasion learning | Ask for suitable occasions using metadata, edit/reverse tags, save/wear/like feedback, and relaunch/sync/export. Do not infer fit, wear, ownership or laundry status from a generated picture; no new image call for a metadata occasion question. | Not run |
| TO-08 Core independence | On iPhone 12/iPad and offline/expired subscription/image quota/provider outage, closet/manual editor/collage/saved-look viewing/export remain usable. Try-on photo stays optional; shopping appears only after explicit user choice. | Not run |

Recommended next evaluation: compare Seedream Lite, a dedicated single-garment baseline such as FASHN, and the documented two-piece FLUX adapter using consented test material only after processor/privacy approval. Choose by garment/body fidelity and cost per accepted look, not API sticker price. No vendor contact or contract has been performed.

## 10. Petite-First Styling Layer

V1 validation is intentionally Lily-first and petite-focused. The underlying FitRulesEngine is profile-driven from day one, with an initial conditional petite/short-proportion rule set. Its applicability follows supplied dimensions, confirmed fit issues and preferences; short height does not automatically imply a short torso, narrow shoulders or a particular clothing size. Petite support should be visible in relevant fit metadata, options and explanations. Confirmed preferences and garment evidence govern her result.

- Evaluate Petite / Short variants and relevant garment dimensions when product data exposes them. A regular or cropped garment with better documented fit may outrank a Petite label; the label alone is not evidence that a garment fits this user.
- Store height and measurements separately from weight; weight alone must never determine size.
- Track brand-specific fit feedback over time (for example: “regular sleeves run long” or “Petite S fits well”).
- Prefer garment proportions that are less likely to overwhelm shorter frames while respecting the user’s stated aesthetic.
- Never frame petite sizing as a beauty ranking; it is a fit/proportion constraint.
- Height and measurements are optional and editable. Offer inseam, rise, torso, sleeve, and fit preferences only when useful; missing values do not block styling. Petite does not describe a weight, and the user is not required to want to look taller. Explain guidance in terms of her stated fit and style goals, with no exact-fit guarantee.

Lily priorities confirmed October 3, 2026: prioritize nice occasions, casual outings and everyday polished looks; coordinated color variety; and trouser style/length guidance. Her supplied initial inseam preference is 25 or 26 inches. Preserve that editable preference without silently averaging it to an exact 25.5-inch measurement or applying it to every user. Confirm its body-versus-preferred-garment measurement basis or a well-fitting garment reference only when necessary for a pants comparison, together with desired hem/shoe context. Do not derive inseam from 4'11" height. Sleeve length is an editable fit dimension, not a confirmed primary complaint, and there is no blanket fabric exclusion. Keep optional fabric/comfort/coverage preferences and distinguish a stated firm requirement from a ranking preference. Previewing a combination remains useful without try-on; the conditional image pilot should evaluate her ability to judge a style before physical try-on while preserving its fidelity, privacy and cost gates.

### 10.1 Minimal setup for personalized fit

Personalized size and height/proportion guidance supports owned-clothes styling and the optional missing-piece finder; shopping does not define the primary experience. The preferred setup asks once for height, usual top and bottom sizes (including US/UK/EU or brand sizing), and preferred close/regular/relaxed fit. An optional reference is a brand, garment category, and size she confirms fits well; reuse existing confirmed wardrobe/fit feedback instead of asking again. No full closet, body photo, scan, app account, or retailer-account connection is required for ordinary styling. All inputs remain editable and skippable; skipped data reduces specificity rather than preventing basic styling. The optional try-on photo in Section 9.2 is a distinct image purpose and never creates precise measurements or validates physical fit.

Profile → Fit & Measurements offers optional inseam/preferred trouser length, sleeve length, waist and bust, with inch/centimeter display and clear measurement basis. Each value can be updated or cleared independently as her needs change; no full profile reset or new closet setup is required. Reuse Lily's supplied 25-/26-inch inseam preference rather than repeatedly asking for it. Other numeric values remain unknown until supplied. Preserve her petite styling goals and confirmed garment references while applying the current dimensions; petite does not require fixed waist/bust values or a weight-derived size. Updating a field is a local edit, not an AI call or automatic body-change tracking feature.

Ask a targeted follow-up only when it can improve the particular styling or fit question for owned garments or an optional purchase: inseam for trousers, for example, or desired crop-top length/coverage. Offer Skip and explain what remains unknown. Do not infer bust, waist, hips, torso, or sleeve dimensions from height and a size label. A brand's body-size chart and a garment's actual measurements are different evidence; any comparison must preserve that distinction and account for intended ease/stretch where known.

Keep style suitability, recommended size, and length/proportion evidence separate. A supported width/size recommendation must not imply verified crop length, rise, or sleeve fit. Use plain evidence such as “petite length offered,” “matches your confirmed size in this brand,” or “top length not provided.” Do not invent an accuracy percentage or promise perfect fit. Provider confidence is not a measured probability of success in this app; numeric confidence needs validation and an understandable meaning before display.

Retain optional Fits Well / Too Long / Too Tight / Too Loose / Returned feedback locally and include it in private sync/export. A return is not automatically a fit problem; accept an optional reason. Do not read retailer purchase histories or transmit feedback to a fit vendor without a separately disclosed, permissioned feature.

### 10.2 Flexible foundation and protection of Lily's experience

- Store supplied measurements as optional typed values or explicitly supplied preferred lengths/ranges with units, measurement basis/method where known, source, last update and confirmation state. Keep body dimensions, preferred garment lengths, chart ranges and actual garment dimensions distinguishable. Unknown is absent, never zero. Preserve confirmed well-fitting garment references; height/weight/photo cannot fill missing dimensions.
- Increment the profile revision when a measurement/preference changes. New recommendations and fit assessments use the current revision; revalidate in-flight results and mark earlier fit assessments as based on older profile context, offering explicit reassessment where useful. Preserve saved outfit compositions and assessment provenance; a profile update must not alter stored garment dimensions, silently regenerate a look or remove her petite preferences. Values need not be retained as a separate historical body-measurement timeline.
- Store size labels with category, brand/sizing system, source chart context and supplied fit/cut qualifiers. Preserve the retailer's raw label; no universal S/M/L conversion or assumption that Petite, Plus, Short or Tall are interchangeable or exclusive dimensions.
- Keep user-selected clothing/catalog preferences separate from measurements and identity. Future men's/women's/mixed coverage must be explicitly supported; do not infer department or style from a photo or gender. Optional fields do not require a broader launch UI or mandatory new setup.
- FitRulesEngine evaluates application-owned versioned rules against the profile, garment evidence and user goals. Separate universal constraints from the conditional petite rule set; contradictory/missing evidence stays explicit. Preserve profile/rule revisions in requests and assessments, with compatible schema changes and rollback under Sections 11.3/11.7.
- Personalization is scoped to the user's profile. Other users' feedback cannot directly overwrite Lily's preferences or fit history. Shared model/rule improvements require evaluation; her saved scenario suite must pass before rollout. Do not weaken her fit constraints to improve average adoption or catalog coverage.
- Establish consented local/pseudonymous Lily fixtures for confirmed fit references, sleeve/inseam/rise/coverage preferences, different occasions/weather, independent swaps, skipped/changed measurements, reversible fit/style feedback and failures. Do not derive a clothing size from the 110–130 lb range or require weight tracking. Evaluate recommendations with her feedback; record issues and resolve them before declaring her experience validated. Keep actual personal content out of diagnostics/analytics.
- Expansion uses the same core app and per-profile rule contract, with its own garment/sizing/source/quality tests and all existing Lily regression checks. Broader fit or try-on support is not achieved merely by adding a profile option or changing a prompt. Conditional cloud services remain subject to their own consent/cost gates.

### 10.3 Observed Lily usability sessions

Decision approved October 3, 2026: make Lily-first validation a repeatable observation routine alongside the existing fit scenarios, reliability tests and regression suite.

- Once a usable prototype exists, run a brief session of about 15 minutes weekly during active iteration and after material changes to the core flow. Rotate real tasks: choose an outfit for an occasion, use a starting garment, swap one piece, mark Already Own, save/reopen a look, or recover interrupted work. Optional finder/try-on tasks apply only when those services are enabled.
- Start with her confirmed situations: a nice occasion, a casual outing, and an everyday put-together look. Include her 25-/26-inch preferred trouser-length context and a coordinated-color comparison; ask whether the board helps her decide what to try on. Use her actual supplied/confirmed preferences rather than inventing a sleeve, fabric, measurement basis or cut requirement. Optional on-body-preview evaluation follows the TO gates and does not substitute for real fit feedback.
- Let Lily attempt the task without coaching. Record where she hesitates, makes a correction, needs help or abandons the task; ask what she expected after the attempt. If help is necessary, provide it and mark the completion as assisted. She may skip or end the session.
- For styling tasks, measure time from beginning the task to a look she says she would wear, together with steps/corrections, whether assistance was needed and whether she could save/reopen it. For add-item, editing, saving or recovery tasks, record completion time, errors and assistance instead. Record device/build and separate setup, interaction and provider waiting time. Record no acceptable look when appropriate; do not force a selection or turn a fast unusable result into success. This is a self-reported usefulness signal, separate from actual wear and physical-fit feedback; there is no unmeasured universal time target.
- Maintain a short decision log: task/scenario, build, observed friction, her explanation, proposed change, priority, retest build and result. Resolve the largest daily-use problems before expanding the experience; Section 23.2 data-loss incident priority still takes precedence. Add consented, minimized reproducible cases to the existing Lily regression suite.
- Use consented manual observation and private minimized notes, not automatic session replay, screen recording or wardrobe uploads. Notes should describe the interaction problem without copying measurements, wardrobe photos or raw prompts. Keep approved personal fit fixtures under Section 10.2's separate controls. This routine does not expand the Section 23 analytics schema or require analytics participation.

## 11. Technical Architecture

```text
iPhone / iPad SwiftUI app: adaptive styling, closet, saved, feedback
  |
  +--> Proposed SwiftData store: profile, closet, outfits, styling/fit feedback
  |      +--> Optional private CloudKit: records + sources/derivatives/layouts
  +--> WeatherKit / PhotosUI / Camera / Vision
  +--> StylistEngine + FitRulesEngine + AIProviderRouter
  |      +--> Profile/evidence-driven conditional petite rule set
  |      +--> Apple Foundation Model when eligible, within access rules
  |      +--> Cloud fallback when entitlement + recipient consent allow
  |             |
  |             v
  |           API Gateway --> Durable entitlement / consent / usage ledger
  |             |             Atomic quota + concurrency + cost reservations
  |             +--> Approved cloud model adapter --> Typed outfit validation
  |
  +--> Find One --> API Gateway --> Permitted product discovery adapters
  |                                  +--> Sourced product/variant validation
  |      <--> Local fit comparison + approved optional fit-service adapter
  |      --> Evidence-bearing product options --> Browser retailer checkout
  |
  +--> Local collage + prompt template --> Explicit native share/save/copy
  |      --> User-chosen external AI (no app/gateway AI dispatch)
  |
  +--> Optional Generate Look (disabled until prototype gates pass)
  |      --> Private image upload + durable job + approved TryOnProvider
  |      --> Durable local/private-iCloud result + outfit/item revision links
  |
  +--> Optional feedback account --> Moderated public board / private tickets
  +--> Optional consented analytics --> Allowlisted ingestion / aggregates

Product/fit adapters are a proposed V1 addition pending Section 13 validation.
Browser search remains a fallback; no arbitrary server URL fetching.
Private closet content is separate from developer-held service state.
```

### 11.1 Client technology

- SwiftUI for all primary UI and navigation.
- SwiftData is the proposed local-first baseline for profile, wardrobe memory, outfits, and personal styling/fit feedback, subject to the Section 11.7 recovery prototype. Offer optional sync through the user's private iCloud database, with local use available without iCloud. Public feedback-board data uses its separate backend service. Do not assume a framework supplies all image-file, migration, conflict, or restore guarantees automatically.
- WeatherKit for weather context.
- PhotosUI / camera APIs for optional garment photos.
- SFSafariViewController for a retailer web sheet where permitted, platform URL opening for external browser/store-app handoff, and native ShareLink/UIActivityViewController plus explicit clipboard actions for local sharing. Validate destination-specific behavior; do not promise every app accepts an image and prompt together. A bounded share-extension inbox for incoming links/images is a separate implementation task with the same durable import rules.
- Vision for on-device foreground extraction or image processing where useful.
- Foundation Models framework through SystemLanguageModel when the device is eligible and Apple Intelligence is ready.
- Minimum deployment target must support Lily’s iPhone 12; exact iOS floor to be chosen after device testing.

### 11.2 Backend responsibilities

- Protect cloud LLM and any selected catalog/fit-service credentials; never ship secret keys in the app bundle. Catalog/fit providers remain unselected pending Section 13 validation.
- Verify the relevant subscription, complimentary or purchased-image entitlement and enforce its approved public/sponsored policy plus technical/global controls. Lily's authorized sponsor policy does not inherit public daily/monthly service quotas; no client can bypass financial or permission admission.
- Normalize provider responses into the app’s typed schema.
- Validate every cloud response against the shared versioned schema and product rules before returning it; reject invalid results and use bounded retries or a configured fallback.
- Keep cloud model selection and supported inference settings in server configuration from day one; do not hardcode the cloud model ID in the iOS app.
- Cache safe repeatable results where appropriate (for example static garment metadata), while keeping personal wardrobe data local whenever possible.
- Collect minimal operational telemetry; no wardrobe/photo upload unless required by a selected feature and disclosed to the user.
- Maintain a durable entitlement/usage ledger and shared atomic limits across all gateway instances. A stateless function's memory is not an enforceable quota store.
- Host the optional feedback account, moderated board, private support queue, and consented analytics ingestion separately from the user's private closet. Apply access controls, retention, and deletion to each service.
- Route explicit shopping requests through configured permitted discovery/fit adapters with typed inputs, variant/evidence validation, timeouts, and shared cost reservations. Do not give the LLM unrestricted browsing, arbitrary MCP tool access, or control of purchases. Basic fit comparison stays on device where possible; sending personal fit context to an approved processor requires its named disclosure and permission.

### 11.3 AI provider routing

At request time, the app checks Apple Foundation Model availability. Apple documents that SystemLanguageModel availability can be unavailable because the device is not eligible, Apple Intelligence is disabled, or the model is not ready. Eligible devices use the local provider; Lily’s iPhone 12 uses the cloud fallback. The app-facing schema remains identical either way.

#### Server-configurable cloud model selection

The backend selects the cloud provider, model ID, and supported reasoning settings through server configuration from the first release. The iOS app sends a StyleRequest and receives the shared typed response; it does not depend on a particular cloud model name. A compatible model upgrade or rollback must require only a backend configuration change, with no app rebuild or App Store update.

- Keep provider-specific prompts, API parameters, and response normalization in backend adapters. Switching providers may require a new or updated adapter, while preserving the app-facing contract.
- Validate structure and product rules, including the three outfit lanes, valid piece references, and requested starting-item constraints. Schema compliance alone does not establish styling quality.
- Evaluate model changes on representative styling and swap scenarios before rollout, checking quality, constraint adherence, latency, and actual cost. Retain the previous configuration for rollback.
- Include Lily's Section 10.2 saved scenarios before any model, fit-rule or broader-coverage rollout; respect her confirmed fit/style constraints and preserve simpler daily interaction. Additional audiences cannot bypass this check.
- Support configured fallback routing for failures; introduce routing to a stronger model for difficult requests only when evaluation demonstrates a benefit and cost limits permit it.
- Treat the provider's legal recipient, data categories, retention terms, and approved model/cost bounds as part of versioned server configuration. A different recipient or material sharing change requires updated disclosure and permission before dispatch; a server-only model switch must never bypass consent.
- Preserve compatibility with released clients when evolving the schema. New fields or UI behavior that require client support may still need an iOS update.

### 11.4 Technology stack summary and open choices

The V1 application is a native iOS app written in Swift, built in Xcode. The following stack consolidates the architecture described above; it does not imply that an implementation already exists.

| Layer | Technology / decision | Status |
| --- | --- | --- |
| Language and UI | Swift and SwiftUI, with SF Symbols and semantic asset-catalog colors | Defined |
| Local persistence | SwiftData baseline for profile, wardrobe, saved outfits, and feedback | Proposed; confirm after migration/conflict/recovery prototype |
| Optional private sync | Private iCloud database, using CloudKit-backed persistence; local use remains available | Defined; schema and sync behavior require validation |
| Weather | WeatherKit | Defined |
| Photos and image processing | PhotosUI, camera APIs, and Vision where useful | Defined |
| On-device AI | Apple Foundation Models through SystemLanguageModel, gated by device and runtime availability | Defined for eligible devices |
| Cloud AI | CloudLLMProvider behind the same typed stylist contract; required for Lily's iPhone 12 | Provider and model to be selected |
| Shopping and fit | Permitted discovery adapters, variant/evidence schema, local fit comparison, optional specialist fit API/MCP behind the gateway | New V1 target; access, petite coverage, minimum inputs, privacy, and cost require the Section 13 prototype |
| Checkout and optional external AI handoff | Safari web sheet when permitted; external URL/app opening; local collage/prompt assembly and native share/save/copy | Specified; retailer exceptions and receiving-app compatibility require device tests; no external-AI API dependency |
| Optional personal try-on | Separate server-configurable image provider/job contract, temporary private uploads, atomic cost reservations, durable local accepted results | Feasibility proposal only; provider/terms/quality/allowance unselected; Section 9.2 and its TO gates |
| Client networking | URLSession and Codable for validated typed requests and responses | Defined |
| Backend | Serverless API gateway for cloud credentials, request validation, rate limits, and cost controls | Hosting platform, language, and authentication approach to be selected |
| Durable backend state | Transactional entitlement/usage and reservation ledger, consent records, optional feedback identities/posts/votes/reports, and moderation audit | Database/vendor TBD; atomic operations and separation from private closet required |
| Feedback identity | Optional Sign in with Apple for public submission/voting; browsing and core closet/purchases remain usable without this account | Defined; token verification, revocation, and deletion required |
| Product analytics | First-party allowlisted events, optional consent, bounded ingestion/retention, and aggregate dashboards | Defined; storage/operations implementation TBD |
| Testing | Unit tests for schemas, routing, learning, weather, and swaps; UI tests for the primary styling flow | Defined; test framework to be selected during implementation |
| Distribution and billing | Free App Store download; StoreKit 2 monthly subscription, non-consumable complimentary unlock via Apple offer codes, and conditional consumable image packs | One month free for eligible users; US$9.99/month is a new candidate, final price/allowances/product IDs TBD. Owner-sponsored usage is separate from public quotas. |

Choose the minimum iOS deployment target after verifying framework availability and testing on Lily's iPhone 12. Gate newer framework features behind availability checks. Private sync and the cloud gateway must not make an app-specific account mandatory for the core local experience.

### 11.5 Weather integration and cost notes

Use Apple WeatherKit for current conditions and forecasts that inform layers, fabric, footwear, and precipitation suitability. WeatherKit offers a native Swift API on iOS 16 and later, with forecasts extending up to 10 days. For dates beyond the forecast window, use season and user-entered conditions rather than presenting an unavailable forecast as known.

#### Included allowance and paid usage

Pricing checked October 3, 2026, in USD; recheck before launch.

- WeatherKit includes **500,000 API calls per month per Apple Developer Program membership**, shared across that membership's apps and users. This is not a per-user allowance.
- Apple Developer Program membership is **$99 per year** (or local equivalent) and also covers app distribution. Within the included quota, weather has no additional usage charge.
- Higher monthly quotas cost **$49.99 for 1 million calls** or **$99.99 for 2 million calls**. Unused calls do not roll over.
- The developer pays these costs; app users do not need their own weather API subscription.

Planning estimate: one weather request per session, three sessions per day, and a 30-day month.

| Daily active users | Estimated monthly calls | Within included quota? |
| --- | --- | --- |
| 1,000 | 90,000 | Yes |
| 5,000 | 450,000 | Yes |
| 10,000 | 900,000 | No; requires a higher quota |

These estimates exclude extra refreshes, retries, and requests for other locations or dates. Measure actual API usage during beta testing.

#### Request handling and user experience

- Reuse the session's weather snapshot for outfit generation, regenerations, and item swaps. Fetch again when the location or planned date changes, or the snapshot becomes stale; define freshness limits during implementation.
- Request only the weather data needed for styling and monitor the membership's monthly usage.
- Allow manual location and weather overrides when location access is declined or WeatherKit is unavailable. Label stale data and manual overrides clearly.
- Display the required Apple Weather attribution and legal link wherever weather data is shown, following Apple's current attribution requirements.

Sources: [Apple WeatherKit pricing, availability, and attribution](https://developer.apple.com/weatherkit/) and [Apple Developer Program membership](https://developer.apple.com/programs/).

### 11.6 Cloud service abuse and cost protection

These are V1 requirements. The gateway must protect developer-paid services for trial, paid, complimentary, purchased-credit, and owner-sponsored users alike. The following are proposed public launch defaults, not Apple/provider limits; validate them against real usage before publishing the allowance or enabling production billing. Controls live in versioned server configuration and cannot be overridden by client input. Lily's authenticated owner-sponsored policy may replace public daily/monthly service allowances and principal spending budget with separately approved values; it never bypasses input bounds, idempotency, technical throttles/concurrency, permission, or global financial admission. A public complimentary code alone does not authorize that exception.

#### Allowances and request bounds

| Control | Proposed starting setting |
| --- | --- |
| Successful full cloud generations/regenerations | 10 per styling principal per rolling 24 hours; one generation returns all three lanes |
| Successful cloud swaps + Ask Stylist | 40 combined per styling principal per rolling 24 hours |
| Rapid-request throttle | At most 5 AI actions/minute per principal, with additional installation/short-lived IP abuse limits |
| Concurrent expensive work | 1 in-flight action per principal across all devices; a bounded queue must not accumulate unattended work |
| Provider attempts | At most 2 total per action, including retry, JSON repair, stronger-model escalation, and fallback |
| Provider input | At most 8,000 model tokens, including system rules and selected closet context; retrieve relevant records instead of sending the whole closet |
| Output including billed reasoning | At most 3,000 tokens for a full generation; 1,000 for swap/chat, enforced using the selected provider's supported charge-bounding controls |
| Request payload | At most 64 KiB, with free-text notes at most 2,000 characters; validate field sizes, collection counts, enums, and nesting |
| Idempotency | Retain action keys and content fingerprints for at least 24 hours; duplicate delivery must reuse the same in-flight/completed action |
| Overall deadline | Initial cloud-action deadline 30 seconds across all attempts; bound each attempt and any backoff within this deadline |
| Internal beta inference budget | Public-policy initial guardrail US$1 per principal per rolling 30 days, including failures/retries; validate before launch. Owner-sponsored usage needs its own approved principal budget; set approved production values for each policy. |
| Global financial exposure | Explicit daily/monthly budgets per environment and provider are required before external testing; unset/invalid budgets disable expensive dispatch |

These token/payload/deadline defaults govern text styling. They do not authorize photo uploads or unlimited image generation. If Section 9.2 is enabled, its separate image route requires approved finite upload/pixel/input/output bounds, asynchronous job deadline and category allowance while still obeying shared aggregate principal/global reservations and concurrency controls. The public US$1 guardrail must not be silently exceeded by image work; revise/approve combined public budgets and the separate owner-sponsored budget before an image pilot. Purchased credits authorize customer usage, not a bypass of financial reservations; their approved cost ceiling must support the advertised redeemable service. Metadata/status calls keep normal bounded request behavior.

Public daily allowances must support the intended three-session day and reasonable experimentation. Disclose the shipped limits before trial/purchase and in Settings; never advertise unlimited AI. Do not silently reduce an existing paid period's promised allowance through remote configuration. Internal cost cutoffs must not routinely prevent advertised normal usage: if testing shows that they do, change pricing, model/caps, or approved budgets before release.

Count successful user actions against the daily allowance. Failed work does not consume that successful-action allowance, but its attempts still consume defensive throttles and developer spending budgets. Reserve pending successful-action slots atomically so concurrent calls cannot oversubscribe them. Display remaining cloud allowances and the next availability time. Distinguish a short throttle delay, daily exhaustion, entitlement expiry, and temporary service shutdown; preserve input and personal data in every case. Limits never create an automatic charge or paid top-up. Eligible on-device AI follows the same access and schema rules but does not consume cloud inference allowances; label the allowance accordingly.

#### Identity and atomic financial admission

- Authenticate short-lived backend sessions and verify signed Apple transactions, app/product/environment, expiry, and revocation before paid work. Establish a durable pseudonymous styling principal from verified entitlement evidence, independent of an optional feedback account. Document the accountless purchase/restore authentication flow before launch; client IDs or a client-supplied transaction ID alone are insufficient.
- Aggregate usage across iPhone/iPad installations and restored entitlements. Reinstall, a new attestation key, a device switch, restoration, consent withdrawal, or deletion of closet/analytics/feedback-account data must not reset the associated allowance. Keep only the minimum legally permitted usage-window anti-abuse state, separate from deletable personal content and disclosed in the retention policy. Explain any supported Family Sharing and entitlement-merging behavior before enabling it; avoid simultaneous subscription/complimentary entitlements minting duplicate budgets.
- Supplement with App Attest on supported devices. Validate the app/environment, one-time server challenge, request binding, and replay counter. Provide a documented bounded recovery path for unsupported or temporarily unavailable attestation; it must not grant unrestricted API access. App Attest is an abuse signal, not proof of payment. Shared IP addresses alone must not permanently deny a legitimate subscriber.
- Before **every provider attempt**, estimate a conservative maximum cost from validated input, current approved prices, output/reasoning limits, and per-call charges. Atomically reserve that cost against principal, provider, and global daily/monthly budgets in a durable shared ledger. Include settled cost **plus outstanding reservations** when deciding admission. All gateway instances/regions must share the same enforceable state.
- Dispatch only after entitlement, consent, schema, rate, successful-action slot, concurrency, and financial reservations succeed. Settle reported actual usage afterward. Each second attempt needs another reservation. A fallback or new model never bypasses the ledger.
- An ambiguous timeout or disconnected client is not proof of zero cost or provider cancellation. Keep the conservative financial reservation until reconciliation establishes the outcome; a worker lease expiry must not erase it. Do not blindly retry an uncertain paid dispatch. Missing usage is not zero usage.
- If entitlement/consent verification, the ledger, pricing, or charge-bounding configuration is unavailable, fail closed for new expensive requests and preserve local functionality. No in-memory-only counter, client-only limiter, or read-then-increment race satisfies this requirement.
- Same action key with changed content is rejected. Duplicate delivery returns the existing status/result without another quota debit or dispatch. Encrypt any normalized personal completed-result cache, scope it to its principal, and expire it within 24 hours; raw prompt/response retention in logs is prohibited. Recheck current consent/deletion version before saving or delivering a delayed personal result; after withdrawal/deletion discard it and do not recreate the cache. Recheck recipient permission before each retry/fallback. Financial settlement still accounts for already dispatched work without retaining its personal content.

#### Operational defenses and other metered services

- Alert the operator at 50%, 75%, and 90% of financial budgets; stop new admission at the configured ceiling. Provide immediate global and per-provider kill switches, including the ability to disable costly features. Apply vendor-side hard limits where actually supported and distinguish them from alert-only dashboards.
- Bound execution time, input parsing, queue depth, response size, background jobs, and ingestion rates. Retry transient errors only with bounded backoff/jitter and the total attempt budget; do not retry invalid requests, authentication failures, quota/budget rejection, or permanent errors.
- Monitor hosting/database/storage/egress, product discovery, specialist fit, feedback, analytics, and WeatherKit costs separately from model tokens. Metered shopping calls use the same verified styling principal and shared reservation ledger, with their own disclosed allowance finalized after the Section 13 prototype. Use deployment/platform quotas and public-endpoint/WAF limits so unauthenticated floods cannot run unbounded functions or fill databases. Close submissions/ingestion temporarily during abuse; retain closet/support access where possible.
- Weather uses the unchanged-location/date session snapshot for at least 30 minutes, coalesces simultaneous lookups, and allows at most one automatic retry. Explicit new location/date requests and expired snapshots may refresh. Warn at 75%/90% of the membership quota and switch to clearly labeled cached/manual conditions before an exhausted allowance creates repeated failures. Any shared weather cache must respect Apple terms and avoid retaining precise personal locations.
- Base V1 garment photos remain local/private iCloud except the user's explicit local export/share in Section 13.5; the text-styling gateway rejects image uploads. The optional Section 9.2 image route stays disabled until separate named permission, encoded-size/decoded-pixel bounds, metadata removal, deadline, retention, deletion and cost gates pass. Only that validated route may accept approved images; unsolicited/unauthorized uploads are rejected. Local collage/template sharing itself invokes no model or paid fit/search service.
- Do not fetch arbitrary pasted retailer URLs on the backend in V1. Treat notes, garment descriptions, imported records, product links, and model output as untrusted data. They cannot change entitlements, budgets, provider/model selection, prompts' authority, credentials, or tool permissions. V1 AI has no arbitrary tool/code execution.
- A model rollout must pass quality, schema, consent compatibility, price/output-bound, latency, and budget checks. Keep an audited rollback. A more expensive model is not permitted to silently invalidate published allowances.
- These controls bound authorized dispatch and reduce exposure; exact invoices can still differ due to in-flight work, vendor billing/reporting, infrastructure charges, or compromise. Maintain emergency key rotation, kill-switch, reconciliation, and incident procedures.

Security references: [Apple App Attest server validation](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server), [attestation availability](https://developer.apple.com/documentation/devicecheck/dcappattestservice/issupported), and [OWASP API resource-consumption guidance](https://owasp.org/API-Security/editions/2023/en/0xa4-unrestricted-resource-consumption/). Detailed verification obligations are in Sections 19 and 24.

### 11.7 Persistence prototype, migrations, and bounded waiting

Before confirming SwiftData/CloudKit as the persistence implementation, build a recovery prototype with versioned schema fixtures, representative images, durable drafts, and two offline devices. Verify atomic record/file linking, original-inclusive export/restore, migration rollback, and recoverable conflict resolution. If the baseline cannot meet these gates, choose a different persistence implementation behind the same services before committing production user data.

- Migrations stage a versioned recovery snapshot, verify free space and integrity, and journal progress before changing the live store. An interrupted/failed migration leaves the old store recoverable; unsupported schemas open a recovery/export path instead of resetting the closet. Validate old-to-current fixture counts, IDs, image hashes, relationships, and restart at each boundary. A recovery snapshot is protected personal data and follows the deletion/retention rules; remove it after verified upgrade recovery within seven days.
- Merge nonconflicting edits; preserve competing revisions and show a conflict review when the same value/layout changed. Do not select a winner solely from a device clock. Delete/Trash/archive versus edit has explicit precedence: removal stays excluded until a reviewed restore, and permanent deletion markers prevent resurrection. Test offline edits on both devices, reconnect in both orders, repeat delivery, and recover without duplicate records or silent overwrites.
- App-controlled interactive network operations have cancellation, a declared overall deadline (initial default 30 seconds), bounded attempts, and useful status/recovery choices by ten seconds. Preserve input and expose saved/manual alternatives. Background uploads/downloads use durable per-entry state and bounded worker attempts; a slow transfer may remain visibly Pending with pause/retry while local work continues. Cancellation never implies a dispatched charge was refunded.
- CloudKit synchronization and StoreKit pending purchases follow their system-managed lifecycle rather than a fabricated completion deadline. Keep their status explicit and free local actions responsive; do not blindly restart a pending purchase or force an OS background operation to claim success. Test authentication refresh/expiry, malformed responses, 429/5xx, and cancellation in each app-owned service.

### 11.8 United States launch and regional expansion foundation

Decision confirmed October 3, 2026: launch publicly in the United States for adults 18+, then consider other countries with similar fit needs after validation. Country expansion reuses the same client/service contracts and profile-driven fit foundation; do not encode Lily's height or a presumed national body type as a country rule.

- Keep App Store distribution, approved cloud-service/processor eligibility, UI language, measurement display, garment sizing system, StoreKit price/currency, weather/travel location and shopping delivery destination distinct. Changing one must not silently rewrite the others, confirmed profile values or saved looks.
- Use localizable strings and locale-aware date/number/unit presentation from day one. Preserve canonical measurements with explicit units/basis and original brand/category size labels; display conversion does not change the underlying fit evidence. Use actual localized StoreKit prices, never a country-based hardcoded subscription amount.
- Keep supported markets and optional service/catalog coverage in versioned configuration. App Store Connect controls distribution; backend adapters enforce approved service access. Client input alone cannot activate a disabled paid service. Missing shopping or image coverage leaves the independent closet, saved looks and recovery usable.
- Start with the United States selected explicitly; do not opt into all current/future storefronts automatically. Additional markets require current legal/privacy/processor/payment/support assessment, any needed localization and source/fit evidence before enablement under Section 24. App distribution does not itself verify shipping or size coverage.
- A supported country may be enabled through App Store Connect and compatible backend configuration without a new app architecture. New languages, screens, schemas, integrations or platform requirements can still require an app update. Do not promise that a switch alone resolves legal obligations or delivers untested features.
- Before rollout, test regional configuration, units/sizing, prices, service-unavailable states and any localized layouts on iPhone/iPad, including Lily's existing fit/color/workflow cases. Preserve her profile, entitlements, sponsored policy and simple primary flow. Broader clothing/audience support remains the separate Section 10.2 validation decision.

References checked October 3, 2026: [Apple App Store country/region availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store/) and [age-rating setup and higher-rating overrides](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).

## 12. Core Data Model

| Entity | Key fields |
| --- | --- |
| UserProfile | stable id/revision, optional supplied height/measurements with units/basis/source/confirmation, optional contextual weight, category/brand sizing contexts, fit/style preferences, optional chosen clothing/catalog preferences, budget, retailer preferences, independently confirmed shopping destination; unknown values stay absent; no height/weight/size/gender cutoff; adult-service eligibility is separate under Section 24.2 |
| MeasurementValue / SizeContext | typed dimension/value or explicit preferred length/range/unit, known body/preferred-garment/actual-garment/chart basis, source, lastUpdated, confirmation and profile revision; raw size label with category/brand/sizing system, source chart context and fit/cut qualifiers; preserve unknowns and distinctions under Section 10.2 |
| WardrobeItem | stable id, revision, category, color, silhouette, season, brand?, sizeContext?, fabric?, notes?, tag provenance/confirmation, sourceAssetId?, activeDerivativeId?, imageRevision, imageSource, ownershipStatus, availability, trashDate?/purgeAfter?, unavailableUntil?, sourceRetailer?, sourceURL?, purchaseDate? |
| StyleRequest | profile revision, fit-rule version/context, occasion, date/time, weather snapshot, season, startingItem?, freeText, mode, eligibleWardrobeSnapshot/revision, explicit availabilityOverrideItemIds, unchanged-piece IDs/layout for a swap |
| Outfit | stable id, revision, lane, title, explanation, weather rationale, pieces, saved flag, intendedDate?, canvas/layout version |
| OutfitPiece | stable id, wardrobeItemId? required in wardrobe-only mode, category, descriptor, imageRef, owned status, source type, shoppingCandidateId?, normalized frame/scale/rotation/z-order/crop/fit |
| OutfitGenerationResult | success: three-lane OutfitSet, or verified InsufficientWardrobe / GenerationNotCompleted / typed error with actionable reason; no fabricated partial success |
| EditorDraft | id, target entity/id, base revision, staged values/piece/layout state, last durable save, pending/error state, bounded undo/redo history |
| PhotoAsset | stable id, source/derivative revision, local reference, integrity hash, dimensions, processing state, associated item/reference count |
| ImportJob | stable job and entry IDs, item/asset references, source acquisition/staging/commit/processing status, retry/cancel state; no dependence on the old device's library |
| StyleFeedback | selected lane, swaps, recent saved/worn combinations, too-dressy/not-my-style/wrong-weather reason, reversible item/combination exclusions, local preference revision |
| FitReference / FitFeedback | profile reference, brand/category, product/item reference?, size context, user-confirmed fit result, preferred ease and supplied relevant dimensions, optional return reason, source/revision; never infer Fits Well from ownership alone or overwrite another profile's feedback |
| ShoppingRequest | category/style constraints, editable budget/currency/destination, fit-context revision, optional confirmed measurements, request/idempotency ID; no checkout/payment authority |
| ShoppingVisit / PurchaseDraft | stable local visit/draft ID, source product/link and originating outfit/piece revision, permitted variant snapshot, user-confirmed actual size/color, not-arrived status, resume/dismiss state; no checkout credentials or inferred order verification |
| ShoppingCandidate / ProductVariant | permitted source, retailer/brand/product/variant IDs, canonical detail URL, title, licensed image reference?, selected size/color + sizing system/type, sourced body-chart and garment measurements kept distinct, units/stretch/fit description when known, price/currency/stock/delivery evidence with timestamps, rights/expiry, explicit unknowns |
| FitAssessment | product/variant and profile revisions, fit-rule version, recommended size? with sizing context/evidence, separate length/proportion assessment, unresolved dimensions, method/provider/version/source timestamp, confidence meaning if validated; no fabricated dimensions |
| Saved look occasion/feedback | outfit ID/revision, editable occasion associations, confirmed like/worn/rejection signals, local preference revision; generated appearance alone is not actual fit or wear |
| Conditional TryOnReference / TryOnJob / GeneratedLook | Section 9.2 proposal only: local source asset/version, exact outfit/item/image/reference revisions, provider/config, permission/cost/job/deletion state, durable generated asset/hash and saved-look links; full fields and TO gates in Sections 9.2.4/9.2.5 |
| DeletionMarker / SyncConflict | content-free deleted ID/generation and purge acknowledgement; competing record revisions, affected fields and reviewed resolution; never a retained copy of purged garment content |

Ownership status is one of Inspiration, Wishlisted, Owned (Already Own/manual confirmation), or PurchasedConfirmed (explicit I bought this). PurchasedConfirmed is also owned for styling; the label records the user's confirmation, not independently verified payment. A suggestion, saved link, retailer click, or browsing history cannot transition a record into either owned state. Availability is independently Available/Dirty/Unavailable/Archived; Trash removes eligibility regardless of either value. Generic image source remains explicit. Optional AI tags cannot overwrite user-confirmed metadata without review.

Backend-only entities include StylingPrincipal/Entitlement, ConsentReceipt, UsageReservation, conditional ImageCreditGrant/Reservation/Debit/Adjustment under Section 14.4, owner-authorized sponsored policy/budget, FeedbackAccount, FeedbackPost, FeedbackVote, ContentReport, PrivateSupportTicket, and schema-validated AnalyticsEvent. These are not a cloud copy of the closet. Keep public feedback content and optional analytics identities separate from payment and usage identifiers; never send Apple transaction IDs to an AI provider or include them in wardrobe export archives. An imported archive does not prove an entitlement, wallet balance or sponsorship.

## 13. Shopping and Retailer Integration

**Scope update, October 3, 2026:** the app centers on styling and reusing her existing wardrobe. Shopping is secondary to owned alternatives and begins only when she asks for a missing piece. The earlier browser search remains a fallback; the proposed optional V1 fit-aware finder would provide actual-product size/length evidence without an arbitrary region restriction. No catalog/fit vendor, access agreement, production integration, worldwide coverage, or fit accuracy has been validated. Complete the prototype gate before promising/enabling this capability; it is not a dependency of the local wardrobe/collage experience, and browser fallback must not be marketed as a verified fit-aware finder.

### 13.1 User flow and geographic reach

If no matching item is found, say “I couldn't find a matching crop top in your saved closet,” rather than claiming she owns none. Preserve the owned alternative and Already Own choices. Only an explicit Find One action starts product discovery.

1. Reuse her saved height, category size, fit preference, and confirmed fit references. Confirm an editable shipping country on the first shopping request, reusing it thereafter; an address and GPS permission are not required. Weather/travel location does not silently change shopping destination.
2. Search broadly across supported permitted sources, including international retailers able to deliver there. Store/connector configuration belongs on the server, with eligibility based on usable size/length data, permitted access, delivery, returns information, price range, and quality. Do not hardcode one country as the product boundary. Source coverage may still be incomplete.
3. Present a few useful actual product options with a supported size recommendation, separate length evidence/unknowns, outfit rationale, price/currency, and stock/delivery timestamps. If no supported size recommendation exists, clearly label chart-only guidance or Fit Not Verified rather than manufacturing one. Do not equate a Petite tag with a fit assessment.
4. Offer one useful, skippable question when missing information prevents stronger guidance. Let her refine budget, fit, or destination without rebuilding her profile.
5. Open the exact retailer product/variant page where the permitted link format supports it, using the web-sheet/external policy in Section 13.4. Recheck volatile information when supported and disclose that final stock, delivery, shipping charges/duties, returns, and checkout are determined by the retailer. If unavailable, offer Find Something Similar. Saving/clicking remains distinct from confirming ownership.

Distinguish “does not ship here,” “shipping not verified,” “no matching product in connected sources,” and provider failure. Never silently broaden a request to a different size/destination. The user can explicitly broaden criteria or open an unverified browser search. Unsupported catalog coverage does not disable the local closet or basic outfit help. Shopping delivery coverage is separate from App Store/legal launch eligibility in Section 24.

### 13.2 Data, privacy, and service bounds

- Separate product discovery, variant verification, fit assessment, and style ranking. Return versioned structured shopping results with evidence/unknown fields; validate them on backend and client. An LLM can explain or rank supplied evidence, but cannot invent product IDs, measurements, size availability, shipping, or purchase outcomes. The existing outfit contract remains unchanged.
- Preserve each source's size system and units, whether a chart describes a body or garment, and size/color-specific inventory. Do not convert a brand's S into another brand's S as if they were equivalent. Backordered, available for sale, and immediately in stock are distinct when the source exposes them.
- Keep body data and feedback local/private iCloud by default. Prefer retrieving public garment data for on-device comparison. A specialist fit service may require personal inputs or a vendor profile: validate the actual minimum inputs, retention/deletion, consent, and account implications before selecting it. Declining sharing preserves basic/manual guidance. No mandatory weight, scan, photo, or consumer account may be silently introduced by a vendor integration.
- Approved adapters use structured queries/product IDs and restricted provider endpoints; pasted URLs stay references unless a permitted connector supports their identifiers safely. No arbitrary backend URL fetching, retailer scraping, retailer login harvesting, purchase-history access, or autonomous checkout in V1. API/MCP transport does not by itself grant catalog rights or authorize tools.
- Add every metered discovery/fit attempt to Section 11.6's atomic reservation ledger and global/provider kill switches. Define and test finite fan-out, pages, candidates, fit calls, retries, concurrent searches, and customer-visible allowances before launch. Search only on explicit request, not on every outfit or swap. Validate the chosen public price, now considering US$9.99/month, against these added costs; no unlimited shopping-service promise.
- Bound app-controlled shopping calls to the existing thirty-second request deadline, useful status by ten seconds, and cancellation. Cache public data only as licensing permits; label stale snapshots and avoid logging personal fit queries. Provider outage leaves saved work intact and offers local/manual or browser alternatives.
- Display/cache product images only under explicit permitted use and retention rules. Permanent wardrobe images still require lasting-image rights or a user photo/app-owned placeholder. Product links and private screenshots are not a redistribution license. Accept best-effort shared metadata with manual/screenshot fallback; unknown brand/size/stock stays unknown or unverified.

### 13.3 Fit-service research and required prototype

Checked official documentation October 3, 2026. [True Fit's July 2026 technical specification](https://www.truefit.com/fit-intelligence-spec) describes API/MCP access for external shopping assistants, product-specific size guidance and confidence, and a basic no-profile fallback. This makes it a relevant evaluation candidate, not a selected dependency or proof of petite-length accuracy. Its [MCP FAQ](https://www.truefit.com/mcp-fit-intelligence) requires product data through permitted catalogs/platform connections; access to fit intelligence is not automatic access to every retailer's live inventory. Independent-app eligibility, exact minimum inputs, catalog coverage, costs, and privacy terms remain unconfirmed.

[Fit Analytics' feed documentation](https://developers.fitanalytics.com/) and [Sizebay's service API](https://docs.sizebay.com/size-and-fit-implementation/service-implementation-api) describe store/product-linked integrations. Evaluate them if commercial access fits this app; do not assume any is an unrestricted universal clothing API.

Before committing the finder, prototype representative tops, crop tops, trousers, dresses, and sleeves across brands and multiple delivery destinations. Verify permissioned product access, size-system mapping, chart semantics, petite/length dimensions, stock/delivery freshness, image rights, actual shopper-input requirements, privacy/deletion, latency, and full per-search cost. Exercise missing charts, weak confidence, regular/cropped alternatives, non-shipping results, unavailable sizes, expired links, and outages. Compare recommendations with consented real fit feedback; set a justified claim/quality threshold rather than inventing an accuracy target. If evidence/access is insufficient, document the gap and revise the product promise or provider plan before release. Do not declare the browser fallback a successful fit-aware implementation.

### 13.4 Retailer opening, purchase capture, and visual closet

For retailers whose terms and checkout work with it, View at Store opens Apple's [Safari web interface](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) as a sheet. Closing it returns to the same look/product. Also provide external browser/store-app opening and use it when required or when checkout needs it. Platform URL handling may open a supported installed retailer app; exact variant selection and authentication behavior require testing. Never promise shared login sessions, capture checkout fields, or inspect browser activity to infer a purchase.

Save the outfit/product/visit context durably before leaving. On return, retain a small optional “Bought it? Add to closet” action and keep the reference accessible later; dismissing/returning does not trigger another metered search or repeated purchase prompts. Confirm actual size/color, ownership, and whether the item has arrived. If ordered, use PurchasedConfirmed plus Unavailable/not-arrived until she confirms arrival. Show a review of existing allowed metadata and let her save text-only, take a picture, select a photo/screenshot, explicitly paste an image/link, or attach a photo later. Duplicate retries update the intended record; buying a second identical garment is an explicit separate entry. Purchases made elsewhere use the same Add Item flow without a prior visit. A link alone does not provide an image or verify purchase/size; unsupported retailer metadata uses manual entry.

The closet grid shows saved garment thumbnails with category/search filters. The manual outfit board lets her place clothes, shoes and accessories together, compare/swap pieces, and save a look. Add to This Outfit is explicit and preserves other pieces/layouts; delayed shopping or image work cannot replace later edits. Wishlist/inspiration and not-arrived pieces may appear in a clearly labeled planned look, but do not pass today's strict available-wardrobe validation. This is a garment collage, not a photorealistic image of her wearing the outfit.

Amazon is not automatically searched or ranked first. Prioritize supported fit/length, variant availability, delivery, budget, and user retailer preferences; an optional Amazon preference never overrides a hard size/delivery constraint. No Amazon integration or affiliate monetization is selected. Its current [affiliate browser rule](https://affiliate-program.amazon.com/help/node/topic/GW7ZSEASVXHFPZCY) requires the Amazon app/device browser. Its [Associates policies](https://affiliate-program.amazon.com/help/operating/policies) restrict mobile approval, paid link access, content reuse, and image storage. Any proposed Creators API/catalog use needs separate marketplace/access and permitted fit-analysis/export review; do not assume a general catalog license. Retain a user-provided garment photo or independently licensed exportable asset for durable closet imagery. Recheck actual terms before choosing that integration.

### 13.5 Optional Ask another stylist export

The user may take selected closet items or a look to an AI service of her choice. This is an optional local export/share feature, available without our styling subscription or remaining quota. Rendering and prompt preparation happen on device from templates and selected records; no LLM, discovery, or specialist fit call is made for this handoff. Previously requested in-app styling/shopping still has its ordinary cost. The destination's account, plan, limits and processing policies are the user's choice and are not promised free or included in our subscription.

1. Select a look or garments and preview a legible collage/contact sheet with numbered labels, ownership/availability, and clearly labeled representative images. For larger selections, use readable batches/pages with bounded thumbnail decoding instead of one unreadable whole-closet image. Images must be exportable under their source rights; restricted catalog imagery uses a placeholder/text tile. Sanitize export metadata.
2. Preview/edit a locally prepared prompt, for example: “Style these owned items for dinner. Keep jeans #2. Suggest three combinations using the numbered garments. Ask before adding shopping items.” Optional height/fit/preferences may be added after explicit selection; measurements, name, location, product URLs and whole-closet data are excluded by default. The shared numbers are export labels, not internal record identifiers.
3. Offer Share, Save Image/File, Copy Image where supported, and Copy Prompt. Use Apple's native sharing controls; destinations depend on content types and installed apps. Do not automatically read/write the clipboard, open another app, or send any content. Show what will leave the device before the user invokes sharing; do not place personal context in a deep-link URL. A phone screenshot is possible, but local collage export gives a clean preview without unrelated screen content.
4. If a destination does not accept both image and prompt, let her save/upload the image and paste the prompt herself. No universal one-tap handoff, external sign-in, automatic response retrieval, or user-plan API integration is promised. She returns to manually assemble/save suggested combinations with actual stored items. The external AI does not inherit our owned-only validator or establish exact fit; its answer cannot automatically change inventory, measurements, or purchase state.

Temporary export files use private app storage, expire within 24 hours, and are cleared by Delete My Data when no active share needs them; independently saved/shared copies remain outside app deletion. A canceled/failed handoff preserves the look and makes no model call through our app/gateway. Once she selects a receiving app, that app may already have obtained the reviewed content even if she subsequently cancels its UI; do not promise recall or infer successful sending from selection. Apply Section 15.4's exact-content preview/disclosure to these explicit exports, separate from app-managed cloud-AI permission and optional analytics.

Checked October 3, 2026: [Apple ShareLink](https://developer.apple.com/documentation/swiftui/sharelink) documents content-dependent sharing destinations. [Official OpenAI image-input documentation](https://learn.chatgpt.com/docs/image-inputs) supports image input on the web; it does not establish universal iPhone image-plus-prompt sharing. Validate actual installed destinations on iPhone/iPad and retain save/upload/paste as the dependable fallback.

## 14. Monetization: Monthly Subscription and Complimentary Access

Decision updated October 3, 2026: Free download and one monthly auto-renewable subscription for AI styling remain the public plan. Lily is the primary user, and the owner accepts her AI/image usage as a personal expense; break-even or profit is not the product's primary objective. Selected users can redeem Apple codes for ongoing complimentary access. Public pricing may rise from the earlier US$4.99 plan; US$9.99/month is a candidate if needed, not a final price instruction. Retain the one-month free introductory trial for eligible users and no discounted paid introductory month. If optional try-on ships, include a disclosed monthly image service allowance with optional consumable image packs for additional use. The owner still pays all service providers, while public App Store payments help fund usage. Validate final allowances, localized prices and operating budgets before launch.

### 14.1 Public monthly subscription

Use StoreKit 2 and Apple's In-App Purchase system. Present the subscription name, included services and meaningful usage allowance, localized full renewal price, monthly period, auto-renewal terms, and any offer's expiry and subsequent price clearly. Provide Restore Purchases, Manage Subscription, Redeem Offer Code, Terms of Use, and Privacy Policy actions. Include the required legal links in App Store metadata. Avoid making an app-specific account necessary solely to purchase or restore access.

AI outfit generation, AI swaps, and Ask Stylist require verified styling access. If the optional fit-aware finder ships after Section 13 validation, its metered discovery/specialist-fit requests use the same subscription/trial/complimentary styling entitlement, with a separately disclosed allowance and validated costs. An exhausted category allowance does not consume or disable another available category. Lily's sponsored policy follows Section 14.4. No second consumer account or separate fit subscription is planned.

Optional Generate Look image generation in Section 9.2 is under exploration and is not yet a promised subscription benefit. If enabled, the public subscription should include a disclosed monthly image service allowance, with optional StoreKit consumable packs for extra images; amounts and pack prices are not finalized. Trial image allowance is separately disclosed, and no automatic overage charge is permitted. Keep period-specific service allowance separate from non-expiring purchased credits; assess the final offer wording against Apple's rules rather than assuming a label permits paid credits to expire. Purchased balances remain usable for supported image jobs after subscription expiry without repurchasing text-stylist access. Lily's owner-sponsored policy in Section 14.4 requires no image-pack purchase. Viewing/manually editing/exporting saved looks stays available after any allowance or entitlement ends.

Closet management, saved fit-profile editing, local/manual chart guidance, optional unverified browser search, manually saved product references, manual outfit creation/editing/saving/undo, viewing saved outfits, local collage/prompt export to a user-chosen AI, iCloud sync/recovery, export/import, feedback browsing, and support remain available after expiry or exhausted service usage; cancelling a subscription must not delete or strand the user's wardrobe. Previously saved personal fit notes remain accessible, while stock/price snapshots stay labeled with their age. Optional analytics and public feedback participation are never conditions of paid access. Prevent duplicate purchase prompts when the user already has either qualifying entitlement.

#### Cancellation and continued closet access

- Cancelling a trial or subscription stops future renewal. Keep AI access while Apple reports a valid active entitlement; use Apple's reported expiry or revocation rather than assuming every cancelled trial remains active until its originally scheduled end.
- When styling access ends, disable new AI outfit generation, AI swap suggestions, Ask Stylist, and metered product discovery/specialist fit requests unless the user has a valid complimentary unlock. Local/manual fit guidance and browser-search fallback remain usable.
- If try-on and image packs are enabled, unspent purchased credits still authorize supported image generation from manually selected garments after styling subscription expiry. No new paid subscription is required to spend that balance. Image consent and normal technical/service controls still apply; image credits do not independently unlock text-stylist or shopping services.
- Continue to allow adding, editing, and deleting garments, availability controls, viewing photos/saved outfits, manual outfit editing/creation/saving/undo, private iCloud sync/recovery, and export/import without payment. Preserve wardrobe records, saved layouts, meaningful drafts, preferences, and personal feedback.
- If the user subscribes again, resume AI styling using the existing closet and preferences without requiring another closet setup. Explain the current access state and offer resubscription without blocking access to personal data.
- Cancellation or expiry must never trigger Delete My Data. Data removal remains a separate explicit user action; normal user-directed edits and deletions continue to work.

#### One-month free trial

Decision updated October 3, 2026: Eligible users receive one month free, then the finalized localized monthly price, automatically renewing until cancelled. US$9.99/month is under consideration; US$4.99 is the superseded fixed-price assumption. Remove the earlier discounted introductory-month proposal.

The trial gives users time to build their closet, receive personalized outfit recommendations, try swaps, and decide whether the AI delivers enough continuing value to pay for it. Let users add garments gradually and experience useful styling before completing their entire closet. Start the trial when the user explicitly activates the subscription through Apple's purchase flow, rather than merely downloading the app.

Configure a one-month free introductory offer on the monthly subscription in App Store Connect. One month follows Apple's subscription calendar rules and is not a fixed 30-day duration. Check introductory-offer eligibility; users who have already used an introductory offer in the same subscription group must see their actual available terms. No launch discount code is required for this trial. Family complimentary codes remain a separate entitlement.

Present the offer clearly before purchase: “1 month free, then [localized monthly price]/month. Auto-renews until cancelled.” Display the actual configured StoreKit price and renewal date instead of hardcoded dates or prices. Disclose the actual trial/paid image allowance and optional extra-image purchase terms before activation. Provide subscription management and Apple's current trial cancellation guidance. Users who do not continue paying retain their closet, saved outfits, sync/recovery, export/import, and any unspent purchased image credits under Section 14.4.

Measure trial engagement (garments added, outfits generated/saved, swaps, and repeat styling use), trial-to-paid conversion, paid renewals, and AI costs from users who never become paying subscribers. Keep measurement minimal and avoid uploading garment photos or wardrobe contents solely for analytics. Evaluate whether recommendations help users choose outfits and return to the app; trial starts alone do not demonstrate value.

Financial forecasts must include non-converting trials and actual paid billing periods. A user who starts the trial at the beginning of a 12-month observation window and stays subscribed afterward generally contributes 11 monthly payments, not 12. The previous full-price, full-year revenue estimate is not a first-year trial-cohort forecast.

Source: [Apple introductory offer durations and eligibility](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions).

### 14.2 Codes for selected users

Two distinct mechanisms serve different purposes:

| Access type | Apple product / mechanism | Intended use |
| --- | --- | --- |
| Monthly paid access | Auto-renewable subscription | General users |
| Limited free or discounted period | Subscription offer code | Time-limited promotions; access may renew at the regular price afterward |
| Ongoing complimentary access | Separate non-consumable styling unlock with a free Apple offer code | Lily and selected family members; no recurring billing from this unlock |

Apple supports offer codes for non-consumable In-App Purchases. Proposed implementation: configure an approved non-consumable product that grants non-expiring access to the V1 styling service and issue targeted one-time-use free offer codes. Keep the standard public paywall focused on monthly subscription; explain the complimentary product and code flow in App Review notes. Verify product availability, redemption, and restoration in App Store Connect and sandbox before launch. Approval is not guaranteed by this specification.

Redeeming a code creates an Apple transaction that the app and backend validate. A code's redemption deadline differs from the duration of the granted entitlement. Do not implement a hardcoded family password or an independent code system that bypasses Apple's purchase mechanisms. Treat codes as bearer credentials before redemption: distribute privately; a forwarded unused code can be redeemed by its recipient.

If a subscriber redeems the non-consumable unlock, clearly explain that it does not automatically cancel an existing monthly subscription; provide Manage Subscription so the user can stop future renewal. Do not imply that code redemption will refund previous charges.

### 14.3 Entitlement handling and operating costs

- Grant styling access when there is either a verified active subscription (including applicable grace-period behavior) or a valid non-revoked complimentary unlock. A local flag or imported backup is never proof of paid access.
- Validate signed Apple transaction data on the backend before allowing cloud styling. Process subscription renewals, expiry, refunds, and revocations through App Store Server Notifications and reconciliation. Keep entitlement tracking separate from private wardrobe storage.
- Restore access using Apple's transaction entitlement mechanisms after reinstalling or changing devices. Support pending purchases, cancellation, billing recovery, offline states, and redemption outside the app.
- Complimentary users still generate developer-paid AI costs. Ordinary complimentary users retain their disclosed service policy. Lily's separately authorized owner-sponsored policy removes public daily/monthly allowance and credit-purchase requirements with an owner-funded budget; all users retain technical/permission/idempotency controls. Track sponsored spending separately; a complimentary unlock alone does not disable budgets or grant unrestricted vendor access.
- Keep cloud prompts compact, reuse relevant context, and avoid automatic image generation. Before enabling optional try-on, approve its separate image allowance and measured economics within the aggregate service budget. Choose monthly pricing using measured AI/hosting costs, App Store fees, taxes, and the complimentary-user allowance.
- Test subscription and code flows with StoreKit testing and sandbox. Do not use temporary TestFlight distribution as the permanent family-access plan.

Sources checked October 3, 2026: [Apple subscriptions](https://developer.apple.com/app-store/subscriptions/), [subscription offer codes](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes), [offer codes for In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-offer-codes-for-in-app-purchases), [StoreKit offer-code handling](https://developer.apple.com/documentation/storekit/supporting-offer-codes-in-your-app), and [App Review payment guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase).

### 14.4 Owner-sponsored use and conditional image-credit purchases

**Lily's experience:** redeem an Apple-issued complimentary unlock, then bind a separately authorized Sponsored policy to her verified restored styling principal. A code is a bearer credential before redemption, so possession of a code or a client-supplied name is not proof that the recipient is Lily. Owner confirmation and privileged server administration authorize sponsorship; ordinary clients cannot set or inherit it. This policy requires no public monthly subscription or image-credit purchase and does not apply public daily/monthly service allowances. The owner funds and monitors her text/image costs under a separately approved budget that can be increased intentionally. Retain finite per-job bounds, concurrency/throttles, permissions, idempotency and emergency/global spending controls. Sponsorship is not an unlimited unprotected API key. Describe the complimentary/sponsored flow to App Review and test restoration; other family members are sponsored only if explicitly authorized.

**Public experience, if try-on ships:** subscription supplies ongoing styling and a disclosed monthly image service allowance. Show its remaining allowance/reset and any separately purchased balance. Once the included allowance is used, offer Wait Until Reset or an optional StoreKit consumable image pack; never charge automatically. Before Generate Look, show the mode's credit requirement and whether it uses included allowance or purchased balance. Quantities, mode-to-credit mapping, pack prices, trial allowance and renewal behavior remain unselected. Do not claim unlimited images or finalize them from raw per-output API prices alone.

Purchased IAP credits do not expire and remain usable for supported image jobs after subscription expiry. Keep them separate from the period-specific service allowance; if the final subscription is marketed as purchasing credits, address non-expiry explicitly rather than relabeling the balance. Prefer spending included allowance first. Viewing saved images/linked outfits, local manual editing and export stay free regardless of either balance. This is a conditional product plan, not an implemented wallet or approved App Store product.

- Validate signed Apple subscription, complimentary and consumable transactions on the server. Grant a pack once per verified transaction ID/environment to the correct principal; persist the grant before finishing delivery. Validate product/quantity against approved server configuration, not client values.
- Store grants, reservations, debits and adjustments durably. Reserve customer units atomically per idempotent image job, separately from provider-dollar financial reservations. Duplicate taps, callbacks, transaction deliveries and app restoration cannot create extra balances or charges.
- Debit once for a technically valid delivered preview; dislike does not itself refund a completed rendering, and explicit Regenerate uses another disclosed allowance/credit. A failed or unusable technical result releases customer units even if the provider bills the owner. Ambiguous in-flight work stays Pending until reconciliation instead of dispatching another paid job.
- Define/test stable-principal purchase proof and remaining-balance recovery across reinstall and iPhone/iPad before selling packs. Purchase history identifies grants; only the durable debit ledger establishes unspent balance. Do not promise that generic Restore Purchases or an imported wardrobe archive reconstructs a finished consumable wallet. If the proposed accountless recovery cannot be verified, resolve that design before launch rather than losing customer value.
- Reconcile refunds/revocations and duplicate deliveries without deleting wardrobe or saved looks. Adjust only the relevant grants/balance under disclosed rules; no automatic customer charge for prior usage. Minimal wallet/billing history remains separate from wardrobe content and follows the documented legal retention/deletion policy.

Apple's current rules permit subscription benefits alongside consumables and prohibit expiry of purchased IAP credits. Use StoreKit purchases for the chosen public plan and Apple offer codes for complimentary entitlement; no custom paid unlock key. Sources: [Review Guidelines 3.1.1–3.1.2](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase), [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi). Validate the complete final offer and recovery design before enabling credit sales.

## 15. Privacy, Security, and Trust

- Body measurements and wardrobe data are local-first by default.
- Cloud requests send only the minimum context needed to generate a recommendation.
- The base text-stylist gateway does not upload user photos. Photos stay on device/private iCloud unless she explicitly exports/shares selected content (Section 13.5), or the separately validated optional try-on route is enabled with image-purpose permission (Section 9.2). Preview the relevant content and actual processor; define upload/retention/deletion/cost bounds before image enablement. Prior text-styling consent, Photos access or a generated-look save does not authorize background image sharing/training.
- API credentials live only on the backend gateway.
- The app must not promise exact fit. Fit recommendations are guidance based on measurements, brand metadata, and the user’s own feedback.
- No body-shaming or attractiveness scoring. Petite is treated as a clothing-fit category.
- Provide clear Delete My Data controls for the closet, optional developer-held data/accounts, or both, with accurate local/cloud completion states. Details are in Section 15.4.

### 15.1 Private iCloud Sync

Decision added September 27, 2026: Offer optional private iCloud sync for user-created profile, wardrobe, fit feedback, and saved outfits. Keep a local copy so core flows work offline and when iCloud is unavailable. An app-specific online account is not required for this feature.

Make sync status and the choice to use iCloud understandable in Settings. Show local Saved, sync Pending/Failed, and the last successful cloud acknowledgement separately, with counts of still-pending records/assets. A last-sync timestamp does not mean later edits are uploaded. Handle sign-out, unavailable storage, delayed sync, device changes, and conflicts without losing the local copy. Follow the Section 11.7 two-device conflict policy; synchronization can propagate deletion and is not an independent backup.

Decision updated October 3, 2026 after review-derived requirements: Include retained unprocessed source photos and active display derivatives in optional private iCloud sync and export archives, alongside wardrobe records, availability, saved piece layouts/revisions, and meaningful editor drafts. Drafts are identified by draft/device and base revision; concurrent editing conflicts require review rather than one device silently overwriting another. Recovery must not rely on access to the old device's Photos library. Exclude replaceable caches and bundled assets; regenerate thumbnails/collages from restored assets and stored layouts without rearranging them. This supersedes the earlier optimized-only photo default.

If Generate Look is enabled, include retained TryOnReference and accepted GeneratedLook assets/hashes, source/outfit/item/image revisions, saved links and occasion feedback in private sync and archive recovery. Disclose the included personal-photo content. Restore accepted images from durable retained assets, not an expiring provider URL or a new paid generation; reconstruct safe local job/status references without restoring API credentials or authorizing duplicate dispatch. Purged assets stay excluded, and stale job results cannot recreate them.

Delete My Data must cover the local store and any synced records, with a clear explanation of how deletion propagates. Verify reinstall and new-device recovery, offline edits, and deletion across devices before launch.

If iCloud is unavailable, show local deletion as complete and cloud deletion as pending, tied to the correct Apple Account; do not claim all copies are removed. Use a tested deletion/tombstone or generation-reset strategy so reconnecting stale devices cannot recreate deleted closet records. Keep any minimal deletion markers free of closet content. Account changes must not upload one account's private data into another without an explicit user-directed migration.

### 15.2 Export, import, and recovery

Provide Export Backup and Import Backup in Settings. Export a portable archive containing a versioned manifest, readable JSON records, retained unprocessed garment sources, and active derivatives. Include profile, wardrobe/ownership/availability and unexpired Trash, content-free deletion markers, saved outfits/layouts/revisions, meaningful drafts and bounded recoverable edit history, preferences, and styling/fit feedback, preserving stable IDs and relationships. Include completed source staging and its resumable import manifest where needed; explicitly identify source entries that were never acquired and cannot be recovered. Exclude API secrets, authentication tokens, purged garment content, and disposable caches. Export from a consistent committed snapshot with asset integrity checks; prevent concurrent editing or photo cleanup from producing an archive with missing references. Export/import operates without any AI provider.

- Let the user save the archive through Files to iCloud Drive or another chosen location. Explain that an export is a snapshot and does not update itself; private iCloud sync handles ongoing updates when enabled.
- Offer iCloud sync during onboarding without requiring an app-specific account. Report pending records/photos and sync failures accurately; never claim the closet is recoverable in iCloud while uploads are incomplete. Explain storage-full and offline states and allow retry.
- On reinstall or a replacement device using the same Apple Account, restore synced records, source/active photo assets, saved layouts, and meaningful drafts when iCloud is enabled. Show recovery progress and keep available local content usable. Changes/assets that never uploaded cannot be recovered from iCloud.
- Archive import must preview record/source/derivative/outfit/draft counts, validate schema versions, asset integrity and layout references, and reject unsupported or damaged archives without modifying the current closet. Use bounded extraction and validated referenced files. Resumable staging is allowed, but the merge/replace commit remains all-or-nothing; partial photo-import entry commits must not weaken archive-restore safety.
- If try-on is enabled, export/import preview also identifies retained profile-reference/generated-image counts and personal-photo inclusion. Verify their hashes and outfit/item/image revisions; keep preview labels and deletion markers. Recovery must not rely on a live image provider, temporary URL or another generation charge. Customer-credit balance and sponsored access remain backend-verified and are not imported from this archive.
- Let the user explicitly choose merge or replace. Deduplicate by stable IDs, surface conflicts, and create a recovery export before replacement. Commit the import only after validation succeeds; never silently clear the current closet.
- Distinguish app deletion from Delete My Data: app deletion removes the local store, while completed private iCloud copies are retained for recovery. Delete My Data removes local and synced records. Independently exported files remain under the user's control and must be deleted separately through Files.

Private iCloud sync maintains the current closet; it is not a version history for undoing deletions. Export archives provide separate recovery snapshots. Apple's device-level iCloud Backup is an additional user-controlled mechanism, not the app's primary reinstall recovery path. See [Apple's sync and backup explanation](https://support.apple.com/en-us/108770).

### 15.3 Closet storage estimate

Planning assumptions updated October 3, 2026; these are engineering estimates, not measured build sizes. A populated example closet contains 300 garments, each with one retained source and one optimized display derivative. Original-first recovery changes the earlier optimized-only estimate.

- Installed application and bundled representative images: budget **100–200 MB**, depending on the asset library. No large local model weights are bundled in this estimate.
- Display derivatives: target an average **0.4–0.8 MB per item**, using resized HEIC/JPEG images (initial target: 1,200–1,600 pixels on the longest edge). This is an average target, not a guaranteed size or fixed-quality limit; verify fabric/detail readability on real photos. Sources stay at their accepted import resolution.
- Retained source photos: illustrative **4 MB per item**; actual camera/format/resolution varies substantially. Preserve sources for revert/recovery instead of silently deleting them after optimization.
- Records, saved outfit references, thumbnails, and bounded caches: allow **10–30 MB** for these example scenarios. Saved outfits reference existing garment images instead of duplicating them.

| Closet size | Retained sources + display derivatives | Estimated total on-device app storage |
| --- | --- | --- |
| 100 items | 440–480 MB | 550–710 MB |
| 300 items | 1,320–1,440 MB | 1,430–1,670 MB |
| 1,000 items | 4,400–4,800 MB | 4,510–5,030 MB |

Formula: installed app + item count × (source + derivative size) + records/thumbnails/caches. Extra photos, additional derivatives, collages, larger sources, and retained replacement/undo assets increase storage; bounded undo may add up to 100 MB beyond the table. Trash, import staging, migration recovery snapshots and export working space are additional and excluded from these steady-state examples. Disclose their disk use; no early silent Trash purge to free space. Saved outfits retain layout/references instead of duplicate garment images. The user's Photos library is separate and may hold another copy. If the user explicitly removes app sources, storage can approach the earlier optimized-only estimates, but full-source recovery/revert is then lost.

A 300-item export is estimated at **1,325–1,455 MB** for sources/active derivatives plus an illustrative 5–15 MB records/archive allowance, before retained undo/replacement assets or additional photos. Already compressed images will not shrink much in a ZIP archive. Private iCloud storage should be of a similar order, subject to service overhead; an export in iCloud Drive consumes additional space for every retained snapshot. A 1,000-item closet can consume most of the free allowance even before the user's other iCloud data.

iCloud storage is shared with the user's other data. Apple provides 5 GB free, but available capacity may be much smaller; show actionable sync errors if storage is full. See [Apple iCloud storage guidance](https://support.apple.com/en-us/108922).

Measure installed size, source/derivative quality and size, retained history, cache use, and export/import peak temporary disk usage during beta. Validate 100-/300-item cases and the release dataset of **1,000 garments with 500 saved outfits on Lily's iPhone 12**, also covering iPad. Archive creation/import may require substantially more free disk space than steady-state use; preflight and preserve existing data if capacity is insufficient.

### 15.4 Consent, data inventory, retention, and deletion

Apple's current privacy rules require explicit permission before sharing personal data with third-party AI. Minimizing a prompt or putting a sentence in the privacy policy alone does not fulfill the product's consent requirement. Cloud styling is an independent permission, separate from analytics, iCloud sync, Photos, location, and public feedback.

- Before the first cloud styling request, disclose the actual AI recipient, purpose, context categories (including measurements, relevant wardrobe descriptions, and free text), processing location/retention information where applicable, and the real training-use policy. Provide affirmative Allow and decline choices. Do not promise zero retention or no training unless the selected provider contract/account settings support that statement.
- Apply named-recipient/purpose permission separately to product discovery and specialist fit where personal queries, sizing inputs, or feedback leave the device. AI-styling consent does not implicitly authorize a different fit vendor or vendor profile. Minimize transmitted context, disclose any vendor-profile creation, and preserve local/manual alternatives on decline. No retailer account or purchase-history access is implied.
- If optional try-on ships, obtain separate image-purpose permission naming the actual processor, reference/body and selected garment photos, processing/training/retention terms and image allowance. Validate temporary input/output privacy and deletion. Withdrawal/deletion fences queued/retry/late-result writes; app-controlled dependent likenesses must be purged by the reviewed deletion scope. Do not infer exact measurements or physical fit from the photo/preview. Basic closet/collage access remains on decline.
- Store a versioned consent receipt with allowed recipients/data categories/purpose. Client and server must reject unconsented dispatch. Do not silently fall back to a different company; request permission for that recipient first. Material changes to sharing/retention require updated disclosure and renewed permission as appropriate. An unchanged recipient/model replacement may remain a server configuration change.
- Settings shows approved cloud styling, discovery, fit, and any enabled try-on image recipients/purposes and lets the user withdraw permission separately. Withdrawal stops new dispatch and clears queued personal requests/result caches; delayed results cannot recreate those caches or trigger a retry. In-flight processing may have already reached a provider and must be described accurately. Allow eligible local AI under its normal styling entitlement; explain the cloud dependency on iPhone 12 before trial/purchase and link subscription management if permission is withdrawn later.
- Use PhotosUI's selected-item access rather than requesting the entire library for import. Request camera/location only when the associated feature is invoked, explain why, and handle denial with photo/manual-weather alternatives. Prefer approximate, while-in-use location adequate for weather; no background location. Send weather conditions, not coordinates, to the AI provider.
- Export preview identifies included profile/closet/images and explains that a portable unencrypted archive contains personal information. Save only to the user's chosen Files destination; exported snapshots remain outside automatic app deletion. Do not silently attach the closet to feedback or diagnostics.
- Local collage/prompt sharing has its own exact-content preview and explicit user action; it is not a gateway upload or an implicit extension of styling consent. Personal fields are excluded by default and individually selectable. The native destination selection controls the recipient, whose account/retention policies apply; no automatic dispatch, clipboard access, or image/measurement transmission occurs on opening the export screen. External copies cannot be recalled by Delete My Data. Omit restricted catalog assets from the export and offer an own-photo/placeholder alternative.

The following retention defaults are product requirements, subject to verification against processor terms and applicable law before release. Any necessary departure must be documented in the actual notices; the implementation must not silently retain more data than promised.

| Data path | Purpose and recipients | Retention / deletion requirement |
| --- | --- | --- |
| Local profile, closet, photos, outfits, personalization | Core app; device and optional user-private CloudKit | Until user deletion; support granular edit/delete and tested cross-device deletion. No developer-readable closet database is required. |
| Conditional try-on reference/results and transient image processing | Local/private-iCloud saved artifacts; enabled gateway plus separately consented image processor only after TO gates | Durable saved images follow personal asset deletion/export rules. App/gateway media access must be private and temporary; exact retention/deletion/training settings, safety exceptions and processing location need processor approval/disclosure before enablement. No photos/payloads/signed URLs in logs. Vendor URL expiry is not saved-look durability or proof of complete deletion. |
| Local recovery copies | Editor undo, Trash and safe migration recovery; device/optional private sync | Undo up to 20 actions/100 MB/seven days; Trash up to 30 days; verified migration recovery snapshot up to seven days. Permanent purge/Delete My Data clears covered personal copies immediately locally, with accurate pending cloud cleanup. Independent Files exports remain user-controlled. |
| Temporary collage/prompt exports | On-device preparation for explicit user-selected share/save/copy; no developer/AI gateway | Private app staging expires within 24 hours; Delete My Data clears it subject to finishing an active share. No analytics copy or background upload. User-saved/shared copies are independent and under the user's/recipient's retention controls; explain this before sharing. |
| Cloud styling context and raw vendor response | Transient gateway processing and named, consented AI processor | Do not persist raw payloads on the developer gateway or in logs. Provider retention/training terms must be assessed, configured, and disclosed before selection. Normalized completed-action results may be encrypted and principal-scoped for at most 24 hours for idempotent recovery, then deleted. |
| Personalized shopping queries and fit-service context/results | Transient gateway and named, consented discovery/fit processors | No raw personal queries, measurements, feedback or responses in developer logs/persistent payload stores. Normalized personal action results may be encrypted/principal-scoped for at most 24 hours for idempotent recovery, then deleted; withdrawal/deletion prevents delayed cache recreation. Vendor retention must be assessed and disclosed before selection. Public catalog caching follows its license separately and must not retain a shopper profile or search association. |
| Optional specialist vendor fit profile | Only if required by a selected, disclosed and permissioned integration; vendor processing | No automatic vendor-profile creation under general styling consent. Confirm minimum fields, pseudonymous linkage, legal retention, in-app deletion/withdrawal routing and deletion acknowledgement before activation. Local profile edits/deletion must not leave an undisclosed vendor copy; pending remote deletion remains visible. If terms cannot support these controls, use another integration or local guidance. |
| Consent and pseudonymous entitlement/usage ledger | Permission enforcement, access, anti-abuse, and cost admission on developer backend | Retain the minimum active consent/access state and necessary usage-window records; after deletion retain only documented lawful billing/security evidence. No measurements, closet contents, or prompt bodies. Define applicable legal record periods before launch. |
| Identifiable operational/security events | Service reliability, attack detection, and incident response | Default maximum 30 days, with longer retention only for documented investigations/legal obligations; aggregate longer-lived totals without principal/device/IP identifiers. Bound edge IP retention to the shortest necessary abuse window. |
| Optional improvement events | Consented first-party product analytics | Raw events at most 30 days, then delete or aggregate without identifiers; delete queued events on withdrawal and provide deletion of linked events. See Section 23. |
| Public board account/posts/votes | Optional community feedback; account service, moderators, and approved public content | Until user/account deletion or moderation removal; remove associated public content/votes on account deletion. Keep minimized moderation/security records at most 90 days after closure unless a documented obligation requires longer. |
| Private support reports | Resolve an explicitly submitted bug/billing/privacy/security issue; authorized support staff | Default delete 90 days after closure; restrict longer retention to documented billing, security, or legal need. Keep ticket content out of public board/search/analytics. |
| Optional welcome/check-in email contacts | Separately volunteered address, communication preferences and consent; authorized operator and a disclosed email processor only if Section 22.4 is enabled | Retain while opted in; unsubscribe immediately stops new and queued optional sends. Delete the contact and optional message history within 30 days of a deletion request, including processor routing. Keep only a protected minimal suppression/consent record where necessary and disclosed; set its lawful retention before enablement. No closet/profile/billing linkage, tracking pixels or automatic behavioral targeting. |
| Developer backups | Recovery of the limited backend services above | Encrypted, restricted, maximum 30-day rotation unless a documented legal hold applies. Deleted data must not be restored to live service; reapply deletion records after restore and let backups expire. |

Delete My Data must offer plainly labeled scopes for the local/synced closet, optional developer-held feedback/analytics/consent data, and all app data. If the email program is enabled, identify its separate contact/consent record and offer a no-account unsubscribe/deletion route from each email and the website; include it in all-data deletion when the contact is verifiably linked. Do not create a wardrobe/billing identity link merely to join a mailing list. Show consequences, allow export first, and confirm completion or pending steps. Verification may protect against unauthorized deletion, but must not force a support call or unnecessary retention.

For an optional feedback account, offer in-app **Delete Feedback Account**, remove account-associated posts/votes and personal identifiers, and revoke Sign in with Apple tokens. Temporary deactivation is insufficient. Preserve only necessary, documented billing/security/legal records separately, never closet data under that exception. Deleting an account/data or uninstalling the app does not itself cancel Apple billing; explain this and provide Manage Subscription while allowing immediate deletion. Restoring a valid Apple purchase may re-establish access, not erased personal data or consent.

Maintain a data/processor inventory covering gateway hosting, AI, product discovery, specialist fit/vendor profiles, account/board services, the public website and any enabled email service, analytics, crash tooling, and backups. The privacy policy must describe actual collection/sharing, purpose, processors, retention, rights/contact, deletion, and withdrawal. Complete App Store privacy answers from actual off-device/vendor behavior; local-only data and optional consent do not automatically mean the whole app collects nothing. Audit free-text, persistent identifiers, provider retention, and third-party SDKs. Use “pseudonymous” for linkable identifiers rather than claiming anonymity.

References checked October 3, 2026: [App Review privacy requirements](https://developer.apple.com/app-store/review/guidelines/#privacy), [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), and [in-app account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

### 15.5 Security and user safety

- Use TLS through platform networking/App Transport Security; no broad cleartext exceptions. Protect local files with appropriate iOS Data Protection, keep session/authentication material in Keychain, and use server-side secret storage, scoped credentials, rotation, and separate test/production projects. Encrypt backend data/backups at rest and restrict moderator/operator access by role with strong authentication.
- Enforce authorization on every principal/account/post/ticket/result access; never trust an object ID as permission. Public board responses contain only approved public fields. Validate signed tokens/transactions/notifications and defend replay. Audit administrative actions and pricing/budget/model changes without copying sensitive payloads.
- Disable payload logging in client networking, gateway access logs, tracing, SDKs, crash breadcrumbs, exceptions, and support tools. Record bounded error categories, action IDs, operation/schema/model versions, latency/tokens/cost, and admission reasons. Do not record measurements, images, notes, outputs, coordinates, full product URLs, tokens, signed transactions, or keys.
- Secure import/image processing against path traversal, archive bombs, excessive decoded pixels, unsupported files, and storage exhaustion. Validate before committing, cap resource use, remove unnecessary photo location metadata from app copies, and clean temporary files after success/failure. Imported data cannot provide executable instructions or styling entitlement.
- Treat AI suggestions as fit/style guidance, never exact sizing guarantees, medical advice, body scores, weight-loss advice, or safety-critical weather advice. Validate owned-item references, starting-item constraints, weather/occasion suitability, and three-lane diversity; flag uncertain context instead of inventing forecasts or ownership. Use respectful body-neutral language and provide a private Report Styling Problem action.
- Maintain dependency/SDK and vulnerability review, production access review, key-leak/runaway-cost response, incident triage, containment, evidence retention, and notification assessment under applicable law. App review approval does not replace these responsibilities.

## 16. Non-Functional Requirements

| Area | Requirement |
| --- | --- |
| Performance | Proposed release-build targets on physical iPhone 12 with 1,000 items/500 outfits: p95 local interactive launch ≤2 seconds, local text search ≤300 ms, and durable local save acknowledgement ≤500 ms. Also target warm Home within 1 second and ordinary selection feedback p95 ≤100 ms. Document OS/build, cold/warm start, storage/headroom, thumbnail-cache state, thermal state and batch activity; use at least 100 samples per measured operation. Normal baseline is nominal thermal state, sufficient disk, and no active migration/import; separately report stressed conditions rather than hiding them. No network wait in local launch/save. |
| AI latency | Text styling targets a few seconds locally and a single-digit-second cloud median under normal conditions; measure median/p95 by provider and enforce its 30-second overall deadline. Conditional image jobs use their separately approved asynchronous deadline in Section 9.2, with a proposed 120-second starting bound to validate, not a text-latency promise. Both show useful status by ten seconds, preserve input and support honest cancellation. |
| Reliability | Durable drafts/autosave, recoverable Trash, safe migrations/conflicts, resumable imports, and original/derivative handling survive interruption. Offline/manual core remains available through AI failure/quota exhaustion/authentication refresh. Never show Saved/Synced before acknowledgement. Every app-owned network operation follows Section 11.7 bounded waiting; publish no measured performance/reliability claim until validated. |
| Accessibility | Support all Dynamic Type sizes through AX5, VoiceOver, Full Keyboard Access, Reduce Motion, semantic contrast, and 44-by-44-point targets. No color-, pointer-, or drag-only actions. |
| Adaptive layout | Validate iPhone 12/larger iPhone, iPad mini, and 11-/13-inch iPads in portrait/landscape and system-supported resized windows; no lost state, unreachable actions, or unwanted horizontal overflow. Wide iPad must expose useful multi-pane comparison/editing. |
| Maintainability | AI providers, shopping providers, weather, and persistence should be behind protocols/services, not embedded directly in views. |
| Observability | Essential pseudonymous service/security/billing records and optional improvement analytics have separate purposes, consent, retention, and access. Audit forbidden payloads and measure latency, failure, and reserved/settled cost. |
| Financial reliability | Atomic shared admission must survive simultaneous devices, retries, timeouts, instance failures, and model changes. Local data access remains usable during provider, ledger, or budget shutdown. |
| Feedback operations | Named moderation/support owner, daily queue coverage, report-triage target within 24 hours, escalation/removal controls, and a safe publishing pause. This target is an operational choice, not an Apple-prescribed number. |
| Testing | Validate schemas/routing/petite rules, billing, consent/deletion, concurrency/budget boundaries, feedback authorization/moderation, analytics allowlists, restore/import safety, and the full iPhone/iPad UI matrix. Include release-build traces and real-device checks, not only preview screenshots. |
| Resource use | Profile a 50-photo batch, repeated manual edits and interrupted sync on physical devices. Bound decoding/concurrency/retries, stop unnecessary background work, and handle memory pressure/thermal throttling without data loss. Avoid repeatedly rewriting whole archives/images for each small edit. |
| Network and file compatibility | Verify IPv6-only access for all app services and recovery states. Support Files/iCloud documents for archive and supported image selection; use system pickers with scoped access and explicit permission fallbacks. |

## 17. Explicitly Out of Scope for MVP

- Photographing the user’s entire wardrobe during onboarding.
- Mandatory body-photo/scan onboarding and body-avatar generation. Optional photographic Generate Look is now a feasibility proposal under Section 9.2, with no guaranteed launch inclusion or untested full-outfit promise.
- Training a custom fashion foundation model.
- Guaranteed exact sizing across every retailer.
- Social outfit feed, follower system, public closet sharing, direct messages, or influencer marketplace. The moderated product-feedback board in Section 22 is included in V1.
- Android version.
- Always-on generative chat as the primary navigation model.
- AI image generation for every outfit request.
- Calendar integration or automated event extraction (can be added after the styling loop is proven).

## 18. Proposed Delivery Phases

| Phase | Deliverable |
| --- | --- |
| 0 - Prototype | Adaptive closet-first SwiftUI screens plus Section 11.7 storage/recovery: Home, comparative lanes, closet grid/detail, item swaps, Already Own and saved looks. Start Section 10.3 observed Lily sessions as soon as the core loop is usable. No AI required. In parallel, explore Section 9.2 try-on and Section 13 permitted missing-piece search; personal-image evaluation needs approved privacy controls first. Neither service replaces storage/recovery evidence. |
| 1 - Styling MVP | Flexible personal profile and conditional FitRulesEngine, Lily's scenario suite, WeatherKit, consented cloud AI, structured outfit generation, local wardrobe memory, saved outfits, verified entitlements, durable rate/usage/budget controls, and degraded-service states. Validate Lily's daily experience first. |
| 2 - Hybrid AI | Apple Foundation provider + automatic provider routing + cloud fallback. Prompt/version testing. |
| 3 - Saved looks and learning | Occasion questions/tags, reversible style and real-world fit feedback, current item links/availability, versatility and owned-piece swaps; no automatic gap shopping. |
| 4 - Optional image refinement/try-on | Exact-item photos, local cutouts and representative assets; if the conditional TO gates pass, separately budgeted Generate Look with a reusable photo, private durable jobs/results and saved-look links. Full-outfit/launch inclusion remains a prototype decision. |
| 5 - Secondary shopping | After Section 13 validation, permitted missing-piece discovery, sourced size/length guidance, editable delivery destination, checkout return/purchase capture, and unverified-search/manual fallbacks. No primary shopping feed or automatic retailer priority. |
| Before public V1 release | Validate Lily's Sections 10.2/10.3 experience and claimed audience coverage. Complete core StoreKit/trial/comp-code flows, durable drafts/manual editor/undo, strict wardrobe-only/availability, source-inclusive sync/export recovery, saved-look learning, local collage/prompt sharing, moderated feedback/private support, a compact product/support website, initial release notes, essential contextual help, optional analytics, privacy/security, iPhone/iPad and Sections 24/25 gates. If shipping fit-aware shopping, its Section 13 evidence gate is mandatory; if enabling personal try-on, all Section 9.2.5 TO gates are mandatory. Optional emails need their own Section 22.4 controls only if enabled. Clearly disclose disabled/pending services; phases are not recovery exemptions. |
| Later | After Lily validation, consider a small group with similar fit needs, then broader sizes/lengths/proportions and men's clothing only after their own fit/content/catalog/any try-on evidence plus Lily regression checks. Use the same app foundation. Offer optional welcome/check-in emails to interested early users after the communication controls are ready. Grow website guides, free tools and evidence-based comparisons from repeated questions; a large content library or regular YouTube schedule is not a launch requirement. Additional garment/layer coverage, sources, calendar, wear analytics, packing and customization remain optional; none substitutes for P0 recovery gates. |

## 19. MVP Acceptance Criteria

1. Lily can install the app on an iPhone 12 and complete onboarding without Apple Intelligence support.
2. She can choose Office, Date Night, Brunch, Concert, Casual, Event, or Other and optionally add a starting item in free text.
3. The app displays weather and season automatically and lets her override them.
4. Successful Style Me generation returns exactly three distinct lanes: Safe/Simple, Stylish/Elevated, and Creative/Risky. Strict wardrobe-only requests with insufficient valid inventory return the typed insufficient-inventory outcome and useful next steps, never fabricated owned pieces.
5. Creative/Risky includes at least one non-obvious but defensible styling or color choice and explains it briefly.
6. Every primary clothing piece in an outfit is tappable and can be swapped independently.
7. Marking Already Own persists the item and influences a later recommendation without requiring a photo.
8. A user can optionally attach a photo to a known wardrobe item.
9. Shopping is secondary to owned alternatives and requires explicit Find One. If the fit-aware finder ships, actual options have sourced size/length guidance, honest unknowns, editable delivery destination and retailer checkout, with no arbitrary region restriction. Otherwise expose its unavailable/pending status and optional unverified browser search without a verified-fit claim. Section 13's gate must pass before enablement. A saved link is a reference; ownership requires explicit confirmation.
10. A saved outfit can be reopened and modified later, preserving linked item IDs and saved revisions. Occasion suggestions use outfit metadata and confirmed preferences; the user can edit/reverse occasion tags and feedback without resending a body photo. Saving a preview does not infer actual fit, wear, ownership, or laundry status.
11. If the on-device Apple model is unavailable, cloud styling works with verified styling access, approved recipient consent, and available service budget. Otherwise, explain the unavailable path and preserve the user's local closet, saved outfits, and backups.
12. Monthly subscribers and users with a verified complimentary unlock can access AI styling within normal service controls. Without active styling access or remaining AI allowance, users can still manage their closet/availability, manually create/edit/save outfits, undo routine edits, recover drafts, sync, and export/import their data.
13. With iCloud sync enabled, user-created records become available on another device using the same iCloud account; with iCloud unavailable, the app continues locally. Deleting all data also removes synced records.
14. After completed iCloud sync, reinstalling or moving to a replacement device restores wardrobe/availability, retained source/active photo assets, saved layouts and meaningful drafts, and personal styling/fit feedback without the old Photos library. The public feedback board/account uses its separate account service.
15. A complete export saved to iCloud Drive can be imported into a fresh installation with item photos and outfit relationships intact. Repeated merge imports do not duplicate records; damaged archives leave existing data unchanged.
16. Offline or storage-full conditions show pending uploads and recovery limitations clearly. Validate photo-inclusive recovery and storage estimates with representative closet sizes before launch.
17. Monthly purchases, renewals, expiry, restoration, and complimentary code redemption work in sandbox. Cloud styling rejects unverified entitlements; importing a backup cannot unlock styling.
18. A redeemed complimentary unlock restores on another device and does not incur recurring charges. Existing subscribers are directed to subscription management to cancel any separate renewal.

19. Eligible users receive one month free followed by the finalized localized monthly price, with included allowances and renewal date shown before purchase. US$9.99/month is a planning candidate, not a hardcoded approved price. Ineligible users see accurate terms; trial activation, cancellation, expiry, and first paid renewal work in sandbox.
20. Cancelling or expiring styling access preserves the closet, photos, saved outfits, preferences, and feedback. Closet editing, sync/recovery, and export/import remain available; text styling and metered finder access follow verified styling entitlements and can resume with the existing closet after resubscription. If image packs ship, unspent purchased credits still authorize supported image jobs after styling expiry under Section 14.4.
21. On iPhone 12, a larger iPhone, iPad mini, and 11-/13-inch iPads, complete onboarding, styling, swapping, closet editing, saved outfits, purchase/restore, feedback, and Settings in portrait/landscape and system-supported resized windows. No clipped controls, overlapping text, unreachable actions, or unwanted horizontal scrolling; wide iPad visibly supports lane comparison and closet grid/detail editing.
22. Resize/rotate or show a keyboard during item/profile/feedback editing and in-flight generation. Preserve drafts, navigation, selected lane/item, generated results, and useful scroll context; provider-call counts do not increase merely from layout changes. Touch, keyboard/pointer, and drag alternatives all work.
23. Core flows pass VoiceOver, Full Keyboard Access, largest Dynamic Type/AX5, Reduce Motion, contrast, and touch-target checks in both appearances. Release-build traces with 300- and 1,000-item photo closets meet the Section 16 local responsiveness targets without eager full-resolution grid decoding or UI-blocking archive work.
24. Before cloud styling, demonstrate named-recipient permission for profile/wardrobe/free-text context. Decline/withdrawal sends no new personal request; changing to an unconsented provider is refused until permission is obtained. On iPhone 12, explain the cloud dependency before purchase; free data access persists when consent is declined.
25. Under the proposed public starting policy, a three-session day with six full generations and twelve follow-ups succeeds. After ten successful generations or forty successful follow-ups in the rolling window, the next action in that category is refused with accurate next-availability information and no vendor call. Failed actions do not consume successful-action allowance but remain in rate/spend accounting. Test owner-sponsored policy separately under criterion 57; it does not inherit these public service quotas.
26. Restore/reinstall on iPad preserves the iPhone entitlement's remaining allowance. Simultaneous requests through multiple server instances cannot exceed the shared concurrency, pending action slots, or financial budgets. Changing a client ID, adding a complimentary entitlement, or deleting personal/feedback/analytics/consent data then restoring must not mint another budget for the same styling principal; test the delete → restore → request sequence.
27. Insufficient principal/global budget, unavailable ledger/pricing/consent verification, revoked access, invalid signed purchases, replayed attestation, or client-selected expensive models are rejected before paid dispatch. An approved more expensive model still obeys reservations; alerts and global/per-provider kill switches are exercised.
28. Repeating a successfully completed action twenty times causes only its original provider dispatch and one allowance debit. Reusing its key with different content is refused. Repair/retry/fallback stays within two total attempts and independently reserved costs; ambiguous timeouts and disconnected clients remain financially accounted for without uncontrolled duplicate calls.
29. Oversized/malformed requests, unsolicited photos, arbitrary server URL-fetch requests, and injected instructions cannot alter server settings or exceed parsing/processing limits. A simulated outage creates no unbounded queue/retry storm; cached/local closet and backups remain accessible.
30. Five swaps in an unchanged weather session reuse the weather snapshot. Weather failure/quota warning uses clearly labeled stale/manual conditions without repeated fetches or fabricated forecasts; attribution remains visible.
31. Public suggestions remain private until moderation approves them. Test duplicate search/merge, one retractable vote/account, remoderation after edits, status changes, reporting, author blocking, removal/suspension, own-content/account deletion, offline draft retry, and publishing pause. Private tickets and diagnostics never appear in public APIs/search, public notifications, or analytics.
32. With improvement analytics off, transmit no optional events. Withdrawal deletes unsent events and stops collection; linked-data deletion works. Injected photos, measurements, free text, URLs, tokens, or unknown fields are rejected by both client and ingestion schemas. Allowed aggregate dashboards report usefulness, reliability, trial conversion, and costs with explicit denominators/consent coverage.
33. Audit client/gateway/tracing/crash/access logs using distinctive test measurements, notes, images, coordinates, URLs, keys, and token markers; none appear. Verify private result-cache expiry, optional analytics/support/moderation retention, backend authorization, and least-privilege operator access.
34. Delete local/synced closet data while another device is offline, then reconnect it; erased records do not resurrect. iCloud-unavailable deletion clearly shows pending remote work. Optional feedback-account deletion removes associated public content/votes, revokes Apple tokens, and provides subscription management without blocking immediate deletion. Withdraw consent/delete data during a delayed provider call: no subsequent retry/fallback dispatch or personal result-cache recreation. Retain only financial settlement/necessary anti-abuse state; restored developer backups reapply deletions.
35. Complete and retain the Section 24 release evidence: working legal/support URLs, actual privacy labels/manifests/processor settings, confirmed age/storefront scope and legal review, moderation coverage, budgets/authentication design, current Apple requirements, and reviewer access. These are implementation/release checks, not claims that this documentation already passes App Review.
36. From a fresh empty closet, Lily gets useful Suggestions-mode outfit ideas without importing/photographing garments. Pricing, AI allowances, and practical import/storage bounds are visible before starting the work; V1 has no subscription-dependent item/outfit count cap. Adding text-only items through Already Own remains sufficient.
37. Force-close at accepted-edit/draft-save, source-copy, photo processing, explicit outfit-save, import-staging/commit, and sync boundaries. Relaunch recovers acknowledged local changes and meaningful drafts with no duplicate entries, broken references, false Saved/Synced state, or public feedback publication. An interrupted overwrite preserves either its prior or new complete revision, never a half-written outfit.
38. Repeatedly edit one saved look, undo/redo, save, relaunch, and save again offline and with no AI entitlement/remaining allowance; its ID and relationships stay stable. Save as Copy alone creates a new outfit ID. A failed save/discard does not destroy the prior saved version; a delayed AI result cannot overwrite later manual edits.
39. Replace/process/revert photos with different resolutions/aspect ratios and silhouettes across a fixture where affected items appear in many of 500 saved looks. Item/piece IDs, layouts, scale/rotation/order/crop/fit settings and relationships remain intact; the original and prior usable replacement remain recoverable according to retention. Colors do not change without explicit acceptance, and failed processing does not block manual editing.
40. Interrupt a multi-item import, lose a source permission/download, resume, retry a failed entry, and cancel remaining entries. A valid item has a durable source before optional processing; retries create no duplicate garments, while two intentionally separate identical garments remain separate. Corrupt/low-space staging cannot replace a prior usable photo or leave dangling saved references.
41. Export **1,000 garments and 500 saved outfits**, including sources, active derivatives, availability, stable IDs/layouts, drafts, and eligible retained history. Restore on a fresh installation without the original Photos library and compare manifest counts, asset hashes and relationships/layouts. Run separate completed-iCloud recovery. Interrupted/damaged merge/replace leaves the previous closet intact; repeat merge creates no duplicates.
42. On Lily's iPhone 12 with that dataset, exercise browsing/manual editing/saving/undo/export under poor/no internet, AI and iCloud outages, denied photo/camera/location permissions, and low storage; also run representative iPad layouts. Preserve acknowledged data and usable local actions with explicit retry/recovery states. Export/import may be refused safely when disk is insufficient; never clear data or claim backup success on failure.
43. In strict wardrobe-only mode, inject nonexistent/deleted/trashed/unowned IDs, fabricated attributes, and Dirty/Unavailable/Archived IDs without an explicit per-request override into local/cloud responses, including an inventory change in flight. Validation refuses them; displayed pieces resolve to canonical current records. Test a confirmed single-ID status override without changing stored status or permitting any other ineligible item. Put valid alternatives outside the initial shortlist: full-store preflight must not report global insufficiency solely from shortlist/model failure. Non-success never fabricates three looks, auto-switches mode, or consumes a successful action.
44. Start with skipped measurements; verify editable profile and honest unknown tags/placeholders. Saving a suggestion/link or wishlisting never marks it owned; Already Own and I bought this explicitly do. A one-item swap preserves all other selections/layout values. Too dressy/not my style/wrong weather/exclusion feedback reduces unsuitable repeats and can be reversed; Worn does not silently mark garments Dirty or create a shopping checklist.
45. Archive, unarchive, Trash, restore within 30 days, expiry, and Delete Permanently preserve the documented ID/recovery semantics. Permanent purge removes garment content from photos, collages, embedded outfit descriptors, drafts/history/caches and pending jobs; another offline device and routine old-archive merge cannot resurrect it. Show shared-asset and independent-export limitations before purge. Delete My Data bypasses Trash recovery.
46. Upgrade every supported old schema fixture; interrupt each migration boundary and simulate low disk/corrupt assets. Recover the prior complete store without reset or destructive partial upgrade. Edit the same outfit/item on two offline devices, then reconnect in both orders, including archive/Trash/permanent delete versus edit. Conflicts remain reviewable and delivery/retry creates no duplicates or silent loss.
47. Measure Section 16 p95 launch/search/save targets on physical iPhone 12 with 1,000 items/500 outfits; import 50 typical phone photos while browsing/editing remains responsive. Include at least 100 saved outfits sharing a replaced image and transparent/white/black/patterned/logo fixtures; preview versus saved/exported composition stays consistent. Record memory/thermal behavior, bounded concurrency, and retry of failed entries only.
48. Exercise AI/weather/feedback authentication expiry, malformed response, timeout, 429/5xx, cancellation, and IPv6-only networking. App-owned calls respect deadlines/status by ten seconds; system-managed pending sync/purchase stays honestly Pending without blocking local edits or restarting charges. Denied Photos/location and retailer metadata failure offer manual/screenshot fallbacks subject to rights and safe import bounds.
49. Retain the current Apple review mapping in Section 24.4 with actual build evidence, including public APIs/container access, intended background execution, power/memory checks, current SDK/upload requirements, truthful metadata/name/age/accessibility declarations, and both iPhone/iPad flows. Classify the shipped Ask Stylist surface before submission; no unreviewed remote software/plugin catalog or native code execution.
50. Before enabling the optional fit-aware finder, complete the Section 13 permissioned-catalog/fit prototype with real products across brands, garment categories, and multiple delivery destinations. Confirm provider eligibility, required user inputs, image/cache rights, size/length data, freshness, privacy/deletion, latency, and cost. Validate fit claims with representative consented outcomes; no universal coverage or exact-fit claim. Missing access/evidence blocks claiming the fit-aware finder is ready; core wardrobe styling remains independently usable.
51. If enabling the fit-aware finder, exercise US/UK/EU and brand sizing, body charts versus garment dimensions, Petite versus better-fitting regular/cropped options, supported size with unknown length, unavailable/backordered variants, and changed price/stock. Distinguish no delivery, unverified delivery, insufficient catalog coverage, and service failure. Changing destination does not alter weather or silently relax size requirements; basic styling remains usable wherever shopping coverage is absent.
52. If enabling the fit-aware finder, reuse a saved fit profile without repeated setup; skipped measurements, no photo, no retailer connection, and no app account remain supported. A targeted follow-up is skippable and unknown fit stays explicit. Personal fit-service sharing requires approved recipient consent; refusal/withdrawal stops dispatch. Test shopping cancellation/outage, finite fan-out/retries, shared cost reservations, stale-result rejection after profile changes, and no purchases or ownership transitions from product clicks.
53. Open/dismiss a permitted retailer web sheet and leave/return through external browser/store app, including background/force-close. Restore the same outfit/product without new paid searches, false purchase detection or repeated prompts. Confirm actual size/color and not-arrived availability, add an item via Camera/Photos/screenshot/explicit Paste/text, and retry interrupted purchase/import saves without duplicates. Missing link metadata stays editable/unknown; photo-later and explicit Add to This Outfit preserve stable relationships and other selections.
54. View the closet grid and assemble/save a mixed garment outfit locally, with clear owned/wishlist/inspiration/not-arrived labels. Export a look or selected items as a readable numbered collage plus editable prompt, offline and without styling access; include larger selections as legible bounded batches/pages. No generative model, fit, or discovery call is made for rendering/template preparation. Restricted retailer media uses a placeholder/own-photo alternative; sources/layouts stay unchanged.
55. Test native sharing on iPhone/iPad with an installed, missing, image-only and text-only receiving destination; support Save Image/File and Copy Prompt fallback. Opening/canceling our export preview or system share sheet before recipient selection makes no app-initiated upload/model call or automatic clipboard action. Selecting a recipient hands over the reviewed payload under its policies; canceling its UI does not prove successful sending or recall already handed-off copies. Personal fields default off; exact payload preview matches the shared content, metadata is sanitized, temporary copies expire/delete, and external copies are described honestly. An external AI answer cannot automatically change wardrobe/ownership/fit records or bypass available-item validation; manual saving remains possible.
56. If image packs ship, verify signed purchases, duplicate deliveries, purchase-before-finish interruption, atomic customer-unit reservations and separate provider-cost settlement. Trial/paid allowance and non-expiring purchased balance stay distinct. Failed technical jobs release customer units; delivered-but-disliked previews and explicit regenerations follow disclosed rules. Reinstall/device recovery restores the server's actual unspent balance, not original purchased totals; expired styling subscription does not strand purchased credits. Refunds/revocations do not delete saved personal data.
57. Verify Lily's complimentary redemption and authorized Sponsored policy across reinstall/iPhone/iPad: no subscription or image-pack purchase is required, public service quotas are replaced by approved sponsored policy, and the owner can monitor/increase her budget. A forwarded code, unrelated complimentary principal, restored duplicate entitlement or forged client flag cannot obtain sponsorship. Technical bounds, consent, idempotency and global emergency controls still work; no automatic customer charge occurs at a sponsored budget ceiling.
58. Validate the Section 10.2 Lily scenario suite using her 4'11" context and confirmed garment/fit/style evidence; optional 110–130 lb context never maps to a size or fabricates measurements. Changing/skipping weight cannot override confirmed dimensions/fit references or cause a weight-only size change. Profile-specific conditional rules, unknown dimensions, raw/category/brand sizing context and reversible feedback survive save/sync/export. No 5-foot/size/gender eligibility gate or added mandatory onboarding. Broader fixtures cannot overwrite her preferences, and model/rule/coverage rollout must pass her prior scenarios; no universal fit/support claim without separate evidence.
59. Complete a consented Section 10.3 observation cycle on a usable build: record an unassisted/assisted task result and completion time; for styling, record time to a self-reported wearable look or no acceptable look. Record concrete friction, a prioritized change and retest outcome when a change is indicated, or why no change was needed. Add any reproducible case to the existing scenario suite. No automatic recording, wardrobe upload or new analytics payload is introduced; task speed is not presented as physical-fit validation.
60. Before public launch, inspect the compact Section 22.3 website on phone and desktop, with keyboard access and readable enlarged text. The product demonstration, pricing/trial/free-core explanation, limitations, support/legal/feedback links and footer work and match the shipped app. There are no empty promised content sections, unsupported fit/connector claims or unmetered public AI/photo endpoints.
61. Publish initial and subsequent public-version release notes with version/date, user-visible changes and known limitations. Verify links resolve only to approved public feedback and no private reporter/ticket/wardrobe data is disclosed. Essential current-version notes are readable in-app without an account or styling entitlement; offline copies show their version and stale state where relevant.
62. If the optional email program is enabled, verify separate affirmative opt-in, a voluntarily supplied address, reply handling, unsubscribe/deletion and queued-send cancellation. Decline/unsubscribe leaves core and paid access intact. Support, Apple identity, billing and analytics addresses/identifiers never populate the list; messages contain no wardrobe/profile data, tracking pixels, tracked links or automatic behavior-based targeting.
63. Open the initial contextual help on iPhone/iPad with no account, expired styling access and no internet: gradual setup, add a garment, swap/save/reopen, availability/originals, and sync/export/restore instructions remain readable. Exercise the documented manual actions offline; help explains which styling/cloud operations need service access or connectivity. Help preserves the current draft, invokes no AI and accurately distinguishes conditional try-on previews from physical fit. Website versions and current app help agree.
64. Validate nice-occasion, casual-outing and everyday-polished scenarios with Lily: coordinated color variety follows her preference, an explicit monochrome request works, and her supplied 25-/26-inch inseam preference stays editable with honest measurement-basis/cut unknowns. Change or clear inseam, sleeve length, waist and bust independently; current-profile assessments reflect the edit, stale context is identified and saved outfits/garment dimensions/petite preferences remain intact. Save/sync/export/restore preserves the current values, units and basis; editing causes no automatic AI dispatch. Record whether the native board helps her choose what to try on. No invented sleeve/fabric exclusion, height-derived measurement or image-based fit claim; enabled try-on separately passes its TO gates.
65. Verify adults-18+ intended scope and United States-only initial App Store configuration, approved minimal age eligibility before personal cloud processing, actual processor requirements and separate AI consent. Truthful age-rating answers and any EULA-required higher override agree; a declaration is not labeled verified age. Known ineligibility stops new covered processing while recovery/export/deletion remains accessible.
66. Exercise a simulated candidate-market configuration without production enablement: storefront, delivery destination, weather location, language, units/size labels and price currency stay independent; disabled service coverage leaves local core intact. Existing Lily fit/color/workflow cases pass without profile or sponsored-access changes. Retain per-market legal/service/localization/support evidence before actual rollout; new-client requirements cannot be bypassed by remote configuration.

## 20. Risks and Open Decisions

| Risk / decision | Mitigation / next step |
| --- | --- |
| Public pricing, sponsored usage and image packs | Owner funds Lily as a personal expense; profitability is secondary. Measure trial/paid/sponsored usage separately. US$9.99/month is a candidate, and public image allowance/pack quantities remain open. Sponsor overrides public quotas with an approved budget; technical/global controls remain. Purchased credit recovery, non-expiry and after-subscription use must pass before sale. |
| Fashion quality of AI output | Use structured lane prompts plus deterministic petite/occasion/weather validation instead of trusting raw LLM prose. |
| Lily quality versus audience expansion | Validate Lily first using confirmed fit/style evidence and her saved scenarios. Flexible per-profile rules prepare later expansion; wider sizes/lengths and men's clothing remain unvalidated. Preserve her preferences and require Lily regression checks alongside each new audience's evidence; no second app or broad launch commitment. |
| Representative image library scope | Start with a compact set of common garment types/colors; expand from observed user needs. |
| Retailer image rights | Keep product links as references. Permanent wardrobe images come from user photos, app-owned assets, or explicit retailer licenses. |
| Petite fit confidence | Deliver product-specific evidence where supported, separating size from length/proportions. Validate with fit feedback; never claim guaranteed fit or fabricate confidence when garment data is missing. |
| Catalog/fit access and international delivery | Section 13 is a new V1 target. Verify independent-app access, permitted catalogs, petite dimensions, delivery evidence, input/consent requirements and per-search economics before committing a provider or advertising coverage. No artificial one-country feature boundary; incomplete sources still limit supported results. |
| Retailer checkout and external-AI handoff | Preserve local context across web/app return; require manual ownership confirmation. Amazon-specific access/media/browser rules must be verified before integration. Native sharing receivers vary; retain save/upload/paste, exportable imagery, and explicit personal-data preview. Local sharing invokes no AI API but does not promise the chosen service is free. |
| Optional try-on fidelity and personal-photo cost/privacy | Section 9.2 is a prototype proposal. Validate real garment/body preservation, supported item count, privacy/retention/deletion, saved-artifact recovery and cost per accepted look before enablement. Visual preview does not prove size/length fit; separate image allowance and server ledger are required. |
| Naming / trademark | “My Petite Style” is a working title; perform App Store and trademark availability checks before publication. |
| Pricing | One-month introductory trial for eligible users retained; previous fixed US$4.99 assumption reopened, with US$9.99/month a candidate. Finalize localized price, included image allowance and optional pack terms using experience/cost measurements; no profitability promise. |
| Cloud privacy | Require named-recipient consent and approved processor terms, minimize context, and block dispatch after withdrawal or unapproved recipient changes. |
| iPad quality | Treat comparative workspace, window resizing, keyboard/pointer input, and accessibility as V1 requirements; test the device/window matrix before launch. |
| Public feedback abuse | Pre-moderate publication, provide report/block/contact, staff a moderation queue, and pause publishing if the operator cannot meet response targets. |
| Privacy/legal scope | Confirm age audience, launch territories, data classification, processors, payment terms, and retention with qualified review before release; apply additional jurisdictional requirements before expansion. |
| Analytics scope creep | Enforce client/server event allowlists and independent consent; no session replay, prompts, closet contents, or marketing tracking in V1. |
| Work loss and stale asynchronous results | Durable drafts, atomic saved revisions, bounded undo, import journaling, and revision checks; force-close and delayed-result checks are release blockers. |
| Source-photo storage and layout disruption | Retain source/derivative revisions, stable piece/layout references, and explicit cleanup choices; source-inclusive storage estimates and fresh-install recovery must be verified. |
| Wardrobe-only hallucination or unavailable clothes | Validate transient allowed IDs on backend and canonical current records on client; availability filters and typed insufficient-inventory outcomes apply to both providers. |
| Persistence framework uncertainty | SwiftData is a proposed baseline, not proof of recovery. Section 11.7 migrations/offline conflicts/original-file prototype must pass before production schema commitment. |

## 21. Technical Reference Notes

The following platform capabilities were used to shape the architecture. These are implementation references, not product dependencies that must all ship in V1.

Apple Foundation Models - SystemLanguageModel: Apple documents SystemLanguageModel as the on-device model powering Apple Intelligence and requires an availability check because devices may be ineligible, Apple Intelligence may be disabled, or model assets may not be ready.
https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

Apple Foundation Models updates: Apple documents a LanguageModel protocol for using server or on-device language models, supporting the provider-abstraction approach.
https://developer.apple.com/documentation/Updates/FoundationModels

WeatherKit: WeatherKit provides current and forecast weather through Swift APIs and includes a substantial monthly request allowance with Apple Developer Program membership.
https://developer.apple.com/weatherkit/

Shopping remains user-directed with browser checkout. No specific retailer integration, including Amazon, is selected; the earlier browser-search-only plan is superseded by Section 13's prototype-gated fit-aware target. Catalog/fit integration does not authorize scraping or arbitrary URL fetching.

Product images for owned items come from user-provided photos or licensed assets; source links do not authorize permanent image storage.

Apple subscription and offer-code references are included in Section 14. Configure subscription products, required agreements, and pricing in App Store Connect before launch.

## 22. Feedback Board and Private Support

The feedback board is included in V1 and accessible from navigation and Settings. Its purpose is to improve the app through feature ideas, votes, and visible development status. It is not a social closet feed. Basic browsing and private support remain available regardless of subscription state.

| Surface | Required behavior |
| --- | --- |
| Public ideas | Search/filter approved feature suggestions by topic/status; sort by recent or votes. Show title, sanitized description, generated public alias, vote count, and developer status. Only approved public fields enter public APIs/search. |
| Submit idea | Suggest existing ideas before submission. Title at most 120 characters and body at most 2,000. Show what will be public and prohibit personal/contact/body/closet data. No public photo attachments, comments, DMs, or follower features in V1. |
| Participation identity | Optional Sign in with Apple for public posting/voting, with backend token verification and a pseudonymous public alias. Never expose Apple identity/email or connect the public alias to purchase IDs. Core closet, purchases/restoration, and board browsing require no feedback account. |
| Voting and ownership | One retractable vote per account per idea; no paid vote weighting. My Submissions shows pending/approved/rejected/merged status. Authors can withdraw/delete their ideas; edited content must pass moderation again before it becomes public. |
| Roadmap status | Under review, Planned, In progress, Released, or Not planned; only authorized staff change status or publish staff replies. Status does not promise a delivery date. Merged duplicates retain a visible destination; do not silently multiply votes. |
| Private issue form | Bugs, styling quality, billing, security, and privacy reports enter a private support queue, never the public board. Provide support contact without account creation. Optional reply email is used only for the ticket; submission clearly shows recipient and included fields. |
| Diagnostics | Only with an explicit preview/submit action: app/OS version, operation/error category, and an opaque error reference. No automatic prompts, outfit text, measurements, photos, exported closet, or full product URLs. V1 attachments are disabled; users can describe the issue in their own text. |
| Offline/error | Cache approved public ideas read-only with a stale indicator. Keep a private local submission draft; explicit retry uses idempotency and must not create duplicate posts or tickets. Do not publish automatically on reconnect without a clear queued-submission state. |

Public and private submissions require separate forms and explicit choices. Private content must never appear through public responses, moderator status messages, search indexing, notifications, analytics, or duplicate-detection results. Server authorization protects own drafts, private tickets, and moderator views.

### 22.1 Moderation and abuse controls

- Filter objectionable content and obvious personal information before publication; human moderation approves public suggestions and substantive edits. Keep rejected material private. Prohibit harassment, body shaming, sexual content, threats, spam, unlawful content, and unauthorized personal information. Display accessible community rules.
- Provide Report Content and Block Author on public posts. Blocking hides that author's content for the blocker; staff can suspend abusive accounts and remove content from the service. Reports receive timely review, including already approved posts. Pre-moderation does not replace report/block controls.
- Assign a named operator and daily coverage before release. Target report triage within 24 hours; escalate urgent safety/privacy/security issues immediately, remove violating content, notify the reporter of resolution where appropriate, and record minimal moderator actions. Provide an appeal/support route.
- Proposed submission defenses: at most 3 public ideas per account per rolling day, 1 vote per account per idea, and 5 private tickets per authenticated principal/installation per rolling day. Add bounded body sizes, idempotency, and edge abuse limits; rate limiting must preserve an independent published support contact for legitimate urgent/billing/privacy requests. Do not use paid AI to moderate every keystroke.
- If moderation coverage or public services fail, pause new publication and keep already approved content/read-only status or a clear unavailable state. Private support/contact remains reachable. Never launch an unmoderated public board as a temporary fallback.
- Account deletion removes associated public content, votes, and account identifiers according to Section 15.4. Provide in-app deletion and revoke Sign in with Apple tokens; account deletion does not cancel StoreKit billing.
- Publish current support/contact information in-app and at the App Store Support URL. App Store review prompts use Apple's supported mechanisms without rewarding votes/reviews or sending only happy users to ratings. Product feedback is not a substitute for unbiased App Store reviews.

References: [Apple user-generated-content and developer-contact requirements, Guidelines 1.2 and 1.5](https://developer.apple.com/app-store/review/guidelines/#user-generated-content), [Sign in with Apple token revocation](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens), and [account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/).

### 22.2 Public versioned release notes

Decision approved October 3, 2026: add a small read-only What changed surface on the website and in Settings/Help, alongside the existing feedback statuses.

- Each public app version has a version/build identifier, release date, concise user-visible improvements/fixes and known limitations. Publish shipped behavior accurately; planned work stays labeled on the roadmap. Link addressed ideas only when their public content has been approved. Sanitize issue summaries; never publish private ticket text, reporter identities, measurements or wardrobe material.
- A named operator maintains notes with each public release. Bundle essential current-version notes for fresh-install offline reading, then cache later web updates and label their version/date and stale state where relevant. Reading needs no account or subscription and creates no comment/feed surface.
- Give a private reporter a relevant resolution update through the support channel they requested, without subscribing them to optional emails. No forced release-note modal, push notification or new primary tab is required.

### 22.3 Product website and concise help library

Decision approved October 3, 2026: ship a compact product/support website and task-based help before public V1 launch. Reuse Section 7.1's visual theme and the existing legal/support requirements; website implementation/hosting remains an open choice rather than a replacement for the native app stack.

The initial site explains the owned-clothes-first promise, shows an occasion → outfit options → one-piece swap → save demonstration, and provides actual pricing/trial/retained-free-core terms, fit/AI limitations, FAQ, About, support/contact, feedback, release notes, Privacy and Terms. Use fictional or explicitly permissioned demonstration material. A prototype is labeled as such; public launch screenshots and download actions reflect the actual available app. Lily's name, personal story or images are published only with her choice. Support and information remain available without account creation.

Keep the top navigation small: How It Works, Pricing, Guides/Help, Support and the actual available Download action. Use this footer taxonomy as content grows; publish only working destinations and omit empty groups rather than building a large content library before Lily's flow works.

| Footer group | Initial or staged content |
| --- | --- |
| Product | Home/How It Works, Pricing, Fit & AI Limitations, iPhone & iPad, AI Sharing, Feedback and What changed. AI Sharing describes the implemented local collage/prompt export; AI Connectors is used only after a real separately validated integration exists. |
| Guides | Start without a full closet upload, Add a Garment, Swap/Save a Look, Petite Fit Basics, Measuring Inseam/Rise and Backup/Restore. Begin with the essential help below; expand from repeated questions. |
| Tools | Later free measurement-unit conversion, a weekly outfit worksheet, packing checklist or downloadable templates. Prefer bounded deterministic/local helpers; this website does not introduce a free unmetered AI/image service or an exact-fit predictor. |
| Compare | Later factual wardrobe-app/features/cost comparisons and manual versus AI styling explanations, with dated primary sources and research limits. Competitor opinions and historical complaints are not proof of current defects. |
| Company | About/why built, Contact, Support, Privacy, Terms and accessibility information reflecting actual tested support. Build Notes/newsletter and social links are optional maintained content, not required channels. |

Essential help is short, task-based and reachable from the relevant app screen as well as Settings/Help. Bundle the core instructions for offline access without AI, subscription or login, preserve the current draft when opening/dismissing help, and maintain website versions from the same approved content source. A named content owner checks changes against the current app version at release; help is not an independently maintained specification or mandatory walkthrough.

Initial help covers getting suggestions without importing the whole closet; adding one garment or a confirmed purchase; manual swapping/saving/reopening; ownership and availability; original photos and optional processing; local saves versus iCloud sync versus independent export; safe restore; retained free core versus paid AI; and AI preview versus physical-fit limitations if try-on is enabled. Keep key explanations readable outside screenshots. Check website links, phone/desktop layout, keyboard access and enlarged text before publication. Publish only validated fit, feature and pricing claims under Sections 24/25.

### 22.4 Optional personal welcome and check-in emails

Decision approved October 3, 2026: support a small optional program for interested early users after Lily's core flow is useful. This is not a prerequisite for Lily testing or public core launch, and it does not introduce mandatory accounts or emails for closet use.

- Invite participation with an independently volunteered address and affirmative opt-in explaining who sends the messages, their purpose, the expected welcome/check-in cadence and how to stop them. No preselected consent. Do not use a private support reply address, Apple identity, receipt, analytics identifier or purchase record to create/target a mailing list.
- Start with one brief replyable welcome explaining how to get a first outfit without inventory homework, followed by one optional check-in asking whether they found a look they would wear and where they got stuck. Send personally during early testing; select an email service only when necessary. Occasional broader product updates require a separately stated optional preference. Do not add tracking pixels, tracked links, automatic wardrobe-based targeting or profile/closet transfers. A habitual growth campaign is not required.
- Provide a monitored reply address and an easy no-account unsubscribe/deletion route in each optional message. Check current consent immediately before sending; withdrawal removes queued messages and prevents future optional sends. Apply the Section 15.4 inventory, processor, retention and deletion requirements before enablement. Ticket replies remain limited to the requested support conversation and never confer mailing permission.

Research basis checked October 3, 2026: Amy's [product website](https://www.amyfoodjournal.com/), [public updates](https://feedback.amyfoodjournal.com/updates) and [contact page](https://www.amyfoodjournal.com/contact), plus Chris Raroque's [personal welcome-email account for his Luna budgeting app](https://www.linkedin.com/posts/raroque_userexperience-onboarding-activity-7252000364525150213-L-27). These practices inspired the accepted additions; no verified email/website conversion lift, Amy reliability audit or guaranteed outcome is implied.

## 23. Analytics for Product Improvement

Local wardrobe learning stays private and works without improvement analytics. Optional first-party product analytics defaults **off** until an independent opt-in explains the purpose and data categories. A Settings toggle allows withdrawal without losing paid or free features. Essential access, spending, security, and service records are separately disclosed and minimized; do not relabel optional engagement tracking as essential.

### 23.1 Allowed events and properties

Use a versioned client **and ingestion-server** allowlist. Reject unknown fields, invalid enums, oversized batches, and nested/free-text properties; never automatically serialize view text or user objects.

| Event family | Allowed measurement |
| --- | --- |
| Onboarding | Started/completed/abandoned-step enum; no entered profile values |
| Styling | Requested/completed/failed, local/cloud route, latency bucket, bounded error category, model/config version |
| Usefulness | Lane-selected enum, swap completed, Already Own/add item, saved outfit, optional worn/helpful signal; no garment descriptors |
| Data reliability | Export/import and sync outcome, record-count band if needed, coarse duration/error category; no archive, identifiers, filenames, or content |
| Local reliability | Session start/end/crash outcome, launch/search/save timing bucket, interrupted import and save/migration/sync/restore failure enum; no entered search, stack-local values, images, or garment IDs |
| Access funnel | Paywall viewed, trial activation result, restore result, allowance reached, consent-screen outcome; no receipt/transaction tokens |
| Feedback | Form type enum and submission outcome; no idea/ticket text, alias, email, or report details |

Shared properties may include event ID, coarse time bucket, app/OS version, iPhone/iPad device class, operation/outcome enum, and consent-schema version. A random, resettable analytics identifier may support consented funnels, but remains pseudonymous; never join it to billing, public accounts, precise location, or wardrobe records. Do not collect body measurements/weight, photos, prompts/responses, free text, garment attributes, retailer searches/URLs, contact details, tokens, or Apple transaction identifiers. V1 has no ads, IDFA, cross-company tracking, fingerprinting, session replay, screen recording, analytics screenshot capture, or automatic view-text capture. Explicit local collage export/user screenshots are separate user actions and never become analytics payloads.

- Queue only after consent, at most 100 events or 64 KiB per device, expiring within 7 days. Nonessential analytics never block rendering, styling, saving, or exit. Withdrawal stops collection and clears unsent events immediately; Delete Analytics Data removes linked retained events and resets the analytics ID.
- Raw optional events expire within 30 days. Longer-lived aggregates remove identifiers and suppress very small cohorts to reduce re-identification risk. Protect ingestion/database access, cap request frequency/batch sizes/storage, and include its costs in operational budgets.
- Use aggregate StoreKit entitlement/renewal and cost totals for billing operations without requiring analytics opt-in. Optional behavioral funnels must use consented events. Report the analytics-consent population and denominator; do not treat its behavior as automatically representative of all users.
- Dashboard requirements: three-lane completion/failure and latency, save/swap/worn or helpful signals per completed generation, repeat styling use, trial-to-first-paid and later renewal rates, non-converting trial inference cost, principal/cohort spend, sync/import failures, iPhone/iPad reliability, and moderated feedback trends. Generation count or trial starts alone do not prove product value.
- Experiments may compare UI/prompt/model configurations only within approved consent, schemas, allowances, and budgets. Track versions, define outcome/quality guardrails, and provide rollback. Do not experiment with undisclosed sharing, surprise charges, or data retention.

First-party improvement analytics is not automatically tracking under Apple's ATT definition. Reassess and obtain ATT permission if future behavior meets that definition; ordinary privacy disclosure/consent obligations still apply. Keep App Store privacy answers and SDK manifests consistent with actual behavior. Reference: [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

### 23.2 Reliability operating targets and incident priority

Proposed post-launch operating target: **≥99.9% crash-free sessions** over a rolling 30-day window with at least 10,000 measurable sessions. Define a session as foreground use beginning after launch or at least 30 minutes of inactivity; distinguish OS/user force-termination, controlled test interruptions, and actual process crashes. Document the collector's detection limits, crash count, denominator, app/OS cohort and consent coverage. Below the sample threshold report insufficient evidence, not a reliability guarantee. This is an operating target, not a requirement to collect 10,000 sessions before the first release or an Apple-prescribed threshold.

Only opted-in app diagnostics/analytics or user-authorized platform diagnostics contribute to optional client metrics. Diagnostic collection must redact payloads, avoid memory dumps/view text, and comply with the Section 23 allowlist; track local operation timing and save/import/sync/restore failure enums without wardrobe content. Private bug reports can include a user-reviewed opaque operation/error ID with optional diagnostic consent; submitting one does not require a closet/photo upload.

Any confirmed loss of acknowledged user data is P0: pause the affected rollout/destructive operation, prioritize containment and recovery over new features, preserve a privacy-minimal reproduction, and require the failed boundary plus related recovery tests to pass before resuming. Assign an incident/support owner and give affected users accurate recovery status through the established support process. Track p95 local timings, interrupted imports, save/sync/restore failures, and recommendation feedback alongside crash rate; a high crash-free rate alone does not prove data safety.

## 24. App Store, Legal, and Release Requirements

Policy references were checked October 3, 2026. Recheck the current Apple rules, submission toolchain requirements, provider terms, and applicable law before each public release or material payment/data change. This PRD specifies required work and release evidence; it does not establish App Store approval or legal clearance.

### 24.1 Payments, disclosures, and submission

- Use the StoreKit monthly subscription and Apple-issued complimentary IAP code plan in Section 14, with optional StoreKit consumable image packs only if that service is enabled. V1 has no independent digital checkout, family password unlock, or requirement to purchase elsewhere. Physical clothing is purchased with the retailer through a permitted web sheet or external browser/store app; it does not unlock the app or create an Apple digital-content purchase. Optional external-AI sharing exports local content; it does not sell another provider's plan, embed its chat service, or unlock premium app features through external payment.
- Paywall and store descriptions identify paid AI versus retained free closet functionality, actual trial eligibility/duration, localized renewal amount/period, cancellation/management, meaningful cloud allowances, and cloud dependencies. Supply functional Terms of Use, Privacy Policy, and support URLs, and restore/redeem access. Terms describe service scope, fair use, AI limitations, cancellation/refund routes, complimentary access, and applicable rights without overriding Apple's purchase flow or statutory rights.
- Keep subscription services available across the user's supported devices. Complete developer agreements, tax/banking setup, subscription group/products, offer-code eligibility, and production/sandbox separation. Do not show a false trial to an ineligible user or charge a device twice for already restored access.
- Explain the non-consumable complimentary unlock, restoration and owner-authorized sponsored policy to App Review, including non-recurring access, public versus sponsored allowance treatment and retained technical/global controls. Configure production codes only when Apple's required app/product statuses permit; code redemption deadlines are distinct from entitlement duration. Validate the product's review approval before promising production family codes.
- App Review receives working backend services and instructions/access for subscription, complimentary/sponsored, cloud-consent, iPad, feedback-account, moderation/report/block, and deletion flows. If try-on/packs ship, include separate image-purpose consent, generation, allowance/wallet, non-expiry, after-subscription use, purchase/refund and balance-recovery review paths. No hidden review-only behavior or security bypass. All published metadata, age-rating answers, screenshots, privacy answers, and model/fit claims match the shipped app; screenshots use fictional data and show real iPhone/iPad experiences.

Sources: [Apple subscriptions](https://developer.apple.com/app-store/subscriptions/), [introductory offers](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions), [IAP offer codes](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-offer-codes-for-in-app-purchases), and [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

### 24.2 Privacy and legal launch scope

- Decision confirmed October 3, 2026: intended public users are adults aged 18 or older; initial App Store distribution is the United States. This reduces the intended launch scope but does not itself verify age or remove applicable privacy obligations. V1 does not add HealthKit, biometric identification, medical diagnosis, or weight-loss features.
- Approve and test a proportionate age-eligibility method for the adult service and actual processors before personal cloud processing, including optional try-on. Prefer the minimum eligibility result needed; no full birth date, identity document or age inference from body data/photos by default. A declaration must not be described as verified adulthood or universally sufficient compliance. If an ineligible/minor user becomes known, stop new covered processing and follow the reviewed handling/deletion process while preserving local recovery/export/deletion. Age eligibility and AI-recipient permission remain separate.
- Complete Apple's age-rating questionnaire truthfully for actual shipped features. If the EULA's minimum age exceeds Apple's calculated rating, apply the required higher-rating override; displayed ratings can vary by region and OS. A rating is not identity/age verification. See [Apple age-rating setup](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).
- Configure United States availability explicitly and assess each later market under Section 11.8 before expanding. App Store Connect requires a trader-status declaration even without EU distribution; EU distribution as a trader additionally requires verified public contact information. Plan appropriate operator contact details and complete the applicable process without assuming trader status from a hobby/profit label alone. See [Apple DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/).
- Obtain a documented jurisdictional review of privacy notices, body-measurement/weight classification, lawful bases where required, processors/contracts, cross-border transfers, data rights, consumer subscription disclosures, applicable tax/refund rules, and breach notification. Where a field/use falls under Apple's restriction on personal health information in iCloud, remove that prohibited sync or field before launch; do not assume all body data is legally interchangeable.
- Assess Apple's Guideline 5.1.1(ix) against the actual required data and service. If sensitive-user-information or regulated-service criteria apply, use the legal entity providing the service for enrollment/submission rather than an individual developer. Record this decision before configuring the public developer identity; fashion positioning alone does not settle the classification.
- Assess COPPA when the service is child-directed or there is actual knowledge of covered under-13 collection; assess GDPR territorial/application requirements for relevant EU activity; assess CCPA and other state laws from actual applicability criteria. Neither a small user count nor App Store approval establishes an exemption. Expansion requires a fresh assessment rather than silently enabling all storefronts.
- Execute processor agreements and verify selected AI/hosting/SDK retention, training use, security, deletion, and international transfer practices. Keep a maintained subprocessor list and legal/support contact. Publish accessible rights-request procedures for access/export, correction, deletion, and consent withdrawal; verify requests proportionately and respond within applicable statutory deadlines.
- Complete accurate App Store privacy disclosures and the `PrivacyInfo.xcprivacy`/required-reason API and third-party SDK manifest/signature audit where required. Manifests, privacy labels, ATT, and user consent serve different purposes; completing one does not replace the others. Do not charge merely for Apple's built-in iCloud sync.
- Name the responsible operator/legal entity and privacy/security contact. Maintain a proportionate written security and incident-response program, legal retention schedule, vendor review, and breach-assessment/notification procedure. Include applicable obligations such as New York SHIELD where covered information is maintained.

Primary references: [FTC COPPA guidance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions), [EDPB GDPR territorial-scope guidance](https://www.edpb.europa.eu/documents/guideline/guidelines-32018-on-the-territorial-scope-of-the-gdpr-article-3-version-adopted_en), [California CCPA guidance](https://www.oag.ca.gov/privacy/ccpa), [New York SHIELD guidance](https://ag.ny.gov/resources/organizations/data-breach-reporting/shield-act), [Apple required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), and [third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/).

### 24.3 Release evidence and ownership

Assign named owners before external testing; one developer may hold multiple roles, but none may be unassigned. Keep an evidence checklist per build with dates/configuration, unresolved findings, and pass/fail results. Required implementation choices remain explicit release gates rather than claims that they already work.

| Owner / gate | Evidence required before public V1 release |
| --- | --- |
| Product/design | Complete core Section 19 flows and all applicable enabled-feature criteria on the iPhone/iPad/window/accessibility matrix; usable real-device layouts, truthful optional-service status, performance traces and error/offline states. Retain Section 10.3 observed Lily task/change/retest evidence alongside the fit suite. Disabled optional finder/try-on/packs do not claim readiness or require their conditional gates for core launch. |
| Local data/recovery | Sections 11.7/25 interruption, migration, two-device conflicts, Trash/purge, original-first import, image/layout consistency, and fresh-install/cloud restore evidence, including 1,000 items/500 outfits and 50-photo batches on iPhone 12. |
| Billing | StoreKit purchase/trial/renewal/expiry/refund/revocation/restore/grace/pending/code and authorized sponsorship tests; if image packs ship, durable grant/debit/refund/non-expiry/after-subscription use/balance-recovery tests. No duplicate entitlements or units; correct localized terms/legal links, approved products and reviewer instructions. |
| Backend/cost | Chosen authentication/database/hosting design, durable cross-device admission and settlement, approved prices/budgets/caps, concurrency/idempotency/timeout/failure tests, alerts and exercised kill switch/rollback. |
| Privacy/security | Data inventory and chosen provider contracts/settings, accurate policy/labels/manifests, consent/withdrawal/recipient-change tests, token/authorization/replay/log audits, safe imports, local/iCloud/account deletion and backup restoration evidence. |
| Feedback/support | Named daily moderation coverage, tested filter/report/block/removal/appeal/account deletion, private/public separation, published support contact, queue response/pause procedures. |
| Website/help/communications | Named content/support owner; compact Section 22.3 site with working truthful links/demonstrations, offline essential help and initial versioned release notes. If optional emails are enabled, approved processor/notices, independent contact consent, reply coverage, withdrawal/queued-send and deletion evidence; otherwise clearly keep the program disabled. |
| Analytics | Opt-in/offline/withdrawal/deletion tests, client/server schema rejection tests, retention jobs, bounded ingestion, and useful aggregate dashboards without sensitive content. |
| Operator/legal | Adults-18+/United States launch configuration, proportionate age eligibility and truthful rating/EULA override evidence, applicable trader declaration/contact handling, payment/privacy/security assessment and published notices, rights/incident process, fresh Apple guideline review and working review-access services. Later countries pass Section 11.8's separate rollout gates. |

### 24.4 Current Apple review cross-check

Checked [Apple's live guidelines](https://developer.apple.com/app-store/review/guidelines/) October 3, 2026; the page's update date is June 8, 2026. This is specification coverage, not validated binary compliance or approval.

| Guideline sections reviewed | PRD coverage |
| --- | --- |
| 1.1, 1.2, 1.5, 1.6 | 15, 22, 24 |
| 2.1–2.3 | 19, 24.1 |
| 2.4.1–2.4.4 | 7.2, 16 |
| 2.5.1–2.5.6, 2.5.9, 2.5.14–2.5.15 | 11.7, 15, 16; criterion 49 |
| 3.1.1–3.1.3, 3.2.2(x) | 13, 14, 24.1 |
| 4.1–4.3, 4.7–4.8, 4.10 | 7, 8, 22; criterion 49 |
| 5.1–5.2, 5.6 | 9, 13, 15, 23, 24 |

Added release checks for IPv6, resource/background use, public APIs, container/Files access and system controls. Titles stay within 30 characters; metadata must match actual iPhone/iPad use. Ratings use Apple's native prompt without incentives/filtering. Classify shipped Ask Stylist under 4.7 before submission; V1 excludes remote executable code/plugin catalogs.

Separately, Apple's [current upload requirements](https://developer.apple.com/news/upcoming-requirements/) specify Xcode 26 or later with iOS/iPadOS 26 SDKs since April 28, 2026, and an iOS/iPadOS 13-or-later deployment target since September 9, 2026. The actual app minimum may be higher to support selected frameworks; SDK 26 does not itself require deployment only on OS 26. Complete current age-rating questions and any EULA-required higher override, and recheck upload requirements at submission. Preserve the iPhone 12 test commitment.

The one-month eligible subscription trial and complimentary IAP offer-code plan remain supported directions in Apple's [introductory-offer help](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions) and [IAP offer-code help](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-offer-codes-for-in-app-purchases). Production code generation requires Ready for Distribution app status and an Approved IAP; sandbox tests come first. Publish [accessibility declarations](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels) only after platform-specific end-to-end evidence. Recheck the live review rules before every release; requirements can change.

## 25. Review-Derived Reliability and Recovery Gates

Consolidated October 3, 2026. This section contains the complete supplied-review traceability, implementation invariants, dataset/evidence procedure, 22 RV checks and source qualifications. Core RV checks and acceptance criteria 36–49 remain mandatory alongside Section 24; enabled optional services add their relevant checks. All application checks are **Not run**.

The user supplied a detailed qualitative report and source links concerning Smart Closet, Acloset, Whering, Stylebook, and Indyx. This is not an exhaustive review collection, frequency estimate, or audit of current behavior. Reviews contain praise and criticism. Smart Closet examples include historical 2018–2023 reports; newer supplied Acloset/Whering/Indyx examples include 2025–2026. Issues may have been fixed, and Android complaints do not establish iOS bugs. S3 is indexed evidence whose directly retrieved review selection differed. No competitor bug reproduction or independent naming clearance is claimed. Sources are recorded below.

Useful outfit help before closet cataloging remains the advantage. Users must keep acknowledged work, original garment appearance, saved layouts and access to their data when a service/import fails. The proposed performance targets and recovery gates require implementation evidence; document review is not a passing release test.

### 25.1 Pain-point traceability

| User-reported pain point | Required V1 behavior | PRD coverage / checks |
| --- | --- | --- |
| Smart Closet [S1]: lost drafts, freezes, saved collage differs from preview, difficult editing/search | Durable local drafts; undo/redo; atomic Save/Copy; stale-result rejection; shared layout rendering; offline text search | FR-31/32/39; Sections 7.3/9.1; RV-01/02/03/05/17 |
| Historical Smart Closet/Stylebook [S1,S6,S7] recovery and transfer uncertainty | Local-save/sync/processing status and last acknowledged sync; portable backup; fresh-install recovery; migration and offline conflicts tested | FR-21/22/40; Sections 11.7/15; RV-07/08/13 |
| Acloset [S2,S3]: heavy cataloging, slow controls/crop mistakes/login loops, late item limits | Value with zero imports; editable/reversible processing; local access through auth refresh; terms upfront; no paid count cap | FR-10/33/36; Sections 7.3/8.1/9.1; RV-09/10/11 |
| Indyx [S8]: hanging uploads, repeated work, changed garment color | Durable source before optional processing; per-entry resume; bounded decoding; preview/revert; preserve garment details | FR-33; Section 9.1; RV-04/05/20 |
| Whering [S4,S5]: long loads, glitches/launch failure, laundry-awareness requests | Offline core; bounded loading; availability exclusion with explicit per-request override; user-controlled laundry; launch/failure gates | FR-32/34/35; Sections 7.3/8.1/16; RV-06/10/11/18 |
| Stylebook [S6,S7]: replacing a photo disrupts saved layouts/scaling | Stable item/piece IDs and normalized layout; explicit image versions; preview/revert across ≥100 saved looks | FR-20/33; Section 9.1/data model; RV-05 |

### 25.2 Coverage of all 23 supplied P0 requirements

Numbers match the supplied report. These map to implementation requirements, not completed features.

| Report # | Concrete coverage | PRD / checks |
| --- | --- | --- |
| 1 | Durable accepted edits before acknowledgement; relaunch recovery; actionable write errors | 7.3; RV-01/02 |
| 2 | Inspiration, wishlist, owned and user-confirmed purchase distinct; clicks/suggestions never infer ownership | FR-37; 12; RV-15 |
| 3 | Stable IDs/normalized layout/separate image revisions | 9.1; RV-05 |
| 4 | Archive versus 30-day Trash versus scoped permanent purge; bounded undo | 7.3–7.4; RV-14 |
| 5 | Local save, acknowledged sync and snapshot backup distinct; last successful sync visible | 15.1–15.2; RV-08 |
| 6 | Versioned original-inclusive archive, integrity validation, atomic import without AI | 15.2; RV-07/08 |
| 7 | Offline/manual core through auth refresh; queued sync; cloud failure isolated | 7.3; 11.7; RV-11/18 |
| 8 | No upload prerequisite; skippable/editable measurements | FR-01; 8.1; RV-09/15 |
| 9 | Minimal Already Own/optional photo; representative imagery clearly labeled | 9; RV-09/15 |
| 10 | Optional photos/screenshots/manual entries; original-first resumable idempotent jobs | 9.1; RV-04 |
| 11 | Best-effort user-shared link/details; screenshot/manual fallback with rights; no arbitrary URL fetch/scraping or catalog prerequisite for basic styling; permitted finder access has a separate prototype gate | 13; RV-21 |
| 12 | Optional derived processing/review/revert preserves color/pattern/silhouette/logos/details | 9.1; RV-05 |
| 13 | Editable inferred tags/provenance; ambiguous brand/size/fabric/exact fit stay unknown | FR-37; 9.1; 12; RV-15 |
| 14 | Three distinct choices; one-item swaps preserve other selections and constraints | FR-06/09; 8.1; RV-06/16 |
| 15 | Actual eligible IDs enforced; full-store preflight; separately chosen inspiration on insufficiency | 8.1; RV-06/09 |
| 16 | Dirty/Unavailable/Archived excluded by default; individually confirmed request override; Worn never auto-Dirty | 7.3; RV-06/16 |
| 17 | Petite is not weight or a mandate to look taller; optional inseam/rise/torso/sleeve/fit; no guarantee | 10; RV-15/16 |
| 18 | Recent local history and reversible too dressy/not my style/wrong weather/don't suggest again feedback | FR-39; 8.1; RV-16 |
| 19 | Trial/monthly terms and AI limits before substantial setup/purchase; no unlimited recurring-cost promise | 14; 24.1; RV-09/19 |
| 20 | Free core after expiry/quota; verified restore across reinstall/devices | 14.3; RV-02/11/19 |
| 21 | Owned alternatives first; shopping optional; no automatic checklist for every gap | 8.1; 13; RV-16/21 |
| 22 | Focused occasion/options/swap/save flow; Saved/search easy to reach; category/color/brand/notes search, optional tags | FR-39; 5/7; RV-17 |
| 23 | No outfit social feed/required sharing; cloud choices disclosed; no sensitive content in diagnostics | 15/17/22/23; RV-12/22 |

### 25.3 Implementation invariants

- **Acknowledgement means durable local commit.** Saving, saved locally, processing, queued for sync, and synced are distinct states. Editor changes save a draft; immediate Already Own/availability controls commit canonical state before acknowledgement so styling reads the change. Do not rely on an app-exit callback. Text drafts target autosave within one second; edits not yet committed must not be labeled Saved. A disk failure preserves the prior valid revision and communicates what remains unsaved.
- **Drafts and committed looks are separate.** Relaunch recovers drafts. Save updates the same outfit ID atomically; Save as Copy creates a new ID. Undo/redo covers routine edits with the PRD's disclosed bounded history. Delete My Data clears drafts/history; feedback drafts do not auto-publish.
- **Manual control is independent of AI.** Closet availability/editing, manual outfit creation/editing/saving/undo, backup, and local browsing stay free and usable offline, after subscription expiry, and when cloud allowances run out. An AI request is a separate explicit action.
- **Images never define identity or layout.** Wardrobe/item/piece IDs and saved transforms survive image-resolution/aspect changes. Retain the unprocessed source independently of the Photos library; derivatives are optional/reversible. Failed replacement leaves the previous usable image. Source-inclusive storage supersedes the old optimized-only estimate.
- **Imports resume without duplication.** Durable job/entry IDs connect copied sources to atomic item commits. Per-entry retry is idempotent; distinct garments can legitimately share identical photos. Archive restore stages resumably but commits the validated merge/replace as a whole.
- **Wardrobe-only is enforced, not just prompted.** Backend validates bounded eligible inventory; client rechecks canonical current owned records and revision. Available is the default; only individually confirmed Dirty/Unavailable/Archived override IDs become eligible for this request, without changing stored status. Unowned/Trash/deleted IDs remain forbidden. Full-store preflight is required before verified InsufficientWardrobe; shortlist/model failure is GenerationNotCompleted. Retry remains bounded; no automatic shopping switch or successful-action debit for failure.
- **Old saved looks are preserved.** Mark unavailable/missing pieces visibly; do not silently rearrange or substitute them. A late AI/processing/sync result cannot overwrite a newer editor revision.
- **Storage limits are honest.** There is no artificial paid closet/outfit count cap in V1. State real import/file/disk/recovery bounds before work. A 1,000-item/500-outfit fixture is a minimum test target, not a ceiling. Insufficient disk can safely prevent an export/import, but must never clear the existing closet or report success.
- **Archive retains; permanent deletion purges.** A separate 30-day Trash recovery window preserves IDs. Permanent purge removes garment metadata/images, embedded piece content, collages, drafts/history and pending job copies; shared assets and independently saved old archives have disclosed limits. Delete My Data bypasses recovery. Content-free markers prevent routine sync/merge resurrection.
- **Unknown means unknown.** Editable inferred tags never silently overwrite confirmed values; representative imagery is labeled. Inspiration/wishlist become inventory only after explicit ownership confirmation. Measurements can be skipped and edited; fit suggestions are guidance.
- **Migrations and conflicts have recovery paths.** Versioned old-schema fixtures, free-space checks, a protected recovery snapshot, atomic staged commit and restart tests precede stack confirmation. Preserve conflicting offline revisions for review; removal stays excluded until reviewed restore, and device clocks alone cannot choose the winner.
- **Loading and resource work are bounded.** App-owned network calls have cancellation/deadlines and useful status by ten seconds. System-managed StoreKit/CloudKit Pending states remain honest and do not block local work. Start with two photo-processing workers, downsample UI images, lower concurrency under pressure, and keep decode/archive work off the main thread.

### 25.4 Release dataset and evidence

Use **1,000 garments and 500 saved outfits** on Lily's physical iPhone 12, with source photos and active derivatives, repeated item references, saved layouts, drafts, availability states, and selected history. Include different dimensions/aspect ratios, text-only items, duplicate-looking distinct garments, unavailable items, and difficult/corrupt media. Also cover the PRD's iPad mini/11-/13-inch and resized-window/accessibility matrix.

At least 100 saved looks share an image in replacement testing; include transparent/white/black/patterned/logo garments and compare preview versus saved/exported layout. Import 50 typical phone photos while browsing/editing. Proposed normal-condition p95 targets: local interactive launch ≤2 seconds, text search ≤300 ms, durable save acknowledgement ≤500 ms. Measure at least 100 samples per operation; document cold/warm start, build/OS, free disk, cache and thermal state. Normal baseline has sufficient storage, nominal thermal state and no active migration/import; separately report stressed conditions. These are targets, not measured performance.

Record release build, OS/device, fixture ID/seed, data counts/revisions, interruption point, network/permission/storage condition, expected result, actual result, screenshots/traces where relevant, integrity/reference comparisons, issue ID, and pass/fail. Use fictional test data and redacted evidence; no real measurements/photos/tokens in operational logs.

All checks are **Not run** until supported by implementation evidence. A checklist tick or passing document review is not evidence of application behavior.

### 25.5 Release checks

| ID | Procedure | Required result | Status |
| --- | --- | --- | --- |
| RV-01 | Force-close/relaunch after an acknowledged item/profile/outfit edit and around draft-save/explicit-save boundaries; repeat with low disk | Acknowledged changes return; incomplete work is a recoverable draft or clearly unsaved. The committed outfit is wholly old or wholly new, never partial. No false Saved status | Not run |
| RV-02 | Edit the same saved look repeatedly; undo/redo; Save; relaunch; Save as Copy; Discard a further draft | Save preserves outfit ID and links. Copy alone creates a new ID. Undo/recovered draft/discard behave consistently and preserve the last valid committed version | Not run |
| RV-03 | Start slow AI/image/sync work, then manually edit or navigate; cancel and deliver the delayed result | Later edits/draft survive. Stale work is discarded or offered for explicit review; no silent overwrite or automatic re-generation. Cancellation does not falsely erase billed dispatch | Not run |
| RV-04 | Interrupt source acquisition/copy, item commit, processing, and a multi-entry import; deny access; retry failed entries; cancel the remainder | Complete source exists before optional processing. Completed entries remain usable; resume/retry creates no duplicates or dangling references. Corrupt/low-space input leaves prior photos intact | Not run |
| RV-05 | Replace/cut out/crop/reset different-aspect photos used in ≥100 saved looks; transparent/white/black/pattern/logo fixtures; compare preview/save/export; fail processing | IDs/frames/scale/rotation/order/crop/fit/references intact; original/accepted derivative and revert work; detail preserved or original fallback; saved composition matches preview | Not run |
| RV-06 | Mark Dirty/Unavailable/Archived; inject invalid/deleted/Trash/unowned IDs and attributes; change inventory in flight; alternatives outside shortlist; explicit single-ID override | Canonical current eligible owned records only; no failure quota debit/global insufficiency from shortlist alone. Only confirmed status override passes; stored status unchanged. Existing looks show warnings without substitution | Not run |
| RV-07 | Export complete fixture, restore on a fresh installation with no old Photos access, and compare source/derivative hashes, counts, stable IDs, relationships, layouts, drafts/history; repeat merge | Manifest/content reproduce correctly; no duplicate merge records. Processing is not required to recover original imagery. No hidden dependence on device-local asset IDs or the old library | Not run |
| RV-08 | Two devices edit offline/reconnect in both orders; same-value conflicts/archive/delete; completed cloud recovery; corrupt/interrupted archive; low disk | Recoverable competing revisions, no duplicates/silent overwrite/resurrection; last acknowledged sync/pending honest; invalid import leaves old closet intact | Not run |
| RV-09 | Fresh install with empty closet; inspect onboarding/paywall/import preflight; get Suggestions-mode outfits; add text-only Already Own items; choose wardrobe-only with insufficient inventory | No catalog/photo prerequisite. Prices/AI limits/storage/import bounds are visible upfront; no surprise paid item cap. Three lanes on success; typed actionable insufficient-inventory outcome otherwise | Not run |
| RV-10 | Profile repeated local launch/search/save on physical iPhone 12 fixture and representative iPads/windows, using documented normal/stressed conditions | p95 ≤2 s / ≤300 ms / ≤500 ms with ≥100 samples each; bounded thumbnail decoding; no freezes; resize preserves state and causes no AI calls | Not run |
| RV-11 | Offline/poor internet, AI/iCloud outage, quota/expiry, auth refresh/expiry, bad responses, 429/5xx, denied permission and low disk during edit/save/export | Local core/drafts intact through authentication/service failures; safe error/recovery; only impossible disk/network steps refused; no clearing/automatic charges | Not run |
| RV-12 | Audit release evidence and privacy deletion after retained draft/source/history/import/cache operations | No unresolved blocker below. Delete My Data clears covered local/synced/history data with accurate pending status and no resurrection. Logs/telemetry contain no sensitive test payloads | Not run |
| RV-13 | Upgrade supported old schema fixtures; interrupt migration boundaries; corrupt asset/low disk/relaunch | Prior complete store recoverable; IDs/hash/relationships verified; no partial destructive upgrade/reset; recovery snapshot follows retention | Not run |
| RV-14 | Archive/unarchive, Trash/restore, 30-day expiry/permanent purge; shared assets/collage/old archive/job/offline device | Stable recovery IDs; covered garment content purged from copies/history; scope limits disclosed; routine merge cannot undo deletion; Delete My Data immediate | Not run |
| RV-15 | Suggest/wishlist/link/click/manual add/Already Own/I bought this; ambiguous tags; skip/edit measurements; generic image | Explicit ownership transitions only; inferred/confirmed tags separate; honest unknowns/placeholders; optional profile; no fit/weight assumptions | Not run |
| RV-16 | One-item swap; repeated recommendations/local history; reversible feedback/exclusion; Worn; tiny inventory | Other selections/layouts retained; repetition reduced where possible; constraints prevail; feedback undo; no automatic Dirty/shopping checklist | Not run |
| RV-17 | Offline category/color/brand/notes search with incomplete tags; Home/Saved/editor navigation; accessibility end-to-end | Correct local matches, easy reachable controls, optional tags, no search-content telemetry; Dynamic Type/VoiceOver/touch/contrast/keyboard pass | Not run |
| RV-18 | Delay/cancel each app-owned service; system pending purchase/sync; restart | Status by ten seconds, deadline/attempt bounds, preserved input/manual alternatives; no indefinite blocking spinner/blind purchase restart | Not run |
| RV-19 | Trial/purchase/cancel/expiry/refund/grace/pending/restore/complimentary code/quota across devices/reinstall | Accurate terms/eligibility, verified restored entitlement, no duplicate charge, core access preserved | Not run |
| RV-20 | 50-photo import plus browsing/editing, failed-entry retry, memory/thermal/background stress, IPv6-only services, Files/iCloud selection | Bounded resource use/concurrency; originals/completed entries safe; no freeze/memory exhaustion; network/permission/container recovery correct | Not run |
| RV-21 | Missing/blocked retailer metadata/expired link/stock; screenshot/manual fallback | No catalog/scraping prerequisite; unverified values labeled, rights respected; no inferred purchase | Not run |
| RV-22 | Inject allowed/forbidden diagnostics; simulate session/crash aggregation and data-loss incident | Consent/allowlist/retention enforced; window/count/coverage honest; private bug report needs no wardrobe upload; P0 recovery owner/process exercised | Not run |

### 25.6 Release blockers

Do not ship with unresolved lost acknowledged work, destructive migration/sync conflicts, incomplete purge, corrupt/duplicate imports, missing original-inclusive restore, altered saved layouts/details, invalid inventory constraints, surprise caps, or manual/export access gated by AI.

If a check fails, preserve the reproduction and data, fix the cause, and rerun the affected boundary plus related recovery checks. Provide a recoverable error/pending state; do not replace failure with clearing data or a success message. Zero bugs cannot be promised, and no implementation has been validated yet.

Any confirmed acknowledged-data loss takes priority over new features: pause the affected rollout/operation, contain, support recovery and rerun related gates. Proposed post-launch target is ≥99.9% crash-free sessions over rolling 30 days with at least 10,000 measurable sessions; PRD 23.2 defines session/consent/denominator limits. Below that threshold report insufficient evidence. This is not a prelaunch sample requirement or proof of data safety. Monitor p95 local timing, interrupted imports, save/sync/restore failures and recommendation feedback without wardrobe content. Wear analytics, packing and cosmetic customization come later.

### 25.7 Supplied sources

The supplied report states these were accessed October 3, 2026. That is its access date, not a claim that this update fetched all reviews. User reports were not reproduced.

- **S1:** [Smart Closet Apple reviews](https://apps.apple.com/us/app/smart-closet-your-stylist/id1198057728?see-all=reviews).
- **S2:** [Acloset Google Play reviews](https://play.google.com/store/apps/details?hl=en-US&id=com.looko.acloset).
- **S3:** Same listing; search-indexed August 10, 2026 complaint about discovering a 100-item limit after setup. Direct retrieved review selection differed; treat as indexed evidence, not a complete current feed.
- **S4:** [Whering Google Play reviews](https://play.google.com/store/apps/details?hl=en_US&id=com.whering.app).
- **S5:** [Whering Apple reviews](https://apps.apple.com/pl/app/whering-your-digital-wardrobe/id1519461680?platform=ipad&see-all=reviews); supplied June 16, 2025 launch-crash report.
- **S6:** [Stylebook Apple reviews, Australia](https://apps.apple.com/au/app/stylebook/id335709058?platform=iphone&see-all=reviews).
- **S7:** [Stylebook Apple reviews, Finland](https://apps.apple.com/fi/app/stylebook/id335709058?see-all=reviews).
- **S8:** [Indyx Google Play reviews](https://play.google.com/store/apps/details?id=com.indyx.android); supplied July 15, 2026 example.
- Naming comparison: [Smart Wardrobe: Style & Try-On](https://play.google.com/store/apps/details?id=com.healthyandelegant.smartwardrobe).
- Supplied direct name search: [Apple U.S. software query](https://itunes.apple.com/search?term=Smart%20Petite%20Wardrobe&entity=software&country=us&limit=200).
- Supplied domain check: [Verisign RDAP query](https://rdap.verisign.com/com/v1/domain/smartpetitewardrobe.com).

The live Apple review cross-check and submission requirements are recorded in Section 24.4. Naming clearance, legal release assessment and actual application tests still require evidence.

### 25.8 Current product definition

A Lily-first, petite-focused iPhone/iPad stylist built around her 4'11" experience and confirmed fit/style preferences, with flexible per-profile rules for later expansion. Occasion/weather/optional starting item produce three visual outfit directions; owned-piece swaps, saved looks, reversible feedback and gradual Already Own learning are central. Local closet/manual editing, original-inclusive recovery and export remain accessible without AI access. Monthly or complimentary access funds styling; Lily's authorized sponsored policy replaces public service quotas. Missing-piece search and Generate Look are optional only after their own evidence gates; conditional image packs follow Section 14.4. Broader audience coverage is future validation work within the same app. No app implementation, tested physical fit, provider selection or App Store approval is claimed.

## 26. Project Status and Next Steps

### 26.1 Authority, consolidated coverage and historical material

Maintain current decisions in this master file only. Consolidated coverage is **47 functional requirements, 66 acceptance criteria, 22 RV checks and eight conditional TO checks**. The other three Markdown files retain their existing paths as pointers to this document, avoiding independently maintained copies of requirements. The original [Word draft](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.docx) is preserved unchanged as historical source material. Its one-time paid download/no-subscription plan, browser-only shopping, always-on PetiteRulesEngine and categorical try-on exclusion are superseded by this master.

The workspace contains no implemented application. No application/model/fit/recovery/billing test, personal-photo upload, generated example, provider purchase/contact, commit, deployment, production billing setup or App Store submission has been performed by this documentation pass. Markdown consistency checks verify document structure only. All release evidence still needs actual implementation.

### 26.2 Working name and screening limits

The supplied report calls the project MyPetiteCloset and proposes Smart Petite Wardrobe; neither is a confirmed rename. The main PRD retains My Petite Style as a working title. The report says exact/concatenated searches found no exact use, Apple's U.S. search returned 181 apps without an exact title, and Verisign RDAP returned HTTP 404 for smartpetitewardrobe.com. These are supplied screening results, not independently rechecked here. Registrar availability and trademark clearance remain unconfirmed. Smart Wardrobe: Style & Try-On and multiple Smart Wardrobe titles make similar-name screening necessary.

The source links and supplied access-date qualifications are retained in Section 25.7. Keep My Petite Style as the working title until an explicit naming decision and appropriate similar-name/trademark screening; no rename or domain purchase is implied.

### 26.3 Open implementation decisions

| Decision | Required next evidence |
| --- | --- |
| Persistence and optional private sync | Confirm SwiftData/CloudKit through migrations, original-file linking, offline conflicts and fresh-install restore; choose an alternative behind the same services if needed. |
| Text provider/model and backend | Select real supported API model/configuration, contracts/consent, hosting, stable principal authentication and transactional ledger; measure quality, latency and complete cost. No production model is selected. |
| Public pricing and image economics | Finalize localized subscription price, trial service scope and actual public/sponsored budgets; US$9.99 is a candidate. If enabling try-on/packs, establish accepted-look cost, quantities/mode mapping and verified wallet recovery before sale. |
| Optional missing-piece finder | Prove permitted source/fit access, minimum fields, product/variant/length/delivery evidence, rights and bounded per-search cost under Section 13. |
| Optional Generate Look | Approve processor privacy/media settings first, then pass Section 9.2.5 quality/recovery/cost tests. One garment versus two-piece/full outfit coverage must be evidenced. |
| Platform, operator and release implementation | Adults 18+ and United States initial distribution are confirmed. Choose supported OS floor while retaining Lily's iPhone 12, final name, responsible operator, proportionate age eligibility/rating implementation and review/support owners; recheck live Apple requirements. Future countries require Section 11.8 evidence, not a new app by default. |
| Lily's remaining fit details | Initial inseam preference of 25 or 26 inches is supplied and editable. Confirm measurement basis/garment reference, preferred cuts/rise/hem-shoe relationship and any useful sleeve/waist/bust values or firm comfort requirements through skippable contextual questions. No sleeve/waist/bust numbers or fabric exclusion have been supplied; keep unknowns explicit. |
| Broader audience support | Validate Lily and a small similar-needs group first. Later sizes/lengths/men's clothing require their own fit/content/catalog/try-on evidence and Lily regression checks; no separate app is currently planned. |
| Website/help and optional emails | Choose a modest website host/content workflow and named owner; publish the truthful initial site/help/release notes. If enabling early-user emails, approve the separate communication consent, processor, retention and monitored reply/unsubscribe/deletion paths. No vendor, contact list or campaign has been created. |

### 26.4 Pick up implementation here

1. Build adaptive core screens and the storage/recovery prototype first. Include flexible measurement/sizing contexts and conditional FitRulesEngine, safe migration/conflict/Trash behavior and original-file recovery.
2. Assemble consented Lily scenarios and start Section 10.3's observed sessions and task/change/retest log. Validate her daily wardrobe, swapping, occasion planning and saved-look flow; measure time to a look she would wear and resolve friction. Preserve acknowledged work and simpler interaction before broader expansion.
3. Select a real text provider/model and backend authentication/ledger/hosting; implement StoreKit trial/restoration/complimentary/sponsored access and privacy controls. Measure actual use and complete service costs rather than only token/image sticker prices.
4. Evaluate optional try-on only after processor/privacy controls, and optional permissioned missing-piece search after its source/fit gate. Enable neither from a prototype demo alone. Verify image wallet recovery before selling conditional packs.
5. Run core and all applicable enabled-feature evidence checks on physical iPhone/iPad devices. Record unresolved findings and actual build evidence; recheck current Apple rules immediately before submission.
6. Before public launch, publish the compact Section 22.3 product/support website, essential contextual help and versioned release notes. Grow guides/tools/comparisons from repeated needs; add the independently optional early-user welcome/check-in program only after its communication controls are ready.
