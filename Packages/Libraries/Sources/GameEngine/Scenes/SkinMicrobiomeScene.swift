import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the skin microbiome puzzle. Mirrors
/// `OralMicrobiomeScene` (gentle-care vs. disturbance vs. recovery) but
/// the care-load lever replaces the sugar-load picker since skin ecology
/// is driven by washing/moisturizing + scratching disturbance + rest.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class SkinMicrobiomeScene: SKScene {
    public private(set) var state: SkinMicrobiomeState = .empty
    public let simulator: MicrobiomeSimulator
    public let historyLimit: Int
    public private(set) var history: [SkinMicrobiomeState] = []
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let skinLayer = SKNode()
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
        fatalError("SkinMicrobiomeScene does not support NSCoder")
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

        // Warm peach/sand background — matches the "skin garden" register
        // per the kit_07_skin_microbiome.json copy. Trauma-informed: no
        // clinical white, no warning red, no medical sterility.
        backgroundColor = SKColor(red: 0.97, green: 0.89, blue: 0.81, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(skinLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance one simulator tick. Mirrors `OralMicrobiomeScene.advanceOneTick`;
    /// wrapped in the same `PerfSignpost.simulatorTick` so Instruments can
    /// verify the FEATURE_PLAN.md exit-criteria target of < 8ms per tick.
    public func advanceOneTick() {
        PerfSignpost.simulatorTick.interval("skin.advance") {
            pushHistory()
            let underlying = simulator.tick(state.underlying)
            state = SkinMicrobiomeState(
                underlying: underlying,
                careLoad: state.careLoad
            )
        }
    }

    /// Apply a new care-load. Threads through to the underlying engine's
    /// feeding-mode lever per `SkinCareLoad.feedingMode`.
    public func setCareLoad(_ load: SkinCareLoad) {
        pushHistory()
        let nextUnderlying = MicrobiomeState(
            populations: state.underlying.populations,
            feedingMode: load.feedingMode,
            antibioticState: state.underlying.antibioticState,
            tickCount: state.underlying.tickCount,
            activeSlot: state.underlying.activeSlot
        )
        state = SkinMicrobiomeState(
            underlying: nextUnderlying,
            careLoad: load
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
        // Visual layer (per-microbe sprites, skin-garden heatmap) lands
        // with the asset-bundle PR — for now the scene is a calm warm
        // background that the SpriteView shows while the SwiftUI HUD
        // surfaces the state.
    }
}
