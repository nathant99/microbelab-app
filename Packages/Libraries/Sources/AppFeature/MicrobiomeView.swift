import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor

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
    @State private var mentorMessage: String

    // Achievement-criteria tracking. Tick-counter reset every time the
    // antibiotic state perturbs so `microbiomeSteady` rewards uninterrupted
    // stable runs, not cumulative ticks.
    @State private var hasFedFiber = false
    @State private var hasFedSugar = false
    @State private var stableTickRun: Int = 0

    private let mentor: VeeMentor?
    private let gamification: GamificationService?

    public init(
        simulator: MicrobiomeSimulator,
        mentor: VeeMentor? = nil,
        gamification: GamificationService? = nil
    ) {
        let initial = MicrobiomePuzzleScene(
            size: CGSize(width: 400, height: 600),
            simulator: simulator
        )
        _scene = State(initialValue: initial)
        self.mentor = mentor
        self.gamification = gamification
        let initialCue = mentor?.fallbackEcologyHypothesis(for: .balanced)
        _mentorMessage = State(initialValue: initialCue.map { "\($0.observation) \($0.hypothesis)" }
            ?? "Pick a feeding mode and tick the gut. Watch who grows.")
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .ignoresSafeArea(edges: .horizontal)
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
            }
            .navigationDestination(isPresented: $showingImmuneGame) {
                ImmuneGameView(mentor: mentor, gamification: gamification)
                    .navigationTitle("Defense")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
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
                    }
                    evaluateAchievements()
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
    /// emits an unlock the first time.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.fiberPioneer.id: return hasFedFiber
            case MicrobeLabAchievements.sugarTrial.id: return hasFedSugar
            case MicrobeLabAchievements.microbiomeSteady.id: return stableTickRun >= 10
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("MicrobiomeView achievement \(definition.id) earned (+\(definition.xpValue) XP)")
        }
    }
}
