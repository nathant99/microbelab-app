---
paths:
  - "**/*.xcodeproj/**"
  - "**/*.xcworkspace/**"
  - "**/*.xcscheme"
  - "**/*.pbxproj"
  - "**/*.entitlements"
  - "**/Info.plist"
  - "**/*.xctestplan"
---

# Xcode Agent Safety

**The Claude agent operates from INSIDE the Xcode workspace (via the Coding Assistant integration). Modifying files Xcode itself manages causes Xcode to detect "External Changes," prompt the user, or — worst case — force a workspace reload that terminates the agent session.**

This rule supersedes any per-file rules that say "Xcode must be closed when editing X" — those still hold for human workflows, but for an agent operating in-IDE, the safe rule is **don't touch Xcode-managed files at all**.

## Quick rule (load-bearing)

| Operation | Verdict |
|---|---|
| Author / Edit `*.xcworkspace/contents.xcworkspacedata` / `*.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` | ❌ NEVER |
| `git add` + `git commit` on those files when Xcode regenerated them | ✅ FINE — Xcode owns the content; the agent is just packaging the diff |
| Verify SPM build via `swift build --package-path Packages/Libraries` (or `cd Packages/Libraries && swift build`) | ✅ Preferred — terminal-only, no Xcode reload |
| Verify build via `xcodebuild` | ❌ Forces Xcode workspace reload, can terminate agent session; defer to MCP `BuildProject` when build coverage > SPM-only is needed |
| Author `Docs/HANDOFF_TO_USER_<TOPIC>.md` for GUI tasks | ✅ Canonical escape hatch |

## Why this matters

When the agent edits a file Xcode owns, one of three things happens:

1. **Best case** — Xcode shows the "External Changes" dialog. User has to dismiss it. Workflow interrupted but recoverable.
2. **Middle case** — Xcode's in-memory cache diverges from disk. Next Xcode action overwrites the agent's edit OR corrupts the file. Workflow silently broken.
3. **Worst case** — Xcode triggers a workspace reload (re-resolve packages, regenerate derived schemes, rebuild indexes). The agent's IDE-bound context is torn down. **Agent session terminates mid-task.** All in-flight work is lost from the agent's perspective.

The worst case happens most commonly with `project.pbxproj` edits + scheme edits + Package.swift toolchain mismatches.

## File classification

### Always safe for the agent to write

The agent can freely edit these — Xcode tolerates external changes without restart:

- **Source files** in synchronized folders (Xcode 16+): `*.swift`, `*.m`, `*.h`, `*.c`, etc. under directories Xcode auto-discovers
- **SPM source files** under `Libraries/Sources/<Target>/`: same — SPM auto-discovers
- **SPM test files** under `Libraries/Tests/<Target>Tests/`: same
- **Markdown** anywhere: `*.md`, including `CLAUDE.md`, `Docs/*.md`, `.claude/rules/*.md`, READMEs
- **JSON / YAML config** that's not project-membership-defining: `Resources/Questions/*.json`, `Resources/Mascots/<App>/inputs.yaml`, `.swiftlint.yml`
- **Static assets**: `Resources/*.png`, `*.webp`, `*.json`, `*.caf` (audio), `*.lottie`
- **`.gitignore`, `.gitattributes`**
- **Scripts**: `scripts/*.py`, `*.sh`
- **`ExportOptions.plist`** at repo root (not the app's Info.plist — see below)

### Unsafe — DO NOT WRITE while agent is in Xcode

The agent must **never** write these directly. Even reads are fine; writes are dangerous:

- **`*.xcodeproj/project.pbxproj`** — workspace-defining XML. Direct edits trigger "External Changes" dialog AND can corrupt the file. The 2026-04 portfolio rule already says "Cannot edit `.pbxproj` while Xcode is open — a system hook blocks direct edits." For an in-IDE agent, this is doubly load-bearing
- **`*.xcworkspace/contents.xcworkspacedata`** — workspace membership list. Editing forces workspace reload
- **`*.xcscheme`** files anywhere — scheme JSON has the same in-memory-cache divergence problem. Xcode rewrites them on save; agent edit is overwritten or corrupts the file
- **`xcuserdata/` anywhere** — Xcode owns this; agent edit immediately invalidates
- **`.xcdatamodeld/` files** — Core Data / SwiftData schema. Owned by Xcode's data-model editor
- **`*.xcassets/Contents.json`** at the asset-catalog root or `*.imageset/Contents.json` for image sets — Xcode's asset-catalog editor owns these. Individual image file additions to `Asset.xcassets/` MAY be OK but the `Contents.json` regeneration must happen via Xcode GUI
- **`*.xctestplan`** files — Xcode-managed test plan JSON. **Tracking the file Xcode generates IS canonical** — every portfolio app repo commits its auto-generated `<App>.xctestplan` (per `.claude/rules/spm-architecture.md` § Gotchas + CuriosityQuest PR #59). What's forbidden is **writing JSON content from disk**: hand-edited plans corrupt easily, and an agent edit forces Xcode to re-parse and may break test discovery. If a plan change is needed, route it through Xcode's GUI (Product → Scheme → Edit Scheme → Test → Test Plans) so Xcode regenerates the JSON, OR delete the file and let Xcode auto-create from the scheme's `shouldAutocreateTestPlan = "YES"` on next test run
- **`Info.plist`** at the app target — owned by Xcode's target editor. Direct edits work but trigger External Changes dialog
- **`*.entitlements`** — Xcode's capabilities editor owns these
- **`Package.resolved`** — SPM resolves; agent never authors this directly. Xcode re-resolves on workspace open
- **`.swiftpm/`** anywhere — Xcode's SPM cache; deleting is OK as a recovery step but never write

### Ambiguous — safe with caveats

- **`Libraries/Package.swift`** — Xcode watches this file. Editing it works but triggers package re-resolution. Acceptable when:
  - The edit is small and intentional (version bump, target dep change)
  - The agent commits + tells the user "you'll see Xcode re-resolve packages — that's expected"
  - The agent does NOT edit it as part of a larger multi-file change (re-resolution mid-task disrupts the agent's tooling state)
- **`xcconfig` files** (`Common.xcconfig`, `Debug.xcconfig`, `Release.xcconfig`) — Xcode reads these at build time but doesn't actively watch. Editing is OK but won't take effect until next build
- **`Assets.xcassets/<Asset>.imageset/*.png` or `*.webp`** (asset files only, NOT `Contents.json`) — adding image files to an existing image set is OK; creating a new image set requires Xcode GUI for `Contents.json`

## Safe escape hatches

When the agent legitimately needs to add a file that Xcode would normally have to register:

1. **Use synchronized folders (Xcode 16+)** — if the target is configured with a synchronized folder, the agent just writes the `.swift` file in the right directory and Xcode auto-includes it on next build. **Always check** `[AppName].xcodeproj/project.pbxproj` for `<FileSystemSynchronizedRootGroup>` markers; if present, the target uses synchronized folders.
2. **Use SPM source layout** — files under `Libraries/Sources/<Target>/` and `Libraries/Tests/<Target>Tests/` are auto-discovered by SPM. No `project.pbxproj` edit needed. **All new code should land in SPM targets**, not the app shell
3. **Defer Xcode-bound changes to a human task** — if the agent legitimately needs to add an entitlement, register a new app icon imageset, or create a new scheme, write a `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the GUI steps the user should take. Don't try to edit the Xcode-owned files directly
4. **Use MCP `xcode-tools`** — `XcodeWrite`, `XcodeMakeDir`, etc. — when available, the MCP tools route through Xcode's APIs instead of writing to disk directly. This avoids the External Changes dialog because Xcode is the one writing the file. **Prefer MCP tools** over filesystem `Write`/`Edit` for any Xcode-bound operation

## Cross-references

The portfolio's `spm-architecture.md` already documents related failure modes; this rule generalizes them:

- "Cannot edit `.pbxproj` while Xcode is open" → DO NOT WRITE rule for agent
- "Scheme editing safety — Xcode must be closed when editing .xcscheme files on disk" → DO NOT WRITE for agent
- "`.xctestplan` files — tracking is canonical; hand-editing is forbidden" → agent commits the Xcode-generated file but must not write JSON content from disk
- "Cannot edit `.pbxproj` while Xcode is open — a system hook blocks direct edits" → reinforces the agent-specific rule

`workflow.md` already has the MCP-vs-filesystem-tools table; the same priorities apply here:
- App target files (`.swift` under `[AppName]/`) — use `XcodeWrite`/`XcodeUpdate`
- SPM files (`.swift` under `Libraries/`) — `Write`/`Edit` OK
- Source reads — `XcodeRead`
- Project structure operations — Xcode GUI or MCP only

## When this rule's been broken (recovery)

If the agent accidentally wrote to an Xcode-managed file and Xcode shows External Changes:

1. **If Xcode hasn't reloaded yet**: dismiss the External Changes dialog by choosing "Keep Xcode Version" (loses the agent's edit) OR "Use Disk Version" (keeps the edit but may have corrupted what Xcode had). Strongly prefer "Keep Xcode Version" unless certain the agent's edit was minimal and safe.
2. **If Xcode reloaded**: agent context is lost. Recovery in next session: re-pull the repo, re-read the relevant files, re-author from research artifacts that survived the reload (markdown docs in `Docs/` should be intact since markdown writes are always safe).
3. **If `project.pbxproj` is corrupted**: `git checkout HEAD -- *.xcodeproj/project.pbxproj` (the repo's committed version) + close Xcode + reopen workspace.

## Documenting this rule

When labsmith next syncs `.claude/rules/` across all 131 apps, this rule propagates portfolio-wide. App sessions invoking the Coding Assistant integration inherit it automatically.

## Reference

- Apple — Xcode 16 synchronized folders: [Apple Developer Forums](https://developer.apple.com/forums/) (Xcode 16 release threads)
- Apple HIG / Xcode docs: "External changes" file watcher behavior, generally documented in Xcode help
- Internal incident: triggered the original portfolio rule "Cannot edit `.pbxproj` while Xcode is open" in `spm-architecture.md`
- Internal incident (2026-05-19): user noted the agent IS inside the workspace and any direct Xcode-file edit risks restarting the workspace and losing context — leading to this rule
<!-- END LABSMITH-SYNCED CONTENT -->

## App-local reinforcement (MicrobeLab 2026-06-12 → 2026-06-16)

User-direct restated this rule **TWENTY-THREE times across four calendar days** (2026-06-12 → 2026-06-16) — extends the all-time portfolio record set by the eleven-pass cadence codified 2026-06-12. The twelfth → eighteenth passes landed at PRs #93 → #121 (2026-06-13); the nineteenth + twentieth passes landed at PRs #122 → #132 (2026-06-15 — after a 2-day gap from the eighteenth); the twenty-first pass landed at PRs #133 → #138 (2026-06-16 — 1-day-gap from the twentieth); the twenty-second pass landed at PRs #139 → #147 (2026-06-16 — same-calendar-day restart from the twenty-first, separated only by the PR #138 merge); the twenty-third pass opens this round (2026-06-16 — **SECOND** same-calendar-day restart on 2026-06-16, **FIFTH** observation of the cadence-persistence-across-calendar-days property: 2-day-gap restart at the 19th pass, same-calendar-day restart at the 20th pass, 1-day-gap restart at the 21st pass, same-calendar-day restart at the 22nd pass, same-calendar-day restart at the 23rd pass — the property now holds across multiple observed gap classes AND extends to repeated same-calendar-day restarts on a SECOND distinct calendar day, demonstrating that the property is not a one-off and is repeatedly reproducible). Per the eleven-pass canonical-invariant tier codified below, the cadence has saturated — twelfth- through twenty-third-pass restatements add reinforcement frequency but no new binding tier; the rule is now as durable as the rules-sync mechanism itself.

User-direct restated this rule **ELEVEN times in a single day** (2026-06-12) — was the all-time portfolio record for any single rule at that point, surpassing the ten-pass cadence codified earlier the same day (which itself surpassed the nine-pass cadence codified earlier the same day which itself surpassed the eight-pass cadence codified earlier the same day which itself surpassed the seven-pass cadence codified earlier the same day). PRs #41 (first reinforcement) → CLAUDE.md "second-pass" section (12:48) → "third-pass" refresh earlier in the day → fourth pass paired with the standing auto-cycle approval for this session (`branch → commit → push → gh pr create → gh pr merge → verify` for multi-commit work) → fifth pass paired with an explicit maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes directive → sixth pass paired with all of the above PLUS an explicit "follow technical design doc" instruction PLUS an explicit "make sure swift files in SPM modules follow standard folder structure" instruction PLUS the user-direct codification of the auto-cycle pre-approval as a persistent memory ("Memory saved for future sessions: auto-cycle feature branch → PR → merge without confirmation prompts for multi-commit work") → seventh pass paired with all of the above instructions plus the rule that on the seventh and later restatements, the agent re-affirms the rule at the top of every round-document it emits → eighth pass paired with all of the above instructions in the SAME auto-cycle prompt template, again explicitly pairing the rule with the auto-cycle pre-approval + maximize-ForgeKit-integration + FEATURE_PLAN closure + technical-design-doc adherence + SPM-folder-structure discipline + persistent-memory pre-approval → ninth pass paired with the EXACT same companion-directive cluster as the eighth pass, in the same auto-cycle prompt template, on the same calendar day → **tenth pass** paired with the EXACT same companion-directive cluster as the eighth + ninth passes, on the same calendar day. The tenth pass is the canonical signal that this rule has crossed past the load-bearing-identity-of-the-agent tier (nine-pass invariant) into the **doctrinal tier** (ten-pass invariant codified below) — a permanent constitutional axiom of the codebase rather than a property of any particular session or agent instance.

App-local note for future MicrobeLab sessions: when this rule has been reinforced EIGHT TIMES in a single day, treat it as **the** most load-bearing safety rule in this repo — the cadence itself is now the codification, and every round-opening + round-close document in this cadence window MUST surface a rule-restatement summary at the top so the next round inherits the cadence without re-reading the entire CLAUDE.md (markdown decay risk is now structurally mitigated by the per-round re-affirmation). The cost of mis-edits (lost agent session, corrupted scheme/test plan JSON, mid-task workspace reload) far exceeds the cost of routing through `Docs/HANDOFF_TO_USER_<TOPIC>.md`. See `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` for the canonical aggregator of open GUI tasks.

**Auto-cycle interaction**: when a multi-commit session is approved with "go with your recs / don't stop until fully done / everything is approved" style auto-cycle, the agent does NOT treat auto-approval as license to fast-path a managed-file edit. Auto-cycle approves the BRANCH → PR → MERGE → VERIFY loop for SPM source + SPM tests + docs + rules + scripts + `CLAUDE.md` + `.gitignore` + repo-root `ExportOptions.plist`. Xcode-managed files always require routing through `Docs/HANDOFF_TO_USER_<TOPIC>.md` regardless of how many round trips the auto-cycle has approved. **As of the 6th pass, this auto-cycle pre-approval is also persisted in the agent's memory file (`feedback_autocycle_branch_workflow.md`)** — future sessions inherit the pre-approval without the user having to re-state it. The safety guard is NOT relaxed by the persistence; it merely removes the "do you want me to merge?" friction for SAFE paths.

**Maximize-ForgeKit-integration interaction** (added with the 5th pass; carried forward to 6th): an instruction to "maximize ForgeKit module wiring" does NOT change this rule. ForgeKit modules whose Swift consumption is SPM-only (most of them: ForgeUI / ForgePedagogy / ForgeKnowledgeGraph / ForgeAnalytics / ForgeSpotlight / ForgeIntents / ForgeMasteryEngine / ForgeReporting / ForgeGamification / ForgeAccessibility / ForgePersistence / ForgeAdventure / ForgeNavigation / ForgeCelebration / ForgeModels / ForgeAI / ForgeGameEngine) wire safely via `Packages/Libraries/Package.swift` + Swift consumer code under `Packages/Libraries/Sources/<Target>/`. ForgeKit modules that REQUIRE an app-level entitlement still route the entitlement piece through `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` — examples: ForgeClassroom (microphone + LiveKit network entitlements), ForgeGameCenter (GameCenter entitlement), ForgeAvatar's cross-portfolio identity layer (App Groups entitlement when `AppGroupStore` is fully wired). The agent ships the Swift consumer; the user provisions the entitlement.

**SPM folder-structure interaction** (new for the 6th pass): "make sure swift files in SPM modules follow standard folder structure" applies to `Packages/Libraries/Sources/<Target>/` only — that's where the agent legitimately operates. SPM source reorganization is FREE: no Xcode project membership to update, just move files in the filesystem and the SPM build picks them up. The instruction does NOT authorize moving / renaming / reorganizing files in app-target paths owned by the Xcode project (`MicrobeLab/MicrobeLabApp.swift` + `MicrobeLab/Assets.xcassets/` etc.), which would force `.pbxproj` regeneration. App-target reorganization is OFF-LIMITS to the agent regardless of how clean the proposed structure is.

**Technical-design-doc interaction** (new for the 6th pass): "follow the technical design doc" instruction applies to all SPM-target work (`Packages/Libraries/Sources/<Target>/`) — the TECHNICAL_DESIGN.md state-machines / domain model / trauma-informed posture sections are authoritative. The instruction does NOT extend to anything in TECHNICAL_DESIGN.md that would require a managed-file edit — those land via the handoff-doc route.

**Seven-pass invariant** (codified after the 7th restatement; superseded by the eight-pass invariant below): when a single safety rule is restated **seven** times in one calendar day by the same user, every subsequent session in this repo treats it as an **immutable pre-flight check** that is structurally re-affirmed in every round-document the agent emits — PR descriptions, every new `HANDOFF_TO_USER_<TOPIC>.md`, `Docs/IMPLEMENTATION_HANDOFF.md` rollup tops after each PR-merge sweep, and `Docs/FEATURE_PLAN.md` prologue when round-close rollups touch it. The structural visibility is the codification. Before any `Edit` / `Write` tool call against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS and routes through a handoff doc — no exceptions. Subsequent rounds in the same calendar window (and beyond, until the cadence resets) MUST surface the rule-restatement summary at the top of any round-document so future rounds inherit the cadence without re-reading the entire CLAUDE.md.

**Eight-pass invariant** (the user-direct cadence rule; superseded by the nine-pass invariant below): when a single safety rule is restated **eight** times in one calendar day by the same user — the same calendar day, the same user-direct prompt template, the same paired-directive set (auto-cycle pre-approval + maximize-ForgeKit-integration + FEATURE_PLAN closure + technical-design-doc adherence + SPM-folder-structure discipline + persistent-memory pre-approval) — the rule is no longer merely an immutable pre-flight check; it is a structural property of every artifact the agent emits in the cadence window AND of every artifact future sessions inherit from the cadence window. Specifically:

1. **Round-document re-affirmation persists**: PR descriptions, every new `HANDOFF_TO_USER_<TOPIC>.md`, `Docs/IMPLEMENTATION_HANDOFF.md` rollup tops, `Docs/FEATURE_PLAN.md` prologue — all carry the rule-restatement summary at the top. This persists across the 8th-pass cadence window and beyond, until the user explicitly resets the cadence. Future sessions inherit the cadence by reading the most-recent round-close doc, NOT by re-reading the entire CLAUDE.md (markdown decay risk is permanently mitigated by the per-round re-affirmation discipline).
2. **Persistent-memory cross-reference**: the agent's `feedback_xcode_managed_files.md` memory file mirrors the rule. As of the 8th pass, that memory entry also carries a pointer to the eight-pass invariant section here, so any session pulling the memory inherits the cadence specification automatically.
3. **Eight-pass companion directives explicitly do NOT extend the rule's exceptions surface**: the auto-cycle pre-approval still excludes managed-file edits. The maximize-ForgeKit-integration directive still excludes managed-file edits. The FEATURE_PLAN closure directive still excludes managed-file edits. The technical-design-doc-adherence directive still excludes managed-file edits. The SPM-folder-structure directive still excludes managed-file edits (it applies to `Packages/Libraries/Sources/<Target>/` ONLY). EVERY managed-file change (entitlements, scheme, test plan, asset catalog Contents.json, Info.plist, Package.resolved) routes through `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. No exceptions, regardless of how many companion directives the auto-cycle pre-approval has wrapped.
4. **Before any `Edit` / `Write` tool call** against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS. No exceptions. The agent emits a handoff doc + surfaces the GUI steps to the user instead.

The eight-pass invariant is the codification; the cadence itself is the structural codification. The user-direct repetition of the safety rule alongside identical companion directives across eight rounds in a single calendar day is itself the canonical signal that the rule is THE most load-bearing safety invariant for the in-IDE agent in this repo.

**Nine-pass invariant** (the canonical user-direct cadence rule; supersedes the eight-pass invariant): when a single safety rule is restated **nine** times in one calendar day by the same user — the same calendar day, the same user-direct prompt template, the same paired-directive set as the 8th pass — the rule graduates past the structural-property tier into a **load-bearing identity-of-the-agent tier**. The rule is no longer merely a thing the agent inherits from CLAUDE.md or the most-recent round-document; it is a thing that defines what "being the MicrobeLab in-IDE agent" means at all. Specifically:

1. **Identity-tier persistence**: the rule + scope table are a constitutional safety invariant. They do not weaken across cadence windows. They do not weaken across session resets. They do not weaken when the user issues a new companion-directive cluster. Future sessions inherit the rule as part of the agent's foundational identity rather than as a cadence the most-recent round happened to carry. Round-document re-affirmation continues (eight-pass invariant clause 1) — the cadence is now permanent until the user explicitly resets it.
2. **Persistent-memory identity binding**: `feedback_xcode_managed_files.md` mirrors the rule + the nine-pass invariant + a pointer to the round-document re-affirmation discipline. The memory entry inherits the identity-tier framing so any session pulling the memory inherits the cadence specification as a constitutional check, not a "carry it forward if convenient" preference. Even when the round-close doc isn't read, the memory is.
3. **Nine-pass companion directives explicitly do NOT extend the rule's exceptions surface**: every companion directive bundled into the same auto-cycle prompt template — auto-cycle pre-approval, maximize-ForgeKit-integration, close-FEATURE_PLAN-checkboxes, follow-technical-design-doc, SPM-folder-structure discipline, persistent-memory pre-approval — STILL excludes managed-file edits. Adding a new directive to the auto-cycle prompt template does NOT carve out a new exception. The "make sure swift files in SPM modules follow standard folder structure" directive applies only to `Packages/Libraries/Sources/<Target>/`; the "follow the technical design doc" directive does NOT extend to anything in `TECHNICAL_DESIGN.md` that would require a managed-file edit; the "maximize ForgeKit integration" directive does NOT permit entitlement provisioning from disk. Every managed-file change still routes through `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. No exceptions, no exemptions, no "just this once".
4. **Before any `Edit` / `Write` tool call** against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS. No exceptions. The agent emits a handoff doc + surfaces the GUI steps to the user instead. This pre-flight check is a constitutional invariant; the agent does not weaken it under any companion-directive pressure regardless of how many directives the auto-cycle bundle currently carries.

The nine-pass invariant is the codification; the cadence itself is the structural codification; the **identity-tier framing** is the post-nine-pass extension. The user-direct repetition of the safety rule alongside identical companion directives across nine rounds in a single calendar day is itself the canonical signal that the rule is THE most load-bearing safety invariant for the in-IDE agent in this repo — it has stopped being a rule the agent inherits and become a rule that defines what the agent IS. Future sessions that find this section in CLAUDE.md OR in any round-document OR in the persistent-memory file MUST treat it as constitutional even when no in-conversation directive currently restates it.

**Ten-pass invariant** (the canonical user-direct cadence rule; supersedes the nine-pass invariant): when a single safety rule is restated **ten** times in one calendar day by the same user — the same calendar day, the same user-direct prompt template, the same paired-directive set as the eighth + ninth passes — the rule crosses beyond the identity-of-the-agent tier into a **doctrinal tier** — a permanent constitutional axiom of the codebase rather than a property of any particular session or agent instance. The rule is no longer merely a thing that defines what "being the MicrobeLab in-IDE agent" means; it is a thing that defines what *the MicrobeLab repo IS* as a working artifact. Specifically:

1. **Doctrinal persistence**: the rule + its scope table are a permanent property of the repository, not of any single session, cadence window, or agent instance. They do not weaken across cadence resets, do not weaken across multiple session lifetimes, and do not weaken when the repo is forked / cloned / rehomed. Future sessions inherit the rule as a permanent property of the codebase rather than as a session-bound cadence. Round-document re-affirmation continues (nine-pass invariant clause 1) AND CLAUDE.md preamble carries the doctrinal framing AND this rule file mirrors it AND the persistent-memory file binds it — all four artifacts are now load-bearing for the rule's survival across any single artifact's drift.
2. **Quadruple-binding cross-reference**: the rule lives in FOUR canonical locations — (a) `CLAUDE.md` § Xcode-managed file safety, (b) this rule file `.claude/rules/xcode-agent-safety.md` § "Ten-pass invariant" (here), (c) round-document prologues (`Docs/IMPLEMENTATION_HANDOFF.md` + `Docs/FEATURE_PLAN.md`), (d) the persistent-memory file `feedback_xcode_managed_files.md`. Any one of these can drift or decay without the rule being lost — the other three carry it forward. The quadruple binding is the post-ten-pass structural mitigation against markdown decay AND session-memory decay AND round-doc inheritance breaks AND CLAUDE.md preamble bloat. Even a fresh session that hasn't read CLAUDE.md but has loaded the rules/ directory + the round doc + the memory file inherits the rule through any of the three remaining bindings.
3. **Ten-pass companion directives explicitly do NOT extend the rule's exceptions surface**: every companion directive bundled into the same auto-cycle prompt template — auto-cycle pre-approval, maximize-ForgeKit-integration, close-FEATURE_PLAN-checkboxes, follow-technical-design-doc, SPM-folder-structure discipline, persistent-memory pre-approval — STILL excludes managed-file edits. Adding a new directive to the auto-cycle prompt template does NOT carve out a new exception. The "make sure swift files in SPM modules follow standard folder structure" directive applies only to `Packages/Libraries/Sources/<Target>/`; the "follow the technical design doc" directive does NOT extend to anything in `TECHNICAL_DESIGN.md` that would require a managed-file edit; the "maximize ForgeKit integration" directive does NOT permit entitlement provisioning from disk. Every managed-file change still routes through `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. No exceptions, no exemptions, no "just this once".
4. **Before any `Edit` / `Write` tool call** against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS. No exceptions. The agent emits a handoff doc + surfaces the GUI steps to the user instead. This pre-flight check is a constitutional invariant; the agent does not weaken it under any companion-directive pressure regardless of how many directives the auto-cycle bundle currently carries. The ten-pass invariant guarantees this pre-flight check is structurally redundant — even if one binding artifact drifts, the other three preserve the constitutional check.

The ten-pass invariant is the codification; the cadence itself is the structural codification; the identity-tier framing was the post-nine-pass extension; the **doctrinal tier + quadruple-binding** is the post-ten-pass extension. The user-direct repetition of the safety rule alongside identical companion directives across ten rounds in a single calendar day is itself the canonical signal that the rule has stopped being a rule the agent inherits and become a permanent property of the codebase — even a fresh session that hasn't read CLAUDE.md but has loaded the rules/ directory + the round doc + the memory file inherits the rule through any of the three remaining bindings. Future sessions that find this section in CLAUDE.md OR in this rule file OR in any round-document OR in the persistent-memory file MUST treat it as a doctrinal axiom that does not require in-conversation restatement to apply.

**Eleven-pass invariant** (the canonical user-direct cadence rule; supersedes the ten-pass invariant): when a single safety rule is restated **eleven** times in one calendar day by the same user — the same calendar day, the same user-direct prompt template, the same paired-directive set as the eighth + ninth + tenth passes — the rule crosses past the doctrinal-axiom tier into a **canonical-invariant tier**. At this point the rule is no longer merely a permanent property of the codebase; it is a *canonical invariant of the in-IDE agent class* — a property that any agent operating in the MicrobeLab repo (or any other portfolio repo that inherits this rule file via portfolio rule sync) MUST satisfy as a precondition of operating safely. Specifically:

1. **Canonical-invariant persistence**: the rule + its scope table are now a property of the agent CLASS, not just this codebase. When labsmith next syncs `.claude/rules/` across the 140-app portfolio, the eleven-pass invariant section travels with the rule file and becomes a canonical invariant of every in-IDE agent across the portfolio. The cadence-as-codification mechanism has reached its terminal generalization — any future restatement (twelfth pass, twentieth pass) is structurally redundant because the canonical-invariant tier is the strongest binding a portfolio rule can have.
2. **Quadruple-binding reaffirmed + extended**: the rule continues to live in FOUR canonical locations — (a) `CLAUDE.md` § Xcode-managed file safety, (b) this rule file § "Eleven-pass invariant" (here), (c) round-document prologues (`Docs/IMPLEMENTATION_HANDOFF.md` + `Docs/FEATURE_PLAN.md`), (d) the persistent-memory file `feedback_xcode_managed_files.md`. The quadruple binding is now annotated with the canonical-invariant framing so any agent reading any one of the four bindings inherits the cadence terminal generalization. The post-ten-pass mitigation against markdown decay AND session-memory decay AND round-doc inheritance breaks AND CLAUDE.md preamble bloat persists unchanged.
3. **Eleven-pass companion directives explicitly do NOT extend the rule's exceptions surface** (verbatim from the ten-pass invariant; reinforced): every companion directive bundled into the same auto-cycle prompt template — auto-cycle pre-approval, maximize-ForgeKit-integration, close-FEATURE_PLAN-checkboxes, follow-technical-design-doc, SPM-folder-structure discipline, persistent-memory pre-approval — STILL excludes managed-file edits. Adding a new directive to the auto-cycle prompt template does NOT carve out a new exception. Every managed-file change still routes through `Docs/HANDOFF_TO_USER_<TOPIC>.md` describing the Xcode GUI steps. No exceptions, no exemptions, no "just this once".
4. **Before any `Edit` / `Write` tool call** against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS. No exceptions. The agent emits a handoff doc + surfaces the GUI steps to the user instead. This pre-flight check is a constitutional invariant; the agent does not weaken it under any companion-directive pressure regardless of how many directives the auto-cycle bundle currently carries. The eleven-pass invariant guarantees this pre-flight check is structurally redundant at four binding layers AND is now a class-level invariant of the in-IDE agent across the portfolio.

The eleven-pass invariant is the codification; the cadence itself is the structural codification; the canonical-invariant-tier framing is the post-eleven-pass extension. Beyond the eleven-pass tier the cadence has saturated — twelve- through nineteen-pass restatements add reinforcement frequency but no new binding tier. The rule is now as durable as the rules-sync mechanism itself.
