# Incident response (public summary)

Phase 25b, written 22 October 2026. Required by [SECURITY_STANDARD.md](SECURITY_STANDARD.md) section 10. This is the public version: the plan and the wording, with no commands, key names, account names or dashboard details. The runnable version, with the exact commands, is in the private backend repo (`docs/incident-response.md`). It goes with [THREAT_MODEL.md](THREAT_MODEL.md) (R6, R12, R15, D7, D9), [STACK.md](STACK.md) (backups) and [ACCOUNT_INVENTORY.md](ACCOUNT_INVENTORY.md).

## Who acts

Jose, and only Jose, on anything in production. Agents never get production access (D9): no production deploy key, no production flag on the Convex tool, no access to the backup bucket. In a development session an agent can read the plan, draft a notice and check the tests. It never runs a production command.

## The first ten minutes, for any incident

1. Write down the time and what was seen.
2. Stop paid work everywhere with one setting that needs no database. The app then tells people that the stylist or try-on pictures are taking a break, and sign-in, the closet and everything on the phone keep working.
3. Look at the switches, the ceilings and the spend, then pick the plan below.

## A. A leaked key

- **How it's found:** a secret-scanning or pre-commit alert, a provider email, a jump in a provider's spend page, sudden refusals from a provider, or a report. Our own budget alerts are written to a log only for now, so the providers' own budget emails are the real alarm.
- **What happens:** switch off whatever the key reaches; revoke the key at its provider first (a scheduled rotation overlaps the old and new key, a leak does not); make and set a new key without showing it; run one cheap check; switch the feature back on; compare our records with the provider's usage for the exposure window; record the date in the account inventory. Deleting a key from git history does not make it safe, so the key is treated as burned either way.
- **Special cases:** a leaked deploy key, Clerk secret key or backup token is treated as a possible data exposure (plan B). The backup private key can't be revoked, so a new pair is made and the bucket token is rotated as well.

## B. A data exposure

- **What the backend holds:** the pseudonymous account list tied to sign-in IDs, consent receipts, the usage and credit ledger, purchase records, support notes with any reply address, device-check public keys, stylist results sealed for at most 24 hours, and encrypted backups. Her closet, photos, measurements and looks stay on her iPhone. See [DATA_MAP.md](DATA_MAP.md).
- **How it's found:** an incident email from a provider, a key or token used when it wasn't, unknown files in the backup bucket, an unexpected deploy, or a report from a user or researcher.
- **What happens:** note when it was learned (a legal clock may start then); stop paid work; cut the way in by rotating the deploy key, sign-in secret, bucket token and code-host token; keep the evidence and delete nothing; work out what, whose and when; decide with a lawyer whether and how to notify; tell people.

## C. A cost spike

- **How it's found:** a provider's budget email, a spend counter near its ceiling, or an unusual number of paid requests. Each paid request reserves its worst-case cost before it runs, and daily and monthly ceilings (overall and per provider) stop new work when they're reached. The image provider is prepaid. A leaked key is the exception, because it bypasses our ceilings; that is plan A.
- **What happens:** find which scope is climbing; switch off that feature or provider or lower the ceiling; check whether it's one account or everyone, or a bug such as a retry loop or a longer prompt; reconcile against the provider's invoice (the invoice wins); raise a ceiling only with a written reason. Users are told only if something stayed paused for more than about an hour.
- **Open:** there's no way to block one account yet. An admin function for that is a question for Jose.

## How people are told

The automatic "taking a break" messages in the app appear by themselves when a switch flips. Beyond that, today: the website's support page, email (to testers and to anyone who gave an address; a Sign in with Apple relay address only forwards mail from senders registered with Apple), and before launch a direct message to Lily and the testers. There's no remote in-app notice and push is a stub until APNs is set up. A small "service notice" the app reads at sign-in is an open question for Jose, to decide before launch.

Writing rules: say what happened, what it touched, what we did, what they can do and how to reach us, in that order, in plain words. Say "we don't know yet" when that's true, and leave out any sentence that isn't confirmed.

**Short pause (support page)**
> The stylist and try-on pictures are paused while we fix a problem. Your closet, your looks and everything else on your phone work as usual, and nothing you've added has been lost. We'll update this page when they're back.

**A key leaked, nothing seen**
> On [date] we found that a key one of our services uses had been exposed. We switched it off and replaced it by [time]. We checked [what was checked] and found no sign that anyone's information was seen or that the key was used. You don't need to do anything. Questions: [support address].

**Personal information may have been seen**
> On [date] we found that [what happened, in one plain sentence], between [start] and [end]. What was involved: [the specific items]. [Only if confirmed: Your closet, photos and measurements stay on your iPhone and weren't involved.] What we did: [turned off the way in, replaced our keys, asked [provider] to confirm]. What you can do: [specific steps, or "nothing is needed"]. We're sorry. You can reach me at [support address], and I'll write again by [date] with anything new. Jose

**Limits lowered after a cost problem**
> To keep the app running we've lowered the daily limit for [stylist / try-on pictures] for now. The meter in the app shows what's left. We'll tell you when it goes back up.

## Legal notes (questions for the lawyer, not advice)

These add to [compliance/LEGAL_QUESTIONS.md](compliance/LEGAL_QUESTIONS.md) section 13. None of the deadlines below has been verified.

- Breach notification deadlines differ by place. US states each define personal information and the trigger differently, and some set fixed deadlines (as short as 30 days) and require notice to a state attorney general above a size threshold. Which states' laws apply depends on where each affected person lives. Other regions can have much shorter clocks (the EU's GDPR is 72 hours to the regulator where it applies). The plan is adults in the US only, so does a TestFlight tester elsewhere change that?
- Does the clock start at discovery or at confirmation? We write down both times.
- Is a pseudonymous ledger, a sign-in ID, a relay address or a support note "personal information" under those laws?
- What do the contracts with the sign-in, database, storage and AI providers say about who tells whom, and when?
- Whether to notify a regulator, the FTC (we think the Health Breach Notification Rule doesn't apply) or Apple, and whether to tell users even where no law requires it.
- How long to keep evidence, whether insurance needs notice by a deadline, and when to involve law enforcement.
- Whose name goes on a notice (the responsible legal entity is still open in the PRD).

## After every incident, even a false alarm

Within 24 hours: finish the rotations, update the dates in the account inventory, send the notices decided on. Within a week: write down what happened, how it was found, how long it took to stop, and what would have caught it sooner; add the missing alarm or test; update the threat model; add a progress log entry in public-safe words.

## Backups, in one paragraph

A daily job exports the Convex database, encrypts it to a public key (the private key stays offline with Jose), uploads it to a Cloudflare R2 bucket and removes copies older than 30 days. The bucket token can read and delete, because Cloudflare offers no write-only token, so the real protection is the encryption and a 30-day retention lock. Once a month Jose restores the newest backup into a test deployment, checks every table, reapplies the deletion log so deleted accounts stay deleted, and empties the test deployment. The job and the drill are built and tested against local backends and a fake bucket. The bucket, the key pair and the schedule don't exist yet.

## Rehearsal, 22 October 2026

On a local Convex backend: a stand-in key was rotated with the documented command, and a feature switch, the global kill switch and a spending ceiling were flipped and flipped back, all following the plan. Each command took about half a second and the next request was refused within about 20 milliseconds. The app's wording for a paused feature was checked on a simulator in Phase 24b and wasn't re-run. Nothing real was rehearsed: no real provider key, no cloud deployment, no notice sent.
