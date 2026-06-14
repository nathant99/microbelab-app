import Foundation

/// Top-level mode selector for the immune defense surface. Mirrors the
/// pedagogy beat from `Docs/TECHNICAL_DESIGN.md` § Phase 2 — innate
/// (macrophages clean up early intruders) → adaptive (B-cells recognize
/// shapes and remember between encounters).
///
/// Pure enum value type so view-local state machines (`ImmuneGameMachine`
/// in SharedUI) can switch on it without rippling SwiftUI dependencies.
public nonisolated enum ImmuneMode: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case innate
    case adaptive

    /// Human-readable label for the mode picker. Trauma-informed
    /// register: the labels frame the body's response as helping work,
    /// never warfare. Stoplist (`fight` / `attack` / `destroy` / `kill` /
    /// `war` / `enemy` / `battle` / `weapon` / `soldier` / `warrior`) is
    /// pinned by parameterized test.
    public var displayName: String {
        switch self {
        case .innate: return "Macrophage patrol"
        case .adaptive: return "B-cell library"
        }
    }

    /// Short tagline used by the mode picker subtitle. Keeps the
    /// pedagogy beat foregrounded: innate is patrol-style cleanup,
    /// adaptive is shape-matching + memory.
    public var tagline: String {
        switch self {
        case .innate: return "Patrol the area; help when something doesn't belong."
        case .adaptive: return "Match shapes; the body remembers between encounters."
        }
    }

    /// SF Symbol for picker affordance + accessibility hint anchors.
    public var systemImage: String {
        switch self {
        case .innate: return "shield.lefthalf.filled"
        case .adaptive: return "puzzlepiece.fill"
        }
    }
}
