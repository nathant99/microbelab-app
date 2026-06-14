import Foundation
import SpriteKit
import Models

/// SpriteKit scene skeleton for the Phase 2 adaptive-immunity B-cell
/// antibody-matching minigame.
///
/// Per `Docs/FEATURE_PLAN.md` § Phase 2: Adaptive Immunity + Microbiome
/// Expansion — pattern-match antibodies to antigens. This PR ships the
/// **pure-value logic skeleton + scene + tests**; UI integration into
/// `ImmuneGameView` lands when the rest of the Phase 2 progression
/// (adaptive-unlock-after-innate / 8 question kits / etc.) is in place.
///
/// **Trauma-informed register** (per `Docs/TECHNICAL_DESIGN.md` § Trauma-
/// Informed Design Posture + the `AdaptiveImmuneScenario` pedagogy
/// beats authored in `AIMentor.MentorGenerables`): adaptive immunity
/// surfaces as the body's library of shapes. Antibodies MATCH antigens;
/// the body REMEMBERS shapes. No "fight" / "attack" / "destroy" / "kill"
/// / "war" / "enemy" / "battle" / "weapon" / "soldier" / "warrior"
/// vocabulary anywhere — this is shape recognition, not warfare.
///
/// Per `.claude/rules/spritekit.md` § Lazy Visual Setup, no `SKShapeNode`
/// construction in `init`. Logic (spawn / load / match / memory) lives
/// behind a pure-value surface so SPM unit tests can exercise the
/// pedagogy beats without a GPU context. Visuals (SKNodes per antigen +
/// B-cell + memory chip) only activate via `configureVisuals()`.
///
/// Per `.claude/rules/state-machines.md`, the wave + memory state stays
/// in this scene class for now; a `*Machine` extraction lands if/when
/// the surface grows beyond 4-5 coordinated `@State`-like properties.
@MainActor
public final class BCellAntibodyMatchScene: SKScene {

    // MARK: - Wave / scoring state

    public private(set) var wave: Int = 1
    public private(set) var score: Int = 0
    public private(set) var isComplete: Bool = false
    private var hasSetupVisuals = false

    public let contentRoot = SKNode()
    public let antigenLayer = SKNode()
    public let bcellLayer = SKNode()
    public let memoryLayer = SKNode()
    public let hudAnchorLayer = SKNode()

    /// Number of waves to clear in the Phase 2 surface. Phase 2 line
    /// item ships at 5 waves to mirror the Phase 1 immune Pac-Man cadence.
    public let totalWaves: Int

    /// Per-wave antigen counts (index 0 = wave 1). The Phase-2 curve is
    /// deliberately gentle on day-1 — DDA tuning per `DifficultyAdjuster`
    /// lands in the wave-counts the `ImmuneGameView` adapter wires.
    public let waveAntigenCounts: [Int]

    /// Points awarded per successful shape-match. Memory-cell-aided
    /// matches award `memoryMatchPoints` instead.
    public let baseMatchPoints: Int
    public let memoryMatchPoints: Int

    // MARK: - Pure-value gameplay state

    public private(set) var antigens: [AntigenState] = []
    public private(set) var bcell: BCellState
    public private(set) var memoryCells: [MemoryRecord] = []
    private var rng: SeededRNG

    public init(
        size: CGSize,
        totalWaves: Int = 5,
        waveAntigenCounts: [Int] = [3, 4, 5, 6, 7],
        baseMatchPoints: Int = 2,
        memoryMatchPoints: Int = 4,
        seed: UInt64 = 0
    ) {
        precondition(
            waveAntigenCounts.count == totalWaves,
            "waveAntigenCounts must have one entry per wave"
        )
        self.totalWaves = totalWaves
        self.waveAntigenCounts = waveAntigenCounts
        self.baseMatchPoints = baseMatchPoints
        self.memoryMatchPoints = memoryMatchPoints
        self.bcell = BCellState(position: Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        ))
        self.rng = SeededRNG(seed: seed)
        super.init(size: size)
        scaleMode = .resizeFill
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("BCellAntibodyMatchScene does not support NSCoder")
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

        backgroundColor = SKColor(red: 0.04, green: 0.10, blue: 0.16, alpha: 1)
        addChild(contentRoot)
        contentRoot.addChild(antigenLayer)
        contentRoot.addChild(bcellLayer)
        contentRoot.addChild(memoryLayer)
        contentRoot.addChild(hudAnchorLayer)

        repositionAnchors()
    }

    // MARK: - Wave spawn (pure logic)

    /// Spawn the current wave's antigens at random edges of the scene
    /// with inward velocities. Deterministic given the seeded RNG; mirrors
    /// the `MacrophagePacmanScene.spawnCurrentWave` pattern.
    public func spawnCurrentWave() {
        guard !isComplete else { return }
        let count = waveAntigenCounts[max(0, min(waveAntigenCounts.count - 1, wave - 1))]
        antigens.removeAll()
        for _ in 0..<count {
            antigens.append(makeAntigen())
        }
    }

    private func makeAntigen() -> AntigenState {
        let shape = AntibodyShape.allCases[Int(rng.nextUnit() * Double(AntibodyShape.allCases.count)) % AntibodyShape.allCases.count]
        let width = Double(size.width)
        let height = Double(size.height)
        let edgeSpeed = 25.0
        let position: Vec2
        let velocity: Vec2
        switch Int(rng.nextUnit() * 4) {
        case 0: // left → right
            position = Vec2(x: 0, y: rng.nextUnit() * height)
            velocity = Vec2(x: edgeSpeed, y: 0)
        case 1: // right → left
            position = Vec2(x: width, y: rng.nextUnit() * height)
            velocity = Vec2(x: -edgeSpeed, y: 0)
        case 2: // bottom → up
            position = Vec2(x: rng.nextUnit() * width, y: 0)
            velocity = Vec2(x: 0, y: edgeSpeed)
        default: // top → down
            position = Vec2(x: rng.nextUnit() * width, y: height)
            velocity = Vec2(x: 0, y: -edgeSpeed)
        }
        return AntigenState(shape: shape, position: position, velocity: velocity)
    }

    // MARK: - Per-tick logic

    /// Advance unmatched antigens by `delta` seconds, bouncing off the
    /// scene bounds. Matched antigens stay put (they're already
    /// "recognized" and waiting for wave clear).
    public func advanceAntigens(by delta: TimeInterval) {
        guard !isComplete, delta > 0 else { return }
        let width = Double(size.width)
        let height = Double(size.height)
        for index in antigens.indices {
            var a = antigens[index]
            guard !a.isMatched else { continue }
            a.position.x += a.velocity.x * delta
            a.position.y += a.velocity.y * delta
            if a.position.x < 0 || a.position.x > width {
                a.velocity.x = -a.velocity.x
                a.position.x = max(0, min(width, a.position.x))
            }
            if a.position.y < 0 || a.position.y > height {
                a.velocity.y = -a.velocity.y
                a.position.y = max(0, min(height, a.position.y))
            }
            antigens[index] = a
        }
    }

    /// Move the B-cell by `delta` scene-coord units, clamped to bounds.
    public func moveBCell(by delta: Vec2) {
        guard !isComplete else { return }
        let width = Double(size.width)
        let height = Double(size.height)
        let nextX = max(0, min(width, bcell.position.x + delta.x))
        let nextY = max(0, min(height, bcell.position.y + delta.y))
        bcell.position = Vec2(x: nextX, y: nextY)
    }

    /// Swap the antibody shape the B-cell currently has loaded. Mirrors
    /// the "select a tool" pedagogy beat — the kid picks the
    /// complementary shape before approaching the antigen.
    public func loadAntibody(_ shape: AntibodyShape) {
        guard !isComplete else { return }
        bcell.loadedAntibody = shape
    }

    /// Attempt to match the loaded antibody against any antigen within
    /// `bcell.matchRadius`. Returns the count matched this tick.
    ///
    /// Memory awareness: if any matched antigen's shape already has a
    /// `MemoryRecord` entry, award `memoryMatchPoints` instead of
    /// `baseMatchPoints` and bump the recognition count. Otherwise create
    /// a new `MemoryRecord` for that shape (counting as the body's first
    /// recognition of that pattern).
    @discardableResult
    public func attemptMatch() -> Int {
        guard !isComplete else { return 0 }
        let complement = bcell.loadedAntibody.complement
        var matched = 0
        var awarded = 0
        for index in antigens.indices {
            var a = antigens[index]
            guard !a.isMatched else { continue }
            guard a.shape == complement else { continue }
            guard a.position.distance(to: bcell.position) <= bcell.matchRadius else { continue }
            a.isMatched = true
            antigens[index] = a
            matched += 1
            awarded += awardForShapeRecognition(a.shape)
        }
        if awarded > 0 {
            score += awarded
        }
        return matched
    }

    /// Bump or create the memory record for `shape`. Returns the point
    /// award for this single match.
    private func awardForShapeRecognition(_ shape: AntibodyShape) -> Int {
        if let existing = memoryCells.firstIndex(where: { $0.shape == shape }) {
            memoryCells[existing].recognitionCount += 1
            return memoryMatchPoints
        } else {
            memoryCells.append(MemoryRecord(shape: shape, recognitionCount: 1))
            return baseMatchPoints
        }
    }

    /// True when every antigen in the current wave has been matched.
    /// Drives the wave-clear UI cue. Mirrors `MacrophagePacmanScene`'s
    /// "all consumed" gate.
    public var currentWaveIsComplete: Bool {
        !antigens.isEmpty && antigens.allSatisfy { $0.isMatched }
    }

    /// Advance to the next wave. Returns `true` if the minigame is now
    /// complete. Memory cells persist across wave boundaries — the body
    /// remembers between waves.
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
        antigens.removeAll()
        memoryCells.removeAll()
        bcell = BCellState(position: Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        ))
        rng = SeededRNG(seed: 0)
    }

    private func repositionAnchors() {
        bcell.position = Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        )
    }
}
