# Terms of use outline

Phase 19b draft, 19 October 2026. Outline and draft wording for https://niftyoutfitnook.pages.dev/terms. PRD 24.1 asks the terms to cover service scope, fair use, AI limits, cancellation and refund routes, complimentary access and the user's rights, without overriding Apple's purchase flow or anyone's legal rights. Apple's subscription rules (Schedule 2 of the Apple Developer Program License Agreement, referenced by App Review 3.1.2(c)) need a working link to the terms in the app and in the App Store metadata once subscriptions ship.

**Not published.** Most of this document needs a lawyer before public launch; the sections that need it most are marked **[Lawyer]**. For Lily's internal TestFlight, the terms page can stay short (version 0 below).

## Apple's standard licence or our own

Apple applies its Licensed Application End User License Agreement (the "standard EULA") to every app unless the developer supplies its own in App Store Connect. Two options:

1. **Keep Apple's standard EULA** for the app licence, and publish our terms as additional service terms (AI, purchases, acceptable use). Simpler, and the standard EULA already covers Apple's required points.
2. **Our own EULA** in App Store Connect. Apple publishes minimum terms a custom EULA must include (to confirm the current document).

Suggestion: option 1, with our terms page saying it applies alongside Apple's standard EULA. **[Lawyer]** to confirm.

## Version 0 (TestFlight, now)

> These terms are for the test version of Nifty Outfit Nook. It's a test build with sample data. It may change, break or lose what you add, so don't rely on it for anything you can't redo. It sends nothing from your iPhone. Please send problems and ideas through Send feedback. Full terms come before the app is offered to anyone else.

## Draft sections (release)

### 1. Who and what

> These terms are between you and **[operator, to confirm]**, the maker of Nifty Outfit Nook ("we"). By using the app, you agree to them and to Apple's standard licence for apps from the App Store. Our privacy policy explains what happens to your data.

### 2. Who can use it **[Lawyer]**

> You must be 18 or older and live in the United States, where the app is offered. You can use your closet without an account. Online features need you to sign in with Apple and confirm you're 18 or older.

PRD 24.2 sets adults 18+ and a US-only launch. The age method is a legal question (LEGAL_QUESTIONS question 9).

### 3. What's free and what's paid

> Your closet, looks, suitcases, laundry, making your own looks, search, iCloud sync and export are free and stay free, even if you stop paying. Paying gets you the AI stylist (Style Me, swaps, Ask stylist) and, if offered, try-on pictures, within the limits shown in the app.

Matches PRD 14.1. Wording finalised with the paywall in 30a.

### 4. Subscription, trial and cancelling **[Lawyer]**

> The subscription is monthly and renews automatically until you cancel. If you're eligible for the free trial, it lasts one month, then the monthly price shown in the app is charged. Apple bills you, and you cancel or manage the subscription in your Apple Account settings, at least 24 hours before the renewal date to avoid the next charge (to confirm Apple's current wording). Deleting the app or your data doesn't cancel it. Refunds are handled by Apple under its rules.

**[Lawyer]** State automatic-renewal laws (for example California's, amended for 2025) may require specific wording, consent and reminders on top of what Apple's sheet shows (question 10).

### 5. Free unlock codes

> We may give some people a code for free ongoing access. A code is used once. Redeeming it doesn't cancel a subscription you already have; cancel that in your Apple Account. Codes can't be sold.

PRD 14.2.

### 6. Picture credits

> If you buy picture credits, they don't expire, and you can use them for try-on pictures even after a subscription ends. Credits have no cash value and can't be transferred. A picture that fails or isn't delivered doesn't use credits. A delivered picture uses its credits even if you don't like it.

App Review 3.1.1 bars purchased credits from expiring. PRD 14.4 sets the delivery and refund rules. Wording finalised in 30b.

### 7. Fair use and limits

> AI features have limits so the service stays affordable and fair: a number of requests per day or month, shown in the app. We may pause a feature for everyone if a provider fails or costs spike, and we'll say so in the app. Your closet keeps working.

PRD 11.6, kill switches (24b).

### 8. What the AI can and can't do

> Outfit ideas and try-on pictures are suggestions made by AI. They can be wrong. A try-on picture is a simulation: it doesn't show how a piece will really fit, and it isn't a photo of you wearing it. Fit notes are guidance, not a sizing guarantee. Nothing in the app is medical, health or weight advice.

PRD 15, 15.5.

### 9. Your content

> Your photos, notes and looks are yours. You give us only the permission we need to run the features you turn on, such as sending a styling request to Anthropic or a try-on photo to Black Forest Labs, as the privacy policy describes. If you use try-on, Black Forest Labs may keep the faceless photo and your clothing photos and use them to improve their models; you agree to that when you turn try-on on.

**[Lawyer]** Whether a user can grant the rights BFL's Service Terms take (perpetual, sublicensable) through our consent screen, and what our terms must pass through: BFL's Service Terms ask that end-user terms be "at least as restrictive as the FLUX Usage Policy" (quoted for video generation; whether it applies to images is to confirm). Also who owns try-on outputs (question 11).

### 10. Rules for using the app

> Use only photos of yourself and of clothes you own or are allowed to photograph. Don't upload photos of other people, of anyone under 18, or nude or sexual images. Don't try to get around limits, copy the service, or use the app to break the law. If you post on the public feedback board, be kind: no harassment, body shaming or personal details.

SECURITY_STANDARD section 7 (only the user's own photo), PRD 22.1 (board rules, only if the board is built).

### 11. Feedback

> If you send an idea, we can use it to improve the app without owing you anything.

### 12. Changes, ending and availability

> We may change or stop features. If we stop the app, we'll give notice in the app where we can, and you can still export your closet. You can stop using the app any time and delete your data in the app. We may close an account that breaks these terms.

### 13. Disclaimers and limits of liability **[Lawyer]**

Standard "as is" disclaimer and limitation of liability, written by the lawyer within what consumer law allows.

### 14. Disputes and governing law **[Lawyer]**

Which state's law, which court, and whether to use arbitration. No suggestion here; this is the lawyer's call.

### 15. Apple

> Apple isn't responsible for the app or these terms, and doesn't provide support for it. Apple and its subsidiaries can enforce Apple's standard licence against you.

Apple's standard EULA already says most of this. **[Lawyer]** to confirm what's needed if we keep option 1.

### 16. Contact

> support@codedetails.io. Support page: https://niftyoutfitnook.pages.dev/support
