---
status: COMPLETE
date: 2026-06-16
round: twenty-sixth-pass auto-cycle, PR #3 of 5
freshness-horizon: 14
methodology: read-only audit per `.claude/rules/trauma-informed-content.md` § "Hard requirement" + ADR-016 § "Trauma-adjacent DN-S story authoring" + `.claude/rules/workflow.md` § "Save Research, Plans, and Audits to Docs/ Immediately"
adr-reference: ADR-016 (trauma-gated DN-S story-axis approval)
---

# Audit — trauma-informed gate review for disease-story arc scaffolds (2026-06-16)

> **Twenty-sixth-pass rule-restatement summary** (canonical-invariant tier; verbatim user-direct 2026-06-16): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing Xcode-managed files is ok."* See `@CLAUDE.md` § Xcode-managed file safety. Nothing in this audit's recommendations implies a managed-file edit.

## Why this audit exists

`Docs/FEATURE_PLAN.md` § "Phase: Accessibility & Trauma-Informed Polish" carries the open item *"Trauma-informed gate review for disease-story arcs (SAMHSA TIP 57 register; off-ramps + crisis-resource surface; cultural-context note for global-microbiome cards)"* (line 261). The Phase 3 + Phase 4 scaffolds shipped PRs #141 / #152 / #154 / #164 / #167 / #168 / #162 lay the structural surface area for that content; this audit pins per-scaffold conformance with the trauma-informed framework BEFORE reviewer-signed-off prose lands. The audit closes the checkbox at the structural-conformance tier; the prose-reviewer-signoff tier per ADR-016 stays a downstream gate.

## The framework being checked

Per `.claude/rules/trauma-informed-content.md` MicrobeLab is **trauma-informed-AWARE but NOT in the formally-trauma-gated cluster** (per `Docs/TECHNICAL_DESIGN.md` § "Trauma-Informed Design Posture (COVID-era sensitivity)"). The disease-story-arc + historical-context-cards + vaccine-mini-explainer + global-microbiome-tour scaffolds individually engage **trauma-adjacent content** (Phase 3 disease-story arcs cover handwashing / vaccine-priming / antibiotic-stewardship / outbreak-recovery; Phase 4 historical context cards cover Koch / Pasteur / Salk / Marshall — Marshall's H. pylori work especially overlaps medical-trauma surface area). So this audit checks each scaffold against the **6 SAMHSA TIP 57 principles** + the **6 off-ramp requirements** even though MicrobeLab as a whole sits in the AWARE tier.

Per ADR-016, user-direct standing approval covers the **story-axis** (chapter prose authoring) AS LONG AS:
1. SAMHSA TIP 57 register applied (validate-then-inform / hold-space / refer-up)
2. Off-ramps + content warnings + crisis-resource lists shipped
3. Cultural-respect framing (Indigenous + traditional credited without mascotization)
4. Anti-shame framing (structural / systems-level framings replace personal-failing)
5. Anti-evangelism for contested life-questions
6. ADR-016 cited in the per-app handoff with trauma-axis flags
7. ADR-012 art-axis path remains load-bearing for downstream art generation

This audit checks each scaffold's structural surface area against constraints 1-6. Constraint 7 lives at the asset-generation seam (currently `await labsmith portrait pack`).

## Per-scaffold verdict matrix

| # | Scaffold | PR | Gate semantics | Authoring state | SAMHSA register stoplist test? | Off-ramp surface plumbed? | Consent axis correct? | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | `DiseaseStoryArc` + `DiseaseStoryService` | #141 | `disease-story-immune` (vaccinePriming) + `disease-story-microbiome` (handwashing / antibioticStewardship / outbreakRecovery) | `.placeholder` for all 4 arcs | ✅ 11 unit tests pin display titles + primitives against the warfare + shame + threat lexicon stoplist (`fight` / `attack` / `war` / `battle` / `weapon` / `kill` / `destroy` / `enemy` / `germ` / `scary` / `fear`) | ✅ `ArcPresentation.gatedBehindConsent` enum case fires when `ParentalConsentService.diseaseStoryArcs` is opt-out — view layer renders the parent-handoff surface instead of the arc body | ✅ `gateID` routes match the per-arc trauma-axis (vaccinePriming → immune gate; the other 3 → microbiome gate) | **PASS** at structural tier — prose authoring is still gated by `DiseaseStoryAuthoring.reviewerSignedOff` per ADR-016 |
| 2 | `VaccineExplainerStep` + `VaccineExplainerService` | #154 | `disease-story-immune` | `.placeholder` for all 4 pedagogy beats (introduction / antibodyPriming / memoryFormation / boosterRationale) | ✅ Stoplist tests pin step titles + primitives (no warfare lexicon in `.antibodyPriming` framing; "library" + "priming" register replaces "weapon" + "trained killer") | ✅ `StepPresentation` 4-case switch — `.gatedBehindConsent` fires when consent absent; view rendering deferred per reviewer-signoff gate | ✅ Single gate (disease-story-immune) — vaccine pedagogy correctly tagged immune-axis, not microbiome | **PASS** at structural tier |
| 3 | `HistoricalContextCard` + `HistoricalContextService` | #164 | `disease-story-immune` (all 4 figures share the immune gate per ADR-016) | `.placeholder` for all 4 figures | ✅ Anti-credentialism gate per CQ CONTENT_STYLE_GUIDE.md § 4.5 — stoplist test pins hero-myth + mortality + warfare lexicon forbidden on titles + eras + contributions | ✅ Cards inherit `ParentalConsentService.diseaseStoryArcs` opt-in (single consent axis shared with disease-story arcs) | ✅ Marshall ↔ Pylo cross-cast bridge (Phase 2 cast PR #119); cross-portfolio bridges to labsmith (notebook register) + curiosityquest (kid-scientist register) named explicitly | **PASS** at structural tier — anti-credentialism guard rail explicitly applied |
| 4 | `DespairSignalDetector` + `DespairSignalSurface` | #167 | N/A (ambient detection, not gated) | N/A (pure-value detector; no authoring state) | ✅ Phrase-level stoplist derived from SAMHSA TIP 57 + Crisis Text Line training material; tests cover diacritic + case + whitespace-insensitive normalization | ✅ `DespairSignalSurface.presentation(for:)` returns trauma-informed `Presentation` (header + hedge + canonical 3-resource list reusing portfolio-canonical `CrisisResources.all`); `ReflectionEntryStore.append(_:)` publishes `pendingDespairPresentation` to view consumers | ✅ Three-tier severity (`.calm` / `.elevatedDistress` / `.elevatedCrisis`); crisis wins on mixed text — surfaces 988 + Crisis Text Line + Childhelp | **PASS** — load-bearing for any future trauma-adjacent surface; on-device only (free text never logged) per privacy posture |
| 5 | `PhaseBoundaryNote` + `PhaseBoundaryExplainerService` | #168 | Per-note: disease-story (immune + microbiome) + historical-context (immune) + global-tour (none — ecology+adaptation) | `.placeholder` for all 3 notes | ✅ `requiresConsent` axis distinguishes trauma-gated notes (disease-story + historical context = true) from ecology-only notes (global tour = false per ADR-016) | ✅ `BoundaryPresentation` 4-case switch (`.notReached` / `.awaitingConsent` / `.readyToInvite` / `.alreadyAccepted`); `acknowledge(_:)` per-note for non-consent notes; `resetAcknowledgements()` for testing | ✅ Canonical catalog order — disease-story → historical context → global tour (lowest session-day floor first); per-note `requiresConsent` axis is load-bearing | **PASS** at structural tier — parent-facing explainer surface ready for prose authoring |
| 6 | `GlobalMicrobiomeTourStop` + `GlobalMicrobiomeTourService` + `GlobalMicrobiomeTourView` | #162 + #169 | `global-microbiome-tour` (ecology + adaptation, NO consent axis per ADR-016) | `.placeholder` for all 4 stops | ✅ Indigenous TEK cultural-respect gate (load-bearing) per `.claude/rules/distributed-narrative.md` § cultural-sensitivity gates — Yellowstone primitive surfaces Indigenous TEK credit; test pins the credit surface presence | ✅ View renders Indigenous TEK credit footer at EVERY authoring state (not gated behind reviewer signoff) so the credit surface is correct today + auto-upgrades when prose lands | ✅ Distinct from disease-story arcs in NOT requiring parental consent — ecology + adaptation framing | **PASS** at structural tier — cultural-respect framing explicitly hard-coded |

## Cross-cutting conformance

### SAMHSA TIP 57 — six principles per scaffold

| Principle | Mapping to MicrobeLab scaffolds | Verdict |
|---|---|---|
| **Safety** | Predictable session structure (no surprise reveals); content warnings via `ParentalConsentService.diseaseStoryArcs` opt-in; "leave" affordance via the always-present onboarding parent-handoff surface | ✅ Structural surface present across scaffolds 1 / 2 / 3 / 5 |
| **Trustworthiness & transparency** | `DiseaseStoryAuthoring.placeholder` state surfaces "Coming soon" not silent omission; `PhaseBoundaryExplainerService` invites parent into the gate decision BEFORE the kid encounters the gated content | ✅ Per-scaffold `Presentation` enum surfaces the gate state explicitly |
| **Peer support** | N/A for MicrobeLab Phase 3+ surfaces (no multiplayer at disease-story tier; pass-and-play deferred to Phase 4 classroom mode) | ✅ Not applicable; no peer surface to gate |
| **Collaboration & mutuality** | AI mentor (Cilia via `VeeMentor`) carries the Socratic register per `.claude/rules/foundationmodels.md`; `PublicHealthHypothesis` `@Generable` (#153) explicitly forbids warfare + shame + threat lexicon in LLM prompt; static fallback ALWAYS available | ✅ Per-scenario register cue (handwashing → care / vaccine → library / antibiotic → patience / outbreak → community) verified by `AIMentorTests` |
| **Empowerment, voice & choice** | Daily session cap (parent-gated); off-ramp affordance on every immune-game wave; mentor calmly acknowledges difficulty | ✅ `AppSettings` + `ImmuneGameView` + mentor copy verified across PRs |
| **Cultural, historical & gender issues** | `GlobalMicrobiomeTourView` renders Indigenous TEK credit footer at every authoring state; `HistoricalContextCard` anti-credentialism gate per CQ CONTENT_STYLE_GUIDE § 4.5; gender register on cast is balanced (Lacto / Yeast / Photo / Net / Spore / Guard all gender-neutral named) | ✅ Cultural-respect framing hard-coded; gender register inherited from chapter author voice |

### Off-ramps — six requirements

| Requirement | Current MicrobeLab surface | Verdict |
|---|---|---|
| **Pre-content content warning** | `ParentalConsentService.diseaseStoryArcs` opt-in is the per-arc content warning — parent reviews the topic header before the kid sees the body | ✅ Per-arc consent surface |
| **In-content skip affordance** | `MicrobeLabTab` shell always renders a visible "leave to Explore" affordance — every Phase 3+ surface is reachable from the Explore tab and dismissable back to it | ✅ Tab shell affordance |
| **Skip-with-summary** | Deferred — per-arc summary copy lands with reviewer-signed-off prose authoring | ⚠️ Deferred to prose tier per ADR-016 |
| **Audio-only / silent mode** | Deferred — Phase 2 audio drama per `.claude/rules/distributed-narrative.md` § Phase 2 + `Docs/HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` waits on Google Cloud TTS / ElevenLabs vendor lock-in | ⚠️ Deferred to Phase 2 audio drama pipeline |
| **Pacing control** | Variable-reward selector cadence + session-target service per Phase 1; respects `accessibilityReduceMotion` per `.claude/rules/swiftui.md` | ✅ Inherited from Phase 1 engagement surfaces |
| **Optional debrief** | `WelcomeBackOverlay` carries the warm callback line via `MentorRecallStore`; trauma-safe pivot (no abandonment framing) verified by `longGapCueAvoidsAbandonmentFraming` test | ✅ Warm-callback debrief surface |

### Crisis-resource surfacing

`Services/AppShell/CrisisResources.swift` ships the portfolio-canonical 3-resource list (988 Suicide & Crisis Lifeline / Crisis Text Line / Childhelp). Surfaces:

- **`DespairSignalSurface.presentation(for:)`** — ambient detection path (PR #167); reuses `CrisisResources.all`
- **`SettingsView.CrisisResourceCard`** — always-visible parent-facing surface; lives at AppFeature/Settings/
- **Mentor refer-up path** — `VeeMentor` does NOT attempt therapy; out-of-scope distress signals route the kid to the always-visible CrisisResourceCard per the mentor posture rule

✅ Per SAMHSA TIP 57 § "The mentor posture for heavy content" the three rules (validate-then-inform / hold-space / refer-up) are encoded across the AIMentor + Services boundary.

## Constraints NOT covered by this audit

This audit closes the **structural-tier conformance** checkbox at FEATURE_PLAN line 261. It does NOT claim:

- **Prose reviewer signoff per ADR-016** — every `*Authoring` enum state defaults to `.placeholder`; `.reviewerSignedOff` only fires when the user-direct ADR-016 conformance review happens per-chapter / per-card / per-step. The audit verifies the GATE EXISTS, not that any single piece of prose has been reviewed.
- **External R0 sensitivity-reviewer signoff for downstream art generation** — ADR-012 art-axis path remains load-bearing for any trauma-adjacent illustration (chapter opener + spot art at `Resources/Chapters/` already shipped per `HANDOFF_FROM_LABSMITH_CHAPTER_ILLUSTRATIONS_TRAUMA_GATED_WAVE.md`; future Phase 3+ art waves still route through ADR-012's audit pathway).
- **Site-side / spark-anvil-site surfacing of the same content** — that's a separate labsmith-side audit per `.claude/rules/spark-anvil-website.md` § "DN-S chapter-book pages" and is out of scope here.

## Action summary

- **FEATURE_PLAN.md line 261**: ✅ CLOSED at structural-tier conformance (verified PRs #141 / #152 / #154 / #162 / #164 / #167 / #168 / #169 + Phase 1 surfaces).
- **Prose authoring**: continues to be `.placeholder`-gated per ADR-016; reviewer-signoff per-chapter / per-card / per-step is a per-PR gate.
- **Skip-with-summary** + **audio-only / silent mode**: tracked as ⚠️ deferred to the prose tier + Phase 2 audio drama pipeline; no Phase 3 + 4 prose ships without the skip-with-summary copy live.

## Cross-references

- ADR-011 § Cross-Repo Audit Methodology (this audit follows pull-first + freshness horizon)
- ADR-016 (trauma-gated DN-S story-axis approval per user-direct R363)
- ADR-012 (trauma-adjacent art-axis path per founder-ADR-approved AI gen)
- `.claude/rules/trauma-informed-content.md` § "Hard requirement" + § "Soft recommendation"
- `Docs/TECHNICAL_DESIGN.md` § "Trauma-Informed Design Posture (COVID-era sensitivity)"
- `Docs/HANDOFF_FROM_LABSMITH_CHAPTER_ILLUSTRATIONS_TRAUMA_GATED_WAVE.md` (closes art-axis at Phase 1 surfaces)
- `Docs/HANDOFF_FROM_LABSMITH_DN_S_STORY_PER_CHARACTER.md` (Phase 2 audio drama dependency)
- `Docs/AUDIT_HANDOFF_INBOUND_2026-06-16.md` (parent audit; this audit closes one of its DEFER items at the structural tier)
- `Docs/FEATURE_PLAN.md` § "Phase: Accessibility & Trauma-Informed Polish" line 261 (target of this audit)
