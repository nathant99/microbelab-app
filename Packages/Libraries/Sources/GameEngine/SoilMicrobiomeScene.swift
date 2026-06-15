import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the soil microbiome puzzle. Mirrors
/// `OralMicrobiomeScene` / `SkinMicrobiomeScene` but the moisture-load
/// lever replaces the sugar/care-load picker since soil ecology is
/// driven by water availability + the periodic compost pulse + drought.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class SoilMicrobiomeScene: SKScene {
    public private(set) var state: SoilMicrobiomeState = .empty
    public let simulator: MicrobiomeSimulator
    public let historyLimit: Int
    public private(set) var history: [SoilMicrobiomeState] = []
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let soilLayer = SKNode()
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
        fatalError("SoilMicrobiomeScene does not support NSCoder")
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

        // Warm forest-floor brown — matches the "quiet underground"
        // register per kit_08_soil_microbiome.json. Trauma-informed: no
        // dead-leaves register, no decay-as-death framing; soil is
        // thriving and warm.
        backgroundColor = SKColor(red: 0.55, green: 0.43, blue: 0.31, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(soilLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance one simulator tick. Mirrors `OralMicrobiomeScene.advanceOneTick`;
    /// wrapped in the same `PerfSignpost.simulatorTick` so Instruments can
    /// verify the FEATURE_PLAN.md exit-criteria target of < 8ms per tick.
    public func advanceOneTick() {
        PerfSignpost.simulatorTick.interval("soil.advance") {
            pushHistory()
            let underlying = simulator.tick(state.underlying)
            state = SoilMicrobiomeState(
                underlying: underlying,
                moistureLoad: state.moistureLoad
            )
        }
    }

    /// Apply a new moisture-load. Threads through to the underlying
    /// engine's feeding-mode lever per `SoilMoistureLoad.feedingMode`.
    public func setMoistureLoad(_ load: SoilMoistureLoad) {
        pushHistory()
        let nextUnderlying = MicrobiomeState(
            populations: state.underlying.populations,
            feedingMode: load.feedingMode,
            antibioticState: state.underlying.antibioticState,
            tickCount: state.underlying.tickCount,
            activeSlot: state.underlying.activeSlot
        )
        state = SoilMicrobiomeState(
            underlying: nextUnderlying,
            moistureLoad: load
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
        // Visual layer (per-microbe sprites, soil-stratification heatmap)
        // lands with the asset-bundle PR — for now the scene is a calm
        // warm background that the SpriteView shows while the SwiftUI HUD
        // surfaces the state.
    }
}
