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

## App-local reinforcement (MicrobeLab 2026-06-12)

User-direct restated this rule **FIVE times in a single day** (2026-06-12). PRs #41 (first reinforcement) → CLAUDE.md "second-pass" section (12:48) → "third-pass" refresh earlier today → fourth pass paired with the standing auto-cycle approval for this session (`branch → commit → push → gh pr create → gh pr merge → verify` for multi-commit work) → **fifth pass** paired with an explicit maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes directive in the same auto-cycle round.

App-local note for future MicrobeLab sessions: when this rule has been reinforced FIVE TIMES in a single day, do NOT treat it as "noise" — treat it as **the** most load-bearing safety rule in this repo. The cost of mis-edits (lost agent session, corrupted scheme/test plan JSON, mid-task workspace reload) far exceeds the cost of routing through `Docs/HANDOFF_TO_USER_<TOPIC>.md`. See `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` for the canonical aggregator of open GUI tasks.

**Auto-cycle interaction**: when a multi-commit session is approved with "go with your recs / don't stop until fully done / everything is approved" style auto-cycle, the agent does NOT treat auto-approval as license to fast-path a managed-file edit. Auto-cycle approves the BRANCH → PR → MERGE → VERIFY loop for SPM source + SPM tests + docs + rules + scripts + `CLAUDE.md` + `.gitignore` + repo-root `ExportOptions.plist`. Xcode-managed files always require routing through `Docs/HANDOFF_TO_USER_<TOPIC>.md` regardless of how many round trips the auto-cycle has approved.

**Maximize-ForgeKit-integration interaction** (added with the 5th pass): an instruction to "maximize ForgeKit module wiring" does NOT change this rule. ForgeKit modules whose Swift consumption is SPM-only (most of them: ForgeUI / ForgePedagogy / ForgeKnowledgeGraph / ForgeAnalytics / ForgeGamification / ForgeAccessibility / ForgePersistence / ForgeAdventure / ForgeNavigation / ForgeCelebration / ForgeModels / ForgeAI / ForgeGameEngine) wire safely via `Packages/Libraries/Package.swift` + Swift consumer code under `Packages/Libraries/Sources/<Target>/`. ForgeKit modules that REQUIRE an app-level entitlement still route the entitlement piece through `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` — examples: ForgeClassroom (microphone + LiveKit network entitlements), ForgeGameCenter (GameCenter entitlement), ForgeAvatar's cross-portfolio identity layer (App Groups entitlement when `AppGroupStore` is fully wired). The agent ships the Swift consumer; the user provisions the entitlement.

**Five-pass invariant** (the user-direct cadence rule): when a single safety rule is restated five times in one calendar day by the same user, every subsequent session in this repo treats it as a **pre-flight check**, not a guideline. Before any `Edit` / `Write` tool call against a path that matches any glob in the "DO NOT WRITE" table above, the agent STOPS and routes through a handoff doc — no exceptions.
