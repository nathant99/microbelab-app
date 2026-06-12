import Foundation

/// UserDefaults-backed on-device retention tracking per `Docs/FEATURE_PLAN.md`
/// § Engagement Foundation — "Retention metrics baseline — D1 / D7 / D30
/// (on-device, privacy-first)".
///
/// **Privacy posture (COPPA + FTC 2026 compliant)**:
///
/// - Counts + distinct calendar days only — never a per-event log
/// - Stays ON DEVICE; no outbound transmission, no third-party SDK
/// - Persists a small day-set (capped at 32 entries) so storage is bounded
/// - Per `.claude/rules/age-assurance.md` § 2026 FTC COPPA — no PII flows
///   through this store
///
/// Derives the standard mobile-product cohort metrics:
///
/// - **D1**: kid returned ON or AFTER day-1 of install (within the first 48h)
/// - **D7**: kid returned at some point in days 2-7 after install
/// - **D30**: kid returned at some point in days 2-30 after install
///
/// Per `.claude/rules/workflow.md` § Service Architecture: construct once at
/// app boot; pass through the view hierarchy. NOT a singleton.
@MainActor
public final class RetentionMetricsStore {
    /// Cap on persisted distinct-day entries. Day-30 is the deepest cohort we
    /// care about, plus a small buffer for the install day + late-bird returns.
    /// Once exceeded, the OLDEST entries get evicted to keep storage bounded.
    public static let dayLogCapacity = 32

    private let defaults: UserDefaults
    private let installKey: String
    private let daysKey: String
    private let calendar: Calendar

    public private(set) var installDate: Date?
    /// Distinct calendar days on which the kid had a session, stored as
    /// `Date` values representing `startOfDay(for:)` per the user's current
    /// calendar. Order is preserved (oldest first) so eviction is FIFO.
    public private(set) var distinctSessionDays: [Date]

    public init(
        defaults: UserDefaults = .standard,
        installKey: String = "MicrobeLab.RetentionInstallAt",
        daysKey: String = "MicrobeLab.RetentionSessionDays",
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.installKey = installKey
        self.daysKey = daysKey
        self.calendar = calendar

        let stamp = defaults.double(forKey: installKey)
        self.installDate = stamp > 0 ? Date(timeIntervalSinceReferenceDate: stamp) : nil

        let rawDays = (defaults.array(forKey: daysKey) as? [Double]) ?? []
        self.distinctSessionDays = rawDays
            .sorted()
            .map { Date(timeIntervalSinceReferenceDate: $0) }
    }

    /// Stamp a session start. Idempotent within a calendar day — calling
    /// twice on the same date doesn't grow the day-set. Sets the install
    /// date on first call.
    public func recordSession(now: Date = .now) {
        if installDate == nil {
            installDate = now
            defaults.set(now.timeIntervalSinceReferenceDate, forKey: installKey)
            DebugLog.state("RetentionMetricsStore — installDate=\(now)")
        }
        let today = calendar.startOfDay(for: now)
        if distinctSessionDays.contains(today) { return }
        distinctSessionDays.append(today)
        if distinctSessionDays.count > Self.dayLogCapacity {
            distinctSessionDays.removeFirst(distinctSessionDays.count - Self.dayLogCapacity)
        }
        let encoded = distinctSessionDays.map(\.timeIntervalSinceReferenceDate)
        defaults.set(encoded, forKey: daysKey)
        DebugLog.state("RetentionMetricsStore — recorded day=\(today); totalDays=\(distinctSessionDays.count)")
    }

    /// Number of full calendar days between install and `now`. Returns `nil`
    /// if no install timestamp is recorded yet.
    public func daysSinceInstall(now: Date = .now) -> Int? {
        guard let installDate else { return nil }
        let installDay = calendar.startOfDay(for: installDate)
        let nowDay = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: installDay, to: nowDay).day
    }

    /// True when the kid returned within the D1 window (any session on or
    /// before day 1, excluding the install day itself, OR ≥ 2 distinct
    /// session days). False until the kid plays a second day.
    public func returnedWithinD1(now: Date = .now) -> Bool {
        returnedWithin(window: 1, now: now)
    }

    public func returnedWithinD7(now: Date = .now) -> Bool {
        returnedWithin(window: 7, now: now)
    }

    public func returnedWithinD30(now: Date = .now) -> Bool {
        returnedWithin(window: 30, now: now)
    }

    /// Total distinct calendar days with at least one session. The session
    /// count store mirrors raw launch counts; this is the engagement-depth
    /// signal.
    public var totalDistinctSessionDays: Int {
        distinctSessionDays.count
    }

    /// Reset for debug + test surfaces.
    public func clear() {
        installDate = nil
        distinctSessionDays = []
        defaults.removeObject(forKey: installKey)
        defaults.removeObject(forKey: daysKey)
    }

    // MARK: - Internals

    /// Returns true when at least one session day falls AFTER the install
    /// day but within `window` calendar days of install. Install-day-only
    /// returns false (D1 needs the second day, not the first).
    private func returnedWithin(window: Int, now: Date = .now) -> Bool {
        guard let installDate else { return false }
        let installDay = calendar.startOfDay(for: installDate)
        let nowDay = calendar.startOfDay(for: now)
        // Window upper bound is min(install + window, today) so we don't
        // count future days the kid hasn't reached yet.
        guard let windowEnd = calendar.date(byAdding: .day, value: window, to: installDay) else {
            return false
        }
        let effectiveEnd = min(windowEnd, nowDay)
        guard effectiveEnd > installDay else { return false }
        return distinctSessionDays.contains { day in
            day > installDay && day <= effectiveEnd
        }
    }
}
