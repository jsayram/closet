# Paywall, picture packs and running out of pictures

Status: prototype, 5 October 2026. Everything here is simulated. Prices, allowances and pack sizes are sample values, not decisions; PRD §14 keeps final pricing open until image costs are measured. Nothing talks to the App Store and nothing is charged.

## Turning it on

The screens are off by default so they don't interrupt other testing. Turn on **Demo Controls › Styling access › Paywall and purchases**, then pick an access plan in the same section. Lily's default plan is owner-sponsored, which never sees a paywall, so choose "Not subscribed", "Expired" or "Monthly styling access" to see each screen.

Launch arguments do the same for scripted runs: `-purchasesDemo`, `-plan <trialEligible|trialActive|subscribed|complimentary|sponsored|expired>` and `-purchaseSheet <paywall|imagePacks|outOfPictures>`.

With the toggle off, a blocked action explains itself and links to Styling Access, as before.

## The three screens

| Screen | When it appears | What it shows |
| --- | --- | --- |
| Paywall | Tapping Style Me, "See plans" on a blocked picture, or Start free trial in Styling Access, without a plan | What the plan includes with its limits, a dated timeline of the free month, the price line under the button, Restore, Redeem code, Terms and Privacy |
| Picture packs | "Get more pictures" in Styling Access, or from the out-of-pictures screen | The included and bought balances, three sample packs with a per-picture price, and the total on the buy button |
| Out of pictures | "See options" on a picture that can't start because the month's allowance is used | How many were used, the date more arrive, picture packs, and keeping the board |

A lapsed subscriber gets the same paywall without the free month: the timeline says the first charge is today.

## What is disclosed before any confirm button

App Review guideline 3.1.2 asks for these to be clear before purchase. Each is on screen without opening anything unless noted.

- **Price and period:** "$9.99 a month" under the button, and in the timeline with the first billing date.
- **Free trial:** its length, that nothing is charged today, the date billing starts, and that it continues unless cancelled.
- **What she gets and its limits:** Style Me requests a day, On Me pictures a month, swaps a day, Find One. Styling is never called unlimited.
- **How to cancel:** "Cancel anytime" under the button; the route (Settings › Styling Access › Manage subscription, or the App Store account) is in Billing details.
- **Restore, Terms of Use and Privacy Policy:** links in the footer. Terms and Privacy are placeholders until the legal pages exist.
- **What stays free:** the "Always free" row.
- **Picture packs:** the number of pictures, the price, that it is a one-time purchase and not a subscription, that bought pictures don't expire, and that there are no automatic top-ups. Packs are consumable, so there is no Restore on that screen.
- **Confirmation:** each buy button opens a stand-in for the App Store sheet that repeats the price and says nothing is charged in the prototype.

## Rules the prototype follows (PRD §11.6, §14)

- Included monthly pictures are used before bought ones.
- Bought pictures don't expire and keep working if the subscription ends.
- Reusing an earlier picture never uses a picture.
- Nothing is charged automatically when an allowance runs out.
- Sponsored use isn't counted and never sees these screens.

## What other apps do

Checked on Mobbin, 5 October 2026.

- **A dated trial timeline** (today, reminder, first charge) with "you won't be charged today": [Headspace](https://mobbin.com/screens/17e4ce60-0851-40be-92af-336be1220857), [Vocabulary](https://mobbin.com/screens/32238af5-552f-4ac3-bede-16981f4c23d3), [Mesh](https://mobbin.com/screens/60db255e-0f7c-4caf-a0a5-4d91c0aa8740), [Pillow](https://mobbin.com/screens/73a2cafa-d97e-477b-9e00-1e276ef50151).
- **The price line directly under the button**, with Restore, Terms and Privacy below it: [Vocabulary](https://mobbin.com/screens/32238af5-552f-4ac3-bede-16981f4c23d3), [Jomo](https://mobbin.com/screens/355c903b-4580-4f82-bd8f-0c46195fa434), [Pillow](https://mobbin.com/screens/73a2cafa-d97e-477b-9e00-1e276ef50151).
- **Packs as a short list with a per-unit price and the total on the button:** [Tinder](https://mobbin.com/screens/382971b4-39d0-4f3b-8bd9-11290c501ebc), [Bumble](https://mobbin.com/screens/74c16a07-96f0-4188-816f-eab65b1aecb7).
- **Plan credits and bought credits shown as separate balances:** [Perplexity](https://mobbin.com/screens/de44dc45-bff5-4886-a7bc-13061cba2856). [Anything](https://mobbin.com/screens/f66acae2-91e6-4212-8090-f3140f5bcb62) states up front that unused credits carry over.

## Still to decide

- The monthly price, the number of included pictures and the pack sizes and prices.
- Whether the reminder before the trial ends is a notification, and whether she can switch it off.
- Whether a pack can be bought without ever subscribing.
- An annual plan, which would add a plan picker to the paywall.
- The outfit editor's Update Preview still only explains a blocked picture; it doesn't open these screens yet.
