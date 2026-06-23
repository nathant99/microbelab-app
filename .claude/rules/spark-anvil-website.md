# Spark & Anvil Company Website

The studio brand (Spark & Anvil) ships a company website at `spark-and-anvil.com` (planned domain) that introduces parents/educators/press/kids to the 131-app portfolio.

## Scope of hub for the website (UPDATED 2026-05-25)

**Hub owns the website end-to-end.** The app-repo scope rule (hub ≠ implementation) does NOT apply to the website because the site is markup/content (Astro + Tailwind + TypeScript data files), not portfolio Swift app code. Per user 2026-05-25: "web site is not really code so it's okay" + "you own the website."

Hub owns:

- **Brand assets**: palette, typography, logo (generated 2026-05-20 to `Branding/Logo/PNG/`), brand guidelines
- **Research + plans**: `Docs/RESEARCH_SPARK_ANVIL_WEBSITE.md`, `Docs/PLAN_SPARK_ANVIL_WEBSITE.md`, `Docs/PLAN_SPARK_ANVIL_LOGO.md`, `Docs/DECISION_FIGMA_FOR_SPARK_ANVIL_WEBSITE.md`
- **Content sourcing**: per-app taglines + descriptions + curriculum mapping sourced from each app's `CLAUDE.md` and `Docs/`
- **Asset reuse choreography**: which existing per-app assets surface on the website
- **Site code itself**: Astro pages, Tailwind config, TypeScript data files, build scripts at `/Volumes/Data/Projects/GitHub/spark-anvil-site/`
- **PRs against `spark-anvil-site`**: open, ship, merge from hub session

Hub does NOT own:

- Site deployment / DNS / hosting accounts (Cloudflare Pages — user-managed)
- Production domain configuration (Cloudflare account-level)

### Workflow

When making site changes from hub:

1. `cd ../spark-anvil-site && git pull --ff-only` (always pull first)
2. Branch: `feature/<topic>` in the site repo
3. Edit `src/pages/*.astro`, `src/data/*.ts`, `tailwind.config.js`, etc. directly
4. `npm install` if needed; `npm run build` to verify
5. `gh pr create` + `gh pr merge --merge --delete-branch` from the site repo
6. Pair with a hub doc update if the change reflects a research/plan delta

### Handoff doc convention (legacy + audit trail)

`spark-anvil-site/Docs/HANDOFF_FROM_HUB_*.md` (canonical 2026-06-11+) or `HANDOFF_FROM_LABSMITH_*.md` (legacy) docs are NO LONGER required for site work (hub implements directly). They MAY still be authored when:
- A major IA change deserves a durable audit-trail artifact (e.g., the Reflect-pillar 4th-modality rollout)
- The change spans multiple sessions and the next session needs a self-contained brief

If the change is small (palette tweak, copy edit, new page from existing pattern), skip the handoff doc — just ship the PR.

## Asset reuse policy

The website MUST reuse existing portfolio assets. Generation budget for website-specific assets is constrained to:

- ✅ **Brand logo** — completed 2026-05-20 (Gemini Nano Banana Pro). One-time gen.
- ❌ **Topic illustrations** — DEFERRED per user policy 2026-05-20. Site v1 uses mascots + backdrops for visual variety; topic-level illustration not needed for site-level pages.
- ❌ **Per-app screenshots** — apps not built yet. Defer to v2 after first apps ship.
- ❌ **Demo videos** — same as screenshots.
- 🟡 **Press kit downloadable bundle** — assemble from existing assets (logos + per-app icons + mascots). Composition only; no new generation.

Any other website-specific asset request requires:
1. Confirming the asset cannot be sourced from an existing app's bundle
2. User approval before generation (cost discipline per `portfolio.md` § Asset generation ownership)
3. Per-pipeline ceiling adherence (mascot ~$0.27, accessory pack ~$0.36, etc.)

## Brand asset locations

| Asset | Path | Format | Generated |
|---|---|---|---|
| Brand palette (tokens) | `Branding/Colors/spark-anvil-palette.md` | Markdown table | Pre-existing |
| Brand README (asset directory + quick reference) | `Branding/README.md` | Markdown | Pre-existing |
| Logomark (color) | `Branding/Logo/PNG/spark_anvil_logomark_v1.png` | PNG 1024×1024 | 2026-05-20 Nano Banana Pro |
| Full lockup (with wordmark) | `Branding/Logo/PNG/spark_anvil_lockup_v2.png` | PNG 1024×1024 | 2026-05-20 Nano Banana Pro |
| Logomark variants (sizes, dark/light) | `Branding/Logo/PNG/*.png` | (To export) | TODO post-v1 launch |
| Brand guidelines doc | `Branding/Guidelines/brand-usage.md` | (To author) | TODO Phase 1.3 of PLAN |

Logomark and lockup are both visually-audited and aesthetically aligned with the chunky-cartoon portfolio style (Toca-Boca / Animal-Crossing register: bold `#2A1F1A` outlines, Forge Orange + Spark Gold + Anvil Charcoal palette).

## Tech stack (locked in)

- **Static site generator**: Astro 4.x (per `DECISION_FIGMA_FOR_SPARK_ANVIL_WEBSITE.md` + `PLAN_SPARK_ANVIL_WEBSITE.md`)
- **Styling**: Tailwind CSS with token-mapped brand palette (`tailwind.config.js` defines `forge`, `anvil`, `spark`, `warm`, `slate`)
- **Hosting**: Cloudflare Pages (preferred) or Vercel
- **Analytics**: Plausible (privacy-first, no cookies, COPPA-safe)
- **Forms**: Formspree or Netlify Forms (press contact, parent feedback)
- **No third-party SDKs** — preserves the "no tracking, no kid data leaves the device" trust signal

## Design workflow (locked in)

- **No Figma for v1** — code-first; Astro + Tailwind authored via Claude Code / Cursor; iterate in browser DevTools; Cloudflare Pages preview deploys for review (per `DECISION_FIGMA_FOR_SPARK_ANVIL_WEBSITE.md`)
- Brand palette doc + logo PNGs + per-app CLAUDE.md = the spec. No parallel design artifacts.

Revisit if: designer joins team, marketing landing page needs novel composition, press-kit / Apple Design Award submission requires pixel-precision.

## Content sourcing pattern

Per-app website pages auto-populate from hub state:

```
spark-anvil-site/scripts/build-apps-data.mjs reads:
  ├── spark-anvil-hub/Docs/<AppName>/README.md          → tagline + summary
  ├── <app>-app/CLAUDE.md                         → tech stack + safety statement
  ├── <app>-app/.../Resources/Illustrations/      → visuals
  ├── spark-anvil-hub/Docs/REGISTRY_APP_HERO_COLORS.md   → per-app theming
  └── spark-anvil-hub/Docs/RESEARCH_CURRICULUM_STANDARDS_MAPPING.md → curriculum chips
```

For 131 apps, the script generates 131 templated pages. Phase 3 of PLAN: manually populate 10 flagship apps first; Phase 4: bulk-generate the rest with skeleton + "Coming soon" tags for apps with insufficient assets.

## COPPA + trust signal requirements

Per 2026 FTC COPPA amendments effective April 22 2026:

- Opt-in default for ad data sharing (we don't share — one-line copy)
- Separate verifiable parental consent flows (per-app, surfaced via screenshots)
- Defined data retention periods (no indefinite storage)
- Written security program (linked policy)

Trust signals visible above-the-fold on home + `/for-parents`:
- "No ads · No in-app purchases · COPPA compliant · iOS 26 native"
- "All data on-device — nothing leaves the device"
- "No third-party SDKs / no tracking"

Per `RESEARCH_SPARK_ANVIL_WEBSITE.md`, third-party certifications (iKeepSafe COPPA, Common Sense Privacy Seal, KidSAFE) are aspirational v2+ goals — pursue once portfolio has shipping apps + revenue justifies audit fees.

## Liquid Glass policy (ADR-014, Round 149 #580, 2026-05-29)

The website adopts a **HYBRID** Liquid-Glass-inspired accent layer: chunky-cartoon brand register remains the primary visual identity; 3-5 narrowly-scoped accent surfaces use mature Glassmorphism 2.0 (semi-opaque overlay + `backdrop-filter: blur(8-16px)` + thin border). **No SVG-displacement refraction** — Chromium-only, broken on mobile Safari, GPU-expensive on school iPads. See `Docs/ADR-014_HYBRID_LIQUID_GLASS_WEBSITE.md` + `Docs/RESEARCH_LIQUID_GLASS_WEBSITE_2026-05-29.md` for the full decision + 29-source research.

**Authorized glass surfaces** (all live in `src/styles/global.css` + `src/components/Nav.astro`):

| Utility | Where | Pattern |
|---|---|---|
| Sticky top nav | `Nav.astro` | `bg-warm/85 backdrop-blur-md border-b border-anvil/10` (+ dark variant) |
| `.btn-glass` | Secondary CTAs over imagery | `bg-white/25 backdrop-blur-md border border-white/40` |
| `.card-glass` | Hero / feature overlay cards | `bg-warm/70 backdrop-blur-lg border border-warm/40 rounded-2xl` |
| `.chip-glass` | Tags / badges over hero color bands | `bg-white/30 backdrop-blur-sm border border-white/40` |

**Hard constraints**:

1. ≤ 3 concurrent active glass panels per page (2026 production guidance — `backdrop-filter` forces GPU screen-buffer copy + blur + paste; > ~50 instances crash mobile browsers)
2. Body text NEVER on glass — text sits on solid surfaces inside the glass card
3. WCAG AA contrast verified at light + dark mode + multiple scroll positions
4. `@media (prefers-reduced-transparency: reduce)` MUST collapse all glass to solid brand-palette colors
5. `@media (prefers-reduced-motion: reduce)` MUST drop any glass-morph transitions
6. Pages OFF-LIMITS to glass (always solid): `donate.astro`, `privacy.astro`, `terms.astro`, `annual-report.astro`, `for-parents.astro` body, `for-educators.astro` body, `press.astro`, `mission.astro`, `about.astro`, `board.astro`. Trust-sell + legal + long-form copy stays solid
7. Primary CTAs (`btn-primary`) stay solid — trust + max contrast

**Reversibility is HIGH** — removing the layer is a 5-line revert of `global.css` + `Nav.astro`. If field metrics surface AA failures or perf issues on school devices, revert without ceremony.

**When updating the policy**: edit `Docs/ADR-014_HYBRID_LIQUID_GLASS_WEBSITE.md` + this section + open a hub PR. The site itself is the implementation source of truth for the actual utility class definitions.

## DN-S chapter-book pages (Wave 1 SHIPPED 2026-06-02; spark-anvil-site PRs #104 + #105)

The site now ships **663 illustrated chapter-book pages** at `/cast/<app>/<char>` + `/stories` aggregate index. Per `Docs/PLAN_DN_S_WEBSITE_WAVE_1_2026-06-02.md` + `Docs/ADR-022_DN_S_WEBSITE_WAVE_1_OPEN_QUESTIONS.md`. Editing rules below:

### Content source-of-truth

- **DO NOT edit `spark-anvil-site/src/content/chapters/<app>/<char>.md` directly.** They are sync targets, not source. The source-of-truth is `<app>-app/Docs/dn-s/chapters/<char>.md`.
- To update chapter text: edit the app-repo chapter MD, then re-run `spark-anvil-hub/scripts/sync_content_to_site.sh --app <slug> --apply`.
- The sync also distributes chapter illustrations (to `public/chapters/`) + audio M4A + VTT (to `public/audio/`).

### Astro Content Layer schema

- Schema lives at `src/content/config.ts` (Astro 4.16 content-collections API).
- **Permissive schema required**: chapter front-matter conventions vary across 663 entries; twin/cohort chapters use `primitive (X):` instead of flat `primitive:`. Use `.passthrough()` + make all non-essential fields optional. Only `character` + `app` are hard requirements.
- Astro 4.x uses `gray-matter` + `js-yaml` for front-matter parsing; **unquoted YAML values with embedded colons / markdown emphasis (`*...*`) / em-dashes fail at parse time.** `spark-anvil-hub/scripts/normalize_chapter_frontmatter.py` quotes fields known to contain these (`primitive` / `role` / `register` / `audience` / `chapter-round` / `character`) in the SYNC TARGET copies only — source repos stay untouched.

### CRITICAL: Normalizer auto-runs in site `prebuild` — do NOT remove (2026-06-04 regression-pattern lift)

**The normalizer is wired into `spark-anvil-site/package.json` `prebuild`** so every build (local OR Cloudflare Pages) self-heals from YAML drift. **Never remove the normalizer call from the prebuild chain** — doing so re-opens the regression class below.

```jsonc
"prebuild": "bash scripts/lint-ios-caps.sh && python3 scripts/normalize-chapter-frontmatter.py && node scripts/build-cast-manifest.mjs && ..."
```

**Regression pattern** — codified after two consecutive Cloudflare-deploy failures (PR #160 fix → sync re-broke it → PR #162 final fix, 2026-06-04 evening):

1. Hub sync writes fresh chapter MDs from `<app>-app/Docs/dn-s/chapters/` → `spark-anvil-site/src/content/chapters/`.
2. Source chapters use unquoted YAML (`primitive: CAESAR SHIFT — *the simplest cipher: shift every letter by N.*` — embedded `:` after "cipher" trips js-yaml).
3. Local Astro dev may not surface the bug if cached; Cloudflare's fresh-clone build always re-parses → fails with `incomplete explicit mapping pair; a key node is missed`.
4. Point-in-time normalizer runs fix the symptom but the NEXT sync re-introduces the drift.

**The auto-run prebuild is the only durable fix.** Running the normalizer once-per-sync is racy against any sync landing between that run and the build.

**Two copies of the normalizer exist + are intentional**:
- `spark-anvil-hub/scripts/normalize_chapter_frontmatter.py` — source of truth; canonical implementation
- `spark-anvil-site/scripts/normalize-chapter-frontmatter.py` — in-repo mirror (path-relative; works on Cloudflare's `/opt/buildhome/repo`) so the build agent doesn't clone hub

When the normalizer's quoting rules change, **update BOTH copies in the same change-set**. The site copy resolves `CHAPTERS_ROOT` from `__file__` so it works in any environment; otherwise it's byte-for-byte identical to hub's.

**When in doubt — run the normalizer**: it's idempotent. Re-running on already-normalized YAML produces zero diff.

**Companion sync rule for hub-side workflow**: when authoring a new chapter or rewriting an existing one, do NOT pre-quote the source MD's YAML — leave the unquoted convention. The prebuild normalizer is responsible for quoting the sync-target copy. This preserves authoring ergonomics on the hub side while keeping the site build resilient.

### Reusable components (3 shipped; reused across #1 / #3 / #4 per ADR-022)

- `<ChapterIllustration app="..." char="..." variant="opener|spot|thumbnail" />` — consumes `public/chapters/<app>/chapter_<char>_<variant>.webp`
- `<SiblingCastStrip app="..." currentChar="..." />` — persistent-sticky on desktop / header-pinned on mobile / `prefers-reduced-motion` fallback; reads `apps.generated.ts dnCast.members`
- `<AudioDramaPlayer app="..." drama="..." characterName="..." traumaGated={...} traumaAxis={...} />` — HTML5 `<audio>` + WebVTT chapters track + inline interactive transcript with active-line highlight; vanilla JS only (no third-party SDKs; COPPA-safe); WCAG AA keyboard support

### Typography

- **Chapter prose: Lora serif** (locally hosted at `public/fonts/Lora-Variable.ttf`) per ADR-022 Q6.
- Sans-serif (site default) for chrome / infobox / nav / strips / cards.
- `chapter-body` class applies the serif + generous line-height + max-width 36rem reading column.

### Trauma-safety per-page surface (per ADR-021)

- 24 chapters across the portfolio are trauma-gated (PASS-CLEARED audits in `Docs/AUDIT_TRAUMA_GATED_AUDIO_*_2026-06-02.md`). Their pages auto-detect via `register` front-matter field (regex match on `trauma|SAMHSA|anti-shame|anti-colonial|cultural-respect|food-justice|sensory-regulation|body-image|crisis|overwhelm|panic`).
- Trauma-gated pages render: content-warning between opener illustration + body; trauma-tag in infobox; trauma-rating chip in audio player; crisis-resources footer (988 / Childhelp / Crisis Text Line).
- DO NOT remove these guardrails when editing the chapter-book template; ADR-021 enforces them as load-bearing for the trauma-axis carve-out.

### Audio sibling files (per ADR-022 Q2)

- App repos bundle `.caf` (iOS-native, app-bundled only).
- Site `public/audio/<app>/` requires `.m4a` (web-distribution; universal browser support) + `.vtt` (WebVTT chapters + transcript).
- `spark-anvil-hub/scripts/gen_dn_s_audio_drama.py --apply` now emits all three; legacy CAFs need backfill via `afconvert -f m4af -d aac -b 64000 -c 1 <input>.caf <output>.m4a` + VTT placeholder (better: re-gen).

### Build performance (post Wave 1b)

- 828 total site pages built in ~28s on Astro 4.16 (663 dynamic chapter routes + /stories + existing 24 site pages).
- Static output mode preserved per existing `astro.config.mjs` lock-in; no SSR adapter added.
- Build-time content-collection load handles 663 entries cleanly with the permissive schema.

## Cast portrait slug convention (R-CAST-PORTRAIT-SLUG; 2026-06-05)

**The portrait file at `spark-anvil-site/public/cast/<app>/<char>.webp` MUST match the chapter MD filename slug at `src/content/chapters/<app>/<char>.md`.** Both are the same `<char>` token. This is load-bearing because chapter pages at `/cast/<app>/<char>` render `<img src="/cast/<app>/<char>.webp">` with no fallback; Astro static-build doesn't verify `<img src>` targets, so a slug mismatch ships as a silently-broken portrait link with no build-time error.

### Why the rule exists (2026-06-05 user report)

User-reported "a lot of cast characters with broken links for portrait images on the website" surfaced 48 of 754 chapter pages (6.4%) rendering broken `<img>` against missing files. Root cause: slug-mismatch between chapter MD filenames and portrait WebP filenames in 5 distinct patterns:

| Pattern | Where | Example chapter slug → portrait slug |
|---|---|---|
| **A. Underscore vs dash** | adventurehub / generalstale / stonesong | `archivist_atlas.md` ↔ `archivist-atlas.webp` |
| **B. `the-` prefix on portraits** | cardforge / dealtales | `bluffer.md` ↔ `the-bluffer.webp` |
| **C. Role-suffix descriptor on portraits** | chanceforge / discretequest / mythforge / ratiorealm | `display.md` ↔ `display-the-picture-maker.webp` |
| **D. App-repo `cast_<char>_<pose>` convention** | quillspell | `ember.md` ↔ `cast_ember_demonstrating.webp` |
| **E. Accent stripping** | cipherforge | `vigenere.md` ↔ `Vigenère` name in registry → `vigen-re.webp` from naive slugify |

Phase A + B remediation shipped via spark-anvil-site PR #175 (33 renames + 2 syncs; coverage 93.6% → 98.3%); Phase C gen + slug-fix shipped 2026-06-05 (registry additions + 13 portraits genned + Phase B re-run; coverage to 100%).

### The canonical slug derivation

```python
def canonical_slug(name: str) -> str:
    # NFKD-normalize to strip diacritics (Vigenère → Vigenere)
    s = unicodedata.normalize("NFKD", name)
    s = s.encode("ascii", "ignore").decode("ascii")
    s = s.lower()
    # Ampersand → "-and-"
    s = re.sub(r"&", "-and-", s)
    # Non-alphanumeric → "-"
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s or "char"
```

This matches `slugChar` in `spark-anvil-site/src/pages/cast/[app]/[char].astro` AND the canonical implementation in `spark-anvil-hub/scripts/gen_cast_portraits.py` (fixed 2026-06-05).

### Source of truth for `<char>`

The chapter MD filename (Tier-1 lives at `<app>-app/Docs/dn-s/chapters/<char>.md`; Tier-2 at `spark-anvil-hub/Resources/DN-S-Tier-Upper/chapters/<app>/<char>.md`) is the canonical slug. Portrait filenames must match. The character's display name in `dnCast.members[]` MAY differ from the slug (e.g., "The Bluffer" → `bluffer.md`); when the registry-derived slug doesn't match the chapter slug, the canonical slug is the chapter filename, and the post-gen fix script (`fix_cast_portrait_slugs.py`) renames the portrait to the chapter slug.

### CI check (prebuild)

`spark-anvil-site/package.json` `prebuild` runs `python3 ../spark-anvil-hub/scripts/audit_cast_portrait_coverage.py --json` and FAILS the build if any portrait is missing. This makes the regression class build-time-visible — a chapter MD without a matching portrait file blocks deploy. Local dev catches the regression before commit; Cloudflare Pages catches it before deploy.

Per `.claude/rules/spark-anvil-website.md` § "CRITICAL: Normalizer auto-runs in site prebuild" the prebuild chain is the canonical self-healing seam. The cast portrait audit joins it.

### When this rule applies

- **Authoring a new chapter MD**: name the file with the kebab-case slug of the character name; verify a matching `public/cast/<app>/<char>.webp` exists OR queue gen via `scripts/gen_cast_portraits.py --app <slug> --yes`.
- **Authoring a new app**: the per-app gen workflow already aligns; the `dnCast.members[]` `name` field flows through canonical slug derivation.
- **Renaming a chapter MD**: rename the portrait file in the same PR. The prebuild CI check will block the merge if not.
- **Adding a mentor or ensemble char** that doesn't fit `dnCast.members[]`: add it anyway (Captain Castle + The Pawn Cohort precedent — gambittales gained 2 entries 2026-06-05 to close the chapter-page broken-link surface).

### Tools

- `spark-anvil-hub/scripts/audit_cast_portrait_coverage.py` — enumerate (app, char) pairs; classify missing portraits by remediation path (B1 site rename / B2 app sync / C gen); `--json` machine-readable.
- `spark-anvil-hub/scripts/fix_cast_portrait_slugs.py` — Phase B one-shot remediation (B1 site `git mv` + B2 app-repo `cp`). Dry-run by default.
- `spark-anvil-hub/scripts/gen_cast_portraits.py` — Phase C gen pipeline; uses canonical slug derivation; idempotent (skip-if-exists).

### What this rule does NOT enforce (yet)

- **Per-cluster trauma-axis review on portrait gen** — Phase C portrait gen still gates on ADR-012 founder-ADR-approved AI gen for trauma-adjacent clusters; the CI check only catches "missing file", not "trauma-axis-unsafe content".
- **Mentor / ensemble chars in dnCast.members[]**: this rule documents the precedent but doesn't enforce that every chapter MD has a matching `dnCast.members[]` entry. File a per-app handoff to add mentors/ensembles to the registry when a gap surfaces.
- **App-repo Resources/Cast slug**: the rule applies to spark-anvil-site portraits only. App-bundle conventions per `.claude/rules/forgekit.md` § "Cast asset filename convention" (`cast_<character_slug>_<pose>.webp`) remain orthogonal.

### Cross-references

- `Docs/AUDIT_CAST_PORTRAIT_BROKEN_LINKS_2026-06-05.md` — Phase A + B remediation audit
- `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § cast portrait broken-image
- `.claude/rules/forgekit.md` § "Cast asset filename convention" (app-bundle orthogonal convention)
- `.claude/rules/portfolio.md` § "Asset Consumer Audit" (precedent for "registered ≠ wired" / "synced ≠ rendered")

## Multi-beat chapter snapshot convention (R-MULTIBEAT-SNAPSHOT; 2026-06-10)

**Multi-beat chapter pages read prose from a SNAPSHOT at `public/chapters/<app>/chapter_<char>.md` — NOT from `src/content/chapters/<app>/<char>.md`.** When the source-of-truth chapter MD is rewritten (e.g., Option C register cleanup, content corrections, register rewrites), **the snapshot must be regenerated alongside the per-beat sidecar + illustrations + audio**, because the sidecar's `prose-range: { from-line, to-line }` indexes against the snapshot's line numbers AND the per-beat audio narration speaks the snapshot's prose.

### Why two prose paths exist

The chapter template at `src/pages/cast/[app]/[char].astro` checks the `multibeat-chapters.json` manifest (built by prebuild from `public/chapters/<app>/chapter_<char>.beats.json` presence):

- **Multi-beat present** → `<InterleavedChapterAudioPlayer mode="multi-beat" />` reads beat-prose from the snapshot via the manifest's `beatProse[]` (sliced from `public/chapters/<app>/chapter_<char>.md` by `build-multibeat-chapter-manifest.mjs`)
- **Multi-beat absent** → `<InterleavedChapterAudioPlayer mode="single-chapter" />` OR plain `<Content />` renders from `src/content/chapters/<app>/<char>.md` (Astro content collection)

The snapshot was introduced to keep beat-prose-range slicing stable + decoupled from content-collection schema. But the dual paths mean a chapter can have STALE multi-beat prose while the content-collection version is current.

### Required workflow when rewriting a chapter that's already in multi-beat mode

For any chapter where `public/chapters/<app>/chapter_<char>_chapter.m4a` exists (i.e., Path B has shipped for it):

1. **Rewrite source** via `scripts/rewrite_chapter_register.py --app <slug> --chapter <char> --tier 1 [--model gemini-2.5-pro] [--force]` — updates `<app>-app/Docs/dn-s/chapters/<char>.md`
2. **Commit + push source app-repo PR** (cross-repo write per hub-as-research-hub Docs/ exception)
3. **Delete stale multi-beat assets**:
   ```bash
   rm Resources/AutoSegmentedChapters/<app>/<char>.beats.json
   rm <pilot-or-wave-out-dir>/<char>_receipt.json <pilot-or-wave-out-dir>/<char>_beat_*.png <pilot-or-wave-out-dir>/<char>_chapter.*
   rm /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>.beats.json
   rm /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>.md
   rm /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>_beat_*.png
   rm /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>_chapter.*
   ```
4. **Re-run the surgical regen** (target the single chapter; do NOT use `path_b_wave_runner.sh` which iterates ALL chapters in an app):
   ```bash
   /usr/bin/python3 scripts/auto_segment_chapter.py --chapter <md-path> --out Resources/AutoSegmentedChapters/<app> --app <app>
   /usr/bin/python3 scripts/pilot_interleaved_ensemble_chapter.py --manifest Resources/AutoSegmentedChapters/<app>/<char>.beats.json --out-dir <out-dir>
   # then cp the chapter_<char>.* family into spark-anvil-site/public/chapters/<app>/
   ```
5. **Sync content collection** via `scripts/sync_content_to_site.sh --apply --app <slug>` (also updates `src/content/chapters/<app>/<char>.md` + opener/spot illustrations + audio drama if any)
6. **Commit + push spark-anvil-site** (one commit per app-batch is fine)

Per-chapter regen cost: **~$0.32** (Pro opener $0.134 + 4 × Flash $0.045 + Gemini TTS ~$0.10).

### Why `sync_content_to_site.sh` does NOT also update the snapshot

The snapshot at `public/chapters/<app>/chapter_<char>.md` is paired with the sidecar `chapter_<char>.beats.json` whose `prose-range` indexes lines into the snapshot. If `sync_content_to_site.sh` copied the new source MD over the snapshot without re-segmenting the sidecar AND re-genning per-beat assets, the chapter would render with:

- Wrong text per beat (sidecar's `from-line/to-line` point to wrong lines in the new MD)
- Audio narration speaks OLD prose (per-beat audio was generated from the OLD snapshot)
- Per-beat illustrations depict OLD scenes

So `sync_content_to_site.sh` deliberately leaves the snapshot alone. Snapshot ownership lives with `path_b_wave_runner.sh` (or the surgical regen recipe above).

### Methodology-section stop in the segmenter (2026-06-10 fix)

**The auto-segmenter STOPS collecting paragraphs at the first methodology H2** (`## Voice register` / `## Arc across kits` / `## Relationships` / `## Cultural-sensitivity gate` / `## Cultural-context note` / `## Author's note` / `## Sample lines` / `## A note for grown-ups` / `## What's the big idea here?` etc.). Beats only cover the narrative body; methodology stays in the snapshot file for reference but is **never sliced into a beat**.

**Why this is in the segmenter, not the snapshot**:

Multi-beat pages render exclusively from beat prose. The chapter template does NOT fall back to `<Content />` on the content-collection MD when multi-beat is active. So the spark-anvil-site-side `strip-chapter-methodology-sections.py` (which processes `src/content/chapters/<app>/<char>.md`) has zero effect on multi-beat pages — its strip-output is never rendered. Methodology leaked into beats whenever the segmenter included those lines in its even-paragraph-count split.

The fix lives in `spark-anvil-hub/scripts/auto_segment_chapter.py` `_METHODOLOGY_H2_PATTERNS` set + `_is_methodology_h2()` hard-stop in `collect_paragraphs()`. The strip-script's pattern set + the segmenter's pattern set MUST stay in sync — adding a new methodology H2 to one requires adding it to the other.

**Companion implication for per-beat audio**: the pilot script's per-beat TTS sources prose from sidecar's `prose-range` slice of the snapshot. With the segmenter stopping at methodology, beats only contain narrative, so per-beat audio only narrates narrative. No "Voice register" / "Arc across kits" speech leaks into the audio drama.

**Discovered 2026-06-10** when user-flagged the live cosmosforge/gleam page rendering "## Voice register", "## Arc across kits", "## Relationships" sections under the beats UI. Root cause: pre-fix segmenter included methodology lines in beat 4 (closer); multi-beat renderer sliced beat 4 from snapshot lines 51-100 which contained all the methodology content.

**Future enhancement idea**: extend `sync_content_to_site.sh` to detect multi-beat chapters + automatically run the surgical regen. Out of scope for the current convention; for now, the human/agent operator handles regen explicitly when rewriting multi-beat chapters.

### When the rule applies

- Author rewriting a chapter MD for register / content / accuracy: check `ls /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>_chapter.m4a` — if present, the chapter is multi-beat; follow the workflow above
- Portfolio-wide Option C rewrite + Path B regen rollout: bake the regen step into the per-app wave driver (see Work Queue § Option C portfolio rewrite for the operational pattern)
- Content corrections that don't change line structure (typo fix, single-word swap): `sync_content_to_site.sh` is sufficient — sidecar line-ranges still point to valid lines; audio is only off by one word

### Verification

After regen, verify:

1. **Local snapshot matches source**: `diff <(head -30 <app>-app/Docs/dn-s/chapters/<char>.md) <(head -30 /Volumes/Data/Projects/GitHub/spark-anvil-site/public/chapters/<app>/chapter_<char>.md)` should show only YAML front-matter quoting differences (from the prebuild normalizer)
2. **Receipt shows uniform cost**: `Resources/PilotsAndExperiments/<wave>/<app>/<char>_receipt.json` `total_cost_usd` should be ~$0.32
3. **Live URL**: hard-refresh `https://spark-and-anvil.com/cast/<app>/<char>` after Cloudflare redeploys; check that opener prose + first-beat prose match the rewritten source

### Cross-references

- `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "Option C portfolio rewrite — multi-beat snapshot staleness gotcha + remediation" — operational rollout plan
- `spark-anvil-hub/scripts/sync_content_to_site.sh` — content-collection sync (does NOT touch multi-beat snapshot)
- `spark-anvil-hub/scripts/path_b_wave_runner.sh` — multi-beat batch driver (idempotent — skip if `site_m4a` exists; delete to force regen)
- `spark-anvil-hub/scripts/auto_segment_chapter.py` — segmenter (creates sidecar with prose-range against current MD line numbers)
- `spark-anvil-hub/scripts/pilot_interleaved_ensemble_chapter.py` — per-beat illustration + audio gen
- `spark-anvil-site/scripts/build-multibeat-chapter-manifest.mjs` — prebuild manifest builder (slices snapshot prose by sidecar line-ranges)
- `spark-anvil-site/src/pages/cast/[app]/[char].astro` — chapter template (decides single-chapter vs multi-beat based on manifest)

## Path B illustration prompt parity (R-PATH-B-PROMPT-PARITY; 2026-06-11)

**Per-beat illustration prompts in `scripts/pilot_interleaved_ensemble_chapter.py` MUST include (a) chapter prose for the beat's `prose-range`, (b) a character-identity block from the chapter's YAML front-matter + opening passage, AND (c) a per-app `base_style` resolved via `STYLE_REGISTRY`.** The auto-segmenter sidecar's `scene` field is structural metadata, not artistic direction; never use it as the sole content cue.

### Why the rule exists

`Docs/AUDIT_PATH_B_WRONG_CHARACTER_2026-06-11.md` surfaced a systemic regression where Path B beat illustrations rendered the wrong character. Root cause: the pre-2026-06-11 `build_illustration_prompt()`:

1. Never received chapter prose (it was extracted only for TTS)
2. Used `auto_segment_chapter.py`'s generic `"scene": "<Char> beat N of M"` placeholder verbatim
3. Inherited a hard-coded `GAMBITTALES_STYLE` (warm amber + cream + tan fairy-tale palette) as the unconditional default

Under those constraints, Pro hallucinated a generic warm-amber Animal-Crossing bear in a fairy-tale village for ANY chapter where the character was non-conventional (paper fence, mathematical-concept embodiment, abstract entity). Apps with conventional kid/animal casts survived by coincidence; non-conventional casts shipped visibly wrong art.

### The 3 load-bearing prompt blocks

The 2026-06-11 v2 prompt adds three blocks before the existing `ANTI_TEXT` clause:

| Block | Source | Why it's load-bearing |
|---|---|---|
| **CHARACTER IDENTITY (LOAD-BEARING)** | YAML front-matter (`character:` + `role:` + `primitive:`) + first beat's `prose-range` + species-defaulting clause | Locks the species + role; the species-defaulting clause ("if the chapter does NOT describe a specific non-human form, render as a HUMAN child or adult appropriate to the role + scene — NOT a generic anthropomorphic animal") prevents the badger-in-medieval-village failure mode for chapters whose prose lacks visual character description |
| **STORY EXCERPT (this beat's prose)** | `beat_prose(beat, md_lines)` trimmed to ~220 words | Gives Pro the actual scene + action context for THIS beat; without it the model invents a fairy-tale-village backdrop regardless of chapter content |
| **STYLE** | `STYLE_REGISTRY.get(app, _DEFAULT_STYLE)` | Per-app palette + register override. `_DEFAULT_STYLE` deliberately drops the amber/cream/tan palette and tells the model to derive palette from the CHARACTER IDENTITY + STORY EXCERPT blocks |

### `STYLE_REGISTRY` ownership

The `STYLE_REGISTRY` dict in `pilot_interleaved_ensemble_chapter.py` is the canonical per-app style override surface. Default behavior (when the app slug is not in the registry) is `_DEFAULT_STYLE` which prescribes ONLY the chunky-cartoon outline + cell-shading register, NOT a specific palette.

Add a per-app entry only when:
- The app has a distinctive visual register that prose alone won't trigger (e.g., `gambittales` fairy-tale fantasy palette; an `aiforge` paper-craft palette if the prose-injection alone proves insufficient)
- 1+ chapters of the app ship visibly off-register after the v2 prompt baseline

Per-app overrides should pass a Phase B-equivalent proof regen before being committed.

### Companion: when chapter prose lacks species cues

Some chapters describe characters by behavior + setting but NOT species (proofquest/direct-proof-dora was the canonical 2026-06-11 incident — Dora described as "step-by-step talkative kid who walked the bridge to school," no species cue). The species-defaulting clause inside `extract_character_identity()` defaults to "human child or adult" for these chapters. If a chapter SHOULD render a non-human form (paper / fence / robot / animal / object / abstract entity), make sure the chapter's opening prose explicitly states that form. Don't rely on the cast portrait as the only species signal — Pro doesn't see the portrait during gen unless we wire it as a ref-image (see Phase A+ future enhancement).

### Don'ts

- Don't remove the `_DEFAULT_STYLE` "Derive the specific palette + setting from the CHARACTER IDENTITY + STORY EXCERPT blocks below" instruction — it's the seam that keeps Pro on-prose
- Don't reintroduce the hard-coded `GAMBITTALES_STYLE` as default for non-Gambittales apps; that was the original regression
- Don't strip the species-defaulting clause from `extract_character_identity()` — it's the only signal preventing Pro from rendering "mathematician archetype" as an anthropomorphic badger
- Don't bypass `build_illustration_prompt()` and call the gen API directly with a custom prompt unless you also pass the 3 load-bearing blocks — duplicate prompt construction is the regression class

### When the rule applies

- Any `path_b_wave_runner.sh` invocation — auto-applies (the runner calls `pilot_interleaved_ensemble_chapter.py`)
- Any one-off chapter regen via `pilot_interleaved_ensemble_chapter.py --manifest <sidecar>` — auto-applies
- Any new Path B / Path C ensemble chapter gen script (e.g., future `gen_app_illustrations.py --interleaved` portfolio rollout) — MUST adopt the same 3-block pattern. The blocks are reusable via the same helper functions (`extract_character_identity()` + `_trim_excerpt_for_prompt()` + `STYLE_REGISTRY` lookup)
- **Cast portrait gen (`scripts/gen_cast_portraits.py`)** — applies the 3-block pattern with POSE / FRAMING substituted for STORY EXCERPT (portraits are neutral 3/4 head-and-shoulders, not beat-scene depictions). Imports `STYLE_REGISTRY` + `_DEFAULT_STYLE` + `_parse_frontmatter` + `_trim_excerpt_for_prompt` directly from `pilot_interleaved_ensemble_chapter` so the per-app palette + species-defaulting + front-matter parsing helpers are shared, not duplicated. Codified after `Docs/AUDIT_CAST_PORTRAIT_VS_BEAT_0_COHERENCE_2026-06-11.md` surfaced 100% portrait-vs-beat-0 drift across 58 multi-beat chapters. See § "Portrait companion (cast portrait gen)" below
- **Book cover gen (`scripts/gen_book_covers.py`)** — SHIPPED 2026-06-11 (commit 3057c177; "Sister-of-Phase-A book cover refactor + 286-cover portfolio regen wave"). Applies the 3-block pattern with COMPOSITION substituted for STORY EXCERPT (covers are tier-specific layout: top 60% character + bottom 40% title typography + Spark & Anvil footer; per-tier register from `TIER_REGISTERS`). Imports `STYLE_REGISTRY` + `_DEFAULT_STYLE` + `_parse_frontmatter` + `_trim_excerpt_for_prompt` directly from `pilot_interleaved_ensemble_chapter` so the cover, the cast portrait, and beat 0 all inherit the same per-app visual register. See `Docs/AUDIT_PDF_BOOK_COVER_COHERENCE_2026-06-11.md` for the parent audit + `scripts/gen_book_covers.py::build_prompt()` for the canonical 3-block impl.

### Portrait companion (cast portrait gen)

The `scripts/gen_cast_portraits.py` prompt pipeline (refactored 2026-06-11) adopts the R-PATH-B-PROMPT-PARITY 3-block pattern with portrait-specific framing:

| Block | Source for portraits | Differs from beat-illustration use |
|---|---|---|
| **CHARACTER IDENTITY (LOAD-BEARING)** | YAML front-matter (`character:` + `role:` + `primitive:`) + first 30 body lines of the chapter MD (trimmed to ~220 words) + species-defaulting clause | Beat pipeline takes prose from beat-0's `prose-range` slice; portrait pipeline takes from the chapter MD's opening passage directly (no sidecar dependency since portrait gen runs before any sidecar exists) |
| **POSE / FRAMING** | Neutral 3/4 head-and-shoulders portrait; character fills ~65% of square 1:1 frame; transparent background; signature visual trait visible IF described in CHARACTER IDENTITY | Beat pipeline uses `build_composition_direction(beat)` for per-beat cinematic shots; portrait pipeline uses a fixed neutral pose (`_PORTRAIT_POSE_FRAMING` constant) since portraits are character-identity sidebars, not scene depictions |
| **STYLE** | `STYLE_REGISTRY.get(app_slug, _DEFAULT_STYLE)` — same registry as the beat pipeline | Identical; shared lookup so per-app palette overrides cascade to BOTH portrait + beat 0 simultaneously |

**Chapter MD lookup**: `_load_chapter_md_for_char(app_slug, char_slug)` resolves `<app>-app/Docs/dn-s/chapters/<char_slug>.md`. When the chapter MD doesn't exist (cast member present in `apps.generated.ts` but no DN-S chapter authored yet), the prompt falls back to a legacy name+role construction with STYLE_REGISTRY still applied — so per-app palette consistency holds across both paths.

**Regen wave discipline**: `gen_cast_portraits.py --regen` overwrites existing portraits. The `convert_to_webp()` helper accepts `overwrite=True` when `--regen` is set; without this guard, the old WebP would persist even after a successful Flash gen + PNG write. Reference fix: 2026-06-11 portrait remediation wave (PR following this codification).

**Don'ts (portrait-specific)**:

- Don't hand-roll a parallel `extract_character_identity()` in the portrait script — import from the pilot module so the species-defaulting clause and front-matter parsing stay synchronized
- Don't expand `_PORTRAIT_POSE_FRAMING` to include scene depiction — portraits are character-identity sidebars; scene context belongs to beat 0
- Don't skip `--regen` when remediating drift; the default `--regen=False` behavior is intentional for first-emit waves but blocks remediation
- Don't add a per-character chapter MD path override unless the character genuinely lives in a non-canonical location — the Tier-1 source-of-truth `<app>-app/Docs/dn-s/chapters/<char_slug>.md` is the rule

### Cross-references

- `Docs/AUDIT_PATH_B_WRONG_CHARACTER_2026-06-11.md` — root-cause audit + Phase A patch + Phase B proof regen receipts
- `Docs/AUDIT_CAST_PORTRAIT_VS_BEAT_0_COHERENCE_2026-06-11.md` — portrait companion audit (100% drift across 58 chapters); triggered portrait-companion codification
- `Docs/AUDIT_PDF_BOOK_COVER_COHERENCE_2026-06-11.md` — sister audit for the book cover gen pipeline; refactor pending
- `labsmith/scripts/pilot_interleaved_ensemble_chapter.py:446` — `build_illustration_prompt()` canonical impl (beat illustrations)
- `labsmith/scripts/gen_cast_portraits.py` — `build_prompt()` portrait impl (imports STYLE_REGISTRY + helpers from pilot module)
- `labsmith/scripts/auto_segment_chapter.py:278` — generic `scene` placeholder upstream (treated as structural metadata, not artistic direction)
- `Docs/SPEC_INTERLEAVED_ENSEMBLE_CHAPTER.md` — ensemble sidecar manifest schema (parent spec)

### Pre-distribute text-leak gate (R-PATH-B-TEXT-LEAK-GATE; 2026-06-13)

**`path_b_wave_runner.sh` MUST run `audit_image_text_leaks.py` against each newly-generated beat PNG BEFORE distributing to spark-anvil-site. If any beat verdicts LEAK, the wave runner fails-fast for that chapter — no distribution to public/chapters/ — and the operator regenerates with a tightened prompt.**

#### Why the gate exists

Queue #971 Phase 2 portfolio sweep (`Docs/AUDIT_IMAGE_TEXT_LEAKS_PORTFOLIO_SWEEP_2026-06-13.md`) classified 397 site beat PNGs and surfaced **62 LEAKs (15.6%)**. Without a pre-distribute gate, future Path B waves can ship new leaks. The top-3 leakers (BeatForge 11 + GambitTales 10 + BridgeForge 9 = 48% of total) demonstrate the regression class.

Pre-distribute is the right seam (NOT post-distribute or runtime detection) because:

1. Audit cost is sub-cent per image (~$0.001 Gemini 2.5 Flash); cumulative gate cost per chapter is ~$0.005 (5 beats × $0.001)
2. Re-running the gen for a failed chapter is cheaper than syncing a leak + then remediating it (avoids cascade through `sync_content_to_site.sh` → site prebuild → Cloudflare deploy)
3. The operator sees the leak verdict + detected text strings inline in the wave runner output

#### Gate mechanics (`scripts/path_b_wave_runner.sh` step 2.5)

```bash
if [ "${SKIP_TEXT_LEAK_GATE:-0}" != "1" ]; then
    for beat in beat_00..beat_04; do
        audit_image_text_leaks.py --image $beat --json-out tmp
        verdict=$(jq -r '.results[0].verdict' tmp)
        if [ "$verdict" = "LEAK" ]; then
            echo "✗ $app/$slug — text-leak gate FAIL on beat $i"
            mark-failed; break-chapter
        fi
    done
fi
```

The gate enumerates each `${slug}_beat_0N.png` produced by `pilot_interleaved_ensemble_chapter.py`, calls the audit script per-beat, and parses the per-image verdict. LEAK verdict → fail the chapter; the wave runner records `<app>/<slug>:text-leak-gate` in the FAILED_LIST and moves to the next chapter. Operator inspects the leak diagnostics + reruns the wave.

#### Override

Set `SKIP_TEXT_LEAK_GATE=1` to bypass. Use sparingly:

- Trauma-axis carve-outs where transient text leaks are operationally acceptable
- Diagnostic runs where the operator wants to ship + inspect the leak in-context
- Math-app override is already handled inside `audit_image_text_leaks.py` (MULTI_DIGIT is OK for math apps; see `MATH_APPS` set) — don't reach for `SKIP_TEXT_LEAK_GATE` for math apps unless the gate misfires

Default = gate enabled. Anytime a math-app beat surfaces a false-positive LEAK because of legitimate single-digit / multi-digit numerals not caught by the math-app override, FIRST extend `MATH_APPS` in the audit script; only use the env-var bypass when extension isn't appropriate.

#### Companion: per-app remediation queue (R1)

The 62 LEAKs surfaced in the portfolio sweep are NOT auto-remediated by adding this gate. R1 remediation per `Docs/AUDIT_IMAGE_TEXT_LEAKS_PORTFOLIO_SWEEP_2026-06-13.md` § Recommendations:

1. Per-app regen for top-3 leakers (BeatForge / GambitTales / BridgeForge = 30 of 62)
2. Per-app spot-check + selective regen for tail-15 apps (32 of 62)
3. Verify post-regen via `audit_image_text_leaks.py --app <slug>` returning 0 LEAKs

The gate prevents NEW leaks; R1 remediates EXISTING leaks. Both are required for full closure of Queue #971.

#### When this rule applies

- Every `path_b_wave_runner.sh` invocation — auto-applies via step 2.5 (chapter beats)
- Every `gen_cast_portraits.py` invocation — auto-applies via `gate_single_image()` between PNG render and WebP conversion (R-PATH-B-TEXT-LEAK-GATE companion, 2026-06-15)
- Every `gen_book_covers.py` invocation — auto-applies via `gate_single_image()` between PNG render and WebP conversion (R-PATH-B-TEXT-LEAK-GATE companion, 2026-06-15)
- Any one-off chapter regen via direct `pilot_interleaved_ensemble_chapter.py` invocation — operator MUST manually run `audit_image_text_leaks.py --image <beat>.png` before copying to spark-anvil-site (the gate is currently wired into the wave runner only; one-off path is operator-discipline)
- Future Path C ensemble gen (when portfolio-scale `gen_app_illustrations.py --interleaved` ships) — MUST adopt the same pre-distribute gate pattern

#### Reusable gate function

The per-image gate is canonicalized in `audit_image_text_leaks.py:gate_single_image()`. New gen scripts MUST import + call this function rather than re-implement the audit + verdict logic. Signature:

```python
from audit_image_text_leaks import gate_single_image

passed, audit = gate_single_image(
    image_path,                # Path to the rendered PNG
    app_slug="myapp",          # Optional explicit override; falls back to path detection
    client=client,             # Optional google.genai.Client; lazy-built if None
    skip_env="SKIP_TEXT_LEAK_GATE",  # Env override knob
)
if not passed:
    # quarantine, log, continue (don't crash; assets are independent)
```

The function respects `SKIP_TEXT_LEAK_GATE=1` for trauma-axis carve-outs + diagnostic runs. `passed=False` only on `verdict == "LEAK"`; CLEAN / BORDERLINE / NON_ENGLISH_FLAG / GATE_SKIPPED all pass.

`app_slug_from_path()` recognizes three layouts: `chapters/<app>/`, `cast/<app>/`, and `CustomArt/<app>/`. The math-app override (multi-digit numerals OK for `MATH_APPS`) carries through.

#### Gate quarantine

Gate-blocked assets are moved to `labsmith/tmp/text-leak-gate-failed/<asset-kind>/<app-slug>/` (NOT distributed). Inspect, manually decide whether to regen or accept; do NOT `mv` back to the source path without re-auditing.

#### INTENTIONAL_CURRICULUM_SIGNAGE — 6th-category allow-list (2026-06-16)

For chapters where curricular signage (compass cardinals N/E/S/W on a compass scene; angle measures 60° / 120° on a polygon; variable letters x / y in equation visuals; cable-tension RATIOS in bridge engineering scenes; etc.) is intentional and load-bearing per the chapter's curricular surface, declare the allow-list IN the chapter MD's YAML front-matter:

```yaml
---
character: Apprentice Sides
role: ...
gate-allow-text:
  - N
  - E
  - S
  - W
  - 60
  - 120
gate-allow-text-pattern: '^[0-9]{1,3}°?$'   # OPTIONAL regex for ranges (e.g., any angle measure)
---
```

When the audit detects text that would normally LEAK (ENGLISH_WORDS or non-math-app MULTI_DIGIT), it consults the chapter MD's front-matter. If ALL detected text matches the `gate-allow-text` list OR the `gate-allow-text-pattern` regex, the verdict downgrades from `LEAK` → `LEAK_ALLOWLISTED` (PASSING). The audit emits the allow-list match in the per-image JSON for audit-trail clarity.

**Resolution mechanism**:

| Image path pattern | Resolved chapter MD |
|---|---|
| `spark-anvil-site/public/chapters/<app>/chapter_<char>_beat_NN.png` | `<app>-app/Docs/dn-s/chapters/<char>.md` (Tier-1) |
| `spark-anvil-site/public/chapters/<app>/chapter_<char>-advanced_beat_NN.png` | `labsmith/Resources/DN-S-Tier-Upper/chapters/<app>/<char>.md` (Tier-2) |

**When to use the allow-list**:

- Chapter prose explicitly references curricular signage (compass / angle measures / equation variables / ratios / scale labels / etc.)
- Math-app chapters where multi-digit signage IS the curriculum (already handled by `MATH_APPS` set; allow-list is BELT-AND-SUSPENDERS for non-math-app math content like cable-tension RATIOS)
- Trauma-gated chapters where SAMHSA register intentionally surfaces small affect labels in the scene
- Op β R1 accept-residual chapters: bridgeforge/cable (cable-tension RATIOS), fractionforge/equi (equivalent-fraction labels), numbersense/splitter-sasha (digit-split visuals), quillspell/ember (spelling letters)
- Geometryforge curricular bypasses surfaced 2026-06-16: apprentice-sides + compass-wraith (N/E/S/W cardinals), captain-construction (workshop labels), madame-polygon (angle measures + variables), axia-and-theora (background village signage)

**Don'ts**:

- Don't use the allow-list to bypass real defect text (typos / hallucinated brand names / wrong-character signage). The allow-list is for INTENTIONAL curricular content, not accidental leaks
- Don't make the allow-list too permissive (e.g., `gate-allow-text-pattern: '.*'` accepts everything; defeats the gate's purpose)
- Don't omit `gate-allow-text` when SKIP_TEXT_LEAK_GATE=1 was used as the bypass — codify the allow-list in the MD so the next audit doesn't need the env override

**Companion**: when SKIP_TEXT_LEAK_GATE=1 is used to bypass the gate, the OPERATOR SHOULD also add a `gate-allow-text:` entry to the chapter MD so future re-audits don't re-flag the same intentional signage.

#### What this rule does NOT cover

- **`copy_cast_portraits_to_site.sh`** — the gen-side gate inside `gen_cast_portraits.py` is sufficient. Optionally extend the sync script with `--gate-on-sync=1` for belt-and-suspenders. Default off
- **Mascot / topic / modecard / backdrop gen** — separate scripts (`gen_app_illustrations.py` variants); the gate doesn't auto-apply there yet. Pending Item 1 (Queue #971 Phase 5+ portfolio sweep)
- **Achievement badge gen (`gen_app_badges.py`)** — rarity-tier frame treatment merges text via design; flagged but not gate-wired. Future: extend gate to recognize intentional title typography vs accidental signage leaks

#### Audit script resilience flags (Item 4 — codified V9; expanded V10 2026-06-23)

`scripts/audit_image_text_leaks.py` exposes three resilience knobs added after the V8 stall incident (Gemini API hung 14+ min mid-call; killed via SIGINT lost 1197/1692 images of progress with no JSON written):

| Flag | Default | Behavior |
|---|---|---|
| `--call-timeout <seconds>` | 60 | Wraps each `client.models.generate_content()` call in `concurrent.futures.ThreadPoolExecutor.submit().result(timeout=...)`. On timeout, raises + falls into the retry path |
| `--max-retries <N>` | 1 | Total attempts = `max_retries + 1`. On transient failure (timeout / 503 / 429), retries with backoff |
| `--checkpoint-every <N>` | 50 | After every N completed classifications, writes partial JSON to `--json-out` so a stall doesn't lose all progress |
| `--resume <partial.json>` | off | Skips images whose absolute path already appears in `partial.results`. Combine with `--checkpoint-every` for stall recovery |

`SIGINT` (`Ctrl-C`) writes a final checkpoint before `sys.exit(130)` — partial JSON is always preserved.

**When this rule applies** — every audit invocation (portfolio-wide sweep, per-app sweep, spot-check, single-image, gate-mode). The flags are optional but the defaults are tuned for portfolio-scale (1500+ images in ~30 min on Gemini 2.5 Flash classification, with stall-resilient checkpointing).

**Canonical full-portfolio invocation**:

```bash
/usr/bin/python3 scripts/audit_image_text_leaks.py \
    --site-sweep \
    --json-out Docs/AUDIT_IMAGE_TEXT_LEAKS_FULL_<date>.json \
    --call-timeout 60 \
    --checkpoint-every 50
# If a stall recurs mid-sweep:
/usr/bin/python3 scripts/audit_image_text_leaks.py \
    --site-sweep \
    --json-out Docs/AUDIT_IMAGE_TEXT_LEAKS_FULL_<date>.json \
    --resume Docs/AUDIT_IMAGE_TEXT_LEAKS_FULL_<date>.json
```

#### Wave Q CI guardrail (Item 5 — codified V9 + Round 488 audit-script discipline + V10 rule-sync 2026-06-23)

`scripts/check_no_hardcoded_paths.sh` + `.github/workflows/check-no-hardcoded-paths.yml` enforce the § P1 standing directive that scripts MUST use relative paths (not `/Volumes/Data/Projects/GitHub/...` hardcodes). Runs on every PR open + push to main that touches `scripts/**.{py,sh}`.

**Why**: per V8 stall incident root-cause + Round 488 `Docs/AUDIT_DOCS_ONLY_APP_RANKING_2026-06-02.md` inventory bug — scripts with hardcoded absolute paths to the (now-moved) `/Volumes/Data/Projects/GitHub/` root silently fail when the portfolio root moves. The CI guardrail prevents regression at PR time.

**Self-skip mechanism**: the check script reconstructs the forbidden pattern from variables (so its own grep doesn't self-flag) AND filters out its own filename (`check_no_hardcoded_paths.sh`) from the match set. Verified: PASS on clean tree; FAIL with exit 1 on planted regression script containing the hardcoded path.

**Companion rule**: `.claude/rules/portfolio.md` § "P1 — Scripts must use relative paths" is the authoritative spec; this CI guardrail is the automated enforcement. Distributed to portfolio app repos via `scripts/copy_rules_to_repos.sh --apply` (V10 round-close).

#### Cross-references

- `Docs/AUDIT_IMAGE_TEXT_LEAKS_PORTFOLIO_SWEEP_2026-06-13.md` — parent audit (62 LEAKs surfaced)
- `Docs/AUDIT_TEXT_IN_IMAGE_LEAK_SCAN_2026-06-13.md` — original audit policy + category framework
- `Docs/AUDIT_PORTRAIT_BOOK_COVER_TEXT_LEAK_GATE_WIRE_UP_2026-06-15.md` — companion gate adoption audit (this expansion)
- `Docs/RESEARCH_OPTION_V_P3_CARRY_ITEMS_SCOPING_2026-06-15.md` § Item 2 — parent scoping for this expansion
- `labsmith/scripts/audit_image_text_leaks.py` — audit tool + `gate_single_image()` reusable function
- `labsmith/scripts/path_b_wave_runner.sh:96-122` — wave runner gate impl
- `labsmith/scripts/gen_cast_portraits.py` — portrait gate wire-up
- `labsmith/scripts/gen_book_covers.py` — book cover gate wire-up

## Chapter hero source-of-truth (R-CHAPTER-HERO-SOURCE; 2026-06-11)

**For multi-beat chapters, beat 0 IS the chapter hero. The top-of-page `chapter_<char>_opener.webp` (rendered via `<ChapterIllustration variant="opener" />`) MUST NOT also render** — doing both creates visual redundancy (two opening-scene heroes within 200px) and wastes gen budget at portfolio scale.

### When the rule applies

| Surface | Multi-beat chapter | Path-A-only chapter |
|---|---|---|
| Cast page `/cast/<app>/<char>` | beat 0 hero (via `InterleavedChapterAudioPlayer`); NO top opener WebP | top opener WebP (no beat 0 exists) |
| Tier-2 page `/cast/<app>/<char>/advanced` | same as above (advanced variant of multi-beat sidecar) | same as above |
| `/stories` index thumbnail | uses `chapter_<char>_opener.webp` (cached on disk; not rendered on chapter page itself) | uses `chapter_<char>_opener.webp` |
| PDF book cover (per-app anthology) | uses `<app>-app/Resources/CustomArt/<app>/cover_book_<tier>.webp` from `gen_book_covers.py` (NOT a chapter asset; #812 premise corrected per `Docs/AUDIT_PDF_BOOK_COVER_COHERENCE_2026-06-11.md`) | same per-app cover (not a per-chapter asset) |

The gate in the Astro template is `!hasMultibeat` for the top opener. `hasMultibeat` derives from `multibeat-chapters.json` (prebuild manifest indexing chapters with sidecar + beat PNGs + audio shipped).

### Why this rule exists

Per user-direct 2026-06-11 late ("should we even need opener illustration now that we have multi-beat illustrations?") + Option B selection of the 5-option opener-deprecation decision matrix in `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md`. Visual redundancy + gen-budget waste + storybook-format intent (text+image alternating from the START) all favored dropping the separate top-hero for multi-beat chapters.

### Don'ts

- Don't render `<ChapterIllustration variant="opener" />` unconditionally on a chapter page — always gate on `!hasMultibeat` (OR equivalent feature-detection if the file naming convention evolves)
- Don't DELETE `chapter_<char>_opener.webp` from `spark-anvil-site/public/chapters/<app>/` — the file still serves `/stories` thumbnail role (per `Docs/AUDIT_PDF_BOOK_COVER_COHERENCE_2026-06-11.md` the PDF cover is `cover_book_<tier>.webp`, NOT `_opener.webp`; the `_opener.webp` only feeds the site thumbnail + Path-A-only chapter-page hero)
- Don't render BOTH `<ChapterIllustration variant="opener" />` AND beat 0 in the same page — that's exactly the visual redundancy the rule eliminates
- Don't bypass `.ic-beat-image-opener` styling — beat 0's hero treatment (max-width 960px + heavier shadow + 18px radius) is what makes it read as a chapter cover rather than another beat. Reducing those values reverts to "just another beat" UX

### Reference impl

- `spark-anvil-site/src/pages/cast/[app]/[char].astro` — gate at line 105 (`{!hasMultibeat && <ChapterIllustration ... />}`)
- `spark-anvil-site/src/pages/cast/[app]/[char]/advanced.astro` — same gate for Tier-2 register
- `spark-anvil-site/src/components/InterleavedChapterAudioPlayer.astro` — `.ic-beat-image-opener` hero styling (960px / 18px / 0 6px 24px)

### Forward gen policy (2026-06-13) — DO NOT generate new opener WebPs

Per user-direct 2026-06-13 ("we are not going with openers anymore. this should be documented in the repo folder"): the gen-side stance is STRONGER than the render-side gate above. **NEW chapter authoring does NOT emit `chapter_<char>_opener.webp` assets.** Multi-beat (5-beat canonical per `.claude/rules/distributed-narrative.md` § R-MULTIBEAT-DEFAULT) is the forward standard; beat 0 (Pro tier) IS the chapter hero on the site AND in the PDF book.

| Direction | Pre-2026-06-13 | Post-2026-06-13 (this directive) |
|---|---|---|
| **New chapter gen** | `gen_app_illustrations.py --chapters` → Pro `_opener.webp` + Flash `_spot.webp` (~$0.18/chapter) | `auto_segment_chapter.py` + `pilot_interleaved_ensemble_chapter.py` → 5 beats (Pro beat 0 + 4 Flash; ~$0.32/chapter). NO standalone opener gen |
| **Forward authoring path** | Single-beat allowed as default | Multi-beat 5-beat canonical (R-MULTIBEAT-DEFAULT); single-beat is a narrow carve-out |
| **Legacy opener WebPs on disk (769 across portfolio)** | Live as chapter-page hero + `/stories` thumbnail + (some) PDF cover | STAY on disk as legacy asset; serve `/stories` thumbnail for Path-A-only chapters + chapter-page hero for the dwindling pre-2026-06-12 single-beat set. Do NOT delete |
| **`/stories` thumbnail for multi-beat chapters** | `chapter_<char>_opener.webp` | **MIGRATION NEEDED** to beat 0 source (`chapter_<char>_beat_00.png`); work-queue item filed |

### Downstream work items (filed 2026-06-13)

Filed in `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "Opener illustration deprecation":

1. Migrate `/stories` thumbnail source for multi-beat chapters → beat 0 (~1-2h)
2. Strip opener gen from `gen_app_illustrations.py --chapters` (~30 min)
3. Audit non-GambitTales PDF builders for legacy opener-only fallback (~15 min)
4. Companion deletion sweep (DEFERRED until app reaches 100% multi-beat coverage)

### What this rule does NOT cover

- **PDF book cover source-of-truth transition** — separate work item `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "PDF book cover coherence audit vs PDF book content" handles the PDF builder change from `_opener.webp` to `_beat_00.png`
- **Legacy `chapter_<char>_opener.webp` deletion** — the file remains on disk for `/stories` thumbnail use + Path-A-only chapter-page hero use. Deletion is deferred until both downstream uses have migrated (work items 1 + 2 above + per-app multi-beat 100% coverage)
- **Ensemble chapter Path B** — same rule applies (beat 0 is the hero); no special-casing needed once ensemble chapters move to Path B
- **Edge-case forced single-beat chapters** — extremely rare (trauma-axis chapters where SAMHSA register makes 5-beat infeasible). If a chapter genuinely needs single-beat, surface to user; the chapter retains the legacy `_opener.webp` + `_spot.webp` treatment as documented carve-out

### Cross-references

- `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "Should the opener illustration still exist now that multi-beat illustrations ship?" — the parent strategic question + Option B selection
- `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "PDF book cover coherence audit vs PDF book content" — downstream PDF-axis transition
- `Docs/WORK_QUEUE_INBOUND_HANDOFFS_2026-05-20.md` § "Cast portrait + opener illustration coherence audit vs prose + multi-beat illustrations" — audit scope collapses from 3 axes to 2 axes for multi-beat chapters under this rule (portrait + beat 0)
- `.claude/rules/spark-anvil-website.md` § R-PATH-B-PROMPT-PARITY — beat 0 (Pro tier) is the reference seed for downstream Flash beats; removing the separate opener-gen step doesn't change this because beat 0 IS the opener in `pilot_interleaved_ensemble_chapter.py`'s pipeline
- `Docs/CONTEXT_HANDOFF_2026-06-11_P0_ROUND_CLOSED.md` — predecessor round confirming all 53 chapters have beat 0 Pro-tier assets

## Content upload + manifest rebuild discipline (R-CONTENT-UPLOAD-MANIFEST-DISCIPLINE; 2026-06-19)

**Every content upload to spark-anvil-site MUST result in the corresponding freshness manifest being rebuilt before/during the next Cloudflare Pages deploy.** The site's `package.json` `prebuild` chain handles 5 of 6 manifests automatically via filesystem-scan or git-mtime-scan builders. The 6th manifest (`pdfs-recency.json`) lives hub-side and requires explicit re-run after every PDF render wave.

### 6 manifests + rebuild discipline

| Manifest | Builder | Trigger | Operator responsibility |
|---|---|---|---|
| `src/data/cast-recency.json` | `scripts/build-cast-recency-manifest.mjs` | site prebuild | None — auto. Reads git mtime of sidecars + reads `pdfs-recency.json` mirror |
| `src/data/multibeat-chapters.json` | `scripts/build-multibeat-chapter-manifest.mjs` | site prebuild | None — auto. Scans `public/chapters/<app>/` for sidecar + snapshot + per-beat PNG + M4A + VTT sets |
| `src/data/audio-drama-manifest.json` | `scripts/build-audio-drama-manifest.mjs` | site prebuild | None — auto. Scans `public/audio/<app>/*.m4a` |
| `src/data/books-manifest.json` | `scripts/build-books-manifest.mjs` | site prebuild | None — auto. Scans `public/books/*-book.pdf` + `public/books/covers/<app>/{standard,advanced}.webp` |
| `src/data/cast.json` + `src/data/cast-slug-map.json` | `scripts/build-cast-manifest.mjs` + `build-cast-slug-map.mjs` | site prebuild | None — auto |
| **`src/data/pdfs-recency.json`** | hub-side `scripts/build_pdfs_recency_manifest.py` | **manual after every PDF render wave** | MANDATORY: run hub-side; copy to site; commit |

### PDF-recency refresh recipe (after every PDF render wave)

```bash
# In labsmith/
python3 scripts/build_pdfs_recency_manifest.py

# Mirror to spark-anvil-site/
cp Resources/PDFBooks/recency/pdfs-recency.json \\
   ../spark-anvil-site/src/data/pdfs-recency.json

# Commit in spark-anvil-site/
cd ../spark-anvil-site
git add src/data/pdfs-recency.json
git commit -m "PDF recency manifest refresh after <wave-name> render wave"
git push origin <branch>
```

If the manifest isn't refreshed after a PDF render wave, the homepage "Freshly Updated PDFs" strip + the per-app PDF-weight bonuses on the recency comparator stale out — newly-rendered PDFs DON'T surface above older ones, even though they're fresher.

### What NOT to do

- **Do NOT skip the PDF-recency refresh after a render wave** — site prebuild can't know about hub-side `.pdf` mtimes unless the mirror is committed
- **Do NOT auto-run `build-apps-data.mjs`** — destructive; wipes the rich 136-app schema (see ⚠️ banner at `scripts/build-apps-data.mjs:3`). Use targeted Python read+modify+write edits to `apps.generated.ts` instead
- **Do NOT trust filesystem mtime in cast-recency** — it scans git mtime via `git log -1 --format=%aI`; untracked sidecars get `null` and are excluded from the manifest (correct behavior — only committed content surfaces)

### RSS + sitemap per-entry freshness (this PR codification)

`feed.xml.ts` `<entry><updated>` + `sitemap.xml.ts` `<url><lastmod>` use per-entry mtime sourced from `books-manifest.json` (book entries) + `cast-recency.json` (chapter URLs). Build-time `new Date()` is NOT acceptable for either surface — RSS subscribers + search-engine crawlers depend on these timestamps for novelty / recrawl-priority decisions.

When adding new RSS entry types OR new sitemap URL classes, the per-entry mtime MUST be sourced from an existing manifest OR a fresh one MUST be added to the prebuild chain.

### Cross-references

- `Docs/AUDIT_HOMEPAGE_FRESHNESS_UPDATE_DISCIPLINE_2026-06-19.md` — parent audit
- `scripts/build-cast-recency-manifest.mjs` — canonical recency builder (git-mtime based)
- `scripts/build_pdfs_recency_manifest.py` — hub-side PDF recency builder

## Sidecar `tier` field required (R-SIDECAR-TIER-REQUIRED; 2026-06-19)

**Every multi-beat sidecar manifest MUST carry a `tier` field with integer value 1 or 2.** Applies to BOTH source-of-truth sidecars in `labsmith/Resources/AutoSegmentedChapters/<app>/<char>.beats.json` AND distributed copies in `spark-anvil-site/public/chapters/<app>/chapter_<char>.beats.json`.

### Why this rule exists

Surfaced via Wave 4 chanceforge T2 center fix (2026-06-18). The pilot script `scripts/pilot_interleaved_ensemble_chapter.py` resolves the chapter MD path from the sidecar's `tier` field:

- `tier: 1` → `<app>-app/Docs/dn-s/chapters/<char>.md` (Tier-1 source-of-truth)
- `tier: 2` → `labsmith/Resources/DN-S-Tier-Upper/chapters/<app>/<char>.md` (Tier-2 source-of-truth)

Sidecars missing the field silently default to T1 path. Failure mode: T2 chapter regen reads T1 prose → per-beat audio narrates T1 text → audio + on-page T2 prose mismatch → reader perceives the page as broken.

### How to apply

When `auto_segment_chapter.py` emits a new sidecar, it must include `tier: 1` (default) or `tier: 2` (if `--tier 2` flag set). The flag MUST be threaded through wave runners (`path_b_wave_runner.sh --tier 2`).

When manually authoring a sidecar (rare; usually regenerated):

```json
{
  "chapter": "<char>",
  "app": "<app>",
  "tier": 2,
  "beats": [...]
}
```

### Cross-references

- `Docs/AUDIT_HOMEPAGE_FRESHNESS_UPDATE_DISCIPLINE_2026-06-19.md` § "Companion finding" — surfacing audit
- `scripts/pilot_interleaved_ensemble_chapter.py` — consumer (MD path resolution)
- `scripts/auto_segment_chapter.py` — emitter
- `.claude/rules/distributed-narrative.md` § "Dual-tier chapter editions" — parent dual-tier spec
- `.claude/rules/distributed-narrative.md` § "R-TIER-2-MULTIBEAT-REUSE" — Tier-2 illustration-reuse companion rule

## Cross-references

- `Docs/RESEARCH_SPARK_ANVIL_WEBSITE.md` — research synthesis (~2026-05-20 web search + competitive analysis)
- `Docs/RESEARCH_LIQUID_GLASS_WEBSITE_2026-05-29.md` — Liquid Glass website research synthesis (Round 149 #580; 29 sources)
- `Docs/ADR-014_HYBRID_LIQUID_GLASS_WEBSITE.md` — hybrid Liquid Glass accent adoption decision
- `Docs/PLAN_SPARK_ANVIL_WEBSITE.md` — 7-phase Astro build plan, 3-week v1 launch
- `Docs/PLAN_SPARK_ANVIL_LOGO.md` — logo design plan (Concept C selected)
- `Docs/DECISION_FIGMA_FOR_SPARK_ANVIL_WEBSITE.md` — no Figma for v1
- `.claude/rules/liquid-glass.md` — native iOS 26 Liquid Glass APIs (portfolio-side; distinct from web-side hybrid policy above)
- `Branding/` — brand asset directory
- `Docs/REGISTRY_APP_HERO_COLORS.md` — per-app theming source
- `Docs/RESEARCH_CURRICULUM_STANDARDS_MAPPING.md` — curriculum chips source
- `Docs/DESIGN_BRAND_ARCHITECTURE.md` — brand architecture rules (must apply across portfolio + website)
- `Docs/PLAN_DN_S_WEBSITE_WAVE_1_2026-06-02.md` — Wave 1 implementation plan (8-stage; mostly shipped 2026-06-02)
- `Docs/ADR-022_DN_S_WEBSITE_WAVE_1_OPEN_QUESTIONS.md` — Wave 1 decisions (8 questions resolved)
- `Docs/RESEARCH_DN_S_WEBSITE_INTEGRATION_NEXT_STEPS_2026-06-02.md` — Wave 1 research foundation (24 sources)
- `Docs/AUDIT_DN_S_6_PILLAR_FINAL_2026-06-02.md` — DN-S 6-pillar coverage baseline + chapter-book content source
- `Docs/GUIDE_CAST_PAGE_USER.md` — visitor-facing /cast page guide (warm + non-jargon; ages 9-14 readable per R-SITE-CHROME)
- `Docs/GUIDE_CAST_PAGE_DEVELOPER.md` — maintainer-facing /cast page guide (architecture + data sources + load-bearing rules + extension recipes + gotchas + test plan)
- `spark-anvil-hub/scripts/sync_content_to_site.sh` — chapter/audio/illustration distribution from app repos
- `spark-anvil-hub/scripts/normalize_chapter_frontmatter.py` — YAML normalizer for synced chapter MDs (source of truth)
- `spark-anvil-site/scripts/normalize-chapter-frontmatter.py` — in-repo mirror; auto-runs in prebuild on every site build
<!-- END LABSMITH-SYNCED CONTENT -->
