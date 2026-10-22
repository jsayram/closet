# App Store privacy labels

Phase 19b draft, 19 October 2026. These are the answers for App Store Connect's App Privacy questionnaire (App Store Connect, the app, App Privacy), staged by the phase that changes them. They must match [PRIVACY_MANIFEST.md](PRIVACY_MANIFEST.md), the privacy policy and what the app really does. Phase 35a checks them against the shipped build.

Definitions are Apple's, from https://developer.apple.com/app-store/app-privacy-details/ (read 19 October 2026):

- **Collect** means sending data off the device in a way that lets us or a third-party partner keep it longer than it takes to answer the request. Data sent to our server and thrown away straight after isn't collected. Data handled only on the phone isn't collected.
- **We aren't responsible for disclosing data collected by Apple.** So her private iCloud sync, WeatherKit's location lookup, Sign in with Apple itself, StoreKit's payment sheet and Xcode Organizer crash reports aren't in our answers.
- **Linked** means tied to her identity. Apple's page adds that "Personal Information" and "Personal Data" as defined under privacy laws count as linked. A faceless body photo is still personal data (STACK.md), so it is answered as linked.
- **Tracking** means linking our data with other companies' data for advertising, or sharing it with a data broker. We never do either, so every "used for tracking" answer is **No**.

## Today (Stage A, internal TestFlight)

The app sends nothing, so the honest answer is **"No, we do not collect data from this app."** Internal TestFlight doesn't need the questionnaire filled in. Whether external TestFlight needs it is **to confirm** when outside testers are near. The App Store submission in 35b does.

## Answers by phase

Each row is cumulative: once a phase adds a data type, it stays for every later phase.

| Phase | Data type (Apple's category: type) | Collected? | Linked to her? | Tracking? | Purposes | What and where |
|---|---|---|---|---|---|---|
| Up to 23b | None | No | | | | Everything stays on the phone or in her private iCloud (Apple's collection) |
| 24a | Identifiers: User ID | Yes | Yes | No | App Functionality | Clerk user ID and the Apple user ID Clerk holds; our principal ID in Convex |
| 24a | Identifiers: Device ID | Yes (cautious; **to confirm** whether an App Attest key counts) | Yes | No | App Functionality | App Attest key ID, public key and counter in Convex, used to stop cloned apps and fraud |
| 24a, only if decision D6 needs it | Contact Info: Email Address | Yes | Yes | No | App Functionality | The address Clerk gets from Apple, likely a private relay address. If Clerk works without one, leave this out until 24d |
| 24d | User Content: Customer Support | Yes | Yes | No | App Functionality | Notes sent with Send feedback (her words and an optional screenshot), kept 90 days after the ticket closes, or 180 days if never closed. Optional: Contact Info (email address) only if she gives a reply address; Diagnostics-style app and device details only if she turns them on; the closet's size as three numbers only if she ticks it. Linked to her account (deleted with it) |
| 24d | Contact Info: Email Address | Yes | Yes | No | App Functionality | The optional reply address she gives with a note |
| 24d, only if the public board is built | User Content: Other User Content | Yes | Yes | No | App Functionality | Public ideas and votes under an alias |
| 27a | User Content: Other User Content | Yes | Yes | No | App Functionality | Styling requests to Anthropic (piece descriptions, occasion, weather conditions, notes, recent looks), which Anthropic keeps up to 30 days; the 24-hour result cache in Convex |
| 27a, only if sent | Health & Fitness: Health | Yes | Yes | No | App Functionality | Body measurements, weight or today's comfort, if Jose decides they go into cloud requests (see the README). Whether Apple counts body measurements as "Health" is **to confirm**; answering Yes is the cautious choice if any of them leave the phone |
| 29 | None new | | | | | Location goes to Apple's WeatherKit from the device (a rounded coordinate, from a city she picked or, if she turns it on, her approximate location); the words of a city search go to Apple Maps. Convex and Anthropic get a weather summary only (condition, temperatures, chance of precipitation). Her city and choices stay on the iPhone. Not our collection, so no location type is declared. Revisit if a coordinate or city is ever sent to our backend |
| 30c | Purchases: Purchase History | Yes | Yes | No | App Functionality | Transactions, entitlements and credit ledger in Convex. Payment details stay with Apple |
| 31, only if opt-in analytics ship | Usage Data: Product Interaction | Yes, or optional to disclose (see below) | No | No | Analytics | Allowlisted events with a resettable ID never joined to her account |
| 31, only if our own crash reporting ships | Diagnostics: Crash Data, Performance Data | Yes | No | No | App Functionality | Only if crash or performance payloads go to our backend. Xcode Organizer alone needs no answer |
| 33a | User Content: Photos or Videos | Yes | Yes | No | App Functionality, **Other Purposes** | The faceless body photo on a plain backdrop and the selected garment photos, sent to Black Forest Labs, which may keep them and use them to improve its models |
| 34, only if Find One ships | Search History, and possibly Other User Content | Decide in 34 | Decide in 34 | No | App Functionality | Garment search intent through Convex to a search provider |

**Optional disclosure for analytics.** Apple lets a "product improvement program" go undeclared if it is opt-in with two clear choices, doesn't change features or price, can be changed any time in settings, isn't linked to her identity, isn't used for tracking, and isn't used for advertising, personalization or other purposes. PRD 23's analytics plan meets all of these on paper. Declaring it anyway is simpler and costs little; Jose decides in Phase 31.

**Optional disclosure for feedback.** Apple's general optional-disclosure test needs her name or account name shown on the submission form. Our feedback form doesn't show one, so feedback doesn't qualify and is declared.

## How the label will read at release

If everything planned ships (measurements sent, analytics built, no Find One), the store page shows:

- **Data Used to Track You:** none.
- **Data Linked to You:** Purchases; Contact Info (email address); User Content (photos or videos, customer support, other user content); Identifiers (user ID, device ID); Health & Fitness (health).
- **Data Not Linked to You:** Usage Data (product interaction).

## The try-on disclosure in the label

D1 asks for plain disclosure in the App Store privacy label. The label has **no free-text field**: Apple shows only categories and purposes. So, in the label, the disclosure is:

1. Photos or Videos answered as collected and linked.
2. Its purposes include **Other Purposes**, because Black Forest Labs may use the photos to improve its models. That's BFL's purpose, not ours. Apple's purpose list has no "third party trains on it" option, and Analytics and Product Personalization are about our own use, so Other Purposes is the honest fit.
3. The plain words live in the try-on consent screen, the privacy policy and "See what was sent", which the label points to through the privacy policy link.

Suggestion for Jose: also add one plain line to the App Store description once try-on ships, such as "Try-on pictures: your face stays on your iPhone. A photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models." That puts the disclosure where people read before downloading.

## Other App Store Connect fields that touch privacy

| Field | Answer | When |
|---|---|---|
| Privacy Policy URL | https://niftyoutfitnook.pages.dev/privacy | Page drafted in 19b, published when Jose approves, required by 35b |
| User Privacy Choices URL (optional) | https://niftyoutfitnook.pages.dev/privacy#your-choices, the policy section on switches, deletion and requests | 35b |
| Support URL | https://niftyoutfitnook.pages.dev/support | 35b (page drafted in 19b) |
| Age rating | Answer the questionnaire honestly for the shipped features, then apply the higher rating if our terms set 18+ (PRD 24.2). See [LEGAL_QUESTIONS.md](LEGAL_QUESTIONS.md) question 9 | 35a |
| Export compliance (`ITSAppUsesNonExemptEncryption`) | `NO` today. Recheck in 20b when the export archive is encrypted with CryptoKit | 20b |
| EU Digital Services Act trader status | Required declaration even for a US-only launch | 35b |

## Keeping it true

- Any phase that adds a request, a processor or a stored field updates this file, the manifest and DATA_MAP.md together (definition of done).
- A processor change (for example BFL to the OpenAI backup, or Haiku to a US-pinned model) is checked here too. The categories may not change, but the policy text will.
- Phase 35a compares the answers with a proxy capture of the release build's traffic.
