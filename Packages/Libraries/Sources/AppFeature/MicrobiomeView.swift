import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Microbiome puzzle tab. Wraps `MicrobiomePuzzleScene` + feeding-mode picker
/// + antibiotic shock affordance. Hosts a NavigationStack so the innate-
/// immunity minigame is reachable as a sub-page (toolbar shield button).
///
/// Surfaces a `MentorBubble` cue on feeding-mode change and every 5th tick
/// (microbiome stability milestone per `Docs/FEATURE_PLAN.md` line 91), and
/// awards Phase-1 achievements (`fiberPioneer` / `sugarTrial` /
/// `microbiomeSteady`) as the kid hits the criteria.
public struct MicrobiomeView: View {
    @State private var scene: MicrobiomePuzzleScene
    @State private var feedingMode: FeedingMode = .balanced
    @State private var tickCount: Int = 0
    @State private var showingAntibioticPrompt = false
    @State private var showingImmuneGame = false
    @State private var showingOralMicrobiome = false
    @State private var showingSkinMicrobiome = false
    @State private var showingSoilMicrobiome = false
    @State private var showingGlobalTour = false
    @State private var showingSeasonalMicrobiome = false
    @State private var mentorMessage: String

    // Achievement-criteria tracking. Tick-counter reset every time the
    // antibiotic state perturbs so `microbiomeSteady` rewards uninterrupted
    // stable runs, not cumulative ticks.
    @State private var hasFedFiber = false
    @State private var hasFedSugar = false
    @State private var stableTickRun: Int = 0
    // Per-session mastery moments — fired once per kind via
    // `CelebrationCoordinator.personalBest(metric:value:)` (`.epic` tier)
    // when the kid demonstrates internalization of ecology causality.
    // Per `Docs/FEATURE_PLAN.md` § Delight & Polish → "Mastery moments".
    @State private var masteryDetector = MasteryMomentDetector()

    private let mentor: VeeMentor?
    private let gamification: GamificationService?
    private let difficulty: DifficultyAdjuster
    private let celebration: CelebrationCoordinator?
    private let analytics: AnalyticsService?
    private let sensory: SensoryPaletteCoordinator?
    private let adaptiveProgress: AdaptiveImmunityProgressStore?
    private let simplifyChallenge: Bool
    /// Catalog used to host the oral-cavity sub-puzzle. When nil, the toolbar
    /// affordance for the oral surface is hidden so callers (e.g., unit
    /// previews) that don't need it don't pay the wiring cost.
    private let catalog: MicrobeCatalogService?
    /// Phase 4 global-microbiome tour service. When nil, the global-tour
    /// toolbar item is hidden so the existing call sites don't pay the
    /// wiring cost; AppRootView injects the canonical instance.
    private let globalTour: GlobalMicrobiomeTourService?
    /// Phase 3+ progression service. When nil, the tour view falls back to
    /// the scaffold "not yet" copy; AppRootView injects the canonical
    /// instance so the gate hint reflects the kid's actual session count.
    private let progression: ProgressionService?
    /// Phase 4 seasonal-microbiome surface gate. When non-nil, surfaces the
    /// seasonal-microbiome toolbar item; the seasonal scene + view inherit
    /// the same trauma-informed register applied across oral / skin / soil
    /// per `Models/SeasonalMicrobiomeState.swift`. The service itself is
    /// already wired for the streak / currency emoji affordances; passing
    /// it through here makes the seasonal sub-puzzle reachable when the
    /// experiment flag flips ON.
    private let seasonalEvents: SeasonalEventService?

    public init(
        simulator: MicrobiomeSimulator,
        mentor: VeeMentor? = nil,
        gamification: GamificationService? = nil,
        difficulty: DifficultyAdjuster = DifficultyAdjuster(level: .standard),
        celebration: CelebrationCoordinator? = nil,
        analytics: AnalyticsService? = nil,
        sensory: SensoryPaletteCoordinator? = nil,
        adaptiveProgress: AdaptiveImmunityProgressStore? = nil,
        simplifyChallenge: Bool = false,
        catalog: MicrobeCatalogService? = nil,
        globalTour: GlobalMicrobiomeTourService? = nil,
        progression: ProgressionService? = nil,
        seasonalEvents: SeasonalEventService? = nil
    ) {
        let initial = MicrobiomePuzzleScene(
            size: CGSize(width: 400, height: 600),
            simulator: simulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        self.difficulty = difficulty
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        self.adaptiveProgress = adaptiveProgress
        self.simplifyChallenge = simplifyChallenge
        self.catalog = catalog
        self.globalTour = globalTour
        self.progression = progression
        self.seasonalEvents = seasonalEvents
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Pick a feeding mode and tick the gut. Watch who grows.")
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea(edges: .horizontal)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Microbiome simulator. Pick a feeding mode below to shift the gut ecology; tap the antibiotic button to perturb it.")
                    .accessibilityValue("Current feeding mode: \(Self.accessibilityLabel(for: feedingMode)). Tick \(tickCount).")
                    .safeAreaInset(edge: .top, spacing: 8) {
                        headerRow
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                MentorBubble(message: mentorMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                controlBar
                    .padding()
                    .background(.thinMaterial)
            }
            .alert("Apply antibiotic?", isPresented: $showingAntibioticPrompt) {
                Button("Cancel", role: .cancel) {}
                Button("Apply") {
                    scene.triggerAntibiotic()
                    DebugLog.state("MicrobiomeView antibiotic applied")
                }
            } message: {
                Text("Antibiotics knock back the microbiome for a few ticks. Watch your microbes recover.")
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImmuneGame = true
                    } label: {
                        Label("Defense game", systemImage: "shield.lefthalf.filled")
                    }
                    .accessibilityHint("Open the innate immunity minigame")
                }
                if catalog != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingOralMicrobiome = true
                        } label: {
                            Label("Oral microbiome", systemImage: "mouth.fill")
                        }
                        .accessibilityHint("Open the oral-cavity microbiome puzzle")
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingSkinMicrobiome = true
                        } label: {
                            Label("Skin microbiome", systemImage: "hand.raised.fill")
                        }
                        .accessibilityHint("Open the skin microbiome puzzle")
                    }
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingSoilMicrobiome = true
                        } label: {
                            Label("Soil microbiome", systemImage: "leaf.arrow.triangle.circlepath")
                        }
                        .accessibilityHint("Open the soil microbiome puzzle")
                    }
                }
                if globalTour != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingGlobalTour = true
                        } label: {
                            Label("Global tour", systemImage: "globe.americas.fill")
                        }
                        .accessibilityHint("Open the global microbiome tour — Yellowstone, deep-sea vents, your gut, the soil")
                    }
                }
                if seasonalEvents != nil, catalog != nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            showingSeasonalMicrobiome = true
                        } label: {
                            Label("Seasonal", systemImage: "calendar.badge.clock")
                        }
                        .accessibilityHint("Open the seasonal microbiome — watch the gut shift through cold, pollen, summer warmth, and autumn settling")
                    }
                }
            }
            .navigationDestination(isPresented: $showingImmuneGame) {
                ImmuneGameView(
                    mentor: mentor,
                    gamification: gamification,
                    difficulty: difficulty,
                    celebration: celebration,
                    analytics: analytics,
                    sensory: sensory,
                    adaptiveProgress: adaptiveProgress,
                    simplifyChallenge: simplifyChallenge
                )
                    .navigationTitle("Defense")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
            }
            .navigationDestination(isPresented: $showingOralMicrobiome) {
                if let catalog {
                    OralMicrobiomeView(
                        catalog: catalog,
                        mentor: mentor,
                        gamification: gamification,
                        celebration: celebration,
                        analytics: analytics,
                        sensory: sensory
                    )
                }
            }
            .navigationDestination(isPresented: $showingSkinMicrobiome) {
                if let catalog {
                    SkinMicrobiomeView(
                        catalog: catalog,
                        mentor: mentor,
                        gamification: gamification,
                        celebration: celebration,
                        analytics: analytics,
                        sensory: sensory
                    )
                }
            }
            .navigationDestination(isPresented: $showingSoilMicrobiome) {
                if let catalog {
                    SoilMicrobiomeView(
                        catalog: catalog,
                        mentor: mentor,
                        gamification: gamification,
                        celebration: celebration,
                        analytics: analytics,
                        sensory: sensory
                    )
                }
            }
            .navigationDestination(isPresented: $showingGlobalTour) {
                if let globalTour {
                    GlobalMicrobiomeTourView(
                        tour: globalTour,
                        progression: progression,
                        catalog: catalog
                    )
                }
            }
            .navigationDestination(isPresented: $showingSeasonalMicrobiome) {
                if let catalog {
                    SeasonalMicrobiomeView(
                        catalog: catalog,
                        mentor: mentor,
                        gamification: gamification,
                        celebration: celebration,
                        analytics: analytics,
                        sensory: sensory
                    )
                }
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Microbiome — Tick \(tickCount)")
                .font(.headline)
            Spacer()
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            FeedingModePicker(selected: feedingMode) { mode in
                feedingMode = mode
                scene.setFeedingMode(mode)
                if mode == .fiber { hasFedFiber = true }
                if mode == .sugar { hasFedSugar = true }
                refreshMentorCue(forFeedingMode: mode)
                evaluateAchievements()
                if let analytics {
                    Task { await analytics.track(.feedingModeChanged(modeSlug: mode.rawValue)) }
                }
            }
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.machine.state.tickCount
                    // Stable runs reset whenever the antibiotic perturbs the
                    // ecology; otherwise each tick extends the run by 1.
                    if scene.machine.state.antibioticState.isPerturbing {
                        stableTickRun = 0
                    } else {
                        stableTickRun += 1
                    }
                    // Microbiome-milestone event: every 5 ticks the simulator
                    // hits a stable beat — surface a fresh ecology hypothesis
                    // so the mentor scaffolds inquiry without being chatty.
                    if tickCount > 0, tickCount % 5 == 0 {
                        refreshMentorCue(forFeedingMode: feedingMode)
                        DebugLog.state("MicrobiomeView milestone tick=\(tickCount) stableRun=\(stableTickRun)")
                        if let analytics {
                            let captured = tickCount
                            Task { await analytics.track(.microbiomeMilestone(tickCount: captured)) }
                        }
                    }
                    evaluateAchievements()
                    evaluateEcologyMastery()
                }
                .buttonStyle(.glassProminent)

                Button("Antibiotic") {
                    showingAntibioticPrompt = true
                }
                .buttonStyle(.glass)

                Button("Undo") {
                    scene.undo()
                    tickCount = scene.machine.state.tickCount
                    stableTickRun = 0
                }
                .buttonStyle(.glass)
            }
        }
    }

    /// Pull a static ecology hypothesis for the current mode. Async generated
    /// cues land once the AI surface is fully wired to the speech-bubble.
    private func refreshMentorCue(forFeedingMode mode: FeedingMode) {
        guard let mentor else { return }
        let cue = mentor.fallbackEcologyHypothesis(for: mode)
        mentorMessage = "\(cue.observation) \(cue.hypothesis)"
    }

    /// Evaluate Phase-1 microbiome achievements against the running criteria.
    /// `GamificationService.evaluateAchievements` is idempotent — re-entering
    /// the criteria closure with the same flags is safe; the engine only
    /// emits an unlock the first time. Proportional celebrations fire per
    /// newly-unlocked achievement: medium tier matches the "your microbiome
    /// stayed steady" register without crowding the mentor bubble.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.fiberPioneer.id: return hasFedFiber
            case MicrobeLabAchievements.sugarTrial.id: return hasFedSugar
            case MicrobeLabAchievements.microbiomeSteady.id: return stableTickRun >= difficulty.microbiomeSteadyTickThreshold
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("MicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP)")
            celebration?.badgeEarned(title: definition.title)
            if let analytics {
                let capturedSlug = definition.id
                Task { await analytics.track(.achievementEarned(slug: capturedSlug)) }
            }
        }
        // Juice layer: per-achievement haptic; per-event so successive
        // unlocks in the same tick each surface a discrete cue.
        if !newlyEarned.isEmpty {
            sensory?.fire(.achievement)
        }
    }

    /// Mastery-moment evaluation point. Pure mutation against the per-session
    /// `MasteryMomentDetector`; the detector enforces the once-per-session
    /// rule + criteria thresholds so the view's job is to forward state and
    /// fire UI surfaces (celebration overlay + mentor bubble cue + sensory
    /// streak-milestone haptic) on a non-nil `Moment` return.
    private func evaluateEcologyMastery() {
        guard let moment = masteryDetector.recordEcologyTick(
            stableTickRun: stableTickRun,
            feedingMode: feedingMode
        ) else { return }
        DebugLog.state("MicrobiomeView mastery moment: \(moment.kind.rawValue) at tick=\(tickCount) stableRun=\(stableTickRun)")
        // Epic-tier celebration ripples the screen + plays the
        // `daily-complete` Lottie per ForgeCelebration's mapping.
        celebration?.personalBest(metric: moment.headline, value: "\(stableTickRun) stable ticks")
        // Carry the moment's voice into the mentor bubble so the kid sees
        // calm narration of what they just did (no benchmark framing).
        mentorMessage = moment.subline
        // Distinct sensory cue — streakMilestone carries a longer, more
        // intentional haptic pattern than the routine `.achievement` cue.
        sensory?.fire(.streakMilestone(MasteryMomentDetector.ecologyMasteryStableTickThreshold))
        if let analytics {
            Task { await analytics.track(.achievementEarned(slug: moment.kind.rawValue)) }
        }
    }

    // VoiceOver-facing label for the feeding mode — sibling helper to the
    // private one in `SharedUI.FeedingModePicker`; mirrored here so the
    // simulator-canvas accessibility value doesn't need to reach into the
    // picker's private surface. Keep the two in sync if either gains a case.
    static func accessibilityLabel(for mode: FeedingMode) -> String {
        switch mode {
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .balanced: return "Balanced"
        case .none: return "Empty"
        }
    }
}
