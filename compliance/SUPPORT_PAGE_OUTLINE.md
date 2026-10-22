# Support page outline

Phase 19b draft, 19 October 2026. Outline and draft wording for https://niftyoutfitnook.pages.dev/support, which becomes the App Store Support URL. App Review 1.5 asks that the app and its Support URL give an easy way to reach the developer. STACK.md says the app itself never contains an email address, so the app links here (from Help's "Still stuck?" and from Privacy and terms) instead of printing one.

**Not published.** Jose approves it and decides when it goes live. Nothing here needs a lawyer, except the privacy request wording, which follows the privacy policy.

Keep the page short and task-based (PRD 22.3). Version 0 can go up with the privacy policy; later sections arrive with their features.

## Draft page

### Get help

> Write to **support@codedetails.io**. Tell us what you were doing, what you expected and what happened. Please don't send your measurements, photos of yourself or your closet details; we don't need them to help.
>
> In the app, Send feedback (Profile, or the middle desk drawer on Home) shows exactly what will be sent before you send it.
>
> We usually answer within **[Jose to decide, for example 3 working days]**.

Until Phase 24d, Send feedback opens the share sheet and she picks where it goes. From 24d (built against mocks, 22 October 2026) it reaches the private support queue when she is signed in, with an optional reply address, an optional screenshot and optional closet counts; signed out it still uses the share sheet. The app's Send feedback page has a Support page row that opens this page (address from `NOOK_SUPPORT_URL`; make this page live at that address, and give the App Store the same Support URL). Say on the page: a note with no reply address can't be answered.

### Your subscription (from 30a)

> - **Cancel or change:** open Settings on your iPhone, tap your name, then Subscriptions, then Nifty Outfit Nook. Or in the app: Profile, Styling access, Manage subscription.
> - **Refunds:** Apple handles refunds. Go to reportaproblem.apple.com.
> - **New phone or reinstalled:** in the app, Profile, Styling access, Restore purchases.
> - **Free unlock code:** Profile, Styling access, Redeem code. Redeeming a code doesn't cancel a subscription you already have.
> - **Picture credits** don't expire, and work after a subscription ends.
> - Deleting your data or the app doesn't cancel a subscription.

The navigation paths are placeholders until 30a builds the screens.

### Your data and privacy

> - **Delete everything:** Profile, Privacy and terms, Delete my data. It removes everything from this iPhone and your private iCloud copy. With an account, Delete account also removes what our server holds.
> - **Turn a feature off:** Profile, Privacy and terms. Each switch stops future sending for that feature.
> - **Ask for a copy, a correction or deletion** of what we hold: email support@codedetails.io with the subject "Privacy request". We may ask you to confirm the request from inside the app.
> - Full details: [Privacy policy](/privacy).

### Common questions

> **Does it work offline?** Your closet, looks, suitcases and making your own looks work offline. Style Me, swaps, Ask stylist, weather and try-on pictures need a connection.
>
> **Which iPhones and iPads?** iOS and iPadOS 26 or later. On iPhone 15 Pro and newer, some styling can run on the phone itself; other models use the online stylist.
>
> **Is my closet backed up?** Only if you turn on iCloud sync, or export a backup in Profile. Deleting the app deletes the copy on this iPhone.
>
> **Why does a try-on picture not fit like the real thing?** Try-on pictures are simulations made by AI. They show the look, not the real fit.
>
> **Where did my face go in "See what was sent"?** That's the point: your face never leaves your phone. The app covers it before sending and puts it back afterwards.

Each answer is published only once its feature ships, and says only what the app really does (PRD 22.3).

### Report a styling problem

> If the stylist says something hurtful, wrong or strange, use Report styling problem on the result, or write to us. We read every report.

Arrives with 27a (PRD 15.5).

### Security

> Found a security problem? Email support@codedetails.io with the subject "Security", or use private vulnerability reporting on the app's GitHub repository. Please don't post it publicly.

The app repo already has SECURITY.md and private vulnerability reporting on.

### What changed

Link to release notes (PRD 22.2), from the first public release (35b).

### Accessibility

> The app follows your iPhone's text size, VoiceOver, Reduce Motion and dark appearance settings. If something doesn't work for you, tell us.

Only claims that Phase 35a's accessibility audit confirms.
