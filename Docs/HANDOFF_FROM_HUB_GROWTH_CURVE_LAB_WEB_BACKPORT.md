# Handoff from Hub — Growth Curve Lab (web-pioneered → iOS backport)

Direction: **hub → app**. The `/play/microbelab` web clone shipped a new interactive learning
surface — **Growth Curve Lab** — that the MicrobeLab iOS app does not have. Per
R-CLONE-BIDIRECTIONAL-BACKPORT this is filed as a 🟡 iOS-backport candidate for the app's own
Claude Code session to implement (hub never writes Swift).

## The feature

A **predict-observe-explain (POE)** manipulative for the **binary-fission / exponential-growth**
primitive from kits 01–02 ("microbes grow by doubling"), which on iOS today ships only as
Concepts-MC. A colony starts at N₀ cells and DOUBLES every generation time, so after `t` minutes:

```
N = N₀ · 2^(t / doubling)
```

The learner **predicts** one of three things BEFORE the growth curve reveals the answer:
- **population** — how many cells after `t` minutes,
- **doublings** — how many doublings fit in `t` minutes (`t ÷ doubling`),
- **compare** — exponential vs a "linear" straight-line guess ("adds N₀ each step"), which badly
  under-counts.

The load-bearing pedagogy is the **exponential-vs-linear misconception**: learners routinely
under-predict, treating "doubles every 20 min" as "adds the same amount each step." The web surface
makes this visible by drawing the exponential curve **over a faint dashed linear-guess reference
line**, and by offering the linear under-count as the primary distractor ("500 cells (linear)" vs
the correct "1600 cells (doubling wins)").

## Web reference implementation

- Engine (pure, deterministic, framework-free): `spark-anvil-site/src/lib/play/microbelab/growth.ts`
  - `doublings(minutes, doubling)`, `population(start, doubling, minutes)`,
    `linearGuess(start, doubling, minutes)` (the misconception model), `computeAnswer(challenge)`.
  - 12-challenge bank; every answer engine-derived; misconception under-count distractor per item.
- Island / UI: `spark-anvil-site/src/lib/play/microbelab/growthlab.ts` (quiet accent-topped stage,
  NaN-safe growth-curve SVG with a dashed linear reference line, prominent Q&A cards).
- Tests: `spark-anvil-site/src/lib/play/microbelab/growth.test.ts` (arithmetic + bank integrity +
  NaN-free SVG; 9 specs, all green).
- Route: `/play/microbelab/growth` (live).

## Proposed iOS surface

A new **Growth Curve** mode alongside Immune Match / Immune Response / Microbiome Lab:

- A SwiftUI / SpriteKit growth-curve view: an exponential curve building doubling-by-doubling,
  with a faint linear-guess reference line for the POE contrast; tabular elapsed / doublings readouts.
- Reuse `ForgePedagogy.PolyaScaffold` for articulate-before-hint (predict before the reveal;
  hint only after a first miss) + the shared first-try scoring + anti-shame register.
- Kit-derived challenge bank mirroring the web engine's `N = N₀·2^(t/doubling)` arithmetic — engine
  is the source of truth, options include the linear under-count misconception.
- Calm, no-alarm register consistent with the MicrobeLab "most microbes are friends" posture
  (growth here is neutral/curious, not a threat framing).

## Parity ledger

Tracked as a 🟡 web-pioneered → iOS-backport row in
`spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md` (Expansion passes — Pass 3). The row
closes when the app ships the mode back (a `HANDOFF_FROM_APP_*_SHIPPED` return).

## What this handoff does NOT cover

- No Swift is written by hub. The app session owns the implementation, the Xcode wiring, and tests.
- Web social rails / mastery / engagement shells (pass-and-play, room MP, adventure) are separate
  passes with their own handoffs — not part of this one.

## References

- `spark-anvil-hub/Docs/web/microbelab/AUDIT_WEB_CLONE_EXPANSION_microbelab_MANIP_2026-07-18.md`
- `.claude/rules/spark-anvil-website.md` §R-WEB-CLONE-POE / §R-WEB-CLONE-CRA-LADDER / §R-CLONE-BIDIRECTIONAL-BACKPORT
- Site PR #951.
