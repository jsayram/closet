# In-app privacy text

Phase 19b draft, 19 October 2026. The real wording for Privacy and terms (Profile, and the bottom desk drawer on Home) and for each consent switch, staged by the phase that brings the feature. The app spells "colour" the British way, so these do too.

Each switch arrives with the feature it controls, because a switch with nothing behind it controls nothing (app `docs/settings.md`). The words must always match what the app sends: when a phase changes a request, its text here changes in the same PR, along with DATA_MAP.md, the labels and the policy.

**Not in the app yet.** The app repo is unchanged. The 19b block is ready to drop into `PrivacyText` in `Features/Settings/Privacy/PrivacyScreen.swift` when Jose says go.

## Phase 19b: the screen as it should read now

The current screen is accurate except for two lines. Changes:

1. The try-on line under "Later, sent only if you allow it" still describes the old plan ("your try-on photo"). Since D1 (19 October 2026), only a faceless copy leaves the phone and it goes to Black Forest Labs. Replace it.
2. "The full privacy policy and terms are still being written." becomes the policy date once the pages are live.

**Banner** (unchanged):

> This is a test build. It has no account, the app sends nothing, and there's no tracking or analytics.

**Stays on this iPhone** (unchanged list and note).

**Later, sent only if you allow it**

> None of these is in this test build. Each will ask first, and allowing one never allows another.

| Row | Detail |
|---|---|
| Style Me and swaps | Piece names, kinds and colours, the occasion and the weather, when you tap Style me. Never your photos or your name. |
| Try-on pictures | A photo of your body, without your face and on a plain backdrop, and that look's piece photos, only when you tap Try it on. Your face never leaves your iPhone. |
| Weather | A rough location for the forecast, from the city you pick or, if you turn it on, where you are. Never your exact address. |

The Style Me line stays silent on measurements until Jose decides in 27a (see the README). If measurements will never be sent, add "or your measurements" after "photos".

**Policies**, once the pages are published:

> Privacy policy · Terms of use. On the website.
> Last updated [date of the published version].

Before they're published, keep today's note.

## The pattern for every consent

Each consent is a sheet that opens the first time she uses the feature, and a switch in Privacy and terms afterwards. Same shape every time:

> **[Feature] sends [what] to [company]**
> What's sent: …
> Never sent: …
> What [company] does with it: …
> [Allow] [Not now]
> You can turn this off any time in Privacy and terms.

- **Allow** and **Not now** have equal weight; neither is preselected (App Review 5.1.1(iv)).
- Turning a switch off says: "[Feature] is off. Nothing more will be sent. What you already have stays in the app."
- Turning a switch on from Privacy and terms shows the same sheet first.
- A change of company, or of what's sent, shows the sheet again before the next request (PRD 15.4).
- Each Allow writes a consent receipt with the text version (PRD 15.4, DATA_MAP consent receipts).

## Phase 20b: iCloud sync

Not one of the six switches in `docs/settings.md`, but it's a choice about where data goes, so it gets the same care.

**Switch:** iCloud sync

**Sheet:**

> **Keep a copy in your iCloud?**
> Your closet, photos, looks and fit go to your private iCloud, so they're on your other devices and come back if you change iPhones. Only your Apple Account can reach it; we can't.
> Apple can read most iCloud data unless you've turned on Advanced Data Protection in Settings. With it on, your measurements, notes and photos are end-to-end encrypted.
> It uses your iCloud storage.
> [Turn on sync] [Not now]

The ADP sentence states accepted risk D8(a). Phase 20b's design (app repo `docs/decisions/0004-backup-and-recovery.md`) encrypts everything the app puts in iCloud, so the finished sheet says "With it on, everything the app puts in iCloud is end-to-end encrypted, apart from the names of record types and their dates and sizes." While weight, measurements, fit notes and the try-on photo are kept out of sync (LEGAL_QUESTIONS question 3, 0004 decision 2), the sheet adds "Your measurements, weight, fit notes and try-on photo stay on this iPhone." and drops "and fit" from the first line.

**Off:** "Sync is off. This iPhone keeps everything. Your iCloud copy stays until you delete it in Delete my data."

## Phase 22a: photos (only if "Describe my photos" is built)

Phase 22a (20 October 2026) left the cloud garment-naming aid out: nothing about a photo leaves the phone. Whether it ever exists is Jose's decision. If it does, it gets its own switch and names its own company. Draft, kept for that case, with the company left open:

> **Describe my photos sends one garment photo to [company]**
> What's sent: the photo of the piece you choose, without its location.
> Never sent: your other photos, your try-on photo, your name.
> What [company] does with it: [their terms].
> [Allow] [Not now]
> You can always name pieces yourself.

## Phase 24a: account and age

**Section in Privacy and terms:** Account

> **Signed in with Apple** (or **Not signed in**)
> You only need an account for online features like Style Me. Your closet works without one.

**Sign-in sheet** (before the Apple sheet):

> **Sign in for online features**
> Online features need an account so your purchases and limits follow you. You'll sign in with Apple. We ask Apple for no name [and no email].
> What we keep: a private account ID, the features you've allowed, your usage and purchases. Not your closet, photos or measurements.
> Who holds it: Clerk runs sign-in; our server keeps the rest. Clerk may process data outside the US.
> [ ] I'm 18 or older.
> [Continue with Apple] [Not now]

The age line follows PRD 24.2 (adults only, minimum check). The lawyer may change it (LEGAL_QUESTIONS question 9). "[and no email]" depends on D6. The "outside the US" sentence states accepted risk D8(c).

**Sign out:** "You're signed out. Your closet is still here. Online features need you to sign in again."

## Phase 24c: delete account

**Built 21 October 2026, against the fake sign-in and fake backend.** Not a third scope inside Delete my data, as first drafted here: a separate **Delete my account** row in Privacy and terms, under Delete my data, shown only while she's signed in. It opens the same two-step screen (what goes, then one question), with Apple's sign-in sheet after the question. Delete my data (this iPhone only) is unchanged.

The screen as built:

> **Delete my account.** Deletes your account and everything the app keeps for you, on the server and on this iPhone.
>
> What's deleted: **What the app's server keeps** (how much you've used the stylist and try-on, and sign-in records; anything still running is stopped) · **Your account** (your sign-in to the app, on every device) · **Sign in with Apple** (the link between your Apple Account and this app) · **Your iCloud copy** (only if sync was ever on) · then the six parts Delete my data lists, with their counts.
>
> Afterwards: You're signed out and the app starts fresh, as if it were just installed. Signing in again later makes a new, empty account.
> Deleting your account doesn't cancel a subscription. If you have one, cancel it in the Settings app: tap your name, then Subscriptions.
> Copies you exported stay where you saved them. Requests the stylist and try-on already sent are kept by those services for the time the privacy policy says, and then deleted.

The question: "Delete your account?" / "Your account, everything the app's server keeps for it, and everything in the app on this iPhone will be deleted. Apple will ask you to confirm it's you. This can't be undone." Buttons: **Delete my account**, Cancel.

How it can end, in her words:

- Nothing deleted (Apple's sheet closed: back to the screen, no message; offline: "Nothing was deleted. You're offline: connect to the internet and try again."; server trouble: "Nothing was deleted. The app's server couldn't take the request. Try again in a moment.").
- All done: the app starts fresh, as after Delete my data.
- The server still finishing: "Everything on this iPhone is deleted and you're signed out. Still being deleted on the server: Your account. It finishes on its own; you don't need to do anything." with a Done button.
- The Apple link couldn't be removed: "The app couldn't remove its Sign in with Apple link. To remove it, open the Settings app, tap your name, then Sign in with Apple."

**Still to do:** the "providers" sentence names no company yet; when 27a and 33a ship it should name only the ones she used, as planned: "Anthropic deletes styling requests within 30 days (longer if flagged), and Black Forest Labs may keep try-on photos it received." Phase 30 adds a Manage subscription link and checks for an active subscription. The privacy policy states what the backend keeps after a deletion (DATA_MAP, "What account deletion reaches"): a deletion record with a pseudonymous ID for 35 days and usage counts under a keyed hash for 31 days, so deleting can't reset an allowance.

## Phase 24d: feedback

**Reply address field**, optional:

> Reply address (optional). We'll use it only to answer this note.

**What's sent** line, when the queue replaces the share sheet:

> This note goes to the app's private support inbox. Never your closet, photos, measurements, looks or name.

## Phase 27a: Style Me, swaps and Ask stylist

**Switch:** Style Me, swaps and Ask stylist

**Sheet**, version A (if measurements are never sent):

> **Style Me sends your request to Anthropic**
> Anthropic makes Claude, the AI that suggests your outfits.
> What's sent, when you tap Style me, swap a piece or ask the stylist: short descriptions of the pieces involved (kind, colour, fabric, the names you gave them), the occasion, the weather (like "cool and rainy"), any note you type, and your recent looks so ideas don't repeat.
> Never sent: your photos, your name, your measurements or weight, your location.
> What Anthropic does with it: doesn't use it to train its models, and deletes it within 30 days. If its safety checks flag a request, it can keep it for up to 2 years. It may be processed outside the US.
> [Allow] [Not now]
> You can turn this off any time in Privacy and terms.

**Sheet**, version B (if measurements are sent): replace the "What's sent" and "Never sent" lines with:

> What's sent: … plus your height and any measurement that matters for this request, like your inseam for trousers.
> Never sent: your photos, your name, your weight, your location.

Requests may be processed outside the US (D5, Haiku 5.5, global processing allowed), so the consent text keeps the line "It may be processed outside the US." Recheck the 30-day and 2-year figures when 27a starts.

**If she says Not now:** Style Me explains: "Style Me needs your OK to send your request to Anthropic. You can still make your own looks." with **Review** and **Make my own look**.

**Built in 27a (21 October 2026, against a fake backend; nothing is sent yet):** version A, word for word, as consent version `stylist-1` (app `docs/decisions/0008-cloud-stylist.md`). The switch sits in a Style Me group in Privacy and terms once the cloud stylist is on, with the detail "Piece descriptions, the occasion and the weather go to Anthropic when you ask. Never your photos, name, measurements or location." and, when off, "Style Me is off. Your closet, saved looks and making your own looks still work." Not now leaves "Style Me needs your OK" with **Review** and **Back to Style Me** (there's no Make my own look button on Your looks yet; Make your own look is on Saved Looks). Two notes for review: the text lists fabric, which the app has no field for and doesn't send; and changing the words, or the recipient, needs a new version, which the server checks.

## Phase 29: weather

**Switch:** Live weather

**Sheet:** the location pre-prompt in [PERMISSIONS.md](PERMISSIONS.md), then iOS's prompt.

**Detail under the switch:**

> A rough location goes to Apple Weather for the forecast. It isn't saved. Only the weather goes into Style Me.

**Off:** "Live weather is off. You can type a city or set the weather yourself."

**Built in 29 (the words as shipped):** the group has Live weather, City ("Needs no permission."), Use my location ("Rough location only, and only while the app is open. Your city is used when this is off."), the note "Location is off for this app in Settings, so the weather uses your city." with an Open Settings row, and Apple Weather's credit. While Live weather is off the group says "Live weather is off. Home's window stays plain and Style Me doesn't use the weather." While it is on, the banner at the top says a rough location goes to Apple Weather. While WeatherKit isn't switched on for the build, it says the weather is a sample and nothing is sent. The city sheet says the name she types goes to Apple Maps and only a rough point is kept. (Typing a city also needs Live weather on, so the "Off" line above is shortened accordingly.)

## Phase 30a: before paying

Not a privacy switch, but the paywall's disclosure lines, from PRD 14.1:

> 1 month free, then [localized price]/month. Renews automatically until you cancel.
> Includes: [styling allowance] and [picture allowance] each month.
> Your closet, looks and export stay free, even if you stop paying.
> Cancel any time in your Apple Account settings.
> [Restore purchases] · [Redeem code] · [Terms of use] · [Privacy policy]

Final wording with 30a and the lawyer (LEGAL_QUESTIONS question 10).

## Phase 31: analytics (only if built)

**Switch:** Help improve the app (off by default)

**Sheet:**

> **Help improve the app?**
> If you turn this on, the app sends simple events, like "Style Me finished", with the app version and a random ID you can reset. That shows us what works and what breaks.
> Never sent: what you type, your photos, measurements, closet, looks or location.
> Kept for 30 days, then only totals.
> Turning it off changes nothing else in the app.
> [Turn on] [Not now]

**Under the switch:** Reset analytics ID · Delete my analytics data.

## Phase 33a to 33c: try-on pictures

**Switch:** Try-on pictures

**Sheet** (first time she taps Try it on with a real try-on photo set up):

> **How try-on pictures work**
> Your face never leaves your iPhone. Before anything is sent, your iPhone covers your head and hair and puts you on a plain studio backdrop. If it can't do that, nothing is sent.
>
> **A photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models.**
>
> They send back the dressed picture, and your iPhone puts your face back in. The finished picture is saved only on your iPhone (and your iCloud if sync is on). Our server keeps neither.
>
> Never sent: your face, your room, your measurements, your notes, your name.
> We can't delete copies Black Forest Labs keeps.
> Each picture shows "See what was sent", so you can check exactly what left your iPhone.
> [Allow] [Not now]
> You can turn this off any time in Privacy and terms.

The bold sentence is the approved D1 wording, word for word. If the OpenAI backup is ever used, it gets its own sheet naming OpenAI, never a silent switch.

**First-run walkthrough captions (33c)**, then the loading screen on every try-on:

> Hiding your face
> Swapping in a studio backdrop
> Dressing you
> Putting you back together on your phone

If a step fails, the screen stops there and says which step, for example: "Your face couldn't be hidden in this photo, so nothing was sent. Try a photo where you face the camera."

**Under every try-on picture:**

> See what was sent
> Your face never leaves your phone. A photo of your body, without your face and on a plain backdrop, and your clothing photos go to Black Forest Labs, who may keep them and use them to improve their models.

**Off:** "Try-on pictures are off. Nothing more will be sent. Your pictures stay in the app. Black Forest Labs may keep what it already received."

## Phase 34: Find One (only if built)

Written when the shopping direction is settled. It names the search provider and sends garment intent only, never body data or photos (PRD 13.2).

## Privacy and terms, fully built

For reference, the order of the screen once every phase has shipped:

1. Short summary line: "Your closet stays on your iPhone. Each feature below sends something only if you turn it on."
2. Stays on this iPhone (list).
3. Account (24a).
4. Sent only if you allow it: Style Me, swaps and Ask stylist (27a) · Try-on pictures (33a) · Live weather (29) · Describe my photos (22a, if built) · Help improve the app (31, if built). Each a switch with its one-line detail.
5. iCloud sync (20b).
6. Your data: Export a copy (21b) · Delete my data (and account, 24c).
7. Policies: Privacy policy · Terms of use, with the date.
