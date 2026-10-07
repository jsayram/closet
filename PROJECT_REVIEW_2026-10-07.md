# Project review — 7 October 2026

The project has a substantial working native prototype, a newer illustrated room-design prototype, and a detailed specification for a production app. The immediate design backlog is only one part of the work remaining. Production integrations, data recovery, real recommendation quality and release evidence are still outstanding.

## Review scope and evidence

This was a repository-wide inventory and status review, with source inspection of architecture, storage, service wiring, navigation, photo handling, search, results, saved content, purchases and tests. It covered the root specification/history, prototype documentation, HTML/CSS/JavaScript, native source/configuration/tools, local research and artifact inventories. It is not a line-by-line defect audit of the roughly 50,000 lines of Swift or an exhaustive visual review of every archived image and video frame.

Before this report was added, the workspace contained 902 files excluding Git internals and `.DS_Store`: 693 tracked files, 208 local research files and local agent configuration. There were 127 Swift files, 41 HTML files, 77 SVGs, 43 Markdown/text documents, 546 PNG/JPEG images and five MP4 files. A file-by-file inventory is in [PROJECT_FILE_INVENTORY_2026-10-07.tsv](PROJECT_FILE_INVENTORY_2026-10-07.tsv).

Fresh checks in this review: JSON, Python and project XML parsing; all 77 room-art SVGs parsed; the historical Word document's text was readable; active room HTML local file references resolved; current native theme contrast pairings passed; the older proposed color palette's contrast check passed. I inspected the saved Home, sticker-results and Saved Looks images. Runtime-generated HyperFrames preview paths depend on the preview server and were not treated as broken project assets.

Native build/UI-test results and video-render results below are existing recorded evidence. No native build, simulator test suite, new screenshot tour, production API call or video render was run in this review. External research claims and commercial terms were not revalidated on the web.

## What each part of the workspace represents

| Files / area | What has been done | How to use it now |
|---|---|---|
| `My_Petite_Style_PRD_v2.md` | Consolidated specification: 72 functional requirements, 102 acceptance criteria, 29 RV checks and eight conditional try-on checks. Includes scoped Suitcases, history/reuse, personal names, genuine web discovery, fit-first ranking and release safeguards. | Baseline product specification, with later owner decisions kept separately. Its implementation-status prose predates the prototype. |
| `My_Petite_Style_PRD_v0.1.md` and `.docx` | Earlier specification and original Word draft preserved. | Historical evidence; do not treat old requirements as a second current backlog. |
| `Lilys_Wardrobe_App_Feedback.txt` | Original interview evidence and examples. | Preserve Lily's intent and use the real scenarios for usability/quality evaluation. |
| `Lilys_Feedback_PRD_Assessment.md` | Read-only assessment of the earlier specification, feasibility, costs, missing requirements and proposed validation. | Explains the evolution into v2; many listed decisions were subsequently resolved. |
| Root README, handoff and two research pointers | Navigation into the master, its revisions and research. | Update status references: the “planning documents only” description is now stale. |
| Claude mockup capabilities and prompt | Original native-prototype brief and environment research. | Historical delivery contract; much of the requested prototype was built. |
| `prototypes/LilyStyleMockup` | Runnable iPhone/iPad SwiftUI application, local store, mocks, feature screens, tests, capture tools and documentation. | Reusable implementation foundation and interactive product demo. |
| `prototypes/RoomDirectionMockups` | Illustrated room screens, garment/furniture art, soft variants, gallery, snapshots, rendering tools and preserved explorations. | Current design reference, with pending owner decisions recorded in `NEXT_SESSION.md`. |
| Native design/contrast/calm-screen documents | Existing theme/components, accessibility/motion rules, less-text pass and iPad layout conventions. | Reuse working components, reconciling them with newer room/soft decisions. |
| `Docs/ColorLanguage.md` and proposed contrast table | Separate pastel role-color proposal, explicitly not applied to the native app. | Historical proposal; its outlined controls and blue selected states conflict with newer approved no-outline/plum-selected rules. |
| `Docs/PRD-amendment-body-size.md` | Separate amendment proposal; corresponding body-fit prototype code already exists. | Formalize its status and validate the illustrative mapping before production use. |
| `Simplified_Direction_On_Hold.md` | Recorded proposal for Supabase, cloud-boundary Apple login, one subscription, bounded sponsorship and deferred packs/shopping/public feedback. | Explicitly on hold. Do not treat it as adopted architecture or authorized implementation. |
| `research/reports` and `research/research_notes` | Wardrobe/AI-stylist pattern research and general onboarding/trust/identity research. | Supporting reference material, not evidence that those integrations exist. |
| `research/visual-direction` | Interview notes, competitor captures, several generated visual concepts and saved prompts. | Design history. Later room decisions supersede older avatar/mirror concepts. |
| `research/visual-direction/recording-restyle` | Palette-restyling scripts/C++ processor, local video composition, full walkthrough, short preview and verification artifacts. | Completed visual exploration. The recolored video does not implement the interface in SwiftUI. |

## What is implemented in the native prototype

| Area | Existing implementation | Remaining distinction |
|---|---|---|
| App shell | Compact tabs, wide sidebar, navigation stacks, root sheets, launch routes, keyboard commands, persistent feature UI state, scroll memory and iPad layout helpers. | First tab is still Style Me; room Home has not been implemented. Actual system multitasking/accessibility hardware checks remain. |
| Wardrobe | Canonical garment records, ownership/arrival/availability distinctions, names/aliases/details, filtering, item detail, archive, no-longer-owned, Trash and permanent deletion. | Production migrations/recovery and larger datasets remain. |
| Photo intake | Photos/camera/paste/drop/text entry, input validation, local original-byte storage, replacement review and separate processed copies. | Cleanup is a simulated presentation workflow, not garment segmentation. Resumable/batch production imports and whole-outfit photo intake are not established. |
| Suitcases | Create/rename/archive/delete, shared canonical memberships, add/remove with undo, remembered source, empty cases and scope eligibility. | New illustrated favorites/See all design and production cross-device recovery remain. |
| Styling | Occasion/Other, source, starting garment/name resolution, weather overrides, comfort, color constraints, mode, explicit new-piece option, blockers and mock result generation. | Real stylist/prompt evaluation, WeatherKit and production metering remain. |
| Results/history | Flat-lay drawings, partial/insufficient/failure outcomes, saved history, current-context checks, free local reuse and exact retained-picture reuse. | Sticker-photo canvas, Shuffle, current/Earlier tabs and per-look try-on entry remain. |
| Manual editing | One-piece swaps, eligible alternatives, request-specific exceptions, undo/redo, save/copy and one durable draft with replacement confirmation. | Multiple retained drafts are explicitly outside the prototype. |
| Search | Local metadata search across garments, outfits and previews; synonyms, spelling/prefix/phrase handling, facets, possible matches and confirmed aliases. | Production index recovery, deletion integrity, scale and performance evidence remain. |
| Saved content | All Looks, Preview History, Favorites, private collections, related-look navigation, current-status labels, intended dates and preview dislike/favorite controls. A toolbar already opens Saved search. | Inline search under the new Looks/Pictures tabs is a presentation change; search itself is already implemented. Decide where Favorites/collections remain in the new structure. |
| Laundry | Individual/selected/scoped-all cleaning, review, revision checks and undo. | Opt-in toggle is absent; current eligibility excludes dirty garments. Hamper and off/on design/behavior remain. |
| Profile/fit | Optional measurements, unit/basis/confirmation, fit references, preferences, retailer priorities, separate processing permissions, usual comfort and structured optional weight. | Fit cue thresholds and height/weight size-band mapping are illustrative and unvalidated. |
| Stylist chat | Secondary conversation, suggested questions, explicit Send, attached looks, source/permission/access guards and local editor/save actions. | Answers are mock-generated; conversation is in memory only. |
| Shopping | Fictional search/ranking, public-intent review, supported/unknown/conflict groups, evidence, saved products, store-handoff demo, explicit purchase/arrival and reminder records. | No real search, retailer integration, live fit evidence or scheduled notifications. Room placement is unresolved. |
| External stylist export | Local numbered contact sheets, editable prompt and explicit copy/save/share actions with optional personal context. | Closet multi-select → collage/share entry path is deferred. This is separate from backup export/import, which is simulated. |
| Settings/support | Source defaults, consent screens, sync/conflict/backup/deletion review states, offline help, release notes, legal placeholders, feedback demo and developer scenarios. | Real sync, backup archive import/export, developer-held deletion, public moderation and legal pages remain. |
| Billing/try-on | Access-state model, allowances, sponsorship, simulated paywall/packs/out-of-pictures behind a demo toggle; cancellable mock image jobs and retained preview records. | No StoreKit transactions or image generation. Backend-authoritative balances/reservations/recovery are absent. |

The store really writes JSON atomically in Application Support and stores imported photos locally. It is not merely temporary UI state. However, loading rejects unreadable or non-current-schema snapshots, and `loadOrFixtures()` falls back to fixtures and persists them. A production app needs migration and recoverable load errors rather than this demo-reset behavior.

The native `OutfitFlatLayView` renders `GarmentArtwork` from captured kind/color. It does not currently compose imported garment-photo cutouts. The approved sticker treatment therefore needs photo/cutout rendering and retained image/version references, in addition to visual restyling.

## Room design: completed and pending

Completed references include Home, large-text Home, Closet, garment detail, Suitcases, Laundry, results, swap, Saved Looks, look detail, Profile, access, paywall, onboarding, chat and iPad Home/Closet. There are 23 user-facing HTML screen variants, five art-check pages, 30 active snapshots and 77 SVG assets. Older avatar attempts and renders are deliberately archived, not unfinished features to revive.

Approved direction already recorded: soft surfaces without box outlines, plum selected pills, garment sticker bundles, Home first tab, name sign instead of a portrait/avatar, decorative Maya, results-only Ask Stylist/Try it on, separate Looks/Pictures, large-text banner/rows and a real iPad arrangement. This direction has not been ported into the native app.

Still pending in HTML:

1. Home wardrobe → Closet; suitcase → source/Suitcases; remove starting rack/plate; add laundry hamper; replace More options drawer with Help/Feedback/Privacy drawers; laptop opens the Style Me request screen.
2. Cloudy/snow window art and weather/night selection; rain/sun/night SVGs already exist.
3. Style Me request summary plus Comfort/Color/Mode and their small option sheets.
4. Results Shuffle, current/Earlier tabs, equal 2×2 actions and allowance hint. Current actions are already roughly two rows, but unequal widths/heights remain.
5. Inline Saved Looks search on both tabs, matched-results and no-results states.
6. Laundry off explanation, Settings toggle, dirty/all-clean/off hamper states.
7. Drawer destinations; more-than-three suitcase favorites/See all.
8. Soft treatment on the older screens; `saved-flatlay.html` has sticker bundles and tabs but still contains older outlined styling.
9. Phone landscape, iPad portrait and then remaining device/width/state coverage.
10. Missing core references: garment add/edit, starting-piece picker, occasion/Other, loading, manual outfit editor, suitcase detail, empty/partial/error/offline states. Then shopping, fit/settings/help and picture-specific screens as retained launch scope requires.

Shopping placement and saved-products location are proposals. The “pictures left” hint is also marked for confirmation. Fixed-size HTML does not prove adaptive native behavior.

## Recorded verification and remaining evidence

Existing evidence records clean native builds, seven named flow tests passing on both phone and iPad, a 225-capture native screenshot pass across nine configurations, and 46 confirmed code-review findings fixed/rechecked. “14 flow tests passed” in `NEXT_SESSION.md` means seven tests on each of two devices; the source contains seven test methods.

The screenshots were intentionally removed while the interface changed. Their absence is not a failed deliverable; the capture tool and tour remain. Later fit inputs, calm-screen changes, purchases and iPad changes have different verification coverage. The final iPad note records seven tests passing on iPhone 14 and iPad Pro 11, while earlier text still says body-fit changes need a rerun. Consolidate evidence by commit/build before calling all current behavior verified.

Outstanding checks include newer-screen visual coverage, dark/large-text/landscape purchase states, narrow iPad/system multitasking, VoiceOver/Switch Control/hardware keyboard sessions, physical iPhone 12 performance, save/load/import/recovery fault tests and real two-device behavior. The seven flow tests do not prove every screen, body-fit mapping, billing, privacy deletion, cost accounting or provider quality.

All 29 production RV and applicable eight TO gates remain unproven. Required production datasets include 1,000 garments/500 outfits, plus 1,500 retained previews when images are enabled and 50-photo import batches. These are validation targets, not implemented scale evidence or product caps.

No completed observed Lily task/change/retest log was found. Design interviews and screenshot review do not substitute for watching her complete the core tasks and measuring time to a look she would wear.

## Production work still required

- Durable local persistence/migrations; original and derivative lifecycle; interrupted imports; recoverable drafts; private iCloud sync/conflicts; fresh-install restore; real backup archives; complete deletion/search/history fences.
- Selected text/image/search/weather adapters behind existing contracts. Enforced schemas and inventory constraints, measured Lily usefulness, photo fidelity and latency. Replace simulated cleanup with real cutouts where supported, with honest fallback.
- Backend authentication/principals, verified access, transactional usage reservations/settlement, durable jobs, bounded retries, idempotency, cross-device reconciliation, sponsorship limits, administrative audit and spending kill switches.
- Real StoreKit products, trials, renewal/expiry/refund/revocation/restore/code flows, localized terms and conditional pack-wallet recovery if packs ship.
- Recipient-specific privacy/consent, actual processor settings, storage access controls, account/developer-data deletion, output reporting and legal documents.
- Real shopping source validation and conservative fit ranking, browser-return/purchase/arrival recovery and optional local notifications if Find One stays in launch scope.
- Production support/feedback moderation if public feedback remains; truthful website/help/release notes; optional analytics with its consent/retention controls.
- Final branding/name screening, distribution/signing/App Store configuration and submission evidence. A working prototype app icon already exists (`AppIcon.png`, plum background with a hanger and MPS initials); final release branding remains an owner decision.

One subscription, Supabase and Sign in with Apple are not settled implementation facts. Shopping and the public feedback board remain in the baseline specification and prototype until the on-hold simplification is explicitly adopted. Optional ChatGPT-plan connection remains research only. Android, social wardrobe feeds, autonomous checkout, guaranteed sizing and advanced semantic/pixel search are not current work to implement by default.

## Mismatches to resolve before implementation expands

1. Root README/handoff/master status says no implemented app; the native prototype now exists. Update status pointers while preserving historical specification text.
2. Native paywall terms use one month free; room paywall/art direction uses seven days. Do not interpret either sample price as a finalized commercial decision.
3. Older ColorLanguage proposal requires outlines/blue selections; approved soft room direction removes outlines and uses plum selections.
4. Native All Looks/Preview History/Favorites/Collections must be preserved or deliberately relocated when introducing Looks/Pictures.
5. Shuffle says three looks always, but also says show fewer when too little history matches. Preserve honest partial results and source/occasion/eligibility constraints; resolve the wording before implementation.
6. Laundry opt-in changes eligibility and fixtures as well as navigation. Turning it off must preserve dirty marks while making those pieces available under the new policy.
7. Per-look try-on changes admission, labels, result behavior, billing hints and tests; it is not just removing a toggle.
8. Body-size prototype goes beyond the master. Its separate amendment exists, but its illustrative mapping has not been validated for production.
9. Entire `research/` is Git-ignored. Native documentation links into it, so a fresh clone loses supporting notes and videos. Choose what to version or preserve elsewhere; do not assume a clean Git status means those assets are backed up.
10. Old avatar/video concepts are superseded visual history. Do not reintroduce their behavior from archived files.

## Recommended sequence and what Codex can help with

First finish the HTML core journey and state/device coverage, refresh the gallery/snapshots and present the concrete mockups. `NEXT_SESSION.md` explicitly places native changes and the room amendment after owner review of those mockups.

After review, write the separate amendment covering all behavioral changes actually retained, then port the approved Home/Style Me/results/Saved/Laundry experience into the existing app. Reuse the existing store, search, editor, history and mocks rather than rebuild them. Add photo cutout rendering and update meaningful flow/eligibility tests. Verify the current build on the phone/iPad/accessibility matrix and start observed Lily sessions.

In parallel with planning, reconcile documentation/evidence and settle launch scope. Once providers/backend/commercial terms are chosen, prioritize durable storage/recovery and bounded live AI/billing infrastructure, then prove quality/privacy/cost before enabling production services. Finish launch artifacts after the actual behavior is stable.

Codex can implement the mockups, native flows, photo rendering, persistence/recovery, provider adapters and backend contracts; build targeted regression checks; maintain the requirement/evidence ledger; and prepare reviewable product/support artifacts. Provider contracts, production credentials, real purchases, personal-photo evaluation and release decisions depend on owner configuration and consent. None was performed as part of this review.
