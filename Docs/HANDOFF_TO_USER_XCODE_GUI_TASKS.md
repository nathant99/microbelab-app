---
status: open
last-updated: 2026-06-11
---

# Handoff to User — Xcode GUI Tasks

Direction: **agent → user**. The Claude agent operates inside Xcode and per `.claude/rules/xcode-agent-safety.md` must never write Xcode-managed files (workspace / scheme / pbxproj / testplan / Info.plist / entitlements / xcasset Contents.json). This doc lists the GUI steps you'll need to do as Phase 1 work lands.

## 1. Add `Packages/Libraries` to the workspace

After PR #2 (`feature/phase1-spm-scaffolding`) lands, the local Swift Package will exist at `Packages/Libraries/` but the workspace won't yet reference it.

1. Open `MicrobeLab.xcworkspace` in Xcode.
2. **File → Add Package Dependencies… → Add Local…** → navigate to `Packages/Libraries/` → **Add Package**.
3. When prompted, **add the `AppFeature` product to the `MicrobeLab` app target** (Target → General → Frameworks, Libraries, and Embedded Content → `+` → `AppFeature`).
4. Build (⌘B) to verify the package resolves and the app shell links against `AppFeature`.

After this, the workspace `contents.xcworkspacedata` will gain a `<FileRef location = "group:Packages/Libraries">` entry. Commit it; the workspace file is Xcode-generated and the agent does not need to write it.

## 2. Wire the app `@main` entry to `AppFeature`

After PR #2 + PR #10 (the AppFeature root view lands), edit `Apps/MicrobeLab/MicrobeLab/MicrobeLabApp.swift` to import + use the package root view. The agent can do this edit (it's an app-shell `.swift` file under a synchronized folder — safe to write per the rule).

The agent will land this change as part of PR #10 (`feature/phase1-gamification-onboarding`), after the `AppFeature.AppRootView` exists.

## 3. Info.plist additions (deferred — only when respective features land)

The agent cannot write `Info.plist`. When the following capabilities land, add the corresponding usage descriptions via Xcode's **target → Info tab**:

| Key | When | Suggested value |
|---|---|---|
| `NSCameraUsageDescription` | NEVER for Phase 1 (microscope is simulated; no real camera). Skip unless Phase 4+ AR microscope ships. | n/a |
| `NSMicrophoneUsageDescription` | If/when voice-input mentor lands (post Phase 2). | "MicrobeLab uses the microphone so you can ask Vee questions out loud." |
| `NSSpeechRecognitionUsageDescription` | Pair with mic per `warnings.md` rule. | "MicrobeLab uses speech recognition so Vee can hear your questions." |
| `NSLocalNetworkUsageDescription` | If/when classroom mode lands (Phase 4). | "MicrobeLab uses the local network to share microbiome discoveries with your classroom." |

Phase 1 needs **none** of these. The placeholder app shell is privacy-clean.

## 4. Asset catalog additions (mascot Vee + cast portraits)

Per `forgekit.md` § "Asset generation ownership", labsmith owns asset generation. The 12-microbe portrait pack lands via a labsmith handoff in `Resources/Cast/<slug>.webp` under the SPM package — agent can drop them in. **What requires GUI**:

- App icon (`AppIcon.appiconset`) — Phase 4 polish; not blocking Phase 1
- Accent color (`AccentColor.colorset`) — already Xcode-generated; agent will leave it alone

## 5. `.xctestplan` test target additions

When PR #2 lands the SPM test targets (`ModelsTests`, `ServicesTests`, `GameEngineTests`, `AIMentorTests`), add them to `MicrobeLab.xctestplan` via Xcode:

1. **Product → Scheme → Edit Scheme → Test → Test Plans → MicrobeLab.xctestplan**
2. In the test-plan editor, click **+** under **Tests** → select each SPM test target from the **Libraries** package
3. Save the test plan. Xcode rewrites the JSON — commit the diff

The agent will NOT write `MicrobeLab.xctestplan` from disk. Per `.claude/rules/xcode-agent-safety.md` § "Unsafe — DO NOT WRITE": hand-edited plan JSON corrupts; route through Xcode's GUI so Xcode regenerates the JSON cleanly.

## 6. Scheme edits (none in Phase 1)

The MicrobeLab scheme that Xcode auto-generated is sufficient for Phase 1. No agent edits needed; no GUI edits expected.

---

When this doc's tasks are done, this file moves to `Docs/archive/HANDOFF_TO_USER_XCODE_GUI_TASKS_DONE.md`. New GUI tasks accumulate here.
