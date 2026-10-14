# Account inventory

Phase 0c, started 13 October 2026. Required by [SECURITY_STANDARD.md](SECURITY_STANDARD.md) section 2: every account, key and webhook that can touch the app, with its owner, two-factor status and last rotation date. Goes with [DATA_MAP.md](DATA_MAP.md) and [THREAT_MODEL.md](THREAT_MODEL.md).

This repo is public, so this file holds no secrets, account emails, phone numbers, recovery codes or recovery details. "Recovery method" only says whether recovery is set up and stored offline; the details stay in Jose's password manager and offline storage.

Two-factor status is only marked confirmed when someone actually checked it. Everything else says **Jose to confirm**.

## Accounts

| Account | Owner | Purpose | Two-factor status | Recovery method | Notes |
|---|---|---|---|---|---|
| GitHub (`jsayram`) | Jose | Hosts the public `closet` planning repo and the public `nifty-outfit-nook` app repo; later the private backend repo; CI | Jose to confirm. Checked 13 October 2026 with `gh api user`: the `two_factor_authentication` field came back empty because the CLI token doesn't have the `user` scope, so it couldn't be read. | Jose to confirm (recovery codes offline) | Standard asks for passkeys or a hardware key where offered. Phase 1b turns on rulesets, signed commits and secret scanning. |
| Apple Account used for the Apple Developer Program | Jose | Paid membership (also used for Life Wrapped), certificates, identifiers (`com.jsayram.niftyoutfitnook`), WeatherKit, App Attest, Sign in with Apple | Jose to confirm | Jose to confirm | Apple requires two-factor authentication for developer accounts, but confirm it on this account rather than assume. |
| App Store Connect | Jose | App record, TestFlight, tester feedback and crash reports, offer codes, subscriptions, App Store Server API keys | Jose to confirm | Jose to confirm | Same Apple Account as the Developer Program unless Jose has set up separate users. Any team users get the smallest role they need. |
| Cloudflare | Jose | Cloudflare Pages for the website (https://niftyoutfitnook.pages.dev/), later privacy policy and support pages | Jose to confirm | Jose to confirm | Called out in the 13 October progress log entry. No custom domain yet, so no registrar account. Any API tokens should be scoped to Pages for this project only. |
| here.now | Jose | Hosts the mockup review site where Lily leaves notes | Jose to confirm | Jose to confirm | Holds the owner key that can change or delete notes. Retire the site, or leave it read-only, once the review work is done. |
| Email account that receives the accounts above | Jose | Password resets and alerts for every account here | Jose to confirm | Jose to confirm | The standard lists email explicitly. Whoever controls this inbox can reset most other accounts, so it needs the strongest protection. |
| Password manager | Jose | Stores every password and API key | Jose to confirm | Jose to confirm | Standard section 2: no shared passwords, recovery codes offline. |
| Backend provider (to be chosen in Phase 23) | Jose | Gateway, identity, usage ledger, consent records, support and feedback, secret store | Placeholder | Placeholder | Separate projects per environment (dev, staging, production). Add one row per project when chosen. |
| Database provider, if separate from the backend (Phase 23) | Jose | Durable ledger and records | Placeholder | Placeholder | Row Level Security with default deny if Postgres or Supabase. |
| AI text provider (Phase 23 or 27a) | Jose | Cloud stylist, swaps, Ask stylist | Placeholder | Placeholder | Record retention, training-use policy and processing location here when chosen. Set provider-side hard spending caps and budget alerts. |
| AI image provider (Phase 33, gated) | Jose | Try-on pictures | Placeholder | Placeholder | Only after PRD 9.2's gates pass. Same terms to record as the text provider. |
| Web search and ranking providers (Phase 34) | Jose | Find One | Placeholder | Placeholder | Only once the shopping direction is settled. |
| Crash reporting or analytics tool, if any (Phase 31) | Jose | Crash reports, opt-in analytics | Placeholder | Placeholder | Only if it earns its place; no third-party analytics SDK in the app without written approval. |
| Email sending service, if PRD 22.4 is enabled | Jose | Optional welcome and check-in emails | Placeholder | Placeholder | Not planned yet. |

## Keys, tokens and webhooks

None of these exist for the app yet. Each one gets a row when it is created, with its scope and a rotation date. One key per purpose; the value never goes in this file.

| Key or webhook | Account | Scope | Where it is stored | Created | Last rotated | Next rotation |
|---|---|---|---|---|---|---|
| GitHub CLI token on Jose's Mac | GitHub | `repo`, `workflow`, `read:org`, `gist` (seen 13 October 2026) | macOS keychain | Jose to confirm | Jose to confirm | Jose to set |
| here.now API key, if one exists | here.now | Publishing the review site | Jose's local tool config, never committed | Jose to confirm | Jose to confirm | Jose to set |
| Cloudflare API tokens, if any | Cloudflare | Pages deploys | Jose to confirm | Jose to confirm | Jose to confirm | Jose to set |
| App Store Connect API keys | App Store Connect | Per purpose (CI upload, App Store Server API) | Protected CI environment or backend secret store | Not created | | |
| App Store Server Notifications URL | App Store Connect to backend | Subscription and purchase events | Backend config | Not created (Phase 30c) | | |
| AI provider keys | AI providers | Per environment | Backend secret store | Not created (Phase 25a) | | |
| Backend service keys | Backend provider | Per environment | Backend secret store | Not created (Phase 25a) | | |
| Signing certificates | Apple Developer | Development and distribution | Jose's keychain; CI only if CI signs | Jose to confirm | | |

## What Jose needs to confirm

For each account above marked "Jose to confirm":

1. Two-factor authentication is on. Note the type (passkey, hardware key, authenticator app or SMS). SMS is the weakest; move off it where the service allows.
2. Recovery codes exist and are stored offline.
3. Update the "Two-factor status" column to the date checked and the type, without any contact details.

For GitHub, either confirm in Settings > Password and authentication, or refresh the CLI token with the `user` scope (`gh auth refresh -s user`) so `gh api user` can report it.
