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

// MARK: - Adaptive immunity (Phase 2)

/// Antigen / antibody shape categories for the Phase 2 B-cell antibody-
/// matching minigame.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Trauma-Informed Design Posture the
/// adaptive-immunity surface is framed as SHAPE-MATCHING + recognition,
/// never warfare. Each `AntigenKind` has a complementary `AntibodyShape`
/// (`.spiral` ↔ `.spiral`; `.ridged` ↔ `.ridged`; etc.) — matching is
/// the pedagogy beat, not destruction.
///
/// Kept generic / abstract so the shape register is curriculum-truth
/// (most antigens are shape-recognition surfaces, NOT named pathogens
/// the kid could fear). No COVID, no pandemic-era references.
public nonisolated enum AntibodyShape: String, Codable, Sendable, CaseIterable {
    case spiral
    case ridged
    case branched
    case rounded

    /// Pedagogically-canonical complementary shape. In real adaptive
    /// immunity the antibody's binding region mirrors the antigen
    /// epitope — for kid pedagogy we surface this as "matching shapes."
    public var complement: AntibodyShape {
        // Symmetric: each shape pairs with itself in the simplified
        // pedagogy register. Phase 2.5+ could surface mirror-pairs once
        // the kid has internalized basic shape-recognition.
        return self
    }
}

/// Antigen marker surfaced for the kid to recognize. Pure-value state so
/// the SPM test target can drive the minigame logic without GPU.
public nonisolated struct AntigenState: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let shape: AntibodyShape
    public var position: Vec2
    public var velocity: Vec2
    /// `true` once a complementary antibody has been matched to this
    /// antigen. Matched antigens stop being targetable but stay in the
    /// pool until cleared at wave end (so the kid sees their progress).
    public var isMatched: Bool

    public init(
        id: UUID = UUID(),
        shape: AntibodyShape,
        position: Vec2,
        velocity: Vec2 = .zero,
        isMatched: Bool = false
    ) {
        self.id = id
        self.shape = shape
        self.position = position
        self.velocity = velocity
        self.isMatched = isMatched
    }
}

/// The kid's B-cell avatar — carries the currently-loaded antibody
/// shape. Loading a new shape replaces the previous one.
public nonisolated struct BCellState: Codable, Sendable, Equatable {
    public var position: Vec2
    public var loadedAntibody: AntibodyShape
    /// Match radius in scene-coords. Antigens within this radius whose
    /// `shape` matches `loadedAntibody.complement` are eligible for
    /// matching on the kid's next confirm tap.
    public var matchRadius: Double

    public init(
        position: Vec2,
        loadedAntibody: AntibodyShape = .spiral,
        matchRadius: Double = 32
    ) {
        self.position = position
        self.loadedAntibody = loadedAntibody
        self.matchRadius = matchRadius
    }
}

/// Memory cells the body retains after a successful match. Each entry
/// pairs a shape with the count of how many times it has been
/// recognized — the pedagogy beat for the `AdaptiveImmuneScenario`
/// `.recallFromMemory` case (per `AIMentor.MentorGenerables`).
public nonisolated struct MemoryRecord: Codable, Sendable, Equatable {
    public let shape: AntibodyShape
    public var recognitionCount: Int

    public init(shape: AntibodyShape, recognitionCount: Int = 1) {
        self.shape = shape
        self.recognitionCount = recognitionCount
    }
}
