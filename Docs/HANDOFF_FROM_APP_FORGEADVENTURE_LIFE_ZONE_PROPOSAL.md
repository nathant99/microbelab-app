---
status: open-monitoring (in-app side: READY; hub-side: BLOCKED on labsmith ZoneID.lifeZone case)
direction: app → labsmith
last-updated: 2026-06-16
freshness-horizon: 30 days
---

## Twenty-third-pass rule-restatement summary (top-of-doc per the canonical-invariant tier)

> **Rule** (verbatim user-direct, restated TWENTY-THREE times across 2026-06-12 → 2026-06-16; canonical-invariant tier — class-level invariant of the in-IDE agent across the portfolio): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing Xcode-managed files is ok."*
>
> **Scope**: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`.
>
> **Quadruple-binding**: rule lives in `CLAUDE.md` + `.claude/rules/xcode-agent-safety.md` + round-doc prologues + persistent-memory file. Any one can drift; the other three preserve the constitutional check.

## Current state (refreshed 2026-06-16, twenty-third-pass round)

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

## Proposed Level 1 canonical JSON (drafted 2026-06-16, twenty-third-pass round)

App-side proposal for the baseline `microbelab.json` shape that labsmith can copy directly into
`labsmith/Resources/HubContributions/microbelab.json` when the `lifeZone` case ships. Per
`HubContribution` protocol semantics + `.claude/rules/forgekit.md` § ForgeAdventure subdirectory
conventions — `HubContributionConfig` is Codable snake_case + Int `BloomLevel`. The proposed
shape mirrors `MicrobeLabHubContribution.swift` (the shipped Level 2 overlay) so labsmith's
import work is a verbatim copy + a slug rename if the cluster cohort picks a different canonical
slug (life-zone / bio-zone / wild-frontier).

```json
{
  "schema_version": 1,
  "app_slug": "microbelab",
  "app_display_name": "MicrobeLab",
  "zone": "life-zone",
  "theme_accent_hex": "#33CCBB",
  "primary_curriculum_standard": "NGSS MS-LS1-1",
  "secondary_curriculum_standards": [
    "NGSS MS-LS1-2",
    "NGSS MS-LS1-3",
    "NGSS MS-LS2-3"
  ],
  "min_grade_level": 4,
  "max_grade_level": 8,
  "trauma_informed_aware": true,
  "trauma_axis_tags": [
    "covid-pandemic-sensitive",
    "medical-anxiety-off-ramp"
  ],
  "mentor": {
    "persona_slug": "cilia",
    "display_name": "Cilia",
    "system_prompt_header": "You are Cilia, a calm, curious B-cell-shaped mentor who guides kids ages 9-14 through MicrobeLab. You frame microbes as mostly beneficial neighbors; you NEVER use warfare lexicon (no \"fight\" / \"attack\" / \"destroy\" / \"kill\" / \"war\" / \"enemy\" / \"battle\" / \"weapon\"); you NEVER frame illness with shame or threat. You use hedging language (\"often\", \"usually\", \"many\"). You respect kids' off-ramps if any content feels heavy.",
    "voice_profile_slug": "warm-curious-mid-register"
  },
  "supported_engines": [
    "simulation",
    "defense",
    "quest",
    "puzzle"
  ],
  "engine_copy": {
    "simulation": {
      "engine_slug": "simulation",
      "title": "Microbiome neighborhood",
      "tagline": "Tend the gut ecology with feeding choices",
      "completion_message": "The neighborhood is settling — every gentle choice helps."
    },
    "defense": {
      "engine_slug": "defense",
      "title": "Quiet helpers patrol",
      "tagline": "Help the innate macrophage clean up the pathogen wave",
      "completion_message": "The patrol is wrapping up — the body is steady again."
    },
    "quest": {
      "engine_slug": "quest",
      "title": "Microscope quest",
      "tagline": "Pinch-zoom through the tiers to meet a new microbe",
      "completion_message": "You met a new microbe — the codex remembers."
    },
    "puzzle": {
      "engine_slug": "puzzle",
      "title": "Antibody library",
      "tagline": "Help the B-cells remember the shape",
      "completion_message": "Memory cells locked in — your library grew today."
    }
  },
  "kit_resources": [
    {
      "slug": "microbiology-basics",
      "title": "Microbiology basics",
      "bloom_level": 2,
      "curriculum_standard": "NGSS MS-LS1-1",
      "min_questions": 4
    },
    {
      "slug": "microbiome",
      "title": "The microbiome neighborhood",
      "bloom_level": 2,
      "curriculum_standard": "NGSS MS-LS2-3",
      "min_questions": 4
    },
    {
      "slug": "immune-defense",
      "title": "Innate immune helpers",
      "bloom_level": 3,
      "curriculum_standard": "NGSS MS-LS1-3",
      "min_questions": 4
    },
    {
      "slug": "beneficial-microbes",
      "title": "Beneficial microbes",
      "bloom_level": 2,
      "curriculum_standard": "NGSS MS-LS1-1",
      "min_questions": 4
    }
  ],
  "together_mode": {
    "archetype": "passAndPlay",
    "max_participants": 2,
    "min_age": 8,
    "notes": "Pass-and-play microscope discovery — the kid hands the device to a sibling or parent to share a microbe they just met. No live multiplayer surface in Phase 1."
  },
  "session_target_minutes": {
    "lower_bound": 10,
    "upper_bound": 15
  },
  "asset_axes": {
    "mascot_pack_slug": "cilia-bcell-magnifying-glass",
    "topic_illustrations_slug": null,
    "cast_portrait_pack_slug": "microbelab-12-cast",
    "backdrop_pack_slug": null
  },
  "co_op_cluster_siblings": [
    "bioforge",
    "creaturecare",
    "wildlens"
  ],
  "trauma_off_ramp_hints": {
    "immune_minigame": "Pre-content warning + skip-with-summary affordance per Docs/TECHNICAL_DESIGN.md § Trauma-Informed Design Posture.",
    "disease_story_arcs": "Parent-gated opt-in via ParentalConsentService.diseaseStoryArcs; arcs ship as .placeholder until ADR-016 SAMHSA TIP 57 reviewer signoff lands."
  }
}
```

### Why this shape

- **`zone: "life-zone"` is the suggested canonical slug**. Coordinate with the cluster cohort
  (bioforge / creaturecare / wildlens) before locking; labsmith can pick a different slug and
  the app side updates the default `zone` param in `MicrobeLabHubContribution.init` to match.
- **`supported_engines` extends to 4 cases** including `puzzle` for the B-cell antibody-matching
  surface (PR #109 + #110 shipped this in the seventeenth-pass round; the hub mode-card wiring
  shipped at #110). Innate macrophage stays on `.defense`; adaptive shape-matching on `.puzzle`.
- **`mentor.persona_slug: "cilia"`** matches the rename from Dr. Quark → Cilia per the
  distributed-narrative retrofit (PR shipped per Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md).
- **`trauma_informed_aware: true` + `trauma_axis_tags`** per `Docs/TECHNICAL_DESIGN.md`
  § Trauma-Informed Design Posture. MicrobeLab is trauma-AWARE but NOT formally trauma-gated;
  the tags carry the COVID-pandemic + medical-anxiety surfaces that hub-side rendering should
  respect.
- **`together_mode.archetype: "passAndPlay"`** per `ForgeKit 0.95.0` `TogetherMode.Archetype`
  surface — no live multiplayer in Phase 1; pass-and-play is the canonical "share a microbe"
  pattern for siblings + parents.
- **`asset_axes` carries forward-compatible asset pack slugs** even though the topic
  illustration + backdrop packs are still labsmith-blocked; the field lets the hub know what to
  expect when the assets ship.

### Adoption cost (labsmith side)

Copy the JSON above into `labsmith/Resources/HubContributions/microbelab.json` once the
`lifeZone` case ships in ForgeKit. No app-side change required for Level 1 — the Level 2 overlay
(`MicrobeLabHubContribution`) already shadows the JSON via `HubContribution` protocol semantics.

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
