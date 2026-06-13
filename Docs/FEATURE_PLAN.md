# MicrobeLab — Feature Plan

> **Seventh-pass rule-restatement summary** (top-of-doc per the seven-pass invariant codified 2026-06-12; verbatim user-direct, repeated SEVEN times in one calendar day — all-time portfolio record): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. staging and committing is ok."* Scope: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`. No checkbox below implies an edit to any of those paths; items that need them ship via `Docs/HANDOFF_TO_USER_<TOPIC>.md`. See `@CLAUDE.md` § Xcode-managed file safety for the canonical statement.
>
> Phased delivery roadmap. Mirrors the engineering breakdown in `@Docs/TECHNICAL_DESIGN.md`. Implementing sessions check off boxes as work lands; do not collapse phases — the per-phase exit criteria gate ship readiness.
>
> **SPM folder convention** (per `@CLAUDE.md` § SPM Folder Convention): new feature surfaces with ≥ 3 files (view + machine + service) land in a per-feature subdirectory under their target (e.g., `AppFeature/Onboarding/`, `AppFeature/Engagement/`). Add subdirs as the codebase grows; the flat-root pattern stays canonical SPM regardless.
>
> **Xcode-managed file constraint** (per `@CLAUDE.md` § Xcode-managed file safety): no item in this plan implies edits to `*.xcodeproj/*.xcscheme/*.xctestplan/Info.plist/*.entitlements/Package.resolved`. Items that need them ship via `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps.

## Phase 1: Microscope Foundations (MVP)

Core microscope-zoom loop, 12-character microbe cast, freshwater microbiome simulator, innate-immunity minigame, and AI Socratic mentor (Vee). NGSS MS-LS1-1 baseline + portfolio safety/COPPA bedrock.

### Scaffolding

- [x] Create Xcode project with thin app shell (`MicrobeLab/MicrobeLabApp.swift`)
- [x] Create `Packages/Libraries/Package.swift` with 6 targets (Models, Services, SharedUI, GameEngine, AIMentor, AppFeature)
- [x] Add ForgeKit dependency (remote GitHub URL, `from: "0.99.0"`)
- [x] Create stub source files for all targets
- [x] Verify build succeeds with zero warnings (via `swift build` — no Xcode reload)
- [x] Add `Packages/Libraries` to workspace (PR #14 — workspace + test plan now wire the 4 SPM test targets)

### Data Layer

- [x] Define value types: `MicrobeCharacter`, `MicrobiomeState`, `ZoomTier`, `GutSlot`, `FeedingMode`, `AntibioticState`, `GrowthRate`
- [x] Define SwiftData models: `PersistentMicrobeSession`, `PlayerProgress`, `EncounterLog`, `JournalEntry`
- [x] Create `VersionedSchema` (V1) with all models — `SchemaV1`
- [x] Create `SchemaMigrationPlan` (V1 only — start early) — `MicrobeLabMigrationPlan`
- [x] Bundle 12 microbe character catalog as JSON in `Services/Resources/microbes.json`
- [x] Create `MicrobeCatalogService` to load + query microbe data
- [x] Create value-type cache structs (`PlayerProgressData`, `EncounterLogData`, `JournalEntryData`, `MicrobeSessionData`)

### Microscope Engine

- [x] Implement `ZoomTier` enum + transition rules (1× → 100× → 1000× → 10000×)
- [x] Implement `MicroscopeScene` skeleton (SpriteKit) with lazy visual setup + `.resizeFill` scaleMode
- [x] Implement pinch-to-zoom gesture handler + tier boundary snap (via `ZoomMachine` + `MicroscopeScene.handlePinch(delta:)`)
- [ ] Implement LOD sprite atlas + per-tier sprite swap (asset-blocked on microbe portrait pack)
- [x] Implement `ZoomMachine` view-local state machine
- [x] Implement microscope HUD overlay (tier badge + zoom level) — `MicroscopeHUD` in SharedUI, wired into ExploreView with mentor-cue refresh on snap

### Microbiome Simulator

- [x] Implement `MicrobiomeState` value type (populations + feeding mode + antibiotic state + tick count)
- [x] Implement `FeedingMode` enum (fiber / sugar / balanced / none) + per-microbe growth-rate effects
- [x] Implement `AntibioticState` enum (none / active / recovering) + recovery-curve mechanics
- [x] Implement `MicrobiomeSimulator` per-tick update logic
- [x] Implement `GutSlot` ecology zones (oralCavity / stomach / smallIntestine / largeIntestine / colon + skin + soil)
- [x] Implement `SimulationMachine` view-local state machine
- [x] Implement deterministic seedable RNG for reproducible test states (`SeededRNG` splitmix64; `tick(_:using:)` overload threads jitter)

### Immune Response Engine (innate path)

- [x] Implement `MacrophagePacmanScene` skeleton (SpriteKit) — Pac-Man-style consume-pathogen loop
- [x] Implement pathogen spawn + wave progression (pure-value logic in `MacrophagePacmanScene` + `PathogenState` / `PathogenKind` in Models)
- [x] Implement macrophage movement + boundary handling (`moveMacrophage(by:)` clamps to scene bounds; `consumePathogensInRadius()` awards points)
- [x] Implement scoring + 5-wave Phase-1 progression (logic-level: `recordConsume(_:)` + `clearWave()`)
- [x] Wire scene into `GameEngine` target with lazy visual setup

### 12-Character Microbe Cast

- [x] Define 12 named microbes (Lacto / Yeast / Photo / Net / Spore / Guard canonical DN cast + Bifido / Akker / Strep / Coli / Rhino / Deino codex-supporting)
- [x] Bundle character JSON metadata in `Services/Resources/microbes.json` (v2 schema includes voiceLines)
- [ ] Bundle character portrait WebPs in `Resources/Cast/<slug>.webp` (12 portraits; await hub distribution per `.claude/rules/forgekit.md` § Asset generation ownership)
- [ ] Wire `ForgeIllustrations.IllustrationRegistry` registration (awaits portrait pack)
- [x] Implement per-character voice lines per DN voice register card — `voiceLines: [String]` on `MicrobeCharacter`; `VeeMentor.voiceLine(for:rotation:)` rotates lines deterministically; backward-compatible Decoder default for v1 catalogs

### SwiftUI Views

- [x] Create 5-tab `TabView` (Explore / Codex / Microbiome / Progress / Profile) shell + bundled-catalog bootstrap
- [x] Build `ExploreView` wrapping `MicroscopeScene` via `SpriteView` (tier-badge HUD + mentor bubble)
- [x] Build `MicrobeCodexView` (12-microbe grid; locked entries show "???" until discovered) — **ecology surfacing landed PR #60**: `MicrobeKnowledgeGraph` (Services/) wraps `ForgeKnowledgeGraph.KnowledgeGraph` with shared-habitat edges (symmetric, `.recommended` strength) derived from `MicrobeCharacter.preferredEnvironment`. The view builds the graph once on appear; each discovered card surfaces up to 2 already-discovered ecology neighbors via a small "Lives near: X, Y" caption. Trauma-informed posture: neighbors are filtered to the kid's discovered set so the codex never hints at undiscovered microbes (no shame-mining "you haven't met X yet" framing). 9 unit tests pin graph construction + neighbor ordering + limit + exclude-self + unknown-slug handling.
- [x] Build `MicrobiomeView` wrapping simulator with feeding-mode + antibiotic controls
- [x] Build `ImmuneGameView` wrapping `MacrophagePacmanScene` — reached via NavigationStack toolbar in MicrobiomeView; ships trauma-safe off-ramp + score HUD
- [x] Build `ProgressTabView` with XP / streak / codex grid
- [x] Build `ProfileView` with `ForgeAvatar.AvatarStudioView(.lite)` sheet — `AvatarStudioSheet` seeds the ForgeID via `getOrCreateForgeID(displayName:)` in `.task` before the editor opens (R489 gotcha), reads back `currentForgeID()?.avatar` on appear so the row shows the saved look
- [x] Build `SettingsView` with parental gate (`AppSettings` + `AppSettingsStore` in Services; `ParentalGateView` math gate; sensory toggles kid-accessible, content gate + session cap parent-gated)
- [x] Build `QuizView` for question kits — wired from MicrobeCodexView toolbar Menu; `QuestionKit` + `Question` in Models; `QuestionKitService` loader; `QuizMachine` in SharedUI; kit 01 (microbiology basics, 5 questions) bundled

### AI Mentor (Vee — Socratic)

- [x] Create `VeeMentor` class with lazy `LanguageModelSession`
- [x] Implement `MicrobeFact` `@Generable` with curriculum-guarded fallbacks for all 12 microbes
- [x] Implement `ZoomCue` `@Generable` for tier-transition Socratic prompts
- [x] Implement `EcologyHypothesis` `@Generable` for microbiome puzzle scaffolding
- [x] Implement static fallbacks for every `@Generable` per `.claude/rules/foundationmodels.md`
- [x] Create mentor speech-bubble UI component — `SharedUI.MentorBubble` with thinMaterial backdrop + combined accessibility label
- [x] Wire mentor to events: microscope tier-up, microbiome milestone, immune wave-clear — `ExploreView` refreshes cue on tier snap; `MicrobiomeView` refreshes on feeding-mode change + every 5th tick milestone; `ImmuneGameView` surfaces a wave-clear cue on bubble (run-end + per-wave variants)

### Gamification

- [x] Integrate ForgeGamification `XPEngine` for leveling (wrapped in `GamificationService` MainActor `@Observable`)
- [x] Integrate `StreakManager` for daily engagement (`recordSession()` async surface; `currentStreak` / `longestStreak` mirrored to the `@Observable`)
- [x] Integrate `AchievementEngine` with first 10 Phase-1 achievements (`MicrobeLabAchievements.phase1` set defined; `evaluateAchievements(with:)` grants + auto-XP-awards)
- [x] Wire question kits 01-04 via `Bundle.module` (microbiology basics / microbiome / immune defense / beneficial microbes) — all four phase-1 kits ship via `QuestionKitService.phase1KitSlugs`
- [x] Implement XP awards for: first microbe discovered, microbiome stable for 5 ticks, immune wave cleared, etc. — quiz-completion XP + first-quiz / quiz-perfect achievements wired; microbiome (`fiberPioneer` / `sugarTrial` / `microbiomeSteady`) + immune (`immuneRookie` / `immuneRunner`) achievements now auto-evaluate via `MicrobiomeView` + `ImmuneGameView` calling `GamificationService.evaluateAchievements`, which auto-awards XP per achievement definition

### Adventure Mode

- [ ] Wire Level 1 config from `spark-anvil-hub/Resources/HubContributions/microbelab.json` (Life Zone contribution)
- [ ] Implement `MicrobeLabHubContribution` Level 2 Swift overlay in `Packages/Libraries/Sources/AppFeature/HubContribution/`
- [ ] Register mode-cards in `AdventureView`
- [ ] Wire `ForgeProgressionManager` gating across mode-cards

### Onboarding

- [x] Create 5-step onboarding flow (welcome, first zoom-in, meet first microbe, first observation, first quiz) — `MicrobeLabOnboardingFlow` wraps `ForgeUI.ForgeOnboardingFlow`; `OnboardingMachine` value-type state + `OnboardingStore` UserDefaults persistence; gated at `AppRootView` before the tab shell
- [x] Implement aha moment: first microscope zoom reveals a character introducing themselves — onboarding step 3 introduces Lacto verbatim ("one of trillions of tiny lives that help you digest food"); `ExploreView` mentor-bubble cue refreshes on tier snap (the in-app aha continues after onboarding completes)
- [x] Implement progressive disclosure (Session 1: microscope + codex only) — `SessionCountStore` (UserDefaults monotonic counter) + `TabDisclosure` (pure mapping: count < 2 → Explore + Codex; 2-3 → + Microbiome; 4+ → full chrome incl. Progress + Profile); wired into `AppRootView.tabShell`; increment fires only after onboarding completes so the 5-step flow isn't counted as session #1
- [x] Implement parent handoff flow (30s setup) — `ParentHandoffFlow` (AppFeature/Onboarding/) wraps a 4-step value-type `ParentHandoffMachine` (welcome → content comfort → daily session cap → ready). Persists choices into `AppSettings` (disease-story gate + daily cap); flips `ParentHandoffStore.hasCompletedHandoff` (Services/) on completion. AppRootView gates the kid-facing `MicrobeLabOnboardingFlow` behind the parent handoff so a grown-up confirms preferences ONCE before handoff. No PII captured (binary completion flag only) per `.claude/rules/age-assurance.md` § 2026 FTC COPPA.
- [/] Apple Declared Age Range API gate (iOS 26+) — **scaffold landed**. `Services/AgeAssuranceService.swift` (MainActor `@Observable`) holds the most-recent verification result + the `AgeAssuranceCapability.isDeclaredAgeRangeAvailable` entitlement probe (reads `Bundle.main`'s `Entitlements` dict). `SettingsView` → About surfaces a passive readout ("Math gate — Apple gate pending entitlement" until the entitlement lands; flips to "Declared Age Range API ready" after). ForgeKit's `ForgeSystemAgeGate` already implements the system request + math-gate fallback. **Entitlement provisioning** is documented in `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6b — agent cannot author `.entitlements` files from disk (per CLAUDE.md § Xcode-managed file safety). The `requestSystemVerification(...)` method is a stub that no-ops + records `.notAttempted`; replace with the live `await requestAgeRange(...)` call only when the COPPA consent + retention surface ships (per `.claude/rules/age-assurance.md` — receiving "Under 13" creates **COPPA actual knowledge**, all consent flows immediately apply). 9 unit tests pin the scaffold (init defaults / recordResult / unavailable path / entitlement probe / key constant / result equality).

### Quality

- [x] Unit tests for microbiome simulator (feeding modes / antibiotic shock / recovery curve) — `MicrobiomeSimulatorTests` + `MicrobiomeStateTests` + `SimulationMachineTests`
- [x] Unit tests for zoom-tier transitions — `ZoomMachineTests` + `ZoomTierTests` + `MicroscopeSceneTests`
- [x] Unit tests for cast catalog loading + integrity — `MicrobeCatalogServiceTests` (bundled-load + canonical DN cast presence + beneficial-microbe foregrounding + unique-slug guard + voice-line integrity)
- [ ] UI tests for microscope + codex flow
- [ ] UI tests for microbiome puzzle
- [x] Accessibility audit (VoiceOver / Dynamic Type / color contrast) — read-only audit at `Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md`. Covers all SwiftUI surfaces shipped through PR #50; documents PASS / GAP per surface. Verdict: **PASS WITH GAPS** — Dynamic Type + color contrast PASS portfolio-wide (semantic font tokens, lowest contrast = `Color.primary.opacity(0.08)` solid fallback ≥ 4.5:1); 3 prioritized gaps identified (GAP 1: SpriteView hosts lack top-level VoiceOver labels — ~1h fix; GAP 2: 2 not-yet-swept thinMaterial sites in `ProgressView` + `QuizView` content cards — defer per Liquid Glass content-card policy; GAP 3: ParentHandoffFlow card material — bundle with next AppFeature touch). Recommendation: land GAP 1 + GAP 3 ahead of App Store submission; GAP 2 + SpriteKit action-duration clamp on Reduce-Motion can defer to Phase 2. Reviewer XCUITest `performAccessibilityAudit(for:)` coverage lands when the UI test surface lands. **GAP 1 closed PR #69**: `ExploreView` / `MicrobiomeView` / `ImmuneGameView` each carry a top-level `.accessibilityElement(children: .contain) + .accessibilityLabel(...) + .accessibilityValue(...)` envelope on the `SpriteView` host so VoiceOver lands on a named canvas + hears dynamic state (current tier / feeding mode + tick / wave + score + pathogens-remaining) on every snap. Asset-blocked items (LOD sprite per-microbe labels) still inherit when the portrait pack ships.
- [/] Performance profiling (microscope tier transition < 16ms; simulator tick < 8ms) — **signpost probes shipped**. `PerfSignpost` (Models/) wraps `OSSignposter` with 3 portfolio-canonical channels (`zoom` / `simulator` / `immune`). Wired into `MicroscopeScene.handlePinch(delta:)` + `MicroscopeScene.snapToTier(_:)` (tier transition), `MicrobiomePuzzleScene.advanceOneTick()` (per-tick budget), `MacrophagePacmanScene.advancePathogens(by:)` (immune wave). The signposts are zero-overhead in release builds (Apple's unified logging absorbs them) so they stay safe to leave in production. Open Instruments → Points of Interest → filter `com.microbelab.app` to verify the budget. Bench-harness + per-test latency assertions still pending — wires once a real device + Instruments capture lands the baseline.

**Exit criteria**: first session reaches aha moment in ≤ 60 seconds; microbiome simulator stable across 100 ticks; immune Pac-Man playable end-to-end; 4 question kits ship; 12 cast members visible in codex.

---

## Phase 2: Adaptive Immunity + Microbiome Expansion

Adaptive B-cell antibody-matching minigame, expanded microbiome ecology (oral + skin + soil microbiomes), and 4 more question kits.

- [ ] Implement `BCellAntibodyMatchScene` (SpriteKit) — pattern-match antibodies to antigens
- [ ] Implement adaptive-immunity progression curve (innate-first → adaptive unlocks)
- [ ] Expand `GutSlot` to include oral / skin / soil ecologies
- [ ] Bundle 8 additional microbe characters (20 total)
- [ ] Implement oral-cavity microbiome scene (plaque ecology)
- [ ] Implement skin-microbiome scene (eczema-safe framing per `.claude/rules/trauma-informed-content.md`)
- [ ] Implement soil-microbiome scene (decomposer ecology bridge to bioforge/ecosphere)
- [ ] Integrate question kits 05-08 (adaptive immunity / oral biome / skin biome / soil biome)
- [ ] Add 8 Phase-2 achievements
- [ ] Add ForgeAdventure mode: Antibody Lab (timed antigen-matching)
- [ ] Wire `MicrobeKnowledgeGraph` cross-microbe ecology edges
- [ ] Expand mentor `@Generable` set with adaptive-immunity hypotheses

**Exit criteria**: adaptive minigame integrated; 20-microbe cast complete; 8 question kits live; cross-microbiome navigation works.

---

## Phase 3: Disease Stories + Vaccines

Disease-narrative arcs (always trauma-informed; COVID-sensitive framing), vaccine mechanics, and historical-microbiology context cards.

- [ ] Author 4 disease-story arcs (chosen for kid-developmental safety; coordinate with SAMHSA register per `.claude/rules/trauma-informed-content.md`)
- [ ] Implement vaccine-mechanism mini-explainer (antibody-priming visualization)
- [ ] Bundle historical context cards (Pasteur / Koch / Salk / portfolio cast)
- [ ] Implement disease-story narrative scenes (chunky-cartoon register; no graphic illness imagery)
- [ ] Add 4 disease-themed achievements
- [ ] Integrate question kits 09-12 (vaccines / herd immunity / hygiene / public health)
- [ ] Implement crisis-resource surfacing if despair signals detected (per portfolio trauma-informed gate)
- [ ] Expand mentor `@Generable` with public-health framing
- [ ] Add parent/educator explainer at the disease-story phase boundary (opt-in)

**Exit criteria**: 4 disease arcs ship; vaccine mini-explainer playable; crisis-resource surface implemented; SAMHSA register reviewed.

---

## Phase 4: Microbiome Worlds + Classroom

Cross-microbiome global tour, classroom integration, and App Store submission readiness.

- [ ] Implement global-microbiome tour (Yellowstone hot-spring / deep-sea vent / human gut comparison)
- [ ] Add extremophile microbe characters (4 more — 24 total)
- [ ] Implement seasonal-microbiome simulation (winter cold + spring allergy seasons — trauma-safe framing)
- [ ] Integrate question kits 13-16 (extremophiles / global microbiome / microbiome research / synthesis)
- [ ] Add 8 advanced achievements
- [ ] Add classroom mode (ForgeKit `ForgeClassroom` integration when 0.94+ module wires)
- [ ] Add parent/educator progress reports (`ForgeReporting`) standards-mapped to NGSS MS-LS1-1/2/3 + MS-LS2-3
- [ ] App Store submission preparation (privacy nutrition label / KIDSAFE plan / parental gates)
- [ ] App Store screenshot + preview-video assets (await hub distribution per portfolio pipeline)

**Exit criteria**: full 24-character cast; 16 question kits; classroom mode wired; App Store metadata complete.

---

## Phase: Onboarding & Child Safety

COPPA compliance, parental consent, age gates, and first-time experience polish. Runs in parallel with Phase 1 — must land BEFORE TestFlight.

### Onboarding & Child Safety (Excellence Framework)

- [ ] **First 60 Seconds experience** — Vee introduction → microscope zoom-in → first microbe meet → celebration → curiosity hook
- [ ] **Aha moment design** — The "I just saw a microbe" moment in session 1
- [x] **Parent handoff flow** — `ParentHandoffFlow` ships a 4-step ~30s setup (welcome → content comfort → daily session cap → ready) that persists into `AppSettings` + flips `ParentHandoffStore.hasCompletedHandoff`. AppRootView gates the kid-facing 5-step onboarding behind it so the grown-up confirms preferences ONCE before handoff. Age question stays deferred to the Apple Declared Age Range API gate item; this surface is preference-capture only — no PII persisted (binary flag).
- [ ] **Age gate** — Apple Declared Age Range API on iOS 26+
- [ ] **Parental consent service** — COPPA-compliant consent; annual re-consent per 2026 FTC
- [x] **Privacy policy** — Plain-language policy accessible from Settings. Canonical doc lives at `Docs/PRIVACY_POLICY.md`; in-app surface `PrivacyPolicyView` (AppFeature/Settings/) renders a sectioned ScrollView with the same plain-language copy (one-line version → what we don't do → what lives on your device → on-device AI → parents + COPPA → crisis resources → questions → changes-to-this-policy). Inline Swift String keeps the view self-contained (no Bundle.module resource processing surprises in production); when the canonical doc changes, both copies update together in the same PR. Wired into `SettingsView` via NavigationLink from the About section's "Privacy policy" row. Settings now wraps the Form in a `NavigationStack` so the NavigationLink resolves. App Store listing surface inherits from the canonical doc when submission ships.
- [ ] **Parental gates** — Required for external links and data-sharing permissions
- [x] **Progressive disclosure** — Session 1: microscope + codex only → Sessions 2-3: + simulator (Microbiome tab) → Sessions 4+: full feature set incl. Progress + Profile. Shipped via `SessionCountStore` + `TabDisclosure` pure-mapping enum + `AppRootView.tabShell` conditional `Tab(...)` blocks

### Engagement Foundation (Excellence Framework)

- [x] **Streak system** — `StreakStore` (UserDefaults persistence of current / longest / freezes / lastRecordedAt) + `GamificationService.hydrated(from:)` so cold launches read yesterday's state; `recordSession` flushes through the store after the StreakManager actor returns. **Warm broken-streak messaging** lands via `StreakRescueOverlay` (AppFeature/Engagement/) gated on the pure `StreakRescue.from(lastRecordedAt:priorStreak:)` derivation (≥ 2 calendar-day gap with a prior streak ≥ 1 surfaces "The microbiome missed you" copy; long-streak / short-streak / fresh variants in `bodyCopy`). Streak-freeze mercy-day wiring continues to come from ForgeKit's actor; the kid's `availableFreezes` defaults to 2 + persists per session.
- [x] **DDA engine** — Invisible difficulty adjustment across microbiome puzzles + immune game wave count. `DifficultyAdjuster` (Services/Engagement/) is a pure nonisolated value type with three bands (`.introductory` / `.standard` / `.challenging`); `DifficultyAdjuster.from(sessionCount:simplifyChallenge:)` derives the band at session boundaries (1-2 → introductory; 3-4 → standard; 5+ → challenging). Outputs: `immuneWavePathogenCounts(totalWaves:)` (replaces the hardcoded `[4,6,8,10,12]` in `MacrophagePacmanScene`; `.introductory` uses `[3,4,5,6,7]`, `.challenging` `[5,7,9,11,13]`) + `microbiomeSteadyTickThreshold` (6 / 10 / 14). Wired through `AppRootView.tabShell` into `MicrobiomeView` + `ImmuneGameView`. Parent-gated `AppSettings.simplifyChallenge` toggle (Settings → Content gates) pins the band to `.introductory` regardless of session count for kids who want the chill mode permanently. **Trauma-informed posture**: the curve only ever ramps UP from `.introductory`; repeated resets never escalate difficulty. AppSettings now ships a custom decoder so adding fields doesn't invalidate the entire persisted struct.
- [x] **Session targeting** — `SessionTargetService` + `SessionTargetMachine` track the 10-15 min target window per ForgeKit's portfolio default; `phase` returns `.focused` / `.inTarget` / `.overTarget`. UI consumer `SessionNudgeOverlay` (AppFeature/Engagement/) surfaces a trauma-safe gentle stretch suggestion at the in-target boundary (once per session) and a softer pause suggestion past the upper bound; refresh cadence via `TimelineView(.periodic(by: 30))` so the service stays pure
- [x] **Variable rewards** — `VariableRewardSelector` (Services) deterministic-per-session selector with portfolio salt + ~1 in 5 hit cadence (splitmix64 mixer of `(salt, sessionCount)`); returns `.rareMicrobeSighting(slug:)` or `.specialMentorMoment`. `ExploreView` consumes via `init(sessionCount:)` + the static `copy(for:catalog:)` helper that quotes the canonical microbe display name. Trauma-informed copy framed as "hanging around today" / "quiet day under the lens" — never as a chase / loss-aversion mechanic. Hidden-codex-entry reward variant deferred until the codex-discovery surface ships its hidden-entry plumbing.
- [x] **Return loop** — Welcome-back flow for 3+ day lapsed users: `LastActiveStore` UserDefaults-persists last-session timestamp; `AppRootView` surfaces `WelcomeBackOverlay` (warm greeting, trauma-safe copy) when `daysSinceLastActive ≥ 3`. Recap surface deferred to follow-up.
- [x] **Retention metrics baseline** — D1 / D7 / D30 cohort signal via `RetentionMetricsStore` (Services/Engagement/). Persists install date + a bounded ring of distinct calendar-day session stamps (cap 32) to UserDefaults; derives `returnedWithinD1` / `D7` / `D30` + `totalDistinctSessionDays`. Privacy-first: counts only, never an event log; stays on-device per `.claude/rules/age-assurance.md` § Portfolio Status. Wired into `AppRootView.task` alongside `sessionCount.incrementForSessionStart()` after onboarding completes. 10 unit tests cover empty / single-day / D1 / D7 / D30 / beyond-window / persistence / capacity / clear paths.

**Exit criteria**: aha moment within 60s; DDA holds flow; engagement loop creates intrinsic return motivation.

---

## Phase: Delight & Parent Integration

Audio/visual/haptic polish, parent-facing dashboards, and emotional design. Runs after Phase 2 minimum.

### Delight & Polish

- [/] **Juice layer** — Visual + audio + haptic trifecta on every interaction (with iPad haptic fallback). **Visual + haptic axes shipped PR #71**: `SensoryPaletteCoordinator` (Services/Engagement/, MainActor `@Observable`) wraps `ForgeSensory.SensoryPalette`. `AppRootView` instantiates one coordinator + threads it through `MicrobeCodexView` → `QuizView` and `MicrobiomeView` → `ImmuneGameView`. Per-event wiring: QuizView fires `.correctAnswer` / `.incorrectAnswer` on reveal + `.achievement` on per-unlock + `.challengeComplete` on kit-finish; MicrobiomeView fires `.achievement` on per-unlock; ImmuneGameView fires `.streakMilestone(wave)` per wave-clear, `.challengeComplete` on full-run clear, and `.achievement` per immune-defense unlock. The audio dispatch path stays defaulted-nil until the SFX pack lands per `.claude/rules/forgekit.md` § Asset generation ownership — palette plays haptics + `lastEvent` observation immediately. Visual axis remains on `CelebrationCoordinator` (PR #53). 6 new `SensoryPaletteCoordinatorTests` pin init / mirror / monotonic counter / associated-value handling / mascotReaction payload / independent-instances. iPad haptic fallback inherits from `ForgeHapticEngine.shared.playSync(...)` per ForgeKit's canonical engine.
- [x] **Celebration system** — Proportional ForgeCelebration `CelebrationCoordinator` wired at `AppRootView` (single coordinator instance applied via `.celebrationOverlay(coordinator)` on the tab shell), passed down to `MicrobeCodexView` → `QuizView`, `MicrobiomeView` → `ImmuneGameView`. Tier rules: per-wave immune clear → `.medium` (subtle sparkle); full immune run → `.epic` "Defense run complete" (full-screen Lottie via `game-complete` slug with emoji + headline fallback); quiz perfect → `.epic` via `perfectRound(count:)`; quiz near-perfect (n-1 right) → `.major`; quiz partial → `.small` acknowledgement; per-achievement unlock in microbiome → `.major` via `badgeEarned(title:)`. Mentor bubble carries the educational meta-voice; celebration overlay carries the visual/haptic juice — both coexist because `CelebrationOverlayModifier` renders in the view's own overlay envelope while `MentorBubble` renders inline. `CelebrationCoordinator`'s built-in cooldown + tier-precedence rules keep events from stacking. Cinematic "first microbe of new microbiome" still pending the codex-discovery wiring + portrait pack.
- [/] **Micro-delight coverage** — All 8 types: celebration, surprise, personality, mastery, social, sensory, agency, discovery. **Agency partial via PR #59** — Quiz "Hint" button (ForgePedagogy `HintTier` scaffolding via `QuestionHintStrategy` + `QuizMachine.requestNextHint()`) lets the kid escalate vague → medium → specific at their own pace; trauma-informed completion-panel framing ("Asked for help on N — that's how learning works"). Remaining axes (mastery / social / surprise / discovery) ride follow-up PRs.
- [/] **Character personality** — `MentorRecallStore` (Services/Engagement/, MainActor `@Observable` + UserDefaults-persisted ring buffer cap 5; FIFO recency dedup) + `VeeMentor.recallCue(for:daysSinceLastSeen:)` give Cilia a warm callback layer that quotes microbes the kid has previously "met". Day-bucket pivot (0 / 1 / 2-6 / 7+) drives trauma-informed framing: same-day reads as "still hanging around from earlier today", multi-day reads as "still here when you're ready" — pinned by `longGapCueAvoidsAbandonmentFraming` test (no "missed" / "abandon" / "forgot"). `ExploreView.init()` prefers a recall callback over the variable-reward / default cold-open copy when the store has entries; `.onAppear` records rare-microbe-sighting slugs into the store so subsequent cold opens can quote them. Cast-member quirk lines per DN voice register continue to surface via `VeeMentor.voiceLine(for:rotation:)`. (PR #66, 2026-06-12)
- [ ] **Mastery moments** — Distinct screen ripple + chord when child internalizes microbiome ecology
- [x] **Easter eggs** — Hidden rare-microbe encounters rewarding curious zoom exploration. `EasterEggDetector` (Services/Engagement/) is a pure nonisolated value type that tracks per-session zoom-tier visit history; `record(visit:)` returns `true` on the snap that completes all four tiers. `ExploreView` owns the detector as `@State`, surfaces a one-shot mentor cue ("You walked the whole range today. \(microbeName) usually only shows up for the careful ones — thanks for looking.") when the kid hits all 4 tiers, then acknowledges so it doesn't re-trigger mid-session. Microbe pick is deterministic per session via a splitmix64 mixer with a salt distinct from `VariableRewardSelector.appSalt` so the two engagement surfaces decorrelate. Trauma-informed posture: warm recognition, never loss-aversion ("you missed it"); the easter egg can re-trigger across sessions but never within one.
- [ ] **Share-worthy moments** — Codex completion certificates; immune-game high-score trophies

### Parent Integration

- [/] **Progress dashboard** — Parent-facing standards-mapped view (NGSS MS-LS1-1 / MS-LS1-3 etc.). **Engagement skeleton landed PR #70**: `ProgressReportService` (Services/Engagement/, pure nonisolated value type) wraps `ForgeReporting.ForgeReportGenerator`, building a `StudentReportData` snapshot from live engagement signals (session count / total time / streak / longest streak / XP / achievement count / distinct session days) and rendering the canonical `ForgeReportGenerator.parentConferenceReport(_:)` text. `phase1Standards` exposes the 4 NGSS MS-LS standards + 2 NHES standards the Phase 1 kits ship with so the parent surface lists "Standards covered" without runtime catalog scans. `ProgressReportView` (AppFeature/Settings/) is a sectioned Form that surfaces engagement counts + standards-covered list + the generated parent-conference text (selectable + monospaced for screen-reader friendliness). `SettingsView` gains a "For parents" section gated behind the existing `ParentalGateView` math-gate; the section only appears when `AppRootView` plumbs an optional `ProgressReportSnapshot` through `ProfileView` → `SettingsView`. Trauma-informed posture: counts only, on-device only, anonymous `displayName` default ("your kid"). Per-standard proficiency surfaces (strengths / growth areas) follow when per-question attempt logs land — `ForgeReportGenerator` gracefully skips those sections when empty, so the today-shipped surface is the engagement skeleton. 7 new `ProgressReportServiceTests` pin the phase1Standards coverage + reportData mapping + averageSessionMinutes division-by-zero safe / parentReportText anonymity + low-sessions recommendation flow + empty-standards skip + NGSS/.custom framework assignment.
- [x] **Parental controls** — Daily session time limits (default 30 min) + content-comfort filters (e.g., disease-story arc opt-in). ForgeKit `SessionTimerService` (actor) is the source of truth for cumulative on-device daily time; `DailyTimeCoordinator` (Services/Engagement/, MainActor `@Observable` wrapper) adapts the actor for SwiftUI consumption. AppSettings.dailySessionCap drives the cap (15 / 30 / 45 / 60 / unlimited); the wrapper rebuilds the underlying `SessionTimerConfig` on cap change. `unlimited` collapses to a 24h cap so the timer never trips. AppRootView wires start/end/pause/resume against `scenePhase` (active → start, background → endSession flush, inactive → pause). When the kid crosses the cap, `DailyCapOverlay` (AppFeature/Engagement/) surfaces a centered trauma-safe wrap-up: warm "Great session" copy with a single "See you next time" acknowledgement; never force-quits the app. Centered-overlay priority places the daily-cap above streak-rescue / welcome-back so the kid sees a calm wrap-up on the launch they crossed the cap. Disease-story content-comfort filter is wired via the parent-handoff flow's `diseaseStoryGateEnabled` preference (defaults ON; pre-Phase-3 has no surfaces to gate). 5 unit tests pin the coordinator's MainActor wrapper behaviors (init defaults / explicit cap / unlimited acceptance / idempotent updateCap / cap swap).
- [ ] **Weekly summary** — Opt-in progress notification (strengths, growth areas, recommendations)
- [x] **Session closer** — End-of-session summary surface. `SessionSummary` (Services/Engagement/) is a pure nonisolated value type that captures a frozen snapshot of session-relevant stats (currentLevel / totalXP / currentStreak / microbesDiscovered / achievementsEarned) at the moment the kid taps "Wrap up today" in the Progress tab; future-session activity doesn't retroactively change a summary the kid has seen. `SessionSummarySheet` (AppFeature/Engagement/) renders the snapshot as a `presentationDetents([.medium])` sheet with warm headline ("Quiet today — that's allowed" / "Solid session" / "You explored a lot today" branches), stats grid, and gentle next-session preview ("pick up where we left off" / "try a different feeding mode"). Trauma-informed: the sheet NEVER frames the streak as a threat or absence as failure. Wired into `ProgressTabView` via a toolbar "Wrap up today" button. 6 unit tests pin the trauma-safe copy invariants (zero-streak preview never mentions the broken streak; quiet-session headline always includes "allowed"). **Auto-surfacing on app background landed PR #61** — `AppRootView` stamps `sessionStartedAt` + `sessionStartXP` on cold launch + every `.background → .active` resume; on `.background` the productivity gate fires (`captureSessionSummaryIfProductive`) requiring elapsed ≥ 60s AND XP earned > 0; the next `.active` surfaces `pendingSessionSummary` via `.sheet(isPresented:)` UNLESS the daily-cap / welcome-back / streak-rescue overlays have precedence in the centered-overlay priority chain. Trauma-informed: short backgrounds (notification check) NEVER fire the summary; quiet sessions (0 XP) NEVER fire it; the summary only celebrates earned engagement.

---

## Phase: Accessibility & Trauma-Informed Polish

- [ ] VoiceOver labels for every microscope LOD sprite + cast portrait
- [ ] Dynamic Type support across all SwiftUI views
- [ ] Color-contrast audit (WCAG AA in default + dark + high-contrast themes)
- [x] Reduce-Motion variants for celebration + tier-transition animations — `A11yPreferences` (Services/) is a pure nonisolated value type that OR-combines the system `accessibilityReduceMotion` env with the parent-gated `AppSettings.forceReduceMotion` toggle. Wired into `AppRootView` (overlay morph + animation), `SessionNudgeOverlay` (slide-from-top transition + easeInOut), and the two centered overlays (`WelcomeBackOverlay` / `StreakRescueOverlay` no longer scale-morph when Reduce-Motion is active). Scene-side tier-transition + celebration polish lands with the LOD sprite atlas item (still asset-blocked).
- [x] Reduce-Transparency variants for any glass UI (per portfolio Liquid Glass policy) — same `A11yPreferences` surface. `SharedUI.MentorBubble` + `SharedUI.MicroscopeHUD` read `@Environment(\.accessibilityReduceTransparency)` directly (system-only — they're outside the AppSettings dep graph); AppFeature-level overlays (`AppRootView`, `SessionNudgeOverlay`, the two centered overlays) combine system + force via the resolver. Glass surfaces swap to a solid `Color.primary.opacity(...)` fill that adapts to light/dark mode. Liquid Glass on Chrome (TabBar / NavBar / etc.) stays unmodified per portfolio policy.
- [ ] Trauma-informed gate review for disease-story arcs (SAMHSA TIP 57 register; off-ramps + crisis-resource surface; cultural-context note for global-microbiome cards)
- [x] Crisis-resource list (988 / Childhelp / Crisis Text Line) surfaced from Settings — `CrisisResources` (Services) is a pure nonisolated value type with the portfolio-canonical safety hotlines + a `CrisisResource` row struct (id / title / subtitle / actionLabel / actionURL). `CrisisResourceCard` (AppFeature/Settings/) renders a Form section with one tappable row per resource; taps deep-link into the system phone / messages app via `tel:` / `sms:` URLs (no in-app modal that could trap a kid mid-crisis). Wired into `SettingsView` above the About section. Section header "If you need to talk to someone" + footer copy "You don't have to be in a crisis to call — 'not sure' is reason enough" applies SAMHSA TIP 57 validate-then-inform register. Disease-story arc integration deferred to Phase 3 when the arcs ship.

**Exit criteria**: A11y audit PASS; trauma-gate sensitivity reviewer signoff per ADR-012 / ADR-016 protocol.

---

## Cross-references

- `@Docs/TECHNICAL_DESIGN.md` — architecture + state machines + domain model
- `@Docs/IMPLEMENTATION_HANDOFF.md` — hub-shipped implementation context
- `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` — 12-character cast definition
- `@Docs/HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` — DN-S chapter-depth backstories
- `@.claude/rules/forgekit.md` § Module Catalog — ForgeKit 0.99 surface
- `@.claude/rules/spritekit.md` § Lazy Visual Setup — microscope + simulator scene pattern
- `@.claude/rules/state-machines.md` — ZoomMachine + SimulationMachine pattern
- `@.claude/rules/trauma-informed-content.md` — COVID-sensitive disease-story register
- `@.claude/rules/foundationmodels.md` — `@Generable` + fallback discipline for Vee
