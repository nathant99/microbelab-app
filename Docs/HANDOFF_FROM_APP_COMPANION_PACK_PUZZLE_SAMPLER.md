# Handoff to Labsmith — Companion pack `puzzle_sampler.pdf` (MicrobeLab)

Direction: **app → labsmith**. Request labsmith ship the missing 4th PDF (`puzzle_sampler.pdf`) in the MicrobeLab companion-pack bundle so the in-app "For Parents & Educators" surface (and the eventual `/apps/microbelab` site download surface) carries the full 4-PDF set documented in `Docs/HANDOFF_FROM_LABSMITH_COMPANION_PACK.md`.

> **Twenty-sixth-pass rule-restatement summary** (canonical-invariant tier per the eleven-pass invariant; verbatim user-direct 2026-06-16): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing Xcode-managed files is ok."* See `@CLAUDE.md` § Xcode-managed file safety. Nothing in this handoff implies a managed-file edit on either side.

## State at this handoff's commit

- **MicrobeLab repo HEAD**: `feature/companion-pack-puzzle-sampler-outbound-2026-06-16` branched from `main` (post-PR #174 merge).
- **Companion pack bundle**: `Resources/CompanionPack/` ships **3 of the 4 expected PDFs** + manifest:
  - ✅ `cast_poster.pdf` (present)
  - ✅ `coloring.pdf` (present)
  - ✅ `parent_letter.pdf` (present)
  - ❌ `puzzle_sampler.pdf` (**MISSING — this handoff's ask**)
  - ✅ `companion_pack.json` (current manifest lists 3 PDFs + count 3; will need to flip to 4 once `puzzle_sampler.pdf` lands)
- **Inbound handoff doc**: `Docs/HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` already documents the canonical 4-PDF schema (per the labsmith script's intended output); the schema example in that doc lists all 4 PDFs. The current shipped bundle is the partial state — labsmith's `scripts/build_companion_pack.py` (queue #332) presumably emitted the other 3 but skipped or failed on the puzzle sampler.
- **Audit reference**: `Docs/AUDIT_HANDOFF_INBOUND_2026-06-16.md` (PR #134, twenty-first-pass round) classified the companion pack as **PARTIAL (3/4 PDFs)** + filed a P5 sequencing note for an outbound labsmith-side `puzzle_sampler.pdf` delivery. This handoff is the P5 outbound corresponding action.

## Requested change

Labsmith re-runs (or re-extends) the `scripts/build_companion_pack.py` (queue #332) per-app generator for MicrobeLab so the missing `puzzle_sampler.pdf` lands at `Resources/CompanionPack/puzzle_sampler.pdf` in the same bundle layout the other 3 PDFs already use. Companion update to `companion_pack.json` to flip `pdfs` to the canonical 4-entry list + `count: 4`.

## Concrete spec for the missing PDF

Per `Docs/HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` § "What's in `Resources/CompanionPack/`":

| Field | Value |
|---|---|
| Filename | `puzzle_sampler.pdf` |
| Bundle path | `Resources/CompanionPack/puzzle_sampler.pdf` |
| Format | PDF (US Letter / 8.5 × 11 in) |
| Content | 6 representative kit-01 questions + answer key |
| Footer / header framing | 501(c)(3) non-profit (pending) per inbound handoff; no third-party tracking; mission-first |
| Size budget | < ~200 KB per § "Each PDF is letter-size ... ~5-200 KB" |

Source content: `Packages/Libraries/Sources/Services/Resources/kit_01_microbiology_basics.json` is the canonical 5-question kit-01. Per § 5.4 spec the puzzle sampler is **6 representative kit-01 questions + answer key** — labsmith's existing per-app generator pulls the right kit; this handoff just asks for the gen to re-run for MicrobeLab.

## Content + register constraints (load-bearing)

- **Trauma-informed register**: every kit-01 question + answer-key entry MUST honor the COVID-trauma-aware + beneficial-microbes-foregrounded posture per `Docs/TECHNICAL_DESIGN.md` § "Trauma-Informed Design Posture (COVID-era sensitivity)". No warfare lexicon (`fight` / `attack` / `war` / `battle` / `weapon` / `kill` / `destroy` / `enemy`); no shame framings (`dirty` / `gross` / `nasty` / `ashamed`); no COVID-specific references. The kit-01 source already conforms — the gen pipeline should preserve the source verbatim.
- **Distractor authoring discipline** (codified per the nineteenth-pass round PR #123 codifier): the trauma-informed register applies to the FULL `choices` array, not just the correct answer + body. The shipped `kit_06_oral_microbiome.json` + `kit_07_skin_microbiome.json` distractor rewrites surfaced 2 wrong-answer rewrites (`kill` / `ashamed` tokens). Kit-01 was authored pre-codifier — please spot-check the distractors against the same parameterized stoplist before bundling.
- **Anti-credentialism gate** per CQ `CONTENT_STYLE_GUIDE.md` § 4.5 (relevant to kit-01 question framing): no hero-myth + mortality + warfare framing on any "scientist who discovered X" pedagogy beat.

## Why this is asked now (the labsmith-side action context)

- The audit at `Docs/AUDIT_HANDOFF_INBOUND_2026-06-16.md` (freshness-horizon 2026-06-30, currently fresh) flagged the partial state.
- The 4th PDF is **not blocking** in-app gameplay — Phase 1+2 surfaces ship without it. But the "For Parents & Educators" surface (planned per § "How to surface in-app") shows a 4-card grid in `HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` — without the puzzle sampler that surface either has a missing card OR ships as a 3-card grid that diverges from the canonical 4-card spec.
- The `/apps/microbelab` site download surface on spark-anvil-site (per § "How to keep in sync with the website") also expects 4 downloadable PDFs.

## Options considered (verdict matrix)

| Option | Verdict |
|---|---|
| **A. Labsmith re-runs `scripts/build_companion_pack.py --app microbelab --apply`** (preferred path) | ✅ Reuses existing canonical pipeline; preserves per-app override pattern; emits both PDF + manifest update; manifest auto-rolls 3 → 4 entries / count 3 → 4. |
| **B. App session generates the PDF locally via a Swift PDFKit / `UIGraphicsPDFRenderer` path** | ❌ Diverges from the labsmith-side pipeline; would double-bundle (the source-of-truth manifest stays at labsmith; the app shouldn't author the bundle). Per `.claude/rules/portfolio.md` § "Asset generation ownership", labsmith owns ALL portfolio asset generation. |
| **C. Drop the puzzle sampler from the manifest + ship the 3-card grid as canonical** | ❌ Would require a follow-on `HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` edit to update the schema; the inbound handoff already documents the 4-PDF canonical schema as labsmith's intent. Aligning the schema downward is the wrong direction; aligning the bundle upward is the right one. |
| **D. Defer indefinitely + drop the audit row** | ❌ Audit flagged this; the audit's `freshness-horizon` resets the question every 14 days. Filing the outbound handoff replaces deferral with explicit ask, which is the productive workflow. |

## Sequencing to unblock

1. **Labsmith session**: pull `microbelab-app` (`git pull --ff-only`); run `scripts/build_companion_pack.py --app microbelab --apply` (or equivalent) so `puzzle_sampler.pdf` + the manifest update land in the same bundle path the existing 3 PDFs use.
2. **Labsmith session**: stage `Resources/CompanionPack/puzzle_sampler.pdf` + the updated `companion_pack.json` (now 4 entries / count 4); commit + cross-repo PR per the canonical handoff workflow per `.claude/rules/portfolio.md` § "Cross-Repo Handoff Protocol".
3. **Labsmith session**: optional companion `HANDOFF_FROM_LABSMITH_COMPANION_PACK_PUZZLE_SAMPLER_SHIPPED.md` confirming what landed (per the portfolio handoff convention — bidirectional exchange leaves the durable audit trail).
4. **MicrobeLab session** (future round): re-audit at `Docs/AUDIT_HANDOFF_INBOUND_<date>.md` flips the companion pack row from **PARTIAL (3/4 PDFs)** → **SHIPPED**. Optional: ship the in-app `CompanionPackView` (per § "How to surface in-app") once the bundle is complete; surface is currently deferred to a Delight-tier round.

## What this handoff does NOT cover

- The in-app `CompanionPackView` Swift implementation per § "How to surface in-app" — that's a separate MicrobeLab-side deferred task; the appropriate parent / educator surface placement (Settings tab vs. dedicated About surface) is an app-side design decision.
- The `/apps/microbelab` site download surface on spark-anvil-site — that's a separate labsmith-side task once the bundle is complete + the site's `sync_content_to_site.sh` next runs.
- Any other Phase 2+ companion-pack expansion (e.g., per-Phase-3 disease-story explainer print sheets, per-Phase-4 global tour print maps) — those would file as separate per-pack outbound requests if/when the kit content stabilizes.

## Cross-references

- `Docs/HANDOFF_FROM_LABSMITH_COMPANION_PACK.md` — inbound handoff documenting the canonical 4-PDF schema
- `Docs/AUDIT_HANDOFF_INBOUND_2026-06-16.md` — audit row classifying the companion pack as PARTIAL (3/4 PDFs) + P5 sequencing
- `Resources/CompanionPack/companion_pack.json` — current manifest (lists 3 PDFs + count 3; needs flip to 4 once labsmith ships)
- `.claude/rules/portfolio.md` § "Asset generation ownership" + § "Cross-Repo Handoff Protocol" + § "Asset request sub-pattern" (this handoff conforms to the asset-request sub-pattern's required-content schema)
- `.claude/rules/spark-anvil-website.md` § "Asset reuse policy" (downstream consumer of the same bundle)
