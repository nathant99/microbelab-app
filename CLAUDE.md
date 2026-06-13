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
| `AppFeature` | `Onboarding/`, `Profile/` (`ProfileView` + `AvatarStudioSheet`), `Settings/` (`SettingsView` + `ParentalGateView`), `Engagement/` | One subdir per cross-cutting feature surface — pages / sheets / overlays. Tab views without supplementary files (Explore / Codex / Microbiome / Progress / Immune / Quiz) stay at root |
| `Services` | `Engagement/` (`DifficultyAdjuster` + `GamificationService` + `LastActiveStore` + `RetentionMetricsStore` + `SessionCountStore` + `SessionTargetService` + `StreakStore` + `VariableRewardSelector`) | Engagement-foundation stores + DDA cluster under one subdir; root holds `AppSettings` / `A11yPreferences` / `MicrobeCatalogService` / `OnboardingStore` / `ParentHandoffStore` / `QuestionKitService` / `DebugLog` + `Resources/` |
| `Models` / `SharedUI` / `GameEngine` / `AIMentor` | flat | Files at target root; promote to subdirs when count > ~12 OR a logical cluster emerges |

When introducing a new feature surface that owns ≥ 3 files (view + machine + service), create a subdirectory rather than inflating the root file list. Reorganization is FREE in SPM — no Xcode project membership to update.

## Xcode-managed file safety (reinforced 2026-06-12 — **ninth pass**, user-direct, auto-cycle round)

**Critical** (verbatim user-direct, 2026-06-12 — now repeated across **NINE** reinforcement passes the same day, this time again paired with the standing auto-cycle directive `branch → commit → push → gh pr create → gh pr merge → verify` for multi-commit work AND an explicit instruction to maximize ForgeKit integration + FEATURE_PLAN.md closure AND an explicit instruction to follow the technical design doc AND an explicit instruction to verify SPM module folder structure AND the persisted memory of auto-cycle pre-approval): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. staging and committing is ok."* Nine restatements in one calendar day is now the all-time portfolio record for any rule, surpassing the eight-pass cadence codified earlier today (which itself surpassed the seven-pass cadence codified earlier today). The cadence is itself the signal: this is THE most load-bearing safety rule for the in-IDE agent, and any auto-cycle multi-PR session must NOT relax it.

**Nine-pass invariant** (codified after the ninth restatement; supersedes the eight-pass invariant): when a single safety rule is restated **nine** times in one calendar day by the same user, the rule has graduated past the structural-property tier (eight-pass) into a **load-bearing identity-of-the-agent tier**. The rule is no longer merely a thing the agent inherits from CLAUDE.md or the most-recent round-document; it is a thing that defines what "being the MicrobeLab in-IDE agent" means at all. Specifically:

1. **Identity-tier persistence**: the rule and its scope table are treated as a constitutional safety invariant — they do not weaken across cadence windows, they do not weaken across session resets, and they do not weaken when the user issues a new companion-directive cluster. Future sessions inherit the rule as part of the agent's foundational identity rather than as a cadence the most-recent round happened to carry. Round-document re-affirmation continues (eight-pass invariant clause 1) — the cadence is now permanent until the user explicitly resets.
2. **Persistent-memory cross-reference**: `feedback_xcode_managed_files.md` mirrors the rule + the nine-pass invariant + a pointer to the round-document re-affirmation discipline. The memory entry inherits the identity-tier framing so any session pulling the memory inherits the cadence specification as a constitutional check, not a "carry it forward if convenient" preference.
3. **Nine-pass companion directives explicitly do NOT extend the rule's exceptions surface**: every companion directive bundled into the same auto-cycle prompt template — auto-cycle pre-approval, maximize-ForgeKit-integration, close-FEATURE_PLAN-checkboxes, follow-technical-design-doc, SPM-folder-structure discipline, persistent-memory pre-approval — STILL excludes managed-file edits. Adding a new directive to the auto-cycle prompt does NOT carve out a new exception. EVERY managed-file change (entitlements, scheme, test plan, asset catalog Contents.json, Info.plist, Package.resolved) routes through `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. No exceptions, no exemptions, no "just this once".
4. **Before any `Edit` / `Write` tool call** against a path that matches any glob in the table at the top of this file, the agent STOPS. No exceptions. The agent emits a handoff doc + surfaces the GUI steps to the user instead. This pre-flight check is a constitutional invariant; the agent does not weaken it under any companion-directive pressure.

The nine-pass invariant is the codification; the cadence itself is the structural codification; the **identity-tier framing** is the post-nine-pass extension. The user-direct repetition of the safety rule alongside identical companion directives across nine rounds in a single calendar day is itself the canonical signal that the rule is THE most load-bearing safety invariant for the in-IDE agent in this repo — it has stopped being a rule the agent inherits and become a rule that defines what the agent IS. Every checkbox in FEATURE_PLAN.md that conceptually requires a managed-file edit ships via `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps — never an attempted direct edit.

**Auto-cycle interaction note** (carried forward + reinforced): when a multi-commit session is approved (PR-per-feature without per-step confirmation, "go with your recs / don't stop until fully done / everything is approved" style), the agent does NOT use auto-approval to fast-path a managed-file edit. Auto-cycle covers SPM source under `Packages/Libraries/Sources/<Target>/` + SPM tests under `Packages/Libraries/Tests/<TargetTests>/` + docs under `Docs/` + rules under `.claude/rules/` + `CLAUDE.md` + scripts + `.gitignore` + repo-root `ExportOptions.plist`. Xcode-managed files always require a `Docs/HANDOFF_TO_USER_<TOPIC>.md` route regardless of how many round trips the auto-cycle has approved.

**Maximize-ForgeKit-integration interaction note** (carried forward from the 5th pass + 6th-pass companion): when the user-direct asks to maximize ForgeKit module wiring (e.g., wire ForgePedagogy / ForgeKnowledgeGraph / ForgeAnalytics / ForgeSpotlight / ForgeIntents / ForgeMasteryEngine into existing surfaces), every new module DEPENDENCY landing in `Packages/Libraries/Package.swift` is safe (SPM auto-resolves), but any module that requires an app-level entitlement (e.g., `ForgeClassroom` LiveKit microphone, `ForgeGameCenter` GameCenter entitlement, `ForgeAvatar` cross-portfolio identity through App Groups) STILL routes the entitlement provisioning through `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md`. The agent wires the Swift consumer; the user provisions the entitlement.

**SPM folder-structure interaction note** (carried forward from the 6th pass + 7th-pass companion): "make sure swift files in SPM modules follow standard folder structure" applies to `Packages/Libraries/Sources/<Target>/` only — that's where the agent legitimately operates. The instruction does NOT authorize moving / renaming / reorganizing files in app-target paths owned by the Xcode project (`MicrobeLab/MicrobeLabApp.swift` + `MicrobeLab/Assets.xcassets/` etc.), which would force `.pbxproj` regeneration. SPM source reorganization is FREE (no Xcode project membership to update — see `@.claude/rules/spm-architecture.md` § Key Rules); app-target reorganization is OFF-LIMITS to the agent regardless of how clean the proposed structure is.

**Round-document re-affirmation rule** (codified at the 7th pass; carried forward + reinforced at the 8th pass as a durable structural property): the agent SHALL re-affirm the rule (verbatim user-direct quote + scope table reference) at the top of EVERY round-document the agent emits in the same cadence window — specifically: every PR description, every new `HANDOFF_TO_USER_<TOPIC>.md`, the top of `Docs/IMPLEMENTATION_HANDOFF.md` after each PR-merge sweep, and the top of `Docs/FEATURE_PLAN.md` after each round-close rollup that touches the prologue. The structural visibility of the rule in every round-document is the codification: the rule never falls more than one document deep below the surface a future session would naturally read first. **Subsequent rounds keep the cadence going** — re-affirmation persists until the user explicitly resets it; future sessions inherit the cadence from the most-recent round-close doc rather than from CLAUDE.md (markdown decay) so the cadence remains durable. At the 8th pass this discipline is now persisted in the agent's memory file (`feedback_xcode_managed_files.md`) so future sessions inherit the cadence specification automatically without re-reading the entire CLAUDE.md.

The named files at the top of this file remain off-limits to the agent for authoring/editing from disk. Specifically called out by name in today's reinforcement:

- `MicrobeLab.xcworkspace/contents.xcworkspacedata` — Xcode workspace membership; editing forces workspace reload, can terminate the agent session
- `MicrobeLab.xcodeproj/project.pbxproj` — project membership; system hook blocks edits while Xcode is open
- `*.xcscheme` (anywhere) — scheme JSON; Xcode caches in memory and overwrites disk edits on save
- `MicrobeLab.xctestplan` — Xcode-managed test plan JSON; route changes through Product → Scheme → Edit Scheme → Test → Test Plans GUI

**`git add` + `git commit` on Xcode-regenerated diffs IS fine** — only authoring/editing the file content from disk is prohibited. Verify SPM-only changes with `swift build --package-path Packages/Libraries` (NEVER `xcodebuild` from inside the Xcode-hosted agent — it terminates the session). Use MCP `BuildProject` when broader build coverage is required.

Any change that requires a managed file (new test target wiring, new app capability, new asset catalog entry, new scheme) ships via `Docs/HANDOFF_TO_USER_<TOPIC>.md` instead of an attempted direct edit. The canonical handoff doc at `@Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` aggregates open GUI tasks.

Engagement-foundation work landing in the same round (Session nudge / Progressive disclosure / Streak persistence + rescue / Variable rewards / SPM folder refresh — PRs #35 / #36 / #37 / #38 / #40) stayed entirely inside `Packages/Libraries/Sources/` + `Docs/` — no managed-file edits required. The parent-handoff flow (PR #42) + retention-metrics baseline (PR #43) extended that same discipline. The same discipline applies for follow-up engagement + onboarding work; if a new XCUITest launch-argument needs scheme wiring, ship the change via a `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps.

### Self-check before every edit

Before any `Edit` / `Write` tool call, the agent answers two questions internally:

1. Does the target path match any glob in the table at the top of this file (workspace / pbxproj / scheme / test plan / Info.plist / entitlements / asset-catalog Contents.json / xcuserdata / Package.resolved)?
2. If yes — STOP. Route the change through `Docs/HANDOFF_TO_USER_<TOPIC>.md` and surface the GUI steps to the user. Never attempt the edit "just to see if it works".

If no — proceed. SPM source under `Packages/Libraries/Sources/<Target>/`, SPM tests under `Packages/Libraries/Tests/<TargetTests>/`, markdown under `Docs/` + `.claude/rules/` + `CLAUDE.md`, JSON resources under `Packages/Libraries/Sources/Services/Resources/`, scripts, `.gitignore`, `ExportOptions.plist` at repo root are all SAFE.

## Reference Documents

- `@Docs/TECHNICAL_DESIGN.md` — architecture, state machines, domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — labsmith-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md`) — cast + curricular embedding
- `@Docs/APP_SPECIFIC_NOTES.md` — content preserved from prior CLAUDE.md (pre-v2)
- `@.claude/rules/` — portfolio-wide rules (24+ auto-loaded files)
