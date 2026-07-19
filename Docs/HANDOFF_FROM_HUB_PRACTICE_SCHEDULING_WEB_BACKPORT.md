# Handoff from Hub — Practice-scheduling (Mixed practice) web backport

Direction: **hub → app**. The `/play/microbelab` web clone shipped an ADR-048 **axis-7 Mixed-practice `/review`** surface. The iOS app already has the ENGINE (`ForgeMasteryEngine` + `SpacedRepetitionEngine`) but no surfaced learner-facing "Mixed practice / Review" mode — so this is a web-pioneered → iOS backport (R-CLONE-BIDIRECTIONAL-BACKPORT).

## What the web shipped
- `src/lib/play/microbelab/review.ts` — interleaves questions round-robin across the kits DUE for review (spaced retrieval over the on-device progress store), falling back to the acquired-kit pool once ≥2 kits are attempted; edge-of-competence ordered; a review advances each kit's spacing schedule. Calm-rails: **orders + resurfaces, never gates.**
- A `/play/microbelab/review` route + a landing "Mixed practice" card at a session boundary.
- On-device only (localStorage, no identifier), COPPA-aligned. Site PR #1013.

## Proposed iOS surface
- A "Mixed practice" / "Review" entry (menu or session boundary) that uses `ForgeMasteryEngine.NextProblemPicker` + `SpacedRepetitionEngine` (FSRS) to assemble an **interleaved** review set across acquired topics, **edge-of-competence** ordered.
- Calm-rails: no due-count dread, no streak-guilt, boundary-placed (R-NARRATIVE-BETWEEN-NOT-DURING), never gates content.
- The engine already exists on iOS; this backport is the surfaced VIEW + the interleave/review-session assembly.

## Status
🟡 **open** — hub filed this handoff; the app's own Claude Code session implements the iOS surface and files a `HANDOFF_FROM_APP_*_SHIPPED` return. Parity ledger: `spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md` § Axis 7.

## What this does NOT cover
- The web clone (shipped) or the shared `_shared/practiceScheduling.ts` engine (web-side, done). Any non-review expansion axis.
