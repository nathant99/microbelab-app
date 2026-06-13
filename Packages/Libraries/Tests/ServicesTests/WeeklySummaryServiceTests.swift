import Foundation
import Testing
@testable import Services

@Suite("WeeklySummaryService")
@MainActor
struct WeeklySummaryServiceTests {
    /// Recording adapter so we can assert what the service requested
    /// without touching the real `UNUserNotificationCenter` (which
    /// requires entitlements + a system daemon).
    private final class RecordingScheduler: UserNotificationScheduler, @unchecked Sendable {
        var authorizationRequested = 0
        var scheduledIdentifiers: [String] = []
        var scheduledContents: [WeeklySummaryNotificationContent] = []
        var scheduledTriggers: [WeeklySummaryTrigger] = []
        var cancelledIdentifiers: [String] = []
        var authorizationOutcome: Bool

        init(authorizationOutcome: Bool = true) {
            self.authorizationOutcome = authorizationOutcome
        }

        func requestAuthorization() async -> Bool {
            authorizationRequested += 1
            return authorizationOutcome
        }

        func schedule(identifier: String, content: WeeklySummaryNotificationContent, trigger: WeeklySummaryTrigger) async {
            scheduledIdentifiers.append(identifier)
            scheduledContents.append(content)
            scheduledTriggers.append(trigger)
        }

        func cancel(identifier: String) async {
            cancelledIdentifiers.append(identifier)
        }

        func pendingFireDate(identifier: String) async -> Date? {
            scheduledIdentifiers.contains(identifier) ? Date(timeIntervalSinceReferenceDate: 0) : nil
        }
    }

    // MARK: - Composer

    @Test func composerQuietWeekReadsAsAllowed() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 0,
            totalDurationMinutes: 0,
            activitiesCompleted: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalXP: 0,
            activeDays: 0,
            standardProficiencies: []
        )
        let content = WeeklySummaryNotificationContent.compose(from: snapshot)
        #expect(content.body.lowercased().contains("quiet"))
        #expect(content.body.lowercased().contains("allowed"))
        // Stoplist — the quiet-week body must NEVER imply absence as failure.
        for stop in ["missed", "skipped", "lost", "behind", "failure"] {
            #expect(!content.body.lowercased().contains(stop))
        }
    }

    @Test func composerActiveWeekMentionsBadgesAndStreak() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 5,
            totalDurationMinutes: 60,
            activitiesCompleted: 3,
            currentStreak: 4,
            longestStreak: 4,
            totalXP: 250,
            activeDays: 4,
            standardProficiencies: []
        )
        let content = WeeklySummaryNotificationContent.compose(from: snapshot)
        #expect(content.body.contains("3"))
        #expect(content.body.lowercased().contains("badge"))
        #expect(content.body.contains("4"))
    }

    @Test func composerSingularBadgeStreakHandling() {
        let snapshot = ProgressReportSnapshot(
            totalSessions: 2,
            totalDurationMinutes: 15,
            activitiesCompleted: 1,
            currentStreak: 1, // singular streak shouldn't render the "returned N days" clause
            longestStreak: 1,
            totalXP: 50,
            activeDays: 1,
            standardProficiencies: []
        )
        let content = WeeklySummaryNotificationContent.compose(from: snapshot)
        #expect(content.body.contains("1 badge"))
        // Single-day streak suppresses the multi-day return narrative.
        #expect(!content.body.lowercased().contains("days in a row"))
    }

    @Test func composerStoplistHoldsAcrossSnapshotCombinations() {
        // Cross-product of (activities, streak, XP) — even with engagement
        // active, the body must NEVER use loss-aversion language.
        let stops = ["dont lose", "don't lose", "in danger", "compared", "punish"]
        let cases: [ProgressReportSnapshot] = [
            ProgressReportSnapshot(totalSessions: 0, totalDurationMinutes: 0, activitiesCompleted: 0, currentStreak: 0, longestStreak: 0, totalXP: 0, activeDays: 0, standardProficiencies: []),
            ProgressReportSnapshot(totalSessions: 7, totalDurationMinutes: 90, activitiesCompleted: 5, currentStreak: 7, longestStreak: 7, totalXP: 600, activeDays: 7, standardProficiencies: []),
            ProgressReportSnapshot(totalSessions: 3, totalDurationMinutes: 20, activitiesCompleted: 0, currentStreak: 0, longestStreak: 2, totalXP: 0, activeDays: 1, standardProficiencies: [])
        ]
        for snapshot in cases {
            let content = WeeklySummaryNotificationContent.compose(from: snapshot)
            for stop in stops {
                #expect(!content.body.lowercased().contains(stop), "Body \"\(content.body)\" contains stop-word \"\(stop)\"")
            }
        }
    }

    @Test func composerCategoryIdentifierStable() {
        // The category identifier is what `UNUserNotificationCenter` uses
        // to attach actions; changing it silently invalidates any
        // already-scheduled fire. Lock the canonical string.
        let content = WeeklySummaryNotificationContent.compose(
            from: ProgressReportSnapshot(
                totalSessions: 0, totalDurationMinutes: 0, activitiesCompleted: 0,
                currentStreak: 0, longestStreak: 0, totalXP: 0, activeDays: 0,
                standardProficiencies: []
            )
        )
        #expect(content.categoryIdentifier == "com.microbelab.weekly_summary")
    }

    // MARK: - Service

    @Test func freshServiceUnauthorized() {
        let scheduler = RecordingScheduler(authorizationOutcome: false)
        let service = WeeklySummaryService(scheduler: scheduler)
        #expect(service.authorizationGranted == false)
        #expect(service.lastScheduledAt == nil)
    }

    @Test func requestAuthorizationPropagatesOutcome() async {
        let scheduler = RecordingScheduler(authorizationOutcome: true)
        let service = WeeklySummaryService(scheduler: scheduler)
        let granted = await service.requestAuthorization()
        #expect(granted == true)
        #expect(service.authorizationGranted == true)
        #expect(scheduler.authorizationRequested == 1)
    }

    @Test func scheduleNextSummaryRecordsRequest() async {
        let scheduler = RecordingScheduler()
        let service = WeeklySummaryService(scheduler: scheduler)
        let snapshot = ProgressReportSnapshot(
            totalSessions: 4, totalDurationMinutes: 45, activitiesCompleted: 2,
            currentStreak: 3, longestStreak: 3, totalXP: 200, activeDays: 3,
            standardProficiencies: []
        )
        await service.scheduleNextSummary(from: snapshot)
        #expect(scheduler.scheduledIdentifiers == [WeeklySummaryService.requestIdentifier])
        #expect(service.lastScheduledAt != nil)
        // The body composer ran end-to-end through the service.
        let composed = try? #require(scheduler.scheduledContents.first)
        #expect(composed?.body.contains("2 badge") == true)
    }

    @Test func cancelClearsLastScheduledAt() async {
        let scheduler = RecordingScheduler()
        let service = WeeklySummaryService(scheduler: scheduler)
        await service.scheduleNextSummary(from: ProgressReportSnapshot(
            totalSessions: 1, totalDurationMinutes: 5, activitiesCompleted: 1,
            currentStreak: 1, longestStreak: 1, totalXP: 50, activeDays: 1,
            standardProficiencies: []
        ))
        #expect(service.lastScheduledAt != nil)
        await service.cancel()
        #expect(service.lastScheduledAt == nil)
        #expect(scheduler.cancelledIdentifiers == [WeeklySummaryService.requestIdentifier])
    }

    @Test func triggerDefaultIsSaturdayNineAM() {
        let trigger = WeeklySummaryTrigger()
        #expect(trigger.weekday == 7)
        #expect(trigger.hour == 9)
        #expect(trigger.minute == 0)
        #expect(trigger.repeats == true)
    }

    @Test func customTriggerThreadsThroughToScheduler() async {
        let scheduler = RecordingScheduler()
        let custom = WeeklySummaryTrigger(weekday: 1, hour: 17, minute: 30, repeats: false)
        let service = WeeklySummaryService(scheduler: scheduler, trigger: custom)
        await service.scheduleNextSummary(from: ProgressReportSnapshot(
            totalSessions: 0, totalDurationMinutes: 0, activitiesCompleted: 0,
            currentStreak: 0, longestStreak: 0, totalXP: 0, activeDays: 0,
            standardProficiencies: []
        ))
        let scheduled = try? #require(scheduler.scheduledTriggers.first)
        #expect(scheduled?.weekday == 1)
        #expect(scheduled?.hour == 17)
        #expect(scheduled?.minute == 30)
        #expect(scheduled?.repeats == false)
    }

    @Test func requestIdentifierStability() {
        // The identifier is the canonical join key between the scheduler
        // and pending fire requests. Locking it makes sure a refactor
        // doesn't orphan previously-scheduled fires on a kid's device.
        #expect(WeeklySummaryService.requestIdentifier == "com.microbelab.weekly_summary.request")
    }
}
