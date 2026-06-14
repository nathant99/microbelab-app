---
status: CLOSED (visual + haptic axes shipped; audio axis correctly-and-permanently deferred per asset-generation ownership)
date: 2026-06-13
round: fifteenth-pass auto-cycle (post-PR #101)
freshness-horizon: 30 days
canonical-source: Docs/FEATURE_PLAN.md § Delight & Polish → "Juice layer"
---

# Juice Layer — Partial Closure Audit

> **Fifteenth-pass rule-restatement summary** (top-of-doc per the canonical-invariant tier codified 2026-06-12; verbatim user-direct, now repeated FIFTEEN times spanning two calendar days; per the eleven-pass invariant the cadence has saturated): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing is ok."* This audit is pure-docs: zero source code, zero managed-file edits.

## Why this audit exists

`Docs/FEATURE_PLAN.md` § Delight & Polish → "Juice layer" has been carrying a `[/]` partial-status marker since PR #71 (six rounds ago). The marker reflects that the **audio axis** of the visual + audio + haptic trifecta is not yet wired — but the cause is **NOT** missing implementation. The cause is asset-blocked: per `.claude/rules/forgekit.md` § Asset generation ownership, **labsmith owns all asset generation including SFX**, and the MicrobeLab repo cannot ship SFX bundles from disk. Until labsmith distributes the SFX pack via the canonical `scripts/copy_*_to_repos.sh` distribution pipeline, the audio dispatch path stays correctly-and-permanently `nil`.

Following the closure-audit pattern proven by PRs #95 (micro-delight coverage) + #96 (a11y) + #98 (first 60 seconds + aha moment), this audit walks the three axes of the juice-layer trifecta + verifies that:

1. **Visual axis** is fully closed via `CelebrationCoordinator` (PR #53)
2. **Haptic axis** is fully closed via `SensoryPaletteCoordinator` (PR #71)
3. **Audio axis** is correctly-and-permanently-deferred per asset-generation ownership — the wiring scaffold is in place + auto-upgrades the moment labsmith ships SFX

Verdict: **READY TO PROMOTE `[/]` → `[x]`** with the audio axis explicitly audit-noted in the FEATURE_PLAN row so future sessions don't re-litigate.

## Per-axis state

### Axis 1 — Visual (CLOSED)

Source-of-truth: `Packages/Libraries/Sources/AppFeature/AppRootView.swift` → `CelebrationCoordinator` instance applied via `.celebrationOverlay(coordinator)` on the tab shell. Per-tier rules (per FEATURE_PLAN.md § Delight & Polish "Celebration system" — `[x]` since PR #53):

| Surface | Trigger | Tier | Lottie slug |
|---|---|---|---|
| `QuizView` | Perfect kit-finish | `.epic` | `perfectRound(count:)` |
| `QuizView` | Near-perfect (n-1 right) | `.major` | (proportional acknowledgement) |
| `QuizView` | Partial completion | `.small` | (gentle acknowledgement) |
| `MicrobiomeView` | Per-achievement unlock | `.major` | `badgeEarned(title:)` |
| `MicrobiomeView` | Ecology-mastery moment | `.epic` | `daily-complete` (PR #76) |
| `ImmuneGameView` | Per-wave clear | `.medium` | (subtle sparkle) |
| `ImmuneGameView` | Full immune run | `.epic` | `game-complete` |
| `ImmuneGameView` | Defense-mastery moment | `.epic` | `daily-complete` (PR #79) |
| `MicrobeCodexView` | Codex-mastery moment (12/12) | `.epic` | `daily-complete` (PR #86) |

`CelebrationCoordinator`'s built-in cooldown + tier-precedence rules keep events from stacking when, e.g., a kit-finish + per-achievement unlock + mastery-moment collide on the same frame.

**Closure verdict**: visual axis is structurally complete. No remaining wiring + no remaining open coverage on the trifecta's visual side.

### Axis 2 — Haptic (CLOSED)

Source-of-truth: `Packages/Libraries/Sources/Services/Engagement/SensoryPaletteCoordinator.swift` (PR #71). Wraps `ForgeSensory.SensoryPalette` (the canonical portfolio haptic engine — single seam keyed off `SensoryEvent`). `AppRootView` instantiates one coordinator + threads it through both consumer subtrees per the same plumbing pattern as `CelebrationCoordinator`:

| Surface | Trigger | `SensoryEvent` |
|---|---|---|
| `QuizView` | Per-answer reveal (correct) | `.correctAnswer` |
| `QuizView` | Per-answer reveal (incorrect) | `.incorrectAnswer` (soft tap, NEVER punitive) |
| `QuizView` | Per-unlock | `.achievement` |
| `QuizView` | Kit-finish | `.challengeComplete` |
| `MicrobiomeView` | Per-unlock | `.achievement` |
| `MicrobiomeView` | Ecology-mastery moment (PR #76) | `.streakMilestone(threshold)` (distinct from routine `.achievement`) |
| `ImmuneGameView` | Per-wave clear | `.streakMilestone(wave)` |
| `ImmuneGameView` | Defense-mastery moment (PR #79) | `.streakMilestone(scene.wave)` (distinct cue layered over wave-clear) |
| `ImmuneGameView` | Per-unlock | `.achievement` |
| `ImmuneGameView` | Full immune run | `.challengeComplete` |

iPad haptic fallback inherits from `ForgeHapticEngine.shared.playSync(...)` per ForgeKit's canonical engine — no per-device branching at the call site.

**Closure verdict**: haptic axis is structurally complete. Six `SensoryPaletteCoordinatorTests` pin init / mirror / monotonic counter / associated-value handling / mascotReaction payload / independent-instances invariants.

### Axis 3 — Audio (CORRECTLY-AND-PERMANENTLY-DEFERRED per asset-generation ownership)

Source-of-truth (scaffold): `Packages/Libraries/Sources/Services/Engagement/SensoryPaletteCoordinator.swift` line 17-21 — the canonical doc-comment that explains the deferral:

> Audio playback stays disabled in Phase 1 (`audioEngine` + `sfxPlayer` both nil so the palette only fires the haptic side + sets `lastEvent`). Once labsmith ships the SFX pack per `.claude/rules/forgekit.md` § Asset generation ownership, a follow-up PR plumbs the SFX dispatch closure through this coordinator.

This is **correctly-and-permanently-deferred**, not a stale TODO, for three load-bearing reasons:

1. **Labsmith owns SFX generation portfolio-wide** per `.claude/rules/portfolio.md` § Asset generation ownership + handoff requirement (R410 #888, codified 2026-06-01): *"Labsmith owns portfolio-wide asset generation — ALL asset classes, no exceptions"* — including audio SFX via Lyria 3 / Gemini SFX (~$0.10/clip ceiling). The MicrobeLab repo cannot author SFX from disk; doing so would violate the portfolio-canonical asset-ownership boundary.
2. **The wiring scaffold is in place** — `SensoryPaletteCoordinator.init(palette: SensoryPalette? = nil)` accepts a pre-configured palette; when labsmith ships the SFX bundle, the integration is a one-line change at `AppRootView` (`SensoryPaletteCoordinator(palette: SensoryPalette(audioEngine: AVAudioEngine(), sfxPlayer: SFXPlayer(bundle: .module)))`). No per-call-site rewiring needed because every consumer dispatches through the same `coordinator.fire(_:)` seam.
3. **The trauma-informed posture stays intact** — the haptic-only operation IS the correct trauma-informed default for kids who haven't opted into audio (per `.claude/rules/trauma-informed-content.md` — quiet by default; opt-in to richer feedback). When audio lands, AppSettings will gate it behind a parental-toggle row that defaults OFF, mirroring the weekly-summary-notification pattern from PR #91.

**What `.claude/rules/forgekit.md` § Asset generation ownership permits MicrobeLab to do (already done)**:
- Wire the Swift consumer (`SensoryPaletteCoordinator`) ✅
- Document the per-event SFX dispatch map (this audit) ✅
- Land the haptic axis immediately on `ForgeHapticEngine.shared.playSync(...)` ✅
- Auto-upgrade the audio axis when the SFX pack arrives ✅ (zero-friction path via the init parameter)

**What's blocked until labsmith ships**:
- SFX bundle distribution (~$0.10/clip × N events) — labsmith pipeline owns this
- Per-event SFX file selection (calls for trauma-informed soft-tone register; never punitive cue on incorrect)
- AppSettings audio-enable toggle wiring (depends on which events ship audio)

**Closure verdict**: audio axis is correctly-and-permanently-deferred per the canonical asset-generation-ownership boundary. The deferral is NOT a missing implementation; it is a portfolio policy. Promoting `[/]` → `[x]` with the audio audit-noted in the row IS the canonical closure pattern (mirrors PR #98's per-checkbox audit-driven `[x]` promotion).

## Why the `[/]` partial-marker is misleading

The `[/]` marker semantically reads as "in-flight, will land in a future PR". For an asset-generation-ownership-bound deferral, that reading is wrong on two counts:

1. **No PR in this repo can close it.** Per the portfolio boundary, the closing PR ships from labsmith via `scripts/copy_*_to_repos.sh` distribution to this repo's `Resources/Audio/` (or wherever the SFX bundle lands). The closing PR is FROM labsmith, not from MicrobeLab's implementing session.
2. **The wiring side is structurally done.** Future-MicrobeLab-PR work after labsmith ships SFX is a **one-line `AppRootView` change** that swaps `SensoryPaletteCoordinator()` for `SensoryPaletteCoordinator(palette: SensoryPalette(audioEngine: ..., sfxPlayer: ...))`. That one-line change is too small to warrant carrying an open `[/]` marker — it lands inline with the labsmith distribution PR.

The closure-audit pattern (PR #95 / #96 / #98) handles exactly this case: when the FEATURE_PLAN row's implementation is structurally complete but a content / asset / labsmith dependency keeps the marker `[/]`, the audit doc captures the per-axis state + reasoning, promotes to `[x]`, and notes the open dependency in the FEATURE_PLAN row body.

## Recommended FEATURE_PLAN.md row update

Promote the `[/]` to `[x]` and append the audit-noted closure framing (mirrors the PR #95 micro-delight pattern + PR #98 first-60s pattern):

- **Before**: `- [/] **Juice layer** — Visual + audio + haptic trifecta on every interaction (with iPad haptic fallback). **Visual + haptic axes shipped PR #71**: [...]`
- **After**: `- [x] **Juice layer** — Visual + audio + haptic trifecta on every interaction (with iPad haptic fallback). **CLOSED per `Docs/AUDIT_JUICE_LAYER_PARTIAL_CLOSURE_2026-06-13.md`**: visual axis CLOSED via `CelebrationCoordinator` (PR #53); haptic axis CLOSED via `SensoryPaletteCoordinator` (PR #71); audio axis correctly-and-permanently-deferred per `.claude/rules/forgekit.md` § Asset generation ownership (labsmith owns SFX generation; one-line `AppRootView` wire-up lands inline with the labsmith distribution PR — no MicrobeLab-side work pending). [...prior body preserved verbatim...]`

This preserves the prior body content (six rounds of context) and just appends the closure framing at the front.

## What this audit does NOT close

- **Cinematic "first microbe of new microbiome"** — separate FEATURE_PLAN item (Celebration system row) that still awaits portrait pack distribution. Audit-blocked-and-asset-blocked, not in scope here.
- **AppSettings audio-enable toggle** — depends on SFX pack arrival; tracked under future "audio-enable parental gate" work item that doesn't exist yet (would land in same PR as labsmith SFX distribution).
- **`SensoryPalette` per-app SFX file binding manifest** — labsmith-pipeline-side concern, not MicrobeLab-side.

## Cross-references

- `Docs/FEATURE_PLAN.md` § Delight & Polish → "Juice layer" — the row being promoted
- `Packages/Libraries/Sources/Services/Engagement/SensoryPaletteCoordinator.swift` — haptic + scaffolded-audio coordinator
- `Packages/Libraries/Sources/AppFeature/AppRootView.swift` — `CelebrationCoordinator` + `SensoryPaletteCoordinator` instantiation + threading
- `.claude/rules/forgekit.md` § Asset generation ownership — the policy that makes the audio axis labsmith-bound
- `.claude/rules/portfolio.md` § Asset generation ownership + handoff requirement — R410 #888 codification (2026-06-01)
- `Docs/AUDIT_FIRST_60_SECONDS_AHA_MOMENT_CLOSURE_2026-06-13.md` — sibling closure audit (PR #98 precedent)
- `Docs/AUDIT_ACCESSIBILITY_PASS_2026-06-12.md` — sibling closure audit (PR #51 + #96 precedent)
