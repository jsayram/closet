# First-use tours amendment — accepted and integrated

**Accepted by Jose and integrated into the master PRD on 7 October 2026.** His instruction was: “make sure to add that to the PRD as that will be on the real app”. The authoritative requirements are now [Section 7.8](My_Petite_Style_PRD_v2.md#78-first-use-quick-tours-and-replay), FR-73, TourProgress / TourPreferences and AC-103. Coverage expanded to every shipped user-facing screen; iPad/landscape/large-text layouts share a logical tour ID. All 38 HTML tour pages are mocked, including 102 tips beyond Home, and Profile replay links work. Native first-use behavior remains unimplemented and native acceptance is Not run.

## Historical proposal (superseded)

The draft below is retained as the proposal history, not text to paste into the current PRD. Its five-screen scope, proposed analytics extension, line numbers and open questions are superseded by the integrated master; no new tour analytics requirement was adopted. Style Me starts on its first visit, results have a separate guide, and the reviewed friendly voice is retained.

Line numbers below refer to the PRD as it stands on 7 October 2026. Each item quotes the passage it changes and gives replacement or new text that can be pasted in.

## The decision

The owner asked for this on 7 October 2026 after reviewing a Home mockup with a coach mark on the laptop. The real app needs it.

1. **Each main screen has a short tour that shows once.** The first time Lily opens Home, Closet, Style Me, Suitcases or Saved Looks, the app dims the screen, puts a soft spotlight on one real control and shows a small card next to it with one or two sentences, a step count ("1 of 4"), Skip and Next. Each tour has two to four steps. Home's tour runs right after onboarding finishes.
2. **Tours point at real controls.** In the room design the controls are objects, so Home's tour points at the laptop (Style Me), the wardrobe (Closet), the suitcase (the styling source) and the name sign (Profile). Tours never show a picture of a screen in place of the screen itself.
3. **Never forced.** Skip ends that tour on any step, and so do Escape or a two-finger scrub with VoiceOver. A skipped or finished tour counts as seen and doesn't come back on its own. A tour never blocks a task: if she taps the spotlighted control, the tour ends and the control does what it normally does.
4. **Replay from Settings.** Profile/Settings has an "App tours" row ("Replay the tips for any screen"). It opens a sheet that lists every screen that has a tour, with its step count and a short summary. Tapping a screen opens that screen and starts its tour from step 1. The same sheet has a "Show tips on new screens" switch, on by default. Turning it off stops tours from starting on their own; replay still works.
5. **Updates can add tips.** When a release changes a screen enough to need new tips, that screen's tour gets a new version and shows once more. A version bump only happens for real changes, not for copy fixes.

Mockups: `prototypes/RoomDirectionMockups/screens/home-tour.html` (Home tour; `?step=1..4` opens a step) and `screens/settings.html` (App tours row; `?sheet=tours` opens the sheet). Only Home's tour is mocked so far. The other screens are listed in the sheet and say "not in the mockups yet" when tapped.

## Passages that change, with proposed text

### 1. §7 Screen-Level Requirements, Onboarding row (line 291)

Current:

> Petite-focused intro; skippable profile/measurements; optional fit/style preferences and budget; pricing/AI limits and privacy explanation before substantial setup.

Proposed:

> Petite-focused intro; skippable profile/measurements; optional fit/style preferences and budget; pricing/AI limits and privacy explanation before substantial setup. When onboarding finishes, Home's first-use tour starts (see First-use tours).

### 2. §7 Screen-Level Requirements, new row after Help / What changed (after line 303)

New row:

> | First-use tours | One short tour per main screen (Home, Closet, Style Me, Suitcases, Saved Looks), two to four steps each, shown the first time she opens that screen. Each step dims the screen, spotlights one real control and shows a card with a step count, one or two sentences, Skip and Next; the last step's button names what to do next (for example "Start styling"). Skip, Escape or the VoiceOver escape gesture ends the tour; tapping the spotlighted control ends it and performs the control's action. A tour never blocks a task, never asks for data and never starts on its own while "Show tips on new screens" is off. Replay any tour from Settings > App tours. |

### 3. §7 Screen-Level Requirements, Settings / Privacy & Data row (line 302)

Current:

> Default wardrobe view: Main Closet or a named Suitcase; cloud AI recipients and permission,

Proposed:

> Default wardrobe view: Main Closet or a named Suitcase; App tours (pick any screen to replay its tour, and a "Show tips on new screens" switch, on by default); cloud AI recipients and permission,

### 4. §7 Screen-Level Requirements, Help / What changed row (line 303)

Current:

> no extra primary navigation tab or forced walkthrough.

Proposed:

> no extra primary navigation tab or forced walkthrough. First-use tours are optional, skippable on every step and replayable from Settings, so they don't count as a forced walkthrough.

### 5. §6 Functional Requirements, new row after FR-72 (after line 285)

New row:

> | FR-73 | First-use tours and replay | Show each main screen's tour once, on her first visit to that screen, and Home's tour right after onboarding. Store per tour the version seen and whether it was finished or skipped; a finished or skipped tour does not show again unless its version changes. Settings > App tours lists every tour and replays any of them from step 1, and a "Show tips on new screens" switch (default on) stops automatic tours without disabling replay. Tours point at real controls on the live screen, keep 44 pt tap targets, work with Dynamic Type, VoiceOver, Reduce Motion and iPad layouts, and never block or replace a task. Tour state is a local preference: included in export and iCloud sync with other preferences, reset by Delete My Data. |

### 6. §12 Core Data Model, new row near WardrobeViewPreference (after line 1075)

New row:

> | TourProgress | Per tour ID: last seen version, outcome (Finished / Skipped), date; plus the "Show tips on new screens" preference. Local preference data only; no content, no analytics identifier. Restored from export/sync like other preferences. |

### 7. §23.1 Allowed analytics events, Onboarding row (line 1748)

Current:

> Started/completed/abandoned-step enum; no entered profile values

Proposed:

> Started/completed/abandoned-step enum; tour ID, version and outcome enum (finished / skipped at step N / ended by tapping the control / replayed from Settings); no entered profile values

### 8. §19 MVP Acceptance Criteria, new item after 102 (after line 1622)

New item:

> 103. On a fresh install, finish onboarding and confirm Home's tour starts and spotlights the laptop, wardrobe, suitcase and name sign in order. Skip on step 2 and relaunch: the tour does not return. Open Closet, Style Me, Suitcases and Saved Looks for the first time and confirm each tour shows once. Tap a spotlighted control mid-tour and confirm the control works and the tour ends. Replay each tour from Settings > App tours. Turn off "Show tips on new screens", bump a tour version and confirm it doesn't start on its own but still replays. Check every step on iPhone 12 and iPad portrait/landscape with the largest Dynamic Type size, VoiceOver and Reduce Motion: no clipped card, no card covering its spotlighted control, focus starts on Next, and Skip is reachable.

## Open questions for the owner

- Should the Style Me tour run on her first Style Me visit, or wait until after her first results so it can explain the looks?
- Tips text is written in the app's first-person stylist voice ("I'll pull together a look"). Keep that voice, or use plain second person?
