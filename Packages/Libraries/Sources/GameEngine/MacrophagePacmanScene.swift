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
///
/// Logic (spawn / move / consume) lives behind a pure-value surface so the
/// SPM test target can exercise it without a GPU context. Visuals (SKNodes
/// per pathogen + macrophage) only activate via `configureVisuals()`.
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

    // MARK: - Pure logic state

    public private(set) var pathogens: [PathogenState] = []
    public private(set) var macrophage: MacrophageState
    private var rng: SeededRNG

    /// Per-wave pathogen counts (index 0 = wave 1). The Phase-1 difficulty
    /// curve climbs gently — DDA tuning lands in Phase 2 per FEATURE_PLAN.
    public let wavePathogenCounts: [Int]

    public init(
        size: CGSize,
        totalWaves: Int = 5,
        wavePathogenCounts: [Int] = [4, 6, 8, 10, 12],
        seed: UInt64 = 0
    ) {
        precondition(wavePathogenCounts.count == totalWaves,
                     "wavePathogenCounts must have one entry per wave")
        self.totalWaves = totalWaves
        self.wavePathogenCounts = wavePathogenCounts
        self.macrophage = MacrophageState(position: Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        ))
        self.rng = SeededRNG(seed: seed)
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
        pathogens.removeAll()
        macrophage = MacrophageState(position: Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        ))
        rng = SeededRNG(seed: 0)
    }

    // MARK: - Wave spawn (pure logic)

    /// Spawn the current wave's pathogens at random edges of the scene with
    /// inward velocities. Deterministic given the seeded RNG.
    public func spawnCurrentWave() {
        guard !isComplete else { return }
        let count = wavePathogenCounts[max(0, min(wavePathogenCounts.count - 1, wave - 1))]
        pathogens.removeAll()
        for _ in 0..<count {
            pathogens.append(makePathogen())
        }
    }

    private func makePathogen() -> PathogenState {
        let kind: PathogenKind
        let roll = rng.nextUnit()
        if roll < 0.6 {
            kind = .common
        } else if roll < 0.9 {
            kind = .fast
        } else {
            kind = .stubborn
        }
        // Spawn on a random edge so pathogens visibly enter the field.
        let width = Double(size.width)
        let height = Double(size.height)
        let position: Vec2
        let velocity: Vec2
        switch Int(rng.nextUnit() * 4) {
        case 0: // left edge moving right
            position = Vec2(x: 0, y: rng.nextUnit() * height)
            velocity = Vec2(x: kind.speed, y: 0)
        case 1: // right edge moving left
            position = Vec2(x: width, y: rng.nextUnit() * height)
            velocity = Vec2(x: -kind.speed, y: 0)
        case 2: // bottom edge moving up
            position = Vec2(x: rng.nextUnit() * width, y: 0)
            velocity = Vec2(x: 0, y: kind.speed)
        default: // top edge moving down
            position = Vec2(x: rng.nextUnit() * width, y: height)
            velocity = Vec2(x: 0, y: -kind.speed)
        }
        return PathogenState(kind: kind, position: position, velocity: velocity)
    }

    // MARK: - Per-tick logic

    /// Advance pathogen positions by `delta` seconds, bouncing off the scene
    /// bounds. Pure-value mutation — exposes a deterministic surface tests
    /// can drive without GPU.
    public func advancePathogens(by delta: TimeInterval) {
        guard !isComplete, delta > 0 else { return }
        let width = Double(size.width)
        let height = Double(size.height)
        for index in pathogens.indices {
            var p = pathogens[index]
            p.position.x += p.velocity.x * delta
            p.position.y += p.velocity.y * delta
            if p.position.x < 0 || p.position.x > width {
                p.velocity.x = -p.velocity.x
                p.position.x = max(0, min(width, p.position.x))
            }
            if p.position.y < 0 || p.position.y > height {
                p.velocity.y = -p.velocity.y
                p.position.y = max(0, min(height, p.position.y))
            }
            pathogens[index] = p
        }
    }

    /// Move the macrophage by `delta` scene-coord units, clamped to bounds.
    public func moveMacrophage(by delta: Vec2) {
        guard !isComplete else { return }
        let width = Double(size.width)
        let height = Double(size.height)
        let nextX = max(0, min(width, macrophage.position.x + delta.x))
        let nextY = max(0, min(height, macrophage.position.y + delta.y))
        macrophage.position = Vec2(x: nextX, y: nextY)
    }

    /// Remove pathogens within consume radius + award their point value.
    /// Returns the count consumed this tick.
    @discardableResult
    public func consumePathogensInRadius() -> Int {
        guard !isComplete else { return 0 }
        var consumed = 0
        var awarded = 0
        pathogens.removeAll { pathogen in
            if pathogen.position.distance(to: macrophage.position) <= macrophage.consumeRadius {
                consumed += 1
                awarded += pathogen.kind.pointValue
                return true
            }
            return false
        }
        if awarded > 0 {
            recordConsume(value: awarded)
        }
        return consumed
    }

    private func repositionAnchors() {
        macrophage.position = Vec2(
            x: Double(size.width) / 2,
            y: Double(size.height) / 2
        )
    }
}
