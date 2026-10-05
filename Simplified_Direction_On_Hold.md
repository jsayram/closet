# Simplified first-release direction (on hold)

Status: recorded 5 October 2026, not started. The owner asked to hold this and keep it on file. Nothing in `My_Petite_Style_PRD_v2.md` or the prototype has been changed for it.

This file holds two things as the owner gave them: the rationale for a simpler first release, and the brief describing the changes. The last section lists what has to be decided before work starts and what in today's prototype it would affect.

## Rationale

We are simplifying My Petite Style's first release to reduce implementation risk, operational complexity and unpredictable AI spending while preserving the app's core value: helping users create useful outfits from their own wardrobe.

The original PRD combines several substantial systems: local wardrobe management, iCloud recovery, AI styling, personal-image generation, shopping, subscriptions, purchased credits and community feedback. Each is manageable individually, but their interactions create many failure cases and testing obligations. The goal is a smaller, dependable release, not weaker security or recovery.

### Why one subscription instead of purchased credits

Purchased credits create a durable financial wallet. We would need to recover balances across devices, reconcile purchases and refunds, prevent duplicate grants or deductions, and handle credits reserved by interrupted image jobs.

A monthly subscription with separate text and image allowances removes the separately purchased wallet. Users get predictable pricing and understandable limits, while the developer retains control over expensive requests.

This does not mean unlimited AI or eliminate billing complexity. We still need verified subscriptions, renewal/refund handling, atomic usage reservations and reliable job reconciliation. Pricing and allowances must follow measured costs rather than guesses.

### Why Sign in with Apple

Persistent cloud functionality needs a recoverable identity so the backend can associate access, allowances, pending jobs and restrictions with the correct account across devices.

Sign in with Apple avoids building our own password and password-recovery system. It provides a familiar authentication experience without requiring a public profile or unnecessary personal details.

Keep local wardrobe features available without login. Introduce authentication at the cloud-service boundary, explain its actual customer benefits, and review whether mandatory login is justified under Apple's rules. Do not assume API costs alone justify requiring an account.

Identity, payment and consent are separate:

- Authentication establishes who is requesting service.
- Verified entitlements establish whether they have access.
- Consent establishes what personal data may be sent to which AI provider.

### Why Supabase and a small administration interface

Supabase consolidates backend authentication, database records and server-side functions. AI providers still run externally; their credentials stay in backend secrets, never in the iPhone app.

A small restricted administration interface is enough initially to grant sponsored access, suspend abusive AI usage and inspect operational status. Lily's access becomes a reusable grant on her verified account, not a special app build or an unlimited spending exception.

Supabase does not automatically make the system secure. We must implement and test authorization, RLS policies, rate limits, spending controls and administrative audit records.

### Why one text provider and one image provider

Every additional provider adds integration, consent, capability and failure-handling differences. Start with one validated provider for each purpose and keep replaceable backend adapters.

This preserves future flexibility without building complex routing before we understand real usage. Compatible provider changes can happen behind stable app contracts, but new capabilities or consent requirements may still require app changes.

### Why defer shopping automation and the public feedback board

Shopping introduces external-data uncertainty, fit evidence, changing availability and purchase-tracking workflows. A public feedback board introduces moderation, abuse handling and additional account/data responsibilities.

Neither needs to delay validation of the core wardrobe-styling experience. Record them as deferred scope, not abandoned ideas. Keep private support available.

### What we must preserve

Do not reduce complexity by weakening recovery, purchase verification, privacy, deletion, spending limits or honest AI claims. Keep local features usable offline and after subscription expiration.

Virtual try-on remains important to Lily. Validate it early, but launch only the garment combinations and workflows that demonstrate acceptable fidelity, privacy and cost. A smaller launch must still deliver the experience she actually values.

### Success criterion

The direction is successful if users can manage their wardrobe freely, understand cloud access and allowances, recover their account and data, and receive dependable styling results, while the developer can operate the service with bounded costs and manageable support.

Use this rationale to guide PRD and implementation decisions. Distinguish genuine reductions in scope from responsibilities that remain mandatory.

## The brief

Update My Petite Style's PRD and existing iOS/iPadOS prototype to reflect the simplified architecture below. Read the authoritative PRD and inspect the existing screens, navigation, storage and service interfaces before editing. Implement the changes, not just a proposal.

### Product and backend

- Use Supabase for backend authentication, AI gateway functions, service secrets, access entitlements, usage accounting and durable AI-job records.
- Keep the wardrobe local-first, with optional private iCloud sync. Signing into Supabase must not automatically upload the closet.
- Start with one cloud text provider and one image provider behind replaceable backend adapters. Do not build sophisticated automatic provider routing.
- Defer purchased AI credit packs, shopping automation and the public feedback board. Preserve existing work without presenting deferred features as available.
- Keep any disabled service clearly distinguished from a functioning integration.

### Local access

- Users can add and browse clothes, search, manage Suitcases, create manual outfits and save looks without an app account, subscription or internet connection.
- Subscription expiration, logout or AI restrictions must not remove local wardrobe access or saved results.
- Purely on-device AI does not inherently require cloud authentication.

### Sign in with Apple

- Introduce native Sign in with Apple when users enter account-based cloud AI functionality, not as mandatory initial onboarding.
- Use Apple's identity proof to authenticate through Supabase Auth and obtain a persistent backend user ID and session.
- Do not require a public profile, custom password or unnecessary personal information.
- Identify users and assign access by verified internal user ID, not name or email.
- Support returning-user login, session refresh, cancellation, failure, revoked authorization, logout and in-app account deletion.
- Recover backend access and allowances across reinstall and iPhone/iPad when the same existing account is authenticated.
- Keep backend identity recovery separate from wardrobe/iCloud recovery.
- Authentication is not proof of purchase or permission to upload personal data.
- Document the App Review justification for any required cloud login. Do not claim Apple approval is guaranteed or unnecessarily gate purchasing/restoration behind registration.

### Subscription and allowances

- Offer one monthly AI subscription, with separate recurring text-styling and image/try-on allowances.
- Do not offer purchased credits, top-ups or an unlimited-AI promise in the initial release.
- Keep pricing and allowance quantities configurable and unresolved until actual service costs are measured. Do not invent final commercial terms.
- Verify StoreKit transactions and relevant server events on the backend. Never trust a client-provided "paid" flag.
- Define renewal, expiration, cancellation, refund and revocation behavior explicitly.
- Use backend-authoritative allowance periods. Logout, reinstall or switching devices must not reset usage.
- Reusing saved results must not consume new allowance.
- Running out of allowance blocks new relevant cloud requests, not local features or saved content.

### Lily and sponsored access

- Support an administrator-issued sponsored grant associated with Lily's verified user ID.
- Sponsored access must not initiate a subscription or charge Lily.
- Keep developer-funded usage bounded by configurable safety limits and a separate owner budget.
- Allow the same grant mechanism to support other approved users later.
- Do not hard-code Lily's identity or privileged credentials into the app.

### Paywall and account screens

- Update the existing paywall, cloud-AI entry flow and Settings to match this model and the current design language.
- Show the subscription price, billing period, actual included allowances, renewal terms, Restore Purchases, subscription management, privacy and terms.
- Show separate remaining text and image allowances and their next reset dates.
- Cover signed-out, signed-in/unsubscribed, subscribed, sponsored, exhausted, restricted, offline, loading and verification-failed states.
- Sponsored users must see their access status without an unnecessary purchase prompt.
- Preserve pending requests through authentication/purchase where safe, but never dispatch a paid AI job unexpectedly.
- Simulated pricing, authentication and entitlements must be clearly labeled in the prototype.

### Security and reliability

- Keep AI-provider secrets and privileged Supabase keys exclusively on the backend.
- Verify sessions, entitlements, consent, request bounds and budgets before dispatch.
- Enforce atomic allowance reservations, concurrency limits, bounded retries, idempotency and global spending circuit breakers.
- Finalize usage only under a documented successful-delivery rule; release reservations for technical failures.
- Reconcile ambiguous pending jobs rather than blindly issuing duplicate paid requests.
- Keep personal-photo consent separate from text-styling consent.
- Retain existing privacy, deletion, fidelity and recovery requirements for features that remain enabled.
- Restrict administrative grants and AI suspensions to authorized server-side operations with an audit trail.

### PRD, implementation and verification

- Update conflicting PRD requirements, architecture, monetization, acceptance criteria, delivery phases and open decisions consistently.
- Clearly record what is retained, simplified or deferred. Do not silently remove safeguards.
- Reuse existing provider-neutral contracts and mock-service patterns.
- For the prototype, simulate authentication, purchases, allowances and failures without real charges or personal uploads.
- Implement live services only when the required configuration and authorization are available; report missing integrations honestly.
- Test access-state transitions, sponsored access, restore flows, exhausted allowances, failed jobs and cross-device accounting.
- Verify updated screens on iPhone and iPad for layout and accessibility.
- Finish with a concise summary of changes, tests run and remaining production decisions.

## Before this starts

Two decisions are open, because the brief conflicts with earlier standing instructions for the prototype work:

1. **How the PRD changes.** The standing rule has been to leave `My_Petite_Style_PRD_v2.md` untouched and write changes as separate amendment proposals. The brief asks for the PRD itself to be updated. One option that satisfies both is a new v3 file that carries the changes, with v2 kept as it is.
2. **Supabase as the backend.** The standing rule has been not to select production providers. The brief names Supabase. The text and image AI providers stay unnamed behind adapters either way.

The prototype would stay fully simulated in any case. No credentials or backend exist in this repo.

## What it would affect in today's prototype

- **Picture packs:** built on 5 October behind the "Paywall and purchases" demo toggle (`Docs/Purchases.md`). They become deferred: the code stays, the screen stops being offered, and the out-of-pictures screen loses its "See picture packs" button.
- **Paywall and Styling Access:** keep the single monthly plan; show text and image allowances separately, each with its own reset date; add the signed-out, restricted, offline, loading and verification-failed states.
- **Sign in with Apple:** new. Today the prototype has no app account for styling; only the feedback board has a simulated sign-in.
- **Sponsored access:** today it is a plan value set in Demo Controls and the default for the demo profile. It would become a grant attached to a simulated account ID.
- **Find One shopping and the feedback board:** both are working demos today. They would be marked as not available yet, with private support kept.
- **PRD sections touched:** at least §9.2 (image providers), §11.6 (allowances and cost protection), §13 (shopping), §14 (monetization, including packs and offer-code complimentary access), the FR table (FR-23, FR-29, FR-36 and the shopping and feedback rows), delivery phases and open decisions.
