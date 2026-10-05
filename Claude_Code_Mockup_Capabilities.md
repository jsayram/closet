# Claude Code: iPhone and iPad mockup handoff

Research checked October 4, 2026. This is a design handoff aid, not a revision to the master PRD. No prototype, API call or device test was performed in this research pass.

## Recommended approach

Use a runnable universal SwiftUI prototype with fictional data and simulated services. Its views and components can carry forward into the real application; production storage, provider integration and release validation remain separate work.

Give Claude Code the current [master PRD](/Users/jramirez/Git/closet/My_Petite_Style_PRD_v2.md) and paste the complete [mockup prompt](/Users/jramirez/Git/closet/Claude_Code_iPhone_iPad_Mockup_Prompt.txt). Use a local Mac session for native execution. The prompt requests a frontend prototype, preserves the master and identifies conditional features.

## Current capabilities and limits

| Capability | Verified scope |
| --- | --- |
| Design canvas | Claude Code's /design drafts editable artboards with PNG/PDF export. It requires compatible paid-account/session availability and Claude Code v2.1.265 or later. [Official artifact documentation](https://code.claude.com/docs/en/artifacts) |
| Design handoff | Claude Design supports visual iteration and handoff to Claude Code. The documented exports do not establish automatic SwiftUI export. [Getting started](https://support.claude.com/en/articles/14604416-get-started-with-claude-design) |
| Design-system import | The documented component synchronization route emphasizes existing React components; native SwiftUI component roundtrip is not established. [Design-system setup](https://support.claude.com/en/articles/14604397-set-up-your-design-system-in-claude-design) |
| Native simulator | Claude Code Desktop has a public-beta iPhone/iPad Simulator pane for local macOS sessions. It requires Claude Desktop v1.24012.0 or later and Xcode with the iOS platform. It cannot control physical phones/tablets. Screenshots reach Anthropic under conversation retention settings after device consent, so use fictional data. [Simulator documentation](https://code.claude.com/docs/en/desktop-ios-simulator) |
| Xcode previews | Xcode integrates Claude's agent tooling and exposes native capabilities through MCP. External Claude Code can use that configured integration for native preview work. [Anthropic's Xcode announcement](https://www.anthropic.com/news/apple-xcode-claude-agent-sdk), [Apple's external-agent setup](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) |
| Web previews | Browser previews are useful for web prototypes, but do not verify native SwiftUI rendering or behavior. [Desktop documentation](https://code.claude.com/docs/en/desktop) |

No official documentation promises perfect screen conversion or production readiness without review. Simulator rendering and interaction evidence remain distinct from physical-device performance, real AI quality, fit accuracy, storage recovery, billing and App Store approval.

## Product alignment

The prompt follows master sections 7.1/7.2 for the existing theme and adaptive navigation, 7.5–7.7 for search/history/Suitcases, and 11.10 for provider-independent mocks. It covers the section 7 screen inventory and protects the key distinctions: owned versus unowned, arrival versus purchase, current availability versus historical appearance, preview history versus Favorites, and Suitcases versus saved-look collections.

Lily's inseam stays unknown until confirmed. Optional On Me/photo analysis is demonstrated only as simulation. Optional ChatGPT-plan login remains exploration under section 24.5. Pricing stays configurable sample content rather than a finalized public price.

The prompt authorizes local prototype work only. It does not authorize publishing, live provider calls, real purchases, private-photo use or production setup.
