# Nifty Outfit Nook planning documents

This repo holds the planning and design work for Nifty Outfit Nook, Lily's wardrobe app (its working title was My Petite Style). The iOS app is built in a separate public repo, [nifty-outfit-nook](https://github.com/jsayram/nifty-outfit-nook). This repo stays the design and planning repo.

## Start here

[Nifty Outfit Nook PRD v2](Nifty_Outfit_Nook_PRD_v2.md) is the master specification. New requirements go there. It describes the intended first release of the app, not a second release. [The room-direction amendment](PRD_Amendment_Room_Direction.md) updates it with the room design and Lily's approved review changes.

Writing a requirement down doesn't prove it works. Features, providers and performance still need building and evidence, and no app or fit quality has been validated yet.

## Building the app

- [SWIFT_BUILD_PLAN.md](SWIFT_BUILD_PLAN.md): the phase list for the iOS build, with the progress log at the bottom.
- [IOS_APP_PLAYBOOK.md](IOS_APP_PLAYBOOK.md): verified lessons we can reuse on future iOS apps.
- [SECURITY_STANDARD.md](SECURITY_STANDARD.md): required for every phase. Exceptions need Jose's written approval.
- [DATA_MAP.md](DATA_MAP.md): what data the app handles, how sensitive it is, and where it goes.
- [THREAT_MODEL.md](THREAT_MODEL.md): what could go wrong and which controls cover it.

## Reviewing mockups

The client mockup review process is in [CLIENT_REVIEW_WORKFLOW.md](CLIENT_REVIEW_WORKFLOW.md), with a reusable Obsidian workflow and checklist for future apps. Agents can add useful lessons there; see [AGENTS.md](AGENTS.md).

## What the PRD covers

The v2 specification takes in Lily's feedback, fit based on her proportions, deliberate shopping choices, garment and shoe previews from the closest source, kept preview history, and offline search across everything.

- **Suitcases (7.7).** Several named suitcases are a V1 requirement. A garment can be in more than one, the Settings view is remembered, styling stays inside the chosen suitcase, and deleting a suitcase is safe and can be recovered.
- **Laundry and ownership (7.3, 7.4).** A visible Dirty status, cleaning one, selected or all pieces (all needs a confirm), and No longer own keeps the history.
- **Names and search (7.6, 8.4).** Personal garment names, details added a bit at a time, search corrections she confirms, finding a named item, and optional photo understanding with its own permission.
- **Mock development and history (11.10, 11.11).** Private history is checked and reused before any paid AI call. Reuse is checked against the current context, she can ask for fresh ideas, and a matching preview that's already kept costs no new image units.
- **Shopping (8.5, 13, 26.7).** The web-search finder, a stylist prompt that uses her measurements, and optional reminders to finish a purchase. RV-28 and RV-29 check sources, privacy, cost and styling quality live. Catalog and fit vendors are optional future adapters; the first release doesn't need any.
- **Fit-first shopping (13.8, 26.8).** Editable priorities for Amazon, TikTok Shop, Target, Walmart, H&M and other permitted sources. Fit supported for that exact product ranks above retailer, style and price. Critical unknowns are shown separately and known conflicts are excluded. FR-72, AC-102, RV-28 and RV-29 require real evidence; no retailer integration or guaranteed fit is claimed.

The October 4 Suitcases integration audit and the implementation evidence still needed are in section 26.6.

## Older material

- The [project handoff](PROJECT_HANDOFF.md), [try-on pointer](Virtual_Try_On_Exploration.md) and [competitor-review pointer](Petite_Wardrobe_Review_Requirements.md) all point to the master PRD.
- [Lily's original feedback](Lilys_Wardrobe_App_Feedback.txt) is kept as source evidence.
- The [feedback assessment](Lilys_Feedback_PRD_Assessment.md) is the earlier read-only review of v0.1. It isn't the current specification.
- [PRD v0.1 in Markdown](My_Petite_Style_PRD_v0.1.md) and the [original Word draft](My_Petite_Style_PRD_v0.1.docx) are kept for history. Their old authority statements and replaced behaviour don't override v2.
