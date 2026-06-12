import Foundation

/// UserDefaults-backed monotonic counter tracking how many sessions the kid
/// has launched. Drives **progressive disclosure** per `Docs/FEATURE_PLAN.md`
/// § Onboarding & Child Safety → "Progressive disclosure":
///
/// > Session 1: microscope + codex only → Sessions 2-3: + simulator → Sessions
/// > 4+: full feature set
///
/// The store is COPPA-safe: nothing but the integer counter persists. No
/// session-content PII passes through this store.
///
/// Per `.claude/rules/workflow.md` § Service Architecture: construct once at
/// app boot; pass through the view hierarchy. NOT a singleton.
@MainActor
public final class SessionCountStore {
    private let defaults: UserDefaults
    private let key: String
    public private(set) var sessionCount: Int

    public init(defaults: UserDefaults = .standard, key: String = "MicrobeLab.SessionCount") {
        self.defaults = defaults
        self.key = key
        self.sessionCount = defaults.integer(forKey: key)
    }

    /// Increment the counter. Call on app open after `LastActiveStore`
    /// records the new session-start timestamp.
    public func incrementForSessionStart() {
        sessionCount += 1
        defaults.set(sessionCount, forKey: key)
        DebugLog.state("SessionCountStore — sessionCount=\(sessionCount)")
    }

    /// Reset for debug + test surfaces.
    public func clear() {
        sessionCount = 0
        defaults.set(0, forKey: key)
    }
}

/// Progressive-disclosure tab visibility derived from session count. Pure
/// nonisolated value — testable without UserDefaults round-trips.
///
/// Phasing rationale (`Docs/FEATURE_PLAN.md` § Onboarding & Child Safety
/// + § Engagement Foundation):
///
/// - **Session 1** — Explore (microscope) + Codex only. Kid needs the aha
///   moment WITHOUT decision fatigue from the simulator + progress + profile
///   surfaces.
/// - **Sessions 2-3** — adds Microbiome simulator. The simulator's feeding-
///   mode + antibiotic decisions assume a baseline cast familiarity built in
///   sessions 1-2.
/// - **Session 4+** — full tab set including Progress + Profile chrome.
public nonisolated enum TabDisclosure: Sendable, Equatable {
    case session1
    case session2to3
    case fullDisclosure

    public static func from(sessionCount: Int) -> TabDisclosure {
        switch sessionCount {
        case ..<2: return .session1
        case 2...3: return .session2to3
        default: return .fullDisclosure
        }
    }

    public var showsMicrobiome: Bool {
        switch self {
        case .session1: return false
        case .session2to3, .fullDisclosure: return true
        }
    }

    public var showsProgress: Bool {
        switch self {
        case .session1, .session2to3: return false
        case .fullDisclosure: return true
        }
    }

    public var showsProfile: Bool {
        switch self {
        case .session1, .session2to3: return false
        case .fullDisclosure: return true
        }
    }
}
