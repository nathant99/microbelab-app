import Foundation
import Testing
@testable import Services

@Suite("RetentionMetricsStore")
@MainActor
struct RetentionMetricsStoreTests {
    // Per `.claude/rules/testing.md` § Crash-Resilience #5 — never
    // UserDefaults.standard in tests; per-file suite.
    private func makeDefaults() -> UserDefaults {
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic suite name per #file; never nil under XCTest.
        let defaults = UserDefaults(suiteName: #file)!
        defaults.removePersistentDomain(forName: #file)
        return defaults
    }

    private func makeStore(defaults: UserDefaults, suffix: String = "default") -> RetentionMetricsStore {
        RetentionMetricsStore(
            defaults: defaults,
            installKey: "test.retention.install.\(suffix)",
            daysKey: "test.retention.days.\(suffix)"
        )
    }

    // MARK: - Empty / first session

    @Test func emptyStoreHasNoInstallDate() {
        let store = makeStore(defaults: makeDefaults(), suffix: "empty")
        #expect(store.installDate == nil)
        #expect(store.distinctSessionDays.isEmpty)
        #expect(store.daysSinceInstall() == nil)
        #expect(store.returnedWithinD1() == false)
        #expect(store.returnedWithinD7() == false)
        #expect(store.returnedWithinD30() == false)
    }

    @Test func firstSessionSetsInstallAndOneDay() {
        let store = makeStore(defaults: makeDefaults(), suffix: "first")
        let install = Date(timeIntervalSinceReferenceDate: 800_000_000)
        store.recordSession(now: install)
        #expect(store.installDate == install)
        #expect(store.totalDistinctSessionDays == 1)
        // D1/D7/D30 stay false on install day — no return yet.
        #expect(store.returnedWithinD1(now: install) == false)
        #expect(store.returnedWithinD7(now: install) == false)
        #expect(store.returnedWithinD30(now: install) == false)
    }

    @Test func sameDayRecordingIsIdempotent() {
        let store = makeStore(defaults: makeDefaults(), suffix: "idem")
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
        store.recordSession(now: now)
        store.recordSession(now: now.addingTimeInterval(60 * 60))   // +1h
        store.recordSession(now: now.addingTimeInterval(60 * 60 * 5)) // +5h
        #expect(store.totalDistinctSessionDays == 1)
    }

    // MARK: - D1 / D7 / D30 cohort surface

    @Test func d1ReturnsTrueAfterSecondDay() {
        let defaults = makeDefaults()
        let store = makeStore(defaults: defaults, suffix: "d1")
        let install = isoDate("2026-06-12")
        store.recordSession(now: install)
        // Play again the next calendar day → D1 cohort returns true.
        let nextDay = isoDate("2026-06-13")
        store.recordSession(now: nextDay)
        #expect(store.returnedWithinD1(now: nextDay) == true)
        #expect(store.returnedWithinD7(now: nextDay) == true)
        #expect(store.returnedWithinD30(now: nextDay) == true)
    }

    @Test func d7TrueWhenReturnLandsWithinSevenDays() {
        let store = makeStore(defaults: makeDefaults(), suffix: "d7")
        let install = isoDate("2026-06-01")
        store.recordSession(now: install)
        let day5 = isoDate("2026-06-06")
        store.recordSession(now: day5)
        #expect(store.returnedWithinD7(now: day5) == true)
        #expect(store.returnedWithinD30(now: day5) == true)
    }

    @Test func d30TrueWhenReturnLandsOnDayTwentyFive() {
        let store = makeStore(defaults: makeDefaults(), suffix: "d30")
        let install = isoDate("2026-06-01")
        store.recordSession(now: install)
        let day25 = isoDate("2026-06-26")
        store.recordSession(now: day25)
        // D7 is false (the return landed past day 7) but D30 catches it.
        #expect(store.returnedWithinD7(now: day25) == false)
        #expect(store.returnedWithinD30(now: day25) == true)
    }

    @Test func returnsBeyondWindowDoNotCountInsideWindow() {
        let store = makeStore(defaults: makeDefaults(), suffix: "beyond")
        let install = isoDate("2026-06-01")
        store.recordSession(now: install)
        let day40 = isoDate("2026-07-11")
        store.recordSession(now: day40)
        #expect(store.returnedWithinD1(now: day40) == false)
        #expect(store.returnedWithinD7(now: day40) == false)
        #expect(store.returnedWithinD30(now: day40) == false)
    }

    // MARK: - Persistence

    @Test func sessionLogPersistsAcrossInits() {
        let defaults = makeDefaults()
        let install = isoDate("2026-06-01")
        let day3 = isoDate("2026-06-04")
        let store = makeStore(defaults: defaults, suffix: "persist")
        store.recordSession(now: install)
        store.recordSession(now: day3)

        let reopened = makeStore(defaults: defaults, suffix: "persist")
        #expect(reopened.installDate == install)
        #expect(reopened.totalDistinctSessionDays == 2)
        #expect(reopened.returnedWithinD7(now: day3) == true)
    }

    // MARK: - Capacity eviction

    @Test func dayLogStaysWithinCapacity() {
        let store = makeStore(defaults: makeDefaults(), suffix: "cap")
        let baseline = isoDate("2026-06-01")
        // Record 40 distinct days; the store caps at 32.
        for offset in 0..<40 {
            let day = Calendar.current.date(byAdding: .day, value: offset, to: baseline)!  // swiftlint:disable:this force_unwrapping
            store.recordSession(now: day)
        }
        #expect(store.totalDistinctSessionDays == RetentionMetricsStore.dayLogCapacity)
        // First few days evicted; latest entry survives.
        let expectedFirst = Calendar.current.date(byAdding: .day, value: 40 - RetentionMetricsStore.dayLogCapacity, to: baseline)!  // swiftlint:disable:this force_unwrapping
        let firstDayStart = Calendar.current.startOfDay(for: expectedFirst)
        #expect(store.distinctSessionDays.first == firstDayStart)
    }

    @Test func clearResetsEverything() {
        let store = makeStore(defaults: makeDefaults(), suffix: "clear")
        store.recordSession(now: isoDate("2026-06-01"))
        store.clear()
        #expect(store.installDate == nil)
        #expect(store.distinctSessionDays.isEmpty)
    }

    // MARK: - Helpers

    private func isoDate(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        // swiftlint:disable:next force_unwrapping
        // Safety: deterministic ISO-8601 date string.
        return formatter.date(from: iso)!
    }
}
