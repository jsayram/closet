# Questions for a lawyer

Phase 19b draft, 19 October 2026. Questions to bring to a lawyer who knows US consumer privacy law, so the review is short and focused. SECURITY_STANDARD section 9 and PRD 24.2 require this review before launch. These notes are our understanding, not legal advice; every "we think" below is for the lawyer to confirm or correct.

**Facts to give the lawyer** (one page, from DATA_MAP.md and THREAT_MODEL.md):

- A free iPhone and iPad wardrobe app with a monthly subscription and picture credits (StoreKit). US App Store only at launch, adults 18+ (PRD 24.2). One user today (Lily, the developer's partner), outside testers later, then the public.
- Kept on the device and the user's private iCloud: closet photos, height, body measurements, optional weight, fit notes, today's comfort (neutral clothing wording such as "more room at the waist"), try-on photo, looks. The developer has no copy.
- Sent only with per-feature consent: styling text to Anthropic (no identity, kept up to 30 days, longer if flagged, processed anywhere); a faceless body photo on a plain backdrop and garment photos to Black Forest Labs, which may keep them and train on them; sign-in through Clerk (processed anywhere); purchases, consent records, usage and support notes in Convex (US region expected); encrypted backups in Cloudflare R2.
- Face detection and masking run on the phone with Apple Vision. The face never leaves the phone.

**Priority:** "Before testers" means before anyone other than Lily uses real data. "Before launch" means before the public App Store release (Phase 35a).

## 1. Who the operator should be (before launch)

Jose would publish as an individual unless advised otherwise. App Review 5.1.1(ix) says apps that "require sensitive user information should be submitted by a legal entity that provides the services, and not by an individual developer."

- Does this app's data (measurements, weight, body photos) count as "sensitive user information" in Apple's sense, so it should be published by a company?
- Should Jose form an LLC anyway, for liability? What name and address must the privacy policy and App Store listing show?

## 2. Body measurements, weight and comfort as health data (before testers)

- Do height, body measurements, weight, fit notes about the body, or today's comfort count as **consumer health data** under Washington's My Health My Data Act (RCW 19.373), Nevada's SB 370, or Connecticut's consumer health data rules? Washington's law has no revenue or user-count threshold and a private right of action (our understanding, to confirm).
- If yes: do we "collect" it when it stays on the user's phone and in her own iCloud and we never receive it? Does sending a measurement to Anthropic inside a styling request count as collecting and sharing?
- What would we need: a separate consumer health data privacy policy page, separate consent to collect and to share, a ban on geofencing, and so on?
- Product choice that depends on the answer: Jose has to decide before Phase 27a whether measurements and weight go to Anthropic at all. If keeping them on the phone avoids most of this, we'd like to know.

## 3. Apple's rule on health information in iCloud (before testers)

App Review 5.1.3(ii): apps "may not store personal health information in iCloud." Our plan syncs measurements and optional weight to the user's private CloudKit database (end-to-end encrypted only if she has Advanced Data Protection).

- Is weight, or are body measurements, "personal health information" for this rule? Apple decides at review, but how would a lawyer read it?
- Should weight and measurements be left out of sync? (PRD 24.2 already says to remove a prohibited sync before launch.)

## 4. The faceless body photo and on-device face detection as biometric or sensitive data (before testers)

- Is a body photo with the head and hair masked, on a plain backdrop, "biometric data" or "sensitive data" under Illinois BIPA, Texas CUBI, Washington's biometric law (RCW 19.375), Colorado's biometric rules, or the state comprehensive privacy laws? It can still show body shape, skin, tattoos or birthmarks.
- Apple Vision detects the face on the phone to mask it, and the try-on setup may keep Apple's hair and skin mattes on the device. Is detecting a face to hide it "collecting a biometric identifier" when nothing leaves the phone and nothing identifies anyone? Does keeping the mask outline matter?
- Should the App Store label also declare "Sensitive Info"? We currently think not (APP_STORE_PRIVACY_LABELS.md).

## 5. Black Forest Labs keeping and training on try-on photos (before testers)

Jose accepted BFL's standard API terms (D1): BFL gets a "perpetual, irrevocable, worldwide" right to use inputs and outputs, including to train. The app discloses it in the consent screen: "A photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models."

- Is that wording, with an explicit opt-in and "See what was sent", adequate notice and consent under state laws and the FTC Act?
- Is giving BFL these rights a **"sale"** or **"sharing"** of personal data, or of sensitive data, under the CCPA/CPRA, Texas's TDPSA (which, as we understand it, needs consent to sell sensitive data even for small businesses), or other states? Does that change "we never sell your data" in our policy?
- Is BFL a processor or a third party here? Do we need a data processing agreement with BFL, and does its standard API offer one?
- Can a user grant BFL the rights its Service Terms take, through our consent screen? Must our terms pass through BFL's usage policy?
- BFL's privacy policy (revised 1 August 2026) offers a training opt-out by email to privacy@blackforestlabs.ai. Does that apply to API inputs, given the Service Terms? If it does, should we use it?
- App Review 5.1.1(i) asks us to confirm third parties give "the same or equal protection" as our policy. Does stating BFL's terms plainly meet that?

## 6. Which state privacy laws apply at this size (before launch)

- CCPA/CPRA: we think we're under every threshold (revenue, 100,000 consumers, selling or sharing). Confirm, and say what changes if question 5 makes BFL a "sale".
- CalOPPA applies to any app with California users regardless of size (our understanding). What must the policy include (effective date, Do Not Track wording)?
- Other state comprehensive laws: which, if any, apply at a few hundred or a few thousand users?
- What rights process should we offer anyway, and in how many days must we answer?

## 7. Users outside the US (before any expansion)

- If the App Store is US-only, are we outside GDPR and the UK GDPR? What if an EU resident downloads it anyway with a US Apple Account?
- If we expand: Article 9 special category data (health, biometrics), explicit consent as the lawful basis, an Article 27 representative, transfer mechanisms for Clerk, Anthropic and BFL (BFL GmbH is in Germany and has an EU endpoint).

## 8. Processing outside the US (before testers)

Clerk says data may be processed anywhere in the world. Stylist requests are pinned to US-only inference (Jose, 20 October 2026), on Haiku 5.5 (stored in the US), with support to be confirmed in 27a. BFL has a US-only endpoint we plan to use (to confirm in 33a).

- Do we need to say anything beyond what the policy says now?
- Does any US state law restrict sending health or biometric data abroad?

## 9. Age, children and age-verification laws (before testers)

PRD 24.2: adults 18+, US only.

- What age check is enough before cloud features: a self-declaration, or Apple's age-range signals (Declared Age Range API)? PRD 24.2 asks for the minimum (no birth date, no ID, no guessing age from photos).
- Do the state "app store accountability" laws (Utah, Texas, Louisiana; their current status and dates are to confirm) put duties on us as a developer?
- COPPA: we aren't child-directed. What do we do if we learn a user is under 13, or under 18?
- Age rating: should we pick the 18+ rating outright because the terms say 18+? BFL's privacy policy says its services aren't directed at under-18s.

## 10. Subscription and auto-renewal laws (before launch)

Apple runs billing, cancellation and refunds.

- What do California's automatic renewal law (amended effective 2025) and similar state laws still require of us: specific paywall wording, express consent, renewal reminders, an online cancellation path, notice of price changes? Does Apple's flow satisfy any of them for us?
- Status of the FTC's negative option rule (to confirm) and what ROSCA requires.
- The free one-month trial: required wording.
- Non-expiring picture credits: any state gift-card or stored-value rules?

## 11. Terms of use (before launch)

- Keep Apple's standard EULA and add service terms, or write our own EULA?
- Disclaimers and liability limits that hold up for consumers; arbitration or not; governing law.
- Who owns try-on pictures and outfit suggestions, given BFL's terms and Anthropic's?
- The AI limits wording: not fit advice, not medical, simulated pictures.

## 12. How long to keep records (before launch)

- Consent receipts, the usage ledger (kept after data deletion so limits can't be reset), purchase records, deletion records and security logs: what periods are lawful and enough? PRD 15.4 leaves these as "the lawful minimum".
- Is keeping a pseudonymous usage record after a deletion request allowed under deletion rights?

## 13. Breaches (before launch)

- Which notification laws apply to what we hold (state breach laws, New York SHIELD)?
- Does the FTC Health Breach Notification Rule apply to an app that holds body measurements on the device (we think not, because we don't hold them and aren't a health record app)?
- What should the incident plan in Phase 25b say about notifying users and regulators?

## 14. Anthropic (before testers)

- Is Anthropic's 30-day retention, and up to 2 years for flagged content, adequately disclosed by our consent screen?
- Does Anthropic's commercial terms' data processing addendum cover us, or do we need to sign something?

## 15. Lily's details in the public planning repo (before launch)

Jose accepted the risk (R1, D8e): the public planning repo quotes Lily and includes some of her details. Is there any legal exposure once the app is a commercial product, and should anything be removed before launch?

## 16. AI laws (before launch)

- Do any state AI laws apply to a styling chatbot and generated try-on pictures of the user (for example Utah's AI disclosure law, California's AI transparency law; scope and thresholds to confirm)?
- Do generated pictures of a real person (the user herself, with her consent) need a label or watermark under any law?
