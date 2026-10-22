# Security test report, Phase 32b

22 October 2026. Tested by an agent (Opus 5.5), with a Sonnet 5.5 helper for the first pass over the app source. Everything ran locally: the backend's tests on `convex-test` and on a real local Convex backend (anonymous mode, a fake Clerk issuer on 127.0.0.1, fake providers), the app's tests on the "32b iPhone 12" simulator (iOS 26.5), and source review of both repos. No cloud service, provider or third party was called. Nothing cost money.

Measured against [SECURITY_STANDARD.md](SECURITY_STANDARD.md), the risks and flows in [THREAT_MODEL.md](THREAT_MODEL.md) and the data in [DATA_MAP.md](DATA_MAP.md).

## Summary

No critical, high or medium findings. Eleven low findings: seven are fixed (backend local commit 33b5b61; app jsayram/nifty-outfit-nook#100, merged into `develop` as 1b895cc), one is a platform limit kept as a residual risk with a tripwire test, and three need a decision from Jose. Update, 22 October 2026: Jose said yes to L9 and L10, and both are now fixed (see the table and "Decisions for Jose"), so nine are fixed and two decisions remain (L11, L8). The controls the earlier phases claim held up under the attacks below, including forged tokens, cross-account requests, parallel spends, forged App Store chains, crafted images and crafted backups.

## Findings, by severity

Severity is judged for this app as it stands: one main user now, public users later, paid AI behind App Attest.

### Critical, high, medium

None.

### Low

| # | Where | Finding | Evidence | Status |
|---|---|---|---|---|
| L1 | Backend, request schemas | "Unknown fields rejected" could be bypassed by a field named after an `Object.prototype` member (`constructor`, `toString`, `__proto__`...). The validator used `key in properties`, which also finds inherited names, so the field passed unchecked. The handlers read only named fields, so nothing reached a table, but the control didn't do what the standard says. | Before the fix, `POST /v1/session` with `{"__proto__":{"admin":true},...}` created an account. `tests/attacks.test.ts` tries six such names on each of the 9 request schemas (54 cases) and in a nested closet piece. | Fixed: own-property checks (`Object.hasOwn`) in `convex/gateway/contract.ts`. |
| L2 | Backend, stylist prompt and output | The text cleaner removed zero-width and direction characters but not the word joiner range (U+2060 to U+2064) or U+FEFF, so invisible characters from her names could reach the prompt and the model's text could reach the app. | The prompt test plants them in names, notes and questions and checks the built prompt. | Fixed: both cleaners in `convex/stylist/prompt.ts` and `validate.ts`. |
| L3 | Backend, stylist output | Output validation didn't look for links or addresses. A steered model (prompt injection through her own words now, web text later in Find One) could show "buy it at https://..." or an email address in a why line, an idea's name or an Ask stylist answer. An idea's colours were any strings, so free text could ride along as a "colour". | `tests/attacks.test.ts`, "steered output is dropped". | Fixed: a why line with a link or email address is dropped like body talk; an answer with one didn't finish (not shown, not counted); an idea named with one is dropped; idea colours must be the schema's colour words. |
| L4 | Backend, image cleaner (support screenshots and try-on photos) | The JPEG cleaner kept every segment it didn't recognise, so reserved markers (0x02 to 0xBF, 0xC8) could carry a hidden payload past the metadata strip. | A crafted JPEG with planted text in four reserved segments plus a ZIP after the end marker: before the fix the text survived. | Fixed: only the segments a decoder needs are kept (`convex/ticketing/image.ts`). |
| L5 | Backend, test-only modes | `NOOK_APP_ATTEST_MODE=mock` (an attestation anyone can make) and `NOOK_APPSTORE_MODE=test` (a root from an environment variable) were honoured on a production deployment if set there by mistake. App Attest would then stop anything. | `tests/attacks.test.ts`, last test. | Fixed: both fall back to off when `NOOK_ENVIRONMENT=production`, so paid work and purchase checks fail closed. |
| L6 | App, backup restore | The restore summed the manifest's file sizes with plain `+`. A crafted but correctly encrypted backup with sizes near `Int64.max` made the sum overflow, and Swift traps, so the app quit during the check. Someone would have to get her to restore their file with their passphrase. | New `CraftedArchiveTests.manifestSizesThatOverflowAreRefused`. | Fixed: overflow-checked sums; such a copy is "damaged" and nothing is staged. |
| L7 | App, `scripts/check-release.sh` | The Release check didn't cover the debug switches added since Phase 20a (`-gateway-lab`, `-limits-lab`, `-diagnostics-lab`, `-fake-signed-in`, `-cloud-stylist`, `-seed-photo-closet` and others) or the lab screens' symbols. All of them are inside `#if DEBUG` today (checked one by one), but nothing would catch a slip. | Source review. | Fixed: added to the check, which CI runs on every archive. |
| L8 | Backend, sign-in (Convex platform) | Convex doesn't check a JWT's `nbf`: a correctly signed token that isn't valid for another day was accepted. Only Clerk can sign one, and Clerk sets `nbf` in the past, so there's no path to exploit it today. | Local-backend test with `nbfIn: 86400`. Every other forgery was refused (below). | Residual risk. A tripwire test fails if Convex starts checking `nbf`. |
| L9 | App, Release builds | A Release build without `CLERK_PUBLISHABLE_KEY` and `NOOK_API_BASE_URL` quietly runs on the in-process fake sign-in and fake backend (`AppGateway.fake` has no `#if DEBUG`). Nothing trusts the fake, and no Release screen signs in to it, so a pack bought in such a build stays unfinished rather than being lost. But a misconfigured build should fail closed, not pretend. | `NiftyOutfitNook/AppGateway.swift`. | Fixed 22 October 2026 (decision 1, yes): the fakes are compiled only into Debug, and a Release build without the settings gets the unavailable services, with try-on and Styling access saying "Not available right now". `scripts/check-release.sh` fails if the Release binary holds the fakes (checked on a real Release build and, as a negative test, on a Debug one). App `jsayram/nifty-outfit-nook#101`. |
| L10 | Backend, try-on input | `POST /v1/try-on` accepts photos up to 8,192 px a side and 40 megapixels (the support screenshot limits), while the app sends at most 1,280 px for her photo and 768 px per garment. BFL prices by input megapixels, so a modified client on an attested device could make a picture cost more than its US$0.10 reservation. Settlement records BFL's real cost and prepaid credits cap the total. | `convex/tryon/prepare.ts`, contract `limits.tryOn`. | Fixed 22 October 2026 (decision 2, yes): the backend now refuses a photo past 2,048 px a side for hers and 1,024 px for a piece (`invalid_request`, before admission, nothing counted). Contract `limits.tryOn`, tests and the app's contract copy updated (backend local commit ff1efde; app #101). |
| L11 | App, backup passphrase | "Use mine" accepts any 12 characters, and Apple's scrypt profile is fixed and fast (about 50 ms on a Mac, decision 0004). A short, common passphrase on a copy that leaves the phone is guessable offline. The generated passphrase (about 120 bits) is fine. | `Backups.swift`, decision 0004. | Open: decision 3. |

### Informational and carried over

- A JPEG's compressed picture data can still carry arbitrary bytes; only re-encoding would remove them, and the backend doesn't decode images on purpose. Nothing reads those bytes.
- A why line can still be steered into odd but plain text. It is checked for body talk, links and length, and Report Styling Problem (not built) is the backstop.
- Known gaps from earlier phases, unchanged: no rate limit on the App Store notification endpoint beyond Convex's own, no OCSP check of Apple's certificates (30c), Clerk's Keychain class `AfterFirstUnlockThisDeviceOnly` (D11, confirmed again: `clerk-ios` 1.6.1 has no option for it), Apple's App Attest check not built (paid work stays off in `apple` mode), Convex log retention unverified (31).
- When the support email hook is built, her reply address must not go into a mail header unescaped. The contract's pattern already refuses spaces and line breaks.

## What was tested

### Backend (private repo, local only)

New file `tests/attacks.test.ts` (10 tests, `convex-test`) and four new tests at the end of `tests/local-backend.test.ts` (real local Convex runtime). The fake Clerk issuer gained attack modes for the token tests.

| Area | What was tried | Result |
|---|---|---|
| Sign-in tokens | `alg: none`; HS256 signed with the published RSA public key (key confusion); an unknown `kid`; a token carrying its own key (`jwk`) and a `jku` to an attacker's key set; no `exp`; `nbf` a day ahead; `bearer` in lower case, a double space, `Basic`, two tokens, a NUL; the token in the query string or a cookie. Earlier phases already cover expired, wrong audience, wrong issuer and wrong signature. | All refused with 401 except `nbf` (L8). The attacker's key set was never fetched. |
| Cross-account access | `tests/authorization.test.ts` (24c) already runs a second account against every contract endpoint and fails when a new endpoint has no case. Re-read: every handler takes the account from the verified token; App Attest keys, idempotency keys, stylist results and try-on staging are looked up per account. | No gap found. |
| The paid gate | The same Idempotency-Key and body sent six times at once from six registered devices of one account; six accounts at once against a provider ceiling with room for exactly two pictures (the stand-in never answers, so nothing is freed). Earlier phases cover replays, key reuse across accounts, bursts, allowances, kill switches and ceilings. | Ran and counted once. Exactly two admitted, four paused, the counter never past the ceiling. |
| App Store JWS | The intermediate used as the leaf; the root used as the intermediate; four certificates; a DER signature in place of JOSE's; a genuine notification wrapping a transaction for another bundle or the Production environment. 30c covers forged chains, a swapped root, tampering, `alg: none`, missing markers, expiry, and wrong bundle, app or environment. | All refused. |
| Input limits | 20,000 levels of nested arrays and 10,000 of objects inside 64 KiB; seven wrong or missing content types; non-UTF-8 bytes, a byte order mark, NUL padding; 70 KB with an honest and with a lying `Content-Length`; duplicate keys; the `Object.prototype` names (L1). | Clean 400, 413 or 415, never a 500. L1 fixed. |
| Prompt injection | Names, other names, colour notes, an occasion note, a question and earlier turns carrying `</closet>`, `<request>`, fullwidth brackets, direction overrides, zero-width and word-joiner characters, line and paragraph separators, and JSON that tries to add a system message. | One of each block tag, one `Operation:` line, every line the server's own wording, no invisible characters, no tools. L2 and L3 fixed. |
| Support endpoint | Reserved JPEG segments and a ZIP after the end (a polyglot); a PNG with HTML after `IEND`; a PNG sent as a JPEG; GIF and SVG text sent as images; a PNG header with nothing behind it. 24d covers EXIF, XMP, IPTC, text chunks, floods, daily caps and other accounts' tickets. | Payloads gone or the file refused. L4 fixed. |
| Log redaction | One run plants a unique word in a token's subject, bad tokens, a stray header, broken JSON, unknown field names, a content type, a deletion ID, a signed transaction, a notification, a support note and reply address, closet names, an occasion note and request fields, then reads everything the local backend printed. | The word and the token never appear. Only the route, status and timing lines do. |

All backend tests pass with the fixes: `npm test` 201 passed and 23 skipped (the real-runtime ones), and `scripts/test-local.sh` passed 222 of 224, including the four new real-runtime tests. The two failures (the first local test's first request reset with `ECONNRESET`, and `tests/restore-drill.test.ts`, which also ran without `NOOK_RUN_DRILL`, hitting the same reset) fail the same way on the untouched tree, so they predate this phase. Both look like the drill's throwaway backends disturbing the shared one when the files run in parallel; worth a separate look.

### App (public repo)

Source review of `develop` at 4f845c1 (Phase 33a's try-on is still in PR #99; its backend side is in the backend repo and was tested there).

| Area | Result |
|---|---|
| Keychain | The App Attest key ID is the app's only Keychain item, with `WhenUnlockedThisDeviceOnly`. No tokens in `UserDefaults`, plists or files. Clerk's own item is D11. |
| File protection | `NSFileProtectionComplete` is the default in all four entitlements files, and the store, photos, thumbnails, backup staging, exports, journals and safety copies set `.complete` too. Diagnostics use `completeUntilFirstUserAuthentication` (reports arrive while locked; documented in 31). Safety copies, staging, exports, thumbnails and diagnostics are excluded from device backups; photos are included on purpose (0004). |
| ATS | No `NSAppTransportSecurity` key and no `http://` in Swift sources. The gateway URL must be https with no query or credentials. |
| URL schemes and deep links | None: no URL types, `onOpenURL`, user activities, associated domains, widgets or App Intents. The one way in is a local notification tap, which opens an existing job by its ID and carries no parameters. |
| Pasteboard | Paste only through the system `PasteButton`. The one Release write is the generated backup passphrase, on her tap, local only, gone after 120 seconds. |
| Photo metadata | Library, camera and paste all go through `PhotoCleaner`, which redraws from pixels. Feedback screenshots too. The backend strips again. Restored photos come back as they were saved (they were clean when saved, and the copy is authenticated). |
| Debug code in Release | Every debug screen, switch and sample is inside `#if DEBUG`, checked one by one. L7 extends the automatic check. |
| No client trust for paid work | Credit balances are display only; `X-Nook-Entitlement-Hint` is never read by the server; no jailbreak check is used as protection. |
| Backup format (21b's claims) | Paths: an allowlist of characters, no leading dot or slash, so `..`, absolute, encoded and non-ASCII paths fail. Links: only regular files and empty folders, so symlinks and hard links fail. Bombs: at most 200,000 entries, a 16 MB manifest, every size must match the manifest, total checked against free space (now overflow-safe, L6). Tampering: the encryption profile is pinned, the manifest is inside the authenticated stream, every file's SHA-256 is checked and trailing bytes are refused. All confirmed in code and tests (`CraftedArchiveTests`, `BackupTamperTests`). |
| App switcher | Fit, measurements, the try-on photo, try-on pictures and the backup sheet are covered while the app isn't active (`hiddenWhenInactive`). |
| Logging | One Release logger, which logs only the endpoint and a failure kind, as public. No `print` in Release code. |

The new backup test and the existing `CraftedArchiveTests` and `BackupTamperTests` passed (22 tests) on the "32b iPhone 12" simulator. CI ran the Release archive check with the new switches on a real Release binary and passed. Two CI attempts failed in `MigrationDebugTests` (from #98, not touched here; it passed alone and with every Services test on the simulator, and on the third attempt), so that test looks flaky on CI and is worth a look.

### Dependencies

| Package | Version | In the shipped app? | License | Known advisories (GitHub advisory database, 22 October 2026) |
|---|---|---|---|---|
| clerk-ios (`ClerkKit` only) | 1.6.1 | Yes | MIT | None |
| Nuke | 13.2.0 | No (resolved for `ClerkKitUI`, not linked) | MIT | None |
| PhoneNumberKit | 5.0.12 | No (same) | MIT | None |
| swift-snapshot-testing | 1.19.6 | Tests only | MIT | None |
| swift-custom-dump | 1.7.3 | Tests only | MIT | None |
| swift-issue-reporting | 2.1.2 | Tests only | MIT | None |
| swift-syntax | 604.0.0 | Tests only (macros) | Apache-2.0 | None |
| convex (backend) | 1.47.0 | Backend runtime | Apache-2.0 | None |
| convex-test | 0.0.63 | Backend tests | Apache-2.0 | None |
| esbuild (via convex) | 0.27.0 | Build tool | MIT | One high advisory listed for 0.17 to 0.28.0 was withdrawn (it concerned the Deno module); the low one starts at 0.27.3. Not affected |
| prettier (via convex) | 3.9.10 | Build tool | MIT | None |
| ws (via convex) | 8.21.0 | CLI | MIT | Every listed range is patched at or below 8.21.0 |

`npm audit` found 0 vulnerabilities. The app's two direct dependencies are pinned exactly, and both `Package.resolved` files agree (7 pins).

## Not covered

- The OWASP MASVS and ASVS checklists were not walked item by item. This report covers the standard's controls and the threat model's flows; the formal checklists are still due before the first App Store submission (standard §11), and fit Phase 35a.
- No test on a real device: App Attest, the Keychain on hardware, file protection while locked and the real Vision masking are on the device checklist.
- Scale: the races used six parallel requests, not load. Phase 32a covers load.
- The independent review or penetration test the standard asks for before public launch.

## Decisions for Jose

1. **L9 (done, #101):** make Release builds without the backend settings fail closed (the "unavailable" services instead of the fakes)? Suggested: yes, in a small app change once 33a is merged, since 33a touches the same wiring.
2. **L10 (done, ff1efde and #101):** cap try-on photos by pixels on the server, near what the app sends (for example 2,048 px for her photo and 1,024 px per garment)? It's a contract change, so the app's copy moves with it. Suggested: yes, before the first real FLUX.3 call.
3. **L11:** for "Use mine" backup passphrases, raise the minimum (14 to 16 characters) or add a simple strength check, and point people to "Make one for me"? Suggested: a longer minimum plus the nudge.
4. **L8:** accept Convex not checking `nbf` as a residual risk (Clerk controls every token's dates)? Suggested: accept, with the tripwire test as the reminder.
