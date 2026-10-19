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
| App Store Connect user for Lily | Jose (invites and manages it) | Lily's access as an internal TestFlight tester. Marketing role, limited to this app. | Her own Apple Account's two-factor authentication. Lily to confirm. | Lily's own Apple Account recovery; nothing for this repo to hold | Phase 18, step 4 in the app repo's `docs/testflight.md`. Smallest role that lets her test. Remove it or narrow it when she no longer needs it. |
| Internal TestFlight group | Jose | Gets TestFlight builds to internal testers (Lily) | Not an account; each member's own Apple Account applies | Not applicable | Phase 18. Internal testers must be App Store Connect users, so there's no public link. Add members only through the user row above. |
| Cloudflare | Jose | Cloudflare Pages for the website (https://niftyoutfitnook.pages.dev/), later privacy policy and support pages | Jose to confirm | Jose to confirm | Called out in the 13 October progress log entry. No custom domain yet, so no registrar account. Any API tokens should be scoped to Pages for this project only. |
| here.now | Jose | Hosts the mockup review site where Lily leaves notes | Jose to confirm | Jose to confirm | Holds the owner key that can change or delete notes. Retire the site, or leave it read-only, once the review work is done. |
| Email account that receives the accounts above | Jose | Password resets and alerts for every account here | Jose to confirm | Jose to confirm | The standard lists email explicitly. Whoever controls this inbox can reset most other accounts, so it needs the strongest protection. |
| Project email | Jose | Public support contact for the app (App Store Connect and the website support page). Not used for commits. | Lives in Jose's iCloud+ account (iCloud two-factor, Jose to confirm) | Jose to confirm | Created October 2026 on Jose's own domain with iCloud+ custom email; MX, SPF and DKIM checked 18 October 2026, DMARC still to add (STACK.md). The domain's registrar and its DNS host also control this inbox, so they get two-factor too. Commits use GitHub's no-reply address instead. |
| Password manager | Jose | Stores every password and API key | Jose to confirm | Jose to confirm | Standard section 2: no shared passwords, recovery codes offline. |
| Convex (planned, confirmed in Phase 23b) | Jose | Backend: HTTP actions as the gateway, usage ledger, consent records, support and feedback, server-side AI keys as environment variables | Placeholder | Placeholder | STACK.md. Separate dev and production deployments, each with its own secrets. No RLS: per-function checks and cross-user tests (Phase 24c). Backups: free daily encrypted export (STACK.md). |
| Clerk (planned, confirmed in Phase 23b) | Jose (existing account) | Sign in with Apple and sessions for the app; `clerk-ios` in the app needs written dependency approval | Jose to confirm | Jose to confirm | STACK.md. One Clerk application per app. Holds her Apple ID and email, so it is a named processor in DATA_MAP.md and the privacy policy. |
| AI text provider (Phase 23 or 27a) | Jose | Cloud stylist, swaps, Ask stylist | Placeholder | Placeholder | Record retention, training-use policy and processing location here when chosen. Set provider-side hard spending caps and budget alerts. |
| AI image provider (Phase 33a, gated) | Jose | Try-on pictures with FLUX.3, decided 19 October 2026 | Placeholder | Placeholder | Either a BFL business agreement or FLUX hosted on Microsoft Azure (still to pick); one of them must be settled before Phase 33a. Only after PRD 9.2's gates pass. Same terms to record as the text provider. |
| WaveSpeed | Jose | Test and demo images only (AI-generated people, never real photos). Generated the sample wardrobe and try-on test images (PR #56) | Jose to confirm | Jose to confirm | Prepaid balance, so it can't overspend. Not a try-on provider for real photos since 19 October 2026. The API key lives only in Jose's local `.env` outside both repos; never in chat or a repo. |
| Black Forest Labs (FLUX.3) | Jose | Try-on pictures, Phase 33a | Jose to confirm | Jose to confirm | Test key only, in Jose's local `~/.config/nook/*.env` on his Mac, never in a repo or chat. BFL's standard API terms allow training on inputs, so business terms with no training are needed before any real photo goes there (to verify in 19b). Credits are prepaid. |
| OpenAI API | Jose | Backup image provider (gpt-image-2.5 Sunburst) | Jose to confirm | Jose to confirm | Test key only, in Jose's local `~/.config/nook/*.env` on his Mac. API data isn't used for training by default (to verify in 19b). Set a spend limit before real use. |
| Google Cloud project `nifty-outfit-nook-dev` | Jose | Vertex virtual try-on test only; dropped as a provider | Jose to confirm | Jose to confirm | $5 budget alert, using the AI Pro credit. Can be deleted. |
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
