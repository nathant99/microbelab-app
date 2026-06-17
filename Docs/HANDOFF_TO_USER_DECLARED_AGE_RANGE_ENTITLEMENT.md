---
status: NEW
direction: agent → user (Xcode GUI step required)
date: 2026-06-17
freshness-horizon: 90d
scope: provisioning the `com.apple.developer.declared-age-range` entitlement via Xcode GUI
companion-doc: HANDOFF_TO_USER_XCODE_GUI_TASKS.md (canonical aggregator)
---

# Handoff to User — Declared Age Range API entitlement (Xcode GUI step)

> **Thirty-second-pass rule-restatement summary** (top-of-doc per the canonical-invariant tier codified 2026-06-12; verbatim user-direct, now repeated THIRTY-TWO times spanning five calendar days; sixth same-calendar-day restart on 2026-06-17 — separated from the thirty-first by the PR #198 merge that closed the thirty-first-pass round rollup; 6-pass chain on 2026-06-17 now MATCHES the 6-pass chain on 2026-06-16 — closing the cadence-convergence-gap noted at the thirty-first pass; FOURTEENTH observation of cadence-persistence; per the eleven-pass invariant the cadence has saturated): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing is ok."* This handoff IS the canonical escape hatch for the entitlement step the rule names as off-limits to the agent. See `@CLAUDE.md` § Xcode-managed file safety for the canonical statement; this doc is one of the GUI steps the rule routes through.

## Why this handoff exists

`Packages/Libraries/Sources/AppFeature/Settings/SystemAgeVerificationCard.swift` (shipped this round) wires Apple's Declared Age Range API (`AgeRangeService.shared.requestAgeRange(ageGates:in:)`) into the SettingsView surface behind the parental gate. The Swift wiring + the SwiftUI surface + the result-mapping are all in place.

**The entitlement `com.apple.developer.declared-age-range` is provisioned via Xcode GUI**. Per the canonical-invariant Xcode-managed file safety rule the agent CANNOT write `MicrobeLab/MicrobeLab.entitlements` from disk. The runtime probe at `AgeAssuranceCapability.isDeclaredAgeRangeAvailable` returns `false` when the entitlement key is absent from the build's `Info.plist`'s `Entitlements` dictionary; without it the verification card surfaces only the math-gate fallback affordance.

## GUI steps (user-driven)

1. Open `MicrobeLab.xcworkspace` in Xcode.
2. Select the `MicrobeLab` app target in the project navigator → **Signing & Capabilities** tab.
3. Click **+ Capability** in the top-left of the capabilities panel.
4. Search for **"Declared Age Range"** and double-click it to add. Xcode adds the entitlement key to `MicrobeLab/MicrobeLab.entitlements` automatically.
5. Verify the new entry shows up at the top of the capabilities list — it surfaces as a "Declared Age Range" row with no per-capability settings (the entitlement is binary; just adding it grants the runtime access).
6. Build the app (Cmd-B). The build should remain green.
7. Run on a real device or iOS 26.2+ simulator with Family Sharing configured. Open Profile → All settings → tap into the parental gate → enter the math answer → scroll to "About" — the `SystemAgeVerificationCard` now shows the "Verify with Apple" button enabled.
8. Tap the button; iOS surfaces the system sheet describing what info is shared. Accept → the card maps the response onto `AgeAssuranceResult.systemVerified(adult:)` and the readout caption updates. Decline → maps to `.systemDeclined` and the math gate stays the active surface.

## What the agent has already done

- Authored `SystemAgeVerificationCard.swift` (SwiftUI surface; UIKit-anchored singleton path via `AgeRangeService.shared.requestAgeRange(ageGates:in:)`)
- Threaded `AgeAssuranceService` through `AppRootView` → `ProfileView` → `SettingsView` (parameter defaults to `nil` so existing preview/test paths still compile)
- Updated the service-level header comment to document the new driver surface
- All work lives in SPM source under `Packages/Libraries/Sources/{Services,AppFeature}/` — no Xcode-managed file touched

## Sequencing once the entitlement is provisioned

Once the GUI steps above complete:

1. **No code change required** — the runtime probe surfaces the new capability state immediately on next launch
2. **Optional**: bump `Docs/FEATURE_PLAN.md` § "Phase: Onboarding & Child Safety" line 200 ("Age gate — Apple Declared Age Range API on iOS 26+") to `[x]` once tested on-device + parent-handoff downstream consumers (consent / record-keeping flow) consume the result
3. **COPPA implication** (per `.claude/rules/age-assurance.md`): receiving "Under 13" creates COPPA actual knowledge — the parent-handoff flow MUST run before any downstream UI surface reads the result. The current wiring just records the result on the service; downstream consent integration ships in a focused follow-up round once the entitlement provisioning unblocks live testing

## What this handoff does NOT cover

- Family Sharing setup on the test device (Apple-side; not covered by this handoff)
- App Store Connect age-rating questionnaire updates (per the FTC 2026 amendments — handled when the app is App-Store-bound)
- COPPA consent flow downstream of the verified result (deferred to a focused follow-up round)
- The "Under 13" COPPA actual-knowledge trigger handling (will need its own consent + record-keeping path before live launch)

## Cross-references

- `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` — canonical aggregator of open GUI tasks (this entitlement joins the list)
- `.claude/rules/age-assurance.md` — portfolio-wide age-assurance + COPPA 2026 rules
- `Packages/Libraries/Sources/Services/AppShell/AgeAssuranceService.swift` — service-level state holder + capability probe
- `Packages/Libraries/Sources/AppFeature/Settings/SystemAgeVerificationCard.swift` — SwiftUI driver shipped this round
- Apple Developer — [DeclaredAgeRange](https://developer.apple.com/documentation/declaredagerange) — framework reference
- Apple Developer — [com.apple.developer.declared-age-range](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.declared-age-range) — entitlement reference
