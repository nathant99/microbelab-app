import SwiftUI
import Models
import Services
import SharedUI
import GameEngine
import AIMentor

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
    @State private var welcomeBackDaysAway: Int?
    @State private var streakRescue: StreakRescue = .none

    public init() {
        // GamificationService hydrates from StreakStore at init so day-1 of
        // a streak doesn't read as "fresh install" after the first session.
        let store = StreakStore()
        _streakStore = State(initialValue: store)
        _gamification = State(initialValue: GamificationService.hydrated(from: store))
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
                tabShell(catalog: catalog)
                    .overlay(alignment: .top) {
                        // Session-target nudge pins to the top so the kid sees
                        // it without losing the current tab. Either centered
                        // overlay (welcome-back or streak-rescue) suppresses
                        // the nudge.
                        if welcomeBackDaysAway == nil && streakRescue == .none {
                            SessionNudgeOverlay(service: sessionTarget)
                        }
                    }
                    .overlay(alignment: .center) {
                        // Mutual exclusivity: welcome-back takes priority over
                        // streak-rescue (long-absence framing wins when both
                        // would fire). Both have warm-acknowledgment copy so
                        // showing only one keeps the cold-launch surface calm.
                        if let days = welcomeBackDaysAway {
                            WelcomeBackOverlay(daysAway: days) {
                                welcomeBackDaysAway = nil
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else if case .lapsed(let prior) = streakRescue {
                            StreakRescueOverlay(priorStreak: prior) {
                                streakRescue = .none
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: welcomeBackDaysAway)
                    .animation(.easeInOut(duration: 0.25), value: streakRescue)
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
            }
        }
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
        return TabView {
            Tab("Explore", systemImage: "microscope") {
                ExploreView(
                    catalog: catalog,
                    mentor: mentor,
                    sessionCount: sessionCount.sessionCount
                )
            }
            Tab("Codex", systemImage: "book") {
                MicrobeCodexView(catalog: catalog, gamification: gamification)
            }
            if disclosure.showsMicrobiome {
                Tab("Microbiome", systemImage: "leaf") {
                    MicrobiomeView(simulator: simulator, mentor: mentor, gamification: gamification)
                }
            }
            if disclosure.showsProgress {
                Tab("Progress", systemImage: "chart.bar") {
                    ProgressTabView(
                        progress: PlayerProgressData.empty(),
                        totalMicrobes: catalog.microbes.count,
                        gamification: gamification
                    )
                }
            }
            if disclosure.showsProfile {
                Tab("Profile", systemImage: "person") {
                    ProfileView()
                }
            }
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
