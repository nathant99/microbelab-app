import Foundation

/// UserDefaults-backed persistence of streak counters. ForgeGamification's
/// `StreakManager` is a pure actor with in-memory state — callers own
/// persistence per `.claude/rules/forgekit.md` § ForgeGamification Quick
/// Reference. This store is that owned persistence for MicrobeLab.
///
/// COPPA-safe: only counters + a single `lastRecordedAt` timestamp persist.
/// No session-content PII flows through this store.
///
/// Per `.claude/rules/workflow.md` § Service Architecture: construct once at
/// app boot; pass through the view hierarchy. NOT a singleton.
@MainActor
public final class StreakStore {
    private struct Keys {
        let current: String
        let longest: String
        let freezes: String
        let lastRecordedAt: String

        init(prefix: String) {
            current = "\(prefix).current"
            longest = "\(prefix).longest"
            freezes = "\(prefix).freezes"
            lastRecordedAt = "\(prefix).lastRecordedAt"
        }
    }

    public static let defaultStartingFreezes: Int = 2

    private let defaults: UserDefaults
    private let keys: Keys
    private let startingFreezes: Int

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "MicrobeLab.Streak",
        startingFreezes: Int = StreakStore.defaultStartingFreezes
    ) {
        self.defaults = defaults
        self.keys = Keys(prefix: keyPrefix)
        self.startingFreezes = startingFreezes
    }

    public var currentStreak: Int {
        defaults.integer(forKey: keys.current)
    }

    public var longestStreak: Int {
        defaults.integer(forKey: keys.longest)
    }

    /// Available freezes. Fresh installs return the starting allotment
    /// per ForgeGamification's portfolio default — the first read is the
    /// only place the "default" matters since every subsequent persist
    /// writes the integer explicitly.
    public var availableFreezes: Int {
        if defaults.object(forKey: keys.freezes) == nil {
            return startingFreezes
        }
        return defaults.integer(forKey: keys.freezes)
    }

    public var lastRecordedAt: Date? {
        let stamp = defaults.double(forKey: keys.lastRecordedAt)
        return stamp > 0 ? Date(timeIntervalSinceReferenceDate: stamp) : nil
    }

    /// Persist the new state. Called after a `StreakManager.recordSession`
    /// returns + the GamificationService surface has been updated.
    public func save(
        currentStreak: Int,
        longestStreak: Int,
        availableFreezes: Int,
        recordedAt: Date
    ) {
        defaults.set(currentStreak, forKey: keys.current)
        defaults.set(longestStreak, forKey: keys.longest)
        defaults.set(availableFreezes, forKey: keys.freezes)
        defaults.set(recordedAt.timeIntervalSinceReferenceDate, forKey: keys.lastRecordedAt)
        DebugLog.state(
            "StreakStore — saved current=\(currentStreak) longest=\(longestStreak) freezes=\(availableFreezes)"
        )
    }

    /// Reset for debug + test surfaces.
    public func clear() {
        defaults.removeObject(forKey: keys.current)
        defaults.removeObject(forKey: keys.longest)
        defaults.removeObject(forKey: keys.freezes)
        defaults.removeObject(forKey: keys.lastRecordedAt)
    }
}

/// Pure derivation of a "rescue" prompt from prior streak state. The overlay
/// surfaces in `AppRootView` per `Docs/FEATURE_PLAN.md` § Engagement
/// Foundation → "warm broken-streak messaging".
///
/// Trauma-informed copy lives at the call site; this enum carries only
/// machine-readable kind + the prior-streak number the copy quotes.
public nonisolated enum StreakRescue: Sendable, Equatable {
    /// Kid lapsed ≥ 2 calendar days OR a recorded session reset the streak.
    /// The carrier integer is the prior streak we want to acknowledge.
    case lapsed(priorStreak: Int)
    case none

    /// Build a rescue prompt from persisted state + the current calendar.
    /// Falls through to `.none` on first-ever launch (no `lastRecordedAt`)
    /// and on same-day re-opens (kid already on the streak today).
    public static func from(
        lastRecordedAt: Date?,
        priorStreak: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> StreakRescue {
        guard let last = lastRecordedAt, priorStreak > 0 else { return .none }
        let lastDay = calendar.startOfDay(for: last)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        // 0 days = same calendar day; 1 day = consecutive (streak continues).
        // ≥ 2 days = the streak has broken regardless of freeze state, so
        // even a freeze-saved streak surfaces the warm acknowledgment.
        return days >= 2 ? .lapsed(priorStreak: priorStreak) : .none
    }
}
