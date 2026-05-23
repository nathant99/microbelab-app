# Handoff from Labsmith — Distributed-Narrative Methodology Retrofit (Wave 32b)

Direction: **labsmith → microbelab-app**. Wave 32b of the portfolio-wide distributed-narrative methodology expansion. This handoff specifies the canonical **6-character microbe-archetype cast** progressively introduced across MicrobeLab's microscope-zoom + microbiome-simulator core loop.

## 1. The decision

MicrobeLab's CLAUDE.md already mentions **"named microbe characters"** as a core feature — this handoff FORMALIZES the canonical 6-character cast. Domain (microbiology + immune-response + microbiome simulation) decomposes into 6 microbe-archetype primitives per research § 5. UNIQUE TO MICROBELAB: COVID-trauma-sensitive flag is LOAD-BEARING per app design — beneficial microbes are foregrounded; pathogen content is OPT-IN behind off-ramps.

## 2. State at this handoff's commit

- **Microscope-zoom-as-core-loop** mechanic
- **Microbiome simulator**
- **Named microbe characters** (per CLAUDE.md — UNDEFINED; this handoff formalizes)
- **Immune-response minigame**
- **COVID-trauma-sensitive design** (per CLAUDE.md — UNIQUE flag)
- **Dr. Quark** as AI mentor (site `apps.generated.ts`) — **HARD COLLISION** with AdventureHub Wave 27 zone-host Dr. Quark (Science Labs zone). Per registry rule 1, exact-string match requires rename. Proposed: **Cilia** (microbiology-domain-specific register; clear in registry) — site PR includes this rename
- **No DN cast yet**

## 3. The 6-character microbe-archetype cast

Each character IS a microbe-class with personality + ecological-role. Standard chunky-cartoon aesthetic. Beneficial microbes foregrounded; pathogens come LAST (kit 5+ with off-ramps).

| # | Name | Microbe archetype | Personality + voice | Catchphrase | Visual hook | First kit |
|---|---|---|---|---|---|---|
| 1 | **Lacto** | Lactobacillus + helpful-bacteria | Cheerful, abundant, "I'm in your yogurt + sauerkraut + miso" | "Friend in your food. Friend in your gut." | Rod-shaped tween in dairy-toned wrap with food-icons pendant fan (yogurt + miso + pickle) | Kit 1 (Helpful bacteria) |
| 2 | **Yeast** | Saccharomyces + helpful-fungi | Bubbly, transformative, "I turn dough into bread" | "I make air inside bread." | Round-tween with bubble-trail + tiny-loaf pendant | Kit 2 (Helpful fungi) |
| 3 | **Sun** | Cyanobacteria + photosynthetic-microbes | Bright, generous, "I made Earth's air" | "Sunlight. Then air. Then everything else." | Spiral-coiled-tween in blue-green cape with sun-pendant + oxygen-bubble trail | Kit 3 (Microbe + planet) |
| 4 | **Soil** | Mycorrhizal-fungi + nitrogen-fixers | Steady, patient, "I connect the trees underground" | "Forests talk through me." | Network-pattern-tween in earth-brown cardigan with root-tendril pendant fan | Kit 4 (Microbe ecosystems) |
| 5 | **Spore** | Pathogens (introduced with off-ramps) | Neutral-presented, scientific-not-villainous, "I'm part of the world; we work to coexist" | "Some friends. Some not. All real." | Generic spore-shape tween in NEUTRAL grey wrap (NOT villain-coded red); identity-card pendant | Kit 5 (Pathogens — off-ramp gated) |
| 6 | **Guard** | Immune cells (T-cell / macrophage / B-cell) | Patient, alert, "the body knows what's family" | "I check IDs. Patient + careful." | White-blood-cell-tween in cream uniform with ID-card-checker pendant + soft-shield | Kit 6 (Immune response) |

**Name collision check** (registry 2026-05-22):
- **Lacto** — clear in registry
- **Yeast** — clear in registry
- **Sun** — REJECTED — too generic + brand-context (Spark & Anvil sun-coding); RENAMED → **Cyan** (REJECTED — CoRegRealm mentor + Wave 32b sibling above HARD); RENAMED → **Blue-Green** (compound name unusual); RENAMED → **Sky** (REJECTED FlightForge Wave 24 mentor Skye soft-collision homophone + Wave 28 TrailForge AVOID list); RENAMED → **Photo** (clear in registry; photosynthesis register)
- **Soil** — REJECTED HarvestForge Wave 26 reject list + GrowForge Wave 26; HARD collision; RENAMED → **Web** (REJECTED IllusionForge Wave 8 + SleuthLab Wave 17 HARD); RENAMED → **Net** (clear in registry; mycorrhizal-network register)
- **Spore** — clear in registry (different from MakerForge Wave 19 Spool mentor)
- **Guard** — clear in registry (different from Wave 24 SafetyForge Aegis mentor)
- Final cast: **Lacto / Yeast / Photo / Net / Spore / Guard**. dnCast block uses revised names.

## 4. Per-kit introduction schedule

Kits 1-4 introduce beneficial microbes (Lacto / Yeast / Photo / Net). Kit 5 introduces Spore (pathogens) WITH PRE-CONTENT WARNING + OPT-IN GATE. Kit 6 introduces Guard (immune response). Kits 7+ recurrence + ensemble.

**COVID-TRAUMA-SENSITIVE GATE enforced** (LOAD-BEARING; UNIQUE to MicrobeLab):

1. Kits 1-4 (helpful microbes) load-bearing — beneficial microbes get 4 kits BEFORE any pathogen content
2. Kit 5 (pathogens) is GATED — pre-content warning + opt-in + skip-with-summary affordance
3. Cast NEVER frames pathogens as villainous — Spore presented neutrally, scientifically
4. NO COVID-specific scenarios (per CLAUDE.md trauma-sensitive flag) — generic-pathogen framing only
5. NO mask-or-vax-mandate scenarios — vaccine science explained as IMMUNE-RESPONSE-TRAINING (Kit 6), NOT policy debate
6. NO graphic illness imagery — sick people NEVER depicted; immune-response is the cast story
7. External pediatric-microbiology-pedagogy + COVID-trauma-aware sensitivity reviewer RECOMMENDED ($500-$800) for kit 5 + kit 6

## 5. Cross-app cameos

- **Photo ↔ EcoSphere + BiomeForge** (photosynthesis cross-cluster)
- **Net ↔ NexusForge** Wave 23 + **OriginForge** Wave 23 (network-systems cross-cluster — load-bearing)
- **Guard ↔ BodyForge** + **HealthForge** archived planning (immune-system cross-cluster)
- **Lacto ↔ SaffronLab** Wave 19 (fermentation cross-cluster — load-bearing)
- **Yeast ↔ SaffronLab + HarvestForge** Wave 19 + Wave 26 (food-microbe cross-cluster)

## 6. Asset spend

6 chars × 5 poses × ~$0.27 = **~$1.62**. Labsmith owns generation. External reviewer separate: $500-$800.

## 7. Acceptance criteria

Standard cast intro per kit + Dr. Quark renamed to Cilia in Wave 32b site PR + pathogen kit gated behind opt-in + Cilia mentor scaffolding refs cast + external sensitivity reviewer engaged + consumer-audit grep passes.

Direction summary: **labsmith → microbelab-app**. Adopt 6-character microbe-archetype cast (Lacto / Yeast / Photo / Net / Spore / Guard) under Dr. Quark-renamed-to-Cilia mentor. UNIQUE COVID-trauma-sensitive burden. Mentor rename resolves HARD collision with AdventureHub Wave 27 Dr. Quark zone-host.
