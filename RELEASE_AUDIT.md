# Release audit (Phase 35a)

22 October 2026, by an agent (Opus 5.5). Audited `develop` at `a411143` in `nifty-outfit-nook` (after #107 merged), the local backend repo, the live website, and the docs in this repo. Phase 35b (submission) is Jose's and wasn't touched.

**Result: not ready to submit.** The app itself is in good shape: the Release archive is clean, the privacy manifest matches the code, the permission strings are right and the consent screens name every AI provider. What stops a submission is everything around it: there is no way to sign in in a Release build, the backend isn't switched on, the privacy policy, terms and support pages don't exist yet, the paywall still shows placeholder allowances, and the legal, trademark and independent security reviews haven't happened. Those are listed under [Release blockers](#release-blockers), and the decisions behind them under [Decisions for Jose](#decisions-for-jose).

**Update, 22 October 2026 (later the same day, app PR `feature/release-signin-and-reports`, backend commit 750fa46):** blocker 1's app half and blocker 10 are built against the mocks: Sign in with Apple appears when she first uses a cloud feature, Profile has Sign in and Sign out, and Report a problem is on stylist looks and real try-on pictures. Both still need the live backend (blocker 2) to work in a Release build.

**Status words:** PASS (checked, holds), FAIL (checked, doesn't hold), BLOCKED (can't pass until Jose, a lawyer, a real device or an outside party does something), N/A.

Guideline quotes were checked against https://developer.apple.com/app-store/review/guidelines/ today (the page says it was last updated 16 October 2026). One change since the 19 October checklist: guideline 1.2 now names "AI content creation apps" among user-generated content apps.

## Release blockers

In order of how much they hold up.

1. **No sign-in in a Release build (2.1, 3.1.2(a)).** *Built against mocks on 22 October 2026 (app decision 0011): no sign-in at first launch; the sign-in sheet (Apple's own button, Not now, the privacy policy) appears only when she first starts cloud styling, a real try-on picture, a purchase or redeemed code, a support note or report, or Delete my account after her session ended, and what she started carries on once she's in; Profile has "Signed in with Apple" with Sign out, or "Sign in". It calls the 24a `AccountService`, so it is Clerk's sign-in once Clerk is configured; a Release build without the settings still says "Not available right now" and has no fake. Left: the Clerk instance and live backend (blocker 2), a device run of the real Apple sheet, and Jose's call on where sign-in should live and the 18+ line (below). The rest of this item is the audit as written.* The only "Sign in with Apple" buttons are in the Debug labs (`Features/Debug/GatewayLab`, `LimitsLab`); every other `signIn()` call goes to the fake gateway inside `#if DEBUG` (`AppStylist.swift:49`, `AppTryOn.swift:98`, `AppGateway.swift:150`). So even with the backend configured, a Release build can't reach the cloud stylist, try-on pictures, credit claims, the support queue or the server half of account deletion. The paywall would sell a subscription whose main benefits she can't use. Needs the sign-in design Jose was asked for in 24a (question 5), then a small app phase.
2. **The backend isn't switched on (2.1).** The archive's `NookClerkPublishableKey` and `NookAPIBaseURL` are empty, so Release fails closed and the cloud features say "Not available right now" (as 32b L9 intended). App Review needs live services for every flow plus a demo account. This needs Jose's setup: Clerk production instance, Convex production deployment and plan, App Attest on the App ID (and the agent-built Apple check, not built yet), the Anthropic and BFL keys, `NOOK_APPSTORE_MODE apple`, the account-deletion secrets, and the R2 backups.
3. **The privacy policy, terms and support pages don't exist (5.1.1(i), 3.1.2(c), 1.5, 2.1).** `https://niftyoutfitnook.pages.dev/privacy`, `/terms` and `/support` all return 200, but each serves the "Coming soon" landing page: the same bytes as `/nonexistent-xyz` (checked with curl and an MD5 of each). The app links to all three (Privacy and terms, the paywall's Terms of use and Privacy policy, Help's "Still stuck?"), and App Store Connect needs the privacy and support URLs. 2.1 asks for "fully functional URLs" and no "empty websites".
4. **Placeholder allowances on the paywall (3.1.2(c), 2.1).** `StylingAllowances.placeholder` (10 Style Me a day, 40 swaps and questions a day, 30 try-on pictures a month; `Models/Services/Subscriptions.swift:355`) is what the paywall says the subscription includes, and `CreditPacks.pictures` (10 and 30 pictures; `Models/Services/Credits.swift:18`) names the packs. Prices are never typed in the app: they come from StoreKit's `displayPrice`, so they'll be right once the products exist in App Store Connect. See [Prices and placeholders](#5-content) for exactly what must come from where.
5. **The privacy manifest declares no collected data.** `NSPrivacyCollectedDataTypes` is empty, and `scripts/check-archive.sh` (line 103) fails the build if it isn't. That's correct for today's Release build, which sends nothing, but wrong the moment the backend is switched on. Fill it in, and relax the check, in the same change that switches the backend on, with the label answers below.
6. **Legal review not done (5.1.1(ix), 5.1.2, 5.1.3).** No lawyer has seen `compliance/LEGAL_QUESTIONS.md` yet. The "before launch" questions decide who publishes the app (an individual or a company), whether the BFL terms make try-on a "sale" or "sharing" of data, the age rating, the terms of use and the subscription wording.
7. **Trademark search not done.** The 13 October name check was a quick screening only (Progress log, 13 October).
8. **Independent security review or penetration test not done**, and the OWASP MASVS and ASVS checklists haven't been walked item by item (`SECURITY_TEST_REPORT.md`, "Not covered"; `SECURITY_STANDARD.md` §11).
9. **Real-device checks that App Review answers rest on:** VoiceOver on a phone (device checklist 2.6), real account deletion (3.7), StoreKit sandbox purchases and offer codes (3.8, 3.9), App Attest (3.2), and the iPad keyboard shortcuts on a real iPad (plan, Phase 35a).
10. **No way to report a bad AI result (1.2, 1.1).** *Built against mocks on 22 October 2026: Report a problem under a cloud stylist look (the look or its why line) and on a real try-on picture's page, with four reasons, an optional note, Include the picture (try-on only, off every time) and Hide. It goes to 24d's support queue as `kind: "aiReport"` with the result's and the action's IDs; the backend adds the provider and model from its own records, has its own rate limit (5 in a burst, 20 a day) and deletes reports with the account (backend commit 750fa46, 7 new tests). Ask stylist answers can be reported once that screen exists (it's still the stand-in). Left: the live backend (blocker 2). The rest of this item is the audit as written.* Guideline 1.2 now lists "AI content creation apps" with user-generated content apps, which need a way to report offensive content. Try-on output goes through BFL's own moderation (`safety_tolerance: 2`; a moderated result fails cleanly, backend `convex/tryon/bfl.ts`) and the stylist's text is validated on the server, but "Report styling problem" (PRD 15.5) isn't built. Everything the AI makes is private to her, which lowers the risk, but a small report button on try-on pictures and stylist results is the safe answer before review.

## 1. App Review Guidelines

Walked against `compliance/APP_REVIEW_CHECKLIST.md` and the current app.

| Item | Status | Evidence |
|---|---|---|
| 2.1 No fakes, sample data or debug code in Release | PASS | `scripts/check-release.sh` on the archive's device binary: "no catalog, benchmark, snapshot-testing code, fake backend, sample data code, sample photos or secrets". #101's fail-closed wiring holds: `AppGateway.allowsFakes` is false outside Debug and `FakeGateway` isn't in the binary. |
| 2.1 Completeness overall | FAIL | Blockers 1 to 4: no sign-in, no live backend, placeholder web pages, placeholder allowances. (22 October, later: sign-in is built against mocks; it works in Release once blocker 2 closes.) |
| 3.1.1 In-app purchase only; credits don't expire; restore | PASS (built), BLOCKED (live) | StoreKit 2 only, no other checkout; packs are consumables credited by the server and never expire (PRD 14.4); Restore purchases and Redeem code on the paywall. Live products don't exist in App Store Connect yet (device checklist 3.8, 3.9). |
| 3.1.2(a) Ongoing value | BLOCKED | The value is the cloud stylist and try-on pictures, unreachable until blockers 1 and 2 close. |
| 3.1.2(c) and Schedule 2 terms before subscribing | PASS (wording), FAIL (links, numbers) | The paywall shows StoreKit's price and period, the free month only when eligible, the first charge date, auto-renewal, how to cancel, Restore, Manage, Terms and Privacy links (UI test `StylingAccessTests`). The links lead to a "Coming soon" page and the allowances are placeholders. |
| 4.2 Minimum functionality | PASS | A native closet, outfit builder, suitcases, laundry, saved looks, on-device Quick ideas, weather, backups, iPad layouts. Far beyond a wrapped website. |
| 4.8 Login services | PASS (built) | Sign in with Apple is the only sign-in, with Apple's own button (22 October, later); Clerk is a back end, not a login button. No other login exists. |
| 5.1.1(i) Privacy policy linked in the app and in App Store Connect | FAIL | Linked in the app, but the page doesn't exist (blocker 3). |
| 5.1.1(ii), (iv) Permission and no pressure | PASS | Camera and location each have the app's own explainer first with a way out, and every refusal has a manual path (`compliance/PERMISSIONS.md`, as built in 22a and 29). |
| 5.1.1(v) Account deletion in the app | PASS (app), BLOCKED (server) | Privacy and terms, Delete my account, with the "doesn't cancel your subscription" note and Manage subscription (UI test `AccountDeletionTests`; new audit test below). The server's Clerk deletion and Apple token revocation are mocked until Jose's setup (device checklist 3.7). |
| 5.1.1(ix) Sensitive data submitted by a legal entity | BLOCKED | Lawyer question 1. |
| 5.1.2(i) Third-party AI disclosed with explicit permission | PASS | Separate named consents: Anthropic (`StylistConsent.swift`: what's sent, never photos, name, measurements or location; 30-day retention, 2 years if flagged; processing outside the US) and Black Forest Labs (`TryOnConsent.swift`, the exact 33c sentence, plus "We can't delete copies Black Forest Labs keeps"). Each is withdrawable in Privacy and terms. |
| 5.1.2(ii) No repurposing | PASS | BFL's training use is in the first consent, not added later; the server checks the consent version. |
| 5.1.3(ii) No health information in iCloud | PASS today, BLOCKED for sync | The app writes nothing to iCloud: CloudKit sync isn't built and there is no iCloud entitlement. Whether measurements and weight count as health data is lawyer question 3, and decides whether they may ever sync. |
| Body measurements sent anywhere | PASS | Not sent (D14, interim answer "none"). The styling request carries `comfort` (fitted, comfortable or relaxed: a fit preference, not a health fact) but no measurements, weight or height (`APIV1+Stylist.swift`). |
| AI-generated content | PASS (built against mocks, 22 October, later), was FAIL (report button) | Every try-on picture carries the "Simulated" badge and VoiceOver reads "Simulated try-on picture of ..."; BFL moderation is on; the stylist output is validated. Missing: a report action (blocker 10). |
| 5.1.4 Kids | BLOCKED | Not a kids app; 18+ in the terms. The age check before cloud features and the age rating answer wait on lawyer question 9. |
| 5.1.5 Location | PASS | Approximate only (`NSLocationDefaultAccuracyReduced` true), while in use, only after she turns on Use my location; a typed city needs no permission; coordinates rounded and never sent to our backend. |
| 1.5 Developer contact | FAIL | Help's "Still stuck?" opens the support URL, which is the "Coming soon" page. |
| 2.3 Accurate metadata | BLOCKED | Store text and screenshots are 35b. |
| 5.6.1 Review prompt | N/A | No review prompt in the app yet; if one is added it must be Apple's. |

## 2. Privacy manifest, labels, permissions, export

**Required-reason APIs: PASS.** Scanned every Swift file in the app and packages, excluding tests.

| Category | Found in Release code | Manifest |
|---|---|---|
| User defaults | App state, weather settings, consents, notifications card and the subscription cache, each in the app's own suite or `.standard` | `CA92.1` declared |
| Disk space | `volumeAvailableCapacityForImportantUsageKey` in `MigrationCoordinator.swift:354` and `BackupArchive.swift:270`, to refuse work when space is low (she sees the message) | `E174.1` declared |
| File timestamps | None. Sizes are read with `fileSizeKey`, which isn't on Apple's list. `attributesOfItem` appears only in `Services/Debug/DeviceFileChecks.swift`, inside `#if DEBUG` | Not needed |
| System boot time, active keyboards | None | Not needed |

The archive carries the app's manifest and Clerk's own (`Clerk_ClerkKit.bundle/PrivacyInfo.xcprivacy`, which declares `UserDefaults` `CA92.1` and no collected data). `ClerkKitUI`, Nuke and PhoneNumberKit aren't in the app.

**Collected data: FAIL at the moment the backend goes on** (blocker 5). Today's empty list is honest for a build that sends nothing. When the backend is switched on, the manifest and App Store Connect should both say, from `DATA_MAP.md` and the code:

| Data type | Linked | Purposes | Sent where | Status |
|---|---|---|---|---|
| User ID | Yes | App Functionality | Clerk (Apple `sub`, Clerk ID), Convex (`usr_` principal) | Declare |
| Device ID | Yes | App Functionality | App Attest key ID and public key in Convex | Declare (cautious; still "to confirm") |
| Email address | Yes | App Functionality | Only the optional reply address on a support note; Clerk may hold Apple's relay address (D6) | Declare |
| Customer support | Yes | App Functionality | Support notes and screenshots in Convex | Declare |
| Other user content | Yes | App Functionality | Styling requests through Convex to Anthropic; 24-hour result cache | Declare |
| Photos or videos | Yes | App Functionality, Other | Faceless body photo and garment photos to BFL, who may keep and train on them | Declare |
| Purchase history | Yes | App Functionality | Entitlements and credit ledger in Convex | Declare |
| Crash data, performance data | Yes | App Functionality | Only when she ticks "Share crash and speed details" on a note | Declare, pending Jose's 31 answer on "linked" |
| Health | | | Not sent (D14 interim) | Don't declare unless D14 changes |
| Location, product interaction, search history | | | Not sent; no analytics; Find One not built | Don't declare |

Clerk is a processor here: whatever Clerk's SDK sends to Clerk (session and device details) counts as our collection and is covered by User ID; check Clerk's own disclosure when the production instance is made. Apple's WeatherKit, Maps city search, StoreKit and Sign in with Apple are Apple's collection and aren't declared. Cloudflare R2 holds encrypted copies of Convex data that's already declared, so it adds no data type, but the privacy policy must name it as a processor. Tracking is "No" for every type.

**Labels draft versus reality: PASS with two corrections for `compliance/APP_STORE_PRIVACY_LABELS.md`.** Its "How the label will read" section assumes measurements are sent (Health); under D14's interim answer they aren't, so Health drops out. And it predates the 32a change in #107: a try-on poll now sends only the action ID, so nothing new is collected there.

**Purpose strings: PASS.** The archive's Info.plist has exactly two, both matching `compliance/PERMISSIONS.md` word for word (the archive check enforces it): camera ("Take photos of your clothes to add them to your closet, and take your try-on photo if you set one up.") and location when in use ("Your rough location gets the forecast, so outfit ideas suit the weather. It's used only for the forecast and isn't saved."). No photo library key is needed: picking uses `PhotosPicker`, paste uses `PasteButton`, and the only share sheet carries text (`ShareSheet.swift`). Notifications need no key.

**Export compliance: PASS, with one open question.** `ITSAppUsesNonExemptEncryption` is `NO` in the archive. The app uses only Apple's encryption (HTTPS, CryptoKit and Apple Archive for backups), which Apple treats as exempt from documentation. Still open from 21b: whether to file the US year-end self-classification report.

## 3. Release build

| Check | Status | Evidence |
|---|---|---|
| Unsigned Release archive (`scripts/check-archive.sh`) | PASS | Archived in 222 s with Xcode 27.1 (iOS 27.1 SDK), exit 0. Info.plist, manifest and entitlements as expected. |
| `scripts/check-release.sh` on the archive's binary | PASS | Run inside the archive check and again on its own: no debug screens or switches, fakes, sample photos, snapshot testing or secrets. |
| No localhost or test addresses | PASS | No `localhost` or `127.0.0.1` in the binary; the only addresses in Release code are the website, WeatherKit's attribution page and our own gateway (configured, empty today). |
| Size | PASS | App 26 MB, binary 15 MB, dSYM 53 MB. |
| Symbols and bitcode | PASS | `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` in Release, and a dSYM was made. Bitcode no longer exists in current Xcode, so there's nothing to set. `ENABLE_NS_ASSERTIONS = NO`, whole-module `-O`, dead-code stripping on. |
| Version | Note | 0.1.0 (1). The release branch in 35b sets 1.0.0 and a fresh build number (`scripts/bump-build.sh`). |
| Compiler warnings | Note | 10 Swift concurrency warnings in the app target: `AppDiagnostics.install(into:)` and `AppGateway.installSupport(into:)` are called from a non-isolated context in `NiftyOutfitNookApp.swift:272` and `:285`, and `AppDiagnostics.log` from a Sendable closure. Harmless today, errors under the Swift 6 language mode. Worth a small cleanup. |

## 4. Accessibility

| Check | Status | Evidence |
|---|---|---|
| UI batch on the hosted runners (`scripts/run-ui-batch.sh`) | PASS, with one part cut short | Run 39830667919 on `a411143`. `ui-audit-and-settings` (every audit walk at the default size, the Profile and Closet walks at AX5, Settings, Styling access) passed in 34 min. `ui-add-and-saved` (the other AX5 walks, onboarding, tours, Backups, Saved Looks) passed in 35 min. `ui-rest` ran 44 tests with no failure, then hit its 40-minute limit; it had to build for itself (11.5 min) because the Mac runner's build was queued. Its 5 unrun tests (`WeatherTests.testTypeACityInsteadFromTheExplanation` and the four `YourLooksTests`) passed on the 35a iPhone 12 simulator. No UI test failed anywhere. |
| Audit coverage of Stage B screens | PASS (fixed) | The existing walks covered onboarding, Home, Closet, Style Me, Saved Looks, Profile and the settings screens, but no Stage B screen. #108 adds walks for the try-on photo sheet, Styling access, Backups and Delete my account. All six runs (three walks, two sizes) pass on a fresh "35a iPhone 12" simulator (iOS 26.5): no issue beyond the app-wide exclusions in `AuditExclusions`. |
| Contrast | PASS | Every text and status colour pair is checked against WCAG ratios in light and dark by `ContrastRequirement` and `ContrastTests` in `DesignSystemTests`, which run on every PR; the audits also check contrast on screen. |
| Reduce Motion | PASS | 19 views read `accessibilityReduceMotion`, including the room canvas, tours, toasts, buttons, the AI job banner, the try-on camera and the privacy walkthrough (a plain fade, 33c). The six animated views that don't read it only cross-fade or change opacity briefly (`TryOnSheet`, `NameSignView`, `HomeBanner`, `TourOverlay`, `GarmentPicture`, and `MayaView`, whose sleepy Zs stay still through an `animates` flag its parent sets from Reduce Motion). |
| VoiceOver on a real phone | BLOCKED | Device checklist 2.6. The audits can't move VoiceOver or hear it. |
| iPad keyboard shortcuts | BLOCKED | Needs a real iPad with a keyboard (plan, Phase 35a). |
| Still not audited | Note | The stylist and try-on consent sheets, the privacy walkthrough, the try-on camera, Weather settings and the restore flow. Each has its own UI test, but no accessibility audit. |

## 5. Content

**Placeholder copy, TODOs, debug strings: PASS.** No "lorem", `TODO`, `FIXME` or debug text in Release sources or string catalogs. Every "placeholder" hit is a code comment, a text field's prompt ("Type a city", "Your first name") or the drawn stand-in for a piece with no photo.

**Prices and placeholders: what must come from where before submission.**

| What the user sees | Where it comes from now | Where it must come from |
|---|---|---|
| Subscription price and period, the free month | StoreKit (`Product.displayPrice`, the introductory offer); never typed in the app. The US$9.99 and free month exist only in `NiftyOutfitNookTests/NiftyOutfitNook.storekit` (Xcode testing) | App Store Connect: product `com.jsayram.niftyoutfitnook.styling.monthly` in its subscription group, with the price, storefronts and the introductory offer (`docs/payments.md` steps 1 to 14) |
| Picture pack prices | StoreKit `displayPrice` | App Store Connect: `com.jsayram.niftyoutfitnook.pictures.small` and `.pictures.large` (steps 15 to 20) |
| Complimentary unlock | Offer codes only, never sold in the app | App Store Connect: `com.jsayram.niftyoutfitnook.styling.complimentary`, its price and the codes |
| "10 Style Me a day, 40 swaps and questions a day, 30 try-on pictures a month" on the paywall and in Help | `StylingAllowances.placeholder` in `Models/Services/Subscriptions.swift:355` | Jose's D12 numbers, set in the app and in the backend's allowances together, so the paywall promises what the server enforces |
| "10 pictures" and "30 pictures" pack names | `CreditPacks.pictures` in `Models/Services/Credits.swift:18` | Jose's pack sizes, in the app, the backend's `CREDIT_PACKS` and the App Store Connect display names together |
| Try-on cost reservation | Backend placeholder US$0.10 a picture | BFL's real price, with D12 |
| Support page address | `NOOK_SUPPORT_URL`, defaulting to `https://niftyoutfitnook.pages.dev/support` (`FeedbackService.swift:110`) | The published support page (35b) |

## 6. What was fixed here

One safe fix, merged: **jsayram/nifty-outfit-nook#108** (`a5d764d` on `develop`). It adds the Stage B accessibility audits above, lists them in `docs/accessibility-audit.md`, and runs their AX5 versions in `ui-add-and-saved` so `ui-rest` doesn't grow past its limit. No app code changed. CI's fast gate passed on the PR; the new tests themselves were run locally (the next UI batch runs them on CI).

Not fixed here, because each needs a decision or is more than trivial:

- Everything under [Release blockers](#release-blockers).
- The Swift concurrency warnings in the app target (section 3): a small change to app start-up, better as its own PR with a test run.
- `ui-rest` running close to its 40-minute limit whenever the hosted runners have to build for themselves. Either raise its `timeout-minutes` or move a class to another part. A CI change worth its own PR.
- `compliance/APP_STORE_PRIVACY_LABELS.md`: the two corrections in section 2 (Health drops out under D14's interim answer; the try-on poll no longer resends photos). Left for whoever fills in the manifest, so the two change together.
- Accessibility audits for the consent sheets, the privacy walkthrough, the try-on camera, Weather settings and restore.

## Decisions for Jose

Every open question from the board's "Waiting on Jose" cards and the Progress log, deduplicated and sorted. The numbers in brackets are where each was asked.

### Release blockers

1. **Where sign-in lives** (24a Q5). Built on 22 October as the least intrusive standard pattern (asked when a cloud feature is first used, plus Profile's row; app decision 0011). Keep it, or move it (onboarding, an account screen)? Also: add the "I'm 18 or older" line from IN_APP_PRIVACY_TEXT to the sheet now, or after the lawyer (question 9)?
2. **Switch the backend on** (24a, 24b, 24c, 27a, 30c, 33a). Clerk production instance (Apple only, the `convex` JWT template), Convex production deployment and plan (Professional suggested at about 2.5 million calls a month for 1,000 users, 32a), App Attest on the App ID, the Anthropic key, the BFL key and region (`api.bfl.ai` or `api.us.bfl.ai`, 33a), the account-deletion secrets, `NOOK_APPSTORE_MODE apple` and the notification URLs (`docs/payments.md` steps 21 to 26).
3. **Publish the privacy policy, terms and support pages**, and pick the support email shown there (19b, 24d Q4). Also: Apple's standard EULA or our own terms (30a).
4. **D12: production allowances, spending ceilings and the real image cost** (24b). The paywall copy changes with them.
5. **Prices and products** (30a, 30b): the monthly price and storefronts, the free month, Family Sharing, the subscription group name, pack sizes and prices, the unlock's App Store price. Then the App Store Connect steps.
6. **Book the lawyer** for the "before launch" questions in `compliance/LEGAL_QUESTIONS.md`, starting with who publishes the app (an individual or an LLC, 5.1.1(ix)), whether giving BFL its rights is a "sale" or "sharing", the age rating and age check, and the auto-renewal wording.
7. **Trademark search** for "Nifty Outfit Nook" and "Outfit Nook".
8. **Independent security review or penetration test**, and the MASVS and ASVS walk before it.
9. **D13: allowances across an account deletion** (24c). Key them on a protected hash of Apple's stable user ID (suggested), or accept that deleting and re-creating an account resets them. Also confirm Delete my account skipping App Attest is fine.
10. **D11: Clerk's Keychain setting** (24a). A written exception (suggested), wait for Clerk, or our own Sign in with Apple. SECURITY_STANDARD needs a signed exception before Clerk ships.
11. **A report button for AI results** (guideline 1.2). Built on 22 October. Two calls: Include the picture sends the picture with her face to the support ticket when she ticks it (keep, or mask the face first?); and Hide removes the result (a picture goes as Delete picture does, with Undo). OK?
12. **The privacy label answers** (31 Q4, 24a): Diagnostics as linked (suggested yes), App Attest as Device ID (suggested yes), and re-read the D1 approval for BFL before launch.
13. **Export compliance** (21b Q2): file the year-end self-classification report yourself, or ask the lawyer.
14. **Real-device runs** that App Review answers rest on: VoiceOver (2.6), account deletion (3.7), sandbox purchases and offer codes (3.8, 3.9), App Attest (3.2), the iPad keyboard (35a).

### Before outside testers

15. **Measurements to the stylist (D14)**: confirm "none are sent" for good, or ask the lawyer first (27a Q2).
16. **Body data in iCloud** (20b, lawyer question 3): keep measurements and weight out of any sync until answered.
17. **BFL's training opt-out**: ask `privacy@blackforestlabs.ai` in writing whether it covers API inputs (compliance README item 3).
18. **Re-read the accepted risks** D1, D4 and D8 before anyone but Lily uses real data.
19. **L11: backup passphrase minimum** (32b): keep 12 characters, or require 14 to 16 plus a nudge to "Make one for me" (suggested).
20. **L8: Convex not checking `nbf`** (32b): accept as a residual risk with the tripwire test (suggested).
21. **Credits and refunds** (30b, 30c): keep or forfeit unspent credits at account deletion; collect a refunded-but-spent pack from the next one, or never; Lily's plan override and budget (US$5 placeholder).
22. **Consumption requests and OCSP** (30c): answer Apple's consumption requests (needs an App Store Server API key) or not; add certificate revocation checks or not.
23. **"Get styling access" prompt inside Style Me** (30c Q5), so a refusal doesn't read "This account can't do that".
24. **Support channel** (24d): keep the share sheet when signed out or ask her to sign in; 180 days for unclosed tickets; replies by email only or also in the app.
25. **Alerts** (31): email, push or both for cost and error alerts; the spike thresholds.
26. **Consent wording** (27a Q5): the Anthropic consent mentions fabric, which isn't sent. Reword (suggested).
27. **Try-on details** (33a, 33b, 33c): keep a lost result fetchable for longer than 2 minutes; whether the consent line itself should mention the server's 30 minutes; front camera first.
28. **Backend dependencies** (24a, 27a): TypeScript as a dev-only tool; `@anthropic-ai/sdk` or plain fetch.
29. **Backups design 0004's nine defaults** (20b, 21b): approve or change; whether "Add what's missing" should show conflicting copies.
30. **Server backup setup** (25b): the R2 bucket with a 30-day lock, the offline key pair, the deploy key, the schedule, the first backup and drill.
31. **Account housekeeping** (25a, account setup): two-factor on every account, a fine-grained GitHub token for agents, rotate the BFL and OpenAI test keys by 16 January 2027, provider spend limits, DMARC for codedetails.io.
32. **TestFlight**: the first upload, Lily's App Store Connect user and the internal group (deferred 20 October until the app is stable).
33. **Lily's reviews**: the camera explainer, Backups, possible matches, the privacy walkthrough (33c checkpoint), and the cutout go/no-go on her iPhone 12.
34. **WeatherKit** (29): turn it on for the App ID and set `NOOK_WEATHERKIT = YES`; Apple Maps city search or a built-in list; move the weather credit off the dog's feet.

### Later

35. **iCloud sync** (20b, 21b): the container, test accounts and the sync layer itself.
36. **Push when the app is closed** (27c): the APNs key and capability.
37. **Ask stylist screen** (27a, 27c) and an on-device Apple stylist for iPhone 15 Pro and newer (28).
38. **Small product calls**: Quick ideas before cloud consent (28), the generic colour rules staying public (28), allowances in Settings (24b), a free-month reminder (30a), the Home "ready" dot and the 10-minute job limit (27c), try-on thumbnails, Undo-expiry deletion and the space reserves (22b), "Remember this name" after a normal result and name history (7.6), the 35-day retention of finished paid actions (32a), opt-in analytics and on-device counters (31), "Describe my photos" (22a), HEIC (22a, 22b).
39. **Repo housekeeping**: delete the untracked `website/` folder in this repo, local commit signing, merge commits for promotions, the unused Google Cloud project, and the Mac's Time Machine and Spotlight exclusions for build folders.

Already decided, in case they look open: D1 to D10 (19 October), the 21a and 21c questions, paste in Add a piece, L9 and L10 (fixed in #101), the corrected "our server keeps neither" wording (33b), and the try-on status call (#107, merged today).

## How this was checked

- `scripts/check-archive.sh` and `scripts/check-release.sh` on `a411143`, on Jose's Mac.
- Source scans of `NiftyOutfitNook/` and `Packages/NookKit/Sources` (tests excluded) for the required-reason APIs, network addresses, sign-in calls, prices, placeholders and permission use.
- `curl` against the website's `/`, `/privacy`, `/terms`, `/support` and a made-up path.
- The UI batch on GitHub's hosted runners, and the new audit tests on a "35a iPhone 12" simulator (iOS 26.5), deleted afterwards.
- The Progress log, the board's 21 "Waiting on Jose" cards, and the compliance, security, load and device documents listed in the task. A Sonnet helper compiled the open questions from the Progress log; each was checked against the board.
