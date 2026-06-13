import SwiftUI
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// 4-tab `TabView` shell per portfolio convention + `Docs/TECHNICAL_DESIGN.md`
/// § Home Screen & Navigation.
///
/// Bootstraps the cast catalog from the bundled JSON. On load failure the
/// shell falls back to a diagnostic view so the kid never sees a blank
/// screen + the issue gets surfaced via `DebugLog.error`.
public struct AppRootView: View {
    @State private var catalog: MicrobeCatalogService?
    @State private var loadError: String?
    @State private var streakStore = StreakStore()
    @State private var gamification: GamificationService
    @State private var onboarding = OnboardingStore()
    @State private var parentHandoff = ParentHandoffStore()
    @State private var settingsStore = AppSettingsStore()
    @State private var lastActive = LastActiveStore()
    @State private var sessionCount = SessionCountStore()
    @State private var retention = RetentionMetricsStore()
    @State private var sessionTarget = SessionTargetService()
    /// Active tab in `tabShell`. Defaults to `.explore` so cold launches
    /// land on the microscope canvas. App Intents (Siri / Spotlight /
    /// Shortcuts) drive this via `NavigationCoordinator.shared` — the
    /// `.onChange(of: navigationCoordinator.requestedTab)` observer below
    /// applies the request and clears it so the same intent can re-fire
    /// later.
    @State private var selectedTab: MicrobeLabTab = .explore
    /// Single MainActor-isolated coordinator that brokers App Intent →
    /// tab-switch requests. `@Observable`-backed so SwiftUI tracks
    /// changes automatically. Per `Services.NavigationCoordinator` +
    /// AppFeature `Intents/`.
    private let navigationCoordinator: NavigationCoordinator = .shared
    @State private var welcomeBackDaysAway: Int?
    @State private var streakRescue: StreakRescue = .none
    @State private var celebration = CelebrationCoordinator()
    @State private var dailyTime: DailyTimeCoordinator
    @State private var showDailyCapOverlay: Bool = false
    // On-device privacy-first analytics. Per CLAUDE.md § ForgeAnalytics +
    // .claude/rules/age-assurance.md § Portfolio Status: every event stays
    // local. Sessions track the kid's play span; events surface engagement
    // milestones (zoom-tier reached, immune wave cleared, etc.).
    @State private var analytics = AnalyticsService()
    // On-device Spotlight index for the 12-microbe codex. Per
    // .claude/rules/forgekit.md § ForgeSpotlight — the index stays
    // on-device (`CSSearchableIndex`), surfacing parent + kid search via
    // iOS Spotlight. Trauma-informed posture mirrors MicrobeCodexView:
    // entire catalog indexed (codex already shows all 12 cards from
    // launch); locked entries gate the fact card behind discovery.
    @State private var spotlight = MicrobeSpotlightIndex()
    // Persistent ring buffer of microbes the kid has recently "met" so the
    // mentor (Cilia) can surface callbacks ("Saw Lacto yesterday — they're
    // still here when you're ready"). Closes the Character-personality
    // FEATURE_PLAN item.
    @State private var recall = MentorRecallStore()
    // Persistent codex discovery set. Per
    // `Docs/FEATURE_PLAN.md` § Delight & Polish → "Mastery moments —
    // Distinct screen ripple + chord when child internalizes microbiome
    // ecology": the codex axis fires when the kid completes the catalog
    // (12 / 12). Discovery surfaces on codex card tap + sync-write from
    // ExploreView's rare-sighting / curious-explorer cues so meets the
    // kid encounters during the microscope loop reflect in the codex.
    @State private var discovery = DiscoveryStore()
    // Persistent per-question quiz-attempt log. Closes the
    // `Docs/FEATURE_PLAN.md` § Parent Integration → "Progress dashboard"
    // per-standard proficiency follow-up: every QuizView reveal writes a
    // QuestionAttempt row through to UserDefaults; the parent-facing
    // report consumes the log via `proficiencies(matching:)`.
    @State private var attemptStore = QuestionAttemptStore()
    // Per-feature parental consent records per the 2026 FTC COPPA Rule
    // (effective April 22 2026). Closes the FEATURE_PLAN § Onboarding &
    // Child Safety items "Parental consent service" + "Parental gates":
    // consumer surfaces (disease-story arcs, weekly summary, external-
    // link taps, classroom mode) call `hasValidConsent(for:)` before
    // proceeding. Annual re-consent via `recordGrant` resetting the
    // expiry window. Surfaced through `ParentalConsentManagerView` from
    // SettingsView's "For parents" section (parental-gate guarded).
    @State private var consent = ParentalConsentService()
    // ForgeSensory palette — routes haptic (and, when SFX bundle lands,
    // audio) feedback for correct/incorrect answers, achievement unlocks,
    // wave clears, and run-complete moments. Closes the FEATURE_PLAN
    // § Delight & Polish "Juice layer" item on the haptic + audio axis;
    // the visual axis stays on CelebrationCoordinator above.
    @State private var sensory = SensoryPaletteCoordinator()
    // Auto-surface session-summary on app background (PR #61). Pure
    // in-memory — the welcome-back overlay covers the "kid left for 3+
    // days" case via LastActiveStore. Per Docs/FEATURE_PLAN.md § Parent
    // Integration → "Session closer" follow-up.
    @State private var pendingSessionSummary: SessionSummary?
    @State private var showingPendingSummary: Bool = false
    @State private var sessionStartedAt: Date?
    @State private var sessionStartXP: Int?
    @State private var sessionStartMicrobeCount: Int?
    /// Tracks the most-recently observed phase so transitions can fire
    /// the `app_phase_reached` analytics event + a DebugLog.lifecycle
    /// line exactly once per change. `nil` on cold launch — the first
    /// observation emits the entry phase.
    @State private var lastObservedPhase: MicrobeLabPhase?
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var systemReduceTransparency

    public init() {
        // GamificationService hydrates from StreakStore at init so day-1 of
        // a streak doesn't read as "fresh install" after the first session.
        let store = StreakStore()
        _streakStore = State(initialValue: store)
        _gamification = State(initialValue: GamificationService.hydrated(from: store))
        // Daily-cap coordinator reads the parent-set cap from the settings
        // store at first launch; later changes flow through .onChange below.
        let settings = AppSettingsStore()
        _settingsStore = State(initialValue: settings)
        _dailyTime = State(initialValue: DailyTimeCoordinator(cap: settings.settings.dailySessionCap))
    }

    /// Current `MicrobeLabPhase` derived from the store states the
    /// conditional-rendering `Group` block reads. Mirrors the body 1:1 so
    /// the value type can be threaded into analytics + debug logs from
    /// outside the view body without re-implementing the gating logic.
    private var currentPhase: MicrobeLabPhase {
        MicrobeLabPhase.resolve(
            parentHandoffCompleted: parentHandoff.hasCompletedHandoff,
            kidOnboardingCompleted: onboarding.hasCompletedOnboarding,
            catalogLoaded: catalog != nil,
            catalogFailureMessage: loadError
        )
    }

    public var body: some View {
        Group {
            if !parentHandoff.hasCompletedHandoff {
                // Parent handoff runs FIRST so a grown-up confirms content
                // comfort + session cap before the kid sees the microscope
                // onboarding. Per Docs/FEATURE_PLAN.md § Onboarding & Child
                // Safety + .claude/rules/age-assurance.md.
                ParentHandoffFlow(
                    store: parentHandoff,
                    settingsStore: settingsStore,
                    onComplete: { /* state observation reflows the Group */ }
                )
            } else if !onboarding.hasCompletedOnboarding {
                MicrobeLabOnboardingFlow {
                    onboarding.markCompleted()
                }
            } else if let catalog {
                let prefs = effectiveA11yPreferences
                tabShell(catalog: catalog)
                    .celebrationOverlay(celebration)
                    .overlay(alignment: .center) {
                        // Daily-cap overlay takes priority over the other
                        // centered overlays so the kid sees a calm wrap-up
                        // instead of a streak-rescue or welcome-back on the
                        // same launch they crossed the parent-set cap.
                        if showDailyCapOverlay {
                            DailyCapOverlay(
                                dailyElapsedMinutes: Int(dailyTime.dailyElapsedMinutes),
                                reduceTransparency: prefs.reduceTransparency
                            ) {
                                showDailyCapOverlay = false
                                welcomeBackDaysAway = nil
                                streakRescue = .none
                            }
                            .transition(overlayTransition(reduceMotion: prefs.reduceMotion))
                        }
                    }
                    .overlay(alignment: .top) {
                        // Session-target nudge pins to the top so the kid sees
                        // it without losing the current tab. Either centered
                        // overlay (welcome-back or streak-rescue) suppresses
                        // the nudge.
                        if welcomeBackDaysAway == nil && streakRescue == .none {
                            SessionNudgeOverlay(
                                service: sessionTarget,
                                reduceMotion: prefs.reduceMotion,
                                reduceTransparency: prefs.reduceTransparency
                            )
                        }
                    }
                    .overlay(alignment: .center) {
                        // Mutual exclusivity: welcome-back takes priority over
                        // streak-rescue (long-absence framing wins when both
                        // would fire). Both have warm-acknowledgment copy so
                        // showing only one keeps the cold-launch surface calm.
                        if let days = welcomeBackDaysAway {
                            WelcomeBackOverlay(
                                daysAway: days,
                                reduceTransparency: prefs.reduceTransparency
                            ) {
                                welcomeBackDaysAway = nil
                            }
                            .transition(overlayTransition(reduceMotion: prefs.reduceMotion))
                        } else if case .lapsed(let prior) = streakRescue {
                            StreakRescueOverlay(
                                priorStreak: prior,
                                reduceTransparency: prefs.reduceTransparency
                            ) {
                                streakRescue = .none
                            }
                            .transition(overlayTransition(reduceMotion: prefs.reduceMotion))
                        }
                    }
                    .animation(overlayAnimation(reduceMotion: prefs.reduceMotion), value: welcomeBackDaysAway)
                    .animation(overlayAnimation(reduceMotion: prefs.reduceMotion), value: streakRescue)
                    // Auto-surfaced session-summary sheet — only fires after
                    // the kid has actually backgrounded a productive session
                    // (see captureSessionSummaryIfProductive).
                    .sheet(isPresented: $showingPendingSummary) {
                        if let summary = pendingSessionSummary {
                            SessionSummarySheet(summary: summary) {
                                showingPendingSummary = false
                                pendingSessionSummary = nil
                            }
                            .presentationDetents([.medium])
                        }
                    }
            } else if let loadError {
                catalogLoadFailure(loadError)
            } else {
                loadingView
            }
        }
        .task {
            evaluateWelcomeBack()
            evaluateStreakRescue()
            loadCatalog()
            lastActive.recordSessionStart()
            // Increment AFTER welcome-back evaluation so the days-away
            // computation reads the prior timestamp, not the fresh one.
            // Onboarding completion is the gate — counting only "real" play
            // sessions keeps progressive disclosure honest.
            if onboarding.hasCompletedOnboarding {
                sessionCount.incrementForSessionStart()
                // Retention runs alongside session-count for D1/D7/D30
                // cohort signal — on-device only per Docs/FEATURE_PLAN.md
                // § Engagement Foundation.
                retention.recordSession()
                // Record the session AFTER counter bump so the StreakManager
                // sees the actual play session, not a launch into onboarding.
                await gamification.recordSession()
                // Wire the ForgeAccessibility SessionTimerService daily-cap
                // pipeline. Refresh + decide whether the kid is already over
                // the cap from a prior session today; if so, surface the
                // wrap-up overlay immediately. `unlimited` never trips this
                // because DailyTimeCoordinator collapses to a 24h cap.
                await dailyTime.startSession()
                if dailyTime.isDailyLimitReached {
                    showDailyCapOverlay = true
                    welcomeBackDaysAway = nil
                    streakRescue = .none
                    DebugLog.lifecycle("AppRootView — daily cap reached on launch; showing wrap-up overlay")
                }
                // Auto-surface session-summary markers: stamped on cold
                // launch so a subsequent .background → .active cycle can
                // evaluate productivity. The .onChange(scenePhase) handler
                // re-stamps on each .active resume.
                sessionStartedAt = Date()
                sessionStartXP = gamification.totalXP
                // Start the on-device analytics session in parallel with the
                // ForgeAccessibility timer. Engine is an actor so the call is
                // safe to schedule from the .task block.
                await analytics.startSession()
            }
        }
        .onChange(of: settingsStore.settings.dailySessionCap) { _, newCap in
            // Parent rebuilt the cap from Settings → propagate to the
            // ForgeKit timer. `updateCap` is no-op if `newCap == activeCap`.
            Task { await dailyTime.updateCap(newCap) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Pause / resume the daily timer with scene phase so backgrounded
            // time doesn't count against the cap. End-session flushes on
            // .background so the daily bucket persists across cold launches.
            switch newPhase {
            case .background:
                Task {
                    await dailyTime.endSession()
                    await analytics.endSession()
                    DebugLog.lifecycle("AppRootView — scenePhase → background; daily timer + analytics flushed")
                }
                // Capture the auto-surface session summary BEFORE clearing
                // the start markers; pendingSessionSummary surfaces on the
                // next .active scene phase.
                captureSessionSummaryIfProductive()
            case .inactive:
                Task { await dailyTime.pause() }
            case .active:
                if onboarding.hasCompletedOnboarding {
                    Task {
                        await dailyTime.startSession()
                        await analytics.startSession()
                    }
                    // Surface the pending summary captured on the previous
                    // .background. Skipped when (a) the daily cap is
                    // currently showing, (b) the welcome-back / streak-
                    // rescue overlay is up — those carry precedence per
                    // the centered-overlay priority chain.
                    if pendingSessionSummary != nil,
                       !showDailyCapOverlay,
                       welcomeBackDaysAway == nil,
                       streakRescue == .none {
                        showingPendingSummary = true
                        DebugLog.lifecycle("AppRootView — scenePhase → active; auto-surfacing session summary")
                    }
                    // Start markers for the NEW session segment. Captured
                    // once per cold launch + once per .background → .active
                    // resume — so a kid who backgrounds for 10 seconds to
                    // check a notification still gets the summary if their
                    // previous active span was productive.
                    sessionStartedAt = Date()
                    sessionStartXP = gamification.totalXP
                    sessionStartMicrobeCount = discovery.discoveredSlugs.count
                }
            @unknown default:
                break
            }
        }
        .onChange(of: currentPhase) { _, newPhase in
            // Phase transition observer — emits a DebugLog.lifecycle line
            // + an `app_phase_reached` analytics event exactly once per
            // change. ForgeNavigation's `MicrobeLabPhase` is the source
            // of truth for the slug. The conditional-rendering Group
            // block remains the actual phase router today; this observer
            // turns the value type into runtime traction so analytics +
            // logs see a single canonical phase identifier instead of
            // re-derivation at every consumer.
            guard newPhase != lastObservedPhase else { return }
            lastObservedPhase = newPhase
            DebugLog.lifecycle("AppRootView phase → \(newPhase.slug)")
            Task { await analytics.track(.appPhaseReached(phaseSlug: newPhase.slug)) }
        }
    }

    /// Decides whether the just-ended session is "productive enough" to
    /// surface a summary on the next launch. Trauma-informed posture:
    /// summary fires on EARNED engagement, not on every background. A 5-
    /// second background to check a notification doesn't trigger; an 8-
    /// minute play session does.
    ///
    /// Rules (all required):
    /// 1. The kid has completed onboarding (so they've seen the tab shell)
    /// 2. Session duration ≥ 60 seconds (`sessionStartedAt` was stamped)
    /// 3. The kid earned at least 1 XP during this session segment
    /// 4. No summary is currently presented or pending (no stacking)
    private func captureSessionSummaryIfProductive() {
        guard onboarding.hasCompletedOnboarding else { return }
        guard pendingSessionSummary == nil, !showingPendingSummary else { return }
        guard let startedAt = sessionStartedAt else { return }
        let elapsed = Date().timeIntervalSince(startedAt)
        guard elapsed >= 60 else {
            DebugLog.lifecycle("AppRootView — session too short for summary (elapsed=\(Int(elapsed))s)")
            return
        }
        let xpEarned: Int
        if let baseline = sessionStartXP {
            xpEarned = max(0, gamification.totalXP - baseline)
        } else {
            xpEarned = 0
        }
        guard xpEarned > 0 else {
            DebugLog.lifecycle("AppRootView — session yielded 0 XP; skipping auto summary")
            return
        }
        let summary = SessionSummary(
            currentLevel: gamification.currentLevel,
            totalXP: gamification.totalXP,
            currentStreak: gamification.currentStreak,
            microbesDiscovered: max(0, discovery.discoveredSlugs.count - (sessionStartMicrobeCount ?? 0)),
            achievementsEarned: gamification.earnedAchievementSlugs.count
        )
        pendingSessionSummary = summary
        DebugLog.lifecycle("AppRootView — captured session summary (elapsed=\(Int(elapsed))s, xpEarned=\(xpEarned))")
    }

    /// Build the engagement snapshot the parent-facing progress report
    /// consumes. Pure-value capture — the view stores the snapshot at the
    /// moment SettingsView is invoked so the report reflects the kid's state
    /// at that instant rather than ticking live across navigation. Per
    /// `.claude/rules/age-assurance.md` § Portfolio Status: counts only,
    /// never PII. `displayName` stays the anonymous default so a future
    /// avatar-name surface doesn't accidentally leak into the parent screen.
    private var progressReportSnapshot: ProgressReportSnapshot {
        ProgressReportSnapshot(
            totalSessions: sessionCount.sessionCount,
            totalDurationMinutes: Int(dailyTime.dailyElapsedMinutes),
            activitiesCompleted: gamification.earnedAchievementSlugs.count,
            currentStreak: gamification.currentStreak,
            longestStreak: gamification.longestStreak,
            totalXP: gamification.totalXP,
            activeDays: retention.totalDistinctSessionDays,
            standardProficiencies: attemptStore.proficiencies(matching: ProgressReportService.phase1Standards)
        )
    }

    /// Combine the system accessibility env values with the parent-gated
    /// `forceReduceMotion` + `forceReduceTransparency` toggles via the pure
    /// `A11yPreferences.resolved` helper. Per
    /// `Docs/FEATURE_PLAN.md` § Accessibility & Trauma-Informed Polish.
    private var effectiveA11yPreferences: A11yPreferences {
        .resolved(
            systemReduceMotion: systemReduceMotion,
            systemReduceTransparency: systemReduceTransparency,
            settings: settingsStore.settings
        )
    }

    /// Reduce-Motion drops the scale morph (vestibular trigger); opacity
    /// still cross-fades so the kid sees the overlay change.
    private func overlayTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95))
    }

    /// Reduce-Motion collapses the animation to instant so the value-change
    /// driver doesn't introduce a spring-y morph.
    private func overlayAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    /// Compute streak-rescue state BEFORE the new session is recorded so the
    /// "missed you" overlay quotes the streak the kid earned LAST time, not
    /// the one about to start. Reads from `StreakStore` directly — the
    /// hydrated `GamificationService` already has these values but reading
    /// from the store keeps the rescue derivation purely time-based.
    private func evaluateStreakRescue() {
        guard onboarding.hasCompletedOnboarding else { return }
        streakRescue = StreakRescue.from(
            lastRecordedAt: streakStore.lastRecordedAt,
            priorStreak: streakStore.currentStreak
        )
        if case .lapsed(let prior) = streakRescue {
            DebugLog.lifecycle("AppRootView — streak rescue surfaced; priorStreak=\(prior)")
        }
    }

    /// Compute days-away BEFORE stamping the new session start. The store's
    /// `shouldShowWelcomeBack` returns false on first ever install (no
    /// `lastActiveAt`) so onboarding flows are unaffected.
    private func evaluateWelcomeBack() {
        guard onboarding.hasCompletedOnboarding else { return }
        let days = lastActive.daysSinceLastActive() ?? 0
        if days >= 3 {
            welcomeBackDaysAway = days
            DebugLog.lifecycle("AppRootView — welcome-back surfaced; daysAway=\(days)")
        }
    }

    private func tabShell(catalog: MicrobeCatalogService) -> some View {
        let mentor = VeeMentor(microbes: catalog.microbes)
        let simulator = MicrobiomeSimulator(microbes: catalog.microbes)
        // Progressive disclosure: hide Microbiome / Progress / Profile until
        // the kid has launched enough sessions. Reduces day-1 decision
        // fatigue + lands the aha moment inside the microscope loop.
        let disclosure = TabDisclosure.from(sessionCount: sessionCount.sessionCount)
        // Invisible difficulty adjustment per Docs/FEATURE_PLAN.md
        // § Engagement Foundation. Bands shift at session boundaries; the
        // parent-gated `simplifyChallenge` toggle pins to .introductory.
        let difficulty = DifficultyAdjuster.from(
            sessionCount: sessionCount.sessionCount,
            simplifyChallenge: settingsStore.settings.simplifyChallenge
        )
        return TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "microscope", value: MicrobeLabTab.explore) {
                ExploreView(
                    catalog: catalog,
                    mentor: mentor,
                    sessionCount: sessionCount.sessionCount,
                    analytics: analytics,
                    recall: recall,
                    discovery: discovery
                )
            }
            Tab("Codex", systemImage: "book", value: MicrobeLabTab.codex) {
                MicrobeCodexView(
                    catalog: catalog,
                    gamification: gamification,
                    celebration: celebration,
                    sensory: sensory,
                    discovery: discovery,
                    attemptStore: attemptStore
                )
            }
            if disclosure.showsMicrobiome {
                Tab("Microbiome", systemImage: "leaf", value: MicrobeLabTab.microbiome) {
                    MicrobiomeView(
                        simulator: simulator,
                        mentor: mentor,
                        gamification: gamification,
                        difficulty: difficulty,
                        celebration: celebration,
                        analytics: analytics,
                        sensory: sensory
                    )
                }
            }
            if disclosure.showsProgress {
                Tab("Progress", systemImage: "chart.bar", value: MicrobeLabTab.progress) {
                    ProgressTabView(
                        progress: PlayerProgressData.empty(),
                        totalMicrobes: catalog.microbes.count,
                        gamification: gamification
                    )
                }
            }
            if disclosure.showsProfile {
                Tab("Profile", systemImage: "person", value: MicrobeLabTab.profile) {
                    ProfileView(
                        progressReportSnapshot: progressReportSnapshot,
                        consentService: consent
                    )
                }
            }
        }
        .onChange(of: navigationCoordinator.requestedTab) { _, requested in
            // App Intents → tab switch. The coordinator surfaces a
            // requested tab; we apply it iff the tab is currently
            // visible in the progressive-disclosure shell (e.g., a
            // Shortcut targeting Microbiome silently no-ops on session 1
            // when the tab isn't surfaced yet). Then clear the request
            // so the same intent can re-fire later.
            guard let target = requested else { return }
            if isTabAvailable(target, disclosure: disclosure) {
                selectedTab = target
                DebugLog.lifecycle("AppRootView — intent-driven tab switch → \(target.rawValue)")
            } else {
                DebugLog.lifecycle("AppRootView — intent requested tab \(target.rawValue) not yet disclosed; ignored")
            }
            navigationCoordinator.clearRequest()
        }
    }

    /// Returns true if the requested tab is currently visible in the
    /// progressive-disclosure shell. Explore + Codex are always available;
    /// the others gate on `TabDisclosure`.
    private func isTabAvailable(_ tab: MicrobeLabTab, disclosure: TabDisclosure) -> Bool {
        switch tab {
        case .explore, .codex: return true
        case .microbiome: return disclosure.showsMicrobiome
        case .progress: return disclosure.showsProgress
        case .profile: return disclosure.showsProfile
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Image(systemName: "microscope")
                .imageScale(.large)
            Text("Warming up the microscope…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func catalogLoadFailure(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
                .font(.largeTitle)
            Text("Couldn't load the microbe catalog")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private func loadCatalog() {
        switch MicrobeCatalogService.loadBundled() {
        case .success(let service):
            catalog = service
            DebugLog.startup("AppRootView catalog loaded: \(service.microbes.count) microbes")
            // Spotlight index runs once per cold launch; ForgeSpotlight
            // dedupes by `spotlightID` so repeated launches are no-ops.
            let microbes = service.microbes
            Task { await spotlight.indexCatalog(microbes) }
        case .failure(let error):
            loadError = String(describing: error)
            DebugLog.error("AppRootView catalog load failed", error: error)
        }
    }
}

private extension PlayerProgressData {
    static func empty() -> PlayerProgressData {
        PlayerProgressData(
            id: UUID(),
            displayName: "Explorer",
            totalXP: 0,
            currentStreak: 0,
            longestStreak: 0,
            lastActiveDate: nil,
            discoveredMicrobeIDs: [],
            earnedAchievementSlugs: []
        )
    }
}
