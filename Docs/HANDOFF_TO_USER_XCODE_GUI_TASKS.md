---
status: open
last-updated: 2026-06-12
---

# Handoff to User — Xcode GUI Tasks

Direction: **agent → user**. The Claude agent operates inside Xcode and per `.claude/rules/xcode-agent-safety.md` must never write Xcode-managed files (workspace / scheme / pbxproj / testplan / Info.plist / entitlements / xcasset Contents.json). Staging + committing those files when Xcode regenerates them IS fine. This doc lists the GUI steps you'll need to do as work lands.

## 1. ✅ Add `Packages/Libraries` to the workspace — DONE (PR #14)

The `Packages/Libraries` SPM package is wired into `MicrobeLab.xcworkspace`. All 6 targets (Models / Services / SharedUI / GameEngine / AIMentor / AppFeature) build and the `AppFeature` product is linked against the `MicrobeLab` app target.

## 2. ✅ Wire the app `@main` entry to `AppFeature` — DONE

`MicrobeLab/MicrobeLabApp.swift` imports + uses `AppRootView`.

## 3. Info.plist additions (deferred — only when respective features land)

The agent cannot write `Info.plist`. When the following capabilities land, add the corresponding usage descriptions via Xcode's **target → Info tab**:

| Key | When | Suggested value |
|---|---|---|
| `NSCameraUsageDescription` | NEVER for Phase 1 (microscope is simulated; no real camera). Skip unless Phase 4+ AR microscope ships. | n/a |
| `NSMicrophoneUsageDescription` | If/when voice-input mentor lands (post Phase 2). | "MicrobeLab uses the microphone so you can ask Cilia questions out loud." |
| `NSSpeechRecognitionUsageDescription` | Pair with mic per `warnings.md` rule. | "MicrobeLab uses speech recognition so Cilia can hear your questions." |
| `NSLocalNetworkUsageDescription` | If/when classroom mode lands (Phase 4). | "MicrobeLab uses the local network to share microbiome discoveries with your classroom." |

Phase 1 needs **none** of these. The current build is privacy-clean.

## 4. Asset catalog additions (mascot Cilia + cast portraits)

Per `forgekit.md` § "Asset generation ownership", labsmith owns asset generation. The 12-microbe portrait pack lands via a labsmith handoff in `Packages/Libraries/Sources/SharedUI/Resources/Cast/<slug>.webp` (path TBD with labsmith) — agent can drop the WebPs in place once they arrive. **What requires GUI**:

- App icon (`AppIcon.appiconset`) — Phase 4 polish; not blocking Phase 1
- Accent color (`AccentColor.colorset`) — already Xcode-generated; agent will leave it alone

## 5. ✅ `.xctestplan` test target additions — DONE (PR #14)

The four SPM test targets (`ModelsTests` / `ServicesTests` / `GameEngineTests` / `AIMentorTests`) are wired into `MicrobeLab.xctestplan` via `container:../../Packages/Libraries` references. Re-run Test (⌘U) in Xcode to confirm.

## 6. Scheme edits (none required)

The MicrobeLab scheme that Xcode auto-generated is sufficient. No agent edits needed; no GUI edits expected.

## 7. Verifying SPM-only changes without Xcode reload

Per `.claude/rules/xcode-agent-safety.md` + CLAUDE.md's Xcode-managed-files warning, the agent verifies SPM changes via terminal `swift build` (no Xcode reload). Local commands:

```bash
swift build --package-path Packages/Libraries   # compile all 6 SPM targets + ForgeKit
swift test --package-path Packages/Libraries    # run all 4 SPM test targets (when supported)
```

The agent does NOT run `xcodebuild` for SPM verification — it forces Xcode workspace reload and can terminate the agent session.

---

When this doc's open tasks reach zero, this file moves to `Docs/archive/HANDOFF_TO_USER_XCODE_GUI_TASKS_DONE.md`. New GUI tasks accumulate here.
