# App Review checklist

Started in Phase 19b, 19 October 2026. A living checklist against the App Store Review Guidelines that apply to this app. Each phase that touches an item updates its status. Phase 35a walks the whole list against the release build, and 35b's checkpoint needs every row closed.

Guideline numbers and quotes were checked on https://developer.apple.com/app-store/review/guidelines/ on 19 October 2026. The guidelines change; recheck at 35a. Where a number couldn't be confirmed it says so.

**Status:** Done, Partly (some of it built), Open (not started), N/A (doesn't apply unless the plan changes).

## Privacy (5.1)

| # | Guideline | What it asks | How we meet it | Closes in | Status |
|---|---|---|---|---|---|
| P1 | 5.1.1(i) | A privacy policy linked in App Store Connect and in the app, saying what's collected, how and why, that third parties protect data as the policy says, retention and deletion, and how to withdraw consent or ask for deletion | [PRIVACY_POLICY_OUTLINE.md](PRIVACY_POLICY_OUTLINE.md); the app already links /privacy from Privacy and terms | Draft 19b, live version 0 when Jose approves, full 35b | Partly |
| P2 | 5.1.1(i), "same or equal protection" | Third parties must protect data as well as the policy says | Each processor's terms are stated in the policy. **Risk:** Black Forest Labs may keep and train on try-on photos. Disclosed and consented, but a reviewer could still question it. Mitigations: the face never leaves the phone, the consent names BFL and training, "See what was sent", BFL's training opt-out if it covers API inputs (to confirm) | 33a | Open |
| P3 | 5.1.1(ii) | Permission for data collection, an easy way to withdraw it, purpose strings that fully describe the use | Per-feature consent switches in Privacy and terms, each withdrawable; purpose strings in [PERMISSIONS.md](PERMISSIONS.md) | 22a, 24a, 27a, 29, 31, 33a | Open |
| P4 | 5.1.1(iii) | Ask only for data relevant to the core function, collect only what the task needs | Minimum context per request (DATA_MAP), picker instead of library access, approximate location, no name from Apple | Every phase | Partly |
| P5 | 5.1.1(iv) | Respect permission settings; don't manipulate or force consent | Pre-prompts with Not now; every refusal has a manual path; no feature locked behind a permission it doesn't need | 22a, 29, 33b | Open |
| P6 | 5.1.1(v) | If there are no significant account features, let people use the app without a login | The closet works fully without an account; sign-in only for cloud features | 24a | Partly (no login today) |
| P7 | 5.1.1(v) | Apps that support account creation must offer account deletion in the app | Delete account in Privacy and terms deletes Convex rows, the Clerk user and revokes the Sign in with Apple token; shows pending steps | 24c | Open |
| P8 | 5.1.1(v) (Apple's account deletion guidance) | Say what deletion removes and how long it takes; deletion isn't hidden behind support | Delete my data already lists what goes, two-step confirm; 24c adds server parts and the "doesn't cancel your subscription" note | 24c | Partly |
| P9 | 5.1.1(ix) | Apps that need sensitive user information should be submitted by a legal entity providing the service, not an individual | **Question for the lawyer** (body measurements, weight, body photos). Decide before the App Store Connect seller identity is fixed for public release | Before 35b | Open |
| P10 | 5.1.2(i) | Clearly disclose where personal data is shared with third parties, **including third-party AI**, and get explicit permission first | Named-recipient consent before the first Anthropic request (27a) and the first BFL request (33a); separate from Photos access and from each other; receipts checked on the device and the server | 27a, 33a | Open. 27a built against a fake: consent sheet and switch, version checked by the server (`consent_required`) |
| P11 | 5.1.2(ii) (to confirm exact sub-number) | Data collected for one purpose isn't repurposed without further consent | BFL's training use is disclosed up front in the try-on consent, not added later. Any new use or new recipient asks again (PRD 15.4) | 33a | Open |
| P12 | 5.1.3(ii) | Apps may not store personal health information in iCloud | **Question for the lawyer** whether weight, body measurements or comfort count. If they do, keep them out of CloudKit sync | 20b (design), lawyer before outside testers | Open |
| P13 | 5.1.4 | Kids category and children's data | Not a kids app; adults 18+ (PRD 24.2). Age confirmation before cloud features | 24a | Open |
| P14 | 5.1.5 | Location only when relevant, with notice and consent before collecting, sending or using it | Approximate, while in use, weather only, manual fallback; coordinates never leave for our server | 29 | Open |
| P15 | Privacy labels (App Store Connect) | Answers match what the app does, including SDKs | [APP_STORE_PRIVACY_LABELS.md](APP_STORE_PRIVACY_LABELS.md) | Draft 19b, check 35a | Partly |
| P16 | Privacy manifest and required-reason APIs | `PrivacyInfo.xcprivacy` declares every required-reason API, with approved reasons | Correct today (`UserDefaults` `CA92.1`); plan in [PRIVACY_MANIFEST.md](PRIVACY_MANIFEST.md) | Each phase; check 35a | Done for today |
| P17 | Third-party SDK manifests and signatures | Listed SDKs need manifests and signatures | Only `clerk-ios` planned; check its manifest and whether it's on Apple's list | 24a | Open |

## Accounts and sign-in

| # | Guideline | What it asks | How we meet it | Closes in | Status |
|---|---|---|---|---|---|
| A1 | 4.8 | Apps using a third-party or social login must also offer an equivalent private option (Sign in with Apple qualifies) | Sign in with Apple is the only sign-in. Clerk is a back-end provider, not a login button. If any other login is ever added, Sign in with Apple stays | 24a | Open |
| A2 | Sign in with Apple token revocation (Apple's account deletion guidance) | Revoke tokens when the account is deleted | Revoke through Apple's REST endpoint, or confirm Clerk does it (THREAT_MODEL F12) | 24c | Open |

## Payments (3.1)

| # | Guideline | What it asks | How we meet it | Closes in | Status |
|---|---|---|---|---|---|
| M1 | 3.1.1 | Digital features and credits through In-App Purchase | StoreKit 2 subscription, non-consumable complimentary unlock, consumable credit packs; no other checkout | 30a, 30b | Open |
| M2 | 3.1.1 | Purchased credits may not expire; restore restorable purchases | Credits never expire and work after a subscription ends (PRD 14.4); Restore purchases | 30b, 30c | Open |
| M3 | 3.1.2(a) | Subscriptions give ongoing value | The stylist and image allowance renew monthly; the free core stays free | 30a | Open |
| M4 | 3.1.2(c) and Schedule 2 | Before asking someone to subscribe, describe what they get for the price; Schedule 2 requirements (title, length, price, links to the privacy policy and terms in the app and the metadata) | Paywall per PRD 14.1: name, allowance, localized price, period, auto-renew, trial terms, Restore, Manage, Redeem, Terms and Privacy links | 30a | Open |
| M5 | Offer codes | Complimentary unlock through Apple offer codes, explained to App Review | Review notes describe the unlock and Lily's sponsored policy (PRD 24.1) | 30b, 35b | Open |
| M6 | Account and subscription | Deleting the account doesn't cancel billing; tell people | Note on Delete my data and Delete account, with Manage subscription | 24c, 30a | Open |

## AI and images of people

| # | Guideline | What it asks | How we meet it | Closes in | Status |
|---|---|---|---|---|---|
| I1 | 5.1.2(i) | Consent before sharing with third-party AI | See P10 | 27a, 33a | Open |
| I2 | No specific guideline found for generated images of real people | The check on 19 October found no guideline on making images of a real person's likeness. Related: 1.1 (objectionable content), 5.2.1 (others' rights), the age rating questions on AI and user content | Only her own photo (SECURITY_STANDARD 7); terms forbid photos of others and of minors; input and output moderation (THREAT_MODEL F8); every picture labelled as AI-made ("Simulated" today); no face sent | 33a | Open |
| I3 | 1.1 | No offensive or harmful content | Body-neutral stylist policy, typed validation, Report styling problem (PRD 15.5) | 27a | Open |
| I4 | 2.3, accurate metadata | No claims of exact fit or real-photo accuracy | Store text and screenshots say try-on pictures are simulations | 35b | Open |

## Metadata, content and review access

| # | Guideline | What it asks | How we meet it | Closes in | Status |
|---|---|---|---|---|---|
| R1 | 1.5 | An easy way to contact the developer in the app and at the Support URL | Support page ([SUPPORT_PAGE_OUTLINE.md](SUPPORT_PAGE_OUTLINE.md)) linked from Help; email on the website only (STACK.md) | 24d, 35b | Open |
| R2 | 1.2 | User-generated content needs filtering, reporting, blocking and contact | Only if 24d builds the public board (PRD 22.1) | 24d | N/A unless built |
| R3 | 2.1 | Complete app, working backend during review, demo access | Review notes, demo account, live services for every flow (PRD 24.1) | 35b | Open |
| R4 | 2.3 | Metadata, including privacy information, screenshots and previews, matches the app | Screenshots of the real app with fictional data; labels checked against the build | 35a, 35b | Open |
| R5 | 2.3.6 | Answer the age rating questions honestly | Answer for the shipped features; apply the 18+ override if the terms set 18+ (PRD 24.2) | 35a | Open |
| R6 | 2.5.1 | Public APIs only | Apple frameworks only today; recheck each phase | Every phase | Partly |
| R7 | 5.6.1 | App Store reviews only through Apple's prompt | Native prompt, no incentives, no filtering (PRD 24.4) | 35b | Open |
| R8 | Export compliance | `ITSAppUsesNonExemptEncryption` answered correctly | `NO` today; recheck when 20b adds CryptoKit encryption for exports | 20b | Open |
| R9 | EU Digital Services Act trader declaration | Required in App Store Connect even for a US-only launch | Declare; publish contact details only if trading in the EU | 35b | Open |
| R10 | iPad (2.4.1) | iPhone apps should run on iPad | Universal app built in Stage A | 15a, 15b | Done |

## Phase closing map

| Phase | Rows it closes or moves |
|---|---|
| 19b | P1 (draft), P15 and P16 (draft), this checklist |
| 20b | P12 (design), R8 |
| 22a | P3, P5 (camera) |
| 24a | P3, P6, P13, P17, A1 |
| 24c | P7, P8, A2, M6 (note) |
| 24d | R1, R2 |
| 27a | P3, P10, I1, I3 |
| 29 | P3, P14 |
| 30a to 30c | M1 to M6 |
| 31 | P3 (analytics, if built) |
| 33a to 33c | P2, P3, P10, P11, I1, I2 |
| 35a | P9, P15, P16, R4, R5, full recheck |
| 35b | P1 (final), M5, R1, R3, R7, R9 |
