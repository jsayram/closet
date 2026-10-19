# Privacy policy outline

Phase 19b draft, 19 October 2026. The outline and draft wording for the policy at https://niftyoutfitnook.pages.dev/privacy. It follows App Review 5.1.1(i), which asks the policy to say what data the app collects, how and why, confirm that third parties it shares data with protect it as well as the policy says, explain retention and deletion, and explain how to withdraw consent and ask for deletion.

**Not published.** Jose approves the wording and decides when it goes live. Sections marked **[Lawyer]** need a lawyer's check before public launch; see [LEGAL_QUESTIONS.md](LEGAL_QUESTIONS.md).

## How the published page grows

The page must describe what the app does now, not what it will do. So it starts small and grows phase by phase:

| Version | When | What the page covers |
|---|---|---|
| 0 | When Jose approves 19b | Sections 1 to 4, 9, 11 and 12 only, with Section 3 saying the app sends nothing and listing the features still to come, each "only if you allow it" |
| 1 | 24a, before sign-in ships | Adds account data, Clerk and Convex, age |
| 2 | 27a and 29 | Adds the stylist (Anthropic) and weather |
| 3 | 30a to 30c | Adds purchases |
| 4 | 33a | Adds try-on and Black Forest Labs |
| Release | 35a | Full text after legal review |

Each version keeps a dated "What changed" line at the bottom, and the app's Privacy and terms screen shows the policy's date.

## Draft sections

### 1. Who we are

> Nifty Outfit Nook is an iPhone and iPad app that helps you put outfits together from the clothes you already own. It is made by **[operator name, to confirm: Jose personally or a business]** ("we"). Questions about privacy: **support@codedetails.io**.

**[Lawyer]** Whether the operator should be a business rather than an individual (App Review 5.1.1(ix) asks apps that need sensitive user information to be submitted by a legal entity; LEGAL_QUESTIONS question 1). A postal address may be required by some state laws.

### 2. The short version

> - Your closet, photos, measurements and looks are kept on your iPhone, and in your own iCloud if you turn sync on. We don't keep a copy of your closet.
> - Nothing leaves your phone for a feature until you turn that feature on. Each feature asks separately, and saying yes to one never says yes to another.
> - When a feature does send something, this page names the company that gets it, what they get, and how long they keep it.
> - No ads, no tracking, and we never sell your data.
> - Try-on pictures are different: if you turn them on, a photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models. Your face never leaves your phone.

The last bullet appears from version 4. "We never sell your data" needs the lawyer's answer on whether sending photos to BFL under its training terms counts as a "sale" under any state law before it's published (**[Lawyer]**, question 5).

### 3. What stays on your device

> Everything you add: your pieces and their photos, suitcases, laundry marks, looks, try-on pictures, your try-on photo, the name on your sign, your fit, measurements and weight, and your preferences. The app protects these files with your iPhone's strongest file protection, and hides your measurements and pictures when you switch apps.
>
> If you turn on iCloud sync, a copy goes to your private iCloud, which only your Apple Account can reach. We can't read it. Apple holds the keys to most iCloud data unless you turn on Advanced Data Protection; with it on, the fields we mark as encrypted are end-to-end encrypted. See Apple's iCloud security overview.
>
> If you export a backup, the file is encrypted with a passphrase you choose, and it's yours to keep or delete.

The iCloud paragraph comes with 20b, the export one with 21b, once the designs are final (D10). It states accepted risk D8(a) plainly.

**[Lawyer]** Whether syncing weight and body measurements to iCloud is allowed under App Review 5.1.3(ii), which bars storing "personal health information in iCloud" (question 3).

### 4. Features that send data, and only when you allow them

One subsection per feature, each with the same five lines: what's sent, to whom, why, how long they keep it, what's never sent. Added with the feature's phase.

**4a. Your account (24a)**

> If you sign in with Apple, Apple tells our sign-in provider, Clerk, a private ID for you. We ask Apple for no name **[and no email; if Clerk needs one, a private relay address, decision D6]**. Clerk keeps your account and sign-in sessions; our server (Convex) keeps a private ID that links your account to your purchases, your consent choices and your usage limits. You don't need an account to use your closet.
>
> We also check, with Apple's App Attest, that requests come from the real app. That stores a key for your app install on our server.

**4b. Style Me, swaps and Ask stylist (27a)**

> When you tap Style me, swap a piece or ask the stylist, the app sends Anthropic, the company that makes Claude, what it needs for that request: short descriptions of the pieces involved (kind, colour, fabric, the names you gave them), the occasion, the weather conditions (like "cool and rainy", never your location), notes you typed, and a short list of recent looks so it doesn't repeat them. **[If decided: your height and the one or two measurements that matter for the request. Never your weight.]** It never gets your name, your email, your account ID or your photos.
>
> Anthropic doesn't use this to train its models. It deletes it within 30 days, unless its safety systems flag a request, in which case it can keep it for up to 2 years. Requests may be processed in data centres outside the US.
>
> Our server passes the request along without saving it, and keeps the answer for up to 24 hours, encrypted, so a dropped connection doesn't cost you another request.

The bracketed measurement sentence depends on the 27a decision in the README. The location line depends on D5 (global processing accepted, or a US-pinned model).

**4c. Weather (29)**

> If you allow location, the app asks Apple Weather for the forecast near you, using a rough location, not your exact address. We don't keep your location, and only the weather conditions go into Style Me.

**4d. Try-on pictures (33a)**

> If you turn on try-on pictures, your phone first hides your face: it covers your head and hair with flat grey and replaces the room behind you with a plain studio backdrop. If it can't find your face or can't confirm the cover, nothing is sent.
>
> Then **a photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models.** Black Forest Labs' terms give it a lasting right to use what it receives, including for training. We can't delete copies Black Forest Labs keeps, and deleting your data in the app doesn't remove them.
>
> Black Forest Labs sends back the dressed picture. Your phone puts your own face back in and saves the finished picture on your iPhone (and your iCloud if sync is on). Our server keeps neither the photo nor the picture. On every try-on picture, "See what was sent" shows the exact image that left your phone.
>
> No measurements, notes or names are sent with try-on.

**[Lawyer]** Whether this disclosure and the in-app consent are enough under state privacy, biometric and consumer health laws, and under App Review 5.1.1(i)'s "same or equal protection" clause (questions 4 and 5).

**4e. Feedback and support (24d)**

> If you send feedback, we get exactly the text you saw before sending, plus the app and iOS version and your iPhone model only if you turned on "Include app details". If you give a reply address, we use it only to answer that note. We delete notes 90 days after we close them.

**4f. Purchases (30a to 30c)**

> Apple handles payment; we never see your card. We get a record of what you bought (subscription, free unlock or picture credits) so the app knows what you have, and we keep it for as long as billing and tax records require. **[Lawyer: the period, question 12.]**

**4g. Improvement analytics (31, only if built)**

> Off unless you turn it on. If on, the app sends simple events like "Style Me finished" with the app version and a random ID you can reset. Never what you type, your photos or anything about your closet. Raw events are deleted after 30 days.

**4h. Find One (34, only if built).** Written when the shopping direction is settled.

### 5. Companies that handle your data

> We only use companies we need to run the features above. Each one gets only what's listed for its feature.

| Company | What it gets | Why | Where | How long |
|---|---|---|---|---|
| Apple | iCloud sync (if on), Sign in with Apple, App Attest, purchases, the weather lookup, crash reports you choose to share | Running the app on Apple's platform | Apple's data centres | Apple's own terms |
| Clerk | The private ID from Sign in with Apple, your sign-in sessions | Accounts | Anywhere in the world (Clerk's policy) | Until you delete your account; Clerk's retention after deletion **to confirm** |
| Convex | Your private ID, consent choices, usage and credits, purchase records, support notes; passes styling and try-on requests through without saving them | Our server | **US region, to confirm when the deployment is created (23b)** | As listed in section 7 |
| Anthropic (Claude) | The styling request in 4b | Outfit ideas | Inference anywhere in the world; stored in the US | Within 30 days; up to 2 years if flagged |
| Black Forest Labs | The faceless body photo and clothing photos in 4d | Try-on pictures | **US endpoint available (api.us.bfl.ai, "US regions only" per BFL); confirm in 33a which one we use** | May keep them permanently and use them to improve its models |
| Cloudflare | An encrypted copy of our server's database, which only we can unlock; also hosts this website | Backups, website | Cloudflare's network | Backups 30 days |

The table grows with the phases, as in the version table above. If we ever switch a feature to a different company, the app asks you again first (PRD 15.4).

**[Lawyer]** App Review 5.1.1(i) asks us to confirm third parties give "the same or equal protection" as this policy. That holds for each row because the policy states each company's own terms, but BFL's training right is the weak point (question 5). Also: whether any state law needs data processing agreements on file (Anthropic's commercial terms include one; Clerk's and BFL's **to confirm**).

### 6. What we never do

> No ads. No tracking across other apps or websites. No selling or renting your data. No data brokers. We don't use your photos or measurements to guess your size, score your body or train our own models. Payment card details never reach us.

### 7. How long we keep things

| Data | Where | Kept |
|---|---|---|
| Your closet, photos, looks, measurements | Your device, your iCloud | Until you delete them |
| Recently deleted pieces | Your device | 30 days |
| Styling answers (cache) | Convex | Up to 24 hours |
| Consent choices | Convex | While active, then the minimum record the law needs **[Lawyer]** |
| Usage limits and credit ledger | Convex | The usage window, plus a period the law needs **[Lawyer]**. These survive data deletion so limits can't be reset |
| Purchase records | Convex, Apple | Billing period **[Lawyer]** |
| Support notes | Convex | 90 days after closing |
| Security logs, no personal content | Convex | 30 days, then totals only |
| Deletion records (a private ID and a date) | Convex | As long as a backup could bring data back |
| Server backups | Cloudflare R2, encrypted | 30 days |

### 8. Your choices and how to delete

> - **Turn a feature off** in Privacy and terms. It stops future sending straight away. It doesn't delete what you already have in the app.
> - **Delete my data** removes everything from this iPhone and your private iCloud copy. If you have an account, **Delete account** also removes what our server holds and your Clerk account, and stops Sign in with Apple for this app. Deleting doesn't cancel a subscription; manage that in your Apple Account.
> - What we can't delete: copies Anthropic still holds for up to 30 days (or longer if flagged), photos Black Forest Labs keeps, backups until they expire within 30 days (we make sure deleted accounts don't come back from them), and records the law makes us keep.
> - **Ask us** for a copy of what we hold about you, to correct it, or to delete it, at support@codedetails.io. We may ask you to confirm from inside the app that the request is yours. We answer within **[Lawyer: the deadline that applies, 30 or 45 days]**.

**[Lawyer]** Which state rights apply at this size (CCPA and similar thresholds, Washington's My Health My Data Act, which has no size threshold) and whether a separate consumer health data policy page is needed (questions 2 and 6).

### 9. Children

> Nifty Outfit Nook is for adults 18 and over (PRD 24.2). It isn't meant for children, and we don't knowingly collect information from anyone under 13. If you think a child has sent us information, write to support@codedetails.io and we'll delete it.

From 24a, add the age confirmation the app asks for before cloud features. **[Lawyer]** The age method and state app store age laws (question 9).

### 10. Security

> Data is encrypted on your device and in transit. Our server keeps no photos and no copy of your closet. Keys to AI services live only on our server, never in the app. Backups are encrypted before they leave our server, with a key kept offline. If something goes wrong that affects your data, we'll tell you as the law requires.

**[Lawyer]** Breach notice duties (question 13).

### 11. Do Not Track and this website

> This website has no analytics, cookies, forms or trackers. Our host, Cloudflare, sees the usual request details like your IP address to serve the page. The app and site don't respond to browser Do Not Track signals because they don't track you in the first place.

California's CalOPPA asks a policy to say how it handles Do Not Track (**[Lawyer]** to confirm wording).

### 12. Changes and contact

> When this page changes, the date at the top changes and the change is listed below. If a change means a feature sends something new or to a new company, the app asks you again before sending it.
>
> Contact: support@codedetails.io. **[Postal address if the lawyer says it's required.]**

## Provider facts this draft relies on

Checked on the providers' own pages. Recheck when each phase starts.

| Fact | Source | Checked |
|---|---|---|
| Anthropic: no training on API content; deletion within 30 days; flagged content up to 2 years; inference geography global by default, `us` not on Haiku 4.5 | DATA_MAP.md processors | 18 October 2026 |
| Clerk: data "may be transferred, processed, and stored anywhere in the world" | https://clerk.com/legal/privacy | 18 October 2026 |
| BFL API Service Terms: "perpetual, irrevocable, worldwide" right to use inputs and outputs, may use them "to train and improve its artificial intelligence models"; last revised 4 August 2026 | https://bfl.ai/legal/flux-api-service-terms | 19 October 2026 |
| BFL privacy policy: BFL GmbH (Germany) and Black Forest Labs Inc (US); a training opt-out by email to privacy@blackforestlabs.ai with the subject "Training Opt Out"; services "not directed towards" under-18s; last revised 1 August 2026 | https://bfl.ai/legal/privacy-policy | 19 October 2026 |
| BFL endpoints: global `api.bfl.ai`, EU `api.eu.bfl.ai`, US `api.us.bfl.ai` ("US regions only"); delivery URLs expire after 10 minutes | https://help.bfl.ai/articles/9532536301-which-api-endpoint-should-i-use and https://docs.bfl.ai/api_integration/integration_guidelines | 19 October 2026 |
| Cloudflare R2 encrypts objects at rest with AES-256 | DATA_MAP.md processors | 18 October 2026 |

Still to confirm (from THREAT_MODEL's 19b list): Clerk's retention after a user is deleted and its sub-processors; Convex's region for our deployments, encryption at rest and log retention; BFL's sub-processors, whether its privacy-policy training opt-out covers API inputs given its Service Terms, and whether it deletes on request; the OpenAI backup's terms; whether Anthropic offers zero retention at this size. These go in DATA_MAP.md processors when answered.
