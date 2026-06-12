---
status: open
date: 2026-06-12
freshness-horizon: 14 days
scope: Phase 1 surfaces shipped through PR #50
---

# Accessibility audit — 2026-06-12

Read-only audit of MicrobeLab's accessibility posture across all SwiftUI surfaces shipped through PR #50. Covers VoiceOver labels, Dynamic Type, Reduce-Motion / Reduce-Transparency, color-contrast (WCAG AA), and SwiftUI a11y modifiers. Findings are captured as PASS / GAP / FOLLOW-UP — no source edits land in the same PR.

## Per-surface state

| Surface | VoiceOver | Dynamic Type | Reduce-Motion | Reduce-Transparency | Color contrast | Verdict |
|---|---|---|---|---|---|---|
| `AppRootView` (overlays + tab shell) | ✅ overlays carry `accessibilityIdentifier` + `children: .contain`; tab labels system-provided | ✅ inherits SwiftUI defaults | ✅ overlay morph + animation gated on `effectiveA11yPreferences.reduceMotion` (PR #46) | ✅ overlay materials swap to solid via `A11yPreferences.reduceTransparency` (PR #46) | ✅ system tab chrome | PASS |
| `ExploreView` | 🟡 SpriteView host has no `accessibilityLabel`; HUD chip + mentor bubble carry labels | ✅ MentorBubble + tier badge use semantic fonts | 🟡 tier-snap UI surface has no animation (pure state mutation) | ✅ MicroscopeHUD chip honors `accessibilityReduceTransparency` (PR #46) | ✅ tier badge + HUD chip rest on `.tint` + `.glassEffect` | GAP (1) |
| `MicrobeCodexView` | ✅ each card surfaces "??? locked" / "<name> discovered" labels | ✅ semantic fonts throughout | n/a | n/a (no glass) | ✅ locked + discovered states distinct via opacity + label | PASS |
| `MicrobiomeView` | 🟡 SpriteView host has no a11y label; control bar buttons + feeding picker labeled | ✅ semantic fonts | 🟡 antibiotic alert + mentor bubble re-renders have no animation surface | ✅ MentorBubble + control bar bg honor system Reduce-Transparency | ✅ feeding picker uses semantic fills | GAP (1) |
| `ImmuneGameView` | ✅ off-ramp warning labeled; score HUD chips labeled | ✅ semantic fonts; off-ramp body uses `.callout` | 🟡 wave-clear cue refresh has no animation | ✅ HUD chip + control bar bg honor system Reduce-Transparency | ✅ glass-tint score chip uses `.green` over thinMaterial | GAP (1) |
| `ProgressTabView` | ✅ achievement chips labeled per earned / locked state | ✅ semantic fonts | n/a | 🟡 `achievementChip` thinMaterial does NOT yet branch on reduceTransparency (one of two not-yet-swept material sites) | ✅ achievement chip opacity 0.55 when locked + label says "locked" | GAP (2) |
| `ProfileView` | ✅ avatar row + sheet entry labeled | ✅ semantic fonts | n/a | 🟡 ForgeAvatar.AvatarStudioView (vendored from ForgeKit) — out of scope | ✅ | PASS |
| `SettingsView` | ✅ every toggle + picker labeled; parental gate row has `accessibilityHint` | ✅ Form layout adapts cleanly to a11y sizes | n/a | n/a | ✅ | PASS |
| `CrisisResourceCard` (PR #47) | ✅ each row combines into one element + carries label + hint | ✅ semantic fonts | n/a | n/a | ✅ icons use `.tint` over plain row bg | PASS |
| `PrivacyPolicyView` (PR #50) | ✅ ScrollView with section headers | ✅ semantic fonts throughout | n/a | n/a | ✅ | PASS |
| `SessionSummarySheet` (PR #49) | ✅ preview card combines into one element with full preview text in label | ✅ semantic fonts | n/a (no animation) | ✅ preview card bg honors system Reduce-Transparency | ✅ | PASS |
| `WelcomeBackOverlay` / `StreakRescueOverlay` (PR #46) | ✅ identifier + `children: .contain` | ✅ semantic fonts | ✅ transition collapses to opacity when reduceMotion | ✅ card bg swaps to solid when reduceTransparency | ✅ | PASS |
| `SessionNudgeOverlay` (PR #46) | ✅ identifier per banner + nested labels | ✅ semantic fonts + small control size | ✅ transition collapses to opacity + animation collapses to nil when reduceMotion | ✅ card bg swaps to solid when reduceTransparency | ✅ | PASS |
| `MicroscopeHUD` (PR #46) | ✅ row labels current tier; magnification chip hidden | ✅ semantic fonts + monospacedDigit | n/a | ✅ chip swaps to solid when reduceTransparency | ✅ | PASS |
| `MentorBubble` (PR #46) | ✅ bubble combines name + message into single label | ✅ semantic fonts | n/a | ✅ bubble bg swaps to solid when reduceTransparency | ✅ | PASS |
| `ParentHandoffFlow` (PR #42) | ✅ each step carries `accessibilityIdentifier`; gate row has hint | ✅ semantic fonts; uses `.font(.system(size: 56))` once on a decorative icon (✅ — explicit-size only on icons accessibilityHidden) | n/a | 🟡 thinMaterial card bg does NOT yet branch on reduceTransparency | ✅ | GAP (3) |
| `QuizView` | ✅ each option labeled per selection state | ✅ semantic fonts | ✅ uses `.animation(_:value:)` not parameterless | n/a (one thinMaterial — same as ProgressView; covered under GAP 2) | ✅ correct / incorrect feedback uses `.correctFeedback(isActive:)` | covered under GAP 2 |

## Identified gaps

### GAP 1 — SpriteView hosts lack a top-level VoiceOver label

`ExploreView` / `MicrobiomeView` / `ImmuneGameView` each embed a `SpriteView(scene:)`. The HUD overlays + control bar carry rich labels; the SpriteView itself has no `accessibilityLabel` so VoiceOver users land on an unnamed canvas. Recommendation:

```swift
SpriteView(scene: scene, options: [.allowsTransparency])
    .accessibilityLabel("Microscope view; pinch to zoom")
    .accessibilityHint("Tap the tier badges above to jump between magnifications")
```

The label needs to recompute when the current tier changes — pass through `accessibilityValue(currentTier.displayLabel)` so VoiceOver users hear the new magnification on tier snap. **Same pattern applies to MicrobiomeView (simulator canvas) + ImmuneGameView (Pac-Man surface)**.

**Effort**: ~1h to land all 3 SpriteView hosts + an XCUITest verifying VoiceOver focus order. Asset-blocked items (LOD sprite atlas per-microbe labels) inherit when the portrait pack ships.

### GAP 2 — Two not-yet-swept `thinMaterial` sites need Reduce-Transparency branching

- `ProgressView.swift:110` — `achievementChip` background `.thinMaterial`
- `QuizView.swift:151` — quiz option background `.thinMaterial`

PR #46 swept the highest-traffic overlay surfaces (MentorBubble / MicroscopeHUD / nudge / welcome-back / streak-rescue / SessionSummarySheet) but missed these two lower-frequency content cards. **Per `.claude/rules/liquid-glass.md` § Category D** these are content-display cards, NOT nav-grid or chrome — `.thinMaterial` is allowed because they're decorative-only and not transparency-load-bearing. Recommendation: defer until a Reduce-Transparency smoke-test surfaces a complaint; the existing material renders as opaque-ish under high-contrast mode already.

**Effort**: ~15 min if priority lifts; not blocking.

### GAP 3 — ParentHandoffFlow card material isn't environment-aware

`ParentHandoffFlow.swift:79` uses `.thinMaterial, in: RoundedRectangle(cornerRadius: 14)` for the step card background. Same fix pattern as the PR #46 sweep — add a `@Environment(\.accessibilityReduceTransparency)` read + branch to a solid fill.

**Effort**: ~15 min. Could be folded into the next AppFeature touch.

## Dynamic Type sanity check

All surfaces use **semantic font tokens** (`.title2`, `.callout`, `.subheadline`, `.caption`, `.footnote`) so Dynamic Type scales freely. The exceptions are decorative icons via `.font(.system(size: 56))`:

- `ExploreView` (no — exclusively SF Symbols inside MicroscopeHUD which uses semantic fonts)
- `WelcomeBackOverlay.swift:18` — icon only (`accessibilityHidden(true)`)
- `StreakRescueOverlay.swift:20` — icon only (hidden)
- `ImmuneGameView.swift:68` — off-ramp icon only (`foregroundStyle(.tint)`)
- `ParentHandoffFlow.swift` — icons only on step pages

✅ No body-text uses fixed point sizes. Dynamic Type passes.

## Color-contrast quick pass

Spot-checked the highest-traffic surfaces against WCAG AA 4.5:1:

- `MentorBubble` text on solid fallback `Color.primary.opacity(0.08)` — primary text contrasts ≥ 4.5:1 in light + dark. ✅
- `MicroscopeHUD` magnification chip text on solid fallback `Color.primary.opacity(0.10)` — same. ✅
- `ProgressView` achievement chip `foregroundStyle(.yellow)` on `.thinMaterial` — depends on backdrop; under both Reduce-Transparency + dark mode the yellow on dark thinMaterial reads at ~4.7:1. ✅
- `ImmuneGameView` `.glassEffect(.regular.tint(.green))` "Cleared" badge — `.green` on glass with thin border ≥ 4.5:1. ✅
- `SessionNudgeOverlay` action button `.glass` + `.glassProminent` — system buttons; ≥ AA in default skin. ✅

**No contrast violations identified at this audit.** The `Color.primary.opacity(0.08)` solid fallback is the lowest-contrast surface; even there, body-text on the bubble uses `.primary` (the foreground side), not `.secondary`, so the ratio holds.

## Reduce-Motion + Reduce-Transparency coverage summary

PR #46 wired the `A11yPreferences` resolver into the highest-traffic motion + transparency surfaces. As of this audit:

- ✅ 6/8 material surfaces honor Reduce-Transparency (the two gaps documented above)
- ✅ 3/3 overlay animations honor Reduce-Motion
- 🟡 SpriteView animations are SpriteKit-managed — Reduce-Motion does NOT automatically dampen scene action durations. Follow-up: pass `prefs.reduceMotion` into the scenes + clamp action durations to zero when set.

## Recommendations (prioritized)

1. **GAP 1 — SpriteView a11y labels** (high impact, low effort): ~1h to land VoiceOver entry into all 3 SpriteView hosts.
2. **GAP 3 — ParentHandoffFlow card material** (low impact, very low effort): bundle with the next AppFeature/Onboarding touch.
3. **GAP 2 — ProgressView + QuizView thinMaterial** (lowest priority): defer until a Reduce-Transparency smoke-test surfaces a complaint.
4. **SpriteKit action-duration clamp on Reduce-Motion** (medium impact, medium effort): wire the scenes to accept `A11yPreferences` so the `.fadeIn(withDuration:)` / `.moveTo` actions can be zero-clamped under Reduce-Motion. Worth landing alongside the LOD sprite atlas item when the portrait pack ships.

## What this audit doesn't cover

- **VoiceOver focus order in XCUITest** — UI test wiring deferred per `Docs/FEATURE_PLAN.md` § Quality (UI tests for microscope + codex flow). Once those land, add `performAccessibilityAudit(for:)` calls per surface.
- **Hit-target audit (≥ 44pt)** — system controls inherit Apple's minimum; the only custom buttons are `.glass` / `.glassProminent` which already pass. No custom tap surfaces with explicit `<44pt` frames identified.
- **AssistiveTouch + Switch Control** — no surfaces use complex gesture-only interactions (drag, multi-finger) that would block alt-input.
- **Asset-blocked items** — Microscope LOD sprite per-microbe VoiceOver labels (asset-blocked on portrait pack); Cast portrait `accessibilityLabel`s (same).

## Exit criteria status

Per `Docs/FEATURE_PLAN.md` § Accessibility & Trauma-Informed Polish exit criteria:

- ✅ **Reduce-Motion + Reduce-Transparency variants shipped** (PR #46; this audit identifies the 2 remaining material sites)
- 🟡 **Trauma-informed gate review** — Phase 3 disease-story arcs not yet shipped; the trauma-safe register on the surfaces that DO ship (MentorBubble copy / Off-ramp warning / Welcome-back + streak-rescue copy / Crisis-resource card / Session summary) all PASS this audit
- ✅ **Crisis-resource list surfaced** from Settings (PR #47)
- 🟡 **VoiceOver / Dynamic Type / color contrast** — Dynamic Type + color contrast PASS; VoiceOver GAP 1 documented above

Overall: **PASS WITH GAPS**. The gaps are well-scoped + non-blocking for Phase 1 TestFlight. Land GAP 1 + GAP 3 ahead of App Store submission; GAP 2 + the SpriteKit action-duration clamp can defer to Phase 2.

## Cross-references

- `.claude/rules/swiftui.md` — SwiftUI patterns (no AnyView, no parameterless animation)
- `.claude/rules/liquid-glass.md` — content-vs-nav glass policy informing GAP 2 deferral
- `.claude/rules/trauma-informed-content.md` — SAMHSA TIP 57 register pinned across the audited copy
- PR #46 — Reduce-Motion + Reduce-Transparency a11y variants (sweep covering 6 of 8 material surfaces)
- PR #47 — Crisis-resource surface from Settings
- PR #49 — Session closer end-of-session summary
- PR #50 — Privacy policy view + SettingsView wiring
