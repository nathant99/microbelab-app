---
status: SHIPPED
date: 2026-06-01
shipped-date: 2026-06-17
round: Round 397 #820 (labsmith DN-S Integration Phase 1D portfolio rollout — microbelab)
parent-decision: labsmith/Docs/DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md
parent-plan: labsmith/Docs/PLAN_DN_S_PORTFOLIO_ROLLOUT_WAVES_2026-06-01.md
template-source: labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md
forgekit-version-required: 0.97.0 (CastDialog API) — shipped path uses 1.0.0-rc.3 + the new `CastDialogContext.emotionSnapshot` field per the thirty-fourth-pass round PR #207
trauma-gating: NONE
moderation-sensitivity: .normal
shipped-via: PR #173 (twenty-sixth-pass round; CastVoiceRegistry + 6 MicrobeCastVoiceProfiles + `cast_voicing` flag scaffold) + PR #181 (twenty-seventh-pass round; production wiring via `VeeMentor.voicedRecallCue` dispatching through CastDialog) + PR #207 (thirty-fourth-pass round; ForgeKit 1.0.0-rc.3 pin + `EmotionSnapshotDerivation` seam for the rc.3 continuous-band affect-attunement). Implementation steps 1-4 fully closed; step 5 (regression-test moderation pipeline at 100-interaction sample scale) deferred until TestFlight unblocks (currently entitlement-blocked per the canonical age-gate handoff).
---

# Handoff from Labsmith — DN-S AI-Mentor Voicing for Microbelab

Direction: **labsmith → microbelab-app**. Operationalizes Option D of labsmith's `PLAN_DN_S_INTEGRATION_PHASES_2026-06-01.md` (ADR-019; Phase 1D approved per `DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md` R394 #818) for microbelab.

## What this handoff delivers

A per-app `CastVoiceRegistry` (Swift) mapping microbelab's 6 cast members' chapter voice-register cards into `CastVoiceProfile` instances consumable by ForgeKit 0.97.0's `CastDialog` API. When wired, the AI mentor can speak AS any cast member in the character's voice register.

## Pre-requisites

- [ ] ForgeKit pin in `Libraries/Package.swift` is `from: "0.97.0"` or higher
- [x] `Docs/dn-s/chapters/*.md` files exist for every cast member (6 of 6 shipped; total 1614 words)
- [ ] App's existing AI mentor service uses `FoundationModels.LanguageModelSession`
- [x] App is in the Phase 1D portfolio rollout (post-pilot trio)

## Microbelab cast inventory + voicing priority

| Order | Character | Slug | Primitive embodied | Chapter words | Priority rationale |
|---|---|---|---|---|---|
| 1 | Guard | `guard` | (derive from chapter) | 279 | Lead — establishes CastVoiceRegistry baseline; voice-clarity heuristic |
| 2 | Lacto | `lacto` | (derive from chapter) | 273 | Secondary lead — order 2 |
| 3 | Net | `net` | (derive from chapter) | 262 | Secondary lead — order 3 |
| 4 | Photo | `photo` | (derive from chapter) | 260 | Wave-batch — order 4 |
| 5 | Spore | `spore` | (derive from chapter) | 313 | Wave-batch — order 5 |
| 6 | Yeast | `yeast` | (derive from chapter) | 227 | Wave-batch — order 6 |

**Cast total**: 6 chapters; 1614 words.

## Implementation steps

Follow `labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` § Implementation, customized to microbelab's cast:

1. **[x] SHIPPED PR #173** — Derive `CastVoiceProfile` per chapter using `labsmith/Docs/SCHEMA_CAST_VOICE_REGISTRY.md`. 6 profiles authored in `Sources/AIMentor/MicrobeCastVoiceProfiles.swift` (lacto / yeast / photo / net / spore / guard_), one per DN-S chapter; each carries id, displayName, 1-sentence embodiment, 4 catchphrases, and the portfolio trauma-informed antiPatterns stoplist. Spore extends the shared stoplist with 3 COVID-trauma-aware guards per the chapter's STRONGEST trauma-axis gate.
2. **[x] SHIPPED PR #173** — Build `CastVoiceRegistry` at app launch. `Sources/AIMentor/CastVoiceRegistry.swift` (`nonisolated public struct`) wraps the 6 profiles + O(1) slug lookup + `register(into:)` extension that registers every profile against a `CastDialog` actor in a single async hop. `AppRootView.wireCastVoicingIfEnabled()` instantiates + registers when the `cast_voicing` flag returns `.enabled`.
3. **[x] SHIPPED PR #181 + extended PR #207** — Wire AI mentor call sites to invoke `castDialog.respondAs(.character(slug), prompt:, context:)`. `VeeMentor.voicedRecallCue(for:daysSinceLastSeen:context:)` dispatches utterances through `CastDialog.respond(as:trigger:context:)` for the `.greeting` trigger. PR #207 extends the dispatch surface by documenting the new `CastDialogContext.emotionSnapshot` field (ForgeKit 1.0.0-rc.3) + ships `Services.EmotionSnapshotDerivation` mapping `DespairSignalDetector.Severity` (PR #167) → `EmotionSnapshot?` so callers can populate the affect-attunement seam without ad-hoc derivations.
4. **[x] SHIPPED PR #173** — Feature-flag via `ForgeExperiments.castVoicing` (default off; TestFlight enable). `ExperimentsService.castVoicing` registered with the deterministic SHA256(seed|experimentID) bucketing pattern; defaults 100% control / 0% enabled. The TestFlight debug toggle (in-app way to flip the variant for QA) is deferred until TestFlight unblocks (currently entitlement-blocked per `Docs/HANDOFF_TO_USER_DECLARED_AGE_RANGE_ENTITLEMENT.md`).
5. **[/] DEFERRED to TestFlight unblock** — Regression-test moderation pipeline (100 sample interactions across diverse contexts). Requires kid-session telemetry which the canonical entitlement-blocked TestFlight surface gates. Can run as a synthetic 100-utterance audit ahead of TestFlight via a `RegressionTestKit` helper if QA bandwidth permits; the structural seam is in place via the experiment flag + the CastDialog moderation pipeline.

## Pilot-derived learnings (codified per `DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md`)

1. **Prompt-budget calibration FIRST** — for any app with chapters > 1500w, measure input tokens before authoring all profiles
2. **12-profile perf ceiling validated** — `CastVoiceRegistry` at 12-profile scale fits on iPad Mini 2026
3. **Paired-voicing API works without extension** — `respondAs(.character(slug), ...)` handles "we"/plural automatically for paired chapters
4. **Crisis-keyword fallback is universal** — ForgeKit's built-in moderation handles distress signals
5. **Voicing-priority order matters** — start with most-formal-register character

## Success criteria

- [/] Voice fidelity: 100 sample audit; ≥ 90% rated "clearly this character" for each profile — **defer to TestFlight unblock** (audit requires kid sessions; currently entitlement-blocked per `Docs/HANDOFF_TO_USER_DECLARED_AGE_RANGE_ENTITLEMENT.md`)
- [/] Character drift rate: < 2% per session — same TestFlight gating
- [/] Engagement parity: session length / kit completion / hint frequency ≥ baseline single-mentor — same TestFlight gating
- [x] Crisis-keyword fallback verified — CastDialog output-moderation pipeline guards every utterance per `ForgeServerSafety` integration (rc.3 changelog); MicrobeLab-side reflection-entry screening via `DespairSignalDetector` (PR #167) layered on top per the canonical safety surface; affect-attunement pipeline now consumes the same severity per `EmotionSnapshotDerivation` (PR #207)
- [x] Feature-flag shipped (default off) — `cast_voicing` registered in `ExperimentsService` (PR #173); default 100% control / 0% enabled; `AppRootView.wireCastVoicingIfEnabled()` only instantiates the CastDialog when the experiment returns `.enabled`

## Effort estimate

- 6 `CastVoiceProfile`s × ~15-20 min/profile derivation = ~2-4h
- Registry + wiring + regression-test = ~1-2h
- Total per-app CC session: ~3-7h
- ~14d telemetry observation (optional; gated on app-side decision)

## Cross-references

- `labsmith/Docs/DECISION_DN_S_AI_MENTOR_PORTFOLIO_ROLLOUT.md` — parent decision (R394 #818)
- `labsmith/Docs/PLAN_DN_S_PORTFOLIO_ROLLOUT_WAVES_2026-06-01.md` — rollout sequencing
- `labsmith/Docs/TEMPLATE_HANDOFF_FROM_LABSMITH_DN_S_AI_MENTOR_VOICING.md` — template
- `labsmith/Docs/SCHEMA_CAST_VOICE_REGISTRY.md` — `CastVoiceProfile` schema
- `labsmith/Docs/ADR-019_DN_S_INTEGRATION_OVER_ENSEMBLE_STORIES.md` — decision rationale
- `forgekit/Docs/CHANGELOG.md` (0.97.0) — `CastDialog` API
- `.claude/rules/distributed-narrative.md` § DN-S Integration — portfolio rule
- `.claude/rules/foundationmodels.md` — FoundationModels safety patterns


- Local: `Docs/dn-s/chapters/*.md` (6 chapters, 1614 words total) — source content

---

**Disposition**: ✅ HANDED OFF — implementation belongs to microbelab-app's CC session. No retrospective required (portfolio rollout proceeds without per-app retrospective gating).
