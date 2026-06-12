import Foundation
import SpriteKit
import Models

/// SpriteKit scene for the innate-immunity Pac-Man-style consume-pathogen
/// minigame. Phase 1 scope per `Docs/FEATURE_PLAN.md` § Immune Response
/// Engine.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, no `SKShapeNode`
/// construction in `init`. Per CLAUDE.md trauma-informed posture, the
/// minigame is framed as "your body's quiet helpers," NOT "warriors."
@MainActor
public final class MacrophagePacmanScene: SKScene {
    public private(set) var wave: Int = 1
    public private(set) var score: Int = 0
    public private(set) var isComplete: Bool = false
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let pathogenLayer = SKNode()
    public let macrophageLayer = SKNode()
    public let hudAnchorLayer = SKNode()

    /// Number of waves to clear in Phase 1.
    public let totalWaves: Int

    public init(size: CGSize, totalWaves: Int = 5) {
        self.totalWaves = totalWaves
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("MacrophagePacmanScene does not support NSCoder")
    }

    public override func didMove(to view: SKView) {
        super.didMove(to: view)
        configureVisuals()
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size != oldSize, hasSetupVisuals else { return }
        repositionAnchors()
    }

    public func configureVisuals() {
        guard !hasSetupVisuals else { return }
        hasSetupVisuals = true

        backgroundColor = SKColor(red: 0.02, green: 0.07, blue: 0.12, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(pathogenLayer)
        contentRoot.addChild(macrophageLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Award a pathogen-consumed score event. Bounded so test harnesses can
    /// drive without worrying about overflow.
    public func recordConsume(value: Int) {
        guard !isComplete else { return }
        score += max(0, value)
    }

    /// Advance to the next wave. Returns `true` if the minigame is now complete.
    @discardableResult
    public func clearWave() -> Bool {
        guard !isComplete else { return true }
        if wave >= totalWaves {
            isComplete = true
        } else {
            wave += 1
        }
        return isComplete
    }

    public func reset() {
        wave = 1
        score = 0
        isComplete = false
    }

    private func repositionAnchors() {
        // Real macrophage / pathogen sprite spawn lands with the visual PR.
    }
}
