import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the Phase 4 seasonal-microbiome sub-puzzle.
/// Mirrors `OralMicrobiomeScene` / `SkinMicrobiomeScene` / `SoilMicrobiomeScene`
/// in shape: a per-season lever (`SeasonalLoad`) replaces the feeding-mode
/// picker since the seasonal surface is driven by winter / spring-pollen /
/// summer-produce / autumn-settling cycles rather than direct diet choices.
///
/// **Pedagogy** (per `Docs/TECHNICAL_DESIGN.md` § Phase 4 + `Models/SeasonalMicrobiomeState.swift`
/// doc-comment table): cold is "the immune library is busy" NOT "the body is
/// sick"; allergy is "the body is noticing pollen" NOT "attacked"; pollen is
/// sensory NOT enemy. The underlying `MicrobiomeSimulator` is the same
/// shared engine the other ecology scenes use, so trauma-informed register
/// applies uniformly.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class SeasonalMicrobiomeScene: SKScene {
    public private(set) var state: SeasonalMicrobiomeState = .empty
    public let simulator: MicrobiomeSimulator
    public let historyLimit: Int
    public private(set) var history: [SeasonalMicrobiomeState] = []
    /// Per-season stable-run counter — pure-value derivation against
    /// `SeasonalMicrobiomeState.nextStableRun(prior:load:)`. Surfaces the
    /// `seasonalAwareness` achievement predicate without leaking the
    /// derivation into the view layer.
    public private(set) var stableRun: Int = 0
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let canopyLayer = SKNode()
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
        fatalError("SeasonalMicrobiomeScene does not support NSCoder")
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

        // Warm seasonal background — neutral cream that doesn't preassign
        // a season's color register so the per-load mentor cue carries the
        // sensory framing (snowflake / leaf / sun / wind glyph + label).
        // Trauma-informed: no clinical white, no warning red.
        backgroundColor = SKColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(canopyLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance one simulator tick. Mirrors the other ecology scenes; wrapped
    /// in the same `PerfSignpost.simulatorTick` so Instruments can verify
    /// the FEATURE_PLAN.md exit-criteria target of < 8ms per tick.
    public func advanceOneTick() {
        PerfSignpost.simulatorTick.interval("seasonal.advance") {
            pushHistory()
            let underlying = simulator.tick(state.underlying)
            state = SeasonalMicrobiomeState(
                underlying: underlying,
                load: state.load
            )
            stableRun = SeasonalMicrobiomeState.nextStableRun(
                prior: stableRun,
                load: state.load
            )
        }
    }

    /// Apply a new seasonal load. Threads through to the underlying engine's
    /// feeding-mode lever per `SeasonalLoad.feedingMode`. **Does not** reset
    /// the per-season `stableRun` — the achievement criterion intentionally
    /// rewards "noticing the season" across changes (winter → summer keeps
    /// momentum); only allergy resets the run per the doc-comment table.
    public func setLoad(_ load: SeasonalLoad) {
        pushHistory()
        let nextUnderlying = MicrobiomeState(
            populations: state.underlying.populations,
            feedingMode: load.feedingMode,
            antibioticState: state.underlying.antibioticState,
            tickCount: state.underlying.tickCount,
            activeSlot: state.underlying.activeSlot
        )
        state = SeasonalMicrobiomeState(
            underlying: nextUnderlying,
            load: load
        )
    }

    public func undo() {
        guard let previous = history.popLast() else { return }
        state = previous
        // Clamp stable run; pure-value derivation against the restored load
        // would require knowing the prior run, which isn't stored. The kid
        // never sees a regression as failure — the trauma-informed register
        // covers this — but the achievement predicate stays honest.
        stableRun = max(0, stableRun - 1)
    }

    public func reset() {
        history.removeAll(keepingCapacity: true)
        state = .empty
        stableRun = 0
    }

    private func pushHistory() {
        history.append(state)
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }
    }

    private func repositionAnchors() {
        // Visual layer (per-season canopy sprites + ambient particles) lands
        // with the asset-bundle PR — for now the scene is a calm warm
        // background that the SpriteView shows while the SwiftUI HUD
        // surfaces the state.
    }
}
