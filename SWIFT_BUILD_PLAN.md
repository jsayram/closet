# Swift build plan

Drafted 7 October 2026, revised the same day. This is the phase list for building Nifty Outfit Nook as a real iOS app from the room-direction mockups. It's a working plan and not part of the PRD. Where the PRD already sets a rule (security, cost protection, persistence, image handling), the PRD wins and this plan points to it.

There is no deadline. The project has two goals of equal weight: an app Lily can rely on every day, and a proven playbook ([IOS_APP_PLAYBOOK.md](IOS_APP_PLAYBOOK.md)) for building reliable, compliant, safe and cost-effective iOS apps in the future. Security, cost control and data safety are designed in from the start, and every phase should leave behind something reusable as well as working code.

## How we work

- **One short phase at a time.** Each phase fits in one sitting and ends with something Jose can run or read. Nothing starts on the next phase until he says go.
- **Every phase has a checkpoint.** Jose decides there whether the direction is right. If it isn't, we fix it before building on top of it.
- **Structure before speed.** Small files, clear module boundaries, protocols at every service edge, and tests for logic. Nothing gets built on a shortcut we plan to "clean up later".
- **The mockups are the visual reference.** Where they disagree with the decisions list in [the mockup README](prototypes/RoomDirectionMockups/README.md), the list wins. Each UI phase starts by checking for newer approved Lily feedback.
- **The old prototype is a reference, not a base.** [LilyStyleMockup](prototypes/LilyStyleMockup) has useful logic (models, mock stylist, flat-lay layout, iPad helpers). We bring pieces over on purpose, one at a time, and review each one as new code.
- **No commits unless Jose asks.** After each phase, a dated entry goes in the progress log at the bottom, and anything reusable goes in [IOS_APP_PLAYBOOK.md](IOS_APP_PLAYBOOK.md).
- **Security is not negotiable.** [SECURITY_STANDARD.md](SECURITY_STANDARD.md) is a requirement for every phase, not a later clean-up. This app holds sensitive personal data, so no corners get cut. Any exception needs Jose's written approval in the progress log, with a reason and a review date.

## Repositories and branching

Decided 7 October 2026.

- **`closet` (this repo)** is the design and planning repo: PRD, research, mockups, Lily's review site, the old prototype, this plan, the playbook, the security standard and agent files. It uses `main` plus the occasional branch. `closet/mock` merges into `main` after Lily's review.
- **The app repo, `nifty-outfit-nook` (public, https://github.com/jsayram/nifty-outfit-nook)** holds the shipping iOS app (Xcode project, packages, tests, CI and the art assets the app uses) and the app's website in `website/` (static Cloudflare Pages site: landing page now, privacy policy and support pages before launch). It has its own README and a short AGENTS.md that points back to `closet` for the spec.
- **The backend repo (private, decided in Phase 23)** holds the gateway, prompts, fit rules and infrastructure config. Prompts and business rules never go in the app repo.

The app and backend repos use Git Flow:

| Branch | Role |
|---|---|
| `main` | Release-ready only. Tagged with the app version (`v1.0.0`) when a build ships to the App Store. |
| `develop` | Where approved phases land. TestFlight builds come from here. |
| `feature/<phase>-<name>` | One per phase, for example `feature/02a-design-tokens`. Branched off `develop`, merged back by PR after the checkpoint. |
| `release/<version>` | Cut from `develop` to prepare an App Store version (final fixes, version and build numbers, store listing). Merged into `main` and back into `develop`. |
| `hotfix/<name>` | Off `main` for urgent fixes after launch. Merged into `main` and `develop`. |

Rules:
- Nothing is pushed directly to `main` or `develop`. Everything goes through a PR with CI passing.
- Phase branches are not stacked. Each one starts from the latest `develop`.
- Before 1.0, `develop` is promoted to `main` only at milestones (end of Phase 3, before Phase 18, after 21, after 30, and at release). Every promotion runs the full test suite and the security review gate.
- Dev, staging and production are build configurations and backend environments, not branches.

## Definition of done (every phase)

A phase isn't finished until all of these hold, or Jose has agreed in the log to an exception:

1. **No regressions.** The whole test suite passes, not only the new tests.
2. **Tests where they make sense.** Unit tests for logic and rules. Integration tests where services meet (store, network, purchases). UI tests for the main flows. Snapshot tests for key screens once the design system exists.
3. **Mock data covers every case.** Empty, one item, typical, and very large data sets (a closet of 2,000+ garments), plus failure and offline cases. Every screen has a defined empty, loading and error state.
4. **Accessibility.** Dynamic Type up to the largest size, VoiceOver labels and order, Reduce Motion, dark appearance, and sufficient contrast.
5. **iPhone and iPad.** Checked on a small iPhone, a large iPhone and iPad in both orientations.
6. **Security and privacy.** The PR's security checklist is complete for every section of [SECURITY_STANDARD.md](SECURITY_STANDARD.md) the phase touches. New data is classified and added to the data map. No secrets in the app or repo, no personal data in logs, URLs or analytics, and only the permissions the phase needs. Security tests are added alongside the feature.
7. **Performance.** No main-thread stalls, and images are downsampled and cached. Lists stay smooth with the large data set.
8. **Apple guidelines.** Anything that touches App Review rules (payments, privacy, permissions, account deletion, AI content) is checked against the current App Store Review Guidelines and Human Interface Guidelines.
9. **Documented.** Progress log entry, plus any reusable lesson in the playbook.

## Stage A: the app with sample data

Everything here runs on mock data behind protocols. No accounts, network or real storage yet. The goal is an app Lily can hold and react to.

### Phase 0a: Technical decisions (no app code)

- New production project rather than evolving the prototype.
- iOS floor (iOS 17 covers on-device subject lifting and runs on Lily's iPhone 12; check her current version).
- Code layout: an app target plus local Swift packages (likely DesignSystem, Models, Fixtures, Features).
- Swift 6 language mode with strict concurrency, Swift Testing, XCUITest, a snapshot-testing approach, and a lint/format setup.
- Rules for third-party dependencies: what's allowed, and how each one gets vetted.

**Checkpoint:** Jose approves a one-page decisions note.

### Phase 0b: PRD amendment draft

- Amendment proposal for the room-direction changes: Home tab, On Me moved to results, Saved Looks tabs, sticker bundles, favorite suitcases.
- Lily's approved review changes from `prototypes/RoomDirectionMockups/feedback/signoff-2026-10-13.md`: warm neutral palette, "Preferences" instead of "Mode", one outfit in three versions (Simple, Dressed up, Something new) with "Try a different outfit", Saved tab instead of Earlier and no Shuffle, Swap for every piece change with the editor only for "Make your own look", plus the smaller items (weather row, swap "Show 3 more", filters, suitcase icons, last worn and repeat setting, fit wording, removing a piece, "Thinking of buying?"). The mockups weren't updated for these, so the sheet is the spec.

**Checkpoint:** Jose approves or edits the amendment.

### Phase 0c: Data classification and threat model

- Classify every kind of data the PRD describes using the tiers in the security standard.
- First data map and threat model for the whole system: what could go wrong for Lily, for Jose and for the services, and which controls cover each risk.
- Account inventory: every service account (GitHub, Apple Developer, Cloudflare, here.now and later the backend and AI providers), who owns it, and whether two-factor authentication is on.

**Checkpoint:** Jose reviews the top risks and confirms two-factor authentication on every account.

Outputs: [DATA_MAP.md](DATA_MAP.md), [THREAT_MODEL.md](THREAT_MODEL.md) and [ACCOUNT_INVENTORY.md](ACCOUNT_INVENTORY.md).

### Phase 1a: Project skeleton

- Xcode project generated from `project.yml`, the local packages, build and test scripts, and separate Debug/Release configurations.
- Secure defaults from the first commit: App Transport Security with no exceptions, Data Protection set, no third-party dependencies yet, and an empty privacy manifest ready to fill.
- App launches to the tab bar with placeholder tabs.

**Checkpoint:** it runs on the simulator and Jose reviews the folder structure.

### Phase 1b: Repo and CI hardening

- Create `develop`, then rulesets on `main` and `develop` (PRs and CI required, signed commits, no force pushes, administrators included).
- Secret scanning with push protection, gitleaks in a pre-commit hook and in CI, Dependabot alerts and security updates.
- CI choice (Xcode Cloud or GitHub Actions) with actions pinned to commit SHAs and a read-only token by default.
- CODEOWNERS, a PR template with the security checklist, and the all-rights-reserved README notice.

**Checkpoint:** Jose tries to push to `develop` directly and to commit a fake key; both get blocked.

### Phase 2a: Design tokens

- Color, type, spacing, corner and shadow tokens from `css/room.css` and `css/soft.css`, with dark mode and Dynamic Type built in.

**Checkpoint:** token values reviewed against the mockups.

### Phase 2b: Components and catalog

- Buttons, plum pill chips, soft rows and cards, search field, bottom sheet, and the empty, loading and error state views.
- A debug-only catalog screen showing every component in light, dark and the largest text size, with the first snapshot tests.

**Checkpoint:** catalog side by side with `screens/results.html`. Nothing should look boxy.

### Phase 3: Models and mock data

- Garment, Outfit (look), Suitcase, Profile, StyleRequest and laundry state.
- An in-memory store behind protocols, with fixture sets: empty, the 21 demo garments, and a generated large closet.
- Unit tests for the model rules.

**Checkpoint:** Jose reads the models and the store protocol before any screen depends on them.

### Phase 4: Home room, phone portrait

- Room art as vector assets, the name sign as live text, and tappable furniture leading to stub screens.

**Checkpoint:** Home on an iPhone simulator next to `screens/home.html`.

### Phase 5a: Home weather and life

- Weather windows, hamper states, and Maya with her z's (still under Reduce Motion).

**Checkpoint:** each window and hamper state.

### Phase 5b: Home appearance and size variants

- Dark appearance, the large-text banner layout (`home-ax.html`), and sideways phone.

**Checkpoint:** each variant with the accessibility settings switched on.

### Phase 6: Closet browsing

- Small wardrobe header, search, filter chips, Suitcases and Laundry entries, and the garment grid.

**Checkpoint:** browse and filter the empty, demo and large closets.

### Phase 7a: Garment detail

- Viewing a garment and its details.

**Checkpoint:** detail screens for several fixture garments.

### Phase 7b: Adding and editing garments

- Adding or editing by photo or by words, with the photo step stubbed. Draft recovery if the app is closed mid-edit.

**Checkpoint:** add and edit a garment end to end, including abandoning and resuming a draft.

### Phase 8a: Cutout feasibility

- On-device subject lifting on real clothing photos. Measure speed, memory and quality on Lily's iPhone 12.

**Checkpoint:** go or no-go on cutouts as the main garment look.

### Phase 8b: Sticker styling and fallback

- The thick white sticker outline, and the rounded-tile fallback for photos without a clean cutout.

**Checkpoint:** a set of real garments as stickers and fallbacks.

### Phase 9: Look bundles

- The sticker bundle view (tilted, overlapping, no tiles or hangers), used wherever a look appears.

**Checkpoint:** bundles of 2 to 6 pieces at phone and iPad sizes.

### Phase 10a: Style Me request

- Request form and option sheets.

**Checkpoint:** build several requests and check what gets produced.

### Phase 10b: Style Me results

- Results as one outfit in three versions with Today and Saved tabs and Try a different outfit, no Shuffle ([PRD amendment](PRD_Amendment_Room_Direction.md) LR-05a, LR-05b, LR-06), and the partial, insufficient, generating, failed and offline states, all driven by a mock stylist.
- Try it on and Ask stylist entries on results.

**Checkpoint:** a full styling run with each state forced.

### Phase 11: Swap and editor

- Swapping a piece and editing a look.

**Checkpoint:** swap and edit flows.

### Phase 12a: Saved Looks, Looks tab

- Looks tab, search, and look detail.

**Checkpoint:** save a look from results and find it again.

### Phase 12b: Saved Looks, Pictures tab

- Pictures tab and picture detail with the simulated placeholder, linked back to its look.

**Checkpoint:** move between pictures and their looks.

### Phase 13: Suitcases and Laundry

- Three favorite suitcases with See all, suitcase detail, and opt-in laundry tracking.

**Checkpoint:** pack a suitcase and mark items dirty and clean.

### Phase 14a: Profile essentials

- Name on your sign, fit and weight, and the try-on photo sheet.

**Checkpoint:** changing the name updates the sign; fit values save and validate.

### Phase 14b: Remaining settings

- Accessibility, privacy, help and feedback screens, and account/data deletion entry points (required by Apple once accounts exist).

**Checkpoint:** every Profile row works.

### Phase 15a: iPad, Home and Closet

- The wide Home room, the Closet sidebar and wide grid, and Split View.

**Checkpoint:** both screens on iPad in both orientations and in Split View.

### Phase 15b: iPad, Style Me and Saved

- Results and Saved Looks with side-by-side detail and centered panes.

**Checkpoint:** every main screen on iPad.

### Phase 16a: Coach-mark system and Home tour

- One reusable tour system (spotlight, card, focus, Skip, Escape) and the Home tour.

**Checkpoint:** Home tour with VoiceOver and large text.

### Phase 16b: Remaining tours

- The other screen tours, first-use tracking, and replay from Profile.

**Checkpoint:** fresh install, then replaying tours.

### Phase 17: Onboarding

- First-run flow into the Home room.

**Checkpoint:** delete, reinstall, and go from first launch to the first look.

### Phase 18: Lily's first TestFlight

- Internal TestFlight build with sample data only.

**Checkpoint:** Lily uses it on her phone. Her notes go through the usual sign-off before anything changes.

## Stage B: making it real

These phases swap mock data for real services behind the same protocols. Mocks stay in place for tests and previews. Several phases depend on choices PRD section 11.4 still lists as open, so they start with a decision step and may be split further when we reach them.

Bullets marked *(from Stage A)* are work a Stage A phase deferred; the app repo's `docs/` explain each one. Bullets and phases marked *(new)* had no home in the plan until the Stage A audit on 16 October 2026.

- *(new)* Every screen added in Stage B gets its tour when it's built, from the mockups' tour pages where one exists (PRD 7.8, FR-73; app `docs/tours.md`).

### Phase 19a: Threat model for real data

- Revisit the Phase 0c threat model now that real storage, photos, a backend and payments are about to arrive. Add the concrete data flows and the controls each one needs.

**Checkpoint:** Jose reviews the updated data map and the top risks.

### Phase 19b: Privacy and compliance baseline

- Draft privacy manifest, App Store privacy labels, the permission list with reasons, the privacy policy outline, and an App Review checklist we keep updating until release.
- List the legal questions for a lawyer, for example whether weight and measurements count as health data under US state law.
- The privacy policy, terms and support page get published on the app's website (https://niftyoutfitnook.pages.dev/, Cloudflare Pages). App Store Connect requires a privacy policy URL and a support URL.
- *(from Stage A)* The real wording of Privacy and terms in the app. Its permission and consent switches don't come all at once: each one arrives with the feature it controls (19b, 24a, 27a, 29, 31, 33), because a switch with nothing behind it controls nothing (app `docs/settings.md`).

**Checkpoint:** Jose approves the baseline and decides when to get the legal review.

### Phase 20a: Persistence spike

- The PRD 11.7 recovery prototype: versioned fixtures, images, migrations, interrupted migrations, and two offline devices.
- *(from Stage A)* Release builds stop shipping sample data: the `-fixtures` launch argument and the fixture sets become Debug-only, checked in the release build the way the catalog is (Phase 3 audit note).

**Checkpoint:** go or no-go on SwiftData.

### Phase 20b: Backup and recovery design

- Local backups, optional private iCloud sync, export and restore, and what happens after a failed migration or a lost device.
- *(from Stage A)* The export format. PRD 15.4 describes an unencrypted archive, but SECURITY_STANDARD.md section 4 requires exports that leave the app to be encrypted. The standard wins unless Jose approves an exception in writing.
- *(from Stage A)* Which fields use CloudKit encrypted values, and what Lily gets with and without Advanced Data Protection (DATA_MAP.md, open points).
- *(from Stage A)* Delete my data also removes her private iCloud copy (app `docs/settings.md`).

**Checkpoint:** Jose approves the recovery design.

### Phase 21a: Real local storage

- Wire the chosen store in behind the existing protocols, with migrations from day one.
- *(from Stage A)* Durable `DraftStore` and `LookDraftStore` with complete file protection, and rows for both kinds of draft in DATA_MAP.md. Stage A keeps drafts in memory only.
- *(from Stage A)* Move into the real store: the profile (her name on the sign included), the remembered source and occasion, the unsent feedback note, and the onboarding and tour flags that sit in a `UserDefaults` suite today (app `docs/profile.md`, `suitcases-and-laundry.md`, `settings.md`, `onboarding.md`).
- *(from Stage A)* "Delete permanently now" in Recently deleted, with a preview of what gets purged (PRD 7.4, app `docs/garment-detail.md`).
- *(from Stage A)* The real stores pass the same store contract test suites as the in-memory ones.

**Checkpoint:** data survives relaunches and a schema change.

### Phase 21b: Export, restore and recovery tests

- Export and restore working, plus automated tests for corruption, failed migrations and restore.

**Checkpoint:** wipe the app and restore a closet from a backup.

### Phase 21c: Closet and Saved Looks extras *(new)*

- Search aliases ("Other names") and a sub-kind such as Cardigan or Blazer on garments, which the Add a piece mockup shows but the model doesn't have yet (PRD 7.6, app `docs/add-a-piece.md`).
- Favorites and collections for saved looks (RD-08, FR-13, FR-49) and Archive for garments (LR-16, PRD 7.4). Stage A left all three out. Ask Lily first whether she wants them.
- Search over earlier unsaved results as well as saved looks (LR-06.4). Stage A keeps them but only saved looks are searchable. *(Done in 21c as a separate group under typed search, then replaced on 21 October 2026 by a Saved | All switch: see the Progress log.)*

**Checkpoint:** Jose and Lily try each one on real data, and a schema change carries them across.

### Phase 22a: Photo intake

- PhotosUI and the camera, with permission flows.
- *(from Stage A)* Strip EXIF and location from stored originals. The photo picker includes location by default (app `docs/cutout-feasibility.md`, SECURITY_STANDARD.md section 4).
- *(from Stage A)* A real try-on photo in Profile through the system picker, with its metadata stripped (app `docs/profile.md`).
- *(from Stage A)* Decide on the optional garment-understanding upload: its own named, consented processor, or leave it out (DATA_MAP.md, requests to services).
- *(from Stage A)* The cutout go/no-go happens here. Simulators can't run Vision's subject lifting (on the iPhone 12 simulator it fails with "Could not create inference context"), and no real iPhone 12 was available in Stage A. Run `-cutout-bench` on Lily's iPhone 12 with her real photos for speed, memory and quality, then set the thresholds before real photos depend on them. Any real iPhone Jose has can give an earlier quality-only read.

**Checkpoint:** add real garments from the library and the camera.

### Phase 22b: Image storage and caching

- Originals next to cutouts, thumbnails, the image cache, and disk-space handling.
- *(from Stage A)* Stored files for generated try-on pictures, removed when she deletes a picture (app `docs/try-on-pictures.md`).
- *(from Stage A)* Deleting a garment for good removes the pictures that depend on it, where the purge rules say so (PRD 9.2.4). Today a purged piece is only left out of the drawing.

**Checkpoint:** a large real-photo closet stays smooth and the storage footprint is reasonable.

### Phase 23a: Backend options *(done 18 October 2026: Convex, see STACK.md)*

- Compare hosting options, including Supabase, for the gateway, auth, the usage ledger and feedback, against the PRD's requirements.

**Checkpoint:** Jose reads the comparison.

### Phase 23b: Backend decision *(done 18 October 2026: Convex HTTP actions + Clerk)*

- Choose the stack, the environments (dev, staging, production) and the costs at expected usage.

**Checkpoint:** Jose approves the stack and the monthly cost estimate.

### Phase 24a: Gateway and identity *(built against mocks 21 October 2026; the switch to Clerk and Convex waits on Jose)*

- Gateway skeleton, user identity (Sign in with Apple where needed), device attestation, and request validation.
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** an authenticated request round-trips; bad requests are rejected.

### Phase 24b: Limits and cost protection *(built against mocks 21 October 2026; production limits and Apple's attestation check wait on Jose)*

- Rate limits, the atomic usage ledger, cost reservations before any paid call, and a kill switch (PRD 11.6).

**Checkpoint:** limits hold under deliberate abuse in a test.

### Phase 24c: Authorization and account deletion *(built against mocks 21 October 2026; the real Clerk and Apple calls wait on Jose)*

- Row-level access rules with default deny, tests proving one user can't read another's data, and in-app account deletion that removes server data.
- *(from Stage A)* Sign in with Apple token revocation when the account is deleted, and the note on Delete my data that deleting doesn't cancel a subscription (app `docs/settings.md`).

**Checkpoint:** a cross-user access test fails as it should, and a deleted account leaves nothing behind.

### Phase 24d: Support and feedback channel *(built against mocks 22 October 2026; the real services and the support page wait on Jose; the board and email program are left for later)*

- The private support queue that Send feedback reaches, replacing the share sheet, with an optional reply address.
- The public feedback board (PRD 22) and the optional, separately opted-in email program (FR-44, PRD 22.4), or a written decision to leave them for later.
- The project's support email in ACCOUNT_INVENTORY.md and on the website's support page (DATA_MAP.md open points, app `docs/settings.md`).

**Checkpoint:** a note sent from the app reaches the queue and Jose can answer it.

### Phase 25a: Secrets and credentials

- AI provider keys only on the server, separate secrets per environment, rotation schedule, and least-privilege access for every service account.

**Checkpoint:** a secrets review; nothing sensitive in the app bundle or any repo.

### Phase 25b: Incident response *(built and rehearsed locally 22 October 2026; the R2 bucket, the offline key and the schedule wait on Jose)*

- Written plan for a leaked key, a data exposure or a cost spike: who acts, how every key gets rotated, how paid features get switched off, and how users are told.
- *(new)* The daily backup job from STACK.md: a scheduled `npx convex export`, encrypted with a key kept offline, 30 days kept in a Cloudflare R2 bucket no agent can reach, and a monthly restore into a test deployment.

**Checkpoint:** a rehearsal. Rotate one key and flip one kill switch, following the plan.

### Phase 26: Network resilience

- Timeouts, cancellation, bounded retries, offline mode, and handling of 401, 429 and 5xx responses (PRD 11.7).

**Checkpoint:** every failure case forced against a test server.

### Phase 27a: Cloud stylist *(built against a fake provider 21 October 2026; the Anthropic key and the quality check on Lily's scenarios wait on Jose)*

- Provider adapter on the server, typed response validation, and server-side model configuration.
- *(from Stage A)* The "From your history" check before paid inference (FR-58), and the "why" line under results, written by the stylist (app `docs/your-looks.md`).
- *(from Stage A)* Labelled ideas for an empty closet (PRD 8.1). Pending Jose's decision: Stage A offers Add a piece instead (app `docs/style-me.md`).
- *(new)* Ask stylist on results, which is still a stand-in sheet (RD-06, app `docs/your-looks.md`).
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** styling quality on Lily's saved scenarios.

### Phase 27b: Token and cost efficiency

- Prompt size budgets, caching safe repeat results, and cost tracking per request.

**Checkpoint:** measured cost per styling request against the budget.

### Phase 27c: Background AI jobs *(built against the fakes 22 October 2026; push when the app is closed waits on Jose's APNs setup)*

- Every paid AI action (Style Me now, Ask stylist and try-on next) is an app-level job kept in the store, resumed after a relaunch with the same Idempotency-Key, and announced with a banner, a tab dot or a local notification (Jose, 21 October 2026).

**Checkpoint:** start Style Me with a slow stylist, browse and search, see the banner and the looks; background the app and see the notification; a job killed mid-way finishes after a relaunch with no second charge.

### Phase 28: On-device stylist *(built 22 October 2026: Quick ideas on the phone and one router; Lily's iPhone 12 can't run Apple's model, so the Foundation Models stylist waits on Jose)*

- Apple's on-device model on eligible devices, with the same response contract.

**Checkpoint:** same scenarios on an eligible device and on the iPhone 12 fallback.

### Phase 29: Weather

- WeatherKit feeding the request and the Home windows.
- *(from Stage A)* Its location permission and switch in Privacy and terms.

**Checkpoint:** live weather shows in the room and shapes suggestions.

### Phase 30a: Subscription and paywall *(built 22 October 2026 against Xcode's StoreKit testing; the real products, final price and allowances wait on Jose)*

- StoreKit 2 subscription, free trial and the paywall, following Apple's rules for subscription wording.
- *(from Stage A)* The try-on picture allowance, and Help's "Free and paid" topic (app `docs/settings.md`, `try-on-pictures.md`).

**Checkpoint:** sandbox purchase, restore, renewal and expiry.

### Phase 30b: Complimentary unlock and credit packs

- Offer-code unlock and consumable image-credit packs.

**Checkpoint:** each purchase type in sandbox.

### Phase 30c: Server-side verification and credit ledger *(built 22 October 2026 against a test CA; switching on needs Jose's App Store Connect steps)*

- App Store Server Notifications, entitlement checks on the server, and the credit balance that the gateway enforces.

**Checkpoint:** refunds, expiry and revoked purchases correctly remove access and credits.

### Phase 31: Monitoring and analytics *(built 22 October 2026; opt-in analytics deliberately not built, see the Progress log)*

- Crash reporting, cost and usage alerts, and opt-in analytics only if they earn their place.
- *(from Stage A)* The analytics switch in Privacy and terms, if analytics ship. *(Not built: analytics didn't ship, so there is no switch.)*

**Checkpoint:** a forced crash and a forced cost spike both reach Jose. *(Both are forced in tests; the alert channel is still a log line until Jose picks one.)*

### Phase 32a: Scale and load testing *(done 22 October 2026 locally; cold launch, memory and typing on a phone wait on Jose, see the Progress log and LOAD_TEST_REPORT.md)*

- Load tests on the gateway, many concurrent users, and very large closets and histories on the device.

**Checkpoint:** results against agreed limits.

### Phase 32b: Security testing

- Work through the OWASP MASVS (app) and ASVS (backend) checklists, run abuse tests at scale, and inspect the release build for secrets and sensitive data at rest.

**Checkpoint:** every finding fixed or recorded as an approved exception.

### Phase 33a: Try-on pictures, face stays on the phone (gated) *(built against the fakes 22 October 2026; the real Vision run on an iPhone and the first real FLUX.3 call wait on Jose)*

- Only after the PRD 9.2 checks pass. Model: FLUX.3, picked by Jose on 19 October 2026 after the try-on tests (whole outfit in one call). It runs through BFL's standard API, which lets BFL keep inputs and outputs permanently and train on them. Jose approved that on 19 October 2026 for the faceless body photo on a plain studio backdrop and the clothing photos, because the face never leaves the phone (D1 in `THREAT_MODEL.md`). The condition is plain disclosure in the try-on consent screen, the privacy policy and the App Store privacy label, and Jose re-reads the approval before any outside testers or the public launch. A BFL business agreement or FLUX on Azure stays as an optional later upgrade, and OpenAI gpt-image-2.5 Sunburst is the backup. If the phone can't find the face or confirm the mask, the try-on doesn't run.
- The face never leaves the phone. Apple Vision traces her head and hair, the app fills that shape with flat grey, and only the faceless photo and the clothing photos go through Convex to the model. When the dressed body comes back, the phone lines her real head up with her neck and shoulders and blends it back in over the same backdrop, with no extra call. Her pose is never changed. The prototype in the 19 October tests handled long, curly, afro and short hair, a three-quarter pose, and turtlenecks, scarves, hats and coats.
- The room never leaves the phone either. The same Apple Vision person outline replaces the room behind her with a plain studio backdrop, like a model photoshoot, before anything is sent (Jose decided this on 19 October 2026). Her real head goes back on over that same backdrop.
- Convex holds the faceless photo and the garment photos, sealed (encrypted), only while the picture is made, and the result for at most 30 minutes; the consent says exactly that (corrected 22 October 2026, 33b). The finished picture is saved on her phone only.
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** the PRD's go/no-go gates, plus the 19 October hard cases redone in the app.

### Phase 33b: Try-on photo setup *(built against the stand-ins 22 October 2026; the real camera and live Vision wait on Jose)*

- "Set up try-on" opens the app's own camera with an outline to stand in. Live pose hints come from Apple's on-device body tracking (whole body in frame, facing the camera, arms a little away from the body), and a timer takes the photo by itself. It saves Apple's hair and skin mattes for the cleanest outline.
- "Choose from photos" as a fallback runs the same checks and explains, kindly, when a photo won't work well.
- The photo is taken once and reused, kept on the phone and in her own iCloud if she turns that on.

**Checkpoint:** setup works on the iPhone 12 and a newer iPhone, from both the camera and the library.

### Phase 33c: Privacy walkthrough (last step, once try-on is ready) *(built against the stand-ins 22 October 2026; Jose and Lily watching it on a real phone is the checkpoint)*

- The first time, a 5 to 6 second animation shows what happens to her photo. A soft privacy veil fades over her head from the neck up. The faceless photo goes to the cloud, comes back dressed, and her own face fades back in with an "on your phone" lock. No literal cut-off head.
- On every later try-on, the loading screen shows the same real steps as short captions ("Hiding your face", "Swapping in a studio backdrop", "Dressing you", "Putting you back together on your phone"). If a step fails, it stops there. Skip after the first time, and a simple fade when Reduce Motion is on.
- "See what was sent" on every try-on picture shows the exact image that left the phone: the faceless body on a plain backdrop.
- One line under it, and the same plain wording in the try-on consent screen: "Your face never leaves your phone. A photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models." The privacy policy and the App Store privacy label say the same, and "See what was sent" shows exactly that image.

**Checkpoint:** Jose and Lily watch it on a real phone, and the animation matches what the app actually sends.

### Phase 34: Find One (open question)

- Only after the shopping direction is settled.
- *(from Stage A)* Fit checks that use the pieces that fit her well (LR-12, app `docs/profile.md`).

### Phase 35a: Release audit

- Full App Store Review Guidelines pass, accessibility audit, and privacy labels checked against what the app actually does.
- Independent security review or penetration test of the app and backend, with findings fixed.
- Legal review complete for privacy policy and sensitive data.
- *(from Stage A)* A proper trademark search for the name. The 13 October check was only a quick screening.
- *(new)* iPad keyboard shortcuts (Command-F for search, Escape to close a sheet), checked on a real iPad with a keyboard. Stage A left them out because the simulator's keys didn't trigger them (app `docs/ipad.md`).

**Checkpoint:** every item on the App Review checklist is done and the independent review is closed.

### Phase 35b: Submission

- App Store listing, review notes, demo account for reviewers, and submission.
- Website ready: the landing page with real screenshots, and the privacy policy and support URLs used in App Store Connect.
- *(from Stage A)* Help's "What changed" topic, with public release notes (PRD 22.2).

**Checkpoint:** Jose submits.

## Progress log

Add a dated line per phase: what was built, what Jose decided at the checkpoint, and anything carried forward.

- 7 October 2026: plan drafted, then split into smaller phases with a shared definition of done. No app code yet.
- 7 October 2026: two-repo setup and Git Flow decided. Security standard adopted with no corner-cutting; threat model moved up to Phase 0c, repo hardening added as Phase 1b, and authorization, incident response, security testing and an independent review added.
- 7 October 2026: quick pattern scan of `closet` history found no committed secrets; here.now state is ignored. Jose to turn on secret scanning and push protection for `closet` (this repo is public; he's fine with Lily's details being in it).
- 13 October 2026: Lily's mockup notes pulled (sign-off sheet in `prototypes/RoomDirectionMockups/feedback/signoff-2026-10-13.md`). Jose decided all design must be settled before the iOS build moves on, including her palette choice (a neutral, more grown-up palette study is under way). Phase 2a (design tokens) can't start until she has picked.
- 13 October 2026: Lily picked the **warm neutral** palette and **Preferences** (replacing "Mode"), and approved the one-outfit, three-version results ("Perfect."). Jose decided the HTML mockups won't be updated further: the approved changes are specified in `prototypes/RoomDirectionMockups/feedback/signoff-2026-10-13.md` and get built straight into the native app. Phase 0b (PRD amendment) folds them in; Phase 2a takes its colours from `css/palette.css` (warm). Design is settled.
- 13 October 2026: the app is named **Nifty Outfit Nook** (home-screen name "Outfit Nook"), replacing My Petite Style across the docs and mockups; the master PRD is now `Nifty_Outfit_Nook_PRD_v2.md`. The app repo will be `nifty-outfit-nook`. A quick screening found no exact App Store, GitHub or trademark match and the main domains apparently free; a proper trademark search stays in Phase 35a.
- 13 October 2026: `nifty-outfit-nook` created with `main` and `develop`, then made **public** at Jose's request (no GitHub Pro; he wants it as a portfolio piece). This fits SECURITY_STANDARD.md section 3: a client repo may be public as long as every repo control is on and no business logic lives in it. So backend code, prompts, fit and styling rules, model config and any keys stay in the private backend repo, and the app repo holds only the client. Public repos get rulesets, secret scanning with push protection and Dependabot at no cost, so Phase 1b can turn all of them on.
- 13 October 2026: Jose created the app website at https://niftyoutfitnook.pages.dev/ (Cloudflare Pages, "Coming soon" for now). It becomes the landing page with the app's screens, and hosts the privacy policy and support pages the App Store requires (Phases 19b and 35b). The Cloudflare account goes in the Phase 0c account inventory with two-factor authentication.
- 13 October 2026: Phase 0a started in `nifty-outfit-nook` on `feature/00a-technical-decisions` (pushed). The proposed decisions note is `docs/decisions/0001-technical-decisions.md`, waiting on Jose's four answers (Lily's iOS version, bundle ID, snapshot-testing dependency, Apple Developer membership). Finding: Foundation Models needs an iPhone 15 Pro or later, so Lily's iPhone 12 always uses the cloud stylist and Phase 28 is an optional extra for newer phones.
- 13 October 2026: **Phase 0a done.** Jose approved the decisions note (iOS 26.0 minimum since Lily is on 26+, bundle ID `com.jsayram.niftyoutfitnook`, `swift-snapshot-testing` approved for tests only, and he already has a paid Apple Developer membership from shipping Life Wrapped). Merged into `develop` as PR jsayram/nifty-outfit-nook#1 (squash), feature branch deleted. **Next: Phase 0b** (PRD amendment draft, including Lily's approved changes from the 13 October sign-off sheet), on `feature/00b-prd-amendment`. Repo protections are still off until Phase 1b, so work only on feature branches and merge through PRs.
- 13 October 2026: the website source (`website/`, the Cloudflare Pages coming-soon page) moved from closet into `nifty-outfit-nook`, at Jose's request.
- 13 October 2026: Jose authorized running all of Stage A without stopping at checkpoints, then auditing Stage A himself before Stage B starts. Each entry below lists the checkpoint items left for that audit.
- 13 October 2026: **Phase 0b done.** `PRD_Amendment_Room_Direction.md` covers the room-direction changes (RD-01 to RD-13) and Lily's approved items (LR-02 to LR-18), each with the previous PRD text, the new rule, acceptance checks and the phase that builds it; the PRD links to it. For the audit, check these calls: Something new stays owned-only inside a suitcase; "Style with this" offers a choice between setting the starting piece and opening Make your own look; swap ranking on the phone uses only stored facts, since the real rules stay off the public repo; no Stage A screens for Favorites, collections or Archive; Lily's default is "Mine + one idea"; the warm palette's dark mode is derived in Phase 2a.
- 13 October 2026: **Phase 0c done.** `DATA_MAP.md` (five-tier classification, flow table and diagram), `THREAT_MODEL.md` (top 10 risks, STRIDE per component, a control and build phase for each) and `ACCOUNT_INVENTORY.md`. R1 (Lily's details in this public repo) is recorded as accepted, per Jose's 7 October decision. For the audit: (1) confirm two-factor authentication and offline recovery codes for GitHub, the Apple Account, Cloudflare, here.now, the reset email account and the password manager (the gh token can't read 2FA status); (2) PRD 15.4's unencrypted export conflicts with the standard, flagged for Phase 20b; (3) no phase builds the real feedback board, support queue or email program yet, so that's a plan gap to place in Stage B.
- 13 October 2026: **Phase 1a done** (jsayram/nifty-outfit-nook#3). A hand-written Xcode project with synchronized folders, the `NookKit` package (DesignSystem, Models, Fixtures, Features), Home / Closet / Saved Looks tabs, a `-fixtures` launch argument, xcconfigs per environment with the team ID in an ignored local file, complete Data Protection, an empty privacy manifest, no ATS keys, and build, test and format scripts. 11 tests pass and warnings fail the build. NookKit is a folder reference, not a local-package reference, because the usual reference skipped its tests without an error. For the audit: open the project in Xcode once, and read the README's folder layout. iPad tabs sit at the top on iOS 26 until Phase 15a.
- 14 October 2026: **Phase 1b done** (jsayram/nifty-outfit-nook#4, #5, #6). GitHub Actions CI runs three jobs (`swift-format`, `build-and-test` on `macos-26` with Xcode 26.6, `gitleaks`), with actions pinned to SHAs and a read-only token, in about 5–7 minutes. Also added: a gitleaks pre-commit hook, Dependabot, CODEOWNERS, a PR template with the security checklist, SECURITY.md and AGENTS.md. In the repo settings, secret scanning and push protection, Dependabot alerts and fixes, and private vulnerability reporting are on. Merges are squash only. One ruleset on `main` and `develop` has no bypass, admins included; it requires a PR, the three checks, signed commits and linear history, and blocks force pushes and deletion. Verified: a direct push to `develop` or `main` is rejected, and the hook blocks a fake token. `gh pr merge` gets refused because local commits are unsigned, so PRs merge through `scripts/merge-pr.sh` (the REST API with all rules still applied). For the audit: decide whether to set up local commit signing; run `scripts/install-hooks.sh` in each clone you commit from.
- 14 October 2026: **Phase 2a done** (jsayram/nifty-outfit-nook#7). 34 warm-neutral colour tokens (light values from `css/palette.css`, dark derived as the same room at night with a warm charcoal wall), held in `Palette.swift` with tests that check the asset catalog against it. Also: 12 Dynamic Type text roles (system rounded for interface text, New York serif for titles and the name sign), spacing, radius and below-only shadow tokens. Tests cover WCAG contrast for 57 light and dark pairs. Two contrast fixes: the row chevron darkened to `#8A7B6E`, and secondary text on the bare floor must sit on a tint. For the audit: the token tables in `DesignSystem/README.md` against the mockups, the latte accent pill in dark mode (espresso only reaches 2.3:1 there), and the new sage, ochre and brick status colours.
- 14 October 2026: **Phase 2b done** (jsayram/nifty-outfit-nook#8). Outline-free components:
  - buttons, chips and chip rows, soft rows and cards, a search field, a sheet helper
  - empty, loading, error and offline states, a segmented switch, toasts and badges
  
  Each keeps 44pt targets, VoiceOver traits, Reduce Motion, dark mode and AX5 reflow. A debug-only catalog opens with `-catalog`, and `scripts/check-release.sh` proves Release has no catalog or snapshot code. `swift-snapshot-testing` 1.19.6 is pinned and test-only (vetting in `docs/decisions/0002-snapshot-testing.md`). The 44 snapshots render through `ImageRenderer`, since the library's renderer lost the shadows. For the audit: the catalog next to `results.html`, and the AX5 snapshot images.
- 14 October 2026: **Phase 3 done** (jsayram/nifty-outfit-nook#9).
  - **Models:** Garment, Look (one result in three versions plus an optional unowned idea), Suitcase, Profile and Preferences, StyleRequest and the stylist outcomes, each field tagged with its data tier.
  - **Rules:** pure functions with tests.
  - **Stores:** async protocols in `NookServices`.
  - **Fixtures:** in-memory stores with the empty, demo (21 garments) and large (2,400, seeded) sets, plus offline, slow, failing and partial modes (`-fixtures demo:offline`). The mock stylist only matches stored facts. 187 unit tests and 10 UI tests pass.
  - **Milestone:** `develop` was promoted to `main` (#10, security gate checklist in the PR, gitleaks clean on the full history).
  - **Promotions from now on:** the repo only allows squash merges, so `main` and `develop` no longer share history. Future promotions go through `scripts/promote.sh` (#11), which builds the PR on `main`.
  - **For the audit:** read `docs/models.md`. Whether to allow merge commits for promotions instead (a repo-settings call). Demo profile has no body measurements since the repo is public. When Release builds stop shipping sample data (Phase 20a). CI's build-and-test job now takes about 9–14 minutes.
- 14 October 2026: **Phase 4 done** (jsayram/nifty-outfit-nook#12). The Home room is built from 16 mockup drawings turned into vector assets, recoloured into the warm palette with dark versions. The wardrobe and shelf switch tabs. The laptop, calendar, suitcase, hamper, drawers, name sign and Profile open stub screens. Her name on the sign is live text, and every tap target is a labelled VoiceOver button. 218 package tests and 12 UI tests pass. For the audit:
  - The iPhone SE screen scrolls about 160 pt so the drawers keep 44 pt targets.
  - An empty sign says "Hello".
  - Room text stops growing at xxxLarge until 5b.
  - The tab bar uses the espresso accent.
  - The recolour reads richer than the mockup's filtered study (the desk is sage).
- 14 October 2026: **Phase 5a done** (jsayram/nifty-outfit-nook#13).
  - **Weather windows:** six of them (sun, cloudy, rain, snow, night, unknown), and the lamp glows at night.
  - **Hamper:** off, empty, a small heap and a full heap. When tracking is off, tapping it offers to turn tracking on.
  - **Maya:** asleep on the rug. Her z's stay visible but still under Reduce Motion.
  - **Weather sheet:** per LR-04 the weather row lives on Style Me, so its use / indoors / ignore sheet sits on Style Me's stand-in. Home only shows the window.
  - **Launch flags:** `-fixtures demo:weather=snow:laundry=full`.
  - **Tests:** 260 package tests and 14 UI tests pass.
  
  For the audit:
  - Window skies keep a faint blue so sun and cloud stay distinct.
  - Maya keeps her real apricot colours.
  - The full hamper starts at 6 pieces.
  - CI's build-and-test job has grown to about 18 minutes, so it should be trimmed.
- 14 October 2026: **Phase 5b done** (jsayram/nifty-outfit-nook#14, #15).
  - **Large text:** from AX1 to AX5, Home switches to the banner layout from `home-ax.html`, with uncapped text and a big row per action.
  - **Sideways:** the phone uses `home-landscape.html`, with the room on the left and tiles beside it.
  - **Dark mode:** the hamper and the night lamp glow were fixed.
  - **CI:** split into parallel jobs, cutting it from about 18 to about 12 minutes. Nothing is cached and the required check names are unchanged.
  - **Tests:** 274 package tests and 16 UI tests pass.
  
  For the audit:
  - Home at AX3 and AX5, sideways, and the dark hamper and night lamp.
  - The weather plate is left out of both layouts (LR-04).
  - A CI run now uses five macOS runners, so back-to-back runs can queue.
- 14 October 2026: **Phase 6 done** (jsayram/nifty-outfit-nook#16). The Closet has:
  - the wall header, a search with a 250 ms wait that matches every word, and filters for piece, colour, suitcase and dirty (`GarmentFilter`)
  - Suitcases and Laundry tiles, a lazy grid of colour-matched placeholder pictures loaded through `ImageProvider` with a cache, and a "Recently deleted" entry
  - loading, error, empty and no-match states, with filters folding behind a button at AX sizes

  With 2,400 pieces the grid prepares in 48 ms. 318 package tests and 18 UI tests pass. For the audit:
  - browse `demo`, `empty`, `large` and `demo:laundry=some` at AX5 and in dark
  - last worn is spoken by VoiceOver but not shown on the grid
  - the "Photos stay on this iPhone." line was left out
  - run `ClosetScrollPerformanceTests` on Lily's iPhone 12 to measure hitches
- 14 October 2026: **Phase 7a done** (jsayram/nifty-outfit-nook#17). Garment detail shows:
  - last worn, with a repeat-window note, and the suitcase names, which link to each suitcase
  - the piece's facts and fit, and laundry marking with Undo
  - Style with this, which offers "Style me with it" or "Make my own look"
  - Remove from closet (LR-16), with both choices confirmed and an Undo toast

  Recently deleted keeps pieces for 30 days, with Restore. 362 package tests and 20 UI tests pass. For the audit: the LR-18 fit and comfort lines live on 14a and 10a, not on detail. Deleting a piece also has Undo. "Delete permanently now" waits for 21a. Phase 13 must hide pieces she no longer owns from her suitcases (`isInCloset`).
- 14 October 2026: **Phase 7b done** (jsayram/nifty-outfit-nook#18).
  - **Add a piece:** four photo entry points, all stand-ins with no camera, Photos access or permission strings, then a validated details form.
  - **Describe in words:** an on-phone word matcher that sends nothing and holds no style rules.
  - **Edit:** uses the same form.
  - **Drafts:** recovered through `DraftStore` ("Continue where you left off?"). In Stage A drafts are kept in memory only, because a draft can hold Sensitive words and Phase 18 comes before the storage phases. Phase 21a gives `DraftStore` real storage. `-fixtures demo:draft=add|edit` seeds a draft.
  - **Tests:** 443 package tests and 23 UI tests pass.
  - **For the audit:**
    - A kind is required as well as a name.
    - LR-12 and LR-13 aren't in the form (reasons in `docs/add-a-piece.md`).
    - Two large-closet speed checks went over their limit once on a slow CI runner, so their bounds may need loosening for CI.
- 14 October 2026: **Phase 8a built; the go/no-go is waiting on Jose** (jsayram/nifty-outfit-nook#19).
  - **What's in:** `CutoutService` uses Vision's foreground mask in a new `Services` module, with Apple frameworks only, no metadata in the output and quality signals. Stage A uses a stand-in. A debug-only benchmark opens with `-cutout-bench` and uses PhotosPicker, which needs no permission. Release is checked to contain none of it.
  - **Testing:** Vision's mask doesn't work on the simulator, so the real path returns `unsupported` there. On Jose's M1 Max a warm cutout takes about 105 ms.
  - **Proposed go criteria:** on the iPhone 12, warm median 1 s or less, p90 2 s or less, cold start 4 s or less, peak memory 300 MB or less, and at least 70% of cutouts usable.
  - **For the audit:** run the benchmark on Lily's iPhone 12 with about 20 real garment photos (steps in `docs/cutout-feasibility.md`) and make the call. Phase 22a must strip location from saved originals. The CI speed checks were hardened (best of 3, 3× allowance on CI).
- 14 October 2026: **Phase 8b done** (jsayram/nifty-outfit-nook#20).
  - **Choosing the picture:** one rule (`GarmentArtChoice`) shows a clean cutout as a sticker with a thick white outline and below-only shadow (`NookSticker`, made with Accelerate dilation and cached by picture, about 25 ms). Anything else gets a same-size rounded tile (`NookPhotoTile`). The sample drawings get the sticker treatment too. `GarmentPicture` draws every piece.
  - **Where stickers show:** the Closet grid keeps the mockup's standing pieces, and stickers appear on detail and, from Phase 9, in looks.
  - **Tests:** 540 package tests and 25 UI tests pass.
  - **For the audit:**
    - Compare stickers and tiles with `-fixtures demo:photos=samples`.
    - The outline is a bit thicker than the mockup's, and slightly off-white in dark mode.
    - Run the cutout benchmark on Lily's phone, which now shows each real garment as both a sticker and a tile, then set the cutout thresholds.
- 14 October 2026: **Phase 9 done** (jsayram/nifty-outfit-nook#21).
  - **Layout:** `StickerBundleLayout` places 2 to 6 pieces in the mockup's 300 × 356 box. Tilts are seeded by look ID and stay the same between launches, and shoes sit over the hems.
  - **Bundle:** `LookBundle` comes in large, medium and thumbnail sizes. A piece she doesn't own gets a soft "Not in your closet" tag. VoiceOver reads the look as one element, with the pieces in a rotor.
  - **Piece list:** `LookPieceList` shows Find one and "Same as Simple".
  - **Tests:** all 1,708 piece mixes were tested for bounds, overlap and determinism. 578 package tests and 26 UI tests pass.
  - **For the audit:**
    - The look-bundles page at the end of `-catalog`.
    - Shoes look small because the drawn shoe is a single loafer.
    - `HomeTests` failed once on CI on a suitcase tap and passed on rerun, so watch for flakiness.
- 14 October 2026: **Phase 10a done** (jsayram/nifty-outfit-nook#22).
  - **Request check:** `StyleRequestBuilder` (tested over 2,688 combinations) checks Lily's choices against her closet. `ColorWish` is added.
  - **Screen:** Source, Occasion and Starting piece, then Weather, Comfort (with the LR-18 line), Colour and Preferences, and one Style me button.
  - **Entry points:** the laptop, the calendar (opens on Occasion) and "Style me with it".
  - **Blocked states:** empty closet, empty or small suitcase, a starting piece that can't be used, and unreadable weather.
  - **Style me:** opens a stand-in that shows the request, plus its JSON in Debug.
  - **Tests:** 650 package tests and 31 UI tests pass.
  - **For the audit** (see `docs/style-me.md`):
    1. An empty closet can't style, though PRD §8.1 allows labelled ideas.
    2. Occasion resets to Office each time.
    3. Preferences changed here apply to that request only.
    4. The app spells it "Colour"; the amendment says "Color".
    5. A suitcase warns below 6 usable pieces and blocks below 2.
- 15 October 2026: **Phase 10b done** (jsayram/nifty-outfit-nook#23).
  - **Your looks:** Today and Saved tabs. One outfit comes in three versions (Simple · Dressed up · Something new), each with its bundle and piece notes.
  - **Actions:** Save look (one tap, with an automatic colour name and Undo) and Try a different outfit (the stylist is told which outfits it has already shown). Try it on, Swap, Ask stylist and Find one are stubs that send nothing.
  - **States:** styling, partial, not enough pieces, failed, offline and stopped, each forceable with a flag. Leaving the screen cancels the request.
  - **Tests:** 703 package tests and 35 UI tests pass.
  - **For the audit:**
    - An absent version is dropped from the switch, and a banner explains why.
    - The "looks will wait here" line is gone.
    - Home UI tests flaked twice on CI and passed on rerun, so stabilising UI tests is now worth a pass.
- 15 October 2026: **Phase 11 done** (jsayram/nifty-outfit-nook#24, #25).
  - **UI test stability (#24):** UI tests now wait on screen state instead of sleeping. CI reruns a failed UI test once, documented as a workaround for flaky CI machines.
  - **Swap a piece:** shows an explanation line, 3 options with Show 3 more, then See all (weaker matches marked "May not match"), plus Find one, Remove and Undo. Ranking only uses stored facts.
  - **Make your own look:** covers Style with this and "+ Make your own", with one piece of each kind, Undo and Redo, a named save, and a draft that survives the editor closing and the model being rebuilt. Surviving a real relaunch comes with Phase 21a storage.
  - **Toasts:** the toast on garment detail now sits above the tab bar.
  - **For the audit:**
    - The demo Office look shows mostly "May not match" tops.
    - Olive counts as a neutral.
    - Saving a changed look makes a new look.
    - Your own look doesn't need shoes.
- 15 October 2026: **Phase 12a done** (jsayram/nifty-outfit-nook#26).
  - **Saved Looks:** a Looks / Pictures switch, search, piece and colour filters, a lazy grid of bundles, "+ Make your own", and empty, no-match, loading and error states.
  - **Look detail:** Wear today, Swap, Try it on (stub), Rename, a piece list linking to each garment, and Delete with Undo. Pieces she has removed show faded with "Swap it".
  - **Home:** the shelf frames show the three newest saved looks.
  - **Tests:** 824 package tests pass, and 41 of 42 UI tests pass locally. The Swap UI test fails locally on `develop` too but passes on CI.
  - **For the audit:**
    - Swapping a saved look edits it in place.
    - Delete has no confirmation, only Undo.
    - Rename replaced Ask stylist on detail.
    - The shelf frames' tap areas are about 36 pt, under 44 pt.
    - CI's `ui-rest` job took about 29 minutes, which needs trimming.
- 15 October 2026: **Phase 12b done** (jsayram/nifty-outfit-nook#27, #28).
  - **CI:** the UI jobs were rebalanced and catalog tests now jump straight to their page (`-catalog-page`), so the check takes about 20 minutes instead of 29.
  - **Try it on:** first explains that the picture is simulated, then makes a picture of the look's pieces with a "Simulated" badge. It shows no person and uses no network, camera or Photos. Pictures are saved through `TryOnPictureStore`.
  - **Pictures:** a Pictures tab, picture detail (See the look, Delete with Undo) and a list of pictures on each look.
  - **Tests:** 871 package tests and 44 UI tests pass.
  - **For the audit:**
    - Deleting a look keeps its pictures (PRD §7.5, §9.2.4).
    - Try it on from Your looks saves the look first.
    - An existing picture of the same look is offered first.
    - Check on a device that pictures are hidden in the app switcher.
- 15 October 2026: **Phase 13 done** (jsayram/nifty-outfit-nook#29).
  - **Suitcases:** three favourites (the most recently used) in an entry hall, See all with search and Archived, "+ Add a suitcase" always in the bar, and five suitcase pictures.
  - **One suitcase:** packing that reuses Closet's filters, plus Style me from this suitcase, set as source, rename, archive, and delete with Undo. Pieces she no longer owns are hidden.
  - **Garment detail:** an Add to a suitcase sheet.
  - **Laundry:** clean one, clean selected or mark all clean, each with Undo. Style Me skips pieces in the wash.
  - **Remembered choices:** Home's suitcase and calendar show the remembered source and occasion.
  - **Tests:** 928 package tests and 45 UI tests pass.
  - **For the audit:**
    - Home's suitcase and hamper open on the Closet tab, so Back goes to Closet.
    - Suitcase pictures are shapes, not colours.
    - Delete suitcase relies on Undo only.
    - Look at the four new suitcase drawings.
    - Laundry can't be turned off until 14b.
    - The remembered source and occasion reset on quit until 21a.
- 15 October 2026: **Phase 14a done** (jsayram/nifty-outfit-nook#30).
  - **Profile:** the name on the sign updates Home live, and Preferences and the repeat setting (1 week) live here.
  - **Fit and measurements:** usual fit (LR-18 wording) and optional measurements, with the units following the region until she picks. Values are range-checked in her units, and the LR-13 example shows only while she has none.
  - **Try-on photo sheet:** an example photo only, with no camera or Photos access.
  - **Privacy:** the Fit screens are covered in the app switcher (checked on the simulator's saved snapshots), and body measurements can't be printed.
  - **Tests:** 971 package tests and 48 UI tests pass.
  - **For the audit:**
    - There's no Confirm step on measurements.
    - The mockup's size-guess line was dropped (the PRD forbids it).
    - Weight isn't promised "never shared".
    - The UK defaults to inches and pounds.
- 22 October 2026: **Phase 24d support and feedback channel, built against mocks** (jsayram/nifty-outfit-nook#85, merged into `develop` as 778bbee with every required check green on the first CI run). Same pattern as 24a to 24c: one shared contract, real Convex code tested on a local backend, the app's fake server, and the real services a configuration switch away. No new dependencies on either side (the backend still has only `convex` and `convex-test`). One backend commit (local only).
  - **The contract (v1, additive):** `POST /v1/feedback` (token, no App Attest; 202 with a reference like `NK-7F3A9C21`). The request is a `submissionId`, a kind, her words (at most 2,000 characters; the app stops at 1,000) and, only if she chose them, a reply address, app details (version, build, iOS, device model), three closet counts and one screenshot (JPEG or PNG, base64, at most 600,000 bytes). Unknown fields are refused, so a device name, a list of pieces or an account ID can't ride along (invalid examples for each). The only endpoint with a body over 64 KiB (1 MiB); `maxBodyBytes` is now per endpoint. Golden examples in both repos, tested by both.
  - **Decision, App Attest:** none on this endpoint. Support must work on a device that can't attest, and a note costs nothing; the protection is the token (every note belongs to an account and goes with it), limits and caps. Same reasoning as deletion (24c). App decision 0009.
  - **Limits** (backend `ticketing/policy.ts`): burst of 5 then one every 12 minutes per account (the 24b token bucket), 10 notes and 3 screenshots in any 24 hours, 300 notes a day across all accounts (`unavailable`), `NOOK_SUPPORT_INTAKE=closed` to close intake without an app update. A resend with the same `submissionId` returns the same ticket, stores nothing twice and uses no allowance.
  - **Backend** (`convex/support.ts`, `convex/ticketing/`): a `supportTickets` table, a note admitted before its screenshot is stored (limits first, so a refused note leaves no file; a ticket waiting for its picture expires after an hour and a resend finishes it), tickets deleted by a daily cron (**90 days after Jose closes one, 180 days from arrival if he never does**; the 180 is my default, to confirm), and deleted with the account, files included (`deletion.ts`; the deletion test lists the table). **Admin only:** every function is internal, no HTTP route reads a ticket, `check-public-functions` still passes. Jose reads them in the Convex dashboard (Data and Files tabs) or `npx convex run support:list | get | close | remove` (README, "Reading and answering tickets"). **Email to Jose:** a mock hook (`NOOK_SUPPORT_NOTIFY_MODE`: off, mock = one log line with the reference, kind and whether there is a picture, email = not built, fails closed); whatever sender comes carries those three things and a dashboard link, never her words, address or picture.
  - **Screenshots:** the app rewrites the picture from its pixels (`ScreenshotPreparer` on `PhotoCleaner`: upright JPEG, at most 600 KB, 2,000 px on the long side, shrunk further only if it must) and the backend rewrites it again from the file's own structure (`ticketing/image.ts`: JPEG keeps decode tables, frame, scan and the colour profile; PNG keeps image and colour chunks; EXIF, XMP, IPTC, thumbnails, comments, text chunks and trailing bytes go; HEIC, GIF, WebP and anything malformed or over 8,192 px is refused; nothing is decoded). Checked with a real decoder and `exiftool` on the output.
  - **App:** `FeedbackService` and `GatewayFeedbackService`; Send feedback picks the queue when she is signed in and keeps the share sheet otherwise (there is no sign-in screen yet, so on a real build today everyone is on the share sheet). Reply address field, screenshot row (system picker, screenshots only, no permission, thumbnail and Remove), Include my closet's size, and a "What's sent" list of every value (`FeedbackNote.sentValues`: a test checks the page shows each one, another that the request carries those and nothing else). No queue (Jose): a note that can't go stays as written, says why in plain words, and goes when she taps Send again; the same note keeps one submission ID. The screenshot is never in the draft; the reply address and closet switch are. Support page row from Send feedback (address from `NOOK_SUPPORT_URL`, placeholder `https://niftyoutfitnook.pages.dev/support`; the app holds no email address). Fake backend: the same checks, limits and answers, plus an auditor that reports which metadata a received picture carried.
  - **Checkpoint**, on the "24d iPhone 12" simulator (iOS 26.5): the UI test `SupportFeedbackTests` signed in with the fake Apple sign-in, wrote a note, gave a reply address, attached the debug sample screenshot (1170 x 2532 with Exif, GPS, TIFF and IPTC planted in it, checked by `FeedbackQueueTests`), turned on the app details and closet size, read "What's sent" and sent. From outside the app, the fake server's report in the container (`tmp/fake-backend-support.json`) showed the screenshot received as a 924 x 2000 JPEG of 49 KB with **no metadata**, the diagnostics 0.1.0 (1), iOS 26.5, iPhone13,2 and the counts 21 pieces, 10 looks, 6 suitcases, exactly what the page listed (screenshots in the test result). Signed out, the page keeps the share sheet and has none of the extras. "Jose can answer it": he reads the note in the dashboard and mails the reply address; with no address he can't (the page says so before and after).
  - **Tests:** backend 130 (21 new in `tests/feedback.test.ts` on `convex-test`: the cleaner on planted JPEG and PNG, refused formats, limits with an injected clock, resend, pending tickets, intake closed, retention, the admin functions, the mock hook, cross-user, deletion with files; plus one more cross-user case; one more on the real local Convex backend, including reading the stored file and `convex run support:get`). App: `FeedbackQueueTests` 13, `FeedbackNoteTests` 8, `FeedbackGatewayTests` (Networking, with a hand-moved clock), `ScreenshotPreparerTests`, contract and fake-backend cases, `SupportFeedbackTests` (UI). Package suites Networking, Models, Services, Fixtures and the Settings tests pass locally except the two AX5 snapshots (1 to 2 pixels of height on iOS 26.5, the same runtime mismatch as before).
  - **Not built, decided:** the public feedback board and the opt-in email program are left for later (written in DATA_MAP: no board, no new processor, no UGC duties for the first release). An in-app reply channel is not built.
  - **For Jose:**
    1. Is "signed out keeps the share sheet" right until the sign-in screen exists, or should Send feedback ask her to sign in first? (Asking would make support depend on Clerk.)
    2. Retention for a ticket nobody closes: 180 days, OK? (Closed: 90, as DATA_MAP said.)
    3. Do you want an in-app answer (a reply she reads in the app) later, or is email to her reply address enough? With no reply address you can't answer her.
    4. The email notification: which sender (an iCloud+ login, or a service, which would be a new processor)? Until then you look in the dashboard.
    5. The support page itself and the support email on it, in ACCOUNT_INVENTORY.md (35b): the app opens `https://niftyoutfitnook.pages.dev/support` until you say otherwise.
    6. The 300 notes a day and 10 per account are starting numbers.
- 15 October 2026: **Phase 14b done** (jsayram/nifty-outfit-nook#31).
  - **Track laundry:** a switch that keeps dirty marks when turned off.
  - **Accessibility:** shows the system settings, with no in-app options.
  - **Help:** eight offline topics.
  - **Send feedback:** goes through the share sheet. App details are off by default and she sees the exact text before sending.
  - **Privacy and terms:** a plain summary, plus the website's `/privacy` and `/terms` links in an in-app Safari view.
  - **Delete my data:** confirmed in two steps, it wipes every store and rebuilds the app; the service is ready for 24c.
  - **Home:** the desk drawers open Help, Send feedback, and Privacy and terms.
  - **Tests:** 1,006 package tests and 52 UI tests pass.
  - **For the audit:**
    - App tours stay hidden until 16b.
    - Feedback has no reply-email field.
    - Delete uses a two-step confirm, not typing to confirm.
    - The privacy and terms pages don't exist yet (19b).
    - We need a support or feedback channel.
    - A CI UI job takes about 24 minutes again.
- 15 October 2026: **Phase 15a done** (jsayram/nifty-outfit-nook#32). Layout is now decided by the window, not the device, in one place (`WindowLayout`).
  - **Tab bar:** on iPad it sits at the bottom. This is a workaround that tells the tab view it has a compact width.
  - **Home:** a wide room in landscape and a tall room in portrait (`RoomPlan`).
  - **Closet:** a sidebar, the grid and the selected piece side by side. Narrow windows and AX sizes fall back to the phone layouts.
  - **Tests:** 1,033 package tests and 52 iPhone UI tests pass, plus 3 iPad UI tests that run on CI.
  - **For the audit:**
    - Home and Closet on iPad in both orientations and in a narrow window.
    - The upright room leaves out the mockup's Style Me panel (RD-01.6).
    - Suitcases and Laundry still use their phone pages on iPad.
    - CI is back to about 30 minutes, and `docs/ipad.md` wrongly says it didn't grow.
- 15 October 2026: **Phase 15b done** (jsayram/nifty-outfit-nook#33).
  - **Your looks:** shows the look and its pieces side by side on iPad.
  - **Saved Looks:** a sidebar, a grid and the detail beside it (each tab keeps its own selection).
  - **Style Me, Swap, and Make your own look:** use two panes when the iPad is sideways.
  - **Other screens:** every other screen sits in a centred 640 pt column.
  - **Sheets:** they're fitted to their content.
  - **Fixed:** a crash when switching Looks/Pictures with a detail open.
  - **CI:** iPad UI tests have their own job, and the whole check takes about 21–26 minutes.
  - **Tests:** 1,055 package tests, 52 iPhone UI tests and 5 iPad UI tests pass.
  - **For the audit:**
    - Every main screen on iPad.
    - Suitcases and Profile keep the wall on top rather than beside.
    - Keyboard shortcuts (⌘F, Esc) weren't added, because simulated keys didn't trigger them, so they need a real iPad keyboard.
- 15 October 2026: **Phase 16a done** (jsayram/nifty-outfit-nook#34).
  - **Tour system:** one reusable system with a warm dim, a soft spotlight and a card with Back, Skip and Next. Anchors follow rotation, resizing, text size and scrolling.
  - **Progress:** a `TourProgressStore` records which tours she has seen and how each ended. Delete my data erases it.
  - **Home tour:** four steps, with copy for each Home layout. It starts once, and `-tour home|reset|off` controls it in debug builds only.
  - **Tests:** 1,093 package tests pass, and about 58 iPhone UI tests ran and passed (the 65 UI test methods include 6 iPad tests and 1 performance test), as do the iPad UI tests.
  - **For the audit:**
    - The card is opaque.
    - VoiceOver starts on the card's words.
    - Back was added.
    - The dim covers the tab bar.
    - At AX sizes the card usually has no spotlight.
    - Needs a hands-on VoiceOver check (focus moves, the two-finger escape skips, focus returns) and Escape on a real iPad keyboard.
- 15 October 2026: **Phase 16b done** (jsayram/nifty-outfit-nook#35).
  - **19 new screen tours:** each starts once, never over a sheet, toast or another tour, and works on iPhone, AX sizes and iPad.
  - **App tours on Profile:** Replay for each tour, "Show tips on new screens", and "Reset all tips".
  - **Delete my data:** now mentions tours.
  - **Copy:** tour text was updated to match the amendment (table in `docs/tours.md`).
  - **Tests:** 1,135 package tests pass, plus the iPhone UI tests and 6 iPad UI tests.
  - **For the audit:**
    - The tour copy changes.
    - Screens without a mockup tour get none.
    - The VoiceOver and Escape check from 16a.
    - Tour progress isn't saved yet, so tours would come back on every relaunch in TestFlight. Phase 17 handles this.
- 16 October 2026: **Phase 17 done** (jsayram/nifty-outfit-nook#36).
  - **First run:** a welcome screen, then the name for the sign, plain-words privacy, an optional usual fit, and a choice of sample or empty closet, ending on Home with its tour. No permissions or account are needed.
  - **Saved between launches:** "onboarding done", the closet choice, which tours were seen and the tips switch, in an app-only `UserDefaults` suite. DATA_MAP gained a lowest-tier "app state flags" row, and the privacy manifest declares `UserDefaults`.
  - **Delete my data:** goes back to the welcome screen.
  - **Debug:** `-onboarding reset|skip` is available.
  - **Tests:** 1,247 tests pass and 12 iPad tests are skipped, and the checkpoint walk is a UI test.
  - **For the audit:**
    1. The name isn't kept between launches (it's Personal tier), so the sign says Hello after a relaunch. The test build says it forgets changes. Keeping the name takes one key and a DATA_MAP change.
    2. There are four steps after the welcome.
    3. Six Your looks unit tests kept timing out on CI at 60 s, so their wait was raised to 600 s. That hides slowness, so find out why they're slow.
    4. On a device, check the `UserDefaults` file protection, relaunch after iOS ends the app, and VoiceOver through the steps.
- 16 October 2026: **Phase 18 prepared; upload is Jose's** (jsayram/nifty-outfit-nook#37, #39, #41, promoted to `main` in #42).
  - **Test timing fix (#37):** the slow tests weren't the stylist. About 300 snapshot tests were crowding the main actor. A `HeavyMainActorWork` trait now makes them take turns, and test waits count polls instead of seconds. The median CI test time went from about 200 s to 46 s.
  - **Release prep:**
    - A placeholder Icon Composer icon (a dress on a hanger in a nook).
    - Version 0.1.0, with timestamp build numbers from `scripts/bump-build.sh`.
    - A wall-coloured launch screen.
    - `scripts/check-archive.sh`, which builds an unsigned archive and checks it (all pass).
    - `Configs/ExportOptions-TestFlight.plist`.
  - **Tests:** 1,190 package tests and 61 iPhone UI tests pass; the 7 iPad UI tests pass on CI. The large-text wardrobe UI test flake was fixed (#41).
  - **Milestone:** `develop` was promoted to `main` with the security gate checklist. No tag was made.
  - **Jose's steps** (`docs/testflight.md`):
    1. Set the team ID in `Configs/Signing.local.xcconfig`.
    2. Register the App ID with Data Protection set to Complete.
    3. Create the App Store Connect record (Nifty Outfit Nook, SKU `niftyoutfitnook-ios`, Lifestyle).
    4. Add Lily as a Marketing-role user limited to this app, plus an internal TestFlight group.
    5. Run `scripts/bump-build.sh`, Archive, then Distribute to TestFlight Internal Only.
    6. Paste the What to Test text.
  - **Still flaky:** the iPad test `testClosetSidebarAndPieceBesideTheGrid` failed once.
  - **Stage A is complete.** Stopping here for Jose's Stage A audit, as he asked. **Next: Phase 19a**, only after he says so.
- 16 October 2026: **Stage A audit.** Four read-only audits ran over Stage A: spec, security, code and docs.
  - **Found in the docs:** many items Stage A deferred had no named Stage B phase, three progress log entries overstated what was tested, and some docs had gone stale (the PRD title, absolute links, the website's script, Lily's TestFlight access).
  - **Fixes in progress:** code and CI fixes in the app repo; docs fixes here, including the deferrals now listed under each Stage B phase and the new Phases 21c and 24d.
  - **Open decisions for Jose** are in the next entry.
- 16 October 2026: **Stage A audit decisions.** Jose asked Claude to do what's best for the app. Claude's calls:
  1. **Name and settings:** keep the sign name and the Profile settings (Preferences, Track laundry, repeat setting) between launches, in the app-only defaults suite. DATA_MAP gets a row for each.
  2. **Unsaved results:** searching unsaved earlier results (LR-06.4) is deferred to Stage B and written into Phase 21c.
  3. **Tours:** short tours for the six screens without one (Recently deleted, See all suitcases, Delete my data, Accessibility, Try it on, editing a piece), in the same style.
  4. **Empty closet:** it stays blocked from styling. Labelled ideas come with the real stylist in 27a.
  5. **Wording:** "Dark Mode" becomes "Dark appearance".
  6. **UI rules:** the Home shelf frames get 44 pt tap areas; selection ticks and colour dots lose their outlines.
  7. **Drawer plates:** they keep their short labels, since VoiceOver reads the full names.
  8. **Closet repo:** gets a basic ruleset on `main` and Dependabot alerts.
  
  **Stage B rule:** it doesn't start until Jose approves it. He sees the database and storage options (`STAGE_B_DATA_OPTIONS.md`) first.
- 17 October 2026: **Stage A audit closed.**
  - **Code audit fixes** (#44–#46): the Saved Looks Profile bug, store contract suites, stale-load guards, atomic writes, image retry, redacted measurement types, and snapshots cut to 56 MB.
  - **CI** (#43, #48, #49): 16–20 min (was 26–34), flaky tests fixed at the root.
  - **Polish from the decisions above** (#51, #52): the name and settings are kept, six tours added, "Dark appearance", 44 pt shelf frames, outline-free ticks and dots.
  - **Website:** source now in the app repo (#50).
  - **Playbook:** reorganised into 16 topic chapters.
  - **Final regression pass:** 1,289 passed, 0 failed. It found five display bugs, all fixed in #53, with a new check that fails any phone snapshot wider than its window.
  - **Still on Jose:**
    - 2FA on every account.
    - The project email, then switch git commits to it or the noreply address.
    - The TestFlight upload steps in `docs/testflight.md`.
    - The cutout benchmark on Lily's iPhone 12.
    - VoiceOver and iPad keyboard checks on devices.
    - Delete the untracked `closet/website/` folder (its content is in the app repo; only `ARTWORK.md` isn't).
    - Approve or change `STAGE_B_DATA_OPTIONS.md`.
  - **Next:** Stage B starts only when Jose approves it.
- 17 October 2026: **Device checks moved onto simulators** (jsayram/nifty-outfit-nook#54, #55). Jose doesn't have Lily's iPhone 12.
  - **iPhone 12 simulator:** the full UI suite passed at 390 × 844, and a screenshot walk found one bug (the Simulated badge at AX5), now fixed.
  - **Accessibility audit:** Apple's audit now runs on every main screen at default size and AX5, as the closest substitute for VoiceOver. Every exclusion has a reason, and contrast exclusions are re-measured from pixels (`docs/accessibility-audit.md`).
  - **Tours:** a test checks that the card is read first on each step.
  - **iPad keyboard:** ⌘F goes to search on Closet and Saved Looks, and Escape or ⌘. closes the top sheet.
  - **Taps:** every UI test tap now confirms its effect, and a check blocks bare taps (#54).
  - **Cutout:** the go/no-go moves to Phase 22a.
  - **Still needs a real device:** VoiceOver, an iPad hardware keyboard, A14 speed and memory, and the Data Protection class on the kept settings file.
- 17 October 2026: **Real sample wardrobe** (jsayram/nifty-outfit-nook#56, #57, #58).
  - **#56:** the demo's pieces now have AI-generated photos and cutouts (51 pieces, JPEG 2000 cutouts with alpha), going through the same path real photos will use. Also: the example try-on photo, six try-on previews, `demo:wardrobe=full` with 30 more pieces, and shared photos in the large closet.
  - **#57:** every screen snapshot preloads the real photos (`.snapshotPhotos()`).
  - **Real-photo audit:** 33 findings (7 high, 15 medium, 11 low).
  - **#58 fixes them, as Jose decided:**
    - **Try-on:** the demo has woman C as her try-on photo. Every try-on line now covers both kinds of picture, the person wearing the look or the pieces on their own, and everything stays Simulated. The badge never covers her. There are no more letterbox bands.
    - **Shoes:** sized from the cutout's real shape.
    - **Large closet:** pieces take their photo's colours.
    - **Renamed:** the taupe blazer, the nude pumps and the navy ballet flats.
    - **Decoding:** JPEG 2000 is decoded once per cutout. Saved Looks settles in 118 ms instead of 158 ms cold, and 105 ms instead of 199 ms after Closet (simulator, Debug).
    - **Also:** the medium and low fixes.
  - **Kept on purpose:** the hangers on 14 cutouts, the chair post in the tote, and the lace tops as the photo-tile fallback.
  - **Dropped:** the cool-weather preview, because it showed a vest.
  - **iPad:** installs and passes on a freshly created simulator.
  - **Still open:**
    - The office preview shows a gray blazer, and the not-yet-arrived cream crop is worn in an older picture. Both need new images.
    - Gold pieces are filed as Yellow.

- 18 October 2026: **Phase 19a done, checkpoint waiting on Jose.** `THREAT_MODEL.md` and `DATA_MAP.md` are updated for real data on the stack in `STACK.md` (SwiftData with `CKSyncEngine`, Clerk, Convex HTTP actions, Claude API, WaveSpeed, Cloudflare R2). Docs only; nothing signed up for.
  - **Threat model:** 14 concrete flows (F1 to F14), each with assets, trust boundaries, STRIDE threats, the control and the phase that builds it. The top risks are re-ranked and five new ones added: R11 Clerk as a processor, R12 the backup bucket, R13 agent and MCP access, R14 Clerk's 7-day session, R15 incomplete deletion. No Phase 0c risk retires; the RLS control is replaced by internal functions, a CI lint and cross-user tests.
  - **Data map:** every row now says where each copy lives, what deletes it and who can read it. Clerk, Convex, Anthropic, WaveSpeed and Cloudflare R2 are named processors, with the terms checked on their official pages today and the open questions for 19b.
  - **Findings:** Haiku 4.5 can't be pinned to US-only inference. WaveSpeed deletes outputs within 7 days, but no official page says how long it keeps inputs, whether it trains on them, or where it processes them.
  - **For Jose (decisions D1 to D10 in `THREAT_MODEL.md`):** WaveSpeed for her try-on photo; the `clerk-ios` dependency (ClerkKit only); the RLS wording in the standard; Clerk's 7-day session; where text requests are processed; email scope; backup key custody; the risks to accept in writing; the agent access policy; the export format.
  - **Plan gaps:** no 25b bullet builds the daily backup job, and the public-function lint belongs in 24a or 24c. DMARC is still missing.
  - **Next:** Phase 19b starts only when Jose has reviewed the data map and top risks.
- 19 October 2026: try-on tests on AI-generated test people (no real photos). Google Vertex takes one item per call, chained items drift, and the model retires in March 2027. OpenAI and FLUX.3 both do a whole outfit in one call. Jose picked FLUX.3, but BFL's standard API terms allow training on inputs, so real photos wait for BFL business terms or FLUX on Azure. Jose's idea of keeping the face on the phone worked in a prototype on every hard case. Phase 33 is now split into 33a (try-on with the on-phone head swap), 33b (photo setup with the in-app camera) and 33c (privacy walkthrough animation and "See what was sent", the last step once try-on is ready). D1 in `THREAT_MODEL.md` needs updating to match.
- 19 October 2026: Jose approved BFL's standard API for faceless photos, with disclosure in the app (consent screen, privacy policy, App Store privacy label). He accepts that BFL may keep the photos and train on them, because the face stays on the phone. No BFL business agreement or Azure is needed now. The same day he decided the app also swaps the room for a plain studio backdrop on the phone, so the room never leaves it. Review before outside testers or the public launch. `THREAT_MODEL.md` D1 and the data docs are updated to match.
- 19 October 2026: Phase 19a checkpoint passed. Jose approved D8 (accepted risks a, b, c, e and f, reviewed again before outside testers; d waits for Phase 20a) and D9 (agents never get production Convex access, a production deploy key, or the backup bucket). D1 was decided the same day. Phase 19b starts.
- 19 October 2026: **Phase 19b drafted, checkpoint waiting on Jose.** New folder `compliance/` (index in its README): the privacy manifest plan, App Store privacy label answers, permissions with purpose strings, in-app privacy and consent wording by phase, outlines for the privacy policy, terms and support page, a living App Review checklist, and questions for a lawyer. Docs only; nothing published, the app repo unchanged.
  - **Findings:** today's privacy manifest is already correct (`UserDefaults`, `CA92.1`, nothing collected). The App Store label has no free text, so BFL's training shows there as Photos or Videos with "Other Purposes"; the plain sentence lives in the consent screen and policy. BFL's privacy policy offers a training opt-out by email, a US-only endpoint, and 10-minute delivery URLs. The in-app try-on line predates D1 and needs the new wording. App Review 5.1.1(i) ("same or equal protection") and 5.1.3(ii) (no personal health information in iCloud) are risks to watch.
  - **For Jose:** approve the baseline; decide when to get the legal review (suggested: the "before testers" questions before anyone but Lily uses real data, the rest before 35a); whether measurements and weight ever go to Anthropic (before 27a); who the operator is for the policy and App Store; whether to ask BFL about the training opt-out; when to publish version 0 of the privacy, terms and support pages.
- 19 October 2026: Phase 19b checkpoint passed. Jose approved the compliance baseline in `compliance/` as the working draft (lawyer review before anyone but Lily uses real data; the web pages wait for him), and D2 to D7 and D10 as suggested in THREAT_MODEL.md. 23a and 23b are marked done (Convex chosen 18 October). Whether the stylist sends measurements or weight is decided before 27a. From here Jose asked for batch review: phases run back to back, each merged through its PR checks, stopping only at a real go/no-go or anything that needs him (accounts, keys, Apple setup). Account setup and loose ends wait.
- 20 October 2026: Jose switched the stylist's default model from Haiku 4.5 to Haiku 5.5 (about 10 times cheaper). Whether Haiku 5.5 can be pinned to US-only inference is checked in Phase 27a. Rote agent work also moves to Haiku 5.5. Global processing stays allowed (the app may expand beyond the US); US-only inference is an option to keep in mind.
- 20 October 2026: **Phase 20a done, checkpoint waiting on Jose** (jsayram/nifty-outfit-nook#60). The spike lives in the app repo's test target `PersistenceSpikeTests` and ships nothing; findings in its `docs/decisions/0003-persistence-spike.md`.
  - **Recommendation: GO on SwiftData**, with three conditions: a migration journal and recovery snapshot around every schema change, `CKSyncEngine` for sync (never SwiftData's own CloudKit mirroring), and stores as `@ModelActor`s that hand out value types only.
  - **Why the journal is needed:** SwiftData's custom migration stages aren't atomic. Killed with SIGKILL halfway, a store reopened as the new version with 150 of 300 image records and never finished. With the spike's coordinator, all 64 real kills of a 2,400-garment migration (every checkpoint, twice in a row, and 40 at random) recovered to a store matching every ID, count, image hash and relationship.
  - **The other gates:** the SwiftData closet, look and suitcase stores pass all 28 contract checks; 2,400 garments load in about 0.3 to 0.8 s off the main thread; 1,000 rapid saves from two actors lost nothing. A newer store is refused and left alone, never reset. Record and file linking, an export with original photos, and restore (including an old version, which migrates) are tested.
  - **Two offline devices:** PRD 11.7's rules as pure functions, against a stand-in CloudKit zone with change tags, in both reconnect orders: different fields merge, the same field keeps both values for review (no clock decides), removal and restrictions win, wear days and new pieces are all kept, a piece deleted for good never comes back, and a repeated delivery changes nothing.
  - **D8(d): no Data Protection exception needed.** `CKSyncEngine` writes no state file of its own; its state is `Codable` and the app keeps it as a row in the store, saved after the records, with the store's `complete` protection. The engine starts when protected data is available.
  - **Release builds stop shipping sample data:** the sample sets and `-fixtures` are Debug-only and checked in Release; onboarding there has three steps and an empty closet. `scripts/check-release.sh` also had a `pipefail` bug that let it pass when it shouldn't; fixed. The 12 MB of sample photos still ship unused, because SwiftPM copies package resources in every configuration and the build-script sandbox blocks removing them.
  - **CI fixes on the way:** a test job that builds for itself now keeps one `.xctestrun`; the iOS 27.0 snapshot flake in `startingPieceSheet` is fixed at the root (its lazy grid drew 675 or 693 points tall depending on the process; still images now use a plain grid layout, 5 of 5 full runs green on an iPad simulator); `piecesIPad`'s different failure (PNG encoding) got a defensive fix that couldn't be reproduced locally.
  - **Still needs a real device or iCloud account:** Data Protection classes on the store files, a migration killed on an iPhone and its speed on the A14, and a real `CKSyncEngine` on two devices (push, sign-out, zone deletion, quota, Advanced Data Protection).
  - **For Jose:** GO or NO-GO on SwiftData; whether to upload TestFlight before 21a, now that a Release build starts empty and keeps nothing (and some in-app wording still says sample data); how to drop the sample photos from Release (sandbox off for the app target, or move them); and agree D8(d) needs no exception.
- 20 October 2026: **Phase 20b done, checkpoint waiting on Jose** (jsayram/nifty-outfit-nook#61, merged into `develop`). Docs only. The design is the app repo's `docs/decisions/0004-backup-and-recovery.md`, and `docs/settings.md`, `onboarding.md`, `models.md` and `testflight.md` point to it. DATA_MAP.md, THREAT_MODEL.md (R7, F2 to F4, D7's scope) and the privacy manifest plan are updated to match.
  - **Safety copies:** the 20a migration snapshot, also taken before a restore and before the first iCloud merge. Kept 7 days at most, left out of device backups, with Undo restore and Undo iCloud merge.
  - **Device backups** keep the store and photos. A Keychain marker that never leaves the device tells the app a store came from a backup, so sync starts fresh there.
  - **Export (D10):** an Apple Encrypted Archive with a passphrase (scrypt, AES with HMAC, streamed). It's Apple's own framework, so no dependency. Inside: JSON records, deletion markers and the original photos, with a hash for every file. The passphrase is never stored or recoverable. Check a copy tests a file without restoring it. Expect about 1.3 to 1.5 GB for 300 pieces and 4.4 to 4.9 GB for 1,000. If AEA fails in 21b, the fallback is PBKDF2 from CommonCrypto with chunked CryptoKit AES-GCM, also with no dependency.
  - **Restore:** every check runs before anything is written (authentication, bounded extraction, hashes, references, deletion markers). Then a preview, and she picks Replace or Add what's missing. A journal makes it safe to kill.
  - **iCloud:** off, and hidden until 21b's restore and two-device tests pass. One encrypted payload per record. Images are separate records that never change. No plain fields beyond the record ID, type and system fields. Without ADP Apple could decrypt everything (D8(a)); with ADP it's end-to-end, apart from record types, counts, sizes and dates. Every account event (sign-out, switch, full storage, zone deleted in Settings, encrypted data reset) has a defined response, and one account's data never uploads into another.
  - **Delete my data** deletes the iCloud zones. If iCloud can't be reached, that part shows as pending and runs first at the next connected launch. Other devices ask before they erase.
  - **Also designed:** the recovery screen after three failed migrations (with an export of the raw store) and the new-phone and lost-phone flows. A 21b test plan marks what needs a real device or iCloud account.
  - **Carried forward:** 21a declares the disk-space reason `E174.1`, because the migration coordinator checks free space. 21b rechecks `ITSAppUsesNonExemptEncryption` and the macOS commands that open an export.
  - **For Jose:**
    1. Approve the design.
    2. Body data in iCloud (App Review 5.1.3(ii)). Suggested: keep the `Me` zone (measurements, weight, fit notes, try-on photo) off until the lawyer answers. Also decide whether iCloud Backup needs the same treatment.
    3. Safety copies after a purge: accept that a purged piece's text stays in a copy for up to 7 days (its photos go at once), or delete the copies instead.
    4. Delete my data on other devices: ask first (suggested), or erase automatically.
    5. Whether onboarding gets an iCloud step once 21b passes. It may need Lily's look.
    6. Permissions after a restore: suggested that each feature asks again.
    7. Replace and Add what's missing together in 21b, or Replace first. And where conflicts to review are shown.
    8. Apple setup only Jose can do: the iCloud capability, the container `iCloud.com.jsayram.niftyoutfitnook`, and two test Apple Accounts (one with ADP on, one nearly full).
    9. Passphrase rules: at least 12 characters, or a generated one.
- 20 October 2026: **Phase 21a done, checkpoint waiting on Jose** (jsayram/nifty-outfit-nook#62, merged into `develop` with every required check green). Built overnight without Jose; nothing here needed a product decision to proceed, and the ones it touched are listed below.
  - **Real storage:** her data lives in one SwiftData store on the iPhone (`Application Support/Store/Nook.store`, Data Protection `complete`), as one `StoredRecord` per value: a kind, a stable key and the value type's JSON with a payload version. That follows 20b (JSON records in the export, one encrypted payload per CloudKit record) and keeps the SwiftData schema small. Every store protocol has a real `@ModelActor` store handing out value types only, and they pass the same contract suites as the in-memory ones. A golden test keeps a version 1 payload of every kind that later builds must still read.
  - **Migrations from day one:** the 20a coordinator is app code (`Services/Storage`): version from metadata before opening, free-space check, journal, snapshot left out of backups, a manifest of every record's kind, key and payload hash, verify, snapshot put back at the next launch, three tries per app build, cleanup after seven days, and Delete my data deletes a verified migration's snapshot at once. A newer or damaged store is never opened or reset; a short recovery screen says so (0004 §7 wording, no buttons until 21b).
  - **Moved into the store:** the whole profile (name on the sign, remembered source and occasion, fit, measurements), both kinds of draft, the unsent feedback note, and the onboarding and tour flags. The first 21a launch moves Stage A's `UserDefaults` suite in once and empties it. Tour records (how each ended) stay in memory, as the data map splits them.
  - **Delete now** in Recently deleted, with the preview in its question: photo and details, an unsaved Edit (deleted with it), the saved looks that keep their other pieces, the suitcases it leaves, and that try-on pictures stay.
  - **Behaviour kept:** Release keeps everything. Debug's sample closet and `-onboarding skip` stay in memory, so `-fixtures` (including `wardrobe=full`) and every UI test work as before; Debug's empty closet uses the real store. `-onboarding reset` also clears the store. Help, Privacy and terms and onboarding now say what's kept instead of claiming the app forgets it.
  - **Privacy manifest:** disk space `E174.1` added for the free-space check; `UserDefaults` `CA92.1` stays (the move reads the suite). Sizes are read with `fileSizeKey`, so no file-timestamp reason.
  - **Checkpoint proof:** automated (a relaunch round trip of every demo record and 300 large-closet garments; a crash at each of 11 migration checkpoints recovering with every record; a lossy migration rolled back; a UI test that adds a piece to the empty closet and finds it after a relaunch). By hand on an iPhone 12 simulator (iOS 26.5): added a piece, relaunched (still there), installed a build with a temporary version 2 schema (a new column on `StoredRecord`) over it; the journal said verified, the column was added, and the hash of every payload matched the one from before. Reinstalling the version 1 build showed "This closet was saved by a newer version" and left the file unchanged. The temporary schema isn't committed.
  - **Tests:** 1,352 package tests (Models 232, Fixtures 182, Services 78, Features 743, DesignSystem 82, the spike 35). New: store contracts on every real store, the relaunch round trips, the migration crash matrix, the `UserDefaults` move, payload fixtures, Delete now, the kept feedback note and the root's recovery state. Two new UI tests: a piece kept after a relaunch, and Delete now. Eight snapshots were re-recorded from CI for the new words and button, and one more after a CI fix.
  - **CI fixes on the way:** `anotherSuitcaseInDark` changed height between runs (a lazy grid measured from estimates), so the garment grid draws eagerly in still images, as 20a did for the Starting piece sheet; that layout then trapped on an infinite width and crashed the snapshot process once, now fixed. `piecesIPad` passed every run.
  - **DATA_MAP.md** rows updated: Add a piece and Edit drafts (new, Sensitive), the look draft, the unsent feedback note (new), the remembered source, Preferences, the name on the sign, app state flags, safety copies, and the device paths.
  - **For Jose:**
    1. GO on SwiftData was still open from 20a; 21a builds on it as recommended. Say if that's not what you want.
    2. Delete now keeps try-on pictures that show the piece (Stage A's rule); PRD §7.4 would purge them. And deletion markers wait for 21b.
    3. The new in-app wording on what's kept (onboarding step 2 and step 4, Help's "Your data", Privacy and terms) and the recovery screen's words. Lily hasn't seen either.
    4. The debug sample closet stays in memory rather than being copied into the store, so fixtures keep working; only the empty closet and Release persist.
    5. Still from 20a: whether to upload TestFlight now (a Release build now keeps what Lily adds), the Help version line that still says "test build with sample data", and the 12 MB of sample photos in Release.
  - **Needs a device:** the Data Protection class on `Nook.store`, its `-wal` and `-shm`, the journal and the snapshot, and that the store can't be read while the phone is locked (the simulator reports no class); a real relaunch after iOS ends the app; migration timing on the A14.
- 20 October 2026: **Phase 21b done, checkpoint waiting on Jose** (jsayram/nifty-outfit-nook#64, merged into `develop` with every required check green). Export, Check a copy, restore and recovery tests, all on the phone. iCloud sync isn't built: the container and the two test Apple Accounts don't exist yet, so it stays off and hidden and no entitlement was added. The open 0004 decisions use the suggested defaults. No new dependencies.
  - **Jose's answers to 21a's questions (20 October 2026):** (1) when a piece is deleted for good, by Delete now or the 30-day purge, the try-on pictures that show it are deleted too, as the PRD says; built in its own commit, with tests, and a restore or Add what's missing never brings them back. (2) The 21a wording on what's kept and the recovery screen's text are approved as they are, and can be tweaked later. (3) The debug sample closet resetting at each launch is fine. (4) No TestFlight upload until the app is stable.
  - **Backups** on Privacy and terms and Profile, wherever her closet is in the store (her own closet and every Release build): Export a copy, Check a copy, Restore from a copy, Undo restore for 7 days. Onboarding's welcome has Restore from a backup file. The recovery screen has Export a copy (the raw store and photos, encrypted the same way).
  - **The file** is an Apple Encrypted Archive (scrypt passphrase, AES with HMAC, LZFSE), encrypted as it's written, with `NOOK-BACKUP 1` as the only clear text. Inside: a manifest first with every file's size and SHA-256, one readable JSON file of records per kind, deletion markers, and the photos the records point to. Passphrase: one the app makes (24 symbols, about 120 bits, Copy passphrase lasts 2 minutes on this iPhone only) or her own of at least 12 characters, typed twice. Never stored. A Mac opens it with `aea decrypt` and `aa extract` (checked).
  - **Restore** checks everything before writing anything (authentication, no bytes after the end, safe paths, no links, entry and size limits, free space, every hash, every record decoded and checked as a save checks it), shows a preview, then Replace or Add what's missing. It takes a safety copy, writes every record in one save (so a kill leaves the old closet or the whole new one), and the app rebuilds its screens on fresh store actors. A piece deleted for good never comes back.
  - **Changed from 0004, and why** (written up in its "Built in Phase 21b" section): one records file per kind (measurements stay in the profile file); the restore writes in the running app rather than at the next launch; the restore's safety copy sits in `Store/RestoreSafetyCopy` because a migration clears `Recovery`; Add what's missing keeps the copy's differing version as a review record, with no review screen until sync.
  - **Found on the way:** AEA ignores bytes after its end (the reader checks the size), and `replacePersistentStore` leaves a copy's data in its own `-wal`, which emptied the recovery screen's store copy until it was checkpointed. Export compliance rechecked against Apple's page: `ITSAppUsesNonExemptEncryption` stays NO; see question 2.
  - **Checkpoint proof, on the iPhone 12 simulator (iOS 26.5):** a fresh install, onboarding with a name, three pieces added to her own closet, measurements, and three real photo files with two pieces and the try-on photo pointing at them (standing in for 22b's photo store, set in the store file by hand). Exported with her own passphrase and saved On My iPhone through the Files sheet; the store was unchanged by the export and no unsaved copy stayed in `tmp`. Deleted the app, installed it again, Restore from a backup file on the welcome, Replace: every record matched field for field and all three photos matched by SHA-256, and Home opened on her closet. The passphrase wasn't anywhere in the app's container.
  - **Tests:** 1,407 package tests on CI (Models 233, Fixtures 182, Services 120, Features 755, DesignSystem 82, the spike 35; 55 more than 21a) and every UI test class. New: 40 backup tests (round trips of the demo, the 2,400-piece closet and an empty closet; a wrong passphrase; tampering in five places, a cut file, an extra byte and swapped blocks; crafted archives with `..`, absolute paths, links, too many entries, wrong sizes, unlisted, missing and changed files, too little space and records that fail their checks; a format 1 fixture file every later build must restore; nothing personal in the clear; what's left out; the passphrase never written; Replace and Undo; Add what's missing; deletion markers; a kill at each of six restore steps in both modes and during Undo; safety copy expiry and Delete my data; space checks), 7 Backups model tests, the purge tests, eight new snapshots (recorded on the iOS 26.5 simulator, checked by eye, and matching on CI's iOS 27.0), and a UI test from onboarding to the Files sheet.
  - **CI on the way:** merged the latest `develop` (the Release cleanup, #63) before merging, with no conflicts. `ComponentSnapshotTests.iPad` failed once with "Newly-taken snapshot's data could not be loaded", the iOS 27.0 problem 20a fixed for one suite; the 8-bit sRGB redraw moved into `NookTestSupport` and every snapshot helper that had it, plus the component helper, now uses it. Develop's own push runs after #62 and #63 failed in the catalog UI tests on the runner (a stalled test runner, then `kAXErrorServerNotFound`), not in code; this PR's run of the same job passed.
  - **Simulator note:** the "21b iPhone 12" simulator I made disappeared mid-session (not deleted by me); I made a second one the same way and deleted it at the end.
  - **Parked, waiting on Jose:** every device test in 0004's plan (file protection classes on the store, `-wal`, `-shm`, staging and the safety copy; APFS clone sizes; export and restore of 300 and 1,000 pieces on the iPhone 12 for time and memory; the Keychain marker after a backup restore; export carrying on in the background) and every iCloud test (two devices, ADP on and off, account changes, quota, Settings deletion, new phone from iCloud), plus the sync layer itself. Also waiting: a store copy from an older schema (needs the app's first real schema change), removing a purged piece's photos from safety copies (22b), and Try again and Send feedback on the recovery screen.
  - **DATA_MAP.md** rows updated: the device row, try-on pictures (purged with their piece), safety copies, the export archive, restore staging, the F4 flow, and new rows for deletion markers and review copies.
  - **For Jose:**
    1. 0004's nine decisions are still open; 21b used the suggested defaults (Replace and Add what's missing together, no consent receipts in exports, 12-character passphrases, body data kept out of iCloud since sync isn't built). Approve or change them.
    2. Export compliance: Apple says OS-provided encryption is typically exempt from the documentation upload but may still need a year-end self-classification report to the US government. Decide whether to file one, or ask the lawyer.
    3. Apple setup for the parked tests: the iCloud capability and container `iCloud.com.jsayram.niftyoutfitnook`, two test Apple Accounts (one with ADP, one nearly full), and a real iPhone for the device tests.
    4. Conflicts from Add what's missing are kept but not shown anywhere yet. Fine until sync, or show a count on Backups now?
    5. Lily hasn't seen the Backups screens or the new welcome button.

- **20 October 2026, release cleanup: sample photos out of Release builds** (nifty-outfit-nook PR #63).
  - The 12 MB of sample photos no longer ship in Release, TestFlight or App Store builds. They live once in `Packages/NookKit/Tests/NookTestSupport/SampleWardrobe`: the package tests read them as a `NookTestSupport` resource, the app target copies the same folder in, and `Configs/Release.xcconfig` excludes it (`EXCLUDED_SOURCE_FILE_NAMES`). The script sandbox stays on. This closes the 20a open question about the 12 MB.
  - `scripts/check-release.sh` now inspects the built app and fails on the folder, a Fixtures or test-support bundle, or any file named like a sample photo. Shown failing with the exclusion off and with planted files, and passing after. Release `.app` 73.6 MB to 61.0 MB (simulator build).
  - Checked: FixturesTests, ServicesTests, the sample wardrobe snapshots and the Closet and Home UI tests on an iPhone 12 simulator; CI green. One CI shard (`ui-home-and-settings`) hit its 40-minute cap on a slow runner (unrelated tests ran 2 to 4 times slower, an accessibility audit timed out) and passed on re-run in 31 minutes. It normally takes 34, so it has little headroom.

- 20 October 2026: **Phase 22a done, cutout go/no-go waiting on Jose with a real iPhone** (jsayram/nifty-outfit-nook#66, merged into `develop` on 21 October 2026 with every required check green, after merging in 21b, the CI rebalance and 21c). Real photos come in from the camera and the system photo picker, for garments and the try-on photo, and only a copy with no metadata is kept. No new dependencies.
  - **Where it's on:** her own closet and every Release build. The debug sample closet and the tests keep Stage A's stand-ins, so fixtures and the existing UI tests work as before.
  - **Choose from Photos** opens the system picker (`PhotosPicker`, `preferredItemEncoding: .current`): no permission and no Info.plist key. **Take photo** follows PERMISSIONS.md. The app's own sheet comes first (Continue or Not now), then iOS's prompt with "Take photos of your clothes to add them to your closet." If access is off, the alert offers Open Settings or Choose a photo. With no camera or a restriction, it offers the picker. The camera is the system one (`UIImagePickerController`, photo mode). Paste isn't offered with real photos (question 2).
  - **Metadata:** `PhotoCleaner` decodes the main picture upright (at most 4,096 px long, over 100 MP refused unread) and writes a new JPEG from the pixels alone, so no location, camera, lens, serial number, time, captions, XMP, depth or gain map survives. The bytes she picked are never written. Copies go in `Application Support/Photos`, the folder 21b's backups carry, with Data Protection `complete`. Exports include them, and Delete my data removes them with the backups' files.
  - **Why JPEG, not HEIC:** on the iOS 26.5 simulator a HEIC encode never finished (it waited inside VideoToolbox), so the tests and the checkpoint would hang. HEIC would be about half the size; 22b can revisit it on a device.
  - **Try-on photo:** Profile's sheet has Choose from Photos (Change photo once set), a line on what makes a good photo, and her photo covered in the app switcher. Changing or removing it deletes the old file at once. If the profile can't be saved, the new copy is deleted.
  - **Photos nothing points to:** one replaced before saving, a discarded new piece's photo and a discarded draft's photo are deleted at once. The photo a saved edit replaced and a purged piece's photos stay until 22b's sweep.
  - **Storage seam kept simple for 22b:** `PhotoIntake` gained `keep`, `discard`, `sources` and `usesSystemPicker`. `PhotoFileStore` is a plain folder using 21b's `PhotoFiles` naming, and `StoredPhotoProvider` reads it for every screen. No thumbnails, cache or disk-space handling yet.
  - **Wording:** onboarding step 2 no longer says the app never asks for the camera, the empty closet choice says "with your own photos", and Help's Add a piece note in her own closet says how photos are kept. `scripts/check-archive.sh` now allows exactly one permission key, the camera's, with its words.
  - **Cutout:** nothing changed in the pipeline. Real photos aren't cut out yet and show in a tile, which is also the fallback when lifting fails. `-cutout-bench` was checked on the iPhone 12 simulator: it opens, Choose photos opens the picker with no prompt, and the drawn samples run and report no times, since Vision can't lift there. **Parked, waiting on Jose (real device):** the go/no-go run on Lily's iPhone 12 (steps in the app's `docs/cutout-feasibility.md`), plus the HEIC test cases, which now run on a device only.
  - **Checkpoint proof, iPhone 12 simulator (iOS 26.5, Xcode 27.1):** I added three sample photos with planted GPS, camera make, model and serial using `simctl addmedia`. The picker showed "Location Is Included". Through onboarding to the empty closet, I added a black tee and a sundress from the library. Each kept file has no GPS, no TIFF maker fields and none of the planted text, and the tee was still there with its photo after a relaunch. Take photo showed the explainer, then iOS's prompt with the purpose string, then (after Don't Allow) the Settings or photo alert, whose Choose a photo opened the picker. With access allowed, the simulator's camera opened but its shutter captures nothing, so Cancel was the path it allows. The try-on photo from the library showed on the sheet with no GPS in its file, and Remove deleted the file. After merging 21b I added a piece again and confirmed it landed in the shared folder.
  - **Tests:** on CI, 1,447 package tests: 1,441 passed and 6 skipped on the simulator (the five Vision cutout tests and the HEIC case), plus every UI part. New: `PhotoCleanerTests` and `LocalPhotoIntakeTests` (17 on the simulator, with the HEIC cases on a device), `PhotoPickingModelTests` (9), `RealPhotoIntakeTests` (11), 3 more `ProfileModelTests`, and the UI test `testHerOwnClosetOffersTheCameraAndPhotos`. Five onboarding snapshots were re-recorded from CI for the new wording. On the fourth CI run the UI test runner in build-and-archive failed to start twice before any test ran ("crashed while preparing", then "Timed out waiting for AX loaded notification"); the same tests passed in every other run, and the next full run after merging 21c was green.
  - **Found on the way:** HEIC encoding hangs on the iOS 26.5 simulator, and HEIC decoding stalled CI's iOS 27.0 simulator, so HEIC test cases run on a device only. ImageIO adds generic Exif fields of its own to any JPEG, so the tests search the file for planted values instead of expecting empty Exif. An English-only `InfoPlist.xcstrings` isn't copied into the build, so the purpose string lives in the build setting until the first translation.
  - **DATA_MAP.md** rows updated (device, try-on photo, garment photos, garment-understanding upload, F1), along with compliance/PERMISSIONS.md and the IN_APP_PRIVACY_TEXT note on the naming aid. The playbook gained four lessons.
  - **For Jose:**
    1. The optional garment-understanding upload ("Describe my photos") is left out, and nothing about a photo leaves the phone. Keep it out, or should a later phase build it with its own named processor and consent?
    2. Paste with real photos: build it (iOS asks "Allow Paste?" every time, unless it's a system Paste button) or leave it out?
    3. Kept photos are JPEG at most 4,096 px. Fine for now, or should 22b test HEIC on a device for about half the storage?
    4. The cutout go/no-go needs Lily's iPhone 12 and about 20 of her photos (15 minutes, steps in `docs/cutout-feasibility.md`). The same session can run the device-only tests.
    5. Lily hasn't seen the camera explainer, the new Add a piece line or the try-on photo sheet's real version.
- 20 October 2026: **Phase 21c done, checkpoint waiting on Jose and Lily** (jsayram/nifty-outfit-nook#67, merged into `develop` as 4bcff42 with every required check green). Only the parts that don't need Lily's answer: favorites, collections and Archive wait for her (questions below). No new dependencies.
  - **Other names** (PRD §7.6) on Add a piece and Edit: a field with Add name, each name a chip that removes itself ("Remove Date-night top" to VoiceOver). Up to 10, 40 characters each; a repeat (ignoring case and accents) or the piece's own name is refused with a reason; a name typed but not added is added on Save. Garment detail lists them.
  - **Type** under Kind (the mockup's second row of kinds): Tops, Layers, Bottoms, Shoes, Bags and Accessories each have a short list, with None of these. Changing the kind drops a type that doesn't belong. Dresses have none yet. Garment detail shows it under the kind.
  - **Search:** Closet (and Swap and the piece picker, which share it), Style Me's starting piece and Saved Looks find a piece by its other names and type.
  - **Earlier results (LR-06.4):** Saved Looks' typed search also lists matching Style Me results she didn't save, under "Earlier results, not saved". Chips alone don't bring them up, and they never show otherwise. One opens on look detail with its facts ("Casual · Simple · Made Oct 11 · Not saved"), Save look and its pieces; Save look names it as Your looks would, with Undo.
  - **The app's first real schema change.** Garments and garment drafts are payload version 2. Version 1 JSON reads as it is (a missing field means none), so nothing is rewritten; a record moves to 2 when next saved. The bump is there because `JSONDecoder` ignores unknown keys: a 21b build would have read a garment without its other names and lost them at its next save. The store schema is version 2 at the same time with the same columns (a hash modifier on `payloadVersion`), so a 21b build sees a newer store and stops at the recovery screen before reading a record. The 1 to 2 migration is a lightweight stage through the 21a coordinator (journal, snapshot, manifest, byte-for-byte check). Rule written into `RecordPayload` and `docs/models.md`: every payload bump an older build would misread needs a schema bump too.
  - **Backups** carry the new fields. The manifest's payload version is 2, so a 21b build refuses a 21c copy as "from a newer version". The archive layout didn't change, so `formatVersion` stays 1.
  - **Proof, with files the 21b build wrote.** Before any change, `develop` at b0c063c wrote the demo closet (every kind of record, three photo files) and saved its schema 1 store, a records export, the recovery screen's store copy and every row as stored; they're test fixtures now. Tests: the store migrates with all 50 rows byte for byte; a crash at each of the 8 migration checkpoints recovers; the new fields save and survive a relaunch; the 21b plan refuses the version 2 store and leaves it unchanged; the records export restores with Replace and with Add what's missing (her newer other names stay, the copy's older piece is kept as a conflict); the schema 1 store copy migrates in staging and restores both ways, which closes the store-copy item 21b parked; a new export carries the fields and restores.
  - **Checkpoint by hand on the "21c iPhone 12" simulator (iOS 26.5):** installed the `develop` build, onboarding with "Lily" and an empty closet, added "Navy blazer". Installed this build over it: journal 1 to 2, verified, 5 records, every payload hash unchanged, Lily's sign and the piece there. Edit showed Other names and Type; Blazer and two other names saved (one added by Save), a draft with them survived a relaunch, and Closet search found the piece by an other name ("1 of 1 piece"). Only the edited record moved to payload 2. Installed the `develop` build again: "This closet was saved by a newer version", store hash unchanged. Earlier results weren't tried by hand (an empty closet can't run Style Me); the tests cover them.
  - **Found on the way and fixed:** typing in Other names right after another change lost a letter, when the half-second draft save landed mid-word (typing in other fields pushes it back; this field didn't). And Return-to-add left the vertical text field two lines tall without focus; Return now just ends editing, as in every one-line field, and Add name or Save adds the name.
  - **Tests:** 1,440 package tests on CI (Models 243, Fixtures 182, Services 132, Features 766, DesignSystem 82, the spike 35; 33 more than 21b) and every UI test class. New: `SchemaV2MigrationTests` (5, one run at 8 checkpoints), `OlderBackupTests` (5, one in both modes), 2 in `RecordPayloadTests`, `OtherNamesTests` (10), `OtherNamesEditorTests` (8) and `EarlierResultsTests` (3). The five Add a piece form snapshots and the edit tour step were re-recorded on the iOS 26.5 simulator, checked by eye, and match on CI's iOS 27.0; the filled form now shows a type and an other name.
  - **CI:** the first run passed every test, but `ui-home-and-settings` hit its 40-minute cap: it waited 8 minutes for a runner, then two accessibility audits ("Audit failed to complete in time", one on Style Me screens 21c didn't touch) timed out on a slow runner and were retried. Instead of re-running, waited for the CI agent's shard rebalance (#65), merged the latest `develop` with no conflicts, and the second run was green (that shard 31 minutes).
  - **DATA_MAP.md:** the garment row (type, other names, in exports) and the looks row (earlier results found by search, nothing new stored).
  - **For Jose and Lily:**
    1. Favorites and collections for saved looks (RD-08, FR-13, FR-49): does Lily want them?
    2. Archive for garments (LR-16, PRD 7.4), apart from "I don't have it any more": wanted?
    3. The type lists, the label "Type" (the app already calls the category "Kind") and "None of these": right words and pieces? Dresses have no types yet; Describe in words doesn't suggest a type.
    4. Earlier results come up only with typed search, not chips alone. Is that how she'd look for them?
    5. PRD §7.6's possible matches, Remember this name and alias history aren't built. Later phase, or not needed?
- 21 October 2026: **PRD §7.6 possible matches and Remember this name done** (jsayram/nifty-outfit-nook#69, merged into `develop` as e6c2a95 with every required check green). Jose answered 21c's question 5 on 21 October: "Just do it now if it's just additive during development or if it's not too complicated." It was: everything runs on the phone, with no service, data processor, dependency or schema change. No new dependencies.
  - **Possible matches** in Closet: when no piece has every typed word, "No pieces match" is followed by a labelled Possible matches section, kept apart from real results. Each piece shows "2 of 3 words", VoiceOver reads which words it has and which aren't recorded, and the line above names any word none of them has. Chips, swatches, the Suitcase filter and Dirty still apply in full. Filler words ("my", "the" and a few more, translatable) don't count, it needs two other words, and it shows at most eight. The rule is `GarmentFilter.possibleMatches` in Models. Closet only: Swap's See all and the piece picker share the model but don't show them.
  - **Remember this name** on garment detail, only after opening a possible match: her search words (minus filler words) in a field she can change, "Only these words are kept, on this piece. Your search isn’t saved.", then Remember or Not now. Remember adds them to the piece's other names through 21c's rule, with Undo, and the same search then finds the piece as a real result. Not now keeps nothing. No card when the words are already one of its names, when it has 10 other names, or when it isn't in her closet.
  - **Why it needed no schema change:** a remembered name is an ordinary other name (21c's payload version 2), so 21c's migration, older-backup and restore tests already cover it. No new migration or backup tests were needed.
  - **Not built:** spelling and synonym help ("baggie" / "baggy") and quoted phrases, which Closet search doesn't have yet; and alias provenance or history (where an other name came from), which would need a schema change.
  - **Checked** on the "76 iPhone 12" simulator (iOS 26.5, Xcode 27.1): the new package tests, `GarmentFilterTests`, `ClosetModelFilterTests`, the Closet and garment detail snapshots and every `ClosetTests` UI test, including the new `testPossibleMatchesAndRememberThisName` (search "navy party pants", open the possible match, Remember, back on Closet the piece is a real result). Not tried on an iPad; the words carry over when the detail sits beside the grid. CI: the first run waited on busy runners; once 22a landed on `develop` it was merged in with no conflicts, the new tests and the UI test passed again locally, and the second run passed every check.
  - **Tests:** `PossibleMatchesTests` (Models, 9), `ClosetPossibleMatchesTests` (5), `RememberThisNameTests` (8), three new snapshots (`possible-matches`, `remember`, `remember-ax5`) checked by eye, and the UI test. One local run of `GarmentDetailSnapshotTests.tanLoafersNeverWorn`, which this change doesn't touch, missed by 1.7% of pixels with no visible difference and passed the run before; left for the snapshot flake work.
  - **DATA_MAP.md:** the garment details row says Remember this name keeps only the words she confirms, never the search.
  - **Jose's other 21c answers (21 October 2026):** (1) no favorites or collections; saved looks stay plain for now. (2) No Archive for garments. (3) The type lists are fine; change them later if needed.
  - **For Jose and Lily:**
    1. Lily hasn't seen Possible matches or the Remember card. Is "2 of 3 words" clear enough, or would she rather see the missing words on each piece?
    2. Remember is offered only after opening a possible match, not after a real result. Should it also offer when her words found the piece but aren't one of its names?
    3. Alias provenance (where a name came from) needs a schema change. Wanted later, or not needed?
- 21 October 2026: **Saved Looks gets a Saved | All switch** (jsayram/nifty-outfit-nook#70, merged into `develop` as 592a0c9 with every required check green). Jose's decision, after seeing 21c's "Earlier results" group: "it should be unambiguous". It replaces that group and the rule behind it (only typed search brought unsaved results up). No data model change, no new dependencies.
  - **What Jose decided:** a two-option switch at the top of the Looks tab, Saved (the default) and All. Saved lists only her saved looks. All lists her saved looks and every Style Me result she kept but didn't save, in one list, each unsaved one with a "Not saved" tag and a Save look button. Search and the filters work the same in both, with no special cases. On Saved, when the search or filters also match unsaved looks, one line ends the results, "N more in All", and tapping it switches to All and keeps them. The scope goes back to Saved each time she leaves the screen (the app keeps no screen state, so there was nothing to restore).
  - **Choices I made inside that decision:** the line needs a typed search or a chip, so an unfiltered Saved never says "34 more in All"; it also shows under "No saved looks match", where it matters most. All is ordered by when a look was made, so saving one changes it where it is and doesn't move it; Saved stays newest saved first. An unsaved look shows when it was made ("Casual · Made Oct 11"), since several can share a name. On All a colour only an unsaved look has gets a swatch; on Saved it doesn't, and a swatch she turned on stays until she turns it off. Every state names its scope: "Nothing saved yet" and "No saved looks match" on Saved, "No looks yet" and "No looks match in All" on All. The tour only runs on Saved.
  - **Accessibility:** the switch is "Which looks to show", each option says what it lists as a hint. "N more in All" is a button with a hint. An unsaved look reads "Casual, Made Oct 11, Not saved"; Save look is its own button named for the look ("Save look: Casual look"). Layouts checked at AX5 on phone and by the accessibility audit on All.
  - **Tests:** `SavedLooksScopeTests` (replaces `EarlierResultsTests`: both lists and their order, 15 search, chip and swatch cases on both scopes, the nudge count, empty and no-match states, swatches, Save look in place with Undo); 9 new snapshots (Saved with the line, All in light, dark and AX5, both scopes with no matches, both empty states, All on iPad) and 13 re-recorded on the iOS 26.5 simulator, which matched on CI's iOS 27.0; three new UI tests; the accessibility audit now covers All at the default size and AX5. By hand on the "scope iPhone 12" simulator (iOS 26.5): "denim" and Bottoms on Saved showed "1 more in All"; it opened All with both kept and the tag; Save look named the look "Cream & denim" in place; Saved then listed both.
  - **Docs:** app `docs/saved-looks.md` (the scope, the states, the tests, decision 10), `docs/ipad.md`, `docs/tours.md` and `docs/accessibility-audit.md`; here the PRD amendment's LR-06.4, DATA_MAP.md's looks row and the Phase 21c line in the plan. The 21c entry above stays as it was written.
  - **CI:** all green, but it took long because the macOS runners were shared with three other agents (the UI shards queued about 40 minutes). Develop moved twice before the merge (22a, then name memory); the second merge hit a conflict in `Localizable.xcstrings` (both added keys), which I resolved by re-applying my keys on develop's file. One UI test, `testAShelfFrameOpensItsLook`, broke because the switch pushed the last look out of the lazy grid, so it now scrolls first.
  - **For Jose:**
    1. Is "10 looks, 1 not saved" the right count under the title on All, or should it just say "10 looks"?
    2. The nudge needs a typed search or a chip. Should it also show on a plain Saved list?
    3. Lily's question 4 from 21c (earlier results only with typed search) is answered by this change.
- 21 October 2026: **Phase 22b done, checkpoint waiting on Jose** (jsayram/nifty-outfit-nook#72, merged into `develop` as fa8fea3 on 21 October 2026 with every required check green, after merging in 24a, the Saved | All switch and possible matches). Image storage and caching, written up in the app's `docs/image-storage.md`. No new dependencies, no backend.
  - **Thumbnails:** 512 and 1,024 pixels in `Library/Caches/Thumbnails`, made from the pixels alone the first time a screen asks, Data Protection `complete`, never in a backup, at most 200 MB (least recently used go first; the order is kept in memory, so no file dates are read). Larger sizes read the image itself. The memory cache now holds at most 64 MB of pixels as well as 300 pictures.
  - **Originals next to cutouts:** a cutout is its own PNG next to its original (`PhotoFileStore.addCutout`), carried by exports, thumbnailed and removed with its piece. Making cutouts of her photos still waits for the go/no-go.
  - **Low space and failed writes:** a new photo is only written if 50 MB stays free (Add a piece's existing "may be out of space" error). Thumbnails aren't written below 500 MB free, and the folder is halved. Every write is atomic; a stray temporary file is swept.
  - **Files nothing points to:** removed at launch (away from the screens), when a piece is deleted for good (photo, cutout, its Edit's photos, its pictures' stored images, thumbnails, and the restore's safety copy, which closes 21b's parked item), when Delete picture's Undo has gone, and when a made picture isn't kept. What counts is the same list exports use, files written since launch are spared, nothing goes while the store can't be read, and the sweep shares a lock with restore.
  - **Fixed on the way:** exports now carry the photos of review copies from Add what's missing (the sweep would otherwise have removed them), and Undo restore leaves out the try-on pictures of pieces deleted for good since the restore (21b only left out the piece).
  - **Checkpoint, "22b iPhone 12" simulator (iOS 26.5, Xcode 27.1, Debug):** 2,400 pieces in her own closet, each with a 3,024 x 4,032 JPEG (about 1.8 MB) and a cutout. The app scrolled the grid itself for 40 s at 4,000 pt/s (about 1,600 pieces) and counted frames with a display link. Hitch time 0.8 to 1.7 ms/s with thumbnails (Apple counts under 5 as good), 1.3 with thumbnails off, longest frame 33 to 34 ms, peak memory 88 to 90 MB and flat. The first launch straight after writing 4.3 GB read 35 ms/s; it's not a state she meets. The simulator hides decode cost, so measured directly: a 480 px grid picture takes 18.5 ms from the original and 2.1 ms from its thumbnail. Footprint: 4.1 GB originals, 190 MB cutouts, 6 MB store, about 27 KB per thumbnail (about 130 MB if she scrolls everything). XCUITest swipes weren't used for the numbers: the runner's own queries stalled the main thread (two 75 ms frames every 3 s, even idle).
  - **HEIC:** kept off; the doc has the four steps for a device test (an option on `PhotoCleaner`, nothing else changes since files have no extension and ImageIO detects the format).
  - **Tests:** `ThumbnailCacheTests` (14), `StoredImageFilesTests` (9: the launch sweep, shared files, the safety copy, Delete now, the 30-day purge, an export after Delete now restored byte for byte with no thumbnails, Undo restore after a purge), and one each in `SavedPicturesTests`, `TryOnModelTests` and `GarmentImageLoaderTests`. `RestoreTests`' setup now purges like the app does. `PhotoClosetScrollTests` (UI) is the checkpoint, skipped unless asked. Locally every package test passed apart from snapshot tests (they only match the recorded iOS 27.0 runtime). `MigrationCoordinatorTests.recoversFromACrashAt` failed once in a parallel run with a SQLite prepare error and passed four reruns; it doesn't touch this code and is flagged as its own task.
  - **CI:** three runs. The first passed every test, but the repo's tap check stopped the new perf test's plain `tap()` (now `tapUntilSelected`). The second was all green. After merging the latest `develop` (three small keep-both conflicts in `NookServices`, the app's launch wiring and Saved Looks' `onDisappear`), `ui-add-and-tours` hit its 40-minute cap: its tests all passed, but a runner "Failed to terminate" error cost a 97-second retry on top of 5 minutes waiting for the build and 28 of tests. The cap belongs to PR #71's CI work, so only that job was re-run, and it passed in 22 minutes.
  - **DATA_MAP.md:** device row (thumbnails, cutouts, stored pictures, the 50 MB rule), garment photos, try-on pictures and safety copies. The playbook gained three lessons (in-app scroll measurement, what the simulator hides about thumbnails, sweeping from the export's reference list).
  - **Needs a device:** the same scroll run on Lily's iPhone 12 for hitches and memory on the A14, the Data Protection class on the thumbnail folder, and HEIC.
  - **For Jose:**
    1. Thumbnails of try-on pictures and the try-on photo are made like any other (protected, never backed up, removed with the picture). Fine, or should Sensitive images skip the disk thumbnail and decode from the original each time?
    2. A deleted picture's file goes when its Undo goes (she leaves Saved Looks or deletes another), or at the next launch at the latest. OK?
    3. The 50 MB reserve for a new photo and 500 MB for thumbnails are my picks. Change them?
    4. HEIC on a device: try it in the same session as the cutout go/no-go?
- 21 October 2026: **Phase 24a gateway and identity, built against mocks** (jsayram/nifty-outfit-nook#73, merged as 913ad20). Jose's direction that day: "build it all out with mock responses and data... then we can talk to the real deal when all is ready, it'd be just a switch." No Clerk keys and no Convex login were needed. One new dependency, `clerk-ios` 1.6.1, approved as D2.
  - **The contract:** `contract/v1/contract.json` with golden examples, in the new private backend repo, is the single source of truth: three endpoints (`GET /v1/health`, `POST /v1/session`, `GET /v1/me`), the bearer token from Clerk's `convex` JWT template, a 64 KiB body limit, unknown fields rejected, and one error envelope with 13 codes, Retry-After on 429 and 503. The app repo keeps a byte-identical copy with a SHA-256 manifest, and both sides test against the same files. No endpoint or field names an AI provider; the 24b, 24c, 24d and 27a additions are listed in the file as planned, not built.
  - **Backend repo** `/Users/jramirez/Git/nifty-outfit-nook-backend`: local only, no remote, two local commits. Convex HTTP actions as the only public entry point, a `principals` table (Clerk token identifier to a random `usr_` ID the app sees), sign-in audit events, a check that fails on any public query, mutation or action, and the switch steps in its README. 26 tests: the contract, the gateway under `convex-test`, and 7 against a real local Convex backend run without an account (`CONVEX_AGENT_MODE=anonymous`), with a fake Clerk issuer on 127.0.0.1, so the real `auth.config.ts` refuses expired, wrong-audience, wrong-issuer and wrongly signed tokens. Only `convex` 1.47.0 and `convex-test` 0.0.63, pinned; tests use Node's own runner, so no Vitest.
  - **App:** a `Networking` target (contract types, a `URLSession` client with one token refresh after a 401, bounded retries, Retry-After and offline handling, the account service, the fake Apple sign-in and an in-process fake backend with slow, timeout, expired-token, 403, 429, 500, 503, malformed-JSON and offline modes) and a `ClerkAuth` target over `ClerkKit`, used only when `CLERK_PUBLISHABLE_KEY` and `NOOK_API_BASE_URL` are set in the ignored `Configs/Secrets.xcconfig` (template committed). `NookServices.account` carries it; nothing in her closet depends on it. App `docs/decisions/0005-gateway-and-identity.md` (with the clerk-ios vetting) and `docs/backend-switch.md`.
  - **Checkpoint**, on the "24a iPhone 12" simulator (iOS 26.5, Xcode 27.1) with `-gateway-lab`: fake Apple sign-in, then Who am I? through the fake backend; the expired-token mode showed `401 token_expired`, a fresh token, then `200`; Offline showed "You're offline. Your closet still works on this iPhone."; the 429 mode showed "Too many tries. Try again in 30 seconds." with Who am I? held until then. `GatewayLabTests` repeats it with screenshots. The real backend's "bad requests are rejected" half is the backend's tests. The Clerk path itself wasn't run: there's no instance yet.
  - **Tests:** `NetworkingTests` 39, `GatewayLabModelTests` 7, the UI test, and the backend's 26. **CI:** the first run had one snapshot flake in `YourLooksSnapshotTests.somethingNew` (not touched here) and `ui-add-and-tours` hitting its 40-minute cap; after merging the latest `develop`, the second run passed every job (UI shards 19 to 38 minutes, mostly waiting for runners). `develop` gained #70 during that run, touching only Saved Looks; the combined tree was built locally before merging.
  - **Not built in 24a:** App Attest (the header is reserved; it comes with the first paid endpoint) and the consent switch in Privacy and terms (nothing personal is sent yet). The real sign-in screens need a design first.
  - **DATA_MAP.md** (principal map, session and Keychain, audit rows, gateway logs), **THREAT_MODEL.md** (R8 controls built, F5 and F6 rows, new decision D11) and **IOS_APP_PLAYBOOK.md** (new chapter 15, Backend and gateway, and a Swift 6.4 compiler crash).
  - **For Jose:**
    1. D11: Clerk keeps its session in the Keychain with `AfterFirstUnlockThisDeviceOnly`, not configurable, while the standard asks for `WhenUnlockedThisDeviceOnly`. A written exception (suggested, reviewed before outside testers), wait for Clerk, or build our own Sign in with Apple?
    2. Approve `typescript` as a dev-only backend dependency, so the backend code is type-checked?
    3. When you're ready to switch: the Clerk dashboard steps, then `npx convex login` in the backend repo (yours to run), then the env var and deploy to `beaming-oyster-905` (backend README and app `docs/backend-switch.md`).
    4. App Attest and the consent switch were in 24a's bullets but aren't built. Move them to 24b and 27a, where they first matter?
    5. Where should the sign-in live for Lily: a design is needed before any real sign-in screen.
- 21 October 2026: **Paste in Add a piece, and a Saved Looks bug from #70** (jsayram/nifty-outfit-nook#74, merged into `develop` as ed876ac with every required check green). Jose approved Paste on 21 October. No new dependencies, no backend.
  - **Paste:** Add a piece (real photos only) offers Apple's `PasteButton` (images only) under Choose from Photos, for the case where she long-presses a garment photo on a shop's website, taps Copy, then Paste. Because she taps the system button, iOS shows no "Allow Paste?" and the app has no pasteboard permission or key; nothing in the app reads `UIPasteboard`. The pasted image goes through the same 22a intake as a picked photo: `PickedPhoto.pasted` gives it to `keepPhoto` and `PhotoIntake.keep`, so `PhotoCleaner` makes the same metadata-free JPEG (4,096 px cap, 100 million pixel refusal), and the form opens with "Your photo". The pipeline wasn't forked. A paste with nothing the app can read, or over 100 MB, says "That photo couldn’t be read". iOS dims the button while the pasteboard holds no image, and a line beside it says to copy a photo first. VoiceOver reads "Paste a copied photo" with a hint; at the accessibility sizes the row stacks; on iPad it sits in the same column as the other choices. The Change photo dialog on the form doesn't list Paste (a dialog can't hold the system button). The debug sample closet keeps its stand-in Paste row.
  - **Saved Looks bug:** on a short list the "N more in All" line sat under the floating tab bar until she scrolled. Cause (measured on the UI test): the tab view's inset already stops scrolling above the bar, but the line was the last item of a page only slightly taller than the screen, so at the top of the scroll it fell in the bar's zone (y 765 under a bar starting at 761). Fix at the root: the line is now in the scroll view's bottom safe area (`safeAreaInset`), so it is always visible above the bar and the list scrolls above it. Home and Closet have no must-see line at the end of their pages and the same inset applies, so they needed no change (read, not measured on each).
  - **Tests:** `RealPhotoIntakeTests` and `LocalPhotoIntakeTests` (a pasted JPEG, PNG and TIFF with GPS, camera and the rest come out clean; text, empty, oversize and unreadable pastes), snapshot `choose-paste`, with AX5 checked for fit only (`ImageRenderer` can't draw the system button, so they show a look-alike), `saved-more-in-all-on-screen` (the whole 402 x 874 screen with a stand-in tab bar, which would have clipped the old line out), and two UI tests: `testPasteAPictureFromTheSystemButton` (the test runner puts text, then a picture, on the simulator's pasteboard, so no hook in the app was needed) and `testTheMoreInAllLineClearsTheTabBarOnAShortList` (failed before the fix). Three Saved Looks snapshots were re-recorded because the still-image page is now top-aligned. On the iOS 26.5 "paste iPhone 12" simulator all of these pass; the other snapshot tests that don't match on 26.5 (Home, Settings, Profile, components, picture detail AX5) are untouched by this change.
  - **Docs:** app `docs/add-a-piece.md` (a Paste section, decision 10 updated) and `docs/saved-looks.md`; here `compliance/PERMISSIONS.md` (paste needs no permission key) and `DATA_MAP.md` (one more intake source, same handling).
  - **For Jose:** the system button's label ("Paste") and look are Apple's, so it's a pill beside the explaining text, not a row with a chevron like the others. OK, or would you rather it matched the rows?
- 21 October 2026: **Phase 24b limits and cost protection, built against mocks** (jsayram/nifty-outfit-nook#75, merged into `develop` as c93b992 with every required check green). Same pattern as 24a: one shared contract, real Convex code tested on a local backend, the app's fake server, and the real services a configuration switch away. Nothing calls a provider or costs money. No new app dependencies; the backend still has only `convex` and `convex-test`.
  - **The contract (v1, additive):** `GET /v1/usage` (each allowance's use today and in 30 days, when the next one frees up, and whether each paid feature is on; no money or provider names), App Attest registration (`POST /v1/attest/challenge`, `/v1/attest/key`), and two **placeholder** paid endpoints, `POST /v1/style` and `/v1/try-on`, that 27a and 33a fill in. Paid endpoints need an `Idempotency-Key` and an App Attest assertion. New codes: `quota_exceeded` (429, with category, `resetAt` and Retry-After), `feature_paused` (503, with feature), `idempotency_conflict` and `action_in_progress` (409), `attestation_required` (403). The plan's "402 or 429, to decide" became 429.
  - **Backend repo** (three local commits): admission is one serializable mutation (`ledger.admit`): App Attest counter, idempotency (a SHA-256 of the endpoint and body, never the body), kill switches, a 5-a-minute token bucket, one paid action at a time, rolling 24-hour and 30-day allowances (PRD 11.6: 10 outfit ideas, 40 swaps and questions; try-on 3 and 30 as placeholders), US$1 per account per 30 days, then the first provider whose own and global daily and monthly ceilings fit the worst-case estimate, reserved in the same transaction. Settlement gives a failed attempt's reservation and slot back and keeps an uncertain one (missing usage isn't zero); the same key then answers `action_in_progress` instead of running again. Haiku 5.5's prices are in the estimate (US$0.10 and US$0.50 per million tokens); the image prices are a US$0.10 placeholder. Switches and ceilings live in a `spendControls` table changed with `npx convex run` and logged, plus `NOOK_KILL_SWITCH=on`; a missing switch or ceiling pauses paid work. Budget alerts at 50, 75, 90 and 100 per cent are recorded once; delivery is a stub. App Attest assertions are checked with WebCrypto exactly as Apple describes; registration works only in the `mock` mode, and the `apple` mode fails closed until the certificate check is built against a real device. 60 tests, including 4 against a real local Convex backend.
  - **App:** `PaidActionService` in Models (`NookServices.paid`); the client sends one key on every try and a fresh assertion each time, so a timeout retry never runs or counts twice; `AttestationSession` registers the key on first use (Apple's `DCAppAttestService` on a device, a CryptoKit stand-in on the simulator) and keeps its ID in the Keychain (`WhenUnlockedThisDeviceOnly`); the fake backend makes the same checks in the same order, with `answerLost` and `attestationRejected` modes. `CloudLimitText` (a different, localized message for a throttle, a used-up allowance with when more comes back, a pause, busy and a failure) and `AllowanceMeter` ("2 of 3 left today") are ready for 27a and 33a; the debug `-limits-lab` screen shows them. App decision `docs/decisions/0006-limits-and-cost-protection.md` has the device checklist; `docs/backend-switch.md` updated.
  - **Checkpoint**, on the "24b iPhone 12" simulator (iOS 26.5): `LimitsLabTests` with screenshots: the sixth quick request says "You've asked a lot in the last minute. Try again in 4 seconds."; the fourth try-on says "You've used your try-on pictures for now. More tomorrow at 7:32 AM." with the meter at 0 of 3; the kill switch pauses try-on ("Try-on pictures are taking a break. Everything else works as usual.") while the stylist still works; Send again with the same key reports "Jobs run on the server: 1 (+0)"; and an answer lost on the way is retried by the client with the same key and run once. On the backend, "a retried paid request with the same Idempotency-Key is not run or counted twice" passes in `convex-test` and on the local backend, along with bursts, used-up allowances, ceilings, kill switches, replayed or tampered assertions and keys from other accounts. The plan's "limits hold under deliberate abuse" is those tests.
  - **Tests:** `NetworkingTests` 56 (new `PaidActionTests`, `AttestationTests`), `FeaturesTests` `CloudLimitTextTests` and `LimitsLabModelTests`, the UI tests `LimitsLabTests` and `GatewayLabTests`, run on the tree merged with the latest `develop`. **CI:** the first run failed only in `RestoreKillTests`, a test that started failing on every run at 12:00 UTC that day because it compared a fixed test date with the real clock (fixed in #76). The second, after merging #76, failed in the new `LimitsLabTests`: on the runner six taps took 11.75 seconds, so the rate bucket refilled before the sixth; the test now taps until one is throttled. The third run, with #71 merged in too, passed every job.
  - **Lessons along the way:** a UI test of a time-based limit can't assume how fast taps land on CI. gitleaks flags a stored `privateKey` property and a high-entropy example value under a key-like name; renamed rather than allowlisted. A SwiftUI `List` drops rows that scroll away, so a UI test waiting on a result row that scrolled off polls the whole tree until the main thread is busy answering it; the debug screen now pins its result to the bottom.
  - **For Jose:**
    1. D12: approve production allowances and ceilings, and decide Lily's owner-sponsored policy (PRD 11.6). Dev values are seeded on local and dev only.
    2. App Attest on a device: turn on App Attest for the App ID in Apple Developer (and the entitlement), then an agent builds the backend's Apple attestation check against a real attestation from an iPhone. Until then the real backend refuses paid work, by design.
    3. Where should she see her allowances: on the stylist and try-on screens only, or also in Settings (PRD 11.6 asks to disclose them there once the numbers are final)?
    4. Still open from 24a: D11 (Clerk's Keychain class) and approving `typescript` as a dev-only backend dependency.
- 21 October 2026: **Phase 29 weather, built with WeatherKit behind a switch** (jsayram/nifty-outfit-nook#77). No new dependencies, no backend. WeatherKit needs the capability on the App ID, which only Jose can enable, so the stand-in weather stays the default and `NOOK_WEATHERKIT = NO` makes no WeatherKit call at all.
  - **Built:** `PlaceWeatherProvider` (her choices, a city or her approximate location, a cache per place and hour with one shared ask, no polling, an older forecast used for up to 3 hours if a lookup fails), `WeatherKitForecastSource` (used only with the switch), `CoreLocationApproximateProvider` (When In Use, reduced accuracy, one fix at a time), `MapKitCityFinder` (a typed city, no permission), a Weather group in Privacy and terms (Live weather, City, Use my location, Open Settings when iOS says no, the explanation alert first), Apple Weather's credit under Home's room, Style Me's Weather row and the settings, and the weather sheet now shows today's range and the chance of precipitation when there is one. Delete my data erases her weather choices.
  - **Privacy choices:** every coordinate goes through `CoarseCoordinate` (rounded to 0.1 degree, about 11 km, on creation and on decoding); no position is stored, only the city she picked (name and rounded point, in a `UserDefaults` suite); the stylist may get only `WeatherSummary` (condition, temperatures in whole degrees, precipitation to the nearest 10 percent, night or day), with a test on its exact keys. Phase 27a must serialize that type and not `WeatherSnapshot`. The text she types for a city goes to Apple Maps. DATA_MAP.md, PERMISSIONS.md, the privacy labels draft and the in-app privacy text are updated.
  - **The switch (Jose):** Apple Developer, Identifiers, `com.jsayram.niftyoutfitnook`, tick WeatherKit; then `NOOK_WEATHERKIT = YES` in `Configs/Secrets.xcconfig` (or Base.xcconfig). That one setting adds the entitlement and turns the provider on. Steps in the app repo's `docs/weather.md`. In `NOOK_WEATHERKIT = NO` builds Privacy and terms says the weather is a sample and nothing is sent; Apple's credit shows for the sample only in Debug builds.
  - **Checkpoint**, on the "29 iPhone 12" simulator (iOS 26.5) with the fake provider: `WeatherTests` pick a city (Seattle) and see Home's window and the credit change with `-fixtures demo:weather=` (sun, cloudy, night, snow, rain), and turn on "Use my location" and say no: the switch goes back off, the note and Open Settings show, and Home keeps the weather from the city. Screenshots in `scratchpad/weather/` (`weather-home-snow-credit.png`, `weather-location-denied.png`, plus the privacy and explainer screens). iOS's own location alert was scripted (`-weather-location askDeny`), not tapped.
  - **Tests:** Models (`CoarseCoordinateTests`, `WeatherSummaryTests`), Fixtures (`PlaceWeatherProviderTests`: choices, cache, one ask for many callers, offline, stale), Services (`WeatherSettingsStoreTests`), Features (`WeatherSettingsModelTests`, Privacy and Home snapshots), and 5 UI tests. Snapshots were recorded on iOS 26.5 (the only runtime I may use); on that runtime some old AX5 and AX3 snapshots and the runtime check fail without my change, and CI is the judge.
  - **Needs a device (checklist):** the real WeatherKit call after the switch (a typed city and approximate location), Apple's mark loading, the legal link, one lookup per hour, airplane mode showing the last forecast, and iOS's real location alert with the Settings round trip.
  - **For Jose:** 1. Enable WeatherKit on the App ID when ready (steps above). 2. Typing a city uses Apple Maps; OK, or would you prefer a built-in list of cities (no network, fewer cities)? 3. Home's credit sits over the rug above the tab bar and clips the dog's feet a little; fine, or somewhere else? 4. Not built: entry points from Style Me's weather row and Home's window to the explanation (the docs mention them); they only open Privacy and terms today.
- 21 October 2026: **Phase 24c authorization and account deletion, built against mocks** (jsayram/nifty-outfit-nook#79, merged into `develop` as e5b7064 with every required check green on the first CI run, after merging the latest `develop` with Phase 29). Same pattern as 24a and 24b: one shared contract, real Convex code tested on a local backend, the app's fake server, and the real services a configuration switch away. No new dependencies on either side.
  - **The contract (v1, additive):** `POST /v1/account/deletion` (token, `confirm: "delete-my-account"` and a fresh Sign in with Apple authorization code; 202 with three steps: `signInWithApple`, `serverData`, `account`, each done, pending or failed) and `POST /v1/account/deletion/status` (no token, by a random `del_` ID, since the token dies with the account). The plan's draft `DELETE /v1/account` and `GET .../{id}` changed so the ID never sits in a URL or log. An account being deleted gets `forbidden` everywhere else.
  - **Authorization:** `tests/authorization.test.ts` runs a second account against every endpoint (a new endpoint fails until it has a case) and checks the first account's rows are unchanged and never echoed: another account's App Attest key, challenge, Idempotency-Key, or a body naming its `usr_` ID all fail. A contract test fails if a request schema gains a user, account or principal field. The public-function check still runs with the tests.
  - **Backend deletion** (one local commit): the account is marked first (admission refuses paid work; a late paid result is dropped because cost entries go before actions), the Apple link is revoked with the code (mock), every row is deleted in batches of 200 with the principal last, then the Clerk user (mock; the real Backend API call is written behind `NOOK_CLERK_DELETE_MODE=clerk`). Every step repeats safely; the scheduler retries (30 seconds, doubling, 8 tries) then alerts `deletion_stuck`; repeating the request carries on the same deletion. Kept: the deletion record (pseudonymous, 35 days, for restores; `deletion:reapplyAfterRestore`), allowance use under a keyed hash (31 days), and a `securityLog` with only the event and time. A daily cron cleans both. `tests/deletion.test.ts` lists every table and fails on one it doesn't know. 79 tests, 13 of them on a real local Convex backend; the local run found a real gap (a sign-in could re-create the account between the purge and the Clerk deletion), now fixed and tested.
  - **App:** Delete my account in Privacy and terms while signed in: what goes (the server's records, the account, the Apple link, her iCloud copy when sync was on, then this iPhone), the subscription note, one question, then Apple's sheet again. `AccountDataDeletion` does Apple and the backend first (nothing deleted anywhere if either says no), reads pending steps, runs the iCloud hook (`ICloudCopyDeletion`, `NoICloudCopy` until sync exists; tested with a fake), erases the iPhone, signs out and forgets the App Attest key. The screen says nothing was deleted and why, starts fresh, says the server is still finishing (with Done), or offers Try again, which doesn't ask the backend twice. `ClerkAuthProvider` gets the Apple code straight from Apple (not run on a device). App decision 0007, `docs/settings.md`, `docs/backend-switch.md`.
  - **Checkpoint**, on the "24c iPhone 12" simulator (iOS 26.5): launched with `-seed-photo-closet 3 -fake-signed-in` (fake Apple sign-in and one paid action on the fake server): 3 pieces, 6 photo files and the store. `AccountDeletionTests` then opened Privacy and terms, Delete my account, cancelled once, deleted, and the app went back to the welcome with "Your data is deleted". In the container afterwards: no `Photos` folder, the store's only row is the `defaultsImport` migration flag, the preferences suite is empty, and the fake backend reported `{"accounts":0,"deletionsCompleted":1,"deletionsRunning":0,"usersWithData":0}`. On the backend, "a retry after a failure part-way through the deletion completes it" (Clerk mock failing, then back) and "user B can't read, use or delete user A's data" pass on the real local Convex backend.
  - **Tests:** Models `AccountDataDeletionTests`, Networking `AccountDeletionGatewayTests` and the fake backend's contract cases, Features `DeleteAccountModelTests` and two snapshots, the UI test above. On the merged tree locally, every package test passes except the 11 known runtime snapshot mismatches (references are 27.0, the simulator 26.5); the whole UI suite passed on the pre-merge tree. The two new snapshots were recorded on 26.5 and pass on CI's 27.0.
  - **What deletion can't reach** (DATA_MAP, "What account deletion reaches"): Anthropic (no deletion call; 30 days, flagged up to 2 years), BFL (perpetual right under its terms, D1), OpenAI if used (about 30 days, to verify), Clerk's own retention after a user is deleted (unknown), R2 backups (age out in 30 days; deletions reapplied after a restore), exports she saved, and the support inbox.
  - **For Jose:**
    1. D13: allowances survive a deletion only if the hashed identity survives it. Clerk makes a new user ID, so should the hash use Apple's own `sub` in the `convex` JWT template, or accept that deleting resets allowances (the per-account and global ceilings still cap cost)?
    2. When switching on: Clerk's secret key and `NOOK_CLERK_DELETE_MODE=clerk`, a `NOOK_SUBJECT_PEPPER`, and the Sign in with Apple key so the revocation can be built, unless Clerk already revokes Apple's link when a user is deleted (to check on the dev instance).
    3. App Attest isn't required for deletion, on purpose, so a device that can't attest can still delete (Guideline 5.1.1(v)); re-authentication with Apple is the check. OK?
    4. Not built: a screen after a relaunch for a deletion the server is still finishing (the server finishes on its own and alerts if stuck).

- 21 October 2026: **Phase 26 network resilience** (jsayram/nifty-outfit-nook#78, merged into `develop` as e39a9ac with every required check green on its own branch; #80 then fixed a compile break with 24c, see below). Written up in the app's `docs/network-resilience.md`. No new dependencies, no contract change.
  - **Already there from 24a and 24b:** a 15 second timeout on every try, three tries with backoff and jitter for requests marked safe to repeat, Retry-After on 429 and 503 (waited out up to 3 seconds, otherwise handed to the screen), one token refresh after a 401, the idempotency key reused on every try, the limit errors and their wording, `waitsForConnectivity` off, and the fake backend's slow, timeout, offline, expired-token, 429, 500, 503 and malformed-JSON modes with a test for each.
  - **Gaps found against PRD 11.7 and built:** there was no overall deadline (three 15 second tries plus waits ran to about 50 seconds); one timeout fitted every endpoint; a connection lost in the middle failed at once instead of being retried safely; a 503 without Retry-After wasn't retried; Retry-After in its date form was ignored; "still running" (409) used up the three tries and was only waited for up to 3 seconds; a second 401 or a failed refresh left her "signed in" on the phone; there was no connection monitor; and nothing owned a screen's call, so leaving a screen didn't cancel it.
  - **Built:** per-endpoint timing (try 10 s, call 30 s; paid text 40 s and 45 s; try-on 30 s and 360 s, the aggregate PRD 9.2.4 proposes), with the hard limit as a race against a timer in a task group, and no wait started that can't finish before the deadline. A connection lost mid-request is retried for safe requests (no connection at all fails at once). 409 is polled with the same key until the deadline. A second 401, or a refresh that fails, signs out on the phone. `PathConnectivitySource` (NWPathMonitor), `ConnectionStatus` and `CloudOfflineBanner` (announced once to VoiceOver). `CloudTask` (one call at a time, cancelled on leaving the screen, "taking longer than usual" at 10 seconds, failures announced) and `PaidActionAttempt` (one key per action). `CloudProblemText` for every network problem, in 24b's voice. Fake modes `connectionLost`, `actionInProgress` and `trickle`.
  - **Decision, offline:** nothing is queued and nothing retries by itself when the connection comes back. A queued paid request could run hours later and spend her allowance; PRD 11.7 asks for durable queues only for background transfers, which are CloudKit's and StoreKit's. She sees the banner and taps Retry, and her input stays where it was.
  - **Checkpoint, "every failure case forced against a test server":** `ResilienceTests`, one test per case: slow (answers, and cut off at the limit), a trickle, never answers (bounded by the deadline), offline at the start and in the middle (once, for ever, not safe to repeat, a paid request that runs once), 401 then a fresh token, 401 and the refresh fails (signs out, no third request), 429 with Retry-After (short, long, date form), 500, 503 with and without Retry-After, other 4xx never retried, malformed JSON, still running, and cancellation in a backoff wait, in flight and on a paid request (asked again with its key, run and counted once). Removing the hard limit made the trickle test fail after 9.9 seconds, so it tests what it says. Also `CloudTaskTests`, `ConnectionStatusTests`, `CloudProblemTextTests`, and on the "26 iPhone 12" simulator (iOS 26.5) the new `GatewayLabTests.testTheOfflineBannerAndAConnectionLostInTheMiddle` with screenshots, plus `LimitsLabTests`. 91 network tests and all package tests pass except the snapshot tests that already don't match on 26.5.
  - **Not built:** no real screen uses `CloudTask` or the banner yet (27a and 33a are the first); the try-on polling endpoint and its real deadline come with 33a; IPv6-only and airplane-mode runs on a real iPhone are on the device checklist in the doc.
  - **Merge hiccup:** 24c (#79) landed on `develop` while #78 was in its last CI run, and added `reauthenticateForDeletion()` to `AuthProvider`. I ran `scripts/merge-pr.sh` without merging `develop` in again, GitHub squashed it cleanly, and the combined tree didn't compile: two `AuthProvider` stand-ins in `ResilienceTests` lacked the new method. I found it by building the merged `develop` right after, fixed it in #80 (test code only, merged as 8aed4ac with every check green; `develop`'s tests were broken for 33 minutes), and the 889 package tests pass on it apart from the same 8 snapshot tests that don't match on iOS 26.5. Lesson in the playbook: before `merge-pr.sh`, fetch and, if `develop` moved, merge it and let CI run again.
  - **Lessons** added to `IOS_APP_PLAYBOOK.md` chapter 15 (the hard limit, what to retry, polling a running job, the connection monitor as a hint, and four Swift 6.4 and XCUITest details).
  - **For Jose:**
    1. Is "no queue while offline, she taps Retry" right? The alternative is retrying by itself when the connection returns, which I'd only do for free requests.
    2. The paid-text 45 second and try-on 360 second deadlines are the PRD's starting values. 27a and 33a confirm them against the real endpoints.
- 21 October 2026: **Phase 27a cloud stylist, built against a fake provider** (jsayram/nifty-outfit-nook#81, merged into `develop` as fd935be with every required check green). Same pattern as 24a to 24c: one shared contract, real Convex code tested on a local backend, the app's fake server, and the real provider a configuration switch away. Nothing called Anthropic or cost money. No new dependencies on either side; the Anthropic SDK is a question below.
  - **The contract (v1):** `POST /v1/style` keeps its path, Idempotency-Key, assertion and errors. Its request is now `mode` (`full`, or `ask` for Ask stylist), the consent version and a bounded closet snapshot (at most 150 pieces as category, kind, colours, colour note, fit, dressiness, warmth and her names; never photos, notes, brands, sizes, measurements or weight), plus the outfit choices (occasion and an Other occasion's words, indoors or Phase 29's `WeatherSummary`, comfort, colour wish, whether one idea is allowed, starting piece, combinations to avoid) or a question about a look with up to six earlier turns. The answer is typed: `complete`, `partial` (each missing version with why), `insufficient`, or `answer`, with looks as garment IDs, an optional idea piece, a why line, a confidence and `fromCache`. New code `consent_required` (403). The `swap` mode is gone: swaps stay on the phone (Phase 11). Golden examples for both modes; app and backend test the same files.
  - **Backend** (one local commit, `convex/stylist/`): provider, model (`claude-haiku-5-5`), effort (`low`), cache TTL and region come from Convex environment variables, and `CONSENT_COVERS` says which consent text covers which recipient, so a backup provider is an adapter plus new consent text, with no app change. Before admission: the request's own rules, consent, the result key (`NOOK_RESULT_KEY`; without it the stylist stays paused), then the prompt and its token estimate, which 24b's `ledger.admit` now reserves (the prompt at the dearest input price plus the 3,000-token output bound, about US$0.0022). After admission: the 24-hour result cache, a closet pre-check (no dress and no top-and-bottom is `insufficient` without a provider call), then the provider, validation and settlement from the reported usage, cache reads included. The Anthropic adapter calls the Messages API over `fetch` (30-second timeout, no tools, structured JSON output) and runs only when `ANTHROPIC_API_KEY` is set; otherwise a fake answers in the model's format from the request's own pieces, or fails on purpose (`NOOK_STYLIST_FAKE`: overloaded 529, rate_limited 429, invalid_json, refusal, timeout). Validation: only pieces from the request (an invented one drops its version), two to six pieces, a dress or a top and a bottom, the starting piece in every version, shared pieces with Simple, an idea only where allowed; repeats, a forbidden idea, aliases and over-long why lines are repaired; a why line about her body is dropped; a missing version must be shown impossible or the attempt didn't finish. Failures are `503` "It didn't work this time. It wasn't counted." (Retry-After 30) with the allowance slot back; a timeout keeps the reservation. README "How to switch the stylist to Anthropic", and `scripts/try-stylist.mjs --yes` for three real calls once the key exists (not run).
  - **Prompt and caching:** system policy (adapted from PRD 8.5's stylist-policy/1, identical for everyone, about 1,070 tokens) with a `cache_control` breakpoint; then her closet catalog with aliases p01, p02... by ID order (byte-identical until her pieces change, tested) with the second breakpoint; then the request block. Her words are cleaned, quoted and kept inside the delimited blocks, and the policy says they're data. Haiku 5.5 caches prefixes of 512 tokens or more, for 5 minutes by default (1 hour on request); writes cost 1.25 times the input price and reads 0.1 times. **Estimated cost per request** for a 40-piece closet (about 2,560 input tokens, 700 output including low-effort thinking): US$0.00061 with no caching, US$0.00067 cold (both blocks written), US$0.00042 warm (both read), so about 30 per cent less when she asks again within 5 minutes; output is about US$0.00035 of every request. The result cache (identical request, same account, 24 hours) answers for nothing: no provider call, no allowance. Estimates come from character counts; the try script measures the real numbers.
  - **App** (`CloudStylist`, `StyleCall`, `StyleHistory`, `APIV1+Stylist`, `FakeStylist`): Style Me uses the cloud stylist with the real services, or `-cloud-stylist [normal|fails]` against the fake backend in debug builds; otherwise Stage A's stylist on the phone, unchanged. No call without consent (version A of the in-app text, `stylist-1`): Your looks says "Style Me needs your OK to send your request to Anthropic. You can still make your own looks." with Review (the consent sheet, Allow or Not now); Privacy and terms gets a Style Me switch; Delete my data erases the consent. "From your history" (FR-58): an earlier cloud result for the same structured request (`StyleIntent`: source, occasion, starting piece, colour wish, idea allowed, weather band and wet or dry) whose pieces she can still use shows first, with New ideas; free text and today's comfort never make a match. The why line shows under the look while it is as the stylist made it. Limits use 24b's words ("Styling is resting for now"); a provider failure is "Styling didn't finish" with Try again. Each tap is a new idempotency key, reused by the client's own retries. App decision `docs/decisions/0008-cloud-stylist.md`; `docs/style-me.md`, `your-looks.md`, `settings.md`, `backend-switch.md` updated.
  - **Checkpoint**, on the "27a iPhone 12" simulator (iOS 26.5) with the fake stylist: the UI test `CloudStylistTests` launched with `-cloud-stylist`: Style me said "Style Me needs your OK" and sent nothing; Review, Allow; looks made only of the demo closet's pieces with a why line ("The brick top and olive bottom keep it easy for the office, and suit the wet weather."); back and Style me again showed "From your history" with New ideas and no request. With `-cloud-stylist fails`: Not now kept the message; Allow then showed "Styling didn't finish" with Try again. Screenshots in `scratchpad/27a/shots/`. "A repeat request hits the cache": `tests/stylist.test.ts` counts provider calls (one for two identical requests, the second `fromCache`, `noCharge`, no allowance) and the local-backend test repeats it on the real Convex runtime; the app's `CloudStylistTests` checks the fake runs one job. The plan's own checkpoint, styling quality on Lily's saved scenarios, needs the real model.
  - **Tests:** backend 102 (22 new in `stylist.test.ts`, one new on the real local Convex backend; 14 there in all), including a name that tries to close its block, an invented piece, body talk in a why line, each failure mode, consent, the missing key, insufficient, Ask stylist, sealed rows and replays, cross-account cache isolation, and cost from usage with cache reads. App: `CloudStylistTests` (Networking, against the fake backend, including the keys that may leave the phone), `CloudStylingTests` (Models), `YourLooksCloudTests` (Features), contract round trips for the new examples, the UI test above, and `LimitsLabTests`, `AccountDeletionTests` and `YourLooksTests.testAFullStylingRun` re-run. **CI:** the first run failed on swift-format (line lengths and two force unwraps, fixed) and nine Saved Looks snapshots that matched locally; the second run passed every job. After merging develop again (#82), one run needed two reruns of the build job: first a Phase 26 timing test (`aServerThatNeverAnswersIsTriedAgainOnlyWithinTheDeadline`, sign-in hit its 200 ms try on a busy runner), then sticker snapshots off by a few thousand pixels with no visible change, including a garment-detail snapshot this PR doesn't touch. The third attempt passed every job. Both look like runner flakes worth a look in the snapshot and resilience tests.
  - **Not tied to a screen** (Jose's requirement, sent mid-phase on 21 October 2026): a cloud Style Me request runs in `StylingJobs`, an app-level owner held by the services, not by Your looks. Leaving the screen to browse or search doesn't stop it; the job saves its looks to her history (and marks a suitcase used) whether or not a screen still waits; coming back to the same Your looks shows them, and a new Style me with the same choices finds them through From your history. Only her Cancel stops it. Phase 26's screen-scoped `CloudTask` isn't used for the stylist. Stage A's stylist on the phone keeps "leaving stops it". Tested in `YourLooksCloudTests` (leave, then the answer arrives: three looks in the store, the screen showing them; Cancel stops the job). Left for the background AI jobs phase: a persisted job list, resuming after a relaunch, a "your looks are ready" banner and local notifications, and keeping Ask stylist conversations (the screen isn't built).
  - **Found on the way:** develop's networking tests stopped compiling when Phase 26 merged on top of 24c (two test auth providers in `ResilienceTests` lacked 24c's `reauthenticateForDeletion`); fixed in #81. Phase 26's "taking longer than usual" line isn't shown on Your looks.
  - **DATA_MAP.md** (what the request carries, the sealed result cache, the why line and intent on looks, the consent record, Anthropic notes), **THREAT_MODEL.md** (controls built for the Anthropic boundary, two new rows for the result cache and the consent-to-recipient check, D5's US-only answer, new D14) and the compliance docs (in-app text as built, App Review P10, the measurements note) are updated.
  - **For Jose:**
    1. The Anthropic key: set `NOOK_RESULT_KEY`, then `ANTHROPIC_API_KEY`, on dev (backend README), then run the try script and the quality check on Lily's saved scenarios. Paid calls on the real backend also need App Attest on a device (24b).
    2. Approve `@anthropic-ai/sdk` as a backend dependency, or keep `fetch`?
    3. D14: measurements and weight (none sent; version A), labelled ideas for an empty closet (still Add a piece), an unproven missing version counted as "didn't finish", and the prompt cache's 5-minute TTL.
    4. Ask stylist: the endpoint and request builder are done; the screen is still the stand-in. Build it next, with its design?
    5. The consent text lists fabric, which isn't sent (the app has no fabric field). Keep it for the future, or drop the word?
- 22 October 2026: **Phase 27c background AI jobs, built against the fakes** (jsayram/nifty-outfit-nook#84, merged into `develop` as 09296a7 with every required check green, after merging in 24d). Jose's requirement of 21 October 2026: she can leave a screen, or the app, while an AI job runs, browse and search, and be told when it's done; AI calls and stylist conversations persist. No new dependencies, no contract change, CI workflows untouched. App doc `docs/background-ai-jobs.md`.
  - **App:** `AIJobs` (Models) replaces 27a's `StylingJobs` as the one app-level owner of paid AI jobs (styling now; Ask stylist's job is ready; try-on plugs in as a third kind in 33a). An `AIJob` keeps its ID, kind, its own Idempotency-Key, state (queued, running, still running, done, failed, cancelled), times, what it asked for (the styling context and consent version, rebuilt into the same body every time, tested) and a result reference. One runs at a time, like the server. Only her Cancel stops one. A late answer (Phase 26's 45-second deadline, or "still running") is asked for again every 20 seconds with the same key, for up to 10 minutes. `CloudStylist` takes the job's key (`KeyedStylist`).
  - **Kept in the 21a store** as two new record kinds, `aiJob` and `stylistThread`, so the schema didn't change. Jobs are this iPhone's work in progress: never exported, never restored, left alone by a restore, kept a day after finishing, erased first by Delete my data. Conversations are exported and restored like looks. A stored job that was sent is asked again after a relaunch with the same key; one never sent and older than 10 minutes says it didn't finish rather than sending late. Looks that couldn't be written (the store is locked with the phone) are written at the next foreground.
  - **Telling her:** a calm banner over every tab ("Your looks are ready", Tap to see them, a Hide button, read out by VoiceOver, Dynamic Type, no timer), a dot on Home where Style Me lives, and a local notification in the background ("Your outfit ideas are ready" / "Open Outfit Nook to see them.", never anything of hers). No banner for the result she's looking at; in the background the notification goes even if that screen was left open. Permission is offered once, on Your looks, the first time a cloud job starts, with a short explanation first; never at launch. If she says no, the banner still works. In the background the app asks iOS for a short background task (about 30 seconds, not promised), so a job that answers soon posts its notification; otherwise it's picked up at the next foreground. No `BGTaskScheduler`: it runs when iOS chooses and the store can't be read while the phone is locked. Closed: nothing runs until the next launch; push needs APNs.
  - **Ask stylist conversations:** `StylistThread` (one per look, up to 60 turns of 2,000 characters) and its store; `AIJobs.ask` keeps her question at once and the stylist's answer when the job is done, across a relaunch. The screen isn't built (question below).
  - **Backend** (one local commit, `convex/push.ts`): when the ledger first settles a paid action it records one `jobEvents` row (public action ID, feature, done or failed, time; never the request or result) and schedules a push hook. `NOOK_PUSH_MODE` off by default, `mock` logs one line, `apns` fails closed. The payload is localization keys and the kind of job only. Events expire after a day and, with a `pushDevices` table nothing writes yet, are deleted with the account. README "Switching on push" has the steps that need Jose.
  - **Checkpoint**, on the "jobs iPhone 12" simulator (iOS 26.5) with `-cloud-stylist slow` (the fake answers after 15 seconds), as UI tests in `BackgroundJobsTests`: Style me, Allow, "You can leave this screen", then Closet and a search for "top"; the banner "Your looks are ready" appears over the closet with the dot on Home; tapping it opens Your looks with the looks. On a clean install: Notify me, iOS's alert, Allow, Home button; the notification "Your outfit ideas are ready, Open Outfit Nook to see them." shows on the Home Screen, and tapping it opens the looks. With her own closet in the store (`-seed-photo-closet 8`): the app is killed mid-job and launched again; the kept job is sent again and finishes with the banner. Screenshots in `scratchpad/27c/shots/`. "No second charge" is the backend's record, proved in `tests/jobs.test.ts` (the app killed mid-job: the relaunched app's ask gets 409 while it runs, then the record: one provider call, one settled charge, one action, one event) and the app's `AIJobsResumeTests` against the fake backend (one action, one job run, one allowance use). The in-process fake restarts with the app, so on the simulator it runs the job again.
  - **Tests:** `AIJobsTests` (17, on the real store, with the `ManualClock` from #83), `AIJobsStoreTests` (relaunch, the 21b store migrating then keeping jobs, 21b and a new 21c backup fixture made by develop at fd935be restoring both ways, export, Delete my data), `AIJobsResumeTests`, `YourLooksCloudTests` (+3), and three UI tests (the banner flow runs on PRs; the notification and relaunch ones on full-suite runs). The whole package suite passed locally apart from the 11 known snapshot and runtime checks that don't match on iOS 26.5. Backend 108 tests, all passing on a real local Convex backend too. **CI:** the first run passed every UI job and failed one Your looks snapshot (`somethingNewDark`) that looks identical to its reference, the runner flake 27a saw; the one re-run failed `CatalogTests` instead, the app taking over 190 seconds to launch on the runner (they had passed in the first attempt). After merging 24d (a string catalog conflict, both sides appending), the run was four to nine times slower than usual on every suite (`StickerBundleLayoutTests` 170 seconds against 19, a speed check failed, and the UI jobs gave up waiting for the build's products); re-running its failed jobs passed every job. None of the failures touched this phase's code.
  - **Found on the way:** with the `async` form of `UNUserNotificationCenterDelegate.didReceive`, tapping the notification crashed the app on iOS 26.5 (UIKit's main-thread assertion); the completion-handler forms on the main actor fixed it. And the first notification run got nothing, because the result's screen left open in the background counted as "she's looking at it". Both are in the playbook.
  - **For Jose:**
    1. Push when the app is closed: set up APNs (backend README, "Switching on push": the APNs key, the Push Notifications capability, then an agent builds the device-token endpoint and sender). Until then a closed app hears about a job at its next launch.
    2. Ask stylist: the conversation model, store and job are ready. Build the screen next, with its design?
    3. The dot is on Home (Style Me's tab). OK, or on whichever tab she started from?
    4. A job still running after 10 minutes says it didn't finish. OK, or longer? Try-on (33a) will need its own limit near PRD 9.2.4's 360 seconds, and the server's 60-second action lease must grow with it.
    5. Privacy and terms' "Stays on this iPhone" list could add "AI requests in progress, kept for a day" (wording in IN_APP_PRIVACY_TEXT.md); not added to the screen yet.
- 22 October 2026: **Phase 28, the stylist on the phone** (jsayram/nifty-outfit-nook#90, merged into `develop` as b432bbf with every required check green on the first CI run). No new dependencies, no contract change, CI workflows untouched. App decision `docs/decisions/0010-on-device-stylist.md`.
  - **The device question:** Apple's article "Generating content and performing tasks with Foundation Models" says the on-device model's availability depends on whether the device supports Apple Intelligence, and tells apps to check `SystemLanguageModel.default.availability` and plan a fallback. On an iPhone 12 that returns `.unavailable(.deviceNotEligible)`. Apple's `PrivateCloudComputeLanguageModel` has the same reason, so it doesn't help either. Lily gets the cloud stylist or Quick ideas, never the on-device model.
  - **Quick ideas** (`QuickIdeasStylist`, Models): the always-available stylist, built on stored facts only, which the public repo allows. The weather band is a firm rule (a top, bottom, dress or layer that doesn't suit it is used only when she has nothing that does); cold, cool or wet days get her best suitable layer and hot days never do; sandals lose out on wet or cold days. Dressiness follows the occasion and occasion tags count. Neutrals plus one colour family scores best, two colours or two prints score down, and a required colour limits the outfits to those that bring it in. Simple skips outfits already shown for the request and outfits worn inside her repeat window while another exists, and says "You wore this..." when it can't; a piece worn in the last three days gives way. Dressed up swaps in one dressier piece of hers; Something new adds one neutral idea or another of her pieces. It returns the same typed result as the cloud stylist, checked by `ResultCheck`, with a why line per version from templates in Features (`QuickIdeasText`), and marks it `StyleResult.madeBy = .rules`.
  - **One router** (`StylistRouter`, Models): the cloud stylist, as a 27c job, when it's set up, she agreed and the phone isn't offline; otherwise the on-device lane when the model is available and a stylist is installed for it (none is yet), else Quick ideas. Limits are only known from the server, so a cloud job that's refused (24b's pause, an allowance used up, rate limited, signed out) or fails falls back to Quick ideas with its reason; her Cancel and a changed request don't. Your looks shows **Quick ideas (on your phone)** with the reason and Review (no consent) or Ask the stylist (a failure); "Uses 1 styling" becomes "Made on this iPhone, free" when the next request stays on the phone. `SystemModelCheck` (Services) reads the model's availability. Without a backend, her own closet now uses Quick ideas instead of Stage A's stand-in; the debug sample closet keeps the stand-in, so Stage A snapshots don't move.
  - **Foundation Models stylist: not built.** Its instructions would sit in the public app repo (SECURITY_STANDARD.md keeps prompts in the backend), it can't reach Lily, its context is 4,096 tokens (27a measured about 2,560 for a 40-piece closet), and its answers vary, so CI could only test a fake. The decision doc describes the path: guided generation into the 27a schema behind the same `Stylist` protocol, installed only when the check says available.
  - **Checkpoint**, on the "28 iPhone 12" simulator (iOS 26.5, deleted afterwards), as the UI test `CloudStylistTests.testOfflineWithoutConsentStillGivesQuickIdeas` with `-cloud-stylist -connection offline` (the app's debug switch that fixes the connection state; the Mac stayed online): Style me with no consent showed "Quick ideas (on your phone)", "Made on this iPhone from your own pieces. For the stylist's ideas, Style Me needs your OK." with Review, and a look from the demo closet for the rainy 14.5° Office day (navy cardigan, cream sweater, olive trousers, tan loafers) with "Smart enough for the office, in neutrals with a touch of olive, with a layer for the wet weather." Nothing was sent. Screenshots in `scratchpad/28/shots/`. The plan's "same scenarios on an eligible device" waits for the Foundation Models stylist.
  - **Tests:** `QuickIdeasTests` (400 generated closets and requests per property: valid by `ResultCheck`, only her pieces, no piece twice, no two versions alike, deterministic; every warmth-sensitive piece suits the band when she owns one that does, with the layer rule; no repeat of a shown or recent outfit while another exists, and the note when it must; plus worked examples and a 150-piece timing check), `StylistRouterTests` (the routing table, the fallback after every cloud error and job failure), `SystemModelCheckTests`, `YourLooksCloudTests` (updated for Quick ideas before consent and after limits and failures, plus the checkpoint on the model), `QuickIdeasLabelSnapshotTests` (9 references: each reason, on-device, dark, AX5, Your looks), and the three `CloudStylistTests` UI tests, all passing locally. The whole package suite passed locally apart from the known iOS 26.5 snapshot and runtime checks. The snapshot references were recorded on 26.5 and still matched CI's 27.0.
  - **For Jose:**
    1. Before consent, Style Me now shows Quick ideas with Review, where 27a showed only "Style Me needs your OK". OK?
    2. The colour and formality matching is generic (neutrals plus one colour, dressiness by occasion). Fine in the public repo, or should any of it move to the backend?
    3. Build the Foundation Models stylist for iPhone 15 Pro and newer (an on-device prompt in the public repo), or leave it?
- 22 October 2026: **Phase 30a, the styling subscription and paywall** (jsayram/nifty-outfit-nook#91, merged into `develop` as d07e3f7 with every required check green on the fourth CI run: the first two found the changed snapshots and an old wording test, and that StoreKit's test sessions get no products on CI; the fourth followed a merge of `develop`). No new dependencies; CI workflows untouched. App doc `docs/payments.md`, with the App Store Connect steps.
  - **Products:** one subscription group, Styling, with `com.jsayram.niftyoutfitnook.styling.monthly`, 1 month, auto-renewing, a free first month for new subscribers (PRD 14.1). **Placeholders:** US$9.99 a month (PRD 14 calls it a candidate), the allowances the paywall shows (10 Style Me a day, 40 swaps and questions a day, 30 try-on pictures a month, the 24b dev values, D12), the group name, Family Sharing off. The local `NiftyOutfitNook.storekit` holds the same, and the scheme's Run uses it.
  - **Entitlement model** (Models): none, trial, active, grace period, billing retry, expired, revoked. Access is a trial or paid month until its end date, or Apple's grace period until it ends; billing retry without grace gives none (PRD 14.3). A cached status never grants past the dates Apple gave, so a free month that ended offline reads as expired. `mayRenew` (trial, active, grace, retry) drives the deletion note.
  - **StoreKit 2** (Services, `StoreKitSubscriptionService`): status from `Product.SubscriptionInfo.status`, falling back to the latest transaction; the `Transaction.updates` listener starts at launch, finishes every transaction and re-reads; purchase with the scene; restore with `AppStore.sync()`; only verified transactions count. Right after a purchase StoreKit's status lags a few hundred milliseconds, so the status comes from the purchased transaction and an empty answer within 60 seconds doesn't erase it (still bounded by its dates). The last status is cached in `UserDefaults` (state and dates, no transaction IDs).
  - **Paywall** (Profile, Styling access, under the name as in `settings.html`): custom, not `SubscriptionStoreView`, because the allowances, what stays free and the first charge date need the app's words, three screens share the state, and snapshot and UI tests must draw it from a fake. Price, period and trial come from StoreKit; the free month shows only when the Apple Account is eligible; it says when the first charge comes, that it renews until cancelled, and how to cancel a day before; Restore purchases, Manage subscription (`manageSubscriptionsSheet`), Terms of use and Privacy policy (the website's placeholder pages), Not now. VoiceOver reads the offer as one element; AX5 snapshot.
  - **Wired in:** Help's "Free and paid" (Good to know); the try-on allowance (simulated pictures stay free, so Lily's TestFlight is unchanged; once 33 makes them real, pictures need access and the sheet offers See styling access); Delete my account shows its note and Manage subscription only while a subscription may renew. Paid requests carry `X-Nook-Entitlement-Hint`, worked out when sent; the contract (backend local commit e51b5d8, synced to the app) says it's a hint only, and the fake backend records it and admits nothing because of it. Server checks are 30c.
  - **Two findings for the playbook:** `SKTestSession` returns no products in a SwiftPM test bundle (no host app), so the StoreKit tests live in a new unit-test target hosted in the app (`NiftyOutfitNookTests`); and on the simulator StoreKit's local testing refuses an app without `get-task-allow` ("not installed for development" in `storekitd`'s log), so Debug builds use `Configs/*-Debug.entitlements` with it, and Release keeps the files `check-archive.sh` checks. Also, `AppStore.sync()` shows Apple's sign-in prompt even in a test session, so the tests' restore skips it (the service takes the sync as a parameter).
  - **Checkpoint**, on the "30a iPhone 12" simulator (iOS 26.5, deleted afterwards), in Xcode's StoreKit testing with no dialogs instead of Apple's sandbox (which needs App Store Connect): `checkpointPurchaseRenewRestoreExpire` bought the free month, waited for the renewal StoreKit made on its own with a month every 30 seconds (active, a later end date), restored on a fresh install with nothing cached (active), and expired it (no access). The other ten `SubscriptionStoreKitTests`: the offer ($9.99, 1 month, free month while eligible, gone after use), purchase, access ending at Apple's date with an injected clock, a forced renewal, expiry, a refund heard by the updates listener (revoked), grace period (access, hint `grace`), billing retry (no access, still `mayRenew`), restore, and Ask to Buy (pending, then the free month when approved). All 11 pass. UI test `StylingAccessTests` (scripted subscription): Profile said Not subscribed, the offer read "1 month free, then $9.99 a month." and "renews automatically", Start free month gave "Styling access is on." and "Your free month ends..."; screenshots in `scratchpad/paywall/`.
  - **Not on CI:** on CI's iOS 27.0 simulator StoreKit's test environment serves no products to the host app (`SKInternalErrorDomain` 17), though the diagnostics read `get-task-allow` from the running app. So `SubscriptionStoreKitTests` is disabled when `NOOK_CI` is set, and two checks (the host's entitlements, the bundled configuration) run on CI. Whether it's iOS 27.0 or the hosted runner needs an iOS 27.0 simulator, which this job couldn't use. Snapshot references for the changed Profile, Help, deletion and tour screens came from CI's iOS 27.0 run; the paused iPad snapshots that draw Help and Profile need re-recording on the next `include_ipad` run.
  - **Tests:** `SubscriptionStatusTests` (access by state and date, stale cache, grace, hints, calendar months, first charge, try-on allowance), `PaidActionTests.paidRequestsCarryTheSubscriptionHintOnly`, `StylingAccessModelTests` (load, buy, Ask to Buy, cancel, failure, restore found and not found, live updates, billing retry, words, Profile, Help, deletion, try-on), `StylingAccessSnapshotTests` (paywall, AX5, free month dark, grace period, ended), and `AccountDeletionTests` and the Profile, Help and deletion snapshots updated.
  - **For Jose:**
    1. Final price (US$9.99 is the placeholder) and storefronts.
    2. Allowances on the paywall (D12).
    3. The mockup's "we remind you before the free month ends": the app sends no reminder today, so the paywall doesn't promise one. Add a reminder (a local notification) or leave it out?
    4. Family Sharing on or off; the group and display names customers see.
    5. Terms: Apple's standard EULA or our own? The app links to the website's `/terms`, not written yet (35b).
    6. App Store Connect setup (docs/payments.md, 14 steps), then a sandbox check on a device.
    7. `StylingAccessTests` isn't in any CI UI part yet; add it to one in `ci.yml` (left alone here).
    8. May an agent use an iOS 27.0 simulator once to find why the StoreKit test sessions get no products there? Until then they run only locally on iOS 26.5.
- 22 October 2026: **Phase 30b, the complimentary unlock and picture credit packs** (jsayram/nifty-outfit-nook#94, merged into `develop` as e491641 with every required check green on the second CI run; the first recorded the new and changed Styling access snapshot references on iOS 27.0). No new dependencies; CI workflows untouched. Backend local commit 63ffe45 (contract synced to the app). App doc `docs/payments.md`, with App Store Connect steps 15 to 20.
  - **Complimentary unlock** (PRD 14.2): non-consumable `com.jsayram.niftyoutfitnook.styling.complimentary`, given only with free one-time offer codes. Styling access → Redeem a code opens Apple's sheet (`offerCodeRedemption`; the iOS 27 form returns the transaction, the iOS 26 one delivers it through `Transaction.updates`), then `redeemedOfferCode()` finishes it and reads the status again. It lives in `SubscriptionStatus.complimentarySince`, read from `Transaction.currentEntitlements(for:)` (refunds and revocations drop out): access with no end, beside any subscription. The screen says it doesn't cancel a renewing subscription and keeps Manage subscription; Profile reads "Complimentary"; the paid-request hint gains `complimentary`. Lily's sponsored policy (PRD 14.4) is server-side and not built.
  - **Picture packs** (PRD 14.4): consumables `...pictures.small` and `...pictures.large`. After a purchase the app sends the signed JWS to the new `POST /v1/credits/claim` and calls `finish()` only after a 200; on any failure the transaction stays open and is claimed again at launch, when Styling access opens, and by the packs' own `Transaction.updates` listener (the subscription listener now leaves consumables alone). The backend reads transaction and product from the JWS, credits sizes from its own list, credits each transaction ID once (repeat: `replayed`; another account: `forbidden`), keeps grants in a new `creditGrants` table (deleted with the account), and adds `credits.pictures` to `GET /v1/usage`. **Mocked**: Apple's signature isn't checked, so crediting runs only with `NOOK_CREDITS_MODE=mock`; otherwise `unavailable`. 30c makes it real.
  - **Balance and spending**: "Picture credits: N left" next to the try-on allowance; packs show only once try-on pictures cost something (Phase 33) and the balance is known, so TestFlight is unchanged. Try-on uses the month's pictures first, then credits (`TryOnFunding`), and credits work without a subscription; the gateway enforces it in 30c.
  - **Placeholders**: pack sizes and prices (10 for US$2.99, 30 for US$6.99, in the app, the `.storekit` file and `convex/credits.ts`), the unlock's App Store price (US$49.99, never sold in the app).
  - **Checkpoint**, on the "30b iPhone 12" simulator (iOS 26.5, deleted afterwards), in Xcode's StoreKit testing: the 9 new `CreditsStoreKitTests` (offer code redemption via `buyProduct(.codeOffer)` and restore on a fresh install, a refunded unlock, the unlock beside a renewing subscription, packs and prices, a pack credited then finished, a pack the server couldn't credit recovered at the next launch, a pack claimed twice credited once, the subscription listener leaving packs alone, the packs listener crediting a pack bought elsewhere) and 30a's 11 all pass (22 hosted tests). Nested in 30a's suite so they're serialized and skipped on CI the same way. Package tests: `SubscriptionStatusTests`, `CreditClaimTests`, contract examples, `StylingAccessModelTests`, snapshot `complimentary-credits-packs` (references for it and the five changed Styling access pictures came from CI's iOS 27.0 run). Backend: `tests/credits.test.ts`, a cross-user case and the deletion case; all backend tests pass.
  - **Playbook findings**: (1) Xcode's StoreKit test environment on iOS 26.5 drops an unfinished consumable from `Transaction.unfinished` about a second after first listing it, with no `finish()` anywhere in the process (instrumented), so recovery is tested through a seam (`StoreKitCreditsService(unfinished:)`). (2) Without `SKIncludeConsumableInAppPurchaseHistory` (now in `AppInfo.plist`) `Transaction.latest(for:)` loses consumables too. (3) `.codeOffer(referenceName:)` on a non-consumable with no code offer configured still buys it, without a `.code` offer on the transaction. (4) The host app's own StoreKit listeners run inside hosted unit tests; the packs listener now doesn't start under XCTest, or it would claim the tests' purchases. (5) gitleaks flags a stand-in JWS whose header starts with `eyJ`; the contract example's header starts with a space instead.
  - **For Jose:**
    1. Pack sizes and prices.
    2. The unlock's App Store price.
    3. Lily's sponsored policy: in 30c, keyed to her signed-in account once you confirm it's her, or later?
    4. Account deletion deletes credit grants: keep unspent paid credits for a time instead? (30c settles billing-record retention.)
    5. App Store Connect setup for the unlock, offer codes and packs (`docs/payments.md` steps 15 to 20); hold the packs back until 30c and Phase 33.
- 22 October 2026: **Phase 30c, server-side verification and the credit ledger** (jsayram/nifty-outfit-nook#96, merged into `develop` as 4b0541e with every required check green on the first CI run, after merging the latest `develop` with #93). Backend local commit 9b5f0f3 (contract synced to the app). No new dependencies on either side (the backend still has only `convex` and `convex-test`); CI workflows untouched.
  - **Apple's signature, no library**: `convex/appstore/` reads DER and X.509 itself and verifies with WebCrypto: ES256 only, exactly three certificates in `x5c`, the root byte for byte the pinned Apple Root CA - G3 (`certs/AppleRootCA-G3.cer`, taken from macOS's system roots; its SHA-256 `63343abf...3e9179` matches Apple's published trusted-root list, checked in a test), Apple's marker OIDs on the intermediate (1.2.840.113635.100.6.2.1) and leaf (1.2.840.113635.100.6.11.1), CA and key-usage checks, unknown critical extensions refused, every certificate valid at the payload's `signedDate`, each certificate signature (P-384 and P-256), then the JWS. Then bundle ID, environment (production takes Production, dev Sandbox) and, for notifications, `NOOK_APP_APPLE_ID`. Apple's real WWDR G6 intermediate verifies against the pinned root in a test, and the verifier runs on a real local Convex backend. `NOOK_APPSTORE_MODE=apple|test` replaces 30b's mock; test mode (a test root) never accepts Production. Not done: online revocation (OCSP) checks, which Apple's library makes optional.
  - **Notifications**: `POST /appstore/v2/notifications` (an HTTP action outside the contract). Each is verified (with its signed transaction and renewal info), handled once per `notificationUUID`, and never lets an older signed fact undo a newer one. SUBSCRIBED, DID_RENEW, DID_FAIL_TO_RENEW (grace), GRACE_PERIOD_EXPIRED, EXPIRED, REFUND, REVOKE, REFUND_REVERSED and ONE_TIME_CHARGE update the account's record; CONSUMPTION_REQUEST is recorded and alerted, not answered; TEST and the rest are recorded. 200 once handled, 400 when it doesn't verify (a `securityLog` line), 503 while checks are off.
  - **Entitlements**: one row per original transaction (subscription or complimentary unlock), linked to the account by `appAccountToken` (a random UUID per account, now in `POST /v1/session` and `GET /v1/me`) or by the app's claim (`POST /v1/entitlements/claim`, needed for offer-code unlocks). Access is worked out from Apple's dates when asked, so it ends on time even if a notification is lost. Another account's purchase is refused before anything is written.
  - **The gate** (24b's `ledger.admit`): styling needs access from those records or the plan override; otherwise `entitlement_required` (403, new in the contract). The hint is never read. Try-on uses the included allowance first (with access), then one credit (with or without access).
  - **Credit ledger**: `creditLedger` replaces `creditGrants`: append-only grant, spend, release, reversal and reinstatement entries, each with a ref unique per account (idempotent), balance derived and never below zero; a refund after spending records `owing`, never charged or taken from a later pack. A refund before the claim blocks the claim. Deleted with the account (credits forfeited, Jose's question open).
  - **Plan override** (Lily's no-limits plan): `admin:setPlanOverride`, internal only and audited, granted to nobody. It skips allowances and credits but keeps rate limits, one action at a time, idempotency, App Attest, kill switches, ceilings and its own 30-day cap (US$5 placeholder).
  - **App** (#96): StoreKit purchases carry the account's `appAccountToken` (cleared at sign-out and deletion); every status read claims the subscription's and the unlock's signed transactions once per launch (off in hosted tests); `entitlement_required` is read by its status for now ("This account can't do that."). Fake backend updated. Docs: `docs/payments.md` (the server's record, steps 21 to 26 for the notifications URL and switching to real verification).
  - **Checkpoint** (backend `tests/appstore.test.ts`, 20 tests, test JWS signed by a test CA made in memory): a refund removes access (subscription and unlock) and credits (spent ones become owing, a reversal restores them exactly); expiry removes access after the grace period, and on time with no notification; REVOKE (Family Sharing) removes access; forged, swapped-root, tampered, `alg: none`, marker-less, expired, wrong-bundle, wrong-app and wrong-environment data is rejected and changes nothing; a replayed notification is idempotent; spends are idempotent and a failed attempt gives its credit back; the hint is ignored; another account's purchase is refused; the plan override is admin-only and given to nobody; deletion removes ledger and entitlements. All backend tests pass (154 in `convex-test`, 16 on a real local Convex backend). App: `NetworkingTests` (new `StylingAccessClaimTests`, contract round trips) and `PurchaseOptionsTests` pass on the "30c iPhone 12" simulator (iOS 26.5, deleted afterwards).
  - **Not clean**: the hosted StoreKit tests (not on CI) passed 22 of 22 in one of four full runs on the branch; the other three failed different timing tests each time (the refund listener, the renewal checkpoint, Ask to Buy) while the Mac's load average was above 600 from other agents. The refund test passes alone, `develop` passed its one run, and the code these tests use only gained purchase options. Worth one rerun on a quiet machine. Two other agents' untracked backend tests (`tests/restore-drill.test.ts`, `tests/incident-rehearsal.test.ts`) call paid endpoints and now need an entitlement (`entitle()` in `tests/support/accounts.ts`, or a claimed test subscription as in `tests/local-backend.test.ts`). The secret lint (`npm test`) had been failing since 30b on the example JWS payloads; fixed.
  - **For Jose:**
    1. Lily's plan override: confirm her account (`usr_` ID) and 30-day budget (US$5 placeholder); then an admin sets it.
    2. Unspent credits on account deletion: forfeited now. Keep them for a time instead?
    3. Owing after a refund: never collected now. Take it from the next pack instead?
    4. CONSUMPTION_REQUEST: answering needs an App Store Server API key (In-App Purchase) and her consent to share usage. Answer, or let Apple decide without it?
    5. Style Me, swaps and Ask stylist don't check styling access in the app, so without access the server's refusal shows as "This account can't do that." A small app phase for a Styling access prompt there?
    6. Switching on: `docs/payments.md` steps 21 to 26 (the app's Apple ID, `NOOK_APPSTORE_MODE apple` on dev with Sandbox, then production, and the two notification URLs).
    7. Online certificate revocation (OCSP) checks of Apple's certificates aren't made (Apple's library makes them optional). Fine, or add them?

- 22 October 2026: **Phase 25b incident response, the backup job and the rehearsal, built and tested locally** (one local commit in the private backend repo; no app change; this repo's [INCIDENT_RESPONSE.md](INCIDENT_RESPONSE.md) is the public summary). Nothing was created in any cloud: no bucket, account or key. The backend still has only `convex` and `convex-test`.
  - **Plans** (backend `docs/incident-response.md`): a leaked key (a per-key table of where to revoke it, what else to do and what breaks), a data exposure, and a cost spike. Each has how it's found, the exact kill-switch and ceiling commands, who acts (Jose; agents never touch production), notice templates, legal questions for the lawyer and the follow-up. It says plainly that the 24b budget alerts are only logged for now, so the providers' own budget emails are the alarm, and that there is no per-account block yet.
  - **Backup job** (`scripts/backup/`, `backup/config.json`, backend `docs/backup.md`): `npx convex export`, encrypted with OpenSSL CMS (AES-256-GCM to an RSA public certificate; `age` isn't on this Mac and isn't needed), a signed S3 upload to R2 written with Node built-ins (no AWS CLI, checked against AWS's published SigV4 example), 30-day retention that never removes the newest 7, a freshness check (newest backup under 36 hours), and a monthly restore drill. The drill needs the offline private key, so Jose runs it. It refuses any deployment not marked `NOOK_ENVIRONMENT=drill`, compares row counts for every table, reapplies the deletion log, and empties the test deployment. Schedules are two example files (launchd for dev, GitHub Actions for production), neither enabled.
  - **Tests** (backend, 171 pass with `npm run test:local`): backup parts and a fake R2 that verifies every signature; backup, then deleting an account, then restoring into a second throwaway local Convex backend, where the deleted account is gone again; a wrong key, a changed byte and a private key on the machine are all refused.
  - **Checkpoint, the rehearsal** (`npm run test:drill`, on a real local backend): `NOOK_RESULT_KEY` rotated with the documented command (about 0.5 s, nothing printed, old cached results stop opening as documented); the stylist switch, the global kill switch and a spending ceiling each refused paid work on the next request (about 15 ms after the command) and resumed when switched back; removing a key before setting the new one pauses the stylist, which is now a warning in the plan. The app's "taking a break" wording was verified in 24b and not re-run. The Mac was busy, so timings are rough.
  - **Lessons:** `convex dev --once` rewrites `.env.local` (it dropped the dev deployment name and pointed the URLs at a throwaway backend, which broke one later test until restored), so scripts that push code to a throwaway backend use `convex deploy`. Cloudflare has no write-only R2 token (found in 25a), so the plan leans on encryption and a retention lock, and the lock still has to be confirmed on a real bucket.
  - **For Jose:**
    1. The R2 bucket `nook-backups` in a Cloudflare account or token separate from the website: no public URL, a 30-day bucket lock, a lifecycle rule at 31 days, and an Object Read and Write token for that one bucket. Confirm the lock stops deletion by the token.
    2. Make the backup key pair on an offline Mac (commands in backend `docs/backup.md`), keep the private key offline, and put only the public certificate in `backup/`.
    3. A Convex production deploy key with the narrowest permissions Convex offers, and a test deployment marked `NOOK_ENVIRONMENT=drill`.
    4. Pick a schedule: GitHub Actions (production; needs a private repo for the backend, which breaks "local only", so your call) or launchd (dev only). A monthly calendar reminder for the drill.
    5. Decide: back up support-note screenshots too (left out now to keep the backup smaller and less personal)? Build a remote "service notice" for the app? Add a per-account block? Wire the budget alerts to email?
    6. Run the first real backup by hand and a drill before trusting it: Ubuntu's OpenSSL, a real R2 bucket and a real cloud export were not tried.
    7. Take the legal questions in INCIDENT_RESPONSE.md to the lawyer.
- 22 October 2026: **Phase 31, monitoring and analytics** (jsayram/nifty-outfit-nook#97, merged into `develop` with every required check green on the first CI run). Backend local commit d7a94a1 on the backend `main` (contract not synced for 33a's try-on changes, which belong to the 33a app PR). No new dependencies on either side (the app still has only clerk-ios and test-only snapshot testing; the backend only `convex` and `convex-test`); CI workflows untouched. Docs: app `docs/monitoring.md`, backend `docs/monitoring.md`.
  - **Crash and speed reports on the phone (Apple's MetricKit, no SDK).** `MetricKitCollector` (Services) subscribes at launch and reads any reports kept since the last one; `MetricKitParser` (Models) cuts each raw `jsonRepresentation()` down at once to fixed fields (kind, date, app and iOS version, device model, a crash's exception and signal as enums, a hang or launch time, peak memory, memory and watchdog exit counts) and drops call stacks, binary names, addresses, region, process ID, bundle ID, termination text and exception text. `DiagnosticsLog` keeps them in `Application Support/Diagnostics/reports.json`: 30 days, at most 200 events and 60 daily samples, outside device backups, file protection `completeUntilFirstUserAuthentication` (reports arrive while locked), emptied by Delete my data. A debug-only screen (`-diagnostics-lab`) shows them, with buttons to add sample reports (with planted personal text) or clear.
  - **Opt-in share with a note.** Send feedback, signed in, shows "Share crash and speed details" only when the phone has something to share. Off for every note, not kept in the draft, and turning it on adds plain lines to the preview (counts, timings, fixed names) that are exactly what the request carries (a test checks every value is on the page, as for the closet counts). Contract `FeedbackRequest.deviceHealth` (`FeedbackDeviceHealth`: whole numbers in range, at most 8 crash kinds as enum names; the contract refuses anything else), stored with the ticket and shown by `support:get`. Apple's own route (Share With App Developers in iOS settings, then Xcode Organizer and TestFlight crash reports) needs nothing from the app.
  - **Server monitoring (backend).** Every log line now goes through `logEvent` (`convex/ops/log.ts`): an allowlist of keys and value shapes (numbers, short plain tokens, an opaque `usr_` ID only under `user`); anything else is dropped and counted. A test fails if any module calls `console.*`, and another replays a busy day with planted names, addresses and tokens. `healthCounters`: hourly counts and timings per route, provider and paid category, no account behind any row, 4 shards, kept 35 days. `health:dailySummary` (internal; run it from the Convex dashboard) gives one UTC day: requests by route with 4xx and 5xx counts and timing buckets, each provider's attempts, errors, spend today and this month against its 24b ceilings with the percentage, feature use, switches that are off and the alerts raised. New `error_spike` alerts (a route: 20 requests, 10 5xx, 20 per cent in an hour; a provider: 5 attempts, 3 failed or uncertain, 50 per cent) go through the same once-only alert hook as the budget alerts at 50, 75, 90 and 100 per cent. The hook is still a mock (one log line).
  - **Analytics: the smallest option, mostly not built.** Built, and clearly fine under the labels: the server's aggregate feature-use counts (no account behind them, no opt-in needed, like the billing totals in PRD 23.1). Not built: the PRD 23 opt-in pipeline (events, resettable ID, ingestion endpoint, settings switch), and on-device usage counters she can see. No tracking, no IDFA, no ATT prompt, no analytics SDK.
  - **Privacy docs.** Labels: Diagnostics (crash data, performance data) linked, App Functionality, optional per note; Product Interaction stays "not collected". PRIVACY_MANIFEST: same, plus a note that no new required-reason API was added; the real `PrivacyInfo.xcprivacy` is unchanged (collected types are filled in at release, as in 24a to 30c). DATA_MAP, THREAT_MODEL and IN_APP_PRIVACY_TEXT updated.
  - **Checkpoint** (forced, in tests; the channel to Jose is still a log line): the backend's `health.test.ts` forces a 5xx spike on a route, failing and uncertain provider attempts, and a cost run to about 95 per cent of a provider's ceiling; each raises its alert once and the mock hook logs it, and the daily summary shows the percentages. For the crash side, `MetricKitParserTests` feed sample reports with a planted crash and the parser keeps the exception and signal; there is no way to force a real crash report through MetricKit on a simulator (it delivers none), so the real-device check is below.
  - **Tests:** backend `npm test`: 210 tests, 191 pass, 19 skipped (the opt-in drills), 0 fail, including `health.test.ts` (14), `logging.test.ts` (4) and one new feedback test. App, on the "31 iPhone 12" simulator (iOS 26.5, deleted afterwards): `MetricKitParserTests` and `DeviceHealthSummaryTests` (19: every event kind, odd and garbage input, units, redaction of every planted string from the records, the file and the summary), `DiagnosticsLogTests` (9: kept across launches, deduped, 30-day ageing with an injected clock, only cut-down fields in the file, outside backups, damaged file, Delete my data through the services), `FeedbackQueueTests` (6 new: the switch's rules, what is sent is what is shown, off for every note, not in the draft), `FeedbackGatewayTests` (3 new: the request carries only numbers and fixed names, the fake refuses what the contract would), and the UI tests `testCrashAndSpeedDetailsAreOfferedListedAndSent` and `testTheDiagnosticsScreenShowsWhatWasKept`.
  - **Playbook findings:** (1) `String(localized:)` formats an `Int` with grouping ("2,400"), which broke the "everything sent is on the page" check; interpolate `String(n)`. (2) `xcodebuild build -scheme Models` from `Packages/NookKit` compiles one module for iOS in about 20 s, where `swift build` builds for macOS and stops on iOS-only APIs. (3) In the Xcode 27.1 SDK `MXMetricManager` is `API_TO_BE_DEPRECATED` (replacement `MetricManager`, iOS 27 and later), which builds without a warning under warnings-as-errors. (4) Rebasing onto the 33a try-on showed the allowlist has to cover every provider's log fields; a test that scans for `console.*` found the two new ones.
  - **Not verified:** no real MetricKit report has been parsed (the simulator delivers none); the parser follows Apple's `jsonRepresentation()` key names and reads loosely. On a device, Xcode's Debug, Simulate MetricKit Payloads sends sample reports: check one before relying on the numbers.
  - **For Jose:**
    1. Alert channel: email, push or both for budget and error-spike alerts? Until then an alert is a log line in the Convex dashboard.
    2. Spike thresholds (route: 20 requests, 10 5xx, 20 per cent per hour; provider: 5 attempts, 3 errors, 50 per cent) are placeholders until there is traffic.
    3. Opt-in analytics (PRD 23, FR-27): build the allowlisted events, resettable ID and the "Help improve the app" switch, or leave it out? Declaring it later adds Usage Data: Product Interaction (not linked) to the label.
    4. On-device usage counters she can see ("what you've done this month", never sent): worth a small phase?
    5. Wording for Privacy and terms about crash reports and Share With App Developers (suggested line in compliance/IN_APP_PRIVACY_TEXT.md): add in 35b?
    6. Declare Diagnostics (crash data, performance data) as linked in App Store Connect, as the labels now say?
    7. Convex log retention is still unverified (DATA_MAP): confirm on the dashboard once the production deployment exists.
    8. Move to Apple's iOS 27 `MetricManager` once iOS 26 is no longer a target (the old API is marked to be deprecated).
- 22 October 2026: **Phase 33a, try-on pictures with the face kept on the phone, built against the fakes** (jsayram/nifty-outfit-nook#99, merged into `develop` as bfaca3b with every required check green, after merging in #95 and #98; backend local commit 30f03aa, with Phase 31's d7a94a1 on top, contract re-synced from backend main). Jose's design of 19 October 2026 (D1), rebuilt properly since the scratch prototype was lost. No new dependencies on either side (the backend still has only `convex` and `convex-test`), CI workflows untouched. App doc `docs/try-on-pictures.md`, "Real pictures (33a)". Nothing called BFL or cost money.
  - **On the phone** (`Services/TryOn`): `PersonAnalyzing` gives her outline (Vision person segmentation, accurate), face (rectangles and landmarks) and neck and shoulders (body pose). `HeadMasking` fills a head shape with flat grey (128): her outline above the chin line near the face, joined with a padded oval, so hair is taken in, not an oval. The same outline puts her on a plain studio backdrop (a soft vertical gradient).
  - **Fail closed:** refuses for no person, no face, two faces or outlines, an outline over 30% unsure, a face outside her outline, or grey missing any pixel of the face box. Then face detection runs again on the faceless pixels and on the exact JPEG to be sent; any face refuses, and so does a detector that can't run. Each refusal is explained kindly and nothing leaves the phone.
  - **What is sent:** only that JPEG (at most 1.5 MB) and up to nine garment JPEGs (cutout on white, or the photo, at up to 768 px, at most 340 KB each), with no metadata, plus each garment's ID, category and kind. Kept on the phone as `TryOnPicture.sent` for **See what was sent**, which shows exactly those bytes with the approved line.
  - **Restore** (`HeadRestore`): her head is aligned by neck and shoulders (small moves ignored, over 8% of the width not trusted). Her original outline is pasted only where the grey survived, so a hat, scarf or collar the model drew stays in front. Leftover grey becomes the backdrop times the brightness gain measured nearby, and the edges are feathered.
  - **Job and consent:** a 27c job (`AIJob.Kind.tryOn`) with one key, a "Dressing you, Keep browsing" sheet, the banner "Your try-on picture is ready" and a dot on Saved Looks. The work files go once the picture is kept or the job fails or is cancelled, and the launch sweep spares a running job's files. Try-on's own consent (`tryon-1`, the approved D1 sentence word for word) and a Privacy and terms switch; Delete my data erases it. Real pictures aren't labelled Simulated.
  - **Backend** (`convex/tryon/`): `POST /v1/try-on` checks the body (JPEG or PNG magic bytes, sizes, 1 to 9 unique garments), the consent (`TRYON_CONSENT_COVERS`, default `tryon-1:bfl`, so there's no silent fallback to OpenAI) and the result key before admission.
    - It then admits through 24b and 30c's ledger (entitlement, allowance then credits), seals the inputs into Convex file storage and starts a scheduled job. The answer is 409, Retry-After 5. The app asks again with the same key and body until it gets 200 with the picture.
    - The try-on lease is 360 s; the stylist's stays 60. Inputs are deleted when the call ends. The sealed result is kept at most 30 minutes, and 2 minutes after delivery. A cron runs every 10 minutes, and account deletion removes the staging.
    - The FLUX.3 adapter runs only when `BFL_API_KEY` is set. It sends base64 images, `grounding: false`, `resolution: "1k"`, `aspect_ratio: "auto"` and no `output_format`, all checked against docs.bfl.ai on 22 October 2026. It polls the regional `polling_url` and treats Reasoning as in progress. The key goes only to `https` hosts under `bfl.ai`. Cost comes from BFL's credits.
    - Otherwise a fake answers, echoing the faceless photo (the Convex runtime has no image codec). The prompt is built only from categories and kinds, and a hat adds "pulled down over the top of the grey shape". `scripts/try-tryon.mjs --yes` makes one real call with the key read from `~/.config/nook/bfl.env`. It was written but **not run**.
  - **Simulator vs device:** no Vision person, face or pose request runs on the iOS 26.5 simulator, so tests and the checkpoint use `SyntheticPersonAnalyzer` on a drawn figure (`SyntheticPerson`, debug only and checked out of Release by `check-release.sh`, never a photo of anyone).
    - I checked the real Vision path on this Mac with the AI-generated sample person. One face was found, none after masking (also in the JPEG), and no grey was left after restoring onto a copy moved by 14 and 9 px. The pose found a move of 15.5 and 8.1.
    - The real run is on the device checklist for Jose's iPhone 14.
  - **Checkpoint**, on the "33a iPhone 12" simulator (iOS 26.5), as the UI test `TryOnTests` with `-seed-tryon -cloud-tryon slow`:
    - Try it on, Allow, "Dressing you"; Keep browsing, then the Closet tab; the banner "Your try-on picture is ready, Tap to see it." appears over the closet.
    - The picture opens ("Made today", not Simulated) with her drawn head back and the garment photos drawn on by the fake.
    - See what was sent shows the faceless figure on the studio backdrop and the 2 clothing photos.
    - Screenshots are in `scratchpad/tryon/` (4).
  - **Tests:** app `HeadMaskingTests` (11), `HeadRestoreTests` (5), `PhoneTryOnTests` (5), `TryOnJobsTests` (4, ManualClock, real store), `RealTryOnModelTests` (4), `TryOnGatewayTests` (4), and `ContractTests` try-on limits. The whole package suite passed locally apart from the known iOS 26.5 snapshot and runtime checks. Backend 191 pass (19 more on the real local backend).
  - **CI:** the first run passed every job. Develop then moved twice (#95, #98), so I merged it in each time, and the next runs each failed one or two different flaky tests in code this PR doesn't touch: Swap sticker snapshots at 99.2% and 99.4% (99.5% needed), a garment-detail loafers snapshot at 98.3%, and #98's new `MigrationDebugTests.aVersion2StoreBecomesAVersion1StoreWithTheSameRecords`, which passed 3 of 3 here and in the run before. Re-running the failed job passed. The snapshot flake is the one 27a saw; the migration test is worth its own look.
  - **For Jose:**
    1. Run the device checklist on your iPhone 14 (the doc), then Lily's iPhone 12 for speed and memory.
    2. The first real FLUX.3 call: set `BFL_API_KEY` on dev with prepaid credits and a spend limit, then OK `scripts/try-tryon.mjs --yes` (about US$0.05). Region: `api.bfl.ai` (global) or `api.us.bfl.ai`?
    3. The consent says "Our server keeps neither", but the backend holds the photos encrypted for up to 30 minutes while the picture is made. Keep the sentence, or say it deletes them within 30 minutes (IN_APP_PRIVACY_TEXT, PRIVACY_POLICY_OUTLINE 4d)?
    4. A dressed picture lost after delivery (the app killed between receiving and restoring) can't be fetched after 2 minutes, so that job says it didn't finish and the charge stands. Keep the result longer, or accept it?
    5. Saving a look from Your looks happens before the job starts (a picture needs a look), so a failed picture leaves the look saved. OK?
- 22 October 2026: **Phase 33b, try-on photo setup with the app's camera and a check before she saves it** (jsayram/nifty-outfit-nook#104, with PR 101 merged in; no new dependencies, CI workflows untouched). Jose's design of 19 October 2026: the photo is ideally taken with the app, the app guides it, and no pose is changed by the AI. App docs `docs/profile.md` ("Your try-on photo, taken with the app") and `docs/try-on-pictures.md` ("Photo setup (33b)").
  - **Camera** (`Features/TryOn/Setup`): Profile, Your try-on photo, **Take your photo** (or Take a new photo) opens a full-screen viewfinder, shown whole at 3 by 4 so what she sees is what Vision looks at and what is photographed, with a dashed outline to stand in. The front camera comes first, with a switch. Its own words come before iOS's prompt (`CameraExplainerText.tryOn`), and the camera purpose string now names the try-on photo (the wording planned in PERMISSIONS.md). The live picture is covered in the app switcher.
  - **Live hints:** `VisionFrameAnalyzer` (Services) reads about five frames a second on the phone (body pose, person outline, brightness) and drops each frame. `FramingGuidance` (Models, plain rules) turns that into one hint, most urgent first: not in the picture, more than one person, step back (cut off at the top or bottom, no ankles), step closer, move to the middle, face the camera (no face joints, or shoulders close together), arms a little away from the body, more light, light behind her. `FramingCoach` keeps the hint steady (two frames must agree) and times the photo: good for a second, then a 3, 2, 1 countdown, and any new hint stops it. The shutter and a switch for the timer are always there. No hint mentions hair, and hats and scarves aren't detected: the sheet says once that they're fine but best without. VoiceOver hears a hint when it changes. Without Vision (a simulator) the card says hints aren't available and leaves the shutter to her. The camera's photo is cut to at most 2,048 px (PR 101's cap for her photo); what is sent is still the 1,280-pixel faceless copy.
  - **The check before saving** (`TryOnPhotoChecker`): the photo (camera or library) is kept through 22a's intake, then checked with the same function try-on runs before it sends anything (`PhoneTryOn.facelessPortrait`: one person, one face, head and hair grey, no face found in the pixels or the JPEG), so a photo it passes is one try-on accepts (a test runs both on every case). Passed: "This photo works" with gentle tips from the same rules (whole body, arms, light, facing the camera). Refused: the reason in kind words, no way to keep it, her current photo untouched. Checks that can't run: Check again, or Keep it anyway (try-on still checks before sending). Nothing is her try-on photo until Use this photo; any other way out deletes the copy. Replace and Remove work as before from the same sheet.
  - **Consent wording fixed (Jose approved):** "Our server keeps neither" is now "Our server keeps the photos, encrypted, for up to 30 minutes while your picture is made, then deletes them." Updated in the app, `IN_APP_PRIVACY_TEXT.md`, `PRIVACY_POLICY_OUTLINE.md`, `DATA_MAP.md` and the 33a bullet above. The version stays `tryon-1`: nothing real has been sent under the old text, and the backend only checks which provider the text names. DATA_MAP also has a row for the camera frames (in memory, never kept or sent).
  - **Simulator:** no camera and no Vision, so a debug-only `-fake-camera [away|two]` opens the same camera screen over a drawn stand-in (`SyntheticPerson`) that gives hints in turn. The UI test `TryOnPhotoSetupTests` passed on the "33b iPhone 12" (iOS 26.5): step back, arms out, ready, the timer takes the photo, "This photo works", Use this photo; and a refused photo (facing away) that can't be kept. Screenshots are in `scratchpad/tryon-setup/` (5). `scripts/check-release.sh` also checks that `-fake-camera` and the stand-in camera aren't in Release, and the Release build passes it.
  - **Tests:** `FramingGuidanceTests` and `FramingCoachTests` (19), `TryOnPhotoCheckerTests` (9), `TryOnCaptureModelTests`, `CameraPhotoSizeTests`, `TryOnSetupTextTests` (no hint, tip or message mentions hair; the consent text), `ProfileModelTests` (keep and check, use, pass on, a problem changing nothing), 12 snapshots (hints, check screens, consent text; recorded on the 26.5 simulator, with large text checked by measuring because AX5 pictures differ between runtimes) and the UI test above. On the 26.5 simulator the older AX5 snapshots and the "recorded runtime is 27.0" checks fail, as they would on develop, and the StoreKit tests fail locally; none touches this change.
  - **Not verified:** the real camera, live Vision and every threshold in `FramingGuidance.Limits` (arm reach, shoulder share, edge margin, darkness). Device checklist items 2.18 (camera hints and timer) and 2.19 (the check) are added for Jose's iPhone 14, then Lily's iPhone 12.
  - **For Jose:**
    1. Run 2.18 and 2.19 and send back any hint that was wrong or late: the thresholds are my estimates.
    2. The front camera comes first because she is likely alone with the timer. Say if the back camera should lead.
    3. A photo the check refuses can't be kept, with no override except when the checks can't run at all.

- 22 October 2026: **Phase 33c, the privacy walkthrough and the real-step loading captions** (jsayram/nifty-outfit-nook#106, merged into `develop` with every required check green, after merging in the 32a changes; no new dependencies, CI workflows untouched). App doc `docs/try-on-pictures.md`, "Privacy walkthrough (33c)"; the words are in `compliance/IN_APP_PRIVACY_TEXT.md`.
  - **Real steps, no timer:** `TryOnStage` lists what the code does in order: hiding the face, swapping in the studio backdrop, checking that no face is left, dressing, putting her back together on the phone. The phone reports each as it starts (`prepare(...progress:)`; `HeadMasking.mask` was split into `head` and `paint` so the backdrop can be reported), and the 27c job records its step (`AIJob.tryOnStage`) and keeps it if it fails. `TryOnProgress` marks each step done, doing, waiting, not started or stopped. A refusal stops at its step with nothing sent (a face still found stops at the check); a failed job stops at "Dressing you" or the last step. Sending and the image service dressing her are one step, because the app makes one request and can't tell them apart.
  - **First time:** a 5.8 second drawn walkthrough plays on her first real picture while the phone works: soft veil over the head and hair, studio backdrop, the check, the photo to the cloud and back dressed, her face back with an "On your phone" lock. No cut-off head. It is a drawn figure, not her photo, so there is nothing of hers to hide and no veil to misplace on a real face. A test fails if a real step has no beat or a beat is out of order. **No Skip the first time** (it holds nothing up, the picture is made behind it); it is remembered once it has played to the end. Later pictures show only the real steps, with "Watch how it works" for a replay with Skip. Reduce Motion fades and moves nothing; VoiceOver reads every step; Dynamic Type wraps.
  - **Wording, reconciled:** the approved line stays word for word under the walkthrough and under See what was sent. It says the photos go to Black Forest Labs but not that our server holds them on the way, which the corrected 33b consent says (up to 30 minutes, encrypted, then deleted). They don't contradict each other, so I left the approved line alone and put a second note right under it, with the consent's own words, in both places. A test keeps the two 30 minutes the same.
  - **Found while recording:** the walkthrough restarted when the sheet moved from the phone's steps to the job (a model built in a redraw, and a view in different `switch` branches). The unit tests passed. Fixed (it owns its model and sits above the switch), and the UI test now checks it never starts over. Added to the playbook, chapter 6.
  - **Checkpoint**, on the "33c iPhone 12" simulator (iOS 26.5), as the UI test `PrivacyWalkthroughTests` against the fake backend's slow image service: Allow, the walkthrough plays through with no Skip and the plan's line under it, then the five steps tick ("Dressing you, in progress"), Watch how it works replays with Skip, Cancel. The 33a UI test still passes. Four key frames and a 14 second recording are in `scratchpad/walkthrough/` (veil over the head, the photo out at the cloud, her face back with the lock, the real steps).
  - **Tests:** `TryOnProgressTests` (8), `PrivacyWalkthroughTests` (11: beats against the real steps and order, 5 to 6 seconds, the exact line and the 30 minutes, Reduce Motion, a manual clock, no Skip the first time, Skip on a replay), more in `RealTryOnModelTests` (steps while preparing and sending, a refusal and a failed job stopping at their step, first time versus later, replays), `TryOnJobsTests`, `PhoneTryOnTests`, 9 snapshots (recorded on the 26.5 simulator; large text by measuring), and the UI test.
  - **Not verified:** the real Vision timing of the three on-phone steps and a real image call; whether the first showing reads well at six seconds. Both are on the device checklist (2.24).
  - **For Jose:**
    1. Watch it on your iPhone 14 and with Lily (2.24). Say if the first showing is too fast to read, or should have a Skip after all.
    2. The walkthrough draws a figure, not her photo. Her own photo would be more personal, but the veil would have to follow her real head, and the picture would need hiding in the app switcher. OK as drawn?
    3. Should the approved line itself carry the server's 30 minutes? Today it is a second note under it. If it moves into the line, the privacy policy and the App Store label should say the same.

- 22 October 2026: **Phase 32a, scale and load testing** (app: jsayram/nifty-outfit-nook#105, merged into `develop` as 85d7966 with every required check green; backend: local commits `8436a42` and `e942782`, never pushed). Everything ran locally (a local Convex backend in its own copy, the iOS simulator); nothing touched a cloud service. Written up in [LOAD_TEST_REPORT.md](LOAD_TEST_REPORT.md).
  - **Method:** `scripts/load-test.mjs` (24 simulated users, try-on polled the 27c way, App Store bursts; local addresses only) and `scripts/cost-profile.mjs` (documents read and written per request, in `convex-test`) in the backend repo; `ScaleBrowsingTests`, `ScaleStoreTests` and `ScaleDataTests` in the app with 5,000 pieces, 2,000 saved looks (plus 1,000 unsaved) and 500 pictures.
  - **Fixed (backend):** a style request took 1.5 s with 4,000 failed or free actions behind it and 12.6 s with 12,000, from a `.filter` after an index (now 44 and 105 ms); about 5% of styling requests and some try-on settlements failed on write conflicts (admit and settle are retried; none reached the app after); the credit balance read the whole history (3,012 documents at 3,000 rows, now 13); every request's health sample read the whole hour's range (now a point read); five daily clean-ups took one batch a day and fell behind; paid actions, cost entries and challenges were never cleaned (24b's gap, now a daily job with 35 days).
  - **Fixed (app):** the backup export held every photo in memory, 1,789 MB at 1,000 photos, now 71 to 76 MB (`FileHandle.read` in an autorelease pool).
  - **App numbers (simulator, Debug):** the store opens in 4 ms and reads everything cold in 325 ms; Closet opens in 23 ms, a typed search takes about 60 ms, possible matches about 0.2 s; Saved Looks opens in 185 ms, Saved | All takes 41 ms, search 110 to 160 ms; one edit saves in 2 ms; export with records only takes 0.9 s, with 1,000 photos 4 s.
  - **Left alone on purpose:** the shared spend counters (sharding would give up exact ceilings; the report says when to shard and how), and the try-on poll that re-sends the photos each time (a contract change, so a question).
  - **Checkpoint:** results against agreed limits: Convex's documented limits (32,000 documents scanned, 64 MiB per action, 1 million calls a month on Starter) leave room at 1,000 users, with about 2.5 million calls a month, so Professional is the safe plan. Cold launch, memory and typing on a phone wait on the device list (2.20 to 2.23).
  - **For Jose:**
    1. Add a small status call so a try-on poll doesn't re-send the photos (changes the contract and the app)?
    2. Is 35 days fine for finished paid actions and cost entries?
    3. Which plan for the backend: about 2.5 million function calls a month at 1,000 users.
    4. Run 2.20 to 2.23 on the iPhone 14, and 2.20 on Lily's iPhone 12 when she can lend it.
- 22 October 2026: **Release: sign-in when it's first needed, and Report a problem on AI results** (release audit blockers 1 and 10; jsayram/nifty-outfit-nook#109, merged into `develop` as 922410e; backend local commit 750fa46). Where sign-in lives was never decided (24a Q5), so this is the least intrusive standard pattern, easy to move. App decision `docs/decisions/0011-sign-in-and-ai-reports.md`. No new dependencies.
  - **Sign-in:** nothing asks at launch. A short sheet appears the first time she starts cloud styling, a real try-on picture, a purchase or redeemed code, a support note, a report, or Delete my account after her session ended. It says why, then offers Apple's own `ASAuthorizationAppleIDButton` (black in light mode, white in dark), Not now, and the privacy policy. Signing in lets what she started carry on; Not now cancels it with nothing sent or bought. Style Me falls back to Quick ideas with a Sign in button, and its Not now holds while the app runs. Profile has "Signed in with Apple" with Sign out (asked first), or "Sign in". Send feedback signed out adds "Sign in to send it to us directly". Built as `SignInGate` and `.signInGate()`: screens call `\.signIn` before cloud work, and the root and each sheet that starts cloud work install their own gate. It uses 24a's `AccountService` (Clerk when configured, the fake in Debug). A Release build without settings offers no sign-in and keeps #101's "Not available right now".
  - **Report a problem (guideline 1.2):** shown under cloud stylist looks (the look or its why line) and on a real try-on picture's page; Quick ideas and simulated pictures are made on the phone and have none. Ask stylist answers can use the same sheet once that screen exists. The sheet has four reasons, an optional note (500 characters), Include the picture (try-on only, off every time) and Hide. It goes to `POST /v1/feedback` as `kind: "aiReport"` with an `aiReport` block (subject, reason, result ID, action ID, version, who made it, when, hidden). The contract refuses provider and model fields; the backend finds the action (hers only, else her nearest one within 15 minutes) and adds the feature, the provider from the cost record and the configured model. A cloud result's ID and a real picture's ID are now the server's action ID. Reports have their own rate limit (5 in a burst, then one every 12 minutes, 20 a day). Hide removes a look result from her history (saved looks stay) and offers Try a different outfit; a picture goes as Delete picture does, with Undo.
  - **Checkpoint**, on the "signin iPhone 12" simulator (iOS 26.5, deleted afterwards), as the UI test `SignInAndReportTests` with `-cloud-stylist normal -signed-out`. Nothing asked at launch. Style me, then Review and Allow, then the sign-in sheet. Not now gave Quick ideas with Sign in. Sign in, then the fake Apple sign-in, and the stylist's looks arrived with the why line without tapping Style me again. Report a problem, "These aren't my clothes", Send, and a reference came back. Profile: Sign in, then Signed in with Apple, then Sign out. Screenshots in `scratchpad/signin/` (sign-in sheet, Profile row, report sheet).
  - **Tests:** app `SignInGateTests` (5), `SignInFlowTests` (5: Style Me, styling access, Delete my account, try-on), `AIReportModelTests` (5), `HideReportedResultTests`, 7 snapshots (`SignInSnapshotTests`), 4 gateway cases and the new contract examples, and the UI test above; `StylingAccessTests` now signs in before buying. Locally every package test passed apart from the 11 known iOS 26.5 snapshot and runtime checks. These UI tests passed locally: SignInAndReport, StylingAccess, CloudStylist, SupportFeedback, Profile and AccessibilityAudit. Backend: 7 new tests in `tests/feedback.test.ts`; 256 pass, including the real local Convex run. **CI:** the first run failed one new snapshot (`sign-in-sheet-ax5`, 1 px taller on iOS 27.0), so I took CI's image; the second run passed every required job. The UI parts didn't run on the PR (no `run-ui` label); they run in the next batch on develop.
  - **For Jose:**
    1. Keep sign-in where it is (asked when first needed, plus Profile), or move it (onboarding, an account screen)?
    2. The drafted sheet in IN_APP_PRIVACY_TEXT had "I'm 18 or older" and the Clerk and "outside the US" lines. They're not on the built sheet. Add the age line now, or after the lawyer (question 9)?
    3. Include the picture sends the try-on picture with her face to the support ticket, only when she ticks it. Keep it, or mask the face first?
    4. A real-device check of the Apple sheet with the Clerk dev instance once it exists (backend-switch.md, "Sign-in in the app").
    5. The audit's numbering: the report item is blocker 10 (7 is the trademark search). I updated 1 and 10.
