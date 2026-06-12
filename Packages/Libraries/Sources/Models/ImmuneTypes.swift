import Foundation

/// Pathogen archetype for the innate-immunity minigame.
///
/// Per CLAUDE.md trauma-informed posture the minigame is framed as "your body's
/// quiet helpers" — pathogen NAMES stay generic (no COVID, no pandemic-era
/// references). Each kind has a different point value + spawn weight so waves
/// feel varied without authoring per-wave content.
public nonisolated enum PathogenKind: String, Codable, Sendable, CaseIterable {
    case common      // 1 point — slow + numerous
    case fast        // 3 points — quick + less common
    case stubborn    // 5 points — slow + rare

    public var pointValue: Int {
        switch self {
        case .common: return 1
        case .fast: return 3
        case .stubborn: return 5
        }
    }

    /// Relative speed in scene-coords per second.
    public var speed: Double {
        switch self {
        case .common: return 35
        case .fast: return 90
        case .stubborn: return 20
        }
    }
}

/// 2D vector kept as a pure `nonisolated` `Codable` `Sendable` value type.
/// Avoids depending on `CGPoint` / `CGVector` (which carry CoreGraphics
/// isolation + Codable surface drift across platforms).
public nonisolated struct Vec2: Codable, Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Vec2(x: 0, y: 0)

    public func distance(to other: Vec2) -> Double {
        let dx = other.x - x
        let dy = other.y - y
        return (dx * dx + dy * dy).squareRoot()
    }
}

/// Pure-value pathogen state. The visual SKNode is rendered separately —
/// this is the logic-bearing representation tests can exercise without GPU.
public nonisolated struct PathogenState: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let kind: PathogenKind
    public var position: Vec2
    public var velocity: Vec2

    public init(id: UUID = UUID(), kind: PathogenKind, position: Vec2, velocity: Vec2) {
        self.id = id
        self.kind = kind
        self.position = position
        self.velocity = velocity
    }
}

/// Pure-value macrophage state. The kid's avatar in the minigame.
public nonisolated struct MacrophageState: Codable, Sendable, Equatable {
    public var position: Vec2
    /// Movement radius in scene-coords. Pathogens within this radius are
    /// consumed in a single tick.
    public var consumeRadius: Double

    public init(position: Vec2, consumeRadius: Double = 28) {
        self.position = position
        self.consumeRadius = consumeRadius
    }
}
