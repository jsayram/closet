# Threat model

Phase 0c, written 13 October 2026. This is the first threat model for Nifty Outfit Nook, covering the whole system as planned. It goes with [DATA_MAP.md](DATA_MAP.md) (what data exists and where it goes) and [ACCOUNT_INVENTORY.md](ACCOUNT_INVENTORY.md) (the accounts that can touch the app). The controls come from [SECURITY_STANDARD.md](SECURITY_STANDARD.md) and PRD sections 11.6 and 15. Phase 19a revisits this model before real data, photos, the backend and payments arrive.

The standard doesn't prescribe a method. This model uses STRIDE (spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege) for each part of the system, and adds harms that aren't attacks, such as data loss or a hurtful AI answer, because those matter as much for Lily.

Both repos are public, so this file stays at the level of a normal public threat model. It names risks and controls, not account details, recovery methods or anything an attacker could use directly.

**Likelihood** and **impact** are High, Medium or Low, judged for a small app with one main user now and public users later. Stage A has no networking code and no accounts. Its only storage across launches is an app-only `UserDefaults` suite holding lowest-tier app state flags (see [DATA_MAP.md](DATA_MAP.md)), and the website's policy pages open in an in-app Safari view. So most of these risks only become live in Stage B. The phase column is where the control gets built and tested.

## Top risks

These are the ones Jose should look at first, roughly in order.

| ID | Risk | Who it hurts | Likelihood | Impact | Main controls | Phases |
|---|---|---|---|---|---|---|
| R1 | Personal details about Lily, some Sensitive under the standard, are already in the public planning repo and in the public review notes | Lily | High (already public) | Medium | **Accepted by Jose, 7 October 2026:** he's fine with Lily's details being in this public repo. Going forward, new docs leave out body and health details where they aren't needed, and here.now notes are pulled into the repo only as needed. The app repo and backend never hold her real data | Accepted |
| R2 | Someone calls the AI gateway outside the app (cloned app, script, stolen token) and runs up the AI bill | Jose | High once the gateway is public | High | App Attest, short-lived tokens, server-side entitlement, atomic usage ledger with cost reserved before every call, per-user, per-device and global limits, provider hard caps and budget alerts, kill switch per paid feature | 24a, 24b, 25a, 25b, 30c |
| R3 | Takeover of one of Jose's accounts (GitHub, Apple Developer, Cloudflare, backend host, AI provider) leading to a malicious build, stolen keys, a defaced website or a large bill | Lily, Jose, public users | Medium | High | Two-factor authentication on every account (passkeys or hardware keys where offered), password manager, offline recovery codes, least-privilege API keys, account inventory with rotation dates | 0c, 1b, 25a |
| R4 | Sensitive data (measurements, comfort, notes, photos) goes to an AI provider beyond what Lily agreed to, or the provider keeps or trains on it | Lily | Medium | High | Named-recipient consent receipts checked on device and server, minimum context with no identity, no photos on the text route, provider terms recorded per provider, a recipient change needs new consent | 19b, 24a, 27a, 33 |
| R5 | Try-on photos of Lily, or generated pictures of her, leak or are misused, or someone uploads a photo of another person | Lily, third parties | Low until Phase 33 | High | Phase 33 stays gated on PRD 9.2; separate image permission; moderation on inputs and outputs; private, short-lived transfers; no photos in logs; app switcher snapshot hidden | 14a, 33 |
| R6 | A secret (AI key, service key, signing material) is committed to one of the public repos or printed in CI logs | Jose | Medium | High | No secrets in the app by design; push protection and secret scanning; gitleaks in pre-commit and CI over full history; secrets only in protected environments; rotation runbook, since deleting a leaked key from git doesn't make it safe | 1b, 25a, 25b |
| R7 | Lily loses her closet: a failed migration, a lost phone with sync off, a bad restore or a sync conflict | Lily | Medium | High | Persistence spike with migration and interruption tests, migrations from day one, export and restore, optional private iCloud, recovery snapshot, tests for corruption | 20a, 20b, 21a, 21b |
| R8 | One user reads or changes another user's data on the backend (broken object-level authorization) | Public users | Medium once public | High | Authorization on every request, Row Level Security with default deny if Postgres, cross-user tests in CI, no trust in client-supplied IDs | 24c, 32b |
| R9 | The stylist says something hurtful about Lily's body, gives sizing as fact, or acts on instructions hidden in notes or web pages | Lily | Medium | Medium | Body-neutral policy on the server, typed response validation against product rules, user text treated as data, no tools on stylist calls, Report Styling Problem, evaluation on her saved scenarios | 27a, 28, 34 |
| R10 | Entitlement or credit fraud: a faked purchase, a replayed webhook, a refund that keeps access | Jose | Medium | Medium | Server verifies signed transactions and JWS notifications, idempotent handlers, server is the authority for credits, refund and revocation tests | 30a, 30b, 30c |

## By component

### Lily's device and the app

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Someone with her unlocked phone sees measurements, try-on pictures or notes, including in the app switcher | Information disclosure | Medium | Medium | Hide sensitive screens in the app switcher snapshot; no Sensitive data on the general pasteboard | 14a, 21a, 33 |
| A lost or stolen locked phone exposes app files | Information disclosure | Low | High | Data Protection class `complete` for Sensitive and Personal files, Keychain `WhenUnlockedThisDeviceOnly` for tokens, caches without Sensitive data | 1a, 21a, 22b, 24a |
| Personal data ends up in logs, crash reports or analytics | Information disclosure | Medium | Medium | `os.Logger` with privacy redaction, no personal data in release logs, analytics allowlist, crash tool vetted before adoption | Every phase, 31 |
| Photo metadata (location, device) leaks through an upload or an export | Information disclosure | Medium | Medium | Strip EXIF and location before anything leaves the device; system photo picker so the app never needs full library access | 22a, 22b |
| A crafted image or import file crashes the app or fills the disk (decompression bomb, path traversal) | Denial of service, tampering | Low | Medium | Size and pixel limits before decoding, validated imports, temporary files cleaned up | 21b, 22a, 22b |
| The app binary is decompiled or its traffic inspected to find keys or the API | Information disclosure | High | Low if no secrets ship | No secrets in the binary, ATS with no exceptions, server enforces everything; pinning evaluated in the backend phase | 1a, 24a, 26 |
| Permission prompts ask for more than needed (full photo library, precise or background location) | Information disclosure | Low | Medium | Ask only when a feature is first used, approximate while-in-use location, PhotosUI picker, clear reason strings | 22a, 29, 19b |
| An export archive or shared collage reaches the wrong person | Information disclosure | Medium | Medium | Encrypted export (see DATA_MAP open points), exact-content preview before sharing, personal fields off by default | 20b, 21b |
| A bad migration or interrupted write destroys data | Denial of service (data loss) | Medium | High | See R7 | 20a, 21a, 21b |

### Her private iCloud

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| A sync conflict or deletion on one device wipes data on another | Tampering, data loss | Medium | High | Tested conflict rules, deletion markers so data isn't resurrected or lost, local-only fallback | 20b, 21b |
| Her Apple account is compromised and her synced closet is read | Information disclosure | Low | High | Out of the app's control. Use CloudKit encrypted fields for Sensitive data; tell her what Advanced Data Protection adds | 20b |

### Backend gateway and identity

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Scripted or cloned clients call paid endpoints (R2) | Spoofing, denial of service | High | High | App Attest with server-side validation, a bounded fallback for devices that can't attest, short-lived tokens | 24a |
| A legitimate user or a bug floods the AI (retry loop, many devices) | Denial of service (cost) | Medium | High | Per-user, per-device and global rate and concurrency limits, bounded retries with backoff, cost reserved before each attempt, fail closed when the ledger is down | 24b, 26 |
| Stolen session or refresh token is reused | Spoofing | Low | Medium | Short-lived access tokens, refresh token rotation, revocation on sign-out and deletion | 24a |
| Oversized or malformed requests exhaust the gateway or reach the model | Denial of service, tampering | Medium | Medium | Typed schema with size limits (64 KiB, 2,000-character notes), unknown fields rejected, token budgets | 24a, 27b |
| Cross-user access to results, consent, tickets or ledger rows (R8) | Elevation of privilege, information disclosure | Medium | High | Authorization on every request, default deny, cross-user CI tests | 24c, 32b |
| Raw prompts or responses kept in gateway logs or traces | Information disclosure | Medium | High | No payload logging anywhere, 24-hour encrypted result cache scoped to one user, audit log without personal data | 24a, 27a |
| Account deletion leaves data behind | Information disclosure | Medium | Medium | In-app deletion that removes server data, tested; backups expire and deletions are reapplied after a restore | 24c, 20b |
| An admin action or config change (model, price, budget) can't be traced | Repudiation | Low | Medium | Audit log for security events and admin and pricing changes | 24a, 25b |
| Dev or staging data or keys mix with production | Information disclosure | Low | High | Separate projects, databases, keys and provider accounts per environment | 23b, 25a |
| Backend host compromise or misconfiguration (public bucket, open database) | Information disclosure | Low | High | Least-privilege roles, no admin credentials in code, encryption at rest, independent security review before launch | 23b, 25a, 32b, 35a |

### AI providers

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Provider keeps or trains on Lily's data (R4) | Information disclosure | Medium | High | Choose providers with no training on our data and the shortest retention; recorded per provider and rechecked on change; disclosed in the consent text | 23b, 27a, 19b |
| Provider key is leaked or abused (R6) | Spoofing | Medium | High | Key only in the server secret store, provider hard caps and budget alerts, rotation runbook | 25a, 25b |
| Prompt injection through garment notes, imported data or retailer pages | Tampering, elevation of privilege | Medium | Medium | User text and web content passed as data, no tools on stylist calls, typed response validation, ranking step has no browsing tools | 27a, 34 |
| Model returns invalid, unsafe or hurtful output (R9) | Tampering | Medium | Medium | Schema and product-rule validation before the app sees it, body-neutral policy, report action | 27a, 28 |
| Provider outage or price change | Denial of service | Medium | Low | Server-configured fallback, kill switch, on-device model on eligible phones, honest error states | 26, 27a, 28 |
| Image provider generates a likeness of someone who didn't consent (R5) | Information disclosure | Low | High | Phase 33 gates, input and output moderation, photo of the user only | 33 |

### Payments and App Store

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Client claims an entitlement or credit balance it doesn't have (R10) | Tampering, elevation of privilege | Medium | Medium | Server verifies transactions and holds entitlement and credit state; the client only displays it | 30c |
| Webhook replayed or forged | Spoofing, tampering | Low | Medium | JWS verification on App Store Server Notifications, idempotent handlers | 30c |
| Refund or revocation doesn't remove access or credits | Elevation of privilege | Medium | Low | Refund, expiry, revocation and family sharing tests | 30c |
| Complimentary offer codes leak and get redeemed by strangers | Elevation of privilege | Low | Low | Codes treated as secrets until handed over; small batches; expiry dates | 30b |
| App Review rejection over privacy, payments or account deletion | Denial of service (launch) | Medium | Medium | Privacy manifest and labels that match behavior, StoreKit 2 only, in-app deletion, App Review checklist | 19b, 30a, 35a |

### Weather

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Precise location sent beyond WeatherKit or stored | Information disclosure | Low | Medium | Approximate location, conditions (not coordinates) in AI requests, no shared cache of personal locations | 29 |
| Weather quota exhausted by retries or many users | Denial of service | Low | Low | 30-minute session snapshot, coalesced lookups, one automatic retry, quota alerts, manual weather fallback | 29 |

### Feedback, support and analytics

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Support reports or tester feedback include her photos or closet without her meaning to | Information disclosure | Medium | Medium | Nothing attached automatically; she sees exactly what is sent | 14b, 18 |
| Public board spam, abuse or personal data in posts | Tampering, information disclosure | Medium | Medium | Moderation before anything is public, length limits, no photos, pseudonymous alias | No phase yet (see DATA_MAP) |
| Analytics joined to billing or wardrobe records | Information disclosure | Low | Medium | Off by default, allowlisted events, resettable ID never joined to other records, 30-day raw retention | 31 |
| Unauthenticated floods fill the feedback or analytics stores | Denial of service | Medium | Low | Request caps, batch size limits, the ability to close intake temporarily | 24b, 31 |

### Repos, CI and supply chain

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Direct push or force push to `main` or `develop` slips in bad code | Tampering | Medium | High | Rulesets with PRs and CI required, no force pushes, signed commits, administrators included | 1b |
| A compromised GitHub Action or dependency steals tokens or alters the build | Tampering | Low | High | Actions pinned to commit SHAs, read-only `GITHUB_TOKEN`, approval for outside contributors' workflows, exact version pins, each dependency approved in writing, Dependabot | 1b |
| Business logic (prompts, fit rules) leaks into the public app repo | Information disclosure | Medium | Medium | Rules kept in the private backend repo; swap ranking on the phone uses plain matching only; CODEOWNERS and PR checklist | 1b, 11, 27a |
| Fixtures or snapshots in the public app repo contain real photos of Lily | Information disclosure | Low | High | Synthetic fixtures only; real photos never committed | 3, 22a |

### Website and review site

| Threat | STRIDE | Likelihood | Impact | Control | Phases |
|---|---|---|---|---|---|
| Website defaced or redirected through a Cloudflare account takeover | Tampering | Low | Medium | Two-factor authentication on Cloudflare, scoped API tokens, static site with a first-party script only, no analytics or forms, and a strict Content Security Policy | 0c, 19b |
| A lookalike site or app copies the name to phish users | Spoofing | Low | Low | The App Store listing and website link to each other; privacy and support pages on the real site | 35b |
| Anyone with the review link reads or spams Lily's review notes | Information disclosure, tampering | Medium | Low | Link is shared only with Lily; notes are copied into the repo only as needed; edits and deletes need the owner key | Now |

## What this model does not cover yet

- Concrete flows for persistence, photo intake, the backend stack and payments. Phase 19a adds them once those choices exist.
- Find One (Phase 34) and the try-on feature (Phase 33) beyond the top-level risks. Each gets its own model before it is enabled.
- Legal risk (state health-data laws, GDPR). That goes to the lawyer in Phase 19b and 35a.
