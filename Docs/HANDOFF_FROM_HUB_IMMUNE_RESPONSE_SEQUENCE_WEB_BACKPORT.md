# Handoff to MicrobeLab — Immune Response sequence drill (web-pioneered → iOS backport)

Direction: **hub → app**. The `/play/microbelab` web clone shipped a new learning surface the iOS
app lacks; per R-CLONE-BIDIRECTIONAL-BACKPORT it is filed here for the MicrobeLab iOS session to
implement (hub never writes Swift). Filing this handoff is the START of the obligation, not its
completion — the web parity ledger's 🟡 Axis-3 row stays open until iOS ships it back (or replies
with a documented waiver).

Date: 2026-07-12 · Web clone: #28 (science) · Source: hub web-clone build.

## The feature — "Immune Response" (sequence the body's defense)

A tap-to-**order** drill: the learner is given a scenario (a scrape, a first meeting with a new
germ, meeting the same germ again, a cold virus, an inflamed cut, friendly gut microbes arriving)
and a **scrambled set of response steps**, and must place them in the correct order. Correct taps
fill an ordered strip; a first wrong tap gives a hint (articulate-before-hint); a second wrong tap
reveals the ordered sequence + explanation. First-try-only scoring, anti-shame, DIR/FEDC reflection
on results.

It teaches the **coordinated sequence** of the innate → adaptive response (barrier → fast innate
helpers → antigen presentation → antibodies → memory) and the **primary-vs-secondary (memory)
response** (why the second meeting is milder) — a load-bearing primitive that the iOS app currently
teaches only via MC (kits 3 & 5) + the arcade MacrophagePacman + the BCellAntibodyMatch shape-game.
**No iOS surface has the learner ORDER the steps.**

## Why it's worth backporting

Ordering-the-response is exactly how the strongest cross-platform exemplars teach it — HHMI
BioInteractive's *Immune System* timeline + *Smallpox and the Immune System* card activity, and the
research card game *Micro-Immune Battles* (statistically significant knowledge gains from building
correct pathogen→response cascades). It's an active-recall complement to the passive MC kit, and it
reinforces the app's calm, no-warfare framing ("your quiet helpers respond in a careful order; most
encounters end peacefully").

## Web reference implementation

- `spark-anvil-site/src/lib/play/microbelab/response.ts` — the mechanic (6 authored sequences, 3-5 steps each).
- `spark-anvil-site/src/pages/play/microbelab/response.astro` — the route.
- Data shape: `{ scenario, hint, explanation, steps: [{ order, text }] }`; tap in ascending `order`.

The 6 sequences (order-tolerant to author more):
1. Scrape on the knee — barrier broken → macrophages tidy up → warm/swollen → heals.
2. First meeting a new germ — innate first → helper shows the shape → B-cells make antibodies → memory saves the shape.
3. Same germ again — memory recognizes → fast antibodies → cleared before you feel sick.
4. Cold virus — mucus traps most → innate responds → antibodies made → memory saved.
5. Why a cut gets red/warm — "come help" signals → more blood (warm/red) → cleanup cells → heals.
6. Friendly gut microbes arrive — immune cells check → recognized as safe → allowed to settle (tolerance).

## Proposed iOS surface

A new lightweight ordering mode (drag-to-reorder or tap-in-order) reusing the existing cast/register
and the kit 3/5 content. Natural fit alongside the existing immune scenes. Could reuse
`MasteryMomentDetector` for a "sequence master" moment. **Keep the calm register and DO NOT add
vaccine content** (kit 9 stays reviewer-gated per ADR-016) — the web impl deliberately omits it.

## What closes this handoff

A `HANDOFF_FROM_APP_IMMUNE_RESPONSE_SEQUENCE_SHIPPED.md` (or equivalent) confirming the iOS mode
landed — OR a documented waiver (e.g., "covered by an existing surface"). Until then the web
ledger row (`spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md` Axis-3) stays 🟡 (open,
compliant).

## Cross-references
- `spark-anvil-hub/Docs/web/microbelab/RESEARCH.md` § Backport candidates (candidate #1, ✅ FILE)
- `spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md` § Web-pioneered (Axis-3)
- `.claude/rules/spark-anvil-website.md` § R-CLONE-BIDIRECTIONAL-BACKPORT / § R-WEB-CLONE-BACKPORT-MINING
