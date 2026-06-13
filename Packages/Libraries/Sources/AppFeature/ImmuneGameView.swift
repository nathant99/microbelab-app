import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine
import AIMentor
import ForgeCelebration

/// Innate-immunity minigame tab. Wraps `MacrophagePacmanScene` + score HUD
/// + wave-progress chip + trauma-informed off-ramp on first launch.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture, the
/// minigame surfaces a pre-content warning + skip-with-summary affordance
/// for kids with medical anxiety. The mentor (Cilia) acknowledges
/// difficulty calmly via the speech bubble at the bottom.
///
/// Surfaces a `MentorBubble` cue on wave-clear (the milestone event in
/// `Docs/FEATURE_PLAN.md` line 91) and awards `immuneRookie` / `immuneRunner`
/// achievements.
public struct ImmuneGameView: View {
    @State private var scene: MacrophagePacmanScene
    @State private var score: Int = 0
    @State private var wave: Int = 1
    @State private var pathogensRemaining: Int = 0
    @State private var isComplete: Bool = false
    @State private var hasAcknowledgedWarning: Bool
    @State private var showWarning: Bool
    @State private var mentorMessage: String?

    // Achievement-criteria tracking.
    @State private var hasClearedFirstWave = false
    @State private var hasClearedAllWaves = false

    private let mentor: VeeMentor?
    private let gamification: GamificationService?
    private let celebration: CelebrationCoordinator?
    private let analytics: AnalyticsService?

    public init(
        showWarningInitially: Bool = true,
        mentor: VeeMentor? = nil,
        gamification: GamificationService? = nil,
        difficulty: DifficultyAdjuster = DifficultyAdjuster(level: .standard),
        celebration: CelebrationCoordinator? = nil,
        analytics: AnalyticsService? = nil
    ) {
        let wavePathogenCounts = difficulty.immuneWavePathogenCounts(totalWaves: 5)
        let initial = MacrophagePacmanScene(
            size: CGSize(width: 400, height: 600),
            totalWaves: wavePathogenCounts.count,
            wavePathogenCounts: wavePathogenCounts
        )
        _scene = State(initialValue: initial)
        _hasAcknowledgedWarning = State(initialValue: !showWarningInitially)
        _showWarning = State(initialValue: showWarningInitially)
        _mentorMessage = State(initialValue: nil)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
    }

    public var body: some View {
        Group {
            if showWarning {
                offRampWarning
            } else {
                gameSurface
            }
        }
        .onAppear {
            DebugLog.lifecycle("ImmuneGameView onAppear; warningShown=\(showWarning)")
        }
    }

    // MARK: - Trauma-safe off-ramp

    private var offRampWarning: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Your body's quiet helpers")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("In this game, you play as a macrophage — one of the patient cells your body sends to clean up when something doesn't belong. There's no scary stuff. You can skip ahead if you'd rather just read about it.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Read a summary instead") {
                    hasAcknowledgedWarning = true
                    showWarning = false
                    // The game scene stays paused; user can come back later.
                    isComplete = true
                }
                .buttonStyle(.glass)

                Button("I'm ready") {
                    hasAcknowledgedWarning = true
                    showWarning = false
                    scene.spawnCurrentWave()
                    pathogensRemaining = scene.pathogens.count
                    DebugLog.state("ImmuneGameView wave-1 spawned")
                }
                .buttonStyle(.glassProminent)
            }
            .padding(.top, 8)
        }
        .padding()
    }

    // MARK: - Game surface

    private var gameSurface: some View {
        VStack(spacing: 0) {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Macrophage minigame. Drag the macrophage to consume pathogens; clear the wave to advance.")
                .accessibilityValue(isComplete
                    ? "Run complete. Final score \(score)."
                    : "Wave \(wave). Score \(score). Pathogens remaining: \(pathogensRemaining).")
                .safeAreaInset(edge: .top, spacing: 8) {
                    scoreHud
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
            if let mentorMessage {
                MentorBubble(message: mentorMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
            controlBar
                .padding()
                .background(.thinMaterial)
        }
    }

    private var scoreHud: some View {
        HStack(spacing: 14) {
            chip(label: "Wave", value: "\(wave) / \(scene.totalWaves)")
            chip(label: "Score", value: "\(score)")
            chip(label: "Left", value: "\(pathogensRemaining)")
            Spacer()
            if isComplete {
                Text("Cleared")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .glassEffect(.regular.tint(.green), in: .capsule)
            }
        }
    }

    private func chip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.callout.monospacedDigit())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var controlBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button("Step") {
                    scene.advancePathogens(by: 0.5)
                    let consumed = scene.consumePathogensInRadius()
                    pathogensRemaining = scene.pathogens.count
                    score = scene.score
                    DebugLog.state("ImmuneGameView step: consumed=\(consumed) remaining=\(pathogensRemaining)")
                    if pathogensRemaining == 0 {
                        let finished = scene.clearWave()
                        wave = scene.wave
                        isComplete = finished
                        hasClearedFirstWave = true
                        if finished {
                            hasClearedAllWaves = true
                        }
                        surfaceWaveClearCue(finished: finished)
                        evaluateAchievements()
                        if !finished {
                            scene.spawnCurrentWave()
                            pathogensRemaining = scene.pathogens.count
                        }
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(isComplete)

                Button("Reset") {
                    scene.reset()
                    score = 0
                    wave = 1
                    pathogensRemaining = 0
                    isComplete = false
                    mentorMessage = nil
                    scene.spawnCurrentWave()
                    pathogensRemaining = scene.pathogens.count
                    DebugLog.state("ImmuneGameView reset")
                }
                .buttonStyle(.glass)
            }
            .accessibilityHint(isComplete ? "Minigame complete — tap Reset to play again" : "Tap Step to advance pathogens and consume nearby ones")
        }
    }

    /// Surface a wave-clear mentor cue. When the whole minigame is done, the
    /// message celebrates the clear; mid-run, it acknowledges the next wave
    /// without raising the stakes. Static authored content per
    /// `.claude/rules/ai-content.md` — never AI-generated for celebrations.
    ///
    /// Pairs with ForgeCelebration: per-wave clear fires a medium tier
    /// (subtle), full run fires an epic tier (full-screen). The mentor
    /// bubble carries the educational meta-voice; the celebration overlay
    /// carries the visual + haptic juice. Both can coexist because
    /// `CelebrationOverlayModifier` renders in the view's own overlay
    /// envelope while `MentorBubble` renders inline.
    private func surfaceWaveClearCue(finished: Bool) {
        if finished {
            mentorMessage = "All waves cleared. Your body's quiet helpers had your back."
            celebration?.celebrate(.epic, message: "Defense run complete", emoji: "🛡️", slug: "game-complete")
            if let analytics {
                Task { await analytics.track(.immuneRunCompleted) }
            }
        } else {
            mentorMessage = "Wave clear. The next group is on its way — take a breath."
            celebration?.celebrate(.medium, message: "Wave clear", emoji: "✨")
            if let analytics {
                let captured = wave
                Task { await analytics.track(.immuneWaveCleared(waveIndex: captured)) }
            }
        }
    }

    /// Evaluate Phase-1 immune-defense achievements. Idempotent — the
    /// `AchievementEngine` only unlocks each ID once.
    private func evaluateAchievements() {
        guard let gamification else { return }
        let newlyEarned = gamification.evaluateAchievements { definition in
            switch definition.id {
            case MicrobeLabAchievements.immuneRookie.id: return hasClearedFirstWave
            case MicrobeLabAchievements.immuneRunner.id: return hasClearedAllWaves
            default: return false
            }
        }
        for definition in newlyEarned {
            DebugLog.state("ImmuneGameView achievement \(definition.id) earned (+\(definition.xpValue) XP)")
        }
    }
}
