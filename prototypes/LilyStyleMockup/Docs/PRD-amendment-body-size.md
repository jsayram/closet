# PRD amendment proposal: body size as a fit input

Status: proposal for the owner, 5 October 2026. The master spec, [My_Petite_Style_PRD_v2.md](../../../My_Petite_Style_PRD_v2.md), was left unchanged. Nothing in this file takes effect in the PRD until the owner accepts it and edits the PRD.

Line numbers below refer to the PRD as it stands on 5 October 2026. Each item quotes the passage that conflicts with the decision and gives replacement text that can be pasted in. Where only part of a paragraph changes, the quote covers just that part and the rest of the paragraph stays as written.

## The decision

The owner approved this: body size affects how clothes fit and look, so the app uses it, in this order of trust.

1. **Confirmed waist, hip and bust come first.** Only measurements with a Body or ChartRange basis that she has confirmed count. They shape styling (what Fitted, Comfortable and Relaxed mean for her) and Find One's chart comparisons, now including hip where a listing gives a hip range.
2. **Weight is an optional fallback.** It's stored as a structured value (number, lb or kg, an "approximate" flag and an update date). Only when waist, hip and bust are all missing or unconfirmed does confirmed height plus weight give a rough overall size band (XS, XS–S, S, S–M, M, M–L, L, L–XL, XL+). The band is always labeled "Rough estimate from your height and weight". It never produces Supported sizing guidance, never sets a recommended size, never excludes a listing as a known conflict and never overrides a confirmed measurement. The app never shows a BMI or any health framing.
3. **Fit cues describe room, not body types.** From confirmed measurements, compared in inches: room at the hip when hip is 10 in or more above waist, room at the bust when bust is 10 in or more above waist, and a straighter line when both are within 6 in of waist. Copy talks about room, ease, stretch, cut and drape. It never uses body-type names (pear, apple, hourglass), "flattering", "slimming", hiding, minimizing, camouflage or "problem areas".
4. **Raw weight is never shared.** It lives only in her own data: on the device, and in her private iCloud when sync is on. It isn't put in a web search query, in the cloud stylist's context or in an Ask another stylist export. Where an existing permission allows, only the band label and the cue words can be shared. Find One's reviewed search intent gets an "Include my size range" control, off by default, that shows the exact text it adds (for example "size M"). Confirmed measurements aren't added to a search as numbers either.
5. **Saved usual fit is the default comfort.** Style Me and Ask Stylist use her saved usual fit (Fitted, Comfortable or Relaxed; the PRD's "Close" is labeled "Fitted") when today's comfort isn't set. Today's choice still overrides it for that request only.
6. **Unknown stays unknown for measurements.** The band never fills in a missing waist, hip, bust, inseam or any other dimension.

The prototype maps height and weight to a band with an illustrative table, not a sizing standard. It computes 703 × lb ÷ in² internally and never shows or names that number: under 18.5 is XS, 18.5–20 XS–S, 20–21.5 S, 21.5–23 S–M, 23–25 M, 25–27 M–L, 27–29.5 L, 29.5–32 L–XL, and over 32 XL+. Lily's demo profile (4′11″ confirmed, about 120 lb) comes out as M. A production mapping would need its own review and evidence, so the amendment text below doesn't fix the numbers.

## Passages that conflict, with proposed replacements

### 1. §3.1 Primary design persona, Body profile row (line 88)

Current:

> Optional 110–130 lb context is owner-supplied, never a fixed size mapping. Confirm other measurements/fit references only when useful; do not infer them from height, weight or a photo.

Proposed:

> Optional 110–130 lb context is owner-supplied. Weight is only a rough fallback: when waist, hip and bust are all missing or unconfirmed, confirmed height plus weight may give a rough overall size band, always labeled as an estimate (Section 10). It is never a fixed size mapping, never fills in a measurement and never overrides a confirmed one. Confirm waist, hip, bust and other fit references only when useful; do not infer measurements from height, weight or a photo.

### 2. FR-01 Flexible personal fit profile (line 214)

Current (two parts of the row):

> storing editable optional height, inseam, sleeve length, waist and bust with units,

> Weight is optional context, never a sizing rule or prerequisite.

Proposed:

> storing editable optional height, inseam, sleeve length, waist, hip and bust with units,

> Confirmed waist, hip and bust are the primary fit inputs. Weight is optional, stored as a value with unit, an approximate flag and an update date, and is never a prerequisite. It is used only as a labeled rough fallback when waist, hip and bust are all missing or unconfirmed: confirmed height plus weight gives a rough size band that never supports a size, never excludes a listing and never overrides a confirmed measurement. Raw weight is never sent to a styling, search, ranking or export recipient (Section 15.4).

### 3. FR-05 Today's styling context (line 218)

Current:

> Default neutral comfort choices are Close / Comfortable / Relaxed;

Proposed:

> Neutral comfort choices are Close / Comfortable / Relaxed (shown as Fitted / Comfortable / Relaxed). When she doesn't choose one, her saved usual fit is used for that request; a choice made today overrides it for that request only and does not change the saved usual fit.

### 4. §8.3 Today's context (line 507)

Current:

> Default today's comfort is a neutral clothing choice: Close / Comfortable / Relaxed, optionally with a specific wish such as more room at the waist. It affects the current request, not measurements, usual fit, weight or a body-photo edit.

Proposed:

> Today's comfort is a neutral clothing choice: Close / Comfortable / Relaxed, optionally with a specific wish such as more room at the waist. When she leaves it unset, the request uses her saved usual fit and says so. A choice made today affects the current request only, not measurements, usual fit, weight or a body-photo edit.

### 5. §8.5 Context assembly (line 528)

Current:

> Contextual weight is optional and omitted when irrelevant; it never maps to size or body shape.

Proposed:

> Raw weight is never included in StylistContext. When waist, hip and bust are all missing or unconfirmed, the client may include only a rough size band label derived on the device from confirmed height and weight, marked as an estimate. When confirmed waist, hip or bust exist, the client may include neutral fit cues (room at the hip, room at the bust, a straighter line) instead. Both are included only while the named cloud styling permission allows. Weight never maps to body shape.

### 6. §8.5 Stylist policy, rule 2 (lines 553–556)

Current:

> Height does not establish inseam, torso length, shoulder width, shape or size; weight does not establish a size.

Proposed:

> Height does not establish inseam, torso length, shoulder width, shape or size. Use confirmed waist, hip and bust and any supplied fit cues to decide how much room, ease, stretch and drape a piece needs, described in those terms and never as a body type or as flattering, slimming or hiding anything. A rough size band from height and weight, when supplied, is an estimate only: mention it as one, and never treat it as a measurement or a confirmed size.

### 7. Section 10 Petite-First Styling Layer, bullets (lines 751 and 755)

Current (line 751):

> Store height and measurements separately from weight; weight alone must never determine size.

Proposed:

> Store height and measurements separately from weight. Confirmed waist, hip and bust are the primary fit inputs. Weight never determines a size on its own: only when waist, hip and bust are all missing or unconfirmed may confirmed height plus weight give a rough size band, always labeled "Rough estimate from your height and weight". The band never gives Supported sizing guidance, never excludes a listing and never overrides a confirmed measurement. No BMI or health framing.

Line 755 ("Petite does not describe a weight…") stays as written. Add a new bullet after it:

> Confirmed waist, hip and bust can give neutral fit cues compared in one unit: room at the hip, room at the bust, or a straighter line, using reviewed thresholds. Cues guide cut, ease, stretch and drape. They are not body types, and fit copy never uses body-type names, "flattering", "slimming", hiding, minimizing or "problem areas".

### 8. §10.1 Minimal setup, Profile → Fit & Measurements (line 763)

Current (two parts):

> offers optional inseam/preferred trouser length, sleeve length, waist and bust,

> no weight-derived size or fixed waist/bust is assumed.

Proposed:

> offers optional inseam/preferred trouser length, sleeve length, waist, hip and bust, plus optional weight,

> no fixed waist, hip or bust is assumed. Waist, hip and bust are presented first as the main fit inputs. Weight is explained as a rough fallback used only when those three are missing, labeled as an estimate and never shared. The profile shows which source fit notes currently use.

### 9. §10.2 Flexible foundation (lines 773 and 779)

Current (line 773):

> height/weight/photo cannot fill missing dimensions.

Proposed:

> height/weight/photo cannot fill missing dimensions. A rough height-and-weight size band is not a dimension: it never fills a missing waist, hip, bust or length, and missing values stay Unknown.

Current (line 779):

> Do not derive a clothing size from the 110–130 lb range or require weight tracking.

Proposed:

> Do not derive a supported clothing size from the 110–130 lb range or require weight tracking. Fixtures cover both paths: no confirmed waist, hip or bust (labeled rough band from height and weight), and confirmed measurements (fit cues, band no longer used).

### 10. §12 Core Data Model, UserProfile entity (line 1070)

Current:

> optional contextual weight;

Proposed:

> optional weight (value, unit lb/kg, approximate flag, updatedAt), private to the device and the user's own sync/export, never sent to search, stylist or export recipients; derived BodyFit (source: measurements, height-and-weight estimate or none; fit cues; rough band label), recomputed from the current profile revision and holding no raw weight;

### 11. §13.2 PublicShoppingIntent (line 1134)

Current:

> Exclude raw user prose, full profile/body measurements, body photos,

Proposed (adds one sentence after that list):

> Exclude raw user prose, full profile/body measurements, weight, body photos, … [rest of the list unchanged]. The one exception is an optional size-range label (for example "size M") that she turns on with a reviewed "Include my size range" control, off by default for each request, which shows the exact text before Search. It carries only the rough band label, never weight or measurement numbers.

### 12. §13.5 Ask another stylist export (line 1194)

Current:

> Optional height/fit/preferences may be added after explicit selection; measurements, name, location, product URLs and whole-closet data are excluded by default.

Proposed:

> Optional height/fit/preferences may be added after explicit selection, including a "Size & fit cues" field that carries only the fit cue words or the rough band label. Weight is never exported. Measurement numbers other than height, name, location, product URLs and whole-closet data are excluded by default.

### 13. §13.8 Fit eligibility before ranking (line 1226 and the fit evidence table, lines 1230–1232)

Current (line 1226):

> If a critical dimension is unknown on either side, retain it as unknown rather than substitute height, weight, XS/S, a photo or a generic petite rule.

Proposed:

> Pants and dress comparisons include hip where the applicable chart gives a hip range; a confirmed hip outside it is a known conflict, and an unknown hip is shown as unknown. If a critical dimension is unknown on either side, retain it as unknown rather than substitute height, weight, XS/S, a photo or a generic petite rule. When waist, hip and bust are all missing or unconfirmed, a rough height-and-weight band may be applied on the device after ranking to label Needs fit confirmation leads as a rough estimate and order them by how close the listed size is to the band. The band never moves a lead into SupportedGuidance, never sets a recommended size and never creates a KnownFitConflict. The ranking processor receives the profile without weight.

Add to the end of the SupportedGuidance row (line 1230):

> A rough height-and-weight estimate is never sufficient evidence for this state.

Add to the end of the KnownFitConflict row (line 1232):

> Only confirmed measurements or reviewed fit references can create a conflict; a rough size band cannot.

### 14. §15.4 Data inventory table (lines 1432 and 1442)

Local profile row (line 1432). Add to the end of the Retention / deletion cell:

> Optional weight is included in local profile data, private sync and export, counted in export review and covered by Delete My Data. It is never sent to a styling, search, ranking or export recipient.

Public search row (line 1442). Current:

> Public search receives reviewed garment intent only, no body measurements/photos/closet context.

Proposed:

> Public search receives reviewed garment intent only, no body measurements, weight, photos or closet context. The only size text it may receive is the rough band label she turned on with "Include my size range". Ranking receives minimal permissioned facts with no browsing tools and no weight.

### 15. §24.2 Privacy and legal launch scope (line 1795)

No wording conflicts, but the review it asks for now has a concrete field to cover. Proposed addition after the first sentence:

> This includes the structured optional weight field and whether it may sync to private iCloud; if it may not, keep it on the device only.

### 16. §19 MVP Acceptance Criteria, AC-58 (line 1574)

Current:

> optional 110–130 lb context never maps to a size or fabricates measurements. Changing/skipping weight cannot override confirmed dimensions/fit references or cause a weight-only size change.

Proposed:

> optional 110–130 lb context never fabricates measurements. With waist, hip and bust missing, height and weight give only a labeled rough size band that never supports a size or excludes a listing. Changing or skipping weight cannot override confirmed dimensions/fit references; once any of waist, hip or bust is confirmed, weight has no effect on fit guidance. Raw weight never appears in a search query, stylist context, export, log or analytics event.

### 17. §19 MVP Acceptance Criteria, AC-96 (line 1615)

Current:

> Never invent 25/26 inseam, shape/size from height/weight/photo, unsupported stretch/ease or confidence percentages.

Proposed:

> Never invent 25/26 inseam, a body shape, a supported size from height/weight/photo, unsupported stretch/ease or confidence percentages. A labeled rough band from height and weight is allowed only when waist, hip and bust are all missing. Fit cues from confirmed measurements are described as room, ease and cut, never as body types.

### 18. §25.5 Release checks, RV-15 and RV-29 (lines 1968 and 1982)

RV-15, current expected result:

> no fit/weight assumptions

Proposed:

> no fit assumptions; weight only as a labeled rough fallback when waist, hip and bust are missing

RV-29, current scenario text:

> weight/height/photo inference

Proposed:

> weight/height/photo inference (only the labeled rough band from height and weight when waist, hip and bust are missing; it never supports, excludes or overrides), and no raw weight in any outbound payload

### 19. New revision record (after §26.9)

Proposed new section:

> ### 26.10 Body size as a fit input — October 5, 2026
>
> The owner decided that body size affects how clothes fit and look, so the app uses it in an order of trust. Confirmed waist, hip and bust are the primary fit inputs and give neutral fit cues described as room, ease and cut. Weight is optional and structured, and is used only as a labeled rough fallback, with confirmed height, when waist, hip and bust are all missing or unconfirmed. The rough band never gives Supported sizing guidance, never excludes a listing and never overrides a confirmed measurement. Raw weight is never sent to a stylist, search or export recipient; only the band label or cue words can be shared where a permission allows, and Find One adds a size range to a search only through an explicit, off-by-default control. Saved usual fit is the default comfort unless today's choice overrides it. All application/RV/TO tests remain **Not run**.

## Passages checked that need no change

These mention weight or body size but already agree with the decision:

- Line 115: no height, weight, size or gender eligibility cutoff.
- Line 755: "Petite does not describe a weight", and the user isn't required to want to look taller.
- Line 1346: today's comfort is separate from usual fit and measurements, with no health history.
- Line 1467: no body scores or weight-loss advice, and body-neutral language.
- Line 1757: analytics never collect body measurements or weight.
- Line 1791: no HealthKit or weight-loss features.
- Line 1916 (traceability row 17): petite is not weight.
- The October 3 revision record (line 2061) describes that revision and stays as history; item 19 adds a new record instead.

## How the prototype follows this

The prototype in this folder already behaves as described above, ahead of the PRD. [Traceability.md](Traceability.md) lists where each rule is enforced in code ("body-size proposal" rows), and [Verification.md](Verification.md) records that this feature was checked by build and code review only, after the screenshot pass.
