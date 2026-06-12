# MicrobeLab — Feature Plan

> Phased delivery roadmap. Mirrors the engineering breakdown in `@Docs/TECHNICAL_DESIGN.md`. Implementing sessions check off boxes as work lands; do not collapse phases — the per-phase exit criteria gate ship readiness.

## Phase 1: Microscope Foundations (MVP)

Core microscope-zoom loop, 12-character microbe cast, freshwater microbiome simulator, innate-immunity minigame, and AI Socratic mentor (Vee). NGSS MS-LS1-1 baseline + portfolio safety/COPPA bedrock.

### Scaffolding

- [x] Create Xcode project with thin app shell (`MicrobeLab/MicrobeLabApp.swift`)
- [x] Create `Packages/Libraries/Package.swift` with 6 targets (Models, Services, SharedUI, GameEngine, AIMentor, AppFeature)
- [x] Add ForgeKit dependency (remote GitHub URL, `from: "0.99.0"`)
- [x] Create stub source files for all targets
- [x] Verify build succeeds with zero warnings (via `swift build` — no Xcode reload)
- [ ] Add `Packages/Libraries` to workspace (user GUI step per `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 1)

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
- [ ] Implement microscope HUD overlay (tier badge + zoom level) — SwiftUI view PR next

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
- [ ] Implement pathogen spawn + wave progression (sprite layer)
- [ ] Implement macrophage movement + boundary handling
- [x] Implement scoring + 5-wave Phase-1 progression (logic-level: `recordConsume(_:)` + `clearWave()`)
- [x] Wire scene into `GameEngine` target with lazy visual setup

### 12-Character Microbe Cast

- [ ] Define 12 named microbes (4 beneficial + 4 neutral + 4 opportunistic/pathogenic per DN cluster balance — see `@Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md`)
- [ ] Bundle character JSON metadata in `Resources/Cast/cast.json`
- [ ] Bundle character portrait WebPs in `Resources/Cast/<slug>.webp` (12 portraits; await hub distribution)
- [ ] Wire `ForgeIllustrations.IllustrationRegistry` registration
- [ ] Implement per-character voice lines per DN voice register card

### SwiftUI Views

- [x] Create 5-tab `TabView` (Explore / Codex / Microbiome / Progress / Profile) shell + bundled-catalog bootstrap
- [x] Build `ExploreView` wrapping `MicroscopeScene` via `SpriteView` (tier-badge HUD + mentor bubble)
- [x] Build `MicrobeCodexView` (12-microbe grid; locked entries show "???" until discovered)
- [x] Build `MicrobiomeView` wrapping simulator with feeding-mode + antibiotic controls
- [ ] Build `ImmuneGameView` wrapping `MacrophagePacmanScene` (next PR)
- [x] Build `ProgressTabView` with XP / streak / codex grid
- [x] Build `ProfileView` placeholder (`ForgeAvatar.AvatarStudioView(.lite)` wiring lands next PR)
- [ ] Build `SettingsView` with parental gate (next PR)
- [ ] Build `QuizView` for question kits (next PR)

### AI Mentor (Vee — Socratic)

- [x] Create `VeeMentor` class with lazy `LanguageModelSession`
- [x] Implement `MicrobeFact` `@Generable` with curriculum-guarded fallbacks for all 12 microbes
- [x] Implement `ZoomCue` `@Generable` for tier-transition Socratic prompts
- [x] Implement `EcologyHypothesis` `@Generable` for microbiome puzzle scaffolding
- [x] Implement static fallbacks for every `@Generable` per `.claude/rules/foundationmodels.md`
- [ ] Create mentor speech-bubble UI component
- [ ] Wire mentor to events: microscope tier-up, microbiome milestone, immune wave-clear

### Gamification

- [ ] Integrate ForgeGamification `XPEngine` for leveling
- [ ] Integrate `StreakManager` for daily engagement
- [ ] Integrate `AchievementEngine` with first 10 Phase-1 achievements
- [ ] Wire question kits 01-04 via `Bundle.module` (microbiology basics / microbiome / immune defense / beneficial microbes)
- [ ] Implement XP awards for: first microbe discovered, microbiome stable for 5 ticks, immune wave cleared, etc.

### Adventure Mode

- [ ] Wire Level 1 config from `spark-anvil-hub/Resources/HubContributions/microbelab.json` (Life Zone contribution)
- [ ] Implement `MicrobeLabHubContribution` Level 2 Swift overlay in `Libraries/Sources/AppFeature/HubContribution/`
- [ ] Register mode-cards in `AdventureView`
- [ ] Wire `ForgeProgressionManager` gating across mode-cards

### Onboarding

- [ ] Create 5-step onboarding flow (welcome, first zoom-in, meet first microbe, first observation, first quiz)
- [ ] Implement aha moment: first microscope zoom reveals a character introducing themselves
- [ ] Implement progressive disclosure (Session 1: microscope + codex only)
- [ ] Implement parent handoff flow (30s setup)
- [ ] Implement Apple Declared Age Range API gate (iOS 26+)

### Quality

- [ ] Unit tests for microbiome simulator (feeding modes / antibiotic shock / recovery curve)
- [ ] Unit tests for zoom-tier transitions
- [ ] Unit tests for cast catalog loading + integrity
- [ ] UI tests for microscope + codex flow
- [ ] UI tests for microbiome puzzle
- [ ] Accessibility audit (VoiceOver / Dynamic Type / color contrast)
- [ ] Performance profiling (microscope tier transition < 16ms; simulator tick < 8ms)

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
- [ ] **Parent handoff flow** — 30-second parent setup (age, content preferences, microbiome topic comfort) → "Ready!" transition
- [ ] **Age gate** — Apple Declared Age Range API on iOS 26+
- [ ] **Parental consent service** — COPPA-compliant consent; annual re-consent per 2026 FTC
- [ ] **Privacy policy** — Plain-language policy accessible from Settings and App Store listing
- [ ] **Parental gates** — Required for external links and data-sharing permissions
- [ ] **Progressive disclosure** — Session 1: microscope only → Sessions 2-3: + simulator → Sessions 4+: full feature set

### Engagement Foundation (Excellence Framework)

- [ ] **Streak system** — Daily activity with streak freeze (one mercy day per week), warm broken-streak messaging ("The microbiome missed you!")
- [ ] **DDA engine** — Invisible difficulty adjustment across microbiome puzzles + immune game wave count
- [ ] **Session targeting** — 10-15 minute sessions with gentle ending summary
- [ ] **Variable rewards** — ~1 in 5 sessions: rare microbe sighting / hidden codex entry / special Vee reaction
- [ ] **Return loop** — Welcome-back flow for 3+ day lapsed users: warm greeting + best-work recap
- [ ] **Retention metrics baseline** — D1 / D7 / D30 (on-device, privacy-first)

**Exit criteria**: aha moment within 60s; DDA holds flow; engagement loop creates intrinsic return motivation.

---

## Phase: Delight & Parent Integration

Audio/visual/haptic polish, parent-facing dashboards, and emotional design. Runs after Phase 2 minimum.

### Delight & Polish

- [ ] **Juice layer** — Visual + audio + haptic trifecta on every interaction (with iPad haptic fallback)
- [ ] **Celebration system** — Proportional: subtle sparkle for small wins → full-screen for milestones → cinematic for "first microbe of new microbiome" beat
- [ ] **Micro-delight coverage** — All 8 types: celebration, surprise, personality, mastery, social, sensory, agency, discovery
- [ ] **Character personality** — Vee with callbacks to player's discoveries; cast member quirks per DN voice register
- [ ] **Mastery moments** — Distinct screen ripple + chord when child internalizes microbiome ecology
- [ ] **Easter eggs** — Hidden rare-microbe encounters rewarding curious zoom exploration
- [ ] **Share-worthy moments** — Codex completion certificates; immune-game high-score trophies

### Parent Integration

- [ ] **Progress dashboard** — Parent-facing standards-mapped view (NGSS MS-LS1-1 / MS-LS1-3 etc.)
- [ ] **Parental controls** — Daily session time limits (default 30 min) + content-comfort filters (e.g., disease-story arc opt-in)
- [ ] **Weekly summary** — Opt-in progress notification (strengths, growth areas, recommendations)
- [ ] **Session closer** — End-of-session summary with achievements + preview of next session content

---

## Phase: Accessibility & Trauma-Informed Polish

- [ ] VoiceOver labels for every microscope LOD sprite + cast portrait
- [ ] Dynamic Type support across all SwiftUI views
- [ ] Color-contrast audit (WCAG AA in default + dark + high-contrast themes)
- [ ] Reduce-Motion variants for celebration + tier-transition animations
- [ ] Reduce-Transparency variants for any glass UI (per portfolio Liquid Glass policy)
- [ ] Trauma-informed gate review for disease-story arcs (SAMHSA TIP 57 register; off-ramps + crisis-resource surface; cultural-context note for global-microbiome cards)
- [ ] Crisis-resource list (988 / Childhelp / Crisis Text Line) surfaced from Settings + disease-story arcs

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
