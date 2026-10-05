# Calm screens: less text on screen, nothing lost

These rules apply to every screen in the prototype. The aim is a screen that opens short and quiet, where the controls explain themselves and the longer wording is one tap away. Text is moved, not deleted.

## What other apps do

Checked on Mobbin, 5 October 2026.

- **One row of chips that scrolls sideways.** Filters and tags stay on a single line and scroll, instead of wrapping into three or four rows: [Formula 1](https://mobbin.com/screens/d412c3c5-7db2-4d7b-b26a-57b3c62e991f), [Careem](https://mobbin.com/screens/c940d5da-a82e-4dbf-a041-bfe9f6b5469c), [FotMob](https://mobbin.com/screens/5925765e-b6f3-40e4-bbc3-89b5ba62792d), [Grab](https://mobbin.com/screens/76656c88-f2d0-4f17-abcf-a9a7213d4521). [Yami](https://mobbin.com/screens/210995de-0ebe-43cb-a307-280c5651b19c) adds a chevron at the end of the row that opens the full list, and [Riot Mobile](https://mobbin.com/screens/510a34c5-cb01-4cd8-914c-6f77bf3f73a3) opens it in a sheet.
- **Titles first, details on tap.** Long explanations sit in closed rows that show only a title and a chevron: [Agoda](https://mobbin.com/screens/7f497875-b125-4508-9bf9-7a5ff2b491bd), [Affirm](https://mobbin.com/screens/8db11201-cb18-46d8-acda-4a55789ceeaa), [Cash App](https://mobbin.com/screens/73545935-8598-4499-b511-d5e579aefa01), [Perplexity](https://mobbin.com/screens/4873615d-9df3-4992-b758-d6dac2cad573). Cash App also tucks the deeper explanation behind a "Learn about…" link.
- **Two buttons, then a menu.** One main action and one secondary action stay visible, and everything else goes in a "…" menu: [Alma](https://mobbin.com/screens/eaa972b9-6a38-4c6d-8399-9595514e20b1), [Claude](https://mobbin.com/screens/804591d7-8663-44b3-8153-3d7fe91d26b7), [AllTrails](https://mobbin.com/screens/7b81639a-b6ea-440f-bfe3-32bc1e3520fc), [Alta](https://mobbin.com/screens/c1b8b98f-9006-4d2b-8537-d736665a2817).
- **Short empty and limited states.** A headline, one sentence, one button and at most one quiet link: [Angi](https://mobbin.com/screens/3397ad40-11a0-4572-93c6-9aeb6c4b6fe0), [timespent](https://mobbin.com/screens/2110919d-e927-4187-af30-c24230f55bff), [Monarch](https://mobbin.com/screens/0af4ad84-9be7-4708-a0bf-2f3695ecf1da), [TheFork](https://mobbin.com/screens/b9b1f8df-b774-490e-941f-11a87827a7bc).

## The rules

1. **One line, then a tap.** Explanatory text that she doesn't need in order to act shows as one short line at most. The rest sits behind a disclosure in the same spot. The full wording must still be reachable with one tap from where it used to be.
2. **Use the lightest disclosure that fits.**
   - A **details row** (title, a count or short summary, a chevron) for lists and evidence, such as "What was checked · 4".
   - An **info button** (ⓘ) beside a label for helper text that used to sit under a control.
   - A quiet **"Why?"** or **"Learn more"** link for rationale.
3. **Chips and badges take one row, and none is cut off.** A row shows only the chips that fit whole. When there are more, a "More" pill after the last visible chip opens the full set, and "Less" closes it. Nothing is clipped at the edge of the screen and nothing scrolls sideways. One choice out of many (a type filter, a category, a kind) is a dropdown that always shows the current choice, not a chip row. At accessibility text sizes rows wrap as before.
4. **Two buttons, then More.** A group of actions shows at most two buttons, side by side, with the most likely action first. Other actions go in a "More" menu. No group of buttons may take more than two rows at the default text size. Destructive actions live in the menu or apart from the rest, and still confirm.
5. **Short states.** Empty, partial and blocked states show a badge or icon, a headline of about six words, one sentence and one main action. Evidence and the other actions sit behind a details row or the More menu.
6. **Captions earn their place.** A caption under a control stays only when it reports the current state ("Strict · only the 5 pieces in this suitcase"). Captions that explain how a control works move to an info button.
7. **Some things are never hidden.** They can be shortened, but they stay on screen:
   - Simulated and Demo labels (as compact badges).
   - Errors and blockers, in a short form, with the detail behind a tap.
   - Anything she needs before agreeing or spending: who receives data and why at the moment she's asked, the cost of an action before she takes it, and what a destructive action removes.
   - Garment status badges such as Dirty and Not arrived.
   - The honest core of a limited result ("Partial result · 1 look").
8. **Fewer words, same meaning.** Visible text is shortened without changing what it says. The longer version stays, word for word or better, behind the disclosure.
9. **The tab bar stays readable.** On iPhone, content fades into the background behind the floating tab bar, so its labels are never read against pictures scrolling underneath.
10. **Disclosures are real controls.** Each one is a button with a 44 pt target that tells VoiceOver whether it's open. Everything behind it is reachable by VoiceOver and keyboard. Opening and closing respects Reduce Motion. State that should survive rotation or the tab/sidebar switch lives in the feature's shared UI state.

## Shared pieces

The rules are built once in the design system and reused:

| Component | What it does |
| --- | --- |
| `ChipCarousel` | One row of whole chips or badges with a "More" pill for the rest; wraps at accessibility sizes |
| `DropdownChip` | A chip that opens a menu for one choice out of many and shows the current choice |
| `DetailsDisclosure` | A closed row with a title, a count or summary and a chevron, opening in place |
| `InfoButton` | A small ⓘ button that shows helper text in a popover or sheet |
| `ActionGroup` | Up to two visible buttons plus a "More" menu for the rest |
| `EmptyStateView` (updated) | Headline, one sentence, one action, optional details |
| `SimulationNotice` (updated) | A compact "Simulated" label with the full sentence behind an info button |
