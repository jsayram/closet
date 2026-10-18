# Jose's default stack

Agreed 18 October 2026. Every new project, and every agent working on one, starts from this. Pick something else only when a project needs what this list can't do, and write down why. Prices were checked on the providers' live pages that day. Re-check them when a project starts paying.

## The four services

| Job | Service | Free | Paid when needed |
|---|---|---|---|
| Websites, landing pages, privacy and support pages | **Cloudflare** (Pages or Workers static assets) | Up to 100 sites, unlimited bandwidth | Workers Paid $5 a month, only if a project needs Workers past the free limits |
| Sign-in for iOS and web apps | **Clerk** | Unlimited apps, 50,000 monthly retained users per app, sessions fixed at 7 days | Pro $25 a month ($20 billed yearly): custom session length, MFA, passkeys, no branding |
| App backend: database, API routes, server-side AI keys, real-time, vector search, file storage, scheduled jobs | **Convex** | 1 M function calls a month, 0.5 GB database, 1 GB files, up to 6 developers, 40 deployments. No inactivity pause | Professional $25 per developer a month: 25 M calls, 50 GB database, 100 GB files, scheduled daily backups. One price covers every app |
| AI text (stylist, chat, reasoning) | **Claude API** (Haiku 4.5 by default, Sonnet 5.5 when quality earns it), called only from Convex | $5 one-time trial; Max plans include $100 to $200 a month in API credits (since 7 October 2026) | About $0.007 per Haiku styling request, $0.014 on Sonnet. Set a Console spend limit |
| AI image generation | **WaveSpeed**, called only from Convex | Prepaid balance | Pay per image, about $0.04 for Seedream 4.5 Edit |
| On-device AI bonus | Apple Foundation Models (iPhone 15 Pro and newer) | Free | Free |

Never use an AI provider's free tier for user data if its terms allow training on it (for example the Gemini API free tier). Paid tiers only for anything personal.

Each user's personal data on an iPhone stays on the device (SwiftData), with optional private iCloud sync (CloudKit). The backend holds only what has to be shared or trusted: accounts, ledgers and credits, purchases, feedback, and the AI calls.

## Apple's free services (come with the developer account)

- **StoreKit** for purchases and subscriptions, with the server checking them in Convex.
- **Push notifications (APNs),** sent from a Convex function.
- **Game Center** for leaderboards, achievements, friends and small real-time matches.
- **SpriteKit** (2D games), **WeatherKit,** **App Attest,** **Sign in with Apple,** and **Xcode Organizer** for crash reports.

## How an iOS app fits together

```
iPhone app
 ├─ SwiftData + iCloud            the user's own data, on the device
 ├─ Clerk (clerk-ios)             Sign in with Apple, keeps the session fresh
 └─ HTTPS to Convex HTTP actions  with the Clerk session token as the bearer
      ├─ Convex database          accounts, ledger, purchases, feedback
      ├─ AI providers, WaveSpeed  keys stored only as Convex environment variables
      └─ App Attest check         proves the request came from the real app
```

- The app calls its own endpoints and never touches the database directly. Moving to a different backend later then means rewriting the server, not the app's screens.
- No AI key, database key or other secret ever ships inside an app or sits in a repo.
- Convex has no row-level security. Every function checks the signed-in user, data access goes through one module that takes the user ID, and CI runs tests proving one user can't read another's data.

## What it covers

| App type | Covered? |
|---|---|
| Productivity, social, AI, shopping and fashion apps | Yes |
| Single-player games like Candy Crush (engine on the phone, progress, coins, events, leaderboards and purchases on the backend) | Yes, with SpriteKit or Unity |
| Turn-based and casual live multiplayer, chat, presence | Yes. Real-time updates are Convex's strength |
| Small fast matches, 2 to 8 players | Yes, through Game Center real-time matches |
| Fast-action multiplayer at 30 to 60 updates a second (shooters, racing) | No. Add a game server: Cloudflare Durable Objects, or a host like Edgegap or Hathora |

## When to add something else

| Need | Add |
|---|---|
| Heavy SQL reporting or analytics on one project | Neon Postgres for that project |
| Large video or photo libraries | Cloudflare R2 or Stream (cheaper than Convex storage at volume) |
| Email the server sends automatically | Resend on a subdomain such as `send.codedetails.io` (free: 3,000 a month, 100 a day) |
| More than 10,000 users connected at once | Convex's Business tier |
| Fast-action multiplayer | See the table above |

## Email

- Support inbox: `support@codedetails.io` on iCloud+ with the custom domain. MX, SPF and DKIM were checked 18 October 2026. Still to add: a DMARC record at `_dmarc.codedetails.io`, starting with `p=none`.
- Apps never contain an email address. Support details live on the website, in App Store Connect and in backend settings, so they can change at any point in an app's life.
- Git commits use GitHub's private no-reply address, so no inbox is exposed in public repos.

## Backups

The backend holds little: accounts live in Clerk, and users' personal data stays on their devices. The one thing that would hurt to lose is a credit ledger, meaning what people have spent.

- No paid backup plan is needed. A free scheduled job (a GitHub Action) runs `npx convex export` every day. It encrypts the file, keeps 30 days of copies in a Cloudflare R2 bucket, and restores the latest copy into a test deployment once a month to prove it works.
- Convex Professional's managed daily backups are a convenience. Move to Professional only when its limits, logs or support are worth $25 a month.

## As an app grows

These estimates assume 20% of monthly users are active on a given day, each making about 15 backend calls.

| Monthly users | Convex | Clerk | Hosting total, including Apple's $99 a year |
|---|---|---|---|
| 1 to 10,000 | $0 to $25 | $0 | about $8 to $33 |
| 100,000 | about $25 | about $1,025 | about $1,060 |
| 1,000,000 | about $150 to $400 | about $19,000 before volume discounts | about $19,500 |

- Past about 50,000 retained users, Clerk becomes the expensive part. Then build our own sign-in: verify Apple's token once, then issue our own session token signed with our key. Convex accepts custom tokens like that, and since apps only talk to our own endpoints, the switch is one planned app update.
- **AI is the real cost.** A styling request costs about $0.002 to $0.01, and a WaveSpeed picture about $0.04. Every app needs these from day one:
  - a per-user cost cap
  - credits reserved before every paid call
  - small free allowances, with images bought as credits
  - a kill switch
  - spending caps at the provider

## Client projects

- Each client gets their own Convex team, their own Clerk application, and their own Cloudflare account. Jose is added as a member and the client pays their own bills.
- Handing a project over means making the client the owner. Their data never shares a database with Jose's projects.

## Accounts and security

- Turn on two-factor sign-in for every service above. Add the domain registrar (Key-Systems), the Google Cloud DNS account and the iCloud account, because whoever controls those controls the email.
- Use separate dev and production deployments, each with its own secrets.
- Set provider-side spending caps or budget alerts wherever they exist. Convex's Starter plan and WaveSpeed's prepaid balance can't overspend. Firebase-style "alerts only" billing is avoided on purpose.

## Considered and not chosen

- **Supabase:** real Postgres and built-in Sign in with Apple, but $25 per organization plus about $10 per extra project, and free projects pause after a week.
- **Firebase:** a strong mobile SDK and a $10 monthly Google Cloud credit with Jose's AI Pro plan, but a Google-only data model and no hard spending cap on Blaze.
- **Cloudflare D1 as the backend:** the cheapest option, and Jose already uses Cloudflare. But sign-in, real-time and vectors would be separate pieces, which goes against the goal of having one home.
