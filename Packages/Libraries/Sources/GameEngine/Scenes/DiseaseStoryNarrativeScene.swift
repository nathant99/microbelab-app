import Foundation
import SpriteKit
import Models

/// SpriteKit scene wrapping the Phase 3 disease-story narrative beat
/// surface. Parameterized by `DiseaseStoryArc` + `currentBeatIndex` so a
/// single scene type covers all 4 canonical arcs × 4 beats (16 records
/// total per `DiseaseStoryNarrativeCatalog.canonicalRecords`).
///
/// **Pedagogy** (per `Docs/TECHNICAL_DESIGN.md` § Phase 3 + ADR-016
/// trauma-gated story-axis approval pathway): every visual element shipped
/// in this scaffold is a calm chunky-cartoon placeholder (warm cream
/// background + soft microbe glyph circles). No graphic illness imagery,
/// no warfare lexicon at the asset layer, no warning-red color. The real
/// illustration axis is asset-blocked per `.claude/rules/forgekit.md` §
/// "Asset generation ownership" — labsmith owns the per-beat illustration
/// pipeline; this scene's job is to land the structural surface so the
/// asset wave can drop in via `IllustrationRegistry` without view changes.
///
/// **Trauma-informed posture** (load-bearing per
/// `.claude/rules/trauma-informed-content.md`): the SwiftUI host
/// (`DiseaseStoryNarrativeView`) carries the off-ramp affordance + the
/// per-beat status chip; the scene itself stays content-neutral so a
/// regression at the scene layer can't surface unreviewed copy.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, all `SKShapeNode`
/// construction lives behind `configureVisuals()` so unit tests can
/// instantiate without a GPU context.
@MainActor
public final class DiseaseStoryNarrativeScene: SKScene {
    public private(set) var arc: DiseaseStoryArc
    public private(set) var currentBeatIndex: Int = 0
    public let totalBeats: Int
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let beatLayer = SKNode()
    public let hudAnchorLayer = SKNode()

    /// Initializes the scene with the chosen arc + the canonical beat
    /// count. `currentBeatIndex` starts at 0 so the kid always begins at
    /// the introduction beat. The totalBeats default matches
    /// `DiseaseStoryNarrativeBeat.allCases.count` (4).
    public init(
        size: CGSize,
        arc: DiseaseStoryArc,
        totalBeats: Int = DiseaseStoryNarrativeBeat.allCases.count
    ) {
        self.arc = arc
        self.totalBeats = totalBeats
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("DiseaseStoryNarrativeScene does not support NSCoder")
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

        // Warm cream background — same family as the seasonal / oral / skin
        // / soil scenes. No clinical white, no warning red, no high-contrast
        // alert palette. The visual register stays gentle so a future kid
        // who lands on this scene without the reviewer-signed-off prose still
        // sees a calm surface.
        backgroundColor = SKColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(beatLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    /// Advance to the next beat. Clamps at the last beat — repeated taps at
    /// the end don't roll back to 0. Pure-value transition; the SwiftUI
    /// host owns the "wrap up the story" affordance separately.
    public func advanceBeat() {
        guard currentBeatIndex < totalBeats - 1 else { return }
        currentBeatIndex += 1
    }

    /// Step backward — useful for the SwiftUI host's "back to last beat"
    /// affordance. Clamps at 0; never goes negative.
    public func retreatBeat() {
        guard currentBeatIndex > 0 else { return }
        currentBeatIndex -= 1
    }

    /// Reset to the introduction beat. The SwiftUI host wires this to the
    /// "start over" + "switch arc" flows; the scene stays pure-value.
    public func resetToFirstBeat() {
        currentBeatIndex = 0
    }

    /// Swap to a different arc — keeps the scene reusable across all 4
    /// arcs without re-instantiating. Resets the beat index to 0 so the
    /// kid always re-enters at the introduction beat for the new arc.
    public func setArc(_ newArc: DiseaseStoryArc) {
        arc = newArc
        currentBeatIndex = 0
    }

    /// Convenience accessor — returns the current beat enum so views can
    /// drive the status chip + label without reaching into the index.
    public var currentBeat: DiseaseStoryNarrativeBeat? {
        DiseaseStoryNarrativeBeat.allCases.first { $0.index == currentBeatIndex }
    }

    private func repositionAnchors() {
        // Per-beat illustration anchor lands with the asset-bundle PR — for
        // now the scene is a calm warm background that the SpriteView
        // shows while the SwiftUI HUD surfaces the per-beat status.
    }
}
