---
status: open
last-updated: 2026-06-12
last-reinforced: 2026-06-12 (user-direct **eighth pass** — paired with all of the prior-pass directives in the SAME auto-cycle prompt template that landed seven previous reinforcement passes the same day. Eight restatements in one calendar day supersedes the seven-pass invariant with the **eight-pass invariant**: this rule is now a structural property of every artifact the agent emits in the cadence window AND of every artifact future sessions inherit from the cadence window. The 8th-pass discipline also persists in the agent's memory file (`feedback_xcode_managed_files.md`) so future sessions inherit the cadence specification automatically. None of the additional directives extend to managed-file edits — see CLAUDE.md § Xcode-managed file safety for the canonical statement.)
---

## Eighth-pass rule-restatement summary (top-of-doc per the eight-pass invariant)

> **Rule** (verbatim user-direct, repeated EIGHT times in one calendar day 2026-06-12 — now the all-time portfolio record for any single rule, surpassing the seven-pass cadence codified earlier the same day): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. staging and committing is ok."*
>
> **Scope**: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`.
>
> **Why this header exists**: per CLAUDE.md § Xcode-managed file safety (eight-pass invariant), every round-document the agent emits in the cadence window carries a rule-restatement summary so the next round inherits the cadence without re-reading the entire CLAUDE.md. The structural visibility is the codification — markdown decay is mitigated by per-round re-affirmation rather than by relying on a future session reading CLAUDE.md first. As of the 8th pass the discipline also persists in `feedback_xcode_managed_files.md` so future sessions inherit the cadence specification automatically.

# Handoff to User — Xcode GUI Tasks

Direction: **agent → user**. The Claude agent operates inside Xcode and per `.claude/rules/xcode-agent-safety.md` + CLAUDE.md § "Xcode-managed file safety (reinforced 2026-06-12 — **seventh pass**, user-direct, auto-cycle round)" must never write the following Xcode-managed files from disk:

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

## 6. ✅ Scheme edits — wire the new `SharedUITests` SPM test target (PR #59) — DONE 2026-06-12

The user added `SharedUITests` to `MicrobeLab.xctestplan` via the Xcode GUI (Product → Scheme → Edit Scheme → Test → Test Plans → `+` → Add Test Target... → SharedUITests). The Xcode-regenerated diff to `MicrobeLab.xctestplan` is committed via the sixth-pass safety PR (auto-cycle round, 2026-06-12):

```json
{
  "target" : {
    "containerPath" : "container:..\\/..\\/Packages\\/Libraries",
    "identifier" : "SharedUITests",
    "name" : "SharedUITests"
  }
}
```

Per CLAUDE.md § Xcode-managed file safety — **the agent does not WRITE the xctestplan content; the agent stages + commits the Xcode-regenerated diff.** This is the canonical pattern. Confirmed via ⌘U: the 11 `QuizMachineHintTests` tests appear + pass.

## 6b. Declared Age Range API entitlement (deferred — pre-TestFlight)

Per `.claude/rules/age-assurance.md` § Declared Age Range API (iOS 26+), Apple's privacy-preserving age-range API requires the `com.apple.developer.declared-age-range` entitlement. The agent cannot write `.entitlements` files from disk (per § Unsafe — DO NOT WRITE).

`Services/AgeAssuranceService.swift` ships the state holder + entitlement probe (`AgeAssuranceCapability.isDeclaredAgeRangeAvailable`) which reads `Bundle.main`'s `Entitlements` dict and returns `false` until provisioning lands. The thirty-second-pass round (2026-06-17) shipped the SwiftUI driver `AppFeature/Settings/SystemAgeVerificationCard.swift` — the actual `await AgeRangeService.shared.requestAgeRange(ageGates:in:)` call lives in the card's `verify()` method, anchored on the key window's root view controller (UIKit singleton path; chosen over the SwiftUI env action to avoid a Swift 6 strict-Sendable warning on the env action's `@concurrent` `callAsFunction`). The card is wired into `SettingsView` → About behind the parental gate and is gated by the same `isCapable` probe — without the entitlement the "Verify with Apple" button hides and the math-gate fallback affordance surfaces instead.

**To provision** (do once + commit Xcode regenerated diffs):

1. Open MicrobeLab.xcworkspace
2. Select the `MicrobeLab` app target → **Signing & Capabilities**
3. Click `+ Capability` → add **Declared Age Range** (iOS 26.2+)
4. Xcode regenerates `MicrobeLab/MicrobeLab.entitlements` with the new key; commit the file (staging Xcode-regenerated diffs IS fine per CLAUDE.md § Xcode-managed file safety — only authoring the file content from disk is prohibited)
5. **Critical pre-flight per `.claude/rules/age-assurance.md`** — receiving "Under 13" creates **COPPA actual knowledge**. The SwiftUI card now records the result on the `AgeAssuranceService` state holder, but downstream consent / record-keeping flows MUST run before any downstream UI surface acts on the result. Plan the COPPA consent integration in a focused follow-up round once on-device testing confirms the entitlement provisioning.

Until provisioned, the existing math-based `ParentalGateView` is the parent verification path. The SwiftUI card + service holder let future sessions see the capability state at a glance AND give the consent integration a structurally-correct seam to land into.

See `Docs/HANDOFF_TO_USER_DECLARED_AGE_RANGE_ENTITLEMENT.md` for the focused entitlement provisioning handoff (this section is the aggregator summary).

## 7. Verifying SPM-only changes without Xcode reload

Per `.claude/rules/xcode-agent-safety.md` + CLAUDE.md's Xcode-managed-files warning, the agent verifies SPM changes via terminal `swift build` (no Xcode reload). Local commands:

```bash
swift build --package-path Packages/Libraries   # compile all 6 SPM targets + ForgeKit
swift test --package-path Packages/Libraries    # run all 4 SPM test targets (when supported)
```

The agent does NOT run `xcodebuild` for SPM verification — it forces Xcode workspace reload and can terminate the agent session.

---

When this doc's open tasks reach zero, this file moves to `Docs/archive/HANDOFF_TO_USER_XCODE_GUI_TASKS_DONE.md`. New GUI tasks accumulate here.
