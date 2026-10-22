# Device test checklist

Written 22 October 2026, from `SWIFT_BUILD_PLAN.md` (Progress log, Stage A through Phase 31), `THREAT_MODEL.md`, and the app repo's `docs/` (including the 33a worktree). One list of everything that needs a real iPhone. Jose runs it on his iPhone 14. Lily's iPhone 12 gets a short second pass later (last section).

How to read an item: the box, a short title, the phase it came from, and what it blocks. Then **Why** (what a simulator can't do), **Steps**, **Pass** and **Send back**. Do the groups in order. Within a group, top to bottom is cheapest first.

Items marked **[not ready]** can't be run yet because something isn't built or a helper is missing. They stay here so nothing gets lost; ask an agent to build the missing piece first.

---

## 1. Setup, once

- [ ] **1.1 Install the Debug build on the iPhone 14** (Phase 1a, 18, 22a) | Blocks: everything below
  - Why: a device is the only place Vision cutouts, Data Protection, the camera, VoiceOver and real notifications work.
  - Steps: (a) On the iPhone: Settings > Privacy & Security > Developer Mode on, restart, confirm. It must run iOS 26 or later. (b) On the Mac: in `nifty-outfit-nook`, `git checkout develop && git pull` (the local `develop` is behind GitHub). (c) `cp Configs/Signing.local.xcconfig.example Configs/Signing.local.xcconfig` and put your team ID in `DEVELOPMENT_TEAM`. Edit only that file, never Xcode's Signing tab (it writes into the public repo). (d) Open `NiftyOutfitNook.xcodeproj` in Xcode 27.1, pick scheme `NiftyOutfitNook`, pick the iPhone 14 as the destination (cable, tap Trust), press Run (Cmd-R). It builds as Debug, which is what you want: the test screens only exist in Debug. (e) If iOS says "Untrusted Developer", go to Settings > General > VPN & Device Management and trust your account.
  - Pass: the app opens on the welcome screen with no crash.
  - Send back: nothing unless the build fails; then the last 20 lines of Xcode's error.

- [ ] **1.2 Know how to pass a launch argument** (Phase 8a, 22b) | Blocks: 2.7, 2.8, 2.9, 2.10, 2.11, 2.13, 2.16, 3.x labs
  - Why: the test screens open only when the app is started from Xcode with an argument. Starting from the Home Screen ignores them.
  - Steps: Xcode > Product > Scheme > Edit Scheme > Run (left) > Arguments tab > "Arguments Passed On Launch" > **+**. Type the whole argument on one row, for example `-cutout-bench` or `-seed-photo-closet 300`. Untick the row (don't delete it) between tests so only one is on at a time. Press Run. When you're done, `git checkout -- NiftyOutfitNook.xcodeproj/xcshareddata` (the scheme is shared; never commit it).
  - Pass: with `-cutout-bench` ticked, the app opens on "Cutout benchmark" instead of the room.
  - Send back: nothing.

- [ ] **1.3 Decide how results come back** (all) | Blocks: nothing
  - Steps: for screenshots, press Side + Volume Up and AirDrop them to the Mac or add them to a chat. For text results, use the screen's Export results or Copy results, then paste into Notes or a chat. For logs, Xcode > Window > Devices and Simulators > your phone > Open Console, or copy from Xcode's debug pane.
  - Pass: you can get a screenshot and a block of text to Claude.
  - Send back: never send passphrases, tokens, keys or photos of Lily's clothes. The bench text has numbers only and no picture names.

---

## 2. No accounts needed

- [ ] **2.1 First launch, and relaunch after iOS ends the app** (Phase 17, 21a) | Blocks: nothing
  - Why: a test's `terminate()` isn't the same as iOS ending the app in the background. The old settings file also moves into the new store at the first launch.
  - Steps: fresh install (delete the app first). Do onboarding with a name, add one piece, press Home, open 10 other apps for a few minutes, come back. Then force-quit and open again.
  - Pass: the name, the piece and the "tour seen" state are all still there; no onboarding repeat.
  - Send back: "ok", or a screenshot of what was lost.

- [ ] **2.2 Private screens are hidden in the app switcher** (Phase 12b, 14a, 22a) | Blocks: nothing
  - Why: the simulator's saved snapshots were checked, but the real swipe-up switcher wasn't.
  - Steps: open Fit and measurements (and its sheets), the try-on picture screen and Profile's try-on photo sheet one by one. Swipe up from the bottom and pause to show the app switcher card each time.
  - Pass: each card shows a cover, not the measurements or pictures.
  - Send back: one screenshot of the switcher with the cover.

- [ ] **2.3 Take photo with the real camera** (Phase 22a) | Blocks: nothing (the camera path is otherwise only checked on a simulator with no camera)
  - Why: the simulator shows the camera prompt but takes no picture.
  - Steps: delete and reinstall, pick the empty closet, Add a piece > Take photo. Read the app's own sheet, tap Continue, then iOS's prompt ("Take photos of your clothes to add them to your closet."), Allow, take a photo of a shirt, Use Photo. Repeat once with Settings > Outfit Nook > Camera turned off: the alert should offer Open Settings or Choose a photo. Then try Choose from Photos with a photo that shows "Location Is Included" in the picker.
  - Pass: the piece is added with its photo; the camera-off path offers both choices; no photo-library prompt ever appears.
  - Send back: "ok" for each path, or a screenshot of any oddity.

- [ ] **2.4 Send feedback: screenshot picker and keyboard** (Phase 24d) | Blocks: nothing
  - Why: the picker's screenshot filter, a real screenshot's colour profile, the keyboard type and VoiceOver reading can't be driven by a simulator test.
  - Steps: Run with `-fake-signed-in`. Profile > Send feedback. Check the reply field offers the email keyboard. Attach a real screenshot (take one first). Send. Then switch VoiceOver on and listen to the success message; turn on airplane mode and send again for the failure message.
  - Pass: the picker shows screenshots only; the sent text matches what the page listed; VoiceOver reads both outcomes.
  - Send back: a screenshot of the preview page, "ok" for the rest.

- [ ] **2.5 Notifications while the app is in the background** (Phase 27c) | Blocks: nothing (push when closed is 3.11)
  - Why: iOS's real permission alert, Lock Screen text and tap-to-open behaviour. 27c found a real crash on tapping a notification, so check it on hardware.
  - Steps: fresh install, Run with `-cloud-stylist slow` (the fake answers after 15 seconds). Style me > Allow > Notify me > Allow in iOS's alert. Press Home. Wait 20 seconds. Look at the Lock Screen and Home Screen. Tap the notification. Then repeat, force-quitting the app mid-job and reopening.
  - Pass: it says only "Your outfit ideas are ready / Open Outfit Nook to see them."; tapping opens Your looks; no crash; after the relaunch the job finishes and the banner shows.
  - Send back: a screenshot of the Lock Screen notification.

- [ ] **2.6 VoiceOver pass** (Phase 17 and the Stage A audit) | Blocks: App Review accessibility answers (35a)
  - Why: UI tests can't run VoiceOver. Any iPhone works for this.
  - Steps: Settings > Accessibility > VoiceOver on (triple-click side button shortcut helps). Walk onboarding, Home's tour (focus should start on the card's words, not Next), Closet, Add a piece, Style Me, Profile. Also try Dynamic Type at the largest accessibility size.
  - Pass: every control is read with a sensible name, in order; nothing behind a tour's dim can be reached; focus lands back on that step's control when the tour closes.
  - Send back: a list of anything unread, read twice, or out of order, with the screen name.

- [ ] **2.7 Cutout go/no-go bench** (Phase 8a, 22a) | Blocks: **the sticker look as the main garment look (RD-07), and Phase 8b follow-ups**
  - Why: simulators can't run Vision's subject lifting ("Could not create inference context"). Only a real A-series chip gives speed, memory and quality. Full steps: app repo `docs/cutout-feasibility.md`, "Running the benchmark".
  - Steps: (a) Photograph about 20 of Lily's real garments (flat lay, hanger on a wall, bed, dark on dark, white on white, patterned, shiny, knit, shoes, a bag, one running off the frame, one with two pieces) into an album called "Cutout test". (b) Run with `-cutout-bench`. (c) Cold start first: Choose photos > the album > select all > tick. Don't run the drawn samples first. (d) Wait for "Photos done 20 of 20". (e) Tap Yes or No under "Usable as a sticker?" for every photo, judging it as Lily would see it. (f) Export results. (g) Optional: working size 1,024 and 2,048, Run again, export each. If the app is closed by iOS mid-run, note which photo it was on.
  - Pass (limits that count on Lily's iPhone 12): warm median at most 1 s, p90 at most 2 s, cold start at most 4 s, peak footprint at most 300 MB, usable as a sticker at least 70%. On the iPhone 14 the quality number counts fully. For speed and memory use tighter margins as a "likely fine on the 12" read (my suggestion, not from the docs): median 0.7 s, p90 1.4 s, cold 3 s, peak 250 MB.
  - Send back: the exported text (it includes the device model) and a screenshot of the pass/fail table. Say how many photos were No and why.

- [ ] **2.8 Scrolling and memory with a big closet** (Phase 22b) | Blocks: nothing (a slow result would change the thumbnail sizes)
  - Why: the simulator ran on the Mac's chip, which hides the cost of decoding photos.
  - Steps: Run with `-seed-photo-closet 2400 -frame-stats -auto-scroll` (one row). Wait for the seeding to finish and relaunch once (the first launch after writing 4.3 GB is slow and doesn't count). The app scrolls itself 20 seconds down and 20 back and reports frames. Do three runs: thumbnails already made, then with `-seed-photo-closet 2400 -frame-stats -auto-scroll -thumbnails off`, then a plain hand scroll for a minute.
  - Pass: hitch time under 5 ms per second (Apple's "good"), longest frame under about 50 ms, peak memory flat (the simulator held about 89 MB).
  - Send back: the on-screen numbers for each run and the peak memory from Xcode's memory gauge.

- [ ] **2.9 File protection on the store** (Phase 20a, 21a, 21b) | Blocks: the "complete protection" claims in DATA_MAP and the privacy answers
  - Why: the simulator doesn't keep protection classes. The code sets `complete` on `Nook.store`, its `-wal` and `-shm`, the migration journal and the snapshot. The Device checks screen (`-device-checks`, Debug only, built 22 October 2026 in app PR 98: pull `develop` after it merges) reads them and shows PASS or FAIL against the design.
  - Steps: (a) Run with no arguments. Pick the empty closet in onboarding (the store only keeps data for her own closet) and add 3 pieces, at least one with a photo from Choose from Photos. Scroll the closet once so thumbnails get made. (b) Stop the app. In the scheme tick only `-device-checks`, Run. (c) The top line should say `PASS: ... 0 failed`. Look at the rows Store folder, Nook.store, Nook.store-wal, Nook.store-shm, MigrationJournal.json, Photos and "Photos: files inside": each should read `NSFileProtectionComplete`. (d) Locked-phone test: leave the screen open, press the side button to lock the phone, wait one minute, unlock, tap **Read again**. Don't force-quit in between. (e) Tap **Copy report**, paste it into Notes or a chat.
  - Pass: no FAIL rows for the store group; the Locked-phone test section says `PASS: Nook.store could not be read 15 s after the lock`. If it says "unlocked before the check" or "iOS ended the app's background time", lock again and retry (it's a timing limit of the probe, not a fail). A line starting `FAIL: Nook.store could be read` is a real fail.
  - Send back: the copied report. It holds class names, counts, times and the phone model; no file names from her closet.
  - Note: on a simulator the screen says "SIMULATOR ... ignore the file results", and every row reads NO CLASS or a made-up class.

- [ ] **2.10 Protection on thumbnails, safety copies and the backups folder** (Phase 21a, 21b, 22b) | Blocks: nothing
  - Why: same reason as 2.9. Thumbnails should be `complete` and never in a backup; safety copies should be `complete` and left out of device backups; diagnostics are `completeUntilFirstUserAuthentication` on purpose (Phase 31).
  - Steps: use the same screen. Rows appear once the thing exists: Thumbnails after you scroll the closet; **Recovery (migration safety copy)** after 2.16's migration; **RestoreSafetyCopy** after a restore from a copy (2.11); **Diagnostics folder** and **Diagnostics reports.json** after one launch with `-diagnostics-lab` and a tap on Add sample reports. Then run `-device-checks` again and copy the report.
  - Pass: no FAIL rows. Each row's second half says `backup: left out` for thumbnails, safety copies and diagnostics, and `backup: included` for the store, journal and photos (the screen shows "expected ..." next to any that differ). Diagnostics rows read `NSFileProtectionCompleteUntilFirstUserAuthentication` and pass.
  - Send back: the copied report.
  - Not checkable with this screen: **Restore staging** and **Exports** are cleared at every launch, and the screen is a separate launch, so they always read NOT THERE. Skipped on purpose; their class is set in code (`BackupLocation.prepare`, `BackupArchive`) and unit-tested.

- [ ] **2.11 Export and restore at 300 and 1,000 pieces** (Phase 21b) | Blocks: sync can't switch on until restore is proven (R7)
  - Why: time, peak memory and temporary space on a real chip. The export should also carry on if she leaves the app.
  - Steps: Run with `-seed-photo-closet 300`. Profile > Backups > Export a copy, with a 12-character passphrase you'll remember (don't send it). Time it and watch Xcode's memory gauge. Check "Check a copy". Then Restore from a copy (Replace) into the same phone; use Undo restore. Try again with `-seed-photo-closet 1000`. Press Home halfway through one export. Also check how much free space the phone loses while exporting (Settings > General > iPhone Storage). AirDrop one export to a Mac and open it with `aea` and `aa` there to confirm it needs the passphrase.
  - Pass: no crash or kill; peak memory well under 400 MB; the export survives going to the Home Screen briefly; the restored closet matches; the Mac can't read it without the passphrase.
  - Send back: for each size, export time, restore time, peak memory, and the phone's storage drop.

- [ ] **2.12 HEIC for kept photos** (Phase 22a, 22b) | Blocks: nothing (storage would be about half) **[not ready: needs the option added]**
  - Why: HEIC encoding hangs on the simulator, so the HEIC test cases only run on a device.
  - Steps: ask an agent for `PhotoCleaner.Options.format` (steps in `docs/image-storage.md`, "HEIC, later"), then run `PhotoCleanerTests` and `LocalPhotoIntakeTests` on the phone with the HEIC cases on: `xcodebuild test -project NiftyOutfitNook.xcodeproj -scheme NiftyOutfitNook -destination 'platform=iOS,name=<phone name>' -only-testing:ServicesTests`. Best done in the same sitting as 2.7.
  - Pass: encode time per photo is short enough that Add a piece doesn't feel stuck; file size about half of JPEG; decode time for a 1,024 thumbnail is fine; the tests pass.
  - Send back: encode ms, file size, decode ms, and the test result line.

- [ ] **2.13 MetricKit reports** (Phase 31) | Blocks: trusting any crash or speed numbers from TestFlight
  - Why: the simulator delivers no MetricKit reports at all; the parser has only been fed sample JSON.
  - Steps: (a) Run with `-diagnostics-lab` (on `develop` only). Add the sample reports and check they show cut-down fields and none of the planted personal text. (b) While attached to Xcode, use Debug > Simulate MetricKit Payloads and look at the lab again. (c) Install the build, use the app normally, and open it again the next day (reports arrive about daily).
  - Pass: a real report shows kind, date, versions, device model, memory and counts, with no call stacks, binary names or addresses.
  - Send back: a screenshot of the lab, plus the next-day screenshot (or "none arrived after 2 days").

- [ ] **2.14 Vision head masking for try-on** (Phase 33a) | Blocks: **try-on pictures with real photos; the 33a checkpoint** **[not ready: 33a isn't built; its branch is `feature/33a-try-on`]**
  - Why: the face must never leave the phone, and the mask has to work on an A-series chip within memory. Only a Mac prototype exists.
  - Steps: when 33a lands, take or pick photos covering long, curly, afro and short hair, a three-quarter pose, a turtleneck, a scarf, a hat and a coat. Run the in-app masking step on each and look at the faceless result before anything is sent (use the "See what was sent" view). Also try a photo with no face, a hand over the face, and a very large photo.
  - Pass: the head and hair are fully grey, the room is the plain studio backdrop, and a no-face or unconfirmed photo stops with no job (fail closed). Peak memory stays low.
  - Send back: screenshots of the masked images (use test photos, not Lily's), time per photo, peak memory.

- [ ] **2.15 Keychain marker after a device-backup restore** (Phase 21b) | Blocks: sync's "fresh start on a restored phone" rule **[later, heavy]**
  - Why: a store restored from a backup must notice it came from a backup. Only a real restore shows whether the Keychain marker stays behind.
  - Steps: add some pieces, make an encrypted Mac backup (Finder), restore it to the phone (or restore from an iCloud Backup), open the app.
  - Pass: the app notices the restored store and starts sync fresh instead of trusting the old state (needs sync, so this fully completes with 3.12).
  - Send back: what the app showed after the restore.

- [ ] **2.16 A migration killed on the phone, and its speed** (Phase 20a, 21a, 21c) | Blocks: nothing
  - Why: kill tests ran on a Mac with the same frameworks; the A-series chip's timing and a real kill mid-migration weren't. The store's only real schema change so far is version 1 to 2 (Phase 21c). The Debug build is already version 2, so a helper first turns the store back into version 1 (same records) so there is a real migration to kill. Built 22 October 2026 in app PR 98.
  - Steps: (a) Get a big closet: run once with `-seed-photo-closet 2400`, wait for seeding, stop, then run `-device-checks` and note **Records** and **Fingerprint** (the store lines). Untick it. (b) **Make the old store:** tick only `-make-old-store`, Run. The app opens and closes itself in about a second; the Xcode console says `make-old-store: written(records: ...)`. If it says `migrationPending`, run once with no arguments so the recovery finishes, then try again; `alreadyOld` means it was already version 1. (c) **Kill it:** untick that, tick only `-migration-kill-at journal.migrating` (one row, as written), Run. The app should vanish at once and Xcode reports it was killed. If the app opens normally, no migration was waiting: repeat (b). (d) **Check the recovery:** untick, tick only `-device-checks`, Run. Under Store and last migration you should see: Store version on disk 2; **Records** and **Fingerprint** the same as in (a); Integrity check ok; Journal step verified; "found an unfinished migration (journal said migrating); safety copy put back: yes"; "migrated version 1 to 2". (e) Repeat (b) to (d) for each other step name: `journal.snapshotting`, `snapshot.copied`, `journal.snapshotTaken`, `migration.finished`, `journal.migrated`, `verified`, `journal.verified`. A kill at `journal.verified` or `verified` leaves a finished store, so (d) then shows no recovery line; that's fine. (f) **Speed:** do (b), then run with only `-device-checks` (no kill). "Last launch opened the store in N s" is the whole migration for 2,400 pieces, with a time after each step below it. (g) **A real force-quit:** do (b), tick only `-migration-pause-at journal.migrating 30` (waits 30 seconds there), Run, swipe the app away in the app switcher during the wait, then do (d).
  - Pass: after every kill the closet is whole: same Records, same Fingerprint, integrity ok, and it is the old store or the new one, never a mix (the screen shows version 2 and verified after recovery). Migration time under a few seconds.
  - Send back: the copied report after (d) for `journal.migrating` and for one more step, and the (f) time.
  - Note: the kill is a SIGKILL, like a force-quit. The same flag works on the restore steps (`restore.staged`, `restore.safetyCopyTaken`, `restore.photosMoved`, `restore.writing`, `restore.saved`, `restore.verified`, `undo.saved`) for 2.11, untested on a device.

- [ ] **2.17 iPad with a keyboard (only if you have an iPad)** (Phase 15b, 17) | Blocks: nothing
  - Steps: Escape closes a sheet and skips a tour; Command-F works on the first press after launch; holding Command lists Search; tabs can still be tapped while the search field is being edited with the hardware keyboard.
  - Pass: all four work.
  - Send back: "ok" or the one that fails.

- [ ] **2.18 The try-on photo camera: live hints and the timer** (Phase 33b, app PR for `feature/33b-photo-setup`) | Blocks: the 33b checkpoint
  - Why: the simulator has no camera and can't run Vision, so the hint rules were only tested with made-up readings. Real Vision readings decide whether the thresholds are right.
  - Steps: Profile, Your try-on photo, Take your photo. The first time you see the app's own explainer, then iOS's camera prompt. In the camera, one at a time: (a) stand too close, so your head or feet are cut off; (b) stand far away; (c) stand off to one side; (d) turn sideways, then face away; (e) hold your arms against your sides, then hands on hips; (f) a dim room, then a bright window behind you; (g) a second person steps in; (h) stand in place. Then: move during the countdown; switch off "Take it for me when I'm ready" and use the shutter; flip to the back camera; try long hair down, curly or afro hair, a hat and a scarf; turn VoiceOver on.
  - Pass: (a) says "Step back a little, so your whole body is in view", (b) "Step a little closer", (c) "Move to the middle of the picture", (d) "Turn to face the camera", (e) "Let your arms hang a little away from your body", (f) the light hints, (g) "Just you in the picture, please". Each shows within about a second of the change and doesn't flicker. In place, the outline turns green, it says "That's it. Hold still.", counts 3, 2, 1 and takes the photo by itself; moving stops the count. No hint mentions hair, and hats and scarves don't trigger one. The photo comes out upright and not mirrored. VoiceOver says a hint when it changes, not on every frame. Preview stays smooth, and the phone stays cool after a minute of framing.
  - Send back: every hint that was wrong, late or missing (the knobs are in `FramingGuidance.Limits`: `armReach`, `minimumShoulderShare`, `edgeMargin`, `darkest`, `backlitGap`), plus how the preview felt on the iPhone 12. Use yourself or a friend who agrees, and delete the test photos after.

- [ ] **2.19 The check before the try-on photo is saved** (Phase 33b) | Blocks: the 33b checkpoint
  - Why: the check runs the same Vision masking as try-on, and only the simulator's drawn people have been through it in tests.
  - Steps: with the camera and again with Choose from Photos, make or pick: a good full-length photo; two people; facing away; a hand over the face; a face only, no body; a dark room; a very large photo; a busy room; a hat and a turtleneck. Then turn the camera off in Settings, Nifty Outfit Nook, and tap Take your photo.
  - Pass: a good photo shows "This photo works" with Use this photo. The others show a kind reason and no way to keep them, nothing is saved, and her old photo stays. Tips (whole body, arms, light) show only when true, and the note about hats, scarves and turtlenecks is there. A photo that passed never makes a try-on refuse for a fixable reason (use 3.11 with the fake backend). Take another photo reopens the camera, and Choose another photo opens Photos. With the camera off the message says how to turn it on and offers Choose a photo.
  - Send back: any photo where the check was wrong (said fine but try-on refused, or refused but looked fine), and the check's time on a large photo on the iPhone 12.

---

## 3. Needs your setup first

- [ ] **3.1 Sign in with Apple through Clerk** (Phase 24a, 24c) | Blocks: every item that uses the real backend (3.3, 3.5 to 3.8, 3.10, 3.11)
  - Why: needs a real Apple Account and the Clerk instance. There is still no real sign-in screen for Lily (needs a design); the lab screen is the test.
  - Setup first (Jose): Clerk dashboard steps in `docs/backend-switch.md` (Apple only, JWT template named `convex`, publishable key), `npx convex login` in the backend repo, the env var, deploy to the dev deployment.
  - Steps: build with `-gateway-lab`. The Sign-in row should say "Clerk (real)". Sign in with Apple, then Who am I?, Sign out, sign in again. Also note Clerk's Keychain class (decision D11).
  - Pass: Who am I? shows an opaque ID, not your name or email; sign-out works.
  - Send back: a screenshot of the lab after Who am I?.

- [ ] **3.2 App Attest** (Phase 24b) | Blocks: **every paid action on the real backend (stylist, try-on)**
  - Why: the simulator can't attest. The real backend refuses paid work until this is on, by design.
  - Setup first (Jose): Apple Developer, turn on App Attest for `com.jsayram.niftyoutfitnook`, add the `com.apple.developer.devicecheck.appattest-environment` entitlement (`development`). Then an agent builds the backend's Apple check; set `NOOK_APP_ATTEST_MODE=apple` and `NOOK_APP_ID` on dev.
  - Steps: confirm `DCAppAttestService.isSupported` is true (iPhone 14 and 12 both should be). Run `-limits-lab`, one paid action, and a second one. Delete the app, reinstall, run again.
  - Pass: the counter goes up on each request; a reinstall registers a new key.
  - Send back: a screenshot of the limits lab after each step.

- [ ] **3.3 Network behaviour on the real backend** (Phase 26) | Blocks: nothing
  - Setup: 3.1 done and the backend on.
  - Steps: with `-gateway-lab`, start a request, then turn on airplane mode in the middle; ask again after turning it off. Switch Wi-Fi to cellular mid-request. Turn on Low Data Mode. Test an IPv6-only network (Mac Sharing > Internet Sharing with "Create NAT64 Network" on, join it from the phone).
  - Pass: the offline banner shows once; nothing is charged twice; asking again works; all four network types work.
  - Send back: "ok" per case, or a screenshot and which case.

- [ ] **3.4 WeatherKit and location** (Phase 29) | Blocks: live weather replacing the stand-in
  - Setup first (Jose): Apple Developer, Identifiers, tick **WeatherKit** (can take 30 minutes), then set `NOOK_WEATHERKIT = YES` in `Configs/Secrets.xcconfig`. Steps are in `docs/weather.md`. Signing must show WeatherKit.
  - Steps: Privacy and terms > Weather > Live weather on. Type a city. Then Use my location: read the app's explanation, then iOS's real alert, Allow; later deny it and use Open Settings. Look for Apple Weather's mark and the legal link under Home's room. Turn on airplane mode after one lookup and reopen Home.
  - Pass: real weather shows for the city and the area; Apple's mark loads in light and dark; the link opens; airplane mode shows the last forecast; only about one lookup an hour.
  - Send back: screenshots of Home with weather and of the credit.

- [ ] **3.5 Real stylist over the backend** (Phase 27a) | Blocks: Lily's quality check on her scenarios
  - Setup: 3.1, 3.2, and the Anthropic key set on dev (`NOOK_RESULT_KEY`, then `ANTHROPIC_API_KEY`, backend README).
  - Steps: Style me with consent. Then try it in airplane mode and on a weak connection.
  - Pass: looks made only of her pieces with a why line; failures fall back to Quick ideas with a reason.
  - Send back: a screenshot of the looks.

- [ ] **3.6 Feedback sent over cellular** (Phase 24d) | Blocks: nothing
  - Setup: 3.1.
  - Steps: Wi-Fi off. Send a note with a screenshot while signed in for real.
  - Pass: it arrives in the queue with a reference like `NK-7F3A9C21`; no EXIF in the stored screenshot.
  - Send back: the reference.

- [ ] **3.7 Delete my account, for real** (Phase 24c) | Blocks: App Review 5.1.1(v)
  - Setup: 3.1, plus Clerk's secret key, `NOOK_CLERK_DELETE_MODE=clerk`, a pepper, and the Apple key (or Clerk revoking the link).
  - Steps: Privacy and terms > Delete my account, read what goes, confirm, do Apple's sheet again.
  - Pass: server records, account and Apple link are gone; the phone is wiped; signing in again makes a new empty account.
  - Send back: the status screen's three steps.

- [ ] **3.8 StoreKit sandbox purchases** (Phase 30a, 30b, 30c) | Blocks: **the paywall and credit packs going live**
  - Setup first (Jose): `docs/payments.md` steps 1 to 20 (products, sandbox tester, offer codes), then steps 21 to 26 (backend `NOOK_APPSTORE_MODE apple`, Sandbox, notification URLs).
  - Steps: Settings > Developer > Sandbox Apple Account, sign in as the tester. Buy the free month, restore after a reinstall, cancel in Manage subscription, wait for a sandbox renewal (a month passes in minutes). Buy a credit pack. Refund one purchase and check Style Me then says styling access is needed.
  - Pass: access turns on and off correctly; the price, trial and first charge date shown come from StoreKit; the server and the phone agree.
  - Send back: screenshots of the paywall, a purchase and Profile's access row.

- [ ] **3.9 Offer code redemption** (Phase 30b) | Blocks: the complimentary unlock for Lily
  - Setup: an offer code (payments.md step 17), on TestFlight.
  - Steps: redeem it on the device, check "Your code is redeemed. Styling access is on.", delete and reinstall, tap Restore purchases.
  - Pass: access is on after the restore.
  - Send back: a screenshot of the redeemed message.

- [ ] **3.10 Push when the app is closed** (Phase 27c) | Blocks: nothing (the app tells her at the next launch meanwhile)
  - Setup first (Jose): APNs key and the Push Notifications capability, then an agent builds the device-token endpoint and sender (backend README, "Switching on push").
  - Steps: start a styling job, force-quit, wait. Also with the phone locked.
  - Pass: the same fixed-words notification arrives; tapping opens the looks.
  - Send back: a Lock Screen screenshot.

- [ ] **3.11 Real try-on picture end to end** (Phase 33a) | Blocks: the 33a go/no-go **[not ready: 33a isn't built]**
  - Setup: 3.1, 3.2, BFL credits; 2.14 passed.
  - Steps: make one try-on picture, check "See what was sent", and the head going back on.
  - Pass: the sent image is faceless on the studio backdrop; the result keeps her real head, neck and pose; the cost stays inside her allowance.
  - Send back: the sent image and the result.

- [ ] **3.12 iCloud sync on two devices** (Phase 21b, 20a) | Blocks: **turning iCloud on for anyone (R7)** **[not ready: the sync layer isn't built]**
  - Setup first (Jose): iCloud capability and container `iCloud.com.jsayram.niftyoutfitnook` on the App ID; two test Apple Accounts (one with Advanced Data Protection on, one nearly full); a second device (iPad or an old iPhone) signed into the same account.
  - Steps: edit offline on both, reconnect in both orders; delete a piece on one; sign out, switch account; turn sync off with and without deleting the copy; check pushes wake the app while locked.
  - Pass: different fields merge, same-field edits keep both values for review, deletes stick, and nothing uploads into a different account.
  - Send back: a screenshot per scenario and the CloudKit console's field types.

- [ ] **3.13 iCloud: ADP, quota, new phone, Delete my data** (Phase 21b) | Blocks: same as 3.12 **[not ready]**
  - Steps: with ADP on and off, check encrypted fields read back; fill the second account's storage; delete the app's data in Settings > iCloud; do "New phone from iCloud" (with progress) and a reinstall; Delete my data while the iPad is offline.
  - Pass: each event shows the planned message, no data is lost, the pending iCloud deletion runs first at the next connected launch.
  - Send back: screenshots of each message.

---

## iPhone 14 vs iPhone 12

The two have the same screen size (390 by 844 points), so layouts match. The 14 has the A15 chip and 6 GB of memory; Lily's 12 has the A14 and 4 GB. iOS ends apps sooner on the 12, so a number that looks fine on the 14 can still get killed there. Neither can run Apple's on-device model (Phase 28 uses Quick ideas and the cloud for both).

Re-check on Lily's phone later (or when she's willing to lend it for 20 minutes), memory-heavy things first:

- **2.7** the cutout bench: the official go/no-go counts only on the 12. Peak footprint, cold start and median time.
- **2.8** the 2,400-piece scroll, hitches and peak memory.
- **2.11** export and restore at 1,000 pieces: peak memory and whether iOS ends the app.
- **2.14** and **3.11** the face-masking step with a large photo, since Vision plus the image copies can peak high.
- **2.18** and **2.19** the live camera hints (frame rate, heat, memory) and the check's time on a large photo.
- **2.12** HEIC encode time, if you adopt it.
- **2.16** migration time on the A14.
- **2.13** MetricKit's memory-exit and watchdog counts over a few days of real use.
- **2.1** the force-quit relaunch, and **2.5** notifications, since the 12 is more likely to evict the app in the background.

Rule of thumb: speed margins of about 30% on the 14, and keep peak memory at about 250 MB or less for any single heavy step.
