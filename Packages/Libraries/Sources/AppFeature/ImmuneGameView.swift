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
    /// Set the first time `clearWave()` returns `finished == true` for the
    /// current life of the view. Guards the run-completion bookkeeping
    /// (mastery moment + AdaptiveImmunityProgressStore bump) so the kid
    /// can keep stepping at the wave-5 boundary without re-triggering the
    /// trifecta.
    @State private var hasRecordedInnateRunCompletion = false
    // Per-session mastery moments — fires once per kind when the kid
    // demonstrates internalization of the defense system. Mirrors the
    // `MicrobiomeView` ecology-mastery wiring shipped PR #76. Per
    // `Docs/FEATURE_PLAN.md` § Delight & Polish → "Mastery moments".
    @State private var masteryDetector = MasteryMomentDetector()
    // Snapshot for the share-worthy "defense trophy" surface. Captured at
    // the moment the kid taps "Share trophy"; nil until then so the sheet
    // never surfaces a placeholder before the run actually completes. Same
    // frozen-snapshot pattern as `CodexCertificate` (capture on tap; the
    // share image never re-derives mid-display).
    @State private var pendingTrophy: ImmuneDefenseTrophy?
    @State private var showingTrophy = false

    // MARK: - Phase 2 adaptive surface

    /// Currently-active surface. Defaults to `.innate` per the pedagogy
    /// sequencing rule (innate first; adaptive unlocks once the kid has
    /// internalized the innate concept).
    @State private var mode: ImmuneMode = .innate
    /// B-cell antibody-matching scene. Lazily configured by SpriteKit on
    /// first `didMove(to:)` (per `BCellAntibodyMatchScene.configureVisuals`)
    /// so it stays test-safe in the SPM target.
    @State private var bcellScene: BCellAntibodyMatchScene
    /// Adaptive-side score / wave mirror. The scene owns its own state;
    /// these `@State` mirrors drive the UI without forcing the view to
    /// observe the scene every body re-eval.
    @State private var adaptiveScore: Int = 0
    @State private var adaptiveWave: Int = 1
    @State private var adaptiveAntigensRemaining: Int = 0
    @State private var adaptiveIsComplete: Bool = false
    /// Whether the adaptive-side wave has been spawned. Mirrors the
    /// innate side's "first wave spawned" gating so step taps before
    /// spawn don't no-op silently.
    @State private var adaptiveWaveSpawned: Bool = false
    /// Currently-loaded antibody shape on the B-cell. Mirrors
    /// `bcell.loadedAntibody` for the picker UI.
    @State private var loadedAntibody: AntibodyShape = .spiral

    /// Display name threaded down from `AppRootView` via `PlayerProgressData
    /// .displayName`. Defaults to "Explorer" when the parent hasn't filled
    /// it in. The trophy preserves the value verbatim — same convention as
    /// `CodexCertificate.displayName`.
    private let playerDisplayName: String

    private let mentor: VeeMentor?
    private let gamification: GamificationService?
    private let celebration: CelebrationCoordinator?
    private let analytics: AnalyticsService?
    private let sensory: SensoryPaletteCoordinator?
    /// Phase 2 progression store. Threaded from `AppRootView` so the
    /// adaptive unlock gate persists across sessions. Optional so the
    /// view stays self-contained for Phase 1 surfaces / previews; when
    /// nil the adaptive surface is permanently locked (no progress
    /// can accumulate).
    private let adaptiveProgress: AdaptiveImmunityProgressStore?
    /// Parent-gated chill-mode flag (mirrors `AppSettings.simplifyChallenge`).
    /// When true the adaptive surface is always unlocked — kids whose
    /// parents have signalled "make it gentler" never have to earn their
    /// way in.
    private let simplifyChallenge: Bool

    public init(
        showWarningInitially: Bool = true,
        mentor: VeeMentor? = nil,
        gamification: GamificationService? = nil,
        difficulty: DifficultyAdjuster = DifficultyAdjuster(level: .standard),
        celebration: CelebrationCoordinator? = nil,
        analytics: AnalyticsService? = nil,
        sensory: SensoryPaletteCoordinator? = nil,
        adaptiveProgress: AdaptiveImmunityProgressStore? = nil,
        simplifyChallenge: Bool = false,
        playerDisplayName: String = "Explorer"
    ) {
        let wavePathogenCounts = difficulty.immuneWavePathogenCounts(totalWaves: 5)
        let initial = MacrophagePacmanScene(
            size: CGSize(width: 400, height: 600),
            totalWaves: wavePathogenCounts.count,
            wavePathogenCounts: wavePathogenCounts
        )
        _scene = State(initialValue: initial)
        let adaptive = BCellAntibodyMatchScene(
            size: CGSize(width: 400, height: 600)
        )
        _bcellScene = State(initialValue: adaptive)
        _hasAcknowledgedWarning = State(initialValue: !showWarningInitially)
        _showWarning = State(initialValue: showWarningInitially)
        _mentorMessage = State(initialValue: nil)
        self.mentor = mentor
        self.gamification = gamification
        self.celebration = celebration
        self.analytics = analytics
        self.sensory = sensory
        self.adaptiveProgress = adaptiveProgress
        self.simplifyChallenge = simplifyChallenge
        self.playerDisplayName = playerDisplayName
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
        .sheet(isPresented: $showingTrophy) {
            if let trophy = pendingTrophy {
                ImmuneDefenseTrophySheet(trophy: trophy) {
                    showingTrophy = false
                }
                .presentationDetents([.large])
            }
        }
    }

    /// Capture a frozen `ImmuneDefenseTrophy` snapshot at the moment the
    /// kid taps "Share trophy" in the score HUD. Future-session activity
    /// doesn't retroactively change a trophy the kid has shared. The
    /// `perfectRun` flag mirrors `MasteryMomentDetector
    /// .recordDefenseRunComplete(wavesCleared:pathogensRemaining:)`'s gate
    /// (all waves cleared AND zero pathogens missed on the final wave) so
    /// the mastery moment and the trophy share a perfect-run definition.
    private func captureTrophySnapshot() -> ImmuneDefenseTrophy {
        let perfect = hasClearedAllWaves && pathogensRemaining == 0
        return ImmuneDefenseTrophy(
            displayName: playerDisplayName,
            wavesCleared: scene.wave,
            totalWaves: scene.totalWaves,
            finalScore: score,
            perfectRun: perfect,
            issuedAt: Date()
        )
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
            modeSelectorBar
                .padding(.horizontal)
                .padding(.top, 4)
            Group {
                switch mode {
                case .innate: innateSurface
                case .adaptive: adaptiveSurface
                }
            }
        }
    }

    /// Pure-derivation unlock state for the adaptive mode. Refreshed
    /// every body re-eval because `AdaptiveImmunityProgressStore` is
    /// `@Observable`. Trauma-informed posture is in
    /// `AdaptiveImmunityUnlock.unlockExplainerCopy`.
    private var adaptiveUnlock: AdaptiveImmunityUnlock {
        guard let adaptiveProgress else {
            // Without a progress store, behave as if no progress has
            // accumulated. The simplifyChallenge flag still bypasses
            // the gate for chill-mode previews.
            return AdaptiveImmunityUnlock.from(
                innateRunsCompleted: 0,
                perfectInnateRuns: 0,
                simplifyChallenge: simplifyChallenge
            )
        }
        return adaptiveProgress.unlock(simplifyChallenge: simplifyChallenge)
    }

    private var modeSelectorBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker("Defense surface", selection: $mode) {
                ForEach(ImmuneMode.allCases, id: \.self) { candidate in
                    Label(candidate.displayName, systemImage: candidate.systemImage)
                        .tag(candidate)
                        .accessibilityHint(candidate.tagline)
                }
            }
            .pickerStyle(.segmented)
            .disabled(mode == .adaptive ? false : !adaptiveUnlock.isUnlocked && mode != .innate)
            .onChange(of: mode) { _, newMode in
                if newMode == .adaptive && !adaptiveUnlock.isUnlocked {
                    // Adaptive isn't earned yet; bounce back to innate.
                    // The locked explainer surfaces beneath the picker.
                    mode = .innate
                }
                if newMode == .adaptive {
                    DebugLog.lifecycle("ImmuneGameView mode → adaptive")
                }
            }
            if !adaptiveUnlock.isUnlocked, let copy = adaptiveUnlock.unlockExplainerCopy {
                Text(verbatim: copy)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                    .accessibilityHint("Tap Macrophage patrol to keep going; more runs unlock the B-cell library.")
            }
        }
    }

    private var innateSurface: some View {
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

    private var adaptiveSurface: some View {
        VStack(spacing: 0) {
            SpriteView(scene: bcellScene, options: [.allowsTransparency])
                .ignoresSafeArea(edges: .horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("B-cell antibody-matching minigame. Pick a shape; nearby antigens with the matching shape are recognized.")
                .accessibilityValue(adaptiveIsComplete
                    ? "All waves cleared. Final score \(adaptiveScore)."
                    : "Wave \(adaptiveWave). Score \(adaptiveScore). Antigens remaining: \(adaptiveAntigensRemaining).")
                .safeAreaInset(edge: .top, spacing: 8) {
                    adaptiveScoreHud
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
            if let mentorMessage {
                MentorBubble(message: mentorMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }
            adaptiveControlBar
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
                Button {
                    pendingTrophy = captureTrophySnapshot()
                    showingTrophy = true
                    DebugLog.lifecycle("ImmuneGameView trophy sheet presented: waves=\(scene.wave)/\(scene.totalWaves) score=\(score) perfect=\(pendingTrophy?.perfectRun ?? false)")
                } label: {
                    Label("Share trophy", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                        .padding(8)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Share defense trophy")
                .accessibilityHint("Open a shareable trophy showing your wave + score from this run")
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
            // Juice layer: epic-tier challenge-complete haptic on full run
            // pairs with the celebration overlay's full-screen Lottie.
            sensory?.fire(.challengeComplete)
            if let analytics {
                Task { await analytics.track(.immuneRunCompleted) }
            }
            // Phase 2 progression: persist this innate run so the adaptive
            // surface unlocks on the canonical curve. The perfect-run flag
            // mirrors `MasteryMomentDetector` exactly so the fast-track
            // unlock and the mastery moment share a definition. Guarded by
            // `hasRecordedInnateRunCompletion` so the kid can keep tapping
            // Step at the wave-5 boundary without retriggering.
            if !hasRecordedInnateRunCompletion {
                hasRecordedInnateRunCompletion = true
                let perfect = hasClearedAllWaves && pathogensRemaining == 0
                adaptiveProgress?.recordRunCompleted(perfectRun: perfect)
                DebugLog.state("ImmuneGameView innate-run recorded: perfect=\(perfect) runs=\(adaptiveProgress?.innateRunsCompleted ?? -1) perfectRuns=\(adaptiveProgress?.perfectInnateRuns ?? -1)")
            }
            // Defense-mastery axis (closes PR #76 partial). The detector
            // returns a `Moment` only on a perfect run (≥ 5 waves cleared
            // AND zero pathogens remaining) — the step-button advance gate
            // already enforces `pathogensRemaining == 0` before `clearWave`,
            // so any `finished == true` path here is a perfect run.
            evaluateDefenseMastery()
        } else {
            mentorMessage = "Wave clear. The next group is on its way — take a breath."
            celebration?.celebrate(.medium, message: "Wave clear", emoji: "✨")
            // Juice layer: medium-tier streak-milestone haptic on per-wave
            // clear. Mid-run cues stay subtle so the run doesn't feel
            // overstimulating; the canonical ForgeHapticLibrary pattern
            // already calibrates the intensity.
            sensory?.fire(.streakMilestone(wave))
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
        if !newlyEarned.isEmpty {
            sensory?.fire(.achievement)
        }
    }

    /// Defense-mastery moment evaluation. Mirrors the ecology-mastery
    /// wiring in `MicrobiomeView.evaluateEcologyMastery()`: pure mutation
    /// against the per-session `MasteryMomentDetector`; on a non-nil
    /// `Moment` return, fire the same trifecta as the ecology axis —
    /// `.epic`-tier celebration ripple via `CelebrationCoordinator
    /// .personalBest(metric:value:)` + the moment's subline into the
    /// mentor bubble + a distinct `.streakMilestone` sensory cue.
    ///
    /// Trauma-informed: the detector's subline copy stoplist (`finally` /
    /// `at last` / `you almost` / `failed` / `behind` / `should have` /
    /// `compared to` / `better than`) is pinned by parameterized test in
    /// `MasteryMomentDetectorTests`; the mentor bubble inherits that copy
    /// verbatim. The defense run never frames prior runs as failure.
    private func evaluateDefenseMastery() {
        guard let moment = masteryDetector.recordDefenseRunComplete(
            wavesCleared: scene.wave,
            pathogensRemaining: pathogensRemaining
        ) else { return }
        DebugLog.state("ImmuneGameView mastery moment: \(moment.kind.rawValue) waves=\(scene.wave) score=\(score)")
        celebration?.personalBest(metric: moment.headline, value: "\(scene.wave) waves perfect")
        mentorMessage = moment.subline
        sensory?.fire(.streakMilestone(scene.wave))
        if let analytics {
            Task { await analytics.track(.achievementEarned(slug: moment.kind.rawValue)) }
        }
    }

    // MARK: - Adaptive surface HUD + control bar

    private var adaptiveScoreHud: some View {
        HStack(spacing: 14) {
            chip(label: "Wave", value: "\(adaptiveWave) / \(bcellScene.totalWaves)")
            chip(label: "Score", value: "\(adaptiveScore)")
            chip(label: "Left", value: "\(adaptiveAntigensRemaining)")
            Spacer()
            if adaptiveIsComplete {
                Text("Library full")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .glassEffect(.regular.tint(.purple), in: .capsule)
            }
        }
    }

    private var adaptiveControlBar: some View {
        VStack(spacing: 10) {
            antibodyShapePicker
            HStack(spacing: 12) {
                Button(adaptiveWaveSpawned ? "Step" : "Begin wave") {
                    if !adaptiveWaveSpawned {
                        bcellScene.spawnCurrentWave()
                        adaptiveAntigensRemaining = bcellScene.antigens.filter { !$0.isMatched }.count
                        adaptiveWaveSpawned = true
                        DebugLog.state("ImmuneGameView adaptive wave-\(adaptiveWave) spawned (count=\(adaptiveAntigensRemaining))")
                        return
                    }
                    bcellScene.advanceAntigens(by: 0.5)
                    let matched = bcellScene.attemptMatch()
                    adaptiveScore = bcellScene.score
                    adaptiveAntigensRemaining = bcellScene.antigens.filter { !$0.isMatched }.count
                    DebugLog.state("ImmuneGameView adaptive step: matched=\(matched) remaining=\(adaptiveAntigensRemaining)")
                    if matched > 0 {
                        sensory?.fire(.correctAnswer)
                    }
                    if bcellScene.currentWaveIsComplete {
                        let finished = bcellScene.clearWave()
                        adaptiveWave = bcellScene.wave
                        adaptiveIsComplete = finished
                        surfaceAdaptiveWaveClearCue(finished: finished)
                        if !finished {
                            bcellScene.spawnCurrentWave()
                            adaptiveAntigensRemaining = bcellScene.antigens.filter { !$0.isMatched }.count
                        }
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(adaptiveIsComplete)

                Button("Reset") {
                    bcellScene.reset()
                    adaptiveScore = 0
                    adaptiveWave = 1
                    adaptiveAntigensRemaining = 0
                    adaptiveIsComplete = false
                    adaptiveWaveSpawned = false
                    loadedAntibody = bcellScene.bcell.loadedAntibody
                    mentorMessage = nil
                    DebugLog.state("ImmuneGameView adaptive reset")
                }
                .buttonStyle(.glass)
            }
            .accessibilityHint(adaptiveIsComplete
                ? "Adaptive run complete — tap Reset to play again"
                : "Pick an antibody shape, then tap Step to advance and recognize antigens")
        }
    }

    private var antibodyShapePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: "Antibody shape")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("Antibody shape", selection: $loadedAntibody) {
                ForEach(AntibodyShape.allCases, id: \.self) { shape in
                    Text(verbatim: shape.rawValue.capitalized).tag(shape)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: loadedAntibody) { _, newShape in
                bcellScene.loadAntibody(newShape)
                DebugLog.state("ImmuneGameView antibody loaded: \(newShape.rawValue)")
            }
        }
    }

    /// Surface a wave-clear cue for the adaptive surface. Trauma-informed:
    /// frames each match as recognition, never destruction. Static
    /// authored content (no `@Generable` calls — recognition cues are
    /// stable enough to ship as authored copy).
    private func surfaceAdaptiveWaveClearCue(finished: Bool) {
        if finished {
            mentorMessage = "Your B-cell library remembers every shape. The body's quiet helpers will recognize them faster next time."
            celebration?.celebrate(.epic, message: "B-cell library full", emoji: "🧬", slug: "game-complete")
            sensory?.fire(.challengeComplete)
        } else {
            mentorMessage = "Shapes recognized. The body remembers — the next wave will move faster."
            celebration?.celebrate(.medium, message: "Wave recognized", emoji: "✨")
            sensory?.fire(.streakMilestone(adaptiveWave))
        }
    }
}
