# Privacy manifest plan

Phase 19b draft, 19 October 2026. This plans the app's `PrivacyInfo.xcprivacy` (in the app repo at `NiftyOutfitNook/PrivacyInfo.xcprivacy`) from today until release. It must always agree with [APP_STORE_PRIVACY_LABELS.md](APP_STORE_PRIVACY_LABELS.md): the manifest's collected data types and the App Store Connect answers describe the same behaviour.

**Status: draft for Jose's 19b checkpoint.** Nothing in the app repo was changed.

## Sources checked today

- Required-reason API categories and reason codes: Apple's `NSPrivacyAccessedAPIType` and `NSPrivacyAccessedAPITypeReasons` reference pages (developer.apple.com, bundleresources, app-privacy-configuration), read 19 October 2026. Every code below was copied from those pages.
- Collected data type and purpose keys: Apple's `NSPrivacyCollectedDataType` and `NSPrivacyCollectedDataTypePurposes` reference pages, read the same day.
- What counts as "collected", "linked" and "data collected by Apple": https://developer.apple.com/app-store/app-privacy-details/, read the same day.

Apple updates these lists. Re-check them when each phase below starts, and again in Phase 35a.

## What the app uses today

Scanned on `develop` at commit `d44562e` (the app repo's Swift sources, `Configs/`, the entitlements file and `Package.swift`).

| Question | Answer today |
|---|---|
| Third-party SDKs in the app | None. `swift-snapshot-testing` (and what it pulls in) is linked by test targets only (`Package.swift`) |
| Network calls | None. The only web content is the policy pages, opened in `SFSafariViewController`, which loads them outside the app |
| Tracking, IDFA, ATT | None |
| `UserDefaults` | Yes. `AppStateDefaults` keeps app state flags, the sign name and three Style Me settings in the app's own suite (`com.jsayram.niftyoutfitnook.appstate`). Not an App Group. Reason `CA92.1` is already declared |
| File timestamp APIs (`creationDate`, `modificationDate`, `contentModificationDateKey`, `stat` and the rest) | None found |
| System boot time (`systemUptime`, `mach_absolute_time()`) | None found. `ContinuousClock` is used to time the cutout (`VisionCutoutService`); it isn't on Apple's list. If an upload warning ever names boot time, declare `35F9.1` (to confirm only if Apple flags it) |
| Disk space APIs (`volumeAvailableCapacity...Key`, `systemFreeSize`, `statfs` and the rest) | None found |
| Active keyboards (`activeInputModes`) | None found |
| Permission-gated frameworks | `PhotosUI` (`PhotosPicker`) and `UIPasteboard` appear only in the debug-only cutout benchmark, which `scripts/check-release.sh` keeps out of Release. `PhotosPicker` needs no permission anyway |
| `utsname` (device model for "Include app details" in feedback) | Not a required-reason API. Only sent when she turns that switch on and shares the note herself |
| Info.plist purpose strings | None (correct: nothing asks for a permission yet) |
| Entitlements | Data Protection `NSFileProtectionComplete` only |
| `ITSAppUsesNonExemptEncryption` | `NO` |

**Result: today's manifest is already correct.** No change is needed in Phase 19b.

### Today's `PrivacyInfo.xcprivacy`

This is the file as it stands in the app repo, and what it should stay until Phase 22b.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>CA92.1</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

## Rules that never change

- `NSPrivacyTracking` stays `false` and `NSPrivacyTrackingDomains` stays empty. The app has no ads, no IDFA, no data brokers and no cross-company linking (PRD 23, SECURITY_STANDARD section 4). If that ever changes, it needs a new review first.
- Each reason code is used only for what Apple's text allows. For example, `C617.1` and `E174.1` say the information may not be sent off the device, so file dates and free space never go into feedback, analytics or any request.
- Apple's own frameworks (SwiftUI, SwiftData, CloudKit, WeatherKit, StoreKit, Vision) carry their own manifests. We declare only our own calls and our own collection.
- A third-party SDK must bring its own manifest. The app can't declare an SDK's API use for it.

## Required-reason APIs, by phase

| Category | Reason code | What Apple's code allows | Why we'd need it | Phase | Status |
|---|---|---|---|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | Read and write defaults only this app can access | App state flags, sign name and Style Me settings. From 21a most of these move into the real store, but onboarding and tour flags may stay in defaults | 17 (done) | **Declared today** |
| `NSPrivacyAccessedAPICategoryUserDefaults` | `1C8F.1` | Defaults shared within an App Group | Only if an extension (a widget, a share extension) is ever added. None is planned | None planned | Not needed |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | Timestamps, size or other metadata of files inside the app container, an App Group container or the app's CloudKit container | Image cache eviction by age, measuring how much space her photos and try-on pictures take (PRD 15.3 asks to show it), cleaning up staging and temporary files | 22b | Add in 22b if any listed API is used (likely) |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `3B52.1` | Metadata of files she picked through a document picker | Restore from an export file she picks in Files, if restore reads the file's size or dates before importing | 21b | Add in 21b only if restore reads them |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `DDA9.1` | Show file timestamps to her | Only if a screen shows a file's date, such as "Exported on" read from the file itself. Prefer storing the date in the record instead | 21b | Probably not needed |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `E174.1` | Check there's enough space to write files, or that space is low so the app can delete files; the app must behave differently in a way she can see | Checking free space before a migration's safety copy, a photo import, an export, a restore or a try-on job, and pausing with a message when it's low (PRD 15.3, 9.2.4) | 21a, 21b, 22b | Add in 21a: the migration coordinator checks free space (Phase 20b) |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `85F4.1` | Show disk space to her | Only if a screen shows the iPhone's free space (for example "You need 1.2 GB free; you have 800 MB") | 21b, 22b | Add with that screen, if built |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | Measure time between events in the app, or run timers | Only if code calls `systemUptime` or `mach_absolute_time()` directly. Network timeouts and retries (26) can use `ContinuousClock` and `URLSession` instead | 26 | Not expected |
| `NSPrivacyAccessedAPICategoryActiveKeyboards` | none | | The app never reads active keyboards | Never | Not needed |

Phase 31 added no required-reason API. The diagnostics file uses `FileManager` to write and delete one file and `URLResourceValues.isExcludedFromBackup`, and reads no timestamps, boot time, disk space or defaults. (Checked 22 October 2026 against Apple's required-reason API list.)

`7D9E.1` and `3D61.1` (disk space or boot time in a bug report she chooses to send) are deliberately not planned: feedback carries only the app version, iOS version and model identifier, and only when she turns "Include app details" on.

## Collected data types, by phase

"Collected" here means Apple's definition: sent off the device in a way that lets us or a third-party partner keep it longer than it takes to answer the request. Apple also says developers aren't responsible for disclosing data collected by Apple. So her private iCloud sync, WeatherKit's location lookup, Sign in with Apple itself and Xcode Organizer crash reports aren't our collection. Data processed only on the phone (cutouts, face masking, the on-device stylist) isn't collected either.

Each row matches a row in [APP_STORE_PRIVACY_LABELS.md](APP_STORE_PRIVACY_LABELS.md). "Linked" follows Apple's note that personal data as defined by privacy laws counts as linked.

| Data type key | What it is for us | Linked | Tracking | Purposes | Phase |
|---|---|---|---|---|---|
| `NSPrivacyCollectedDataTypeUserID` | Clerk user ID, the Apple user ID Clerk holds, our styling principal ID | Yes | No | `AppFunctionality` | 24a |
| `NSPrivacyCollectedDataTypeDeviceID` | App Attest key ID, public key and counter, stored in Convex with her principal. Apple's definition is "other device-level ID"; an App Attest key is per install, so whether it counts is **to confirm**. Declaring it is the cautious choice | Yes | No | `AppFunctionality` | 24a |
| `NSPrivacyCollectedDataTypeEmailAddress` | Only if Clerk needs an email from Apple (decision D6, likely a private relay address), or if she gives a reply address with feedback | Yes | No | `AppFunctionality` | 24a (if D6 needs it), 24d |
| `NSPrivacyCollectedDataTypeCustomerSupport` | Feedback and support notes in the Convex support table, kept 90 days after closure | Yes | No | `AppFunctionality` | 24d |
| `NSPrivacyCollectedDataTypeOtherUserContent` | Styling requests to Anthropic (piece descriptions, occasion, weather conditions, notes, recent looks), kept by Anthropic up to 30 days, and the normalized result cached in Convex for 24 hours under her principal. Public board posts too, if 24d builds the board | Yes | No | `AppFunctionality` | 27a (24d if board) |
| `NSPrivacyCollectedDataTypeHealth` | Only if body measurements, weight or today's comfort go into cloud styling requests. Whether they do is an open decision before 27a (see the README). Whether Apple counts measurements as "Health" is **to confirm** | Yes | No | `AppFunctionality` | 27a, only if sent |
| `NSPrivacyCollectedDataTypePurchaseHistory` | Subscription, complimentary unlock and credit-pack transactions, entitlements and the credit ledger in Convex | Yes | No | `AppFunctionality` | 30c |
| `NSPrivacyCollectedDataTypePhotosorVideos` | Try-on: the faceless body photo on a plain backdrop and the selected garment photos, sent to Black Forest Labs, which may keep them and use them to improve its models (D1) | Yes | No | `AppFunctionality`, `Other` | 33a |
| `NSPrivacyCollectedDataTypeProductInteraction` | Opt-in improvement analytics with a resettable ID never joined to her account. **Phase 31 did not build it**, so nothing is declared. Declare it only if Jose approves building the PRD 23 pipeline | No | No | `Analytics` | Not built |
| `NSPrivacyCollectedDataTypeCrashData`, `NSPrivacyCollectedDataTypePerformanceData` | The crash and speed summary a support note carries when she turns on "Share crash and speed details" (counts, timings and fixed names from MetricKit; no stacks, text or IDs), stored with the ticket in Convex. Xcode Organizer crash reports stay Apple's collection | Yes (with the ticket) | No | `AppFunctionality` | 31 |
| `NSPrivacyCollectedDataTypeSearchHistory` | Find One's garment search intent through Convex to a search provider, only if Phase 34 ships | To decide in 34 | No | `AppFunctionality` | 34, only if built |

Not collected at any phase, and not to be declared: name (the sign name never leaves the phone; we ask Apple for no name), phone, physical address, payment info (Apple handles payment), precise or coarse location (coordinates go only to Apple's WeatherKit; Convex gets conditions), contacts, browsing history, advertising data, sensitive info (to confirm with the lawyer for the faceless body photo, see [LEGAL_QUESTIONS.md](LEGAL_QUESTIONS.md) question 4), and anything synced to her private iCloud.

## Planned release manifest

Draft of the full file once every planned feature has shipped, assuming measurements are sent in 27a, Phase 31 sends no analytics and Find One doesn't. Each block carries the phase that adds it. Remove the blocks for features that don't ship.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<!-- Phase 17 -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryUserDefaults</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array><string>CA92.1</string></array>
		</dict>
		<!-- Phase 22b (3B52.1 only if 21b restore reads picked-file metadata) -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array><string>C617.1</string></array>
		</dict>
		<!-- Phase 21b or 22b -->
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryDiskSpace</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array><string>E174.1</string></array>
		</dict>
	</array>
	<key>NSPrivacyCollectedDataTypes</key>
	<array>
		<!-- Phase 24a -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeUserID</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 24a (to confirm whether App Attest keys count as Device ID) -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeDeviceID</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 24d (and 24a if Clerk needs an email) -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeEmailAddress</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 24d -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeCustomerSupport</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 27a -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeOtherUserContent</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 27a, only if measurements, weight or comfort are sent -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeHealth</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 30c -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypePurchaseHistory</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Phase 31: the crash and speed summary a support note carries when she turns it on -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypeCrashData</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypePerformanceData</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array><string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string></array>
		</dict>
		<!-- Opt-in analytics (ProductInteraction, Analytics) is not built in Phase 31: no block until Jose approves it -->
		<!-- Phase 33a: Black Forest Labs may keep and train on these (D1) -->
		<dict>
			<key>NSPrivacyCollectedDataType</key>
			<string>NSPrivacyCollectedDataTypePhotosorVideos</string>
			<key>NSPrivacyCollectedDataTypeLinked</key>
			<true/>
			<key>NSPrivacyCollectedDataTypeTracking</key>
			<false/>
			<key>NSPrivacyCollectedDataTypePurposes</key>
			<array>
				<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
				<string>NSPrivacyCollectedDataTypePurposeOther</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
```

## Third-party SDKs

| SDK | Phase | What to check before it ships |
|---|---|---|
| `clerk-ios`, `ClerkKit` product only (decision D2) | 24a | Whether its release includes its own `PrivacyInfo.xcprivacy`, which required-reason APIs it declares (it likely uses `UserDefaults` and Keychain), whether it collects anything itself (device or session metadata sent to Clerk), and whether Apple lists it among the SDKs that need a signature (to confirm on Apple's third-party SDK requirements page). Whatever Clerk sends to its servers counts as our collection in the labels |
| `swift-snapshot-testing` and its dependencies | Test only | Must never link into the app target. `scripts/check-release.sh` already checks this |

No analytics, crash or ads SDK is used. Phase 31 (22 October 2026) used Apple's MetricKit, which is part of iOS and needs no SDK and no manifest of its own. A third-party one would need Jose's written approval (THREAT_MODEL, analytics).

## Checks each time the manifest changes

1. Archive the app and run Xcode's **Generate Privacy Report** on the archive. The report should list exactly the rows above for the current phase.
2. Grep the Release build's sources for each required-reason API name (the scan in this file), and diff against the manifest.
3. Update [APP_STORE_PRIVACY_LABELS.md](APP_STORE_PRIVACY_LABELS.md) and the App Store Connect answers in the same change.
4. A suggestion for a later app phase: extend `scripts/check-archive.sh` to fail if the archive's privacy report names an API category the manifest doesn't declare.
