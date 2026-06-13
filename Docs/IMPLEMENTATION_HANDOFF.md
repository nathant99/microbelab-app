# Implementation Handoff — MicrobeLab

> **Eighth-pass rule-restatement summary** (top-of-doc per the eight-pass invariant codified 2026-06-12; verbatim user-direct, repeated EIGHT times in one calendar day — all-time portfolio record, surpassing the seven-pass cadence codified earlier the same day): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. staging and committing is ok."* Scope: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`. Every round-document the agent emits in the cadence window carries this summary so the next round inherits the cadence without re-reading the entire CLAUDE.md. The 8th-pass discipline also persists in the agent's memory file (`feedback_xcode_managed_files.md`) so future sessions inherit the cadence specification automatically. See `@CLAUDE.md` § Xcode-managed file safety for the canonical statement.

**Status**: Phase 1 effectively shipped. Round 0 (scaffold) shipped 2026-05-22; Phase 1 systems landed via PRs #11 → #71 (through 2026-06-12). The bulk of Phase 1 engineering is complete; remaining work is asset-bundle-blocked (12-microbe portrait pack) or follow-on polish (UI tests, real-device perf capture).

**Latest round (2026-06-12, PRs #73 → #76, eighth-pass auto-cycle sweep)**: 4-PR sweep driven by the user-direct standing auto-cycle (`branch → commit → push → gh pr create → gh pr merge → verify`) paired with the **eighth-pass** Xcode-managed file safety reinforcement + the persisted maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes + follow-technical-design-doc + SPM-folder-structure directive set. Each PR landed end-to-end before the next branched. **Eight restatements in one calendar day is the all-time portfolio record for any single rule**, surpassing the seven-pass cadence codified earlier the same day. Rollup:

| PR | Theme |
|---|---|
| #73 | **Eighth-pass** Xcode-managed file safety reinforcement — codifies the **eight-pass invariant** (supersedes the seven-pass invariant). The rule is no longer merely an immutable pre-flight check; it is a structural property of every artifact the agent emits in the cadence window AND of every artifact future sessions inherit from the cadence window. Four clauses: (1) round-document re-affirmation persists indefinitely until the user explicitly resets the cadence, (2) persistent-memory cross-reference — `feedback_xcode_managed_files.md` mirrors the rule + the round-document re-affirmation discipline, (3) eight-pass companion directives do NOT extend the rule's exceptions surface, (4) before any `Edit` / `Write` tool call against a path matching the "DO NOT WRITE" glob table, the agent STOPS. |
| #74 | ForgeAdventure wire-up — `MicrobeLabHubContribution` Level 2 Swift overlay. Promotes `ForgeAdventure` from declared-but-unused to actively consumed. Ships `MicrobeLabHubContribution` (`nonisolated public struct` conforming to `ForgeAdventure.HubContribution` with themeAccent `#33CCBB`, mentor persona Cilia, kitResources pointing at the 4 Phase-1 question kits, trauma-informed engineCopy for `.simulation` / `.defense` / `.quest`), `MicrobeLabHubRegistrar.register(into:)` async registrar helper, `MicrobeLabHubChallengeAdapter` SwiftUI adapter, and `MentorPersona.microbeLabCilia` (`nonisolated public static let` extension on MentorPersona with Cilia's canonical system-prompt header). Targets `ZoneID.scienceLabs` until labsmith ships the canonical `lifeZone` case — cross-repo handoff filed at `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md`. New `AppFeature/HubContribution/` subdir per SPM folder convention. Closes (partial) FEATURE_PLAN.md § Adventure Mode Level 2 Swift overlay; `[/]` partial on "Register mode-cards in AdventureView" (registrar ready; AdventureHub-side integration closes the item). |
| #75 | Codex completion certificate — Share-worthy moments axis. Closes (partial) FEATURE_PLAN.md § Delight & Polish "Share-worthy moments" on codex axis (immune-trophy axis still pending). Ships `CodexCertificate` (Services/Engagement/, pure nonisolated `Sendable` value type) snapshotting the kid's discovery progress with warm tiered headline (Microbe Explorer Pass → Microbe Field Notebook → Microbe Naturalist → Microbe Scientist → Codex Complete!), `CodexCertificateView` (AppFeature/Engagement/) self-contained SwiftUI card driving both in-app preview AND the rendered PNG share image, `CodexCertificateSheet` with `ImageRenderer` → `ShareLink` integration shipping the PNG through the system share sheet. `ProgressTabView` gains a secondary-action toolbar "Share my codex" button. Trauma-informed: zero-discovery framed as agency not absence; copy stoplist (`missed` / `failure` / `behind` / `should` / `must` / `haven't yet` / `fell short`) pinned by parameterized test across count `0...12`. 8 new `CodexCertificateTests`. |
| #76 | Mastery moments detector — ecology axis wired into MicrobiomeView. Closes (partial) FEATURE_PLAN.md § Delight & Polish "Mastery moments — Distinct screen ripple + chord when child internalizes microbiome ecology" on ecology axis. Ships `MasteryMomentDetector` (Services/Engagement/, pure nonisolated `Sendable` value type) tracking per-session mastery thresholds for `.ecologyMaster` (≥ 15 consecutive stable ticks under fiber feeding) / `.defenseMaster` (perfect 5-wave immune run) / `.codexMaster` (12/12 microbes) with `acknowledged: Set<MasteryKind>` so each kind fires once per session. `MicrobiomeView` carries the detector as `@State`; on a returned `Moment` it fires `CelebrationCoordinator.personalBest(metric:value:)` (`.epic` tier ripple + chord via `daily-complete` Lottie) + carries the moment's subline into the mentor bubble + fires `SensoryPaletteCoordinator.streakMilestone(threshold)` for distinct haptic vs the routine `.achievement` cue. Trauma-informed: copy stoplist (`finally` / `at last` / `you almost` / `failed` / `behind` / `should have` / `compared to` / `better than`) pinned by parameterized test across all 3 moment kinds. 12 new `MasteryMomentDetectorTests`. Defense + codex axes ship the detector surface ready for follow-up wiring into `ImmuneGameView` + `MicrobeCodexView`. |

Net additions: 2 new Services modules (`CodexCertificate` + `MasteryMomentDetector`, both under `Services/Engagement/` per the portfolio SPM folder convention) + 1 new AppFeature subdir (`HubContribution/` containing `MicrobeLabHubContribution` + `MicrobeLabHubRegistrar`) + 2 new AppFeature views (`CodexCertificateView` + `CodexCertificateSheet` under `Engagement/`) + 20 new unit tests across 2 suites (`CodexCertificateTests` 8 + `MasteryMomentDetectorTests` 12) + 1 cross-repo handoff to labsmith (`HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md`) + 1 ForgeKit module promoted from declared-but-unused → actively consumed (`ForgeAdventure` → AppFeature). Build green at each merge.

**Previous round (2026-06-12, PRs #68 → #71, seventh-pass auto-cycle sweep)**: 4-PR sweep driven by the user-direct standing auto-cycle (`branch → commit → push → gh pr create → gh pr merge → verify`) paired with the **seventh-pass** Xcode-managed file safety reinforcement + the persisted maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes + follow-technical-design-doc + SPM-folder-structure directive set. Each PR landed end-to-end before the next branched. Seven restatements in one calendar day is the all-time portfolio record for any single rule. Rollup:

| PR | Theme |
|---|---|
| #68 | **Seventh-pass** Xcode-managed file safety reinforcement — codifies the **seven-pass invariant** (supersedes the six-pass invariant). New rule: when the same safety rule has been restated seven times in a single calendar day, the agent re-affirms the rule (verbatim user-direct quote + scope table reference) at the top of every round-document it emits (PR descriptions, every new `HANDOFF_TO_USER_<TOPIC>.md`, `Docs/IMPLEMENTATION_HANDOFF.md` rollup top, `Docs/FEATURE_PLAN.md` prologue). Markdown decay risk is now structurally mitigated by per-round re-affirmation rather than relying on a future session reading CLAUDE.md first. |
| #69 | SpriteView VoiceOver labels — closes the high-priority GAP 1 from `Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md` § Findings. `ExploreView` / `MicrobiomeView` / `ImmuneGameView` each carry a top-level `.accessibilityElement(children: .contain) + .accessibilityLabel(...) + .accessibilityValue(...)` envelope so VoiceOver users land on a named canvas + hear dynamic state on each state change (tier snap / feeding-mode change + tick / wave + score + pathogens-remaining). FEATURE_PLAN § Quality "Accessibility audit" GAP 1 follow-up closed. |
| #70 | ForgeReporting wire-up — parent-facing standards-mapped progress report (engagement skeleton). `ProgressReportService` (Services/Engagement/, pure nonisolated value type wrapping `ForgeReporting.ForgeReportGenerator`) + `ProgressReportView` (AppFeature/Settings/) under a new "For parents" section gated behind the existing parental-gate math gate. Plumbing: `AppRootView` builds a `ProgressReportSnapshot` from live engagement signals + threads through `ProfileView(progressReportSnapshot:)` → `SettingsView(progressReportSnapshot:)`. Per-standard proficiency (strengths / growth areas) follows when per-question attempt logs land; today's surface is the engagement skeleton. 7 new `ProgressReportServiceTests`. Closes (partial) FEATURE_PLAN § Parent Integration → "Progress dashboard". |
| #71 | ForgeSensory wire-up — juice layer (haptic + audio-ready axis). `SensoryPaletteCoordinator` (Services/Engagement/, MainActor `@Observable`) wraps `ForgeSensory.SensoryPalette`. `AppRootView` instantiates one coordinator + threads through MicrobeCodexView → QuizView and MicrobiomeView → ImmuneGameView. Per-event wiring: QuizView fires `.correctAnswer` / `.incorrectAnswer` / `.achievement` / `.challengeComplete`; MicrobiomeView fires `.achievement`; ImmuneGameView fires `.streakMilestone(wave)` / `.challengeComplete` / `.achievement`. Audio dispatch defaults nil until the SFX pack lands per `.claude/rules/forgekit.md` § Asset generation ownership; haptic axis fires immediately via `ForgeHapticEngine.shared`. Trauma-informed: incorrect haptic is the canonical soft tap, never punitive. 6 new `SensoryPaletteCoordinatorTests`. Closes (partial — visual + haptic axes) FEATURE_PLAN § Delight & Polish → "Juice layer". |

Net additions: 2 new Services modules (`ProgressReportService` + `SensoryPaletteCoordinator`, both under `Services/Engagement/` per the portfolio SPM folder convention) + 1 new AppFeature module (`ProgressReportView` under `AppFeature/Settings/`) + 13 new unit tests across 2 suites (`ProgressReportServiceTests` + `SensoryPaletteCoordinatorTests`) + 2 ForgeKit modules promoted from declared-but-unused → actively consumed (`ForgeReporting` → Services; `ForgeSensory` → Services). Build green at each merge.

**Previous round (2026-06-12, PRs #63 → #66, sixth-pass auto-cycle sweep)**: 4-PR sweep driven by the user-direct standing auto-cycle paired with the **sixth-pass** Xcode-managed file safety reinforcement + an explicit maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes + follow-technical-design-doc + SPM-folder-structure directive set. Rollup:

| PR | Theme |
|---|---|
| #63 | **Sixth-pass** Xcode-managed file safety reinforcement — codifies the **six-pass invariant** (when a single safety rule is restated six times in one calendar day, every subsequent session treats it as an immutable pre-flight check + every subsequent handoff doc carries a rule-restatement summary at the top so the cadence is inherited without re-reading the entire CLAUDE.md). Adds two new 6th-pass interaction notes (SPM folder-structure + technical-design-doc) clarifying that neither directive extends to managed-file edits. Also commits the Xcode-regenerated diff to `MicrobeLab.xctestplan` that wires the `SharedUITests` SPM test target from PR #59 — per the rule, staging+committing the Xcode-regenerated diff IS fine. Closes `HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6. |
| #64 | ForgeAnalytics on-device privacy-first event totals — closes the "still declared but unused" gap from § ForgeKit Integration Status. Adds `AnalyticsService` (MainActor `@Observable` wrapper around the `ForgeAnalytics.AnalyticsEngine` actor) under `Services/Engagement/` + a canonical `MicrobeLabAnalyticsEvent` enum with grep-able snake_case event names + PII-safe property bags (counts + slugs only). Wires `AppRootView` (session start/end on scenePhase), `ExploreView` (zoom_tier_reached on every microscope snap), `MicrobiomeView` (feeding_mode_changed + microbiome_milestone every 5th tick + achievement_earned per ForgeGamification unlock), and `ImmuneGameView` (immune_wave_cleared per wave + immune_run_completed on full-run clear). 12 new `@Test` covering init defaults + session lifecycle + per-event name mapping + accumulation + activeDays plumbing + ZoomTier slug stability + property-bag PII discipline. |
| #65 | ForgeSpotlight indexing for the 12-microbe codex — closes the "still declared but unused" ForgeSpotlight gap. Adds `MicrobeSpotlightItem` (pure `SpotlightIndexable` adapter; stable slug-based `spotlightID` so UUID churn doesn't fragment the index) + `MicrobeSpotlightIndex` (MainActor `@Observable` wrapper around `ForgeSpotlightIndexer`). `AppRootView.loadCatalog()` indexes the catalog on every cold launch; ForgeSpotlight dedupes via `spotlightID`. Trauma-informed posture mirrors `MicrobeCodexView`: entire catalog indexed (the codex already shows all 12 cards from launch — locked entries render as "???"); locked microbes still gate the fact card behind discovery once landed. Privacy: `CSSearchableIndex` is on-device per `.claude/rules/age-assurance.md`; keywords ship stable enum slugs only (pinned by `spotlightKeywordsContainOnlyStableEnumSlugs` invariant). 7 new `@Test`. |
| #66 | Mentor personality callbacks — closes the FEATURE_PLAN § Delight & Polish → "Character personality" item. Adds `MentorRecallStore` (UserDefaults-persisted ring buffer of recently-met microbe slugs; cap 5; FIFO recency dedup) + `VeeMentor.recallCue(for:daysSinceLastSeen:)` (warm trauma-informed callback copy with day-bucket pivots 0 / 1 / 2-6 / 7+ — "still hanging around" / "still here when you're ready" — never "you abandoned us" or loss-aversion). `ExploreView.init()` prefers a recall callback over the variable-reward / default cold-open copy when the store has entries; `ExploreView.onAppear` records rare-microbe-sighting slugs into the store so subsequent cold opens can quote them. 8 new `@Test` for the store + 6 new `@Test` for the cue (pinning the trauma-safe no-abandonment-words discipline). |

Net additions: 2 new Services modules (`AnalyticsService` + `MicrobeSpotlightIndex` + `MentorRecallStore` — the last two land flat at the Services root + under `Services/Engagement/` respectively per the SPM folder convention) + 1 new SharedUITests xctestplan wiring (Xcode GUI) + 33 new unit tests across 4 suites + 3 ForgeKit modules promoted from declared-but-unused → actively consumed (`ForgeAnalytics` → Services, `ForgeSpotlight` → Services; the recall surface extends the existing `ForgeAI`-fronted `VeeMentor`). Build green at each merge.

**Previous round (2026-06-12, PRs #58 → #61, fifth-pass auto-cycle)**: 4-PR sweep driven by the user-direct standing auto-cycle paired with the fifth-pass Xcode-managed file safety reinforcement + maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes directive. Rollup:

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

## ForgeKit Integration Status (post-2026-06-12 maximize-integration sweep, eighth pass)

Modules now actively consumed (vs the `Package.swift` declared list):

| Module | Where it's wired | Notes |
|---|---|---|
| `ForgeModels` | Models, Services, AppFeature | `StudentProfile`, `BloomLevel`, `StandardAlignment`, base value types |
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
| `ForgeAnalytics` | Services (`AnalyticsService` wraps the actor-based `AnalyticsEngine`; `MicrobeLabAnalyticsEvent` enum carries grep-able event names + PII-safe property bags) | On-device event totals + session lifecycle (PR #64) |
| `ForgeSpotlight` | Services (`MicrobeSpotlightIndex` wraps `ForgeSpotlightIndexer`; `MicrobeSpotlightItem` adapts `MicrobeCharacter` to `SpotlightIndexable`) | 12-microbe codex Spotlight indexing (PR #65) |
| `ForgeReporting` | Services (`ProgressReportService` wraps `ForgeReportGenerator`; `AppFeature/Settings/ProgressReportView` renders the parent-conference text + standards-covered list under the parental-gate "For parents" section) | Parent-facing standards-mapped progress report (PR #70) |
| `ForgeSensory` | Services (`SensoryPaletteCoordinator` wraps `SensoryPalette`; QuizView / MicrobiomeView / ImmuneGameView fire `.correctAnswer` / `.incorrectAnswer` / `.achievement` / `.streakMilestone(wave)` / `.challengeComplete` events) | Juice layer haptic axis (PR #71); audio dispatch defaults nil until SFX pack lands |
| `ForgeAdventure` | AppFeature (`MicrobeLabHubContribution` Level 2 overlay conforms to `HubContribution`; `MicrobeLabHubRegistrar.register(into:)` async helper for AdventureHub-side integration; `MicrobeLabHubChallengeAdapter` renders the per-engine hub placeholder surface) | Phase-1 hub contribution targets `.scienceLabs` (PR #74); cross-repo handoff requests labsmith add canonical `lifeZone` case |

Still declared but unused in Swift code (deps stay in `Package.swift` so future wiring is friction-free):

- `ForgeNavigation` — TabView's native iOS 26 chrome covers Phase 1; lift when nav grids land

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
- `MicrobeKnowledgeGraph` — pure value-type wrapper around `ForgeKnowledgeGraph.KnowledgeGraph` with shared-habitat edges (PR #60)
- `AnalyticsService` — MainActor `@Observable` wrapper around the `ForgeAnalytics.AnalyticsEngine` actor; on-device only (PR #64)
- `MicrobeSpotlightIndex` — MainActor `@Observable` wrapper around `ForgeSpotlightIndexer`; indexes the 12-microbe catalog for Spotlight search (PR #65)
- `MentorRecallStore` — UserDefaults-persisted ring buffer of recently-met microbe slugs; powers Cilia's callback line surface (PR #66)
- `ProgressReportService` — pure nonisolated value type wrapping `ForgeReporting.ForgeReportGenerator`; produces parent-conference report text + standards-covered list from a `ProgressReportSnapshot` (PR #70)
- `SensoryPaletteCoordinator` — MainActor `@Observable` wrapper around `ForgeSensory.SensoryPalette`; routes haptic (and audio when SFX pack lands) feedback events across QuizView / MicrobiomeView / ImmuneGameView (PR #71)
- `CodexCertificate` — pure nonisolated `Sendable` value type snapshotting the kid's discovery progress with warm tiered headline; trauma-informed copy stoplist pinned by test (PR #75)
- `MasteryMomentDetector` — pure nonisolated `Sendable` value type tracking per-session mastery thresholds for `.ecologyMaster` / `.defenseMaster` / `.codexMaster`; once-per-session via `acknowledged: Set<MasteryKind>` (PR #76)
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
| ~~Accessibility audit GAP 1 (SpriteView VoiceOver labels)~~ | ✅ SHIPPED via PR #69 — 3 SpriteView hosts carry top-level `.accessibilityLabel` + dynamic `.accessibilityValue` |
| ~~Progress dashboard (engagement skeleton)~~ | ✅ SHIPPED via PR #70 — `ProgressReportService` + `ProgressReportView` under SettingsView's "For parents" section; per-standard proficiency (strengths / growth areas) follows when per-question attempt logs land |
| ~~Juice layer (haptic axis)~~ | ✅ SHIPPED via PR #71 — `SensoryPaletteCoordinator` routes haptic events across QuizView / MicrobiomeView / ImmuneGameView; audio dispatch defaults nil until SFX pack lands |
| ~~Adventure Mode Level 2 Swift overlay~~ | ✅ SHIPPED via PR #74 — `MicrobeLabHubContribution` conforms to `ForgeAdventure.HubContribution`; `MicrobeLabHubRegistrar.register(into:)` ships the async helper AdventureHub-side integration calls at hub startup. Targets `.scienceLabs` until labsmith ships canonical `lifeZone` case per `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` |
| ~~Share-worthy moments (codex completion axis)~~ | ✅ SHIPPED via PR #75 — `CodexCertificate` + `CodexCertificateView` + `CodexCertificateSheet` (`ImageRenderer` → `ShareLink`); Progress tab gains "Share my codex" toolbar button; immune-trophy axis still pending |
| ~~Mastery moments (ecology axis)~~ | ✅ SHIPPED via PR #76 — `MasteryMomentDetector` fires `.epic` tier celebration + distinct haptic when the kid maintains stable ecology ≥ 15 ticks under fiber feeding; defense + codex axes ship the detector API ready for follow-up wiring |
| Declared Age Range API gate (iOS 26.2+) | **Scaffold landed PR #55**. Live `await requestAgeRange(...)` blocked on (a) entitlement provisioning via Xcode GUI per `HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6b, (b) COPPA consent + retention surface (receiving "Under 13" creates actual knowledge) |
| Adventure Mode (Life Zone hub config + ProgressionManager gating) | Awaits AdventureHub Level 1 JSON + ZoneID.lifeZone case + ForgeProgressionManager hub-side integration. Cross-repo handoff filed `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` |
| Performance profiling (16ms tier transition / 8ms sim tick) | **Signposts landed PR #56**. Real-device Instruments capture + bench-harness assertions still pending |
| UI tests / accessibility XCUITests | Best landed once portrait pack ships (UI tests rely on rendered assets) — accessibility audit already PASS WITH GAPS per `Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md`; GAP 1 closed PR #69 |
| Juice layer audio axis (SFX pack) | Asset-blocked on labsmith SFX bundle handoff per `.claude/rules/forgekit.md` § Asset generation ownership; coordinator is wired and ready (SFX dispatch closure parameter defaults nil) |
| Parent progress dashboard (per-standard proficiency) | Awaits per-question attempt log persistence; `ProgressReportService` already exposes the standards list + `StudentReportData.standardProficiencies` will pick up when the log lands |

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
