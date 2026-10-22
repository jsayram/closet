# Load and scale test report (Phase 32a)

Written 22 October 2026. Everything ran on Jose's Mac against a local Convex backend and the iOS simulator. Nothing touched a cloud service, a provider or a real account.

**The short version.** Four things were worth fixing and are fixed:

1. Backup export held every photo in memory: 1,789 MB at 1,000 photos, now 71 to 76 MB (app PR #105).
2. A styling request took 1.5 s with 4,000 failed or free actions in an account's history and 12.6 s with 12,000, because one lookup scanned them all. Now 44 ms and 105 ms.
3. Under 24 simulated users, about 5% of styling requests failed on write conflicts, and a try-on picture's settlement was lost more than once. Now none reach the app.
4. The credit balance read the whole credit history on every usage read (3,012 documents at 3,000 rows). Now 13.

Several things were measured and left alone on purpose, with the reasons below. The two that matter most are the shared spend counters and the try-on poll that re-sends the photos.

## How it was measured

**Backend.** A copy of the backend repo with its own local Convex deployment (own SQLite file, own ports), a fake Clerk issuer, and `scripts/load-test.mjs` (Node built-ins only; it refuses any address that isn't 127.0.0.1 or localhost). It makes accounts that sign in, claim a signed test subscription and register an App Attest key, then runs virtual users who pick an idle account (one device per account) and do one action by weight: usage read 40, who-am-I 12, full style 14, quick style 14, try-on 13, feedback 3, credit claim 4. A try-on is polled the way the app does it (27c): the same Idempotency-Key and body again, a fresh assertion each time, until the picture is there. Then three bursts of 60 signed App Store notifications at once. Run: 120 accounts, 24 users, 60 s, polling every second.

A second tool, `scripts/cost-profile.mjs`, runs the real functions inside `convex-test` and counts documents read and written, index queries, bytes and function runs per request, using convex-test's own transaction tracker. These are exact counts and don't depend on how busy the Mac is. One blind spot: the tracker counts documents a query returns, not ones a `.filter` skips, which Convex counts as scanned. The one place that mattered was found by timing on the real local backend instead.

**App.** Package tests on a "32a iPhone 12" simulator (iOS 26.5, Xcode 27.1, Debug build), with 5,000 pieces, 2,000 saved looks plus 1,000 unsaved results, and 500 try-on pictures (`ScaleData`, in the app repo's `NookTestSupport`). Each check prints the fastest, median and slowest of three to ten runs.

**Why the numbers are relative.** The Mac was busy the whole time (CI and other agents; its load average ran in the hundreds), and a simulator runs on the Mac's chip in a Debug build. Latencies from the local backend (a second or two with 24 users) are queueing on a shared laptop, not what Convex's cloud would do. Use the numbers to compare before and after, and the document counts for what scales.

## Backend results

### Load run, before and after the fixes

Same script, same parameters, one run each.

| | Before | After |
|---|---|---|
| Unexpected errors | 10 (4 full styles, 4 quick styles, 1 try-on start, 1 picture) | 0 |
| Style requests sent in the run | 99 (51 full, 48 quick) | 169 (73 full, 96 quick) |
| Write conflicts logged by Convex | 20 | 30, every one absorbed by a retry |
| `GET /v1/usage` p50 / p95 | 2,466 / 4,730 ms | 1,613 / 4,473 ms |
| `POST /v1/style` full p50 / p95 | 3,399 / 5,914 ms | 2,135 / 9,649 ms |
| Notifications, 60 at once, p50 / p95 | 560 / 1,164 ms | 609 / 1,157 ms |
| Try-on picture, start to finish p50 | 7.6 s | 5.3 s |

The latencies move with the machine more than with the code; the errors don't. A conflicting settle is the serious one: in the first run a try-on's settlement failed after the picture was made, which leaves the action running until its lease ends, then uncertain, with the reservation kept and the picture never delivered. Admit and settle are now retried up to five times with a short random wait (`convex/gateway/retry.ts`).

### What each request costs the database

Counts per request on a fresh account (functions run, index queries, documents read, documents written):

| Request | Runs | Queries | Read | Written |
|---|---|---|---|---|
| `GET /v1/me` | 2 | 2 | 1 | 1 |
| `GET /v1/usage` | 3 | 21 | 12 | 1 |
| `POST /v1/style` full | 7 | 40 | 44 | 19 |
| `POST /v1/style` quick | 11 | 43 | 64 | 20 |
| Same key again (replay) | 9 | 14 | 15 | 3 |
| `POST /v1/feedback` | 3 | 8 | 2 | 3 |
| `POST /v1/try-on` first ask | 10 | 29 | 38 | 11 |
| Try-on background job | 10 | 19 | 28 | 11 |
| Try-on poll that gets the picture | 6 | 13 | 14 | 3 |
| `POST /v1/credits/claim` | 3 | 11 | 6 | 5 |
| App Store notification | 2 | 7 | 6 | 6 |

Convex's per-function limits (docs.convex.dev/production/state/limits, read 22 October 2026): a query or mutation may scan 32,000 documents and 16 MiB, write 16,000 documents, read 4,096 index ranges, and run 1 second of its own code. Nothing here comes near one.

How reads grow with history, per usage read:

| History | Before | After |
|---|---|---|
| Credit ledger, 100 / 1,000 / 3,000 rows | 112 / 1,012 / 3,012 docs | 13 / 13 / 13 |
| Failed actions in the last 30 days, 50 / 200 / 1,000 | 62 / 212 / 1,012 docs | unchanged (see below) |

### Findings

**Fixed**

- **A scan hidden in a filter** (`stylistResults.store`). It looked the action up with `withIndex("by_principal_status", principal)` and then `.filter(publicId == ...)`, so it walked all the account's actions in status order, and failed and free ones sort before the running one. A free action is what a cached answer leaves behind. Timed on the local backend with one account, style requests took about 65 ms with none behind them, 1,547 ms with 4,000 and 12,648 ms with 12,000 (the fresh control account stayed at 116 to 157 ms). Now an index on `paidActions.publicId`: 44 ms and 105 ms.
- **Credit balance** summed the whole ledger on every read. A running balance row per account (`creditBalances`) is now written in the same transaction as every ledger row (`credits.append`), so a read is one document. An account with no row gets one from its ledger on its next credit, and `credits:check` compares the two.
- **Health counters** found their row by collecting the whole (hour, route) range on every request, so every concurrent request on a route depended on every shard and they queued behind each other. A sample is now a point read on the full index, 8 shards instead of 4, and the range is read only when the sample is an error. This also sits inside `settle`.
- **Write conflicts on the shared spend counters** (see "Left alone" for why they weren't sharded). Retried in the action, as above.
- **Daily clean-ups took one batch a day and stopped.** Stylist results (500), job events (500), support tickets (200), deletion records and App Store notifications (500 each). With more than 500 results expiring a day, the 24-hour promise breaks and the table grows. Each now carries on while a batch comes back full.
- **Ledger rows were never removed.** 24b listed the clean-up as unbuilt and nothing built it, so paid actions, cost entries and attestation challenges only grew, about three rows per paid action for ever. A daily job removes finished actions and settled or released cost entries after 35 days (running, reserved and uncertain stay), and challenges a day after they expire.

**Left alone, with reasons**

- **The spend counters stay one row per scope and period.** Every admit and every settle writes four of them (global and provider, day and month). That is the cost of exact ceilings: the 32b race test proves six accounts can't push a provider past its ceiling, and a sharded counter can't do that without either giving up exactness or a lease scheme that touches the ceiling logic, the alerts, the controls and the summary. The retry removes the visible failures. At 1,000 users the shared rows are idle (see the projection). The design to use when it matters is in the next item.
- **When to shard:** when a day's peak hour has more than about 2 paid actions a second (7,200 an hour) sustained, which is about 14 times the 1,000-user peak below, or when the dashboard shows many "changed while this mutation was being run" lines for `ledger:admit` or `ledger:settle`. The safe design is per-shard leases: each shard may reserve up to a lease it holds without checking the others, a full shard reads all of them and reclaims unused leases before refusing, and `controls:setCeiling` revokes every lease. Not built, because nothing needs it yet.
- **The try-on poll re-sends the photos.** Each poll is the same POST with the same body (up to 6 MiB), because the key is bound to the exact body. On the backend that costs about 0.3 s of action time at the largest size (6 users at once, 5.4 MB bodies: p50 328 ms, against 50 to 90 ms for a usage read) and nothing in the database. For her phone it means about 8 to 10 MB uploaded per picture at a typical 1.2 MB body and six polls, more on a slow service. A small status call (the action's ID, no photos) would fix both ends, but it changes the contract and the app (27c, 33a), so it is a question for Jose, not a fix.
- **Failed and free actions inside the 30-day window** still make usage and admit read one document each. Only failures and cache hits do this, and the rate limit (5 a minute) bounds it: reaching Convex's 32,000-document scan limit takes about four and a half days of non-stop failing, and only that account suffers. The fix is an index by status, three queries instead of one. Do it if the heavy-user numbers on the dashboard ever show hundreds.
- **Function calls per request.** A usage read is 3 runs plus the HTTP action, a full style 7, a quick style 11, a try-on picture about 50 with its polls. Every request also makes one `recordRequest` mutation for the daily summary. At 1,000 users that is about 2.5 million calls a month (below), over the 1 million Starter includes (about US$3 at the listed overage) and 10% of Professional's 25 million.
- **`auditEvents` and `rateBuckets`** have no clean-up. One row per failed assertion or key registration, and one per account and purpose. Small, but unbounded.

### Maximum try-on bodies

Nine pieces at 340 KB and a 1.4 MB photo (a 6.1 MB body, just under the 6 MiB limit), six accounts at once, polled as the app does: no errors, no memory failure on the local backend. Convex's own limit is 64 MiB of memory for an action in its default runtime, and this path holds the body, the decoded images, the cleaned copies and the sealed copy at once, so it is worth one run of the same size on a real dev deployment when Jose sets that up.

### What changes at 1,000 users

Assumptions, not measurements: 1,000 accounts active every day; each opens the app 5 times (5 usage reads), asks for 3 styles (2 full, 1 quick) and 0.5 try-on pictures, and sends a note one day in twenty; the peak hour carries 15% of the day.

| Measure | At 1,000 users | Convex limit or plan figure | Verdict |
|---|---|---|---|
| Paid actions a day | 3,500 | none | |
| Paid actions in the peak hour | about 525 (0.15 a second) | one hot row set; conflicts start to bite near 2 a second | 14 times of room |
| Function calls a month | about 2.5 million | 1 million Starter, 25 million Professional | over Starter; fine on Professional |
| Concurrent mutations at peak | a handful | 16 Starter, 256 Professional | fine |
| Concurrent HTTP actions at peak | under 10 | 64 Starter, 512 Professional | fine |
| Largest query (a usage read) | 12 documents for a typical user, up to about 780 for one at her monthly allowance | 32,000 scanned | fine |
| Stylist results kept | about 3,500, about 10 MB | | fine now the clean-up keeps up |
| Paid-action and cost rows kept | about 70 MB at 35 days, my estimate (about 700 MB a year without the clean-up) | check the plan's storage | fine now |
| Staged try-on photos | a few in flight, deleted within 30 minutes | | fine |

## App results (5,000 pieces, 3,000 looks, 500 pictures)

Simulator, Debug, quiet Mac, fastest of five runs unless noted. These are in Debug builds; a Release build is several times faster for this kind of code, and a phone's A14 differs from the Mac's chip, so none of it replaces the device list below.

| What she does | Time |
|---|---|
| Store opens at launch (5,000 + 3,000 + 500 records) | 4 ms |
| First screens read everything, cold (fresh store object) | 325 ms |
| A screen reads all 5,000 pieces (stores warm) / all 3,000 looks | 50 ms / 20 ms |
| One edit saved, among 5,000 pieces / one look saved | 2 ms / 1 ms |
| Launch sweep for unused photo files (runs away from the screens, reads every record) | 360 ms |
| Closet opens (grid prepared) | 23 ms |
| Closet typed search: a name word / two words / an other name's word | 58 / 62 / 60 ms |
| Closet possible matches (a search with no results) | 205 to 255 ms |
| Closet chip, swatch or Suitcase filter | 0 to 6 ms |
| Saved Looks opens (3,000 looks, 500 pictures) | 185 ms |
| Saved to All and back | 41 ms |
| Saved Looks search, either scope | 110 to 160 ms |
| Pictures tab and back / Pictures search | 37 ms / 240 ms (two searches) |
| Backup: the summary Export shows first | 360 ms |
| Backup export, records only (11 MB of records) | 0.93 s, 0.58 MB file, peak 88 to 93 MB |
| Backup export with 1,000 photos of 1.8 MB | 3.6 to 4.0 s, 1,728 MB file, peak 71 to 76 MB |
| Check a copy / Restore (Replace) of that | 2.7 / 2.8 s, peak 64 MB |
| Restore of 5,000 + 3,000 + 500 records with 100 photos | 5.1 s, peak 101 MB |

Typed search waits 250 ms after she pauses, then costs 60 to 160 ms on the main thread in Debug, so nothing here needs a change. Possible matches is the slowest per keystroke at about 0.2 s in Debug; check it on the phone before touching it.

**The bug.** The first run of the export with real-sized photos peaked at 1,789 MB, almost exactly the photos' total size. `FileHandle.read(upToCount:)` returns memory Foundation frees only when its autorelease pool drains, and an export runs in one pool from start to end. Mapped reads of the same files peaked at 42 MB and 1 MiB reads without a pool at 558 MB, so it was the loop, not the files. `BackupArchiveWriter.add` now reads each piece in its own `autoreleasepool`. An iPhone 12 would have been ended by the system around the same size, and the 21b tests used a few small files, so none could see it.

## Re-measure on the phone

Added to `DEVICE_TEST_CHECKLIST.md` as 2.20 to 2.23. In short: export at 1,000 photos (memory and the system keeping the app alive), cold launch and the launch sweep with the 2,400-piece photo closet, typed search and possible matches on the phone, and the data a try-on picture uses over cellular.

## Questions for Jose

1. Try-on polling re-sends the photos every five seconds. Add a small status call (the action's ID only) so a poll costs nothing? It changes the contract and the app.
2. Retention: finished paid actions and cost entries are now removed after 35 days, the 31-day rule the schema comment always said. Is 35 days fine? Account deletion already keeps usage under a hashed key for 31 days.
3. Plan size: at about 2.5 million function calls a month for 1,000 users, Professional is the safe choice, and Starter costs a few dollars more per month than listed. Your call when you pick the plan.

## What was committed

- Backend (local repo, `main`, never pushed): `8436a42` the fixes above, `e942782` the ledger clean-up. Scripts: `scripts/load-test.mjs`, `scripts/cost-profile.mjs`; tests: `tests/scale.test.ts` (9). `npm test` passes (213 plus 23 that need a local backend); the 21 tests that run on a real local backend also pass on the new code.
- App: PR #105, branch `perf/32a-scale`: the export fix and the scale tests (`ScaleBrowsingTests`, `ScaleStoreTests`, `ScaleDataTests`), numbers in `docs/image-storage.md`.
