---
status: open-monitoring (in-app side: READY; hub-side: BLOCKED on labsmith ZoneID.lifeZone case)
direction: app → labsmith
last-updated: 2026-06-16
freshness-horizon: 30 days
---

## Twenty-second-pass rule-restatement summary (top-of-doc per the canonical-invariant tier)

> **Rule** (verbatim user-direct, restated TWENTY-TWO times across 2026-06-12 → 2026-06-16; canonical-invariant tier — class-level invariant of the in-IDE agent across the portfolio): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing Xcode-managed files is ok."*
>
> **Scope**: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`.
>
> **Quadruple-binding**: rule lives in `CLAUDE.md` + `.claude/rules/xcode-agent-safety.md` + round-doc prologues + persistent-memory file. Any one can drift; the other three preserve the constitutional check.

## Current state (refreshed 2026-06-16, twenty-second-pass round)

| Side | Status |
|---|---|
| **In-app contribution** | ✅ SHIPPED (PR #74, eighth-pass round) — `MicrobeLabHubContribution` + `MicrobeLabHubRegistrar` + `MicrobeLabHubChallengeAdapter` all wired |
| **In-app Phase 3+ session gates** | ✅ SHIPPED (PR #137, twenty-first-pass round) — `ProgressionService` wraps `ForgeProgressionManager` for `disease-story-immune` / `disease-story-microbiome` / `global-microbiome-tour` gates (distinct from this handoff's hub-side gating; both can coexist) |
| **In-app `ForgeStateMachine` wiring** | ✅ SHIPPED (PR #142, twenty-second-pass round) — `ZoomMachine` adopts the canonical `ViewMachine` protocol per `.claude/rules/state-machines.md` |
| **In-app SeasonalEventService** | ✅ SHIPPED (PR #143, twenty-second-pass round) — pairs with `ExperimentsService.seasonal_content_gate` pilot for Phase 4 surface |
| **Hub-side `ZoneID.lifeZone` case in ForgeKit** | ⛔ BLOCKED — labsmith has not added the case to `forgekit/Sources/Client/ForgeAdventure/Hub/HubTypes.swift` |
| **Hub-side AdventureHub registry orchestration** | ⛔ BLOCKED — AdventureHub repo has not called `MicrobeLabHubRegistrar.register(into:)` at startup |
| **Cluster naming coordination** (life-zone slug) | ⛔ BLOCKED — labsmith has not coordinated naming with bioforge / creaturecare / wildlens cohort |

**In-app side is at "ready when hub flips" status**: the moment labsmith ships the `ZoneID.lifeZone` case + bumps a ForgeKit release, this app's session retargets `MicrobeLabHubContribution.init` from `.scienceLabs` to `.lifeZone` in a single-line SPM-only PR (per the canonical-invariant tier, no managed-file edits required).

**Re-verification cadence** (ADR-011 Rule 4 freshness horizon = 30 days from 2026-06-16): re-check by 2026-07-16. If still BLOCKED on the hub side, this handoff stays open-monitoring; no in-app action required.

# Handoff to Labsmith — ForgeAdventure Life Zone proposal

Direction: **app → labsmith**. MicrobeLab has shipped its Level 2 `HubContribution` overlay
(`Packages/Libraries/Sources/AppFeature/HubContribution/MicrobeLabHubContribution.swift`)
targeting AdventureHub. The contribution currently targets `ZoneID.scienceLabs` as the closest
available match for microbiology / cells / immune system content (NGSS MS-LS1-1 / MS-LS1-3 /
MS-LS2-3). Per `Docs/TECHNICAL_DESIGN.md` § Adventure Mode Integration + `Docs/FEATURE_PLAN.md`
§ Adventure Mode, the canonical target is the **Life Zone** of AdventureHub (TBD — coordinate
with bioforge / creaturecare / wildlens cluster). This handoff requests labsmith add the
canonical `lifeZone` case to `ZoneID` so MicrobeLab + its cluster siblings can retarget once
the zone lands.

## Request

1. **Add `lifeZone = "life-zone"` (or canonical slug) to `ForgeAdventure.ZoneID`** in
   `forgekit/Sources/Client/ForgeAdventure/Hub/HubTypes.swift`. Suggested slug follows the
   existing `math-mountains` / `word-woods` / `science-labs` kebab-case convention; canonical
   options include `life-zone` / `bio-zone` / `wild-frontier` — coordinate naming with the
   cluster cohort.
2. **Confirm engine-binding canonical set for life-science apps**. MicrobeLab's contribution
   currently binds `.simulation` (microbiome puzzle) + `.defense` (innate immune Pac-Man) +
   `.quest` (microscope exploration). Siblings (bioforge / creaturecare / wildlens) may share
   `.simulation` + `.collection` / `.quest` patterns; consolidating the engine-binding
   convention in the zone-introduction handoff prevents per-app drift.
3. **Optional**: ship a Level 1 `microbelab.json` config at
   `labsmith/Resources/HubContributions/microbelab.json` so AdventureHub has the baseline JSON
   alongside MicrobeLab's Level 2 overlay. Per `HubContribution` protocol semantics, Level 2
   shadows Level 1 for the same `(zone, engine)` slot, so both can coexist.

## What MicrobeLab shipped on its side (PR #74 sweep, 2026-06-12, **eighth-pass auto-cycle**)

- `MicrobeLabHubContribution` — `nonisolated public struct` conforming to
  `ForgeAdventure.HubContribution` with `themeAccent` = `#33CCBB` (hero color per
  `Docs/TECHNICAL_DESIGN.md`), `mentorPersona` = `.microbeLabCilia` (extension on
  `MentorPersona` with Cilia's canonical system-prompt header), `kitResources` = the 4 Phase-1
  question kits already bundled via `QuestionKitService.phase1KitSlugs`, `engineCopy` carrying
  trauma-informed protection / agency / discovery copy for `.simulation` / `.defense` /
  `.quest`.
- `MicrobeLabHubRegistrar.register(into:)` — thin async registrar helper for AdventureHub-side
  integration to call when the hub orchestration lands. AdventureHub owns the canonical
  registry instance; MicrobeLab doesn't unilaterally register.
- `MicrobeLabHubChallengeAdapter` — SwiftUI adapter that renders a hub-friendly per-engine
  placeholder surface (icon + completion message + back-to-hub + wrap-up-today affordances).
  When AdventureHub-side context wiring lands (Phase 4 classroom-mode integration), this
  placeholder can be upgraded to host the live MicrobeLab tab surfaces.

## Sequencing to unblock

1. Labsmith adds the canonical `lifeZone` case to `ZoneID` + ships a ForgeKit release
   (suggested ≥ 0.99.2 patch or 1.0.0 if cluster-wide breaking changes consolidate).
2. MicrobeLab session updates the default `zone` param on `MicrobeLabHubContribution.init` from
   `.scienceLabs` to `.lifeZone` (one-line SPM-only change) + bumps the ForgeKit pin if needed.
3. Cluster cohorts (bioforge / creaturecare / wildlens) author their own Level 2 contributions
   against the same zone.
4. AdventureHub session integrates the registry call to `MicrobeLabHubRegistrar.register(...)`
   at hub startup, completing the FEATURE_PLAN § Adventure Mode "Register mode-cards in
   `AdventureView`" item.

## What this doc does NOT cover

- AdventureHub-side rendering of the Life Zone immersive scene (lives in AdventureHub repo).
- Cross-app Bloom mastery propagation (`ForgeSync` integration follows its own track).
- Cluster naming bikeshed — labsmith coordinates the canonical slug with the bioforge /
  creaturecare / wildlens cohort.

## Related

- `Docs/TECHNICAL_DESIGN.md` § Adventure Mode Integration
- `Docs/FEATURE_PLAN.md` § Adventure Mode
- `Docs/IMPLEMENTATION_HANDOFF.md` § ForgeKit Integration Status — ForgeAdventure now
  actively consumed (was declared-but-unused pre-PR #74)
- `Packages/Libraries/Sources/AppFeature/HubContribution/MicrobeLabHubContribution.swift`
- `Packages/Libraries/Sources/AppFeature/HubContribution/MicrobeLabHubRegistrar.swift`
- `.claude/rules/forgekit.md` § Module Catalog → ForgeAdventure
