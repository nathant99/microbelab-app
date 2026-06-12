import Foundation

/// UserDefaults-backed persistence of the last-session timestamp.
///
/// Drives the welcome-back overlay surface per `Docs/FEATURE_PLAN.md` §
/// Engagement Foundation — when ≥ 3 calendar days have passed, the app shows
/// a warm greeting on next launch.
///
/// Per `.claude/rules/age-assurance.md` § 2026 FTC COPPA — only a timestamp
/// is stored. No session-content PII passes through this store.
@MainActor
public final class LastActiveStore {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "MicrobeLab.LastActiveAt") {
        self.defaults = defaults
        self.key = key
    }

    /// The persisted last-session timestamp, or `nil` if no session has been
    /// recorded yet.
    public var lastActiveAt: Date? {
        let stamp = defaults.double(forKey: key)
        return stamp > 0 ? Date(timeIntervalSinceReferenceDate: stamp) : nil
    }

    /// Stamp a session start. Called from `AppRootView.task` on launch.
    public func recordSessionStart(now: Date = .now) {
        defaults.set(now.timeIntervalSinceReferenceDate, forKey: key)
        DebugLog.state("LastActiveStore — recorded \(now)")
    }

    /// Number of FULL calendar days since the last session, or `nil` if no
    /// prior session was recorded. Uses the user's current `Calendar` so the
    /// midnight boundary respects locale.
    public func daysSinceLastActive(now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let last = lastActiveAt else { return nil }
        let lastDay = calendar.startOfDay(for: last)
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: lastDay, to: today).day
    }

    /// True when the kid has been gone ≥ 3 days. First-ever launch returns
    /// `false` so the welcome-back overlay never shows on a fresh install.
    public func shouldShowWelcomeBack(now: Date = .now, calendar: Calendar = .current) -> Bool {
        (daysSinceLastActive(now: now, calendar: calendar) ?? 0) >= 3
    }

    /// Reset for debug + test surfaces.
    public func clear() {
        defaults.removeObject(forKey: key)
    }
}
