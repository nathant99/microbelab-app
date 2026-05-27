# Handoff from Labsmith — Pillar Deepening: MicrobeLab (Perspective-taking (microaggression encounter reflection))

> **⚠️ STATUS UPDATE 2026-05-27 (Round 88 #449)**: Reviewer envelope **APPROVED** per user confirmation — "all gated issues have been reviewed and approved". Phase D ART generation + trauma-adjacent DN-D3 / DN-D8 / DN-D12 moves NOW UNBLOCKED. Original Phase-D-BLOCKED / reviewer-envelope references below are SUPERSEDED. Mentor posture + `ForgeServerSafety` output moderation remain load-bearing per `.claude/rules/trauma-informed-content.md`.

Direction: **labsmith → microbelab-app**. Round 85 #439 fan-out remainder ships **R5 (Perspective-taking (microaggression encounter reflection))** as the recommended `DIR-FEDC` deepening move for MicrobeLab. The move derives from the per-app top-move in `AUDIT_PILLAR_DEEPENING_PER_APP.md` § 3 row for `microbelab`; methodology grounding in `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` § 2-§ 5 (move ID `R5`).

**Filed**: 2026-05-26
**Round**: 85 queue #439 (Round 85 #439 fan-out remainder)
**Cluster wave**: Round 85 #439 fan-out — `DIR-FEDC`
**Companion docs (labsmith)**: `labsmith/Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` (§ for move `R5`) + `labsmith/Docs/AUDIT_PILLAR_DEEPENING_PER_APP.md` (per-app row for `microbelab`)

---

## § 1 — Header: app context

| Field | Value |
|---|---|
| **App slug** | `microbelab` |
| **App name** | MicrobeLab |
| **DN cluster** | `DIR-FEDC` |
| **DN status** | Distributed-narrative handoff shipped per `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md` second pass). |
| **DN pattern** | Per app's DN handoff (Standard / Aggregator-infrastructure / Younger variant) |
| **AI mentor** | Per app's DN handoff |
| **Current pillar profile (audit)** | Per `AUDIT_PORTFOLIO_PILLAR_TAGGING.md` |
| **Trauma-informed status** | `TI-GATE` (see `.claude/rules/trauma-informed-content.md`) |
| **Implementation tier** | Per `AUDIT_IMPLEMENTATION_READINESS.md` |
| **Repo status** | Docs-only / pre-scaffolding (verify Phase 1 scaffolding before adoption). Build-ready when Phase 1 lands. |
| **App-side blockers** | Phase 1 scaffolding (Xcode project + Libraries SPM) precedes this work. **Build-ready when Phase 1 lands.** |


**Trauma-informed status**: `TI-GATE` per `.claude/rules/trauma-informed-content.md`. Sensitivity-reviewer engagement required before Phase D asset / surface ship. Cumulative reviewer envelope: ~$5K shared across the gated set.

---

## § 2 — Why this deepening move now

The recommended top-move for `microbelab` per the Round 77 #394 audit catalog is **R5 (Perspective-taking (microaggression encounter reflection))**. The audit cluster recipe (`AUDIT_PILLAR_DEEPENING_PER_APP.md` § for `DIR-FEDC`) identifies this as the highest-leverage deepening direction for the cluster.

**Concrete signals**:

- `DIR-FEDC` cluster recipe identifies this move as the cluster-shared dominant deepening direction.
- ForgeKit primitives (per § 4 below) are SHIPPED — no blocked dependency.
- Pre-launch positioning: per-app pillar depth IS the load-bearing curriculum claim for TestFlight + foundation-officer scan + district-licensing teacher-preview.

**Strategic frame** (from methodology § 1.1):

> Pre-launch positioning leans on per-app depth (TestFlight retention + foundation-officer scan + district-licensing teacher-preview). This handoff achieves: **modes.reflect: +1 on Reflect (canonical move-target)**.

---

## § 3 — The move

**Move identifier**: `R5`
**Move name**: Perspective-taking (microaggression encounter reflection)
**Pillar(s) deepened**: Reflect
**Score delta**: modes.reflect: +1 on Reflect (canonical move-target)

### 3.1 What the move IS (operational definition)

Per methodology § for `R5` — apply per-app to MicrobeLab's existing curriculum + cast.

1. **Primary surface**: the move's canonical UI / state-machine integrates with MicrobeLab's existing 16-kit curriculum cadence.
2. **Cast integration**: cast members embody the move's primitive surface (per DN methodology); fading per L4 over kits 1-12.
3. **Parent-dashboard signal** (where applicable): aggregate-only weekly summary per `.claude/rules/age-assurance.md` COPPA hygiene; never per-event per-day surfacing.

### 3.2 What the move IS NOT (anti-pattern guard)

- ❌ **A separate "mode" or "tab"** — per Habgood intrinsic integration, the move surfaces INSIDE existing gameplay, not as a separate sibling surface.
- ❌ **Punitive / FOMO-gated framing** — validate-then-inform per `.claude/rules/ai-content.md` AI tone.
- ❌ **Surfacing algorithm internals** — algorithm state is INVISIBLE to the kid; only canonical learner-visible labels surface.

### 3.3 Evidence baseline (cited from methodology doc)

- Theory of mind research — perspective-taking is cornerstone metacognition
- SAMHSA TIP 57 — perspective-taking is trauma-informed when scaffolded properly
- Bystander-intervention research (SafetyForge canonical implementation)

---

## § 4 — ForgeKit dependency check

**Verified against `forgekit/Docs/CHANGELOG.md` (0.94.0 current).**

| Primitive | Required version | Status |
|---|---|---|
| `ForgePassAndPlay.dyadic (0.89)` | 0.89.0 | ✅ shipped |
| `ForgeDevelopmental.CoRegulationEngine (optional)` | 0.86.0 | ✅ shipped |

**Pin recommendation**: `.package(url: "https://github.com/nathant99/forgekit.git", from: "0.86.0")` minimum (0.94.0 preferred for newest primitives). All primitives SHIPPED.

---

## § 5 — Implementation Phase A-D

Following the DN-retrofit handoff pattern (per `Docs/PORTFOLIO_PATTERNS.md`):

### Phase A — Design finalization (1-2 days)

- [ ] Review § 3 move definition with app-session
- [ ] Read methodology doc move ID `R5` in `PLAN_PILLAR_DEEPENING_METHODOLOGY.md`
- [ ] Confirm cast-attachment points (which cast member embodies this move surface)
- [ ] Confirm Bloom-level alignment (per existing kit metadata)
- [ ] Confirm UI surfaces that need adjustment (settings / HUD / kit-end screen / library view)
- [ ] **Trauma-informed gate** (if cluster TI-applicable): off-ramps designed per `.claude/rules/trauma-informed-content.md`

### Phase B — Kit 1-4 introduction (3-5 days)

- [ ] Wire ForgeKit primitive(s) per § 4 into AppFeature root (relevant `import`s)
- [ ] Add per-student SwiftData @Model classes if needed
- [ ] Surface the move in kits 1-4 (introductory exposure; high cast scaffolding)
- [ ] Add hint-tier scaffolding per `.claude/rules/trauma-informed-content.md` if TI-applicable
- [ ] Update CLAUDE.md § 9 Things-That-Will-Bite-You with primitive-specific gotchas

### Phase C — Kit 5-8 deepening (3-5 days)

- [ ] Move surfaces deeper in kits 5-8 (less cast scaffolding; more autonomy)
- [ ] Wire formative-feedback surface (per L7 from methodology if applicable)
- [ ] Wire parent-dashboard signal (per `ProgressReportService` if applicable)
- [ ] **Asset Consumer Audit** per `.claude/rules/portfolio.md`: grep for primitive consumer call site — at least one view must actually render the move's surface

### Phase D — Kit 9-12 fading + asset polish (3-5 days)

- [ ] Move integrates fully (cast support fades per L4)
- [ ] Capstone integration in kit 12-16 (per P7 boss-encounter if Play-pillar)
- [ ] Final visual polish + accessibility audit
- [ ] If cluster trauma-adjacent: final sensitivity-reviewer signoff

**Total estimate**: ~10-17 days per-app session work; +5-10 days for TI-gated cluster apps (reviewer cycle).

---

## § 6 — Code-shape sketch

A rough Swift outline showing how the move integrates with the app's existing `AppFeature` root. **NOT a copy-paste implementation** — the app session writes the real code; this is the shape guide.

```swift
// Libraries/Sources/AppFeature/MicrobeLabAppRootView.swift (excerpt)

import SwiftUI
import SwiftData
import ForgeUI
// + ForgeKit modules per § 4

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var moveStateMachine = R5StateMachine()  // local FSM per `.claude/rules/state-machines.md`

    // R5: Perspective-taking (microaggression encounter reflection)
    // Wires the primitive into the app shell; per methodology § for R5.

    var body: some View {
        ContentView()
            .onAppear {
                Task {
                    await wirePrimitive()
                }
            }
    }

    private func wirePrimitive() async {
        // Canonical integration shape — replace with real app-session code.
        // Reference: `forgekit/Sources/Client/<Module>/` source.
    }
}
```

**Notes for the app session**:

- Use `package` access modifier when crossing target boundaries (per `.claude/rules/spm-architecture.md`)
- Mark new public Sendable structs `nonisolated` (per `.claude/rules/concurrency.md`)
- Keep `@Model` classes in `Models/` target; never in `AppFeature/`
- Wire `ModelContext` injection via `onAppear`, NOT `init` (per `.claude/rules/swiftdata.md`)

---

## § 7 — Failure-mode tests

Analogous to DN's 6 failure-mode tests. Per-move tests:

### Universal failure-mode tests (apply to every deepening move)

1. **Cluster-coherence** — does this move work alongside the rest of the `DIR-FEDC` cluster recipe?
2. **Anti-dilution guard** — does this move push the app toward 3+ pillars at 2+, violating the methodology § 8 "diluted matrix" guard?
3. **ForgeKit version verification** — was `forgekit/Docs/CHANGELOG.md` pulled + read before citing primitives at § 4?
4. **Asset consumer audit** — at least one view actually renders the move surface (per `.claude/rules/portfolio.md`)?
5. **Score-delta accuracy** — does the proposed score delta (§ 3) match the move type per methodology § 2-§ 5?

### Move-specific failure-mode tests

- **Anti-pattern guard**: per § 3.2, no separate-mode-tab framing; intrinsic integration only.
- **Cast-coherence**: cast cameos in the move's surface preserve archetype + voice.
- **Trauma-informed off-ramps** (if applicable): skip-with-summary + audio-only + pacing control per `.claude/rules/trauma-informed-content.md`.

---

## § 8 — Cross-references

### Labsmith
- `Docs/PLAN_PILLAR_DEEPENING_METHODOLOGY.md` (move ID `R5` section) — move definition + research grounding
- `Docs/AUDIT_PILLAR_DEEPENING_PER_APP.md` (cluster recipe + this app's row in the 138-row table)
- `Docs/AUDIT_PORTFOLIO_PILLAR_TAGGING.md` — current pillar tagging baseline
- `Docs/RESEARCH_DISTRIBUTED_NARRATIVE_PORTFOLIO_EXPANSION.md` — DN methodology
- `Docs/GUIDE_DISTRIBUTED_NARRATIVE_METHODOLOGY.md` — DN spec
- `.claude/rules/trauma-informed-content.md` (if cluster TI-applicable)
- `.claude/rules/forgekit.md` — module catalog + versioning
- `.claude/rules/portfolio.md` — cross-repo handoff protocol

### App repo
- `microbelab-app/Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` (or `_ENHANCEMENT.md`) — DN baseline
- `microbelab-app/Docs/IMPLEMENTATION_HANDOFF.md` — Phase 1 implementation handoff
- `microbelab-app/CLAUDE.md` — app-specific patterns + gotchas
- `microbelab-app/Docs/TECHNICAL_DESIGN.md` — architecture
- `microbelab-app/Docs/FEATURE_PLAN.md` — phased delivery (this deepening adds a sub-phase)
- `microbelab-app/Resources/Questions/` — kit JSONs (if move depends on kit metadata)

### ForgeKit
- `forgekit/Docs/CHANGELOG.md` — authoritative versioning
- `forgekit/Sources/Client/<Module>/` — primitive source (see § 4 for module names)

### External research

- Theory of mind research — perspective-taking is cornerstone metacognition
- SAMHSA TIP 57 — perspective-taking is trauma-informed when scaffolded properly
- Bystander-intervention research (SafetyForge canonical implementation)

---

## § 9 — Sequencing for app session

1. **Read this handoff in full** (15 min)
2. **Read the methodology move definition** in `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` (move ID `R5`) (10 min)
3. **Read the cluster recipe** in `AUDIT_PILLAR_DEEPENING_PER_APP.md` (5 min)
4. **Pull forgekit + verify primitive versions** per § 4 (5 min)
5. **If cluster TI-applicable**: confirm reviewer engagement BEFORE Phase A
6. **Plan-mode session** (15-30 min) — design Phase A integration with cast / Bloom / standards mapping
7. **Phase A** → **Phase B** → **Phase C** → **Phase D** per § 5
8. **Asset Consumer Audit** per Phase C checkpoint (per `.claude/rules/portfolio.md`)
9. **Mark handoff CLOSED** — labsmith inbound queue updated by founder

### Post-completion checklist

- [ ] Build succeeds (all targets) per Definition of Done in `.claude/rules/workflow.md`
- [ ] Unit + UI tests pass for new surface
- [ ] CLAUDE.md § 9 updated with primitive-specific gotchas
- [ ] FEATURE_PLAN.md sub-phase marked complete
- [ ] Per-pillar mode-score in `apps.generated.ts` updated by labsmith (if score-delta non-zero)
- [ ] Site-side adoption tracked in spark-anvil-site queue

---

## § 10 — Open questions for app session

Common per-move questions to surface in plan-mode:

**Q1**: Where does the move's state persist?
A: Per-student SwiftData `@Model` in your `Models/` target. Schema migration plan per `.claude/rules/swiftdata.md`.

**Q2**: How does this move interact with the existing 16-kit progression?
A: The move integrates with the kit cadence; per § 5 Phase A-D, surfaces evolve from kit 1-4 introduction to kit 9-12 fading. Cast support fades per L4 methodology.

**Q3**: Does this require a separate mode, or interleave with normal gameplay?
A: Interleaving is recommended (Habgood intrinsic-integration). The move should feel like part of the game, not a separate mode.

---

## § 11 — Labsmith follow-up after app session ships

After the app session marks this handoff CLOSED:

1. Labsmith updates `apps.generated.ts` modes score (if score-delta non-zero)
2. Labsmith updates `AUDIT_PILLAR_DEEPENING_PER_APP.md` row for `microbelab` — mark `next_step` as "Adopted YYYY-MM-DD"
3. Labsmith files cluster-wave-N+1 inbound for next-app in the cluster
4. If this app's deepening reveals a gap in the methodology doc, labsmith updates `PLAN_PILLAR_DEEPENING_METHODOLOGY.md` accordingly

---

**End of pillar-deepening handoff for `microbelab`.**

Filed by labsmith Round 85 #439 fan-out remainder distribution. Cluster wave: `DIR-FEDC`. Move: `R5` (Perspective-taking (microaggression encounter reflection)).
