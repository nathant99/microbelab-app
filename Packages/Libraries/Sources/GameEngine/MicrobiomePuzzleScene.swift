import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the microbiome puzzle (gut ecology + feeding +
/// antibiotic shock loop).
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class MicrobiomePuzzleScene: SKScene {
    public private(set) var machine = SimulationMachine()
    public let simulator: MicrobiomeSimulator
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let microbeLayer = SKNode()
    public let hudAnchorLayer = SKNode()

    public init(size: CGSize, simulator: MicrobiomeSimulator) {
        self.simulator = simulator
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("MicrobiomePuzzleScene does not support NSCoder")
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

        backgroundColor = SKColor(red: 0.05, green: 0.1, blue: 0.15, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(microbeLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance one simulator tick. Drives population deltas + state machine
    /// history. Real visual update (microbe-population sprite scaling, etc.)
    /// lands with the visual PR.
    public func advanceOneTick() {
        machine.advance(using: simulator)
    }

    public func setFeedingMode(_ mode: FeedingMode) {
        machine.setFeedingMode(mode)
    }

    public func triggerAntibiotic(daysActive: Int = 3) {
        machine.triggerAntibiotic(daysActive: daysActive)
    }

    public func undo() {
        machine.undo()
    }

    private func repositionAnchors() {
        // Real anchor placement (gut-slot grid, feeding-mode pickers, etc.)
        // lands with the visual PR.
    }
}
