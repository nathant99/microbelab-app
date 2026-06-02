# MicrobeLab — Technical Design

**Status**: Pre-implementation scaffold (Tier-D). Implementing session will flesh this out per Phase 1.
**Concept source**: [`Docs/README.md`](README.md) (copy of labsmith `Docs/MicrobeLab/README.md`)
**Primitive**: microbiology adventure (microscope-zoom-as-core-loop + microbiome simulator + named microbe characters + immune-response gameplay)
**Curriculum**: NGSS MS-LS1-1 (cells investigation), MS-LS1-2 (cell function model), MS-LS1-3 (immune system as subsystem), MS-LS2-3 (matter/energy in ecosystems); CCSS RST.6-8.4 / 6-8.7; NHES 1 + 7
**Primary standard mapping**: NGSS MS-LS1-1

## SPM Module Architecture

Per `.claude/rules/spm-architecture.md`. Standard targets:

| Target | Purpose | Dependencies |
|---|---|---|
| `Models` | Domain models, SwiftData `@Model` classes, value-type cache structs | `ForgeModels` |
| `Services` | Persistence, audio, networking, AI session management | `Models`, `ForgePersistence`, `ForgeAI` |
| `SharedUI` | Reusable SwiftUI components, ForgeUI theme integration | `Models`, `ForgeUI` |
| `GameEngine` | SpriteKit microscope-zoom scenes, microbiome simulator, immune minigame | `Models`, `ForgeGameEngine` |
| `AIMentor` | FoundationModels `@Generable` types, Vee Socratic mentor session | `Models`, `ForgeAI` |
| `AppFeature` | Root view, navigation, app coordinator | All above + `ForgeAdventure` + `ForgeCelebration` |

ForgeKit deps live on `AppFeature` only (matches labsmith-app pattern); intermediate targets are deps-free for faster incremental compilation.

## ForgeKit Module Integration

Pinned at `from: "0.99.0"`. Modules:

- `ForgeUI`
- `ForgeNavigation`
- `ForgePedagogy`
- `ForgeGamification`
- `ForgeAccessibility`
- `ForgeAdventure`
- `ForgeAI`
- `ForgeAvatar`
- `ForgePersistence`
- `ForgeAnalytics`
- `ForgeModels`
- `ForgeCelebration`
- `ForgeGameEngine` (for SpriteKit microscope-zoom scenes)
- `ForgeKnowledgeGraph` (for cross-microbe relationships + microbiome ecology surfacing)

See @CLAUDE.md § ForgeKit Module Integration for the per-module rationale.

## Domain Model

The MicrobeLab domain model centers on **microbiome ecology + microscope-driven discovery** — named microbe characters (Lacto / Bif / Strep / Norovirus / E.coli + 7 others) interact in a gut-ecology simulator the kid manipulates via feeding modes + antibiotic shock + recovery state. The implementing session will translate this into Swift types per Phase 1. Suggested type sketches (revise during implementation):

### Value types (Sendable, nonisolated)

```swift
// Models target — placeholder shape, refine in Phase 1
nonisolated public struct MicrobeCharacter: Codable, Sendable, Identifiable {
    public let id: UUID
    public let slug: String                    // "lacto", "bif", "strep"
    public let displayName: String
    public let kingdom: MicrobeKingdom         // .bacteria / .virus / .archaea / .fungi
    public let role: MicrobeRole               // .beneficial / .neutral / .opportunistic / .pathogenic
    public let preferredEnvironment: GutSlot   // ileum / colon / oral / skin
    public let growthRate: GrowthRate          // affected by feeding mode + antibiotic state
}

nonisolated public enum GutSlot: Codable, Sendable {
    case oralCavity, stomach, smallIntestine, largeIntestine, colon
}

nonisolated public struct MicrobiomeState: Codable, Sendable {
    public let populations: [UUID: Int]        // microbe characters → count
    public let feedingMode: FeedingMode        // .fiber / .sugar / .balanced / .none
    public let antibioticState: AntibioticState // .none / .active(daysLeft:) / .recovering
    public let tickCount: Int
}

nonisolated public enum ZoomTier: Int, Codable, Sendable {
    case unaided = 0      // 1×
    case light = 1        // 100×
    case fluorescence = 2 // 1000×
    case electron = 3     // 10000×+
}
```

### SwiftData @Model classes (MainActor)

```swift
// Models target
@Model
public final class PersistentMicrobeSession {
    public var id: UUID = UUID()
    public var encodedStateData: Data = Data()   // JSON-encoded MicrobiomeState snapshot
    public var startedAt: Date = Date()
    public var endedAt: Date?
    public init() { }
}
```

Implementing session decides exact storage strategy (snapshot per session vs continuous tick log). Per `.claude/rules/swiftdata.md`: never `@Query` in views; cache to value-type structs in `onAppear`.

## New Engines (App-Specific)

- **MicroscopeEngine** — SpriteKit camera + LOD sprite atlas swap across 4 zoom tiers (1× → 100× → 1000× → electron). Tactile pinch-to-zoom UX; level-of-detail sprite swap on tier boundary.
- **MicrobiomeSimulator** — gut ecology state machine: feeding modes (fiber/sugar/balanced/none) affect microbe growth rates; antibiotic shock + recovery as discrete event states; per-tick population updates.
- **ImmuneResponseEngine** — innate macrophage Pac-Man minigame (Phase 1); adaptive B-cell antibody-matching (Phase 2).
- **MicrobeKnowledgeGraph** — extends `ForgeKnowledgeGraph` with microbe-to-microbe ecology edges + curriculum-standard mapping.

Each engine lives in its own SPM target or is folded into `GameEngine` / `Services` per Phase 1 complexity.

## Phase 1 Scope (engineering breakdown)

- Microscope viewer (4 zoom tiers; SpriteKit camera + LOD sprite swap)
- Microbiome simulator (gut puzzle: feeding modes + antibiotic shock + recovery state machine)
- 12 named microbe characters (4 beneficial + 4 harmful + 4 neutral; chunky-cartoon style cluster)
- Immune-response minigame (innate macrophage Pac-Man; B-cell antibody-matching in Phase 2)
- AI Socratic mentor (Vee) — `@Generable MicrobeFact` with curriculum guardrails per `.claude/rules/ai-content.md`
- 4 question kits in Phase 1 (microbiology basics / microbiome / immune defense / beneficial microbes); 12 more in Phase 2 to reach portfolio-standard 16 kits
- Custom microbe portrait pack (12 microbes × ~3 poses each; per-app `HANDOFF_FROM_APP_MICROBE_ILLUSTRATIONS.md` to labsmith)

See @Docs/FEATURE_PLAN.md for the full phased roadmap.

## Adventure Mode Integration

Contributes to **Life Zone** in AdventureHub (TBD — coordinate with bioforge / creaturecare / wildlens cluster). Level 1 config (canonical JSON) lives at `labsmith/Resources/HubContributions/microbelab.json`; Level 2 Swift overlay (this repo) lives at `Libraries/Sources/AppFeature/HubContribution/MicrobeLabHubContribution.swift` per `Docs/AMENDMENTS_ADVENTUREHUB_SOURCE_OWNED_UI.md`.

## Home Screen & Navigation

4-tab `TabView` per portfolio convention:

- **Explore**: microscope viewer + core discovery loop
- **Adventure**: Life Zone mode-cards (gated via `ForgeProgressionManager`)
- **Progress**: streak, XP, badge gallery, microbe-discovery codex
- **Profile**: avatar via `ForgeAvatar.AvatarStudioView(.lite)`, settings, parental controls

## Full-App UI/UX Patterns

- **ZoomMachine** / **SimulationMachine** structs (per `.claude/rules/state-machines.md`) for view-local state
- **SpriteKit lazy visual setup** per `.claude/rules/spritekit.md` § Lazy Visual Setup (zoom + simulator nodes use `configureVisuals()` pattern; testable in SPM unit targets)
- **SafeAreaInset** wrapping per `.claude/rules/spritekit.md` § SpriteView layout cascade — microscope viewer floats SwiftUI HUD over SpriteView; reserve space via `safeAreaInset`
- **Feedback sequences**: `.correctFeedback(isActive:)` / `.incorrectFeedback(isActive:)` from ForgeUI
- **Results animation**: spring + scale via `ForgeCelebration.CelebrationCoordinator`
- **Onboarding**: `ForgeOnboardingFlow.Page` builder; first 60 seconds reach the aha moment (zoom in once, see a microbe character introduce themselves)

## Child Safety & Privacy Architecture

| Channel | Data classification | Storage | Outbound? |
|---|---|---|---|
| Session events + microbe encounters | App-internal | SwiftData (local) | No |
| Mentor dialogue context | App-internal | In-memory only | No |
| Achievement badges + codex | App-internal | SwiftData (local) | No |
| Parental consent records | Required for COPPA audit | SwiftData (local, 12-month expiry per FTC 2026) | No |

See @Docs/KIDSAFE_PREPARATION.md for the full plan.

## Parent & Educator Integration

- `ProgressReportService` standards-mapped to **NGSS MS-LS1-1**, MS-LS1-2, MS-LS1-3, MS-LS2-3
- `ParentalControlsManager`: session limits, content filters, dashboard
- Teacher dashboard data model: weekly summary, anonymized class-wide trends (no per-student PII)

## Onboarding & First-Time Experience

See @CLAUDE.md § Onboarding for the First 60 Seconds timeline. Aha moment: kid pinch-zooms once from 1× to 100×, a microbe character (Lacto) appears and introduces themselves as "one of trillions of tiny lives that help you digest food".

## Engagement & Retention Engine

- `ForgeGamification.StreakManager` with streak freezes + `heldUnderDistress` (0.86 case)
- `ForgeGamification.XPEngine` for level progression
- Discovery codex pattern — every new microbe encountered unlocks a card in the codex
- Variable-ratio reward schedule via `CelebrationCoordinator` (per labsmith `DESIGN_FORGEADVENTURE_API_SPECS.md`)

## Delight & Emotional Design

- 8 micro-delight types per `labsmith/Docs/TEMPLATE_EXCELLENCE_ADDITIONS.md`
- Mascot (Vee — B-cell with magnifying-glass eye) reaction animations on zoom transitions and new microbe discovery
- Hero color `#33CCBB` (bio-luminescent teal-cyan) used judiciously — primary CTA, mascot background, ForgeAdventure zone tag

## Analytics & Instrumentation

- Privacy-first on-device analytics via `ForgeAnalytics`
- MetricKit for crash + performance reporting (no PII)
- Feature flags via `ForgeExperiments` (COPPA-safe on-device A/B)
- **No third-party analytics SDKs** — no Firebase, no Mixpanel, no Amplitude

## Trauma-Informed Design Posture (COVID-era sensitivity)

MicrobeLab engages content that overlaps post-COVID pandemic-trauma surface area. Apply `.claude/rules/trauma-informed-content.md` selectively:

- **Beneficial-microbes nuance is load-bearing** — most microbes are neutral or beneficial; correct the "germ = bad" oversimplification. Phase 1 cast: 4 beneficial + 4 neutral + 4 opportunistic/harmful (not "pathogenic" universally).
- **Generic pathogens only** — rhinovirus, strep, common cold. NOT COVID-19, NOT specific pandemic-era pathogens. Avoid pandemic-trauma imagery (no masked figures, no hospital scenes, no mortality framing).
- **Wonder + agency, not fear** — emotional arc emphasizes discovery and agency (kid manipulates the microbiome via feeding choices) over threat-response.
- **Immune-response minigame framed as protection, not war** — innate immunity surfaces "your body's quiet helpers", not "warriors".
- **Off-ramps for kids with medical anxiety** — pre-content warning + skip-with-summary affordance for the immune-response minigame; mentor (Vee) acknowledges difficulty calmly.

This positions MicrobeLab as trauma-informed-AWARE but NOT in the formally-trauma-gated cluster (no R0 reviewer signoff required). Per `.claude/rules/trauma-informed-content.md`, document this posture explicitly so future sessions don't re-litigate.

## Open Questions / Decisions Pending

Implementing session resolves these in Phase 1 design:

1. Exact SwiftData storage strategy for microbiome simulator state (snapshot per session vs continuous tick log)
2. AI prompt-engineering pass for Vee persona (use `labsmith/Docs/TEMPLATE_MASCOT_PROMPT.md` voice guidance; Socratic "what do you see?" pattern)
3. Specific `ForgeProgressionManager` unlock schedule (which Phase 1 features gate behind which session count)
4. Asset bundle plan (mascot poses arrive via labsmith handoff; topic illustrations deferred per portfolio convention; **12-microbe portrait pack required per Phase 1**)
5. Microscope-zoom UX — pinch-to-zoom tactile + discrete tier-boundary snap, or continuous slider; LOD sprite swap heuristics
6. Immune minigame difficulty curve — Pac-Man-style needs DDA calibration for younger learners
