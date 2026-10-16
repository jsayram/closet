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
- Search over earlier unsaved results as well as saved looks (LR-06.4). Stage A keeps them but only saved looks are searchable.

**Checkpoint:** Jose and Lily try each one on real data, and a schema change carries them across.

### Phase 22a: Photo intake

- PhotosUI and the camera, with permission flows.
- *(from Stage A)* Strip EXIF and location from stored originals. The photo picker includes location by default (app `docs/cutout-feasibility.md`, SECURITY_STANDARD.md section 4).
- *(from Stage A)* A real try-on photo in Profile through the system picker, with its metadata stripped (app `docs/profile.md`).
- *(from Stage A)* Decide on the optional garment-understanding upload: its own named, consented processor, or leave it out (DATA_MAP.md, requests to services).
- *(from Stage A)* If Jose hasn't made the Phase 8a call by then, run the cutout benchmark on Lily's iPhone 12, set the thresholds and decide go or no-go before real photos depend on it.

**Checkpoint:** add real garments from the library and the camera.

### Phase 22b: Image storage and caching

- Originals next to cutouts, thumbnails, the image cache, and disk-space handling.
- *(from Stage A)* Stored files for generated try-on pictures, removed when she deletes a picture (app `docs/try-on-pictures.md`).
- *(from Stage A)* Deleting a garment for good removes the pictures that depend on it, where the purge rules say so (PRD 9.2.4). Today a purged piece is only left out of the drawing.

**Checkpoint:** a large real-photo closet stays smooth and the storage footprint is reasonable.

### Phase 23a: Backend options

- Compare hosting options, including Supabase, for the gateway, auth, the usage ledger and feedback, against the PRD's requirements.

**Checkpoint:** Jose reads the comparison.

### Phase 23b: Backend decision

- Choose the stack, the environments (dev, staging, production) and the costs at expected usage.

**Checkpoint:** Jose approves the stack and the monthly cost estimate.

### Phase 24a: Gateway and identity

- Gateway skeleton, user identity (Sign in with Apple where needed), device attestation, and request validation.
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** an authenticated request round-trips; bad requests are rejected.

### Phase 24b: Limits and cost protection

- Rate limits, the atomic usage ledger, cost reservations before any paid call, and a kill switch (PRD 11.6).

**Checkpoint:** limits hold under deliberate abuse in a test.

### Phase 24c: Authorization and account deletion

- Row-level access rules with default deny, tests proving one user can't read another's data, and in-app account deletion that removes server data.
- *(from Stage A)* Sign in with Apple token revocation when the account is deleted, and the note on Delete my data that deleting doesn't cancel a subscription (app `docs/settings.md`).

**Checkpoint:** a cross-user access test fails as it should, and a deleted account leaves nothing behind.

### Phase 24d: Support and feedback channel *(new)*

- The private support queue that Send feedback reaches, replacing the share sheet, with an optional reply address.
- The public feedback board (PRD 22) and the optional, separately opted-in email program (FR-44, PRD 22.4), or a written decision to leave them for later.
- The project's support email in ACCOUNT_INVENTORY.md and on the website's support page (DATA_MAP.md open points, app `docs/settings.md`).

**Checkpoint:** a note sent from the app reaches the queue and Jose can answer it.

### Phase 25a: Secrets and credentials

- AI provider keys only on the server, separate secrets per environment, rotation schedule, and least-privilege access for every service account.

**Checkpoint:** a secrets review; nothing sensitive in the app bundle or any repo.

### Phase 25b: Incident response

- Written plan for a leaked key, a data exposure or a cost spike: who acts, how every key gets rotated, how paid features get switched off, and how users are told.

**Checkpoint:** a rehearsal. Rotate one key and flip one kill switch, following the plan.

### Phase 26: Network resilience

- Timeouts, cancellation, bounded retries, offline mode, and handling of 401, 429 and 5xx responses (PRD 11.7).

**Checkpoint:** every failure case forced against a test server.

### Phase 27a: Cloud stylist

- Provider adapter on the server, typed response validation, and server-side model configuration.
- *(from Stage A)* The "From your history" check before paid inference (FR-58), and the "why" line under results, written by the stylist (app `docs/your-looks.md`).
- *(from Stage A)* Labelled ideas for an empty closet (PRD 8.1). Pending Jose's decision: Stage A offers Add a piece instead (app `docs/style-me.md`).
- *(new)* Ask stylist on results, which is still a stand-in sheet (RD-06, app `docs/your-looks.md`).
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** styling quality on Lily's saved scenarios.

### Phase 27b: Token and cost efficiency

- Prompt size budgets, caching safe repeat results, and cost tracking per request.

**Checkpoint:** measured cost per styling request against the budget.

### Phase 28: On-device stylist

- Apple's on-device model on eligible devices, with the same response contract.

**Checkpoint:** same scenarios on an eligible device and on the iPhone 12 fallback.

### Phase 29: Weather

- WeatherKit feeding the request and the Home windows.
- *(from Stage A)* Its location permission and switch in Privacy and terms.

**Checkpoint:** live weather shows in the room and shapes suggestions.

### Phase 30a: Subscription and paywall

- StoreKit 2 subscription, free trial and the paywall, following Apple's rules for subscription wording.
- *(from Stage A)* The try-on picture allowance, and Help's "Free and paid" topic (app `docs/settings.md`, `try-on-pictures.md`).

**Checkpoint:** sandbox purchase, restore, renewal and expiry.

### Phase 30b: Complimentary unlock and credit packs

- Offer-code unlock and consumable image-credit packs.

**Checkpoint:** each purchase type in sandbox.

### Phase 30c: Server-side verification and credit ledger

- App Store Server Notifications, entitlement checks on the server, and the credit balance that the gateway enforces.

**Checkpoint:** refunds, expiry and revoked purchases correctly remove access and credits.

### Phase 31: Monitoring and analytics

- Crash reporting, cost and usage alerts, and opt-in analytics only if they earn their place.
- *(from Stage A)* The analytics switch in Privacy and terms, if analytics ship.

**Checkpoint:** a forced crash and a forced cost spike both reach Jose.

### Phase 32a: Scale and load testing

- Load tests on the gateway, many concurrent users, and very large closets and histories on the device.

**Checkpoint:** results against agreed limits.

### Phase 32b: Security testing

- Work through the OWASP MASVS (app) and ASVS (backend) checklists, run abuse tests at scale, and inspect the release build for secrets and sensitive data at rest.

**Checkpoint:** every finding fixed or recorded as an approved exception.

### Phase 33: Try-on pictures (gated)

- Only after the PRD 9.2 checks pass and a provider is chosen. Will be split when we get here.
- *(from Stage A)* Its consent switch in Privacy and terms.

**Checkpoint:** the PRD's go/no-go gates.

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
