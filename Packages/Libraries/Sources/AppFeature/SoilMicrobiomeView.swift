import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Soil microbiome sub-puzzle. Wraps `SoilMicrobiomeScene` + a
/// moisture-load segmented picker so the kid can shift the soil garden
/// toward moist / compost / saturated / drought states.
///
/// Pedagogy: the soil microbiome IS the underground community that
/// holds the ecosystem together — decomposers (Loam) return material
/// to the soil; nitrogen-fixers (Nodu) feed plants their main element;
/// extremophiles (Therm thermophiles + Halo halophiles) ride out the
/// harshest swings. The cast bundled PR #119 covers all of these guilds.
///
/// **Trauma-informed posture per `.claude/rules/trauma-informed-content.md`**:
///
/// - Decay is framed as "decomposers return material to the soil",
///   NEVER as death-anxiety vocabulary (no `rot` / `dying` / `corpse`)
/// - Drought is framed as "everyone slows down — extremophiles wait
///   it out", NEVER as ecosystem failure
/// - Saturated is framed as ecology, NEVER as "you ruined the soil"
/// - Cross-portfolio bridge: this scene is the on-ramp to bioforge /
///   ecosphere ecology; soil is a thriving system, not "dirt"
public struct SoilMicrobiomeView: View {
    /// Threshold of consecutive thriving-load ticks that surfaces the
    /// `soilDecomposerWhisperer` achievement. Calibrated to match the
    /// oral + skin per-ecology recognition thresholds so the kid sees
    /// the same pace across all 3 Phase-2 scenes — predictability is
    /// calming.
    public static let stableRunThreshold = 8

    @State private var scene: SoilMicrobiomeScene
    @State private var moistureLoad: SoilMoistureLoad = .moist
    @State private var tickCount: Int = 0
    @State private var soilStableTickRun: Int = 0
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
        // Filter the catalog to soil-only microbes so the scene's
        // simulator runs on the per-ecology cast. Per PR #119: Halo
        // (halophilic archaea) + Nodu (Rhizobium nitrogen-fixer) +
        // Therm (thermophilic archaea) + Loam (saprophytic fungi).
        let soilMicrobes = catalog.microbes.filter { $0.preferredEnvironment == .soil }
        let soilSimulator = MicrobiomeSimulator(microbes: soilMicrobes)
        let initial = SoilMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: soilSimulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Moist soil with air pockets — the underground is humming. Try a compost pulse and see who feasts.")
    }

    public var body: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Soil microbiome simulator. Pick a moisture load below; tap Tick to watch the underground shift.")
                .accessibilityValue("Moisture load: \(moistureLoad.displayName). Tick \(tickCount).")
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
        .navigationTitle("Soil microbiome")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Soil — Tick \(tickCount)")
                .font(.headline)
            Spacer()
            Text(moistureLoad.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            Picker("Moisture load", selection: $moistureLoad) {
                ForEach(SoilMoistureLoad.allCases, id: \.self) { load in
                    Label(load.displayName, systemImage: load.systemImage)
                        .tag(load)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: moistureLoad) { _, new in
                scene.setMoistureLoad(new)
                refreshMentorCue(for: new)
                if let analytics {
                    Task { await analytics.track(.feedingModeChanged(modeSlug: new.rawValue)) }
                }
            }
            .accessibilityHint("Pick the moisture state — moist soil, fresh compost, saturated water, or drought.")
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.state.tickCount
                    soilStableTickRun = SoilMicrobiomeState.nextStableRun(
                        prior: soilStableTickRun,
                        moistureLoad: moistureLoad
                    )
                    if tickCount > 0, tickCount % 5 == 0 {
                        refreshMentorCue(for: moistureLoad)
                        DebugLog.state("SoilMicrobiomeView milestone tick=\(tickCount) load=\(moistureLoad.rawValue) stableRun=\(soilStableTickRun)")
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
                    soilStableTickRun = max(0, soilStableTickRun - 1)
                }
                .buttonStyle(.glass)

                Button("Reset") {
                    scene.reset()
                    tickCount = 0
                    soilStableTickRun = 0
                    moistureLoad = .moist
                    refreshMentorCue(for: .moist)
                }
                .buttonStyle(.glass)
            }
        }
    }

    private func refreshMentorCue(for load: SoilMoistureLoad) {
        guard let mentor else { return }
        let cue = mentor.fallbackEcologyHypothesis(for: load.feedingMode)
        // Layer in soil-specific framing. Trauma-informed: drought
        // surfaces ecology, NEVER catastrophe; decay surfaces
        // participation ("decomposers return material to the soil"),
        // NEVER death-anxiety.
        let prefix: String
        switch load {
        case .moist: prefix = "Moist soil, air pockets in place. The underground is humming."
        case .compost: prefix = "Fresh compost. The decomposers feast on the new material."
        case .saturated: prefix = "Water has filled every pore. Only the anaerobic specialists thrive — that's ecology, not failure."
        case .drought: prefix = "Everyone slows down. Extremophiles wait it out; the rest go dormant."
        }
        mentorMessage = "\(prefix) \(cue.observation) \(cue.hypothesis)"
    }

    /// Evaluate Phase-2 per-ecology achievements against the running
    /// criteria. Currently scopes to `soilDecomposerWhisperer` (≥
    /// `stableRunThreshold` ticks under thriving loads); per-ecology
    /// siblings (`oralBalanceKeeper` / `skinKindnessChampion`) wire
    /// from their own per-ecology views.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.soilDecomposerWhisperer.id:
                return soilStableTickRun >= Self.stableRunThreshold
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("SoilMicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP) stableRun=\(soilStableTickRun)")
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
}
