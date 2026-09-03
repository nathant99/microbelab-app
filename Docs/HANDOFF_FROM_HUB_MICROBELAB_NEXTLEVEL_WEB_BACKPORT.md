---
kind: HANDOFF
status: OPEN
from: hub
date: 2026-09-03
program: 74
freshness-horizon: 90
---

# HANDOFF FROM HUB — microbelab next-level web-pioneered features (iOS backport spec)

**Program #74** (Fable-Reviewed Next-Level Elevation, `R-FABLE-NEXTLEVEL-REVIEW` / ADR-188).
The `/play/microbelab` web clone shipped 1 **NET-NEW, web-pioneered** learning feature(s) this cycle
(Fable-review next-level recommendations). Per `R-CLONE-BIDIRECTIONAL-BACKPORT` +
`R-WEB-CLONE-MAY-PRECEDE-IOS`, this is the forward-looking **iOS backport spec**.

> Hub authored this doc (cross-repo `Docs/*.md` is an allowed hub write). **Hub never writes Swift** —
> spec only; the app's own CC session implements it in the Xcode project.

## Shipped features (web-pioneered)

### 1. Microbiome POE
A pure simulateShift reusing the shipped iOS-parity sim (tick/beneficialShare) — predict beneficial-share rise/fall/steady before the real ticks reveal the trajectory (before/after bars); 6 engine-derived cases, each Vitest-guarded unambiguous.

Web ship: site #3096 (MERGED → staging). Pure deterministic engine + engine-verified Vitest +
dual-scheme × desktop+mobile screenshot-DoD; on-device / no-PII; boundary-placed; honest-yield.

## iOS backport guidance
- Each web engine is a pure, deterministic TypeScript module (no DOM). The iOS parity is a Swift
  value-type engine with the same oracle + a SwiftUI surface, engine-verified (Swift Testing invariants
  mirroring the web Vitest), answer-withholding where it scaffolds.
- Reuse the app's DN cast/mentor for framing (`R-DN-PARITY`); boundary-placed. Dark-safe + WCAG 2.2 AA +
  ≥44px; no engagement-farm economy (`R-SITE-FEEDBACK`).

## Tracking
- Hub PARITY ledger: `spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md`.
- Forward-port completion registry: `spark-anvil-hub/Docs/REGISTRY_WEB_CLONE_FORWARD_PORT_FEATURES.txt`.
