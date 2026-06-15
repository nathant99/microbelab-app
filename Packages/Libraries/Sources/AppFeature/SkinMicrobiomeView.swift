import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Skin microbiome sub-puzzle. Wraps `SkinMicrobiomeScene` + a care-load
/// segmented picker so the kid can shift the skin garden toward gentle-
/// wash / moisturize / itchy-day / rest states.
///
/// Pedagogy: the skin microbiome IS a garden, not a battlefield. Gentle
/// washing + moisturizing hold the canonical commensals (Sebu / Demi /
/// Guard) in balance (the engine maps both to `FeedingMode.balanced`);
/// scratching when itchy jumbles the flora and tilts toward disturbance-
/// tolerant neighbors (`.sugar`); rest gives the community time to
/// rebalance (`.none`).
///
/// **Trauma-informed posture per `.claude/rules/trauma-informed-content.md`**:
///
/// - Eczema and itchy skin are acknowledged as part of being a kid —
///   NEVER framed as failure or moral judgment
/// - Scratching is something kids sometimes do when itchy — the per-load
///   copy frames the consequence as ecology, never as "you ruined the
///   skin community"
/// - Brushing was care in the oral scene; gentle washing + moisturizing
///   are care here. The mentor surfaces the body-as-helper register
///   inherited from `VeeMentor.fallbackEcologyHypothesis(for:)`
public struct SkinMicrobiomeView: View {
    /// Threshold of consecutive gentle-care ticks that surfaces the
    /// `skinKindnessChampion` achievement. Calibrated to match
    /// `OralMicrobiomeView.stableRunThreshold` so the per-ecology
    /// recognition surface lands at the same pace across the three
    /// Phase-2 scenes — predictability is calming.
    public static let stableRunThreshold = 8

    @State private var scene: SkinMicrobiomeScene
    @State private var careLoad: SkinCareLoad = .gentleWash
    @State private var tickCount: Int = 0
    @State private var skinStableTickRun: Int = 0
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
        // Filter the catalog to skin-only microbes so the scene's
        // simulator runs on the per-ecology cast. Per PR #119 the cast
        // expansion bundled Sebu (sebum commensal) + Demi (Demodex face
        // mite framed as "quiet cleaner"); Guard is an existing commensal.
        let skinMicrobes = catalog.microbes.filter { $0.preferredEnvironment == .skin }
        let skinSimulator = MicrobiomeSimulator(microbes: skinMicrobes)
        let initial = SkinMicrobiomeScene(
            size: CGSize(width: 400, height: 600),
            simulator: skinSimulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Gentle wash, then watch. The skin garden settles when it's left in balance.")
    }

    public var body: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Skin microbiome simulator. Pick a care load below; tap Tick to watch the skin garden shift.")
                .accessibilityValue("Care load: \(careLoad.displayName). Tick \(tickCount).")
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
        .navigationTitle("Skin microbiome")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var headerRow: some View {
        HStack {
            Text(verbatim: "Skin — Tick \(tickCount)")
                .font(.headline)
            Spacer()
            Text(careLoad.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            Picker("Care load", selection: $careLoad) {
                ForEach(SkinCareLoad.allCases, id: \.self) { load in
                    Label(load.displayName, systemImage: load.systemImage)
                        .tag(load)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: careLoad) { _, new in
                scene.setCareLoad(new)
                refreshMentorCue(for: new)
                if let analytics {
                    Task { await analytics.track(.feedingModeChanged(modeSlug: new.rawValue)) }
                }
            }
            .accessibilityHint("Pick what the skin just had — gentle wash, moisturize, itchy day, or rest.")
            HStack(spacing: 12) {
                Button("Tick") {
                    scene.advanceOneTick()
                    tickCount = scene.state.tickCount
                    skinStableTickRun = SkinMicrobiomeState.nextStableRun(
                        prior: skinStableTickRun,
                        careLoad: careLoad
                    )
                    if tickCount > 0, tickCount % 5 == 0 {
                        refreshMentorCue(for: careLoad)
                        DebugLog.state("SkinMicrobiomeView milestone tick=\(tickCount) load=\(careLoad.rawValue) stableRun=\(skinStableTickRun)")
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
                    skinStableTickRun = max(0, skinStableTickRun - 1)
                }
                .buttonStyle(.glass)

                Button("Reset") {
                    scene.reset()
                    tickCount = 0
                    skinStableTickRun = 0
                    careLoad = .gentleWash
                    refreshMentorCue(for: .gentleWash)
                }
                .buttonStyle(.glass)
            }
        }
    }

    private func refreshMentorCue(for load: SkinCareLoad) {
        guard let mentor else { return }
        let cue = mentor.fallbackEcologyHypothesis(for: load.feedingMode)
        // Layer in skin-specific framing. Trauma-informed: scratching
        // surfaces ecology, NEVER blame; rest surfaces care, not judgment.
        let prefix: String
        switch load {
        case .gentleWash: prefix = "Warm water, gentle soap. The garden settles."
        case .barrier: prefix = "Moisturize. The skin keeps its oils. The community holds."
        case .scratch: prefix = "The skin gets itchy. The neighborhood gets jumbled — that's ecology, not blame."
        case .restRecover: prefix = "Give the skin a break. The garden rebalances when it's left alone."
        }
        mentorMessage = "\(prefix) \(cue.observation) \(cue.hypothesis)"
    }

    /// Evaluate Phase-2 per-ecology achievements against the running
    /// criteria. Currently scopes to `skinKindnessChampion` (≥
    /// `stableRunThreshold` ticks under gentle-care loads); per-ecology
    /// siblings (`oralBalanceKeeper` / `soilDecomposerWhisperer`) wire
    /// from their own per-ecology views.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.skinKindnessChampion.id:
                return skinStableTickRun >= Self.stableRunThreshold
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("SkinMicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP) stableRun=\(skinStableTickRun)")
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
