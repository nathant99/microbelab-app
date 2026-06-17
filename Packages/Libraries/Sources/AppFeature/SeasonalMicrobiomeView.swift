import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Phase 4 seasonal-microbiome sub-puzzle. Wraps `SeasonalMicrobiomeScene` +
/// a `SeasonalLoad` segmented picker so the kid can shift the gut ecology
/// through winter cold / spring pollen / summer warm / autumn settling
/// cycles.
///
/// **Pedagogy** (per `Docs/TECHNICAL_DESIGN.md` § Phase 4): seasonality is
/// part of being a body in a place. The microbiome doesn't fight the
/// seasons; it shifts with them. The kid watches what their gut community
/// does when the body is busy with a respiratory bug (cold), noticing
/// pollen (allergy), eating summer fruit (summer warm), or transitioning
/// out of summer (autumn settle).
///
/// **Trauma-informed posture** (load-bearing per `.claude/rules/trauma-informed-content.md`):
///
/// - **Cold** = "immune library busy" NEVER "the body is sick"
/// - **Allergy** = "the body is noticing pollen" NEVER "attacked"
/// - **Pollen** = sensory NEVER enemy
/// - **Autumn settle** = "the community is settling" NEVER "winding down"
///
/// The display labels + per-load mentor cue copy stays body-affirming at
/// the per-load caption tier (this is body-pedagogy framing rather than
/// disease prose, so it does NOT cross the ADR-016 disease-story-arc
/// reviewer line). The view's copy stoplist test pins these invariants.
public struct SeasonalMicrobiomeView: View {
    /// Threshold of consecutive stable-load ticks that surfaces the
    /// `seasonalAwareness` achievement. Calibrated separately from the per-
    /// ecology scenes (oral / skin / soil) so the kid can earn warmth across
    /// any season they pay attention to — not gated on a specific season.
    public static let stableRunThreshold = 8

    @State private var scene: SeasonalMicrobiomeScene
    @State private var load: SeasonalLoad = .winterCold
    @State private var tickCount: Int = 0
    @State private var stableRun: Int = 0
    @State private var mentorMessage: String

    private let mentor: VeeMentor?
    private let gamification: GamificationService?
    private let celebration: CelebrationCoordinator?
    private let analytics: AnalyticsService?
    private let sensory: SensoryPaletteCoordinator?

    public init(
        catalog: MicrobeCatalogService,
        mentor: VeeMentor? = nil,
        gamification: GamificationService? = nil,
        celebration: CelebrationCoordinator? = nil,
        analytics: AnalyticsService? = nil,
        sensory: SensoryPaletteCoordinator? = nil
    ) {
        // Seasonal cycles surface most clearly in the large-intestine gut
        // community per `Models/SeasonalMicrobiomeState.swift` doc-comment.
        // Filter the catalog to the gut-relevant cast so the simulator runs
        // on the per-ecology microbes; falls back to the full cast when no
        // explicit gut-resident is preferred (defensive — every microbe in
        // the catalog can still be ticked through the shared simulator).
        let gutMicrobes = catalog.microbes.filter { microbe in
            microbe.preferredEnvironment == .largeIntestine
                || microbe.preferredEnvironment == .smallIntestine
                || microbe.preferredEnvironment == .colon
        }
        let microbes = gutMicrobes.isEmpty ? catalog.microbes : gutMicrobes
        let seasonalSimulator = MicrobiomeSimulator(microbes: microbes)
        let initial = SeasonalMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: seasonalSimulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Winter cold — the immune library is busy. Watch the gut hold its mix.")
    }

    public var body: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Seasonal microbiome simulator. Pick a season below; tap Tick to watch how the gut shifts.")
                .accessibilityValue("Season: \(load.displayName). Tick \(tickCount).")
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
        .navigationTitle("Seasonal microbiome")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Seasonal — Tick \(tickCount)")
                .font(.headline)
            Spacer()
            Text(load.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            Picker("Season", selection: $load) {
                ForEach(SeasonalLoad.allCases, id: \.self) { load in
                    Label(load.displayName, systemImage: load.systemImage)
                        .tag(load)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: load) { _, new in
                scene.setLoad(new)
                refreshMentorCue(for: new)
                if let analytics {
                    Task { await analytics.track(.feedingModeChanged(modeSlug: new.rawValue)) }
                }
            }
            .accessibilityHint("Pick a season — winter cold, spring pollen, summer warm, or autumn settling.")
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.state.tickCount
                    stableRun = scene.stableRun
                    if tickCount > 0, tickCount % 5 == 0 {
                        refreshMentorCue(for: load)
                        DebugLog.state("SeasonalMicrobiomeView milestone tick=\(tickCount) load=\(load.rawValue) stableRun=\(stableRun)")
                        if let analytics {
                            let captured = tickCount
                            Task { await analytics.track(.microbiomeMilestone(tickCount: captured)) }
                        }
                    }
                    evaluateAchievements()
                }
                .buttonStyle(.glassProminent)

                Button("Undo") {
                    scene.undo()
                    tickCount = scene.state.tickCount
                    stableRun = scene.stableRun
                }
                .buttonStyle(.glass)

                Button("Reset") {
                    scene.reset()
                    tickCount = 0
                    stableRun = 0
                    load = .winterCold
                    refreshMentorCue(for: .winterCold)
                }
                .buttonStyle(.glass)
            }
        }
    }

    /// Evaluate the Phase-4 `seasonalAwareness` achievement against the
    /// running stable-run. `GamificationService.evaluateAchievements` is
    /// idempotent — re-tap of the same predicate is safe; the engine only
    /// emits an unlock the first time.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.seasonalAwareness.id:
                return stableRun >= Self.stableRunThreshold
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("SeasonalMicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP) stableRun=\(stableRun)")
            celebration?.badgeEarned(title: definition.title)
            if let analytics {
                let capturedSlug = definition.id
                Task { await analytics.track(.achievementEarned(slug: capturedSlug)) }
            }
        }
        if !newlyEarned.isEmpty {
            sensory?.fire(.achievement)
        }
    }

    private func refreshMentorCue(for load: SeasonalLoad) {
        guard let mentor else { return }
        let cue = mentor.fallbackEcologyHypothesis(for: load.feedingMode)
        // Layer in seasonal-specific framing so the mentor names what the
        // body is doing. Trauma-informed: cold = library busy NOT sick;
        // allergy = noticing pollen NOT attacked; pollen = sensory NOT enemy.
        let prefix: String
        switch load {
        case .winterCold:
            prefix = "The immune library is busy with a respiratory bug. The gut keeps its mix."
        case .springAllergy:
            prefix = "The body is noticing pollen — that's sensory, not an attack. The gut shifts."
        case .summerWarm:
            prefix = "Summer fruit and fiber — the gut helpers are thriving."
        case .autumnSettle:
            prefix = "The body is settling out of summer. The community pauses, gently."
        }
        mentorMessage = "\(prefix) \(cue.observation) \(cue.hypothesis)"
    }
}
