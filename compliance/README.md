# Compliance

Phase 19b, privacy and compliance baseline, drafted 19 October 2026. These are drafts for Jose's 19b checkpoint. Nothing here is published, nothing in the app repo was changed, and none of it is legal advice.

| File | What it is |
|---|---|
| [PRIVACY_MANIFEST.md](PRIVACY_MANIFEST.md) | The app's `PrivacyInfo.xcprivacy`: today's file (already correct), required-reason APIs and collected data types by phase, and a planned release version |
| [APP_STORE_PRIVACY_LABELS.md](APP_STORE_PRIVACY_LABELS.md) | Answers for App Store Connect's privacy questionnaire, by phase, including how the try-on disclosure shows in the label |
| [PERMISSIONS.md](PERMISSIONS.md) | Every iOS permission: phase, purpose string, the in-app explanation before iOS asks, and what happens on "no" |
| [IN_APP_PRIVACY_TEXT.md](IN_APP_PRIVACY_TEXT.md) | Wording for Privacy and terms and every consent switch, by phase, including a 19b fix for the current screen |
| [PRIVACY_POLICY_OUTLINE.md](PRIVACY_POLICY_OUTLINE.md) | The privacy policy for /privacy, section by section, with the processor list, retention and deletion, and the provider facts checked today |
| [TERMS_OUTLINE.md](TERMS_OUTLINE.md) | Terms of use for /terms |
| [SUPPORT_PAGE_OUTLINE.md](SUPPORT_PAGE_OUTLINE.md) | The support page for /support, the App Store Support URL |
| [APP_REVIEW_CHECKLIST.md](APP_REVIEW_CHECKLIST.md) | Living checklist against the App Review Guidelines, each row with the phase that closes it |
| [LEGAL_QUESTIONS.md](LEGAL_QUESTIONS.md) | Questions for a lawyer, marked "before testers" or "before launch" |

These sit beside [DATA_MAP.md](../DATA_MAP.md), [THREAT_MODEL.md](../THREAT_MODEL.md), [SECURITY_STANDARD.md](../SECURITY_STANDARD.md) and [STACK.md](../STACK.md), and follow them. Where these drafts and the PRD disagree, the PRD and Jose's recorded decisions win, and the disagreement is listed below.

## Keeping them current

Every phase that adds a request, a processor, a stored field or a permission updates, in the same change: DATA_MAP.md, the manifest plan, the labels, the permission list, the in-app text and the policy outline. Phase 35a checks all of them against the release build.

## Found while drafting

1. **Today's privacy manifest is right.** The only required-reason API in the app is `UserDefaults`, declared with `CA92.1`. No third-party SDK ships, no permission is asked, nothing is collected. Next additions: file timestamps (`C617.1`) and disk space (`E174.1`) around 21b and 22b.
2. **The App Store label has no free-text field.** The try-on disclosure there is Photos or Videos, collected, linked, with the purposes App Functionality and **Other Purposes** (BFL's training). The plain sentence lives in the consent screen, the policy and "See what was sent". Suggestion: also put it in the App Store description.
3. **BFL's privacy policy offers a training opt-out** by email (privacy@blackforestlabs.ai, subject "Training Opt Out"), while its API Service Terms take a perpetual right that includes training. If the opt-out covers API inputs, Jose could remove the training exposure without a business agreement. Ask BFL in writing before 33a. BFL also has a US-only endpoint (`api.us.bfl.ai`) and its delivery URLs expire after 10 minutes, which answers part of THREAT_MODEL's "to verify in 19b" list.
4. **Measurements and weight to Anthropic: the docs disagree.** The privacy mockup says Style Me never sends "measurements or weight". PRD 8.5 and DATA_MAP.md send the minimum relevant measurement. Sending them likely adds "Health" to the label and pulls in Washington's My Health My Data Act. Jose decides before 27a; the in-app text has both versions. 27a (21 October 2026) sends neither and uses version A until he decides (THREAT_MODEL D14).
5. **Two App Review risks to watch:** 5.1.1(i) asks that third parties give "the same or equal protection" as our policy, which BFL's training right strains; and 5.1.3(ii) bars storing "personal health information in iCloud", which may cover weight or measurements in sync. Both are in the checklist and the legal questions.
6. **The current in-app try-on line is out of date.** Privacy and terms says try-on would send "your try-on photo". Since D1 only a faceless copy goes, to Black Forest Labs. The replacement text is in IN_APP_PRIVACY_TEXT.md.
7. **Age.** PRD 24.2 sets adults 18+ and a US-only launch. The app needs an age confirmation before cloud features (drafted for 24a) and a decision on the age rating.
8. **Who the operator is.** The policy, terms and App Store need a named operator. App Review 5.1.1(ix) suggests apps needing sensitive information be published by a legal entity. Lawyer question 1.

## Interpretations to check

- The six consent switches in `docs/settings.md` are tied to phases 19b, 24a, 27a, 29, 31 and 33. 19b has no feature that sends anything, so its part is the real wording of the screen, not a switch. 24a's "consent switch" is drafted as the account section with sign-in and the 18+ confirmation.
- iCloud sync (20b) and "Describe my photos" (22a, if built) aren't in that list but get consent wording too.
- Body measurements as Apple's "Health" type, and App Attest keys as "Device ID", are both answered the cautious way (declare) and marked to confirm.
