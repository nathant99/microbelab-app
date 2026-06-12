import Foundation

/// Microscope magnification tier. Drives LOD sprite atlas swap at boundary transitions.
///
/// Per `Docs/TECHNICAL_DESIGN.md` § Domain Model. Each step is one tactile pinch-zoom
/// snap; UI never lands mid-tier.
public nonisolated enum ZoomTier: Int, CaseIterable, Codable, Sendable, Comparable {
    case unaided = 0       // 1× — naked eye
    case light = 1         // 100× — light microscope
    case fluorescence = 2  // 1000× — fluorescence microscope
    case electron = 3      // 10000×+ — electron microscope

    public static func < (lhs: ZoomTier, rhs: ZoomTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Approximate magnification factor surfaced in the HUD.
    public var magnification: Int {
        switch self {
        case .unaided: return 1
        case .light: return 100
        case .fluorescence: return 1_000
        case .electron: return 10_000
        }
    }

    /// Human-readable HUD label (e.g. "1×", "100×", "1 000×").
    public var displayLabel: String {
        switch self {
        case .unaided: return "1×"
        case .light: return "100×"
        case .fluorescence: return "1 000×"
        case .electron: return "10 000×"
        }
    }

    public var next: ZoomTier? {
        ZoomTier(rawValue: rawValue + 1)
    }

    public var previous: ZoomTier? {
        ZoomTier(rawValue: rawValue - 1)
    }
}
