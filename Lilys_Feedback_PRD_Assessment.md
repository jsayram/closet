# Lily’s feedback: product, feasibility and PRD assessment

Assessment date: October 3, 2026. This is a review artifact, not a replacement specification or approval to implement changes. The authoritative master PRD and Lily’s original feedback remain unchanged. Three parallel specialist reviews covered product/fit/UX, image feasibility, and security/Apple/billing, with synthesis and cross-checking by the primary reviewer.

Inputs: [Lily’s complete interview feedback](/Users/jramirez/Git/closet/Lilys_Wardrobe_App_Feedback.txt) and [the authoritative master PRD](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md). Direct answers have greater evidentiary weight than the interviewer’s interpretations, proposed features or unanswered questions. No app, provider quality, physical fit or release readiness was tested. No paid requests, personal-photo uploads or account setup occurred.

## 1. What Lily liked

Lily validates the central purpose: help her make intentional outfits from the clothes she owns, with little setup and easy editing. Her three stated essentials are **today’s context, intentional color variety, and changing one piece without losing the outfit**.

| What she liked or wanted | Evidence in her answers | Implication |
| --- | --- | --- |
| Closet-first help under time pressure | For her work interview, she wanted combinations built around her blue dress pants without needing to shop. | The app must be useful with actual available clothing immediately. |
| Three visual alternatives | She described a safe combination, a more interesting combination, and another useful direction. | Preserve useful choice; refine what each choice means. |
| Safe plus intentional color discovery | Blue/light pink and olive/brick interest her. Denim, black and similar color families are habits she wants help moving beyond. | Past safe choices must not trap personalization into recommending only safe colors. |
| Direct editing | She repeatedly wants to tap a cardigan/top and change the item or color while keeping the rest. | This is a primary action, ahead of a rating questionnaire. |
| Low-effort closet entry | Photograph commonly worn pieces, enter “white tank top” without a photo, and add gradually. | No full cataloging prerequisite. |
| Favorites and contextual organization | Work, Gym and Going Out collections let her reuse successful looks. | Saved outfit retrieval is part of the daily value, not an afterthought. |
| A reusable personal reference photo | She would supply a clothed full-body photo and wants replacement/deletion control. | The existing optional photo foundation matches her willingness; actual processor permission is still needed. |
| Shopping when useful and requested | She wants help finding a missing piece when she has time to buy or await delivery. | Shopping supports the wardrobe goal rather than becoming the app’s main activity. |
| Evidence a purchase will be useful | Multiple ways to wear it, petite fit, and affordable versus investment options. | Explain why a piece earns a place in her existing closet. |
| A straightforward opening flow | “Style me,” the relevant questions, and possibly an affirmation. | Keep the affirmation light and local; it is a “maybe,” not one of her three essentials. |
| A more coherent personal style | Chic, elegant, classy, less trend driven; feminine or sporty as appropriate. | Personalize to her own goals rather than impose a universal age or body rule. |

## 2. What she disliked, rejected or corrected

- **The fixed “Creative/Risky” lane.** She does not identify with that label. She still wants unexpected, coordinated colors; eliminating the label must not eliminate the discovery she values.
- **Repetitive safe palettes.** Reusing the same two or three colors with slightly different garments is insufficient value.
- **A flat outfit board as her preferred first result.** Her direct clarification is that the initial picture should be of her. A collage alone would not fully validate this preference.
- **Pictures contradicting supplied facts.** A known blue garment becoming green is a trust failure. Approximate details are tolerable; obvious contradictions are not.
- **Detailed wear-date tracking.** She finds remembering the exact day unnecessary and prefers organizing looks by context.
- **The presumed inseam.** She has not measured it and does not know what an inseam is. The master’s 25/26-inch preference is not Lily-confirmed.
- **Real clothing fit problems.** Pants are often too long; waist, seat and thighs do not always fit together; some jackets are too long and overwhelm her frame. She prefers rise around her navel, with modest variation, rather than low or extremely high rise.

She did not reject backup, privacy, offline access, purchase controls, availability controls or accessibility. Nor did she approve every technical detail merely because she did not mention it.

## 3. Did this simplify or complicate the app?

**It simplifies the everyday interaction and substantially complicates the image system.** Most requests are clarification or modest application work. The major increase is making three personal try-on pictures central to the first result, especially with separate garments, text-only inventory and subsequent swaps.

Effort labels below are relative engineering judgments, not calendar estimates or measured quality guarantees.

| Effect | Examples | Assessment |
| --- | --- | --- |
| Simpler everyday UI | Meaningful lane names, direct swaps, saved collections, less wear logging, gradual setup | Good simplifications; they reduce steps and irrelevant decisions. |
| Small additions to existing flows | Today-only comfort, required/preferred color, color-filtered owned alternatives, explicit Save for Later | Conventional UI, schema and validation work; no new AI platform needed. |
| Moderate data/UX work | Collection membership and recovery, more specific fit feedback, reviewed outfit-photo intake, closet compatibility examples | Fits the existing local-first architecture. Still needs sensible editing, deletion and sync rules. |
| High uncertainty and additional operational work | Three initial on-body looks, faithful layered outfits, image updates after swaps, generic-garment previews | Requires an early quality/speed/cost study, robust jobs and stronger failure handling. Dedicated APIs do not prove the complete workflow. |
| Larger optional expansion | Automatic identification, extraction and deduplication of every garment from a worn-outfit photo | Do not assume this is required. A manual-first reviewed version may meet her need. |

There is no defensible “20% more work” or completion-date estimate yet. The app is still a specification, and the most consequential capability has not been tested.

## 4. Gaps against the master

“Covered” means written in the master, not implemented. “Partial” means the foundation exists but the explicit behavior needs definition. Priorities below are proposed review priorities, not newly accepted requirements.

| Need | Existing master coverage | Classification and recommended resolution |
| --- | --- | --- |
| Correct inseam provenance | FR-01; §§3.1, 10, 10.1, 10.3; AC64; §26.3 | **Correction.** All eight assertions of her supplied 25/26 preference need correction. Keep inseam unknown; retain earlier owner-supplied numbers only as explicitly unverified provenance if useful, excluded from sizing rules. Height does not fill the gap. |
| Change lane meanings | FR-06/07; §§1, 3, 4, 5, 7; response contract; AC4/5 | **Conflict.** Replace the fixed Risky direction for Lily. Proposed closet-only result: Safe plus two different Elevated owned looks. When she explicitly allows a purchase idea, one option may include a clearly unowned piece. Shopping-off and limited-inventory behavior remain decisions. |
| Initial on-body pictures | FR-08/20; principle §2.2; §§9, 9.2; delivery phases and TO gates | **Major scope conflict.** Current core uses boards and one explicit optional image request. Consider an opted-in On Me mode, with privacy-preserving boards retained. Define image readiness, missing photos, partial failures, allowance and refresh behavior before promising it. |
| Today’s comfort | FR-05; optional fit preferences; StyleRequest | **Partial.** Add a temporary clothing-fit control separate from profile measurements and usual fit. Reset deliberately for a new request; no symptom/cycle history is needed. |
| Required versus preferred event color | FR-05/07; request notes and constraint validation | **Partial.** Distinguish a required blue element from a preferred palette. State which piece/portion must satisfy it. A required blue element must not automatically force every garment blue; explicit monochrome requests remain supported. Never fabricate an owned item to satisfy it. |
| Color-directed one-piece swap | FR-09/35; §§7.3, 8.1; AC6/44 | **Core covered; UX detail missing.** Filter eligible actual items by color and select their stable IDs. In owned-only mode, do not repaint an existing garment and claim ownership of its new color. |
| Preview after a swap | Existing outfit/item/image revisions, stale-result protection and GeneratedLook | **New consequence of primary imagery.** Label the old image as the previous outfit until refreshed; never attach it as a current depiction of changed selections. Offer real garment chips/thumbnails for deterministic editing. |
| Meaningful styling variety | FR-07/39; §§8.1, 10; AC64; RV-16 | **Covered intent; needs Lily-specific evaluation.** Add her actual aesthetic and blue/pink, olive/brick examples. Do not infer that frequently wearing black means she wants all future suggestions neutral. Honor valid inventory and hard constraints before novelty. |
| Named outfit collections | FR-13 occasion tags; saved look associations; Saved screen | **New explicit UX and modest data extension.** Create/rename/remove collections and membership; include them in sync/export/restore. Put them inside Saved rather than add unlimited global navigation tabs. Deleting a collection must not delete its outfits. Multiple membership is a sensible proposal, not confirmed. |
| Less wear chronology | FR-39; optional saved/worn signals in §8 | **Simplification, not a wholesale conflict.** No mandatory wear calendar currently exists. Keep recommendation/save history for diversity; make actual wear logging optional and unobtrusive. Saving is not evidence of wearing. |
| Specific petite fit issues | FR-01/15; §§10.1–10.2; general length/ease feedback | **Partial.** Add jacket length, navel-area rise and optional affected-area fit feedback for waist/seat/thigh/length. Do not introduce mandatory hip/thigh measurements or equate a brand’s “mid-rise” with her desired placement. |
| Meaning of “has to be petite” | §10 allows documented better-fitting regular/cropped alternatives | **Clarification needed.** Does she mean petite proportions or exclusively retailer-labeled Petite? Preserve evidence-based fit guidance until she confirms a literal label restriction. |
| Persistent Save for Later | FR-37; wishlist state; §§12, 13.4, 14.1 | **Mostly covered.** Expose the existing state with a discoverable saved-products view, selected variant and source. Price/stock snapshots age; saved products may become unavailable. Saving never means buying. |
| Buy Now | FR-17/18; Safari/external retailer opening; explicit purchase and arrival | **Mostly covered wording.** The action opens the retailer product page, where she confirms the variant and completes checkout. It is not a new merchant system or automatic purchase. Consider “View at Store” with explanatory copy so the handoff is clear. |
| Multiple ways to wear a candidate | General closet-first/versatility direction; finder lacks a precise output contract | **Partial/new detail.** Show a bounded set of distinct combinations tied to known inventory IDs. Count examples actually found, not imaginary potential wears. Label the candidate unowned throughout. Boards need no image-generation spend; personal previews do. |
| Affordable and investment options | FR-12 and finder budget/price data | **Partial.** Compare credible matching products in two price directions when available. Never invent a second option or treat price/brand as proof of durability. |
| Reusable, replaceable, deletable reference | §§9.2.1, 9.2.4, 15 | **Covered foundation.** Preserve named image-purpose permission, private storage, source versions, recovery and deletion. Resolve Replace versus privacy Delete and effects on existing generated pictures. |
| Own-outfit photo learning | FR-11/19; original-first imports; editable tags; linked saved outfits | **Missing explicit intake flow.** First save a real outfit photo and let Lily link existing clothes. Optional AI suggestions require review and existing/new/ignore choices; do not assume automated extraction was requested. |
| Text-only owned item on her body | FR-19/37 representatives; §9.2 actual-garment image requirement | **Feasibility/expectation gap.** Require known-attribute fidelity for an accepted representative preview, with rejection/fallback when rendering fails that criterion. An exact unphotographed garment cannot be reconstructed from its category/color alone. Closer fidelity needs an optional real photo. |
| “Mostly used” garments | Saved/selected/worn signals exist | **Undefined semantics.** Favorites or “Often in your saved looks” are honest options. Do not call generated/saved selections actual wear or introduce invisible wear tracking. |
| Mature/cohesive personal style | Editable aesthetic preferences | **Personalization detail.** Capture her goal of polished, coherent outfits by occasion. No age-based dress rules, additional birth-date collection or boyfriend-controlled preferences are implied. |
| Less frequent use after establishing a wardrobe | Monthly value and task-success metrics | **Success-model refinement.** Successful learning and reusable looks may reduce daily requests. Three sessions/day remains a cost scenario, not observed demand or a target to force with reminders. |

Relevant master anchors: [functional requirements](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:187), [strict inventory and learning](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:366), [image strategy](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:383), [fit layer](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:506), [data model](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:762), [finder](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:790), [acceptance criteria](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v0.1.md:1081).

## 5. What is actually possible?

### Conventional application work

Today-only preferences, named collections, editable favorites, durable wishlists, actual-item color filters and linked saved photos are achievable with the proposed SwiftUI/local-record architecture. They need implementation and recovery tests, but no custom fashion model or new consumer account.

Showing several combinations for a candidate is also feasible when enough confirmed inventory is recorded. Its usefulness still requires Lily’s evaluation. Finding real affordable/investment products with credible petite fit depends on permitted catalogs and evidence, already an unresolved finder gate. No service can guarantee a product remains in stock or physically fits her.

### Dedicated Google try-on: useful candidate, incomplete proof

Google’s current model is generally available. Its live card lists support retirement on **March 15, 2027**; possible later Gemini API access is a separate offering, not a verified migration. This makes lifecycle planning necessary before relying on this version. [Google model card](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/vto/virtual-try-on-001).

The REST contract specifies a person image and **one product image**. Multiple output candidates are variations from those inputs, not proof of three distinct whole outfits. Separate pants, blouse, cardigan, shoes and accessories are not an established arbitrary garment-array workflow. Sequential passes or a garment collage can be tested, but may distort earlier pieces. [Google input schema](https://docs.cloud.google.com/gemini-enterprise-agent-platform/reference/rest/Shared.Types/VirtualTryOnModelInstance), [generation guide](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/capabilities/generate-virtual-try-on-images).

Preserving unedited wardrobe IDs is deterministic app behavior. Preserving every other garment’s appearance, body proportions, face and pose in a newly generated picture is a different, unvalidated image-quality problem. A dedicated API does not establish that Lily’s layered interview outfit or repeated swaps will pass it.

No verified completion-time guarantee establishes instant results for this workflow. The master’s 120-second bound is a proposed job deadline, not a provider benchmark. Measure end-to-end waiting, not just model execution.

### Generic garments and known colors

Google’s documented input needs a clothing image. A library of licensed/app-owned representative color/category/cut assets could supply that image for text-only entries. This represents an approximate garment; “white tank top” does not disclose exact straps, neckline, fabric or drape. A real photo can improve detail later without changing the item ID.

“Blue must not become green” should be a quality and rejection criterion. Source comparison and validated checks can reduce mistakes, but no absolute error-free rendering guarantee is justified. Do not silently accept a mismatched picture, change the stored color to match it, or make unbounded paid retries. Provide correction and a truthful fallback.

### Own-outfit photos

The modest version is: save the original, link existing items, optionally propose category/color matches, review each candidate as Existing / Add owned / Ignore, then save the outfit and collection. Favorites do not confirm ownership of hypothetical items.

Automatic garment detection and matching are plausible aids, not exact closet reconstruction. Hidden layers, similar garments, borrowed clothes and uncertain attributes require review. Apple Vision and Google image understanding provide useful classification/segmentation/detection building blocks; neither establishes perfect item identity, ownership or size. [Apple Vision](https://developer.apple.com/documentation/vision), [Google image understanding](https://ai.google.dev/gemini-api/docs/image-understanding).

### Preview versus physical fit

Lily’s trust in seeing her proportions is understandable. The app must still separate “does this styling appeal to me?” from “will this specific size fit?” A plausible image can conceal a real length/ease problem. Use measured garment/chart evidence and confirmed fit feedback for sizing. Google also warns that its consumer visualization can contain body/garment errors and does not establish physical fit; that consumer product’s catalog and privacy terms are not our Cloud API contract. [Google’s visualization explanation](https://support.google.com/googleshopping/answer/16253678?hl=en).

## 6. Image cost and subscription implications

Google’s published rate is **US$0.06 per generated output**. The calculations below assume that rate for every billed output and no discounts. A two-pass pipeline is only an experimental scenario. [Google pricing](https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing).

| Hypothetical use | Outputs/day | Image cost, 30 days | Image cost, 365 days |
| --- | ---: | ---: | ---: |
| Ordinary boards, no generated pictures | 0 | $0.00 | $0.00 |
| Three sessions/day, one selected image each | 3 | $5.40 | $65.70 |
| One session/day, three initial images | 3 | $5.40 | $65.70 |
| Three sessions/day, three initial images each | 9 | $16.20 | $197.10 |
| Same use, two charged passes per final picture | 18 | $32.40 | $394.20 |

Additional single-pass swap/regeneration images add $0.06 each at this rate. Personal-image versatility examples multiply outputs too. These scenarios exclude text AI, image recognition, representative-asset creation, storage/egress, hosting, taxes, payment fees and paid rejected/failed work. Cost per accepted look is the important measurement.

Assuming eleven paid months following an eligible initial one-month trial, the candidate $9.99 monthly price would produce $109.89 gross; actual renewal timing follows calendar dates. It cannot cover the intensive $197.10 yearly image scenario even before other costs. That does not imply changing Lily’s experience: her existing owner-sponsored policy can fund intentionally approved usage. Public allowances/pricing must be chosen separately using measured demand, including trials that never convert. Her stated expected decline in long-term use means none of these scenarios should be called her predicted annual bill.

For an opted-in mode, one deliberate Style Me action can transparently request three images; three repeated permission dialogs would create unnecessary friction. Define what happens when only one or two images finish, when an allowance cannot cover all three, and when a swap invalidates a preview. Do not generate automatically on every navigation, color scroll or restoration.

## 7. Privacy, security and Apple implications

Most safeguards are already substantial in the master and should remain: server-held credentials, permissioned image routes, finite cost reservations, durable jobs, metadata sanitization, private assets, redacted logs, independent free core, version fencing and original-inclusive recovery.

Apple requires explicit permission for third-party AI sharing and further consent for repurposing (§5.1.2). Its health rules prohibit personal health information in iCloud (§5.1.3(ii)); digital credits and physical retail goods follow different payment rules (§3.1). A clothing-comfort control does not automatically create a health app, but retaining actual symptom/cycle information requires a separate assessment. Renaming retained symptoms “preferences” is insufficient. Existing privacy, accurate-feature and iPad obligations still apply. This review is not App Store approval. [Current Apple guidelines](https://developer.apple.com/app-store/review/guidelines/).

Recommended minimal handling of her comfort need: use “more room at the waist today” or a fitted/comfortable/relaxed choice. Keep it separate from measurements; do not infer her cycle, change her body photo, or build symptom history. Define expiry and ensure sensitive raw notes do not accidentally persist in synced drafts, outfit explanations or analytics. Actual privacy labels follow what leaves the device and what processors retain. [Apple privacy details](https://developer.apple.com/app-store/app-privacy-details/).

Her interview indicates willingness, not live permission to upload to a particular provider. The actual application must identify the processor and purpose. A reusable photo does not authorize model training, other photo-analysis purposes or transmission to every configured vendor.

Google’s no-training assurance does not establish zero retention. Abuse monitoring has separate retention and review provisions; verify the selected account and image route rather than transfer consumer Shopping promises. Confirm input/output handling and deletion before uploading Lily’s photo. [Google governance](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/zero-data-retention), [abuse monitoring](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/abuse-monitoring).

**Reference replacement needs a precise product rule.** Replacing a current reference should use a new revision for future work without silently altering saved outfits. Explicit privacy deletion should preview its exact scope. The current master purges dependent generated likenesses when deleting a reference; Lily has not said whether uploading a new photo should erase all her old saved pictures. Do not silently weaken that purge policy. App-controlled deletion, pending remote completion, processor retention and independently exported copies remain distinct.

Private collections require no social network or new public-account requirement. Outfit-photo recognition needs reviewed tags and explicit ownership confirmation. Keep owner-sponsored usage privileged on the server; Lily’s name in a client request must never grant it. Purchased credits, if offered, still need durable recovery across reinstall/iPhone/iPad before sale.

## 8. Architecture and rollout recommendation

Keep the same app and the existing separation:

1. Local profile, closet, collections and saved outfits.
2. Typed stylist request with current context and canonical eligible item IDs.
3. Validated outfit composition, independent of whether a photo exists.
4. Separately consented image renderer with durable jobs and financial admission.
5. Generated images linked to exact outfit/reference/item revisions, never used as the ownership database.

No new app, Google consumer login, custom model training, social platform or retailer checkout engine is required. Google image rendering can coexist with another text-stylist provider and a separately chosen backend host.

There is real implementation work beyond a model switch: request context, lane semantics, collection data, image-batch orchestration, allowance disclosure, partial completion and stale-preview UX. Current released-client compatibility rules still matter; new screens or response semantics cannot be assumed to ship through server configuration alone. Three child image jobs need bounded concurrency and reservations consistent with the existing one-in-flight-action policy, not an accidental bypass.

Recommended order:

1. **Make the factual and product clarifications reviewable:** unknown inseam; correct style direction; jacket/rise issues; today-only context; lane/shopping rules; real-item color swaps; collections and wishlist wording. Obtain acceptance of substantive behavior before changing the master.
2. **Prototype on-body comparison early:** it is central to Lily’s expressed preference. Start single garment, then her actual layered cases and swaps. Use consented material only after privacy/budget controls are ready. Select on fidelity, wait and accepted-look cost; verify a successor/provider fallback before production commitment.
3. **Implement reliable closet/edit/save/recovery foundations in parallel with that evidence work:** conventional features do not become less important because a rendering looks polished.
4. **Add bounded purchase-versatility and price comparisons after permitted finder evidence exists.** Save real outfit photos with reviewed links before considering automatic extraction.
5. **Validate her three supplied tasks and retest changes.** A board-only test should not be described as satisfying the full on-body request. If rendering falls short, show her actual results and decide the compromise with her.

Existing open implementation gates remain: persistence/migration/conflict safety; stable accountless entitlement/usage proof; purchased-wallet recovery if packs ship; permitted catalog/fit access; actual processor terms; finite owner/global budgets; iPhone 12/iPad accessibility and performance. Her interview does not close them.

## 9. Decisions still needed

The most valuable follow-up is a small demonstration, not another 35-question interview.

1. **Personal-image timing and edits:** will she accept useful garment choices while personal pictures finish? After a swap, does she prefer one deliberate refreshed image or explicitly metered generation on every committed swap?
2. **Generic garment tolerance:** is a clearly labeled representative preview acceptable until she adds a photo? An exact unknown garment cannot be promised.
3. **Shopping and limited inventory:** when shopping is off, should all choices be owned? If only one or two valid looks exist, should those be shown immediately with an explanation? This would require changing the current exactly-three success contract, not just its labels.
4. **Petite meaning:** documented fit for her proportions, or exclusively a retailer Petite label?
5. **Photo replacement/deletion:** should ordinary replacement retain old saved pictures, and what should explicit deletion remove?

Smaller choices can use reviewable defaults: multiple collections per outfit, Favorites separate from Saved, manual pinning/“Often in saved looks” rather than assumed wear, neutral comfort wording and an explicit new-request reset. Hair/accessory generation and boyfriend-based personalization are not implied requirements.

## 10. Validation to add if these directions are accepted

| Scenario | Evidence needed |
| --- | --- |
| Last-minute work interview | Only confirmed eligible inventory; no shopping dispatch; useful variation; independent swap; save/reopen; personal previews evaluated if enabled. A pink blouse in an example is not proof she actually owns one. |
| Blue-themed rainy event with relaxed-waist comfort | Required/preferred color handled correctly; precipitation and comfort respected; no permanent profile change or symptom timeline; appropriate distinction from a whole-blue outfit. |
| Buy a useful petite piece | Clearly unowned candidate; distinct combinations using actual recorded inventory; credible available price tiers; durable Save for Later; stale/removed products handled; ownership only after explicit confirmation. |
| Color swap and image drift | Other IDs unchanged; generated image linked to correct revision; old preview labeled; actual source color checked; unsupported/mismatched render not presented as faithful. |
| Text-only garment | Known category/color retained, unknown details labeled; no mandatory photo; attaching a later photo preserves item relationships. |
| Collections and favorites | Create/rename/multi-membership if chosen; deletion affects membership only; offline edit, two-device conflict, archive restore and availability badges. |
| Outfit-photo intake | Existing/new/ignore review, no duplicate inferred garments, no invented brand/size/fabric/ownership; original and linked look recover after interruption. |
| Three-image job set | Repeated taps, force-close, timeout, one failed image, exhausted allowance, cancellation and late responses preserve valid outfits; no duplicate inference/debit or stale overwrite. |
| Replace/delete personal reference | Saved-look consequences explicitly reviewed; future jobs use new version; purge and pending status accurate; late jobs cannot resurrect deleted content. |
| Lily’s visual trust | Real consented examples across colors, trouser/jacket proportions and layers; accepted-look rate, p50/p95 waiting, paid outputs per accepted look and concrete reasons for failure recorded. No physical-fit claim from pictures. |

All existing application acceptance and RV/TO checks remain **Not run**. This assessment has not changed their status or the master’s requirement counts.

## Review integrity

At review time, SHA-256 of the master was 4f9cce016ec669217bdf6dac4858fbe079a302fc60ceafc6fe187c347a69f313. Lily’s original feedback was 320998b96fa9489fef496701611134207d2ae51ce3314847c4f46cfe2b756f83. These identify the reviewed inputs, not app test evidence. Historical Word and pointer documents were not amended.
