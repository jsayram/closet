# Stage B data options

Research note for Phases 20a to 21a and 23a to 23b, written 16 October 2026. Prices, limits and features were checked against official docs and pricing pages that day (sources at the end). Nothing was signed up for and no service API was called. Each phase re-checks its numbers when it starts.

Two layers: **A**, where the closet, photos and looks live on the device and how they reach her private iCloud; **B**, the backend for identity, the credit ledger, App Store notifications, the AI proxy, support, opt-in analytics, Find One and account deletion. The backend holds no copy of the closet.

## What the docs already require

From PRD 11.4, 11.6, 11.7 and 15.1 to 15.4, SECURITY_STANDARD.md and DATA_MAP.md:

- **Conflicts are reviewed, not guessed** (PRD 11.7). Keep competing revisions for review, never pick a winner by device clock, removal beats a stale edit, and deletion markers stop old devices bringing records back.
- **Migrations can't destroy data,** and **Delete my data covers iCloud too,** showing "pending" when iCloud is unreachable (PRD 15.1).
- **Exports are encrypted** and **files use `complete` protection** unless an exception is documented (standard section 4).
- **Backend:** atomic ledger with cost reserved before paid calls, idempotent credits and webhooks, JWS-verified App Store notifications, default-deny authorization with a cross-user test, three environments, tested backups, an audit log (standard sections 5, 6, 10).
- **App:** Swift 6 strict concurrency, iOS 26.0 minimum, no shipping dependency without written vetting, plain `URLSession` to the backend.
- **The store protocols** in `NookServices` are `Sendable`, `async` and pass value types. Whatever goes behind them must pass the existing contract test suites.

## A. On-device storage and iCloud sync

### Local store options

| | SwiftData (local only) | Core Data | SQLite through GRDB | Plain files and Codable |
|---|---|---|---|---|
| Who makes it | Apple | Apple | Gwendal Roué, MIT, about 8.7k stars, needs Swift 6.1 or later since 7.9 | Apple (Foundation) |
| Swift 6 fit | Models aren't `Sendable`. Work happens inside a `@ModelActor` and only value types and `PersistentIdentifier` leave it. That matches our protocols, which already return value types. | `NSManagedObject` isn't `Sendable` either. Same actor pattern, more boilerplate. | Records are plain `Sendable` structs, and `DatabasePool` is safe to share. The best fit of the four. | Fine, but every guarantee is hand-made. |
| Migrations | `VersionedSchema` and `SchemaMigrationPlan`. Forums still report staged-migration crashes ("unknown model version") and CloudKit mirroring errors during migration. | Lightweight and staged migrations, mature. | `DatabaseMigrator`, plain SQL, easy to test against fixture databases. | Our own versioned decoding. |
| Search | No full-text search. PRD 11.9's index would be a second store anyway. | No FTS. | FTS5 built in, which is PRD 11.4's search candidate. | None. |
| 2,000+ garments | Records are small. Fine if fetches run off the main actor and screens get value types (Phase 6 already measures 2,400 pieces in memory). | Fine. | Fine, with indexes we control. | Loading the whole closet on every change gets slow. |
| Testability | In-memory `ModelConfiguration` runs the existing contract suites. | In-memory store, same idea. | In-memory database, same idea. | Temporary folder. |
| Cost of choosing it | None. iOS 27 additions (`HistoryObserver`, `ResultsObserver`, the `.codable` option, from Apple's June 2026 notes) need availability checks, since the floor is iOS 26. | None. | A dependency to vet in writing (standard section 3). | Lots of our own code. |

**Images in every option:** files, not blobs. One file per original, cutout and thumbnail, named by stable ID, in Application Support with `complete` protection. The record holds the file name and a hash. Don't use SwiftData's `.externalStorage`, because Core Data then owns where the bytes live, which makes export, purge and per-file protection harder to prove.

### Sync options

| | SwiftData or Core Data with automatic CloudKit mirroring | `CKSyncEngine` (iOS 17+) | iCloud Drive documents |
|---|---|---|---|
| What it is | `NSPersistentCloudKitContainer` mirrors the store to her private database. SwiftData uses it under the hood. | Apple's engine handles scheduling, push subscriptions, batching (250 records per request), change tokens and transient retries. We own the local store and the merge. | Whole files in her iCloud Drive, coordinated with `NSFileCoordinator`. |
| Conflicts | The framework merges for us. There is no hook for "keep both revisions and ask her". | `serverRecordChanged` comes to our code, so PRD 11.7's rules (no clock winner, removal wins, review screen) can be built and unit-tested as pure functions. | Whole-file versions (`NSFileVersion`). No per-record merge. |
| Schema limits | No unique constraints, every relationship optional with an inverse, no Deny delete rule, relationship changes not atomic, and the CloudKit schema is additive forever once promoted. These limits reach into the local model too. | Our record types are additive forever once promoted, but the local schema is free. | None. |
| Encryption | `@Attribute(.allowsCloudEncryption)` per field. | `encryptedValues` per field, chosen in code. Encrypted fields can't be queried, which we don't need. Assets are encrypted by default. | Standard iCloud Drive protection; end-to-end only with Advanced Data Protection. |
| Deleting her iCloud copy | `purgeObjectsAndRecordsInZone` exists on Core Data. SwiftData has no API, so we'd drop to Core Data. | Delete our custom zone. Other devices get a zone-deleted event and clear their copy. | Delete the files. |
| Status for the UI (PRD 15.1 Pending, Failed, last acknowledgement) | Event notifications, coarse. | Per-batch sent and fetched events, so per-record pending counts are ours to show. | Coarse. |
| Effort | Least code at first, the most surprises later. | More code: record mapping, merge rules, tombstones, asset upload, state persistence. | Not suited to a record store. Use it only as an export destination. |

**Encryption (Apple support page 102651, 5 January 2026).** With standard protection, app data in iCloud is encrypted in transit and on the server, and Apple holds the keys. With Advanced Data Protection, CloudKit encrypted fields and assets become end-to-end encrypted. So every Sensitive and Personal text field goes in `encryptedValues`, plain fields hold only IDs, revisions and timestamps, and Lily is told that Advanced Data Protection is what takes Apple out of the picture. Encryption can't be added to an existing field, so this must be settled before the schema is promoted.

**Limits and cost.** A record holds up to 1 MB excluding assets and an asset up to 50 MB, so photos travel as `CKAsset`. Storage counts against her iCloud quota, not Jose's; a 1,000-item closet can fill most of the free 5 GB (PRD 15.3). It costs the developer nothing.

**File protection.** With `complete` protection the store can't open while the phone is locked, so sync applies changes after she unlocks. The `CKSyncEngine` state file holds tokens and record IDs, not closet content, so it may take `completeUntilFirstUserAuthentication` as a documented exception if 20a shows a need.

## B. Backend platform

### Free tiers and entry prices

| | Cloudflare (Workers + D1, Durable Objects, KV, R2) | Supabase | Convex | Firebase (Firestore + Functions) | Neon Postgres + Workers |
|---|---|---|---|---|---|
| Free tier | Workers 100,000 requests a day, 10 ms CPU each. D1: 5 M rows read and 100k written a day, 5 GB total, 500 MB per database, 10 databases. | 500 MB database, 50,000 MAU, 5 GB egress, 500k Edge Function calls, 2 active projects. | 1 M function calls a month, 0.5 GB database, 1 GB egress, 20 GB-hours action compute. | Firestore 1 GiB, 50k reads and 20k writes a day. Functions need the Blaze plan to deploy. | 1 GB per project, 100 CU-hours per project, scale to zero after 5 minutes. |
| Over the limit or idle | Error 1027 after 100k requests (fail-open or fail-closed is configurable). D1 and Durable Object calls fail until 00:00 UTC. Never pauses for inactivity. | **Paused after a week of low activity**, restored by hand from the dashboard. | New writes may fail. A deployment can be disabled until the window rolls over. No inactivity pause. | Spark stops at quota. On Blaze, an alerts-only budget doesn't cap spending. | Cold start after scale to zero. |
| Paid entry | Workers Paid $5 a month: 10 M requests, 30 M CPU-ms, D1 25 B reads, 50 M writes, 5 GB. | Pro from $25 a month with $10 compute credit (one Micro project). Each extra project pays its own compute, about $10 for Micro. | Starter: pay as you go ($2.20 per extra million calls). Professional $25 per developer a month. | Blaze pay as you go with the same free quota first. | Launch: usage only, $0.106 per CU-hour, $0.35 per GB-month, no minimum. |
| Backups | D1 Time Travel always on, any minute, 7 days free and 30 days paid, no charge. Export to R2 for longer. | **None on Free.** Pro: 7 daily backups. Point-in-time recovery $100 a month for 7 days. | Manual backups on every plan, kept 7 days. Scheduled backups need Pro. No point-in-time restore. | Scheduled backups and PITR on Blaze, billed by size. | 6-hour restore window on Free, up to 7 days on Launch. |
| SLA | Only the Business plan and above. | Team plan ($599) and above. | Not on Free or Starter. | Google Cloud SLA on Blaze services. | Scale plan only. |

### Security, identity and money

| | Cloudflare | Supabase | Convex | Firebase | Neon + Workers |
|---|---|---|---|---|---|
| Authorization model | No RLS. D1 has no public endpoint; only our Worker can reach it through its binding. Authorization lives in our code. | Postgres RLS, default deny, as the standard assumes. | No RLS. Checks in each function. | Security Rules, default deny. | RLS available, but the Worker is the only client, so the code does the work. |
| Secrets | Worker secrets per environment, write-only after setting. | Vault and Edge Function secrets. | Environment variables per deployment. | Secret Manager. | Worker secrets. |
| Sign in with Apple | We verify the identity token ourselves (ES256 against `appleid.apple.com/auth/keys`, check `iss`, `aud`, `exp`, `nonce`), then issue our own short-lived session. A small, well-tested job with the `jose` library. | Built in. Native `signInWithIdToken` with a nonce; no 6-month key rotation for native-only. | Not built in. Verify in an HTTP action, then issue a custom JWT. | Built in. | Same as Cloudflare. |
| App Store Server Notifications V2 | Verify the JWS `x5c` chain to the Apple Root CA G3 and check the signature. Apple's MIT `app-store-server-library` exists for Node; Workers' `node:crypto` lists no exception for X.509, but this needs a spike. The free plan's 10 ms CPU may be too little; Paid allows 30 s. | Edge Function (Deno), 2 s CPU. Feasible. | HTTP action. Feasible. | Function. Feasible, Node library works as is. | Same as Cloudflare. |
| Ledger integrity | D1 is single-writer SQLite. `batch()` runs as one transaction and rolls back on any failure. Idempotency through a `UNIQUE` key, reservations through a conditional `UPDATE`. No interactive transactions, so each step has to be one batch. A Durable Object per principal is there if we need serialized multi-step logic. | Full Postgres transactions and functions. The strongest. | Mutations are serializable transactions. Strong. | Firestore transactions. Workable. | Full Postgres transactions. |
| Data residency | Location hints, or an `eu` or `us` jurisdiction. | Region per project. | US East, EU (Ireland), Sydney, Canada. Non-US costs 1.3×. | Location per database. | Region per project. |
| Lock-in and exit | Medium. SQL is portable SQLite and D1 exports to SQL; the Worker code is standard `fetch` handlers. | Low. It's Postgres; `pg_dump` and leave. | High. Its own query and function model; self-hosting exists. | High. Firestore data model and rules. | Low. |
| Swift client with plain URLSession | Our own small JSON API. A clean fit. | REST works, but direct table access ties the app to the schema. Use Edge Functions or RPC only. | HTTP actions fit. The official Swift SDK wraps a Rust core (a binary dependency). | REST is possible but awkward; the platform expects its SDK. | Our own API. |
| AI proxy | Streaming responses, no wall-clock limit while the client is connected, and waiting on `fetch` doesn't count as CPU. Built-in rate-limit binding, but it's eventually consistent, so it's an abuse throttle only, never the quota store. | Edge Functions: 150 s idle timeout, 150 s wall clock on Free, 400 s on paid. | HTTP actions with streamed bodies. | Functions with long timeouts. | Same as Cloudflare. |

**Reliability history.** Cloudflare had a 2 h 28 min outage on 12 June 2025 that took down Workers KV, a network-wide one on 18 November 2025, and minor D1 and Durable Objects errors on 15 October 2026. None of these vendors offers an SLA at Jose's price point. The app is local-first, so an outage stops cloud styling, not the closet.

### Rough monthly cost

Assumptions: about 15 backend requests and 50 row writes per active user per day. AI provider tokens, the $99 Apple membership and WeatherKit are left out. AI cost dominates everything here: PRD 11.6's guardrail is $1 per user per month, so 5,000 users could mean up to $5,000 in inference against a few dollars of hosting.

| | 1 user (Lily) | 300 users | 5,000 users |
|---|---|---|---|
| Cloudflare | $0 (Free) | $5 (Paid, for CPU headroom and no daily cap) | $5 (about 2.3 M requests and 7.5 M writes, inside the included amounts) |
| Supabase | $0 only with pausing and no backups; realistically $25 to $45 for Pro plus staging | $25 to $45 | $35 to $60 (bigger compute) |
| Convex | $0 | $0 | About $3 on Starter, or $25 or more for Pro with scheduled backups |
| Firebase | $0 to $1 on Blaze | $1 to $5 | $5 to $20, with no hard cap |
| Neon + Workers | $0 | $5 to $15 | $25 to $45 |
| iCloud sync (all options) | $0 | $0 | $0 (uses each user's own iCloud quota) |

## Recommendations

### On the device: SwiftData as a local-only store, with `CKSyncEngine` for iCloud

- SwiftData with `cloudKitDatabase: .none`, wrapped in one `@ModelActor` per store, mapping to the existing value types. Images as protected files. A separate rebuildable search index (SQLite FTS5 if the spike shows the system library supports it).
- `CKSyncEngine` in a `SyncService` behind its own protocol, with a custom zone in her private database, PRD 11.7's merge rules as pure functions, deletion markers, and `encryptedValues` on every Sensitive and Personal field.
- Encrypted export archive (CryptoKit AES-GCM, key from a passphrase) saved through Files.

Why: automatic CloudKit mirroring can't meet PRD 11.7's conflict rules or PRD 15.1's per-record status, and its schema limits would spread into the local model. `CKSyncEngine` is Apple's own, free, and puts the rules in code we can test. SwiftData stays because the PRD proposes it, it's Apple's, and our protocols already hide its non-`Sendable` models.

**Runner-up: GRDB with the same `CKSyncEngine` layer.** It's the stronger technical fit for Swift 6 and has FTS5 built in, but it's a shipping dependency that needs Jose's written approval. Name it now as the fallback so the 20a spike has a clear no-go path. Core Data is the all-Apple fallback if he declines the dependency.

**20a go/no-go gates for SwiftData:** passes every store contract suite; a staged migration over the large fixture survives a forced kill at each step; 2,400 garments load off the main actor without a stall; no crash over 1,000 rapid saves from two actors.

### Backend: Cloudflare Workers + D1

- One Worker per environment (dev, staging, production), each with its own D1 database and secrets.
- D1 holds principals, sessions, consent receipts, the ledger and reservations, entitlements, the notification log, the audit log, support tickets and aggregated analytics.
- The rate-limit binding for coarse throttles. Durable Objects only if per-principal concurrency (one expensive action at a time, PRD 11.6) can't be done cleanly with a conditional `UPDATE`. R2 later for Phase 33 image staging.
- Start on Free for Lily alone. Move to Workers Paid ($5) before the first outside tester.

Why: it's the cheapest at every scale, never pauses, Jose already has the account, the database has no public endpoint, Time Travel gives free point-in-time restore, and the app's plain-`URLSession` design fits a hand-written JSON API exactly.

**Runner-up: Supabase Pro** (about $25 to $45 a month). Choose it if Jose would rather pay for built-in RLS, managed Sign in with Apple and real Postgres than write and test those parts himself. Convex and Firebase are not recommended: no RLS and Pro-only scheduled backups for Convex, no hard spending cap and high lock-in for Firebase.

### Main risks and mitigations

| Risk | Mitigation |
|---|---|
| `CKSyncEngine` is more code than mirroring, and sync bugs lose data | Merge rules as pure functions with table-driven tests; a fake engine in CI; PRD 11.7's two-device offline test on real devices; sync off by default until 21b's restore test passes. |
| A CloudKit schema mistake is permanent once promoted | Promote only after 20b sign-off; version record types; encrypted fields decided before promotion. |
| SwiftData still has rough edges on iOS 26 | 20a gates above; GRDB named as fallback; the protocols mean only the store module changes. |
| No RLS, so a missing check leaks another user's data | One data-access module that takes the principal ID on every query, no raw SQL in handlers, and cross-user tests in CI (Phase 24c). |
| Hand-written Apple token and JWS verification | The `jose` library and Apple's own `app-store-server-library`; tests with Apple's sample payloads and tampered ones; covered by the independent review in 35a. |
| No SLA, and Cloudflare-wide outages happen | The app is local-first; ledger reservations stay held through outages; clear "styling unavailable" state (Phase 26). |
| Website and backend share one Cloudflare account (threat R3) | Passkey or hardware-key 2FA, API tokens scoped per product, or a separate Cloudflare account for the backend. |
| Free plan limits during testing | Paid plan before outside testers; fail closed on error 1027. |

### Phases this affects

On the device: 20a (spike gates), 20b (sync design, encrypted fields, zone deletion, export format), 21a, 21b, 22b (image files and `CKAsset`). Backend: 23a and 23b, 24a (our own Apple token check and sessions), 24b (D1 ledger), 24c (code-level authorization, zone deletion), 24d, 25a, 25b (Time Travel restore), 26, 27a (streaming proxy), 30c (JWS in a Worker), 31, 32a, 32b.

### Decisions in the docs this would change

1. **PRD 11.4 and the PRD 11 diagram** assume SwiftData's own CloudKit sync. This note proposes `CKSyncEngine` instead; local persistence stays SwiftData.
2. **SECURITY_STANDARD.md section 5 and Phase 24c** say "Row Level Security". With D1 the equivalent is a principal-scoped data layer with default deny and cross-user tests. Jose should approve that wording so it isn't read as an exception.
3. **ACCOUNT_INVENTORY.md** expects a separate database provider. Here it's the website's Cloudflare account, which raises threat R3's stakes.
4. **`complete` Data Protection** stays for the store and images; the sync state file may need a documented exception.

## Sources (all checked 16 October 2026)

- Cloudflare Workers pricing: https://developers.cloudflare.com/workers/platform/pricing/
- Workers limits: https://developers.cloudflare.com/workers/platform/limits/
- D1 limits: https://developers.cloudflare.com/d1/platform/limits/
- D1 Time Travel: https://developers.cloudflare.com/d1/reference/time-travel/
- D1 batch transactions: https://developers.cloudflare.com/d1/worker-api/d1-database/
- D1 data location: https://developers.cloudflare.com/d1/configuration/data-location/
- Durable Objects pricing: https://developers.cloudflare.com/durable-objects/platform/pricing/
- Rate-limit binding: https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/
- Workers `node:crypto`: https://developers.cloudflare.com/workers/runtime-apis/nodejs/crypto/
- Hyperdrive pricing: https://developers.cloudflare.com/hyperdrive/platform/pricing/
- Cloudflare SLA: https://www.cloudflare.com/business-sla/
- Cloudflare outages: https://blog.cloudflare.com/cloudflare-service-outage-june-12-2025/ and https://blog.cloudflare.com/18-november-2025-outage/ and https://www.cloudflarestatus.com/history
- Supabase pricing: https://supabase.com/pricing
- Supabase backups: https://supabase.com/docs/guides/platform/backups
- Supabase pausing: https://supabase.com/docs/guides/platform/going-into-prod
- Supabase Edge Function limits: https://supabase.com/docs/guides/functions/limits
- Supabase Sign in with Apple: https://supabase.com/docs/guides/auth/social-login/auth-apple
- Convex limits: https://docs.convex.dev/production/state/limits
- Convex backups: https://docs.convex.dev/database/backup-restore
- Convex usage limits: https://docs.convex.dev/production/usage-limits
- Convex regions: https://docs.convex.dev/production/regions
- Convex HTTP actions: https://docs.convex.dev/functions/http-actions
- Convex Swift client: https://docs.convex.dev/client/swift
- Convex Starter plan post: https://news.convex.dev/introducing-the-new-convex-starter-plan-pay-for-only-what-you-need/
- Firebase pricing: https://firebase.google.com/pricing and https://firebase.google.com/docs/projects/billing/firebase-pricing-plans
- Firestore backups: https://firebase.google.com/docs/firestore/backups
- Google Cloud budgets: https://docs.cloud.google.com/billing/docs/how-to/budgets
- Neon pricing: https://neon.com/pricing
- CKSyncEngine: https://developer.apple.com/documentation/cloudkit/cksyncengine-5sie5
- SwiftData sync: https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices
- SwiftData updates: https://developer.apple.com/documentation/updates/swiftdata
- ModelActor: https://developer.apple.com/documentation/swiftdata/modelactor
- Core Data with CloudKit model rules: https://developer.apple.com/documentation/coredata/creating-a-core-data-model-for-cloudkit
- NSPersistentCloudKitContainer: https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer
- CKRecord `encryptedValues`: https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues
- CloudKit size limits: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html
- iCloud data security and Advanced Data Protection: https://support.apple.com/en-us/102651
- SwiftData migration reports: https://developer.apple.com/forums/thread/775060 and https://developer.apple.com/forums/thread/758874
- GRDB: https://github.com/groue/GRDB.swift
- Apple App Store Server Library: https://github.com/apple/app-store-server-library-node
- Sign in with Apple token keys: https://developer.apple.com/forums/thread/119604
