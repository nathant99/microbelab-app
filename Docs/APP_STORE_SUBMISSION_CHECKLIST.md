---
status: scaffold
last-updated: 2026-06-17
last-reviewed: 2026-06-17
freshness-horizon: 14 days
round: twenty-ninth-pass auto-cycle round (third same-calendar-day restart on 2026-06-17)
---

> **Twenty-ninth-pass rule-restatement summary** (top-of-doc per the canonical-invariant tier codified 2026-06-12; verbatim user-direct, now repeated TWENTY-NINE times spanning five calendar days): *"critical: do not author/edit xcode-managed files including Xcode workspace file and Xcode scheme/test plan file. Instead, file a handoff doc with the user to do Xcode UI work. staging and committing is ok."* Scope: `*.xcworkspace/contents.xcworkspacedata` / `*.xcodeproj/project.pbxproj` / `*.xcscheme` / `*.xctestplan` / `Info.plist` / `*.entitlements` / `*.xcassets/Contents.json` / `xcuserdata/` / `Package.resolved`. Every checkbox in this doc that conceptually requires a managed-file edit ships via `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` describing the Xcode GUI steps.

# App Store Submission Checklist — MicrobeLab

Maps Phase 4 line 184 ("App Store submission preparation: privacy nutrition label / KIDSAFE plan / parental gates") to a structured pre-submission checklist. Cross-references the shipped surface area in `@Docs/FEATURE_PLAN.md` + `@Docs/IMPLEMENTATION_HANDOFF.md` + `@CLAUDE.md` so the implementing session has a single load-bearing artifact at submission time.

Submission-asset-axis items (screenshots / preview videos / app icon variants) live separately under FEATURE_PLAN.md line 185 — those are asset-blocked per `.claude/rules/forgekit.md` § Asset generation ownership (labsmith owns ALL portfolio asset generation). This doc covers the **metadata + compliance + parental-gate** axes only.

## 1. Privacy Nutrition Label (App Privacy on App Store Connect)

Per Apple's App Privacy framework — every shipped data-collection point declared, plus opt-in vs required + linked-to-user vs not-linked. MicrobeLab's portfolio posture per `.claude/rules/age-assurance.md` § Portfolio Status: **no PII collection, no third-party analytics, no advertising**. The nutrition label declares EVERY local store anyway because Apple's "data the app collects" definition includes on-device data used for features (not just data sent to a server).

### Per-data-type matrix

| Data type (Apple's taxonomy) | Used by MicrobeLab? | Storage | Linked to user? | Used for tracking? | Notes |
|---|---|---|---|---|---|
| **Contact Info** (name / email / phone / postal address) | ❌ | n/a | n/a | n/a | No account system. `displayName` for the kid is an arbitrary alias chosen during onboarding; not contact info |
| **Health & Fitness** | ❌ | n/a | n/a | n/a | No HealthKit; no fitness data |
| **Financial Info** | ❌ | n/a | n/a | n/a | No IAP; no payment data |
| **Location** | ❌ | n/a | n/a | n/a | No CoreLocation usage |
| **Sensitive Info** (race / sexual orientation / religious beliefs / etc.) | ❌ | n/a | n/a | n/a | Disease-story arcs avoid sensitive demographic content per the trauma-informed-content rule |
| **Contacts** | ❌ | n/a | n/a | n/a | No `CNContactStore` access |
| **User Content** (emails / messages / photos / videos / audio / customer support / gameplay content / other user content) | ✅ — **gameplay content** | SwiftData (local) | NO | NO | `PersistentMicrobeSession` + `EncounterLog` + `JournalEntry` (kid's reflection text, opt-in via session-close affordance per FEATURE_PLAN line 250). On-device only; never sent to a server |
| **Search History** | ❌ | n/a | n/a | n/a | No search bar surface in v1 |
| **Identifiers** (user ID / device ID / etc.) | ❌ | n/a | n/a | n/a | No advertising ID; no third-party analytics ID |
| **Purchases** | ❌ | n/a | n/a | n/a | No IAP |
| **Usage Data** (product interaction / advertising data / etc.) | ✅ — **product interaction** | UserDefaults (local) | NO | NO | `SessionCountStore` (monotonic counter), `RetentionMetricsStore` (D1/D7/D30 cohort signal), `QuestionAttemptStore` (per-question correctness log). On-device only; counts + UUIDs + slugs + booleans; never sent to a server |
| **Diagnostics** (crash data / performance data / other diagnostic data) | ✅ — **crash data + performance data** | MetricKit (system-managed) | NO | NO | TECHNICAL_DESIGN line 178 cites MetricKit usage; no third-party crash SDK. Apple's MetricKit ships crash + performance reports to Apple's servers per the OS-level opt-in (not the app's responsibility to declare separately) |
| **Other Data** | ❌ | n/a | n/a | n/a | None |

### Required submission steps

- [ ] In App Store Connect → MicrobeLab → App Privacy → fill out **Data Types** matrix using the table above
- [ ] For **User Content (gameplay content)** AND **Usage Data (product interaction)**:
    - Check ✅ "Data Not Linked to You" (no user ID; no linkage)
    - Check ✅ "Not Used for Tracking" (no cross-app/website tracking)
    - Purpose: **App Functionality** (gameplay state persistence + adaptive difficulty + parental progress reports — all on-device features)
- [ ] For **Diagnostics**:
    - Check ✅ "Data Not Linked to You" (MetricKit ships anonymized to Apple)
    - Check ✅ "Not Used for Tracking"
    - Purpose: **App Functionality** + **Analytics** (own analytics only — improving app stability)
- [ ] Submit the privacy nutrition label BEFORE the first TestFlight build per Apple's policy (the label is per-app, not per-build)

### Cross-references for the nutrition label

- `@.claude/rules/age-assurance.md` § Portfolio Status — portfolio-canonical "no PII, no third-party analytics, no advertising" posture
- `@Docs/TECHNICAL_DESIGN.md` § "Child Safety & Privacy Architecture" — per-channel data classification table
- `@Docs/PRIVACY_POLICY.md` — plain-language policy linked from the App Store listing
- `Packages/Libraries/Sources/Services/Engagement/*.swift` — all on-device stores; grep for UserDefaults keys + JSONDecoder calls to verify completeness

## 2. KIDSAFE / Apple Kids Category positioning

### Apple Kids Category requirements (Ages 9-12 band per the app's NGSS MS-LS1 target)

Per Apple's App Review Guidelines § 1.3 (Kids Category) + § 5.1.4 (Kids):

| Requirement | Current status | Reference / shipped surface |
|---|---|---|
| **No third-party advertising** | ✅ PASS | `.claude/rules/age-assurance.md` § Portfolio Status — no ad SDKs |
| **No third-party analytics** | ✅ PASS | TECHNICAL_DESIGN line 180 — "no Firebase, no Mixpanel, no Amplitude" |
| **No links out of the app without a parental gate** | ✅ PASS | `CrisisResourceCard` deep-links via `tel:` / `sms:` are gated behind the `.externalLinks` `ParentalConsentService` record (FEATURE_PLAN line 203) |
| **No requests for personal information from kids without verifiable parental consent** | ✅ PASS | No personal info requested. Display name is an arbitrary alias |
| **In-app purchases (if any) gated behind parental gate** | ✅ N/A | No IAP |
| **App must comply with COPPA + GDPR-K + applicable child privacy laws** | ✅ PASS at code-tier | See § 3 below for the COPPA / FTC 2026 verification list |
| **Age-appropriate content** | ✅ PASS | Trauma-informed posture documented in TECHNICAL_DESIGN line 184 onward + reviewer-blocked content gated behind `ADR-016` per ADR-019 |

### Required submission steps

- [ ] App Store Connect → MicrobeLab → App Information → **Age Rating** → answer Apple's questionnaire:
    - Cartoon or Fantasy Violence: **None** (innate immune Pac-Man framed as "your body's quiet helpers", not warfare per TECHNICAL_DESIGN line 189)
    - Realistic Violence: **None**
    - Sexual Content or Nudity: **None**
    - Profanity or Crude Humor: **None**
    - Alcohol, Tobacco, or Drug Use: **None**
    - Mature/Suggestive Themes: **None**
    - Horror/Fear Themes: **None**
    - Medical/Treatment Information: **Infrequent/Mild** (disease-story arcs ship behind reviewer-signoff + parental consent gate per ADR-016)
    - Gambling: **None**
    - Unrestricted Web Access: **None**
    - **AI-generated content frequency** (FTC 2026 disclosure requirement, see § 3): **Infrequent/Mild** (FoundationModels on-device for Vee Socratic prompts; everything ships with curriculum-guarded static fallbacks per `.claude/rules/foundationmodels.md`)
- [ ] App Store Connect → MicrobeLab → App Information → **Primary Category**: **Education**; **Secondary Category**: **Kids** (locks in Kids Category submission requirements)
- [ ] App Store Connect → MicrobeLab → App Information → **Age Range**: **9-11** (matches NGSS MS-LS target; per the per-app handoff `Docs/HANDOFF_FROM_LABSMITH_DISTRIBUTED_NARRATIVE_RETROFIT.md` ages 9-14)

## 3. COPPA + FTC 2026 + state-law compliance verification

Per `.claude/rules/age-assurance.md` § 2026 FTC COPPA Rule Amendments (effective April 22 2026):

| Requirement | Current status | Verification point |
|---|---|---|
| **Opt-in consent for targeted ads** | ✅ N/A (no ads, no targeted ads) | `.claude/rules/age-assurance.md` § Portfolio Status |
| **Data retention limits — defined purpose + timeframe for any personal info** | ✅ PASS | `ParentalConsentService` records have a 365-day expiry per `Packages/Libraries/Sources/Services/Engagement/ParentalConsentService.swift` (FEATURE_PLAN line 201); SwiftData persistence is local-only — no cloud sync of any kid data |
| **Written security program (documented)** | 🟡 BLOCK on first submission | Need: a short `Docs/SECURITY_PROGRAM.md` describing the on-device security posture (Keychain unused for v1, SwiftData encrypted-at-rest via system-managed full-disk encryption, no network egress except FoundationModels which runs on-device). Author in a focused follow-up round |
| **Safe Harbor transparency (if member of a Safe Harbor program)** | ⏸️ N/A | Not currently a member of a Safe Harbor program. iKeepSafe / Common Sense Privacy Seal / KIDSAFE certifications are aspirational v2+ goals per `.claude/rules/spark-anvil-website.md` § COPPA + trust signal requirements |
| **Apple Declared Age Range API (iOS 26.2+) — receiving "Under 13" creates COPPA actual knowledge** | 🟡 SCAFFOLDED | `Services/AgeAssuranceService` ships the scaffold (FEATURE_PLAN line 112); `requestSystemVerification(...)` is a no-op stub until the entitlement lands per `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6b — the entitlement provisioning is a managed-file edit so it routes through the GUI handoff per the canonical-invariant tier |
| **PermissionKit for significant changes** | ⏸️ Future | Not required at v1 ship; surfaces if MicrobeLab introduces a significant new feature post-launch |
| **State law — Utah (May 6 2026)** + **Louisiana (Jul 1 2026)** | ✅ PASS via portfolio posture | No PII collection means no state-specific opt-ins needed at the kid surface; parental consent records satisfy the federal COPPA + state-law overlay |

### Required submission steps

- [ ] Verify `Services/AgeAssuranceService` ships in stub form (the live `requestSystemVerification` is gated on the entitlement landing per the GUI handoff)
- [ ] Verify `ParentalConsentService` ships with the 4 canonical kinds (`diseaseStoryArcs` / `weeklySummaryNotifications` / `externalLinks` / `classroomMode`) wired through Settings → For parents (FEATURE_PLAN line 201)
- [ ] Verify the 365-day re-consent flow surfaces calmly via the "Needs reconfirm" section (FEATURE_PLAN line 201)
- [ ] Author `Docs/SECURITY_PROGRAM.md` in a focused follow-up round per the table above — covers FTC 2026 written-security-program requirement
- [ ] App Store Connect → MicrobeLab → App Information → confirm the privacy policy URL points to `Docs/PRIVACY_POLICY.md` published to the spark-and-anvil.com website (or to a `microbelab.com` subdomain if separately set up)

## 4. Parental Gates — cross-reference table

Per `.claude/rules/age-assurance.md` § PermissionKit + `@CLAUDE.md` portfolio posture + Apple Kids Category § 1.3.

| Surface | Gate type | Shipped? | Reference |
|---|---|---|---|
| Settings → For parents section | `ParentalGateView` math gate | ✅ | `Packages/Libraries/Sources/AppFeature/Settings/ParentalGateView.swift` |
| Parent handoff onboarding flow | Pre-kid-onboarding 4-step ~30s flow | ✅ | `MicrobeLabOnboardingFlow.swift` + `ParentHandoffFlow.swift` (FEATURE_PLAN line 111) |
| Disease-story arc opt-in | `ParentalConsentService` `.diseaseStoryArcs` consent record | ✅ | `ParentalConsentService.swift` (FEATURE_PLAN line 201) |
| Weekly-summary notifications | `ParentalConsentService` `.weeklySummaryNotifications` consent record + system notification authorization | ✅ | `WeeklySummaryService.swift` (FEATURE_PLAN line 249) |
| Crisis-resource `tel:` / `sms:` deep links | `ParentalConsentService` `.externalLinks` consent record | ✅ | `CrisisResourceCard.swift` (FEATURE_PLAN line 203 + 262) |
| Classroom mode (Phase 4) | `ParentalConsentService` `.classroomMode` consent record | ⏸️ entitlement-blocked | Awaiting ForgeKit 0.94+ ForgeClassroom wiring + LiveKit microphone entitlement provisioning per `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` (FEATURE_PLAN line 182) |
| Daily session cap | `AppSettings.dailySessionCap` parent-set; non-blocking warm wrap-up at the cap | ✅ | `DailyTimeCoordinator.swift` + `DailyCapOverlay.swift` (FEATURE_PLAN line 248) |

### Required verification steps

- [ ] Manually exercise the parental gate by selecting a "For parents" surface from Settings; verify the math gate fires + the "For parents" Form renders behind a successful answer
- [ ] Manually exercise the parent handoff flow on a fresh install (delete-and-reinstall on the simulator); verify the 4-step flow surfaces BEFORE the kid-facing onboarding flow per `AppRootView`
- [ ] Verify all 4 canonical `ParentalConsentKind` rows are present in `ParentalConsentManagerView` (FEATURE_PLAN line 201)

## 5. TestFlight rollout plan

| Wave | Audience | Gate before next wave | Notes |
|---|---|---|---|
| **Internal (Wave 0)** | Spark & Anvil team | Manual smoke-test of: First 60 Seconds aha moment (TECHNICAL_DESIGN line 160) + microbiome simulator stability (Phase 1 exit criteria FEATURE_PLAN line 124) + immune Pac-Man playable end-to-end + 4 question kits all open | Pre-blocker checks per the FEATURE_PLAN Phase 1 exit-criteria list |
| **Family + close-circle beta (Wave 1)** | 5-10 testers; parent + kid | 2+ weeks of data-collection on: D1/D7 retention via `RetentionMetricsStore`; daily session cap engagement via `DailyTimeCoordinator`; parental gate friction (anecdotal); FoundationModels availability variance (per `.claude/rules/foundationmodels.md` device-eligibility states) | Telemetry-light; counts only per portfolio posture |
| **Educator beta (Wave 2)** | 5-10 educators per the AdventureHub Life Zone cluster | NGSS standards-mapping signoff via `ProgressReportView` (`ProgressReportService.phase1Standards` etc.); reviewer signal on the trauma-informed posture per `.claude/rules/trauma-informed-content.md` | Aspirational — coordinates with the broader Spark & Anvil portfolio TestFlight schedule |
| **App Store v1 launch** | Public | Cumulative wave-0/1/2 signoff + Apple Kids Category submission accepted | Coordinates with hub-side `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` integration if AdventureHub gates the launch |

### Required steps

- [ ] App Store Connect → MicrobeLab → TestFlight → create Internal group
- [ ] Author `Docs/TESTFLIGHT_BETA_BRIEF.md` for the Family + Educator waves (defer to a focused round closer to TestFlight)
- [ ] Confirm `RetentionMetricsStore` D1 / D7 / D30 derivations are surfacing in the parent-facing progress dashboard if the educator-facing surface needs the same data (per ProgressReportService extensions)

## 6. Submission-blockers (cross-referenced)

The following items MUST land or be explicitly waived before the first App Store submission:

| Item | Status | Blocker | Reference |
|---|---|---|---|
| Privacy nutrition label filled out per § 1 | ⏸️ Awaiting submission action | None | This doc § 1 |
| Apple Kids Category questionnaire answered per § 2 | ⏸️ Awaiting submission action | None | This doc § 2 |
| `Docs/SECURITY_PROGRAM.md` authored | ⏸️ Pending | Author in a follow-up round | § 3 |
| `Docs/PRIVACY_POLICY.md` URL published | ✅ PASS doc-axis (in-app surface shipped); publishing to web TBD | website wave | FEATURE_PLAN line 202 |
| `Services/AgeAssuranceService` entitlement provisioned | 🟡 Routes through `Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` § 6b per the canonical-invariant tier | User-direct GUI task | FEATURE_PLAN line 112 |
| Custom microbe portrait pack (12 portraits) | 🟡 asset-blocked on labsmith pipeline | labsmith asset wave | FEATURE_PLAN line 65 |
| LOD sprite atlas + per-tier sprite swap | 🟡 asset-blocked | labsmith asset wave (same as portrait pack) | FEATURE_PLAN line 39 |
| App Store screenshot + preview-video assets | 🟡 asset-blocked | labsmith asset wave OR Apple Design Award candidate cinematography | FEATURE_PLAN line 185 |
| Hub-side ForgeAdventure Life Zone wiring | 🟡 labsmith-blocked | Awaiting `ZoneID.lifeZone` case in ForgeKit + AdventureHub orchestration | `HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` (filed Round 8) |

## 7. What this doc does NOT cover

- **Marketing copy** (app description, keywords, promotional text) — drafts when the asset pack is in hand so the copy matches the rendered hero screenshots
- **Localization beyond en-US** — v1 ships en-US only; portfolio localization patterns per `.claude/rules/localization.md` apply when secondary locales are added
- **Asset generation** — see `.claude/rules/forgekit.md` § Asset generation ownership (labsmith owns ALL portfolio asset generation)
- **AdventureHub / hub-side integration** — see `Docs/HANDOFF_FROM_APP_FORGEADVENTURE_LIFE_ZONE_PROPOSAL.md` + `Docs/HANDOFF_FROM_LABSMITH_FORGEKIT_BOOTSTRAP.md`
- **Server-side infrastructure** — MicrobeLab v1 has no server component (no `<App>Server/` directory)

## 8. Cross-references

- `@Docs/FEATURE_PLAN.md` — phased delivery roadmap (this checklist closes the doc-axis half of Phase 4 line 184)
- `@Docs/IMPLEMENTATION_HANDOFF.md` — round-by-round shipping log
- `@Docs/TECHNICAL_DESIGN.md` — architecture + on-device privacy posture
- `@Docs/PRIVACY_POLICY.md` — plain-language privacy policy (in-app surface + App Store listing)
- `@Docs/HANDOFF_TO_USER_XCODE_GUI_TASKS.md` — Xcode-managed file changes (entitlements + Info.plist additions) routed via the GUI
- `@.claude/rules/age-assurance.md` — COPPA + FTC 2026 + state-law portfolio posture
- `@.claude/rules/trauma-informed-content.md` — SAMHSA TIP 57 register + ADR-016 trauma-gated story-axis approval
- `@.claude/rules/forgekit.md` § Asset generation ownership — labsmith owns ALL portfolio asset generation
- `@.claude/rules/spark-anvil-website.md` § COPPA + trust signal requirements — website-side messaging
- `@CLAUDE.md` § Xcode-managed file safety — canonical-invariant tier safety rule (twenty-nine restatements across 2026-06-12 → 2026-06-17)
