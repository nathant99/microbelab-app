# MicrobeLab

Microbiology adventure for tweens with microscope-zoom-as-core-loop, microbiome simulator, named microbe characters, and an immune-response minigame — beneficial microbes foregrounded, COVID-trauma-sensitive.

> **Deeper context**: `@Docs/TECHNICAL_DESIGN.md` (architecture), `@Docs/FEATURE_PLAN.md` (in-flight work), `@Docs/IMPLEMENTATION_HANDOFF.md` (handoff state), `@Docs/APP_SPECIFIC_NOTES.md` (preserved prior CLAUDE.md content). Portfolio-wide rules auto-load from `@.claude/rules/`.

> **🚫 Xcode-managed files — DO NOT AUTHOR / EDIT (staging + committing IS fine)**: the agent operates from inside the Xcode workspace. **NEVER write** the following files. **`git add` + `git commit` on Xcode-regenerated diffs IS fine** — the prohibition is on authoring/editing the file content from disk.
>
> | Path glob | Class | Recovery if you wrote one |
> |---|---|---|
> | `*.xcworkspace/contents.xcworkspacedata` | workspace membership | `git checkout HEAD -- *.xcworkspace/contents.xcworkspacedata` + close & reopen Xcode |
> | `*.xcodeproj/project.pbxproj` | project membership | `git checkout HEAD -- *.xcodeproj/project.pbxproj` + close Xcode + reopen workspace |
> | `*.xcscheme` (anywhere) | scheme JSON | revert + close & reopen Xcode |
> | `*.xctestplan` | test plan JSON | revert + re-add test targets via Product → Scheme → Edit Scheme → Test → Test Plans |
> | `Info.plist` (any app target) | target capabilities | revert + add keys via target → Info tab |
> | `*.entitlements` | capabilities | revert + add via target → Signing & Capabilities |
> | `*.xcassets/Contents.json` (catalog root + `*.imageset/Contents.json`) | asset catalog | revert + add via asset catalog editor |
> | `xcuserdata/` (anywhere) | per-user Xcode state | revert |
> | `Package.resolved` | SPM resolution | revert + let Xcode re-resolve |
>
> For changes that need them, author `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. Build verification of SPM-only changes uses `swift build --package-path Packages/Libraries` (terminal, no Xcode reload) — NOT `xcodebuild` (forces Xcode workspace reload, terminates the agent session). See `@.claude/rules/xcode-agent-safety.md` for the full classification table + safe escape hatches.

## Tech Stack

- **Language**: Swift 6 (strict concurrency)
- **UI**: SwiftUI
- **AI**: FoundationModels (on-device)
- **Persistence**: SwiftData
- **Testing**: Swift Testing (`@Test`, `#expect`)
- **Min Target**: iOS 26 / Xcode 26
- **Architecture**: App shell + local Swift Package (`Packages/Libraries/Package.swift`)
- **Framework**: ForgeKit (pinned via `.package(url:, from: "0.99.0")`)

Portfolio-wide tech stack rules live in `@.claude/rules/forgekit.md` + `@.claude/rules/concurrency.md` + `@.claude/rules/swiftui.md` + `@.claude/rules/swiftdata.md` + `@.claude/rules/spritekit.md` + `@.claude/rules/foundationmodels.md`. All auto-load with this file.

## Commands

```bash
# SPM-only build (no Xcode reload — preferred for in-IDE agent verification)
swift build --package-path Packages/Libraries

# Full app build (iOS Simulator) — use MCP `BuildProject` when Xcode is open
xcodebuild -workspace MicrobeLab.xcworkspace -scheme MicrobeLab \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# Tests
xcodebuild test -workspace MicrobeLab.xcworkspace -scheme MicrobeLab \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

When this repo's Coding Assistant session is operating from inside Xcode, prefer in this order:

1. **`swift build --package-path Packages/Libraries`** for SPM-only changes (terminal-only, no workspace reload — safest path for the in-IDE agent)
2. **MCP `BuildProject` / `RunSomeTests`** when broader build coverage (app shell + Xcode-resolved targets) is needed
3. **`xcodebuild`** only when MCP isn't available — it triggers a workspace reload and can terminate the agent session mid-task

See `@.claude/rules/xcode-agent-safety.md` for the full classification of Xcode-managed files the agent must never author from disk, and `@.claude/rules/workflow.md` § "MCP-First Testing Workflow" for testing flow details.

## App-Specific Conventions

See `@Docs/APP_SPECIFIC_NOTES.md` for the preserved prior CLAUDE.md content (architecture / domain patterns / gotchas accumulated through development). Portfolio-wide rules — Swift 6 concurrency, SwiftData patterns, testing conventions, ForgeKit module APIs, Liquid Glass register, distributed-narrative methodology, trauma-informed gates, COPPA / age-assurance — auto-load from `@.claude/rules/` (24+ files synced from labsmith). Do NOT re-state portfolio-wide rules here.

## SPM Folder Convention

The local Swift Package at `Packages/Libraries/` follows the portfolio standard layout per `@.claude/rules/spm-architecture.md`. Source files live directly under `Sources/<TargetName>/` and may optionally be grouped into subdirectories when a target accumulates many files. Current per-target subdirectory groupings shipped through Phase 1:

| Target | Subdirectories | Convention |
|---|---|---|
| `AppFeature` | `Onboarding/`, `Profile/`, `Engagement/` | One subdir per cross-cutting feature surface — pages / sheets / overlays |
| `Models` / `Services` / `SharedUI` / `GameEngine` / `AIMentor` | flat | Files at target root; promote to subdirs when count > ~12 OR a logical cluster emerges |

When introducing a new feature surface that owns ≥ 3 files (view + machine + service), create a subdirectory rather than inflating the root file list. Reorganization is FREE in SPM — no Xcode project membership to update.

## Xcode-managed file safety (reinforced 2026-06-12)

The `*.xcworkspace` / `*.xcodeproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved` files at the top of this file remain off-limits to the agent. **`git add` + `git commit` on Xcode-regenerated diffs IS fine** — only authoring/editing from disk is prohibited. Verify SPM-only changes with `swift build --package-path Packages/Libraries` (NEVER `xcodebuild` from inside the Xcode-hosted agent — it terminates the session).

Any change that requires a managed file (new test target wiring, new app capability, new asset catalog entry, new scheme) ships via `Docs/HANDOFF_TO_USER_<TOPIC>.md` instead of an attempted direct edit.

## Reference Documents

- `@Docs/TECHNICAL_DESIGN.md` — architecture, state machines, domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md`) — cast + curricular embedding
- `@Docs/APP_SPECIFIC_NOTES.md` — content preserved from prior CLAUDE.md (pre-v2)
- `@.claude/rules/` — portfolio-wide rules (24+ auto-loaded files)
