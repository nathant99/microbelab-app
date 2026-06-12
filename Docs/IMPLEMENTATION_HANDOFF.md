# Implementation Handoff — MicrobeLab

**Status**: Phase 1 effectively shipped. Round 0 (scaffold) shipped 2026-05-22; Phase 1 systems landed via PRs #11 → #61 (through 2026-06-12). The bulk of Phase 1 engineering is complete; remaining work is asset-bundle-blocked (12-microbe portrait pack) or follow-on polish (UI tests, real-device perf capture).

**Latest round (2026-06-12, PRs #58 → #61, single-session auto-cycle)**: 4-PR sweep driven by the user-direct standing auto-cycle (`branch → commit → push → gh pr create → gh pr merge → verify`) paired with an explicit maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes directive. Each PR landed end-to-end before the next branched. Rollup:

| PR | Theme |
|---|---|
| #58 | Xcode-managed file safety — **fifth-pass** reinforcement (CLAUDE.md / `xcode-agent-safety.md` / `HANDOFF_TO_USER_XCODE_GUI_TASKS.md`). Codifies the five-pass invariant (when a single safety rule is restated five times in one day it becomes a pre-flight check, not a guideline) + the maximize-ForgeKit-integration interaction note (ForgeKit SPM-only wiring stays safe; modules needing entitlements still route through `HANDOFF_TO_USER_XCODE_GUI_TASKS.md`). |
| #59 | ForgePedagogy hint scaffolding in QuizView — first kid-facing consumer of the previously-declared `ForgePedagogy` ForgeKit module. `QuestionHintStrategy` (SharedUI/, pure `nonisolated` value-type) derives per-tier hint text from a `Question`: vague leans on the curriculum-standard tag; medium returns the first sentence of the explanation with the correct-choice phrase elided; specific returns the full explanation. `QuizMachine` extended with `requestedHintTier` + `hintsUsedCount` + `nextRequestableHintTier` + `requestNextHint()`. `QuizView` adds a "Hint" button next to "Check" + an inline yellow-tinted hint card + a trauma-informed completion summary ("Asked for help on N — that's how learning works"). New `SharedUITests` SPM target ships 11 `@Test` covering the progression + per-tier text invariants (Xcode scheme-wiring step queued in `HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6). |
| #60 | ForgeKnowledgeGraph cross-microbe ecology surfacing — `MicrobeKnowledgeGraph` (Services/, pure `nonisolated` value-type wrapper) builds a shared-habitat graph from the bundled catalog: every pair of microbes with the same `preferredEnvironment` gets a symmetric pair of `.recommended` edges. `MicrobeCodexCard` gains an optional `livesNearDisplayNames` param; discovered cards render a small "Lives near: A, B" caption. `MicrobeCodexView` builds the graph once on appear + threads neighbors through, filtering to the kid's discovered set so the codex NEVER hints at undiscovered microbes (trauma-informed posture). 9 `@Test` units in `ServicesTests/MicrobeKnowledgeGraphTests` pin construction + ordering + limit + exclude-self + unknown-slug. |
| #61 | Auto-surface SessionSummarySheet on app background — closes the FEATURE_PLAN.md § Parent Integration → "Session closer" follow-up. `AppRootView` stamps `sessionStartedAt` + `sessionStartXP` on cold launch + every `.background → .active` resume; on `.background` the productivity gate (`captureSessionSummaryIfProductive`) requires elapsed ≥ 60s AND XP earned > 0; the next `.active` surfaces `pendingSessionSummary` via `.sheet(isPresented:)` UNLESS the daily-cap / welcome-back / streak-rescue overlays hold centered-overlay precedence. Trauma-informed: short backgrounds (notification check) NEVER fire the summary; quiet sessions (0 XP) NEVER fire it. |

Net additions: 1 new Services module (`MicrobeKnowledgeGraph`) + 1 new SharedUI module (`QuestionHintStrategy`) + 1 new SharedUITests SPM test target (scheme wiring queued in handoff doc) + 20 new unit tests (11 `QuizMachineHintTests` + 9 `MicrobeKnowledgeGraphTests`) + 2 ForgeKit modules promoted from declared-but-unused → actively consumed (`ForgePedagogy` → SharedUI; `ForgeKnowledgeGraph` → Services). Build green at each merge.

**Previous round (2026-06-12, PRs #52 → #56, fourth-pass safety + Phase-1 polish)**: 5-PR sweep — Xcode-managed file safety 4th-pass + ForgeCelebration coordinator + DailyTimeCoordinator + Declared Age Range API gate scaffold + OSSignposter perf probes. See git log for the full per-PR notes; cross-references preserved in CLAUDE.md + FEATURE_PLAN.md.

**Pre-2026-06-12 PR #51**: Read-only accessibility audit (`Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md`) — covered every SwiftUI surface shipped through PR #50, verdict PASS WITH GAPS (Dynamic Type + color contrast portfolio-wide PASS; 3 prioritized gaps remain).

**Earlier 2026-06-12 (PRs #28 + #29 + #30)**: Phase-1 question kits 02 (microbiome), 03 (immune defense, trauma-informed register), and 04 (beneficial microbes) shipped — each as its own auto-cycle PR with bundled JSON in `Services/Resources/`, `QuestionKitService.phase1KitSlugs` extended in canonical order, and new `QuestionKitServiceTests` coverage (9/9 pass). FEATURE_PLAN.md § Gamification kit-bundling work item closed. CLAUDE.md Xcode-managed-file safety table (workspace + scheme + test plan) is the canonical reference — the user reinforced this guard at session start.

**Earlier this day (PRs #25 + #26)**: Mentor (Cilia) cue refreshes on `MicrobiomeView` feeding-mode change + every-5th-tick milestone + on `ImmuneGameView` wave-clear / run-complete. Phase-1 achievements `fiberPioneer` / `sugarTrial` / `microbiomeSteady` / `immuneRookie` / `immuneRunner` auto-evaluate as the kid hits criteria; XP awards flow through `GamificationService.evaluateAchievements`. Doc-path drift (`Libraries/Package.swift` → `Packages/Libraries/Package.swift`) corrected across CLAUDE.md + TECHNICAL_DESIGN.md + FEATURE_PLAN.md + APP_SPECIFIC_NOTES.md. Pre-existing `MacrophagePacmanSceneTests.spawnIsReproducibleAcrossSeeds()` failure (UUID-identity drift) fixed by comparing the deterministic `(kind, position, velocity)` projection.

## Read First

1. **`Docs/TECHNICAL_DESIGN.md`** — architecture, state machines, domain model, trauma-informed posture
2. **`Docs/FEATURE_PLAN.md`** — phased roadmap with checkbox status per work item
3. **This repo's CLAUDE.md** — portfolio tech stack + reference doc index + Xcode-managed file constraints
4. **Portfolio patterns**: `labsmith/Docs/PORTFOLIO_PATTERNS.md` § Implementation Prep

## ForgeKit Integration Status (post-2026-06-12 maximize-integration sweep)

Modules now actively consumed (vs the `Package.swift` declared list):

| Module | Where it's wired | Notes |
|---|---|---|
| `ForgeModels` | Models, Services, AppFeature | `StudentProfile`, `BloomLevel`, base value types |
| `ForgePersistence` | Services | SwiftData helpers |
| `ForgeGamification` | Services (`GamificationService` wraps `XPEngine` + `StreakManager` + `AchievementEngine`) | Phase-1 achievements + XP curve |
| `ForgeAccessibility` | Services (`DailyTimeCoordinator` wraps `SessionTimerService`) | Daily-cap pipeline (PR #54) |
| `ForgeUI` | AppFeature (`MicrobeLabOnboardingFlow` wraps `ForgeOnboardingFlow`) | Onboarding glass buttons + flow scaffolding |
| `ForgeCelebration` | AppFeature (`CelebrationCoordinator` at `AppRootView` + `.celebrationOverlay`) | Proportional milestone celebrations (PR #53) |
| `ForgeAvatar` | AppFeature (`AvatarStudioSheet` hosts `AvatarStudioView(.lite)`) | Avatar studio + ForgeID seeding |
| `ForgeSync` | AppFeature (`AvatarStudioSheet` / `ProfileView` read/write the canonical avatar via `AppGroupStore`) | Cross-portfolio identity |
| `ForgeGameEngine` | GameEngine (SpriteKit scenes import for base helpers) | LOD swap infrastructure pending portrait pack |
| `ForgePedagogy` | SharedUI (`QuestionHintStrategy` derives per-tier hint text; `QuizMachine` exposes `HintTier`-driven progression) | Hint scaffolding in QuizView (PR #59) |
| `ForgeKnowledgeGraph` | Services (`MicrobeKnowledgeGraph` wraps `KnowledgeGraph` with shared-habitat edges; `MicrobeCodexView` surfaces "Lives near" hints) | Cross-microbe ecology surfacing (PR #60) |

Still declared but unused in Swift code (deps stay in `Package.swift` so future wiring is friction-free):

- `ForgeAdventure` — awaits the Life Zone hub-contribution wiring (FEATURE_PLAN.md § Adventure Mode)
- `ForgeNavigation` — TabView's native iOS 26 chrome covers Phase 1; lift when nav grids land
- `ForgeAnalytics` — privacy-first on-device only; wires when MicrobeLab needs cross-session event totals

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
- `QuestionKitService` — bundled kit loader; ships kits 01-04 (microbiology basics 5q + microbiome 6q + immune defense 6q + beneficial microbes 6q, all NGSS / NHES tagged) via `phase1KitSlugs`
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
| ~~Question kits 02-04~~ | ✅ SHIPPED 2026-06-12 via PRs #28 / #29 / #30 |
| ~~Onboarding flow (5-step)~~ | ✅ SHIPPED via `MicrobeLabOnboardingFlow` (AppFeature/Onboarding/) |
| ~~Celebration system~~ | ✅ SHIPPED via PR #53 — `CelebrationCoordinator` proportional juice layer |
| ~~Parental controls (daily cap)~~ | ✅ SHIPPED via PR #54 — `DailyTimeCoordinator` + `DailyCapOverlay` |
| Declared Age Range API gate (iOS 26.2+) | **Scaffold landed PR #55**. Live `await requestAgeRange(...)` blocked on (a) entitlement provisioning via Xcode GUI per `HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6b, (b) COPPA consent + retention surface (receiving "Under 13" creates actual knowledge) |
| Adventure Mode (Life Zone) wire-up | Awaits AdventureHub Level 1 config + Level 2 Swift overlay handoff |
| Performance profiling (16ms tier transition / 8ms sim tick) | **Signposts landed PR #56**. Real-device Instruments capture + bench-harness assertions still pending |
| UI tests / accessibility XCUITests | Best landed once portrait pack ships (UI tests rely on rendered assets) — accessibility audit already PASS WITH GAPS per `Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md` |

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
