# Implementation Handoff — MicrobeLab

**Status**: Phase 1 in flight. Round 0 (scaffold) shipped 2026-05-22; Phase 1 systems landed via PRs #11 → #26 (through 2026-06-12). The bulk of Phase 1 engineering is complete; remaining work is asset-bundle-blocked or covered by follow-up rounds (see § Outstanding).

**Latest round (2026-06-12, PRs #25 + #26)**: Mentor (Cilia) cue refreshes on `MicrobiomeView` feeding-mode change + every-5th-tick milestone + on `ImmuneGameView` wave-clear / run-complete. Phase-1 achievements `fiberPioneer` / `sugarTrial` / `microbiomeSteady` / `immuneRookie` / `immuneRunner` auto-evaluate as the kid hits criteria; XP awards flow through `GamificationService.evaluateAchievements`. Doc-path drift (`Libraries/Package.swift` → `Packages/Libraries/Package.swift`) corrected across CLAUDE.md + TECHNICAL_DESIGN.md + FEATURE_PLAN.md + APP_SPECIFIC_NOTES.md. Pre-existing `MacrophagePacmanSceneTests.spawnIsReproducibleAcrossSeeds()` failure (UUID-identity drift) fixed by comparing the deterministic `(kind, position, velocity)` projection.

## Read First

1. **`Docs/TECHNICAL_DESIGN.md`** — architecture, state machines, domain model, trauma-informed posture
2. **`Docs/FEATURE_PLAN.md`** — phased roadmap with checkbox status per work item
3. **This repo's CLAUDE.md** — portfolio tech stack + reference doc index + Xcode-managed file constraints
4. **Portfolio patterns**: `labsmith/Docs/PORTFOLIO_PATTERNS.md` § Implementation Prep

## What's Shipped (Phase 1)

### Scaffold + SPM

- 6-target SPM package (`Packages/Libraries`) — `Models` / `Services` / `SharedUI` / `GameEngine` / `AIMentor` / `AppFeature`
- ForgeKit pinned at `from: "0.99.0"` via remote GitHub URL
- Per-target `swiftSettings` matches portfolio default-isolation MainActor + InferIsolatedConformances
- `Bundle.module` resources for the bundled microbe catalog + question kits

### Data Layer (Models)

- Value types: `MicrobeCharacter` (v2 with `voiceLines`) / `MicrobiomeState` / `ZoomTier` / `GutSlot` / `FeedingMode` / `AntibioticState` / `GrowthRate` / `MicrobeKingdom` / `MicrobeRole`
- Immune-game value types: `PathogenKind` / `PathogenState` / `MacrophageState` / `Vec2`
- Question-kit value types: `Question` / `QuestionKit`
- SwiftData `@Model`s: `PersistentMicrobeSession` / `PlayerProgress` / `EncounterLog` / `JournalEntry`
- `SchemaV1` + `MicrobeLabMigrationPlan` (versioned-schema from day one per `.claude/rules/swiftdata.md`)
- Per-`@Model` value-type cache structs in `CacheStructs.swift`

### Services

- `MicrobeCatalogService` — loads bundled `microbes.json` (v2 schema, 12 entries)
- `QuestionKitService` — bundled kit loader; ships kit 01 (microbiology basics, 5 questions, NGSS-tagged)
- `AppSettings` + `AppSettingsStore` — UserDefaults-backed, dependency-injected per `.claude/rules/testing.md`
- `GamificationService` — `@Observable` MainActor wrapper around `XPEngine` + `StreakManager` + `AchievementEngine`
- `MicrobeLabAchievements` — 10 Phase 1 achievement definitions
- `DebugLog` — single-seam emitter with 7 categories per `.claude/rules/debug-logging.md`

### Game Engine

- `MicroscopeScene` + `ZoomMachine` — pinch-to-zoom + tier-boundary snap; lazy visual setup
- `MicrobiomePuzzleScene` + `MicrobiomeSimulator` + `SimulationMachine` — feeding modes + antibiotic shock + recovery
- `SeededRNG` (splitmix64) — drives reproducible simulator jitter + immune-game spawn
- `MacrophagePacmanScene` — pure-logic surface (`spawnCurrentWave` / `advancePathogens` / `moveMacrophage` / `consumePathogensInRadius`) + lazy visuals
- `SimulationMachine` undo stack + `ZoomMachine` tier-state transitions

### AI Mentor

- `VeeMentor` (Cilia) — lazy `LanguageModelSession` reuse, availability gating, static fallbacks
- `@Generable` types: `MicrobeFact` / `ZoomCue` / `EcologyHypothesis`
- Per-character voice-line rotation via `VeeMentor.voiceLine(for:rotation:)`

### SharedUI

- `TierBadge` (Liquid Glass Category B button)
- `MicroscopeHUD` (tier-badge row + magnification chip)
- `FeedingModePicker`
- `MentorBubble` (Cilia speech bubble)
- `MicrobeCodexCard` (nav-grid Category C card)
- `QuizMachine` (view-local FSM per `.claude/rules/state-machines.md`)

### AppFeature

- 5-tab `TabView` shell (Explore / Codex / Microbiome / Progress / Profile)
- `ExploreView` (microscope SpriteView + HUD + mentor cue refresh on snap)
- `MicrobeCodexView` (12-microbe grid + toolbar Menu → kit picker → QuizView sheet)
- `MicrobiomeView` (puzzle scene + feeding-mode picker + antibiotic alert + NavigationStack → ImmuneGameView)
- `ImmuneGameView` (Pac-Man scene + trauma-safe off-ramp + score HUD)
- `ProgressTabView` (level + XP bar + streak chips + achievement gallery)
- `ProfileView` (placeholder for `AvatarStudioView`) → NavigationLink → `SettingsView`
- `SettingsView` (sensory toggles kid-accessible; content gate + session cap parent-gated via `ParentalGateView`)
- `QuizView` (5-question flow + reveal explanation + completion panel; awards XP + achievements on completion)
- `ParentalGateView` (math-problem gate; 3-strike 30s cooldown)

### Tests

- ModelsTests, GameEngineTests, ServicesTests, AIMentorTests targets each ship per-feature `@Suite` test coverage
- Notable coverage: `SeededRNG` reproducibility, simulator determinism + jitter, `MacrophagePacmanScene` spawn/move/consume logic, `AppSettings` roundtrip, `QuestionKitService` load, `GamificationService` XP + achievement idempotency, `VeeMentor` voice-line rotation

## Outstanding (Phase 1 trail)

These remain unchecked in `Docs/FEATURE_PLAN.md`:

| Item | Blocker / Plan |
|---|---|
| Microscope LOD sprite atlas + per-tier sprite swap | Asset-blocked on 12-microbe portrait pack — labsmith handoff `HANDOFF_FROM_APP_MICROBE_ILLUSTRATIONS.md` queued per `.claude/rules/forgekit.md` § Asset generation ownership |
| 12 cast portrait WebPs + `ForgeIllustrations.IllustrationRegistry` wiring | Same as above |
| Question kits 02-04 (microbiome / immune defense / beneficial microbes) | Authoring pass + JSON bundle in `Services/Resources/` |
| Onboarding flow (5-step) | Requires `ForgeOnboardingFlow.Page` builder + ForgeKit avatar wiring |
| Adventure Mode (Life Zone) wire-up | Awaits AdventureHub Level 1 config + Level 2 Swift overlay handoff |
| UI / accessibility / performance tests | Best landed once portrait pack + onboarding ship — UI tests rely on rendered assets |

## Sequencing Constraints

- **AvatarStudio integration** awaits the ForgeKit 0.99-series `AvatarStudioView` portrait pack distribution per `.claude/rules/forgekit.md` § Avatar Edit Authority
- **Microscope portrait pack** is a single asset wave per `.claude/rules/forgekit.md` § Asset generation ownership; labsmith generates + ships via cross-repo PR
- **Trauma-informed sensitivity review** for Phase 3 disease-story arcs per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture — gated R0 reviewer signoff per portfolio ADR-012 / ADR-016 (MicrobeLab is trauma-AWARE not trauma-gated, so the gate applies at Phase 3 only)

## Cross-references

- `@Docs/TECHNICAL_DESIGN.md` — architecture
- `@Docs/FEATURE_PLAN.md` — phase checklist
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — 6-char canonical cast
- `@Docs/HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` — DN-S chapter spec
- `@.claude/rules/forgekit.md` — module catalog + asset ownership
- `@.claude/rules/spm-architecture.md` — package conventions
- `@.claude/rules/xcode-agent-safety.md` — Xcode-managed file constraints (the agent operates in-IDE; never write `.pbxproj` / `.xcscheme` / `.xctestplan` from disk)
