# Permissions

Phase 19b draft, 19 October 2026. Every system permission the app will ask for, the phase it arrives in, the Info.plist purpose string, what the app says before iOS asks, and what happens if Lily says no.

Rules (SECURITY_STANDARD section 4, PRD 15.4, App Review 5.1.1(ii) and (iv), 5.1.5):

- Ask only when she first uses the feature that needs it, never at launch or during onboarding.
- Show a short in-app explanation first, with **Continue** (which opens the iOS prompt) and **Not now** (which asks nothing). This avoids spending the one iOS prompt when she isn't ready.
- No pressure: no "you must", no repeated nags, no feature locked behind a permission when a manual way exists.
- Every "no" has a way forward, and the app explains how to change it later in Settings.
- Purpose strings are complete and plain. They go in the generated Info.plist through `INFOPLIST_KEY_...` build settings in `Configs/App.xcconfig`, and their words in an `InfoPlist.xcstrings` String Catalog so they can be translated. (Whether every key below has an `INFOPLIST_KEY_` build setting is to confirm; a key without one goes in `Configs/AppInfo.plist`.)
- When a feature grows, its purpose string grows with it. A string must describe every use.

Today the app asks for nothing and has no purpose strings, which is correct.

## Summary

| Permission | Info.plist key | Phase | Asked when |
|---|---|---|---|
| Camera | `NSCameraUsageDescription` | 22a (garments), widened in 33b (try-on photo) | She taps Take a photo in Add a piece, or Set up try-on |
| Photos, picking photos | None | 22a | `PhotosPicker` shows only what she picks and needs no permission |
| Photos, saving pictures to her library | `NSPhotoLibraryAddUsageDescription` | Only when a feature saves an image to Photos (to confirm which phase: a share sheet with an image offers Save Image, which needs this key) | She taps Save to Photos or Save Image |
| Location, approximate, while in use | `NSLocationWhenInUseUsageDescription`, plus `NSLocationDefaultAccuracyReduced` = `YES` | 29 | She first opens Style Me's weather row, or Home's window offers live weather |
| Notifications, local only | None (runtime request) | 34, only if purchase reminders ship | She turns on a reminder for a purchase |

**Never requested:** full photo library read access (`NSPhotoLibraryUsageDescription`), precise location, background location, microphone, contacts, calendars, HealthKit, motion, Bluetooth, local network, Face ID, App Tracking Transparency (`NSUserTrackingUsageDescription`). If a later design seems to need one, it needs Jose's approval and an update here first.

**Capabilities with no prompt** (entitlements, not permissions; listed so nothing is forgotten):

| Capability | Phase | Note |
|---|---|---|
| Data Protection, Complete | Done (1a) | Already in the entitlements |
| iCloud (CloudKit) | 20b | Her private database only. Sync is off until she turns it on in the app. `CKSyncEngine` may need the Remote notifications background mode for silent CloudKit pushes, which shows no prompt (to confirm in 20a) |
| Sign in with Apple | 24a | The Apple sheet is the consent |
| App Attest | 24a | `com.apple.developer.devicecheck.appattest-environment` |
| WeatherKit | 29 | Capability on the App ID; location still needs its own permission |
| In-App Purchase | 30a | StoreKit 2 |

On-device Vision (cutouts, face and person masking, body pose hints) needs no permission of its own.

## Camera

**Phase 22a**, for garment photos. **Phase 33b** widens it for the try-on photo taken with the in-app camera and its pose outline.

**Purpose string, 22a:**

> Take photos of your clothes to add them to your closet.

**Purpose string, from 33b:**

> Take photos of your clothes to add them to your closet, and take your try-on photo if you set one up.

No claim that photos "stay on this iPhone", because from 33a a faceless copy of the try-on photo can leave it, and photos sync to her iCloud if she turns sync on.

**Before the prompt, 22a** (a small sheet over Add a piece):

> **Take a photo of a piece**
> The app needs your camera to take the picture. The photo is saved in the app on this iPhone, without its location.
> [Continue] [Not now]

**Before the prompt, 33b** (on Set up try-on, only if camera access isn't granted yet):

> **Take your try-on photo**
> The app uses your camera to take one full-length photo with a timer. It's kept on this iPhone, and in your iCloud if sync is on.
> [Continue] [Not now]

**If she says no, or turned it off before:** Add a piece still offers Choose from photos and Describe in words. Set up try-on still offers Choose from photos. The camera button stays, and tapping it shows: "Camera access is off for Nifty Outfit Nook. You can turn it on in Settings, or choose a photo instead." with **Open Settings** and **Choose a photo**. Nothing else changes.

## Photos

**Phase 22a.** Picking garment photos, and from 33b the try-on photo, uses `PhotosPicker`, which hands the app only the photos she picks and needs no permission. The app strips location and other metadata before saving its copy (22a).

There's no pre-prompt because there's no prompt. Help's "Add a piece" topic can say: "The app only sees the photos you pick."

**Saving to Photos.** Only if a feature saves an image to her library: saving a try-on picture, or a share sheet that carries an image (the share sheet's Save Image needs `NSPhotoLibraryAddUsageDescription`, or the app can crash). Add-only access can't read her library.

**Purpose string:**

> Save the pictures you choose to your Photos library.

**If she says no:** the picture stays in the app, and the message says "Saving to Photos is off for Nifty Outfit Nook. You can turn it on in Settings." Share to other apps still works.

## Location

**Phase 29**, for WeatherKit. Approximate only (`NSLocationDefaultAccuracyReduced` = `YES`, and the app never asks for temporary full accuracy), while in use only, no background location, coordinates never stored and never sent to Convex or an AI provider (THREAT_MODEL F14, PRD 15.4).

**Purpose string:**

> Your rough location gets the forecast, so outfit ideas suit the weather. It's used only for the forecast and isn't saved.

**Before the prompt** (the first time she opens the weather row on Style Me, or taps Home's window when weather isn't set up):

> **Use the weather where you are?**
> The app asks Apple Weather for today's forecast near you. It uses a rough location, not your exact address, and doesn't keep it. Only the weather itself, like "cool and rainy", goes into Style Me.
> [Continue] [Type a city instead]

**If she says no, or turned it off before:** weather works from a city she types, or she picks the conditions herself, or she ignores weather (the use / indoors / ignore choice already in Style Me). Home's window shows the "unknown" sky. No repeated asking: the row shows "Weather: set by hand" with a way to change it. Privacy and terms has the Weather switch that turns live weather off entirely (see [IN_APP_PRIVACY_TEXT.md](IN_APP_PRIVACY_TEXT.md)).

Apple Weather attribution and its legal link show wherever forecast data does (PRD 11.5).

## Notifications

**Phase 34, only if purchase reminders ship** (PRD 13.7, FR-71). Local notifications only. No push from our server, no profile details or links in the notification text (PRD 15.4).

No Info.plist key. The app calls `requestAuthorization` only when she turns on a reminder.

**Before the prompt:**

> **Remind you about this piece?**
> The app can remind you on this iPhone when it should have arrived. The reminder only says "A piece you bought may have arrived."
> [Allow reminders] [Not now]

**If she says no:** the reminder still appears inside the app (on the piece and in its list). Nothing else changes.

If Jose later wants push notifications from Convex (STACK.md lists APNs as available), that is a new data flow and needs DATA_MAP, label and permission updates first.

## Consents that aren't iOS permissions

These are the app's own switches (named-recipient consent, PRD 15.4 and App Review 5.1.2(i)). Their wording is in [IN_APP_PRIVACY_TEXT.md](IN_APP_PRIVACY_TEXT.md).

| Consent | Phase | Recipient |
|---|---|---|
| iCloud sync | 20b | Apple, her private iCloud |
| Account (sign in) and age confirmation | 24a | Clerk, Convex |
| Garment photo naming ("Describe my photos") | 22a decides whether it exists | A named processor, if built |
| Style Me, swaps and Ask stylist | 27a | Anthropic |
| Live weather | 29 | Apple WeatherKit (paired with the location permission) |
| Improvement analytics | 31, if built | Our own backend |
| Try-on pictures | 33a | Black Forest Labs (OpenAI only with a new, separate consent if the backup is ever used) |
| Find One | 34, if built | A named search provider |
