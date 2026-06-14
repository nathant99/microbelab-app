# Audit — GutSlot expansion closure (oral / skin / soil)

**Date**: 2026-06-13 (seventeenth-pass auto-cycle round)
**Round**: Seventeenth-pass round PRs #113 → ##
**Status**: PASS — work shipped; FEATURE_PLAN checkbox promoted

## Why this audit

FEATURE_PLAN.md § Phase 2 carries the open checkbox:

> - [ ] Expand `GutSlot` to include oral / skin / soil ecologies

The underlying type expansion was shipped in an earlier round but the FEATURE_PLAN checkbox was never promoted. This audit walks the code path, cites the reference impl, and promotes the checkbox to `[x]` via the same audit-driven closure pattern used in PRs #95 / #96 / #98 / #102.

## Reference impl

`Packages/Libraries/Sources/Models/MicrobeCharacter.swift:23-31`:

```swift
/// Ecology zone the microbe prefers. Used by the microbiome simulator to
/// decide which microbes thrive in which gut-slot under given feeding modes.
public nonisolated enum GutSlot: String, Codable, Sendable, CaseIterable {
    case oralCavity
    case stomach
    case smallIntestine
    case largeIntestine
    case colon
    case skin
    case soil
}
```

The enum ships **all 7 cases** — `.oralCavity` was always present (Phase 1 baseline); `.skin` + `.soil` extend it for the Phase 2 multi-environment surfaces. The expansion landed as part of a prior round (PR pre-#100 era — the precise PR is not material; the type surface is what's authoritative).

## Per-case validity for Phase 2 surfaces

| `GutSlot` case | Phase 1 status | Phase 2 surface that will consume it | Authoring constraint |
|---|---|---|---|
| `.oralCavity` | Phase 1 baseline | "Implement oral-cavity microbiome scene (plaque ecology)" (FEATURE_PLAN.md § Phase 2) | Strep + Net + similar oral-cohort microbes in `Sources/Services/Resources/MicrobeCatalog/*.json` |
| `.stomach` | Phase 1 baseline | n/a (no per-stomach scene planned — gastric acid limits sustainable populations) | Acid-tolerant subset only when needed |
| `.smallIntestine` | Phase 1 baseline | Composite "small + large + colon" scene (current `MicrobiomeView`) | Already wired |
| `.largeIntestine` | Phase 1 baseline | Composite scene | Already wired |
| `.colon` | Phase 1 baseline | Composite scene (canonical) | Default `MicrobiomeState.empty(in: .colon)` |
| `.skin` | **Phase 2 extension** | "Implement skin-microbiome scene (eczema-safe framing per `.claude/rules/trauma-informed-content.md`)" | Eczema-safe framing required — no skin-condition imagery; cohort centers on Staph epidermidis + similar commensal skin flora |
| `.soil` | **Phase 2 extension** | "Implement soil-microbiome scene (decomposer ecology bridge to bioforge/ecosphere)" | Decomposer cohort (Bacillus subtilis + Streptomyces + nitrogen-fixers); ecology bridge to BioForge / EcoSphere cluster apps via `MicrobeKnowledgeGraph` cross-app discovery |

## Codable + raw-value stability

The enum is `Codable` via its `String` raw value. Catalog JSON files in `Sources/Services/Resources/MicrobeCatalog/*.json` reference slot tokens by raw value, so adding new cases is forward-compatible (existing catalogs with only the 5 Phase 1 cases decode cleanly; new catalogs adding `.skin` / `.soil` rows are also valid). Per `MicrobeCharacter.init(from:)` the decoder routes through `try container.decode(GutSlot.self, forKey: .preferredEnvironment)` so any unknown raw value would surface as a `DecodingError.dataCorrupted` at catalog load — fail-fast posture for typos.

## Tests covering the surface

The existing `MicrobiomeStateTests` + `MicrobeKnowledgeGraphTests` cover Codable round-trip + per-slot grouping. The PR #114 (seventeenth-pass round Option 2) MicrobeKnowledgeGraph cross-microbe ecology edges relies on `.skin` and `.soil` for cross-slot cohort traversal — the `relatedByRole_crossSlot` test explicitly uses `.skin` and `.relatedByKingdom_crossSlot` validates `.oralCavity` cross-slot behavior. Per-case raw-value stability is implicitly pinned via the JSON catalog decode path; an explicit raw-value stability test would harden the contract further but is not blocking for closure (the catalog JSON files in production already encode the raw values).

## What this audit does NOT close

The FEATURE_PLAN checkboxes that depend on the dedicated **scenes** for each ecology remain open:

- `[ ] Implement oral-cavity microbiome scene (plaque ecology)`
- `[ ] Implement skin-microbiome scene (eczema-safe framing ...)`
- `[ ] Implement soil-microbiome scene (decomposer ecology bridge ...)`

Those are scene-authoring tasks (SpriteKit + new `*Scene` files + bundled microbe rosters per slot) that ship in subsequent rounds. The **type expansion** is the foundational dependency they all share — that's what this audit closes.

## Per-PR closure pattern

This PR mirrors the audit-driven closure pattern from prior rounds:

- PR #95 — Micro-delight coverage formal closure
- PR #96 — A11y Dynamic Type + Color-contrast formal closure
- PR #98 — First 60 Seconds + Aha moment closure
- PR #102 — Juice layer partial-closure audit
- PR #94 closure of "DN-S chapter content"

The pattern: audit doc walks the code path + per-axis state + closure criteria; FEATURE_PLAN.md checkbox promoted `[ ]` → `[x]` with reference to the audit doc.

## Closure

FEATURE_PLAN.md § Phase 2 → "Expand `GutSlot` to include oral / skin / soil ecologies" → `[ ]` → `[x]` per this audit. Zero source code touched.

## Cross-references

- `@Packages/Libraries/Sources/Models/MicrobeCharacter.swift` § `GutSlot`
- `@Packages/Libraries/Tests/ServicesTests/MicrobeKnowledgeGraphTests.swift` (uses `.skin` + `.soil` + `.oralCavity`)
- `@.claude/rules/trauma-informed-content.md` § eczema-safe framing constraint for `.skin` scene
- `@Docs/FEATURE_PLAN.md` § Phase 2
- `@Docs/TECHNICAL_DESIGN.md` § Domain Model
