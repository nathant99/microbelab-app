import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the microscope-zoom core loop.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode` /
/// `SKLabelNode` / `SKSpriteNode` construction lives behind
/// `configureVisuals()`. This lets the scene be instantiated in headless SPM
/// test targets without a GPU context.
///
/// Per `.claude/rules/spritekit.md` § SpriteView layout cascade, the scene
/// uses `.resizeFill` `scaleMode` and overrides `didChangeSize(_:)` so it
/// reflows cleanly when the SwiftUI host changes size.
@MainActor
public final class MicroscopeScene: SKScene {
    public private(set) var machine = ZoomMachine()
    private var hasSetupVisuals = false

    /// Root content node — kept as a single child of the scene so layer
    /// reordering + safe-area inset adjustments touch one parent.
    public let contentRoot = SKNode()

    /// Layer node hosting the LOD-swappable observation sprites.
    public let observationLayer = SKNode()

    /// Layer node hosting the SwiftUI-bridged HUD anchors (named nodes the
    /// HUD overlay can target with `convertPoint(_:from:)`).
    public let hudAnchorLayer = SKNode()

    public override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("MicroscopeScene does not support NSCoder")
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

    /// Lazy visual setup — call AFTER `addChild(node)` so child node creation
    /// happens once and only when the scene is actually rendered.
    public func configureVisuals() {
        guard !hasSetupVisuals else { return }
        hasSetupVisuals = true

        backgroundColor = .black
        addChild(contentRoot)
        contentRoot.addChild(observationLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Apply a pinch delta to the machine; consumes the resulting transition
    /// for the LOD-swap animation. Pure-logic forward to `ZoomMachine`; the
    /// SwiftUI host reads `machine.currentTier` to drive HUD updates.
    ///
    /// Wrapped in `PerfSignpost.zoomTransition` so Instruments can verify the
    /// FEATURE_PLAN.md exit-criteria target of < 16ms per tier transition.
    /// Signposts are free in release builds.
    public func handlePinch(delta: Double) {
        PerfSignpost.zoomTransition.interval("pinch") {
            machine.applyPinch(delta: delta)
            if machine.pendingTransition != nil {
                // LOD swap hook — real sprite swap lands in a follow-up PR.
                machine.consumeTransition()
            }
        }
    }

    /// Direct-tier snap (HUD tier-badge tap).
    public func snapToTier(_ tier: ZoomTier) {
        PerfSignpost.zoomTransition.interval("snap") {
            machine.snap(to: tier)
            if machine.pendingTransition != nil {
                machine.consumeTransition()
            }
        }
    }

    private func repositionAnchors() {
        // Hook for HUD-anchor repositioning when the scene resizes. Real
        // anchor placement (mascot pose, tier-badge anchor, mentor speech-
        // bubble anchor) lands with the HUD PR.
    }
}
