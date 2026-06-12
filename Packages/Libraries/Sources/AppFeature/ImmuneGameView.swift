import SwiftUI
import SpriteKit
import Models
import Services
import SharedUI
import GameEngine

/// Innate-immunity minigame tab. Wraps `MacrophagePacmanScene` + score HUD
/// + wave-progress chip + trauma-informed off-ramp on first launch.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture, the
/// minigame surfaces a pre-content warning + skip-with-summary affordance
/// for kids with medical anxiety. The mentor (Cilia) acknowledges
/// difficulty calmly via the speech bubble at the bottom.
public struct ImmuneGameView: View {
    @State private var scene: MacrophagePacmanScene
    @State private var score: Int = 0
    @State private var wave: Int = 1
    @State private var pathogensRemaining: Int = 0
    @State private var isComplete: Bool = false
    @State private var hasAcknowledgedWarning: Bool
    @State private var showWarning: Bool

    public init(showWarningInitially: Bool = true) {
        let initial = MacrophagePacmanScene(size: CGSize(width: 400, height: 600))
        _scene = State(initialValue: initial)
        _hasAcknowledgedWarning = State(initialValue: !showWarningInitially)
        _showWarning = State(initialValue: showWarningInitially)
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
                .safeAreaInset(edge: .top, spacing: 8) {
                    scoreHud
                        .padding(.horizontal)
                        .padding(.top, 4)
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
                    scene.spawnCurrentWave()
                    pathogensRemaining = scene.pathogens.count
                    DebugLog.state("ImmuneGameView reset")
                }
                .buttonStyle(.glass)
            }
            .accessibilityHint(isComplete ? "Minigame complete — tap Reset to play again" : "Tap Step to advance pathogens and consume nearby ones")
        }
    }
}
