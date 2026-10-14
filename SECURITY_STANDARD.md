# Security standard for iOS apps with sensitive data and paid AI

Adopted 7 October 2026. This is the required security baseline for Nifty Outfit Nook and for any future app that handles personal data, paid AI, subscriptions or credits. It's reusable on purpose: nothing here is specific to one app.

**Every item is required unless Jose approves an exception in writing, with the reason and a review date, in the project's progress log.** "We'll add it later" doesn't count as an exception.

The outside standards we measure against:
- **App:** OWASP MASVS (Mobile Application Security Verification Standard), at L2 plus the resilience controls (MASVS-RESILIENCE), checked with the OWASP MASTG test guide.
- **Backend and API:** OWASP ASVS at level 2, and the OWASP API Security Top 10.
- **Apple:** the current App Store Review Guidelines (especially section 5.1, privacy, and section 3, payments) and Apple's platform security guidance.

Vendor features and prices change. Each control is re-checked against current documentation when its phase begins.

## 1. Data classification

Every piece of data gets a tier before any code stores or sends it.

| Tier | Examples | Rules |
|---|---|---|
| **Sensitive** | Body measurements and weight, photos of the person, try-on pictures, health or disability details, private notes, precise location | On-device by default. Encrypted at rest with the strongest file protection. Never in logs, analytics, crash reports, URLs or push payloads. Leaves the device only for a feature the user explicitly enabled, with consent, and only the minimum needed. |
| **Personal** | Name, email, garment photos, wardrobe, saved looks, purchase history | Encrypted at rest. Never in logs or analytics. Sent to the server only when a feature needs it. |
| **Account and billing** | User ID, entitlements, credit balances, transaction IDs | Server-authoritative. Never trusted from the client. |
| **Secrets** | API keys, service keys, signing certificates, webhook secrets | Never in the app, the repo, logs or chat. Server-side secret store only. |
| **Public** | Static content and catalog data | No special handling. |

The data map (what, where, who can see it, how long it's kept, how it's deleted) is written before the first real data is stored and updated whenever a feature changes it.

## 2. Accounts and access (people)

- Two-factor authentication on every account that can touch the app: GitHub, Apple Developer, App Store Connect, the backend host, Supabase or the database, AI providers, the domain registrar and email. Passkeys or hardware keys where offered.
- Use a password manager. No shared passwords.
- Least privilege. App Store Connect API keys and service accounts get only the roles they need, one key per purpose, with a rotation date recorded.
- An inventory of every account, key and webhook, with its owner and last rotation date.
- Recovery codes stored offline.

## 3. Repository and supply chain

- **Visibility.** Backend code, prompts, fit and styling rules, and infrastructure config live in a private repo. The client app repo may be public only if everything in this section is on and no business logic lives in it.
- **Branch protection (rulesets) on `main` and `develop`.** PRs required, CI required to pass, no force pushes, no deletion, linear history, and administrators included.
- **Signed commits** required on protected branches.
- **GitHub secret scanning with push protection** on every repo.
- **gitleaks** as a pre-commit hook and as a CI step that scans the full history.
- **Dependencies.** Each new dependency is approved in writing first: who maintains it, how widely it's used, its license, and its permissions. Versions pinned exactly, and lockfiles (`Package.resolved`) committed. Dependabot alerts and security updates on. Prefer Apple frameworks over third-party code.
- **CI hardening.** Third-party GitHub Actions pinned to a full commit SHA. `GITHUB_TOKEN` read-only by default. Approval required before workflows run for outside contributors' pull requests. Secrets only in protected deployment environments that need manual approval for production. No secrets ever printed to logs.
- **CODEOWNERS** on security-sensitive paths (auth, payments, crypto, storage, CI config, entitlements).
- **PR template with a security checklist,** covering this standard's sections touched by the change.
- **License.** No open-source license unless chosen on purpose. A README notice that all rights are reserved.

## 4. The iOS app

**Storage**
- Sensitive and personal files use Data Protection class `complete` where the app doesn't need them in the background. Anything that does gets an explicit, documented exception.
- Tokens and keys in the Keychain with the `WhenUnlockedThisDeviceOnly` accessibility class (or stricter). Never in `UserDefaults`, plist files or the app bundle.
- Caches and temporary files hold no sensitive data, or are protected and cleared.
- Exports and backups that leave the app are encrypted, and the user is told where they go.

**Network**
- App Transport Security with no exceptions. TLS only.
- Certificate or public-key pinning to our own API is evaluated in the backend phase. If adopted, it has a tested rotation plan so a certificate change can't lock users out.
- Every request has a timeout, cancellation and bounded retries.

**Privacy on the device**
- Use the system photo picker (`PHPickerViewController`/PhotosUI), so the app never needs full photo-library access.
- Strip location and other metadata (EXIF) from photos before anything leaves the device.
- Hide sensitive screens in the app switcher snapshot (measurements, personal photos, try-on pictures).
- No sensitive data on the general pasteboard without the user asking for it.
- Logging uses `os.Logger` with privacy redaction. Release builds log no personal data.
- Ask for each permission only when its feature is first used, with a clear reason string.
- No tracking, so App Tracking Transparency is not needed. If that ever changes, it needs a new review.

**Integrity and tampering**
- App Attest (DeviceCheck) for every request that can cost money or touch account data. The server rejects requests that fail attestation.
- The server is the authority for entitlements, credits, limits and prices. Nothing the client says about payment or quota is trusted.
- No secrets in the binary. Assume the app will be decompiled and its traffic inspected.
- Jailbreak detection only as a soft signal. It is never relied on as protection.

## 5. Backend and API

- **Identity.** Sign in with Apple where an account is needed. Short-lived access tokens, refresh token rotation, revocation on sign-out and account deletion.
- **Authorization on every request.** If using Supabase or Postgres, Row Level Security is on for every table with default deny, and a test proves one user can't read another's data. The service role key exists only on the server.
- **Input validation.** Every request validated against a typed schema with size limits. Unknown fields rejected.
- **Separate environments.** Dev, staging and production each have their own project, database, keys and provider accounts. Production data never goes into dev.
- **Encryption.** At rest and in transit. Database backups encrypted.
- **Webhooks.** App Store Server Notifications have their signed payloads (JWS) verified, and every handler is idempotent.
- **Audit log** for security events: sign-ins, entitlement changes, credit changes, admin actions, failed attestation. No personal data in it.
- **Least-privilege database roles.** No admin credentials in application code.

## 6. Cost and abuse protection

- Atomic usage ledger with cost reserved before any paid call (AI, image generation, search).
- Per-user, per-device and global rate limits and concurrency limits.
- Hard spending caps set at each provider, plus budget alerts at 50, 80 and 100 percent.
- A server-side kill switch for each paid feature, testable without an app update.
- Credits and purchases are idempotent: a retried request or a replayed webhook can't grant or spend twice.
- Abuse tests in CI: replay, bad tokens, flooding, oversized input, and cross-user access.

## 7. AI-specific safety

- Provider keys only on the server. Models and settings chosen by server configuration.
- Send the minimum. No identity, contact details or unneeded sensitive data in prompts. Sensitive data goes out only when the user enabled that feature.
- Choose providers whose terms say they don't train on our data, with the shortest retention available. Recorded per provider, and re-checked on any change.
- Treat user text, garment notes and web content as data, never instructions. Stylist calls don't get tools that can take actions.
- Every model response is validated against the typed schema and product rules before the app sees it.
- Image features have content moderation on inputs and outputs, and never accept photos of people other than the user without consent.
- Prompts and fit rules stay on the server and out of the client repo.

## 8. Payments and entitlements

- StoreKit 2 only for digital goods and features, following Apple's rules (section 3.1).
- The server verifies transactions and keeps the entitlement and credit state. The client only displays it.
- Refunds, revocations, expiry and family sharing are handled and tested.
- Subscription wording, price display, trial terms and restore purchases follow Apple's requirements.

## 9. Privacy and legal

- Privacy manifest (`PrivacyInfo.xcprivacy`) and App Store privacy labels that match what the app actually does, including third-party SDKs.
- A privacy policy in plain language, linked in the app and on the store page.
- In-app account deletion that actually deletes server-side data (App Store Review Guideline 5.1.1(v)), with a stated retention for anything kept for legal reasons.
- Data export for the user.
- **Legal review before launch.** Body measurements, weight and disability details may count as health or sensitive data under US state laws (for example Washington's My Health My Data Act) and under GDPR if the app expands. Have a lawyer confirm what applies. This document doesn't replace legal advice.
- Age rating set honestly; check children's privacy rules if minors could use the app.

## 10. Backups, recovery and incidents

- Encrypted, automated backups of server data, with a restore test on a schedule, not only at setup.
- On-device data has a tested export and restore path, and migrations can't destroy data (see the project's persistence rules).
- **Incident response plan** written before launch: how to detect, who acts, how to rotate every key, how to turn off paid features, how and when to tell users, and what the law requires.
- Secrets rotated on a schedule and immediately after any suspected leak. Deleting a leaked secret from git does not make it safe.

## 11. Testing and review gates

- Security tests run in CI alongside unit and UI tests: authorization, attestation, rate limits, idempotency, input validation and secret scanning.
- **Security checklist on every PR** that touches data, network, auth, payments, storage or CI.
- **Security review gate** before every `develop` to `main` promotion: this standard is walked through for everything changed since the last promotion, and findings are fixed or written up as approved exceptions.
- MASVS and ASVS checklists completed before the first App Store submission.
- **Independent security review or penetration test** of the app and backend before public launch, and after any major change to auth, payments or data handling.
- Dependency and container vulnerability scans on every build.

## What this does not cover

No set of controls makes an app impossible to copy or attack. The goal is that a leak, a cloned app or an abusive user can't reach user data, can't cost real money, and gets noticed quickly.
