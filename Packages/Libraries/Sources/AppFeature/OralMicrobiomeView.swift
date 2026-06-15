import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Oral-cavity microbiome sub-puzzle. Wraps `OralMicrobiomeScene` + a
/// sugar-load segmented picker so the kid can shift the ecology toward
/// water / fruit / sugar snack / brush states.
///
/// Pedagogy: the oral microbiome IS a neighborhood, not a battlefield.
/// Brushing thins plaque so no single microbe takes over (the engine maps
/// `.brush` → `FeedingMode.none`); sugar snacks tilt toward acid-making
/// microbes (`.sugar`); water + fruit hold the balance (`.balanced`).
///
/// Trauma-informed posture per `.claude/rules/trauma-informed-content.md`:
///
/// - Cavities are framed as ecology, NEVER as blame
/// - Brushing is care, NEVER a moral test or performance review
/// - The mentor cue surfaces the body-as-helper register inherited from
///   `VeeMentor.fallbackEcologyHypothesis(for:)`; the underlying engine is
///   the shared `MicrobiomeSimulator` so trauma-informed register applies
///   uniformly across all 3 ecology surfaces (gut / oral / skin / soil)
public struct OralMicrobiomeView: View {
    /// Threshold of consecutive gentle-load ticks that surfaces the
    /// `oralBalanceKeeper` achievement. Calibrated separately from
    /// `DifficultyAdjuster.microbiomeSteadyTickThreshold` (10) so the oral
    /// surface unlocks faster — the oral microbiome has shorter dwell time
    /// than the gut and the kid sees the result of food choices within a
    /// shorter loop. Trauma-informed: low enough that holding gentle loads
    /// for a single sub-session lands the recognition, never demands a
    /// marathon to earn warmth.
    public static let stableRunThreshold = 8

    @State private var scene: OralMicrobiomeScene
    @State private var sugarLoad: OralSugarLoad = .water
    @State private var tickCount: Int = 0
    @State private var oralStableTickRun: Int = 0
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
        // Filter the catalog to oral-cavity-only microbes so the scene's
        // simulator runs on the per-ecology cast. Per PR #119 the cast
        // expansion bundled Sweet (S. mutans-style) in `.oralCavity`; Guard +
        // Photo are existing oral commensals.
        let oralMicrobes = catalog.microbes.filter { $0.preferredEnvironment == .oralCavity }
        let oralSimulator = MicrobiomeSimulator(microbes: oralMicrobes)
        let initial = OralMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: oralSimulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Water is steady — the oral neighborhood is balanced. Try a sugar snack and watch what shifts.")
    }

    public var body: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Oral microbiome simulator. Pick a sugar load below; tap Tick to watch the neighborhood shift.")
                .accessibilityValue("Sugar load: \(sugarLoad.displayName). Tick \(tickCount).")
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
        .navigationTitle("Oral microbiome")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Oral — Tick \(tickCount)")
                .font(.headline)
            Spacer()
            Text(sugarLoad.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            Picker("Sugar load", selection: $sugarLoad) {
                ForEach(OralSugarLoad.allCases, id: \.self) { load in
                    Label(load.displayName, systemImage: load.systemImage)
                        .tag(load)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: sugarLoad) { _, new in
                scene.setSugarLoad(new)
                refreshMentorCue(for: new)
                if let analytics {
                    Task { await analytics.track(.feedingModeChanged(modeSlug: new.rawValue)) }
                }
            }
            .accessibilityHint("Pick what the kid just had — water, fruit, sugar snack, or brushing.")
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.state.tickCount
                    oralStableTickRun = OralMicrobiomeState.nextStableRun(
                        prior: oralStableTickRun,
                        sugarLoad: sugarLoad
                    )
                    if tickCount > 0, tickCount % 5 == 0 {
                        refreshMentorCue(for: sugarLoad)
                        DebugLog.state("OralMicrobiomeView milestone tick=\(tickCount) load=\(sugarLoad.rawValue) stableRun=\(oralStableTickRun)")
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
                    // Undo rewinds the simulator; clamp the stable run so a
                    // future regression in the simulator's tick history can
                    // never carry forward an over-credited stable run.
                    oralStableTickRun = max(0, oralStableTickRun - 1)
                }
                .buttonStyle(.glass)

                Button("Reset") {
                    scene.reset()
                    tickCount = 0
                    oralStableTickRun = 0
                    sugarLoad = .water
                    refreshMentorCue(for: .water)
                }
                .buttonStyle(.glass)
            }
        }
    }

    /// Evaluate Phase-2 per-ecology achievements against the running
    /// criteria. Currently scopes to `oralBalanceKeeper` (≥
    /// `stableRunThreshold` ticks under gentle loads); per-ecology siblings
    /// (`skinKindnessChampion` / `soilDecomposerWhisperer`) wire from their
    /// own per-ecology views.
    ///
    /// `GamificationService.evaluateAchievements` is idempotent — re-tap of
    /// the same predicate is safe; the engine only emits an unlock the
    /// first time. Proportional celebrations + sensory cues fire per
    /// newly-unlocked achievement.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.oralBalanceKeeper.id:
                return oralStableTickRun >= Self.stableRunThreshold
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("OralMicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP) stableRun=\(oralStableTickRun)")
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

    private func refreshMentorCue(for load: OralSugarLoad) {
        guard let mentor else { return }
        let cue = mentor.fallbackEcologyHypothesis(for: load.feedingMode)
        // Layer in oral-specific framing so the mentor names what the kid
        // chose. Trauma-informed: brushing surfaces care, not correction.
        let prefix: String
        switch load {
        case .water: prefix = "Water is steady."
        case .fruit: prefix = "Fruit is gentle."
        case .sugarSnack: prefix = "Sugar around the teeth — watch the acid-makers."
        case .brush: prefix = "Brushing thins the plaque. The neighborhood settles."
        }
        mentorMessage = "\(prefix) \(cue.observation) \(cue.hypothesis)"
    }
}
