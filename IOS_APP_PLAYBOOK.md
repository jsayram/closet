# iOS app playbook

A reusable guide for building iOS apps with paid AI features, subscriptions and one-time purchases. Started 7 October 2026 alongside [the Nifty Outfit Nook build plan](SWIFT_BUILD_PLAN.md).

Nifty Outfit Nook is the first project built with it, and building that app is also how this playbook gets written. The playbook is a deliverable in its own right, as important as the app. Its aim is apps that are reliable, compliant with Apple's rules, safe for users and the developer, and cheap to run.

The rule for this file: only write down what we actually did and checked. Each section fills in as the matching phase finishes. Lessons specific to Nifty Outfit Nook stay in the build plan's progress log.

## Required standards

- **[SECURITY_STANDARD.md](SECURITY_STANDARD.md)** is the required security baseline for every app built with this playbook. It isn't optional and isn't a later phase.

## 0. Repositories and branching
Separate repos for design and planning, the app, and the private backend. Git Flow in the app and backend repos (`main`, `develop`, `feature/*`, `release/*`, `hotfix/*`), with protected branches, required CI and no stacked feature branches. The decided model is in [SWIFT_BUILD_PLAN.md](SWIFT_BUILD_PLAN.md#repositories-and-branching); lessons go here once it's in use. *(Phase 1b)*

## 1. Project setup
Project generation, package layout, configurations, language mode, lint and format. *(Phase 0a, 1a)*

Verified 13 October 2026 with Xcode 26.6 (Nifty Outfit Nook, Phase 1a):
- **A hand-written project file works.** With `objectVersion = 77`, each source folder is one `PBXFileSystemSynchronizedRootGroup` listed in the target's `fileSystemSynchronizedGroups`, and the Sources and Resources build phases stay empty. Put build settings in xcconfig files (`baseConfigurationReference`) so the project file stays small. Check it with `xcodebuild -list` and a real build.
- **Add a local package as a folder reference, not an `XCLocalSwiftPackageReference`.** Use a `PBXFileReference` with `lastKnownFileType = wrapper` and `path = Packages/<Name>`, and product dependencies without a `package` field. With `XCLocalSwiftPackageReference`, Xcode built the package with `-suppress-warnings` (which clashes with warnings-as-errors) and silently skipped the package's test targets in the scheme and test plan.
- **Run package tests through a test plan.** Each package test target appears as `{"containerPath": "container:Packages/<Name>", "identifier": "<TestTarget>", "name": "<TestTarget>"}`. The app scheme's test action then runs the package tests and the UI tests together on a simulator, which matters when the package is iOS-only and `swift test` can't run on the Mac.
- **Warnings as errors:** set `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` in the project xcconfig and `.treatAllWarnings(as: .error)` (Swift 6.2 tools) in `Package.swift`. Don't pass it on the `xcodebuild` command line, because that reaches package targets too and can clash with `-suppress-warnings`. Prove it works by adding a warning on purpose.
- **Data Protection** goes in the entitlements file as `com.apple.developer.default-data-protection = NSFileProtectionComplete`. A simulator build shows it in the `*-Simulated.xcent` file under DerivedData, not in `codesign -d --entitlements`.
- With `defaultIsolation(MainActor.self)` on a module, its test target also needs `@MainActor` on tests that touch that module's types, or `#expect` fails to compile.

## 2. Design system
Tokens, dark mode, Dynamic Type, component catalog, snapshot tests. *(Phase 2)*

## 3. Models and mock data
Protocol boundaries, fixture sets (empty, typical, huge, failing), previews. *(Phase 3)*

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
