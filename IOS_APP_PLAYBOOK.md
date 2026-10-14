# iOS app playbook

A reusable guide for building iOS apps with paid AI features, subscriptions and one-time purchases. Started 7 October 2026 alongside [the Nifty Outfit Nook build plan](SWIFT_BUILD_PLAN.md).

Nifty Outfit Nook is the first project built with it, and building that app is also how this playbook gets written. The playbook is a deliverable in its own right, as important as the app. Its aim is apps that are reliable, compliant with Apple's rules, safe for users and the developer, and cheap to run.

The rule for this file: only write down what we actually did and checked. Each section fills in as the matching phase finishes. Lessons specific to Nifty Outfit Nook stay in the build plan's progress log.

## Required standards

- **[SECURITY_STANDARD.md](SECURITY_STANDARD.md)** is the required security baseline for every app built with this playbook. It isn't optional and isn't a later phase.

## 0. Repositories and branching
Separate repos for design and planning, the app, and the private backend. Git Flow in the app and backend repos (`main`, `develop`, `feature/*`, `release/*`, `hotfix/*`), with protected branches, required CI and no stacked feature branches. The decided model is in [SWIFT_BUILD_PLAN.md](SWIFT_BUILD_PLAN.md#repositories-and-branching); lessons go here once it's in use. *(Phase 1b)*

Verified 14 October 2026 on a public personal repo (Nifty Outfit Nook, Phase 1b):
- **Order matters: CI first, rulesets second.** Merge the PR that adds CI, then create the ruleset, so the required checks already exist by name. A required check is the job's `name`. Pin it to GitHub Actions with `integration_id: 15368` so a commit status from elsewhere can't satisfy it.
- **One ruleset can cover `main` and `develop`** (`refs/heads/main` and `refs/heads/develop` in `include`). With `bypass_actors: []` the API reports `current_user_can_bypass: "never"`, administrators included. Rules used: `deletion`, `non_fast_forward`, `required_linear_history`, `required_signatures`, `pull_request` (0 approvals for a one-person repo, `allowed_merge_methods: ["squash"]`) and `required_status_checks`.
- **Test it from a throwaway clone.** `git commit --allow-empty` on `develop` and push: GitHub rejects it and lists every rule broken (pull request, status checks, signatures). Deleting the branch is rejected too. `gh api repos/{o}/{r}/rulesets/rule-suites` shows each evaluation afterwards.
- **`gh pr merge` stops working under `required_signatures` when your commits are unsigned.** It refuses on the client side ("the base branch policy prohibits the merge") because GraphQL reports the PR as `BLOCKED`, even with every check green. `gh api -X PUT repos/{o}/{r}/pulls/<n>/merge -f merge_method=squash` merges it as a normal user: GitHub signs the squash commit and the ruleset evaluation passes. Wrap that in a script that runs `gh pr checks <n> --watch` first. Signing commits locally probably also fixes it, but we haven't tried that.
- **Squash-only promotions to `main` need a promotion branch.** Verified 14 October 2026 at the first milestone (Nifty Outfit Nook, end of Phase 3). With `required_linear_history` and squash as the only merge method, promoting `develop` into `main` leaves `main` with one squash commit that `develop` never gets, so the two share no history past the first commit. The first promotion PR straight from `develop` merged cleanly because `main` was still the first commit. A later one wouldn't: simulating one more `develop` commit, `git merge-tree --write-tree origin/main <that commit>` reported a conflict in the edited file. A sync PR from `main` back into `develop` doesn't help, since it's squashed too. What works: `git commit-tree <develop's tree> -p origin/main`, push it as a `promote/...` branch and open the PR from there; the diff is exactly what changed since the last promotion. Script it, and point the agent notes at the script.
- **Repo settings that aren't files**, all set with `gh api`: squash merge only and delete branches on merge (`PATCH /repos/{o}/{r}`); secret scanning and push protection (`security_and_analysis` in the same PATCH; non-provider patterns and validity checks stay off on a free personal repo); `PUT .../vulnerability-alerts`, `.../automated-security-fixes` and `.../private-vulnerability-reporting`; a read-only token that can't approve PRs (`PUT .../actions/permissions/workflow`); only GitHub-owned actions, with SHA pinning enforced (`PUT .../actions/permissions` with `allowed_actions=selected` and `sha_pinning_required=true`, then `.../selected-actions` with `github_owned_allowed=true`); and approval for every outside contributor's workflow run (`PUT .../actions/permissions/fork-pr-contributor-approval` with `all_external_contributors`). List them in the README, since nobody will find them in the code.

## 1. Project setup
Project generation, package layout, configurations, language mode, lint and format. *(Phase 0a, 1a)*

Verified 13 October 2026 with Xcode 26.6 (Nifty Outfit Nook, Phase 1a):
- **A hand-written project file works.** With `objectVersion = 77`, each source folder is one `PBXFileSystemSynchronizedRootGroup` listed in the target's `fileSystemSynchronizedGroups`, and the Sources and Resources build phases stay empty. Put build settings in xcconfig files (`baseConfigurationReference`) so the project file stays small. Check it with `xcodebuild -list` and a real build.
- **Add a local package as a folder reference, not an `XCLocalSwiftPackageReference`.** Use a `PBXFileReference` with `lastKnownFileType = wrapper` and `path = Packages/<Name>`, and product dependencies without a `package` field. With `XCLocalSwiftPackageReference`, Xcode built the package with `-suppress-warnings` (which clashes with warnings-as-errors) and silently skipped the package's test targets in the scheme and test plan.
- **Run package tests through a test plan.** Each package test target appears as `{"containerPath": "container:Packages/<Name>", "identifier": "<TestTarget>", "name": "<TestTarget>"}`. The app scheme's test action then runs the package tests and the UI tests together on a simulator, which matters when the package is iOS-only and `swift test` can't run on the Mac.
- **Warnings as errors:** set `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in the project xcconfig and `.treatAllWarnings(as: .error)` (Swift 6.2 tools) in `Package.swift`. Don't pass it on the `xcodebuild` command line, because that reaches package targets too and can clash with `-suppress-warnings`. Prove it works by adding a warning on purpose.
- **Data Protection** goes in the entitlements file as `com.apple.developer.default-data-protection = NSFileProtectionComplete`. A simulator build shows it in the `*-Simulated.xcent` file under DerivedData, not in `codesign -d --entitlements`.
- With `defaultIsolation(MainActor.self)` on a module, its test target also needs `@MainActor` on tests that touch that module's types, or `#expect` fails to compile.

### CI for an iOS app on GitHub Actions

Verified 14 October 2026 (Nifty Outfit Nook, Phase 1b):
- **Check the runner image before picking a label.** The image READMEs in `actions/runner-images` (`images/macos/macos-26-arm64-Readme.md`) list each Xcode and simulator runtime. `macos-26` had Xcode 26.0.1 to 26.6 and iOS 26.2, 26.4 and 26.5 simulators. Select Xcode by path (`sudo xcode-select --switch /Applications/Xcode_26.6.app`) instead of trusting the default, and choose the simulator at run time from `xcrun simctl list devices available --json`, because device names and runtimes differ between the image and a dev Mac.
- **Pin actions by SHA.** `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` gives the commit SHA when `object.type` is `commit`, as it was for every tag we used. An annotated tag returns `tag` instead, and its `object.url` leads to the commit. Write `uses: actions/checkout@<sha> # v7.0.1` so Dependabot can still update it.
- **gitleaks without a third-party action:** download the release tarball, check it against a SHA-256 copied from the release's checksums file into the workflow, and run `gitleaks git --redact .` after a `fetch-depth: 0` checkout to scan the whole history. It takes about 7 seconds on `ubuntu-latest`.
- **Workflow defaults:** top-level `permissions: contents: read`, `persist-credentials: false` on checkout, a timeout on each job, and a concurrency group that cancels superseded runs only for pull requests (`cancel-in-progress: ${{ github.event_name == 'pull_request' }}`). Upload the `.xcresult` only `if: failure()`.
- **Timing:** swift-format lint about 10 seconds, gitleaks about 7 seconds, and a Release build plus package and UI tests about 5 to 7 minutes on `macos-26`, most of it the first UI test launching the simulator.
- **The local hook:** `.githooks/pre-commit` running `gitleaks git --pre-commit --staged --redact --log-level warn`, installed per clone by a script that sets `core.hooksPath`. Test it with a fake but well-formed token (a random 36-character `ghp_` string trips the `github-pat` rule). AWS's documented example key doesn't work as a test, because gitleaks allowlists it.

## 2. Design system
Tokens, dark mode, Dynamic Type, component catalog, snapshot tests. *(Phase 2)*

Verified 14 October 2026 with Xcode 26.6 (Nifty Outfit Nook, Phase 2a):
- **Keep colour values in one Swift file and test the asset catalog against it.** A `Palette.swift` with every token's light and dark hex lets tests compute WCAG contrast without UIKit. Two tests keep the catalog honest: one decodes each `.colorset/Contents.json` (found through `#filePath`, which simulator tests can read, on CI too) and compares it with the palette; the other resolves the compiled colour through SwiftUI, `Color(name, bundle: .module).resolve(in: env)` with `env.colorScheme` set to `.light` and `.dark`, and compares `linearRed`, `linearGreen`, `linearBlue` and `opacity` with the palette after converting to linear sRGB (tolerance 0.004). Change one channel in a colour set to prove both fail.
- **Xcode generates asset symbols for a package's asset catalog too.** A colour set named `background` gives the module a `ColorResource.background`, so `Color(.background)` becomes ambiguous if your own token enum has a `background` case. Give your initializer a label (`Color(token: .background)`).
- **Main-actor default isolation reaches extensions on SwiftUI types.** With `.defaultIsolation(MainActor.self)`, a `Color` initializer or `static let` added in an extension is main-actor isolated, and a `nonisolated` token struct can't call it. Mark those members `nonisolated`. `Color(_:bundle: .module)` itself is fine to call from them.
- **Check contrast on what's actually under a see-through tint.** Blend the tint over each opaque colour it sits on (both ends of a gradient, the floor) before measuring, and list every pairing the design relies on as data, so the test covers new pairings by adding a line.
- **A shadow that falls only below needs more than `.shadow`.** SwiftUI's shadow has no spread, so CSS like `0 10px 16px -12px` becomes a halo all round. Draw it as a background: the same shape inset by the spread, offset down, blurred by half the CSS blur, and masked with the shape punched out (`ZStack { Rectangle().padding(-n); shape.blendMode(.destinationOut) }.compositingGroup()`) so a see-through fill on top stays clean. It doesn't change layout.
- **Map text roles to Dynamic Type styles and test the default sizes.** `UIFont.preferredFont(forTextStyle:compatibleWith:)` at `.large` gives each style's default size, so a test can hold every role within a couple of points of the mockup. The smallest styles don't shrink below 11 pt at `.extraSmall`, so test growth upward only.
- **System font designs need no licence check.** `.rounded` (SF Pro Rounded) and `.serif` (New York) come with `Font.system(_:design:weight:)` and scale with Dynamic Type. Nothing is bundled.

Verified 14 October 2026 with Xcode 26.6 and swift-snapshot-testing 1.19.6 (Nifty Outfit Nook, Phase 2b):
- **Draw SwiftUI snapshots with `ImageRenderer`, not the library's view strategy.** In a package test target (no host app) `.image(layout:traits:)` renders through `layer.render(in:)`, which drops SwiftUI `.blur`, so soft shadows vanished, and `.sizeThatFits` measured before the AX5 trait applied, so tall layouts were cut off and text truncated. `ImageRenderer` with `proposedSize = ProposedViewSize(width: w, height: nil)`, `scale = 2` and `.environment(\.colorScheme)`, `.dynamicTypeSize`, `.locale` set on the view draws blur and lays out at the real text size. Hand the `UIImage` to `assertSnapshot(of:as: .image(precision:perceptualPrecision:scale:))`. `drawHierarchy` needs a host app.
- **`ImageRenderer` can't draw UIKit-backed views.** `TextField`, `ScrollView`, `ProgressView` and `Toggle` come out as a yellow box with a no-entry sign. Give components an environment flag that swaps in plain SwiftUI that looks the same (a `Text` for the field, a stack for the scroll view), set it only in snapshot tests, and cover the real controls with UI tests. A custom SwiftUI loading indicator avoids the problem for spinners.
- **A sideways scroll view's stand-in must not widen its parent.** A `.fixedSize()` row inside `.frame(maxWidth: .infinity, alignment: .leading)` still reports its full width and pushes the whole snapshot off-centre. A tiny `Layout` that reports the proposed width and places the child at the leading edge fixes it.
- **Snapshots at AX5 find layout bugs fast.** The first recording showed words broken mid-word in buttons, chips and rows. Fixes that held: `ViewThatFits` (icon beside a one-line `fixedSize` title, else icon above a wrapping title), rows that move the icon above the title at accessibility sizes, pairs of buttons that stack at accessibility sizes, and chip bars that wrap instead of scrolling.
- **Same runtime, same pixels.** The iOS 26.5 simulator runtime (build 23F77) on an Apple-silicon Mac and on GitHub's `macos-26` runner produced matching images with a tolerance of `precision: 0.995, perceptualPrecision: 0.98`, and re-recording locally gave byte-identical PNGs. Pin the runtime in the simulator-picking script rather than taking the newest, and add a test that fails with a clear message on any other runtime.
- **Record and artifacts through `xcodebuild`.** Environment variables prefixed `TEST_RUNNER_` reach the test process on the simulator: `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all` re-records, `TEST_RUNNER_SNAPSHOT_ARTIFACTS=<dir>` collects failed images for a CI upload. Don't put `.snapshots(record:)` on the suite, or it overrides the environment variable.
- **A test-only package still resolves its whole manifest.** swift-snapshot-testing pins swift-custom-dump, xctest-dynamic-overlay and swift-syntax in `Package.resolved` even though the `SnapshotTesting` product builds none of them. List them in the dependency note. With a local package added to the project as a folder, Xcode writes its own `Package.resolved` under `*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`, separate from the package's; commit both, check they agree, and build with `-onlyUsePackageVersionsFromResolvedFile`.
- **Prove debug and test code stay out of Release.** After a Release build, `nm` on the app binary for the catalog's and the snapshot library's type names (and `strings` for the launch argument) returns nothing; the same check on the Debug build's `.debug.dylib` finds hundreds of catalog symbols, which shows the check works. Run it in CI.
- **A colour that's close to the background disappears as a fill.** The soft accent (`#EFE6DB`) on the wall (`#F4EEE6`) passed every contrast test as a text background but made icon circles and pressed states invisible. Look at fills on the simulator, not only the numbers.

Verified 14 October 2026 with Xcode 26.6 on the iOS 26.5 simulator (Nifty Outfit Nook, Phase 4, an illustrated Home screen):
- **Multi-colour vector art that follows dark mode: two SVGs per image set.** Template rendering only tints one colour, so for a drawing with dozens of colours give each `.imageset` an Any SVG and a Dark SVG (`"appearances": [{"appearance": "luminosity", "value": "dark"}]`) with `"preserves-vector-representation": true`. Generate both from one source with a script that maps every colour, so the light and dark files only differ in colours, and test that (same text once the hex values are blanked, each dark colour equal to the rule applied to the light one). SVGs with clip paths, linear and radial gradients and `opacity` rendered correctly from a Swift package's asset catalog on the simulator in both appearances, and through `ImageRenderer` in light. We replaced `<use href>` with copies before shipping rather than relying on the system renderer to resolve references.
- **Lay out an illustrated scene from the mockup's own coordinates.** Keep every rect from the design's fixed stage (here 390 x 844) as data, and compute one scale and origin per screen: fit the part of the scene that must show between the bars, never wider than the screen, and never below the scale that keeps the tightest pair of controls 44 pt apart. Grow each tap area to 44 x 44 around its object. Pure layout code makes it testable without UI: for each phone size, check every target is 44 pt or more, no two targets overlap, and none sits under the bars. Where the phone is too short (iPhone SE), let the scene scroll a little rather than shrink targets.
- **Bar heights in iOS 26** from `GeometryReader`'s `safeAreaInsets` inside `NavigationStack` in a `TabView`, inline title: 116 pt top and 83 pt bottom on iPhone 17 and 17 Pro Max, 74 and 83 on iPhone SE (3rd generation). Put the scene in a `ScrollView` with `.ignoresSafeArea()` and place content using those insets; the wall and floor then run under both bars, and `scrollDisabled` keeps it still when it fits.
- **A shrinking `Text` next to a `Spacer` gets squeezed and truncates instead of shrinking.** "Closet" with `minimumScaleFactor(0.5)` in an `HStack` with icons and a `Spacer(minLength: 0)` came out as "Clo…" at a slightly smaller width; `layoutPriority(1)` didn't fix it. `ViewThatFits(in: .horizontal)` over full, shorter and text-only versions, each with a `.fixedSize()` title, did.
- **Fixed-size labels on art need a Dynamic Type cap until the large-text layout exists.** At AX5 the icons and two-line plates overflowed their drawn spaces. `.dynamicTypeSize(...DynamicTypeSize.xxxLarge)` on the scene kept everything inside; the accessibility sizes then need their own layout rather than a bigger scene.
- **Small gotchas.** A command-line `xcodebuild` doesn't add new strings to a package's String Catalog, so add the entries yourself, with plural variations for counts ("1 piece", "17 pieces"), and test a count of one. swift-snapshot-testing writes `__Snapshots__` next to the test file, so a test in `Tests/X/Home/` needs `exclude: ["Home/__Snapshots__"]`. A test target can load the module's assets with `UIImage(named:in: .module, compatibleWith:)` through `@testable import`.

## 3. Models and mock data
Protocol boundaries, fixture sets (empty, typical, huge, failing), previews. *(Phase 3)*

Verified 14 October 2026 with Xcode 26.6 and Swift 6.3 (Nifty Outfit Nook, Phase 3):
- **Split the package three ways.** Models holds value types, rules as pure functions and service protocols, with Foundation only and no user-facing strings (enum cases are words; screens localize them). Fixtures holds actor stores and sample data and depends on Models. Features depends on Models only, and the app target is the one place that builds concrete services. A `NookServices` struct of `any Protocol` values goes into the SwiftUI environment with `@Entry var services: NookServices?`; that compiles cleanly in a module with `defaultIsolation(MainActor.self)`.
- **Stores keep data; rules decide.** Stores return everything they hold and the screens filter with pure functions (eligibility, repeat window, favourites, filters). Every rule takes `now` and a `Calendar` as parameters, tests pin a UTC Gregorian calendar and a fixed date, and fixture dates are generated relative to `now` so the running app reads naturally.
- **Typed throws work across async protocols and actors.** `func garments() async throws(StoreError) -> [Garment]` in a protocol, implemented by an actor, compiles under complete strict concurrency. `Task.sleep` throws an untyped error, so wrap it in `do`/`catch` and throw your own `.cancelled`. Keep "couldn't finish" as a thrown error and "the data doesn't allow it" as an outcome case, so a network failure can never be shown as a small closet.
- **One launch argument for set and behaviour.** `-fixtures demo:offline` (also `slow`, `stylist-fails`, `stylist-partial`, `stores-fail`) gives UI tests every loading, error and offline state without extra flags. Unknown parts fall back to the defaults.
- **A generated large data set should own its arithmetic.** A SplitMix64 generator with its own `int(in:)` (modulo) and `unit()` makes the 2,400-garment closet identical on every run without relying on how the standard library picks random integers. Make dates per record unique by drawing day offsets into a `Set`, and never generate a wear date before the record was added (a test checks both).
- **Performance tests: measure serially, bound loosely.** Swift Testing runs tests in parallel, so record numbers with `-parallel-testing-enabled NO`. In Debug on the simulator, generating 2,400 garments took 36 ms, five filters 35 ms and one mock styling 41 ms; the tests allow 1 s or 500 ms, so they catch big regressions without flaking on CI.
- **Swift Testing gotcha:** `#expect(items.contains(where: \.isArchived))` failed to compile inside the macro expansion ("call can throw, but it is not marked with 'try'"). Use a closure, `#expect(items.contains { $0.isArchived })`.
- **UI test gotchas.** A text with its own `accessibilityIdentifier` inside a `ContentUnavailableView` that also had an identifier wasn't found by that identifier; matching the label (`staticTexts["17 pieces in the sample closet"]`, or a `label ENDSWITH` predicate) worked. Numbers in labels are formatted for the locale ("2,117"), so strip non-digits before comparing.
- **Watch CI time as UI tests grow.** Locally, two extra UI tests with five app launches added about 45 seconds. On `macos-26` the `build-and-test` job then took 8.5 to 13.5 minutes across three runs, against 5 to 7 before. Keep launches few and cover data paths in package tests.

## 4. Testing strategy
What gets unit, integration, UI and snapshot tests, and keeping the suite fast. *(All phases)*

## 5. Accessibility and iPad
Checks that run on every screen. *(All UI phases)*

## 6. Privacy and security baseline
Data classification, data map, threat model, account inventory, privacy manifest, permissions, legal review. *(Phases 0c, 1b, 19, 24c, 25, 32b, 35a)*

## 7. Local data, backups and recovery
Persistence choice, migrations, export and restore, iCloud. *(Phases 20–21)*

## 8. Photos and image handling
Intake, permissions, cutouts, storage and caching. *(Phases 8, 22)*

## 9. Backend and gateway
Choosing a stack, environments, identity, request validation. *(Phases 23–24)*

## 10. Secrets and credentials
Where keys live, rotation, least privilege. *(Phase 25)*

## 11. Rate limits and cost protection
Usage ledger, reservations, kill switch, abuse tests. *(Phase 24b)*

## 12. Networking and resilience
Timeouts, retries, offline mode, error handling. *(Phase 26)*

## 13. AI features
Server-side model config, typed responses, token budgets, caching, on-device models. *(Phases 27–28)*

## 14. Subscriptions, credits and one-time purchases
StoreKit 2, server verification, credit ledger, refunds, Apple's wording rules. *(Phase 30)*

## 15. Monitoring and analytics
Crash reporting, cost alerts, opt-in analytics. *(Phase 31)*

## 16. Load and scale testing
*(Phase 32)*

## 17. App Store submission
Review guidelines checklist, privacy labels, review notes, TestFlight. *(Phases 18, 35)*
