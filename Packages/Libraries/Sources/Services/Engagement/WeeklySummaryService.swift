import Foundation
import Observation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Pure value-type composition of the weekly-summary notification
/// payload. Built as a `nonisolated struct` so the composition can be
/// unit-tested without needing `UNUserNotificationCenter` (which is a
/// system singleton + hard to fake).
///
/// Trauma-informed posture (load-bearing — pinned by parameterized test):
///
/// - Quiet weeks (0 distinct active days, 0 XP earned, no achievements)
///   read as "quiet week — that's allowed", NEVER "you skipped a week"
/// - Routine weeks lead with a calm acknowledgement, NEVER engagement
///   pressure
/// - Streaks aren't named as the headline — engagement counts ARE the
///   data, but the body never says "your streak is in danger" or
///   "you'll lose your streak if..."
/// - No "compared to last week" benchmarking — the notification is a
///   warm one-shot, not a leaderboard nudge
public nonisolated struct WeeklySummaryNotificationContent: Sendable, Equatable {
    public let title: String
    public let body: String
    public let categoryIdentifier: String

    public init(title: String, body: String, categoryIdentifier: String) {
        self.title = title
        self.body = body
        self.categoryIdentifier = categoryIdentifier
    }

    /// Build a trauma-safe weekly-summary notification from a snapshot.
    /// Pure function — same input → same output. Empty / zero / quiet
    /// week is the canonical edge case + reads as a calm acknowledgement
    /// not absence.
    public static func compose(from snapshot: ProgressReportSnapshot) -> WeeklySummaryNotificationContent {
        let isQuiet = snapshot.activitiesCompleted == 0 && snapshot.totalXP == 0
        let title: String
        let body: String
        if isQuiet {
            title = "Microbiome check-in"
            body = "A quiet week — that's allowed. The microbes are still here when you want to look."
        } else {
            title = "Your week with the microbes"
            let microbeNote: String
            if snapshot.activitiesCompleted > 0 {
                let count = snapshot.activitiesCompleted
                microbeNote = "You earned \(count) badge\(count == 1 ? "" : "s") this week. "
            } else {
                microbeNote = ""
            }
            let streakNote: String
            if snapshot.currentStreak > 1 {
                streakNote = "You returned \(snapshot.currentStreak) days in a row. "
            } else {
                streakNote = ""
            }
            let xpNote: String
            if snapshot.totalXP > 0 {
                xpNote = "Tap in when you have time — there's always more to see."
            } else {
                xpNote = "Pick up where you left off whenever you're ready."
            }
            body = microbeNote + streakNote + xpNote
        }
        return WeeklySummaryNotificationContent(
            title: title,
            body: body,
            categoryIdentifier: "com.microbelab.weekly_summary"
        )
    }
}

/// Adapter the service uses to talk to `UNUserNotificationCenter`.
/// Defining the seam at the protocol level lets the test suite pass a
/// recording fake without exercising the system singleton (which
/// requires real entitlements + a running notification daemon).
public protocol UserNotificationScheduler: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(identifier: String, content: WeeklySummaryNotificationContent, trigger: WeeklySummaryTrigger) async
    func cancel(identifier: String) async
    func pendingFireDate(identifier: String) async -> Date?
}

/// Pure value-type calendar trigger for the weekly summary. Saturday
/// 9am is the portfolio default (per `.claude/rules/age-assurance.md`
/// + parent-cadence convention — weekend morning lands when the
/// adult is most likely to engage with the report). Adapters convert
/// this into a `UNCalendarNotificationTrigger`.
public nonisolated struct WeeklySummaryTrigger: Sendable, Equatable {
    public let weekday: Int  // 1 = Sunday, 7 = Saturday per `Calendar.dateComponents(_:from:)`
    public let hour: Int
    public let minute: Int
    public let repeats: Bool

    public init(
        weekday: Int = 7,
        hour: Int = 9,
        minute: Int = 0,
        repeats: Bool = true
    ) {
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
        self.repeats = repeats
    }
}

#if canImport(UserNotifications)
/// Production-side adapter that wraps `UNUserNotificationCenter.current()`.
/// Defaults to `.current()`; tests inject a recording fake instead.
public struct SystemNotificationScheduler: UserNotificationScheduler {
    public init() {}

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            DebugLog.error("SystemNotificationScheduler.requestAuthorization failed", error: error)
            return false
        }
    }

    public func schedule(
        identifier: String,
        content: WeeklySummaryNotificationContent,
        trigger: WeeklySummaryTrigger
    ) async {
        let body = UNMutableNotificationContent()
        body.title = content.title
        body.body = content.body
        body.categoryIdentifier = content.categoryIdentifier
        body.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = trigger.weekday
        dateComponents.hour = trigger.hour
        dateComponents.minute = trigger.minute

        let calendarTrigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: trigger.repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: body,
            trigger: calendarTrigger
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
            DebugLog.permission("SystemNotificationScheduler scheduled \(identifier)")
        } catch {
            DebugLog.error("SystemNotificationScheduler.schedule failed", error: error)
        }
    }

    public func cancel(identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        DebugLog.permission("SystemNotificationScheduler cancelled \(identifier)")
    }

    public func pendingFireDate(identifier: String) async -> Date? {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        guard let match = pending.first(where: { $0.identifier == identifier }) else { return nil }
        if let calendarTrigger = match.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        return nil
    }
}
#endif

/// MainActor `@Observable` coordinator for the opt-in weekly summary
/// local notification. Closes the FEATURE_PLAN.md § Parent Integration
/// → "Weekly summary" item.
///
/// Authorization + scheduling are **opt-in by default** per the 2026
/// FTC COPPA Rule Amendments — `AppSettings.weeklySummaryNotificationEnabled`
/// defaults to false; the toggle in SettingsView's "For parents" section
/// gates both on parental-gate adult confirm AND a
/// `ParentalConsentService.hasValidConsent(for: .weeklySummaryNotifications)`
/// record. Toggling on without consent never schedules.
///
/// The notification is **local-only** (`UNUserNotificationCenter` + a
/// `UNCalendarNotificationTrigger`). No push token registration, no
/// cloud, no third-party SDK. Per the FTC rule's "educational push
/// notifications are explicitly preserved" carve-out + portfolio
/// "no PII flows" baseline.
///
/// Trauma-informed posture (cross-references the composer):
///
/// - Quiet-week framing — never "you skipped a week"
/// - No engagement pressure ("don't lose your streak")
/// - One-shot warm tone — the kid (or adult on the kid's behalf) sees a
///   calm reminder, never a guilt trip
@MainActor
@Observable
public final class WeeklySummaryService {
    public static let requestIdentifier = "com.microbelab.weekly_summary.request"

    public private(set) var lastScheduledAt: Date?
    public private(set) var authorizationGranted: Bool = false

    private let scheduler: UserNotificationScheduler
    private let trigger: WeeklySummaryTrigger

    public init(
        scheduler: UserNotificationScheduler? = nil,
        trigger: WeeklySummaryTrigger = WeeklySummaryTrigger()
    ) {
        #if canImport(UserNotifications)
        self.scheduler = scheduler ?? SystemNotificationScheduler()
        #else
        // Non-UserNotifications platforms (Linux, etc.) — supply a
        // no-op scheduler when the caller doesn't inject one. The
        // production app runs on iOS where UserNotifications is
        // always available.
        self.scheduler = scheduler ?? NoOpScheduler()
        #endif
        self.trigger = trigger
    }

    /// Request authorization to post local notifications. Returns true
    /// if the user (or system in CI) has granted. The service caches
    /// the result + surfaces it through `authorizationGranted` so the
    /// SettingsView toggle can disable itself when the system has
    /// previously denied.
    public func requestAuthorization() async -> Bool {
        let granted = await scheduler.requestAuthorization()
        authorizationGranted = granted
        DebugLog.permission("WeeklySummaryService authorization=\(granted)")
        return granted
    }

    /// Schedule the recurring summary using `snapshot` as the body
    /// content. Idempotent — calling twice replaces the prior schedule
    /// so the next fire reflects the freshest snapshot.
    public func scheduleNextSummary(from snapshot: ProgressReportSnapshot) async {
        let content = WeeklySummaryNotificationContent.compose(from: snapshot)
        await scheduler.schedule(
            identifier: Self.requestIdentifier,
            content: content,
            trigger: trigger
        )
        lastScheduledAt = Date()
    }

    /// Cancel the scheduled summary (e.g., when the parent revokes the
    /// consent or toggles the setting off).
    public func cancel() async {
        await scheduler.cancel(identifier: Self.requestIdentifier)
        lastScheduledAt = nil
    }

    /// Next-fire date for surfacing in SettingsView's "For parents"
    /// section so the adult can see when the next reminder lands.
    public func pendingFireDate() async -> Date? {
        await scheduler.pendingFireDate(identifier: Self.requestIdentifier)
    }
}

#if !canImport(UserNotifications)
/// Linux + other platforms without UserNotifications. The service never
/// actually runs there (the app ships iOS-only) but the SPM package
/// must still build for portfolio-wide CI cross-platform checks.
private struct NoOpScheduler: UserNotificationScheduler {
    func requestAuthorization() async -> Bool { false }
    func schedule(identifier: String, content: WeeklySummaryNotificationContent, trigger: WeeklySummaryTrigger) async {}
    func cancel(identifier: String) async {}
    func pendingFireDate(identifier: String) async -> Date? { nil }
}
#endif
