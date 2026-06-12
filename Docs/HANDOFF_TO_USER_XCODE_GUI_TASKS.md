---
status: open
last-updated: 2026-06-12
last-reinforced: 2026-06-12 (user-direct **fifth pass** — paired with the standing auto-cycle directive for multi-commit work AND an explicit maximize-ForgeKit-integration + close-FEATURE_PLAN-checkboxes directive in the same round. Five restatements in one calendar day codifies the **five-pass invariant**: this rule is now a pre-flight check, not a guideline. The maximize-integration directive does NOT extend to managed-file edits — see CLAUDE.md § Xcode-managed file safety for the canonical statement.)
---

# Handoff to User — Xcode GUI Tasks

Direction: **agent → user**. The Claude agent operates inside Xcode and per `.claude/rules/xcode-agent-safety.md` + CLAUDE.md § "Xcode-managed file safety (reinforced 2026-06-12 — **fifth pass**, user-direct, auto-cycle round)" must never write the following Xcode-managed files from disk:

- `MicrobeLab.xcworkspace/contents.xcworkspacedata` (workspace membership)
- `MicrobeLab.xcodeproj/project.pbxproj` (project membership)
- `*.xcscheme` (anywhere — scheme JSON)
- `MicrobeLab.xctestplan` (test plan JSON)
- `MicrobeLab/Info.plist` (target capabilities)
- `*.entitlements` (capabilities)
- `*.xcassets/Contents.json` (asset catalog roots + per-imageset JSON)
- `xcuserdata/` (per-user Xcode state)
- `Package.resolved` (SPM resolution; Xcode re-resolves on workspace open)

**Staging + committing those files when Xcode regenerates them IS fine.** The prohibition is exclusively on authoring/editing the file content from disk. This doc lists the GUI steps you'll need to do as work lands.

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

## 6b. Declared Age Range API entitlement (deferred — pre-TestFlight)

Per `.claude/rules/age-assurance.md` § Declared Age Range API (iOS 26+), Apple's privacy-preserving age-range API requires the `com.apple.developer.declared-age-range` entitlement. The agent cannot write `.entitlements` files from disk (per § Unsafe — DO NOT WRITE).

`Services/AgeAssuranceService.swift` ships the scaffold today: the entitlement probe (`AgeAssuranceCapability.isDeclaredAgeRangeAvailable`) reads `Bundle.main`'s `Entitlements` dict and returns `false` until provisioning lands. `SettingsView` → About surfaces a passive readout ("Math gate — Apple gate pending entitlement" → flips to "Declared Age Range API ready" once you add it). ForgeKit's `ForgeSystemAgeGate` already implements the system call + math-gate fallback — once the entitlement is in place, a follow-up PR wires it into `ParentHandoffFlow`.

**To provision** (do once + commit Xcode regenerated diffs):

1. Open MicrobeLab.xcworkspace
2. Select the `MicrobeLab` app target → **Signing & Capabilities**
3. Click `+ Capability` → add **Declared Age Range** (iOS 26.2+)
4. Xcode regenerates `MicrobeLab/MicrobeLab.entitlements` with the new key; commit the file (staging Xcode-regenerated diffs IS fine per CLAUDE.md § Xcode-managed file safety — only authoring the file content from disk is prohibited)
5. **Critical pre-flight per `.claude/rules/age-assurance.md`** — receiving "Under 13" creates **COPPA actual knowledge**. Do NOT actually invoke `await requestAgeRange(...)` until annual re-consent + retention + COPPA records are in place. The current `AgeAssuranceService.requestSystemVerification(...)` is a stub that no-ops; replace the stub with the live call only when the consent surface ships.

Until provisioned, the existing math-based `ParentalGateView` is the parent verification path. The scaffold + passive readout let future sessions see the capability state at a glance.

## 7. Verifying SPM-only changes without Xcode reload

Per `.claude/rules/xcode-agent-safety.md` + CLAUDE.md's Xcode-managed-files warning, the agent verifies SPM changes via terminal `swift build` (no Xcode reload). Local commands:

```bash
swift build --package-path Packages/Libraries   # compile all 6 SPM targets + ForgeKit
swift test --package-path Packages/Libraries    # run all 4 SPM test targets (when supported)
```

The agent does NOT run `xcodebuild` for SPM verification — it forces Xcode workspace reload and can terminate the agent session.

---

When this doc's open tasks reach zero, this file moves to `Docs/archive/HANDOFF_TO_USER_XCODE_GUI_TASKS_DONE.md`. New GUI tasks accumulate here.
