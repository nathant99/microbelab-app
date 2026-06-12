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
    @State private var gamification = GamificationService()
    @State private var onboarding = OnboardingStore()
    @State private var lastActive = LastActiveStore()
    @State private var sessionCount = SessionCountStore()
    @State private var sessionTarget = SessionTargetService()
    @State private var welcomeBackDaysAway: Int?

    public init() {}

    public var body: some View {
        Group {
            if !onboarding.hasCompletedOnboarding {
                MicrobeLabOnboardingFlow {
                    onboarding.markCompleted()
                }
            } else if let catalog {
                tabShell(catalog: catalog)
                    .overlay(alignment: .top) {
                        // Session-target nudge pins to the top so the kid sees
                        // it without losing the current tab. Welcome-back
                        // overlay covers the screen + suppresses the nudge.
                        if welcomeBackDaysAway == nil {
                            SessionNudgeOverlay(service: sessionTarget)
                        }
                    }
                    .overlay(alignment: .center) {
                        if let days = welcomeBackDaysAway {
                            WelcomeBackOverlay(daysAway: days) {
                                welcomeBackDaysAway = nil
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: welcomeBackDaysAway)
            } else if let loadError {
                catalogLoadFailure(loadError)
            } else {
                loadingView
            }
        }
        .task {
            evaluateWelcomeBack()
            loadCatalog()
            lastActive.recordSessionStart()
            // Increment AFTER welcome-back evaluation so the days-away
            // computation reads the prior timestamp, not the fresh one.
            // Onboarding completion is the gate — counting only "real" play
            // sessions keeps progressive disclosure honest.
            if onboarding.hasCompletedOnboarding {
                sessionCount.incrementForSessionStart()
            }
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
                ExploreView(catalog: catalog, mentor: mentor)
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
