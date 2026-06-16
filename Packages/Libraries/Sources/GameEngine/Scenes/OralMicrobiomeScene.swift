import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the oral-cavity microbiome puzzle. Mirrors
/// `MicrobiomePuzzleScene` (gut ecology + feeding + antibiotic) but the
/// sugar-load lever replaces the feeding-mode picker since the oral
/// microbiome is driven by sugar exposure + brushing rather than fiber
/// vs. sugar diet choices.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class OralMicrobiomeScene: SKScene {
    public private(set) var state: OralMicrobiomeState = .empty
    public let simulator: MicrobiomeSimulator
    public let historyLimit: Int
    public private(set) var history: [OralMicrobiomeState] = []
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let plaqueLayer = SKNode()
    public let hudAnchorLayer = SKNode()

    public init(
        size: CGSize,
        simulator: MicrobiomeSimulator,
        historyLimit: Int = 32
    ) {
        self.simulator = simulator
        self.historyLimit = historyLimit
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("OralMicrobiomeScene does not support NSCoder")
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

        // Warm cream background — matches the "neighborhood, not battlefield"
        // register. Trauma-informed: no clinical white, no warning red.
        backgroundColor = SKColor(red: 0.96, green: 0.92, blue: 0.85, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(plaqueLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance one simulator tick. Mirrors `MicrobiomePuzzleScene.advanceOneTick`;
    /// wrapped in the same `PerfSignpost.simulatorTick` so Instruments can
    /// verify the FEATURE_PLAN.md exit-criteria target of < 8ms per tick.
    public func advanceOneTick() {
        PerfSignpost.simulatorTick.interval("oral.advance") {
            pushHistory()
            let underlying = simulator.tick(state.underlying)
            state = OralMicrobiomeState(
                underlying: underlying,
                sugarLoad: state.sugarLoad
            )
        }
    }

    /// Apply a new sugar-load. Threads through to the underlying engine's
    /// feeding-mode lever per `OralSugarLoad.feedingMode`.
    public func setSugarLoad(_ load: OralSugarLoad) {
        pushHistory()
        let nextUnderlying = MicrobiomeState(
            populations: state.underlying.populations,
            feedingMode: load.feedingMode,
            antibioticState: state.underlying.antibioticState,
            tickCount: state.underlying.tickCount,
            activeSlot: state.underlying.activeSlot
        )
        state = OralMicrobiomeState(
            underlying: nextUnderlying,
            sugarLoad: load
        )
    }

    public func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
    }

    public func reset() {
        history.removeAll(keepingCapacity: true)
        state = .empty
    }

    private func pushHistory() {
        history.append(state)
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }

    private func repositionAnchors() {
        // Visual layer (per-microbe sprites, plaque-density heatmap) lands
        // with the asset-bundle PR — for now the scene is a calm warm
        // background that the SpriteView shows while the SwiftUI HUD
        // surfaces the state.
    }
}
